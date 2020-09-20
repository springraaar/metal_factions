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
local spGetTeamLuaAI = Spring.GetTeamLuaAI
local spAreTeamsAllied = Spring.AreTeamsAllied
local spGetTeamStartPosition = Spring.GetTeamStartPosition
local spGetTeamUnits = Spring.GetTeamUnits
local spGetAllUnits = Spring.GetAllUnits
local spGetUnitTeam = Spring.GetUnitTeam
local mFAIs = {}
GG.mFAIStartPosByTeamId = {}

local showAIWarningMessage = 0

include("LuaRules/Gadgets/ai/common.lua")
include("LuaRules/Gadgets/ai/AI.lua")
include("LuaRules/Gadgets/ai/MapHandler.lua")

--SYNCED CODE
if (gadgetHandler:IsSyncedCode()) then

function gadget:Initialize()

	local numberOfmFAITeams = 0
	local teamList = spGetTeamList()

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
						mode = string.sub(aiInfo,8,strategyPos1)
						strategyStr = string.match(aiInfo,"%((.-)%)")
					else
						mode = string.sub(aiInfo,8)
					end
					Echo("Player " .. teamList[i] .. " has mode = " .. mode.." strategy="..strategyStr)
				end 
				
				-- add AI object
				thisAI = AI.create(id, mode, strategyStr, allyId, mapHandler)
				thisAI:setStrategy("aven",strategyStr,true) -- side gets overridden once the first unit spawns
				mFAIs[#mFAIs+1] = thisAI
			else
				showAIWarningMessage = 1
				Echo("AI player " .. teamList[i] .. " is not supported, use MFAI instead.")
			end
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
		
		Echo("AI "..thisAI.id.." : allies="..#alliedTeamIds.." enemies="..#enemyTeamIds)
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
        
        -- update sets of unit ids : own, friendlies, enemies
		thisAI.ownUnitIds = {}
        thisAI.friendlyUnitIds = {}
        thisAI.enemyUnitIds = {}

        for _,uId in ipairs(spGetAllUnits()) do
        	if (spGetUnitTeam(uId) == thisAI.id) then
        		addToSet(thisAI.ownUnitIds, uId)
        	elseif (setContains(thisAI.alliedTeamIds,spGetUnitTeam(uId)) or spGetUnitTeam(uId) == thisAI.id) then
        		addToSet(thisAI.friendlyUnitIds, uId)
        	else
        		addToSet(thisAI.enemyUnitIds, uId)
        	end
        end 
	
		-- run AI game frame update handlers
		thisAI:GameFrame(n)
    end

	--TODO make this work or remove it    
    --local data={}
    --SendToUnsynced("AIHighlightUpdateEvent",0,0)
end


function gadget:UnitCreated(unitId, unitDefId, teamId, builderId) 
	-- for each AI...
    for _,thisAI in ipairs(mFAIs) do
		thisAI:UnitCreated(unitId, unitDefId, teamId, builderId)
	end
end

function gadget:UnitDestroyed(unitId, unitDefId, teamId, attackerId, attackerDefId, attackerTeamId) 
	-- for each AI...
    for _,thisAI in ipairs(mFAIs) do
		thisAI:UnitDestroyed(unitId, unitDefId, teamId, attackerId, attackerDefId, attackerTeamId)
	end
end


function gadget:UnitDamaged(unitId, unitDefId, unitTeamId, damage, paralyzer, weaponDefId, projectileId, attackerId, attackerDefId, attackerTeamId)
	-- for each AI...
    for _,thisAI in ipairs(mFAIs) do
		thisAI:UnitDamaged(unitId, unitDefId, unitTeamId, attackerId, attackerDefId, attackerTeamId)
	end	
end

function gadget:UnitIdle(unitId, unitDefId, teamId) 
	-- for each AI...
    for _,thisAI in ipairs(mFAIs) do
		thisAI:UnitIdle(unitId, unitDefId, teamId)
	end
end


function gadget:UnitFinished(unitId, unitDefId, teamId) 
	-- for each AI...
    for _,thisAI in ipairs(mFAIs) do
		thisAI:UnitFinished(unitId, unitDefId, teamId)
	end
end

function gadget:UnitTaken(unitId, unitDefId, teamId, newTeamId) 
	-- for each AI...
    for _,thisAI in ipairs(mFAIs) do
		thisAI:UnitTaken(unitId, unitDefId, teamId, newTeamId)
	end
end

function gadget:UnitGiven(unitId, unitDefId, teamId, oldTeamId) 
	-- for each AI...
    for _,thisAI in ipairs(mFAIs) do
		thisAI:UnitTaken(unitId, unitDefId, teamId, oldTeamId)
	end
end

function gadget:RecvLuaMsg(msg, playerId)
	--Spring.Echo("received lua msg from player "..playerId..": "..msg) --DEBUG

	local pName,active,spectator,teamId,allyId,_,_,_,_,_ = spGetPlayerInfo(playerId)
	-- exclude spectators
	-- TODO allow cheats to override this
	if (active and not spectator) then
		Spring.Echo("pName="..pName.." teamId="..teamId.." allyId="..allyId)
		-- if it was a message to set or remove beacon, forward it to all AIs allied with the player
		for _,thisAI in ipairs(mFAIs) do
			if (thisAI.allyId == allyId) then
				thisAI:processExternalCommand(msg,playerId,teamId,pName)
			end
		end
	end
end


--------------------------------------------- UNSYNCED CODE
else

--TODO use this eventually
-- register synced->unsynced communication of AI UI highlight events
local function AIHighlightUpdateEventHandler(allyId,data)
	if Script.LuaUI('AIHighlightUpdateUIEvent') then
		Script.LuaUI.AIHighlightUpdateUIEvent(allyId,data)
	end
end


function gadget:Initialize()
	gadgetHandler:AddSyncAction("AIHighlightUpdateEvent",AIHighlightUpdateEventHandler)
end


function gadget:Shutdown()
	gadgetHandler:RemoveSyncAction("AIHighlightUpdateEvent",AIHighlightUpdateEventHandler)
end

end


