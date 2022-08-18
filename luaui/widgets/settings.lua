function widget:GetInfo()
	return {
		name	= "Settings",
		desc	= "Overrides some Spring settings: grass, camera, maxParticles, clock, fps, speed indicator",
		author	= "raaar",
		date	= "2015-07-20",
		license	= "PD",
		layer	= 5,
		enabled	= true
	}
end

function widget:Initialize()

	-- set camera to "ta" mode
	local camState = Spring.GetCameraState()
	camState.name = 'ta'
	camState.mode = Spring.GetCameraNames()['ta']
	Spring.SetCameraState(camState, 0)
	
	-- set max particles to 20000
	Spring.SetConfigInt("MaxParticles",20000,true)

	-- set max nano particles to 10000
	Spring.SetConfigInt("MaxNanoParticles",10000,true)
	
	-- set scrollwheel speed to -25 if >= 0
	local swSpeed = Spring.GetConfigInt("ScrollWheelSpeed")
	if (swSpeed and swSpeed >=0) then
		Spring.SetConfigInt("ScrollWheelSpeed",-25,true)
	end
	
	-- disable clock and fps (widget is used instead)
	Spring.SendCommands("clock 0")
	Spring.SendCommands("fps 0")
	
	-- disable game speed indicator
	Spring.SendCommands("speed 0")
	
	-- enforce unit icon distance
	Spring.SendCommands("disticon 120")

	-- enforce high terrain detail
	Spring.SendCommands("grounddetail 140")	

	-- enforce hardware cursor	
	Spring.SendCommands("HardwareCursor 1")
	
	-- enforce vsync
	local vsync = Spring.GetConfigInt("VSync")
	if (vsync and vsync == 0) then
		Spring.SetConfigInt("VSync",1,true)
	end
	
	-- enforce default font sizes
	Spring.SetConfigInt("FontOutlineWeight",25,true)
	Spring.SetConfigInt("FontOutlineWidth",3,true)
	Spring.SetConfigInt("FontSize",23,true)
	Spring.SetConfigInt("SmallFontOutlineWeight",10,true)
	Spring.SetConfigInt("SmallFontOutlineWidth",2,true)
	Spring.SetConfigInt("SmallFontSize",14,true)
	
	if (string.find(Engine.version,"BAR105")) then
		Spring.SendCommands("softparticles 0")
	end
end

