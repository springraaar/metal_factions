include("LuaRules/Gadgets/ai/Common.lua")
 
UnitHandler = {}
UnitHandler.__index = UnitHandler

function UnitHandler.create()
   local obj = {}             -- our new object
   setmetatable(obj,UnitHandler)  -- make AI handle lookup
   return obj
end

function UnitHandler:Name()
	return "UnitHandler"
end

function UnitHandler:internalName()
	return "unitHandler"
end


function getMapCell(position)
	return self.ai.mapHandler.mapCells[position.x * CELL_SIZE + CELL_SIZE / 2] 
end

function initUnitGroup(id)
	local obj = {}
	
	obj.id = id
	obj.centerPos = newPosition()
	obj.nearCenterCost = 0
	obj.nearCenterCount = 0
	obj.totalCost = 0 
	obj.recruits = {}
	obj.closestCell = nil
	obj.closestCellVulnerable = nil
	obj.targetCell = nil
	obj.targetPos = newPosition()
	obj.task = nil
	obj.taskFrame = 0
	
	return obj
end

function UnitHandler:Init(ai)
	self.ai = ai
	self.isEasyMode = (self.ai.mode == "easy")
	self.isBrutalMode = (self.ai.mode == "brutal")
	
	self.sizeMult = 1
	self.atkFailureCost = 0
	self.airHarassWhileAttacking = true

	self.refForceCost = FORCE_COST_REFERENCE * self.sizeMult		-- target force size
	self.refAirForceCost = FORCE_COST_REFERENCE * self.sizeMult		-- target air force size
	
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

	self.attackerCount = 0 
	self.airAttackerCount = 0
	self.seaAttackerCount = 0

	self.recruitsCenterPos = newPosition()

	self.recruitsTargetNormal = newPosition()
	self.recruitsTargetNormal.x = 0
	self.recruitsTargetNormal.y = 0
	self.recruitsTargetNormal.z = 0
	self.recruitsTargetNormalSqNorm	= 1

	self.humanTask = nil
	self.humanTaskFrame = -HUMAN_TASK_DELAY_FRAMES - 1 
	self.baseUnderAttack = false
	self.baseUnderAttackFrame = -BASE_UNDER_ATTACK_FRAMES - 1
	self.ownCellList = {}
	self.ownCells = {}
	self.ownBuildingCells = {}
	
	self.friendlyCellList = {}
	self.friendlyCells = {}
	self.enemyCellList = {}
	self.enemyCells = {}
	self.threatType = THREAT_NORMAL
	self.friendlyExtractorCount = 0
	self.enemyExtractorCount = 0
	
	-- task queue related information
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
	self.allIn = false
	
	
	-- initialize own building cells
	local cellCountX = math.ceil(Game.mapSizeX / CELL_SIZE)
	local cellCountZ = math.ceil(Game.mapSizeZ / CELL_SIZE)
	self.ownBuildingCells = {}
	for i=0,(cellCountX - 1) do
		self.ownBuildingCells[i] = {}
		for j=0,(cellCountZ - 1) do
			local newCell = { buildingIdSet={}, p = newPosition(), xIndex=i,zIndex=j}
			self.ownBuildingCells[i][j] = newCell
			
			newCell.p.x = i * CELL_SIZE + CELL_SIZE / 2
			newCell.p.z = j * CELL_SIZE + CELL_SIZE / 2
		end
	end
	
	self.collectedData = false
end

function UnitHandler:GetHumanTask()
	-- local data = game:SendToContent("GET_HUMAN_TASK")
	-- log("AI : data from gadget="..tostring(data))
end


