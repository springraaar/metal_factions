--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Don't Shoot",
    desc      = "Sets armed cloakable units to return fire while cloaked.",
    author    = "Quantum, Jools",
    date      = "June 2, 2012",
    license   = "GNU GPL, v2 or later",
    layer     = -1,
    enabled   = true
  }
end


-- modified by raaar, sep 2015 : also affects other cloakable units

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


-- Speedups
local GiveOrderToUnit  = Spring.GiveOrderToUnit
local GetUnitStates    = Spring.GetUnitStates
local GetUnitDefID     = Spring.GetUnitDefID
local GetGameFrame     = Spring.GetGameFrame
local GetMyTeamID      = Spring.GetMyTeamID
local GetSelectedUnits = Spring.GetSelectedUnits

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
  if Spring.GetSpectatingState() or Spring.IsReplay() then
    widgetHandler:RemoveWidget()
    return true
  end
end

function widget:CommandNotify(commandID, params, options)
  if (commandID == CMD.CLOAK) then
  
    local selUnits = GetSelectedUnits()
    
    for i,unitID in pairs(selUnits) do
    
      local unitDefID = GetUnitDefID(unitID)
	  local unitDef   = UnitDefs[unitDefID or -1]
	  local cp 		= unitDef.customParams or nil
	  
      if unitDef and unitDef.weapons and unitDef.weapons[1] then
      
        local states = GetUnitStates(unitID)
        if (not states) then
          return
        end
        if states.cloak then
          GiveOrderToUnit(unitID, CMD.FIRE_STATE, {2}, {})
        else
          GiveOrderToUnit(unitID, CMD.FIRE_STATE, {1}, {}) 
        end
      end
    end
  end   
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
