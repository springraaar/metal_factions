function widget:GetInfo()
	return {
	name      = "Red Main Menu",
	desc      = "Main Menu. Requires Red UI Framework",
	author    = "raaar",
	date      = "2023",
	license   = "PD",
	layer     = 0,
	enabled   = true,
	handler   = true,
	}
end

local NeededFrameworkVersion = 8.1
local CanvasX,CanvasY = 1272,734  --resolution in which the widget was made (for 1:1 size)
local vsx, vsy = gl.GetViewSizes()
local maxFontSizeFactor = 1
if (vsy > 1080) then
	maxFontSizeFactor = vsy / 1080
end	
local scale = 1			--- gui scale

VFS.Include("lualibs/constants.lua")
VFS.Include("lualibs/custom_cmd.lua")
VFS.Include("lualibs/util.lua")


local sGetMyTeamID = Spring.GetMyTeamID
local sGetTeamResources = Spring.GetTeamResources
local sSetShareLevel = Spring.SetShareLevel
local spGetTeamRulesParam = Spring.GetTeamRulesParam
local spSendLuaRulesMsg = Spring.SendLuaRulesMsg
local spGetWind = Spring.GetWind
local spGetConfigInt = Spring.GetConfigInt
local sformat = string.format

local min = math.min
local max = math.max
local floor = math.floor
local avgWindMod = 1 

local menuButton = {}
local menuPanel = {}

local CHECK_GFXPROFILE = 0
local CHECK_ICONDIST = 1

