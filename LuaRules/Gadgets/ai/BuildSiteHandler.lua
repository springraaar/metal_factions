include("LuaRules/Gadgets/ai/common.lua")

BuildSiteHandler = {}
BuildSiteHandler.__index = BuildSiteHandler

function BuildSiteHandler.create()
   local obj = {}             -- our new object
   setmetatable(obj,BuildSiteHandler)  -- make BuildSiteHandler handle lookup
   return obj
end

function BuildSiteHandler:Name()
	return "BuildSiteHandler"
end

function BuildSiteHandler:internalName()
	return "buildSiteHandler"
end

function BuildSiteHandler:Init(ai)
	self.ai = ai
	
	self.mapMinX = MAP_EDGE_MARGIN
	self.mapMaxX = Game.mapSizeX - MAP_EDGE_MARGIN
	self.mapMinZ = MAP_EDGE_MARGIN
	self.mapMaxZ = Game.mapSizeZ - MAP_EDGE_MARGIN
	
	-- building order table : <"xi_zi_unitName",{frame=frame,builderId=builderId}>
	self.buildingOrderTable = {}
	
end

function BuildSiteHandler:GameFrame(f)
	-- cleanup build order table
	if fmod(f,60) == 6 then
		for k,v in pairs(self.buildingOrderTable) do
			-- if expired, remove from table
			if (f - v.frame > BUILD_ORDER_VALIDITY_FRAMES) then
				self.buildingOrderTable[k] = nil
			end
		end
	end	
end


function BuildSiteHandler:markBuildOrder(xi,zi,unitName,builderId)
	local f = spGetGameFrame()
	
	self.buildingOrderTable[xi.."_"..zi.."_"..unitName] = {frame = f, builderId = builderId}
end

function BuildSiteHandler:checkBuildOrder(xi,zi,unitName,builderId)
	local f = spGetGameFrame()
	
	local entry = self.buildingOrderTable[xi.."_"..zi.."_"..unitName]
	-- return builderId > 0 if the same unit is going to be built in the same cell by another constructor
	if(	entry ~= nil and entry.builderId ~= builderId) then
		return entry.builderId
	end

	-- return 0 otherwise
	return 0
end

