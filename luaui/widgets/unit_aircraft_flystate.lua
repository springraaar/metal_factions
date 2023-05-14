
function widget:GetInfo()
  return {
    name      = "Aircraft Fly State",
    desc      = "Sets some aircraft to fly when idling by default.",
    author    = "raaar",
    date      = "2022",
    license   = "PD",
    layer     = 1,
    enabled   = true
  }
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGiveOrderToUnit  = Spring.GiveOrderToUnit

local defaultFlyState = {
-------------------- AVEN
	[UnitDefNames["aven_atlas_l"].id] = 0,
	[UnitDefNames["aven_atlas"].id] = 0,
	[UnitDefNames["aven_atlas_b"].id] = 0,
	[UnitDefNames["aven_transport_drone"].id] = 0,
-------------------- GEAR
	[UnitDefNames["gear_carrier_l"].id] = 0,
	[UnitDefNames["gear_carrier"].id] = 0,
	[UnitDefNames["gear_carrier_b"].id] = 0,
	[UnitDefNames["gear_transport_drone"].id] = 0,
-------------------- CLAW	
	[UnitDefNames["claw_mover_l"].id] = 0,
	[UnitDefNames["claw_mover"].id] = 0,
	[UnitDefNames["claw_mover_b"].id] = 0,
	[UnitDefNames["claw_transport_drone"].id] = 0,
-------------------- SPHERE	
	[UnitDefNames["sphere_lifter_l"].id] = 0,
	[UnitDefNames["sphere_lifter"].id] = 0,
	[UnitDefNames["sphere_lifter_b"].id] = 0,
	[UnitDefNames["sphere_transport_drone"].id] = 0	
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	if Spring.GetSpectatingState() or Spring.IsReplay() then
		widgetHandler:RemoveWidget()
		return true
	end
	-- change default fly state for all aircraft to "fly"
	for udId,ud in pairs(UnitDefs) do
		if ud.canFly then
			defaultFlyState[udId] = 0
		end 
	end
end

-- enforce default fly idle states
function widget:UnitCreated(unitId, unitDefId, teamId)
	if defaultFlyState[unitDefId] then
		--Spring.Echo("ID="..unitDefId)
		spGiveOrderToUnit(unitId, CMD.IDLEMODE, {defaultFlyState[unitDefId]}, {})
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
