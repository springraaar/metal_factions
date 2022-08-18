include("luarules/gadgets/ai/common.lua")
 
UnitHandler = {}
UnitHandler.__index = UnitHandler

function UnitHandler.create()
   local obj = {}             -- our new object
   setmetatable(obj,UnitHandler)  -- make AI handle lookup
   return obj
end

function UnitHandler:name()
	return "UnitHandler"
end

function UnitHandler:internalName()
	return "unitHandler"
end

function initUnitGroup(id)
	local obj = {}
	
	obj.id = id
	obj.centerPos = newPosition()
	obj.centerFrame = 0
	obj.oldCenterPos = newPosition()
	obj.oldCenterPosFrame = 0
	obj.nearCenterCost = 0
	obj.nearCenterCount = 0
	obj.totalCost = 0 
	obj.recruits = {}
	obj.nearCenterAntiUWCost = 0
	obj.avgHpCostRatio = 1
	obj.avgRange = 1
	obj.avgSpeed = 1
	obj.isAmphibious = false
	obj.closestCell = nil
	obj.closestCellVulnerable = nil
	obj.targetValue = 0
	obj.targetThreatAlongPath = 0
	obj.targetCell = nil
	obj.targetPos = newPosition()
	obj.task = nil
	obj.taskFrame = 0
	
	return obj
end

function initUnitCell()
	local newCell = {
		cost = 0, 
		attackerCost = 0,
		defenderCost = 0,
		underwaterDefenderCost = 0, -- only own cells  
 		airAttackerCost = 0, 
		nearbyAttackerCost = 0, 
		nearbyDefenderCost = 0,
		nearbyUnderwaterDefenderCost = 0, -- only own cells
		nearbyAirAttackerCost = 0, 
		badAAAttackerCost = 0, -- only enemy cells
		badAADefenderCost = 0,  -- only enemy cells
 		badAAAirAttackerCost = 0, -- only enemy cells
		nearbyBadAAAttackerCost = 0, -- only enemy cells
		nearbyBadAADefenderCost = 0, -- only enemy cells
		nearbyBadAAAirAttackerCost = 0, -- only enemy cells
 		xIndex = 0,
		zIndex = 0, 
		p = newPosition(), 
		baseDistance = 0, 
		extractorCount = 0, 
		underWaterCost = 0, 
		economyCost = 0, 
		nearbyCost = 0,   -- only own cells
		nearbyEconomyCost = 0,   -- only own cells
		buildingCount = 0,
		internalThreatCost = 0, 
		combinedThreatCost = 0, 
		internalThreatCostExcludingBadAA = 0,  -- only enemy cells
		combinedThreatCostExcludingBadAA = 0, -- only enemy cells
		combinedAvgHpCostRatio = 0,  -- only enemy cells
		combinedAvgRange = 0,  -- only enemy cells
		combinedAvgSpeed = 0,  -- only enemy cells
		combinedAvgRefCost = 0  -- only enemy cells
	}
	
	return newCell
end 

function UnitHandler:Init(ai)
	self.ai = ai
	self.isEasyMode = (self.ai.mode == "easy")
	self.isBrutalMode = (self.ai.mode == "brutal")
	
	self.sizeMult = 1
	self.atkFailureCost = 0
	self.latestAlliedLossesCost = 0
	self.latestEnemyLossesCost = 0
	self.teamCombatEfficiencyHistory = {}
	self.selfCombatEfficiency = 1
	self.teamCombatEfficiency = 1
	self.airHarassWhileAttacking = true

	self.refForceCost = FORCE_COST_REFERENCE * self.sizeMult		-- target force size
	
	self.perfCounter = 0
	
	self.basePos = newPosition()
	self.basePos.x = 0
	self.basePos.y = 0 
	self.basePos.z = 0 

	self.mostVulnerableCell = nil
	self.leastVulnerableCell = nil
	self.closestToBaseCenterCell = nil

	self.taskQueues = {}
	
	self.unitGroups = {}
	self.unitGroups[UNIT_GROUP_ATTACKERS] = initUnitGroup(UNIT_GROUP_ATTACKERS) 
	self.unitGroups[UNIT_GROUP_AIR_ATTACKERS] = initUnitGroup(UNIT_GROUP_AIR_ATTACKERS)
	self.unitGroups[UNIT_GROUP_SEA_ATTACKERS] = initUnitGroup(UNIT_GROUP_SEA_ATTACKERS)	
	self.unitGroups[UNIT_GROUP_RAIDERS] = initUnitGroup(UNIT_GROUP_RAIDERS)

	self.baseCount = 0
	self.mobileCount = 0
	self.attackerCount = 0 
	self.airAttackerCount = 0
	self.seaAttackerCount = 0
	self.focusOnEndGameArmy = false 	-- end game, stop making structures, focus on army
	
	self.humanTask = nil		--remove?
	self.humanTaskFrame = -HUMAN_TASK_DELAY_FRAMES - 1	--remove? 	
	self.baseUnderAttack = false
	self.baseUnderAttackFrame = -BASE_UNDER_ATTACK_FRAMES - 1
	self.lastMainForceAttackFrame = 0
	self.ownCellList = {}
	self.ownCells = {}
	self.ownBuildingCells = {}
	self.ownBuildingUDefById = {}
	
	self.friendlyCellList = {}
	self.friendlyCells = {}
	self.enemyCellList = {}
	self.enemyCells = {}
	self.threatType = THREAT_NORMAL
	self.friendlyExtractorCount = 0
	self.enemyExtractorCount = 0
	
	-- task queue related information
	self.standardQueueCount = 0
	self.advancedStandardQueueCount = 0
	self.mexBuilderCount = 0
	self.basePatrollerCount = 0
	self.mexUpgraderCount = 0
	self.defenseBuilderCount = 0
	self.advancedDefenseBuilderCount = 0 
	self.attackPatrollerCount = 0
	
	
	self.mexBuilderCountTarget = 1
	self.basePatrollerCountTarget = 1
	self.mexUpgraderCountTarget = 1
	self.defenseBuilderCountTarget = 1
	self.advancedDefenseBuilderCountTarget = 1 
	self.attackPatrollerCountTarget = 1
	self.commanderMorphing = false
	self.perceivedTeamAdvantageFactor = 1

	-- when on all-in mode, avoid retreating units
	self.allIn = false --TODO remove this? changed to work on a per-group basis
	
	-- raider path distance maps for various path types 
	self.raiderPFDistances = {}
	-- raider threat cost reference for various path types
	self.raiderThreatCostReference = {}
	-- raider paths for the various path types
	self.raiderPath = {}
	
	
	-- dangerous cells, where own units got damaged by enemy recently
	self.dangerCells = {}
	
	-- initialize own building cells
	self.cellCountX = math.ceil(Game.mapSizeX / CELL_SIZE)
	self.cellCountZ = math.ceil(Game.mapSizeZ / CELL_SIZE)

	self.ownBuildingCells = {}
	for i=0,(self.cellCountX - 1) do
		self.ownBuildingCells[i] = {}
		for j=0,(self.cellCountZ - 1) do
			local newCell = { buildingIdSet={}, p = newPosition(), xIndex=i,zIndex=j}
			self.ownBuildingCells[i][j] = newCell
			
			newCell.p.x = i * CELL_SIZE + CELL_SIZE / 2
			newCell.p.z = j * CELL_SIZE + CELL_SIZE / 2
		end
	end
	
	-- init map of bad anti air units (armed weapons only)
	self.badAAUnitNames = {}
	self.badAAUnitDefIds = {}
	local hasDecentAAWeapon = false
	for _,ud in pairs(UnitDefs) do
		if ud.weapons and (not fakeWeaponUnits[ud.name]) and ud.weapons[1] and ud.weapons[1].weaponDef then
			hasDecentAAWeapon = false
			for wNum,w in pairs(ud.weapons) do
				local wd=WeaponDefs[w.weaponDef]
				
			    if not wd.isShield then
			    	if (not wd.burnblow) and (wd.type ~= "BeamLaser") and (not wd.tracks) and (wd.projectilespeed < 20) then
						-- bad aa weapon
						--log(ud.name.." v="..wd.projectilespeed,self.ai)
					else 
						hasDecentAAWeapon = true
						break
					end
			    end
			end
			
			if (not hasDecentAAWeapon) then
				self.badAAUnitNames[ud.name] = true
				self.badAAUnitDefIds[ud.id] = true
			end
	    end
	end
	--printTable(self.badAAUnitNames)
	
	self.nukeTargetCell = nil
	self.beaconAttack = true
	self.beaconMode = nil --TODO make this work
	
	self.brutalPlantDone = false
	self.brutalAirPlantDone = false	
	self.brutalLightDefenseDone = false
	self.brutalAADefenseDone = false
	self.brutalHeavyDefenseDone = false
	
	self.collectedData = false
end

-- evaluate cell as target for enemies, 0 means cell is already well defended
function UnitHandler:getCellVulnerability(cell)

	-- calculate distance to center of base
	local cellDistance = distance(self.basePos,cell.p)
	
	-- get defenses and enemy threat value
	local totalDefenses = cell.defenderCost + cell.nearbyDefenderCost
	local totalEconomy = cell.economyCost + cell.nearbyEconomyCost
	-- TODO: take friendly defenses and economy into account	
		
	local totalThreatCost = 0
	for i=1,#self.enemyCellList do
		local otherCell = self.enemyCellList[i]
		if not (otherCell.xIndex == cell.xIndex and otherCell.zIndex == cell.zIndex) then
			local d = distance(otherCell.p,cell.p) or INFINITY
			totalThreatCost = totalThreatCost + otherCell.internalThreatCost* DEVALUATION_DISTANCE/(DEVALUATION_DISTANCE + d)
		end
	end
	
	-- local defenseCoverage = totalDefenses / totalEconomy
	local value = totalThreatCost --+ (totalEconomy - totalDefenses)/5
	
	return value
end

