function gadget:GetInfo()
   return {
      name = "Unit Extra Resources Gadget",
      desc = "Handles extra resource income/costs and wind generator bonuses.",
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

include("lualibs/constants.lua")

local windGeneratorIds = {}
local windGeneratorUnitDefIds = {}
local massBurnerUnitDefIds = {
	[UnitDefNames['gear_mass_burner'].id] = true
}
local massBurnerIds = {}
local fissionReactorUnitDefIds = {
	[UnitDefNames['sphere_fusion_reactor'].id] = true,
	[UnitDefNames['sphere_hardened_fission_reactor'].id] = true
}
local fissionReactorIds = {}

local INCOME_DELAY_FRAMES = 15

local MASS_BURNER_M_DRAIN_STEP = 0.2 / 2 
local FISSION_REACTOR_M_DRAIN_STEP = 0.5 / 2
local METAL_TO_ENERGY_CONVERSION = 60
local MASS_BURNER_E_EXTRA_STEP = MASS_BURNER_M_DRAIN_STEP * METAL_TO_ENERGY_CONVERSION
local FISSION_REACTOR_E_EXTRA_STEP = FISSION_REACTOR_M_DRAIN_STEP * METAL_TO_ENERGY_CONVERSION

local groundMin,groundMax,groundRef = 0
local spGetWind = Spring.GetWind
local spAddUnitResource = Spring.AddUnitResource
local spUseUnitResource = Spring.UseUnitResource
local spGetUnitResources = Spring.GetUnitResources
local spGetGroundHeight = Spring.GetGroundHeight
local spGetUnitHealth = Spring.GetUnitHealth
local spSetUnitRulesParam = Spring.SetUnitRulesParam 
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spGetUnitPosition = Spring.GetUnitPosition

local totalWindStrength = 0
local totalWindStrFrames = 0

-- load wind gen unitdef ids
function gadget:Initialize()
	for _,ud in pairs(UnitDefs) do
		if ud.name == "aven_wind_generator" or ud.name == "gear_wind_generator" or ud.name == "claw_wind_generator" or ud.name == "sphere_wind_generator" then
			windGeneratorUnitDefIds[ud.id] = true
		end
	end

	-- make wind generation depend on ground height and map profile?
	groundMin, groundMax = Spring.GetGroundExtremes()
	groundMin, groundMax = math.max(groundMin,0), math.max(groundMax,1)
	groundRef = GG.minMetalSpotAltitude
	--Spring.Echo("minMetalSpotAltitude="..GG.minMetalSpotAltitude.." groundRef="..groundRef)
end

-- mark relevant units when they finish
function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	
	if windGeneratorUnitDefIds[unitDefID] then
		windGeneratorIds[unitID] = true
	elseif massBurnerUnitDefIds[unitDefID] then
		massBurnerIds[unitID] = true
	elseif fissionReactorUnitDefIds[unitDefID] then
		fissionReactorIds[unitID] = true
	end
	
end

-- extra income for wind generators
function gadget:GameFrame(n)
	if (n%INCOME_DELAY_FRAMES ~= 0) then
		return
	end

	-------------------- update wind generators
	local _, _, _, windStrength, x, _, z = spGetWind()
	windStrength = (math.min(windStrength,WIND_STR_CAP) / 2)
	
	-- reduce wind strength to match the actual average it's supposed to have
	windStrength = windStrength * EXCESS_WIND_REDUCTION_MULT

	totalWindStrength = totalWindStrength + windStrength
	totalWindStrFrames = totalWindStrFrames + INCOME_DELAY_FRAMES
	--Spring.Echo(n.." avg wind="..(totalWindStrength * 30/totalWindStrFrames))
	
	local frac = 0
	local x,y,z = 0
	for unitID,_ in pairs(windGeneratorIds) do
		factor = 1
		x,y,z = Spring.GetUnitPosition(unitID)
		local _,_,_,_,bp = spGetUnitHealth(unitID)
		if bp >= 1 then
			if y >= groundMax then
				frac =  WIND_ALTITUDE_EXTRA_INCOME_FRACTION
			elseif y < groundRef then
				frac = 0
			else
				frac = ((y-groundRef) / (groundMax-groundRef)) * WIND_ALTITUDE_EXTRA_INCOME_FRACTION
			end
			spSetUnitRulesParam(unitID,"wind_altitude_frac",frac)
			
			-- also add the (MFmultiplier -1)*windStrength to account for the base output of windgens not actually being scaled by the engine
			-- multiply it again by x to account for the fact that the base value already received through builtin engine behavior is also higher than it should
			-- 1.6 * windS = (1.6 - 1) * x * windS + windS / EXCESS_WIND_REDUCTION_MULT
			-- 1.6 = 0.6x + 1.18  ---> x = 0.7
			spAddUnitResource(unitID, "e", (WIND_INCOME_MULTIPLIER -1) * 0.7 * windStrength + windStrength * WIND_INCOME_MULTIPLIER * frac)
			
			-- store averages
			local _,_,energyMake,_ = spGetUnitResources(unitID)
			local oldEMade = spGetUnitRulesParam(unitID,"energy_made")
			if (not oldEMade) then
				oldEMade = 0
			end
			local oldEMadeFrames = spGetUnitRulesParam(unitID,"energy_made_frames")
			if (not oldEMadeFrames) then
				oldEMadeFrames = 0
			end
			spSetUnitRulesParam(unitID,"energy_made",oldEMade+energyMake/2)
			spSetUnitRulesParam(unitID,"energy_made_frames",oldEMadeFrames+INCOME_DELAY_FRAMES)
		end
	end
	
	-------------------- update metal-draining energy generators
	for unitID,_ in pairs(massBurnerIds) do
		local _,_,_,_,bp = spGetUnitHealth(unitID)
		if bp >= 1 then
			if spUseUnitResource(unitID, 'm', MASS_BURNER_M_DRAIN_STEP ) then
				spAddUnitResource(unitID, 'e', MASS_BURNER_E_EXTRA_STEP)
			end
		end
	end
	for unitID,_ in pairs(fissionReactorIds) do
		local _,_,_,_,bp = spGetUnitHealth(unitID)
		if bp >= 1 then
			if spUseUnitResource(unitID, 'm', FISSION_REACTOR_M_DRAIN_STEP ) then
				spAddUnitResource(unitID, 'e', FISSION_REACTOR_E_EXTRA_STEP)
			end
		end
	end	
end

-- cleanup when relevant units are destroyed
function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if windGeneratorIds[unitID] then
		windGeneratorIds[unitID] = nil
	elseif massBurnerIds[unitID] then
		massBurnerIds[unitID] = nil
	elseif fissionReactorIds[unitID] then
		fissionReactorIds[unitID] = nil
	end
end


