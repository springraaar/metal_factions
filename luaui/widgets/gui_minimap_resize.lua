function widget:GetInfo()
	return {
		name	= "Minimap Resize",
		desc	= "Resizes the minimap on the top-right corner",
		author	= "raaar",
		date	= "2021",
		license	= "PD",
		layer	= 5,
		enabled	= true
	}
end

function widget:Initialize()

	local vsx,vsy = gl.GetViewSizes()
	local aspectRatio = Game.mapSizeX / Game.mapSizeZ

	-- resize minimap
	if (aspectRatio > 1) then
		Spring.SendCommands("minimap geometry 0 0 "..(vsx/6).." 0")	
	else
		Spring.SendCommands("minimap geometry 0 0 0 "..vsy/3.8)
	end
end

