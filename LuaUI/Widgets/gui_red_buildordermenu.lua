function widget:GetInfo()
	return {
	version   = "8.1",
	name      = "Red Build/Order Menu",
	desc      = "Requires Red UI Framework",
	author    = "Regret, modified by raaar",
	date      = "August 9, 2009", --modified by raaar, sep 2015
	license   = "GNU GPL, v2 or later",
	layer     = 0,
	enabled   = true,
	handler   = true,
	}
end

-- modified by raaar, sep 2015 :
--   . changed build icon rows from 2 to 3
--   . use fixed flatter icon size on fwd/back buttons

-- modified by raaar, may 2015 :
--   . added filter of build options by category
--   . added buttons to toggle build facing and spacing
--   . changed many variable names from lowercase to camelCase
--   . changed next and previous page buttons to use images instead of ascii arrows
--   . commented out saving and loading config due to bug
--   . added max font size to text and fixed centering

include("keysym.h.lua")

local NeededFrameworkVersion = 8.1
local CanvasX,CanvasY = 1272,734 --resolution in which the widget was made (for 1:1 size)
--1272,734 == 1280,768 windowed
local vsx, vsy = gl.GetViewSizes()
local maxFontSizeFactor = 1
if (vsy > 1800) then
	maxFontSizeFactor = 1.4
elseif (vsy > 1200) then
	maxFontSizeFactor = 1.2
end	
local sGetSelectedUnitsCount = Spring.GetSelectedUnitsCount
local sGetActiveCommand = Spring.GetActiveCommand
local sGetActiveCmdDescs = Spring.GetActiveCmdDescs
local ssub = string.sub

local FILTER_KEY = KEYSYMS.B
local PAGE_KEY = KEYSYMS.N
local FILTER_ECO = 1
local FILTER_PLANT = 2
local FILTER_OTHER = 3
local FILTER_RED = 4
local FILTER_GREEN = 5
local FILTER_BLUE = 6
local filterLabel = {"ENERGY / METAL","FACTORY","OTHER","WEAPON","DEFENSE","UTILITY"}
local filter = FILTER_ECO
local hasOptions = {}
local buildOptionsTable = {}
local latestBuildCmds = {}

local ICON_SML_HEIGHT = 32
local ICON_NORMAL_HEIGHT = 48

local updateHax = false
local updateHax2 = true
local firstUpdate = true



local spacingList = {0,1,3,6,12,20}

-- adds relevant information for some tooltip texts like default hotkeys
local function tooltipExtension(tooltip)
	if (tooltip) then
		if string.match(tooltip, "Move:") then
			tooltip = tooltip .. ".\255\100\255\100 Hotkey \"M\", click-drag to move in line formation"
		elseif string.match(tooltip, "Guard:") then
			tooltip = tooltip .. ".\255\100\255\100 Hotkey \"G\""
		elseif string.match(tooltip, "Stop:") then
			tooltip = tooltip .. ".\255\100\255\100 Hotkey \"S\""
		elseif string.match(tooltip, "Wait:") then
			tooltip = tooltip .. ".\255\100\255\100 Hotkey \"W\""
		elseif string.match(tooltip, "Attack:") then
			tooltip = tooltip .. ".\255\100\255\100 Hotkey \"A\", click-drag to attack targets within an area"
		elseif string.match(tooltip, "Fight:") then
			tooltip = tooltip .. ".\255\100\255\100 Hotkey \"F\", click-drag for line formation"
		elseif string.match(tooltip, "Patrol:") then
			tooltip = tooltip .. ".\255\100\255\100 Hotkey \"P\", click-drag for line formation"
		elseif string.match(tooltip, "Repair:") then
			tooltip = tooltip .. ".\255\100\255\100 Hotkey \"R\", click-drag to repair targets within an area"
		elseif string.match(tooltip, "Reclaim:") then
			tooltip = tooltip .. ".\255\100\255\100 Hotkey \"E\", click-drag to reclaim targets within an area"
		elseif string.match(tooltip, "Cloak state:") then
			tooltip = tooltip .. ".\255\100\255\100 Hotkey \"K\" (also toggles fire state)"
		end
	end
	
	
	return tooltip
