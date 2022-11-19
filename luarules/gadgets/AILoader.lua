function gadget:GetInfo()
   return {
      name = "MFAI",
      desc = "Main AI gadget for Metal Factions. (loosely based on Shard AI by AF)",
      author = "raaar",
      date = "September 2013",
      license = "PD",
      layer = 999999,
      enabled = true,
   }
end

-- localization
local Echo = Spring.Echo
local spGetTeamList = Spring.GetTeamList
local spGetPlayerInfo = Spring.GetPlayerInfo
local spGetTeamInfo = Spring.GetTeamInfo
local spGetAIInfo = Spring.GetAIInfo
local spGetTeamLuaAI = Spring.GetTeamLuaAI
local spAreTeamsAllied = Spring.AreTeamsAllied
local spGetTeamStartPosition = Spring.GetTeamStartPosition
local spGetTeamUnits = Spring.GetTeamUnits
local spGetAllUnits = Spring.GetAllUnits
local spGetUnitTeam = Spring.GetUnitTeam
local mFAIs = {}
GG.mFAIStartPosByTeamId = {}

local showAIWarningMessage = 0

include("luarules/gadgets/ai/common.lua")
include("luarules/gadgets/ai/AI.lua")
include("luarules/gadgets/ai/MapHandler.lua")

---------------------------------------------- auxiliary functions

function registerUnit()
	
end


function deregisterUnit()
	
end


--SYNCED CODE
if (gadgetHandler:IsSyncedCode()) then

---------------------------------------------- engine callins

