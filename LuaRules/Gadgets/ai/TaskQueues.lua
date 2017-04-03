--[[
 Task Queues!
]]--

include("LuaRules/Gadgets/ai/Common.lua")

local function farFromBaseCenter(self, radius)
	if self.unitId == nil then
		return true
	end
	local basePos = self.ai.unitHandler.basePos
	if basePos.x > 0 and basePos.z > 0 and distance(basePos, self.pos) > ( radius or HUGE_RADIUS) then
		return true
	end
	return false
end

local function areEnemiesNearby(self,pos, radius)
	for _,cell  in pairs(self.ai.unitHandler.enemyCellList) do
		-- only check for armed units
		if checkWithinDistance(cell.p,pos,radius) and (cell.attackerCost > 0 or cell.airAttackerCost > 0 or cell.defenderCost > 0) then
			return true
		end
	end
	return false
end 

local function checkMorph(self)
	if self.unitId ~= nil then
		if not setContains(unitTypeSets[TYPE_UPGRADED_COMMANDER],self.unitName) then

			local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")
			local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(self.ai.id,"energy")
			
			-- morph only if income is decent
			if incomeM > 35 and incomeE > 300 then
				-- if enemies are nearby, skip morph
				if areEnemiesNearby(self, self.pos, MORPH_CHECK_RADIUS) then
					--log("enemies nearby")
					return SKIP_THIS_TASK
				end

			
				local cmds = Spring.GetUnitCmdDescs(self.unitId)
				local morphCmdIds = {}
				for i,c in ipairs(cmds) do
					if (c.action == "morph") then
						--Spring.Echo(c.id.." ; "..c.name.." ; "..c.type.." ; "..c.action.." ; "..c.texture) --DEBUG
						morphCmdIds[#morphCmdIds + 1] = c.id
					end
				end
				local morphCmd = morphCmdIds[ random( 1, #morphCmdIds) ]
			
				spGiveOrderToUnit(self.unitId,morphCmd,{},{})
				-- wait until finished or 5 minutes elapsed
				return {action="wait", frames=30*300}
			end
		end
	end
	
	return SKIP_THIS_TASK
end

-- assist another builder that is performing specific functions
local function assistOtherBuilderIfNeeded(self)
	local queues = self.ai.unitHandler.taskQueues

	-- only about 20% should try to assist, the rest should skip
	if (random(1,10) > 8) then
		return SKIP_THIS_TASK
	end

	if(queues ~= nil) then	
		-- search task queues for advanced defense builders or mex upgraders
		for i,tq in ipairs(queues) do
			if self.unitDef.isAirUnit or (tq.unitDef.isAirUnit == false and self.isWaterMode == tq.isWaterMode) then
				if tq.specialRole == UNIT_ROLE_ADVANCED_DEFENSE_BUILDER or tq.specialRole == UNIT_ROLE_MEX_UPGRADER then
					spGiveOrderToUnit(self.unitId,CMD.GUARD,{tq.unitId},{})
					return {action="wait_idle", frames=1800}
				end
			end
		end
	end
	return SKIP_THIS_TASK
end

-- check if nearby metal resources are mostly on land or on water
local function checkLandOrWater(self)
	local result = "land"
	--TODO : make it work with water maps
	--[[
	if self.unitId ~= nil then

		local landSpots = 0
		local waterSpots = 0
		local xi,zi = getCellXZIndexesForPosition(self.pos)
		local mapCell = self.ai.mapHandler.mapCells[xi][zi]
		if (mapCell.isWater == true or mapCell.isDeepWater == true) then
			waterSpots = mapCell.metalSpotCount 
		else
			landSpots = mapCell.metalSpotCount
		end
		waterSpots = waterSpots + mapCell.nearbyWaterMetalSpotCount
		landSpots = landSpots + mapCell.nearbyLandMetalSpotCount

		if ( waterSpots > landSpots ) then
			result = "water"
		end
	end
	--]]
	
	return result
end


-- check if nearby metal resources are mostly on land or on water
function setWaterMode(self)
	self.isWaterMode = true
	return SKIP_THIS_TASK
end

function windSolarIfNeeded(self)
	-- check if we need power
	local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(self.ai.id,"energy")
	if incomeE < 1000  then
		return buildEnergyIfNeeded(self,windSolar(self))
	else
		return SKIP_THIS_TASK
	end
end


function tidalIfNeeded(self)
	-- check if we need power
	local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(self.ai.id,"energy")
	if incomeE < 1000  then
		return buildEnergyIfNeeded(self,tidalByFaction[self.unitSide])
	else
		return SKIP_THIS_TASK
	end
end

function metalExtractorIfNeeded(self)
	-- check if we need metal
	local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")

	local friendlyExtractorCount = self.ai.unitHandler.friendlyExtractorCount or 0
		
	if friendlyExtractorCount < 2 or incomeM < 20 or (incomeM - expenseM < 2) then
		if(self.isWaterMode == true) then
			return UWMexByFaction[self.unitSide]
		else
			return mexByFaction[self.unitSide]
		end
	else
		return SKIP_THIS_TASK
	end
end

function metalExtractorNearbyIfSafe(self)
	local unitName = nil
	
	local friendlyExtractorCount = self.ai.unitHandler.friendlyExtractorCount or 0
	local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")
	if friendlyExtractorCount > 10 and incomeM > 30 and storageM > 500 and currentLevelM >= 0.9 * storageM and incomeM > expenseM then
		return SKIP_THIS_TASK
	end

	if(self.isWaterMode == true) then
		unitName = UWMexByFaction[self.unitSide]
	else
		unitName = mexByFaction[self.unitSide]
	end
	
	local p = self.ai.buildSiteHandler:ClosestFreeSpot(self, UnitDefNames[unitName], self.pos, true, "metal", self.unitDef)
	
	if ( p ~= nil and distance(self.pos,p) < BIG_RADIUS) then	
		return unitName
	end

	return SKIP_THIS_TASK
end


-- restore original queue
function restoreQueue(self)

	-- revert to default queue
	self:ChangeQueue(nil)
	self.specialRole = 0
	self.isWaterMode = false
	return SKIP_THIS_TASK
end

function changeQueueToCommanderBaseBuilderIfNeeded(self)
	if (not self.ai.unitHandler.baseUnderAttack) then
		local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")
		local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(self.ai.id,"energy")
	
		-- if low on resource income or factories, rebuild base	
		if (incomeM < 10 or incomeE < 100) or (countOwnUnits(self,nil,1,TYPE_PLANT) < 1 )  then
			self:ChangeQueue(commanderBaseBuilderQueueByFaction[self.unitSide])
			self.isAttackMode = false
			-- log("changed to base builder commander!",self.ai)
		end

	end
	return SKIP_THIS_TASK
end


function changeQueueToCommanderAttackerIfNeeded(self)
	local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")
	local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(self.ai.id,"energy")

	-- if has decent resource income and factories, go support the attackers
	if (incomeM > 10 and incomeE > 130 and countOwnUnits(self,nil,2,TYPE_PLANT) > 0 ) then
		self:ChangeQueue(commanderAtkQueueByFaction[self.unitSide])
		self.isAttackMode = true
		-- log("changed to attack commander!",self.ai)
	end

	return SKIP_THIS_TASK
end


function changeQueueToWaterCommanderIfNeeded(self)
	if(checkLandOrWater(self) == "water") then
		self:ChangeQueue(commanderWaterQueueByFaction[self.unitSide])

		self.isWaterMode = true
	end
	return SKIP_THIS_TASK
end

function changeQueueToMexUpgraderIfNeeded(self)
	local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(self.ai.id,"energy")

	local mexes = countOwnUnits(self,nil,0,TYPE_MEX)
	local mohos = countOwnUnits(self,nil,0,TYPE_MOHO)
	if  mexes > mohos and (incomeE > 200 and incomeE - expenseE > 60) then
		self:ChangeQueue(mexUpgraderQueueByFaction[self.unitSide])
		self.specialRole = UNIT_ROLE_MEX_UPGRADER
	end
	
	return SKIP_THIS_TASK
end

function changeQueueToMexBuilderIfNeeded(self)
	local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")
	
	-- check if there are spots available
	if( (self.ai.unitHandler.enemyExtractorCount + self.ai.unitHandler.friendlyExtractorCount) / #self.ai.mapHandler.spots > FREE_METAL_SPOT_EXPANSION_THRESHOLD ) then
		return SKIP_THIS_TASK
	end

	if self.ai.unitHandler.mexBuilderCount < self.ai.unitHandler.mexBuilderCountTarget then
		if( self.isWaterMode == true) then
			self:ChangeQueue(waterMexBuilderQueueByFaction[self.unitSide])
		else
			self:ChangeQueue(mexBuilderQueueByFaction[self.unitSide])
		end
		
		self.noDelay = true
		self.specialRole = UNIT_ROLE_MEX_BUILDER
	end
	
	return SKIP_THIS_TASK
end


function changeQueueToDefenseBuilderIfNeeded(self)

	if self.ai.unitHandler.mostVulnerableCell ~= nil and self.ai.unitHandler.defenseBuilderCount < self.ai.unitHandler.defenseBuilderCountTarget then
		if( self.isWaterMode == true) then
			self:ChangeQueue(waterDefenseBuilderQueueByFaction[self.unitSide])
		else
			self:ChangeQueue(defenseBuilderQueueByFaction[self.unitSide])
		end
		
		self.noDelay = false
		self.specialRole = UNIT_ROLE_DEFENSE_BUILDER
	end
	
	return SKIP_THIS_TASK
end

function changeQueueToAdvancedDefenseBuilderIfNeeded(self)

	if self.ai.unitHandler.mostVulnerableCell ~= nil and self.ai.unitHandler.advancedDefenseBuilderCount < self.ai.unitHandler.advancedDefenseBuilderCountTarget then
		if( self.isWaterMode == true) then
			self:ChangeQueue(advancedWaterDefenseBuilderQueueByFaction[self.unitSide])
		else
			self:ChangeQueue(advancedDefenseBuilderQueueByFaction[self.unitSide])
		end
		
		self.noDelay = false
		self.specialRole = UNIT_ROLE_ADVANCED_DEFENSE_BUILDER		
	end
	
	return SKIP_THIS_TASK
end

function buildEnergyIfNeeded(self,unitName)
	local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")
	local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(self.ai.id,"energy")

	local threshold = max(max(1.2 * expenseE + 100, 8 * incomeM + 50),350)
	if incomeE < threshold then
		-- log("buildEnergyIfNeeded: income "..incomeE..", usage "..expenseE..", building more energy",self.ai)
		return unitName
	else
		return SKIP_THIS_TASK
	end
end



function reclaimNearestMexIfNeeded(self)
	-- try to find nearest mex
	local ownUnitIds = self.ai.ownUnitIds
	local tooClose = 2000
	local mexUnitId = nil
	local closestDistance = INFINITY
	local mexPos = nil
	local dist = 0
	
	for uId,_ in pairs(ownUnitIds) do
		if setContains(unitTypeSets[TYPE_MEX],UnitDefs[spGetUnitDefID(uId)].name) then
			dist = INFINITY
			-- if it's not 100% HP, then don't touch it (unless there's REALLY no better choice)
			-- this prevents a situation when engineer reclaims a mex that is still being built by someone else
			mexPos = newPosition(spGetUnitPosition(uId,false,false))
			local _,_,_,_,progress = spGetUnitHealth(uId)
			
			if( (mexPos.y > UNDERWATER_THRESHOLD and self.isWaterMode) or (mexPos.y < UNDERWATER_THRESHOLD and not self.isWaterMode) ) then
				dist = INFINITY
			elseif progress < 1 then
				dist = INFINITY
			elseif areEnemiesNearby(self, mexPos, tooClose) then
				dist = INFINITY
			else
				dist = distance(self.pos,mexPos) 
			end
			
			if dist < closestDistance then
				mexUnitId = uId
				closestDistance = dist
			end
		end
	end

	if mexUnitId ~= nil then
		-- command the engineer to reclaim the mex
		spGiveOrderToUnit(self.unitId,CMD.RECLAIM,{mexUnitId},{})
		-- log("MexUpgradeBehavior: unit "..self.unitName.." goes to reclaim a mex",self.ai)
		
		-- we'll build the moho here
		self.mexPos = mexPos
		self.reclaimedMex = true

		-- wait until it finishes
		return {action="wait_idle", frames=1800}
	end
	
	return SKIP_THIS_TASK
end

function mohoIfMexReclaimed(self)
	if (self.reclaimedMex) then
		self.reclaimedMex = false
		self.noDelay = true
		local unitName = nil
		
		if(self.isWaterMode == true) then
			unitName = UWMohoMineByFaction[self.unitSide]
		else
			unitName = mohoMineByFaction[self.unitSide]
		end
		-- log("goes to build a moho mine where the mex was reclaimed : "..unitName,self.ai)
		return unitName		
	else
		return SKIP_THIS_TASK
	end
end

function basePatrolIfNeeded(self)

	if self.ai.unitHandler.basePatrollerCount > 0 then
		return SKIP_THIS_TASK
	end
	
	local basePos = self.ai.unitHandler.basePos
	local baseX = basePos.x
	local baseZ = basePos.z
	local radius = BASE_AREA_PATROL_RADIUS / 2
	
	local movePos = newPosition(baseX - (radius + random( 1, radius)),0,baseZ)
	if (spTestMoveOrder(self.unitDefId,movePos.x,movePos.y,movePos.z)) then
		spGiveOrderToUnit(self.unitId,CMD.PATROL,{movePos.x,movePos.y,movePos.z},{})
	end

	movePos.x=baseX + (radius + random( 1, radius))
	if (spTestMoveOrder(self.unitDefId,movePos.x,movePos.y,movePos.z)) then
		spGiveOrderToUnit(self.unitId,CMD.PATROL,{movePos.x,movePos.y,movePos.z},CMD.OPT_SHIFT)
	end

	movePos.x=baseX
	movePos.z=baseZ + (radius + random( 1, radius))
	if (spTestMoveOrder(self.unitDefId,movePos.x,movePos.y,movePos.z)) then
		spGiveOrderToUnit(self.unitId,CMD.PATROL,{movePos.x,movePos.y,movePos.z},CMD.OPT_SHIFT)
	end
		
	movePos.z=baseZ - (radius + random( 1, radius))
	if (spTestMoveOrder(self.unitDefId,movePos.x,movePos.y,movePos.z)) then
		spGiveOrderToUnit(self.unitId,CMD.PATROL,{movePos.x,movePos.y,movePos.z},CMD.OPT_SHIFT)
	end

	self.specialRole = UNIT_ROLE_BASE_PATROLLER
	 
	-- do it forever!
	return {action="wait", frames=9999999}
end


function briefAreaPatrol(self)
	
	-- if unit is far away from base center, move to center and then retry
	if unitName ~= SKIP_THIS_TASK and farFromBaseCenter(self)  then
		self:Retry()
		return moveBaseCenter(self)
	end
	
	local selfPos = self.pos
	local radius = BRIEF_AREA_PATROL_RADIUS / 2 
	
	local movePos = newPosition(selfPos.x - (radius + random( 1, radius)),selfPos.y,selfPos.z)
	if (spTestMoveOrder(self.unitDefId,movePos.x,movePos.y,movePos.z)) then
		spGiveOrderToUnit(self.unitId,CMD.PATROL,{movePos.x,movePos.y,movePos.z},{})
	end

	movePos.x=selfPos.x + (radius + random( 1, radius))
	if (spTestMoveOrder(self.unitDefId,movePos.x,movePos.y,movePos.z)) then
		spGiveOrderToUnit(self.unitId,CMD.PATROL,{movePos.x,movePos.y,movePos.z},CMD.OPT_SHIFT)
	end

	movePos.x=selfPos.x
	movePos.z=selfPos.z + (radius + random( 1, radius))
	if (spTestMoveOrder(self.unitDefId,movePos.x,movePos.y,movePos.z)) then
		spGiveOrderToUnit(self.unitId,CMD.PATROL,{movePos.x,movePos.y,movePos.z},CMD.OPT_SHIFT)
	end
		
	movePos.z=selfPos.z - (radius + random( 1, radius))
	if (spTestMoveOrder(self.unitDefId,movePos.x,movePos.y,movePos.z)) then
		spGiveOrderToUnit(self.unitId,CMD.PATROL,{movePos.x,movePos.y,movePos.z},CMD.OPT_SHIFT)
	end
	
	
	-- do it for some time
	return {action="wait", frames=BRIEF_AREA_PATROL_FRAMES}
end

function exitPlant(self)
	local radius = 100
	p = newPosition()
	p.x = self.pos.x
	p.z = self.pos.z+100
	p.y = 0
	spGiveOrderToUnit(self.unitId,CMD.MOVE,{p.x,p.y,p.z},{})

	-- log(self.unitName.." ("..self.pos.x..";"..self.pos.z..") exiting factory to ("..p.x..";"..p.z..")",self.ai) --DEBUG

	-- wait a bit to let the move order finish
	return {action="wait_idle", frames=200}
end


function moveAtkCenter(self)
	local radius = MED_RADIUS
	local atkPos = self.ai.unitHandler.unitGroups[UNIT_GROUP_ATTACKERS].centerPos 
	local basePos = self.ai.unitHandler.basePos
	
	local p = newPosition()
	p.y = 0
		
	if ( atkPos.x > 0 and atkPos.z >0) then
		p.x = atkPos.x-radius/2+random(1,radius)
		p.z = atkPos.z-radius/2+random(1,radius)
	elseif ( basePos.x > 0 and basePos.z > 0) then
		p.x = basePos.x-radius/2+random(1,radius)
		p.z = basePos.z-radius/2+random(1,radius)
	else
		-- do nothing
		return SKIP_THIS_TASK
	end

	spGiveOrderToUnit(self.unitId,CMD.MOVE,{p.x,p.y,p.z},{})
		
	-- add another order to queue in case the first is invalid
	spGiveOrderToUnit(self.unitId,CMD.MOVE,{p.x - radius/2 + random( 1, radius),0,p.z - radius/2 + random( 1, radius)},CMD.OPT_SHIFT)
	return {action="wait", frames=120}
end


function patrolAtkCenter(self)
	local radius = MED_RADIUS
	local atkPos = self.ai.unitHandler.unitGroups[UNIT_GROUP_ATTACKERS].centerPos
	local basePos = self.ai.unitHandler.basePos
	
	local p = newPosition()
	p.y = 0
		
	if ( atkPos.x > 0 and atkPos.z >0) then
		p.x = atkPos.x-radius/2+random(1,radius)
		p.z = atkPos.z-radius/2+random(1,radius)
	elseif ( basePos.x > 0 and basePos.z > 0) then
		p.x = basePos.x-radius/2+random(1,radius)
		p.z = basePos.z-radius/2+random(1,radius)
	else
		-- do nothing
		return SKIP_THIS_TASK
	end

	local f = spGetGameFrame()
	
	-- do not give the orders if already there
	if (distance(self.pos,p) > BIG_RADIUS) then
		spGiveOrderToUnit(self.unitId,CMD.MOVE,{p.x,p.y,p.z},{})			
		spGiveOrderToUnit(self.unitId,CMD.PATROL,{p.x - BRIEF_AREA_PATROL_RADIUS/2 + random( 1, BRIEF_AREA_PATROL_RADIUS),0,p.z - BRIEF_AREA_PATROL_RADIUS/2 + random( 1, BRIEF_AREA_PATROL_RADIUS)},CMD.OPT_SHIFT)
	--elseif (f - self.idleFrame < 90 or self.distance(self.pos,p) > MED_RADIUS) then
	elseif (true) then
		spGiveOrderToUnit(self.unitId,CMD.PATROL,{p.x,p.y,p.z},{})			
		spGiveOrderToUnit(self.unitId,CMD.PATROL,{p.x - BRIEF_AREA_PATROL_RADIUS/2 + random( 1, BRIEF_AREA_PATROL_RADIUS),0,p.z - BRIEF_AREA_PATROL_RADIUS/2 + random( 1, BRIEF_AREA_PATROL_RADIUS)},CMD.OPT_SHIFT)
	end
	
	return {action="wait", frames=120}
end


function moveBaseCenter(self)
	local radius = BIG_RADIUS
	local basePos = self.ai.unitHandler.basePos
	
	if ( basePos.x > 0 and basePos.z > 0 and farFromBaseCenter(self, BIG_RADIUS)) then
		p = newPosition()
		p.x = basePos.x-radius/2+random(1,radius)
		p.z = basePos.z-radius/2+random(1,radius)
		p.y = 0
		spGiveOrderToUnit(self.unitId,CMD.MOVE,{p.x,p.y,p.z},{})
		
		-- add another order to queue in case the first is invalid
		spGiveOrderToUnit(self.unitId,CMD.MOVE,{p.x - radius/2 + random( 1, radius),p.y,p.z - radius/2 + random( 1, radius)},CMD.OPT_SHIFT)
	
		-- wait a bit to let the move order finish
		return {action="wait_idle", frames=1800}
	end
	
	return SKIP_THIS_TASK
end


function moveVulnerablePos(self)
	local radius = BIG_RADIUS
	local cellPos = self.ai.unitHandler.mostVulnerableCell.p
	
	if ( cellPos.x > 0 and cellPos.z > 0 ) then
		p = newPosition()
		p.x = cellPos.x-radius/2+random(1,radius)
		p.z = cellPos.z-radius/2+random(1,radius)
		p.y = 0
		spGiveOrderToUnit(self.unitId,CMD.MOVE,{p.x,p.y,p.z},{})
		
		-- add another order to queue in case the first is invalid
		spGiveOrderToUnit(self.unitId,CMD.MOVE,{p.x - radius/2 + random( 1, radius),p.y,p.z - radius/2 + random( 1, radius)},CMD.OPT_SHIFT)
	
		-- wait a bit to let the move order finish
		return {action="wait_idle", frames=1800}
	end
	
	return SKIP_THIS_TASK
end

function moveSafePos(self)
	local radius = BIG_RADIUS
	local cellPos = self.ai.unitHandler.leastVulnerableCell.p
	
	if ( cellPos.x > 0 and cellPos.z > 0 ) then
		p = newPosition()
		p.x = cellPos.x-radius/2+random(1,radius)
		p.z = cellPos.z-radius/2+random(1,radius)
		p.y = 0

		spGiveOrderToUnit(self.unitId,CMD.MOVE,{p.x,p.y,p.z},{})
		
		-- add another order to queue in case the first is invalid
		spGiveOrderToUnit(self.unitId,CMD.MOVE,{p.x - radius/2 + random( 1, radius),p.y,p.z - radius/2 + random( 1, radius)},CMD.OPT_SHIFT)
	
		-- wait a bit to let the move order finish
		return {action="wait_idle", frames=1800}
	end
	
	return SKIP_THIS_TASK
end


-- build storage if needed
function storageIfNeeded(self)
	local unitName = SKIP_THIS_TASK

	if unitName == SKIP_THIS_TASK then
		unitName = buildWithLimitedNumber(self, energyStorageByFaction[self.unitSide],1)
	end
	if unitName == SKIP_THIS_TASK then
		unitName = buildWithLimitedNumber(self, metalStorageByFaction[self.unitSide],1)
	end	
	if unitName == SKIP_THIS_TASK then
		local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(self.ai.id,"energy")

		if currentLevelE >= 0.9 * storageE then
			unitName = buildWithLimitedNumber(self, energyStorageByFaction[self.unitSide], math.floor(1+math.floor(incomeE/700),ENERGY_STORAGE_LIMIT)) 
		end
	end
	if unitName == SKIP_THIS_TASK then
		local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")

		if currentLevelM >= 0.9 * storageM then
			unitName = buildWithLimitedNumber(self, metalStorageByFaction[self.unitSide],math.floor(1+math.floor(incomeM/25),METAL_STORAGE_LIMIT))		
		end
	end

	return unitName
end

function windSolar(self)
	if ((Game.windMax+Game.windMin)/2 > 15) and (random(1,10) <=5) then
		return windByFaction[self.unitSide]
	else
		return solarByFaction[self.unitSide]
	end
end


-- how many unitName or similar units do we own
function countOwnUnits(self,unitName, maxCount, type)
	local unitCount = 0
	if unitName == SKIP_THIS_TASK then
		return 0
	end
	
	for uId,_ in pairs(self.ai.ownUnitIds) do
		local un = UnitDefs[spGetUnitDefID(uId)].name
		if ((unitName ~= nil and un == unitName) or (type ~= nil and setContains(unitTypeSets[type],un)) ) then
			unitCount = unitCount + 1
			if maxCount ~= nil and maxCount > 0 and unitCount >= maxCount then
				break
			end
		end
	end
	return unitCount
end

function buildWithLimitedNumber(self,tmpUnitName, maxNumber, type)
	local unitCount = 0

	if tmpUnitName == SKIP_THIS_TASK then
		return tmpUnitName
	end
	for uId,_ in pairs(self.ai.ownUnitIds) do
		local un = UnitDefs[spGetUnitDefID(uId)].name
		if un == tmpUnitName or (type ~= nil and setContains(unitTypeSets[type],un)) then
			unitCount = unitCount + 1
		end
		if unitCount >= maxNumber then
			break
		end
	end
	if unitCount >= maxNumber then
		return SKIP_THIS_TASK
	else
		return tmpUnitName
	end
end

function buildWithMinimalMetalIncome(self,unitName, minNumber)
	local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")

	if incomeM < minNumber then
		return SKIP_THIS_TASK
	else
		return unitName
	end
end

-- build something only if we produce at least this much energy, and our e-storage is at least 3/4 full (so probably no estall)
function buildWithMinimalEnergyIncome(self,unitName, minNumber)
	local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(self.ai.id,"energy")
	if ( incomeE < minNumber) or ( currentLevelE < 0.75 * storageE) then
		return SKIP_THIS_TASK
	else
		return unitName
	end
end

function buildWithExtraEnergyIncome(self,unitName, minNumber)
	local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(self.ai.id,"energy")
	if incomeE - expenseE < minNumber then
		return SKIP_THIS_TASK
	else
		return unitName
	end
end

function buildWithExtraMetalIncome(self,unitName, minNumber)
	local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")
	-- log("buildWithExtraMetalIncome: income "..res.income..", usage "..res.expense..", threshold "..minNumber, self.ai)
	if incomeM - expenseM < minNumber then
		return SKIP_THIS_TASK
	else
		return unitName
	end
end

local function lvl1PlantIfNeeded(self)
	-- exclude aircraft factories at first
	local excludeAir = 0 	
	if (countOwnUnits(self, nil,2,TYPE_L1_PLANT) < 1) then
		excludeAir = 1
	end

	local unitName = lev1PlantByFaction[self.unitSide][ random( 1, tableLength(lev1PlantByFaction[self.unitSide]) - excludeAir ) ] 
	local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")

	unitName = buildWithLimitedNumber(self, unitName, 2 + math.floor(incomeM/70), TYPE_L1_PLANT) 
	
	-- if unit is far away from base center, move to center and then retry
	if unitName ~= SKIP_THIS_TASK and farFromBaseCenter(self)  then
		self:Retry()
		return moveBaseCenter(self)
	end	
	
	return unitName
end


local function lvl2PlantIfNeeded(self)
	-- exclude aircraft factories at first
	local excludeAir = 0 	
	if (countOwnUnits(self, nil,1,TYPE_L2_PLANT) < 1) then
		excludeAir = 1
	end

	local unitName = lev2PlantByFaction[self.unitSide][ random( 1, tableLength(lev2PlantByFaction[self.unitSide])- excludeAir ) ]
	local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")
	local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(self.ai.id,"energy")

	-- if low on energy, skip
	if currentLevelE < 0.5*storageE or incomeE < expenseE + 100 then
		return SKIP_THIS_TASK
	end 

	unitName = buildWithLimitedNumber(self, unitName, 0 + math.floor((10+incomeM)/30), TYPE_L2_PLANT)

	-- if unit is far away from base center, move to center and then retry
	if unitName ~= SKIP_THIS_TASK and farFromBaseCenter(self)  then
		self:Retry()
		return moveBaseCenter(self)
	end	
	
	return unitName
end

local function upgradeCenterIfNeeded(self)
	-- skip this on easy mode
	if(self.isEasyMode) then
		return SKIP_THIS_TASK
	end
	
	if (countOwnUnits(self, nil,1,TYPE_UPGRADE_CENTER) > 0) then
		return SKIP_THIS_TASK
	end

	local unitName = upgradeCenterByFaction[self.unitSide]
	local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")
	local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(self.ai.id,"energy")

	-- if low on energy, skip
	if currentLevelE < 0.5*storageE or incomeE < expenseE + 100 then
		return SKIP_THIS_TASK
	end 

	-- if unit is far away from base center, move to center and then retry
	if unitName ~= SKIP_THIS_TASK and farFromBaseCenter(self)  then
		self:Retry()
		return moveBaseCenter(self)
	end	
	
	return unitName
end


local function lvl1WaterPlantIfNeeded(self)
	-- exclude aircraft factories at first
	local excludeAir = 0 	
	if (countOwnUnits(self, nil,2,TYPE_L1_PLANT) < 1) then
		excludeAir = 1
	end

	local unitName = lev1WaterPlantByFaction[self.unitSide][ random( 1, tableLength(lev1WaterPlantByFaction[self.unitSide]) - excludeAir ) ] 
	local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")

	unitName = buildWithLimitedNumber(self, unitName, 2 + math.floor(incomeM/30), TYPE_L1_PLANT) 
	
	-- if unit is far away from base center, move to center and then retry
	if unitName ~= SKIP_THIS_TASK and farFromBaseCenter(self)  then
		self:Retry()
		return moveBaseCenter(self)
	end	
	
	return unitName
end


local function lvl2WaterPlantIfNeeded(self)
	-- exclude aircraft factories at first
	local excludeAir = 0 	
	if (countOwnUnits(self, nil,1,TYPE_L2_PLANT) < 1) then
		excludeAir = 1
	end


	local unitName = lev2WaterPlantByFaction[self.unitSide][ random( 1, tableLength(lev2WaterPlantByFaction[self.unitSide])- excludeAir ) ]
	local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")

	unitName = buildWithLimitedNumber(self, unitName, 0 + math.floor((10+incomeM)/30), TYPE_L2_PLANT)

	-- if unit is far away from base center, move to center and then retry
	if unitName ~= SKIP_THIS_TASK and farFromBaseCenter(self)  then
		self:Retry()
		return moveBaseCenter(self)
	end	
	
	return unitName
end


local function brutalPlant(self)
	if self.isBrutalMode then
		return lvl1PlantIfNeeded(self)
	end
	
	return SKIP_THIS_TASK
end

local function brutalAirPlant(self)
	if self.isBrutalMode then
		if (countOwnUnits(self, nil,4,TYPE_L1_PLANT) < 3) then
			return lev1PlantByFaction[self.unitSide][ tableLength(lev1PlantByFaction[self.unitSide]) ]		
		end
	end
	
	return SKIP_THIS_TASK
end


local function brutalLightDefense(self)
	if self.isBrutalMode then
		return lltByFaction[self.unitSide]
		--return areaLimit_Llt(self)
	end
	
	return SKIP_THIS_TASK
end

local function brutalAADefense(self)
	if self.isBrutalMode then
		if lightAAByFaction[self.unitSide] then
			return lightAAByFaction[self.unitSide]
		end
		return mediumAAByFaction[self.unitSide]
		--return areaLimit_LightAA(self)
	end
	
	return SKIP_THIS_TASK
end

local function brutalHeavyDefense(self)
	if self.isBrutalMode then
		return lev2HeavyDefenseByFaction[self.unitSide][ random( 1, tableLength(lev2HeavyDefenseByFaction[self.unitSide]) ) ]
		--return areaLimit_L2HeavyDefense(self)
	end
	
	return SKIP_THIS_TASK
end


local function respawnIfNeeded(self)
	local unitName = "commander_token"
	
    -- respawn commander on this spot only if there are no enemies nearby
	if areEnemiesNearby(self, self.pos, BIG_RADIUS) then
		-- log("enemies are nearby",self.ai)
		return SKIP_THIS_TASK
	else
		if buildWithLimitedNumber(self,unitName, 1, TYPE_COMMANDER) ~= SKIP_THIS_TASK then
			-- log("rebuilding commander",self.ai)
			return unitName
		else
			-- log("commander is alive and well",self.ai)
		end
	end
	
	return SKIP_THIS_TASK
end

local function zephyrIfNeeded(self)
	return buildWithLimitedNumber(self,"aven_zephyr", 1, nil) 
end

local function geoIfNeeded(self)
	-- don't attempt if there are no spots on the map
	if not self.ai.mapHandler.mapHasGeothermal then
		return SKIP_THIS_TASK
	end

	return buildEnergyIfNeeded(self,geoByFaction[self.unitSide])
end

local function fusionIfNeeded(self)

	local unitName = SKIP_THIS_TASK

	if (countOwnUnits(self, fusionByFaction[self.unitSide],1) > 0 ) then
		unitName = buildWithMinimalMetalIncome(self,buildEnergyIfNeeded(self,fusionByFaction[self.unitSide]),60)
	else
		unitName = buildWithMinimalMetalIncome(self,fusionByFaction[self.unitSide],40)
	end
		
	-- if unit is far away from base center, move to center and then retry
	if unitName ~= SKIP_THIS_TASK and farFromBaseCenter(self)  then
		self:Retry()
		return moveBaseCenter(self)
	end	

	return unitName
end

local function brutalFusion(self)
	if self.isBrutalMode then
		return fusionIfNeeded(self)
	end
	
	return SKIP_THIS_TASK
end

local function roughFusionIfNeeded(self)
	local unitName = buildEnergyIfNeeded(self,"sphere_fusion_reactor")

	-- if unit is far away from base center, move to center and then retry
	if unitName ~= SKIP_THIS_TASK and farFromBaseCenter(self)  then
		self:Retry()
		return moveBaseCenter(self)
	end

	return unitName
end


local function patrolAtkCenterIfNeeded(self)
	if self.ai.unitHandler.attackPatrollerCount < self.ai.unitHandler.attackPatrollerCountTarget then
		self.noDelay = true
		self.specialRole = UNIT_ROLE_ATTACK_PATROLLER
		self:ChangeQueue(attackPatrollerQueue)
		-- local selfPos = newPosition(spGetUnitPosition(self.unitId,false,false))
		-- log(self.unitName.." at ("..selfPos.x.." ; "..selfPos.z..") changed to atk patroller",self.ai)
	end
	return SKIP_THIS_TASK
end

-- how many of our own unitName or similar units there are in a radius around a position
function countOwnUnitsInRadius(self,unitName, pos, radius, maxCount, type)
	local ownUnitIds = self.ai.ownUnitIds
	local unitCount = 0

	local ownCell = getNearbyCellIfExists(self.ai.unitHandler.ownBuildingCells, pos)
	local ud = nil
	if (ownCell ~= nil) then 
		for uId,_ in pairs(ownCell.buildingIdSet) do
			ud = spGetUnitDefID(uId)		
			if ud ~= nil then
				un = UnitDefs[spGetUnitDefID(uId)].name
				if ((unitName ~= nil and un == unitName) or (type ~= nil and setContains(unitTypeSets[type],un)) ) then
					local upos = newPosition(spGetUnitPosition(uId,false,false))
					if checkWithinDistance(pos, upos,radius) then
						unitCount = unitCount + 1
					end
					if maxCount ~= nil and maxCount > 0 and unitCount >= maxCount then
						break
					end
				end
			else
				-- invalid uId entry in building id set, remove
				ownCell.buildingIdSet[uId] = nil 
			end
		end
	end
	
	return unitCount
end

local function checkAreaLimit(self,unitName, builder, unitLimit, radius, type)
	-- this is special case, it means the unit will not be built anyway
	if unitName == nil or unitName == SKIP_THIS_TASK then
		return unitName
	end
		
	local pos = self.ai.buildSiteHandler:getBuildSearchPos(self,UnitDefNames[unitName])
	if (pos ~= nil) then
		-- default radius is medium
		if ( radius  == nil ) then
		   radius = MED_RADIUS 
		end
		-- default type disregards similar units
		
		-- now check how many of the wanted unit or similar is nearby
		local NumberOfUnits = countOwnUnitsInRadius(self,unitName, pos, radius, unitLimit, type)
		local AllowBuilding = NumberOfUnits < unitLimit
		-- log(""..unitName.." wanted, with range limit of "..unitLimit..", with "..NumberOfUnits.." already there. The check is: "..tostring(AllowBuilding), self.ai)
		if AllowBuilding then
			return unitName
		else
			return SKIP_THIS_TASK
		end
	end
	return SKIP_THIS_TASK
end

local function areaLimit_Llt(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	return checkAreaLimit(self,lltByFaction[self.unitSide], self.unitId, 1, SML_RADIUS, nil)
	
end


local function areaLimit_LightAA(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	local unitName = lightAAByFaction[self.unitSide]

	return checkAreaLimit(self,unitName, self.unitId, 4, MED_RADIUS, TYPE_LIGHT_AA)
end



local function areaLimit_WaterLightAA(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	local unitName = waterLightAAByFaction[self.unitSide]

	return checkAreaLimit(self,unitName, self.unitId, 4, MED_RADIUS, TYPE_LIGHT_AA)
end


local function areaLimit_MediumAA(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	local unitName = mediumAAByFaction[self.unitSide]

	return checkAreaLimit(self,unitName, self.unitId, 2, MED_RADIUS, TYPE_LIGHT_AA)
end

local function areaLimit_WaterMediumAA(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	local unitName = waterMediumAAByFaction[self.unitSide]

	return checkAreaLimit(self,unitName, self.unitId, 2, MED_RADIUS, TYPE_LIGHT_AA)
end

local function areaLimit_L2HeavyDefense(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	--	if unit is far away from base center, skip construction
--	if farFromBaseCenter(self) then
--		return SKIP_THIS_TASK
--	end	
	
	local unitName = lev2HeavyDefenseByFaction[self.unitSide][ random( 1, tableLength(lev2HeavyDefenseByFaction[self.unitSide]) ) ]
	
	return checkAreaLimit(self,unitName, self.unitId, 1, MED_RADIUS, TYPE_HEAVY_DEFENSE)
end


local function areaLimit_WaterL2HeavyDefense(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	--	if unit is far away from base center, skip construction
--	if farFromBaseCenter(self) then
--		return SKIP_THIS_TASK
--	end	
	
	local unitName = lev2WaterHeavyDefenseByFaction[self.unitSide][ random( 1, tableLength(lev2WaterHeavyDefenseByFaction[self.unitSide]) ) ]
	
	return checkAreaLimit(self,unitName, self.unitId, 1, MED_RADIUS, TYPE_HEAVY_DEFENSE)
end


local function areaLimit_L2ArtilleryDefense(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	-- if unit is far away from base center, skip construction
--	if farFromBaseCenter(self) then
--		return SKIP_THIS_TASK
--	end	
	
	local unitName = lev2ArtilleryDefenseByFaction[self.unitSide][ random( 1, tableLength(lev2ArtilleryDefenseByFaction[self.unitSide]) ) ]
	
	return checkAreaLimit(self, unitName, self.unitId, 1, BIG_RADIUS, TYPE_ARTILLERY_DEFENSE)
end

local function areaLimit_L3HeavyAA(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	-- if unit is far away from base center, skip construction
--	if farFromBaseCenter(self) then
--		return SKIP_THIS_TASK
--	end	
--	if self.ai.unitHandler.threatType ~= THREAT_AIR then
--		return SKIP_THIS_TASK
--	end	
	
	local unitName = heavyAAByFaction[self.unitSide][ random( 1, tableLength(heavyAAByFaction[self.unitSide]) ) ]

	return checkAreaLimit(self, unitName, self.unitId, 1, BIG_RADIUS, TYPE_HEAVY_AA)
end




local function areaLimit_L3ArtilleryDefense(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	-- if unit is far away from base center, skip construction
--	if farFromBaseCenter(self) then
--		return SKIP_THIS_TASK
--	end	
	
	local unitName = lev3ArtilleryDefenseByFaction[self.unitSide][ random( 1, tableLength(lev3ArtilleryDefenseByFaction[self.unitSide]) ) ]

	return checkAreaLimit(self, unitName, self.unitId, 1, BIG_RADIUS, TYPE_ARTILLERY_DEFENSE)
end


local function areaLimit_L3LongRangeArtillery(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	local unitName = lev3LongRangeArtilleryByFaction[self.unitSide][ random( 1, tableLength(lev3LongRangeArtilleryByFaction[self.unitSide]) ) ]
	
	return buildWithMinimalMetalIncome(self, buildWithMinimalEnergyIncome(self, checkAreaLimit(self, unitName, self.unitId, 4, BIG_RADIUS, TYPE_LONG_RANGE_ARTILLERY),1000),40)
end



local function areaLimit_Radar(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	return checkAreaLimit(self,radarByFaction[self.unitSide], self.unitId, 1, BIG_RADIUS, nil)
	
end


local function areaLimit_WaterRadar(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	return checkAreaLimit(self,waterRadarByFaction[self.unitSide], self.unitId, 1, BIG_RADIUS, nil)
	
end

local function areaLimit_Sonar(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	return checkAreaLimit(self,sonarByFaction[self.unitSide], self.unitId, 1, BIG_RADIUS, nil)
	
end

local function areaLimit_AdvRadar(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	return checkAreaLimit(self,advRadarByFaction[self.unitSide], self.unitId, 1, BIG_RADIUS, nil)
	
end


local function areaLimit_Respawner(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	return checkAreaLimit(self,respawnerByFaction[self.unitSide], self.unitId, 1, BIG_RADIUS, nil)
	
end

local function airRepairPadIfNeeded(self)
	-- only make air pads if the team has air units
	-- TODO: air repair pads have been disabled
	if false and countOwnUnits(self,nil, 3, TYPE_AIR_ATTACKER) > 2 then
		return buildWithLimitedNumber(self,airRepairPadByFaction[self.unitSide], 5)
	end
	
	return SKIP_THIS_TASK
end

local function getChoice(choice)
	if (type(choice) == "table") then
		return choice[ random( 1, tableLength(choice)) ] 
	else
		return choice
	end	
end

local function choiceByType(self,airThreatChoice,defenseThreatChoice,normalThreatChoice,underWaterThreatChoice)
	if self.ai.unitHandler.threatType == THREAT_AIR then
		return getChoice(airThreatChoice)
	elseif self.ai.unitHandler.threatType == THREAT_DEFENSE then
		return getChoice(defenseThreatChoice)
	elseif underWaterThreatChoice~= nil and self.ai.unitHandler.threatType == THREAT_UNDERWATER then
		return getChoice(underwaterThreatChoice)		
	else
		return getChoice(normalThreatChoice)
	end
	return SKIP_THIS_TASK
end

------------------------------------ UPGRADES


--upgradePaths = {"offensive", "defensive", "defensive_regen", "speed", "mixed", "mixed_drones_utility", "mixed_drones_combat"}
upgradePathsByFaction = { [side1Name] = {"speed"}, [side2Name] = {"mixed","mixed_drones_utility","mixed_drones_combat"}, [side3Name] = {"offensive","mixed_drones_combat"}, [side4Name] = {"defensive","defensive_regen"}}
local function selectUpgradeCenterQueue(self)
	if (not self.ai.upgradePath) then
		self.ai.upgradePath = upgradePathsByFaction[self.unitSide][ random( 1, tableLength(upgradePathsByFaction[self.unitSide]) ) ]
	end
	
	if self.ai.upgradePath then
		self:ChangeQueue(upgradeQueueByPath[self.ai.upgradePath])
		--log("UPGRADES: "..self.ai.upgradePath.." "..type(upgradeQueueByPath[self.ai.upgradePath]),self.ai)
	end

	return SKIP_THIS_TASK
end



------------------------------- COMMON


local atkSupporter = {
	moveAtkCenter,
	{action = "wait", frames = 32}
}


local atkPatroller = {
	patrolAtkCenter,
	{action = "wait", frames = 32}
}


local respawner = {
	respawnIfNeeded,
	{action = "wait", frames = 38}
}


local upgradeCenter = {
	selectUpgradeCenterQueue,
	{action = "wait", frames = 38}
}

local upgradeOffensive = {
	"upgrade_red_1_damage",
	"upgrade_red_1_damage",
	"upgrade_red_1_range",
	"upgrade_red_1_range",
	"upgrade_red_1_range",
	"upgrade_red_2_commander_damage",
	"upgrade_red_2_commander_range",
	"upgrade_red_3_damage",
	{action = "wait", frames = 38}
}

local upgradeDefensive = {
	"upgrade_green_1_hp",
	"upgrade_green_1_hp",
	"upgrade_green_1_regen",
	"upgrade_green_1_hp",
	"upgrade_green_1_regen",
	"upgrade_green_2_commander_hp",
	"upgrade_green_2_commander_regen",
	"upgrade_green_3_hp",
	{action = "wait", frames = 38}
}

local upgradeDefensiveRegen = {
	"upgrade_green_1_regen",
	"upgrade_green_1_regen",
	"upgrade_green_1_regen",
	"upgrade_blue_1_speed",
	"upgrade_green_1_hp",
	"upgrade_green_2_commander_hp",
	"upgrade_green_2_commander_regen",
	"upgrade_green_3_regen",
	{action = "wait", frames = 38}
}

local upgradeSpeed = {
	"upgrade_blue_1_speed",
	"upgrade_blue_1_speed",
	"upgrade_blue_1_speed",
	"upgrade_green_1_regen",
	"upgrade_green_1_regen",
	"upgrade_blue_2_commander_speed",
	"upgrade_green_2_commander_regen",
	"upgrade_blue_3_speed",
	{action = "wait", frames = 38}
}

local upgradeMixed = {
	"upgrade_blue_1_speed",
	"upgrade_green_1_regen",
	"upgrade_blue_1_speed",
	"upgrade_blue_1_speed",
	"upgrade_green_1_hp",
	"upgrade_red_2_commander_damage",
	"upgrade_green_2_commander_hp",
	"upgrade_red_3_damage",
	{action = "wait", frames = 38}
}

local upgradeMixedDronesUtility = {
	"upgrade_blue_1_speed",
	"upgrade_green_1_regen",
	"upgrade_blue_1_speed",
	"upgrade_blue_1_speed",
	"upgrade_green_1_hp",
	"upgrade_blue_3_commander_stealth_drone",
	"upgrade_blue_3_commander_builder_drone",
	"upgrade_red_3_damage",
	{action = "wait", frames = 38}
}

local upgradeMixedDronesCombat = {
	"upgrade_blue_1_speed",
	"upgrade_green_1_regen",
	"upgrade_blue_1_speed",
	"upgrade_blue_1_speed",
	"upgrade_green_1_hp",
	"upgrade_blue_2_commander_light_drones",
	"upgrade_blue_3_commander_medium_drone",
	"upgrade_red_3_damage",
	{action = "wait", frames = 38}
}

------------------------------- AVEN

-- choices by threat type : AIR, DEFENSES, NORMAL[, UNDERWATER]

local function avenL2KbotChoice(self) return choiceByType(self,"aven_weaver",{"aven_knight","aven_bolter"},{"aven_bolter","aven_shocker","aven_dervish","aven_knight","aven_magnum","aven_raptor"}) end
local function avenL1LightChoice(self) return choiceByType(self,"aven_samson",{"aven_bold","aven_duster"},{"aven_samson","aven_trooper","aven_warrior"}) end
local function avenL2VehicleChoice(self) return choiceByType(self,{"aven_javelin","aven_kodiak"},{"aven_merl","aven_centurion"},{"aven_centurion","aven_kodiak"}) end
local function avenL2AirChoice(self) return choiceByType(self,"aven_falcon",{"aven_gryphon", "aven_talon"},{"aven_gryphon","aven_falcon","aven_icarus"},"aven_albatross") end
local function avenL2KbotRadar(self) return buildWithLimitedNumber(self,"aven_marky",1) end
local function avenL2KbotRadarJammer(self) return buildWithLimitedNumber(self,"aven_eraser",1) end
local function avenL2VehicleRadar(self) return buildWithLimitedNumber(self,"aven_seer",1) end
local function avenL2VehicleRadarJammer(self) return buildWithLimitedNumber(self,"aven_jammer",1) end
local function avenL1ShipChoice(self) return choiceByType(self,{"aven_skeeter","aven_vanguard"},"aven_crusader",{"aven_skeeter","aven_vanguard"},"aven_lurker") end
local function avenL2ShipChoice(self) return choiceByType(self,"aven_fletcher",{"aven_conqueror","aven_emperor"},{"aven_conqueror","aven_piranha","aven_fletcher"},"aven_piranha") end


local avenCommander = {
	brutalPlant,
	brutalAirPlant,
	brutalLightDefense,
	brutalAADefense,
	brutalHeavyDefense,
	changeQueueToCommanderAttackerIfNeeded,
	moveBaseCenter,
	checkMorph,
	changeQueueToWaterCommanderIfNeeded,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	windSolarIfNeeded,
	areaLimit_Llt,
	windSolarIfNeeded,
	windSolarIfNeeded,
	windSolarIfNeeded,
	lvl1PlantIfNeeded,
	areaLimit_Respawner,
	areaLimit_Llt,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	changeQueueToCommanderAttackerIfNeeded,	
	changeQueueToWaterCommanderIfNeeded,
	windSolarIfNeeded,
	windSolarIfNeeded,
	windSolarIfNeeded,
	windSolarIfNeeded,
	areaLimit_Radar,
	lvl2PlantIfNeeded,
	upgradeCenterIfNeeded,
	changeQueueToCommanderAttackerIfNeeded
}


local avenWaterCommander = {
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	tidalIfNeeded,
	areaLimit_WaterLlt,
	tidalIfNeeded,
	areaLimit_Respawner,
	areaLimit_WaterLlt,	
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	areaLimit_WaterRadar,		
	lvl1ShipyardIfNeeded,
	briefAreaPatrol,
	areaLimit_Llt,
	storageIfNeeded,
	storageIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	areaLimit_Respawner,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	changeQueueToCommanderAttackerIfNeeded,
	lvl2ShipyardIfNeeded,
	briefAreaPatrol,
	upgradeCenterIfNeeded,
	restoreQueue
}

local avenUCommander = {
	checkMorph,
	changeQueueToCommanderBaseBuilderIfNeeded,
	metalExtractorNearbyIfSafe,
	patrolAtkCenter
}

local avenLev1Con = {
	exitPlant,
	metalExtractorNearbyIfSafe,
	windSolarIfNeeded,
	moveBaseCenter,
	areaLimit_Respawner,
	changeQueueToMexBuilderIfNeeded,
	basePatrolIfNeeded,
	changeQueueToDefenseBuilderIfNeeded,
	patrolAtkCenterIfNeeded,
	assistOtherBuilderIfNeeded,
	windSolarIfNeeded,
	metalExtractorNearbyIfSafe,
	areaLimit_L2HeavyDefense,
	areaLimit_LightAA,
	windSolarIfNeeded,
	windSolarIfNeeded,
	windSolarIfNeeded,
	lvl2PlantIfNeeded,
	lvl1PlantIfNeeded,
	upgradeCenterIfNeeded,
	metalExtractorNearbyIfSafe,
	briefAreaPatrol,
	areaLimit_L2ArtilleryDefense,
	storageIfNeeded,
	areaLimit_LightAA,
	lvl2PlantIfNeeded,
	lvl1PlantIfNeeded,
	briefAreaPatrol,
	windSolarIfNeeded,
	areaLimit_L2HeavyDefense,
	windSolarIfNeeded,
	areaLimit_L2ArtilleryDefense,
	areaLimit_Radar,
	windSolarIfNeeded,
	storageIfNeeded,
	geoIfNeeded,
	areaLimit_Respawner,	
	moveBaseCenter
}


local avenLev1WaterCon = {
	exitPlant,
	setWaterMode,
	metalExtractorNearbyIfSafe,
	changeQueueToWaterMexBuilderIfNeeded,
	basePatrolIfNeeded,
	tidalIfNeeded,
	metalExtractorNearbyIfSafe,
	areaLimit_WaterL2HeavyDefense,
	areaLimit_WaterLightAA,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	lvl1WaterPlantIfNeeded,
	lvl2WaterPlantIfNeeded,
	upgradeCenterIfNeeded,	
	briefAreaPatrol,
	metalExtractorNearbyIfSafe,
	storageIfNeeded,
	geoIfNeeded,
	areaLimit_LightAA,
	areaLimit_Respawner,	
	moveBaseCenter
}

local avenMexBuilder = {
	"aven_metal_extractor",
	"aven_metal_extractor",
	areaLimit_LightAA,
	"aven_metal_extractor",
	areaLimit_LightAA,
	"aven_metal_extractor",
	"aven_metal_extractor",
	"aven_metal_extractor",
	areaLimit_LightAA,
	areaLimit_Radar,
	windSolarIfNeeded,
	restoreQueue	
}

local avenWaterMexBuilder = {
	setWaterMode,
	"aven_underwater_metal_extractor",
	"aven_underwater_metal_extractor",
	areaLimit_WaterLightAA,
	{action = "cleanup", frames = 128},
	"aven_underwater_metal_extractor",
	areaLimit_WaterLightAA,
	"aven_underwater_metal_extractor",
	areaLimit_WaterLightAA,
	areaLimit_WaterRadar,
	tidalIfNeeded,
	restoreQueue
}


local avenLev1DefenseBuilder = {
	moveVulnerablePos,
	areaLimit_LightAA,
	areaLimit_Radar,
	areaLimit_L2HeavyDefense,
	areaLimit_LightAA,
	windSolarIfNeeded,
	areaLimit_L2ArtilleryDefense,
	restoreQueue
}


local avenLev2Con = {
	exitPlant,
	brutalFusion,
	airRepairPadIfNeeded,
	changeQueueToMexUpgraderIfNeeded,
	changeQueueToAdvancedDefenseBuilderIfNeeded,
	moveSafePos,
	fusionIfNeeded,
	lvl1PlantIfNeeded,
	lvl2PlantIfNeeded,
	upgradeCenterIfNeeded,
	areaLimit_L3HeavyAA,
	areaLimit_AdvRadar,
	areaLimit_L3ArtilleryDefense,
	moveVulnerablePos,
	areaLimit_L3LongRangeArtillery,
	airRepairPadIfNeeded,
	{action = "cleanup", frames = 128},
	moveBaseCenter	
}

local avenMexUpgrader = {
	moveSafePos,
	reclaimNearestMexIfNeeded,
	mohoIfMexReclaimed,
	reclaimNearestMexIfNeeded,
	mohoIfMexReclaimed,
	moveSafePos,
	reclaimNearestMexIfNeeded,
	mohoIfMexReclaimed,
	reclaimNearestMexIfNeeded,
	mohoIfMexReclaimed,	
	restoreQueue
}

local avenLev2DefenseBuilder = {
	moveVulnerablePos,
	areaLimit_AdvRadar,	
	areaLimit_L3HeavyAA,
	areaLimit_L3ArtilleryDefense,
	areaLimit_L3HeavyAA,
	areaLimit_L3LongRangeArtillery,
	restoreQueue	
}

local avenLightPlant = {
	"aven_samson",
	"aven_construction_kbot",
	{action = "randomness", probability = 0.5, value = "aven_construction_kbot"},
	avenL1LightChoice,
	avenL1LightChoice,
	avenL1LightChoice,
	"aven_trooper",
	"aven_bold",
	{action = "randomness", probability = 0.25, value = "aven_trooper"},
	{action = "randomness", probability = 0.25, value = "aven_warrior"},
	"aven_duster",
	{action = "wait", frames = 128}
}

local avenAircraftPlant = {
	"aven_swift",
	"aven_construction_aircraft",
	{action = "randomness", probability = 0.3, value = "aven_construction_aircraft"},
	"aven_swift",
	"aven_tornado",
	"aven_swift",
	"aven_twister",
	"aven_swift",
	{action = "wait", frames = 128}
}

local avenShipPlant = {
	"aven_skeeter",
	"aven_construction_ship",
	avenL1ShipChoice,
	avenL1ShipChoice,
	avenL1ShipChoice,
	{action = "wait", frames = 128}
}

local avenAdvAircraftPlant = {
	"aven_falcon",
	"aven_adv_construction_aircraft",
	avenL2AirChoice,
	avenL2AirChoice,
	avenL2AirChoice,
	"aven_falcon",
	"aven_gryphon",
	"aven_icarus",
	zephyrIfNeeded,
	{action = "wait", frames = 128}
}

local avenAdvKbotLab = {
	"aven_stalker",
	"aven_adv_construction_kbot",
	"aven_knight",
	avenL2KbotChoice,
	avenL2KbotChoice,
	avenL2KbotChoice,
	"aven_bolter",
	"aven_weaver",
	avenL2KbotRadar,
	avenL2KbotRadarJammer,
	"aven_shooter",
	{action = "wait", frames = 128}
}

local avenAdvVehiclePlant = {
	"aven_javelin",
	"aven_adv_construction_vehicle",
	"aven_kodiak",
	avenL2VehicleChoice,
	avenL2VehicleChoice,
	avenL2VehicleChoice,
	"aven_centurion",
	"aven_merl",	
	avenL2VehicleRadar,
	avenL2VehicleRadarJammer,
	"aven_penetrator",
	{action = "wait", frames = 128}
}


local avenAdvShipPlant = {
	"aven_piranha",
	"aven_adv_construction_sub",
	avenL2ShipChoice,
	avenL2ShipChoice,
	avenL2ShipChoice,
	{action = "wait", frames = 128}
}




------------------------------- GEAR

-- choices by threat type : AIR, DEFENSES, NORMAL[, UNDERWATER]

local function gearL2KbotChoice(self) return choiceByType(self,{"gear_titan","gear_barrel"},{"gear_big_bob","gear_moe"},{"gear_big_bob","gear_pyro","gear_moe","gear_psycho","gear_titan","gear_barrel"}) end
local function gearL1LightChoice(self) return choiceByType(self,"gear_crasher",{"gear_raider","gear_kano","gear_thud"},{"gear_crasher","gear_kano","gear_box","gear_instigator","gear_aggressor"}) end
local function gearL2VehicleChoice(self) return choiceByType(self,"gear_marauder",{"gear_mobile_artillery","gear_reaper","gear_eruptor"},{"gear_reaper","gear_marauder","gear_crock","gear_flareon"}) end
local function gearL2AirChoice(self) return choiceByType(self,"gear_vector",{"gear_stratos","gear_firestorm"},{"gear_vector","gear_stratos","gear_firestorm"},"gear_whirlpool") end
local function gearL2KbotRadar(self) return buildWithLimitedNumber(self,"gear_voyeur",1) end
local function gearL2KbotRadarJammer(self) return buildWithLimitedNumber(self,"gear_spectre",1) end
local function gearL2VehicleRadar(self) return buildWithLimitedNumber(self,"gear_informer",1) end
local function gearL2VehicleRadarJammer(self) return buildWithLimitedNumber(self,"gear_deleter",1) end
local function gearL1ShipChoice(self) return choiceByType(self,{"gear_searcher","gear_viking"},"gear_enforcer",{"gear_searcher","gear_viking"},"gear_snake") end
local function gearL2ShipChoice(self) return choiceByType(self,"gear_shredder",{"gear_executioner","gear_edge"},{"gear_executioner","gear_noser"},"gear_noser") end


local gearCommander = {
	brutalPlant,
	brutalAirPlant,	
	brutalLightDefense,
	brutalAADefense,
	brutalHeavyDefense,
	changeQueueToCommanderAttackerIfNeeded,
	moveBaseCenter,
	checkMorph,
	changeQueueToWaterCommanderIfNeeded,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	windSolarIfNeeded,
	areaLimit_Llt,
	windSolarIfNeeded,
	windSolarIfNeeded,	
	windSolarIfNeeded,	
	lvl1PlantIfNeeded,
	areaLimit_Respawner,
	areaLimit_Llt,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	changeQueueToCommanderAttackerIfNeeded,
	changeQueueToWaterCommanderIfNeeded,
	windSolarIfNeeded,
	windSolarIfNeeded,
	windSolarIfNeeded,
	windSolarIfNeeded,
	areaLimit_Radar,		
	lvl2PlantIfNeeded,
	upgradeCenterIfNeeded,
	changeQueueToCommanderAttackerIfNeeded
}


local coreWaterCommander = {
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	tidalIfNeeded,
	areaLimit_WaterLlt,
	tidalIfNeeded,
	areaLimit_Respawner,	
	areaLimit_WaterLlt,	
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	areaLimit_WaterRadar,		
	lvl1ShipyardIfNeeded,
	briefAreaPatrol,
	areaLimit_Llt,
	storageIfNeeded,
	storageIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	areaLimit_Respawner,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	changeQueueToCommanderAttackerIfNeeded,
	lvl2ShipyardIfNeeded,
	briefAreaPatrol,
	upgradeCenterIfNeeded,
	restoreQueue
}

local gearUCommander = {
	checkMorph,
	changeQueueToCommanderBaseBuilderIfNeeded,
	metalExtractorNearbyIfSafe,
	patrolAtkCenter
}

local gearLev1Con = {
	exitPlant,
	metalExtractorNearbyIfSafe,
	windSolarIfNeeded,
	moveBaseCenter,
	areaLimit_Respawner,	
	changeQueueToMexBuilderIfNeeded,
	basePatrolIfNeeded,
	changeQueueToDefenseBuilderIfNeeded,
	patrolAtkCenterIfNeeded,
	assistOtherBuilderIfNeeded,
	windSolarIfNeeded,
	metalExtractorNearbyIfSafe,
	areaLimit_L2HeavyDefense,
	areaLimit_LightAA,
	windSolarIfNeeded,
	windSolarIfNeeded,
	windSolarIfNeeded,
	lvl2PlantIfNeeded,
	lvl1PlantIfNeeded,
	upgradeCenterIfNeeded,
	metalExtractorNearbyIfSafe,
	briefAreaPatrol,
	areaLimit_L2ArtilleryDefense,
	storageIfNeeded,
	areaLimit_LightAA,
	lvl2PlantIfNeeded,
	lvl1PlantIfNeeded,
	briefAreaPatrol,
	windSolarIfNeeded,
	areaLimit_L2HeavyDefense,
	windSolarIfNeeded,
	areaLimit_L2ArtilleryDefense,
	areaLimit_Radar,
	geoIfNeeded,
	windSolarIfNeeded,
	storageIfNeeded,
	areaLimit_Respawner,	
	moveBaseCenter
}


local gearLev1WaterCon = {
	exitPlant,
	setWaterMode,
	metalExtractorNearbyIfSafe,
	changeQueueToWaterMexBuilderIfNeeded,
	basePatrolIfNeeded,
	tidalIfNeeded,
	metalExtractorNearbyIfSafe,
	areaLimit_WaterL2HeavyDefense,
	areaLimit_WaterLightAA,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	lvl1WaterPlantIfNeeded,
	lvl2WaterPlantIfNeeded,
	upgradeCenterIfNeeded,
	metalExtractorNearbyIfSafe,
	briefAreaPatrol,
	areaLimit_L2ArtilleryDefense,
	storageIfNeeded,
	areaLimit_LightAA,
	lvl1PlantIfNeeded,
	lvl2PlantIfNeeded,
	briefAreaPatrol,
	windSolarIfNeeded,
	areaLimit_L2HeavyDefense,
	windSolarIfNeeded,
	areaLimit_L2ArtilleryDefense,
	areaLimit_Radar,
	geoIfNeeded,
	windSolarIfNeeded,
	storageIfNeeded,
	areaLimit_Respawner,	
	moveBaseCenter
}

local coreMexBuilder = {
	"gear_metal_extractor",
	"gear_metal_extractor",
	areaLimit_LightAA,
	"gear_metal_extractor",
	areaLimit_LightAA,
	"gear_metal_extractor",
	"gear_metal_extractor",
	"gear_metal_extractor",
	areaLimit_LightAA,
	areaLimit_Radar,
	windSolarIfNeeded,
	restoreQueue
}

local coreWaterMexBuilder = {
	setWaterMode,
	"gear_underwater_metal_extractor",
	"gear_underwater_metal_extractor",
	areaLimit_WaterLightAA,
	"gear_underwater_metal_extractor",
	areaLimit_WaterLightAA,
	"gear_underwater_metal_extractor",
	areaLimit_WaterLightAA,
	areaLimit_WaterRadar,
	tidalIfNeeded,
	restoreQueue
}


local gearLev1DefenseBuilder = {
	moveVulnerablePos,
	areaLimit_LightAA,
	areaLimit_Radar,
	areaLimit_L2HeavyDefense,
	areaLimit_LightAA,
	windSolarIfNeeded,
	areaLimit_L2ArtilleryDefense,
	restoreQueue
}


local gearLev2Con = {
	exitPlant,
	brutalFusion,
	airRepairPadIfNeeded,
	changeQueueToMexUpgraderIfNeeded,
	changeQueueToAdvancedDefenseBuilderIfNeeded,
	moveSafePos,
	fusionIfNeeded,
	lvl1PlantIfNeeded,
	lvl2PlantIfNeeded,
	upgradeCenterIfNeeded,
	areaLimit_L3HeavyAA,
	areaLimit_AdvRadar,
	areaLimit_L3ArtilleryDefense,
	moveVulnerablePos,
	areaLimit_L3LongRangeArtillery,
	airRepairPadIfNeeded,
	{action = "cleanup", frames = 128},
	moveBaseCenter
}

local coreMexUpgrader = {
	moveSafePos,
	reclaimNearestMexIfNeeded,
	mohoIfMexReclaimed,
	reclaimNearestMexIfNeeded,
	mohoIfMexReclaimed,
	moveSafePos,
	reclaimNearestMexIfNeeded,
	mohoIfMexReclaimed,
	reclaimNearestMexIfNeeded,
	mohoIfMexReclaimed,	
	restoreQueue
}

local gearLev2DefenseBuilder = {
	moveVulnerablePos,
	areaLimit_AdvRadar,	
	areaLimit_L3HeavyAA,
	areaLimit_L3ArtilleryDefense,
	areaLimit_L3HeavyAA,
	areaLimit_L3LongRangeArtillery,
	restoreQueue	
}

local gearLightPlant = {
	"gear_aggressor",
	"gear_construction_kbot",
	{action = "randomness", probability = 0.5, value = "gear_construction_kbot"},	
	gearL1LightChoice,
	gearL1LightChoice,
	gearL1LightChoice,
	"gear_instigator",
	"gear_raider",	
	"gear_kano",
	"gear_canister",
	{action = "wait", frames = 128}
}

local gearAircraftPlant = {
	"gear_dash",
	"gear_construction_aircraft",
	{action = "randomness", probability = 0.3, value = "gear_construction_aircraft"},	
	"gear_dash",
	"gear_zipper",
	"gear_dash",
	"gear_knocker",
	"gear_dash",
	{action = "wait", frames = 128}
}

local gearShipPlant = {
	"gear_searcher",
	"gear_construction_ship",
	gearL1ShipChoice,
	gearL1ShipChoice,
	gearL1ShipChoice,
	{action = "wait", frames = 128}
}

local gearAdvAircraftPlant = {
	"gear_vector",
	"gear_adv_construction_aircraft",
	gearL2AirChoice,
	gearL2AirChoice,
	gearL2AirChoice,
	"gear_vector",
	"gear_firestorm",
	"gear_stratos",
	{action = "wait", frames = 128}
}

local gearAdvKbotLab = {
	"gear_moe",
	"gear_adv_construction_kbot",
	"gear_cube",
	gearL2KbotChoice,
	gearL2KbotChoice,
	gearL2KbotChoice,
	"gear_moe",
	"gear_big_bob",	
	gearL2KbotRadar,
	gearL2KbotRadarJammer,
	"gear_titan",
	{action = "wait", frames = 128}
}

local gearAdvVehiclePlant = {
	"gear_marauder",
	"gear_adv_construction_vehicle",
	gearL2VehicleChoice,
	gearL2VehicleChoice,
	gearL2VehicleChoice,
	"gear_reaper",
	"gear_mobile_artillery",	
	gearL2VehicleRadar,
	"gear_eruptor",
	gearL2VehicleRadarJammer,
	"gear_tremor",	
	{action = "wait", frames = 128}
}


local gearAdvShipPlant = {
	"gear_noser",
	"gear_adv_construction_sub",
	gearL2ShipChoice,
	gearL2ShipChoice,
	gearL2ShipChoice,
	{action = "wait", frames = 128}
}


------------------------------- CLAW

-- choices by threat type : AIR, DEFENSES, NORMAL[, UNDERWATER]

local function clawL1LandChoice(self) return choiceByType(self,"claw_jester",{"claw_grunt","claw_piston","claw_roller"},{"claw_grunt","claw_boar","claw_piston","claw_roller"}) end
local function clawL2KbotChoice(self) return choiceByType(self,"claw_bishop",{"claw_shrieker","claw_brute","claw_crawler"},{"claw_centaur","claw_brute"}) end
local function clawL2VehicleChoice(self) return choiceByType(self,"claw_ravager",{"claw_pounder","claw_armadon"},{"claw_halberd","claw_ravager","claw_mega"}) end
local function clawL2AirChoice(self) return choiceByType(self,"claw_x","claw_blizzard",{"claw_x","claw_blizzard"},"claw_trident") end
local function clawL2KbotRadar(self) return buildWithLimitedNumber(self,"claw_revealer",1) end
local function clawL2KbotRadarJammer(self) return buildWithLimitedNumber(self,"claw_shade",1) end
local function clawL2VehicleRadar(self) return buildWithLimitedNumber(self,"claw_seer",1) end
local function clawL2VehicleRadarJammer(self) return buildWithLimitedNumber(self,"claw_jammer",1) end
local function clawL1ShipChoice(self) return choiceByType(self,{"claw_speeder","claw_striker"},"claw_sword",{"claw_speeder","claw_striker"},"claw_spine") end
local function clawL2ShipChoice(self) return choiceByType(self,"claw_predator",{"claw_maul","claw_wrecker"},{"claw_drakkar","claw_monster"},"claw_monster") end


local clawCommander = {
	brutalPlant,
	brutalAirPlant,	
	brutalLightDefense,
	brutalAADefense,
	brutalHeavyDefense,
	changeQueueToCommanderAttackerIfNeeded,
	moveBaseCenter,
	checkMorph,
	changeQueueToWaterCommanderIfNeeded,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	windSolarIfNeeded,
	areaLimit_Llt,
	windSolarIfNeeded,
	windSolarIfNeeded,
	windSolarIfNeeded,
	lvl1PlantIfNeeded,
	areaLimit_Respawner,
	areaLimit_Llt,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	changeQueueToCommanderAttackerIfNeeded,
	changeQueueToWaterCommanderIfNeeded,
	windSolarIfNeeded,
	windSolarIfNeeded,
	windSolarIfNeeded,
	areaLimit_Radar,
	lvl2PlantIfNeeded,
	upgradeCenterIfNeeded,
	changeQueueToCommanderAttackerIfNeeded
}


local clawWaterCommander = {
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	tidalIfNeeded,
	areaLimit_WaterLlt,
	tidalIfNeeded,
	areaLimit_Respawner,	
	areaLimit_WaterLlt,	
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	areaLimit_WaterRadar,		
	lvl1ShipyardIfNeeded,
	briefAreaPatrol,
	areaLimit_WaterLlt,
	storageIfNeeded,
	storageIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	areaLimit_Respawner,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	changeQueueToCommanderAttackerIfNeeded,
	lvl2ShipyardIfNeeded,
	briefAreaPatrol,
	upgradeCenterIfNeeded,
	restoreQueue
}

local clawUCommander = {
	checkMorph,
	changeQueueToCommanderBaseBuilderIfNeeded,
	metalExtractorNearbyIfSafe,
	patrolAtkCenter
}

local atkSupporter = {
	moveAtkCenter,
	{action = "wait", frames = 32}
}

local clawLev1Con = {
	exitPlant,
	metalExtractorNearbyIfSafe,
	windSolarIfNeeded,
	moveBaseCenter,
	areaLimit_Respawner,
	changeQueueToMexBuilderIfNeeded,
	basePatrolIfNeeded,
	changeQueueToDefenseBuilderIfNeeded,
	patrolAtkCenterIfNeeded,
	assistOtherBuilderIfNeeded,
	windSolarIfNeeded,
	metalExtractorNearbyIfSafe,
	areaLimit_L2HeavyDefense,
	areaLimit_MediumAA,
	windSolarIfNeeded,
	windSolarIfNeeded,
	windSolarIfNeeded,
	lvl2PlantIfNeeded,
	lvl1PlantIfNeeded,
	upgradeCenterIfNeeded,
	metalExtractorNearbyIfSafe,
	briefAreaPatrol,
	areaLimit_L2ArtilleryDefense,
	storageIfNeeded,
	areaLimit_MediumAA,
	lvl2PlantIfNeeded,
	lvl1PlantIfNeeded,
	briefAreaPatrol,
	windSolarIfNeeded,
	areaLimit_L2HeavyDefense,
	windSolarIfNeeded,
	areaLimit_L2ArtilleryDefense,
	areaLimit_Radar,
	geoIfNeeded,
	windSolarIfNeeded,
	storageIfNeeded,
	areaLimit_Respawner,	
	moveBaseCenter
}


local clawLev1WaterCon = {
	exitPlant,
	setWaterMode,
	metalExtractorNearbyIfSafe,
	changeQueueToWaterMexBuilderIfNeeded,
	basePatrolIfNeeded,
	tidalIfNeeded,
	metalExtractorNearbyIfSafe,
	areaLimit_WaterL2HeavyDefense,
	areaLimit_WaterMediumAA,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	lvl1WaterPlantIfNeeded,
	lvl2WaterPlantIfNeeded,
	upgradeCenterIfNeeded,
	metalExtractorNearbyIfSafe,
	briefAreaPatrol,
	areaLimit_L2ArtilleryDefense,
	storageIfNeeded,
	areaLimit_MediumAA,
	geoIfNeeded,
	lvl1PlantIfNeeded,
	lvl2PlantIfNeeded,
	briefAreaPatrol,
	storageIfNeeded,
	areaLimit_Respawner,	
	moveBaseCenter
}

local clawMexBuilder = {
	"claw_metal_extractor",
	"claw_metal_extractor",
	"claw_metal_extractor",
	"claw_metal_extractor",
	areaLimit_MediumAA,
	"claw_metal_extractor",
	"claw_metal_extractor",
	"claw_metal_extractor",
	"claw_metal_extractor",
	areaLimit_MediumAA,
	areaLimit_Radar,
	restoreQueue
}

local clawWaterMexBuilder = {
	setWaterMode,
	"claw_metal_extractor",
	"claw_metal_extractor",
	"claw_metal_extractor",
	"claw_metal_extractor",
	areaLimit_WaterMediumAA,
	"claw_metal_extractor",
	"claw_metal_extractor",
	"claw_metal_extractor",
	"claw_metal_extractor",
	areaLimit_WaterMediumAA,	
	areaLimit_WaterRadar,
	tidalIfNeeded,
	restoreQueue
}


local clawLev1DefenseBuilder = {
	moveVulnerablePos,
	areaLimit_Radar,
	areaLimit_MediumAA,
	areaLimit_L2ArtilleryDefense,
	areaLimit_L2HeavyDefense,
	areaLimit_MediumAA,
	windSolarIfNeeded,
	restoreQueue
}


local clawLev2Con = {
	exitPlant,
	brutalFusion,
	airRepairPadIfNeeded,
	changeQueueToMexUpgraderIfNeeded,
	changeQueueToAdvancedDefenseBuilderIfNeeded,
	moveSafePos,
	fusionIfNeeded,
	lvl1PlantIfNeeded,
	lvl2PlantIfNeeded,
	upgradeCenterIfNeeded,
	areaLimit_L3HeavyAA,
	areaLimit_AdvRadar,	
	areaLimit_L3ArtilleryDefense,
	moveVulnerablePos,
	areaLimit_L3LongRangeArtillery,
	airRepairPadIfNeeded,
	{action = "cleanup", frames = 128},
	moveBaseCenter
}

local clawMexUpgrader = {
	moveSafePos,
	reclaimNearestMexIfNeeded,
	mohoIfMexReclaimed,
	reclaimNearestMexIfNeeded,
	mohoIfMexReclaimed,
	moveSafePos,
	reclaimNearestMexIfNeeded,
	mohoIfMexReclaimed,
	reclaimNearestMexIfNeeded,
	mohoIfMexReclaimed,
	restoreQueue
}

local clawLev2DefenseBuilder = {
	moveVulnerablePos,
	areaLimit_AdvRadar,
	areaLimit_L3HeavyAA,
	areaLimit_L3ArtilleryDefense,
	areaLimit_L3HeavyAA,
	areaLimit_L3LongRangeArtillery,
	restoreQueue	
}

local clawPlant = {
	"claw_jester",
	"claw_construction_kbot",
	{action = "randomness", probability = 0.5, value = "claw_construction_kbot"},
	clawL1LandChoice,
	clawL1LandChoice,
	clawL1LandChoice,
	"claw_roller",
	"claw_grunt",
	"claw_boar",
	{action = "wait", frames = 128}
}


local clawAircraftPlant = {
	"claw_hornet",
	"claw_construction_aircraft",
	{action = "randomness", probability = 0.3, value = "claw_construction_aircraft"},
	"claw_hornet",
	"claw_boomer",
	"claw_hornet",
	"claw_boomer_m",
	"claw_hornet",
	{action = "wait", frames = 128}
}

local clawShipPlant = {
	"claw_speeder",
	"claw_construction_ship",
	clawL1ShipChoice,
	clawL1ShipChoice,
	clawL1ShipChoice,
	{action = "wait", frames = 128}
}

local clawAdvAircraftPlant = {
	"claw_x",
	"claw_adv_construction_aircraft",
	clawL2AirChoice,
	clawL2AirChoice,
	clawL2AirChoice,
	"claw_x",
	"claw_blizzard",
	"claw_x",
	{action = "randomness", probability = 0.3, value = "claw_havoc"},
	{action = "wait", frames = 128}
}

local clawAdvKbotLab = {
	"claw_centaur",
	"claw_adv_construction_kbot",
	"claw_brute",
	clawL2KbotChoice,
	clawL2KbotChoice,
	clawL2KbotChoice,
	"claw_nucleus",
	"claw_bishop",	
	clawL2KbotRadar,
	clawL2KbotRadarJammer,
	"claw_shrieker",
	{action = "wait", frames = 128}
}

local clawAdvVehiclePlant = {
	"claw_ravager",
	"claw_adv_construction_vehicle",
	"claw_ravager",
	clawL2VehicleChoice,
	clawL2VehicleChoice,
	clawL2VehicleChoice,
	"claw_halberd",
	"claw_pounder",	
	clawL2VehicleRadar,
	clawL2VehicleRadarJammer,
	"claw_armadon",	
	{action = "wait", frames = 128}
}

local clawAdvShipPlant = {
	"claw_monster",
	"claw_adv_construction_ship",
	clawL2ShipChoice,
	clawL2ShipChoice,
	clawL2ShipChoice,
	{action = "wait", frames = 128}
}



------------------------------- SPHERE


-- choices by threat type : AIR, DEFENSES, NORMAL[, UNDERWATER]

local function sphereL1LandChoice(self) return choiceByType(self,"sphere_needles","sphere_rock",{"sphere_bit","sphere_rock"}) end
local function sphereL2KbotChoice(self) return choiceByType(self,{"sphere_chub","sphere_chub","sphere_hermit"},{"sphere_ark","sphere_hanz"},{"sphere_hanz","sphere_chub"}) end
local function sphereL2VehicleChoice(self) return choiceByType(self,"sphere_pulsar",{"sphere_slammer","sphere_bulk"},{"sphere_pulsar","sphere_trax","sphere_bulk"}) end
local function sphereL2AirChoice(self) return choiceByType(self,"sphere_twilight","sphere_meteor",{"sphere_meteor","sphere_spitfire","sphere_twilight"},"sphere_neptune") end
local function sphereL2KbotRadar(self) return buildWithLimitedNumber(self,"sphere_sensor",1) end
local function sphereL2KbotRadarJammer(self) return buildWithLimitedNumber(self,"sphere_rain",2) end
local function sphereL2VehicleRadar(self) return buildWithLimitedNumber(self,"sphere_scanner",1) end
local function sphereL2VehicleRadarJammer(self) return buildWithLimitedNumber(self,"sphere_concealer",2) end
local function sphereL1ShipChoice(self) return choiceByType(self,"sphere_reacher","sphere_endeavour",{"sphere_skiff","sphere_endeavour"},"sphere_carp") end
local function sphereL2ShipChoice(self) return choiceByType(self,"sphere_stalwart",{"sphere_stalwart"},{"sphere_helix","sphere_pluto"},"sphere_pluto") end


local sphereCommander = {
	brutalPlant,
	brutalAirPlant,	
	brutalLightDefense,
	brutalAADefense,
	brutalHeavyDefense,
	changeQueueToCommanderAttackerIfNeeded,
	moveBaseCenter,
	checkMorph,
	changeQueueToWaterCommanderIfNeeded,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	areaLimit_Llt,
	roughFusionIfNeeded,
	lvl1PlantIfNeeded,
	areaLimit_Respawner,
	areaLimit_Llt,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	changeQueueToCommanderAttackerIfNeeded,	
	changeQueueToWaterCommanderIfNeeded,
	areaLimit_Radar,		
	lvl2PlantIfNeeded,
	upgradeCenterIfNeeded,
	changeQueueToCommanderAttackerIfNeeded
}


local sphereWaterCommander = {
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	tidalIfNeeded,
	areaLimit_WaterLlt,
	tidalIfNeeded,
	areaLimit_Respawner,	
	areaLimit_WaterLlt,	
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	areaLimit_WaterRadar,		
	lvl1ShipyardIfNeeded,
	briefAreaPatrol,
	areaLimit_WaterLlt,
	storageIfNeeded,
	storageIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	areaLimit_Respawner,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	changeQueueToCommanderAttackerIfNeeded,
	lvl2ShipyardIfNeeded,
	briefAreaPatrol,
	upgradeCenterIfNeeded,
	restoreQueue
}

local sphereUCommander = {
	checkMorph,
	changeQueueToCommanderBaseBuilderIfNeeded,
	metalExtractorNearbyIfSafe,
	patrolAtkCenter
}

local atkSupporter = {
	moveAtkCenter,
	{action = "wait", frames = 32}
}

local sphereLev1Con = {
	exitPlant,
	metalExtractorNearbyIfSafe,
	moveBaseCenter,
	areaLimit_Respawner,
	roughFusionIfNeeded,	
	changeQueueToMexBuilderIfNeeded,
	basePatrolIfNeeded,
	changeQueueToDefenseBuilderIfNeeded,
	patrolAtkCenterIfNeeded,
	assistOtherBuilderIfNeeded,
	areaLimit_Radar,	
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	moveSafePos,
	roughFusionIfNeeded,
	roughFusionIfNeeded,
	storageIfNeeded,
	storageIfNeeded,
	areaLimit_MediumAA,	
	moveBaseCenter,
	areaLimit_L2ArtilleryDefense,
	lvl2PlantIfNeeded,
	lvl1PlantIfNeeded,
	upgradeCenterIfNeeded,
	areaLimit_Respawner,
	areaLimit_L2HeavyDefense,
	areaLimit_MediumAA,
	areaLimit_L2ArtilleryDefense,
	geoIfNeeded,
	areaLimit_MediumAA,
	briefAreaPatrol,
	roughFusionIfNeeded,
}


local sphereLev1WaterCon = {
	exitPlant,
	setWaterMode,
	metalExtractorNearbyIfSafe,
	changeQueueToWaterMexBuilderIfNeeded,
	basePatrolIfNeeded,
	tidalIfNeeded,
	metalExtractorNearbyIfSafe,
	areaLimit_WaterMediumAA,
	geoIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	lvl1WaterPlantIfNeeded,
	lvl2WaterPlantIfNeeded,
	upgradeCenterIfNeeded,
	metalExtractorNearbyIfSafe,
	briefAreaPatrol,
	areaLimit_L2ArtilleryDefense,
	storageIfNeeded,
	areaLimit_MediumAA,
	lvl1PlantIfNeeded,
	lvl2PlantIfNeeded,
	briefAreaPatrol,
	storageIfNeeded,
	areaLimit_Respawner,	
	moveBaseCenter
}

local sphereMexBuilder = {
	"sphere_metal_extractor",
	"sphere_metal_extractor",
	"sphere_metal_extractor",
	"sphere_metal_extractor",
	areaLimit_MediumAA,
	"sphere_metal_extractor",
	"sphere_metal_extractor",
	"sphere_metal_extractor",
	"sphere_metal_extractor",
	areaLimit_MediumAA,
	areaLimit_Radar,
	restoreQueue
}

local sphereWaterMexBuilder = {
	setWaterMode,
	"sphere_metal_extractor",
	"sphere_metal_extractor",
	"sphere_metal_extractor",
	"sphere_metal_extractor",	
	areaLimit_WaterMediumAA,
	"sphere_metal_extractor",
	"sphere_metal_extractor",
	"sphere_metal_extractor",
	"sphere_metal_extractor",
	areaLimit_WaterMediumAA,
	areaLimit_WaterRadar,
	tidalIfNeeded,
	restoreQueue
}


local sphereLev1DefenseBuilder = {
	moveVulnerablePos,
	areaLimit_Radar,
	areaLimit_MediumAA,
	areaLimit_L2ArtilleryDefense,
	areaLimit_L2HeavyDefense,
	areaLimit_MediumAA,
	restoreQueue
}


local sphereLev2Con = {
	exitPlant,
	brutalFusion,
	airRepairPadIfNeeded,
	changeQueueToMexUpgraderIfNeeded,
	changeQueueToAdvancedDefenseBuilderIfNeeded,
	moveSafePos,
	fusionIfNeeded,
	lvl1PlantIfNeeded,
	lvl2PlantIfNeeded,
	upgradeCenterIfNeeded,
	areaLimit_L3HeavyAA,
	areaLimit_AdvRadar,	
--	areaLimit_L3ArtilleryDefense,
	moveVulnerablePos,
	areaLimit_L3LongRangeArtillery,
	airRepairPadIfNeeded,
	{action = "cleanup", frames = 128},
	moveBaseCenter	
}

local sphereMexUpgrader = {
	moveSafePos,
	reclaimNearestMexIfNeeded,
	mohoIfMexReclaimed,
	reclaimNearestMexIfNeeded,
	mohoIfMexReclaimed,
	moveSafePos,
	reclaimNearestMexIfNeeded,
	mohoIfMexReclaimed,
	reclaimNearestMexIfNeeded,
	mohoIfMexReclaimed,	
	restoreQueue
}

local sphereLev2DefenseBuilder = {
	moveVulnerablePos,
	areaLimit_AdvRadar,	
	areaLimit_L3HeavyAA,
	--areaLimit_L3ArtilleryDefense,
	-- areaLimit_L3HeavyAA,
	areaLimit_L3LongRangeArtillery,
	restoreQueue	
}

local spherePlant = {
	"sphere_needles",
	"sphere_construction_vehicle",
	{action = "randomness", probability = 0.5, value = "sphere_construction_vehicle"},
	sphereL1LandChoice,
	sphereL1LandChoice,
	sphereL1LandChoice,
	"sphere_slicer",
	"sphere_bit",
	"sphere_needles",
	{action = "wait", frames = 128}
}


local sphereAircraftPlant = {
	"sphere_moth",
	"sphere_construction_aircraft",
	{action = "randomness", probability = 0.5, value = "sphere_construction_aircraft"},	
	"sphere_moth",
	"sphere_moth",
	"sphere_moth",
	"sphere_moth",
	"sphere_tycho",
	{action = "wait", frames = 128}
}

local sphereShipPlant = {
	"sphere_skiff",
	"sphere_construction_ship",
	sphereL1ShipChoice,
	sphereL1ShipChoice,
	sphereL1ShipChoice,
	{action = "wait", frames = 128}
}

local sphereAdvAircraftPlant = {
	"sphere_spitfire",
	"sphere_adv_construction_aircraft",
	sphereL2AirChoice,
	sphereL2AirChoice,
	sphereL2AirChoice,
	"sphere_twilight",
	"sphere_meteor",
	{action = "wait", frames = 128}
}

local sphereAdvKbotLab = {
	"sphere_hanz",
	"sphere_adv_construction_kbot",
	"sphere_chub",
	sphereL2KbotChoice,
	sphereL2KbotChoice,
	sphereL2KbotChoice,
	"sphere_charger",
	sphereL2KbotRadar,
	sphereL2KbotRadarJammer,
	"sphere_golem",	
	"sphere_hermit",
	{action = "wait", frames = 128}
}

local sphereAdvVehiclePlant = {
	"sphere_trax",
	"sphere_adv_construction_vehicle",
	sphereL2VehicleChoice,
	sphereL2VehicleChoice,
	sphereL2VehicleChoice,
	"sphere_quad",
	"sphere_slammer",
	sphereL2VehicleRadar,
	sphereL2VehicleRadarJammer,
	"sphere_bulk",
	"sphere_shielder",
	{action = "wait", frames = 128}
}

local sphereAdvShipPlant = {
	"sphere_monster",
	"sphere_adv_construction_ship",
	sphereL2ShipChoice,
	sphereL2ShipChoice,
	sphereL2ShipChoice,
	{action = "wait", frames = 128}
}


------------------------------- unit-queue table

mexUpgraderQueueByFaction = { [side1Name] = avenMexUpgrader, [side2Name] = coreMexUpgrader, [side3Name] = clawMexUpgrader, [side4Name] = sphereMexUpgrader}
mexBuilderQueueByFaction = { [side1Name] = avenMexBuilder, [side2Name] = coreMexBuilder, [side3Name] = clawMexBuilder, [side4Name] = sphereMexBuilder}
commanderBaseBuilderQueueByFaction = { [side1Name] = avenCommander, [side2Name] = gearCommander, [side3Name] = clawCommander, [side4Name] = sphereCommander}
commanderAtkQueueByFaction = { [side1Name] = avenUCommander, [side2Name] = gearUCommander, [side3Name] = clawUCommander, [side4Name] = sphereUCommander}
commanderWaterQueueByFaction = { [side1Name] = avenWaterCommander, [side2Name] = coreWaterCommander, [side3Name] = clawWaterCommander, [side4Name] = sphereWaterCommander}
defenseBuilderQueueByFaction = { [side1Name] = avenLev1DefenseBuilder, [side2Name] = gearLev1DefenseBuilder, [side3Name] = clawLev1DefenseBuilder, [side4Name] = sphereLev1DefenseBuilder}
advancedDefenseBuilderQueueByFaction = { [side1Name] = avenLev2DefenseBuilder, [side2Name] = gearLev2DefenseBuilder, [side3Name] = clawLev2DefenseBuilder, [side4Name] = sphereLev2DefenseBuilder}
waterDefenseBuilderQueueByFaction = { [side1Name] = avenLev1WaterDefenseBuilder, [side2Name] = gearLev1WaterDefenseBuilder, [side3Name] = clawLev1WaterDefenseBuilder, [side4Name] = sphereLev1WaterDefenseBuilder}
advancedWaterDefenseBuilderQueueByFaction = { [side1Name] = avenLev2WaterDefenseBuilder, [side2Name] = gearLev2WaterDefenseBuilder, [side3Name] = clawLev2WaterDefenseBuilder, [side4Name] = sphereLev2WaterDefenseBuilder}
attackPatrollerQueue = atkPatroller
upgradeQueueByPath = {offensive = upgradeOffensive, defensive = upgradeDefensive, defensive_regen = upgradeDefensiveRegen, speed = upgradeSpeed, mixed = upgradeMixed, mixed_drones_utility = upgradeMixedDronesUtility, mixed_drones_combat = upgradeMixedDronesCombat}

taskqueues = {
------------------- AVEN
	aven_commander_respawner = respawner,
	aven_commander = avenCommander,
	aven_u1commander = avenUCommander,
	aven_u2commander = avenUCommander,
	aven_u3commander = avenUCommander,
	aven_u4commander = avenUCommander,
	aven_u5commander = avenUCommander,
	aven_construction_vehicle = avenLev1Con,
	aven_construction_kbot = avenLev1Con,
	aven_construction_aircraft = avenLev1Con,
	aven_construction_ship = avenLev1WaterCon,
	aven_adv_construction_vehicle = avenLev2Con,
	aven_adv_construction_kbot = avenLev2Con,
	aven_adv_construction_aircraft = avenLev2Con,	
	aven_adv_construction_sub = avenLev2WaterCon,
	aven_light_plant = avenLightPlant,
	aven_aircraft_plant = avenAircraftPlant,
	aven_shipyard = avenShipPlant,
	aven_adv_kbot_lab = avenAdvKbotLab,
	aven_adv_vehicle_plant = avenAdvVehiclePlant,
	aven_adv_aircraft_plant = avenAdvAircraftPlant,
	aven_adv_shipyard = avenAdvShipPlant,
	aven_upgrade_center = upgradeCenter,
	aven_marky = atkSupporter,
	aven_eraser = atkSupporter,
	aven_seer = atkSupporter,
	aven_jammer = atkSupporter,
	aven_zephyr = atkSupporter,
------------------- GEAR
	gear_commander_respawner = respawner,
	gear_commander = gearCommander,
	gear_u1commander = gearUCommander,
	gear_u2commander = gearUCommander,
	gear_u3commander = gearUCommander,
	gear_u4commander = gearUCommander,
	gear_u5commander = gearUCommander,
	gear_construction_vehicle = gearLev1Con,
	gear_construction_kbot = gearLev1Con,
	gear_construction_aircraft = gearLev1Con,
	gear_construction_ship = gearLev1WaterCon,
	gear_adv_construction_vehicle = gearLev2Con,
	gear_adv_construction_kbot = gearLev2Con,
	gear_adv_construction_aircraft = gearLev2Con,	
	gear_adv_construction_sub = gearLev2WaterCon,
	gear_light_plant = gearLightPlant,
	gear_aircraft_plant = gearAircraftPlant,
	gear_shipyard = gearShipPlant,
	gear_adv_kbot_lab = gearAdvKbotLab,
	gear_adv_vehicle_plant = gearAdvVehiclePlant,
	gear_adv_aircraft_plant = gearAdvAircraftPlant,
	gear_adv_shipyard = gearAdvShipPlant,
	gear_upgrade_center = upgradeCenter,
	gear_voyeur = atkSupporter,
	gear_spectre = atkSupporter,
	gear_informer = atkSupporter,
	gear_deleter = atkSupporter,
------------------- CLAW
	claw_commander_respawner = respawner,
	claw_commander = clawCommander,
	claw_u1commander = clawUCommander,
	claw_u2commander = clawUCommander,
	claw_u3commander = clawUCommander,
	claw_u4commander = clawUCommander,
	claw_u5commander = clawUCommander,
	claw_construction_kbot = clawLev1Con,
	claw_construction_aircraft = clawLev1Con,
	claw_construction_ship = clawLev1WaterCon,
	claw_adv_construction_vehicle = clawLev2Con,
	claw_adv_construction_kbot = clawLev2Con,
	claw_adv_construction_aircraft = clawLev2Con,	
	claw_adv_construction_ship = clawLev2WaterCon,
	claw_light_plant = clawPlant,
	claw_aircraft_plant = clawAircraftPlant,
	claw_shipyard = clawShipPlant,
	claw_adv_kbot_plant = clawAdvKbotLab,
	claw_adv_vehicle_plant = clawAdvVehiclePlant,
	claw_adv_aircraft_plant = clawAdvAircraftPlant,
	claw_adv_shipyard = clawAdvShipPlant,
	claw_upgrade_center = upgradeCenter,
	claw_revealer = atkSupporter,
	claw_shade = atkSupporter,
	claw_seer = atkSupporter,
	claw_jammer = atkSupporter,	
------------------- SPHERE
	sphere_commander_respawner = respawner,
	sphere_commander = sphereCommander,
	sphere_u1commander = sphereUCommander,
	sphere_u2commander = sphereUCommander,
	sphere_u3commander = sphereUCommander,
	sphere_u4commander = sphereUCommander,
	sphere_u5commander = sphereUCommander,
	sphere_construction_vehicle = sphereLev1Con,
	sphere_construction_aircraft = sphereLev1Con,
	sphere_construction_ship = sphereLev1WaterCon,
	sphere_adv_construction_vehicle = sphereLev2Con,
	sphere_adv_construction_kbot = sphereLev2Con,
	sphere_adv_construction_aircraft = sphereLev2Con,	
	sphere_adv_construction_sub = sphereLev2WaterCon,
	sphere_light_factory = spherePlant,
	sphere_aircraft_factory = sphereAircraftPlant,
	sphere_shipyard = sphereShipPlant,
	sphere_adv_kbot_factory = sphereAdvKbotLab,
	sphere_adv_vehicle_factory = sphereAdvVehiclePlant,
	sphere_adv_aircraft_factory = sphereAdvAircraftPlant,
	sphere_adv_shipyard = sphereAdvShipPlant,
	sphere_upgrade_center = upgradeCenter,
	sphere_sensor = atkSupporter,
	sphere_rain = atkSupporter,
	sphere_scanner = atkSupporter,
	sphere_concealer = atkSupporter,
	sphere_shielder = atkSupporter,
	sphere_screener = atkSupporter
}