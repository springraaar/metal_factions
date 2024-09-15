
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Unit LOF Obstacle Avoidance Handler",
    desc      = "Adds a button that sets the line-of-fire obstacle check/avoidance mode and controls its behavior",
    author    = "raaar",
    date      = "2024",
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
local spGiveOrderToUnit = Spring.GiveOrderToUnit

local spGetUnitWeaponState = Spring.GetUnitWeaponState
local spSetUnitWeaponState = Spring.SetUnitWeaponState

local min = math.min
local max = math.max


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("lualibs/custom_cmd.lua")

local unitNames = {}

local lOFObsAvoidanceCmdDesc = {
	id      = CMD_LOFOBSAVOIDANCE,
	type    = CMDTYPE.ICON_MODE,
	name    = 'LOF Obstacle Avoidance',
	action  = 'lofobsavoidance',
	tooltip = 'Line-of-Fire Obstacle Avoidance Mode : whether to use default behavior or avoid firing through walls and wreckage',
	params  = { '0', 'Fire-Thru', 'Avoid'}
}
 
originalUnitDefWeaponAvoidFlags={}			-- {uDId : {wNum : flags}}
avoidanceUnitDefWeaponAvoidFlags={}			-- {uDId : {wNum : flags}}

local featureFlag = Game.collisionFlags.noFeatures		-- 4 
local neutralFlag = Game.collisionFlags.noNeutrals		-- 8


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- https://stackoverflow.com/a/32389020
local OR, XOR, AND = 1, 3, 4
local function bitOp(a, b, op)
   local r, m, s = 0, 2^31
   repeat
      s,a,b = a+b+m, a%m, b%m
      r,m = r + m*op%(s-a-b), m/2
   until m < 1
   return r
end


local function addLOFObsAvoidanceCmdDesc(unitID)
	if (spFindUnitCmdDesc(unitID, CMD_LOFOBSAVOIDANCE)) then
		return  -- already exists
	end

	spInsertUnitCmdDesc(unitID, CMD_LOFOBSAVOIDANCE, lOFObsAvoidanceCmdDesc)
end


local function updateButton(unitID, statusStr)
	local cmdDescID = spFindUnitCmdDesc(unitID, CMD_LOFOBSAVOIDANCE)
	if (cmdDescID == nil) then
		return
	end

	local tooltip
	if (statusStr == '1') then
		tooltip = 'Line-of-Fire Obstacle Avoidance On : Don\'t engage enemies behind walls, wrecks, rocks, etc.'
	else
		tooltip = 'Line-of-Fire Obstacle Avoidance Off : Default behavior (generally engage / fire-through)'
	end

	lOFObsAvoidanceCmdDesc.params[1] = statusStr

	spEditUnitCmdDesc(unitID, cmdDescID, { 
		params  = lOFObsAvoidanceCmdDesc.params, 
		tooltip = tooltip,
	})
end


local function lOfObsAvoidanceCommand(unitID, unitDefID, cmdParams, teamID)
	local ud = UnitDefs[unitDefID]
	if (unitNames[ud.name]) then

		local status
		if cmdParams[1] == 1 then
			status = '1'
			--Spring.Echo("LOF obstacle avoidance enabled")

			local avoidanceFlagsMap = avoidanceUnitDefWeaponAvoidFlags[unitDefID]
			if (avoidanceFlagsMap) then
				for wNum,flags in pairs(avoidanceFlagsMap) do
					--Spring.Echo(ud.name.." wNum="..wNum.." avoidFlags="..flags)
					spSetUnitWeaponState(unitID, wNum, "avoidFlags",flags)
				end
			end
		else
			status = '0'
			--Spring.Echo("LOF obstacle avoidance disabled")

			local originalFlagsMap = originalUnitDefWeaponAvoidFlags[unitDefID]
			if (originalFlagsMap) then
				for wNum,flags in pairs(originalFlagsMap) do
					--Spring.Echo(ud.name.." wNum="..wNum.." avoidFlags="..flags)
					spSetUnitWeaponState(unitID, wNum, "avoidFlags",flags)
				end
			end
		end
		updateButton(unitID, status)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:Initialize()
	for _,ud in pairs(UnitDefs) do
		if ud.canAttack then
			-- assume all units with non-fake weapons have this command, for now
			if ud.weapons and ud.weapons[1] and ud.weapons[1].weaponDef then
				local wd=WeaponDefs[ud.weapons[1].weaponDef]
		    	if wd.isShield == false and wd.description ~= "No Weapon" then
					unitNames[ud.name] = true
					originalUnitDefWeaponAvoidFlags[ud.id]={}
					avoidanceUnitDefWeaponAvoidFlags[ud.id]={}
				end
		    end
		end
	end

	gadgetHandler:RegisterCMDID(CMD_LOFOBSAVOIDANCE)
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local teamID = spGetUnitTeam(unitID)
		local unitDefID = spGetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
end

function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
	local ud = UnitDefs[unitDefID]
	if (unitNames[ud.name]) then

		-- initialize the unit LOF avoidance flags reference if necessary
		-- do it here because there's no way to get this from the unitdefs directly
		if #originalUnitDefWeaponAvoidFlags[ud.id] == 0 then
			local originalFlagsMap = originalUnitDefWeaponAvoidFlags[ud.id]
			local avoidanceFlagsMap = avoidanceUnitDefWeaponAvoidFlags[ud.id]
			for wNum,props in pairs(ud.weapons) do
				local wd=WeaponDefs[props.weaponDef]
				if wd.isShield == false and wd.description ~= "No Weapon" then
					local flags = spGetUnitWeaponState(unitID, wNum, "avoidFlags")
					--Spring.Echo(ud.name.." wNum="..wNum.." avoidFlags="..flags.." feature="..featureFlag.." neutral="..neutralFlag)
					originalFlagsMap[wNum] = flags
					avoidanceFlagsMap[wNum]= bitOp(bitOp(flags, featureFlag, OR),neutralFlag,OR)
				end
			end
		end

		-- set starting mode, disabled by default
		local mode = 0
		
		addLOFObsAvoidanceCmdDesc(unitID)
		updateButton(unitID, ''..mode)
	end
end


function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, _)
	if cmdID ~= CMD_LOFOBSAVOIDANCE then
		return true
	end
	lOfObsAvoidanceCommand(unitID, unitDefID, cmdParams, teamID)  
	return false
end

function gadget:Shutdown()
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local cmdDescID = spFindUnitCmdDesc(unitID, CMD_LOFOBSAVOIDANCE)
		if (cmdDescID) then
			spRemoveUnitCmdDesc(unitID, cmdDescID)
		end
	end
end



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
