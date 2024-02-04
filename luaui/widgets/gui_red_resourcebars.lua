function widget:GetInfo()
	return {
	name      = "Red Resource Bars",
	desc      = "Resource bars and related information. Requires Red UI Framework",
	author    = "Regret, modified by raaar",
	date      = "29 may 2015",
	license   = "GNU GPL, v2 or later",
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

local sGetMyTeamID = Spring.GetMyTeamID
local sGetTeamResources = Spring.GetTeamResources
local sSetShareLevel = Spring.SetShareLevel
local spGetTeamRulesParam = Spring.GetTeamRulesParam
local spSendLuaRulesMsg = Spring.SendLuaRulesMsg
local spGetWind = Spring.GetWind
local sformat = string.format

local min = math.min
local max = math.max
local floor = math.floor

local avgWindMod = 1 

local Config = {
	metal = {
		px = 370,py = 0, --default start position
		sx = 235,sy = 35, --background size
		
		barsy = 6, --width of the actual bar
		fontsize = 12,
		maxFontsize = 24 * maxFontSizeFactor,
		margin = 5, --distance from background border
		
		padding = 4, -- for border effect
		color2 = {1,1,1,0.022}, -- for border effect
		
		expensefadetime = 0.25, --fade effect time, in seconds
		
		cbackground = {0,0,0,0.6}, --color {r,g,b,alpha}
		cborder = {0,0,0,0.88},
		cbarbackground = {0,0,0,1},
		cbar = {1,1,1,1},
		cindicator = {1,0,0,0.8},
		hpindicator = {0.3,0.3,1,0.8},
		
		cincome = {0,1,0,1},
		cpull = {1,0,0,1},
		cexpense = {1,0,0,1},
		ccurrent = {1,1,1,1},
		cstorage = {1,1,1,1},
		clabel = {0.7,0.7,0.7,1},
		name = "METAL",
		
		dragbutton = {2}, --middle mouse button
		tooltip = {
			background ="\255\255\255\1Left-Click\255\255\255\255 on the bar to set team share, \255\255\255\1Right-Click\255\255\255\255 to set high priority reserve.",
			income = "Your metal income per second.",
			pull = "Your metal expense per second.",
			expense = "Your metal expense, same as pull if not shown.",
			storage = "Your maximum metal storage.",
			current = "Your current metal storage.",
		},
	},
	
	energy = {
		px = 636,py = 0,
		sx = 235,sy = 35, --background size
		
		barsy = 6, --width of the actual bar
		fontsize = 12,
		maxFontsize = 24 * maxFontSizeFactor,
		margin = 5,
		
		padding = 4, -- for border effect
		color2 = {1,1,1,0.022}, -- for border effect
		
		expensefadetime = 0.25,
		
		cbackground = {0,0,0,0.6},
		cborder = {0,0,0,0.88},
		cbarbackground = {0,0,0,1},
		cbar = {1,1,0,1},
		cindicator = {1,0,0,0.8},
		hpindicator = {0.3,0.3,1,0.8},		
		
		cincome = {0,1,0,1},
		cpull = {1,0,0,1},
		cexpense = {1,0,0,1},
		ccurrent = {1,1,1,1},
		cstorage = {1,1,1,1},
		clabel = {1,1,0,1},
		name = "ENERGY",
		
		dragbutton = {2}, --middle mouse button
		tooltip = {
			background ="\255\255\255\1Left-Click\255\255\255\255 on the bar to set team share, \255\255\255\1Right-Click\255\255\255\255 to set high priority reserve.",
			income = "Your energy income per second.",
			pull = "Your energy expense per second.",
			expense = "Your energy expense, same as pull if not shown.",
			storage = "Your maximum energy storage.",
			current = "Your current energy storage.",
		},
	},
	
	wind = {
		px = 636+235+3,py = 0,
		sx = 103,sy = 16, --background size
		
		barsy = 6, --width of the actual bar
		fontsize = 9,
		maxFontsize = 18 * maxFontSizeFactor,
		margin = 4,
		
		padding = 4, -- for border effect
		color2 = {1,1,1,0.022}, -- for border effect
		
		
		cbackground = {0,0,0,0.6},
		cborder = {0,0,0,0.88},
		clabel = {0.9,0.9,1,1},
		
		name = "WIND",
		
		tooltip = {
			background ="\255\255\255\255Wind strength for energy generation purposes.",
		},
	},
	tidal = {
		px = 636+235+3,py = 19,
		sx = 63,sy = 16, --background size
		
		fontsize = 9,
		maxFontsize = 18 * maxFontSizeFactor,
		margin = 4,
		
		padding = 4, -- for border effect
		color2 = {1,1,1,0.022}, -- for border effect
		
		cbackground = {0,0,0,0.6},
		cborder = {0,0,0,0.88},
		clabel = {0.3,0.8,1,1},

		name = "TIDAL",
		
		tooltip = {
			background ="\255\255\255\255Tidal strength for energy generation purposes.",
		},
	},
}

local function setHPLevel(res,level)
	--Spring.Echo("Set high-priority threshold for "..res.." to "..level)
	local msg = ""
	if (res == "energy") then
		msg = UI_CMD_HP_THRESHOLD_ENERGY .."|"..level
	elseif (res == "metal") then
		msg = UI_CMD_HP_THRESHOLD_METAL .."|"..level
	end
	spSendLuaRulesMsg(msg)
end

function getScale(vsx,lx,vsy,ly)
	return (vsy/ly + vsx/lx) * 0.5 
end


local function short(n,f)
	if (f == nil) then
		f = 0
	end
	if (n > 9999999) then
		return sformat("%."..f.."fm",n/1000000)
	elseif (n > 9999) then
		return sformat("%."..f.."fk",n/1000)
	else
		return sformat("%."..f.."f",n)
	end
end

local function createbar(r)
	local background2 = {"rectangle",
		px=r.px+r.padding,py=r.py+r.padding,
		sx=r.sx-r.padding-r.padding,sy=r.sy-r.padding-r.padding,
		color=r.color2,
	}
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
		onUpdate=function(self)
			background2.px = self.px + self.padding
			background2.py = self.py + self.padding
			background2.sx = self.sx - self.padding - self.padding
			background2.sy = self.sy - self.padding - self.padding
		end,
	}
	New(background)
	New(background2)
	
	local number = {"text",
		px=0,py=background.py+r.margin,fontsize=r.fontsize,maxFontsize=20 * maxFontSizeFactor,
		caption=r.name.." +99999.9m",
		options="n", --disable colorcodes
	}
	
	local income = New(number)
	income.color = r.cincome
	
	local barbackground = {"rectangle",
		px=background.px+income.getWidth()-r.margin,py=income.py,
		sx=background.sx-income.getWidth(),sy=r.barsy,
		color=r.cbarbackground,
		--texture = barTexture,
		textureColor = {0.15,0.15,0.15,1},
	}

	local barborder = Copy(barbackground)
	barborder.color = nil
	barborder.border = r.cborder
	barborder.texture = nil
	barborder.textureColor = nil
	
	local bar = Copy(barbackground)
	bar.color = r.cbar
	--bar.texture = barTexture
	bar.textureColor = r.cbar
	
	local shareindicator = Copy(barbackground)
	shareindicator.color = r.cindicator
	shareindicator.py = shareindicator.py -2
	shareindicator.sx = barbackground.sy
	shareindicator.sy = shareindicator.sy +4
	shareindicator.border = r.cborder
	--shareindicator.texture = barTexture
	shareindicator.textureColor = r.cindicator
	
	
	local hpindicator = Copy(barbackground)
	hpindicator.color = r.hpindicator
	hpindicator.py = hpindicator.py -2
	hpindicator.sx = barbackground.sy
	hpindicator.sy = hpindicator.sy +4
	hpindicator.border = r.cborder
	--shareindicator.texture = barTexture
	hpindicator.textureColor = r.hpindicator

	New(barbackground)
	New(bar)
	New(barborder)
	New(shareindicator)
	New(hpindicator)
	
	bar.overrideCursor = true
	
	local pull = New(number)
	pull.color = r.cpull
	--pull.py = pull.py+pull.fontsize
	pull.py = barbackground.py+barbackground.sy+r.margin
	if ((barbackground.sy+r.margin)<r.fontsize) then
		pull.py = barbackground.py+r.fontsize
	end
	
	local expense = New(pull)
	expense.color = r.cexpense
	expense.px = barbackground.px
	
	local current = New(pull)
	current.color = r.ccurrent
	
	local storage = New(pull)
	storage.color = r.cstorage
	
	-- label
	local label = New(number)
	label.color = r.clabel
	label.py = (income.py + pull.py) / 2
	
	expense.effects = {
		fadein_at_activation = r.expensefadetime,
		fadeout_at_deactivation = r.expensefadetime,
	}
	
	background.movableSlaves = {
		barbackground,barborder,bar,shareindicator,hpindicator,
		income,pull,expense,current,storage,label
	}
	
	-- smaller fontsize for fontsize of income and pull
	income.fontsize = r.fontsize*0.93
	pull.fontsize = r.fontsize*0.93
	storage.fontsize = r.fontsize*0.88
	
	--tooltip
	background.mouseOver = function(mx,my,self) setTooltip(r.tooltip.background) end
	income.mouseOver = function(mx,my,self) setTooltip(r.tooltip.income) end
	pull.mouseOver = function(mx,my,self) setTooltip(r.tooltip.pull) end
	expense.mouseOver = function(mx,my,self) setTooltip(r.tooltip.expense) end
	storage.mouseOver = function(mx,my,self) setTooltip(r.tooltip.storage) end
	current.mouseOver = function(mx,my,self) setTooltip(r.tooltip.current) end
	

	return {
		["background"] = background,
		["background2"] = background2,
		["barbackground"] = barbackground,
		["bar"] = bar,
		["barborder"] = barborder,
		["shareindicator"] = shareindicator,
		["hpindicator"] = hpindicator,
		["income"] = income,
		["pull"] = pull,
		["expense"] = expense,
		["current"] = current,
		["storage"] = storage,
		["label"] = label,
		
		margin = r.margin
	}
