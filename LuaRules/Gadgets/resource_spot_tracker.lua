
function gadget:GetInfo()
	return {
		name      = "Resource Spot Tracker",
		desc      = "Loads metal and geo spots into table for use on other widgets and gadgets",
		author    = "raaar",
		version   = "v1",
		date      = "2018",
		license   = "PD",
		layer     = -5,
		enabled   = true
	}
end

------------------------------------------------------------
-- Config
------------------------------------------------------------
local gridSize = 16 -- Resolution of metal map
local buildGridSize = 8 -- Resolution of build positions

------------------------------------------------------------
-- Speedups
------------------------------------------------------------


local min, max = math.min, math.max
local floor, ceil = math.floor, math.ceil
local abs = math.abs
local sqrt = math.sqrt
local INFINITY = math.huge
local METAL_SPOT_MIN_RELATIVE_VALUE = 0.2

local spGetGroundInfo = Spring.GetGroundInfo
local spGetGroundHeight = Spring.GetGroundHeight
local spTestBuildOrder = Spring.TestBuildOrder
local spGetFeatureDefID = Spring.GetFeatureDefID
local spGetFeaturePosition = Spring.GetFeaturePosition

local extractorRadius = Game.extractorRadius

local mapHasGeothermal = false
local isMetalMap = true -- assume metal map unless loadSpots() proves otherwise
local metalSpots = {}
local geoSpots = {}

-- create a position obj from coordinates
function newPosition(x,y,z)
	x = x or 0
	y = y or 0
	z = z or 0

    local self = { x=x, y=y, z=z, toArray = function() return {self.x, self.y, self.z} end}
    return self
end

-- return true if pos within maxDistance from center
function checkWithinDistance(pos,center,maxDistance)
	
	xd = pos.x-center.x
	zd = pos.z-center.z
	if (abs(xd) > maxDistance) then
		return false
	end
	if (abs(zd) > maxDistance) then
		return false
	end
	
	if (sqrt(xd*xd + zd*zd) > maxDistance) then
		return false
	end
	
	return true
end

-- get iterator for sorted table entries
function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