end

local Config = {
	buildMenu = {
		px = 0,py = CanvasY - 380,
		
		isx = ICON_NORMAL_HEIGHT,isy = ICON_NORMAL_HEIGHT, --icon size
		ix = 5,iy = 3, --icons x/y
		iSpreadX=0,iSpreadY=0, --space between icons
		
		margin = 5, --distance from background border
		
		fadeTime = 0.25, --fade effect time, in seconds
		
		ctext = {0.9,0.9,0.9,1}, --color {r,g,b,alpha}
		cbackground = {0,0,0,0.5},
		cborder = {0,0,0,1},
		cbuttonBackground = {0.1,0.1,0.1,1},
		
		dragButton = {2}, --middle mouse button
		tooltip = {
			background = "Hold \255\255\255\1middle mouse button\255\255\255\255 to drag the buildMenu around.",
		},
		showFilter = true
	},
	
	orderMenu = {
		px = 0,py = CanvasY -523,
		
		isx = ICON_NORMAL_HEIGHT,isy = ICON_SML_HEIGHT,
		ix = 5,iy = 3,
		
		iSpreadX=0,iSpreadY=0,
		
		margin = 5,
		
		fadeTime = 0.25,
		
		ctext = {0.9,0.9,0.9,1},
		cbackground = {0,0,0,0.5},
		cborder = {0,0,0,1},
		cbuttonBackground={0.1,0.1,0.1,1},
		
		dragButton = {2}, --middle mouse button
		tooltip = {
			background = "Hold \255\255\255\1middle mouse button\255\255\255\255 to drag the orderMenu around.",
		},
		showFilter = false
	},
}

local function IncludeRedUIFrameworkFunctions()
	New = WG.Red.New(widget)
	Copy = WG.Red.Copytable
	SetTooltip = WG.Red.SetTooltip
	GetSetTooltip = WG.Red.GetSetTooltip
	Screen = WG.Red.Screen
	GetWidgetObjects = WG.Red.GetWidgetObjects
end

local function RedUIchecks()
	local color = "\255\255\255\1"
	local passed = true
	if (type(WG.Red)~="table") then
		Spring.Echo(color..widget:GetInfo().name.." requires Red UI Framework.")
		passed = false
	elseif (type(WG.Red.Screen)~="table") then
		Spring.Echo(color..widget:GetInfo().name..">> strange error.")
		passed = false
	elseif (WG.Red.Version < NeededFrameworkVersion) then
		Spring.Echo(color..widget:GetInfo().name..">> update your Red UI Framework.")
		passed = false
	end
	if (not passed) then
		widgetHandler:ToggleWidget(widget:GetInfo().name)
		return false
	end
	IncludeRedUIFrameworkFunctions()
	return true
end

