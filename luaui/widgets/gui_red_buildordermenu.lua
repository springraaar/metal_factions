function widget:GetInfo()
	return {
	version   = "8.1",
	name      = "Red Build/Order Menu",
	desc      = "Build/Order Menu. Requires Red UI Framework",
	author    = "Regret, modified by raaar",
	date      = "August 9, 2009", --modified by raaar, sep 2015
	license   = "GNU GPL, v2 or later",
	layer     = 11,
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


local vsx, vsy = gl.GetViewSizes()
local maxFontSizeFactor = 1
if (vsy > 1080) then
	maxFontSizeFactor = vsy / 1080
end

local spGetSelectedUnitsCount = Spring.GetSelectedUnitsCount
local spGetActiveCommand = Spring.GetActiveCommand
local spSetActiveCommand = Spring.SetActiveCommand
local spGetActiveCmdDescs = Spring.GetActiveCmdDescs
local spGetBuildSpacing = Spring.GetBuildSpacing
local spGetBuildFacing = Spring.GetBuildFacing
local spGetActionHotKeys = Spring.GetActionHotKeys
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
local latestUnfilteredBuildCmds = {}

local ICON_FLAT_HEIGHT = 15
local ICON_FLAT2_HEIGHT = 32
local ICON_SML_HEIGHT = 36
local ICON_NORMAL_HEIGHT = 42

local updateHax = false
local updateHax2 = true
local firstUpdate = true

local TYPE_BUILD = 1
local TYPE_ORDER = 2
local TYPE_ICONORDER = 3 

local CLEANUP_TAG = 1

-- custom commands
VFS.Include("lualibs/custom_cmd.lua")
VFS.Include("lualibs/util.lua")
VFS.Include("luaui/headers/redui_aux.lua")

local iconCmdPosition = {
	[CMD.ATTACK] = 1,
	[CMD.MANUALFIRE] = 2,
	[CMD.FIGHT] = 3,
	[CMD.MOVE] = 4,
	[CMD_JUMP] = 5,
	[CMD_DASH] = 6,	
	[CMD.PATROL] = 7,
	[CMD.GUARD] = 8,	
	[CMD.WAIT] = 9,
	[CMD.STOP] = 10,
	[CMD.LOAD_UNITS] = 11,
	[CMD.UNLOAD_UNITS] = 12,
	[CMD.REPAIR] = 13,
	[CMD.RECLAIM] = 14,
	[CMD.RESTORE] = 15,
	[CMD.CAPTURE] = 16,
	[CMD_AREAMEX] = 17,
	[CMD_UPGRADEMEX] = 18,
	[CMD_UPGRADEMEX2] = 19
}

local iconCmdTex = {
	[CMD.MOVE] = "icon_move.png",
	[CMD_JUMP] = "icon_jump.png",
	[CMD_DASH] = "icon_dash.png",
	[CMD.ATTACK] = "icon_attack.png",
	[CMD.MANUALFIRE] = "icon_manualfire.png",
	[CMD.FIGHT] = "icon_fight.png",
	[CMD.REPAIR] = "icon_repair.png",
	[CMD.PATROL] = "icon_patrol.png",
	[CMD.GUARD] = "icon_guard.png",
	[CMD.RESTORE] = "icon_restore.png",
	[CMD.RECLAIM] = "icon_reclaim.png",
	[CMD.CAPTURE] = "icon_capture.png",
	[CMD.STOP] = "icon_stop.png",
	[CMD.WAIT] = "icon_wait.png",
	[CMD.LOAD_UNITS] = "icon_load.png",
	[CMD.UNLOAD_UNITS] = "icon_unload.png",
	[CMD_UPGRADEMEX] = "",
	[CMD_UPGRADEMEX2] = "",
	[CMD_AREAMEX] = ""
}


local spacingList = {0,1,10,20}
local stdHotkeysByAction = {} 
local optionalUnitNames = {}

-- simplify a hotkey string, remove the modifiers
-- (visually simpler, but may not be a good idea)
local function simplifyHotkeyStr(str)
	str = str:lower():gsub("shift","")
	str = str:gsub("any","")
	str = str:gsub("ctrl","")
	str = str:gsub("+","")
	return str
end

-- gets tooltip hotkey string
local function tooltipHotkey(key, action)
	if (WG.unboundDefKeys and WG.unboundDefKeys[key]) then
		key = nil
	end
	if (WG.customHotkeys and WG.customHotkeys[action]) then
		key = WG.customHotkeys[action]
	end
	-- hardcoded, change this eventually
	if action == "buildcategory" then
		key = "B"
	end
	if key == nil then
		key = stdHotkeysByAction[action]
		if key == nil then
			local actions = {}
			if (action == "buildfacing" ) then
				actions = {"buildfacing inc", "buildfacing desc"}
			elseif (action == "buildspacing") then
				actions = {"buildspacing inc", "buildspacing desc"}
			else
				actions = {action}
			end
			
			local addedKeys = {}
			for _,actionStr in pairs(actions) do
				local hkTable = spGetActionHotKeys(actionStr)
				if hkTable and #hkTable > 0 then
					for _,k in pairs(hkTable) do
						k = simplifyHotkeyStr(k)
						if key == nil then
							key = "\""..string.upper(k).."\""
						else
							if not addedKeys[k] then
								key = key.." , ".."\""..string.upper(k).."\""
							end	
						end
						addedKeys[k] = true
					end
				end
			end
		end
		if key ~= nil then
			stdHotkeysByAction[action] = key
		end
	else 
		key = "\""..string.upper(key).."\""
	end
	if key ~= nil then
		return "\255\100\255\100 Hotkey "..key.."\255\255\255\255"
	end
	return ""
end

-- adds relevant information for some tooltip texts like default hotkeys
local function tooltipExtension(tooltip,cmdAction)
	if (tooltip) then
		if cmdAction == "move" then
			tooltip = tooltip .. ". Click-drag to move in line formation."..tooltipHotkey("m","move")
		elseif cmdAction == "guard" then
			tooltip = tooltip .. "."..tooltipHotkey("g","guard")
		elseif cmdAction == "stop" then
			tooltip = tooltip .. "."..tooltipHotkey("s","stop")
		elseif cmdAction == "wait" then
			tooltip = tooltip .. "."..tooltipHotkey("w","wait")
		elseif cmdAction == "jump" then
			tooltip = tooltip .. "."..tooltipHotkey("j","jump")
		elseif cmdAction == "dash" then
			tooltip = tooltip .. "."..tooltipHotkey("j","dash")
		elseif cmdAction == "attack" then
			tooltip = tooltip .. ". Click-drag to attack targets within an area."..tooltipHotkey("a","attack")
		elseif cmdAction == "fight" then
			tooltip = tooltip .. ". Click-drag for line formation."..tooltipHotkey("f","fight")
		elseif cmdAction == "patrol" then
			tooltip = tooltip .. ". Click-drag for line formation."..tooltipHotkey("p","patrol")
		elseif cmdAction == "repair" then
			tooltip = tooltip .. ". Click-drag to repair targets within an area."..tooltipHotkey("r","repair")
		elseif cmdAction == "reclaim" then
			tooltip = tooltip .. ". Click-drag to reclaim targets within an area."..tooltipHotkey("e","reclaim")
		elseif cmdAction == "cloak" then
			tooltip = tooltip .. ". Also toggles fire state."..tooltipHotkey("k","cloak")
		elseif cmdAction == "areamex" then
			tooltip = tooltip .. "."..tooltipHotkey(nil,"areamex")
		elseif cmdAction == "areamex2" then
			tooltip = tooltip .. "."..tooltipHotkey(nil,"areamex2")
		elseif cmdAction == "areamex2h" then
			tooltip = tooltip .. "."..tooltipHotkey(nil,"areamex2h")
		elseif cmdAction == "manualfire" then
			tooltip = tooltip .. "."..tooltipHotkey(nil,"manualfire")
		elseif cmdAction == "onoff" then
			tooltip = tooltip .. "."..tooltipHotkey(nil,"onoff")
		elseif cmdAction and string.sub(cmdAction,1,9) == "buildunit" and tooltip:find("Unit disabled") == nil then
			tooltip = cmdAction .. tooltip
		end
	end
	
	return tooltip
end

local Config = {
	buildMenu = {
		px = 0,py = CanvasY - 340,
		
		isx = ICON_NORMAL_HEIGHT,isy = ICON_NORMAL_HEIGHT, --icon size
		ix = 6,iy = 3, --icons x/y
		iSpreadX=0,iSpreadY=0, --space between icons
		maxFontsize=28,
		margin = 5, --distance from background border
		
		fadeTime = 0.25, --fade effect time, in seconds
		
		ctext = {0.9,0.9,0.9,1}, --color {r,g,b,alpha}
		cbackground = {0,0,0,0.6},
		cborder = {0,0,0,1},
		cbuttonBackground = {0.1,0.1,0.1,1},
		
		--dragButton = {2}, --middle mouse button
		tooltip = {
			background = "Build orders menu",
			--background = "Hold \255\255\255\1middle mouse button\255\255\255\255 to drag the buildMenu around.",
		},
		showFilter = true
	},
	orderMenu = {
		px = 0,py = CanvasY - 435,
		
		isx = ICON_NORMAL_HEIGHT,isy = ICON_FLAT2_HEIGHT,
		ix = 6,iy = 2,
		
		iSpreadX=0,iSpreadY=0,
		maxFontsize=15,
		margin = 5,
		
		fadeTime = 0.25,
		
		ctext = {0.9,0.9,0.9,1},
		cbackground = {0,0,0,0.6},
		cborder = {0,0,0,1},
		cbuttonBackground={0.1,0.1,0.1,1},
		
		--dragButton = {2}, --middle mouse button
		tooltip = {
			background = "State / Morph orders menu",
			--background = "Hold \255\255\255\1middle mouse button\255\255\255\255 to drag the orderMenu around.",
		},
		showFilter = false
	},
	iconOrderMenu = {
		px = 0,py = CanvasY - 538,
		
		isx = ICON_SML_HEIGHT,isy = ICON_SML_HEIGHT,
		ix = 7,iy = 2,
		
		iSpreadX=0,iSpreadY=0,
		maxFontsize=15,
		margin = 5,
		
		fadeTime = 0.25,
		
		ctext = {0.9,0.9,0.9,1},
		cbackground = {0,0,0,0.6},
		cborder = {0,0,0,1},
		cbuttonBackground={0.1,0.1,0.1,1},
		
		--dragButton = {2}, --middle mouse button
		tooltip = {
			background = "Orders menu",
			--background = "Hold \255\255\255\1middle mouse button\255\255\255\255 to drag the orderMenu around.",
		},
		showFilter = false
	},	
}

-- adjust Y offsets of grids to attach them to each other
local function adjustGridYOffsets()
	local buildMenuH = buildMenu.background.sy
	local orderMenuH = orderMenu.background.sy
	local iconOrderMenuH = iconOrderMenu.background.sy

	local oldBuildMenuY = buildMenu.background.py
	local oldOrderMenuY = orderMenu.background.py
	local oldIconOrderMenuY = iconOrderMenu.background.py

	local gap = 5 * scale
	local topOffset = 220 * scale
	iconOrderMenu.background.py = topOffset 
	orderMenu.background.py = topOffset + iconOrderMenuH + gap	
	buildMenu.background.py = topOffset + orderMenuH + iconOrderMenuH + gap*2
	
	local buildMenuYShift = buildMenu.background.py - oldBuildMenuY
	local orderMenuYShift = orderMenu.background.py - oldOrderMenuY
	local iconOrderMenuYShift = iconOrderMenu.background.py - oldIconOrderMenuY
	
	local slaves = buildMenu.background.movableSlaves
	--Spring.Echo("build slaves="..#slaves)
	local o,c,niChilds = nil
	if (slaves and #slaves > 0) then
		for i=1,#slaves do
			o = slaves[i]
			o.py = o.py + buildMenuYShift
		end
	end
	slaves = orderMenu.background.movableSlaves
	if (slaves and #slaves > 0) then
		for i=1,#slaves do
			o = slaves[i]
			o.py = o.py + orderMenuYShift
			niChilds = o.nonInteractiveChilds
			if (niChilds and #niChilds > 0) then
				for j=1,#niChilds do
					c = niChilds[j]
					c.py = c.py + orderMenuYShift
				end
			end
		end
	end
	slaves = iconOrderMenu.background.movableSlaves
	--Spring.Echo("iconorder slaves="..#slaves)
	if (slaves and #slaves > 0) then
		for i=1,#slaves do
			o = slaves[i]
			o.py = o.py + iconOrderMenuYShift
		end
	end
end

function getScale(vsx,lx,vsy,ly)
	return vsy/ly
end 

local function CalcGridHeight(r,rows,hasPages)

	local result = r.isy*(rows) + (hasPages and ICON_FLAT_HEIGHT or 0)+ r.iSpreadY * (rows) + r.margin*2
	if (r.showFilter) then
		result = result + r.isy + r.iSpreadY
	end
	
	return result;
end

local function GetSpacingIndex()
	local val = spGetBuildSpacing()
	for ind,s in ipairs(spacingList) do
		if val == s then
			return ind			
		end
	end
	
	return 1
end

local function CreateGrid(r)
	-- default to full table
	local rows = r.iy
	local columns = r.ix
	local hasPages = true
		
	local background = {"rectangle",
		px=r.px,py=r.py,
		sx=r.isx*columns+r.iSpreadX*(columns-1) +r.margin*2,
		sy=CalcGridHeight(r,rows,hasPages),
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
		color={0,1,0,0.45},
		border={0.3,1,0.3,1},
		
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
	selectHighlightFlat.sy=ICON_FLAT_HEIGHT
	local mouseOverHighlightFlat = Copy(mouseOverHighlight,true)
	mouseOverHighlightFlat.sy=ICON_FLAT_HEIGHT
	local heldHighlightFlat = Copy(heldHighlight,true)
	heldHighlightFlat.sy=ICON_FLAT_HEIGHT
	
	local icon = {"rectangle",
		px=0,py=0,
		sx=r.isx,sy=r.isy,
		color=r.cbuttonBackground,
		border=r.cborder,
		maxFontsize = r.maxFontsize * maxFontSizeFactor,
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
			setTooltip(tooltipExtension(self.tooltip,self.cmdAction))
		end,
		
		onUpdate=function(self)
			local _,_,_,curCmdName = spGetActiveCommand()
			if (curCmdName ~= nil) then
				if (self.cmdName == curCmdName) then
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
	iconWide.maxFontsize = 15 * maxFontSizeFactor
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
			
			setTooltip(self.tooltip)
		end
	iconWide.sx=r.isx*2
	local iconFlat = Copy(icon,true)
	iconFlat.maxFontsize = 15 * maxFontSizeFactor
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
			
			setTooltip(self.tooltip)
		end
	iconFlat.sy=ICON_FLAT_HEIGHT
	New(background)
	
	local backward = New(Copy(iconFlat,true))
	backward.tooltip = "Show Previous Page"
	backward.texture = LUAUI_DIRNAME.."Images/buildmenu/prev.png"
	local forward = New(Copy(iconFlat,true))
	forward.tooltip = "Show Next Page (hotkey \"N\" on build orders menu)"
	forward.texture = LUAUI_DIRNAME.."Images/buildmenu/next.png"
	local tspacing = New(Copy(icon,true))
	tspacing.texture = ":n:"..LUAUI_DIRNAME.."Images/buildmenu/spacing.png"
	tspacing.caption = "    "..spacingList[GetSpacingIndex()].."    "
	tspacing.tooltip = "Click to change building spacing."..tooltipHotkey(nil, "buildspacing").."\nNOTE: spacing is applied on shift-click-drag"
	tspacing.maxFontsize = 15 * maxFontSizeFactor
	local tfacing = New(Copy(icon,true))
	tfacing.texture = LUAUI_DIRNAME.."Images/buildmenu/facing"..spGetBuildFacing()..".png"
	tfacing.tooltip = "Click to change building orientation."..tooltipHotkey(nil, "buildfacing")
	local tfilter = New(Copy(iconWide,true))
	tfilter.tooltip = "Click to change build options category."..tooltipHotkey(nil,"buildcategory")
	tfilter.texture = LUAUI_DIRNAME.."Images/buildmenu/filter.png"

	local tqueue = New(Copy(icon,true))
	tqueue.maxFontsize = 25 * maxFontSizeFactor
	tqueue.texture = LUAUI_DIRNAME.."Images/buildmenu/queue.png"
	tqueue.tooltip = "Total Queue Size\n\n\n(right-click to reset)"
	
	local indicator = New({"rectangle",
		px=0,py=0,
		sx=r.isx,sy=ICON_FLAT_HEIGHT,
		captionColor=r.ctext,
		maxFontsize = 17 * maxFontSizeFactor,
		options = "n",
		
		effects = background.effects,
	})
	background.movableSlaves={backward,forward,indicator,tspacing,tfacing,tfilter,tqueue}
	
	local icons = {}
	for y=1,r.iy do
		for x=1,r.ix do
			local b = New(Copy(icon,true))
			--b.cleanupTag = CLEANUP_TAG
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
				tqueue.px = icons[#icons-1].px
				tfilter.px = (tfacing.px + tspacing.px)/2 - r.isx/2
				
				backward.py = icons[#icons].py + r.isy + r.iSpreadY
				forward.py = backward.py
				indicator.py = backward.py

				tfacing.py = background.py + r.margin
				tspacing.py = background.py + r.margin
				tqueue.py = background.py + r.margin
				tfilter.py = background.py + r.margin
			end
		end
	end
	
	local stateRect = {"rectangle",
		border = r.cborder,
		
		effects = background.effects,
	}
	
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
	background.mouseOver = function(mx,my,self) setTooltip(r.tooltip.background) end
	
	return {
		["stateRect"] = stateRect,
		["background"] = background,
		["r"] = r,
		["icons"] = icons,
		["backward"] = backward,
		["forward"] = forward,
		["indicator"] = indicator,
		["tfacing"] = tfacing,
		["tspacing"] = tspacing,
		["tqueue"] = tqueue,
		["tfilter"] = tfilter,
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


local function UpdateGrid(g,cmds,orderType,unfilteredCmds)
	cleanupTaggedObjects(CLEANUP_TAG)
	local nCommands = #cmds
	if (nCommands==0) then
		g.background.active = false
	else
		g.background.active = nil
	end
	
	local curPage = g.page
	local icons = g.icons
	local page = {{}}
	
	local totalBuildQueueSize = 0
	if (orderType == TYPE_BUILD and unfilteredCmds) then --build orders
		for i=1,#unfilteredCmds do
			local cmd = unfilteredCmds[i]
			if (cmd.params[1]) then
				totalBuildQueueSize = totalBuildQueueSize +cmd.params[1]
			end
		end
	end		
	for i=1,nCommands do
		local index = i-(#page-1)*#icons
		page[#page][index] = cmds[i]
		if ((i == (#icons*#page)) and (i~=nCommands)) then
			page[#page+1] = {}
		end
	end
	g.pageCount = #page
	
	if (curPage > g.pageCount) then
		curPage = 1
	end
	
	-- update background size
	local r = g.r
	local rows = r.iy
	local columns = r.ix
	if nCommands then
		rows = math.min(r.iy, 1+math.floor((nCommands-1)/r.ix))
		columns = math.min(nCommands,r.ix)
	end
	local hasPages = g.pageCount > 1	
	if (orderType ~= TYPE_BUILD) then
		g.background.sx = (r.isx*columns+r.iSpreadX*(columns-1) +r.margin*2) * scale
	end 
	g.background.sy = CalcGridHeight(r,rows,hasPages)*scale
	--Spring.Echo(" isy="..icons[1].sy.." r.isy="..r.isy*scale)
	
	local iconsleft = (#icons-#page[curPage])
	if (iconsleft > 0) then
		for i=iconsleft+#page[curPage],#page[curPage]+1,-1 do
			icons[i].active = false --deactivate
		end
	end
	

	for i=1,#page[curPage] do
		local cmd = page[curPage][i]
		local icon = icons[i]
		icon.tooltip = cmd.tooltip
		icon.active = nil --activate
		icon.cmdName = cmd.name
		icon.cmdAction = cmd.action
		
		icon.texture = nil
		if (cmd.texture) then
			if (cmd.texture ~= "") then
				icon.texture = cmd.texture
			end
		end

		icon.mouseClick = {
			{1,function(mx,my,self)
				local descIdx = Spring.GetCmdDescIndex(cmd.id)
				if descIdx then
					spSetActiveCommand(descIdx,1,true,false,Spring.GetModKeyState())
				end
			end},
			{3,function(mx,my,self)
				local descIdx = Spring.GetCmdDescIndex(cmd.id)
				if descIdx then
					spSetActiveCommand(descIdx,3,false,true,Spring.GetModKeyState())
				end
			end},
		}
		
		if (orderType == TYPE_BUILD) then --build orders
			icon.nonInteractiveChilds = {}
			icon.texture = "#"..cmd.id*-1
			if (cmd.params[1]) then
				icon.caption = " "..cmd.params[1].." "
				icon.textureColor = {0.5,0.5,0.5,1}
				--Spring.Echo(cmd.id .. "|" .. icon.caption)
			else
				icon.textureColor = {1,1,1,1}
				icon.caption = nil
			end
			if (cmd.disabled) then
				icon.texture = LUAUI_DIRNAME.."Images/buildmenu/disabled.png"
			end
		else
			if (cmd.type == 5) then --state cmds (fire at will, etc)
				icon.caption = " "..(cmd.params[cmd.params[1]+2] or cmd.name).." "
				local stateCount = #cmd.params-1 --number of states for the cmd
				local curState = cmd.params[1]+1

				local stateRects = {}			
				for i=1,stateCount do
					local s = New(Copy(g.stateRect,true))
					s.cleanupTag = CLEANUP_TAG
					stateRects[#stateRects+1] = s
					s.active = false
					
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
				icon.nonInteractiveChilds = stateRects
			else
				icon.nonInteractiveChilds = {}
				if (iconCmdTex[cmd.id]) then
					if not icon.texture then 
						icon.texture = LUAUI_DIRNAME.."Images/buildmenu/"..iconCmdTex[cmd.id]
					end
				else
					local caption = cmd.name
					-- remove the "Form" from morph options
					local idx = string.find(caption, ' Form', 1, true)
					if idx then
						caption = string.sub(caption,1,idx-1)
					end
					icon.caption = " "..caption.." "
				end
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
				UpdateGrid(g,cmds,orderType,unfilteredCmds)
			end},
		}
		g.backward.mouseClick={
			{1,function(mx,my,self)
				g.page = g.page - 1
				if (g.page < 1) then
					g.page = g.pageCount
				end
				UpdateGrid(g,cmds,orderType,unfilteredCmds)
			end},
		}
		g.backward.active = nil --activate
		g.forward.active = nil
		g.indicator.active = nil
		g.indicator.caption = "    "..curPage.." / "..g.pageCount.."    "
	else
		g.backward.active = false
		g.forward.active = false
		g.indicator.active = false
	end

	if (nCommands > 0 and orderType == TYPE_BUILD) then --build orders
		g.tspacing.mouseClick={
			{1,function(mx,my,self)
				local val = GetSpacingIndex()
				
				if (val < #spacingList) then
					Spring.SetBuildSpacing(spacingList[val + 1])
				else
					Spring.SetBuildSpacing(spacingList[1])
				end
				--UpdateGrid(g,cmds,orderType,unfilteredCmds)
			end},
		}
		g.tspacing.onUpdate = function(self)
			g.tspacing.caption = "    "..spGetBuildSpacing().."    "
		end
		
		g.tfacing.mouseClick={
			{1,function(mx,my,self)
				local val = spGetBuildFacing()
				if (val < 3) then
					Spring.SetBuildFacing(val + 1)
				else
					Spring.SetBuildFacing(0)
				end
				
				--UpdateGrid(g,cmds,orderType,unfilteredCmds)
			end},
		}
		g.tfacing.onUpdate = function(self)
			g.tfacing.texture = LUAUI_DIRNAME.."Images/buildmenu/facing"..spGetBuildFacing()..".png"
		end
		g.tqueue.mouseClick={
			{3,function(mx,my,self)
				for i=1,#unfilteredCmds do
					local cmd = unfilteredCmds[i]
					spSetActiveCommand(Spring.GetCmdDescIndex(cmd.id),3,false,true,false,true,false,true)
				end
			end},
		}		
		g.tfilter.mouseClick={
			{1,function(mx,my,self)
				spSetActiveCommand(-1)
				updateFilter(true)
				updateHax = true
			end},
		}
		
		-- number of active filters
		local activeTabs = 0
		local curTab = 0
		for i=1,#hasOptions do
			if hasOptions[i] == true then
				activeTabs = activeTabs + 1 
			end
			
			if i == filter then
				curTab = activeTabs
			end
		end

		g.tspacing.active = nil --activate
		g.tfacing.active = nil
		g.tqueue.active = nil
		g.tfilter.active = nil
		
		if (activeTabs > 1) then
			g.tfilter.texture = LUAUI_DIRNAME.."Images/buildmenu/filter"..filter..".png"
			g.tfilter.caption = "\n    "..curTab.." / "..activeTabs.."    "
		else
			g.tfilter.texture = LUAUI_DIRNAME.."Images/buildmenu/filter.png"
			g.tfilter.caption = "    "..filterLabel[filter].."    "
		end
		
		
		g.tfacing.texture = LUAUI_DIRNAME.."Images/buildmenu/facing"..spGetBuildFacing()..".png"
		g.tspacing.caption = "    "..spacingList[GetSpacingIndex()].."    "
		if (totalBuildQueueSize > 0) then
			g.tqueue.caption = "\n "..totalBuildQueueSize.." "
		else
			g.tqueue.active = false
		end
	else
		g.tspacing.active = false
		g.tfacing.active = false
		g.tqueue.active = false
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
		UpdateGrid(g,latestBuildCmds,TYPE_BUILD,latestUnfilteredBuildCmds)
	end				
end

function widget:Initialize()
	-- optional unit names
	for id, ud in pairs (UnitDefs) do
		local cp = ud.customParams
		if cp and cp.optional == "1" then
			optionalUnitNames[ud.name] = true
		end
	end
	
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
	iconOrderMenu = CreateGrid(Config.iconOrderMenu)
	
	buildMenu.page = 1
	orderMenu.page = 1
	iconOrderMenu.page = 1
	
	AutoResizeObjects() --fix for displacement on crash issue
	adjustGridYOffsets()
end

local function onNewCommands(filteredBuildCmds,buildCmds,otherCmds,iconOtherCmds)
	if (SelectedUnitsCount==0) then
		cleanupTaggedObjects(CLEANUP_TAG)
		buildMenu.page = 1
		orderMenu.page = 1
		iconOrderMenu.page = 1
	end
	
	UpdateGrid(buildMenu,filteredBuildCmds,TYPE_BUILD,buildCmds)
	UpdateGrid(orderMenu,otherCmds,TYPE_ORDER)	
	UpdateGrid(iconOrderMenu,iconOtherCmds,TYPE_ICONORDER)
	
	adjustGridYOffsets()
	latestBuildCmds = filteredBuildCmds
	latestUnfilteredBuildCmds = buildCmds
end

local function onWidgetUpdate() --function widget:Update()
	AutoResizeObjects()
	adjustGridYOffsets()
	SelectedUnitsCount = spGetSelectedUnitsCount()
end


--lots of hacks under this line ------------- overrides/disables default spring menu layout and gets current orders + filters out some commands
local hijackedLayout = false
function widget:Shutdown()
	if (hijackedLayout) then
		widgetHandler:ConfigLayoutHandler(true)
		Spring.ForceLayoutUpdate()
	end
end
local function GetCommands()
	local isHiddenCmd = {
		[76] = true, --load units clone
		[65] = true, --selfd
		[9] = true, --gatherwait
		[8] = true, --squadwait
		[7] = true, --deathwait
		[6] = true, --timewait
		[135] = true, --autorepairlevel
	}
	
	local buildCmds = {}
	local stateCmds = {}
	local otherCmds = {}
	local iconOtherCmds = {}
	local buildCmdsCount = 0
	local stateCmdsCount = 0
	local otherCmdsCount = 0
	local iconOtherCmdsCount = 0
	
	-- reset build filter category option flags
	for i,_ in ipairs(filterLabel) do
		hasOptions[i] = false
	end

	local uName = ""
	local ud = nil
	for index,cmd in pairs(spGetActiveCmdDescs()) do
		if (type(cmd) == "table") then
			--Spring.Echo("id="..cmd.id.." type="..cmd.type.." action="..cmd.action)
			if (
			(not isHiddenCmd[cmd.id]) and
			(cmd.action ~= nil) and
			-- (not cmd.disabled) and
			(cmd.type ~= 21) and
			(cmd.type ~= 18) and
			(cmd.type ~= 17)
			) then
				if ((cmd.type == 20) --build building
				or (ssub(cmd.action,1,10) == "buildunit_")) then
					uName = ssub(cmd.action,11)
					cmd.uName = uName
					ud = UnitDefNames[uName]
					-- omit build item options for disabled optional units
					if not (cmd.disabled and optionalUnitNames[uName]) then 
						cmd.cost = ud.metalCost
						cmd.isBuilder = ud.buildSpeed > 1
						
						-- update build filter category option flags
						checkEnableCategory(uName)
						
						buildCmdsCount = buildCmdsCount + 1
						buildCmds[buildCmdsCount] = cmd
					end
				elseif (iconCmdTex[cmd.id]) then
					cmd.position = iconCmdPosition[cmd.id]
					iconOtherCmdsCount = iconOtherCmdsCount + 1
					iconOtherCmds[iconOtherCmdsCount] = cmd
				elseif (cmd.type == 5) then
					stateCmdsCount = stateCmdsCount + 1
					stateCmds[stateCmdsCount] = cmd
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
		if checkFilter(cmd.uName) then
			filteredBuildCmdsCount = filteredBuildCmdsCount + 1
			filteredBuildCmds[filteredBuildCmdsCount] = cmd
		end
	end
	
	-- put state commands ahead on the list of "other" commands
	local tempCmds = {}
	for i=1,stateCmdsCount do
		tempCmds[i] = stateCmds[i]
	end
	for i=1,otherCmdsCount do
		tempCmds[i+stateCmdsCount] = otherCmds[i]
	end
	otherCmdsCount = otherCmdsCount + stateCmdsCount
	otherCmds = tempCmds
	
	-- sort command tables
	table.sort(filteredBuildCmds, function(a,b) 
		if a and b then
			if a.isBuilder ~= b.isBuilder then
				return a.isBuilder and (not b.isBuilder)
			elseif a.cost < b.cost then
				return true
			end
		end
		return false
	end)
	table.sort(iconOtherCmds, function(a,b) 
		if a and b then
			if a.position < b.position then
				return true
			end
		end
		return false
	end)
	
	return filteredBuildCmds,buildCmds,otherCmds,iconOtherCmds
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
			onNewCommands({},{},{},{}) --flush
			updateHax2 = false
		end
	end
	
	-- if issuing a build command, cycle build category until the current active command is included 
	local _,curCmdId,curCmdType,curCmdName = spGetActiveCommand()
	--Spring.Echo("curCmdId="..tostring(curCmdId).." curCmdType="..tostring(curCmdType).." curCmdName="..tostring(curCmdName))
	if curCmdId and curCmdId < 0 and curCmdName then
		local cmdIncluded = false
		for i=1,filteredBuildCmdsCount do
			--Spring.Echo("filteredBuildCmds[i]="..tostring(filteredBuildCmds[i]))
			if filteredBuildCmds[i].uName == curCmdName then
				cmdIncluded = true
				break
			end
		end
		if not cmdIncluded then
			updateFilter(true)
			updateHax = true
		end
	end
end

-- use filter key to cycle through filter options
function widget:KeyPress(key, modifier, isRepeat)
	if key == FILTER_KEY  then
		spSetActiveCommand(-1) 
		updateFilter(true)
		updateHax = true
	end
	if key == PAGE_KEY  then
		nextBuildOptionsPage()
		updateHax = true
	end
end
