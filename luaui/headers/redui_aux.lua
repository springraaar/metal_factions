-- auxiliary functions common to red UI widgets

NeededFrameworkVersion = 8.1
CanvasX,CanvasY = 1272,734  --resolution in which the widget was made (for 1:1 size)
scale = 1

function IncludeRedUIFrameworkFunctions()
	New = WG.Red.New(widget)
	Copy = WG.Red.Copytable
	setTooltip = WG.Red.SetTooltip
	getSetTooltip = WG.Red.GetSetTooltip
	screen = WG.Red.Screen
	getWidgetObjects = WG.Red.GetWidgetObjects
	cleanupTaggedObjects = WG.Red.CleanupTaggedObjects
end

function RedUIchecks()
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


function AutoResizeObjects()
	if (LastAutoResizeX==nil) then
		LastAutoResizeX = CanvasX
		LastAutoResizeY = CanvasY
	end
	local lx,ly = LastAutoResizeX,LastAutoResizeY
	local vsx,vsy = screen.vsx,screen.vsy
	if ((lx ~= vsx) or (ly ~= vsy)) then
		local objects = getWidgetObjects(widget)
		--local scale = (vsy/ly + vsx/lx) * 0.5
		if getScale then 
			scale = getScale(vsx,lx,vsy,ly)
		else
			scale = vsx/lx
		end
		
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
				Spring.Echo("WARNING : "..o.name.." has no px")
			end
		end
		LastAutoResizeX,LastAutoResizeY = vsx,vsy
	end
end
 