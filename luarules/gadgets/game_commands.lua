function gadget:GetInfo()
   return {
      name = "Game Commands",
      desc = "Handler for some game commands",
      author = "raaar",
      date = "2022",
      license = "PD",
      layer = 999999,
      enabled = true,
   }
end

-- localization
local spEcho = Spring.Echo
local spGetTeamList = Spring.GetTeamList
local spGetPlayerInfo = Spring.GetPlayerInfo
local spGetTeamInfo = Spring.GetTeamInfo
local spGetAIInfo = Spring.GetAIInfo
local spGetTeamLuaAI = Spring.GetTeamLuaAI
local spAreTeamsAllied = Spring.AreTeamsAllied
local spGetUnitTeam = Spring.GetUnitTeam
local spIsCheatingEnabled = Spring.IsCheatingEnabled
local spGetAllFeatures = Spring.GetAllFeatures
local spDestroyFeature = Spring.DestroyFeature
local spGetFeatureDefID = Spring.GetFeatureDefID
local CMD_CLEARWRECKS = "CLEARWRECKS"
local CMD_RESETUPGRADES = "RESETUPGRADES"

include("lualibs/util.lua")

-- synced only
if (not gadgetHandler:IsSyncedCode()) then
	return false
end

function processExternalCommand(msg,playerId,pName,teamId,allyId, active,spectator)
	if (msg) then
		local parameters = splitString(msg,"|")
		local shift = 0
		local command = parameters[shift+1] 
		--spEcho("command was: "..command)
		if (command == CMD_CLEARWRECKS and active) then
			-- remove all wreckages
			if (spIsCheatingEnabled()) then
				local wrecksRemoved = 0
				local fd = nil
				for _,fId in pairs(spGetAllFeatures()) do
					local fd = FeatureDefs[spGetFeatureDefID(fId)] 
					if (fd) then
						local fName = fd.name
						if (string.find(fName, "_dead") or string.find(fName, "_heap") or string.find(fName, "debris") ) then
							--spEcho("GAME : feature "..fId)					
							spDestroyFeature(fId)
							wrecksRemoved = wrecksRemoved + 1 
						end
					end
				end
				spEcho("GAME : "..wrecksRemoved.." wrecks removed!") 
			else
				spEcho("GAME : CLEARWRECKS command requires cheat mode.")
			end
		elseif (command == CMD_RESETUPGRADES and active) then
			-- remove all features
			if (spIsCheatingEnabled()) then
				GG.resetUpgrades = true
				spEcho("GAME : upgrades reset!") 
			else
				spEcho("GAME : RESETUPGRADES command requires cheat mode.")
			end
		end

	end
end

function gadget:RecvLuaMsg(msg, playerId)
	local pName,active,spectator,teamId,allyId,_,_,_,_,_ = spGetPlayerInfo(playerId)
	processExternalCommand(msg,playerId,pName,teamId,allyId, active,spectator)
end