function UnitHandler:Update()
	local f = spGetGameFrame()
	-- slowly "forget" about attack failures 
	if fmod(f,ATK_FAIL_TOLERANCE_FRAMES) == 0 then
		if self.atkFailureCost > 0 then 
			self.atkFailureCost = self.atkFailureCost - ATK_FAIL_TOLERANCE_COST
		end		
	end
	-- load game status : own cells, friendly cells, enemy cells
	if fmod(f,199) == 0 then
		
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

		
		-- update special role task queue counts
		for _,tq in pairs(self.taskQueues) do
			if (tq.specialRole == 0) then
				standardQueueCount = standardQueueCount + 1
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
		self.mexBuilderCount = mexBuilderCount
		self.basePatrollerCount = basePatrollerCount
		self.mexUpgraderCount = mexUpgraderCount
		self.defenseBuilderCount = defenseBuilderCount
		self.advancedDefenseBuilderCount = advancedDefenseBuilderCount 
		self.attackPatrollerCount = attackPatrollerCount

		self.attackerCount = 0
		self.airAttackerCount = 0
		self.seaAttackerCount = 0
		
		-- update targets based on economy size
		self.mexBuilderCountTarget = self.ai.mapHandler.isMetalMap and 0 or min(1 + floor(incomeM / 50),2)
		self.basePatrollerCountTarget = min(1 + floor(incomeM / 40),3)
		self.mexUpgraderCountTarget = self.ai.mapHandler.isMetalMap and 0 or min(1 + floor(incomeM / 50),1)
		self.defenseBuilderCountTarget = min(0 + floor((incomeM) / 50),2)
		self.advancedDefenseBuilderCountTarget = min(0 + floor(incomeM / 100),2)
		self.attackPatrollerCountTarget = min(0 + floor((15+incomeM) / 40),2)
		
		-- make sure at least a few builders have the standard queue
		local standardQueueMin = 1
		if (standardQueueCount < min(standardQueueMin + floor((20+incomeM) / 30),4)) then
			self.basePatrollerCountTarget = 0
			self.mexUpgraderCountTarget = 0
			self.defenseBuilderCountTarget = 0
			self.advancedDefenseBuilderCountTarget = 0
			self.attackPatrollerCountTarget = 0
		end
		if self.isBrutalMode then
			self.basePatrollerCountTarget = max(self.basePatrollerCountTarget-1,0)
			self.mexUpgraderCountTarget = max(self.mexUpgraderCountTarget-1,0)
			self.defenseBuilderCountTarget = max(self.defenseBuilderCountTarget-1,0)
			self.advancedDefenseBuilderCountTarget = max(self.advancedDefenseBuilderCountTarget-1,0)
			self.attackPatrollerCountTarget = max(self.attackPatrollerCountTarget-1,0)

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
			hasWeapons = #ud.weapons > 0
			cost = getWeightedCostByName(tmpName)
			local xIndex, zIndex = getCellXZIndexesForPosition(pos)
						
			-- check base
			if setContains(unitTypeSets[TYPE_PLANT],tmpName) then
				baseCount = baseCount + 1
				baseX = baseX + pos.x
				baseZ = baseZ + pos.z
			end
			
			-- log("friendly cell at ".."("..xIndex..";"..zIndex..")",self.ai)  --DEBUG
			if ownCells[xIndex] == nil then
				ownCells[xIndex] = {}
			end
			if ownCells[xIndex][zIndex] == nil then
				local newCell = { cost = 0, nearbyCost = 0, defenderCost = 0, attackerCost = 0, airAttackerCost = 0, nearbyAttackerCost = 0, nearbyAirAttackerCost = 0, nearbyDefenderCost = 0, xIndex = xIndex,zIndex = zIndex, p = newPosition(xIndex*CELL_SIZE+CELL_SIZE/2,0,zIndex*CELL_SIZE+CELL_SIZE/2), baseDistance = 0, extractorCount = 0, underWaterCost = 0, economyCost = 0, nearbyEconomyCost = 0, buildingCount = 0}
				ownCells[xIndex][zIndex] = newCell
				table.insert(ownCellList,newCell)
			end
			cell = ownCells[xIndex][zIndex]
			
			if setContains(unitTypeSets[TYPE_EXTRACTOR],tmpName) then
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
				cell.buildingCount = cell.buildingCount + 1
			elseif not ud.canMove then
				cell.economyCost = cell.economyCost + cost
				cell.buildingCount = cell.buildingCount + 1
			end
			
			-- if unit is strategic, assume it is worth twice as much
			if setContains(unitTypeSets[TYPE_STRATEGIC], tmpName) then
				cost = cost * 2
			end
			cell.cost = cell.cost + cost
			
			-- update global average position
			avgPos.x = avgPos.x + pos.x
			avgPos.z = avgPos.z + pos.z
			ownUnitCount = ownUnitCount + 1
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
		for i=1,#ownCellList do
			local cell = ownCellList[i]
			local mapCell = nil 
			if self.ai.mapHandler.mapCells[cell.xIndex] and self.ai.mapHandler.mapCells[cell.xIndex][cell.zIndex] then
				mapCell = self.ai.mapHandler.mapCells[cell.xIndex][cell.zIndex]
			end
			-- check nearby cells
			for dxi = -2, 2 do
				for dzi = -2, 2 do
					xi = cell.xIndex + dxi
					zi = cell.zIndex + dzi
					if (xi >=0) and (zi >= 0) and not (dxi == 0 and dzi == 0) then
						if ownCells[xi] then
							if ownCells[xi][zi] then
								cell.nearbyAttackerCost = cell.nearbyAttackerCost + ownCells[xi][zi].attackerCost
								cell.nearbyAirAttackerCost = cell.nearbyAirAttackerCost + ownCells[xi][zi].airAttackerCost
								cell.nearbyDefenderCost = cell.nearbyDefenderCost + ownCells[xi][zi].defenderCost
								cell.nearbyCost = cell.nearbyCost + ownCells[xi][zi].cost
								cell.nearbyEconomyCost = cell.nearbyEconomyCost + ownCells[xi][zi].economyCost
							end
						end
					end
				end
			end

			-- add combined and internal threat cost
			cell.combinedThreatCost = getCombinedThreatCost(cell)
			cell.internalThreatCost = getInternalThreatCost(cell)
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
				local newCell = { cost = 0, nearbyCost = 0, defenderCost = 0, attackerCost = 0, airAttackerCost = 0, nearbyAttackerCost = 0, nearbyAirAttackerCost = 0, nearbyDefenderCost = 0, xIndex = xIndex,zIndex = zIndex, p = newPosition(xIndex*CELL_SIZE+CELL_SIZE/2,0,zIndex*CELL_SIZE+CELL_SIZE/2), baseDistance = 0, extractorCount = 0, underWaterCost = 0, economyCost = 0, nearbyEconomyCost = 0, buildingCount = 0}
				friendlyCells[xIndex][zIndex] = newCell
				table.insert(friendlyCellList,newCell)
			end
			cell = friendlyCells[xIndex][zIndex]
			
			if setContains(unitTypeSets[TYPE_EXTRACTOR],tmpName) then
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
				cell.buildingCount = cell.buildingCount + 1 
			elseif not ud.canMove then
				cell.economyCost = cell.economyCost + cost
				cell.buildingCount = cell.buildingCount + 1
			end
			
			-- if unit is strategic, assume it is worth twice as much
			if setContains(unitTypeSets[TYPE_STRATEGIC], tmpName) then
				cost = cost * 2
			end
			cell.cost = cell.cost + cost
		end
		self.friendlyCells = friendlyCells
		self.friendlyCellList = friendlyCellList
		
		-- load nearby cell data for each cell
		xi = 0
		zi = 0
		for i=1,#friendlyCellList do
			local cell = friendlyCellList[i]
			-- check nearby cells
			for dxi = -2, 2 do
				for dzi = -2, 2 do
					xi = cell.xIndex + dxi
					zi = cell.zIndex + dzi
					if (xi >=0) and (zi >= 0) and not (dxi == 0 and dzi == 0) then
						if friendlyCells[xi] then
							if friendlyCells[xi][zi] then
								cell.nearbyAttackerCost = cell.nearbyAttackerCost + friendlyCells[xi][zi].attackerCost
								cell.nearbyAirAttackerCost = cell.nearbyAirAttackerCost + friendlyCells[xi][zi].airAttackerCost
								cell.nearbyDefenderCost = cell.nearbyDefenderCost + friendlyCells[xi][zi].defenderCost
								cell.nearbyCost = cell.nearbyCost + friendlyCells[xi][zi].cost
								cell.nearbyEconomyCost = cell.nearbyEconomyCost + friendlyCells[xi][zi].economyCost
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
		
		-- update enemy cell data
		local enemyAttackers = 0
		local enemyAirAttackers = 0
		local enemyDefenders = 0
		local enemyArmedUnits = 0
		if enemyUnitIds ~= nil then
			local cell = nil
			local cells = {}
			local cellList = {}
			
			-- figure out where all the enemies are!
			-- count costs instead of unit numbers
			for eId,_ in pairs (enemyUnitIds) do
				ud = UnitDefs[spGetUnitDefID(eId)]
				local tmpName = ud.name
				local hasWeapons = #ud.weapons > 0
				local cost = getWeightedCostByName(tmpName)
				local _,_,_,_,progress = spGetUnitHealth(eId) 
				progress = progress or 1
				

				-- count every enemy unit
				pos = newPosition(spGetUnitPosition(eId,false,false))
				local xIndex, zIndex = getCellXZIndexesForPosition(pos)
				
				-- log("enemy cell at ".."("..xIndex..";"..zIndex..")",self.ai)  --DEBUG
				if cells[xIndex] == nil then
					cells[xIndex] = {}
				end
				if cells[xIndex][zIndex] == nil then
					local newCell = { cost = 0, defenderCost = 0, attackerCost = 0, airAttackerCost = 0, nearbyAttackerCost = 0, nearbyAirAttackerCost = 0, nearbyDefenderCost = 0, xIndex = xIndex,zIndex = zIndex, p = newPosition(), baseDistance = 0, extractorCount = 0, underWaterCost = 0, internalThreatCost = 0, combinedThreatCost = 0}
					cells[xIndex][zIndex] = newCell
					table.insert(cellList,newCell)
				end
				cell = cells[xIndex][zIndex]
			
				if (pos.y < UNDERWATER_THRESHOLD ) then
					cell.underWaterCost = cell.underWaterCost + cost				
				end
				if setContains(unitTypeSets[TYPE_EXTRACTOR],tmpName) then
					cell.extractorCount = cell.extractorCount + 1
				end

				if progress > 0.85 and setContains(unitTypeSets[TYPE_AIR_ATTACKER],tmpName) then
					cell.airAttackerCost = cell.airAttackerCost + cost
					enemyArmedUnits = enemyArmedUnits + cost
					enemyAirAttackers = enemyAirAttackers + cost
					enemyArmedWeightedCost = enemyArmedWeightedCost + cost / 2
				elseif progress > 0.85 and hasWeapons and ud.canMove then
					cell.attackerCost = cell.attackerCost + cost
					enemyArmedUnits = enemyArmedUnits + cost
					enemyAttackers = enemyAttackers + cost
					enemyArmedWeightedCost = enemyArmedWeightedCost + cost
				elseif progress > 0.85 and hasWeapons then
					cell.defenderCost = cell.defenderCost + cost
					enemyArmedUnits = enemyArmedUnits + cost
					enemyDefenders = enemyDefenders + cost
					enemyArmedWeightedCost = enemyArmedWeightedCost + cost
				end
				
				-- if unit is strategic, assume it is worth twice as much
				if setContains(unitTypeSets[TYPE_STRATEGIC], tmpName) then
					cost = cost * ENEMY_STRATEGIC_COST_FACTOR
				end
				cell.cost = cell.cost + cost
				
				-- target the unit's position instead of the center of the cell
				cell.p.x = pos.x
				cell.p.z = pos.z
			end
			
			-- load nearby cell data for each cell
			local dxi = 0
			local dzi = 0
			local xi = 0
			local zi = 0
			for i=1,#cellList do
				local cell = cellList[i]
				dxi = 0
				dzi = 0
				local mapCell = nil 
				if self.ai.mapHandler.mapCells[cell.xIndex] and self.ai.mapHandler.mapCells[cell.xIndex][cell.zIndex] then
					mapCell = self.ai.mapHandler.mapCells[cell.xIndex][cell.zIndex]
				end
				-- check nearby cells
				for dxi = -2, 2 do
					for dzi = -2, 2 do
						xi = cell.xIndex + dxi
						zi = cell.zIndex + dzi
						if (xi >=0) and (zi >= 0) and not (dxi == 0 and dzi == 0) then
							if cells[xi] then
								if cells[xi][zi] then
									cell.nearbyAttackerCost = cell.nearbyAttackerCost + cells[xi][zi].attackerCost
									cell.nearbyAirAttackerCost = cell.nearbyAirAttackerCost + cells[xi][zi].airAttackerCost
									cell.nearbyDefenderCost = cell.nearbyDefenderCost + cells[xi][zi].defenderCost
								end
							end
						end
					end
				end
				
				-- add combined and internal threat cost
				cell.combinedThreatCost = getCombinedThreatCost(cell)
				cell.internalThreatCost = getInternalThreatCost(cell)
			end
			
			-- load distances to center of base for each cell
			-- if enemy cluster close to base, assume base under attack
			-- log("enemy cells:",self.ai)
			for i=1,#cellList do
				local cell = cellList[i]
				cell.baseDistance = distance(cell.p,self.basePos) or INFINITY
				
				-- log("enemy cell at indexes ( "..cell.xIndex.." ; "..cell.zIndex.." )",self.ai)
				
				if(cell.baseDistance < BASE_UNDER_ATTACK_RADIUS and cell.combinedThreatCost > 1200) then
					self.baseUnderAttack = true
					self.baseUnderAttackFrame = f
				end
			end
			
			-- update cell list
			self.enemyCellList = cellList
			self.enemyCells = cells
		end
		self.enemyExtractorCount = enemyExtractorCount
		self.friendlyExtractorCount = friendlyExtractorCount
		
		-- update threat type 
		if ( enemyAirAttackers / enemyArmedUnits > THREAT_AIR_THRESHOLD ) then
			self.threatType = THREAT_AIR
		elseif ( enemyDefenders / enemyArmedUnits > THREAT_DEFENSE_THRESHOLD ) then
			self.threatType = THREAT_DEFENSE
		else
			self.threatType = THREAT_NORMAL
		end
		
		-- calculate overall force advantage factor
		self.perceivedTeamAdvantageFactor = (ownArmedMobilesWeightedCost + friendlyArmedMobilesWeightedCost ) / enemyArmedWeightedCost
		--log("perceived adv factor : "..self.perceivedTeamAdvantageFactor, self.ai)
		if self.perceivedTeamAdvantageFactor > ALL_IN_ADVANTAGE_THRESHOLD then 
			self.allIn = true
			--Spring.Echo("team "..self.ai.id.." is going ALL IN! ("..self.perceivedTeamAdvantageFactor..")")
		else
			self.allIn = false
			--Spring.Echo("team "..self.ai.id.." is being careful... ("..self.perceivedTeamAdvantageFactor..")")		
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
		-- log("safeCell ( "..leastVulnerableCell.p.x.." ; "..leastVulnerableCell.p.z .." ) vulnerableCell ( "..mostVulnerableCell.p.x.." ; "..mostVulnerableCell.p.z.." )", self.ai)

		self.collectedData = true
	end
	-- define task for each group
	if fmod(f,199) == 52 then
		local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")
		local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(self.ai.id,"energy")
	
		-- iterate through own units : members of unit groups
		for gId,group in pairs(self.unitGroups) do
			local recruits = group.recruits
			local oldGroupPos = newPosition()
			oldGroupPos.x = group.centerPos.x
			oldGroupPos.z = group.centerPos.z
			oldGroupNearCenterCount = group.nearCenterCount
			local groupX = 0
			local groupZ = 0
			local groupCount = 0
			local groupCost = 0
			local groupNearCenterCost = 0
			local groupNearCenterCount = 0
			local forceInclusionRadius = gId == UNIT_GROUP_AIR_ATTACKERS and FORCE_INCLUSION_RADIUS_AIR or FORCE_INCLUSION_RADIUS
			
			for _,behavior in ipairs(recruits) do
				local upos = newPosition(spGetUnitPosition(behavior.unitId,false,false))
				local un = behavior.unitName
				local cost = behavior.unitCost
				-- assume damaged units are worth half as much
				if (behavior.isSeriouslyDamaged == true) then
					cost = cost / 2
				end

				-- check center
				-- ignore units too far from center
				if (  (#recruits < 4 or oldGroupNearCenterCount < 3) or distance(oldGroupPos, upos) < forceInclusionRadius)  then
					groupX = groupX + upos.x
					groupZ = groupZ + upos.z
					groupNearCenterCost = groupNearCenterCost + cost 
					groupNearCenterCount = groupNearCenterCount + 1
				end

				groupCost = groupCost + cost
				groupCount = groupCount + 1
			end
	
			if groupCount > 0 and groupNearCenterCount > 0 then
				groupX = groupX / groupNearCenterCount
				groupZ = groupZ / groupNearCenterCount
			else 
				groupX = self.basePos.x
				groupZ = self.basePos.z
			end
			
			-- update group
			group.centerPos.x = groupX
			group.centerPos.z = groupZ
			group.totalCost = groupCost
			group.nearCenterCost = groupNearCenterCost
			group.nearCenterCount = groupNearCenterCount
			-- log("group "..gId.." center ("..groupNearCenterCount.." / "..groupNearCenterCost..") : ("..groupX..";"..groupZ..")",self.ai) --DEBUG
		end
	
		-- TODO absolute force size irrelevant? 
		-- update attack force size multiplier
		self.sizeMult = 1 + incomeM*FORCE_SIZE_MOD_METAL -- + (self.atkFailureCost/FORCE_COST_REFERENCE)*FORCE_SIZE_MOD_FAILURE
		if self.isBrutalMode then
			self.sizeMult = 1 + incomeM*FORCE_SIZE_MOD_METAL + (self.atkFailureCost/FORCE_COST_REFERENCE)*BRUTAL_FORCE_SIZE_MOD_FAILURE
		end
		
		self.refForceCost = FORCE_COST_REFERENCE * self.sizeMult -- target force size
		self.refAirForceCost = FORCE_COST_REFERENCE * self.sizeMult -- target air force size
		local forceCostFactor = 1

		-- if base is under attack, don't wait too long...
		if (f - self.baseUnderAttackFrame < BASE_UNDER_ATTACK_FRAMES ) then
			self.baseUnderAttack = true
			forceCostFactor = 2
		else
			self.baseUnderAttack = false
		end

		-- log(" self.sizeMult="..self.sizeMult.." refAtkCost="..self.refForceCost.." refAirAtkCost="..self.refAirForceCost, self.ai) --DEBUG
		
		-- update task for each unit group
		for gId,group in pairs(self.unitGroups) do
			local groupCenterPos = group.centerPos
			
			local bestCell = nil
			local bestValue = -INFINITY

			for i=1,#self.enemyCellList do
				local cell = self.enemyCellList[i]
				local value = self:getCellAttackValue(group,cell)
				if (bestCell == nil) then
					bestCell = cell
				end
				if value > bestValue then
					bestCell = cell
					bestValue = value
				end
			end
			-- if bestCell ~= nil then
				-- log("group "..gId.." : ("..bestCell.xIndex.." ; "..bestCell.zIndex..") value="..bestValue, self.ai)
			-- else
				-- log("group "..gId.." couldn't find cell to target", self.ai)
			-- end
			
			-- TODO : get human defined task, somehow
			local task = group.task
			local taskFrame = group.taskFrame
			if ( self.humanTask == nil or (self.humanTaskFrame + HUMAN_TASK_DELAY_FRAMES < f) ) then
				self.humanTask = nil

				local wasAttacking = (task == TASK_ATTACK)
				if (task == nil or (taskFrame + TASK_DELAY_FRAMES < f)) then
					task = nil
					if ( (group.nearCenterCost > self.refForceCost) and bestValue > 0 ) then
						task = TASK_ATTACK
						group.taskFrame = f
					elseif ( wasAttacking and group.nearCenterCost < self.refForceCost) or bestValue < 0  then
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
	if fmod(f,60) == 4 then
		for gId,group in pairs(self.unitGroups) do
			self:DoTargetting(group)
		end
	end
	--if fmod(f,60) == 8 then
	--	self:GetHumanTask()
	--end	
	
	-- resource compensation for brutal mode
	-- TODO move this elsewhere
	if (self.isBrutalMode) then
		if fmod(f,15) == 0 then
			-- spAddTeamResource(self.ai.id,"metal",BRUTAL_BASE_INCOME_METAL * (1+1/(self.perceivedTeamAdvantageFactor+0.2))  )
			-- spAddTeamResource(self.ai.id,"energy",BRUTAL_BASE_INCOME_ENERGY * (1+1/(self.perceivedTeamAdvantageFactor+0.2)) )

			local minutesPassed = floor(f/FRAMES_PER_MIN)
			spAddTeamResource(self.ai.id,"metal",BRUTAL_BASE_INCOME_METAL + minutesPassed * BRUTAL_BASE_INCOME_METAL_PER_MIN  )
			spAddTeamResource(self.ai.id,"energy",BRUTAL_BASE_INCOME_ENERGY + minutesPassed * BRUTAL_BASE_INCOME_ENERGY_PER_MIN )
		end
	end
	

end

function UnitHandler:GameEnd()
	--
end

function UnitHandler:UnitCreated(uId,unitDefId,builderId)
	local ud = UnitDefs[unitDefId]
	if ud.isBuilding then
		local pos = newPosition(spGetUnitPosition(uId))

		-- register building id on all adjacent cells
		local cells = getAdjacentCellList(self.ownBuildingCells,pos)
		for _,cell in ipairs(cells) do
			addToSet(cell.buildingIdSet,uId)
		end		
	end
	
end

function UnitHandler:UnitFinished(uId)
	--
end

function UnitHandler:UnitDestroyed(uId,teamId,unitDefId)
	ud = UnitDefs[unitDefId]
	un = ud.name
	-- own units are dying
	if teamId == self.ai.id then
		
		-- remove building id from all adjacent cells
		if ud.isBuilding then
			local pos = newPosition(spGetUnitPosition(uId))
			local cells = getAdjacentCellList(self.ownBuildingCells,pos)
			for _,cell in ipairs(cells) do
				removeFromSet(cell.buildingIdSet,uId)
			end		
		end 
	
		if (setContains(unitTypeSets[TYPE_ATTACKER],un)) then
			self.atkFailureCost = self.atkFailureCost + getWeightedCost(ud)
		end
		
		-- if enemies are attacking our base, defend!
		if (setContains(unitTypeSets[TYPE_BASE],un)) then
			self.baseUnderAttackFrame = spGetGameFrame()
		end

	-- TODO : not properly used, remove?
	-- enemies are dying => attacks should be working
	elseif setContains(thisAI.enemyTeamIds,teamId) then
		if self.atkFailureCost > 0 then 
			self.atkFailureCost = max(self.atkFailureCost - getWeightedCost(ud),0)
		end	
	end
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
function UnitHandler:getCellAttackValue(group, cell)
	if ( group.id == UNIT_GROUP_AIR_ATTACKERS ) then
		-- ignore cells with only underwater units
		if ( cell.cost == cell.underWaterCost ) then
			return -INFINITY
		end
	elseif ( group.id == UNIT_GROUP_ATTACKERS ) then
		-- ignore deep water cells or cells with only underwater units
		local mapCell = getCellFromTableIfExists(self.ai.mapHandler.mapCells,cell.xIndex,cell.zIndex) 
		if ( mapCell ~= nil and mapCell.isDeepWater or (cell.cost == cell.underWaterCost)) then
			return -INFINITY
		end
	elseif ( group.id == UNIT_GROUP_SEA_ATTACKERS ) then
		-- ignore land cells without an adjacent water cell
		local mapCell = getCellFromTableIfExists(self.ai.mapHandler.mapCells,cell.xIndex,cell.zIndex) 
		if ( mapCell ~= nil and (mapCell.isLand or mapCell.isLandSlope) and cell.hasNearbyWater == false ) then
			return -INFINITY
		end
	end

	-- air units are weaker but can easily travel farther
	local groupCostFactor = 1
	local groupDistanceFactor = 1
	if gId == UNIT_GROUP_AIR_ATTACKERS then
		groupCostFactor = AIR_ATTACKER_EVALUATION_FACTOR
		groupDistanceFactor = AIR_ATTACKER_DISTANCE_EVALUATION_FACTOR
	end  
	
	-- calculate distance to center of group or center of base (if under attack)
	local cellDistance = 0
	-- use devaluation based on distance to base instead of group if base under attack
	if (self.baseUnderAttack) then
		cellDistance = distance(self.basePos,cell.p)
 	else
 		cellDistance = distance(group.centerPos,cell.p)
 	end

	-- add the internal threat cost of each cell that is closer to the group center
	-- regardless of direction
	local totalThreatCost = cell.combinedThreatCost
	for i=1,#self.enemyCellList do
		local otherCell = self.enemyCellList[i]
		if not (otherCell.xIndex == cell.xIndex and otherCell.zIndex == cell.zIndex) then
			local d = distance(otherCell.p,group.centerPos) or INFINITY
			
			if d < cellDistance then
				totalThreatCost = totalThreatCost + otherCell.internalThreatCost
			end
		end
	end
	
	-- compute cell value
	local xIndex, zIndex = getCellXZIndexesForPosition(cell.p)
	local totalAssistCost = 0
	local xi = 0
	local zi = 0
	for dxi = -1, 1 do
		for dzi = -1, 1 do
			xi = xIndex + dxi
			zi = zIndex + dzi
			if (xi >=0) and (zi >= 0) then
				if self.ownCells[xi] and self.ownCells[xi][zi] then
					totalAssistCost = totalAssistCost + self.ownCells[xi][zi].internalThreatCost
				end
				if self.friendlyCells[xi] and self.friendlyCells[xi][zi] then
					totalAssistCost = totalAssistCost + self.friendlyCells[xi][zi].internalThreatCost
				end
			end
		end
	end
	-- remove own attackers cost from assist cost if they are nearby to prevent them from being counted twice
	if (cellDistance < 2*CELL_SIZE) then
		totalAssistCost = totalAssistCost - group.nearCenterCost * groupCostFactor 
	end 
	
	local threatEvaluationFactor = self.baseUnderAttack and DEFENSE_ENEMY_THREAT_EVALUATION_FACTOR or ATTACK_ENEMY_THREAT_EVALUATION_FACTOR
	if (self.isEasyMode) then
		threatEvaluationFactor = threatEvaluationFactor * ATTACK_ENEMY_THREAT_EVALUATION_EASY_FACTOR
	end
	if (self.isBrutalMode) then
		threatEvaluationFactor = threatEvaluationFactor * ATTACK_ENEMY_THREAT_EVALUATION_BRUTAL_FACTOR
	end

	threatEvaluationFactor = threatEvaluationFactor * (group.task == TASK_ATTACK and ATTACK_PERSISTENCE_THREAT_EVALUATION_FACTOR or 1) 
	
	local cellValue = min(group.nearCenterCost * groupCostFactor + totalAssistCost - totalThreatCost * threatEvaluationFactor,cell.cost)
	if (cellValue > 0) then
		cellValue = cellValue * DEVALUATION_DISTANCE/(DEVALUATION_DISTANCE + cellDistance*groupDistanceFactor)
	end
	 
	return cellValue * max(self.perceivedTeamAdvantageFactor,1.0) 
end

function UnitHandler:UnitIdle(uId)
	--
end

-- order unit behavior entries on the group according to the task set
function UnitHandler:DoTargetting(group)
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
	else
		radius = FORCE_RADIUS * (1 + sqrt(#group.recruits/8))
	end
	
	local task = group.task

	if (task == TASK_ATTACK or task == TASK_DEFEND) then
		-- find somewhere to attack
		local cellList = self.enemyCellList
		local bestCell = nil
		local bestValue = -INFINITY

		for i=1,#cellList do
			local cell = cellList[i]
			if bestCell == nil then
				bestCell = cell
			else
				local value = self:getCellAttackValue(group,cell)
				if value > bestValue then
					bestCell = cell
					bestValue = value
				end
			end
		end

		-- if we have a cell then lets go attack it!
		if bestCell ~= nil then
			group.targetPos.x = bestCell.p.x
			group.targetPos.z = bestCell.p.z
			group.targetCell = bestCell
							
			-- atk center <-> target center
			--local v2 = newPosition()
			--v2.x = self.recruitsCenterPos.x - bestCell.p.x
			--v2.z = self.recruitsCenterPos.z - bestCell.p.z
			--v2.y = 0
			
			-- rotate 90 deg
			--local aux = v2.x
			--v2.x = - v2.z
			--v2.z = aux
			--local v2SqNorm = (v2.x*v2.x + v2.z*v2.z) 
			--self.recruitsTargetNormal = v2
			--self.recruitsTargetNormalSqNorm = v2SqNorm

			local evade = false
			for i,recruit in ipairs(group.recruits) do
				-- if unit is far from center of atk force, move to center
				-- else, attack the cell
				if not recruit:AttackRegroupCenterIfNeeded(group.centerPos, radius) then
					if (not recruit.isSeriouslyDamaged ) then
						evade = (not self.allIn) and (not self.isEasyMode) and #group.recruits < 100 and not recruit.unitDef.canFly
						if not (evade and recruit:EvadeIfNeeded()) then
							recruit:AttackCell(group.centerPos, bestCell)
						end
					else
						recruit:Retreat()
					end	
				end
			end
		end
	elseif( aiTask == TASK_RETREAT ) then
		for i,recruit in ipairs(group.recruits) do
			if(group.id == UNIT_GROUP_AIR_ATTACKERS) then
				if (recruit.isFullHealth) then
					recruit:BasePatrol()
				else
					recruit:Retreat()
				end
			else
				if not recruit:AttackRegroupCenterIfNeeded(group.centerPos, radius) then
					recruit:Retreat()
				end
			end
		end
	-- default behavior
	else
		for i,recruit in ipairs(group.recruits) do
			if(group.id == UNIT_GROUP_AIR_ATTACKERS) then
				if (recruit.isFullHealth) then
					recruit:BasePatrol()
				else
					recruit:Retreat()
				end
			else
				if not recruit:AttackRegroupCenterIfNeeded(group.centerPos, radius) then
					recruit:Retreat()
				end
			end
		end
	end
end

function UnitHandler:IsRecruit(attkbehavior,gId)
	for i,v in ipairs(self.unitGroups[gId].recruits) do
		if v == attkbehavior then
			return true
		end
	end
	return false
end

function UnitHandler:AddRecruit(attkbehavior, gId)
	if not self:IsRecruit(attkbehavior, gId) then
		table.insert(self.unitGroups[gId].recruits,attkbehavior)
		attkbehavior:SetMoveState()
	end
end

function UnitHandler:RemoveRecruit(attkbehavior, gId)
	for i,v in ipairs(self.unitGroups[gId].recruits) do
		if v.unitId == attkbehavior.unitId then
			-- log(attkbehavior.unitId.."being removed from recruits",self.ai)
			table.remove(self.unitGroups[gId].recruits,i)
			return true
		end
	end
	return false
end

