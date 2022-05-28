
function widget:GetInfo()
  return {
    name      = "Factories Hold Position",
    desc      = "Sets ground factories to hold position.",
    author    = "raaar",
    date      = "2021",
    license   = "PD",
    layer     = 1,
    enabled   = false
  }
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGiveOrderToUnit  = Spring.GiveOrderToUnit

local registered = {
-------------------- AVEN
	[UnitDefNames["aven_light_plant"].id] = 1,
	[UnitDefNames["aven_adv_kbot_lab"].id] = 1,
	[UnitDefNames["aven_adv_vehicle_plant"].id] = 1,
	[UnitDefNames["aven_shipyard"].id] = 1,
	[UnitDefNames["aven_adv_shipyard"].id] = 1,
	[UnitDefNames["aven_hovercraft_platform"].id] = 1,
	
-------------------- GEAR
	[UnitDefNames["gear_light_plant"].id] = 1,
	[UnitDefNames["gear_adv_kbot_lab"].id] = 1,
	[UnitDefNames["gear_adv_vehicle_plant"].id] = 1,
	[UnitDefNames["gear_shipyard"].id] = 1,
	[UnitDefNames["gear_adv_shipyard"].id] = 1,
	[UnitDefNames["gear_hydrobot_plant"].id] = 1,
	
-------------------- CLAW	
	[UnitDefNames["claw_light_plant"].id] = 1,
	[UnitDefNames["claw_adv_kbot_plant"].id] = 1,
	[UnitDefNames["claw_adv_vehicle_plant"].id] = 1,
	[UnitDefNames["claw_shipyard"].id] = 1,
	[UnitDefNames["claw_adv_shipyard"].id] = 1,
	[UnitDefNames["claw_spinbot_plant"].id] = 1,
	
-------------------- SPHERE	
	[UnitDefNames["sphere_light_factory"].id] = 1,
	[UnitDefNames["sphere_adv_kbot_factory"].id] = 1,
	[UnitDefNames["sphere_adv_vehicle_factory"].id] = 1,
	[UnitDefNames["sphere_shipyard"].id] = 1,
	[UnitDefNames["sphere_adv_shipyard"].id] = 1,
	[UnitDefNames["sphere_sphere_factory"].id] = 1
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	if Spring.GetSpectatingState() or Spring.IsReplay() then
		widgetHandler:RemoveWidget()
		return true
	end
end

-- units on the "registered" set are forced to hold position when created
function widget:UnitCreated(unitId, unitDefId, teamId)
	if registered[unitDefId] then
		--Spring.Echo("ID="..unitDefId)
		spGiveOrderToUnit(unitId, CMD.MOVE_STATE, {0}, {})
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
