function widget:GetInfo()
  return {
    name      = "Select n Center!",
    desc      = "Selects and centers view on commander at the start of the game.",
    author    = "quantum, modified by raaar",
    date      = "22/06/2007",
    license   = "GNU GPL, v2 or later",
    layer     = 5,
    enabled   = true
  }
end
local center = true
local select = true
local unitList = {}

function widget:Update()
	local spec, specFullView = Spring.GetSpectatingState()
	if spec then 
		widgetHandler:RemoveWidget()
	    return
	end
	local t = Spring.GetGameSeconds()
	if t > 1 then
		widgetHandler:RemoveWidget()
		return
	end
	if  center and t > 0 then
		--Spring.Echo("center")
		unitList = Spring.GetTeamUnits(Spring.GetMyTeamID())
		if unitList and #unitList > 0 then
			local x, y, z = Spring.GetUnitPosition(unitList[1])
			Spring.SetCameraTarget(x, y, z)
		end
		center = false
	end
	if select 
		and t > 0 then
		--Spring.Echo("select")
		if unitList and #unitList > 0 then
			Spring.SelectUnitArray({unitList[1]})
		end
		select = false
	end
end