-- evaluate cell as target for unit group
local totalThreatCost = 0
local nearerThreatCostAlongDirection = 0
local otherNearerThreatCost = 0
local totalAssistCost = 0
local nearerAssistCostAlongDirection = 0
local otherNearerAssistCost = 0
local alongDirectionWeight = 1.0
local otherWeight = 0.2
local lineSearchPoints = 10
local processedCellIndexes = {}
local searchX = nil
local searchZ = nil
local enemyCell = nil
local xi,zi,dxi,dzi,xIndex,zIndex
local cellCountX = 0
local cellCountZ = 0
local checkAssist = true
local enemyCells = {}
local ownCells = {}
local friendlyCells = {}
local dangerCells = {}
local groupCostFactor = 1
local groupDistanceFactor = 1
local cellDistance = 0
local baseDistance = 0
local ignoreBadAA = false
function UnitHandler:getCellAttackValue(group, cell)
	-- if cell has no enemies in it, ignore it
	-- cells can have nearby enemy cost from nearby cells without having any actual enemy units inside
	if not cell.cost or cell.cost == 0 then
		return -INFINITY, 0
	end 

	-- ignore cells with only underwater units
	if ( cell.cost == cell.underWaterCost and group.nearCenterAntiUWCost == 0) then
		return -INFINITY, 0
	end
		
	if ( group.id == UNIT_GROUP_AIR_ATTACKERS ) then
		-- nothing here?
	elseif ( group.id == UNIT_GROUP_ATTACKERS or group.id == UNIT_GROUP_RAIDERS) then
		if not group.isAmphibious then
			-- ignore deep water cells or cells with only underwater units
			local mapCell = getCellFromTableIfExists(self.ai.mapHandler.mapCells,cell.xIndex,cell.zIndex) 
			if ( mapCell ~= nil and mapCell.isDeepWater ) then
				return -INFINITY, 0
			end
		end
	elseif ( group.id == UNIT_GROUP_SEA_ATTACKERS ) then
		-- ignore land cells without an adjacent water cell
		local mapCell = getCellFromTableIfExists(self.ai.mapHandler.mapCells,cell.xIndex,cell.zIndex)

		if ( mapCell ~= nil and (mapCell.isLand or mapCell.isLandSlope) and cell.hasNearbyWater == false ) then
			return -INFINITY, 0
		end
	end

	-- air units are weaker but can easily travel farther
	groupCostFactor = 1
	groupDistanceFactor = ATTACKER_DISTANCE_EVALUATION_FACTOR
	if group.id == UNIT_GROUP_AIR_ATTACKERS then
		groupCostFactor = AIR_ATTACKER_EVALUATION_FACTOR
		groupDistanceFactor = AIR_ATTACKER_DISTANCE_EVALUATION_FACTOR
	end  
	
	-- calculate distance to center of group or center of base (if under attack)
	cellDistance = distance(group.centerPos,cell.p)
	baseDistance = distance(self.basePos,cell.p)

	-- main attack force uses devaluation based on distance to base as well	
	if (group.id == UNIT_GROUP_ATTACKERS ) then
		cellDistance = 0.7*baseDistance + 0.3*cellDistance
 	end

	-- raiders and air far from base should not assist or expect assistance from allies, they're likely busy doing something
	--if ( group.id == UNIT_GROUP_AIR_ATTACKERS or group.id == UNIT_GROUP_AIR_ATTACKERS) and (baseDistance > HUGE_RADIUS) then
	if ( group.id == UNIT_GROUP_RAIDERS or group.id == UNIT_GROUP_AIR_ATTACKERS) and ((baseDistance > BIG_RADIUS) or (group.nearCenterCost < 1000)) then
		checkAssist = false
	else 
		checkAssist = true
	end

	totalThreatCost = 0
	nearerThreatCostAlongDirection = 0
	otherNearerThreatCost = 0
	totalAssistCost = 0
	nearerAssistCostAlongDirection = 0
	otherNearerAssistCost = 0
	ignoreBadAA = group.id == UNIT_GROUP_AIR_ATTACKERS
	processedCellIndexes = {}
	searchX = nil
	searchZ = nil
	enemyCell = nil
	cellCountX = self.cellCountX
	cellCountZ = self.cellCountZ
	enemyCells = self.enemyCells
	ownCells = self.ownCells
	friendlyCells = self.friendlyCells
	
	-- add the threat cost of each cell that is closer to the group center
	-- along the direction (assume units can go straight to it)
	-- TODO this will produce bad results if path is obstructed and a long detour is necessary
	for i=1,lineSearchPoints do
		searchX = (i/lineSearchPoints)*cell.p.x + ((lineSearchPoints-i)/lineSearchPoints)*group.centerPos.x 
		searchZ = (i/lineSearchPoints)*cell.p.z + ((lineSearchPoints-i)/lineSearchPoints)*group.centerPos.z
	
		xIndex, zIndex = getCellXZIndexesForPosition(newPosition(searchX,0,searchZ))
		-- search cells around the position
		xi = 0
		zi = 0
		for dxi = -1, 1 do
			for dzi = -1, 1 do
				xi = xIndex + dxi
				zi = zIndex + dzi
				if (xi >=0) and (zi >= 0) and xi < cellCountX and zi < cellCountZ and (not processedCellIndexes[xi] or not processedCellIndexes[xi][zi]) then
					-- threathening enemies
					if enemyCells[xi] and enemyCells[xi][zi] then
						nearerThreatCostAlongDirection = nearerThreatCostAlongDirection + (ignoreBadAA and enemyCells[xi][zi].internalThreatCostExcludingBadAA or enemyCells[xi][zi].internalThreatCost)
					end
				
					if (checkAssist) then
						-- helpful allies
						if ownCells[xi] and ownCells[xi][zi] then
							nearerAssistCostAlongDirection = nearerAssistCostAlongDirection + ownCells[xi][zi].internalThreatCost
						end
						if friendlyCells[xi] and friendlyCells[xi][zi] then
							nearerAssistCostAlongDirection = nearerAssistCostAlongDirection + friendlyCells[xi][zi].internalThreatCost
						end
					end
					if (not processedCellIndexes[xi]) then
						processedCellIndexes[xi] = {}
					end
					processedCellIndexes[xi][zi] = 1
				end
			end
		end
	end
	
	if (checkAssist) then
		-- add the internal threat cost of each cell that is closer to the group center
		-- regardless of direction
		for i=1,#self.enemyCellList do
			local otherCell = self.enemyCellList[i]
			if (otherCell.cost and otherCell.cost > 0) then
				xIndex = otherCell.xIndex
				zIndex = otherCell.zIndex
				if not (xIndex == cell.xIndex and zIndex == cell.zIndex) and (not processedCellIndexes[xIndex] or not processedCellIndexes[xIndex][zIndex]) then
					local d = distance(otherCell.p,group.centerPos) or INFINITY
					if d < cellDistance then
						-- threathening enemies
						otherNearerThreatCost = otherNearerThreatCost + (ignoreBadAA and otherCell.internalThreatCostExcludingBadAA or otherCell.internalThreatCost)
						
						--if (checkAssist) then
							-- helpful allies
							if ownCells[xIndex] and ownCells[xIndex][zIndex] then
								otherNearerAssistCost = otherNearerAssistCost + ownCells[xIndex][zIndex].internalThreatCost
							end
							if friendlyCells[xIndex] and friendlyCells[xIndex][zIndex] then
								otherNearerAssistCost = otherNearerAssistCost + friendlyCells[xIndex][zIndex].internalThreatCost
							end
						--end
						
						if (not processedCellIndexes[xIndex]) then
							processedCellIndexes[xIndex] = {}
						end
						processedCellIndexes[xIndex][zIndex] = 1
					end
				end
			end
		end
	end
	totalThreatCost = totalThreatCost + alongDirectionWeight * nearerThreatCostAlongDirection + otherWeight * otherNearerThreatCost
	if (checkAssist) then
		totalAssistCost = totalAssistCost + alongDirectionWeight * nearerAssistCostAlongDirection + otherWeight * otherNearerAssistCost
	end
	
	if (checkAssist) then	
		-- add assist cost of allies on cells further away but still around the target
		-- and that haven't been processed yet
		-- TODO remove this?
		xIndex, zIndex = getCellXZIndexesForPosition(cell.p)
		xi = 0
		zi = 0
		for dxi = -2, 2 do
			for dzi = -2, 2 do
				xi = xIndex + dxi
				zi = zIndex + dzi
				if (xi >=0) and (zi >= 0) and xi < cellCountX and zi < cellCountZ and (not processedCellIndexes[xi] or not processedCellIndexes[xi][zi]) then
					if ownCells[xi] and ownCells[xi][zi] then
						totalAssistCost = totalAssistCost + ownCells[xi][zi].internalThreatCost
					end
					if friendlyCells[xi] and friendlyCells[xi][zi] then
						totalAssistCost = totalAssistCost + self.friendlyCells[xi][zi].internalThreatCost
					end
				end
			end
		end
	end
	
	-- remove own attackers cost from assist cost if they are nearby to prevent them from being counted twice
	if (checkAssist and cellDistance < 2*CELL_SIZE) then
		totalAssistCost = totalAssistCost - group.nearCenterCost * groupCostFactor 
	end 
	
	local threatEvaluationFactor = ATTACK_ENEMY_THREAT_EVALUATION_FACTOR
	if (self.baseUnderAttack and cellDistance < BASE_DESPERATION_DEFENSE_THRESHOLD_DISTANCE ) then
		threatEvaluationFactor = threatEvaluationFactor * DEFENSE_ENEMY_THREAT_EVALUATION_FACTOR 
	end
	if (self.isEasyMode) then
		threatEvaluationFactor = threatEvaluationFactor * ATTACK_ENEMY_THREAT_EVALUATION_EASY_FACTOR
	end
	if (self.isBrutalMode) then
		threatEvaluationFactor = threatEvaluationFactor * ATTACK_ENEMY_THREAT_EVALUATION_BRUTAL_FACTOR
	end
	-- fast raiders and air should be even more scared of enemy armed units?
	if (group.id == UNIT_GROUP_AIR_ATTACKERS or group.id == UNIT_GROUP_RAIDERS) then
		threatEvaluationFactor = threatEvaluationFactor * 2
	end

	if (self.ai.useStrategies) then
		local currentStrategy = self.ai.currentStrategy
		local sStage = self.ai.currentStrategyStage
	
		local mult = currentStrategy.stages[sStage].properties.enemyThreatEstimationMult
		if (mult and mult ~= 1) then
			threatEvaluationFactor = threatEvaluationFactor * mult
		end
	end
	threatEvaluationFactor = threatEvaluationFactor / max(self.perceivedTeamAdvantageFactor,1.0)
	threatEvaluationFactor = threatEvaluationFactor * (group.task == TASK_ATTACK and ATTACK_PERSISTENCE_THREAT_EVALUATION_FACTOR or 1) 

	-- scale threat according to combat efficiency history
	threatEvaluationFactor = threatEvaluationFactor * min(max(1/(math.pow(self.teamCombatEfficiency,1.2)),COMBAT_EFFICIENCY_FORCE_SIZE_MOD_MIN),COMBAT_EFFICIENCY_FORCE_SIZE_MOD_MAX)
	
	local cellValue = min(group.nearCenterCost * groupCostFactor + totalAssistCost - totalThreatCost * threatEvaluationFactor,cell.cost)
	if (cellValue > 0) then
		cellValue = cellValue * DEVALUATION_DISTANCE/(DEVALUATION_DISTANCE + cellDistance*groupDistanceFactor)
	end
	 
	--if (self.ai.id == 1 and group.id == UNIT_GROUP_ATTACKERS) then 
	--	Spring.MarkerAddPoint(cell.p.x,cell.p.y,cell.p.z,cellValue) --DEBUG
	--	Spring.MarkerAddPoint(group.centerPos.x,group.centerPos.y,group.centerPos.z,"GROUP "..tostring(checkAssist)) --DEBUG
	--	Spring.MarkerAddPoint(self.basePos.x,self.basePos.y,self.basePos.z,"BASE") --DEBUG
	--end
	 
	return cellValue, nearerThreatCostAlongDirection
end


-- check safety along path to positions
-- returns false if any enemy coverage found on cells unless they have enough friendly combatants within
function UnitHandler:isPathBetweenPositionsSafe(startPos, endPos)
	totalThreatCost = 0
	totalAssistCost = 0
	processedCellIndexes = {}
	searchX = nil
	searchZ = nil
	enemyCells = self.enemyCells
	ownCells = self.ownCells
	friendlyCells = self.friendlyCells
	dangerCells = self.dangerCells
	
	-- if both start and end positions are close to base center, assume it's safe unless the target cell has been marked as dangerous
	if (sqDistance(startPos.x,self.basePos.x,startPos.z,self.basePos.z) < 1000000 and sqDistance(endPos.x,self.basePos.x,endPos.z,self.basePos.z) < 1000000) then
		xi, zi = getCellXZIndexesForPosition(startPos)
		local dangerCell = getCellFromTableIfExists(dangerCells,xi,zi)
		if dangerCell ~= nil then
			return false
		end
		xi, zi = getCellXZIndexesForPosition(endPos)
		dangerCell = getCellFromTableIfExists(dangerCells,xi,zi)
		if dangerCell ~= nil then
			return false
		end
		
		--log("position at x="..endPos.x.." z="..endPos.z.." is safe and close to base center",self.ai) --DEBUG
		return true
	end 
	
	-- check along the direction (assume units can go straight to it)
	-- TODO this will produce bad results if path is obstructed and a long detour is necessary
	for i=1,lineSearchPoints do
		searchX = (i/lineSearchPoints)*endPos.x + ((lineSearchPoints-i)/lineSearchPoints)*startPos.x 
		searchZ = (i/lineSearchPoints)*endPos.z + ((lineSearchPoints-i)/lineSearchPoints)*startPos.z

		xi, zi = getCellXZIndexesForPosition(newPosition(searchX,0,searchZ))
		if not (processedCellIndexes[xi] and processedCellIndexes[xi][zi]) then
			totalAssistCost = 0
			totalThreatCost = 0
			
			-- threathening enemies
			if enemyCells[xi] and enemyCells[xi][zi] then
				totalThreatCost = enemyCells[xi][zi].combinedThreatCost  
			end
		
			-- helpful allies
			if ownCells[xi] and ownCells[xi][zi] then
				totalAssistCost = totalAssistCost + ownCells[xi][zi].internalThreatCost
			end
			if friendlyCells[xi] and friendlyCells[xi][zi] then
				totalAssistCost = totalAssistCost + friendlyCells[xi][zi].internalThreatCost
			end
			
			-- unsafe situation detected, return false
			if (totalAssistCost < totalThreatCost) then
				return false
			end
			
			if (not processedCellIndexes[xi]) then
				processedCellIndexes[xi] = {}
			end
			processedCellIndexes[xi][zi] = 1
		end
	end
	
	return true
end



