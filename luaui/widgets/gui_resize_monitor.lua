function widget:GetInfo()
	return {
	version   = "1",
	name      = "Window Resize Monitor",
	desc      = "Reloads UI when window size changes (workaround for some widgets not handling it properly).",
	author    = "raaar",
	date      = "2022",
	license   = "PD",
	layer     = math.huge,
	enabled   = true, --enabled by default
	}
end
local vsx, vsy = gl.GetViewSizes()

local spSendCommands = Spring.SendCommands
local spGetTimer = Spring.GetTimer
local spDiffTimers = Spring.DiffTimers
local floor = math.floor

local reload = false
local refTimer = spGetTimer()

------------------------------------------ Callins


function widget:Initialize()
	-- load current values
	vsx, vsy = gl.GetViewSizes()
end


function widget:ViewResize(viewSizeX, viewSizeY)
	if floor(spDiffTimers(spGetTimer(),refTimer)) > 2 then
		vsx, vsy = gl.GetViewSizes()
		reload = true
		refTimer = spGetTimer()
		Spring.Echo(Spring.GetGameFrame().." view resized!")
	end 
end

function widget:DrawScreen()
	if reload then
		-- trigger the change half a second later
		local delayElapsed = floor(spDiffTimers(spGetTimer(),refTimer)) > 1	-- 1s after last view resize
	
		if (delayElapsed) then
			reload = false
			Spring.Echo("Game view changed : reloading UI...")
			spSendCommands("luaui reload")
		end
	end
end

