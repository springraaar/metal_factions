function widget:GetInfo()
	return {
	version   = "8.1",
	name      = "Red_UI_Framework",
	desc      = "Red UI Framework",
	author    = "Regret, modified by raaar",
	date      = "July 30, 2009", --modified by raaar on may 2015
	license   = "GNU GPL, v2 or later",
	layer     = -99999, --lowest go first
	enabled   = true, --loaded by default
	handler   = true, --access to handler
	}
end

-- modified by raaar, may 2015 :
--   . changed many variable names from lowercase to camelCase
--   . support object max font size
--   . fix text centering on buttons

local TN = "Red"
local DrawingTN = "Red_Drawing" --WG name for drawing function list
local version = 8.1

local clock = os.clock
local glGetTextWidth = gl.GetTextWidth
local sgsub = string.gsub
local function getLineCount(text)
	_,linecount = sgsub(text,"\n","\n")
	return linecount+1
end

local Main = {} --boss table with a manabar
local WidgetList = {} --list of widgets using the framework

local LastProcessedWidget = "" --for debugging

local vsx,vsy = widgetHandler:GetViewSizes()
if (vsx == 1) then --hax for windowed mode
	vsx,vsy = Spring.GetWindowGeometry()
end
function widget:ViewResize(viewSizeX, viewSizeY)
	vsx,vsy = widgetHandler:GetViewSizes()
	Main.vsx,Main.vsy = vsx,vsy
	Main.Screen.vsx,Main.Screen.vsy = vsx,vsy
end


--helper functions
local type = type

local function getTextWidth(o)
	return glGetTextWidth(o.caption)*o.fontsize
end

local function getTextHeight(o)
	return getLineCount(o.caption)*o.fontsize
end

local function isInRect(x,y,px,py,sx,sy)
	if (not py) then
		py = px.py
		sx = px.sx
		sy = px.sy
		px = px.px
	end
	if ((x >= px) and (x <= px+sx)
	and (y >= py) and (y <= py+sy)) then
		return true
	end
	return false
end

local function copyTable(t,copyEveryThing)
	local r = {}
	for i,v in pairs(t) do
		if (copyEveryThing and (type(v)=="table")) then
			r[i] = copyTable(v) --can (probably) cause loops
		else
			r[i] = v
		end
	end
	return r
end
-------------------------


--Objects
local F = {
[1] = function(o) --rectangle
	if (o.draw == false) then
		return
	end
	
	local color = o.color
	local border = o.border	--color
	local textureColor = o.textureColor
	local captionColor = o.captionColor
	
	local texture = o.texture
	local px,py,sx,sy = o.px,o.py,o.sx,o.sy	
	
	local alphaMult = o.alphaMult
	if (alphaMult~=nil) then
		if (color) then
			color = copyTable(color)
			color[4] = o.color[4]*alphaMult
		end
		if (border) then
			border = copyTable(border)
			border[4] = o.border[4]*alphaMult
		end
		if (captionColor) then
			captionColor = copyTable(captionColor)
			captionColor[4] = o.captionColor[4]*alphaMult
		end
		if (textureColor) then
			textureColor = copyTable(textureColor)
			textureColor[4] = o.textureColor[4]*alphaMult
		else
			textureColor = {1,1,1,alphaMult}
		end
	end
	
	if (color) then
		Rect(px,py,sx,sy,color)
	end
	
	if (texture) then
		TexRect(px,py,sx,sy,texture,textureColor)
	end
	
	if (o.caption) then
		local px2,py2 = px,py
		local text = o.caption
		local width = glGetTextWidth(text)
		local linecount = getLineCount(text)
		local fontsize = sx/width
		if fontsize > o.maxFontsize then
			fontsize = o.maxFontsize
		end
		local height = linecount*fontsize

		if (height > sy) then
			fontsize = sy/linecount
			if fontsize > o.maxFontsize then
				fontsize = o.maxFontsize
			end
			px2 = px2 + (sx - width*fontsize) /2 --center
		else
			px2 = px2 + (sx - width*fontsize) /2 --center
			py2 = py2 + (sy - height) /2 --center
		end
		

		Text(px2,py2,fontsize,text,o.options,captionColor)
		o.autofontsize = fontsize
	end
	
	if (border) then --todo: border styles
		Border(px,py,sx,sy,o.borderwidth,border)
	end
end,

[2] = function(o) --text
	if (o.draw == false) then
		return
	end
	
	local color = o.color
	local captionColor = o.captionColor
	
	local alphaMult = o.alphaMult
	if (alphaMult~=nil) then
		if (color) then
			color = copyTable(color)
			color[4] = o.color[4]*alphaMult
		elseif (captionColor) then
			captionColor = copyTable(captionColor)
			captionColor[4] = o.captionColor[4]*alphaMult
		end
	end
	
	local px,py = o.px,o.py	
	local fontsize = o.fontsize
	local maxFontsize = o.maxFontsize
	if (not fontsize) then	-- set default
		fontsize = 5
	end
	if (not maxFontsize) then	-- set default
		maxFontsize = 50
	end
	if fontsize > maxFontsize then
		fontsize = maxFontsize
	end
	
	Text(px,py,fontsize,o.caption,o.options,color or captionColor)
end,

[3] = function(o) --area
	--plain dummy
end,
}