-- order unit behavior entries on the group according to the task set
function UnitHandler:doTargetting(group)
	-- log("recruits : "..tostring(#group.recruits),self.ai)
	local enemyUnitIds = self.ai.enemyUnitIds
	if enemyUnitIds == nil or tableLength(enemyUnitIds) == 0 then
		-- log("NO ENEMY UNITS FOUND",self.ai)
		return
	end
	local radius = 0
	
	-- air units are allowed to stray farther away from center
	if (group.id == UNIT_GROUP_AIR_ATTACKERS) then
		radius = FORCE_RADIUS_AIR * (1 + sqrt(#group.recruits/4))
	elseif (group.id == UNIT_GROUP_RAIDERS) then
		radius = FORCE_RADIUS_RAIDERS * (1 + sqrt(#group.recruits/8))
	else
		radius = FORCE_RADIUS * (1 + sqrt(#group.recruits/8))
	end
	
	local amphibiousRaiders = false
	local amphibiousMainForce = false
	local raidersAmphibious = false
	local mainForceAmphibious = false
	if (self.ai.useStrategies) then
		local currentStrategy = self.ai.currentStrategy
		local sStage = self.ai.currentStrategyStage
	
		local mult = currentStrategy.stages[sStage].properties.forceSpreadFactor
		if (mult and mult ~= 1) then
			radius = radius * mult
		end
		
		amphibiousRaiders = currentStrategy.stages[sStage].properties.amphibiousRaiders or false
		amphibiousMainForce = currentStrategy.stages[sStage].properties.amphibiousMainForce or false
		--log("group="..group.id.." radius="..radius,self.ai) --DEBUG
	end
	
	local task = group.task
	local tooSpreadOut = false
	--if (group.id == UNIT_GROUP_AIR_ATTACKERS) then
	--	log("AIR "..self.ai.id.." center="..group.nearCenterCost.." total="..group.totalCost.." TASK="..tostring(task),self.ai)
	--end
	if (group.totalCost > 2.0 * group.nearCenterCost) then
		tooSpreadOut = true
	end
	-- go all-in if engaging longer range units
	local allIn = false
	
	if (task == TASK_ATTACK or task == TASK_DEFEND) then
	
		-- if group is too spread out, converge to current center
		if (group.id == UNIT_GROUP_AIR_ATTACKERS and tooSpreadOut) then
			for i,recruit in ipairs(group.recruits) do
				if (not recruit.isSeriouslyDamaged ) then
					--Spring.MarkerAddPoint(group.centerPos.x,group.centerPos.y,group.centerPos.z,"REGROUP") --DEBUG
					
					if distance(recruit.pos,group.centerPos) < BIG_RADIUS then
						recruit:orderToPosition(group.centerPos,CMD.PATROL)
					else
						recruit:orderToPosition(group.centerPos,CMD.MOVE)
					end
				else
					-- retreat along raiding path
					recruit:orderToClosestCellAlongPath(self.raiderPath[PF_UNIT_AIR], {CMD.MOVE,CMD.MOVE}, true, true)
				end
			end
			return
		end
	
		local bestCell = group.targetCell
		local bestValue = group.targetValue
		local targetDefended = group.targetThreatAlongPath > 0

		-- if we have a cell then lets go attack it!
		if bestCell ~= nil then
			if group.avgRange < 1.1*bestCell.combinedAvgRange then
				--if (group.id == UNIT_GROUP_ATTACKERS) then
				--	log("attackers avgRange="..group.avgRange.." enemyAvgRange="..bestCell.combinedAvgRange.." : engage all-in",self.ai)
				--end
				allIn = true
			end
		
		
			local evade = false
			for i,recruit in ipairs(group.recruits) do
				-- if target is armed and unit is far from center of atk force, move to center
				-- else, attack the cell
				if (not targetDefended) or (not recruit:attackRegroupCenterIfNeeded(group.centerPos, radius)) then
					if (not recruit.isSeriouslyDamaged ) then
						evade = (not allIn) and (not self.isEasyMode) and #group.recruits < 200 and not recruit.canFly
						if not (evade and recruit:evadeIfNeeded()) then
							recruit:attackCell(group.centerPos, bestCell)
						end
					else
						if ( group.id == UNIT_GROUP_RAIDERS or group.id == UNIT_GROUP_AIR_ATTACKERS) then
							-- retreat along raiding path
							recruit:orderToClosestCellAlongPath(group.id == UNIT_GROUP_RAIDERS and self.raiderPath[amphibiousRaiders and PF_UNIT_AMPHIBIOUS or PF_UNIT_LAND] or self.raiderPath[PF_UNIT_AIR], CMD.MOVE, true, true)
						else
							recruit:avoidEnemyAndRetreat()
						end
					end	
				end
			end
		end
	elseif( task == TASK_RETREAT ) then
		for i,recruit in ipairs(group.recruits) do
			if(group.id == UNIT_GROUP_RAIDERS or group.id == UNIT_GROUP_AIR_ATTACKERS ) then
			

				if (not recruit.isSeriouslyDamaged ) then					
					-- advance along raiding path
					recruit:orderToClosestCellAlongPath(group.id == UNIT_GROUP_RAIDERS and self.raiderPath[amphibiousRaiders and PF_UNIT_AMPHIBIOUS or PF_UNIT_LAND] or self.raiderPath[PF_UNIT_AIR], {CMD.FIGHT,CMD.MOVE}, false, true)
				else
					-- retreat along raiding path
					recruit:orderToClosestCellAlongPath(group.id == UNIT_GROUP_RAIDERS and self.raiderPath[amphibiousRaiders and PF_UNIT_AMPHIBIOUS or PF_UNIT_LAND] or self.raiderPath[PF_UNIT_AIR], CMD.MOVE, true, true)
				end
			else
				if not recruit:attackRegroupCenterIfNeeded(group.centerPos, radius) then
					recruit:avoidEnemyAndRetreat()
				end
			end
		end
	-- default behavior (same as retreat, for now)
	else
		for i,recruit in ipairs(group.recruits) do
			if(group.id == UNIT_GROUP_RAIDERS or group.id == UNIT_GROUP_AIR_ATTACKERS) then

				if (not recruit.isSeriouslyDamaged ) then					
					-- advance along raiding path
					recruit:orderToClosestCellAlongPath(group.id == UNIT_GROUP_RAIDERS and self.raiderPath[amphibiousRaiders and PF_UNIT_AMPHIBIOUS or PF_UNIT_LAND] or self.raiderPath[PF_UNIT_AIR], {CMD.FIGHT,CMD.MOVE}, false, true)
				else
					-- retreat along raiding path
					recruit:orderToClosestCellAlongPath(group.id == UNIT_GROUP_RAIDERS and self.raiderPath[amphibiousRaiders and PF_UNIT_AMPHIBIOUS or PF_UNIT_LAND] or self.raiderPath[PF_UNIT_AIR], CMD.MOVE, true, true)
				end
			else
				if not recruit:attackRegroupCenterIfNeeded(group.centerPos, radius) then
					recruit:avoidEnemyAndRetreat()
				end
			end
		end
	end
end

-- detatch raiding party (move units above a given speed threshold to the land raiders group)
function UnitHandler:detachLandRaidingParty(movementSpeedThreshold)
	local unitCount = 0
	for i,v in ipairs(self.unitGroups[UNIT_GROUP_ATTACKERS].recruits) do
		
		-- move all units above a given movement speed threshold
		if (v.unitDef.speed > movementSpeedThreshold) then
			table.remove(self.unitGroups[UNIT_GROUP_ATTACKERS].recruits,i)
			table.insert(self.unitGroups[UNIT_GROUP_RAIDERS].recruits,v)
			unitCount = unitCount + 1
		end
	end
	--log("Moved "..unitCount.." units to the raiding party",self.ai)
end

-- reattach attacker party (move units below a given speed threshold to the land raiders group)
function UnitHandler:reattachRaidersToAttackers(movementSpeedThreshold)
	local unitCount = 0
	for i,v in ipairs(self.unitGroups[UNIT_GROUP_RAIDERS].recruits) do
		
		-- move all units below a given movement speed threshold
		if (v.unitDef.speed < movementSpeedThreshold) then
			table.remove(self.unitGroups[UNIT_GROUP_RAIDERS].recruits,i)
			table.insert(self.unitGroups[UNIT_GROUP_ATTACKERS].recruits,v)
			unitCount = unitCount + 1
		end
	end
	--log("Moved "..unitCount.." units to the raiding party",self.ai)
end

function UnitHandler:isRecruit(attkbehavior,gId)
	for i,v in ipairs(self.unitGroups[gId].recruits) do
		if v == attkbehavior then
			return true
		end
	end
	return false
end

function UnitHandler:addRecruit(attkbehavior, gId)
	if not self:isRecruit(attkbehavior, gId) then
		table.insert(self.unitGroups[gId].recruits,attkbehavior)
		attkbehavior:setMoveState()
	end
end

function UnitHandler:removeRecruit(attkbehavior, gId)
	for i,v in ipairs(self.unitGroups[gId].recruits) do
		if v.unitId == attkbehavior.unitId then
			--log(attkbehavior.unitId.." being removed from recruits",self.ai)
			table.remove(self.unitGroups[gId].recruits,i)
			return true
		end
	end
	return false
end


--------------------------------- RAIDER PATH DETERMINATION

-- init distances for pathing type (graph edges)
function UnitHandler:updateDistancesForPathingType(unitPathingType)
	local dist = {}
	
	local mapCellList = self.ai.mapHandler.mapCellList
	local mapCellsXZ =  self.ai.mapHandler.mapCells
	local pFCellsXZ =  self.ai.mapHandler.mapPFCells

	local threatCostReference = self.raiderThreatCostReference[unitPathingType]

	-- for each "edge", set distance
	local xIndex = 0
	local zIndex = 0
	local dxi, dzi = 0
	local val = 0
	local hasConnection = 0
	for i,cell in ipairs(mapCellList) do
		dist[i] = {}
	
		-- get nearby cells
		xIndex = cell.xIndex
		zIndex = cell.zIndex
		local enemyCell = getCellFromTableIfExists(self.enemyCells,xIndex,zIndex)
		for dxi = -1, 1 do
			for dzi = -1, 1 do
				if (dxi ~= 0 or dzi ~= 0) then
					xi = xIndex + dxi
					zi = zIndex + dzi
					
					-- ignore cells outside of map bounds
					if xi >=0 and xi < self.cellCountX and zi >=0 and zi < self.cellCountZ then
						otherCell = nil
						if (mapCellsXZ[xi]) then
							otherCell = mapCellsXZ[xi][zi]
						end
						if(otherCell ~= nil) then
							-- val depends on
							-- cell.region vs othercell.region
							-- cell.combinedThreatCost / 1500 ?
							
							-- terrain factor
							-- check PF cells along direction of other cell, if they're on the same region, there's a direct path
							if (unitPathingType == PF_UNIT_AIR) then
								hasConnection = true
							else
								hasConnection = self.ai.mapHandler:checkCellConnection(cell,otherCell,unitPathingType)
							end
							
							if (hasConnection) then
								-- check if there are enemies
								local otherEnemyCell = getCellFromTableIfExists(self.enemyCells,xi,zi) 
	
								if (dxi ~= 0 and dzi ~= 0) then
									val = 1.4  -- diagonals are longer						
								end
														
								if (enemyCell and otherEnemyCell) then
									val = val + (enemyCell.combinedThreatCost or 0) / threatCostReference + (otherEnemyCell.combinedThreatCost or 0) / threatCostReference
								elseif(enemyCell) then
									val = val + (enemyCell.combinedThreatCost or 0) / threatCostReference
								elseif(otherEnemyCell) then
									val = val + (otherEnemyCell.combinedThreatCost or 0) / threatCostReference
								end
								
								-- if other cell has no enemy armed coverage but has enemy units, go through it
								if ( otherEnemyCell and otherEnemyCell.cost > 0 and (not otherEnemyCell.combinedThreatCost or otherEnemyCell.combinedThreatCost ==0)) then
									val = 0.1
								end
							else
								val = INFINITY
							end
							
						
							dist[i][otherCell.index] = val 
							
							-- mark cost of moving to this adjacent cell (DEBUG)
							--Spring.MarkerAddPoint(0.9*cell.p.x + 0.1*otherCell.p.x,500,0.9*cell.p.z+0.1*otherCell.p.z,string.format("%.2f",val)) --DEBUG
						end
					end
				end
			end
		end
	end
	
	self.raiderPFDistances[unitPathingType] = dist
end

-- A-star path search between two cells, start and goal
-- uses preloaded table of distance between pairs
function UnitHandler:getAStarPath(unitPathingType,start,goal)
	local dist = self.raiderPFDistances[unitPathingType]
    local closedSet = {}    	  -- The set of nodes already evaluated.
    local openSet = {}    -- The set of tentative nodes to be evaluated, initially containing the start node
    local mapCellList = self.ai.mapHandler.mapCellList
    local mapCellsXZ =  self.ai.mapHandler.mapCells
    openSet[start.index] = true
    local cameFrom = {}    -- The map of navigated nodes.
 
    local gScore = {} -- initialized to infinity
    for i, cell in ipairs(mapCellList) do
    	gScore[i] = INFINITY
    end
    gScore[start.index] = 0    -- Cost from start along best known path.
    -- Estimated total cost from start to goal through y
    local fScore = {} -- initialized to infinity
    for i, cell in ipairs(mapCellList) do
    	fScore[i] = INFINITY
    end
    fScore[start.index] = gScore[start.index] + heuristicCostEstimate(start, goal)
     
    local lowestScore = INFINITY
	local xIndex = 0
	local zIndex = 0
	local dxi, dzi = 0
	local tentative_gScore = 0
	local current = nil
    while tableLength(openSet) > 0 do
    	current = nil
        lowestScore = INFINITY
        -- use the node in openSet having the lowest fScore[] value
        for i,_ in pairs(openSet) do
        	if  fScore[i] < lowestScore then
        		lowestScore = fScore[i]
        		current = mapCellList[i]
        	end 
        end
        
        if current == nil then
        	return nil
        end
        
        if current.index == goal.index then
            return self:reconstruct_path(cameFrom, goal)
        end
        
        openSet[current.index] = nil
        closedSet[current.index] = true

		tentative_gScore = 0
		-- get nearby cells
		xIndex = current.xIndex
		zIndex = current.zIndex
		for dxi = -1, 1 do
			for dzi = -1, 1 do
				xi = xIndex + dxi
				zi = zIndex + dzi
				-- ignore cells outside of map bounds
				if xi >=0 and xi < self.cellCountX and zi >=0 and zi < self.cellCountZ then
					otherCell = getCellFromTableIfExists(mapCellsXZ,xi,zi)
					if (otherCell ~= nil) then
			            if not closedSet[otherCell.index] then	
							tentative_gScore = gScore[current.index] + dist[current.index][otherCell.index]
		            		if not openSet[otherCell.index]	then -- Discover a new node
			                	openSet[otherCell.index] = true
	            			end 
	            			if tentative_gScore < gScore[otherCell.index] then
				        		-- This path is the best until now. Record it!
	            				cameFrom[otherCell.index] = current.index
	            				gScore[otherCell.index] = tentative_gScore
	            				fScore[otherCell.index] = gScore[otherCell.index] + heuristicCostEstimate(otherCell, goal)
							end
						end
					end
				end
			end
		end
	end
	
    return nil
end

function heuristicCostEstimate(start,goal)
	return (distance(start.p,goal.p) / CELL_SIZE)
end

function UnitHandler:reconstruct_path(cameFrom,current)
	local path = {}
    local reversePath = {current.index}
    while cameFrom[current.index] do
    	current = self.ai.mapHandler.mapCellList[cameFrom[current.index]]
    	reversePath[#reversePath+1] = current.index
    end
    
    local i = #reversePath
    for _,idx in ipairs(reversePath) do
    	path[i] = idx
    	i = i-1 
    end
    return path
end


----------------------- engine event handlers


function UnitHandler:UnitDamaged(unitId, unitDefId, unitTeamId, damage, paralyzer, weaponDefId, projectileId, attackerId, attackerDefId, attackerTeamId)
	-- own units are getting damage, mark cell with current frame
	if unitTeamId == self.ai.id and attackerTeamId ~= self.ai.id then
		local f = spGetGameFrame()
		local pos = newPosition(spGetUnitPosition(unitId))
		xIndex,zIndex = getCellXZIndexesForPosition(pos)
		if not self.dangerCells[xIndex] then
			self.dangerCells[xIndex] = {}
		end
		self.dangerCells[xIndex][zIndex] = f
		--log("DANGER cell at xi="..xIndex.." zi="..zIndex.." f="..f,self.ai) --DEBUG
	
		-- enemies are attacking our base, probably
		if (sqDistance(pos.x,self.basePos.x,pos.z,self.basePos.z) < BASE_DESPERATION_DEFENSE_THRESHOLD_SQDISTANCE) then
			self.baseUnderAttackFrame = f
		end
	end		
end



function UnitHandler:UnitCreated(uId,unitDefId,builderId)
	local ud = UnitDefs[unitDefId]
	if ud.isBuilding then
		local pos = newPosition(spGetUnitPosition(uId))

		-- register building id on all adjacent cells
		local cells = getAdjacentCellList(self.ownBuildingCells,pos)
		for _,cell in ipairs(cells) do
			cell.buildingIdSet[uId] = ud
		end
		
		self.ownBuildingUDefById[uId] = ud
	end
	
end

function UnitHandler:UnitDestroyed(uId,teamId,unitDefId)
	ud = UnitDefs[unitDefId]
	un = ud.name
	local thisAI = self.ai
	local cost = getWeightedCost(ud)
	
	if setContains(thisAI.alliedTeamIds,teamId) then
		self.latestAlliedLossesCost = self.latestAlliedLossesCost + cost
	end
	-- own units are dying
	if teamId == thisAI.id then
		
		-- remove building id from all adjacent cells
		if ud.isBuilding then
			local pos = newPosition(spGetUnitPosition(uId))
			local cells = getAdjacentCellList(self.ownBuildingCells,pos)
			for _,cell in ipairs(cells) do
				removeFromSet(cell.buildingIdSet,uId)
			end
			
			if self.ownBuildingUDefById[uId] then
				self.ownBuildingUDefById[uId] = nil
			end
		end 
	
		if (setContains(unitTypeSets[TYPE_ATTACKER],un)) then
			self.atkFailureCost = self.atkFailureCost + getWeightedCost(ud)
		end
		
		-- if enemies are attacking our base, defend!
		if (setContains(unitTypeSets[TYPE_BASE],un)) then
			self.baseUnderAttackFrame = spGetGameFrame()
		end

	-- enemies are dying
	elseif setContains(thisAI.enemyTeamIds,teamId) then
		self.latestEnemyLossesCost = self.latestEnemyLossesCost + getWeightedCost(ud)
	end
end


function UnitHandler:GameFrame(f)
	--if self.perfCounter > 0 then
	--	log("perfCounter was "..tostring(self.perfCounter),self.ai) 
	--end
	--self.perfCounter = 0
	
	-- slowly "forget" about attack failures 
	-- TODO no longer used, remove?
	if fmod(f,ATK_FAIL_TOLERANCE_FRAMES) == 0 then
		if self.atkFailureCost > 0 then 
			self.atkFailureCost = self.atkFailureCost - ATK_FAIL_TOLERANCE_COST
		end		
	end

	-- efficiency tracking
	if fmod(f,COMBAT_EFFICIENCY_HISTORY_STEP_FRAMES) == 0 then
		local kills = self.latestEnemyLossesCost
		local losses = self.latestAlliedLossesCost
		
		local steps = 0
		self.teamCombatEfficiencyHistory[#self.teamCombatEfficiencyHistory+1] = {kills,losses}

		local avgKills = 0
		local avgLosses = 0
		local avgEfficiency = 1
		for i=#self.teamCombatEfficiencyHistory,1,-1 do
			steps = steps +1
			avgKills = avgKills + self.teamCombatEfficiencyHistory[i][1]
			avgLosses = avgLosses + self.teamCombatEfficiencyHistory[i][2]
			if (steps >= COMBAT_EFFICIENCY_HISTORY_CHECK_STEPS) then
				break
			end
		end
		if (steps > 0 ) then
			avgKills = avgKills / steps
			avgLosses = avgLosses / steps
		end

		if avgKills > 0 and avgLosses > 0 then 
			avgEfficiency = avgKills / avgLosses
		elseif avgKills > 0 and avgLosses == 0 then
			avgEfficiency = math.huge
		elseif avgKills == 0 and avgLosses > 0 then
			avgEfficiency = 0
		elseif avgKills == 0 and avgLosses == 0 then
			avgEfficiency = 1			
		end
		
		--log("avgKills="..avgKills.." avgLosses="..avgLosses.." avgEfficiency="..avgEfficiency,self.ai) --DEBUG
		-- reset counters
		self.teamCombatEfficiency = avgEfficiency
		self.latestEnemyLossesCost = 0
		self.latestAlliedLossesCost = 0
	end
	
	--if fmod(f,400) == 0 then
	--	if self.ai.id ==0 then Spring.SendCommands("ClearMapMarks") end  --DEBUG
	--end
		
	local currentStrategy = self.ai.currentStrategy
	local currentStrategyName = self.ai.currentStrategyName
	local sStage = self.ai.currentStrategyStage
	
	-- load game status : own cells, friendly cells, enemy cells
	if fmod(f,199) == 0 + self.ai.frameShift then
		--if self.ai.id ==0 then Spring.SendCommands("ClearMapMarks") end  --DEBUG
	
		-- forget outdated danger cells, if any
		for xi,row in pairs(self.dangerCells) do
			for zi,lastFrame in pairs(row) do
				if f - lastFrame > DANGER_CELL_FORGET_FRAMES then
					--log("forgotten danger cell at xi="..xi.." zi="..zi,self.ai) --DEBUG
					row[zi] = nil
				end
			end
		end
		
		local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")
		local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(self.ai.id,"energy")

		-- log("M ("..currentLevelM.."): +"..incomeM.." -"..expenseM.."    E ("..currentLevelE.."): +"..incomeE.." -"..expenseE, self.ai) --DEBUG
		local baseX = 0
		local baseZ = 0
		local baseCount = 0
		
		local mexBuilderCount = 0
		local basePatrollerCount = 0
		local mexUpgraderCount = 0
		local defenseBuilderCount = 0
		local advancedDefenseBuilderCount = 0
		local attackPatrollerCount = 0
		local standardQueueCount = 0
		local advancedStandardQueueCount = 0
		
		-- update strategy stage (do this based on previously gathered state, shouldn't be an issue)
		local maxReachedStage = 1
		if (self.ai.useStrategies and f > 300) then

			-- check up to which stage are the preconditions met			
			for n,stage in ipairs(currentStrategy.stages) do
				
				local stageEco = stage.economy
				--Spring.Echo("STAGE n="..n.." minM="..stageEco.minMetalIncome)
				if incomeM > stageEco.minMetalIncome and incomeE > stageEco.minEnergyIncome then
					maxReachedStage = n
				end
			end
		end
		self.ai.currentStrategyStage = maxReachedStage
		--if (self.ai.useStrategies and f > 300) then
		--	log("MAX STAGE "..self.ai.currentStrategyStage,self.ai)	--DEBUG
		--end
		sStage = maxReachedStage
		
		-- update special role task queue counts
		for _,tq in pairs(self.taskQueues) do
			if (not tq.isDrone) then
				if ((not tq.isCommander) and tq.isMobileBuilder and tq.specialRole == 0) then
					if (tq.isAdvBuilder) then
						advancedStandardQueueCount = advancedStandardQueueCount + 1 
					else 
						standardQueueCount = standardQueueCount + 1
					end
				elseif (tq.specialRole == UNIT_ROLE_MEX_BUILDER) then
					 mexBuilderCount = mexBuilderCount + 1
				elseif (tq.specialRole == UNIT_ROLE_BASE_PATROLLER) then
					basePatrollerCount = basePatrollerCount + 1
				elseif (tq.specialRole == UNIT_ROLE_MEX_UPGRADER) then
					mexUpgraderCount = mexUpgraderCount + 1
				elseif (tq.specialRole == UNIT_ROLE_DEFENSE_BUILDER) then
					defenseBuilderCount = defenseBuilderCount + 1
				elseif (tq.specialRole == UNIT_ROLE_ADVANCED_DEFENSE_BUILDER) then
					advancedDefenseBuilderCount = advancedDefenseBuilderCount + 1
				elseif (tq.specialRole == UNIT_ROLE_ATTACK_PATROLLER) then
					attackPatrollerCount = attackPatrollerCount + 1
				end
			end
		end
		self.standardQueueCount = standardQueueCount
		self.advancedStandardQueueCount = advancedStandardQueueCount
		self.mexBuilderCount = mexBuilderCount
		self.basePatrollerCount = basePatrollerCount
		self.mexUpgraderCount = mexUpgraderCount
		self.defenseBuilderCount = defenseBuilderCount
		self.advancedDefenseBuilderCount = advancedDefenseBuilderCount 
		self.attackPatrollerCount = attackPatrollerCount
		-- Spring.Echo("builders for AI "..self.ai.id.." std="..standardQueueCount.." advstd="..advancedStandardQueueCount.." mex="..mexBuilderCount.." baseptl="..basePatrollerCount.." atkptl="..attackPatrollerCount.." mexupg="..mexUpgraderCount.." def="..defenseBuilderCount.." advdef="..advancedDefenseBuilderCount) --DEBUG


		self.attackerCount = 0
		self.airAttackerCount = 0
		self.seaAttackerCount = 0
		self.mobileCount = 0
		
		-- update targets based on economy size
		-- check if there are spots available
		local capturedMetalFraction = (self.ai.unitHandler.enemyExtractorCount + self.ai.unitHandler.friendlyExtractorCount) / #self.ai.mapHandler.spots
		if( capturedMetalFraction > FREE_METAL_SPOT_EXPANSION_THRESHOLD ) then
			self.mexBuilderCountTarget = 0
		else 
			self.mexBuilderCountTarget = self.ai.mapHandler.isMetalMap and 1 or max(floor(2.5*(1-capturedMetalFraction)),1)
		end
		self.basePatrollerCountTarget = max(1 + floor(incomeM / 40),1)
		self.mexUpgraderCountTarget = self.ai.mapHandler.isMetalMap and 0 or 1
		self.defenseBuilderCountTarget = max(0 + floor((incomeM) / 40),1)
		self.advancedDefenseBuilderCountTarget = max(0 + floor(incomeM / 50),0)
		self.attackPatrollerCountTarget = max(0 + floor((15+incomeM) / 30),2)
		
		-- make sure at least a few builders have the standard queue
		local standardQueueMin = 2
		local advancedStandardQueueMin = 1
		if (standardQueueCount < standardQueueMin) then
			--Spring.Echo(f.." "..standardQueueCount.." std builders is below min!") --DEBUG
			self.basePatrollerCountTarget = 0
			self.mexUpgraderCountTarget = 0
			self.defenseBuilderCountTarget = 0
			self.advancedDefenseBuilderCountTarget = 0
			self.attackPatrollerCountTarget = 0
		end
		if (advancedStandardQueueCount < advancedStandardQueueMin) then
			--Spring.Echo(f.." "..advancedStandardQueueCount.." ADV std builders is below min!") --DEBUG
			self.mexUpgraderCountTarget = 0
			self.advancedDefenseBuilderCountTarget = 0
		end		
		--if self.isBrutalMode then
		--	self.basePatrollerCountTarget = max(self.basePatrollerCountTarget-1,1)
		--	self.mexUpgraderCountTarget = max(self.mexUpgraderCountTarget-1,1)
		--	self.defenseBuilderCountTarget = max(self.defenseBuilderCountTarget-1,1)
		--	self.advancedDefenseBuilderCountTarget = max(self.advancedDefenseBuilderCountTarget-1,1)
		--	self.attackPatrollerCountTarget = max(self.attackPatrollerCountTarget-1,1)
		--end 

		-- use strategy based targets
		if (self.ai.useStrategies) then
			local bRoles = currentStrategy.stages[sStage].builderRoles
			if (bRoles) then
				if (bRoles.mexBuilders) then
					self.mexBuilderCountTarget = bRoles.mexBuilders
				end
				if (bRoles.basePatrollers) then
					self.basePatrollerCountTarget = bRoles.basePatrollers
				end
				if (bRoles.defenseBuilders) then
					self.defenseBuilderCountTarget = bRoles.defenseBuilders
				end
				if (bRoles.attackPatrollers) then
					self.attackPatrollerCountTarget = bRoles.attackPatrollers
				end
				if (bRoles.mexUpgraders) then
					self.mexUpgraderCountTarget = bRoles.mexUpgraders
				end
				if (bRoles.advancedDefenseBuilders) then
					self.advancedDefenseBuilderCountTarget = bRoles.advancedDefenseBuilders
				end
			end
		end

		-- update base and atk forces location
		local ownUnitIds = self.ai.ownUnitIds
		local friendlyUnitIds = self.ai.friendlyUnitIds
		local enemyUnitIds = self.ai.enemyUnitIds
		local unitCount = 0
		local friendlyExtractorCount = 0
		local enemyExtractorCount = 0
		local avgPos = newPosition()
		local ownUnitCount = 0
		local ownArmedMobilesWeightedCost = 0
		local friendlyArmedMobilesWeightedCost = 0
		local enemyArmedWeightedCost = 1
				
		-- TODO : put cell loading into a separate function
		-- iterate through own units : general
		local cell = nil
		local ownCells = {}
		local ownCellList = {}
		local ud = nil
		local tmpName = nil
		local hasWeapons = false
		local cost = 0
		for uId,_ in pairs(ownUnitIds) do
			local pos = newPosition(spGetUnitPosition(uId,false,false))
			ud = UnitDefs[spGetUnitDefID(uId)]
			tmpName = ud.name
			hasWeapons = #ud.weapons > 0 and (not fakeWeaponUnits[tmpName])
			cost = getWeightedCostByName(tmpName)
			local xIndex, zIndex = getCellXZIndexesForPosition(pos)
			--if (xIndex ~= xIndex) then  -- NaN ! Hohenheim v3 is buggy, ignore it
			--	local x,y,z = spGetUnitPosition(uId,false,false)
			--	log("Error getting indexes for own cell at pos=".."("..x..";"..z..") ".." unit="..tmpName,self.ai)
			--end
			
			-- check base
			if setContains(unitTypeSets[TYPE_PLANT],tmpName) then
				baseCount = baseCount + 1
				baseX = baseX + pos.x
				baseZ = baseZ + pos.z
			end
			self.baseCount = baseCount
			
			-- log("friendly cell at ".."("..xIndex..";"..zIndex..")",self.ai)  --DEBUG
			if ownCells[xIndex] == nil then
				ownCells[xIndex] = {}
			end
			if ownCells[xIndex][zIndex] == nil then
				local newCell = initUnitCell()
				newCell.xIndex = xIndex
				newCell.zIndex = zIndex
				newCell.p.x = xIndex*CELL_SIZE+CELL_SIZE/2
				newCell.p.z = zIndex*CELL_SIZE+CELL_SIZE/2
				ownCells[xIndex][zIndex] = newCell
				table.insert(ownCellList,newCell)
			end
			cell = ownCells[xIndex][zIndex]
			
			if setContains(unitTypeSets[TYPE_EXTRACTOR],tmpName) then
				cost = cost * ENEMY_EXTRACTOR_COST_FACTOR
				cell.extractorCount = cell.extractorCount + 1
			end
			
			if (pos.y < UNDERWATER_THRESHOLD ) then
				cell.underWaterCost = cell.underWaterCost + cost				
			end
			if setContains(unitTypeSets[TYPE_AIR_ATTACKER],tmpName) then
				cell.airAttackerCost = cell.airAttackerCost + cost
				self.airAttackerCount = self.airAttackerCount + 1 
				ownArmedMobilesWeightedCost = ownArmedMobilesWeightedCost + cost / 2
			elseif hasWeapons and ud.canMove then
				cell.attackerCost = cell.attackerCost + cost
				self.attackerCount = self.attackerCount + 1
				ownArmedMobilesWeightedCost = ownArmedMobilesWeightedCost + cost
			elseif hasWeapons then
				cell.defenderCost = cell.defenderCost + cost
				if setContains(unitTypeSets[TYPE_UW_DEFENSE],tmpName) then
					cell.underwaterDefenderCost = cell.underwaterDefenderCost + cost
				end
				cell.buildingCount = cell.buildingCount + 1
			elseif not ud.canMove then
				cell.economyCost = cell.economyCost + cost
				cell.buildingCount = cell.buildingCount + 1
			end
			
			-- if unit is strategic, assume it is worth twice as much
			if setContains(unitTypeSets[TYPE_STRATEGIC], tmpName) then
				cost = cost * ENEMY_STRATEGIC_COST_FACTOR
			end
			cell.cost = cell.cost + cost
			
			-- update global average position
			avgPos.x = avgPos.x + pos.x
			avgPos.z = avgPos.z + pos.z
			ownUnitCount = ownUnitCount + 1
			if (ud.canMove and (not ud.isBuilding)) then
				self.mobileCount = self.mobileCount + 1
			end
		end
		self.ownCells = ownCells
		self.ownCellList = ownCellList
		self.mostVulnerableCell = ownCellList[1]
		self.leastVulnerableCell = ownCellList[1]
		self.closestToBaseCenterCell = ownCellList[1]
		
		if ownUnitCount > 0 then
			avgPos.x = avgPos.x / ownUnitCount
			avgPos.z = avgPos.z / ownUnitCount
		end
		if baseCount > 0 then
			baseX = baseX / baseCount
			baseZ = baseZ / baseCount

			self.basePos.x = baseX
			self.basePos.z = baseZ
		else
			self.basePos.x = avgPos.x
			self.basePos.z = avgPos.z
		end
		self.basePos.y = spGetGroundHeight(self.basePos.x,self.basePos.z)
		--Spring.MarkerAddPoint(self.basePos.x,self.basePos.y,self.basePos.z,"BASE") --DEBUG
		
		-- log("base center ("..baseCount..") : ("..baseX..";"..baseZ..")",self.ai) --DEBUG
		-- get closest to base center cell
		local bestDistance = INFINITY
		for _,cell in ipairs(self.ownCellList) do
			local bd = distance(cell.p,self.basePos)  
			if ( bd < bestDistance) then
				self.closestToBaseCenterCell = cell	
			end
			cell.baseDistance = bd
		end

		-- load nearby cell data for each cell
		local xi = 0
		local zi = 0
		local cellCheckRadius = 1
		for i=1,#ownCellList do
			local cell = ownCellList[i]
			local mapCell = nil 
			if self.ai.mapHandler.mapCells[cell.xIndex] and self.ai.mapHandler.mapCells[cell.xIndex][cell.zIndex] then
				mapCell = self.ai.mapHandler.mapCells[cell.xIndex][cell.zIndex]
			end
			-- check nearby cells
			for dxi = -cellCheckRadius, cellCheckRadius do
				for dzi = -cellCheckRadius, cellCheckRadius do
					xi = cell.xIndex + dxi
					zi = cell.zIndex + dzi
					if (xi >=0) and (zi >= 0) and not (dxi == 0 and dzi == 0) then
						if ownCells[xi] then
							local nearbyCell = ownCells[xi][zi]
							if nearbyCell then
								cell.nearbyAttackerCost = cell.nearbyAttackerCost + nearbyCell.attackerCost
								cell.nearbyAirAttackerCost = cell.nearbyAirAttackerCost + nearbyCell.airAttackerCost
								cell.nearbyDefenderCost = cell.nearbyDefenderCost + nearbyCell.defenderCost
								cell.nearbyUnderwaterDefenderCost = cell.nearbyUnderwaterDefenderCost + nearbyCell.underwaterDefenderCost
								cell.nearbyCost = cell.nearbyCost + nearbyCell.cost
								cell.nearbyEconomyCost = cell.nearbyEconomyCost + nearbyCell.economyCost
							end
						end
					end
				end
			end

			-- add combined and internal threat cost
			cell.combinedThreatCost = getCombinedThreatCost(cell)
			cell.internalThreatCost = getInternalThreatCost(cell)
		end
		-- check end game focus-on-army condition
		self.focusOnEndGameArmy = false
		if (ownUnitCount > Game.maxUnits*END_GAME_ARMY_UNIT_CAP_THRESHOLD ) then
			if (self.mobileCount < Game.maxUnits*END_GAME_ARMY_MOBILE_RATIO_THRESHOLD ) then
				self.focusOnEndGameArmy = true

				-- override builder roles
				self.mexBuilderCountTarget = 0
				self.basePatrollerCountTarget = basePatrollerCountTarget +1
				self.mexUpgraderCountTarget = 0
				self.defenseBuilderCountTarget = 0
				self.advancedDefenseBuilderCountTarget = 0
				self.attackPatrollerCountTarget = self.attackPatrollerCountTarget +1 
			end
		end
		
		-- iterate through friendly units
		local friendlyCells = {}
		local friendlyCellList = {}
		for uId,_ in pairs(friendlyUnitIds) do
			local pos = newPosition(spGetUnitPosition(uId,false,false))
			ud = UnitDefs[spGetUnitDefID(uId)]
			tmpName = ud.name
			local hasWeapons = #ud.weapons > 0
			local cost = getWeightedCostByName(tmpName)
			local xIndex, zIndex = getCellXZIndexesForPosition(pos)
			
			-- log("friendly cell at ".."("..xIndex..";"..zIndex..")",self.ai)  --DEBUG
			if friendlyCells[xIndex] == nil then
				friendlyCells[xIndex] = {}
			end
			if friendlyCells[xIndex][zIndex] == nil then
				local newCell = initUnitCell()
				newCell.xIndex = xIndex
				newCell.zIndex = zIndex
				newCell.p.x = xIndex*CELL_SIZE+CELL_SIZE/2
				newCell.p.z = zIndex*CELL_SIZE+CELL_SIZE/2
				friendlyCells[xIndex][zIndex] = newCell
				table.insert(friendlyCellList,newCell)
			end
			cell = friendlyCells[xIndex][zIndex]
			
			if setContains(unitTypeSets[TYPE_EXTRACTOR],tmpName) then
				cost = cost * ENEMY_EXTRACTOR_COST_FACTOR
				cell.extractorCount = cell.extractorCount + 1
			end
			
			if (pos.y < UNDERWATER_THRESHOLD ) then
				cell.underWaterCost = cell.underWaterCost + cost				
			end
			if setContains(unitTypeSets[TYPE_AIR_ATTACKER],tmpName) then
				cell.airAttackerCost = cell.airAttackerCost + cost
				friendlyArmedMobilesWeightedCost = friendlyArmedMobilesWeightedCost + cost / 2
			elseif hasWeapons and ud.canMove then
				cell.attackerCost = cell.attackerCost + cost
				friendlyArmedMobilesWeightedCost = friendlyArmedMobilesWeightedCost + cost
			elseif hasWeapons then
				cell.defenderCost = cell.defenderCost + cost
				if setContains(unitTypeSets[TYPE_UW_DEFENSE],tmpName) then
					cell.underwaterDefenderCost = cell.underwaterDefenderCost + cost
				end
				cell.buildingCount = cell.buildingCount + 1 
			elseif not ud.canMove then
				cell.economyCost = cell.economyCost + cost
				cell.buildingCount = cell.buildingCount + 1
			end
			
			-- if unit is strategic, assume it is worth twice as much
			if setContains(unitTypeSets[TYPE_STRATEGIC], tmpName) then
				cost = cost * ENEMY_STRATEGIC_COST_FACTOR
			end
			cell.cost = cell.cost + cost
		end
		self.friendlyCells = friendlyCells
		self.friendlyCellList = friendlyCellList
		
		-- load nearby cell data for each cell
		xi = 0
		zi = 0
		cellCheckRadius = 1
		for i=1,#friendlyCellList do
			local cell = friendlyCellList[i]
			-- check nearby cells
			for dxi = -cellCheckRadius, cellCheckRadius do
				for dzi = -cellCheckRadius, cellCheckRadius do
					xi = cell.xIndex + dxi
					zi = cell.zIndex + dzi
					if (xi >=0) and (zi >= 0) and not (dxi == 0 and dzi == 0) then
						if friendlyCells[xi] then
							local nearbyCell = friendlyCells[xi][zi]
							if nearbyCell then
								cell.nearbyAttackerCost = cell.nearbyAttackerCost + nearbyCell.attackerCost
								cell.nearbyAirAttackerCost = cell.nearbyAirAttackerCost + nearbyCell.airAttackerCost
								cell.nearbyDefenderCost = cell.nearbyDefenderCost + nearbyCell.defenderCost
								cell.nearbyUnderwaterDefenderCost = cell.nearbyUnderwaterDefenderCost + nearbyCell.nearbyUnderwaterDefenderCost
								cell.nearbyCost = cell.nearbyCost + nearbyCell.cost
								cell.nearbyEconomyCost = cell.nearbyEconomyCost + nearbyCell.economyCost
							end
						end
					end
				end
			end
			
			-- add combined and internal threat cost
			cell.combinedThreatCost = getCombinedThreatCost(cell)
			cell.internalThreatCost = getInternalThreatCost(cell)
		end
	
		-- get friendly metal extractor count
		if friendlyUnitIds ~= nil then
			for uId,_ in pairs(friendlyUnitIds) do
				if setContains(unitTypeSets[TYPE_EXTRACTOR],UnitDefs[spGetUnitDefID(uId)].name) then
					friendlyExtractorCount = friendlyExtractorCount + 1
				end			
			end
		end
		
		-- update enemy cell data (these are cost totals not unit counts)
		local enemyAttackers = 0
		local enemyAssaults = 0
		local enemyAirAttackers = 0
		local enemyDefenders = 0
		local enemyArmedUnits = 0
		local enemyUnderwaterCost = 0
		if enemyUnitIds ~= nil then
			local cell = nil
			local cells = {}
			local cellList = {}
			
			-- figure out where all the enemies are!
			-- count costs instead of unit numbers
			for eId,_ in pairs (enemyUnitIds) do
				ud = UnitDefs[spGetUnitDefID(eId)]
				local tmpName = ud.name
				if (not neutralUnits[tmpName]) then
					local hasWeapons = #ud.weapons > 0 and (not fakeWeaponUnits[tmpName])
					local cost = getWeightedCostByName(tmpName)
					local health,maxHealth,_,_,progress = spGetUnitHealth(eId) 
					local isSubmerged = false
					progress = progress or 1
					
	
					-- count every enemy unit
					pos = newPosition(spGetUnitPosition(eId,false,false))
					local xIndex, zIndex = getCellXZIndexesForPosition(pos)
					
					-- log("enemy cell at ".."("..xIndex..";"..zIndex..")",self.ai)  --DEBUG
					if cells[xIndex] == nil then
						cells[xIndex] = {}
					end
					if cells[xIndex][zIndex] == nil then
						local newCell = initUnitCell()
						newCell.xIndex = xIndex
						newCell.zIndex = zIndex
						newCell.p.x = xIndex*CELL_SIZE+CELL_SIZE/2
						newCell.p.z = zIndex*CELL_SIZE+CELL_SIZE/2
						cells[xIndex][zIndex] = newCell
						table.insert(cellList,newCell)
					end
					cell = cells[xIndex][zIndex]
				
					if (pos.y < UNDERWATER_THRESHOLD ) then
						isSubmerged = true
						if (progress > 0.85) then
							enemyUnderwaterCost = enemyUnderwaterCost + cost						
						end
					end
					if setContains(unitTypeSets[TYPE_EXTRACTOR],tmpName) then
						cost = cost * ENEMY_EXTRACTOR_COST_FACTOR
						cell.extractorCount = cell.extractorCount + 1
					end
	
					if progress > 0.85 and setContains(unitTypeSets[TYPE_AIR_ATTACKER],tmpName) then
						cell.airAttackerCost = cell.airAttackerCost + cost
						enemyArmedUnits = enemyArmedUnits + cost
						enemyAirAttackers = enemyAirAttackers + cost
						enemyArmedWeightedCost = enemyArmedWeightedCost + cost * AIR_ATTACKER_EVALUATION_FACTOR
						if (self.badAAUnitNames[tmpName]) then
							cell.badAAAirAttackerCost = cell.badAAAirAttackerCost + cost
						end
						cell.combinedAvgHpCostRatio = cell.combinedAvgHpCostRatio + maxHealth  -- cost*hp/cost
						cell.combinedAvgRange = cell.combinedAvgRange + cost*ud.maxWeaponRange
						cell.combinedAvgSpeed = cell.combinedAvgSpeed + cost*ud.speed
						cell.combinedAvgRefCost = cell.combinedAvgRefCost + cost
					elseif progress > 0.85 and hasWeapons and ud.canMove then
						cell.attackerCost = cell.attackerCost + cost
						enemyArmedUnits = enemyArmedUnits + cost
						enemyAttackers = enemyAttackers + cost
						enemyArmedWeightedCost = enemyArmedWeightedCost + cost
						if (maxHealth/cost > ASSAULT_HEALTH_COST_RATIO and ud.speed > ASSAULT_SPEED_THRESHOLD) then
							enemyAssaults = enemyAssaults + cost
						end
						if (self.badAAUnitNames[tmpName]) then
							cell.badAAAttackerCost = cell.badAAAttackerCost + cost
						end
						cell.combinedAvgHpCostRatio = cell.combinedAvgHpCostRatio + maxHealth  -- cost*hp/cost
						cell.combinedAvgRange = cell.combinedAvgRange + cost*ud.maxWeaponRange
						cell.combinedAvgSpeed = cell.combinedAvgSpeed + cost*ud.speed
						cell.combinedAvgRefCost = cell.combinedAvgRefCost + cost
					elseif progress > 0.85 and hasWeapons then
						cell.defenderCost = cell.defenderCost + cost
						enemyArmedUnits = enemyArmedUnits + cost
						enemyDefenders = enemyDefenders + cost
						enemyArmedWeightedCost = enemyArmedWeightedCost + cost
						if (self.badAAUnitNames[tmpName]) then
							cell.badAADefenderCost = cell.badAADefenderCost + cost
						end
						cell.buildingCount = cell.buildingCount + 1
						cell.combinedAvgHpCostRatio = cell.combinedAvgHpCostRatio + maxHealth  -- cost*hp/cost
						cell.combinedAvgRange = cell.combinedAvgRange + cost*ud.maxWeaponRange
						cell.combinedAvgRefCost = cell.combinedAvgRefCost + cost
					elseif progress > 0.85 and (not ud.canMove or setContains(unitTypeSets[TYPE_ECONOMY],tmpName) ) then
						cell.economyCost = cell.economyCost + cost
						cell.buildingCount = cell.buildingCount + 1
					end
					-- add extra threat value
					if extraThreatValue[tmpName] then
						cell.attackerCost = cell.attackerCost + extraThreatValue[tmpName]
					end
					
					-- if unit is strategic, assume it is worth twice as much
					if setContains(unitTypeSets[TYPE_STRATEGIC], tmpName) then
						cost = cost * ENEMY_STRATEGIC_COST_FACTOR
					end
					
					if (isSubmerged) then
						cell.underWaterCost = cell.underWaterCost + cost
					end
					cell.cost = cell.cost + cost
					
					-- target the unit's position instead of the center of the cell
					cell.p.x = pos.x
					cell.p.z = pos.z
				end
			end
			
				
			-- load nearby cell data for each cell
			-- use map cells as empty cells may have nearby threat data
			-- if they do, add them as relevant enemy cells
			local mapCellList = self.ai.mapHandler.mapCellList
			local dxi = 0
			local dzi = 0
			local xi = 0
			local zi = 0
			local xIndex = 0
			local zIndex = 0
			local nearbyDistanceFactor = 1
			for i=1,#mapCellList do
				local mapCell = mapCellList[i]
				local enemyCell = getCellFromTableIfExists(cells,mapCell.xIndex,mapCell.zIndex)
				dxi = 0
				dzi = 0
				xIndex = mapCell.xIndex
				zIndex = mapCell.zIndex
						
				-- check nearby cells
				for dxi = -2, 2 do
					for dzi = -2, 2 do
						xi = xIndex + dxi
						zi = zIndex + dzi
						
						if (xi >=0) and (zi >= 0) and not (dxi == 0 and dzi == 0) and (xi < self.cellCountX) and (zi < self.cellCountZ)  then
							nearbyDistanceFactor = 1 / sqrt(dxi*dxi + dzi*dzi)
							
							if cells[xi] then
								local nearbyCell = cells[xi][zi]
								if nearbyCell and nearbyCell.cost > 0 then
									-- if there's nearby enemy stuff, but enemy cell not registered, create it 
									if enemyCell == nil then
										if cells[xIndex] == nil then
											cells[xIndex] = {}
										end
										if cells[xIndex][zIndex] == nil then
											enemyCell = initUnitCell()
											enemyCell.xIndex = xIndex
											enemyCell.zIndex = zIndex
											enemyCell.p.x = mapCell.p.x
											enemyCell.p.z = mapCell.p.z
											cells[xIndex][zIndex] = enemyCell
											table.insert(cellList,enemyCell)
										end
									end
								
									enemyCell.nearbyAttackerCost = enemyCell.nearbyAttackerCost + nearbyCell.attackerCost * nearbyDistanceFactor
									enemyCell.nearbyAirAttackerCost = enemyCell.nearbyAirAttackerCost + nearbyCell.airAttackerCost * nearbyDistanceFactor
									enemyCell.nearbyDefenderCost = enemyCell.nearbyDefenderCost + nearbyCell.defenderCost * nearbyDistanceFactor
									enemyCell.nearbyBadAAAttackerCost = enemyCell.nearbyBadAAAttackerCost + nearbyCell.badAAAttackerCost * nearbyDistanceFactor
									enemyCell.nearbyBadAAAirAttackerCost = enemyCell.nearbyBadAAAirAttackerCost + nearbyCell.badAAAirAttackerCost * nearbyDistanceFactor
									enemyCell.nearbyBadAADefenderCost = enemyCell.nearbyBadAADefenderCost + nearbyCell.badAADefenderCost * nearbyDistanceFactor

									enemyCell.combinedAvgHpCostRatio = enemyCell.combinedAvgHpCostRatio + nearbyCell.combinedAvgHpCostRatio
									enemyCell.combinedAvgRange = enemyCell.combinedAvgRange + nearbyCell.combinedAvgRange
									enemyCell.combinedAvgSpeed = enemyCell.combinedAvgSpeed + nearbyCell.combinedAvgSpeed
									enemyCell.combinedAvgRefCost = enemyCell.combinedAvgRefCost + nearbyCell.combinedAvgRefCost
								end
							end
						end
					end
				end

				if enemyCell then
					-- add combined and internal threat cost
					enemyCell.combinedThreatCost = getCombinedThreatCost(enemyCell)
					enemyCell.internalThreatCost = getInternalThreatCost(enemyCell)
					enemyCell.combinedThreatCostExcludingBadAA = getCombinedThreatCostExcludingBadAA(enemyCell)
					enemyCell.internalThreatCostExcludingBadAA = getInternalThreatCostExcludingBadAA(enemyCell)

					if (enemyCell.combinedAvgRefCost > 0) then
						enemyCell.combinedAvgHpCostRatio = enemyCell.combinedAvgHpCostRatio/enemyCell.combinedAvgRefCost
						enemyCell.combinedAvgRange = enemyCell.combinedAvgRange/enemyCell.combinedAvgRefCost
						enemyCell.combinedAvgSpeed = enemyCell.combinedAvgSpeed/enemyCell.combinedAvgRefCost
					end
				end
			end
			
			-- load distances to center of base for each cell
			-- if enemy cluster close to base, assume base under attack
			-- log("enemy cells:",self.ai)
			for i=1,#cellList do
				local cell = cellList[i]
				cell.baseDistance = distance(cell.p,self.basePos) or INFINITY
				
				-- log("enemy cell at indexes ( "..cell.xIndex.." ; "..cell.zIndex.." )",self.ai)
				
				if(cell.internalThreatCost > 0 and cell.baseDistance < BASE_UNDER_ATTACK_RADIUS and cell.combinedThreatCost > 1200) then
					self.baseUnderAttack = true
					self.baseUnderAttackFrame = f
				end
			end
			
			-- update cell list
			self.enemyCellList = cellList
			self.enemyCells = cells
		end
		
		--[[		
		if self.ai.id == 0 then
			Spring.SendCommands("ClearMapMarks") --DEBUG
			if self.enemyCells then 
				for i=1,#self.enemyCellList do
					local cell = self.enemyCellList[i]
					Spring.MarkerAddPoint(cell.p.x,spGetGroundHeight(cell.p.x,cell.p.z),cell.p.z,"Value="..string.format("%2f", cell.combinedThreatCost)) --DEBUG
				end	
			end
		end
		]]--
		
		self.enemyExtractorCount = enemyExtractorCount
		self.friendlyExtractorCount = friendlyExtractorCount
		
		-- update threat type 
		if ( enemyAirAttackers / enemyArmedUnits > THREAT_AIR_THRESHOLD ) then
			self.threatType = THREAT_AIR
		elseif ( enemyUnderwaterCost / enemyArmedUnits > THREAT_UNDERWATER_THRESHOLD ) then
			self.threatType = THREAT_UNDERWATER
		elseif ( enemyAssaults / enemyArmedUnits > THREAT_ASSAULT_THRESHOLD ) then
			self.threatType = THREAT_ASSAULT
		elseif ( enemyDefenders / enemyArmedUnits > THREAT_DEFENSE_THRESHOLD ) then
			self.threatType = THREAT_DEFENSE
		else
			self.threatType = THREAT_NORMAL
		end
		--self.ai:messageAll("THREAT="..self.threatType) 
		
		-- calculate overall force advantage factor
		self.perceivedTeamAdvantageFactor = (ownArmedMobilesWeightedCost + friendlyArmedMobilesWeightedCost ) / enemyArmedWeightedCost
		--log("perceived adv factor : "..self.perceivedTeamAdvantageFactor, self.ai)
		if not self.ai.useStrategies and self.perceivedTeamAdvantageFactor > ALL_IN_ADVANTAGE_THRESHOLD then 
			self.allIn = true
			--log("team "..self.ai.id.." is going ALL IN! ("..self.perceivedTeamAdvantageFactor..")",self.ai)
		else
			self.allIn = false
			--log("team "..self.ai.id.." is being careful... ("..self.perceivedTeamAdvantageFactor..")",self.ai)		
		end
		
		-- load cell vulnerability
		-- detect most and least vulnerable own cells
		local mostVulnerableCell = self.closestToBaseCenterCell
		local leastVulnerableCell = self.closestToBaseCenterCell
		local highestValue = -INFINITY
		local lowestValue = INFINITY
		local thresholdDistance = BASE_VULNERABILITY_THRESHOLD_DISTANCE * (1 + incomeM / 50)
		for i=1,#self.ownCellList do
			local cell = self.ownCellList[i]
			local value = self:getCellVulnerability(cell)
			cell.vulnerability = value
			
			-- only track cells within threshold distance
			if (cell.baseDistance < thresholdDistance) then
				-- value = BASE_VULNERABILITY_THRESHOLD_FACTOR * value
							
				if value > highestValue then
					mostVulnerableCell = cell
					highestValue = value
				end
				if value < lowestValue then
					leastVulnerableCell = cell
					lowestValue = value
				end
			end
		end
		self.mostVulnerableCell = mostVulnerableCell
		self.leastVulnerableCell = leastVulnerableCell
		--if self.ai.id == 2 then log("safeCell ( "..leastVulnerableCell.p.x.." ; "..leastVulnerableCell.p.z .." ) vulnerableCell ( "..mostVulnerableCell.p.x.." ; "..mostVulnerableCell.p.z.." )", self.ai) end --DEBUG
		--if self.ai.id == 0 then
		--	Spring.SendCommands("ClearMapMarks")
		--	Spring.MarkerAddPoint(leastVulnerableCell.p.x,500,leastVulnerableCell.p.z,"SAFE") --DEBUG
		--	Spring.MarkerAddPoint(mostVulnerableCell.p.x,500,mostVulnerableCell.p.z,"VULNERABLE") --DEBUG
		--end
		self.collectedData = true
	end
	
	-- update raiding paths for ground and air units
	if fmod(f,159) == 32 + self.ai.frameShift then
		self.raiderThreatCostReference[PF_UNIT_LAND] = self.unitGroups[UNIT_GROUP_RAIDERS] and self.unitGroups[UNIT_GROUP_RAIDERS].nearCenterCost/2 or 100
		self.raiderThreatCostReference[PF_UNIT_AMPHIBIOUS] = self.unitGroups[UNIT_GROUP_RAIDERS] and self.unitGroups[UNIT_GROUP_RAIDERS].nearCenterCost/2 or 100
		self.raiderThreatCostReference[PF_UNIT_AIR] = self.unitGroups[UNIT_GROUP_AIR_ATTACKERS] and self.unitGroups[UNIT_GROUP_AIR_ATTACKERS].nearCenterCost/2 or 100
		
		self:updateDistancesForPathingType(PF_UNIT_LAND)
		self:updateDistancesForPathingType(PF_UNIT_AMPHIBIOUS)
		self:updateDistancesForPathingType(PF_UNIT_AIR)

		-- start is base center
		local xIndex, zIndex = getCellXZIndexesForPosition(self.basePos)
		local start = getCellFromTableIfExists(self.ai.mapHandler.mapCells,xIndex,zIndex)
	
		local goal = nil	
		local bestCell = nil
		local bestNukeCell = nil
		local bestValue = -INFINITY
		local bestNukeValue = -INFINITY 
		for i=1,#self.enemyCellList do
			local cell = self.enemyCellList[i]
			if ( cell.cost and cell.cost > 0 and checkWithinMapBounds(cell.p.x,cell.p.z)) then
				local value = max(cell.cost - cell.combinedThreatCost,0)
				local nukeValue = max((cell.cost + 2*cell.economyCost)/3,0) * (cell.buildingCount > 3 and 1 or 0.5) 
				if (bestCell == nil) then
					bestCell = cell
				end
				if (bestNukeCell == nil) then
					bestNukeCell = cell
				end				
				if value > bestValue then
					bestCell = cell
					bestValue = value
				end
				if nukeValue > bestNukeValue then
					bestNukeCell = cell
					bestNukeValue = nukeValue
				end				
				
				--Spring.MarkerAddPoint(cell.p.x+100,500,cell.p.z+100,"Value="..string.format("%2f",cell.cost - cell.combinedThreatCost)) --DEBUG
			end
		end
		if bestCell then
			goal = getCellFromTableIfExists(self.ai.mapHandler.mapCells,bestCell.xIndex,bestCell.zIndex)
		end
		if bestNukeCell then
			self.nukeTargetCell = getCellFromTableIfExists(self.ai.mapHandler.mapCells,bestNukeCell.xIndex,bestNukeCell.zIndex)
		end		
		-- AI beacon override
		if self.ai:isBeaconActive(UNIT_GROUP_RAIDERS) then
			local xIndex,zIndex = getCellXZIndexesForPosition(self.ai.beaconPos)
			goal = getCellFromTableIfExists(self.ai.mapHandler.mapCells,xIndex,zIndex)
		end
					
		if start and goal then
			local landRaiderPathIndexes = self:getAStarPath(PF_UNIT_LAND,start,goal)
			local amphibiousRaiderPathIndexes = self:getAStarPath(PF_UNIT_AMPHIBIOUS,start,goal)
			local airRaiderPathIndexes = self:getAStarPath(PF_UNIT_AIR,start,goal)
			
			local landRaiderPath = {}
			if (landRaiderPathIndexes) then
				for i=1,#landRaiderPathIndexes do
					local cIdx = landRaiderPathIndexes[i]
					local cell = self.ai.mapHandler.mapCellList[cIdx]
					landRaiderPath[#landRaiderPath+1] = cell
					--if (self.ai.id == 0) then
						--Spring.MarkerAddPoint(cell.p.x,500,cell.p.z,string.format("RAID "..i,value)) --DEBUG
					--end
				end
			end
			self.raiderPath[PF_UNIT_LAND] = landRaiderPath
		
			local amphibiousRaiderPath = {}
			if (amphibiousRaiderPathIndexes) then
				for i=1,#amphibiousRaiderPathIndexes do
					local cIdx = amphibiousRaiderPathIndexes[i]
					local cell = self.ai.mapHandler.mapCellList[cIdx]
					amphibiousRaiderPath[#amphibiousRaiderPath+1] = cell
					--if (self.ai.id == 0) then
						--Spring.MarkerAddPoint(cell.p.x,500,cell.p.z,string.format("RAID "..i,value)) --DEBUG
					--end
				end
			end
			self.raiderPath[PF_UNIT_AMPHIBIOUS] = amphibiousRaiderPath
			
			local airRaiderPath = {}
				if airRaiderPathIndexes then
				for i=1,#airRaiderPathIndexes do
					local cIdx = airRaiderPathIndexes[i]
					local cell = self.ai.mapHandler.mapCellList[cIdx]
					airRaiderPath[#airRaiderPath+1] = cell
					--if (self.ai.id == 0) then
					--	Spring.MarkerAddPoint(cell.p.x,400,cell.p.z,string.format("AIRRAID "..i,value)) --DEBUG
					--end
				end
			end
			self.raiderPath[PF_UNIT_AIR] = airRaiderPath
		
			--log("land raider path = "..#landRaiderPath.."        air raider path = "..#airRaiderPath.." start="..(start.p.x)..","..(start.p.z).." goal="..(goal.p.x)..","..(goal.p.z),self.ai)
		else
			--log("raiding paths undefined, start or goal cell missing : start="..tostring(start).." goal="..tostring(goal).." bestCell="..(not bestCell and tostring(bestCell) or (bestCell.xIndex..","..bestCell.zIndex)),self.ai)
		end
	end
	
	if (self.ai.useStrategies) then
		local raiderSpeedThreshold = currentStrategy.stages[sStage].properties.raiderSpeedThreshold
		if (raiderSpeedThreshold and raiderSpeedThreshold < 999) then
			-- move fast units to the land raiding group
			self:detachLandRaidingParty(raiderSpeedThreshold)
			
			-- remove slow units from the land raiding group and merge them back on the regular attacker group
			self:reattachRaidersToAttackers(raiderSpeedThreshold)
		end
	else
		-- move fast units to the land raiding group immediately
		self:detachLandRaidingParty(65)
	
		-- also detach slower units, if main force has been unable to attack for some time
		-- do this only if the main ground force still outnumbers the raiding party
		if (self.unitGroups[UNIT_GROUP_ATTACKERS].totalCost > self.unitGroups[UNIT_GROUP_RAIDERS].totalCost) and ( f - self.lastMainForceAttackFrame > RAIDING_PARTY_TOLERANCE_FRAMES) then
			self:detachLandRaidingParty(48)
		end
		--log("AI "..self.ai.id.." attackers="..#(self.unitGroups[UNIT_GROUP_ATTACKERS].recruits).." raiders="..#(self.unitGroups[UNIT_GROUP_RAIDERS].recruits).." airAttackers"..#(self.unitGroups[UNIT_GROUP_AIR_ATTACKERS].recruits),self.ai)	
	end
	-- update status and positions for each group
	if fmod(f,59) == 13 + self.ai.frameShift then
		-- iterate through own units : members of unit groups
		for gId,group in pairs(self.unitGroups) do
			local recruits = group.recruits
			oldGroupNearCenterCount = group.nearCenterCount
			local groupX = 0
			local groupZ = 0
			local groupCount = #recruits
			local groupCost = 0
			local groupNearCenterX = 0
			local groupNearCenterZ = 0
			local groupNearCenterCost = 0
			local groupNearCenterCount = 0
			local groupAvgHpCostRatio = 0
			local groupAvgRange = 0
			local groupAvgSpeed = 0
			local forceInclusionRadius = gId == UNIT_GROUP_AIR_ATTACKERS and FORCE_INCLUSION_RADIUS_AIR or FORCE_INCLUSION_RADIUS
			local groupNearCenterAntiUWCost = 0

			-- air units are allowed to stray farther away from center
			if (group.id == UNIT_GROUP_AIR_ATTACKERS) then
				forceInclusionRadius = forceInclusionRadius * (1 + sqrt(groupCount/8))
			elseif (group.id == UNIT_GROUP_RAIDERS) then
				forceInclusionRadius = forceInclusionRadius * (1 + sqrt(groupCount/16))
			else
				forceInclusionRadius = forceInclusionRadius * (1 + sqrt(groupCount/16))
			end
			
			
			group.isAmphibious = false
			if (self.ai.useStrategies) then
				if (gId == UNIT_GROUP_RAIDERS) then
					if currentStrategy.stages[sStage].properties.amphibiousRaiders then
						group.isAmphibious = true
					end
				elseif (gId == UNIT_GROUP_ATTACKERS) then
					if currentStrategy.stages[sStage].properties.amphibiousMainForce then
						group.isAmphibious = true
					end				
				end
			end
			
			for _,behavior in ipairs(recruits) do
				local upos = newPosition(spGetUnitPosition(behavior.unitId,false,false))
				local un = behavior.unitName
				local cost = behavior.unitCost
				-- assume damaged units are worth half as much
				if (behavior.isSeriouslyDamaged == true) then
					cost = cost / 2
				end
				if cost > 0 then
					groupAvgHpCostRatio = groupAvgHpCostRatio + behavior.maxHp
					groupAvgRange = groupAvgRange + cost*behavior.maxRange
					groupAvgSpeed = groupAvgSpeed + cost*behavior.speed
				end
				
				-- check center
				-- ignore units too far from center
				if checkWithinMapBounds(upos.x,upos.z) then
					groupX = groupX + upos.x
					groupZ = groupZ + upos.z
					
					if ((#recruits < 2 or oldGroupNearCenterCount < 2) or distance(group.oldCenterPos, upos) < forceInclusionRadius) then
						groupNearCenterX = groupNearCenterX + upos.x
						groupNearCenterZ = groupNearCenterZ + upos.z
					
						groupNearCenterCost = groupNearCenterCost + cost 
						groupNearCenterCount = groupNearCenterCount + 1
						
						if unitAbleToHitUnderwater[un] then
							groupNearCenterAntiUWCost = groupNearCenterAntiUWCost + cost
						end
					end 
				end

				groupCost = groupCost + cost
			end

			if groupCount > 0 and groupNearCenterCount > 0 then
				-- use the "near-center" position only if most units are actually nearby
				if groupNearCenterCount > groupCount * GROUP_NEAR_CENTER_THRESHOLD and groupNearCenterCost > groupCost * GROUP_NEAR_CENTER_THRESHOLD then
					groupX = groupNearCenterX / groupNearCenterCount
					groupZ = groupNearCenterZ / groupNearCenterCount
				else
					groupX = groupX / groupCount
					groupZ = groupZ / groupCount
				end
			
				if groupCost > 0 then
					groupAvgHpCostRatio = groupAvgHpCostRatio/groupCost
					groupAvgRange = groupAvgRange/groupCost
					groupAvgSpeed = groupAvgSpeed/groupCost
				end
			else 
				groupX = self.basePos.x
				groupZ = self.basePos.z
			end
			
			-- shift center position towards where it's been moving over the last few seconds
			if (group.oldCenterPosFrame > 0) then
				if abs(groupX - group.oldCenterPos.x) < 500 and abs(groupZ - group.oldCenterPos.z) < 500 then
					local newX = groupX + (groupX - group.oldCenterPos.x)*0.3
					local newZ = groupZ + (groupZ - group.oldCenterPos.z)*0.3
					
					if ( newX > 0 and newX < Game.mapSizeX and newZ > 0 and newZ < Game.mapSizeZ) then
						groupX = newX
						groupZ = newZ
					end
				end
			end
			
			-- update group
			group.centerPos.x = groupX
			group.centerPos.z = groupZ
			group.totalCost = groupCost
			group.nearCenterCost = groupNearCenterCost
			group.nearCenterCount = groupNearCenterCount
			group.nearCenterAntiUWCost = groupNearCenterAntiUWCost
			group.avgHpCostRatio = groupAvgHpCostRatio
			group.avgRange = groupAvgRange
			group.avgSpeed = groupAvgSpeed
			
			--if (self.ai.id == 1 ) then 
			--	Spring.MarkerAddPoint(groupX,500,groupZ,(group.id == UNIT_GROUP_ATTACKERS and "ATTACKERS" or (group.id == UNIT_GROUP_RAIDERS and "RAIDERS" or "OTHER")).."\n"..group.nearCenterCount.."/"..(#recruits)) --DEBUG
			--end
			group.oldCenterPos = group.centerPos
			group.oldCenterPosFrame = f
			-- log("group "..gId.." center ("..groupNearCenterCount.." / "..groupNearCenterCost..") : ("..groupX..";"..groupZ..")",self.ai) --DEBUG
		end
	end
	
	
	-- check whether units should attack or retreat towards beacon
	if self.ai:isBeaconActive() then
		local xIndex,zIndex = getCellXZIndexesForPosition(self.ai.beaconPos)
		local cell = getCellFromTableIfExists(self.ai.mapHandler.mapCells,xIndex,zIndex)
		
		local d = distance(self.basePos,cell.p)
		if d < BEACON_BASE_RETREAT_DISTANCE then
			self.beaconAttack = false
		else 
			self.beaconAttack = true
		end
	end
	
	
	-- define task for each group
	if fmod(f,199) == 52 + self.ai.frameShift then
		local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")
		local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(self.ai.id,"energy")
		
		-- TODO absolute force size irrelevant? 
		-- update attack force size multiplier
		self.sizeMult = 1 + incomeM*FORCE_SIZE_MOD_METAL -- + (self.atkFailureCost/FORCE_COST_REFERENCE)*FORCE_SIZE_MOD_FAILURE
		if self.isBrutalMode then
			self.sizeMult = 1 + incomeM*FORCE_SIZE_MOD_METAL -- + (self.atkFailureCost/FORCE_COST_REFERENCE)*BRUTAL_FORCE_SIZE_MOD_FAILURE
		end
		
		self.refForceCost = FORCE_COST_REFERENCE * self.sizeMult -- target minimum force size
		
		-- if base is under attack...?
		if (f - self.baseUnderAttackFrame < BASE_UNDER_ATTACK_FRAMES ) then
			self.baseUnderAttack = true
		else
			self.baseUnderAttack = false
		end

		-- log(" self.sizeMult="..self.sizeMult.." refAtkCost="..self.refForceCost, self.ai) --DEBUG
		
		-- update task for each unit group
		local minForceCost = 0
		local oldTargetCell = nil
		for gId,group in pairs(self.unitGroups) do
			oldTargetCell = group.targetCell
			local groupCenterPos = group.centerPos
			minForceCost = self.refForceCost
			if (group.id == UNIT_GROUP_AIR_ATTACKERS) then
				minForceCost = FORCE_COST_REFERENCE	-- do not scale min air force
			elseif (group.id == UNIT_GROUP_RAIDERS) then
				minForceCost = 50		-- even a little scout can raid?
			end
			
			local bestCell = nil
			local bestValue = -INFINITY
			local bestCellThreatAlongPath = 0
			
			-- AI beacon override
			if self.ai:isBeaconActive(group.id) then
				local xIndex,zIndex = getCellXZIndexesForPosition(self.ai.beaconPos)
				local cell = getCellFromTableIfExists(self.ai.mapHandler.mapCells,xIndex,zIndex)
				local value, threatAlongPath = self:getCellAttackValue(group,cell)
				
				if (cell) then
					bestCell = cell
					bestValue = value or 0
					bestCellThreatAlongPath = threatAlongPath or 0
				end
			else
				for i=1,#self.enemyCellList do
					local cell = self.enemyCellList[i]
					local value, threatAlongPath = self:getCellAttackValue(group,cell)
					
					-- if cell was targeted previously, double the value
					-- this is to discourage hesitation
					if (oldTargetCell ~= nil and i == oldTargetCell.index) then
						value = value * CELL_VALUE_RETARGET_PREFERENCE_FACTOR
					end
					
					if (bestCell == nil) then
						bestCell = cell
					end
					if value > bestValue then
						bestCell = cell
						bestValue = value
						bestCellThreatAlongPath = threatAlongPath
					end
				end
			end
			if (bestCell ~= nil) then
				group.targetPos.x = bestCell.p.x
				group.targetPos.z = bestCell.p.z
			end
			group.targetCell = bestCell
			group.targetValue = bestValue
			group.targetThreatAlongPath = bestCellThreatAlongPath
			
			-- figure out something about the profile of enemies around the target cell
			-- might be relevant to figure out whether to attack or how to engage
			-- TODO move this elsewhere
	
			local task = group.task
			local taskFrame = group.taskFrame
			if ( self.humanTask == nil or (self.humanTaskFrame + HUMAN_TASK_DELAY_FRAMES < f) ) then
				self.humanTask = nil

				local wasAttacking = (task == TASK_ATTACK)
				if (task == nil or (taskFrame + TASK_DELAY_FRAMES < f)) then
					task = nil
					if (self.ai:isBeaconActive(group.id) and self.beaconAttack) or ((group.nearCenterCost > minForceCost) and bestValue > 0 ) then
						task = TASK_ATTACK
						group.taskFrame = f
						if (gId == UNIT_GROUP_ATTACKERS) then
							self.lastMainForceAttackFrame = f
						end
					elseif (self.ai:isBeaconActive(group.id) and (not self.beaconAttack)) or ( wasAttacking and group.nearCenterCost < minForceCost) or bestValue < 0  then
						task = TASK_RETREAT
						group.taskFrame = f
					end
				end
			end
			
			if (task == TASK_ATTACK) then
				if (self.baseUnderAttack) then
					-- log("group "..gId.." : DEFEND",self.ai) --DEBUG
				else
					-- log("group "..gId.." : ATTACK",self.ai) --DEBUG
				end
			elseif  (task == TASK_RETREAT) then
				-- log("group "..gId.." : RETREAT", self.ai) --DEBUG
			else
				-- log("group "..gId.." : IDLE",self.ai) --DEBUG
			end
			
			group.task = task
		end
	end
	
	-- issue orders to units in attack groups according to the current corresponding task
	if fmod(f,60) == 4 + self.ai.frameShift then
		for gId,group in pairs(self.unitGroups) do
			self:doTargetting(group)
		end
	end
end


