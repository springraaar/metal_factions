function widget:GetInfo()
	return {
	name      = "Red Faction Picker",
	desc      = "Faction Picker. Requires Red UI Framework",
	author    = "raaar",
	date      = "2024",
	license   = "PD",
	layer     = 0,
	enabled   = true,
	handler   = true,
	}
end

local vsx, vsy = gl.GetViewSizes()
local maxFontSizeFactor = 1
if (vsy > 1080) then
	maxFontSizeFactor = vsy / 1080
end	

VFS.Include("lualibs/constants.lua")
VFS.Include("lualibs/custom_cmd.lua")
VFS.Include("lualibs/util.lua")
VFS.Include("luaui/headers/redui_aux.lua")

local spGetMyTeamID = Spring.GetMyTeamID
local spGetGameFrame = Spring.GetGameFrame

local selectedFaction = "random"
local scrollIdx = 1
local mousePressed = false
local mouseOverMainPanel = false
local mouseOverScrollBar = false

local min = math.min
local max = math.max
local floor = math.floor

local mainPanel = {}

local CHECK_UNIT = 0
local CHECK_FACTION = 1


local buttonSize = 64
local margin = 6


local Config = {
	mainPanel = {
		px = CanvasX/2 - (5*buttonSize + 6*margin)*0.5 ,py = CanvasY - (buttonSize + 14 + 8*margin),
		sx = 5*buttonSize + 6*margin,sy = buttonSize + 14 + 4*margin, --background size
		
		fontsize = 10,
		maxFontsize = 18 * maxFontSizeFactor,
		margin = margin,
		padding = 0,
		cbackground = UI_BG_TEXT,
		cborder = UI_BORDER,
		clabel = UI_TEXT,
		
		name = "mainPanel",
		
		tooltip = {
			background ="\255\255\255\255Faction Selection Panel.",
		},
	},
	baseButton = {
		sx = buttonSize,sy = buttonSize, --background size
		fontsize = 10,
		maxFontsize = 18 * maxFontSizeFactor,
		margin = margin,
		padding = 8,
		cbackground = UI_BTN_BG,
		cborder = UI_BTN_BORDER,
		clabel = UI_TEXT,
	},
	randomButton = {
		px = 0,py = 0,
		name = "randomButton",
		checkType = CHECK_FACTION,
		texture = "luaui/images/factions/random_big.png", 
		selectedValue = "random",
		tooltip = {
			background ="\255\255\255\255Select a random faction.",
		},
	},

	avenButton = {
		px = 0,py = 0,
		name = "avenButton",
		checkType = CHECK_FACTION,
		texture = "luaui/images/factions/aven_big.png", 
		selectedValue = "aven",
		tooltip = {
			background ="\255\255\255\255Select the AVEN faction.\n \n\255\200\200\1Speed and Diligence.\n \n\255\200\200\200More variety of affordable, fast and aggressive units \nbut they are usually lacking in firepower or resilience.",
		},
	},
	gearButton = {
		px = 0,py = 0,
		name = "gearButton",
		checkType = CHECK_FACTION,
		texture = "luaui/images/factions/gear_big.png", 
		selectedValue = "gear",
		tooltip = {
			background ="\255\255\255\255Select the GEAR faction.\n \n\255\200\200\1Progress. By any means necessary.\n \n\255\200\200\200More variety of powerful but clumsy units, some having\nvery low range, slow speed or dealing indiscriminate damage.",
		},
	},
	clawButton = {
		px = 0,py = 0,
		name = "clawButton",
		checkType = CHECK_FACTION,
		texture = "luaui/images/factions/claw_big.png", 
		selectedValue = "claw",
		tooltip = {
			background ="\255\255\255\255Select the CLAW faction.\n \n\255\200\200\1Power to Us.\n \n\255\200\200\200More variety of units with relatively high firepower and range,\nusually at the expense of speed, resilience or a lower price tag.",
		},
	},
	sphereButton = {
		px = 0,py = 0,
		name = "sphereButton",
		checkType = CHECK_FACTION,
		texture = "luaui/images/factions/sphere_big.png", 
		selectedValue = "sphere",
		tooltip = {
			background ="\255\255\255\255Select the SPHERE faction.\n \n\255\200\200\1Endure and Prevail.\n \n\255\200\200\200More variety of resilient units, although many are somewhat slow\nand not as cost-effective at damaging enemies.",
		},
	},
}

