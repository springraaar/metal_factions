function gadget:GetInfo()
   return {
      name = "Wind Generator Gadget",
      desc = "Handles wind generator income.",
      author = "raaar",
      date = "2015",
      license = "PD",
      layer = 0,
      enabled = true,
   }
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
    return
end


local WIND_EXTRA_INCOME_MULTIPLIER = 0.6
local WIND_ALTITUDE_EXTRA_INCOME_MULTIPLIER = 0.53 -- up to 20% more total output due to altitude 
local windGeneratorIds = {}
local windGeneratorUnitDefIds = {}
local INCOME_DELAY = 15

local groundMin,groundMax = 0
local spGetWind = Spring.GetWind
local spAddUnitResource = Spring.AddUnitResource
local spGetGroundHeight = Spring.GetGroundHeight
local spGetUnitHealth = Spring.GetUnitHealth

-- load wind gen unitdef ids
function gadget:Initialize()
	for _,ud in pairs(UnitDefs) do
		if ud.name == "aven_wind_generator" or ud.name == "gear_wind_generator" or ud.name == "claw_wind_generator" then
			windGeneratorUnitDefIds[ud.id] = true
		end
	end

	-- make wind generation depend on ground height and map profile?
	groundMin, groundMax = Spring.GetGroundExtremes()
	groundMin, groundMax = math.max(groundMin,0), math.max(groundMax,1)
end

-- mark wind generators
function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	
	if windGeneratorUnitDefIds[unitDefID] then
		windGeneratorIds[unitID] = true
	end
end

-- extra income for wind generators
function gadget:GameFrame(n)
	if (n%INCOME_DELAY ~= 0) then
		return
	end

	local _, _, _, windStrength, x, _, z = spGetWind()
	windStrength = (windStrength / 2) * WIND_EXTRA_INCOME_MULTIPLIER
	local factor = 1
	local x,y,z = 0
	for unitID,_ in pairs(windGeneratorIds) do
		factor = 1
		x,y,z = Spring.GetUnitPosition(unitID)
		local _,_,_,_,bp = spGetUnitHealth(unitID)
		if bp >= 1 then
			if y >= groundMax then
				factor = 1 + WIND_ALTITUDE_EXTRA_INCOME_MULTIPLIER
			elseif y < groundMin then
				factor = 1
			else
				factor = 1 + (y / groundMax) * WIND_ALTITUDE_EXTRA_INCOME_MULTIPLIER
			end
			
			--Spring.Echo("alt="..string.format("%.0f",y).." factor="..string.format("%.2f",factor).." windStrength="..string.format("%.1f",windStrength))
			
			if (factor > 1) then
				spAddUnitResource(unitID, "e", windStrength * factor)
			else
				spAddUnitResource(unitID, "e", windStrength)
			end
		end
	end
end

-- cleanup when wind generators are destroyed
function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)

	-- remove base collision volume from table when unit is destroyed
	if windGeneratorIds[unitID] then
		windGeneratorIds[unitID] = nil
	end
end


