include("LuaRules/Gadgets/ai/Common.lua")
include("LuaRules/Gadgets/ai/Modules.lua")
include("LuaRules/Gadgets/ai/AttackerBehavior.lua")
include("LuaRules/Gadgets/ai/TaskQueueBehavior.lua")

AI = {}
AI.__index = AI

function AI.create(id, mode)
   local obj = {}             -- our new object
   setmetatable(obj,AI)  -- make AI handle lookup
   obj.id = id      -- initialize our object
   obj.mode = mode
   obj.frameShift = 7*tonumber(id)	-- used to spread out processing from different AIs across multiple frames
   obj.needStartPosAdjustment = false
   return obj
end

-- check if ally team has start box set (whole map => no start box)
function AI:hasStartBox(xMin,xMax,zMin,zMax)
	if xMin > 1 then
		return true
	end
	if zMin > 1 then
		return true
	end
	if xMax < Game.mapSizeX-1 then
		return true
	end
	if zMax < Game.mapSizeZ-1 then
		return true
	end
	
	return false
end

-- find good starting position within start box
-- if start boxes aren't set, return the assigned start position
function AI:findStartPos(doRangeCheck, minStartPosDist)
	local xMin, zMin, xMax, zMax = Spring.GetAllyTeamStartBox(self.allyId)
	if self:hasStartBox(xMin,xMax,zMin,zMax) and (xMax > xMin + 100) and (zMax > zMin + 100) then
		local rangeCheck = true
		local METAL_POTENTIAL_THRESHOLD = 1
		
		
		local xMin, zMin, xMax, zMax = Spring.GetAllyTeamStartBox(self.allyId)
		
		-- adjust min distance taking into account zone size and number of allies 
		local allies = Spring.GetTeamList(self.allyId)
		local numAllies = #allies
		if (numAllies > 0 and doRangeCheck and minStartPosDist == INFINITY) then
			minStartPosDist = ((xMax-xMin) + (zMax-zMin)) / (1.5*numAllies)
		end
		
		for _, cell in spairs(self.mapHandler.mapCellList, function(t,a,b) return t[b].metalPotential < t[a].metalPotential end) do
			rangeCheck = true
	
			-- check that cell center is within start box for the team and has metal potential
			if cell.metalSpotCount > 0 and cell.metalPotential >= METAL_POTENTIAL_THRESHOLD and (cell.p.x > xMin and cell.p.x < xMax) and (cell.p.z > zMin and cell.p.z < zMax) then
				-- Echo("cellX="..cell.p.x.." cellZ="..cell.p.z.." metal="..cell.metalPotential) --DEBUG
			
				if (numAllies > 0 and doRangeCheck) then
					-- check range from every other ally
					for _,teamId in pairs(allies) do
						local x,y,z
						local uPos
						-- if it's another AI, check if it set the position already
						if (GG.mFAIStartPosByTeamId[teamId]) then
							uPos = GG.mFAIStartPosByTeamId[teamId]
						else
							-- humans already picked their positions
							x,y,z = Spring.GetTeamStartPosition(teamId)
							uPos = {x=x,y=y,z=z}
						end
						
						if(checkWithinDistance(cell.p,uPos,minStartPosDist) == true) then
							rangeCheck = false
							break
						end
					end
				end
				
				-- return spot
				if rangeCheck == true then
					local mSpot = cell.metalSpots[1]
					
					if (mSpot == nil) then
						mSpot = {x=cell.p.x, z=cell.p.z}
					end
					local spot = {}
					spot.x = min(xMax, max(xMin, mSpot.x -50 + random(100)))
					spot.z = min(zMax, max(zMin, mSpot.z -50 + random(100)))  
					spot.y = spGetGroundHeight(spot.x, spot.z)		
					
					-- Spring.Echo("found start position for MFAI id="..self.id.." at ("..spot.x..";"..spot.y..";"..spot.z..")") --DEBUG
					return spot
				end
			end
		end
	else
		-- no start boxes, return the fixed start pos
		local x,y,z = Spring.GetTeamStartPosition(self.id)
		return {x=x,y=y,z=z}
	end

	-- allies are too close, maybe there's no way around it
	-- try again with lower min distance or range check disabled
	if (doRangeCheck) then
		if (minStartPosDist > 200) then
			return self:findStartPos(true,minStartPosDist/2)
		else
			-- Spring.Echo("could not find start position for MFAI id="..self.id.." : trying again with distance check disabled") --DEBUG
			return self:findStartPos(false,0)
		end
	end
	
	Spring.Echo("could not find start position for MFAI id="..self.id) --DEBUG
	return nil
