function gadget:GetInfo()
	return {
		name = "Area Attack",
		desc = "Give area attack commands to ground units",
		author = "KDR_11k (David Becker)",
		date = "2008-01-20",
		license = "Public domain",
		layer = 3,
		enabled = true
	}
end

include("lualibs/custom_cmd.lua")

if (gadgetHandler:IsSyncedCode()) then

--SYNCED



----------- Following bugs fixed by anonymous person ----------------
-- FIXED bug: when o.radius was zero it caused a crash
-- FIXED bug: now checks which units can area-attack = no more crashing via CTRL+A + area attack ;)
---------------------------------------------------------------------------

local spGetUnitWeaponState = Spring.GetUnitWeaponState
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spSetUnitMoveGoal = Spring.SetUnitMoveGoal

local attackerList={}
local closeList={}
local range={}

local aadesc= {
	name = "Area Attack",
	action="areaattack",
	id=CMD_AREAATTACK,
	type=CMDTYPE.ICON_AREA,
	tooltip="Attack an area randomly",
	cursor="Attack",
}

function gadget:GameFrame(f)
	for uId,o in pairs(attackerList) do
		_,reloaded,reloadFrame = spGetUnitWeaponState(uId,1)
        if (reloaded == true) then
        	if (o.attack) then
				local phase = math.random(200*math.pi)/100.0
				if o.radius > 0 then
					local amp = math.random(o.radius)
					--spGiveOrderToUnit(o.unit, CMD.INSERT, {0, CMD.ATTACK, 0, o.x + math.cos(phase)*amp, o.y, o.z + math.sin(phase)*amp}, {"alt"})

					--spGiveOrderToUnit(o.unit, CMD.REMOVE, {0,CMD.ATTACK}, {"ctrl"})					
					spGiveOrderToUnit(o.unit, CMD.REMOVE, {0,CMD.ATTACK}, {"alt"})
					spGiveOrderToUnit(o.unit, CMD.INSERT, {0, CMD.ATTACK, 0, o.x + math.cos(phase)*amp, o.y, o.z + math.sin(phase)*amp}, {"alt"})
				end
				o.attack = false
			end
			--attackerList[uId] = nil
		else
			o.attack = true
        end
	end
	for i,o in pairs(closeList) do
		closeList[i] = nil
		spSetUnitMoveGoal(o.unit,o.x,o.y,o.z,o.radius)
	end
end

function gadget:AllowCommand(unitId, unitDefId, teamId, cmd, param, opt)
	if cmd == CMD_AREAATTACK then
		if UnitDefs[unitDefId].customParams.canareaattack=="1" then
			return true
		else 
			return false
		end
	elseif cmd == CMD.STOP or cmd == CMD.MOVE then
		-- cancel the area attack order
		if attackerList[unitId] then
			attackerList[unitId] = nil
		end
		return true
	else
		return true
	end
end

function gadget:CommandFallback(unitId,unitDefId,team,cmd,param,opt)
	if cmd == CMD_AREAATTACK then
		local x,_,z = Spring.GetUnitPosition(unitId)
		local dist = math.sqrt((x-param[1])*(x-param[1]) + (z-param[3])*(z-param[3]))
		if dist <= range[unitDefId] - param[4] then
			attackerList[unitId] = {unit = unitId, x=param[1], y=param[2], z=param[3], radius=param[4], attack = true} 
		else
			table.insert(closeList, {unit = unitId, x=param[1], y=param[2], z=param[3], radius=range[unitDefId]-param[4]})
		end
		return true, false
	end
	return false
end

function gadget:UnitCreated(unitId, unitDefId, team)
	if UnitDefs[unitDefId].customParams.canareaattack=="1" then
		range[unitDefId] = WeaponDefs[UnitDefs[unitDefId].weapons[1].weaponDef].range
		Spring.InsertUnitCmdDesc(unitId,aadesc)
	end
end

function gadget:UnitDestroyed(unitId, unitDefId, teamId)
	if attackerList[unitId] then
		attackerList[unitId] = nil
	end
end

function gadget:Initialize()
	gadgetHandler:RegisterCMDID(CMD_AREAATTACK)
end

else

-- no UNSYNCED code

function gadget:Initialize()
	Spring.SetCustomCommandDrawData(CMD_AREAATTACK, CMDTYPE.ICON_AREA, {1,0,0,.8},true)
end

--return false

end