local function createMainPanel(r)
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
	
	local text = {"text",
		px=background.px+r.margin,py=background.py+r.margin,fontsize=r.fontsize,maxFontsize=20 * maxFontSizeFactor,
		caption="",
		options="n", --disable colorcodes
	}
	local lb = New(text)
	lb.caption = "Select your faction..."
	lb.color = r.clabel
	lb.fontsize = r.fontsize * 1.3
	
	background.mouseOver = function(mx,my,self) 
		mouseOverMainPanel = true
	end	
	background.mouseNotOver = function(mx,my,self)
		mouseOverMainPanel = false
	end
	
	offsetY = offsetY + 14 + margin
	
	-- close
	--[[
	local bt = Copy(Config.baseButton)
	bt.tooltip = {background = "\255\255\255\255Close panel."}
	bt.sx = 20
	bt.sy = 20
	bt.px = r.px + r.sx - r.margin - r.padding - bt.sx
	bt.py = r.py + r.margin
	local closeButton = createButton(bt,"X",function(mx,my,self)
		hideFactionSelectorPanel()
	end)
	]]--
	offsetY = offsetY + margin

	-- random
	local bt = Copy(Config.randomButton)
	bt = mergeTable(bt,Config.baseButton)
	bt.px = r.px + r.margin + offsetX
	bt.py = r.py + r.margin + offsetY
	local randomButton = createButton(bt,"",function(mx,my,self)
		selectFaction("random")
	end)
	offsetX = offsetX + bt.sx + margin
	-- aven
	bt = Copy(Config.avenButton)
	bt = mergeTable(bt,Config.baseButton)
	bt.px = r.px + r.margin + offsetX
	bt.py = r.py + r.margin + offsetY
	local avenButton = createButton(bt,"",function(mx,my,self)
		selectFaction("aven")
	end)
	offsetX = offsetX + bt.sx + margin
	-- gear
	bt = Copy(Config.gearButton)
	bt = mergeTable(bt,Config.baseButton)
	bt.px = r.px + r.margin + offsetX
	bt.py = r.py + r.margin + offsetY
	local gearButton = createButton(bt,"",function(mx,my,self)
		selectFaction("gear")
	end)
	offsetX = offsetX + bt.sx + margin
	-- claw
	bt = Copy(Config.clawButton)
	bt = mergeTable(bt,Config.baseButton)
	bt.px = r.px + r.margin + offsetX
	bt.py = r.py + r.margin + offsetY
	local clawButton = createButton(bt,"",function(mx,my,self)
		selectFaction("claw")
	end)
	offsetX = offsetX + bt.sx + margin
	-- sphere
	bt = Copy(Config.sphereButton)
	bt = mergeTable(bt,Config.baseButton)
	bt.px = r.px + r.margin + offsetX
	bt.py = r.py + r.margin + offsetY
	local sphereButton = createButton(bt,"",function(mx,my,self)
		selectFaction("sphere")
	end)
	
	offsetX = 0

	background.movableSlaves = {
		randomButton,avenButton,gearButton,clawButton,sphereButton,lb
	}

	local returnTable = {
		["background"] = background,
		["label"] = lb,
		--["closeButton"] = closeButton,
		["randomButton"] = randomButton,
		["avenButton"] = avenButton,
		["gearButton"] = gearButton,
		["clawButton"] = clawButton,
		["sphereButton"] = sphereButton,
		enable = function()
			background.active = nil
			lb.active = nil
			--closeButton.enable()
			randomButton.enable()
			avenButton.enable()
			gearButton.enable()
			clawButton.enable()
			sphereButton.enable()
		end,
		disable = function()
			background.active = false
			lb.active = false
			--closeButton.disable()
			randomButton.disable()
			avenButton.disable()
			gearButton.disable()
			clawButton.disable()
			sphereButton.disable()
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
		overrideCursor = true,
		overrideClick = {1}
	}
	
	if r.texture then
		background.texture = r.texture
		background.textureColor = r.textureColor
	end
	if r.selectedValue ~= nil then
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
		setTooltip(r.tooltip.background)
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
			if r.checkType == CHECK_FACTION then 
				background.isSelected = selectedFaction == self.selectedValue
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

function showFactionSelectionPanel()
	mainPanel.enable()
	WG.factionSelectionPanelShown = true
end

function hideFactionSelectionPanel()
	mainPanel.disable()
	WG.factionSelectionPanelShown = false
end
WG.showFactionSelectionPanel = showFactionSelectionPanel


-- select a faction
function selectFaction(faction)
	selectedFaction = faction
	Spring.SendLuaRulesMsg("PICKFACTION|"..faction)
	
end

------------------------------------ callins

function widget:Initialize()
	if Spring.GetSpectatingState() or Spring.IsReplay() then
		widgetHandler:RemoveWidget(self)
		return
	end
	
	PassedStartupCheck = RedUIchecks()
	if (not PassedStartupCheck) then return end

	_,_,_,_, faction, _,_ = Spring.GetTeamInfo(spGetMyTeamID())
	local validFactions = {
		random = true,
		aven = true,
		gear = true,
		claw = true,
		sphere = true
	}
	if validFactions[faction] then
		selectedFaction = faction
	else
		Spring.Echo("invalid side : "..tostring(faction))
	end
	
	
	mainPanel = createMainPanel(Config.mainPanel)
	AutoResizeObjects()
end

function widget:Shutdown()
end

function widget:GameStart()
	hideFactionSelectionPanel()
	--widgetHandler:RemoveWidget(self)
end

function widget:Update()
	if spGetGameFrame() > 0 then
		hideFactionSelectionPanel()
	else
		AutoResizeObjects()
	end
end