-- metal spot detection, min recommended grid size is 16
function loadMetalSpots(gridSize)

	local spots = {}
	local cellCountX = ceil(Game.mapSizeX / gridSize)
	local cellCountZ = ceil(Game.mapSizeZ / gridSize)
	local metalGridCells = {}
	local metalGridCellList = {}
	-- locate metal grid cells
	for i=0,(cellCountX - 1) do
		metalGridCells[i] = {}
		for j=0,(cellCountZ - 1) do
			local newCell = { metalWorth = 0, nearbyMetalWorth = 0, nearbyMetalCellCount = 0, p = newPosition()}
			metalGridCells[i][j] = newCell
			
			newCell.xIndex = i
			newCell.zIndex = j
			newCell.p.x = i * gridSize + gridSize / 2
			newCell.p.z = j * gridSize + gridSize / 2

			local _, groundMetal = spGetGroundInfo(newCell.p.x, newCell.p.z)
			if groundMetal > 0 then
				-- previous value is added, but is 0 as currently there is only one reading per cell
				newCell.metalWorth = newCell.metalWorth + groundMetal

				-- only add to cell list if metal value > 0
				metalGridCellList[#metalGridCellList+1] = newCell
			else
				if ( isMetalMap == true) then
					isMetalMap = false
				end
			end
		end
	end

	if (isMetalMap == false) then
	
		-- add nearby metal worth to metal grid cells
		-- weigh it less the farther it is (this is to break "ties" in the final processing and ensure spots end up centered)
		local maxIndexDif = max(floor(extractorRadius / (gridSize*2)),1)
		local xi,zi = 0
		local m = 0
		for	i,cell in ipairs(metalGridCellList) do
			-- check nearby cells
			for dxi = -maxIndexDif, maxIndexDif do
				for dzi = -maxIndexDif, maxIndexDif do
					xi = cell.xIndex + dxi
					zi = cell.zIndex + dzi
					if (xi >=0) and (zi >= 0) and not (dxi == 0 and dzi == 0) then
						if metalGridCells[xi] then
							if metalGridCells[xi][zi] then
								m = metalGridCells[xi][zi].metalWorth
								if m > 0 then 
									cell.nearbyMetalWorth = cell.nearbyMetalWorth + m * (1/(abs(dxi)+ abs(dzi)))
									cell.nearbyMetalCellCount = cell.nearbyMetalCellCount + 1
								end 
							end
						end
					end
				end
			end
		end
	
		-- get average values
		local minMetalWorth = INFINITY
		local averageMetalWorth = 0
		local maxMetalWorth = 0
		local combinedMetalWorth = 0
		for	i,cell in ipairs(metalGridCellList) do
			combinedMetalWorth = cell.metalWorth + cell.nearbyMetalWorth
			
			cell.combinedMetalWorth = combinedMetalWorth 
			
			if combinedMetalWorth < minMetalWorth then
				minMetalWorth = combinedMetalWorth
			end
			if combinedMetalWorth > maxMetalWorth then
				maxMetalWorth = combinedMetalWorth
			end
			
			averageMetalWorth = averageMetalWorth + combinedMetalWorth 
		end
		if (#metalGridCellList > 0) then
			averageMetalWorth =  averageMetalWorth / #metalGridCellList
		end
		
		--for	i,cell in ipairs(metalGridCellList) do
			--if (cell.combinedMetalWorth > 1000) then
				--Spring.MarkerAddPoint(cell.p.x,spGetGroundHeight(cell.p.x, cell.p.z),cell.p.z,tostring(cell.combinedMetalWorth))
			--end
		--end
		
		-- Final processing
		-- iterate through nonzero metal cell list from best to worst 
		-- add metal spots to list unless they "collide" with a previously added spot
		local rangeCheck = true
		local checkRadius = max(extractorRadius*1.5,80)
		local metalWorthThreshold = METAL_SPOT_MIN_RELATIVE_VALUE * averageMetalWorth
		for _, cell in spairs(metalGridCellList, function(t,a,b) return t[b].combinedMetalWorth < t[a].combinedMetalWorth end) do
	 		rangeCheck = true
			
			-- check range from every other existing spot
			for _,spot in ipairs(spots) do
				if(checkWithinDistance(cell.p,spot,checkRadius) == true) then
					rangeCheck = false
					break
				end
			end

			--Spring.MarkerAddPoint(cell.p.x,spGetGroundHeight(cell.p.x, cell.p.z),cell.p.z,tostring(cell.nearbyMetalCellCount))
			
			-- add new spot
			if rangeCheck == true and cell.combinedMetalWorth >= metalWorthThreshold then
				local spot = {}
				spot.x = cell.p.x
				spot.z = cell.p.z
				spot.y = spGetGroundHeight(spot.x, spot.z)
				spot.metalWorth = cell.combinedMetalWorth / averageMetalWorth
				spots[#spots + 1] = spot
			end
		end
		
	end
	metalSpots = spots
end

-- load geothermal spots
function loadGeoSpots()

	-- find and store geothermal spot positions
	local tmpFeatures = Spring.GetAllFeatures()
	mapHasGeothermal = false
	local isGeothermal = false
	for _, fId in pairs(tmpFeatures) do
		if fId then
			isGeothermal = FeatureDefs[spGetFeatureDefID(fId)].geoThermal
			if isGeothermal then
				mapHasGeothermal = true
				local fPos = newPosition(spGetFeaturePosition(fId,false,false))
				geoSpots[#geoSpots + 1] = fPos 
			end
		end
	end
	
end	


-------------------------- SYNCED 
if (gadgetHandler:IsSyncedCode()) then
	
	
function gadget:Initialize()
	-- load metal spot list
	-- try first with lower resolution grid
	-- use the low resolution grid if map doesn't have large metal zones combined with low extractor radius 
	-- otherwise use higher resolution grid
	loadMetalSpots(48) -- low res	
	if (#metalSpots < 150) then
		loadMetalSpots(16) -- high res
	elseif (#metalSpots > 300) then
		isMetalMap = true
	end
	
	Spring.Echo(#metalSpots.." metal spots found!")
	loadGeoSpots()
	Spring.Echo(#geoSpots.." geothermal spots found!")
	
	--[[	
	for i,spot in ipairs(metalSpots) do
		Spring.MarkerAddPoint(spot.x,spot.y,spot.z,string.format("%.2f",spot.metalWorth))
	end
	
	for i,spot in ipairs(geoSpots) do
		Spring.MarkerAddPoint(spot.x,spot.y,spot.z,"GEO")
	end
	--]]
	
	GG.metalSpots = metalSpots
	GG.geoSpots = geoSpots
end

-------------------------- UNSYNCED
else
	-- do nothing?

end
