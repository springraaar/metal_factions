function widget:GetInfo()
	return {
		name	= "Settings",
		desc	= "Overrides some Spring settings",
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
	
	-- set scrollwheel speed to -25 if >= 0
	local swSpeed = Spring.GetConfigInt("ScrollWheelSpeed")
	if (swSpeed and swSpeed >=0) then
		Spring.SetConfigInt("ScrollWheelSpeed",-25,true)
	end
	
	-- ensure lua garbage collection has enough slack to do its job
	-- (force persistence because otherwise they won't take effect as of 105.0)
	local gcMemMult = Spring.GetConfigFloat("LuaGarbageCollectionMemLoadMult")
	if (gcMemMult and gcMemMult < 1.3) then
		Spring.SetConfigFloat("LuaGarbageCollectionMemLoadMult",1.3,false) -- default 1.33f
	end
	local gcTimeMult = Spring.GetConfigFloat("LuaGarbageCollectionRunTimeMult")
	if (gcTimeMult and gcTimeMult < 4.5) then
		Spring.SetConfigFloat("LuaGarbageCollectionRunTimeMult",4.5,false) 	-- default 5.0f
	end
	
	-- disable clock and fps (widget is used instead)
	Spring.SendCommands("clock 0")
	Spring.SendCommands("fps 0")
	
	-- disable game speed indicator
	Spring.SendCommands("speed 0")
	
	-- enforce unit icon distance-related settings
	Spring.SendCommands("iconsasui 0")
	Spring.SetConfigInt("UnitIconFadeVanish",1000,false) 	-- default 1000
	Spring.SetConfigFloat("UnitIconScaleUI",1,false) 		-- default 1
	Spring.SetConfigInt("UnitIconsHideWithUI",0,false) 		-- default 0

	-- enforce hardware cursor	
	Spring.SendCommands("HardwareCursor 1")
	
	-- enforce vsync
	--local vsync = Spring.GetConfigInt("VSync")
	--if (vsync and vsync == 0) then
	--	Spring.SetConfigInt("VSync",1,true)
	--end
	
	-- enforce default font sizes
	-- (force persistence because otherwise they won't take effect as of 105.0)
	Spring.SetConfigInt("FontOutlineWeight",25,false)
	Spring.SetConfigInt("FontOutlineWidth",3,false)
	Spring.SetConfigInt("FontSize",23,false)
	Spring.SetConfigInt("SmallFontOutlineWeight",10,false)
	Spring.SetConfigInt("SmallFontOutlineWidth",2,false)
	Spring.SetConfigInt("SmallFontSize",14,false)
end