local function AutoResizeObjects() --autoresize v2
	if (LastAutoResizeX==nil) then
		LastAutoResizeX = CanvasX
		LastAutoResizeY = CanvasY
	end
	local lx,ly = LastAutoResizeX,LastAutoResizeY
	local vsx,vsy = Screen.vsx,Screen.vsy
	--local vsx,vsy = 3940,2160
	if ((lx ~= vsx) or (ly ~= vsy)) then
		local objects = GetWidgetObjects(widget)
		local scale = vsy/ly
		local skippedObjects = {}
		for i=1,#objects do
			local o = objects[i]
			local adjust = 0
			if ((o.movableSlaves) and (#o.movableSlaves > 0)) then
				adjust = (o.px*scale+o.sx*scale)-vsx
				if (((o.px+o.sx)-lx) == 0) then
					o._moveduetoresize = true
				end
			end
			if (o.px) then o.px = o.px * scale end
			if (o.py) then o.py = o.py * scale end
			if (o.sx) then o.sx = o.sx * scale end
			if (o.sy) then o.sy = o.sy * scale end
			if (o.fontsize) then o.fontsize = o.fontsize * scale end
			if (adjust > 0) then
				o._moveduetoresize = true
				o.px = o.px - adjust
				for j=1,#o.movableSlaves do
					local s = o.movableSlaves[j]
					s.px = s.px - adjust/scale
				end
			elseif ((adjust < 0) and o._moveduetoresize) then
				o._moveduetoresize = nil
				o.px = o.px - adjust
				for j=1,#o.movableSlaves do
					local s = o.movableSlaves[j]
					s.px = s.px - adjust/scale
				end
			end
		end
		LastAutoResizeX,LastAutoResizeY = vsx,vsy
	end
end
local function CalcGridHeight(r)
	local result = r.isy*(r.iy) + ICON_SML_HEIGHT + r.iSpreadY * (r.iy) + r.margin*2
	if (r.showFilter) then
		result = result + r.isy + r.iSpreadY
	end
	
	return result;
end

local function GetSpacingIndex()
	local val = Spring.GetBuildSpacing()
	for ind,s in ipairs(spacingList) do
		if val == s then
			return ind			
		end
	end
	
	return 1
end

local function CreateGrid(r)
	local background = {"rectangle",
		px=r.px,py=r.py,
		sx=r.isx*r.ix+r.iSpreadX*(r.ix-1) +r.margin*2,
		sy=CalcGridHeight(r),
		color=r.cbackground,
		border=r.cborder,
		movable=r.dragButton,
		movableSlaves={},
		obeyScreenEdge = true,
		overrideClick = {1,2},
		
		effects = {
			fadeInAtActivation = r.fadeTime,
			fadeOutAtDeactivation = r.fadeTime,
		},
	}
	
	local selectHighlight = {"rectangle",
		px=0,py=0,
		sx=r.isx,sy=r.isy,
		color={1,0,0,0.3},
		border={0.8,0,0,1},
		
		active=false,
		onUpdate=function(self)
			self.active = false
		end,
	}
	
	local mouseOverHighlight = Copy(selectHighlight,true)
	mouseOverHighlight.color={1,1,1,0.3}
	mouseOverHighlight.border={1,1,1,0.3}
	
	local heldHighlight = Copy(selectHighlight,true)
	heldHighlight.color={1,1,0,0.3}
	heldHighlight.border={1,1,0,0.3}
	
	local selectHighlightWide = Copy(selectHighlight,true)
	selectHighlightWide.sx=r.isx*2
	local mouseOverHighlightWide = Copy(mouseOverHighlight,true)
	mouseOverHighlightWide.sx=r.isx*2
	local heldHighlightWide = Copy(heldHighlight,true)
	heldHighlightWide.sx=r.isx*2

	local selectHighlightFlat = Copy(selectHighlight,true)
	selectHighlightFlat.sy=ICON_SML_HEIGHT
	local mouseOverHighlightFlat = Copy(mouseOverHighlight,true)
	mouseOverHighlightFlat.sy=ICON_SML_HEIGHT
	local heldHighlightFlat = Copy(heldHighlight,true)
	heldHighlightFlat.sy=ICON_SML_HEIGHT

	
	local icon = {"rectangle",
		px=0,py=0,
		sx=r.isx,sy=r.isy,
		color=r.cbuttonBackground,
		border=r.cborder,
		maxFontsize=15 * maxFontSizeFactor,
		options="n", --disable colorcodes
		captionColor=r.ctext,
		
		overrideCursor = true,
		overrideClick = {3},
		
		mouseHeld={
			{1,function(mx,my,self)
				heldHighlight.px = self.px
				heldHighlight.py = self.py
				heldHighlight.active = nil
			end},
		},
		mouseOver=function(mx,my,self)
			mouseOverHighlight.px = self.px
			mouseOverHighlight.py = self.py
			mouseOverHighlight.active = nil
			
			SetTooltip(tooltipExtension(self.tooltip))
		end,
		
		onUpdate=function(self)
			local _,_,_,curCmdName = sGetActiveCommand()
			if (curCmdName ~= nil) then
				if (self.cmdname == curCmdName) then
					selectHighlight.px = self.px
					selectHighlight.py = self.py
					selectHighlight.active = nil
				end
			end
		end,
		
		effects = background.effects,
		
		active=false,
	}
	local iconWide = Copy(icon,true)
	iconWide.mouseHeld={
			{1,function(mx,my,self)
				heldHighlightWide.px = self.px
				heldHighlightWide.py = self.py
				heldHighlightWide.active = nil
			end},
		}
	iconWide.mouseOver=function(mx,my,self)
			mouseOverHighlightWide.px = self.px
			mouseOverHighlightWide.py = self.py
			mouseOverHighlightWide.active = nil
			
			SetTooltip(self.tooltip)
		end
	iconWide.sx=r.isx*2
	local iconFlat = Copy(icon,true)
	iconFlat.mouseHeld={
			{1,function(mx,my,self)
				heldHighlightFlat.px = self.px
				heldHighlightFlat.py = self.py
				heldHighlightFlat.active = nil
			end},
		}
	iconFlat.mouseOver=function(mx,my,self)
			mouseOverHighlightFlat.px = self.px
			mouseOverHighlightFlat.py = self.py
			mouseOverHighlightFlat.active = nil
			
			SetTooltip(self.tooltip)
		end
	iconFlat.sy=ICON_SML_HEIGHT
	
	New(background)
	
	local backward = New(Copy(iconFlat,true))
	backward.tooltip = "Show Previous Page"
	backward.texture = ":n:"..LUAUI_DIRNAME.."Images/buildMenu/prev.png"
	local forward = New(Copy(iconFlat,true))
	forward.tooltip = "Show Next Page (hotkey \"N\" on build orders menu)"
	forward.texture = ":n:"..LUAUI_DIRNAME.."Images/buildMenu/next.png"
	local tspacing = New(Copy(icon,true))
	--tspacing.texture = ":n:"..LUAUI_DIRNAME.."Images/buildMenu/spacing"..GetSpacingIndex()..".png"
	tspacing.texture = ":n:"..LUAUI_DIRNAME.."Images/buildMenu/spacing.png"
	tspacing.caption = "    "..spacingList[GetSpacingIndex()].."    "
	tspacing.tooltip = "Build Spacing State : spacing is applied on shift-click-drag\n\n\n(click to change)"
	local tfacing = New(Copy(icon,true))
	tfacing.texture = ":n:"..LUAUI_DIRNAME.."Images/buildMenu/facing"..Spring.GetBuildFacing()..".png"
	tfacing.tooltip = "Build Orientation State\n\n\n(click to change)"
	local tfilter = New(Copy(iconWide,true))
	tfilter.tooltip = "Build Options Filter\n\n\n(click to change, or press \"B\")"
	tfilter.texture = ":n:"..LUAUI_DIRNAME.."Images/buildMenu/filter.png"
	
	local indicator = New({"rectangle",
		px=0,py=0,
		sx=r.isx,sy=ICON_SML_HEIGHT,
		captionColor=r.ctext,
		maxFontsize = 20 * maxFontSizeFactor,
		options = "n",
		
		effects = background.effects,
	})
	background.movableSlaves={backward,forward,indicator,tspacing,tfacing,tfilter}
	
	local icons = {}
	for y=1,r.iy do
		for x=1,r.ix do
			local b = New(Copy(icon,true))
			b.options = b.options.."o"
			b.px = background.px +r.margin + (x-1)*(r.iSpreadX + r.isx)
			if (r.showFilter) then
				b.py = background.py +r.margin + (y)*(r.iSpreadY + r.isy)
			else
				b.py = background.py +r.margin + (y-1)*(r.iSpreadY + r.isy)
			end
			table.insert(background.movableSlaves,b)
			icons[#icons+1] = b
			
			if ((y==r.iy) and (x==r.ix)) then
				backward.px = icons[#icons-r.ix+1].px
				forward.px = icons[#icons].px
				indicator.px = (forward.px + backward.px)/2

				tfacing.px = icons[#icons-r.ix+1].px
				tspacing.px = icons[#icons].px
				tfilter.px = (tfacing.px + tspacing.px)/2 - r.isx/2
				
				backward.py = icons[#icons].py + r.isy + r.iSpreadY
				forward.py = backward.py
				indicator.py = backward.py

				tfacing.py = background.py + r.margin
				tspacing.py = background.py + r.margin
				tfilter.py = background.py + r.margin
			end
		end
	end
	
	local stateRect = {"rectangle",
		border = r.cborder,
		
		effects = background.effects,
	}
	local stateRectangles = {}
	
	New(selectHighlight)
	New(mouseOverHighlight)
	New(heldHighlight)
	New(selectHighlightWide)
	New(mouseOverHighlightWide)
	New(heldHighlightWide)
	New(selectHighlightFlat)
	New(mouseOverHighlightFlat)
	New(heldHighlightFlat)

	--tooltip
	background.mouseOver = function(mx,my,self) SetTooltip(r.tooltip.background) end
	
	return {
		["background"] = background,
		["icons"] = icons,
		["backward"] = backward,
		["forward"] = forward,
		["indicator"] = indicator,
		["tfacing"] = tfacing,
		["tspacing"] = tspacing,
		["tfilter"] = tfilter,
		["stateRectangles"] = stateRectangles,
		["stateRect"] = stateRect,
	}
end

-- checks if unit name matches build filter
-- also flags if there are options present for each filter category
function checkFilter(uName)
	if buildOptionsTable[filter][uName] then
		return true
	end
	
	return false
end

-- enables filter categories if at least one matching unit is found
function checkEnableCategory(uName)
	for fType,table in ipairs(buildOptionsTable) do
		if buildOptionsTable[fType][uName] then
			hasOptions[fType] = true
		end
	end
end

-- used to jump to next available category, and to make sure filter is valid for current unit selection
function updateFilter(next)
	-- if current filter isn't compatible to current unit selection, adjust it
	if not hasOptions[filter] then
		next = true
	end
	
	-- jump to the next available category
	if next then
		nextFilter = filter
		for i=1,#hasOptions do
			nextFilter = nextFilter + 1
			if nextFilter > #filterLabel then
				nextFilter = 1
			end
			
			if hasOptions[nextFilter] then
				filter = nextFilter
				break;
			end
		end	
	end
end



local function UpdateGrid(g,cmds,orderType)
	if (#cmds==0) then
		g.background.active = false
	else
		g.background.active = nil
	end

	local curpage = g.page
	local icons = g.icons
	local page = {{}}
	
	for i=1,#cmds do
		local index = i-(#page-1)*#icons
		page[#page][index] = cmds[i]
		if ((i == (#icons*#page)) and (i~=#cmds)) then
			page[#page+1] = {}
		end
	end
	g.pageCount = #page
	
	if (curpage > g.pageCount) then
		curpage = 1
	end
	
	local iconsleft = (#icons-#page[curpage])
	if (iconsleft > 0) then
		for i=iconsleft+#page[curpage],#page[curpage]+1,-1 do
			icons[i].active = false --deactivate
		end
	end
	
	for i=1,#g.stateRectangles do
		g.stateRectangles[i].active = false
	end
	local usedstateRectangles = 0
	
	for i=1,#page[curpage] do
		local cmd = page[curpage][i]
		local icon = icons[i]
		icon.tooltip = cmd.tooltip
		icon.active = nil --activate
		icon.cmdname = cmd.name
		
		icon.texture = nil
		if (cmd.texture) then
			if (cmd.texture ~= "") then
				icon.texture = cmd.texture
			end
		end
		if (cmd.disabled) then		-- TODO apparently this does nothing
			icon.texturecolor = {0.5,0.5,0.5,1}	
		else
			icon.texturecolor = {1,1,1,1}
		end
		
		icon.mouseClick = {
			{1,function(mx,my,self)
				Spring.SetActiveCommand(Spring.GetCmdDescIndex(cmd.id),1,true,false,Spring.GetModKeyState())
			end},
			{3,function(mx,my,self)
				Spring.SetActiveCommand(Spring.GetCmdDescIndex(cmd.id),3,false,true,Spring.GetModKeyState())
			end},
		}
		
		if (orderType == 1) then --build orders
			icon.texture = "#"..cmd.id*-1
			if (cmd.params[1]) then
				icon.caption = "\n\n"..cmd.params[1].."          "
			else
				icon.caption = nil
			end
			if (cmd.disabled) then
				icon.texture = ":n:"..LUAUI_DIRNAME.."Images/buildMenu/disabled.png"
			end
		else
			if (cmd.type == 5) then --state cmds (fire at will, etc)
				icon.caption = " "..(cmd.params[cmd.params[1]+2] or cmd.name).." "
				
				local stateCount = #cmd.params-1 --number of states for the cmd
				local curState = cmd.params[1]+1
				
				for i=1,stateCount do
					usedstateRectangles = usedstateRectangles + 1
					local s = g.stateRectangles[usedstateRectangles]
					if (s == nil) then
						s = New(Copy(g.stateRect,true))
						g.stateRectangles[usedstateRectangles] = s
						table.insert(g.background.movableSlaves,s)
					end
					s.active = nil --activate
					
					local spread = 2
					s.sx = (icon.sx-(spread*(stateCount-1+2)))/stateCount
					s.sy = icon.sy/7
					s.px = icon.px+spread + (s.sx+spread)*(i-1)
					s.py = icon.py + icon.sy - s.sy -spread
					
					if (i == curState) then
						if (stateCount < 4) then
							if (i == 1) then
								s.color = {0.8,0,0,1}
							elseif (i == 2) then
								if (stateCount == 3) then
									s.color = {0.8,0.8,0,1}
								else
									s.color = {0,0.8,0,1}
								end
							elseif (i == 3) then
								s.color = {0,0.8,0,1}
							end
						else
							s.color = {0.8,0.8,0.8,1}
						end
					else
						s.color = nil
					end
				end
			else
				icon.caption = " "..cmd.name.." "
			end
		end
	end
	
	if (#page>1) then
		g.forward.mouseClick={
			{1,function(mx,my,self)
				g.page = g.page + 1
				if (g.page > g.pageCount) then
					g.page = 1
				end
				UpdateGrid(g,cmds,orderType)
			end},
		}
		g.backward.mouseClick={
			{1,function(mx,my,self)
				g.page = g.page - 1
				if (g.page < 1) then
					g.page = g.pageCount
				end
				UpdateGrid(g,cmds,orderType)
			end},
		}
		g.backward.active = nil --activate
		g.forward.active = nil
		g.indicator.active = nil
		g.indicator.caption = "    "..curpage.." / "..g.pageCount.."    "
	else
		g.backward.active = false
		g.forward.active = false
		g.indicator.active = false
	end

	if (#cmds > 0 and orderType == 1) then --build orders
		g.tspacing.mouseClick={
			{1,function(mx,my,self)
				local val = GetSpacingIndex()
				
				if (val < #spacingList) then
					Spring.SetBuildSpacing(spacingList[val + 1])
				else
					Spring.SetBuildSpacing(spacingList[1])
				end
				UpdateGrid(g,cmds,orderType)
			end},
		}
		
		g.tfacing.mouseClick={
			{1,function(mx,my,self)
				local val = Spring.GetBuildFacing()
				if (val < 3) then
					Spring.SetBuildFacing(val + 1)
				else
					Spring.SetBuildFacing(0)
				end
				
				UpdateGrid(g,cmds,orderType)
			end},
		}
		g.tfilter.mouseClick={
			{1,function(mx,my,self)
				updateFilter(true)
				updateHax = true
			end},
		}
		g.tspacing.active = nil --activate
		g.tfacing.active = nil
		g.tfilter.active = nil
		g.tfilter.caption = "    "..filterLabel[filter].."    "
		g.tfacing.texture = ":n:"..LUAUI_DIRNAME.."Images/buildMenu/facing"..Spring.GetBuildFacing()..".png"
		--g.tspacing.texture = ":n:"..LUAUI_DIRNAME.."Images/buildMenu/spacing.png"
		g.tspacing.caption = "    "..spacingList[GetSpacingIndex()].."    "
	else
		g.tspacing.active = false
		g.tfacing.active = false
		g.tfilter.active = false
	end	
end

-- used to jump to next build options page, if available
function nextBuildOptionsPage()
	local g = buildMenu
	if (g and #latestBuildCmds > 0) then
		g.page = g.page + 1
		if (g.page > g.pageCount) then
			g.page = 1
		end
		UpdateGrid(g,latestBuildCmds,1)
	end				
end

function widget:Initialize()
	
	-- initialize filter tables
	for i=1,#filterLabel do
		buildOptionsTable[i] = {}	
	end
	for id,unitDef in pairs(UnitDefs) do
		local registered = false
		for cat,val in pairs(unitDef.modCategories) do
			-- if unit already registered, skip
			if not registered then
				if cat == "energy" or cat == "metal" or cat == "storage" then
					buildOptionsTable[FILTER_ECO][unitDef.name] = true
					registered = true
					break
				elseif cat == "plant" or cat == "nanotower" or cat == "factory" then
					buildOptionsTable[FILTER_PLANT][unitDef.name] = true
					registered = true
					break
				elseif cat == "upgrade_red"  then
					buildOptionsTable[FILTER_RED][unitDef.name] = true
					registered = true
					break
				elseif cat == "upgrade_green"  then
					buildOptionsTable[FILTER_GREEN][unitDef.name] = true
					registered = true
					break
				elseif cat == "upgrade_blue"  then
					buildOptionsTable[FILTER_BLUE][unitDef.name] = true
					registered = true
					break
				end
			end
		end
		
		if not registered then
			buildOptionsTable[FILTER_OTHER][unitDef.name] = true
		end
		
	end
	PassedStartupCheck = RedUIchecks()
	if (not PassedStartupCheck) then return end
		
	buildMenu = CreateGrid(Config.buildMenu)
	orderMenu = CreateGrid(Config.orderMenu)
	
	buildMenu.page = 1
	orderMenu.page = 1
	
	AutoResizeObjects() --fix for displacement on crash issue
end

local function onNewCommands(buildCmds,otherCmds)
	if (SelectedUnitsCount==0) then
		buildMenu.page = 1
		orderMenu.page = 1
	end

	
	UpdateGrid(buildMenu,buildCmds,1)
	UpdateGrid(orderMenu,otherCmds,2)
	latestBuildCmds = buildCmds
end

local function onWidgetUpdate() --function widget:Update()
	AutoResizeObjects()
	SelectedUnitsCount = sGetSelectedUnitsCount()
end

--save/load stuff
--currently only position

--[[  FIXME: commented out, something was making this not work properly if left enabled
function widget:GetConfigData() --save config
	if (PassedStartupCheck) then
		local vsy = Screen.vsy
		local unscale = CanvasY/vsy --needed due to autoresize, stores unresized variables
		Config.buildMenu.px = buildMenu.background.px * unscale
		Config.buildMenu.py = buildMenu.background.py * unscale
		Config.orderMenu.px = orderMenu.background.px * unscale
		Config.orderMenu.py = orderMenu.background.py * unscale
		return {Config=Config}
	end
end
function widget:SetConfigData(data) --load config
	if (data.Config ~= nil) then
		Config.buildMenu.px = data.Config.buildMenu.px
		Config.buildMenu.py = data.Config.buildMenu.py
		Config.orderMenu.px = data.Config.orderMenu.px
		Config.orderMenu.py = data.Config.orderMenu.py
	end
end
]]


--lots of hacks under this line ------------- overrides/disables default spring menu layout and gets current orders + filters out some commands
local hijackedLayout = false
function widget:Shutdown()
	if (hijackedLayout) then
		widgetHandler:ConfigLayoutHandler(true)
		Spring.ForceLayoutUpdate()
	end
end
local function GetCommands()
	local hiddenCmds = {
		[76] = true, --load units clone
		[65] = true, --selfd
		[9] = true, --gatherwait
		[8] = true, --squadwait
		[7] = true, --deathwait
		[6] = true, --timewait
	}
	local buildCmds = {}
	local statecmds = {}
	local otherCmds = {}
	local buildCmdsCount = 0
	local stateCmdsCount = 0
	local otherCmdsCount = 0

	-- reset build filter category option flags
	for i,_ in ipairs(filterLabel) do
		hasOptions[i] = false
	end

	local uName = ""
	for index,cmd in pairs(sGetActiveCmdDescs()) do
		if (type(cmd) == "table") then
			if (
			(not hiddenCmds[cmd.id]) and
			(cmd.action ~= nil) and
			--(not cmd.disabled) and
			(cmd.type ~= 21) and
			(cmd.type ~= 18) and
			(cmd.type ~= 17)
			) then
				if ((cmd.type == 20) --build building
				or (ssub(cmd.action,1,10) == "buildunit_")) then
						uName = ssub(cmd.action,11)
						 
						-- update build filter category option flags
						checkEnableCategory(uName)
						
						buildCmdsCount = buildCmdsCount + 1
						buildCmds[buildCmdsCount] = cmd
				elseif (cmd.type == 5) then
					stateCmdsCount = stateCmdsCount + 1
					statecmds[stateCmdsCount] = cmd
				else
					otherCmdsCount = otherCmdsCount + 1
					otherCmds[otherCmdsCount] = cmd
				end
			end
		end
	end

	updateFilter()	
	filteredBuildCmdsCount = 0
	filteredBuildCmds = {}
	for i=1,buildCmdsCount do
		local cmd = buildCmds[i]
		uName = ssub(cmd.action,11)
		if checkFilter(uName) then
			filteredBuildCmdsCount = filteredBuildCmdsCount + 1
			filteredBuildCmds[filteredBuildCmdsCount] = cmd
		end
	end
	
	local tempCmds = {}
	for i=1,stateCmdsCount do
		tempCmds[i] = statecmds[i]
	end
	for i=1,otherCmdsCount do
		tempCmds[i+stateCmdsCount] = otherCmds[i]
	end
	otherCmdsCount = otherCmdsCount + stateCmdsCount
	otherCmds = tempCmds
	
	return filteredBuildCmds,otherCmds
end
local hijackAttempts = 0
local layoutPing = 54352 --random number
local function hijackLayout()
	if (hijackAttempts>5) then
		Spring.Echo(widget:GetInfo().name.." failed to hijack config layout.")
		widgetHandler:ToggleWidget(widget:GetInfo().name)
		return
	end
	local function dummyLayoutHandler(xIcons, yIcons, cmdCount, commands) --gets called on selection change
		WG.layoutPingHax = 54352
		widgetHandler.commands = commands
		widgetHandler.commands.n = cmdCount
		widgetHandler:CommandsChanged() --call widget:CommandsChanged()
		local iconList = {[1337]=9001}
		return "", xIcons, yIcons, {}, {}, {}, {}, {}, {}, {}, iconList
	end
	widgetHandler:ConfigLayoutHandler(dummyLayoutHandler) --override default build/orderMenu layout
	Spring.ForceLayoutUpdate()
	hijackedLayout = true
	hijackAttempts = hijackAttempts + 1
end

local function haxLayout()
	if (WG.layoutPingHax~=layoutPing) then
		hijackLayout()
	end
	WG.layoutPingHax = nil
	updateHax = true
end
function widget:CommandsChanged()
	haxLayout()
end
function widget:Update()
	onWidgetUpdate()
	if (updateHax or firstUpdate) then
		if (firstUpdate) then
			haxLayout()
			firstUpdate = nil
		end
		onNewCommands(GetCommands())
		updateHax = false
		updateHax2 = true
	end
	if (updateHax2) then
		if (SelectedUnitsCount == 0) then
			onNewCommands({},{}) --flush
			updateHax2 = false
		end
	end
end

-- use filter key to cycle through filter options
function widget:KeyPress(key, modifier, isRepeat)
	if key == FILTER_KEY  then
		updateFilter(true)
		updateHax = true
	end
	if key == PAGE_KEY  then
		nextBuildOptionsPage()
		updateHax = true
	end
end
