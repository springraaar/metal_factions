
function gadget:GetInfo()
  return {
    name      = "Cob Debug",
    desc      = "used to log data received from COB scripts",
    author    = "raaar",
    date      = "Feb 2014",
    license   = "PD",
    layer     = 2,
    enabled   = true
  }
end


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
    return
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local Echo = Spring.Echo



function cobDebug(unitID, unitDefID, teamID, data)
	Echo(data)
end


gadgetHandler:RegisterGlobal("cobDebug", cobDebug)