local otypes = {
	["rectangle"] = 1,
	["text"] = 2,
	["area"] = 3,
}
-------------------------

local function processEffects(o,CurClock)
	local e = o.effects
	
	if (o.active ~= false) then
		if (e.fadeInAtActivation) then
			if (o.justActivated) then
				if (o.alphaMult == nil) then
					o.alphaMult = 0
				end
				o.fadeInAtActivation_start = CurClock --effect start
			end
			if (o.alphaMult~=nil) then
				local start = o.fadeInAtActivation_start
				o.alphaMult = (CurClock-start)/e.fadeInAtActivation
				if (o.alphaMult > 1) then
					o.alphaMult = nil
					o.fadeInAtActivation_start = nil
				else
					--useless here [x] maby
					o.tempActive = true --force object to be active
				end
			end
		end
	else
		o.fadeInAtActivation_start = nil
	end
	
	if (o.active == false) then
		if (e.fadeout_at_deactivation) then
			if (o.justDeactivated) then
				if (o.alphaMult == nil) then
					o.alphaMult = 0
				end
				o.fadeOutAtDeactivationStart = CurClock --effect start
			end
			if (o.alphaMult~=nil) then
				local start = o.fadeOutAtDeactivationStart
				if (start~=nil) then
					o.alphaMult = 1-(CurClock-start)/e.fadeout_at_deactivation
					if (o.alphaMult <= 0) then
						o.alphaMult = nil
						o.fadeOutAtDeactivationStart = nil
					else
						o.tempActive = true --force object to be active
					end
				end
			end
		end
	else
		o.fadeOutAtDeactivationStart = nil
	end
end

--Mouse handling
local Mouse = {{},{},{}}
local sGetMouseState = Spring.GetMouseState

local dropClick = false
local dropWheel = false

local useDefaultMouseCursor = false
function widget:IsAbove(x,y)
	if (useDefaultMouseCursor) then 
		return true
	end
	return false
end

local WheelState = nil
function widget:MouseWheel(up,value) --up = true/false , value = -1/1
	WheelState = up
	return dropWheel
end

function widget:MousePress(mx,my,mb)
	if (type(dropClick)=="table") then
		for i=1,#dropClick do
			if (dropClick[i] == mb) then
				dropClick = true
				break
			end
		end
		if (dropClick ~= true) then
			dropClick = false
		end
	end
	
	return dropClick
end

local LastMouseState = {sGetMouseState()}
local function handleMouse()
	--reset status
	dropClick = false
	dropWheel = false
	useDefaultMouseCursor = false
	----
	
	local CurMouseState = {sGetMouseState()} --{mx,my,m1,m2,m3}
	CurMouseState[2] = vsy-CurMouseState[2] --make 0,0 top left
	
	Mouse.hoverUnused = true --used in mouseOver
	Mouse.x = CurMouseState[1]
	Mouse.y = CurMouseState[2]
	
	if (WheelState ~= nil) then
		Mouse.wheel = WheelState
	else
		Mouse.wheel = nil
	end
	WheelState = nil
	
	for i=3,5 do
		local n=i-2
		Mouse[n][1] = nil
		Mouse[n][2] = nil
		Mouse[n][3] = nil
		
		if (CurMouseState[i] and LastMouseState[i]) then 
			Mouse[n][1] = true --isheld
		elseif (CurMouseState[i] and (not LastMouseState[i])) then
			Mouse[n][2] = true --waspressed
			Mouse[n][4] = {Mouse.x,Mouse.y} --last press
		elseif ((not CurMouseState[i]) and LastMouseState[i]) then
			Mouse[n][3] = true --wasreleased
			Mouse[n][5] = {Mouse.x,Mouse.y} --last release
		end
	end
	LastMouseState = CurMouseState
