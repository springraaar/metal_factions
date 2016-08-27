function widget:GetInfo()
  return {
    name      = "UI keys",
    desc      = "Adds actions to some key combinations",
    author    = "raaar",
    date      = "2015",
    license   = "PD",
    layer     = 1,
    enabled   = true
  }
end

include("keysym.h.lua")

function widget:Initialize()
   Spring.SendCommands("unbindaction showmetalmap")
end

function widget:KeyPress(key, mods, isRepeat)
	if (key == KEYSYMS.C) and mods.ctrl then
		-- get team units
		local unitList = Spring.GetTeamUnits(Spring.GetMyTeamID())
		
		-- find and select the commander
		for i=1,#unitList do
			local unitID    = unitList[i]
			local unitDefID = Spring.GetUnitDefID(unitID)
			local unitDef   = UnitDefs[unitDefID or -1]
			local cp 		= unitDef.customParams or nil
			
			if unitDef and cp and cp.iscommander then
				Spring.SelectUnitArray({unitID})
				local x,y,z = Spring.GetUnitPosition(unitID)
				Spring.SetCameraTarget(x,y,z)
				return false
			end
		end
	elseif (key == KEYSYMS.ESCAPE) and mods.shift then
		Spring.SendCommands("quitmenu")
	elseif (key == KEYSYMS.F4) then
		Spring.SendCommands("showmetalmap")
	end
end

