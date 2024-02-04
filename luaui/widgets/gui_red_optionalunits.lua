function widget:GetInfo()
	return {
	name      = "Red Optional Units Panel",
	desc      = "Optional Units Selection Panel. Requires Red UI Framework",
	author    = "raaar",
	date      = "2023",
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
local spGetTeamRulesParam = Spring.GetTeamRulesParam

local selectedFaction = "aven"
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

local builderReplacementLabels = {
	aven_l1builder = "AVEN L1 builders",
	aven_l2builder = "AVEN L2 builders",
	gear_l1builder = "GEAR L1 builders",
	gear_l2builder = "GEAR L2 builders",
	claw_l1builder = "CLAW L1 builders",
	claw_l2builder = "CLAW L2 builders",
	sphere_l1builder = "SPHERE L1 builders",
	sphere_l2builder = "SPHERE L2 builders"
}

local optionalUnitDefIds = {}
local buildersStrByDefId = {}
local optionalUnitNames = {}
local optionalUnitDefIdsByFaction = {
	aven = {},
	gear = {},
	claw = {},
	sphere = {}
}
local totalCountByFaction = {
	aven = 0,
	gear = 0,
	claw = 0,
	sphere = 0
}

local myOptionalUnitDefIds = {}
local myActiveOptionalUnitDefIds = {}
local myCountByFaction = {
	aven = 0,
	gear = 0,
	claw = 0,
	sphere = 0
}

local Config = {
	mainPanel = {
		px = CanvasX/4,py = 220,
		sx = CanvasX/2,sy = 380, --background size
		
		fontsize = 10,
		maxFontsize = 18 * maxFontSizeFactor,
		margin = 6,
		padding = 0,
		cbackground = UI_BG_TEXT,
		cborder = UI_BORDER,
		clabel = UI_TEXT,
		
		name = "mainPanel",
		
		tooltip = {
			background ="\255\255\255\255In-Game Menu...",
		},
	},
	baseButton = {
		sx = 100,sy = 20, --background size
		fontsize = 10,
		maxFontsize = 18 * maxFontSizeFactor,
		margin = 6,
		padding = 8,
		cbackground = UI_BTN_BG,
		cborder = UI_BTN_BORDER,
		clabel = UI_TEXT,
	},
	avenButton = {
		px = 0,py = 0,
		name = "avenButton",
		checkType = CHECK_FACTION,
		selectedValue = "aven",
		tooltip = {
			background ="\255\255\255\255Edit AVEN optional unit list.",
		},
	},
	gearButton = {
		px = 0,py = 0,
		name = "gearButton",
		checkType = CHECK_FACTION,
		selectedValue = "gear",
		tooltip = {
			background ="\255\255\255\255Edit GEAR optional unit list.",
		},
	},
	clawButton = {
		px = 0,py = 0,
		name = "clawButton",
		checkType = CHECK_FACTION,
		selectedValue = "claw",
		tooltip = {
			background ="\255\255\255\255Edit CLAW optional unit list.",
		},
	},
	sphereButton = {
		px = 0,py = 0,
		name = "sphereButton",
		checkType = CHECK_FACTION,
		selectedValue = "sphere",
		tooltip = {
			background ="\255\255\255\255Edit SPHERE optional unit list.",
		},
	},

	resetButton = {
		px = 0,py = 0,
		name = "resetButton",
		tooltip = {
			background ="\255\255\255\255Reset to defaults.",
		},
	},
	clearButton = {
		px = 0,py = 0,
		name = "clearButton",
		tooltip = {
			background ="\255\255\255\255Clear optional unit selection.",
		},
	},
	saveButton = {
		px = 0,py = 0,
		name = "saveButton",
		tooltip = {
			background ="\255\255\255\255Save optional unit selection.",
		},
	},
	scrollBar = {
		px = 0,py = 0,
		sx = 8, sy = 246,
		name = "scrollBar",
		tooltip = {
			background ="\255\255\255\255Click to scroll.",
		},
	},
	unitRow = {
		px = 0,py = 0,
		sx = CanvasX/2 -30,sy = 60, --background size
		
		fontsize = 10,
		maxFontsize = 18 * maxFontSizeFactor,
		margin = 5,
		padding = 0,
		
		cbackground = {0.3,0.3,0.3,0.2},
		cborder = UI_BORDER,
		clabel = UI_TEXT,
		checkType = CHECK_UNIT,
		name = "unitRow",
		
		tooltip = {
			background ="\255\255\255\255In-Game Menu...",
		},
	},
}

function getScale(vsx,lx,vsy,ly)
	return vsx/lx
end


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
	lb.caption = "OPTIONAL UNITS"
	lb.color = r.clabel
	lb.fontsize = r.fontsize * 1.3
	
	background.mouseOver = function(mx,my,self) 
		mouseOverMainPanel = true
	end	
	background.mouseNotOver = function(mx,my,self)
		mouseOverMainPanel = false
	end
	
	-- close
	local bt = Copy(Config.baseButton)
	bt.tooltip = {background = "\255\255\255\255Close panel."}
	bt.sx = 20
	bt.px = r.px + r.sx - r.margin - r.padding - bt.sx
	bt.py = r.py + r.margin
	local closeButton = createButton(bt,"X",function(mx,my,self)
		hideOptionalUnitsPanel()
	end)
	offsetY = offsetY + 30

	-- aven
	bt = Copy(Config.avenButton)
	bt = mergeTable(bt,Config.baseButton)
	bt.px = r.px + r.margin + offsetX
	bt.py = r.py + r.margin + offsetY
	local avenButton = createButton(bt,"AVEN    \255\150\150\150"..myCountByFaction["aven"].." / "..MAX_OPTIONAL_UNITS_BY_FACTION,function(mx,my,self)
		showUnits("aven")
	end)
	offsetX = offsetX + bt.sx + 6
	-- gear
	bt = Copy(Config.gearButton)
	bt = mergeTable(bt,Config.baseButton)
	bt.px = r.px + r.margin + offsetX
	bt.py = r.py + r.margin + offsetY
	local gearButton = createButton(bt,"GEAR    \255\150\150\150"..myCountByFaction["gear"].." / "..MAX_OPTIONAL_UNITS_BY_FACTION,function(mx,my,self)
		showUnits("gear")
	end)
	offsetX = offsetX + bt.sx + 6
	-- claw
	bt = Copy(Config.clawButton)
	bt = mergeTable(bt,Config.baseButton)
	bt.px = r.px + r.margin + offsetX
	bt.py = r.py + r.margin + offsetY
	local clawButton = createButton(bt,"CLAW    \255\150\150\150"..myCountByFaction["claw"].." / "..MAX_OPTIONAL_UNITS_BY_FACTION,function(mx,my,self)
		showUnits("claw")
	end)
	offsetX = offsetX + bt.sx + 6
	-- sphere
	bt = Copy(Config.sphereButton)
	bt = mergeTable(bt,Config.baseButton)
	bt.px = r.px + r.margin + offsetX
	bt.py = r.py + r.margin + offsetY
	local sphereButton = createButton(bt,"SPHERE    \255\150\150\150"..myCountByFaction["sphere"].." / "..MAX_OPTIONAL_UNITS_BY_FACTION,function(mx,my,self)
		showUnits("sphere")
	end)
	
	offsetX = 0
	offsetY = offsetY + 30
	
	-- scrollbar
	bt = Copy(Config.scrollBar)
	bt.px = r.px + r.margin + r.sx*0.9+2
	bt.py = r.py + r.margin + offsetY
	scrollBar = createScrollBar(bt)
	
	-- add unit rows
	local unitRows = {}
	for i=0,3 do
		bt = Copy(Config.unitRow)
		bt.sx = r.sx*0.9
		bt.px = r.px + r.margin + r.padding + offsetX
		bt.py = r.py + r.margin + r.padding + offsetY 
		unitRows[i+1] = createUnitRow(bt, function(mx,my,self)
			local newState = not myOptionalUnitDefIds[self.udId]
			if (not newState) or myCountByFaction[selectedFaction] < MAX_OPTIONAL_UNITS_BY_FACTION then
				setOptionalUnitStatus(self.udId,newState)
				updateMyCountByFaction()
			end
		end)
		offsetY = offsetY + bt.sy + 2
	end	
	
	offsetX = 0
	offsetY = offsetY + 16
	
	-- reset
	bt = Copy(Config.resetButton)
	bt = mergeTable(bt,Config.baseButton)
	bt.sx = 50 
	bt.px = r.px + r.margin + offsetX
	bt.py = r.py + r.margin + offsetY
	local resetButton = createButton(bt,"Reset",function(mx,my,self)
		resetOptionalUnitSelection()
		updateMyCountByFaction()
	end)
	offsetX = offsetX + bt.sx + 6
	-- clear
	bt = Copy(Config.clearButton)
	bt = mergeTable(bt,Config.baseButton)
	bt.sx = 50
	bt.px = r.px + r.margin + offsetX
	bt.py = r.py + r.margin + offsetY
	local clearButton = createButton(bt,"Clear",function(mx,my,self)
		clearOptionalUnitSelection()
		updateMyCountByFaction()
	end)
	offsetX = offsetX + bt.sx + 6
	-- save
	bt = Copy(Config.saveButton)
	bt = mergeTable(bt,Config.baseButton)
	bt.sx = 50
	bt.px = r.px + r.margin + offsetX
	bt.py = r.py + r.margin + offsetY
	local saveButton = createButton(bt,"Save",function(mx,my,self)
		saveOptionalUnitSelection()
		updateMyCountByFaction()
	end)
	offsetY = offsetY + 30
	
	local lb2 = New(text)
	lb2.py = background.py+r.margin+offsetY
	lb2.caption = "Select units for each faction, then press \"Save\". Choice is locked when the battle starts."
	lb2.color = r.clabel
	lb2.fontsize = r.fontsize * 0.9
	
	background.movableSlaves = {
		scrollBar,closeButton,avenButton,gearButton,clawButton,sphereButton,lb,lb2,resetButton,clearButton,saveButton
	}
	for i=1,4 do
		table.insert(background.movableSlaves,unitRows[i])
	end
	
	local returnTable = {
		["background"] = background,
		["label"] = lb,
		["label2"] = lb2,
		["closeButton"] = closeButton,
		["avenButton"] = avenButton,
		["gearButton"] = gearButton,
		["clawButton"] = clawButton,
		["sphereButton"] = sphereButton,
		["resetButton"] = resetButton,
		["clearButton"] = clearButton,
		["saveButton"] = saveButton,
		["scrollBar"] = scrollBar,
		["unitRows"] = unitRows,
		enable = function()
			background.active = nil
			lb.active = nil
			lb2.active = nil
			closeButton.enable()
			avenButton.enable()
			gearButton.enable()
			clawButton.enable()
			sphereButton.enable()
			resetButton.enable()
			clearButton.enable()
			saveButton.enable()
			scrollBar.enable()
			for i=1,4 do
				unitRows[i].enable()
			end
		end,
		disable = function()
			background.active = false
			lb.active = false
			lb2.active = false
			closeButton.disable()
			avenButton.disable()
			gearButton.disable()
			clawButton.disable()
			sphereButton.disable()
			resetButton.disable()
			clearButton.disable()
			saveButton.disable()
			scrollBar.disable()
			for i=1,4 do
				unitRows[i].disable()
			end
		end	
	}
	
	return returnTable
end

function createUnitRow(r,lClickHandler)
	local background = {"rectangle",
		px=r.px,py=r.py,
		sx=r.sx,sy=r.sy,
		color=r.cbackground,
		border=r.cborder,
		movable=r.dragbutton,
		obeyScreenEdge = true,
		
		padding=r.padding,
		overrideCursor = true,
		overrideClick = {1},
	}
	New(background)
	
	local offsetY = 0
	local offsetX = 0
	
	local unitPic = {"rectangle",
		px=r.px+6,py=r.py+6,
		sx=48,sy=48,
		color=r.cbackground,
		border=r.cborder,
		movable=r.dragbutton,
		obeyScreenEdge = true,
		padding=r.padding,
		overrideClick = {1},
		texture = "",
	}
	New(unitPic)
	offsetX = offsetX + unitPic.sx + 10


	-- mouse over handling	
	background.mouseOver = function(mx,my,self) 
		setTooltip(self.tooltip)
		if self.isSelected == true then
			background.border = UI_BTN_BORDER_SELECTED_OVER
			background.color = UI_BTN_BG_SELECTED_OVER
		else
			self.color = UI_BTN_BG_OVER
			self.border = UI_BTN_BORDER_OVER
		end
	end	
	background.mouseNotOver = function(mx,my,self)
		if self.isSelected == true then
			background.border = UI_BTN_BORDER_SELECTED
			background.color = UI_BTN_BG_SELECTED
		else
			background.color=UI_BTN_BG
			background.border=UI_BTN_BORDER
		end 
	end	
	background.onUpdate = function(self)
		if r.checkType then
			if r.checkType == CHECK_UNIT then 
				background.isSelected = myOptionalUnitDefIds[self.udId]
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


	local text = {"text",
		px=background.px+r.margin,py=background.py+r.margin,fontsize=r.fontsize,maxFontsize=20 * maxFontSizeFactor,
		caption="",
		options="n", --disable colorcodes
	}
	local nameLabel = New(text)
	nameLabel.caption = "name\n\255\150\150\150description"
	nameLabel.color = r.clabel
	nameLabel.px = nameLabel.px + offsetX 
	
	offsetX = offsetX + 200
	
	local buildersLabel = New(text)
	buildersLabel.caption = "\255\150\150\150Built By:\255\230\230\230 \nbuilder1\nbuilder2"
	buildersLabel.color = r.clabel
	buildersLabel.px = buildersLabel.px + offsetX
	buildersLabel.fontsize = buildersLabel.fontsize *0.9
	
	offsetX = offsetX + 200
	
	local activeLabel = New(text)
	activeLabel.caption = ""
	activeLabel.color = r.clabel
	activeLabel.px = activeLabel.px + offsetX
	activeLabel.fontsize = activeLabel.fontsize *0.9
	activeLabel.py = activeLabel.py + r.sy/2 - activeLabel.fontsize
	
		
	background.movableSlaves = {
		unitPic,nameLabel,buildersLabel,activeLabel
	}
	
	local returnTable = {
		["background"] = background,
		["unitPic"] = unitPic,
		["nameLabel"] = nameLabel,
		["buildersLabel"] = buildersLabel,
		["activeLabel"] = activeLabel,
		enable = function()
			background.active = nil
			unitPic.active = nil
			nameLabel.active = nil
			buildersLabel.active = nil
			activeLabel.active = nil
		end,
		disable = function()
			background.active = false
			unitPic.active = false
			nameLabel.active = false
			buildersLabel.active = false
			activeLabel.active = false
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


function createScrollBar(r)
	local background = {"rectangle",
		px=r.px,py=r.py,
		sx=r.sx,sy=r.sy,
		color=UI_SCROLLBAR_BOX_BG,
		border=UI_SCROLLBAR_BOX_BORDER,
		movable=r.dragbutton,
		obeyScreenEdge = true,
		
		isSelected = false,
		padding=r.padding,
		overrideCursor = true,
		overrideClick = {1}
	}
	
	local slider = {"rectangle",
		px=r.px+1.5,py=r.py,
		sx=r.sx*0.6,sy=r.sy,
		color=UI_SCROLLBAR_INNER_BG,
		border=UI_SCROLLBAR_INNER_BORDER,
		movable=r.dragbutton,
		obeyScreenEdge = true,
		
		isSelected = false,
		padding=r.padding,
		overrideCursor = true,
		overrideClick = {1}
	}
	New(background)
	New(slider)

	background.movableSlaves = {
		slider
	}

	-- mouse over handling	
	background.mouseOver = function(mx,my,self) 
		mouseOverScrollBar = true
	end	
	background.mouseNotOver = function(mx,my,self)
		mouseOverScrollBar = false
	end

	background.onUpdate = function(self)
		local slider = self.movableSlaves[1]
		local total = totalCountByFaction[selectedFaction]

		local viewFraction = 1
		local viewLines = 4
		if total > 0 and total > viewLines then
			viewFraction = viewLines / total
		end

		local maxBarHeight = self.sy-4
		local minBarHeight = self.sy/8
		local barHeight =  max(minBarHeight,viewFraction*maxBarHeight)
		local barOffset = 0
		local remainingHeight = maxBarHeight - barHeight
		--Spring.Echo("viewFraction="..viewFraction.." barH="..barHeight.." maxBarH="..maxBarHeight)	
		if (total > viewLines) then
			barOffset = min(max(0,remainingHeight * (scrollIdx-1) / (total - viewLines)),maxBarHeight-barHeight)
		end 
		
		-- adjust slider height
		slider.sy = barHeight

		-- adjust slider offset
		slider.py = self.py + 2 + barOffset
	end
	
	-- click handling
	background.mouseClick = {}
	table.insert(background.mouseClick,{1,function(mx,my,self)
		if (totalCountByFaction[selectedFaction] > 4) then
			local scrollBarFraction = (my - self.py)/self.sy
			--Spring.Echo("scrollBarFraction="..scrollBarFraction)
			scrollIdx = math.floor(1+(totalCountByFaction[selectedFaction]-3) * scrollBarFraction)
			updateOptionalUnitsView()
		end
	end})
	
	return {
		["background"] = background,
		["slider"] = slider,
		["label"] = lb,
		enable = function()
			background.active = nil
			slider.active = nil
		end,
		disable = function()
			background.active = false
			slider.active = false
		end
	}
end


function showOptionalUnitsPanel()
	--Spring.Echo(tableToString(mainPanel))
	mainPanel.enable()
	showUnits(selectedFaction)
	WG.optionalUnitsPanelShown = true
end

function hideOptionalUnitsPanel()
	mainPanel.disable()
	WG.optionalUnitsPanelShown = false
end
WG.showOptionalUnitsPanel = showOptionalUnitsPanel

-- try to load optional list from local file or use default
function loadOptionalUnitSelection()
	local optionalUnitsText = (VFS.FileExists(optionalUnitsFile) and VFS.LoadFile(optionalUnitsFile)) or defaultOptionalUnitsText
	myOptionalUnitDefIds, myCountByFaction = getOptionalUnitsFromText(spGetMyTeamID() ,optionalUnitsText)
end

-- write optional unit list to file
function saveOptionalUnitSelection()
	local outText = ""
	for udId,enabled in pairs(myOptionalUnitDefIds) do
		if enabled then
			outText = outText .. UnitDefs[udId].name.."\n"
		end
	end
	if outText == "" then
		resetOptionalUnitSelection()
		return
	end
	
	Spring.Echo("saving MF optional units file in "..optionalUnitsFile)
	if not VFS.FileExists(optionalUnitsFile) then
		Spring.CreateDir("luaui")
		Spring.CreateDir("luaui/configs")
		io.output(optionalUnitsFile)
		io.write(outText)
		io.close()
	else
		io.output(optionalUnitsFile)
		io.write(outText)
		io.close()
	end
end

-- reset optional unit list to file
function resetOptionalUnitSelection()
	Spring.Echo("resetting MF optional units to defaults")
	if VFS.FileExists(optionalUnitsFile) then
		os.remove(optionalUnitsFile)
	end
	
	-- reload defaults	
	loadOptionalUnitSelection()
end

-- clear optional unit selection for all factions
function clearOptionalUnitSelection()
	for udId,enabled in pairs(myOptionalUnitDefIds) do
		myOptionalUnitDefIds[udId] = false
	end

	myCountByFaction = {
		aven = 0,
		gear = 0,
		claw = 0,
		sphere = 0
	}
end

-- select/deselect optional unit
function setOptionalUnitStatus(udId,value)
	myOptionalUnitDefIds[udId] = value
end

-- update player's optional unit count by faction
function updateMyCountByFaction()
	myCountByFaction = {
		aven = 0,
		gear = 0,
		claw = 0,
		sphere = 0
	}
	local factions = {"aven","gear","claw","sphere"}
	for i=1,#factions do
		local faction = factions[i]
		
		for _,udId in pairs(optionalUnitDefIdsByFaction[faction]) do
			if myOptionalUnitDefIds[udId] then 
				myCountByFaction[faction] = myCountByFaction[faction] +1
			end 
		end
	
		mainPanel[faction.."Button"].label.caption = string.upper(faction).."    \255\150\150\150"..myCountByFaction[faction].." / "..MAX_OPTIONAL_UNITS_BY_FACTION
	end
end

-- update the optional unit list in view
function updateOptionalUnitsView()
	local unitList = optionalUnitDefIdsByFaction[selectedFaction]
	
	for idx,row in pairs (mainPanel.unitRows) do
		local udId = unitList[scrollIdx+idx-1]
		
		if udId then
			local ud = UnitDefs[udId]
			row.background.tooltip = "buildunit_"..ud.name.."Build:"
			row.background.udId = udId	-- background object is what actually handles clicks, onUpdate, etc.
			row.unitPic.texture = "#"..udId
			row.nameLabel.caption = ud.humanName.."\n\255\150\150\150"..ud.tooltip.."\n\n\255\200\200\200Metal: "..ud.metalCost.."    \255\250\250\0Energy: "..ud.energyCost
			row.buildersLabel.caption = buildersStrByDefId[udId]
			row.activeLabel.caption = myActiveOptionalUnitDefIds[udId] and "\255\250\250\0ACTIVE\255\255\255\255" or ""
			row.enable()
		else
			row.disable()
		end
	end
end

-- show unit list for the selected faction
function showUnits(faction)
	selectedFaction = faction
	scrollIdx = 1
	updateOptionalUnitsView()
end

-- get string with list of builders separated by \n
function getBuildersStr(builtBy)
	local str = "\255\150\150\150Built By:\255\230\230\230 \n"

	for s in builtBy:gmatch("[^,]+") do
		local repLabel = builderReplacementLabels[s]
		if repLabel then
			str = str..repLabel.."\n"
		else
			str = str..UnitDefNames[s].humanName.."\n"
		end
	end
	return str
end

------------------------------------ callins

function widget:Initialize()
	PassedStartupCheck = RedUIchecks()
	if (not PassedStartupCheck) then return end

	-- build list of optional units
	for id, ud in pairs (UnitDefs) do
		local cp = ud.customParams
		if cp and cp.optional == "1" then
			optionalUnitDefIds[ud.id] = true
			optionalUnitNames[ud.name] = true
			local faction = getFactionFromUName(ud.name)
			optionalUnitDefIdsByFaction[faction][ud.id] = ud.cost
			totalCountByFaction[faction] = totalCountByFaction[faction]+1 
			if cp.builtby then
				buildersStrByDefId[ud.id] = getBuildersStr(cp.builtby)
			end
		end
	end

	-- replace the per-faction udef id maps with lists sorted by cost
	local factions = {"aven","gear","claw","sphere"}
	for i=1,#factions do
		local faction = factions[i]
		local old = optionalUnitDefIdsByFaction[faction]
		local new = {}
		for udId,cost in spairs(old, function(t,a,b) return t[b] > t[a] end) do
			new[#new+1] = udId
		end

		optionalUnitDefIdsByFaction[faction] = new
		--Spring.Echo(faction.." : "..tableToString(optionalUnitDefIdsByFaction[faction] ).." totalCount="..totalCountByFaction[faction])
	end
		
	mainPanel = createMainPanel(Config.mainPanel)
	hideOptionalUnitsPanel()

	-- load selection for current player	
	loadOptionalUnitSelection()
	updateMyCountByFaction()
	
	AutoResizeObjects()
end

function widget:Shutdown()
end

function widget:GameStart()
	local optionalUnitsText = (VFS.FileExists(optionalUnitsFile) and VFS.LoadFile(optionalUnitsFile)) or defaultOptionalUnitsText
	myActiveOptionalUnitDefIds, _ = getOptionalUnitsFromText(spGetMyTeamID() ,optionalUnitsText)
end

function widget:MouseWheel(up, value)
	if not WG.optionalUnitsPanelShown then
		return false
	end	

	if mouseOverMainPanel and totalCountByFaction[selectedFaction] > 0  then
		if up then
			local steps = 1
			while (scrollIdx > 1 and steps > 0) do
				scrollIdx = scrollIdx - 1
				steps = steps - 1
			end
		else
			local steps = 1
			while (scrollIdx < (totalCountByFaction[selectedFaction]-3) and steps > 0) do
				scrollIdx = scrollIdx + 1
				steps = steps - 1
			end
		end
		updateOptionalUnitsView()
		return true
	end
	return false
end


function widget:Update()
	AutoResizeObjects()
end


