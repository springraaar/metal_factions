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
local spGetTeamInfo = Spring.GetTeamInfo
local spGetTeamLuaAI = Spring.GetTeamLuaAI
local spAreTeamsAllied = Spring.AreTeamsAllied
local spGetTeamStartPosition = Spring.GetTeamStartPosition
local spGetTeamUnits = Spring.GetTeamUnits
local spGetAllUnits = Spring.GetAllUnits
local spGetUnitTeam = Spring.GetUnitTeam
local mFAIs = {}

local showAIWarningMessage = 0

include("LuaRules/Gadgets/ai/Common.lua")
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
			if (string.sub(aiInfo,1,4) == "MFAI") then
				numberOfmFAITeams = numberOfmFAITeams + 1
				Echo("Player " .. teamList[i] .. " is " .. aiInfo)
				
				-- initialize map handler only once
				-- it is shared by all MFAI instances
				if mapHandler == nil then
					mapHandler = MapHandler.create()
					mapHandler:Init()
				end
				
				local mode = "normal"
				if (string.find(aiInfo,":") ~= nil) then
					mode = string.sub(aiInfo,8)
					--Echo("Player " .. teamList[i] .. " has mode = " .. mode)
				end 
				
				-- add AI object
				thisAI = AI.create(id, mode)
				thisAI.allyId = allyId
				thisAI.mapHandler = mapHandler
				mFAIs[#mFAIs+1] = thisAI
			else
				showAIWarningMessage = 1
				Echo("AI player " .. teamList[i] .. " is not supported")
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
		
		-- Echo("AI "..thisAI.id.." : allies="..#alliedTeamIds.." enemies="..#enemyTeamIds)
		thisAI.alliedTeamIds = alliedTeamIds		
		thisAI.enemyTeamIds = enemyTeamIds
	end
end

function gadget:GameStart() 
    -- Initialise MFAIs
    for _,thisAI in ipairs(mFAIs) do
        local _,_,_,isAI,side = spGetTeamInfo(thisAI.id)
		thisAI.side = side
		local x,y,z = spGetTeamStartPosition(thisAI.id)
		thisAI.startPos = {x,y,z}
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
		thisAI:Update()
    end
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

--UNSYNCED CODE
else





end