end

local function mouseEvent(t,e,o)
	if (t) then
		for i=1,#t do
			local m = Mouse[t[i][1]]
			if (m[e]) then
				if (not o.checkedForMouse) then
					if (isInRect(Mouse.x,Mouse.y,o)) then
						o.checkedForMouse = true 
					else
						return true
					end
				end
				
				if ((e==1) and (not isInRect(m[4][1],m[4][2],o))) then --last click was not in same area
					--nuthin'
				else
					m[e] = nil --so only topmost area will get the event
					t[i][2](Mouse.x,Mouse.y,o)
				end
			end
		end
	end
end

local function processMouseEvents(o)
	o.checkedForMouse = nil
	
	if (o[2] == 2) then --text
		o.sx = o.getWidth()
		o.sy = o.getHeight()
	end
	
	if (o.movable) then
		for i=1,#o.movable do
			if (not o.wasClicked) then
				if (Mouse[o.movable[i]][2]) then
					if (isInRect(Mouse.x,Mouse.y,o)) then
						o.checkedForMouse = true
						
						o.wasClicked = {o.px - Mouse.x,o.py - Mouse.y}
						Mouse[o.movable[i]][2] = nil --so only topmost area will get the event
					end
				end
			else
				local newpx = Mouse.x + o.wasClicked[1]
				local newpy = Mouse.y + o.wasClicked[2]
				
				if (o.obeyScreenEdge) then
					if (newpx<0) then newpx = 0 end
					if (newpy<0) then newpy = 0 end
					if (newpx>(vsx-o.sx)) then newpx = vsx-o.sx end
					if (newpy>(vsy-o.sy)) then newpy = vsy-o.sy end
				elseif (o.movableArea) then
					if (newpx<o.movableArea.px) then newpx = o.movableArea.px end
					if (newpy<o.movableArea.py) then newpy = o.movableArea.py end
					if (newpx>((o.movableArea.px+o.movableArea.sx)-o.sx)) then newpx = (o.movableArea.px+o.movableArea.sx)-o.sx end
					if (newpy>((o.movableArea.py+o.movableArea.sy)-o.sy)) then newpy = (o.movableArea.py+o.movableArea.sy)-o.sy end
				elseif (o.minpx) then
					if (newpx<o.minpx) then newpx = o.minpx end
					if (newpy<o.minpy) then newpy = o.minpy end
					if (newpx>(o.maxpx-o.sx)) then newpx = o.maxpx-o.sx end
					if (newpy>(o.maxpy-o.sy)) then newpy = o.maxpy-o.sy end
				end
				
				local changex = newpx-o.px
				local changey = newpy-o.py
				if (o.movableSlaves) then
					for j=1,#o.movableSlaves do
						local s = o.movableSlaves[j]
						local snewpx = s.px - (o.px - newpx)
						local snewpy = s.py - (o.py - newpy)
						
						if (s.obeyScreenEdge) then
							if (snewpx<0) then snewpx = 0 end
							if (snewpy<0) then snewpy = 0 end
							if (snewpx>(vsx-s.sx)) then snewpx = vsx-s.sx end
							if (snewpy>(vsy-s.sy)) then snewpy = vsy-s.sy end
						elseif (s.movableArea and (s.movableArea~=o)) then --disregard self to prevent a bug
							if (snewpx<s.movableArea.px) then snewpx = s.movableArea.px end
							if (snewpy<s.movableArea.py) then snewpy = s.movableArea.py end
							if (snewpx>((s.movableArea.px+s.movableArea.sx)-s.sx)) then snewpx = (s.movableArea.px+s.movableArea.sx)-s.sx end
							if (snewpy>((s.movableArea.py+s.movableArea.sy)-s.sy)) then snewpy = (s.movableArea.py+s.movableArea.sy)-s.sy end
						elseif (s.minpx) then
							if (snewpx<s.minpx) then snewpx = s.minpx end
							if (snewpy<s.minpy) then snewpy = s.minpy end
							if (snewpx>(s.maxpx-s.sx)) then snewpx = s.maxpx-s.sx end
							if (snewpy>(s.maxpy-s.sy)) then snewpy = s.maxpy-s.sy end
						end
						
						local schangex = snewpx-s.px
						local schangey = snewpy-s.py
						
						if (math.abs(changex)>math.abs(schangex)) then changex = schangex end
						if (math.abs(changey)>math.abs(schangey)) then changey = schangey end
					end
					for j=1,#o.movableSlaves do --move slaves
						local s = o.movableSlaves[j]
						s.px = s.px+changex
						s.py = s.py+changey
					end
				end
				o.px = o.px+changex --move self
				o.py = o.py+changey
				if (Mouse[o.movable[i]][3]) then
					o.wasClicked = nil
					Mouse[o.movable[i]][3] = nil --so only topmost area will get the event
				end
			end
		end
	end
	
	if (o.mouseNotOver) then
		if (isInRect(Mouse.x,Mouse.y,o)) then
			o.checkedForMouse = true
		else
			o.mouseNotOver(Mouse.x,Mouse.y,o)
			return
		end
	end
	
	if (o.overrideCursor) then
		if (not o.checkedForMouse) then
			if (isInRect(Mouse.x,Mouse.y,o)) then o.checkedForMouse = true else return end
		end
		useDefaultMouseCursor = true
	end
	if (o.overrideClick) then
		if (not o.checkedForMouse) then
			if (isInRect(Mouse.x,Mouse.y,o)) then o.checkedForMouse = true else return end
		end
		dropClick = o.overrideClick
	end
	if (o.overrideWheel) then
		if (not o.checkedForMouse) then
			if (isInRect(Mouse.x,Mouse.y,o)) then o.checkedForMouse = true else return end
		end
		dropWheel = true
	end
	
	if (o.mouseOver and Mouse.hoverUnused) then
		if (not o.checkedForMouse) then
			if (isInRect(Mouse.x,Mouse.y,o)) then
				o.checkedForMouse = true
			else
				return
			end
		end
		Mouse.hoverUnused = false
		o.mouseOver(Mouse.x,Mouse.y,o)
	end
	
	if mouseEvent(o.mouseClick,2,o)
	or mouseEvent(o.mouseHeld,1,o)
	or mouseEvent(o.mouseRelease,3,o) then return end
	
	if (o.mouseWheel) then
		if (not o.checkedForMouse) then
			if (isInRect(Mouse.x,Mouse.y,o)) then
				o.checkedForMouse = true
			else
				return
			end
		end
		if (Mouse.wheel ~= nil) then
			o.mouseWheel(Mouse.wheel,Mouse.x,Mouse.y,o)
		end
	end