end

local function createWind(r)
	local background2 = {"rectangle",
		px=r.px+r.padding,py=r.py+r.padding,
		sx=r.sx-r.padding-r.padding,sy=r.sy-r.padding-r.padding,
		color=r.color2,
	}
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
		onUpdate=function(self)
			background2.px = self.px + self.padding
			background2.py = self.py + self.padding
			background2.sx = self.sx - self.padding - self.padding
			background2.sy = self.sy - self.padding - self.padding
		end,
	}
	New(background)
	New(background2)
	
	local text = {"text",
		px=background.px+r.margin,py=background.py+r.margin,fontsize=r.fontsize,maxFontsize=20 * maxFontSizeFactor,
		caption=r.name,
		options="n", --disable colorcodes
	}
	
	local label = New(text)
	label.caption = r.name
	label.color = r.clabel
	
	local baseValue = New(text)
	baseValue.px = baseValue.px + 63
	
	baseValue.caption = "("..formatNbr(Game.windMin*WIND_INCOME_MULTIPLIER*EXCESS_WIND_REDUCTION_MULT,0).."-"..formatNbr(Game.windMax*WIND_INCOME_MULTIPLIER*EXCESS_WIND_REDUCTION_MULT,0)..")"
	local avgWind = (Game.windMax + Game.windMin) * 0.5
	avgWindMod = min(1,max(avgWind-5,0)/9)
	
	baseValue.color = {1-avgWindMod*0.3,avgWindMod,avgWindMod*0.4,1}
	baseValue.fontsize = r.fontsize*0.93
	
	local currentValue = New(text)
	currentValue.px = currentValue.px + 35
	currentValue.caption = ""
	
	background.movableSlaves = {
		label,baseValue,currentValue
	}
	
	--baseValue.fontsize = r.fontsize*0.93
	--currentValue.fontsize = r.fontsize*0.93
	
	--tooltip
	background.mouseOver = function(mx,my,self) setTooltip(r.tooltip.background) end	

	return {
		["background"] = background,
		["background2"] = background2,
		["label"] = label,
		["baseValue"] = baseValue,
		["currentValue"] = currentValue,		
		margin = r.margin
	}