end 

function AI:Init()
	-- Echo("initializing AI for teamID="..self.id) --DEBUG
	-- Echo(#modules)	 --DEBUG
	self.modules = {}
	if next(modules) ~= nil then
		for i,m in ipairs(modules) do
			newModule = m.create()
			local internalName = newModule:internalName()
			self[internalName] = newModule
			table.insert(self.modules,newModule)
			newModule:Init(self)
			-- Echo("added "..newModule:Name().." module") --DEBUG
		end
	end
	
	-- table with unit behaviors indexed by unitId
	self.unitBehaviors = {}
end

function AI:Update(n)
	if self.gameEnd == true then
		return
	end
	
	for i,m in ipairs(self.modules) do
		if m == nil then
			log("nil module!")
		else
			if (m.Update ~= nil) then
				m:Update(n)
			end
		end
	end
	
	-- add behaviour for units missing	
    for uId,_ in pairs(self.ownUnitIds) do
		if ((self.recentlyDestroyedUnitIds == nil or self.recentlyDestroyedUnitIds[uId] == nil or (n - self.recentlyDestroyedUnitIds[uId] > 10)) and self.unitBehaviors[uId] == nil) then
			self:AddUnitBehavior(uId, spGetUnitDefID(uId))
		end
    end 
	
	for i,b in pairs(self.unitBehaviors) do
		if (b.Update ~= nil) then
			b:Update(n)
		end
	end
	
end

function AI:UnitCreated(unitId, unitDefId, teamId, builderId)
	if self.gameEnd == true then
		return
	end
	if self.needStartPosAdjustment == true then
		return
	end
	
	-- only relevant for own units
	if (teamId == self.id and self.modules ~= nil) then
		for i,m in ipairs(self.modules) do
			if (m.UnitCreated ~= nil) then
				m:UnitCreated(unitId,unitDefId,builderId)
			end
		end

		-- add behavior
		self:AddUnitBehavior(unitId, unitDefId)
	end
end

function AI:UnitFinished(unitId, unitDefId, teamId)
	if self.gameEnd == true then
		return
	end
	if self.needStartPosAdjustment == true then
		return
	end
	
	-- only relevant for own units
	if (teamId == self.id and self.modules ~= nil) then
		for i,m in ipairs(self.modules) do
			if (m.UnitFinished ~= nil) then
				m:UnitFinished(unitId)
			end
		end
		
		if (self.unitBehaviors[unitId] ~= nil and self.unitBehaviors[unitId].UnitFinished ~= nil) then
			self.unitBehaviors[unitId]:UnitFinished(unitId)
		end
	end
end

function AI:UnitDestroyed(unitId, unitDefId, teamId, attackerId, attackerDefId, attackerTeamId)
	if self.gameEnd == true then
		return
	end
	for i,m in ipairs(self.modules) do
		if (m.UnitDestroyed ~= nil) then
			m:UnitDestroyed(unitId,teamId, unitDefId)
		end
	end
	
	if (teamId == self.id) then
		for i,b in pairs(self.unitBehaviors) do
			if (b.UnitDestroyed ~= nil) then
				b:UnitDestroyed(unitId)
			end
		end
		
		-- remove behavior from table
		self.unitBehaviors[unitId] = nil
		if (self.recentlyDestroyedUnitIds == nil) then
			self.recentlyDestroyedUnitIds = {}
		end
		self.recentlyDestroyedUnitIds[unitId] = spGetGameFrame()
	end
end

function AI:UnitIdle(unitId, unitDefId, teamId)
	if self.gameEnd == true then
		return
	end
	if self.needStartPosAdjustment == true then
		return
	end
	-- only relevant for own units
	if (teamId == self.id) then
		for i,m in ipairs(self.modules) do
			if (m.UnitIdle ~= nil) then
				m:UnitIdle(unitId)
			end
		end
		
		if (self.unitBehaviors[unitId] ~= nil and self.unitBehaviors[unitId].UnitIdle ~= nil) then
			self.unitBehaviors[unitId]:UnitIdle(unitId)
		end
	end
end

function AI:UnitDamaged(unitId, unitDefId, unitTeamId, damage, paralyzer, weaponDefId, projectileId, attackerId, attackerDefId, attackerTeamId)
	if self.gameEnd == true then
		return
	end

	-- only relevant for own units
	if (unitTeamId == self.id) then
		for i,m in ipairs(self.modules) do
			if (m.UnitDamaged ~= nil) then
				m:UnitDamaged(unitId, unitDefId, unitTeamId, damage, paralyzer, weaponDefId, projectileId, attackerId, attackerDefId, attackerTeamId)
			end
		end
		
		if (self.unitBehaviors[unitId] ~= nil and self.unitBehaviors[unitId].UnitDamaged ~= nil) then
			self.unitBehaviors[unitId]:UnitDamaged(unitId, unitDefId, unitTeamId, damage, paralyzer, weaponDefId, projectileId, attackerId, attackerDefId, attackerTeamId)
		end		
	end
end

function AI:UnitTaken(unitId, unitDefId, teamId, newTeamId)
	if self.gameEnd == true then
		return
	end
	 
 	-- only relevant for own units
	if (teamId == self.id and newTeamId ~= self.id) then
		for i,m in ipairs(self.modules) do
			if (m.UnitTaken ~= nil) then
				m:UnitTaken(unitId)
			end
		end
		
		if (self.unitBehaviors[unitId] ~= nil and self.unitBehaviors[unitId].UnitTaken ~= nil) then
			self.unitBehaviors[unitId]:UnitTaken(unitId)
		end
		
		-- remove behavior from table
		self.unitBehaviors[unitId] = nil
	end
end


function AI:UnitGiven(unitId, unitDefId, teamId, oldTeamId)
	if self.gameEnd == true then
		return
	end

	-- only relevant for own units
	if (teamId == self.id and self.modules ~= nil) then
		for i,m in ipairs(self.modules) do
			if (m.UnitGiven ~= nil) then
				m:UnitGiven(unitId,unitDefId,teamId,oldTeamId)
			end
		end

		-- add behavior
		self:AddUnitBehavior(unitId, unitDefId)
	end
end

function AI:GameEnd()
	self.gameEnd = true
	for i,m in ipairs(self.modules) do
		if (m.GameEnd ~= nil) then
			m:GameEnd()
		end
	end
end


function AI:AddUnitBehavior(unitId,unitDefId)
	-- add behavior
	local beh = nil
	un = UnitDefs[unitDefId].name
	if UnitDefs[unitDefId].isBuilder or setContains(unitTypeSets[TYPE_SUPPORT],un) then
 		-- log("adding task queue behavior for unit "..un, self)
		beh = TaskQueueBehavior.create()
		beh:Init(self,unitId)
	elseif setContains(unitTypeSets[TYPE_ATTACKER],un) then
		-- log("adding attacker behavior for unit "..un, self)
		beh = AttackerBehavior.create()
		beh:Init(self,unitId)
	end
	self.unitBehaviors[unitId] = beh
end

