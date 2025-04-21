function widget:GetInfo()
  return {
    name      = "SelectionTracker",
    desc      = "Tracks unit selection changes for use by other widgets",
    author    = "raaar",
    date      = "2025",
    license   = "GNU GPL, v2 or later",
    layer     = -1000,
    enabled   = true
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGetSelectedUnits = Spring.GetSelectedUnits

WG.unitSelectionChanged = false
local oldSelection = {}

function widget:Update()
	-- track changes in unit selection, for use by other widgets
  	local newSelection = spGetSelectedUnits()
	if (#newSelection == #oldSelection) then
		WG.unitSelectionChanged = false
		for i = 1, #oldSelection do
			if (newSelection[i] ~= oldSelection[i]) then
				WG.unitSelectionChanged = true
				break
			end
		end
	else
		WG.unitSelectionChanged = true
	end
	oldSelection = newSelection
end
             
