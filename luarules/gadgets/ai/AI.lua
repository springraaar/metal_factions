include("luarules/gadgets/ai/common.lua")
include("luarules/gadgets/ai/modules.lua")
include("luarules/gadgets/ai/AttackerBehavior.lua")
include("luarules/gadgets/ai/TaskQueueBehavior.lua")
include("LuaLibs/json.lua")

AI = {}
AI.__index = AI


function AI.create(id, mode, strategyStr, allyId, mapHandler)
	local obj = {}             -- our new object
	setmetatable(obj,AI)  -- make AI handle lookup
	obj.id = id      -- initialize our object
	obj.mode = mode
	obj.isEasyMode = (mode == "easy")
	obj.isBrutalMode = (mode == "brutal")
	obj.originalStrategyStr = strategyStr
	obj.currentStrategyStr = strategyStr
	obj.originalStrategyName = nil
	obj.currentStrategyName = nil
	obj.currentStrategy = nil
	obj.currentStrategyStage = 1
	obj.useStrategies = strategyStr ~= "classic"
	obj.autoChangeStrategies = strategyStr == "adaptable"	--TODO make this work
	obj.side = "aven"		-- assume aven, but override it after the first unit spawns
	obj.sideSet = false  -- to signal that it needs to be set
	obj.beaconSetPlayerId = nil
	obj.beaconSetTeamId = nil
	obj.beaconFrame = nil
	obj.beaconPos = nil
	obj.beaconType = "all"
	obj.allyId = allyId
	obj.mapHandler = mapHandler
   	obj.strategyOverride = false
	obj.humanStrategyStr = nil
	obj.humanDefenseDensityMult = nil
	obj.upgradesBuiltByName = {}
	
	
	obj.commanderRetreatHealth = UNIT_RETREAT_HEALTH
	obj.assaultRetreatHealth = ASSAULT_RETREAT_HEALTH
	obj.otherRetreatHealth = UNIT_RETREAT_HEALTH
	
	obj.frameShift = 7*tonumber(id)	-- used to spread out processing from different AIs across multiple frames
	obj.needStartPosAdjustment = false
	obj.sentStartupHelpMsg = false
	
	local _,_,hostingPlayerId,_,_,_ = spGetAIInfo(id)
	obj.hostingPlayerId = hostingPlayerId
	
	return obj
end

