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

local SURRENDER_THRESHOLD = 0.040 -- 4% of the "strength" of the strongest team
local AI_SURRENDER_FACTOR = 0.5
local NO_COMMANDER_SURRENDER_FACTOR = 0.5
local CHECK_DELAY_FRAMES = 120

local unitCostPerAllyTeam = {}
local aliveCommandersPerAllyTeam = {}

local strongestAllyTeamId = null 
local defeatedAllyIds = {}

-------------------------- SYNCED CODE ONLY
if (not gadgetHandler:IsSyncedCode()) then
	return false
end

-- surrender teams that are very weak compared to the strongest opponent
function gadget:GameFrame(n)
	if n > 300 and math.fmod(n,CHECK_DELAY_FRAMES) == 5 then
		
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
		local cost =  nil
	    for _,uId in ipairs(allUnits) do
			local _,_,_,_,progress = spGetUnitHealth(uId) 
			progress = progress or 0
	    
	    	if progress > 0.85 then
		    	allyId = Spring.GetUnitAllyTeam(uId)
		    	ud = UnitDefs[Spring.GetUnitDefID(uId)]
		    	cost = getWeightedCost(ud)
		    	
		    	unitCostPerAllyTeam[allyId] = unitCostPerAllyTeam[allyId] + cost
		    	if (isCommander(ud)) then
		    		aliveCommandersPerAllyTeam[allyId] = aliveCommandersPerAllyTeam[allyId] + 1 
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
				local _,_,isDead,isAI,side,allyId = spGetTeamInfo(id)
		        
		        local teamValueMod = aliveCommandersPerAllyTeam[allyId] > 0 and 1 or NO_COMMANDER_SURRENDER_FACTOR
		        teamValueMod = teamValueMod * (isAI and AI_SURRENDER_FACTOR or 1)   
		        
		        if maxAllyTeamCost > 0 and not isDead then 
			        teamValueMod = teamValueMod * unitCostPerAllyTeam[allyId] / maxAllyTeamCost
			        
					-- if severely disadvantaged, surrender        
					if teamValueMod < SURRENDER_THRESHOLD then
						if ( not defeatedAllyIds[allyId] ) then
							Spring.SendMessage("Team "..allyId.." has been DEFEATED.")
						end
						defeatedAllyIds[allyId] = true
						Spring.KillTeam(id)
					end
				end
			end
		end
	end
end

