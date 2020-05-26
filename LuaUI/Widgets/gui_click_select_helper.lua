
function widget:GetInfo()
	return {
		name      = "Click Select Helper",
		desc      = "Selects units near the clicked position",
		author    = "raaar",
		version   = "v1",
		date      = "2020",
		license   = "PD",
		layer     = math.huge,
		enabled   = false,
		handler   = true
	}
end

------------------------------------------------------------
-- Speedups
------------------------------------------------------------
local spGetActiveCommand = Spring.GetActiveCommand
local spGetMouseState = Spring.GetMouseState
local spTraceScreenRay = Spring.TraceScreenRay
local spGetUnitsInCylinder = Spring.GetUnitsInCylinder
local spGetSelectedUnits = Spring.GetSelectedUnits
local spGetLocalTeamID =  Spring.GetLocalTeamID
local spGetUnitPosition = Spring.GetUnitPosition
local spGetGameFrame = Spring.GetGameFrame
local spGetLastUpdateSeconds = Spring.GetLastUpdateSeconds
local spGetGameSeconds = Spring.GetGameSeconds
local spGetMouseState = Spring.GetMouseState
local spSelectUnitArray = Spring.SelectUnitArray
local spGetUnitDefID = Spring.GetUnitDefID

local SELECT_CLICK_RADIUS = 150
local SELECT_DOUBLE_CLICK_RADIUS = 1500
local SELECT_APPLY_DELAY_S = 0.2		-- necessary to check if selection box is being drawn and abort
local SELECT_RESET_DELAY_S = 0.4		-- allows for tracking double click
local SELECT_DRAG_DISABLE_DIST = 30
local LEFT_CLICK = 1
local MID_CLICK = 2
local RIGHT_CLICK = 3

local lastX,lastY = 0
local clickMX = 0
local clickMY = 0
local clickPX = 0
local clickPZ = 0
local minDist = 9999999
local bestSelUnitId = 0
local selSeconds = 0
local clicks = 0
local appendSelection = false
local appendSelectionPressed = false
local dx = 0
local dz = 0


function sqDist(x1,z1,x2,z2)
	dx = x1 - x2
	dz = z1 - z2
	
	return (dx*dx+dz*dz)
end

function resetState()
	clickMX = 0
	clickMY = 0
	clickPX = 0
	clickPZ = 0
	minDist = 9999999
	bestSelUnitId = 0
	selSeconds = 0
	clicks = 0
	appendSelection = false
	appendSelectionPressed = false
end

function getSeconds()
	return spGetGameSeconds()
end



----------------------------- CALLINS


function widget:KeyPress(key, mods, isRepeat)
	if mods.shift then 
		appendSelectionPressed = true
		appendSelection = true
	end
end

function widget:KeyRelease(key)
	appendSelectionPressed = false
end


function widget:MousePress(mx,my,button)
	local type, pos = spTraceScreenRay(mx, my, true)
	if not pos then 
		resetState()
		return false
	end

	local _, activeCmdID = spGetActiveCommand()
	if activeCmdID then
		resetState()
		return false
	end

	local currentS = getSeconds()
	clickMX = mx
	clickMY = my
	minDist = 999999
	bestSelUnitId = 0
	if (appendSelectionPressed) then
		appendSelection = true
	end
	-- clicked the ground	
	if (type == "ground" and button == 1) then
		clicks = clicks +1
		local myTeamId = spGetLocalTeamID()
		local nearbyUnits = spGetUnitsInCylinder(pos[1],pos[3],SELECT_CLICK_RADIUS,myTeamId)
		--Spring.Echo(button.." clicked (x"..clicks..") s="..currentS.." type="..type.." at x="..mx.." y="..my.." px="..pos[1].." pz="..pos[3].." units="..#nearbyUnits)
	
		-- find which nearby friendly unit is closest and mark it for selection
		local d,px,py,pz
		if nearbyUnits and #nearbyUnits > 0 then
			--local selectedUnits = spGetSelectedUnits()
			--if appendSelection or (not selectedUnits or #selectedUnits == 0) then
				for _,uId in pairs(nearbyUnits) do
					local px,py,pz = spGetUnitPosition(uId)
					if (px) then
						d = sqDist(pos[1],pos[3],px,pz)
						--Spring.Echo("unit "..uId.." is nearby d="..d)
						if (d < minDist) then
							minDist = d
							bestSelUnitId = uId
							clickPX = px
							clickPZ = pz
						end
					end
				end
			--end
			
			-- we have a unit to select, mark it!
			if (bestSelUnitId > 0) then
				selSeconds = currentS
				--Spring.Echo("unit "..bestSelUnitId.." should be selected!")
				--return true
			end
		else
			resetState()
		end
	end
	
	return false
end

function widget:Update()
	local currentS = getSeconds()

	-- if mouse moved significantly with left button pressed, abort the selection as the user is probably dragging a box
	local mx,my,left,middle,right,offscreen = spGetMouseState()
	if left and (math.abs(mx -clickMX) > SELECT_DRAG_DISABLE_DIST or math.abs(my -clickMY) > SELECT_DRAG_DISABLE_DIST) then
		resetState()
		--Spring.Echo("mouse being moved : abort nearby click selection")
	end
	-- if there's a unit marked for selection and no units have been selected, select it 
	if (currentS-selSeconds > SELECT_APPLY_DELAY_S) then
		if (bestSelUnitId > 0) then
			--local selectedUnits = spGetSelectedUnits()
			--if appendSelection or (not selectedUnits or #selectedUnits == 0) then
				if (clicks == 1) then
					--Spring.Echo("selecting unit "..bestSelUnitId)
					Spring.SelectUnitArray({bestSelUnitId},appendSelection)
				else
					--Spring.Echo("selecting nearby units similar to "..bestSelUnitId)
					-- more than a single click, select all similar units
					idsToSelect = {}
					defIdToSelect = spGetUnitDefID(bestSelUnitId)
					local nearbyUnits = spGetUnitsInCylinder(clickPX,clickPZ,SELECT_DOUBLE_CLICK_RADIUS,myTeamId)
					local defId = 0
					for i,id in pairs(nearbyUnits) do
						defId = spGetUnitDefID(id)
						
						if defId and defId == defIdToSelect then
							idsToSelect[#idsToSelect+1] = id	
						end
					end
					
					if (#idsToSelect > 0) then
						Spring.SelectUnitArray(idsToSelect,appendSelection)
					end
				end
			--end
		end
		if (currentS-selSeconds > SELECT_RESET_DELAY_S) then
			resetState()
		end
	end
end