function BuildSiteHandler:findClosestBuildSite(ud, searchPos, searchRadius, minDistance, builderBehavior)
	local testPos = newPosition(searchPos.x,searchPos.y,searchPos.z)

	local isStaticBuilder = builderBehavior.isStaticBuilder 
	searchRadius = builderBehavior.isStaticBuilder and searchRadius or 200
	local xMin = searchPos.x - searchRadius
	local xMax = searchPos.x + searchRadius
	local zMin = searchPos.z - searchRadius
	local zMax = searchPos.z + searchRadius
	local step = 48
	
	
	local radius = spGetUnitDefDimensions(ud.id).radius
	-- built in sets of 4, assume double radius
	if (multiBuildBuildings[ud.name]) then
		radius = radius + radius
	end
	
	-- log("finding closest build site for "..ud.name.." (radius="..radius..")".."x: "..xMin.."-"..xMax.."z: "..zMin.."-"..zMax,self.ai)
	local uRadius = 0 
	local valid = false
	local uPos = nil
	local uDef = nil

	local ownCell = getNearbyCellIfExists(self.ai.unitHandler.ownBuildingCells,searchPos)
	local mapCell = getNearbyCellIfExists(self.ai.mapHandler.mapCells,searchPos)
	-- use higher resolution for static builders
	if isStaticBuilder then
		step = 24
		--Spring.SendCommands("clearmapmarks") 
	end
	local buildTest = 0
	local testRadius = minDistance+radius
	local groundMetal = 0
	local isMetalMap = self.ai.mapHandler.isMetalMap
	for x = xMin, xMax, step do
		-- check x map bounds
		if (x > self.mapMinX) and (x < self.mapMaxX) then

			testPos.x = x
			for z = zMin, zMax, step do
				-- check z map bounds
				if (z > self.mapMinZ) and (z < self.mapMaxZ) then
					testPos.z = z
					valid = true
					-- do a search radius test for static builders
					if isStaticBuilder then
						if not checkWithinDistance(testPos,searchPos,searchRadius) then
							valid = false
						end
					end

					buildTest = 0
					testPos.y = spGetGroundHeight(x,z)
					--if isStaticBuilder then
					--	Spring.MarkerAddPoint(testPos.x,testPos.y,testPos.z,valid and "b" or "-") --DEBUG
					--end
					
					-- if spot is underwater, skip
					-- TODO support water maps properly
					--if not ( self.waterDoesDamage and spGetGroundHeight(x,z) < 0) then
					
					if valid and (builderBehavior.isWaterMode or testPos.y >= 0) then
						-- check if unit can be built
						if spTestBuildOrder(ud.id, testPos.x, testPos.y, testPos.z,0) > 0 then
							valid = true

							-- on metal maps, check if spot actually has metal
							-- (some metal maps have zones without metal)
							if (isMetalMap == true and ud.extractsMetal > 0) then
								 _, groundMetal = spGetGroundInfo(x, z)
								if groundMetal == 0 then
									valid = false								
								end
							end
							
							if not isStaticBuilder then
								if ( valid == true ) then
									-- test if it can move to the location
									if not self.ai.mapHandler:checkConnection(builderBehavior.pos, testPos,builderBehavior.pFType) then
										valid = false
									end
								end
							end
							
							-- if it is a factory, check if south exit is clear
							-- also check if it's on the same pathing region as the center of base
							if ( valid == true ) then
								if ud.isBuilder then
									local typeToTest = PF_UNIT_LAND
									local plantPFType = pFConnectionRestrictionsByPlant[ud.name]

									-- only test south exit if it isn't an air unit factory or upg center
									if plantPFType ~= PF_UNIT_AIR then
										buildTest = spTestBuildOrder(ud.id, testPos.x, testPos.y, testPos.z + 80,0)
										if (buildTest ~= 1 and buildTest ~= 2) then
											valid = false
										end
									end

									if plantPFType then
										typeToTest = plantPFType
									end

									-- check connection to base
									if not self.ai.mapHandler:checkConnection(self.ai.unitHandler.basePos, testPos,typeToTest) then									
										valid = false
									end
								end
							end
							if ( valid == true ) then
								if (isMetalMap == false and self.ai.mapHandler.allowBuildingOverMetalSpots == false) then
									-- check if unit violates minimum distance from nearby metal spots
									for _,sPos in ipairs(mapCell.metalSpots) do
										if (checkWithinDistance(testPos,sPos,testRadius+100)) then
											valid = false
											break
										end
									end
								end
							end
						
							if ( valid == true ) then
								-- check if unit violates minimum distance from nearby geothermal spots
								for _,sPos in ipairs(self.ai.mapHandler.geoSpots) do
									if (checkWithinDistance(testPos,sPos,testRadius+120)) then
										valid = false
										break
									end
								end
							end
	
							if ( valid == true ) and minDistance > 0 and ownCell ~= nil then		
								-- check if unit violates minimum distance from nearby own buildings
								for uId,_ in pairs(ownCell.buildingIdSet) do
									uDef = UnitDefs[spGetUnitDefID(uId)]
									
									if (uDef) then
										uRadius = spGetUnitDefDimensions(uDef.id).radius
										-- add some safety tolerance around factories to avoid blocking the exit
										if uDef.isBuilder then
											uRadius = uRadius + 64
										end
										uPos = newPosition(spGetUnitPosition(uId,false,false))
										if (checkWithinDistance(testPos,uPos,testRadius+uRadius)) then
											valid = false
											break
										end
									end
								end
							end
							
							-- extra check to confirm that this isn't blocking any factory
							--TODO this shouldn't be necessary at this point
							if ( valid == true ) then
								for _,uId in pairs(spGetUnitsInCylinder(x,z-80,80)) do
									uDef = UnitDefs[spGetUnitDefID(uId)]
									if uDef and setContains(unitTypeSets[TYPE_PLANT],uDef.name) then
										valid = false
										break
									end
								end
							end
									
							if (valid == true) then
								return testPos
							end
						end
					end
				end
			end
		end	
	end
	
	return nil
end


