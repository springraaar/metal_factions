function gadget:GetInfo()
	return {
		name = "Map property overrides",
		desc = "Modifies various properties of maps.",
		author = "raaar",
		date = "Aug, 2013",
		license = "PD",
		layer = -1,
		enabled = true
	}
end


if not gadgetHandler:IsSyncedCode() then ------------------------------ SYNCED
	return
end

local WIND_OVERRIDE_THRESHOLD_MIN = 3
local WIND_OVERRIDE_THRESHOLD_MAX = 10

-- override map wind if it's too low for some maps that are meant for games with very cheap windgens
local windAvg = (Game.windMin + Game.windMax) * 0.5
if windAvg >= WIND_OVERRIDE_THRESHOLD_MIN and windAvg <= WIND_OVERRIDE_THRESHOLD_MAX then
	Spring.SetWind(5,20)
end 

GG.minMetalSpotAltitude = 0

function gadget:Initialize()

	
	-- override terrain type movement modifiers
	local override = {}
	for i = 0,255,1 do
		Spring.SetMapSquareTerrainType(0,0,i)
		local _,name,_,_,t,b,v,s = Spring.GetGroundInfo(0,0)
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
	if(Spring.SetSunLighting) then
		Spring.SetSunLighting({unitAmbientColor = {0.7, 0.7, 0.7}, unitDiffuseColor = {0.5, 0.5, 0.5}, unitSpecularColor = {0.5,0.5,0.5}})
	end
	
	-- adjust smooth mesh to follow the terrain profile more closely
	Spring.SetSmoothMeshFunc(
		function() 
			local tileSize = Game.squareSize
			local sizeX = Game.mapSizeX
			local sizeZ = Game.mapSizeZ
			local set = Spring.SetSmoothMesh
			local get = Spring.GetGroundHeight
			local spGetMetalAmount = Spring.GetMetalAmount
			local radius = 260 
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
			
			GG.minMetalSpotAltitude = minHeight
			Spring.SetGameRulesParam("minMetalSpotAltitude",minHeight)
			
			local m0,xs,zs,mIdx
			local measurementOffsets={{0,1},{0,-1},{-1,0},{1,0},{-0.5,-0.5},{-0.5,0.5},{0.5,-0.5},{0.5,0.5},{-0.2,-0.2},{-0.2,0.2},{0.2,-0.2},{0.2,0.2}}
			local measurement={0,0,0,0,0,0,0,0,0,0,0,0,0}
			local maxMeasurement
			-- override smooth mesh height
			for x=1,sizeX,tileSize do 
				for z=1,sizeZ,tileSize do 
					m0 = get(x,z)
					measurement={m0,m0,m0,m0,m0,m0,m0,m0,m0,m0,m0,m0,m0}  -- 12 positions + center
					mIdx = 2
					for _,offsets in pairs(measurementOffsets) do
						xs = x+radius*offsets[1]
						zs = z+radius*offsets[2]
							
						if (xs >= 0 and xs <= sizeX and zs >= 0 and zs <= sizeZ) then
							measurement[mIdx] = get(xs,zs)
						end
						mIdx = mIdx +1
					end
					
					maxMeasurement = math.max(measurement[1],0.85*measurement[2],0.85*measurement[3],0.85*measurement[4],0.85*measurement[5],measurement[6],measurement[7],measurement[8],measurement[9],measurement[10],measurement[11],measurement[12],measurement[13],minHeight)
					
					set(x,z, maxMeasurement + HEIGHT_OFFSET) 
				end 
			end 
		end
	)
end
