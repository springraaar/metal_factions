
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Unit Drone Production Button",
    desc      = "Adds a button that toggles drone production",
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
local spSetUnitRulesParam = Spring.SetUnitRulesParam

local msx = Game.mapSizeX
local msz = Game.mapSizeZ
local min = math.min
local max = math.max

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("lualibs/custom_cmd.lua")

local enableDroneProductionList = {}


local droneProductionCmdDesc = {
	id      = CMD_DRONEPRODUCTION,
	type    = CMDTYPE.ICON_MODE,
	name    = 'Production',
	cursor  = 'Production',
	action  = 'Production',
	tooltip = 'Drone Production Toggle',
	params  = { '0', 'Drones OFF', 'Drones ON'}
}
  
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local function updateButton(unitID, statusStr)
	local cmdDescID = spFindUnitCmdDesc(unitID, CMD_DRONEPRODUCTION)
	if (cmdDescID == nil) then
		return
	end

	local tooltip
	if (statusStr == '1') then
		tooltip = 'Drone production ON'
	else
		tooltip = 'Drone production OFF'
	end

	droneProductionCmdDesc.params[1] = statusStr

	spEditUnitCmdDesc(unitID, cmdDescID, { 
		params  = droneProductionCmdDesc.params, 
		tooltip = tooltip,
	})
end

local function addDroneProductionCmdDesc(unitID)
	if (spFindUnitCmdDesc(unitID, CMD_DRONEPRODUCTION)) then
		return  -- already exists
	end

	enableDroneProductionList[unitID] = true
	droneProductionCmdDesc.params[1] = '1'
	spInsertUnitCmdDesc(unitID, CMD_DRONEPRODUCTION, droneProductionCmdDesc)
	updateButton(unitID, ''..1)
end

local function removeDroneProductionCmdDesc(unitID)
	local cmdDescID = spFindUnitCmdDesc(unitID, CMD_DRONEPRODUCTION)
	if (cmdDescID) then
		enableDroneProductionList[unitID] = nil
		spRemoveUnitCmdDesc(unitID, cmdDescID)
	end
end


local function droneProductionCommand(unitID, unitDefID, cmdParams, teamID)
	if (enableDroneProductionList[unitID]) then
		local status
		if cmdParams[1] == 1 then
			status = '1'
			-- Spring.Echo("drones enabled")
			spSetUnitRulesParam(unitID,"droneProduction", 1, {public = true})
		else
			status = '0'
			-- Spring.Echo("drones disabled")
			spSetUnitRulesParam(unitID,"droneProduction", 0, {public = true})
		end
		updateButton(unitID, status)
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:Initialize()
	gadgetHandler:RegisterCMDID(CMD_DRONEPRODUCTION)
end

function gadget:UnitDestroyed(unitID, _, teamID)
	enableDroneProductionList[unitID] = nil
end


function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, _)
	local returnvalue
	if cmdID ~= CMD_DRONEPRODUCTION then
		return true
	end
	droneProductionCommand(unitID, unitDefID, cmdParams, teamID)  
	return false
end

function gadget:Shutdown()
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		removeDroneProductionCmdDesc(unitID)
	end
end

-- periodically check that units that spawn drones can toggle drone production
function gadget:GameFrame(n)
	if (n%150 == 0) then
		local droneOwnersDrones = GG.droneOwnersDrones

		for uId,data in pairs(droneOwnersDrones) do
			if next(data) == nil then
				removeDroneProductionCmdDesc(uId)
			else
				addDroneProductionCmdDesc(uId)
			end	
		end
		
		for uId,_ in pairs(enableDroneProductionList) do
			if not droneOwnersDrones[uId] then
				removeDroneProductionCmdDesc(uId)
			end
		end
	end
end



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
