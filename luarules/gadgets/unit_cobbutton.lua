--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
	return false
end

function gadget:GetInfo()
  return {
    name      = "CobButton",
    desc      = "Easy cob button Creation",
    author    = "quantum, Deadnight Warrior",
    date      = "June 28, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = -10,
    enabled   = true
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--  Proposed Command ID Ranges:
--
--    all negative:  Engine (build commands)
--       0 -   999:  Engine
--    1000 -  9999:  Group AI
--   10000 - 19999:  LuaUI
--   20000 - 29999:  LuaCob
--   30000 - 39999:  LuaRules
--

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Spring, ipairs, pairs = Spring, ipairs, pairs
local SetUnitRulesParam, GetUnitRulesParam = Spring.SetUnitRulesParam, Spring.GetUnitRulesParam
local spInsertUnitCmdDesc = Spring.InsertUnitCmdDesc
local spFindUnitCmdDesc = Spring.FindUnitCmdDesc
local spGetUnitCmdDescs = Spring.GetUnitCmdDescs
local spEditUnitCmdDesc = Spring.EditUnitCmdDesc
local spRemoveUnitCmdDesc = Spring.RemoveUnitCmdDesc
local spCallCOBScript = Spring.CallCOBScript
local spGetUnitDefID = Spring.GetUnitDefID
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local reloads = {}

local buttonDefs = VFS.Include"LuaRules/Configs/cob_buttons.lua"

local buttons = {}
local cmdOffset = 0
for unit, cmds in pairs(buttonDefs) do
	for i, cmd in ipairs(cmds) do
		cmd.id = 34520 + cmdOffset
		cmdOffset = cmdOffset + 1
		buttons[cmd.id] = cmd
		cmd.unit = unit
		cmd.buttonIndex = i
		cmd.name = cmd.name or cmd.cob
		cmd.cmdDesc = {
			id      = cmd.id,
			name    = cmd.name or cmd.cob,
			action  = string.lower(cmd.name),
			type    = cmd.type or CMDTYPE.ICON,
			tooltip = cmd.tooltip,
			params  = cmd.params,
		}
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:Initialize()
	for cmdID in pairs(buttons) do
		gadgetHandler:RegisterCMDID(cmdID)
	end
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		gadget:UnitCreated(unitID, Spring.GetUnitDefID(unitID))
	end
end


function gadget:UnitCreated(unitID, unitDefID)
	local name = UnitDefs[unitDefID].name
	if (buttonDefs[name]) then
		for i, button in ipairs(buttonDefs[name]) do
			spInsertUnitCmdDesc(unitID, button.position or 500, button.cmdDesc)
		end
		reloads[unitID] = {}
	end
end


function gadget:Shutdown()
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		for cmdID in pairs(buttons) do
			local cmdDescID = spFindUnitCmdDesc(unitID, cmdID)
			if (cmdDescID) then
				spRemoveUnitCmdDesc(unitID, cmdDescID)
			end
		end
	end
end


function gadget:GameFrame(n)
	local s = n/30
	for unitID, unitButtons in pairs(reloads) do
		local udfid = spGetUnitDefID(unitID)
		if (udfid==nil) then
			reloads[unitID] = nil
		else
			local unitName = UnitDefs[udfid].name
			for buttonIndex, status in pairs(unitButtons) do
				local reload  = status[1]
				local expired = status[2]
				local cmd = buttonDefs[unitName][buttonIndex]
				local cmdDescID = spFindUnitCmdDesc(unitID, cmd.id)
				if (cmdDescID) then
					local cmdArray
					if (cmd.duration and s - reload > cmd.duration and s - reload < cmd.reload) then
						if (cmd.endcob and not expired) then
							spCallCOBScript(unitID, cmd.endcob, 0)
							status[2] = true
						end
						local progress = (s-reload-cmd.duration) / (cmd.reload-cmd.duration) * 100
						local text = string.format("%d%%", progress)    
						cmdArray = {name = text, disabled = true}
					elseif (s - reload < cmd.reload) then 
						local progress = (s-reload) / (cmd.duration) * 100
						local text = string.format("%d%%", progress)
						cmdArray = {name = text, disabled = true}
					else
						if (not cmd.duration) then
							spCallCOBScript(unitID, cmd.endcob, 0)
						end
						cmdArray = {name = cmd.name, disabled = false}
						unitButtons[buttonIndex] = nil
					end
					spEditUnitCmdDesc(unitID, cmdDescID, cmdArray)
				end
			end
			if (not next(unitButtons)) then
				reloads[unitID] = nil
			end
		end
	end
end


function gadget:UnitDestroyed(unitID)
	reloads[unitID] = nil
end


function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (buttons[cmdID] and buttonDefs[UnitDefs[unitDefID].name] and buttons[cmdID].name==buttonDefs[UnitDefs[unitDefID].name][1].name) then
		local cmd = buttons[cmdID]
		local cmdDescID = spFindUnitCmdDesc(unitID, cmdID)
		if (cmd.reload) then
			reloads[unitID] = reloads[unitID] or {}
			if (not reloads[unitID][cmd.buttonIndex]) then
				reloads[unitID][cmd.buttonIndex] = {Spring.GetGameSeconds()}
				spCallCOBScript(unitID, cmd.cob, 0)
			end
		else
			if (cmdDescID and cmd.params) then
				cmd.params[1] = cmdParams[1]
				spCallCOBScript(unitID, cmd.cob, 0, cmdParams[1])
				spEditUnitCmdDesc(unitID, cmdDescID, {params=cmd.params})
			else
				spCallCOBScript(unitID, cmd.cob, 0)
			end
		end
		return false  -- command was used
	end
	return true  -- command was not used
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------