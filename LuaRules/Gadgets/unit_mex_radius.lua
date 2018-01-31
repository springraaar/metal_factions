function gadget:GetInfo() 
  return { 
    name      = "Metal Extractor Radius Gadget", 
    desc      = "Increases extraction radius for some metal extractors.", 
    author    = "raaar",
    date      = "2018", 
    license   = "PD", 
    layer     = -5, 
    enabled   = true 
  } 
end 


local spSetUnitMetalExtraction = Spring.SetUnitMetalExtraction

local extractorRadius = Game.extractorRadius
local ADVANCED_EXTRACTOR_RADIUS_FACTOR = 1.3 
local MIN_EXTRACTOR_RADIUS = 32
local ADVANCED_EXTRACTOR_RADIUS = extractorRadius >= MIN_EXTRACTOR_RADIUS and (extractorRadius*ADVANCED_EXTRACTOR_RADIUS_FACTOR) or (MIN_EXTRACTOR_RADIUS*ADVANCED_EXTRACTOR_RADIUS_FACTOR) 
GG.ADVANCED_EXTRACTOR_RADIUS = ADVANCED_EXTRACTOR_RADIUS

local basicMexDefIds = {
	[UnitDefNames['aven_metal_extractor'].id] = true,
	[UnitDefNames['gear_metal_extractor'].id] = true,
	[UnitDefNames['claw_metal_extractor'].id] = true,
	[UnitDefNames['sphere_metal_extractor'].id] = true
}

local advMexDefIds = {
	[UnitDefNames['aven_moho_mine'].id] = true,
	[UnitDefNames['gear_moho_mine'].id] = true,
	[UnitDefNames['claw_moho_mine'].id] = true,
	[UnitDefNames['sphere_moho_mine'].id] = true,
	[UnitDefNames['aven_exploiter'].id] = true,
	[UnitDefNames['gear_exploiter'].id] = true,
	[UnitDefNames['claw_exploiter'].id] = true,
	[UnitDefNames['sphere_exploiter'].id] = true
}


GG.advMexDefIds = advMexDefIds

------------------------------------------------ SYNCED
if (gadgetHandler:IsSyncedCode()) then 


function gadget:UnitFinished(unitID, unitDefID, unitTeam, builderID) 
  	if (advMexDefIds[unitDefID]) then
  		local ud = UnitDefs[unitDefID]
    	-- apply modified extraction radius for moho mines and exploiters
   		spSetUnitMetalExtraction(unitID, ud.extractsMetal, ADVANCED_EXTRACTOR_RADIUS)
	end 
end


------------------------------------------------ UNSYNCED
else 

	-- do nothing

end