local Config = {
	menuButton = {
		px = CanvasX-50-6,py = 6,
		sx = 50,sy = 20, --background size
		
		fontsize = 10,
		maxFontsize = 18 * maxFontSizeFactor,
		margin = 6,
		
		padding = 8, -- for border effect
		
		cbackground = UI_BTN_BG,
		cborder = UI_BTN_BORDER,
		clabel = UI_BTN_TEXT,
		
		name = "MENUBUTTON",
		
		tooltip = {
			background ="\255\255\255\255Click to open the in-game menu.\255\100\255\100 Hotkey \"Shift-ESC\"",
		},
	},
	menu = {
		px = CanvasX -162-6,py = 6,
		sx = 162,sy = 214, --background size
		
		fontsize = 10,
		maxFontsize = 18 * maxFontSizeFactor,
		margin = 6,
		padding = 0,
		
		cbackground = UI_BG_NOTEXT,
		cborder = UI_BORDER,
		clabel = UI_TEXT,
		
		name = "MENU",
		
		tooltip = {
			background ="\255\255\255\255In-Game Menu...",
		},
	},
	baseButton = {
		sx = 150,sy = 20, --background size
		fontsize = 10,
		maxFontsize = 18 * maxFontSizeFactor,
		margin = 6,
		padding = 8, -- for border effect
		cbackground = UI_BTN_BG,
		cborder = UI_BTN_BORDER,
		clabel = UI_BTN_TEXT,
	},
	resignButton = {
		px = 0,py = 0,
		name = "resignButton",
		tooltip = {
			background ="\255\255\255\255Surrender and change to spectator mode.",
		},
	},
	quitButton = {
		px = 0,py = 0,
		name = "quitButton",
		tooltip = {
			background ="\255\255\255\255Quit game.",
		},
	},
	shareButton = {
		px = 0,py = 0,
		name = "shareButton",
		tooltip = {
			background ="\255\255\255\255Open the unit/resource sharing panel.",
		},
	},
	gfxLowButton = {
		px = 0,py = 0,
		name = "gfxLowButton",
		selectedValue = GFX_LOW,
		checkType = CHECK_GFXPROFILE,
		tooltip = {
			background ="\255\255\255\255Change to a low-detail/high performance graphics settings profile.",
		},
	},	
	gfxMedButton = {
		px = 0,py = 0,
		name = "gfxMedButton",
		selectedValue = GFX_MEDIUM,
		checkType = CHECK_GFXPROFILE,
		tooltip = {
			background ="\255\255\255\255Change to a medium-detail graphics settings profile.",
		},
	},	
	gfxHighButton = {
		px = 0,py = 0,
		name = "gfxHighButton",
		selectedValue = GFX_HIGH,
		checkType = CHECK_GFXPROFILE,
		tooltip = {
			background ="\255\255\255\255Change to a high-detail graphics settings profile.",
		},
	},
	sliderButton = {
		px = 0,py = 0,
		name = "sliderButton",
		margin = 1,
		padding = 2,
		selectedValue = 0,
		checkType = CHECK_ICONDIST,
		texture = LUAUI_DIRNAME.."images/sliderButton.png",
		selectedTexture = LUAUI_DIRNAME.."images/sliderButtonSelected.png",
		textureColor = {1,1,1,1},
		tooltip = {
			background ="",
		}
	},		
	backButton = {
		px = 0,py = 0,
		name = "backButton",
		tooltip = {
			background ="\255\255\255\255Close menu panel.",
		},
	},
	optionalUnitsButton = {
		px = 0,py = 0,
		name = "optionalUnitsButton",
		tooltip = {
			background ="\255\255\255\255Open the optional unit selection panel.",
		},
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


local function AutoResizeObjects()
	if (LastAutoResizeX==nil) then
		LastAutoResizeX = CanvasX
		LastAutoResizeY = CanvasY
	end
	local lx,ly = LastAutoResizeX,LastAutoResizeY
	local vsx,vsy = Screen.vsx,Screen.vsy
	if ((lx ~= vsx) or (ly ~= vsy)) then
		local objects = GetWidgetObjects(widget)
		--local scale = (vsy/ly + vsx/lx) * 0.5 
		local scale = vsx/lx
		local skippedobjects = {}
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
			if (o.px) then
				if (adjust > 0) then
					o._moveduetoresize = true
					o.px = o.px - adjust
					for j=1,#o.movableSlaves do
						local s = o.movableSlaves[j]
						if s and s.px then
							s.px = s.px - adjust/scale
						end
					end
				elseif ((adjust < 0) and o._moveduetoresize) then
					o._moveduetoresize = nil
					o.px = o.px - adjust
					for j=1,#o.movableSlaves do
						local s = o.movableSlaves[j]
						if s and s.px then
							s.px = s.px - adjust/scale
						end
					end
				end
			else
				Spring.Echo(o.name.." has no px")
			end
		end
		LastAutoResizeX,LastAutoResizeY = vsx,vsy
	end
end

local function createMenu(r)
	local background = {"rectangle",
		px=r.px,py=r.py,
		sx=r.sx,sy=r.sy,
		color=r.cbackground,
		border=r.cborder,
		movable=r.dragbutton,
		obeyScreenEdge = true,
		
		padding=r.padding,
		
		--overrideCursor = true,
		overrideClick = {1},
	}
	New(background)
	
	local offsetY = 0
	local offsetX = 0
	
	-- back
	local bt = Copy(Config.backButton)
	bt = mergeTable(bt,Config.baseButton)
	bt.px = r.px + r.margin + r.padding + offsetX
	bt.py = r.py + r.margin + r.padding + offsetY
	local backButton = createButton(bt,"Back",function(mx,my,self)
		hideMenu()
	end)
	offsetY = offsetY + 30

	-- share
	bt = Copy(Config.shareButton)
	bt = mergeTable(bt,Config.baseButton)
	bt.px = r.px + r.margin + offsetX
	bt.py = r.py + r.margin + offsetY
	local shareButton = createButton(bt,"Unit/Resource Sharing",function(mx,my,self)
		Spring.SendCommands("sharedialog")
		hideMenu()
	end)
	offsetY = offsetY + 30

	-- gfx settings
	local text = {"text",
		px=background.px+r.margin,py=background.py+r.margin+offsetY+6,fontsize=r.fontsize,maxFontsize=20 * maxFontSizeFactor,
		caption="GFX Profile:",
		options="n", --disable colorcodes
	}
	local lb = New(text)
	lb.color = r.clabel
	bt = Copy(Config.gfxLowButton)
	bt = mergeTable(bt,Config.baseButton)
	bt.sx = 20
	bt.px = r.px + r.margin + r.padding + offsetX + 70
	bt.py = r.py + r.margin + r.padding + offsetY
	local gfxLowButton = createButton(bt,"L",function(mx,my,self)
		enableWidget("GFX Settings : Low")
	end)
	bt = Copy(Config.gfxMedButton)
	bt = mergeTable(bt,Config.baseButton)
	bt.sx = 20
	bt.px = r.px + r.margin + r.padding + offsetX + 95
	bt.py = r.py + r.margin + r.padding + offsetY
	local gfxMedButton = createButton(bt,"M",function(mx,my,self)
		enableWidget("GFX Settings : Medium")
	end)
	bt = Copy(Config.gfxHighButton)
	bt = mergeTable(bt,Config.baseButton)
	bt.sx = 20
	bt.px = r.px + r.margin + r.padding + offsetX + 120
	bt.py = r.py + r.margin + r.padding + offsetY
	local gfxHighButton = createButton(bt,"H",function(mx,my,self)
		enableWidget("GFX Settings : High")
	end)
	offsetY = offsetY + 30
	
	-- icon distance slider
	local text = {"text",
		px=background.px+r.margin,py=background.py+r.margin+offsetY+6,fontsize=r.fontsize,maxFontsize=20 * maxFontSizeFactor,
		caption="Icon Distance:",
		options="n", --disable colorcodes
	}
	local lb2 = New(text)
	lb2.color = r.clabel

	-- add "slider" buttons
	local sliderButtons = {}
	for i=0,5 do
		bt = Copy(Config.sliderButton)
		bt = mergeTable(bt,Config.baseButton)
		local value = 0
		if i == 0 then
			bt.tooltip.background = "\255\255\255\255ALWAYS display units as icons."
		elseif i == 5 then
			value = 999
			bt.tooltip.background = "\255\255\255\255NEVER display units as icons."
		else
			value = 100 + 25*i
			bt.tooltip.background = "\255\255\255\255Change distance modifier from where units become drawn as icons to "..value.."."
		end
		bt.selectedValue = value
		
		bt.sx = 10
		bt.px = r.px + r.margin + r.padding + offsetX + 70 + (bt.sx+2)*i
		bt.py = r.py + r.margin + r.padding + offsetY
		sliderButtons[i+1] = createButton(bt,"",function(mx,my,self)
			Spring.SendCommands("disticon "..self.selectedValue)
		end)
	end	

	offsetY = offsetY + 30
	
	-- optional units
	bt = Copy(Config.optionalUnitsButton)
	bt = mergeTable(bt,Config.baseButton)
	bt.px = r.px + r.margin + r.padding + offsetX
	bt.py = r.py + r.margin + r.padding + offsetY
	local optionalUnitsButton = createButton(bt,"Optional Units",function(mx,my,self)
		showOptionalUnitsPanel()
	end)
	offsetY = offsetY + 30
	
	-- resign
	bt = Copy(Config.resignButton)
	bt = mergeTable(bt,Config.baseButton)
	bt.px = r.px + r.margin + r.padding + offsetX
	bt.py = r.py + r.margin + r.padding + offsetY
	local resignButton = createButton(bt,"Resign",function(mx,my,self)
		Spring.SendCommands("spectator")
		hideMenu()
	end)
	offsetY = offsetY + 30
	
	-- quit
	bt = Copy(Config.quitButton)
	bt = mergeTable(bt,Config.baseButton)
	bt.px = r.px + r.margin + r.padding + offsetX
	bt.py = r.py + r.margin + r.padding + offsetY
	local quitButton = createButton(bt,"Quit",function(mx,my,self)
		Spring.SendCommands("quitforce")
	end)
	
	
	background.movableSlaves = {
		resignButton,quitButton,shareButton,lb,lb2,gfxLowButton,gfxMedButton,gfxHighButton,backButton,optionalUnitsButton
	}
	for i=1,6 do
		table.insert(background.movableSlaves,sliderButtons[i])
	end
	
	local returnTable = {
		["background"] = background,
		["label"] = lb,
		["label2"] = lb2,
		["resignButton"] = resignButton,
		["quitButton"] = quitButton,
		["shareButton"] = shareButton,
		["gfxLowButton"] = gfxLowButton,
		["gfxMedButton"] = gfxMedButton,
		["gfxHighButton"] = gfxHighButton,
		["backButton"] = backButton,
		["optionalUnitsButton"] = optionalUnitsButton,
		["sliderButtons"] = sliderButtons,
		margin = r.margin,
		enable = function()
			background.active = nil
			lb.active = nil
			lb2.active = nil
			resignButton.enable()
			quitButton.enable()
			shareButton.enable()
			gfxLowButton.enable()
			gfxMedButton.enable()
			gfxHighButton.enable()
			for i=1,6 do
				sliderButtons[i].enable()
			end
			backButton.enable()
			optionalUnitsButton.enable()
		end,
		disable = function()
			background.active = false
			lb.active = false
			lb2.active = false
			resignButton.disable()
			quitButton.disable()
			shareButton.disable()
			gfxLowButton.disable()
			gfxMedButton.disable()
			gfxHighButton.disable()
			for i=1,6 do
				sliderButtons[i].disable()
			end
			backButton.disable()
			optionalUnitsButton.disable()
		end		
	}
	
	return returnTable
end

function createButton(r,label,lClickHandler,rClickHandler)
	local background = {"rectangle",
		px=r.px,py=r.py,
		sx=r.sx,sy=r.sy,
		color=r.cbackground,
		border=r.cborder,
		movable=r.dragbutton,
		obeyScreenEdge = true,
		
		isSelected = false,
		padding=r.padding,
		--overrideCursor = true,
		overrideClick = {1}
	}
	
	if r.texture then
		background.texture = r.texture
		background.textureColor = r.textureColor
	end
	if r.selectedValue then
		background.selectedValue = r.selectedValue
		background.checkType = r.checkType
	end
	New(background)

	local text = {"text",
		px=background.px+r.margin,py=background.py+r.margin,fontsize=r.fontsize,maxFontsize=20 * maxFontSizeFactor,
		caption=r.name,
		options="n", --disable colorcodes
	}
	local lb = New(text)
	lb.caption = label
	lb.color = r.clabel

	background.movableSlaves = {
		lb
	}

	-- mouse over handling
	background.mouseOver = function(mx,my,self) 
		SetTooltip(r.tooltip.background)
		if self.isSelected == true then
			self.color = UI_BTN_BG_SELECTED_OVER
			self.border = UI_BTN_BORDER_SELECTED_OVER			
		else
			self.color = UI_BTN_BG_OVER
			self.border = UI_BTN_BORDER_OVER
		end
	end	
	background.mouseNotOver = function(mx,my,self)
		if self.isSelected == true then
			self.color = UI_BTN_BG_SELECTED
			self.border = UI_BTN_BORDER_SELECTED
		else
			self.color = UI_BTN_BG
			self.border = UI_BTN_BORDER
		end 
	end	

	background.onUpdate = function(self)
		if r.checkType then
			if r.checkType == CHECK_GFXPROFILE then 
				background.isSelected = WG.gfxProfile == r.selectedValue
			elseif r.checkType == CHECK_ICONDIST then
				local dist = spGetConfigInt("UnitIconDist")
				background.isSelected = math.abs(dist - r.selectedValue) < 25
			end
		end

		if self.isSelected == true then
			if r.selectedTexture then
				background.texture = r.selectedTexture
			end
		else
			if r.texture then
				background.texture = r.texture
			end
		end 
	end
	
	
	-- click handling
	background.mouseClick = {}
	if lClickHandler then
		table.insert(background.mouseClick,{1,lClickHandler})
	end
	if rClickHandler then
		table.insert(background.mouseClick,{3,rClickHandler})
	end
	
	return {
		["background"] = background,
		["label"] = lb,
		margin = r.margin,
		enable = function()
			background.active = nil
			lb.active = nil
		end,
		disable = function()
			background.active = false
			lb.active = false
		end
	}
end


function showMenu()
	menuPanel.enable()
	menuButton.disable()
	WG.menuShown = true
end

function hideMenu()
	menuPanel.disable()
	menuButton.enable()
	WG.menuShown = false
end
WG.showMenu = showMenu
WG.hideMenu = hideMenu

function showOptionalUnitsPanel()
	hideMenu()
	if (WG.showOptionalUnitsPanel) then
		WG.showOptionalUnitsPanel()
	end
end


------------------------------------ callins

function widget:Initialize()
	PassedStartupCheck = RedUIchecks()
	if (not PassedStartupCheck) then return end
	
	menuButton = createButton(Config.menuButton," MENU",function(mx,my,self)
		showMenu()
	end)
	menuPanel = createMenu(Config.menu)
	hideMenu()
	
	AutoResizeObjects()
end

function widget:Shutdown()
end

local gameFrame = 0
local lastFrame = -1
function widget:GameFrame(n)
	gameFrame = n
end

function widget:Update()
	AutoResizeObjects()
	if (gameFrame ~= lastFrame) then
		lastFrame = gameFrame
	end
end
