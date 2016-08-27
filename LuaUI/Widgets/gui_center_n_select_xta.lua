function widget:GetInfo()
  return {
    name      = "Select n Center! - XTA",
    desc      = "Selects and centers the Commander at the start of the game.",
    author    = "quantum",
    date      = "22/06/2007",
    license   = "GNU GPL, v2 or later",
    layer     = 5,
    enabled   = true  --  loaded by default?
  }
end
local center = true
local select = true
local unitList = {}

function widget:Update()

  local t = Spring.GetGameSeconds()
  if t > 1 then
    widgetHandler:RemoveWidget()
    return
  end
  if  center and t > 0 then
    --Spring.Echo("center")
    unitList = Spring.GetTeamUnits(Spring.GetMyTeamID())
    local x, y, z = Spring.GetUnitPosition(unitList[1])
    Spring.SetCameraTarget(x, y, z)
    center = false
  end
  if  select 
  and t > 0 then
    --Spring.Echo("select")
    Spring.SelectUnitArray({unitList[1]})
    select = false
  end
end

