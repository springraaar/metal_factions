function gadget:GetInfo()
	return {
		name			= "Disable Buildoptions",
		desc			= "Disables wind or tidal generators according to map attributes.",
		author		= "quantum, modified by raaar",
		date			= "May 11, 2008",
		license	 = "GNU GPL, v2 or later",
		layer		 = 0,
		enabled	 = true
	}
end

--------------------------------------------------------------------------------
--config
--------------------------------------------------------------------------------

local MIN_AVG_WIND = 9
local MIN_TIDAL = 10

--------------------------------------------------------------------------------
--speedups
--------------------------------------------------------------------------------

local FindUnitCmdDesc = Spring.FindUnitCmdDesc
local disableWind, disableTidal
--values: {unitID, reason,}
local alwaysDisableTable = {}

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------


if (not gadgetHandler:IsSyncedCode()) then
	return false
end


local function DisableBuildButtons(unitID, disableTable)
	for _, disable in ipairs(disableTable) do
		local cmdDescID = Spring.FindUnitCmdDesc(unitID, -disable[1])
		if (cmdDescID) then
			local cmdArray = {disabled = true, tooltip = disable[2]}
			Spring.EditUnitCmdDesc(unitID, cmdDescID, cmdArray)
		end
	end
end

function gadget:Initialize()
	disableWind = ((Game.windMax + Game.windMin) / 2) < MIN_AVG_WIND
	if (disableWind) then
		table.insert(alwaysDisableTable, {UnitDefNames["aven_wind_generator"].id, "Unit disabled: Wind is too weak on this map.",})
		table.insert(alwaysDisableTable, {UnitDefNames["gear_wind_generator"].id, "Unit disabled: Wind is too weak on this map.",})
		table.insert(alwaysDisableTable, {UnitDefNames["claw_wind_generator"].id, "Unit disabled: Wind is too weak on this map.",})
	end
	
	disableTidal = Game.tidal < MIN_TIDAL
	if (disableTidal) then
		table.insert(alwaysDisableTable, {UnitDefNames["aven_tidal_generator"].id, "Unit disabled: Tides are too weak on this map.",})
		table.insert(alwaysDisableTable, {UnitDefNames["gear_tidal_generator"].id, "Unit disabled: Tides are too weak on this map.",})
		table.insert(alwaysDisableTable, {UnitDefNames["claw_tidal_generator"].id, "Unit disabled: Tides are too weak on this map.",})
		table.insert(alwaysDisableTable, {UnitDefNames["sphere_tidal_generator"].id, "Unit disabled: Tides are too weak on this map.",})
	end	
end

function gadget:UnitCreated(unitID, unitDefID)
	local disableTable = {}
	
	for key, value in ipairs(alwaysDisableTable) do
		disableTable[key] = value
	end
	
	DisableBuildButtons(unitID, disableTable)
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

