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
	
	-- adjust smooth mesh to follow the terrain profile more closely
	Spring.SetSmoothMeshFunc(
		function() 
			local tileSize = Game.squareSize
			local sizeX = Game.mapSizeX
			local sizeZ = Game.mapSizeZ
			local set = Spring.SetSmoothMesh
			local get = Spring.GetGroundHeight
			local spGetMetalAmount = Spring.GetMetalAmount
			local T = 200  -- sampling "radius"
			local HEIGHT_OFFSET = 30 -- shift desired height
			local minHeight = math.huge
			local floor = math.floor
			local h = 0

			-- get lowest height of any metal spot, use it as minimum if it's above water 
			for x=0,floor(sizeX/16),1 do 
				for z=0,floor(sizeZ/16),1 do
					if spGetMetalAmount(x,z) > 0 then
						h = get(x*16,z*16)
						--Spring.Echo("METAL! check height = "..h)
						minHeight = math.min(h,minHeight)
					end 
				end
			end
			--Spring.Echo("min air mesh height = "..minHeight)
			if (minHeight < 0) then
				minHeight = 0
			end
			
			local mN,mS,mE,mW,m0
			local maxMeasurement
			-- override smooth mesh height
			for x=0,sizeX,tileSize do 
				for z=0,sizeZ,tileSize do 
					m0 = get(x,z)
					mE = get(x+T,z)
					mW = get(x-T,z)
					mN = get(x,z-T)
					mS = get(x,z+T)
					
					maxMeasurement = math.max(m0,mE,mW,mN,mS,minHeight)
					
					set(x,z, maxMeasurement + HEIGHT_OFFSET) 
				end 
			end 
		end
	)
	
end