end

local function createTidal(r)
	local background2 = {"rectangle",
		px=r.px+r.padding,py=r.py+r.padding,
		sx=r.sx-r.padding-r.padding,sy=r.sy-r.padding-r.padding,
		color=r.color2,
	}
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
		onUpdate=function(self)
			background2.px = self.px + self.padding
			background2.py = self.py + self.padding
			background2.sx = self.sx - self.padding - self.padding
			background2.sy = self.sy - self.padding - self.padding
		end,
	}
	New(background)
	New(background2)
	
	local text = {"text",
		px=background.px+r.margin,py=background.py+r.margin,fontsize=r.fontsize,maxFontsize=20 * maxFontSizeFactor,
		caption=r.name,
		options="n", --disable colorcodes
	}
	
	local label = New(text)
	label.caption = r.name
	label.color = r.clabel
	
	local baseValue = New(text)
	baseValue.px = baseValue.px + 35
	baseValue.caption = formatNbr(Game.tidal,1)
	local mod = min(1,Game.tidal/20)  
	baseValue.color = {1-mod*0.3,mod,mod*0.4,1}
	
	background.movableSlaves = {
		label,baseValue
	}
	
	--baseValue.fontsize = r.fontsize*0.93
	
	--tooltip
	background.mouseOver = function(mx,my,self) setTooltip(r.tooltip.background) end
	

	return {
		["background"] = background,
		["background2"] = background2,
		["label"] = label,
		["baseValue"] = baseValue,
		margin = r.margin
	}
