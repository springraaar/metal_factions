function gadget:GetInfo()
   return {
      name = "Surrenderer",
      desc = "Prevents having to kill every last enemy unit to end the game.",
      author = "raaar",
      date = "October, 2016",
      license = "PD",
      layer = 0,
      enabled = true,
   }
end

include("LuaLibs/Util.lua")


local spSetTeamRulesParam = Spring.SetTeamRulesParam
local spSetTeamShareLevel = Spring.SetTeamShareLevel 

local SURRENDER_THRESHOLD = 0.040 -- 4% of the "strength" of the strongest team
local AI_SURRENDER_FACTOR = 0.5
local NO_COMMANDER_SURRENDER_FACTOR = 0.5
local DISCONNECT_SURRENDER_FACTOR = 0.1
local CHECK_DELAY_FRAMES = 120

local unitCostPerAllyTeam = {}
local aliveCommandersPerAllyTeam = {}

local strongestAllyTeamId = nil 
local defeatedAllyIds = {}

local unitDefIdsToIgnore = {
	[UnitDefNames["target"].id] = true,
	[UnitDefNames["cs_beacon"].id] = true,
	[UnitDefNames["scoper_beacon"].id] = true,
	[UnitDefNames["aven_fortification_wall"].id] = true,
	[UnitDefNames["aven_fortification_gate"].id] = true,
	[UnitDefNames["aven_large_fortification_wall"].id] = true,
	[UnitDefNames["gear_fortification_wall"].id] = true,
	[UnitDefNames["gear_fortification_gate"].id] = true,
	[UnitDefNames["gear_large_fortification_wall"].id] = true,
	[UnitDefNames["claw_fortification_wall"].id] = true,
	[UnitDefNames["claw_fortification_gate"].id] = true,
	[UnitDefNames["claw_large_fortification_wall"].id] = true,
	[UnitDefNames["sphere_fortification_wall"].id] = true,
	[UnitDefNames["sphere_fortification_gate"].id] = true,
	[UnitDefNames["sphere_large_fortification_wall"].id] = true
}

-------------------------- SYNCED CODE ONLY
if (not gadgetHandler:IsSyncedCode()) then
	return false
end

-- surrender teams that are very weak compared to the strongest opponent
function gadget:GameFrame(n)
	if (not GG.sandbox) and n > 300 and n%CHECK_DELAY_FRAMES == 5 then
		local teamCommanderIds = {}
		local allyTeamList = Spring.GetAllyTeamList()
		local allUnits = spGetAllUnits()
		local maxAllyTeamCost = 0
		
		for i=1,#allyTeamList do
			local aId = allyTeamList[i]
			unitCostPerAllyTeam[aId] = 0
			aliveCommandersPerAllyTeam[aId] = 0
		end
		
		local allyId = 0
		local ud = nil
		local udId = nil
		local cost =  nil
	    for _,uId in ipairs(allUnits) do
			local _,_,_,_,progress = spGetUnitHealth(uId) 
			progress = progress or 0
	    
	    	if progress > 0.85 then
		    	teamId = Spring.GetUnitTeam(uId)
		    	allyId = Spring.GetUnitAllyTeam(uId)
		    	udId = Spring.GetUnitDefID(uId)
				if (not unitDefIdsToIgnore[udId]) then
					ud = UnitDefs[udId]
					cost = getWeightedCost(ud)
					
					unitCostPerAllyTeam[allyId] = unitCostPerAllyTeam[allyId] + cost
					if (isCommander(ud)) then
						teamCommanderIds[teamId] = uId
						aliveCommandersPerAllyTeam[allyId] = aliveCommandersPerAllyTeam[allyId] + 1 
					end
				end
			end
		end
		
		
		for _,allyId in ipairs(allyTeamList) do
			if (unitCostPerAllyTeam[allyId] > maxAllyTeamCost) then
				maxAllyTeamCost = unitCostPerAllyTeam[allyId]
			end 
		end
		
		local teamList = spGetTeamList()
		for i=1,#teamList do
			local id = teamList[i]
			
			if id ~= Spring.GetGaiaTeamID() then
				local _,leaderId,isDead,isAI,side,allyId = spGetTeamInfo(id)
		        
		        local playersDisconnected = true
		        if isAI then
		        	playersDisconnected = false
		        else
			        local playerList = spGetPlayerList(id)
					if playerList then
						for j = 1, #playerList do
							local name,active,spec = spGetPlayerInfo(playerList[j])
							if not spec then
								if active then
									playersDisconnected = false
								end
							end
						end
					end
		        end
				--Spring.Echo('team '..tostring(id).. ' has leader '..tostring(leaderId))
				-- when a player resigns, explode its commander
				if ((isDead or leaderId < 0) and teamCommanderIds[id] and teamCommanderIds[id] > 0) then
					spDestroyUnit(teamCommanderIds[id])
		        end

				-- set resource sharing threshold to minimum for dead teams to let allies spend its stores		        
		        if isDead then
					spSetTeamShareLevel( id, "metal", 0) 
					spSetTeamShareLevel( id, "energy", 0)		        
		        end
		        
				local teamValueMod = aliveCommandersPerAllyTeam[allyId] > 0 and 1 or NO_COMMANDER_SURRENDER_FACTOR
				teamValueMod = teamValueMod * (isAI and AI_SURRENDER_FACTOR or 1)   
				if playersDisconnected then
					teamValueMod = teamValueMod * DISCONNECT_SURRENDER_FACTOR
				end
		        
				if maxAllyTeamCost > 0 and not isDead then 
					teamValueMod = teamValueMod * unitCostPerAllyTeam[allyId] / maxAllyTeamCost
			        
					-- if severely disadvantaged, surrender        
					if teamValueMod < SURRENDER_THRESHOLD then
						if ( not defeatedAllyIds[allyId] ) then
							Spring.SendMessage("Team "..allyId.." has been DEFEATED : resigning player "..id)
							if isAI then
								spSetTeamRulesParam(id,"ai_resigned","1")
							end
						end
						defeatedAllyIds[allyId] = true
						Spring.KillTeam(id)
					end
				end
			end
		end
	end
end


function gadget:PlayerChanged(playerId)
	pInfo = Spring.GetPlayerInfo(playerId)
	Spring.Echo('player '..tostring(playerId)..' changed : active='..tostring(pInfo.active)..' spectator='..tostring(pInfo.spectator))
	
end