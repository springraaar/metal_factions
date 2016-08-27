-- $Id: unit_disable_buildoptions.lua 3636 2009-01-02 22:57:43Z evil4zerggin $
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name			= "Disable Buildoptions",
		desc			= "Disables wind if wind is too low, units if waterdepth is not appropriate.",
		author		= "quantum",
		date			= "May 11, 2008",
		license	 = "GNU GPL, v2 or later",
		layer		 = 0,
		enabled	 = false	--	loaded by default?
	}
end

--------------------------------------------------------------------------------
--config
--------------------------------------------------------------------------------

local breakEvenWind = 9.1

--------------------------------------------------------------------------------
--speedups
--------------------------------------------------------------------------------

local FindUnitCmdDesc = Spring.FindUnitCmdDesc
local GetUnitPosition = Spring.GetUnitPosition
local GetGroundHeight = Spring.GetGroundHeight
local GetUnitPosition = Spring.GetUnitPosition
local disableWind
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
	disableWind = Game.windMax < breakEvenWind
	
	if (disableWind) then
		table.insert(alwaysDisableTable, {UnitDefNames["aven_wind_generator"].id, "Unit disabled: Wind is too weak on this map.",})
		table.insert(alwaysDisableTable, {UnitDefNames["gear_wind_generator"].id, "Unit disabled: Wind is too weak on this map.",})
		table.insert(alwaysDisableTable, {UnitDefNames["claw_wind_generator"].id, "Unit disabled: Wind is too weak on this map.",})
	end
end

function gadget:UnitCreated(unitID, unitDefID)
	local disableTable = {}
	local unitDef = UnitDefs[unitDefID]
	local posX, posY, posZ = GetUnitPosition(unitID)
	local groundheight = GetGroundHeight(posX, posZ)
	
	for key, value in ipairs(alwaysDisableTable) do
		disableTable[key] = value
	end
	
	--amph facs
	if (unitDef.isFactory and unitDef.buildOptions) then
		for _, buildoptionID in ipairs(unitDef.buildOptions) do
			if (UnitDefs[buildoptionID] and UnitDefs[buildoptionID].moveData) then
				local moveData = UnitDefs[buildoptionID].moveData
				if (moveData and moveData.family and moveData.depth) then
					if (moveData.family == "ship") then
						if (-groundheight < moveData.depth) then
							table.insert(disableTable, {buildoptionID, "Unit disabled: Water is too shallow here."})
						end
					elseif (moveData.family ~= "hover") then
						if (-groundheight > moveData.depth) then
							table.insert(disableTable, {buildoptionID, "Unit disabled: Water is too deep here."})
						end
					end
				end
			end
		end
	end
	
	DisableBuildButtons(unitID, disableTable)
end

-- AllowCommand is probably overkill

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