function BuildSiteHandler:staticClosestBuildSpot(builderBehavior, ud, minimumDistance, attemptNumber)
	local minDistance = minimumDistance or 1
	local builderName = builderBehavior.unitName
	local tmpAttemptNumber = attemptNumber or 0
	local pos = nil	
	
	local targetPos = newPosition(spGetUnitPosition(builderBehavior.unitId,false,false))

	if (targetPos ~= nil) then
		-- add some randomness...or not
		-- targetPos.x = targetPos.x - 32 + random(1,64)	
		-- targetPos.z = targetPos.z - 32 + random(1,64)
		
		-- try to build near the target location
		pos = self:findClosestBuildSite(ud, targetPos, builderBehavior.buildRange * 0.8, minDistance, builderBehavior)
	end
	
	return pos
end

function BuildSiteHandler:closestBuildSpot(builderBehavior, ud, minimumDistance, attemptNumber)
	local minDistance = minimumDistance or 1
	local builderName = builderBehavior.unitName
	local tmpAttemptNumber = attemptNumber or 0
	local pos = nil	
	
	-- target nearest cell (and safest, if building something expensive without weapons) with least amount of buildings
	local targetPos = self:getBuildSearchPos(builderBehavior, ud)

	if (targetPos ~= nil) then
		-- add some randomness
		targetPos.x = targetPos.x - 128 + 16*random(1,16)	
		targetPos.z = targetPos.z - 128 + 16*random(1,16)
		
		
		-- try to build near the target location
		pos = self:findClosestBuildSite(ud, targetPos, BUILD_SEARCH_RADIUS, minDistance, builderBehavior)
	
		-- if failed
		if pos == nil then
		
			-- try near 12 positions in growing circumferences around the target position
			local searchAngle = nil
			local searchPos = nil
			local searchRadius = nil
			for i=1,12,1 do
				local searchRadius = BUILD_SEARCH_RADIUS * (floor(i/6)+1)
				searchAngle = (i - 1) / 3 * math.pi
				searchPos = newPosition()
				searchPos.x = floor(targetPos.x + searchRadius * math.sin(searchAngle) / 16 + 0.5) * 16
				searchPos.z = floor(targetPos.z + searchRadius * math.cos(searchAngle) / 16 + 0.5) * 16
				searchPos.y = targetPos.y
	
				-- test position
				pos = self:findClosestBuildSite(ud, searchPos, searchRadius, minDistance, builderBehavior)	
				if pos ~= nil then
					break
				end
			end
		end
	end
	
	return pos
end

-- return position where builder should attempt to build metal extractor or geothermal plant
function BuildSiteHandler:closestFreeSpot(builderBehavior, ud, position, safety, type, builderDef, builderId)
	local pos = nil
	local bestDistance = INFINITY

 	-- check for armed enemy units nearby
	local enemyUnitIds = self.ai.enemyUnitIds
	local spots = {}
	local isGeo = false
	if (type == "metal" or type == "advMetal") then
		spots = self.ai.mapHandler.spots
	elseif type == "geo" then
		isGeo = true
		spots = self.ai.mapHandler.geoSpots
	end
	
	-- if advanced extractor, ignore basic extractors
	local isAdvExtractor = type == "advMetal"
	for i,v in ipairs(spots) do
		local p = v
		local dist = distance(position, p)

		-- don't add if it's already too high or can't move there
		if dist < bestDistance and (builderDef.canFly or self.ai.mapHandler:checkConnection(position,p,builderBehavior.pFType)) then
			-- now check if we can build there			
			local units = spGetUnitsInCylinder(p.x,p.z,100)
			local vacant = true
			
			if not isGeo then
				if (isAdvExtractor) then
					for j,uId in ipairs(units) do
						local testDef = UnitDefs[spGetUnitDefID(uId)]
						if (setContains(unitTypeSets[TYPE_MOHO],testDef.name)) then
							vacant = false
							break
						end
					end				
				else
					for j,uId in ipairs(units) do
						local testDef = UnitDefs[spGetUnitDefID(uId)]
						if (setContains(unitTypeSets[TYPE_EXTRACTOR],testDef.name)) then
							vacant = false
							break
						end
					end
				end
			end
			if (not isGeo) or spTestBuildOrder(ud.id, p.x, p.y, p.z,0) > 0 then
				if (vacant and ((not safety) or self.ai.unitHandler:isPathBetweenPositionsSafe(position, v))) then
					if dist < bestDistance then
						bestDistance = dist
						pos = p
					end
				end
			end
		end
	end
	
	--if pos == nil then
	--	Spring.MarkerAddPoint(position.x,500,position.z,"NO MEX!") --DEBUG
	--end
	--if isGeo and pos ~= nil then
	--	Spring.MarkerAddPoint(pos.x,spGetGroundHeight(pos.x,pos.z),pos.z,"GEO!") --DEBUG
	--end	
	return pos
