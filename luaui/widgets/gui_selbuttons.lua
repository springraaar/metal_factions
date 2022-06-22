function widget:GetInfo()
  return {
    name      = "SelectionButtons",
    desc      = "Buttons for currently selected unit types and idle builders",
    author    = "raaar, based on unit selection buttons widget by trepan",
    date      = "2021",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local GL_DEPTH_BUFFER_BIT      = GL.DEPTH_BUFFER_BIT
local GL_FILL                  = GL.FILL
local GL_FRONT_AND_BACK        = GL.FRONT_AND_BACK
local GL_LINE                  = GL.LINE
local GL_LINE_LOOP             = GL.LINE_LOOP
local GL_ONE                   = GL.ONE
local GL_ONE_MINUS_SRC_ALPHA   = GL.ONE_MINUS_SRC_ALPHA
local GL_SRC_ALPHA             = GL.SRC_ALPHA
local glCreateList             = gl.CreateList
local glDeleteList             = gl.DeleteList
local glCallList               = gl.CallList
local glBeginEnd               = gl.BeginEnd
local glBlending               = gl.Blending
local glClear                  = gl.Clear
local glColor                  = gl.Color
local glDepthMask              = gl.DepthMask
local glDepthTest              = gl.DepthTest
local glLighting               = gl.Lighting
local glLineWidth              = gl.LineWidth
local glMaterial               = gl.Material
local glPolygonMode            = gl.PolygonMode
local glPolygonOffset          = gl.PolygonOffset
local glPopMatrix              = gl.PopMatrix
local glPushMatrix             = gl.PushMatrix
local glRect                   = gl.Rect
local glRotate                 = gl.Rotate
local glScale                  = gl.Scale
local glScissor                = gl.Scissor
local glTexRect                = gl.TexRect
local glText                   = gl.Text
local glTexture                = gl.Texture
local glTranslate              = gl.Translate
local glUnitDef                = gl.UnitDef
local glUnitShape              = gl.UnitShape
local glVertex                 = gl.Vertex
local spGetModKeyState         = Spring.GetModKeyState
local spGetMouseState          = Spring.GetMouseState
local spGetMyTeamID            = Spring.GetMyTeamID
local spGetSelectedUnits       = Spring.GetSelectedUnits
local spGetSelectedUnitsCounts = Spring.GetSelectedUnitsCounts
local spGetSelectedUnitsSorted = Spring.GetSelectedUnitsSorted
local spGetTeamUnitsSorted     = Spring.GetTeamUnitsSorted
local spGetUnitDefDimensions   = Spring.GetUnitDefDimensions
local spSelectUnitArray        = Spring.SelectUnitArray
local spSelectUnitMap          = Spring.SelectUnitMap
local spSendCommands           = Spring.SendCommands
local spGetFullBuildQueue      = Spring.GetFullBuildQueue
local spGetCommandQueue        = Spring.GetCommandQueue
local spGetUnitDefID           = Spring.GetUnitDefID 
local spGetGameFrame           = Spring.GetGameFrame
local spGetUnitHealth          = Spring.GetUnitHealth
local spGetUnitIsStunned       = Spring.GetUnitIsStunned
local spGetGameSeconds         = Spring.GetGameSeconds
local spGetTimer               = Spring.GetTimer
local spDiffTimers             = Spring.DiffTimers
local floor                    = math.floor
local min                      = math.min

include("colors.h.lua")
VFS.Include("lualibs/util.lua")

local vsx, vsy = gl.GetViewSizes()

local ICON_SIZE = 52
local TYPE_SELECTED = 0
local TYPE_IDLE_BUILDER = 1
local MAX_ICONS = 12 

local activePress = false
local mouseIcon = -1
local mouseIconType = -1

local builderBorder = ":n:"..LUAUI_DIRNAME.."images/idle_builder_border.dds"
local currentDef = nil

local scaleFactor = 1
if (vsy > 1080) then
	scaleFactor = vsy / 1080
end	
local iconSizeX = math.floor(ICON_SIZE*scaleFactor)
local iconSizeY = iconSizeX
local fontSize = iconSizeY * 0.5

local selRectMinX = 0
local selRectMaxX = 0
local selRectMinY = 0
local selRectMaxY = 0

local idleRectMinX = 0
local idleRectMaxX = 0
local idleRectMinY = 0
local idleRectMaxY = 0

local selectedUnitCounts = 0
local selUnitTypes = 0
local selectedSortedUnitTypes = {}
local selectionCheck = ""

local idleUnitCounts = nil
local idleUnitIdsByType = nil
local idleUnitTypes = 0
local idleSortedUnitTypes = {}

local glList = nil
local glListRefreshIdx = -1
local refTimer = spGetTimer()

local ignoreIdleBuilderDefIds = {
-------------------- AVEN
	[UnitDefNames["aven_scout_pad"].id] = true,
	[UnitDefNames["aven_commander_respawner"].id] = true,
	[UnitDefNames["aven_upgrade_center"].id] = true,
-------------------- GEAR
	[UnitDefNames["gear_scout_pad"].id] = true,
	[UnitDefNames["gear_commander_respawner"].id] = true,
	[UnitDefNames["gear_upgrade_center"].id] = true,
-------------------- CLAW	
	[UnitDefNames["claw_scout_pad"].id] = true,
	[UnitDefNames["claw_commander_respawner"].id] = true,
	[UnitDefNames["claw_upgrade_center"].id] = true,
	[UnitDefNames["claw_totem"].id] = true,
-------------------- SPHERE	
	[UnitDefNames["sphere_scout_pad"].id] = true,
	[UnitDefNames["sphere_commander_respawner"].id] = true,
	[UnitDefNames["sphere_upgrade_center"].id] = true
}


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------


local function isIdleBuilder(unitID)
	local defId = spGetUnitDefID(unitID)
	if defId and ignoreIdleBuilderDefIds[defId] == true then
		return false
	end
	local ud = UnitDefs[defId] 
	
	local qCount = 0
	if ud.buildSpeed > 0 then  --- can build
		local bQueue = spGetFullBuildQueue(unitID)
		if not bQueue[1] then  --- has no build queue
			local _, _, _, _, buildProg = spGetUnitHealth(unitID)
			local stunned = spGetUnitIsStunned(unitID)
			if buildProg == 1 and (not stunned) then  --- isnt under construction or stunned
				if ud.isFactory then
					return true 
				else
					if spGetCommandQueue(unitID,_,false) == 0 then
						return true
					end
				end
      		end
		elseif ud.isFactory then
			for _, thing in ipairs(bQueue) do
				for _, count in pairs(thing) do
					qCount = qCount + count
				end 
			end
			if qCount < 1 then
				return true
			end
		end
	end
	return false
end


local function setupDimensions(selCount,idleCount)
	local xmid = vsx * 0.5
	local width = math.floor(iconSizeX * selCount)
	selRectMinX = math.floor(xmid - (0.5 * width))
	selRectMaxX = math.floor(xmid + (0.5 * width))
	selRectMinY = math.floor(0)
	selRectMaxY = math.floor(selRectMinY + iconSizeY)

	width = math.floor(iconSizeX * idleCount)
	idleRectMinX = math.floor(xmid - (0.5 * width))
	idleRectMaxX = math.floor(xmid + (0.5 * width))
	idleRectMinY = math.floor(selRectMaxY + 5)
	idleRectMaxY = math.floor(idleRectMinY + iconSizeY)
end


local function drawUnitDefTexture(type, unitDefID, iconPos, count)
	local xminRef = type == TYPE_SELECTED and selRectMinX or idleRectMinX
	local yminRef = type == TYPE_SELECTED and selRectMinY or idleRectMinY
	local ymaxRef = type == TYPE_SELECTED and selRectMaxY or idleRectMaxY
	 
	local xmin = math.floor(xminRef + (iconSizeX * iconPos))
	local xmax = xmin + iconSizeX
	if ((xmax < 0) or (xmin > vsx)) then return end  -- bail
  
	local ymin = yminRef
	local ymax = ymaxRef
	local xmid = (xmin + xmax) * 0.5
	local ymid = (ymin + ymax) * 0.5

	local ud = UnitDefs[unitDefID] 

	glColor(0.8, 0.8, 0.8)
	glTexture('#' .. unitDefID)
	glTexRect(xmin, ymin, xmax, ymax)
	glTexture(false)

	-- draw the count text
	glColor(1, 1, 1)
	glText(count, (xmin + xmax) * 0.5, (ymin + ymax)* 0.5 - fontSize*0.5, fontSize, "oc")
	
	if type == TYPE_IDLE_BUILDER then
		-- draw builder-type border
		glTexture(builderBorder)
		glTexRect(xmin, ymin, xmax, ymax)
		glTexture(false)
	end
	glColor(0, 0, 0)
	-- draw the border  (note the half pixel shift for drawing lines)
	glBeginEnd(GL_LINE_LOOP, function()
		glVertex(xmin + 0.5, ymin + 0.5)
		glVertex(xmax + 0.5, ymin + 0.5)
		glVertex(xmax + 0.5, ymax + 0.5)
		glVertex(xmin + 0.5, ymax + 0.5)
	end)
end


function drawIconQuad(type,iconPos, color)
	local xmin,xmax,ymin,ymax
	if type == TYPE_SELECTED then
		xmin = selRectMinX + (iconSizeX * iconPos)
		xmax = xmin + iconSizeX
		ymin = selRectMinY
		ymax = selRectMaxY
	else
		xmin = idleRectMinX + (iconSizeX * iconPos)
		xmax = xmin + iconSizeX
		ymin = idleRectMinY
		ymax = idleRectMaxY	
	end
	glColor(color)
	glBeginEnd(GL_LINE_LOOP, function()
		glVertex(xmin + 0.5, ymin + 0.5)
		glVertex(xmax + 0.5, ymin + 0.5)
		glVertex(xmax + 0.5, ymax + 0.5)
		glVertex(xmin + 0.5, ymax + 0.5)
	end)	
	glBlending(GL_SRC_ALPHA, GL_ONE)
	glRect(xmin, ymin, xmax, ymax)
	glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
end




-------------------------------------------------------------------------------
-------------------------------------------------------------------------------


local function leftMouseButton(unitDefID, unitTable)
	local alt, ctrl, meta, shift = spGetModKeyState()
	if (not ctrl) then
		-- select units of icon type
		if (unitTable and #unitTable > 0) then
			if (alt or meta) then
				spSelectUnitArray({ unitTable[1] })  -- only 1
			else
				spSelectUnitArray(unitTable)
			end
		end
	else
		-- select all units of the icon type
		local sorted = spGetTeamUnitsSorted(spGetMyTeamID())
		local units = sorted[unitDefID]
		if (units) then
			spSelectUnitArray(units, shift)
		end
	end
end

local function middleMouseButton(unitDefID, unitTable)
	local alt, ctrl, meta, shift = spGetModKeyState()
	-- center the view
	if (ctrl) then
		-- center the view on the entire selection
		spSendCommands({"viewselection"})
	else
		-- center the view on this type on unit
		local selUnits = spGetSelectedUnits()
		spSelectUnitArray(unitTable)
		spSendCommands({"viewselection"})
		spSelectUnitArray(selUnits)
	end
end


local function rightMouseButton(unitDefID, unitTable)
	if mouseIconType == TYPE_SELECTED then 
		local alt, ctrl, meta, shift = spGetModKeyState()
		-- remove selected units of icon type
		local selUnits = spGetSelectedUnits()
		local map = {}
		for _,uid in ipairs(selUnits) do map[uid] = true end
		for _,uid in ipairs(unitTable) do
			map[uid] = nil
			if (ctrl) then break end -- only remove 1 unit
		end
		spSelectUnitMap(map)
	end
end


-- returns true if x,y is within selected units icons
local function withinSelBounds(x,y)
	if (selUnitTypes <= 0) then return false end
	if (x < selRectMinX)   then return false end
	if (x > selRectMaxX)   then return false end
	if (y < selRectMinY)   then return false end
	if (y > selRectMaxY)   then return false end
	return true
end
-- returns true if x,y is within selected units icons
local function withinIdleBounds(x,y)
	if (idleUnitTypes <= 0) then return false end
	if (x < idleRectMinX)   then return false end
	if (x > idleRectMaxX)   then return false end
	if (y < idleRectMinY)   then return false end
	if (y > idleRectMaxY)   then return false end
	return true
end

local function mouseOverIcon(x, y)
	mouseIconType = -1

	if (withinSelBounds(x,y)) then
		mouseIconType = TYPE_SELECTED
		local icon = math.floor((x - selRectMinX) / iconSizeX)
		-- clamp the icon range
		if (icon < 0) then
			icon = 0
		end
		if (icon >= selUnitTypes) then
			icon = (selUnitTypes - 1)
		end
		return icon
	elseif(withinIdleBounds(x,y)) then
		mouseIconType = TYPE_IDLE_BUILDER
		local icon = math.floor((x - idleRectMinX) / iconSizeX)
		-- clamp the icon range
		if (icon < 0) then
			icon = 0
		end
		if (icon >= idleUnitTypes) then
			icon = (idleUnitTypes - 1)
		end
		return icon
	end
	return -1
end

-------------------------------------------------------------------------------

function widget:MouseRelease(x, y, button)
	if (not activePress) then
		return -1
	end
	activePress = false
	local icon = mouseOverIcon(x, y)
	local units = {}
	local unitDefID = -1
	local unitTable = nil
	if mouseIconType == TYPE_SELECTED then
		for index,udid in ipairs(selectedSortedUnitTypes) do
			if (index-1 == icon) then
				unitDefID = udid
				break
			end
		end

		units = spGetSelectedUnitsSorted()
		if (units.n ~= selUnitTypes) then
			return -1  -- discard this click
		end
		units.n = nil
	
		if units[unitDefID] then
			unitTable = units[unitDefID]
		end
		if (unitTable == nil) then
			return -1
		end
	elseif mouseIconType == TYPE_IDLE_BUILDER then
		for index,udid in ipairs(idleSortedUnitTypes) do
			if (index-1 == icon) then
				unitDefID = udid
				unitTable = idleUnitIdsByType[udid]
				break
			end
		end
		if (unitTable == nil) then
			return -1
		end
	end  
	local alt, ctrl, meta, shift = spGetModKeyState()
  
	if (button == 1) then
		leftMouseButton(unitDefID, unitTable)
	elseif (button == 2) then
		middleMouseButton(unitDefID, unitTable)
	elseif (button == 3) then
		rightMouseButton(unitDefID, unitTable)
	end

	return -1
end

function widget:IsAbove(x, y)
	local icon = mouseOverIcon(x, y)
	if (icon < 0) then
		return false
	end
	return true
end


function widget:GetTooltip(x, y)
	local ud = currentDef
	if (not ud) then
		return ''
	end
	if (mouseIconType == TYPE_SELECTED) then
		return "Selected units : "..ud.humanName .. '\255\180\180\180 - ' ..ud.tooltip.." \n \n(left-click to select, middle-click to view, right-click to deselect)"
	else
		return "Idle builders : "..ud.humanName .. '\255\180\180\180 - ' .. ud.tooltip.." \n \n(left-click to select, middle-click to view)"
	end
end


function widget:Update(dt)
	if spGetGameFrame() % 31 == 0 or doUpdate then
		doUpdate = false
		idleUnitIdsByType = {}
		idleUnitCounts = {}
		QCount = {}
		local myUnits = spGetTeamUnitsSorted(spGetMyTeamID())
		local unitCount = 0
		for unitDefID, unitTable in pairs(myUnits) do
			if type(unitTable) == 'table' then
				for count, unitID in pairs(unitTable) do
					if count ~= 'n' and isIdleBuilder(unitID) then
						unitCount = unitCount + 1
						if idleUnitIdsByType[unitDefID] then
							idleUnitIdsByType[unitDefID][#idleUnitIdsByType[unitDefID]+1] = unitID
						else
							idleUnitIdsByType[unitDefID] = {unitID}
						end
					end
				end
			end
		end
		
		idleUnitTypes = 0
		for unitDefID, units in pairs(idleUnitIdsByType) do
			idleUnitCounts[unitDefID] = #units
			idleUnitTypes = idleUnitTypes + 1
		end
		
		if idleUnitTypes > MAX_ICONS then
			idleUnitTypes = MAX_ICONS
		end
		
		idleSortedUnitTypes = {}
		local icon=0
		if idleUnitCounts then
			for udid,count in spairs(idleUnitCounts, function(t,a,b) return t[b] < t[a] end) do
				idleSortedUnitTypes[#idleSortedUnitTypes+1] = udid
				icon = icon + 1
				if icon >= MAX_ICONS then
					break
				end
			end
		end
	end
end

function updateSelectionInfo()
	local sCounts = spGetSelectedUnitsCounts()
	local newSelectionCheck = sCounts.n
	for key,value in pairs(sCounts) do
		if key ~= "n" then
			newSelectionCheck = newSelectionCheck..key..value
		end
	end
	
	if newSelectionCheck ~= selectionCheck then	
		--Spring.Echo("selection changed "..spGetGameFrame())
		selectionCheck = newSelectionCheck
		selectedUnitCounts = sCounts
		selUnitTypes = selectedUnitCounts.n;
		selectedUnitCounts.n = nil

		if selUnitTypes > MAX_ICONS then
			selUnitTypes = MAX_ICONS
		end
		
		local icon = 0
		selectedSortedUnitTypes = {}
		if selectedUnitCounts then
			for udid,count in spairs(selectedUnitCounts, function(t,a,b) return t[b] < t[a] end) do
				selectedSortedUnitTypes[#selectedSortedUnitTypes+1] = udid
				icon = icon + 1
				if icon >= MAX_ICONS then
					break
				end
			end
		end
	end
end



function widget:DrawScreen()
	-- check if selection changed, update info
	updateSelectionInfo()

	setupDimensions(selUnitTypes,idleUnitTypes)	

	local x,y,lb,mb,rb = spGetMouseState()
	local mouseIcon = mouseOverIcon(x, y)

	if (selUnitTypes <= 0 and idleUnitTypes <= 0) then
		activePress = false
	end
		
	currentDef = nil
	-- update currentDef
	if selectedSortedUnitTypes then
		for idx,udid in ipairs(selectedSortedUnitTypes) do
			if (mouseIconType == TYPE_SELECTED and (idx-1) == mouseIcon) then
				currentDef = UnitDefs[udid]
			end
		end
	end
	if idleSortedUnitTypes then
		for idx,udid in ipairs(idleSortedUnitTypes) do
			if (mouseIconType == TYPE_IDLE_BUILDER and (idx-1) == mouseIcon) then
				currentDef = UnitDefs[udid]
			end
		end
	end

	local refreshIdx = floor(spDiffTimers(spGetTimer(),refTimer)*5)
	-- refresh gl list only a few times per second unless focused
	if (mouseIcon >= 0) or (not glList) or refreshIdx ~= glListRefreshIdx then
		if glList then
			glDeleteList(glList)
		end 
		glList = glCreateList(function()
			-- draw the buildpics
			if selectedSortedUnitTypes then
				for idx,udid in ipairs(selectedSortedUnitTypes) do
					local count = selectedUnitCounts[udid]
					drawUnitDefTexture(TYPE_SELECTED,udid, idx-1, count)
				end
			end

			if idleSortedUnitTypes then
				for idx,udid in ipairs(idleSortedUnitTypes) do
					local count = idleUnitCounts[udid]
					drawUnitDefTexture(TYPE_IDLE_BUILDER,udid, idx-1, count)
				end
			end
		
			-- draw the highlights
			if (not widgetHandler:InTweakMode() and (mouseIcon >= 0)) then
				if (lb or mb or rb) then
					drawIconQuad(mouseIconType,mouseIcon, { 1, 0, 0, 0.333 })  --  red highlight
				else
					drawIconQuad(mouseIconType,mouseIcon, { 1, 1, 1, 0.333 })  --  white highlight
				end
			end
		end)
		glListRefreshIdx = refreshIdx
	end
	glCallList(glList)
end

function widget:MousePress(x, y, button)
	mouseIcon = mouseOverIcon(x, y)
	activePress = (mouseIcon >= 0)
	return activePress
end

function widget:ViewResize(viewSizeX, viewSizeY)
	vsx = viewSizeX
	vsy = viewSizeY
  
	scaleFactor = 1
	if (vsy > 1080) then
		scaleFactor = vsy / 1080
	end
	iconSizeX = math.floor(52*scaleFactor)
	iconSizeY = iconSizeX
	fontSize = iconSizeY * 0.5
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