end
-------------------------

local ssub = string.sub
function widget:Initialize()
	WG[TN] = {{}}
	Main = WG[TN]
	Main.Version = version
	Main.vsx,Main.vsy = vsx,vsy
	Main.Screen = {vsx=vsx,vsy=vsy}
	Main.Copytable = copyTable
	Main.Mouse = Mouse
	
	Main.GetWidgetObjects = function(w)
		for i=1,#WidgetList do
			if (WidgetList[i]:GetInfo().name == w:GetInfo().name) then
				return copyTable(Main[1][i])
			end
		end
	end
	
	Main.SetTooltip = function(text)
		WG[TN].tooltip = text
	end
	Main.GetSetTooltip = function()
		return WG[TN].tooltip
	end
	
	Main.New = function(w) --function to create a function dawg
		for i=1,#WidgetList do --prevents duplicate widget tables
			if (WidgetList[i]:GetInfo().name == w:GetInfo().name) then
				--Spring.Echo(widget:GetInfo().name..">> don't reload the widget \""..w:GetInfo().name.."\" so fast :<")
				table.remove(WidgetList,i)
				table.remove(Main[1],i)
				break
			end
		end
	
		local n = #Main[1]+1
		WidgetList[n] = w --remember widget
		Main[1][n] = {}
		local t = Main[1][n]
		return function(o)
			local duplicate = false
			for i=1,#t do
				if (t[i] == o) then
					duplicate = true --object already exists, create a copy
					break
				end
			end
			
			local r = {}
			
			local m = #t+1
			if (duplicate) then
				--local new = copyTable(o,true)
				local new = copyTable(o)
				t[m] = new
				r = new
			else
				o[2] = otypes[o[1]] --translate object type
				t[m] = o
				r = o
			end
			
			r.delete = function()
				r.scheduledForDeletion = true
			end
			
			if (r.caption) then
				r.getWidth = function()
					return getTextWidth(r)
				end
				
				r.getHeight = function()
					return getTextHeight(r)
				end
			end
			
			return r
		end
	end
