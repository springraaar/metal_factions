
if not gadgetHandler:IsSyncedCode() then return end

function gadget:GetInfo()
	return {
		name      = "Lua Metal Spot Placer",
		desc      = "Places metal spots according to lua metal map",
		author    = "raaar",
		version   = "v1",
		date      = "2017",
		license   = "PD",
		layer     = -math.huge,
		enabled   = true
	}
end

------------------------------------------------------------
-- Config
------------------------------------------------------------
local MAPSIDE_METALMAP = "mapconfig/map_metal_layout.lua"
local MAPSIDE_MAPINFO = "mapinfo.lua"


local METAL_MAP_SQUARE_SIZE = 16
local MEX_RADIUS = Game.extractorRadius
local MAP_SIZE_X = Game.mapSizeX
local MAP_SIZE_X_SCALED = MAP_SIZE_X / METAL_MAP_SQUARE_SIZE
local MAP_SIZE_Z = Game.mapSizeZ
local MAP_SIZE_Z_SCALED = MAP_SIZE_Z / METAL_MAP_SQUARE_SIZE

local mapConfig = VFS.FileExists(MAPSIDE_METALMAP) and VFS.Include(MAPSIDE_METALMAP) or false
local mapInfo = VFS.FileExists(MAPSIDE_MAPINFO) and VFS.Include(MAPSIDE_MAPINFO) or false

local spGetGroundHeight = Spring.GetGroundHeight


-- assigns metal to the defined metal spots when the gadget loads
function gadget:Initialize()
	if mapConfig and mapInfo then
		--for key,value in pairs(mapInfo) do
		--	Spring.Echo("HERE "..key.."="..tostring(value))
		--end
	
		Spring.Log(gadget:GetInfo().name, LOG.INFO, "Loading map-side lua metal spot configuration...")
		spots = mapConfig.spots
		metalFactor = 0.44

		local gaiaTeamId = Spring.GetGaiaTeamID()
		local features = nil
		local metalIdx = 1
		local xIndex, zIndex, xi, zi
		if (spots and #spots > 0) then
			for i = 1, #spots do
				local spot = spots[i]

				px = spot.x
				pz = spot.z
				metal = spot.metal

				-- place metal for spot
				if (px and pz and metal) then
					
					--Spring.Echo("metal set for x="..px.." z="..pz.." metal="..metal)
					xIndex = px / METAL_MAP_SQUARE_SIZE
					zIndex = pz / METAL_MAP_SQUARE_SIZE

					-- set the metal values
					if xIndex >=0 and zIndex >=0 then
						for dxi = -1, 1 do
							for dzi = -1, 1 do
								xi = xIndex + dxi
								zi = zIndex + dzi
	
								if (xi > 0 and xi < MAP_SIZE_X_SCALED and zi > 0 and zi < MAP_SIZE_Z_SCALED ) then							
									Spring.SetMetalAmount(xi,zi,metal * metalFactor *255)
								end
							end
						end
					end
									
					-- check if there is any feature there
					-- if not, place one
					features = Spring.GetFeaturesInCylinder(px,pz,15)
					if (not features or #features == 0) then

						if (metal > 2.7) then
							metalIdx = 3
						elseif (metal > 1.5) then
							metalIdx = 2
						else
							metalIdx = 1
						end
					
						--Spring.Echo("metal feature added at x="..px.." z="..pz)
						local fId = Spring.CreateFeature("metal_spot"..metalIdx,px,spGetGroundHeight(px,pz),pz,math.random(360),gaiaTeamId)
						Spring.SetFeatureAlwaysVisible(fId, true)
						Spring.SetFeatureNoSelect(fId,true)
						Spring.SetFeatureCollisionVolumeData(fId,0, 0, 0, 0, 0, 0,  0, 0, 0 )
						
					end
				end
			end
		end
	end
end