-- pick a strategy, given its identifier and the side
function AI:setStrategy(side,strategyStr,noMessage,playerId)
	
	-- if "adaptable", pick one strategy depending on the map
	if strategyStr == "adaptable" then
		local mapProfile = self.mapHandler.mapProfile
		
		if mapProfile == MAP_PROFILE_LAND_FLAT then
			viableStrategyStrList = {"assault","skirmisher","amphibious"}
			strategyStr = viableStrategyStrList[random( 1, #viableStrategyStrList)]
		elseif mapProfile == MAP_PROFILE_LAND_RUGGED then
			viableStrategyStrList = {"assault","skirmisher","air","amphibious"}
			strategyStr = viableStrategyStrList[random( 1, #viableStrategyStrList)]
		elseif mapProfile == MAP_PROFILE_WATER or mapProfile == MAP_PROFILE_MIXED  then
			viableStrategyStrList = {"air","amphibious"}
			strategyStr = viableStrategyStrList[random( 1, #viableStrategyStrList)]
		elseif mapProfile == MAP_PROFILE_AIRONLY then
			viableStrategyStrList = {"air"}
			strategyStr = viableStrategyStrList[random( 1, #viableStrategyStrList)]
		end
		self.currentStrategyStr = strategyStr
	end

	local stratList = nil
	if (playerId and playerId >=0) then
		stratList = playerStrategyTable[playerId][side.."_"..strategyStr]
	else
		stratList = strategyTable[side.."_"..strategyStr]
	end

	if (stratList and #stratList > 0) then
		self.currentStrategyStr = strategyStr 
		self.currentStrategy = stratList[random( 1, #stratList)]
		self.currentStrategyName = self.currentStrategy.name
		if not noMessage then
			self:messageAllies("Using strategy \""..strategyStr.."\" : "..self.currentStrategyName)
		end
	else
		self:messageAllies("ERROR : Could not find strategy "..strategyStr.." for side "..side.." using default")
		self.useStrategies = false
		self.autoChangeStrategies = nil
	end
	
	-- override certain properties
	if (self.currentStrategy and self.currentStrategy.upgrades) then
		self.upgradePath = self.currentStrategy.upgrades
	end
	if (self.currentStrategy and self.currentStrategy.commanderRetreatHealth) then
		self.commanderRetreatHealth = self.currentStrategy.commanderRetreatHealth
	end
	if (self.currentStrategy and self.currentStrategy.assaultRetreatHealth) then
		self.assaultRetreatHealth = self.currentStrategy.assaultRetreatHealth
	end		
	if (self.currentStrategy and self.currentStrategy.otherRetreatHealth) then
		self.otherRetreatHealth = self.currentStrategy.otherRetreatHealth
	end
end

function AI:updateSideStrategy(side)
	if side ~= self.side then
		self.sideSet = true
		self.side = side
		if (self.useStrategies) then
			--Spring.Echo("updating side and strategy to "..side.."/"..self.currentStrategyStr )	
			self:setStrategy(side,self.currentStrategyStr,false)
		end
	end
end


function AI:isBeaconActive(groupId)
	if self.beaconFrame ~=nil then
		local f = spGetGameFrame()

		if f - self.beaconFrame < BEACON_DURATION_FRAMES then
			if not groupId or (self.beaconType == "all" or (self.beaconType == "raiders" and (groupId == UNIT_GROUP_RAIDERS or groupId == UNIT_GROUP_AIR_ATTACKERS)) or (self.beaconType == "main" and (groupId == UNIT_GROUP_ATTACKERS or groupId == UNIT_GROUP_SEA_ATTACKERS)) ) then
				return true
			end
		else
			-- beacon expired, remove marker
			spMarkerErasePosition(self.beaconPos.x,self.beaconPos.y,self.beaconPos.z)
		end 
	end
	
	return false
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
		
		-- if beacon is set within the box, use that position
		if (self.beaconPos ~= nil and self.beaconPos.x > 0) then
			if (self.beaconPos.x >= xMin and self.beaconPos.x <= xMax and self.beaconPos.z >= zMin and self.beaconPos.z <= zMax) then
				return {x=self.beaconPos.x,y=self.beaconPos.y,z=self.beaconPos.z}
			end
		end
		
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
			-- Echo("added "..newModule:name().." module") --DEBUG
		end
	end
	
	-- table with unit behaviors indexed by unitId
	self.unitBehaviors = {}
end


function AI:addUnitBehavior(unitId,unitDefId)
	-- add behavior
	local beh = nil
	un = UnitDefs[unitDefId].name
	if UnitDefs[unitDefId].isBuilder or setContains(unitTypeSets[TYPE_SUPPORT],un) or taskQueues[un] ~= nil then
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

function AI:messageAllies(msg)
	Spring.SendMessageToAllyTeam(self.allyId,"--- AI "..self.id..": "..msg)
	--Spring.SendMessage("--- AI "..self.id..": "..msg)
end

function AI:markerAllies(x,y,z,msg)
	SendToUnsynced("AIEvent",self.id,self.allyId,EXTERNAL_RESPONSE_SETMARKER,x.."|"..y.."|"..z.."|"..msg)
end

function AI:eraseMarkerAllies(x,y,z)
	SendToUnsynced("AIEvent",self.id,self.allyId,EXTERNAL_RESPONSE_REMOVEMARKER,x.."|"..y.."|"..z)
end


function AI:loadCustomStrategies(playerId,teamId,pName,strategyTextCompressed)
	local resultMessage = ""
	local resultStatus = false
	
	local sIds, sTable = nil
	
	-- if it was already set, return 
	if playerStrategyTable[playerId] then
		return resultMessage,resultStatus
	end
	
	--Spring.Echo("STRATEGY COMPRESSED TEXT IS "..strategyTextCompressed)
	--Spring.Echo("compressed len gadget "..string.len(strategyTextCompressed))
	local strategyText = VFS.ZlibDecompress(strategyTextCompressed)
	--Spring.Echo("len gadget "..string.len(strategyText))
	
	local valid = true
	-- validate strategy text
	--local textToCheck = 
	--lines = {}
	--for s in strategyText:gmatch("[^\r\n]+") do
	    --table.insert(lines, s)
	--end
	--for _,line in pairs(lines) do
	--	Spring.Echo(line)
	--end
	
	-- replace constants
	if (valid) then
		for match,rep in pairs(strategyJsonReplacement) do
			strategyText,_ = strategyText:gsub( '"'..match..'"', rep)
		end
	end
 
	if (valid == true) then
		local obj = Spring.Utilities.json.decode(strategyText)
		sIds = obj.availableStrategyIds
		sTable = obj.strategyTable 

		playerAvailableStrategyOwner[playerId] = {pName,teamId}
		playerAvailableStrategyIds[playerId] = sIds
		playerStrategyTable[playerId] = sTable
	
		local stratIdListStr = "" 
		local n=0
		for _,str in pairs(sIds) do
			if (n > 0) then
				stratIdListStr=stratIdListStr..","
			end
			stratIdListStr=stratIdListStr..str
			n=n+1
		end
	
		resultMessage = stratIdListStr
		resultStatus = true
	end
		
	return resultMessage,resultStatus
end

-- process external command
function AI:processExternalCommand(msg,playerId,teamId,pName,isOwner,spectator)
	if (msg) then
		local parameters = splitString(msg,"|")
		local shift = 0
		local targetTeamId = tonumber(parameters[1])
		if targetTeamId ~= nil then
			shift = 1
		end
		local msgFromAllies = spAreTeamsAllied(self.id,teamId)
		local command = parameters[shift+1] 
		--Spring.Echo("command was: "..command)
		if (command == EXTERNAL_CMD_SETBEACON and (msgFromAllies or (isOwner and spectator))) then
			local px = tonumber(parameters[shift+2])
			local py = tonumber(parameters[shift+3])
			local pz = tonumber(parameters[shift+4])
			
			-- remove existing marker if any
			if (self.beaconPos ~= nil) then
				self:eraseMarkerAllies(self.beaconPos.x,self.beaconPos.y,self.beaconPos.z)
				--spMarkerErasePosition(self.beaconPos.x,self.beaconPos.y,self.beaconPos.z)
			end
			
			self.beaconSetPlayerId = playerId
			self.beaconSetTeamId = teamId
			self.beaconFrame = spGetGameFrame()
			self.beaconPos = newPosition(px,py,pz)

			local seconds = floor((self.beaconFrame + BEACON_DURATION_FRAMES) / 30) 
			local hh = floor(seconds / 3600)
			local mm = floor(seconds % 3600 / 60)
			local ss = floor(seconds % 3600 % 60)
   			hh = hh < 10 and "0"..hh or hh
   			mm = mm < 10 and "0"..mm or mm
   			ss = ss < 10 and "0"..ss or ss
			
			--spMarkerAddPoint(px,py,pz,"AI BEACON\nuntil "..hh..":"..mm..":"..ss.."\n("..pName..")")
			self:markerAllies(px,py,pz,"AI BEACON\nuntil "..hh..":"..mm..":"..ss.."\n("..pName..")")

		elseif (command == EXTERNAL_CMD_REMOVEBEACON and (msgFromAllies or (isOwner and spectator))) then
			self.beaconSetPlayerId = playerId
			self.beaconSetTeamId = teamId
			
			-- remove existing marker if any
			if (self.beaconPos ~= nil) then
				self:eraseMarkerAllies(self.beaconPos.x,self.beaconPos.y,self.beaconPos.z)
				--spMarkerErasePosition(self.beaconPos.x,self.beaconPos.y,self.beaconPos.z)
			end
			self.beaconFrame = nil
			self.beaconPos = nil

		elseif (command == EXTERNAL_CMD_STATUS) then
			if self.useStrategies then
				self:messageAllies("Current strategy : \""..self.currentStrategyStr.."\" : "..self.currentStrategyName)
			else
				self:messageAllies("Classic Mode")
			end
			self:messageAllies("Last 10 min efficiency : "..tostring(self.unitHandler.teamCombatEfficiency))
			self:messageAllies("Beacon Type : \""..self.beaconType.."\"")
		elseif (command == EXTERNAL_CMD_STRATEGY) then
			local strategyStr = nil	
			strategyStr = parameters[shift+2]
			
			if (( msgFromAllies and targetTeamId == nil) or targetTeamId == self.id) then
				if (isOwner and spectator) then
					Spring.Echo("AI "..self.id.." received strategy override from owner/spectator : "..tostring(strategyStr))
				elseif not msgFromAllies then
					Spring.Echo("AI "..self.id.." received strategy override from enemies : "..tostring(strategyStr))
				end
				-- try to get the player's custom strategy with that name, else check the default list
				if (strategyStr ~= nil and playerStrategyTable[playerId] and playerStrategyTable[playerId][self.side.."_"..strategyStr]) then
					self:setStrategy(self.side,strategyStr,false,playerId)
					self.humanStrategyStr = strategyStr
				elseif (strategyStr ~= nil and strategyTable[self.side.."_"..strategyStr]) then
					self:setStrategy(self.side,strategyStr,false)
					self.humanStrategyStr = strategyStr
				else
					self:messageAllies("ERROR: strategy "..tostring(strategyStr).." not found for "..self.side)
				end
			end
		elseif (command == EXTERNAL_CMD_DEFMULT) then
			local targetMultStr = nil
			targetMultStr = parameters[shift+2]
			local targetMult = tonumber(targetMultStr)
			
			if (targetTeamId == nil or targetTeamId == self.id) then
				if (targetMult ~= nil and targetMult >= 0) then
					self.humanDefenseDensityMult = targetMult
					self:messageAllies("defense density multiplier set to "..targetMult)
				else
					self.humanDefenseDensityMult = nil
					self:messageAllies("cleared defense density multiplier")
				end
			end
		elseif (command == EXTERNAL_CMD_COMMORPH) then
			if (targetTeamId == nil or targetTeamId == self.id) then
				local comUId, ud, tmpName = nil
				local morphName = ""
				local morphedComFound = false
				local uX,uZ = 0
				if (self.useStrategies) then
					-- get all the AI units, try to find a commander 
					local units = spGetTeamUnits(self.id)
					
					-- search AI's unit set for a basic commander to morph
					for _,tq in pairs(self.unitHandler.taskQueues) do
						uId = tq.unitId 
						ud = UnitDefs[spGetUnitDefID(uId)]
						tmpName = ud.name
						
						-- abort search if AI already has a morphed commander
						if tq.isUpgradedCommander then
							morphedComFound = true
							break
						end
	
						if tq.isCommander then
							local cmds = Spring.GetUnitCmdDescs(uId)
							comUId = uId
							uX,_,uZ = spGetUnitPosition(uId,false,false)
						
							-- morph to a random form within the set of allowed forms
							local currentStrategy = self.currentStrategy
							local sStage = self.currentStrategyStage
	
							morphName = currentStrategy.commanderMorphs[ random( 1, #currentStrategy.commanderMorphs)] 
							local morphCmd = false
							local morphCmdIds = {}
							for i,c in ipairs(cmds) do
								if (c.action == "morph" and string.find(c.name, morphName)) then
									--Spring.Echo(c.id.." ; "..c.name.." ; "..c.type.." ; "..c.action.." ; "..c.texture) --DEBUG
									morphCmd = c.id
									break
								end
							end
	
							spGiveOrderToUnit(comUId,morphCmd,{},{})
							-- set "wait" action
							tq.waitLeft = 30*300
							tq.currentProject = "waiting"
							tq.progress = true
							break
						end
					end
				end
				if (comUId ~= nil) then
					self:messageAllies("morphing commander at ("..floor(uX)..","..floor(uZ)..") to "..morphName)
				else
					if (morphedComFound) then
						self:messageAllies("commander already morphed")
					else
						self:messageAllies("no commander available to morph, try again later...")
					end
				end
			end
		elseif (command == EXTERNAL_CMD_COMPAD and (msgFromAllies and (not spectator))) then
			if (targetTeamId == nil or targetTeamId == self.id) then

				-- get all the AI units, try to find a commander pad
				local units = spGetTeamUnits(self.id)
				local shareUId, ud, tmpName = nil
				local shareX,shareZ = 0
				for _,uId in pairs(units) do 
					ud = UnitDefs[spGetUnitDefID(uId)]
					tmpName = ud.name
					if setContains(unitTypeSets[TYPE_RESPAWNER],tmpName) then
						shareUId = uId
						shareX,_,shareZ = spGetUnitPosition(uId,false,false)
						break
					end
				end
			
				if (shareUId ~= nil) then
					spTransferUnit(shareUId,teamId,true)
					self:messageAllies("commander respawner pad shared at ("..floor(shareX)..","..floor(shareZ)..")")
				else
					self:messageAllies("no commander pad available, try again later...")
				end
			end
		elseif (command == EXTERNAL_CMD_LOADCUSTOMSTRATEGIES) then
			-- extract text from message properly (compressed text may have the separator)
			local strategyTextCompressed = string.sub(msg,string.len(EXTERNAL_CMD_LOADCUSTOMSTRATEGIES)+2)
			
			local resultMessage,resultStatus = self:loadCustomStrategies(playerId,teamId,pName,strategyTextCompressed)
			if resultMessage then
				self:messageAllies("registered strategies:\n"..resultMessage)
			end
		elseif (command == EXTERNAL_CMD_BEACONTYPE) then
			local targetType = parameters[shift+2]
			
			if targetType and ( targetTeamId == nil or targetTeamId == self.id) then
				if (targetType == "all" or targetType == "raiders" or targetType == "main") then
					self.beaconType = targetType
					self:messageAllies("beacon type set to \""..targetType.."\"")
				else
					self.humanDefenseDensityMult = nil
					self:messageAllies("reset beacon type to \"all\"")
				end
			end			
		elseif (command == EXTERNAL_CMD_RESIGN) then
			if (targetTeamId == nil or targetTeamId == self.id) then
				self:messageAllies("resigning...")
				Spring.KillTeam(self.id)
				spSetTeamRulesParam(self.id,"ai_resigned","1")
			end
		end
	end
end

----------------------- engine event handlers

function AI:GameFrame(n)
	if self.gameEnd == true then
		return
	end
	
	if (n > 100) and (not self.sentStartupHelpMsg) then
		local strategiesStr = ""
		for i,str in ipairs(availableStrategyIds) do
			strategiesStr = strategiesStr.."\n"..str
		end
		self:messageAllies("Use CTRL-ALT-CLICK to set AI beacon (RIGHT click to clear)")
		self:messageAllies("Type #AI to view commands")
		if self.useStrategies then
			self:messageAllies("Current strategy : \""..self.currentStrategyStr.."\" : "..self.currentStrategyName)
			self:messageAllies("Available strategies:")
			for i,str in ipairs(availableStrategyIds) do
				self:messageAllies(" "..str)
			end
			for playerId,sIds in pairs(playerAvailableStrategyIds) do
				local pName = playerAvailableStrategyOwner[playerId][1]
				local pTeamId = playerAvailableStrategyOwner[playerId][2]
				if spAreTeamsAllied(self.id,pTeamId) == true then
					for i,str in ipairs(sIds) do
						if playerStrategyTable[playerId][self.side.."_"..str] then
							self:messageAllies(" "..str.." ("..pName..")")
						end
					end	
				end
			end
		else
			self:messageAllies("Classic Mode")
		end

		self.sentStartupHelpMsg = true
	end
	
	for i,m in ipairs(self.modules) do
		if m == nil then
			log("nil module!")
		else
			if (m.GameFrame ~= nil) then
				m:GameFrame(n)
			end
		end
	end
	
	-- add behaviour for units missing	
    for uId,_ in pairs(self.ownUnitIds) do
		if ((self.recentlyDestroyedUnitIds == nil or self.recentlyDestroyedUnitIds[uId] == nil or (n - self.recentlyDestroyedUnitIds[uId] > 10)) and self.unitBehaviors[uId] == nil) then
			self:addUnitBehavior(uId, spGetUnitDefID(uId))
		end
    end 
	
	for i,b in pairs(self.unitBehaviors) do
		if (b.GameFrame ~= nil) then
			b:GameFrame(n)
		end
	end
	
	-- resource compensation for brutal mode
	if (self.isBrutalMode) then
		if fmod(n,15) == 0 then
			local minutesPassed = floor(n/FRAMES_PER_MIN)
			spAddTeamResource(self.id,"metal",BRUTAL_BASE_INCOME_METAL + minutesPassed * BRUTAL_BASE_INCOME_METAL_PER_MIN  )
			spAddTeamResource(self.id,"energy",BRUTAL_BASE_INCOME_ENERGY + minutesPassed * BRUTAL_BASE_INCOME_ENERGY_PER_MIN )
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
		self:addUnitBehavior(unitId, unitDefId)
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
		-- mark when own upgrades finish
		local ud = UnitDefs[unitDefId]
		if (ud and ud.customParams.isupgrade == "1") then
			if not self.upgradesBuiltByName[ud.name] then
				self.upgradesBuiltByName[ud.name] = 0
			end
			self.upgradesBuiltByName[ud.name] = self.upgradesBuiltByName[ud.name] +1 
		end
	
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

	--log("unit taken t="..teamId.." nt="..newTeamId,self.ai) --DEBUG
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

	--log("unit given t="..teamId.." ot="..oldTeamId,self.ai) --DEBUG
	-- only relevant for own units
	if (teamId == self.id and self.modules ~= nil) then
		for i,m in ipairs(self.modules) do
			if (m.UnitGiven ~= nil) then
				m:UnitGiven(unitId,unitDefId,teamId,oldTeamId)
			end
		end

		-- add behavior
		self:addUnitBehavior(unitId, unitDefId)
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

