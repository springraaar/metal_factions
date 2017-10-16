function gadget:GetInfo()
	return {
		name = "Map speed modifier disabler",
		desc = "Disables map speed modifiers for all but impassable terrain.",
		author = "raaar",
		date = "Aug, 2013",
		license = "PD",
		layer = 0,
		enabled = true
	}
end


if (not gadgetHandler:IsSyncedCode()) then
	return false
end

function gadget:Initialize()
	
	-- override terrain type movement modifiers
	local override = {}
	for i = 0,255,1 do
		Spring.SetMapSquareTerrainType(0,0,i)
		local name,_,_,t,b,v,s = Spring.GetGroundInfo(0,0)
		if (t == 0 and b == 0 and v == 0 and s == 0) or (t == 1 and b == 1 and v == 1 and s == 1)  then
			override[i] = false
		else
			override[i] = true
		end
	end
	for i = 0,255,1  do
		if override[i] then
			Spring.SetTerrainTypeData(i,1,1,1,1)
		end
	end

	-- set ambient lighting for units
	Spring.SetSunLighting({unitAmbientColor = {0.7, 0.7, 0.7}, unitDiffuseColor = {0.5, 0.5, 0.5}, unitSpecularColor = {0.5,0.5,0.5}})
end



