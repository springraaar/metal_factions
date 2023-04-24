
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Unit MD Watch Handler",
    desc      = "Adds a button that sets the MD watch mode and controls its behavior",
    author    = "raaar",
    date      = "2023",
    license   = "PD",
    layer     = 3,
    enabled   = true
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
  return false  --  silent removal
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--Speed-ups

local spGetUnitDefID    = Spring.GetUnitDefID
local spGetUnitCommands = Spring.GetUnitCommands
local spFindUnitCmdDesc = Spring.FindUnitCmdDesc
local spSetUnitBuildSpeed = Spring.SetUnitBuildSpeed
local spInsertUnitCmdDesc = Spring.InsertUnitCmdDesc
local spEditUnitCmdDesc = Spring.EditUnitCmdDesc
local spRemoveUnitCmdDesc = Spring.RemoveUnitCmdDesc
local spGetUnitTeam = Spring.GetUnitTeam
local spGetGameFrame = Spring.GetGameFrame
local spGetUnitPosition = Spring.GetUnitPosition
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGetUnitDirection = Spring.GetUnitDirection
local msx = Game.mapSizeX
local msz = Game.mapSizeZ
local min = math.min
local max = math.max

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("lualibs/custom_cmd.lua")

local unitNames = {}
local enableMDWatchList = {}
GG.enableMDWatchList = enableMDWatchList

local MDWatchCmdDesc = {
	id      = CMD_MDWATCH,
	type    = CMDTYPE.ICON_MODE,
	name    = 'MD Watch',
	cursor  = 'mdwatch',
	action  = 'mdwatch',
	tooltip = 'Missile Defense Watch Mode : avoid firing at other units when enemy long range destroyable missiles are incoming',
	params  = { '0', 'MD Off', 'MD On'}
}
 

 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function addMDWatchCmdDesc(unitID)
	if (spFindUnitCmdDesc(unitID, CMD_MDWATCH)) then
		return  -- already exists
	end
	local insertID = 
		spFindUnitCmdDesc(unitID, CMD.CLOAK)      or
		spFindUnitCmdDesc(unitID, CMD.ONOFF)      or
		spFindUnitCmdDesc(unitID, CMD.TRAJECTORY) or
		spFindUnitCmdDesc(unitID, CMD.REPEAT)     or
		spFindUnitCmdDesc(unitID, CMD.MOVE_STATE) or
		spFindUnitCmdDesc(unitID, CMD.FIRE_STATE) or
		123456 -- back of the pack
	MDWatchCmdDesc.params[1] = '1'
	spInsertUnitCmdDesc(unitID, insertID + 1, MDWatchCmdDesc)
end


local function updateButton(unitID, statusStr)
	local cmdDescID = spFindUnitCmdDesc(unitID, CMD_MDWATCH)
	if (cmdDescID == nil) then
		return
	end

	local tooltip
	if (statusStr == '1') then
		tooltip = 'Missile Defense Watch On : Ignore other targets if there\'s enemy incoming rockets'
	else
		tooltip = 'Missile Defense Watch Off : Target all enemies normally'
	end

	MDWatchCmdDesc.params[1] = statusStr

	spEditUnitCmdDesc(unitID, cmdDescID, { 
		params  = MDWatchCmdDesc.params, 
		tooltip = tooltip,
	})
end


local function MDWatchCommand(unitID, unitDefID, cmdParams, teamID)
	local ud = UnitDefs[unitDefID]
	if (unitNames[ud.name]) then

		local status
		if cmdParams[1] == 1 then
			status = '1'
			-- Spring.Echo("MD watch enabled")
			enableMDWatchList[unitID] = 1
		else
			status = '0'
			-- Spring.Echo("MD watch disabled")
			enableMDWatchList[unitID] = 0
		end
		updateButton(unitID, status)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:Initialize()
	for _,ud in pairs(UnitDefs) do
		if ud.canAttack then
			if ud.weapons and ud.weapons[1] and ud.weapons[1].weaponDef then
				for wNum,w in pairs(ud.weapons) do
					local wd=WeaponDefs[w.weaponDef]
					if wd.customParams and wd.customParams.md == "1" then
						unitNames[ud.name] = true
					end
				end
		    end
		end
	end

	gadgetHandler:RegisterCMDID(CMD_MDWATCH)
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local teamID = spGetUnitTeam(unitID)
		local unitDefID = spGetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
end

function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
	local ud = UnitDefs[unitDefID]
	if (unitNames[ud.name]) then

		-- set starting mode, enabled by default
		local mode = 1
		enableMDWatchList[unitID] = mode
		
		addMDWatchCmdDesc(unitID)
		updateButton(unitID, ''..mode)
	end
end

function gadget:UnitDestroyed(unitID, _, teamID)
	enableMDWatchList[unitID] = nil
end



function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, _)
	if cmdID ~= CMD_MDWATCH then
		return true
	end
	MDWatchCommand(unitID, unitDefID, cmdParams, teamID)  
	return false
end

function gadget:Shutdown()
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local cmdDescID = spFindUnitCmdDesc(unitID, CMD_MDWATCH)
		if (cmdDescID) then
			spRemoveUnitCmdDesc(unitID, cmdDescID)
		end
	end
end



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