end

function widget:Shutdown()
	WG[TN] = nil
	if (LastProcessedWidget ~= "") then
		Spring.Echo(widget:GetInfo().name..">> last processed widget was \""..LastProcessedWidget.."\"") --for debugging
	end
end

local hookedToDrawing = false
local fc = 0 --framecount
function widget:Update()
	Main.tooltip = nil
	handleMouse()
	
	--flush deactivated widgets
	fc=fc+1
	if (fc > 200) then
		fc = 0
		local temp = {}
		for i=1,#WidgetList do
			local name = WidgetList[i]:GetInfo().name
			local order = widgetHandler.orderList[name]
		    local enabled = order and (order > 0)
			
			if (enabled) then
				temp[#temp+1] = WidgetList[i]
			else
				table.remove(Main[1],i)
			end
		end
		WidgetList = temp
	end
	
	if (not hookedToDrawing) then --so drawing widget can be loaded after this widget
		if (WG[DrawingTN]) then
			local X = WG[DrawingTN]
			if (X.version ~= version) then
				Spring.Echo(widget:GetInfo().name..">> Invalid drawing widget version.")
				widgetHandler:ToggleWidget(widget:GetInfo().name)
				return
			end
			Color = X.Color
			Rect = X.Rect
			TexRect = X.TexRect
			Border = X.Border
			Text = X.Text
			hookedToDrawing = true
		end
	else --process widgets
		local wl = Main[1]
		for j=#wl,1,-1 do --iterate backwards
			if (j==0) then break end
			local CurClock = clock()
			
			--for debugging
			WG[DrawingTN].LastWidget = "<failed to get widget name>"
			local w = WidgetList[j]
			if (w) then
				local wInfo = WidgetList[j]:GetInfo()
				if (wInfo) then
					LastProcessedWidget = wInfo.name
					WG[DrawingTN].LastWidget = LastProcessedWidget
				end
			end
			--
			
			local delLst = {}
			local objLst = wl[j]
			
			for i=1,#objLst do
				local o = objLst[i]
				o.tempActive = nil
				if (o.scheduledForDeletion) then
					delLst[#delLst+1] = i
				else
					if (o.active ~= false) then
						o.notFirstProcessing = true
						if (o.lastActiveState == false) then
							o.justActivated = true
						else
							o.justActivated = nil
						end
					else
						if ((o.lastActiveState ~= false) and o.notFirstProcessing) then
							o.justDeactivated = true
						else
							o.justDeactivated = nil
						end
					end
					o.lastActiveState = o.active
					
					if (o.effects) then
						processEffects(o,CurClock)
					end
					if ((o.active ~= false) or o.tempActive) then
						F[o[2]](o) --object draw function
					end
				end
				
				--process mouseevents backwards, so topmost drawn objects get to mouseevents first
				local ro = objLst[#objLst-i+1]
				if (not ro.scheduledForDeletion) then
					if (ro.active ~= false) then
						if (ro.onUpdate) then
							ro.onUpdate(ro)
						end
						processMouseEvents(ro)
					end
				end
			end
			
			for i=1,#delLst do
				table.remove(objLst,delLst[i])
			end
		end
	end
end

function widget:WorldTooltip(ttType,data1,data2,data3)
	return Main.tooltip
end