function gadget:Initialize()

	local numberOfmFAITeams = 0
	local teamList = spGetTeamList()
	local allyIdsWithHumans = {}
	local mapHandler = nil	
	for i=1,#teamList do
		local id = teamList[i]
		local _,_,_,isAI,side,allyId = spGetTeamInfo(id)
        
		--Echo("Player " .. teamList[i] .. " is " .. side .. " AI=" .. tostring(isAI))

		---- adding AI
		if (isAI) then
			local aiInfo = spGetTeamLuaAI(id)
			if (aiInfo and string.sub(aiInfo,1,4) == "MFAI") then
				numberOfmFAITeams = numberOfmFAITeams + 1
				Echo("Player " .. teamList[i] .. " is " .. aiInfo)
				
				-- initialize map handler only once
				-- it is shared by all MFAI instances
				if mapHandler == nil then
					mapHandler = MapHandler.create()
					mapHandler:Init()
				end
				
				local mode = "normal"
				local strategyStr = "adaptable"
				if (string.find(aiInfo,":") ~= nil) then
					local strategyPos1,strategyPos2 = string.find(aiInfo," %(")
					if (strategyPos1 ~= nil) then
						mode = string.sub(aiInfo,8,strategyPos1-1)
						strategyStr = string.match(aiInfo,"%((.-)%)")
					else
						mode = string.sub(aiInfo,8)
					end
					Echo("Player " .. teamList[i] .. " has mode = \"" .. mode.."\" strategy=\""..strategyStr.."\"")
				end 
				
				-- add AI object
				thisAI = AI.create(id, mode, strategyStr, allyId, mapHandler)
				thisAI:setStrategy("aven",strategyStr,true) -- side gets overridden once the first unit spawns
				mFAIs[#mFAIs+1] = thisAI
			else
				showAIWarningMessage = 1
				Echo("AI player " .. teamList[i] .. " is not supported, use MFAI instead.")
			end
		else
			allyIdsWithHumans[allyId] = true
		end
	end

	-- add allied teams for each AI
	for _,thisAI in ipairs(mFAIs) do
		alliedTeamIds = {}
		enemyTeamIds = {}
		for i=1,#teamList do
			if (spAreTeamsAllied(thisAI.id,teamList[i])) then
				addToSet(alliedTeamIds,teamList[i])
			else
				addToSet(enemyTeamIds,teamList[i])
			end
		end
		
		local hasHumanAllies = allyIdsWithHumans[thisAI.allyId] and true or false
		Echo("AI "..thisAI.id.." : allies="..tableLength(alliedTeamIds).." enemies="..tableLength(enemyTeamIds).." hasHumanAllies="..tostring(hasHumanAllies))
		thisAI.hasHumanAllies = hasHumanAllies
		thisAI.alliedTeamIds = alliedTeamIds		
		thisAI.enemyTeamIds = enemyTeamIds
	end
end

function gadget:GameStart() 
    -- Initialise MFAIs
    for _,thisAI in ipairs(mFAIs) do
    	local startPos = thisAI:findStartPos(true,INFINITY)
        GG.mFAIStartPosByTeamId[thisAI.id] = startPos

		-- don't set side here, wait for the first unit to spawn
        -- local _,_,_,isAI,side = spGetTeamInfo(thisAI.id)
		-- thisAI.side = side
		
		thisAI:Init()
    end
end

function gadget:GameFrame(n) 
	if (n%16) == 0 then
		if (showAIWarningMessage == 1) then
			Spring.Echo("---------------------------------------------\nWARNING : unsupported AI players detected. Use MFAI instead.")
			showAIWarningMessage = 0
		end	
	end
	
	-- for each AI...
    for _,thisAI in ipairs(mFAIs) do
		thisAI:GameFrame(n)
    end

	--TODO make this work or remove it    
    --local data={}
    --SendToUnsynced("AIHighlightUpdateEvent",0,0)
end


function gadget:UnitCreated(unitId, unitDefId, teamId, builderId) 
	-- for each AI...
    for _,thisAI in pairs(mFAIs) do
		thisAI:UnitCreated(unitId, unitDefId, teamId, builderId)
	end
end

function gadget:UnitDestroyed(unitId, unitDefId, teamId, attackerId, attackerDefId, attackerTeamId) 
	-- for each AI...
    for _,thisAI in pairs(mFAIs) do
		thisAI:UnitDestroyed(unitId, unitDefId, teamId, attackerId, attackerDefId, attackerTeamId)
	end
end


function gadget:UnitDamaged(unitId, unitDefId, unitTeamId, damage, paralyzer, weaponDefId, projectileId, attackerId, attackerDefId, attackerTeamId)
	-- for each AI...
    for _,thisAI in pairs(mFAIs) do
		thisAI:UnitDamaged(unitId, unitDefId, unitTeamId, attackerId, attackerDefId, attackerTeamId)
	end	
end

function gadget:UnitIdle(unitId, unitDefId, teamId) 
	-- for each AI...
    for _,thisAI in pairs(mFAIs) do
		thisAI:UnitIdle(unitId, unitDefId, teamId)
	end
end


function gadget:UnitFinished(unitId, unitDefId, teamId) 
	-- for each AI...
    for _,thisAI in pairs(mFAIs) do
		thisAI:UnitFinished(unitId, unitDefId, teamId)
	end
end

function gadget:UnitTaken(unitId, unitDefId, teamId, newTeamId) 
	-- for each AI...
    for _,thisAI in pairs(mFAIs) do
		thisAI:UnitTaken(unitId, unitDefId, teamId, newTeamId)
	end
end

function gadget:UnitGiven(unitId, unitDefId, teamId, oldTeamId) 
	-- for each AI...
    for _,thisAI in pairs(mFAIs) do
		thisAI:UnitGiven(unitId, unitDefId, teamId, oldTeamId)
	end
end

function gadget:RecvLuaMsg(msg, playerId)
	--Spring.Echo("received lua msg from player "..playerId..": "..msg) --DEBUG

	local pName,active,spectator,teamId,allyId,_,_,_,_,_ = spGetPlayerInfo(playerId)
	
	--Spring.Echo("pName="..pName.." teamId="..teamId.." allyId="..allyId)
	-- forward message to all AIs allied with the player

	local enemyStrategyOverride = false
	local includeEnemies = false
	if (spGetGameFrame() < FULL_AI_TEAM_ENEMY_STRATEGY_OVERRIDE_FRAMES and string.find(msg,EXTERNAL_CMD_STRATEGY) ~= nil ) then
		enemyStrategyOverride = true
	end
	if (string.find(msg,EXTERNAL_CMD_LOADCUSTOMSTRATEGIES) ~= nil ) then
		includeEnemies = true
	end
	for _,thisAI in pairs(mFAIs) do
		local isOwner = (thisAI.hostingPlayerId == playerId) 
		if ( (isOwner and spectator) or (active and not spectator)) then
			if ( (isOwner and spectator) or thisAI.allyId == allyId or includeEnemies or (enemyStrategyOverride and (not thisAI.hasHumanAllies))) then
				thisAI:processExternalCommand(msg,playerId,teamId,pName,isOwner,spectator)
			end
		end
	end

end


--------------------------------------------- UNSYNCED CODE
else

-- register synced->unsynced communication of AI UI events
local function AIEventHandler(category,teamId,allyId,type,data)
	--if Script.LuaUI('AIEvent') then
		--Script.LuaUI.AIEvent(teamId,allyId,type,data)
	--end
	
	local myPlayerId = Spring.GetLocalPlayerID()
	
	-- if the player is allied with the AI that triggered the event or is a spectator, update UI
	local playerRoster = Spring.GetPlayerRoster()
	for _,playerData in pairs(playerRoster) do
		local pId = playerData[2]
		local tId = playerData[3]
		local aId = playerData[4]
		local spec = playerData[5]
		
		if (pId == myPlayerId and (aId == allyId or spec)) then				
			--Spring.Echo("AI EVENT : pId="..pId.." spec="..tostring(spec).." teamId="..teamId.." allyId="..allyId.." type="..type.." data="..data)
			
			if (data) then
				local parameters = splitString(data,"|")

				--Spring.Echo("command was: "..command)
				if (type == EXTERNAL_RESPONSE_SETMARKER) then
					local px = tonumber(parameters[1])
					local py = tonumber(parameters[2])
					local pz = tonumber(parameters[3])
					local msg = parameters[4]
					
					spMarkerAddPoint(px,py,pz,msg, true)
				elseif (type == EXTERNAL_RESPONSE_REMOVEMARKER) then
					local px = tonumber(parameters[1])
					local py = tonumber(parameters[2])
					local pz = tonumber(parameters[3])
					
					spMarkerErasePosition(px,py,pz)
				end
			end
			break
		end
	end
	
end


function gadget:Initialize()
	gadgetHandler:AddSyncAction("AIEvent",AIEventHandler)
end


function gadget:Shutdown()
	gadgetHandler:RemoveSyncAction("AIEvent",AIEventHandler)
end


end


