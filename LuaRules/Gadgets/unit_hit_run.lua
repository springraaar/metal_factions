
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Unit Hit-n-Run Handler",
    desc      = "Adds a button that sets the hit-n-run mode and controls its behavior",
    author    = "raaar",
    date      = "2019",
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

CMD_HITNRUN = 33456

local enableHitNRunList = {}
local unitIdsThatFiredRecently = {}
local unitNames = {}
local REACTION_DELAY_FRAMES = 15
local RUN_LENGTH = 3000

local CMD_MOVE_STATE    = CMD.MOVE_STATE
local CMD_PATROL        = CMD.PATROL
local CMD_STOP          = CMD.STOP



local trackedCommands = {
	[CMD.ATTACK] = true,
	[CMD.FIGHT] = true
}


local enabledUnitNames = {
	aven_thunder = true,
	gear_shadow = true,
	gear_cascade = true,
	sphere_manta = true
}

local hitNRunCmdDesc = {
	id      = CMD_HITNRUN,
	type    = CMDTYPE.ICON_MODE,
	name    = 'Production',
	cursor  = 'Production',
	action  = 'Production',
	tooltip = 'Attack Mode : after firing, keep attacking or skip attack orders and retreat/keep moving',
	params  = { '0', 'Normal', 'Hit-n-Run'}
}
  
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function addHitNRunCmdDesc(unitID)
	if (spFindUnitCmdDesc(unitID, CMD_HITNRUN)) then
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
	hitNRunCmdDesc.params[1] = '1'
	spInsertUnitCmdDesc(unitID, insertID + 1, hitNRunCmdDesc)
end


local function updateButton(unitID, statusStr)
	local cmdDescID = spFindUnitCmdDesc(unitID, CMD_HITNRUN)
	if (cmdDescID == nil) then
		return
	end

	local tooltip
	if (statusStr == '1') then
		tooltip = 'Hit-and-Run enabled: after firing, cancel attack orders and retreat'
	else
		tooltip = 'Hit-and-Run disabled: keep attacking normally'
	end

	hitNRunCmdDesc.params[1] = statusStr

	spEditUnitCmdDesc(unitID, cmdDescID, { 
		params  = hitNRunCmdDesc.params, 
		tooltip = tooltip,
	})
end


local function hitNRunCommand(unitID, unitDefID, cmdParams, teamID)
	local ud = UnitDefs[unitDefID]
	if (unitNames[ud.name]) then

		local status
		if cmdParams[1] == 1 then
			status = '1'
			-- Spring.Echo("hit-n-run enabled")
			enableHitNRunList[unitID] = 1
		else
			status = '0'
			-- Spring.Echo("hit-n-run disabled")
			enableHitNRunList[unitID] = 0
		end
		updateButton(unitID, status)
	end
end

local function getRetreatPosition(x,z,dx,dz)
	local px,pz
	px = x - RUN_LENGTH * dx + 100
	px = max(300,min(msx-300,px))
	pz = z - RUN_LENGTH * dz + 100
	pz = max(300,min(msz-300,pz))
	return px,pz
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:Initialize()
	for _,ud in pairs(UnitDefs) do
		if ud.canFly and ud.canAttack then

			-- track the units' weapons to know when projectiles are created			
			if ud.weapons and ud.weapons[1] then
				unitNames[ud.name] = true
				for _,w in pairs(ud.weapons) do
					Script.SetWatchWeapon(w.weaponDef,true)
				end
			end
		end
	end

	gadgetHandler:RegisterCMDID(CMD_HITNRUN)
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local teamID = spGetUnitTeam(unitID)
		local unitDefID = spGetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
end

function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
	local ud = UnitDefs[unitDefID]
	if (unitNames[ud.name]) then

		-- set starting mode
		local mode = 0
		if enabledUnitNames[ud.name] then
			mode = 1
		end
		enableHitNRunList[unitID] = mode
		
		addHitNRunCmdDesc(unitID)
		updateButton(unitID, ''..mode)
	end
end

function gadget:UnitDestroyed(unitID, _, teamID)
	enableHitNRunList[unitID] = nil
	unitIdsThatFiredRecently[unitID] = nil
end



function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, _)
	local returnvalue
	if cmdID ~= CMD_HITNRUN then
		return true
	end
	hitNRunCommand(unitID, unitDefID, cmdParams, teamID)  
	return false
end

function gadget:Shutdown()
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local cmdDescID = spFindUnitCmdDesc(unitID, CMD_HITNRUN)
		if (cmdDescID) then
			spRemoveUnitCmdDesc(unitID, cmdDescID)
		end
	end
end

function gadget:GameFrame(n)
	local cmds,cmd1,tx,tz,x,z

	-- process each hit-n-run enabled unit that fired recently
	for unitId,f in pairs(unitIdsThatFiredRecently) do
		if n - f > REACTION_DELAY_FRAMES then
			cmds = spGetUnitCommands(unitId,5)
			-- stop the unit and order it to move somewhere
			if (cmds and (#cmds > 0)) then
				for i,cmd in ipairs(cmds) do
					if trackedCommands[cmd["id"]] and cmd["params"] then
		  	  			--Spring.Echo(CMD[cmd["id"]].." params="..printArr(cmd["params"]))
						if cmd["params"] then
							x,_,z = spGetUnitPosition(unitId)
							dx,_,dz = spGetUnitDirection(unitId)
							px, pz = getRetreatPosition(x,z,dx,dz)
							
							spGiveOrderToUnit(unitId, CMD_STOP,{},{})
							spGiveOrderToUnit(unitId,CMD.MOVE,{px,0,pz},CMD.OPT_SHIFT)
							--Spring.Echo("unit hit-n-runs at ("..tostring(x)..","..tostring(z)..")")
							break
						end
					end
				end
			end
			unitIdsThatFiredRecently[unitId] = nil
		end
	end
end

-- mark units that fired recently when projectiles are created
function gadget:ProjectileCreated(proID, proOwnerID, weaponDefID)
	local mode = enableHitNRunList[proOwnerID] or 0
	if mode == 1 and not unitIdsThatFiredRecently[proOwnerID] then
		unitIdsThatFiredRecently[proOwnerID] = spGetGameFrame()	
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
