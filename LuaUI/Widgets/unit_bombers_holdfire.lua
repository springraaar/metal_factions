
function widget:GetInfo()
  return {
    name      = "Bombers Hold Fire",
    desc      = "Sets some bomber aircraft to hold fire.",
    author    = "raaar",
    date      = "2016",
    license   = "PD",
    layer     = 1,
    enabled   = true
  }
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGiveOrderToUnit  = Spring.GiveOrderToUnit

local bombers = {
-------------------- AVEN
	[UnitDefNames["aven_thunder"].id] = 1,
	[UnitDefNames["aven_ace"].id] = 1,
-------------------- GEAR
	[UnitDefNames["gear_shadow"].id] = 1,
	[UnitDefNames["gear_cascade"].id] = 1,
-------------------- CLAW	

-------------------- SPHERE	
	[UnitDefNames["sphere_manta"].id] = 1
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	if Spring.GetSpectatingState() or Spring.IsReplay() then
		widgetHandler:RemoveWidget()
		return true
	end
end

-- units on the "bombers" set are forced to hold fire when created
function widget:UnitCreated(unitId, unitDefId, teamId)
	if bombers[unitDefId] then
		--Spring.Echo("ID="..unitDefId)
		spGiveOrderToUnit(unitId, CMD.FIRE_STATE, {0}, {})
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