end

local function updatebar(b,res)
	local r = {sGetTeamResources(sGetMyTeamID(),res)} -- 1 = cur 2 = cap 3 = pull 4 = income 5 = expense 6 = share
	local hpThreshold = spGetTeamRulesParam(sGetMyTeamID(),"hp_threshold_"..res)
	if (not hpThreshold) then
		hpThreshold = 0.05
	end
	local barbackpx = b.barbackground.px
	local barbacksx = b.barbackground.sx
	
	b.bar.sx = r[1]/r[2]*barbacksx
	if (b.bar.sx > barbacksx) then --happens on gamestart and storage destruction
		b.bar.sx = barbacksx
	end
	
	b.income.caption = "+ "..short(r[4],(r[4] < 10 and 1 or 0))
	b.pull.caption = "- "..short(r[5],(r[5] < 10 and 1 or 0))  --- was r[3], but it considers weapon E drain twice for some reason
	b.current.caption = short(r[1])
	b.storage.caption = short(r[2])
	b.label.caption = string.upper(res)
	
	--align numbers
	b.income.px = barbackpx - b.income.getWidth() -b.margin*2.2 
	b.pull.px = barbackpx - b.pull.getWidth() -b.margin*2.2
	b.current.px = barbackpx + barbacksx/2 - b.current.getWidth()/2
	b.storage.px = barbackpx + barbacksx - b.storage.getWidth() 
	b.label.px = barbackpx - b.label.getWidth() -b.margin*4.4 - math.max(b.income.getWidth(),b.pull.getWidth())
	
	-- TODO check this
	-- disable expense to make bars less confusing 
	-- it also showed double the amounts it should, which was weird
	if (false and r[3]~=r[5]) then
		b.expense.active = nil --activate
		b.expense.caption = "  - "..short(r[5],(r[5] < 10 and 1 or 0))
	else
		b.expense.active = false
	end
	
	b.shareindicator.px = barbackpx+r[6]*barbacksx-b.shareindicator.sx/2
	b.hpindicator.px = barbackpx+hpThreshold*barbacksx-b.hpindicator.sx/2
end


local function updateWind(r)
	local _, _, _, windStrength, x, _, z = spGetWind()
	windStrength = (min(windStrength,WIND_STR_CAP))
	-- reduce wind strength to match the actual average it's supposed to have
	windStrength = windStrength * WIND_INCOME_MULTIPLIER * EXCESS_WIND_REDUCTION_MULT
	
	local maxWind = Game.windMax * WIND_INCOME_MULTIPLIER * EXCESS_WIND_REDUCTION_MULT
	local fraction = windStrength / maxWind
	local mod = min(1,(fraction-0.3)/0.4)*(1+avgWindMod)*0.5
	-- get color 
	r.currentValue.color = {1-mod*0.3,mod,mod*0.4,1}
	r.currentValue.caption = formatNbr(windStrength,1)
end


function widget:Initialize()
	PassedStartupCheck = RedUIchecks()
	if (not PassedStartupCheck) then return end
	
	metal = createbar(Config.metal)
	energy = createbar(Config.energy)
	wind = createWind(Config.wind)
	tidal = createTidal(Config.tidal)
	
	metal.barbackground.mouseHeld = {
		{1,function(mx,my,self)
			sSetShareLevel("metal",(mx-self.px)/self.sx)
			updatebar(metal,"metal")
		end},
		{3,function(mx,my,self)
			setHPLevel("metal",(mx-self.px)/self.sx)
			updatebar(metal,"metal")
		end},
	}
	energy.barbackground.mouseHeld = {
		{1,function(mx,my,self)
			sSetShareLevel("energy",(mx-self.px)/self.sx)
			updatebar(energy,"energy")
		end},
		{3,function(mx,my,self)
			setHPLevel("energy",(mx-self.px)/self.sx)
			updatebar(energy,"energy")
		end},
	}
	
	Spring.SendCommands("resbar 0")
	AutoResizeObjects()
end

function widget:Shutdown()
	Spring.SendCommands("resbar 1")
end

local gameFrame = 0
local lastFrame = -1
function widget:GameFrame(n)
	gameFrame = n
end

function widget:Update()
	AutoResizeObjects()
	if (gameFrame ~= lastFrame) then
		updatebar(energy,"energy")
		updatebar(metal,"metal")
		updateWind(wind)
		lastFrame = gameFrame
	end
end
