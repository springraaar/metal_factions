function widget:GetInfo()
	return {
	version   = "1",
	name      = "Red Minimap",
	desc      = "Requires Red UI Framework",
	author    = "raaar, based on widget by Regret",
	date      = "2022",
	license   = "GNU GPL, v2 or later",
	layer     = -11,
	enabled   = true, --enabled by default
	handler   = true, --can use widgetHandler:x()
	}
end
local vsx, vsy = gl.GetViewSizes()

local sformat = string.format
local spSendCommands = Spring.SendCommands
local spGetMiniMapGeometry = Spring.GetMiniMapGeometry
local spGetCameraState = Spring.GetCameraState

local NeededFrameworkVersion = 8

local mW = 0
local mH = 0

local lastPos = {}
local uiOpacitySec = 0
local scheduleMinimapGeometry = false

local Config = {
	minimap = {
		px = 0,py = 0, --default start position
		sx = mW, sy = mH, --background size
		fadetime = 0.25, --fade effect time, in seconds
		fadedistance = 100, --distance from cursor at which console shows up when empty
		
		cborder = {0,0,0,1},
		cbackground = {0.5,0.5,0.5,1},
		cbordersize = 3,
		
		--dragbutton = {1}, --left mouse button
		tooltip = {
			--  not used
		},
	},
}

local function updateMinimapSize()
	local vsx,vsy = gl.GetViewSizes()
	local mapWHRatio = Game.mapSizeX / Game.mapSizeZ
	--local viewWHRatio = vsx / vsy
	local maxW = vsx/4.4
	local maxH = vsy/3.4
	local mW = maxW 
	local mH = maxH
	
	if (mapWHRatio > 1) then
		mW = maxW
		mH = mW / mapWHRatio
		
		-- width maxed, but resize to fit height if necessary
		if mH > maxH then
			mW = mW * maxH/mH
			mH = maxH
		end
	else
		mH = maxH
		mW = mH * mapWHRatio

		-- height maxed, but resize to fit width if necessary
		if mW > maxW then
			mH = mH * maxW/mW
			mW = maxW
		end
	end 
	mW = math.floor(mW)
	mH = math.floor(mH)
	
	Config.minimap.sx = mW
	Config.minimap.sy = mH
end

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



local function createMinimap(r)
	local minimap = {"rectangle",
		px=r.px,py=r.py,
		sx=r.sx-r.cbordersize,sy=r.sy-r.cbordersize,
		obeyscreenedge = true,
	}
	local minimapbg = {"rectangle",
		px=r.px-r.cbordersize,py=r.py-r.cbordersize,
		sx=r.sx+r.cbordersize,sy=r.sy+r.cbordersize,
		border=r.cborder,
		bordersize=r.cbordersize,
		color=r.cbackground,
		obeyscreenedge = true,
	}
	
	New(minimap)
	New(minimapbg)
	
	minimap.mousenotover = function(mx,my,self)
		self._mouseover = nil
	end
	
	minimap.mouseover = function(mx,my,self)
		self._mouseover = true
	end
	
	return {
		minimap = minimap,
		minimapbg = minimapbg
	}
end


------------------------------------------ Callins


function widget:Initialize()
	oldMinimapGeometry = spGetMiniMapGeometry()
	
	PassedStartupCheck = RedUIchecks()
	if (not PassedStartupCheck) then return end
	
	updateMinimapSize()  --- updates mW and mH
	rMinimap = createMinimap(Config.minimap)
	gl.SlaveMiniMap(true)
end


function widget:ViewResize(viewSizeX, viewSizeY)
	scheduleMinimapGeometry = true
end

function widget:Update(dt)
	local _,_,_,_,minimized,maximized = spGetMiniMapGeometry()
	if (maximized) then
		--hack to reset state minimap
		gl.SlaveMiniMap(false) 
		gl.SlaveMiniMap(true)
		----
	end
	
	if (minimized) then
		rMinimap.minimap.active = false
		rMinimap.minimapbg.active = false
		--hack to reset state minimap
		gl.SlaveMiniMap(false) 
		gl.SlaveMiniMap(true)
		----
	else
		rMinimap.minimap.active = nil
		rMinimap.minimapbg.active = nil
	end
	
	local st = spGetCameraState()
	if (st.name == "ov") then --overview camera
		rMinimap.minimap.active = false
		rMinimap.minimapbg.active = false
	else
		rMinimap.minimap.active = nil
		rMinimap.minimapbg.active = nil
	end

	if ((lastPos.px ~= rMinimap.minimap.px) or (lastPos.py ~= rMinimap.minimap.py) or (lastPos.sx ~= rMinimap.minimap.sx) or (lastPos.sy ~= rMinimap.minimap.sy) or scheduleMinimapGeometry) then
		spSendCommands(sformat("minimap geometry %i %i %i %i",
		rMinimap.minimap.px,
		rMinimap.minimap.py,
		rMinimap.minimap.sx,
		rMinimap.minimap.sy))
		scheduleMinimapGeometry = false
	end
	lastPos.px = rMinimap.minimap.px
	lastPos.py = rMinimap.minimap.py
	lastPos.sx = rMinimap.minimap.sx
	lastPos.sy = rMinimap.minimap.sy
end

function widget:DrawScreen()
	if (rMinimap.minimap.active ~= nil) then
		return
	end
	
    gl.DrawMiniMap()
end

function widget:Shutdown()
	gl.SlaveMiniMap(false)
	Spring.SendCommands("minimap geometry "..oldMinimapGeometry)
end
