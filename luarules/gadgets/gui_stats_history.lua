function gadget:GetInfo()
   return {
      name = "Stats History",
      desc = "Tracks how relevant metrics evolve over the course of the game.",
      author = "raaar",
      date = "2021",
      license = "PD",
      layer = 0,
      enabled = true,
   }
end

include("lualibs/util.lua")


local spGetUnitTeam = Spring.GetUnitTeam
local spGetAllyTeamList = Spring.GetAllyTeamList
local spGetAllUnits = Spring.GetAllUnits
local spGetTeamUnits = Spring.GetTeamUnits
local spGetUnitAllyTeam = Spring.GetUnitAllyTeam
local spGetUnitDefID = Spring.GetUnitDefID
local spGetTeamResources = Spring.GetTeamResources

local CHECK_DELAY_FRAMES = 30*10	-- every 10s


local dataPerFrame = {}
local maxAllyTeamUnitValue = 0
local maxAllyTeamResourceIncome = 0

GG.statsHistory = {
	dataPerFrame = dataPerFrame
}

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

-- register metrics a few times per minute
function gadget:GameFrame(n)
	if n > 0 and math.fmod(n,CHECK_DELAY_FRAMES) == 0 then

		local unitValuePerAllyTeam = {}
		local resourceIncomePerAllyTeam = {}
	
		local allyTeamList = spGetAllyTeamList()
		
		for i=1,#allyTeamList do
			local aId = allyTeamList[i]
	        unitValuePerAllyTeam[aId] = 0
	        resourceIncomePerAllyTeam[aId] = 0
		end

		for _,allyId in ipairs(allyTeamList) do
			local teamList = spGetTeamList(allyId)
			local resourceIncome = 0
			local unitValue = 0
			
			for i=1,#teamList do
				local id = teamList[i]
				
				if id ~= Spring.GetGaiaTeamID() then
			        
			        -- update unit value	
			       	local ud = nil
					local udId = nil
					local cost =  nil
				    for _,uId in ipairs(spGetTeamUnits(id)) do
						local _,_,_,_,progress = spGetUnitHealth(uId) 
						progress = progress or 0
				    
				    	if progress > 0.85 then
					    	udId = spGetUnitDefID(uId)
							if (not unitDefIdsToIgnore[udId]) then
					    		ud = UnitDefs[udId]
					    		cost = getWeightedCost(ud)
						    	unitValue = unitValue + cost
					    	end
				    	end
				    end

					-- update resource income					
					local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(id,"metal")
					local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(id,"energy")
					resourceIncome = resourceIncome + incomeM + incomeE/60
				end
			end
		
			if (resourceIncome > maxAllyTeamResourceIncome) then
				maxAllyTeamResourceIncome = resourceIncome
			end 
			if (unitValue > maxAllyTeamUnitValue) then
				maxAllyTeamUnitValue = unitValue
			end 
			
			unitValuePerAllyTeam[allyId] = unitValue
			resourceIncomePerAllyTeam[allyId] = resourceIncome
		end
		
		table.insert(dataPerFrame, {
			frame = n,
			unitValuePerAllyTeam = unitValuePerAllyTeam,
			resourceIncomePerAllyTeam = resourceIncomePerAllyTeam
		})
		
		GG.statsHistory.maxFrame = n
		GG.statsHistory.maxAllyTeamUnitValue = maxAllyTeamUnitValue
		GG.statsHistory.maxAllyTeamResourceIncome = maxAllyTeamResourceIncome
	end
end

