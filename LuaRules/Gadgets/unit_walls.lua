function gadget:GetInfo()
   return {
      name = "Walls",
      desc = "Handles wall section ownership.",
      author = "raaar",
      date = "2018",
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


local wallDefIds = {
	[UnitDefNames["aven_fortification_wall"].id] = true,
	[UnitDefNames["gear_fortification_wall"].id] = true,
	[UnitDefNames["claw_fortification_wall"].id] = true,
	[UnitDefNames["sphere_fortification_wall"].id] = true,
	[UnitDefNames["aven_large_fortification_wall"].id] = true,
	[UnitDefNames["gear_large_fortification_wall"].id] = true,
	[UnitDefNames["claw_large_fortification_wall"].id] = true,
	[UnitDefNames["sphere_large_fortification_wall"].id] = true,
	[UnitDefNames["aven_fortification_gate"].id] = true,
	[UnitDefNames["gear_fortification_gate"].id] = true,
	[UnitDefNames["claw_fortification_gate"].id] = true,
	[UnitDefNames["sphere_fortification_gate"].id] = true
}

-- set built wall sections to neutral
function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	if wallDefIds[unitDefID] then
		Spring.SetUnitNeutral(unitID,true)
	end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if wallDefIds[unitDefID] then
		Spring.SetUnitNeutral(unitID,true)
	end
end

function gadget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
	if wallDefIds[unitDefID] then
		Spring.SetUnitNeutral(unitID,true)
	end
end



