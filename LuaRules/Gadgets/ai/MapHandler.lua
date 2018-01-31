include("LuaRules/Gadgets/ai/Common.lua")

MapHandler = {}
MapHandler.__index = MapHandler

function MapHandler.create()
   local obj = {}             -- our new object
   setmetatable(obj,MapHandler)  -- make MapHandler handle lookup
   return obj
end

function MapHandler:Name()
	return "MapHandler"
end

function MapHandler:internalName()
	return "mapHandler"
end


function MapHandler:Init()
	self.ai = nil
	-- assume metal map unless loadSpots() proves otherwise
	self.isMetalMap = true
	self.allowBuildingOverMetalSpots = false  
	self.waterDoesDamage = Game.waterDamage > 0
	
	-- load metal spot list
	-- try first with lower resolution grid
	-- use the low resolution grid if map doesn't have large metal zones combined with low extractor radius 
	-- otherwise use higher resolution grid
	self.spots = GG.metalSpots
	self.isMetalMap = GG.isMetalMap
	
	--log(#self.spots.." metal spots found!",self.ai) --DEBUG
	self.geoSpots = GG.geoSpots
	--log(#self.geoSpots.." geothermal spots found!",self.ai) --DEBUG
	
	-- check if there are any water metal spots
	local UWSpots = {}
	ud = UnitDefNames[UWMetalSpotCheckUnit]
	for i, spot in pairs(self.spots) do
		if spTestBuildOrder(ud.id, spot.x, spot.y, spot.z,0) > 0 then
			hasUWSpots = true
			spot.isUnderWater = true
			UWSpots[#UWSpots + 1] = spot 
		else
			spot.isUnderWater = false
		end
	end
	self.UWSpots = UWSpots
	local underWaterSpotCountFraction = #UWSpots  / #self.spots
		
	-- get terrain profile (cells)
	local cellCountX = math.ceil(Game.mapSizeX / CELL_SIZE)
	local cellCountZ = math.ceil(Game.mapSizeZ / CELL_SIZE)
	self.mapCells = {}
	self.mapCellList = {}
	-- log("cellSize X="..cellCountX.." Z="..cellCountZ, self.ai) --DEBUG

	local pFCellCountX = math.ceil(Game.mapSizeX / PF_CELL_SIZE)
	local pFCellCountZ = math.ceil(Game.mapSizeZ / PF_CELL_SIZE)
	self.mapPFCells = {}
	self.mapPFCellList = {}
	self.pFDistances = {}
	self.pFRegions = {}

	local landTestUnitDef = UnitDefNames[LAND_TEST_UNIT]
	local waterTestUnitDef = UnitDefNames[WATER_TEST_UNIT]
	local deepWaterTestUnitDef = UnitDefNames[DEEP_WATER_TEST_UNIT]
	
	local landCount = 0
	local landSlopeCount = 0
	local waterCount = 0
	local deepWaterCount = 0

	local pFLandCount = 0
	local pFLandSlopeCount = 0
	local pFWaterCount = 0
	local pFDeepWaterCount = 0

	-- standard large cells	
	for i=0,(cellCountX - 1) do
		self.mapCells[i] = {}
		for j=0,(cellCountZ - 1) do
			local newCell = { metalSpotCount = 0, nearbyLandMetalSpotCount = 0, nearbyWaterMetalSpotCount = 0, metalPotential = 0, isWater = false, isDeepWater = false, p = newPosition(), hasNearbyWater = false, metalSpots={}}
			self.mapCells[i][j] = newCell
			
			newCell.xIndex = i
			newCell.zIndex = j
			newCell.p.x = i * CELL_SIZE + CELL_SIZE / 2
			newCell.p.z = j * CELL_SIZE + CELL_SIZE / 2
			newCell.isLand = spTestBuildOrder(landTestUnitDef.id, newCell.p.x,0,newCell.p.z,0) > 0
			newCell.isWater = spTestBuildOrder(waterTestUnitDef.id, newCell.p.x,0,newCell.p.z,0) > 0
			newCell.isDeepWater = spTestBuildOrder(deepWaterTestUnitDef.id, newCell.p.x,0,newCell.p.z,0) > 0
			newCell.isLandSlope = false
			if( not newCell.isLand and not newCell.isWater and not newCell.isDeepWater) then
				newCell.isLandSlope = true	
			end
			
			self.mapCellList[#self.mapCellList+1] = newCell
			-- log("map cell at ".."("..i..";"..j..")",self.ai)  --DEBUG
			
			if(newCell.isLand) then 
				landCount = landCount + 1 
			elseif (newCell.isLandSlope) then
				landSlopeCount = landSlopeCount + 1
			elseif (newCell.isDeepWater) then
				deepWaterCount = deepWaterCount + 1
			elseif (newCell.isWater) then
				waterCount = waterCount + 1
			end			
		end
	end
	
	-- small cells, for path finding
	local height,h1,h2,h3,h4 = 0
	local slope,s1,s2,s3,s4 = 0
	for i=0,(pFCellCountX - 1) do
		self.mapPFCells[i] = {}
		for j=0,(pFCellCountZ - 1) do
			local newCell = { [height] = 0, [slope] = 0, type = PF_TYPE_LAND, isWater = false, isDeepWater = false, p = newPosition(), hasNearbyWater = false}
			self.mapPFCells[i][j] = newCell
			
			newCell.xIndex = i
			newCell.zIndex = j
			newCell.p.x = i * PF_CELL_SIZE + PF_CELL_SIZE / 2
			newCell.p.z = j * PF_CELL_SIZE + PF_CELL_SIZE / 2
			
			
			h1 = spGetGroundHeight(newCell.p.x + PF_CELL_SIZE / 4,newCell.p.z + PF_CELL_SIZE / 4)
			_,_,_,s1 = spGetGroundNormal(newCell.p.x + PF_CELL_SIZE / 4,newCell.p.z + PF_CELL_SIZE / 4)
			
			h2 = spGetGroundHeight(newCell.p.x + PF_CELL_SIZE / 4,newCell.p.z - PF_CELL_SIZE / 4)
			_,_,_,s2 = spGetGroundNormal(newCell.p.x + PF_CELL_SIZE / 4,newCell.p.z - PF_CELL_SIZE / 4)
			
			h3 = spGetGroundHeight(newCell.p.x - PF_CELL_SIZE / 4,newCell.p.z + PF_CELL_SIZE / 4)
			_,_,_,s3 = spGetGroundNormal(newCell.p.x - PF_CELL_SIZE / 4,newCell.p.z + PF_CELL_SIZE / 4)
			
			h4 = spGetGroundHeight(newCell.p.x - PF_CELL_SIZE / 4,newCell.p.z - PF_CELL_SIZE / 4)
			_,_,_,s4 = spGetGroundNormal(newCell.p.x - PF_CELL_SIZE / 4,newCell.p.z - PF_CELL_SIZE / 4)
			
			-- average the height (?)
			height = (h1 + h2 + h3 + h4) / 4 
			-- worst case slope
			slope = max(s1, s2, s3, s4)
			
			if (height >=0) then
				if (slope >= PF_STEEP_SLOPE_THRESHOLD) then
					newCell.type = PF_TYPE_LAND_STEEP_SLOPE
				elseif (slope > 0.05 and slope < PF_STEEP_SLOPE_THRESHOLD) then
					newCell.type = PF_TYPE_LAND_SLOPE
				end
			else
				if (height > PF_DEEP_WATER_THRESHOLD and slope < PF_STEEP_SLOPE_THRESHOLD) then
					newCell.type = PF_TYPE_WATER_SHALLOW
				elseif (height > PF_DEEP_WATER_THRESHOLD and slope >= PF_STEEP_SLOPE_THRESHOLD) then
					newCell.type = PF_TYPE_WATER_STEEP_SLOPE
				elseif (height > PF_DEEP_WATER_THRESHOLD and slope > 0.05 and slope < PF_STEEP_SLOPE_THRESHOLD) then
					newCell.type = PF_TYPE_WATER_SLOPE
				elseif (height <= PF_DEEP_WATER_THRESHOLD) then
					newCell.type = PF_TYPE_WATER_DEEP
				end
			end
			
			newCell.isLand = spTestBuildOrder(landTestUnitDef.id, newCell.p.x,0,newCell.p.z,0) > 0
			newCell.isWater = spTestBuildOrder(waterTestUnitDef.id, newCell.p.x,0,newCell.p.z,0) > 0
			newCell.isDeepWater = spTestBuildOrder(deepWaterTestUnitDef.id, newCell.p.x,0,newCell.p.z,0) > 0
			newCell.isLandSlope = false
			if( not newCell.isLand and not newCell.isWater and not newCell.isDeepWater) then
				newCell.isLandSlope = true	
			end
			
			newCell.index = #self.mapPFCellList+1
			self.mapPFCellList[newCell.index] = newCell
			
			-- log("map PF cell at ".."("..i..";"..j..")",self.ai)  --DEBUG
			
			-- Spring.MarkerAddPoint(newCell.p.x,height,newCell.p.z,"h="..string.format("%.0f",height).."\ns="..string.format("%.2f",slope))
			
			newCell.height = height
			newCell.slope = slope
			
			if(newCell.isLand) then 
				pFLandCount = pFLandCount + 1 
			elseif (newCell.isLandSlope) then
				pFLandSlopeCount = pFLandSlopeCount + 1
			elseif (newCell.isDeepWater) then
				pFDeepWaterCount = pFDeepWaterCount + 1
			elseif (newCell.isWater) then
				pFWaterCount = pFWaterCount + 1
			end
		end
	end


	-- load distances for each relevant pathing type
	self:initDistancesForPathingType(PF_UNIT_LAND)
	self:initDistancesForPathingType(PF_UNIT_LAND_AT)
	self:initDistancesForPathingType(PF_UNIT_AMPHIBIOUS)
	self:initDistancesForPathingType(PF_UNIT_AMPHIBIOUS_FLOATER)
	-- self:initDistancesForPathingType(PF_UNIT_AMPHIBIOUS_AT)
	self:initDistancesForPathingType(PF_UNIT_WATER)
	self:initDistancesForPathingType(PF_UNIT_WATER_DEEP)
	-- self:initDistancesForPathingType(PF_UNIT_AIR)

	self:loadRegionsForPathingType(PF_UNIT_LAND)
	self:loadRegionsForPathingType(PF_UNIT_LAND_AT)
	self:loadRegionsForPathingType(PF_UNIT_AMPHIBIOUS)
	self:loadRegionsForPathingType(PF_UNIT_AMPHIBIOUS_FLOATER)
	-- self:loadRegionsForPathingType(PF_UNIT_AMPHIBIOUS_AT)
	self:loadRegionsForPathingType(PF_UNIT_WATER)
	self:loadRegionsForPathingType(PF_UNIT_WATER_DEEP)
	-- self:loadRegionsForPathingType(PF_UNIT_AIR)

	--[[	
	-- print regions	 
	local regions = self.pFRegions[PF_UNIT_LAND]
	for	i,cell in ipairs(self.mapPFCellList) do
		if regions[i]~= nil then
			Spring.MarkerAddPoint(cell.p.x,cell.height,cell.p.z,regions[i] )
		end
	end
	--]]
	
	-- add metal spot info to cells
	local cell = nil
	for i,spot in ipairs(self.spots) do
		xi,zi = getCellXZIndexesForPosition(spot)
		cell = self.mapCells[xi][zi]
		cell.metalSpotCount = cell.metalSpotCount + 1
		cell.metalSpots[#cell.metalSpots + 1] = spot
	end
	
	-- add nearby metal spot info to cells
	local xi,zi = 0
	for	i,cell in ipairs(self.mapCellList) do
		-- check nearby cells
		for dxi = -1, 1 do
			for dzi = -1, 1 do
				xi = cell.xIndex + dxi
				zi = cell.zIndex + dzi
				if (xi >=0) and (zi >= 0) and not (dxi == 0 and dzi == 0) then
					if self.mapCells[xi] then
						if self.mapCells[xi][zi] then
							if (self.mapCells[xi][zi].isWater == true or self.mapCells[xi][zi].isDeepWater == true) then
								cell.nearbyWaterMetalSpotCount = cell.nearbyWaterMetalSpotCount + self.mapCells[xi][zi].metalSpotCount
								if (abs(dxi) == 1 and abs(dzi) == 1) then
									cell.hasNearbyWater = true
								end
							else
								cell.nearbyLandMetalSpotCount = cell.nearbyLandMetalSpotCount + self.mapCells[xi][zi].metalSpotCount
							end
						end
					end
				end
			end
		end
		
		cell.metalPotential =  cell.metalSpotCount + cell.nearbyLandMetalSpotCount + cell.nearbyWaterMetalSpotCount
	end

	-- if more than 5 metal spots per map cell, allow building over metal spots
	if (#self.spots/#self.mapCellList > 5) then
		self.allowBuildingOverMetalSpots = true
	end

	-- output map profile to console	
	--[[
	for j=0,(cellCountZ - 1) do
		local lineStr = ""
		for i=0,(cellCountX - 1) do
			local cell = self.mapCells[i][j]
			lineStr = lineStr.." "..(cell.isDeepWater and "W" or (cell.isWater and "w" or (cell.isLandSlope and "S" or "L")))
		end
		log(lineStr,self.ai)
	end
	--]]
	
	-- TODO : check PF cells and/or regions for each pathing type instead
	--log("land="..landCount.." slope="..landSlopeCount.." water="..waterCount.." deepWater="..deepWaterCount.." underWaterSpotFraction="..underWaterSpotCountFraction, self.ai)  --DEBUG
	self.mapProfile = MAP_PROFILE_LAND_FLAT
	-- mostly water 
	-- if waterCount+deepWaterCount > 0 and (waterCount+deepWaterCount)*underWaterSpotCountFraction >= 3 * (landCount+landSlopeCount)*(1-underWaterSpotCountFraction) then
	if waterCount+deepWaterCount > 0 and (waterCount+deepWaterCount) >= 3 * (landCount+landSlopeCount) then
		self.mapProfile = MAP_PROFILE_WATER
		--log("WATER MAP DETECTED",self.ai) --DEBUG
	-- mostly land 
	-- elseif landCount+landSlopeCount > 0 and 3*(waterCount+deepWaterCount)*underWaterSpotCountFraction <= (landCount+landSlopeCount)*(1-underWaterSpotCountFraction) then
	elseif landCount+landSlopeCount > 0 and 3*(waterCount+deepWaterCount) <= (landCount+landSlopeCount) then
		self.mapProfile = MAP_PROFILE_LAND_FLAT
	-- mixed		
	else
		-- local waterLandRatio =(waterCount+deepWaterCount)*underWaterSpotCountFraction / ((landCount+landSlopeCount)*(1-underWaterSpotCountFraction)) 
		local waterLandRatio =(waterCount+deepWaterCount) / (landCount+landSlopeCount)
		if waterLandRatio < 3 and waterLandRatio > 1/3 then
			self.mapProfile = MAP_PROFILE_MIXED
			--log("MIXED MAP DETECTED",self.ai) --DEBUG
		end
	end
	if(self.mapProfile == MAP_PROFILE_LAND_FLAT and landSlopeCount * 1.33 > landCount ) then
		self.mapProfile = MAP_PROFILE_LAND_RUGGED
		--log("RUGGED LAND MAP DETECTED",self.ai) --DEBUG
	elseif (self.mapProfile == MAP_PROFILE_LAND_FLAT) then
		--log("FLAT LAND MAP DETECTED",self.ai) --DEBUG
	end
end


-- init distances for pathing type (graph edges)
function MapHandler:initDistancesForPathingType(unitPathingType)
	local dist = {}
	local distMods = PF_DIST_MOD[unitPathingType]
	local pFCellsXZ = self.mapPFCells

	-- for each "edge", set distance
	local xIndex = 0
	local zIndex = 0
	local dxi, dzi = 0
	local val = 0
	for i,cell in ipairs(self.mapPFCellList) do
		dist[i] = {}
	
		-- get nearby cells
		xIndex = cell.xIndex
		zIndex = cell.zIndex
		for dxi = -1, 1 do
			for dzi = -1, 1 do
				if (dxi ~= 0 or dzi ~= 0) then
					xi = xIndex + dxi
					zi = zIndex + dzi
					otherCell = nil
					if (pFCellsXZ[xi]) then
						otherCell = pFCellsXZ[xi][zi]
					end
					if(otherCell ~= nil) then
						--val = distMods[otherCell.type]
						
						val = self:checkAdjacentCellConnection(cell.p,otherCell.p,unitPathingType)
						
						--[[
						if (val == 1) then
							if (dxi ~= 0 and dzi ~= 0) then
								val = 1.4  -- diagonals are longer						
							end					
						end
						--]]
						dist[i][otherCell.index] = val 
						
					end
				end
			end
		end
	end
	
	self.pFDistances[unitPathingType] = dist
end

-- checks if unit with pathing type can move from p1 to p2 (any cell combination)
local CHECKregions = nil
local CHECKx1, CHECKz1 = nil
local CHECKx2, CHECKz2 = nil
local CHECKi1 = nil
local CHECKi2 = nil
function MapHandler:checkConnection(p1,p2,unitPathingType)
	if (unitPathingType == PF_UNIT_AMPHIBIOUS_AT) or (unitPathingType == PF_UNIT_AIR) then
		return true
	end
	
	CHECKregions = self.pFRegions[unitPathingType]
	CHECKx1, CHECKz1 = getPFCellXZIndexesForPosition(p1)
	CHECKx2, CHECKz2 = getPFCellXZIndexesForPosition(p2)
	
	CHECKi1 = self.mapPFCells[CHECKx1][CHECKz1].index
	CHECKi2 = self.mapPFCells[CHECKx2][CHECKz2].index
	
	if (CHECKregions[CHECKi1] ~= CHECKregions[CHECKi2]) then
		return false
	end
	
	return true
end 

-- checks if unit with pathing type can move from p1 to p2 (adjacent cells only)
-- returns 1 if possible and math.huge otherwise
function MapHandler:checkAdjacentCellConnection(p1,p2,unitPathingType)

	h1 = spGetGroundHeight(p1.x,p1.z)
	_,_,_,s1 = spGetGroundNormal(p1.x,p1.z)
	h2 = spGetGroundHeight((p2.x + p2.x) / 2,(p1.z + p2.z) / 2)
	_,_,_,s2 = spGetGroundNormal((p1.x + p2.x) / 2,(p1.z + p2.z) / 2)
	h3 = spGetGroundHeight(p2.x,p2.z)
	_,_,_,s3 = spGetGroundNormal(p2.x,p2.z)

	if unitPathingType == PF_UNIT_LAND then
		if min(h1,h2,h3) < PF_DEEP_WATER_THRESHOLD then
			return math.huge
		end
		if (max(s1,s2,s3) > PF_STEEP_SLOPE_THRESHOLD ) then
			return math.huge
		end
		if (max(abs(h2 - h1),abs(h3 - h2)) > PF_STEEP_SLOPE_HEIGHT_THRESHOLD ) then
			return math.huge
		end		
	elseif unitPathingType == PF_UNIT_LAND_AT then
		if min(h1,h2,h3) < PF_DEEP_WATER_THRESHOLD then
			return math.huge
		end	
	elseif unitPathingType == PF_UNIT_AMPHIBIOUS then
		if (max(s1,s2,s3) > PF_STEEP_SLOPE_THRESHOLD ) then
			return math.huge
		end
		if (max(abs(h2 - h1),abs(h3 - h2)) > PF_STEEP_SLOPE_HEIGHT_THRESHOLD ) then
			return math.huge
		end
	elseif unitPathingType == PF_UNIT_AMPHIBIOUS_FLOATER then
		if max(h1,h2,h3) > PF_DEEP_WATER_THRESHOLD then
			if (max(s1,s2,s3) > PF_STEEP_SLOPE_THRESHOLD ) then
				return math.huge
			end
			if (max(abs(h2 - h1),abs(h3 - h2)) > PF_STEEP_SLOPE_HEIGHT_THRESHOLD ) then
				return math.huge
			end			
		end
	elseif unitPathingType == PF_UNIT_AMPHIBIOUS_AT then
		-- nothing here, can go everywhere
	elseif unitPathingType == PF_UNIT_WATER then
		if max(h1,h2,h3) > -5 then
			return math.huge
		end
	elseif unitPathingType == PF_UNIT_WATER_DEEP then
		if max(h1,h2,h3) > PF_DEEP_WATER_THRESHOLD then
			return math.huge
		end
	elseif unitPathingType == PF_UNIT_AIR then
		-- nothing here, can go everywhere
	end
	
	-- PF_UNIT_AMPHIBIOUS_AT and PF_UNIT_AIR can go everywhere?
	
	return 1	
end 

function MapHandler:loadRegionsForPathingType(unitPathingType)
	local dist = self.pFDistances[unitPathingType]
	local pFCellsXZ = self.mapPFCells
	local total = #self.mapPFCellList
	log("cells to process : "..total,self.ai)
	local iterations = 0
	local regions = {}
	local regionMax = 1
	
	
	local xIndex = 0
	local zIndex = 0
	local dxi, dzi = 0
	local val = 0
	local currentRegion, otherRegion
	local first = true
	local changed = true
	
	while changed == true do
		changed = false
		-- iterate to find regions for each cell
	
		for i,cell in ipairs(self.mapPFCellList) do
			currentRegion = regions[i]
			otherRegion = nil

			if currentRegion == nil then
				regions[i] = regionMax
				regionMax = regionMax + 1
				changed = true
			end
			
			-- get nearby cells
			xIndex = cell.xIndex
			zIndex = cell.zIndex
			for dxi = -1, 1 do
				for dzi = -1, 1 do
					if (dxi ~= 0 or dzi ~= 0) then
						xi = xIndex + dxi
						zi = zIndex + dzi
						otherCell = nil
						if (pFCellsXZ[xi]) then
							otherCell = pFCellsXZ[xi][zi]
						end
						
						if(otherCell ~= nil) then
							otherRegion = regions[otherCell.index] 
							
							-- if there is path to other cell, set both cells to same region
							if dist[i][otherCell.index] == 1 then
								if currentRegion ~= otherRegion then
									currentRegion = min(currentRegion or math.huge,otherRegion or math.huge)
									regions[i] = currentRegion
									regions[otherCell.index] = currentRegion
									changed = true
								end
									
							-- else, if cell not in a region, set to new region
							elseif regions[otherCell.index] == nil then
								otherRegion = regionMax
								regionMax = regionMax + 1
								changed = true
							end
						end
					end
				end
			end
		end	
		
		iterations = iterations + 1
	
		if iterations == 100 then
			break
		end
	end
	
	log("DONE iterations = "..iterations)
	self.pFRegions[unitPathingType] = regions
end

