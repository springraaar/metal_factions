-- TODO
-- add range circle (easy, no Lua?)
-- make the Lord move until it gets in range (relatively hard)
-- cleanups


Cmds = {
        BARRAGE=250
}

OurCmd = {}
for _, id in pairs(Cmds) do
        OurCmd[id] = true
end


BARRAGE_COOLDOWN = 10   -- in seconds
BARRAGE_RANGE = 1200
BARRAGE_RANGE_SQ = BARRAGE_RANGE * BARRAGE_RANGE

_barrageTimeouts = {}
function CmdBarrage(unitID, unitDefID, teamID, cmdID, params, options)
        if _barrageTimeouts[unitID] == nil then
                _barrageTimeouts[unitID] = 0
        end
        -- if spell is on cooldown, do nothing
        if _barrageTimeouts[unitID] > Spring.GetGameSeconds() then
                return true;
        end
        Spring.Echo("CmdBarrage")

        -- try to create in map
        local z, facing
        if params[3]<200 then
                z = params[3]+200
                facing = 2
        else
                z = params[3]-200
                facing = 0
        end
        -- name, X, Y, Z, facing, team (optional) -> unitid
        local newID = Spring.CreateUnit('specBarrager',
                        params[1], params[2], z, facing,
                        Spring.GetGaiaTeamID())
        -- CreateUnit currently puts units on the ground,
        -- and we want it to hover above ground and slighlty before the target
        Spring.SetUnitPosition(newID, params[1], params[2]+1400, params[3]-200)

        -- cloak the unit (just to make sure)
        Spring.GiveOrderToUnit(newID, CMD.CLOAK, {"1"}, {})

        -- XXX hack hack - barrage lasts as long as unit's selfd timer allows
        Spring.GiveOrderToUnit(newID, CMD.SELFD, {}, {})
        -- hold fire and hold pos, so the unit won't bother doing anything
        -- that we don't want it to
        Spring.GiveOrderToUnit(newID, CMD.FIRE_STATE, {"0"}, {})
        Spring.GiveOrderToUnit(newID, CMD.MOVE_STATE, {"0"}, {})

        -- attack ground below
        local target={params[1], params[2], params[3]}
        Spring.GiveOrderToUnit(newID, CMD.ATTACK, target, {"shift"})

        -- add timeout for barrage
        _barrageTimeouts[unitID] = Spring.GetGameSeconds() + BARRAGE_COOLDOWN

        -- start a cob script, which will start a cob thread, which
        -- will call UpdateBarrageCmdDesc periodically
        -- args: totaltime, sleeptime - in miliseconds
        Spring.CallCOBScript(unitID, "BarrageAfter", 0, BARRAGE_COOLDOWN*1000, 1000)

        return true
end

function UpdateBarrageCmdDesc(unitID, unitDefID, teamdID, secs)
        local cmds = Spring.GetUnitCmdDescs(unitID)
        local i = 0
        local thecmd
        for k, cmd in ipairs(cmds) do
                if cmd.id == Cmds.BARRAGE then
                        i = k
                        thecmd = cmd
                        break
                end
        end
        if secs > 1 then
                thecmd.name = string.format("Barrage %ds", secs/1000)
        else
                thecmd.name = "Barrage!"
        end
        Spring.EditUnitCmdDesc(unitID, i, thecmd)
        return 1
end

-- check range
-- if you want to disable a command, always check that here, merely removing
-- a button won't be sufficient
function AllowBarrage(unitID, unitDefID, teamID, cmdID, params, options)
        local x, z
        x, _, z = Spring.GetUnitPosition(unitID)
        local dx = params[1]-x
        local dz = params[3]-z
        if dx*dx + dz*dz > BARRAGE_RANGE_SQ then
                -- XXX don't know if this echoes to all players
                Spring.Echo("Barrage out of range")
                return false
        end
        return true
end

CmdHooks = {
        [Cmds.BARRAGE]=CmdBarrage
}

AllowHooks = {
        [Cmds.BARRAGE]=AllowBarrage
}