end

-- return position where builder should attempt to build unit
function BuildSiteHandler:getBuildSearchPos(builderBehavior,ud)
	local builderPos = newPosition(spGetUnitPosition(builderBehavior.unitId,false,false))
	local builderName = builderBehavior.unitName
	
	if builderBehavior.isMexBuilder or builderBehavior.isStaticBuilder then
		return builderPos		
	end
	
	-- target nearest cell, weighing in safety or vulnerability
	local isArmed = #ud.weapons > 0
	local isRadar = ud.radarRadius  > 1000 or ud.sonarRadius  > 800
	local bestCell = nil
	local targetPos = builderPos
	local bestDistance = INFINITY
	local weightedDistance = 0
	local distanceToVulnerable = 0
	local distanceToSafe = 0
	local distanceToSelf = 0
	local distanceToBase = 0
	local cost = getWeightedCost(ud)
	

	for _,cell in ipairs(self.ai.mapHandler.mapCellList) do
		distanceToSelf = distance(cell.p,builderPos)
		if(distanceToSelf < 5000) then
			local ownCell = getCellFromTableIfExists(self.ai.unitHandler.ownCells,cell.xIndex,cell.zIndex)
			if self.ai.mapHandler:checkConnection(builderPos,cell.p,builderBehavior.pFType) and (ownCell == nil or ownCell.buildingCount < BUILD_CELL_BUILDING_LIMIT) then

				if (self.ai.unitHandler.collectedData) then
					distanceToVulnerable = distance(cell.p,self.ai.unitHandler.mostVulnerableCell.p) 
					distanceToSafe = distance(cell.p,self.ai.unitHandler.leastVulnerableCell.p)
					distanceToBase = distance(cell.p,self.ai.unitHandler.basePos)
					
					if ((builderBehavior.isCommander or builderBehavior.specialRole == UNIT_ROLE_MEX_BUILDER) and (isArmed or isRadar)) then
						weightedDistance = distanceToSelf
					elseif (isArmed or isRadar) then
						if (builderBehavior.specialRole == UNIT_ROLE_DEFENSE_BUILDER or builderBehavior.specialRole == UNIT_ROLE_ADVANCED_DEFENSE_BUILDER) then
							weightedDistance = distanceToSelf * 0.3 + distanceToVulnerable * 0.45 + distanceToBase * 0.25
						else
							weightedDistance = distanceToSelf * 0.8 + distanceToVulnerable * 0.2
						end
					else
						weightedDistance = distanceToSelf * 0.3 + distanceToSafe * 0.45 + distanceToBase * 0.25
					end					
						
				else
					weightedDistance = distanceToSelf
				end
				
				if(bestCell == nil or weightedDistance < bestDistance) then
					bestCell = cell
					bestDistance = weightedDistance
				end
			end
		end
	end
	if bestCell ~= nil then
		targetPos = newPosition(bestCell.p.x,bestCell.p.y,bestCell.p.z)
	end
	
	-- return nil to make builder skip this order if another one already marked it
	-- TODO : maybe return an integer with the builderId instead of the position
	-- so the behavior can choose to assist instead of skipping
	local xIndex,zIndex = getCellXZIndexesForPosition(targetPos)
	if  (not (isArmed or isRadar) and cost < 300) or self:checkBuildOrder(xIndex,zIndex,ud.name,builderBehavior.unitId) == 0 then
		self:markBuildOrder(xIndex,zIndex,ud.name,builderBehavior.unitId)	
	else
		return nil
	end
	return targetPos
end
