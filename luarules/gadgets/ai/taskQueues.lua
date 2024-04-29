--[[
 Task Queues!
]]--

include("luarules/gadgets/ai/common.lua")

function farFromBaseCenter(self, radius)
	if self.unitId == nil then
		return true
	end
	local basePos = self.ai.unitHandler.basePos
	if basePos.x > 0 and basePos.z > 0 and distance(basePos, self.pos) > ( radius or HUGE_RADIUS) then
		return true
	end
	return false
end

function areEnemiesNearby(self,pos, radius)
	for _,cell  in pairs(self.ai.unitHandler.enemyCellList) do
		-- only check for armed units
		if checkWithinDistance(cell.p,pos,radius) and (cell.attackerCost > 0 or cell.airAttackerCost > 0 or cell.defenderCost > 0) then
			return true
		end
	end
	return false
end 

-- reclaim nearby features if necessary according to their metal and energy values
function reclaimNearbyFeaturesIfNecessary(self)
	local selfPos = self.pos
	local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")
	local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(self.ai.id,"energy")
	
	local radius = 500
	if self.isStaticBuilder then
		radius = self.buildRange * 0.9
	end
	
	local wrecks = spGetFeaturesInCylinder(selfPos.x,selfPos.z, radius)
	local featuresToReclaim = {}
	if (#wrecks > 0) then
		local metalAmount = 0
		local energyAmount = 0
		
		for i,fId in ipairs(wrecks) do
			local fPos = newPosition(spGetFeaturePosition(fId,false,false))
			-- pathing check if necessary
			if self.isStaticBuilder or self.ai.mapHandler:checkConnection(selfPos, fPos,self.pFType) then
				local remainingM,_,remainingE,_,reclaimLeft,reclaimTime = spGetFeatureResources(fId)
				local fd = FeatureDefs[spGetFeatureDefID(fId)]
				if (fd and fd.reclaimable == true) then
					if remainingM and remainingM > 0 and currentLevelM + metalAmount < 0.8*storageM  then
						metalAmount = metalAmount + remainingM
						featuresToReclaim[#featuresToReclaim+1] = fId
					end
					if remainingE and remainingE > 0 and currentLevelE + energyAmount < 0.5*storageE  then
						energyAmount = energyAmount + remainingE
						featuresToReclaim[#featuresToReclaim+1] = fId
					end
				end
			end
		end
		
		if #featuresToReclaim > 0 then
			--log("reclaiming "..#featuresToReclaim,self.ai) --DEBUG
			for i,fId in ipairs(featuresToReclaim) do
				spGiveOrderToUnit( self.unitId, CMD.RECLAIM, {CMD_FEATURE_ID_OFFSET+fId}, i == 1 and EMPTY_TABLE or CMD.OPT_SHIFT )
			end
		
			return {action = "wait_idle", frames = CLEANUP_FRAMES}
		end
	end	
	
	return SKIP_THIS_TASK	
end

function checkMorph(self)
	if self.unitId ~= nil then
		local f = spGetGameFrame()

		if (f > 600) then
			if not setContains(unitTypeSets[TYPE_UPGRADED_COMMANDER],self.unitName) then
	
				local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")
				local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(self.ai.id,"energy")
				
				-- morph only if income is decent
				if self.ai.useStrategies or (incomeM > 20 and incomeE > 200) then
					-- if enemies are nearby, skip morph
					if areEnemiesNearby(self, self.pos, MORPH_CHECK_RADIUS) then
						--log("enemies nearby")
						return SKIP_THIS_TASK
					end
	
					local cmds = Spring.GetUnitCmdDescs(self.unitId)
					if (self.ai.useStrategies) then
						-- morph to a random form within the set of allowed forms
						local currentStrategy = self.ai.currentStrategy
						local sStage = self.ai.currentStrategyStage
						local comMorphMetalIncome = currentStrategy.stages[sStage].economy.comMorphMetalIncome or 99999
						local comMorphEnergyIncome = currentStrategy.stages[sStage].economy.comMorphEnergyIncome or 99999
						
						if (incomeM > comMorphMetalIncome and incomeE > comMorphEnergyIncome) then
							if (not currentStrategy.commanderMorphs or #currentStrategy.commanderMorphs == 0) then
								self.ai:messageAllies("Invalid morph definitions for strategy "..self.ai.currentStrategyName)
								return SKIP_THIS_TASK
							end
							local morphName = currentStrategy.commanderMorphs[ random( 1, #currentStrategy.commanderMorphs) ]
							if not morphName then
								self.ai:messageAllies("Invalid morph definitions for strategy "..self.ai.currentStrategyName)
								return SKIP_THIS_TASK
							end
							local morphCmd = false
							local morphCmdIds = {}
							for i,c in ipairs(cmds) do
								if (c.action == "morph" and string.find(c.name, morphName)) then
									--Spring.Echo(c.id.." ; "..c.name.." ; "..c.type.." ; "..c.action.." ; "..c.texture) --DEBUG
									morphCmd = c.id
									break
								end
							end
	
							if (morphCmd) then
								spGiveOrderToUnit(self.unitId,morphCmd,EMPTY_TABLE,EMPTY_TABLE)
							else
								log("MFAI WARNING: "..self.unitName.." got bad morph command : "..tostring(morphName),self.ai)
							end
						else
							return SKIP_THIS_TASK
						end
					else
						-- morph to a random form
						local morphCmdIds = {}
						for i,c in ipairs(cmds) do
							if (c.action == "morph") then
								--Spring.Echo(c.id.." ; "..c.name.." ; "..c.type.." ; "..c.action.." ; "..c.texture) --DEBUG
								morphCmdIds[#morphCmdIds + 1] = c.id
							end
						end

						local morphCmd = morphCmdIds[ random( 1, #morphCmdIds) ]
						spGiveOrderToUnit(self.unitId,morphCmd,EMPTY_TABLE,EMPTY_TABLE)
					end
					
					
					-- wait until finished or 5 minutes elapsed
					return {action="wait", frames=30*300}
				end
			end
		end
	end
	
	return SKIP_THIS_TASK
end

-- assist another builder that is performing specific functions
function assistOtherBuilderIfNeeded(self)
	local queues = self.ai.unitHandler.taskQueues

	-- only about 20% should try to assist, the rest should skip
	if (random(1,10) > 8) then
		return SKIP_THIS_TASK
	end

	if(queues ~= nil) then	
		-- search task queues for advanced defense builders or mex upgraders
		for i,tq in ipairs(queues) do
			if self.unitDef.isAirUnit or (tq.unitDef.isAirUnit == false and self.isWaterMode == tq.isWaterMode) then
				if tq.specialRole == UNIT_ROLE_ADVANCED_DEFENSE_BUILDER or tq.specialRole == UNIT_ROLE_MEX_UPGRADER then
					spGiveOrderToUnit(self.unitId,CMD.GUARD,{tq.unitId},EMPTY_TABLE)
					return {action="wait_idle", frames=1800}
				end
			end
		end
	end
	return SKIP_THIS_TASK
end

-- repair nearby units, or assist nearby construction given some restrictions
-- use the base position as reference
function assistNearbyConstructionIfNeeded(self,includeMobiles,includeNonBuilders,radius)
	local ownUnitIds = self.ai.ownUnitIds

	local basePos = self.ai.unitHandler.basePos
	local selfPos = basePos --self.pos
	local ud = nil
	local units = spGetUnitsInCylinder(selfPos.x,selfPos.z,radius)
	local uPos = nil
	local tId = nil
	if (units ~= nil) then
		--log("buildings :"..#units,self.ai) --DEBUG
		for _,uId in pairs(units) do
			tId = spGetUnitTeam(uId)
			if (spAreTeamsAllied(tId,self.ai.id)) then
				ud = UnitDefs[spGetUnitDefID(uId)]
				if ud ~= nil then
					local health,maxHealth,_,_,bp = spGetUnitHealth(uId)
					uPos = newPosition(spGetUnitPosition(uId,false,false))
					-- if fully built but needs repairs, repair it if you can
					if (bp == 1) then	
						if (health < 0.9*maxHealth) then
							if self.ai.mapHandler:checkConnection(selfPos, uPos,self.pFType) then
								--log("repairing nearby unit",self.ai) --DEBUG
								spGiveOrderToUnit(self.unitId,CMD.REPAIR,{uId},EMPTY_TABLE)
								return {action="wait_idle", frames=300}
							end
						end
					-- if not fully built, assist if you can
					elseif includeMobiles or (ud.speed == 0 and (not setContains(unitTypeSets[TYPE_NUKE],ud.name))) then
						if includeNonBuilders or ud.isBuilder then
							un = ud.name
							if self.ai.mapHandler:checkConnection(selfPos, uPos,self.pFType) then
								--log("assisting nearby unit under construction",self.ai) --DEBUG
								spGiveOrderToUnit(self.unitId,CMD.REPAIR,{uId},EMPTY_TABLE)
								return {action="wait_idle", frames=300}
							end
						end
					end
				end
			end
		end
	end
	
	return SKIP_THIS_TASK
end


function windSolarIfNeeded(self)
	-- check if we need power
	local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(self.ai.id,"energy")
	if incomeE < 1000  then
		return buildEnergyIfNeeded(self,windSolar(self))
	else
		return SKIP_THIS_TASK
	end
end


function tidalIfNeeded(self)
	-- check if we need power
	local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(self.ai.id,"energy")
	if incomeE < 1000  then
		return buildEnergyIfNeeded(self,tidalByFaction[self.unitSide])
	else
		return SKIP_THIS_TASK
	end
end

function metalExtractorIfNeeded(self)
	-- check if we need metal
	local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")

	local friendlyExtractorCount = self.ai.unitHandler.friendlyExtractorCount or 0
		
	if friendlyExtractorCount < 2 or incomeM < 20 or (incomeM - expenseM < 2) then
		return mexByFaction[self.unitSide]
	else
		return SKIP_THIS_TASK
	end
end

function metalExtractorNearbyIfSafe(self)
	local unitName = SKIP_THIS_TASK
	
	local friendlyExtractorCount = self.ai.unitHandler.friendlyExtractorCount or 0
	local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")

	if self.isAdvBuilder then
		local sStage = self.ai.currentStrategyStage
		if sStage > 1 then
			unitName = advMetalExtractor(self)
		else
			unitName = mexByFaction[self.unitSide]
		end
	else
		unitName = mexByFaction[self.unitSide]
	end
	
	local p = self.ai.buildSiteHandler:closestFreeSpot(self, UnitDefNames[unitName], self.pos, true, self.isAdvBuilder and "advMetal" or "metal", self.unitDef)
	
	local radius = EXPANSION_SAFETY_RADIUS
	-- reduce expansion radius for slow commanders, especially if they're on "attack" mode
	if self.isCommander then
		if (self.isAttackMode) then
			radius = max(500,EXPANSION_SAFETY_RADIUS * self.speed / 90)	
		else
			radius = max(500,EXPANSION_SAFETY_RADIUS * self.speed / 45)
		end
	end
	
	if ( p ~= nil and distance(self.pos,p) < radius) then
		self.nextMetalSpotPos = p	
		return unitName
	end
	self.nextMetalSpotPos = nil
	return SKIP_THIS_TASK
end

function geoNearbyIfSafe(self)
	-- don't attempt if there are no spots on the map
	if not self.ai.mapHandler.mapHasGeothermal then
		return SKIP_THIS_TASK
	end

	local unitName = geoByFaction[self.unitSide]
	local p = self.ai.buildSiteHandler:closestFreeSpot(self, UnitDefNames[unitName], self.pos, true, "geo", self.unitDef)
	if ( p ~= nil and distance(self.pos,p) < BIG_RADIUS) then	
		return unitName
	end

	return SKIP_THIS_TASK
end



-- restore original queue
function restoreQueue(self)

	-- revert to default queue
	self:changeQueue(nil)
	self.specialRole = 0
	self.isWaterMode = false
	return SKIP_THIS_TASK
end

function changeQueueToCommanderBaseBuilderIfNeeded(self)
	if (not self.ai.unitHandler.baseUnderAttack and self.isAttackMode) then
		local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")
		local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(self.ai.id,"energy")
	
		-- if low on resource income or factories, rebuild base	
		if (incomeM < 20 or incomeE < 200) or (countOwnUnits(self,nil,1,TYPE_PLANT) < 1)  then
			self:changeQueue(stratCommander)
			self.isAttackMode = false
			-- log("changed to base builder commander!",self.ai) --DEBUG
		end
	end
	return SKIP_THIS_TASK
end

function changeQueueToMexUpgraderIfNeeded(self)
	if (self.ai.unitHandler.mexUpgraderCount < self.ai.unitHandler.mexUpgraderCountTarget ) then
	
		local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(self.ai.id,"energy")
	
		local l1Mexes = countOwnUnits(self,nil,0,TYPE_MEX)
		local allMexes = countOwnUnits(self,nil,0,TYPE_EXTRACTOR)
		if self.ai.useStrategies or (l1Mexes > 0 and (incomeE > 400 or incomeE - expenseE > 150)) then
			self:changeQueue(mexUpgraderQueueByFaction[self.unitSide])
			self.specialRole = UNIT_ROLE_MEX_UPGRADER
			self.ai.unitHandler.mexUpgraderCount = self.ai.unitHandler.mexUpgraderCount + 1
		end
	end	
	return SKIP_THIS_TASK
end

function changeQueueToMexBuilderIfNeeded(self)
	local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")
	
	-- check if there are spots available
	if( (self.ai.unitHandler.enemyExtractorCount + self.ai.unitHandler.friendlyExtractorCount) / #self.ai.mapHandler.spots > FREE_METAL_SPOT_EXPANSION_THRESHOLD ) then
		return SKIP_THIS_TASK
	end

	if self.ai.unitHandler.mexBuilderCount < self.ai.unitHandler.mexBuilderCountTarget then
		self:changeQueue(mexBuilderQueueByFaction[self.unitSide])
		
		self.noDelay = true
		self.specialRole = UNIT_ROLE_MEX_BUILDER
		self.ai.unitHandler.mexBuilderCount = self.ai.unitHandler.mexBuilderCount + 1
	end
	
	return SKIP_THIS_TASK
end


function changeQueueToDefenseBuilderIfNeeded(self)

	if self.ai.unitHandler.mostVulnerableCell ~= nil and self.ai.unitHandler.defenseBuilderCount < self.ai.unitHandler.defenseBuilderCountTarget then
		self:changeQueue(defenseBuilderQueueByFaction[self.unitSide])
		
		self.ai.unitHandler.defenseBuilderCount = self.ai.unitHandler.defenseBuilderCount + 1
		self.noDelay = false
		self.specialRole = UNIT_ROLE_DEFENSE_BUILDER
	end
	
	return SKIP_THIS_TASK
end

function changeQueueToAdvancedDefenseBuilderIfNeeded(self)

	if self.ai.unitHandler.mostVulnerableCell ~= nil and self.ai.unitHandler.advancedDefenseBuilderCount < self.ai.unitHandler.advancedDefenseBuilderCountTarget then
		self:changeQueue(advancedDefenseBuilderQueueByFaction[self.unitSide])

		self.ai.unitHandler.advancedDefenseBuilderCount = self.ai.unitHandler.advancedDefenseBuilderCount + 1		
		self.noDelay = false
		self.specialRole = UNIT_ROLE_ADVANCED_DEFENSE_BUILDER		
	end
	
	return SKIP_THIS_TASK
end

function buildEnergyIfNeeded(self,unitName)
	local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")
	local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(self.ai.id,"energy")

	local threshold = max(max(1.4 * expenseE + 100, 8 * incomeM + 50),300)
	if incomeE < threshold then
		--log("buildEnergyIfNeeded: income "..incomeE..", usage "..expenseE..", building more energy",self.ai)
		return unitName
	else
		return SKIP_THIS_TASK
	end
end

-- set up some static defense if near building clusters which aren't covered by any
function defendNearbyBuildingsIfNeeded(self,safeFraction)
	local ownUnitIds = self.ai.ownUnitIds
	local unitCount = 0
	local pos = self.pos
	if (self.ai.unitHandler.focusOnEndGameArmy) then
		return SKIP_THIS_TASK 
	end
	
	local ownBuildingCell = getNearbyCellIfExists(self.ai.unitHandler.ownBuildingCells, pos)
	if (ownBuildingCell ~= nil) then 
		local ownCell = getNearbyCellIfExists(self.ai.unitHandler.ownCells, pos)
		if (ownCell ~= nil) then 
			local nearbyEconomyCost = ownCell.nearbyEconomyCost or 0
			local extractorCount = ownCell.extractorCount or 0
			local buildingCount = ownCell.buildingCount or 0
			local defenderCost = ownCell.nearbyDefenderCost or 0
			local underwaterDefenderCost = ownCell.nearbyUnderwaterDefenderCost or 0
			
			if buildingCount > 0 then
				local valueToProtect = nearbyEconomyCost + 150 * extractorCount
				
				local defenseDensityMult = 1
				if (self.ai.useStrategies) then
					local currentStrategy = self.ai.currentStrategy
					local currentStrategyName = self.ai.currentStrategyName
					local sStage = self.ai.currentStrategyStage
					defenseDensityMult = currentStrategy.stages[sStage].properties.defenseDensityMult or 1
					
					if (self.ai.humanDefenseDensityMult ~= nil) then
						if self.ai.humanDefenseDensityMult == 0 then
							return SKIP_THIS_TASK
						else
							defenseDensityMult = self.ai.humanDefenseDensityMult
						end
					end
				end
				
				--if self.ai.id == 0 then log("watermode="..tostring(self.isWaterMode).." uwdefCost="..underwaterDefenderCost.." valueToProtect="..valueToProtect,self.ai) end	--DEBUG
				
				-- if there's important stuff here that hasn't been properly defended
				local HIGH_VALUE_THRESHOLD = 3000
				if valueToProtect > HIGH_VALUE_THRESHOLD then
					local action = SKIP_THIS_TASK
					-- heavy defense	
					if (self.isAdvBuilder) then
						if(self.isWaterMode == true and underwaterDefenderCost < safeFraction * valueToProtect) then
							return lev2TorpedoDefenseByFaction[self.unitSide] 
						elseif (defenderCost < safeFraction * valueToProtect) then
							local unitName = heavyAAByFaction[self.unitSide][ random( 1, tableLength(heavyAAByFaction[self.unitSide]) ) ]
							action = checkAreaLimit(self, unitName, self.unitId, (1+valueToProtect/HIGH_VALUE_THRESHOLD)*defenseDensityMult, BIG_RADIUS, TYPE_HEAVY_AA)
							if action ~= SKIP_THIS_TASK then
								return action
							end
						end
					else
						if(self.isWaterMode == true and underwaterDefenderCost < safeFraction * valueToProtect) then
							return lev1TorpedoDefenseByFaction[self.unitSide] 
						elseif (defenderCost < safeFraction * valueToProtect) then
							if (self.unitSide == "claw" or self.unitSide == "sphere") then
								local unitName = mediumAAByFaction[self.unitSide]
								action = checkAreaLimit(self,unitName, self.unitId, 1*defenseDensityMult, BIG_RADIUS, TYPE_LIGHT_AA)
								if action ~= SKIP_THIS_TASK then
									return action
								end
							elseif(self.unitSide == "aven" or self.unitSide == "gear") then
								local unitName = lev1HeavyDefenseByFaction[self.unitSide][ random( 1, tableLength(lev1HeavyDefenseByFaction[self.unitSide]) ) ]
								action = checkAreaLimit(self,unitName, self.unitId, 1*defenseDensityMult, BIG_RADIUS, TYPE_HEAVY_DEFENSE)
								if action ~= SKIP_THIS_TASK then
									return action
								end
							end
						end
					end					
				elseif (defenderCost < safeFraction * valueToProtect) then
					-- light defense
					if lightAAByFaction[self.unitSide] then
						return lightAAByFaction[self.unitSide]
					end
					return mediumAAByFaction[self.unitSide]
				end
			end
		end
	end
	

	return SKIP_THIS_TASK
end

function changeQueueToLightGroundRaidersIfNeeded(self)

	-- 30% probability to go raiders
	if (random( 1, 10) > 6) then 
		self:changeQueue(lightGroundRaiderQueueByFaction[self.unitSide])
	end
	
	return SKIP_THIS_TASK
end

function advMetalExtractor(self)
	self.noDelay = true
	local unitName = SKIP_THIS_TASK

	if (self.ai.useStrategies) then
		local currentStrategy = self.ai.currentStrategy
		local sStage = self.ai.currentStrategyStage
			
		local useHazardousExtractors = currentStrategy.stages[sStage].economy.useHazardousExtractors
		if (useHazardousExtractors) then
			unitName = hazMexByFaction[self.unitSide]
		else
			unitName = mohoMineByFaction[self.unitSide]
		end
	else		
		unitName = mohoMineByFaction[self.unitSide]
	end

	return unitName		
end

function basePatrolIfNeeded(self)

	if self.ai.unitHandler.basePatrollerCount < self.ai.unitHandler.basePatrollerCountTarget then
		self.ai.unitHandler.basePatrollerCount = self.ai.unitHandler.basePatrollerCount + 1
		local basePos = self.ai.unitHandler.basePos
		local baseX = basePos.x
		local baseZ = basePos.z
		local radius = BASE_AREA_PATROL_RADIUS / 2
		
		local movePos = newPosition(baseX - (radius + random( 1, radius)),0,baseZ)
		if (spTestMoveOrder(self.unitDefId,movePos.x,movePos.y,movePos.z)) then
			spGiveOrderToUnit(self.unitId,CMD.PATROL,{movePos.x,movePos.y,movePos.z},EMPTY_TABLE)
		end
	
		movePos.x=baseX + (radius + random( 1, radius))
		if (spTestMoveOrder(self.unitDefId,movePos.x,movePos.y,movePos.z)) then
			spGiveOrderToUnit(self.unitId,CMD.PATROL,{movePos.x,movePos.y,movePos.z},CMD.OPT_SHIFT)
		end
	
		movePos.x=baseX
		movePos.z=baseZ + (radius + random( 1, radius))
		if (spTestMoveOrder(self.unitDefId,movePos.x,movePos.y,movePos.z)) then
			spGiveOrderToUnit(self.unitId,CMD.PATROL,{movePos.x,movePos.y,movePos.z},CMD.OPT_SHIFT)
		end
			
		movePos.z=baseZ - (radius + random( 1, radius))
		if (spTestMoveOrder(self.unitDefId,movePos.x,movePos.y,movePos.z)) then
			spGiveOrderToUnit(self.unitId,CMD.PATROL,{movePos.x,movePos.y,movePos.z},CMD.OPT_SHIFT)
		end
	
		self.specialRole = UNIT_ROLE_BASE_PATROLLER
		 
		-- do it for a few seconds
		return {action="wait_idle", frames=300}
	end
	return SKIP_THIS_TASK
end


function briefAreaPatrol(self)
	-- if unit is far away from base center, move to center and then retry
	if farFromBaseCenter(self)  then
		self:retry()
		return moveBaseCenter(self)
	end
	
	local selfPos = self.pos
	local radius = BRIEF_AREA_PATROL_RADIUS / 2 
	
	local movePos = newPosition(selfPos.x - (radius + random( 1, radius)),selfPos.y,selfPos.z)
	if (spTestMoveOrder(self.unitDefId,movePos.x,movePos.y,movePos.z)) then
		spGiveOrderToUnit(self.unitId,CMD.PATROL,{movePos.x,movePos.y,movePos.z},EMPTY_TABLE)
	end

	movePos.x=selfPos.x + (radius + random( 1, radius))
	if (spTestMoveOrder(self.unitDefId,movePos.x,movePos.y,movePos.z)) then
		spGiveOrderToUnit(self.unitId,CMD.PATROL,{movePos.x,movePos.y,movePos.z},CMD.OPT_SHIFT)
	end

	movePos.x=selfPos.x
	movePos.z=selfPos.z + (radius + random( 1, radius))
	if (spTestMoveOrder(self.unitDefId,movePos.x,movePos.y,movePos.z)) then
		spGiveOrderToUnit(self.unitId,CMD.PATROL,{movePos.x,movePos.y,movePos.z},CMD.OPT_SHIFT)
	end
		
	movePos.z=selfPos.z - (radius + random( 1, radius))
	if (spTestMoveOrder(self.unitDefId,movePos.x,movePos.y,movePos.z)) then
		spGiveOrderToUnit(self.unitId,CMD.PATROL,{movePos.x,movePos.y,movePos.z},CMD.OPT_SHIFT)
	end
	
	-- do it for some time
	return {action="wait", frames=300}
end


function staticBriefAreaPatrol(self)
	local selfPos = self.pos
	local radius = 100 
	
	local movePos = newPosition(selfPos.x - (radius + random( 1, radius)),selfPos.y,selfPos.z)
	spGiveOrderToUnit(self.unitId,CMD.PATROL,{movePos.x,movePos.y,movePos.z},EMPTY_TABLE)
	movePos.x=selfPos.x + (radius + random( 1, radius))
	spGiveOrderToUnit(self.unitId,CMD.PATROL,{movePos.x,movePos.y,movePos.z},CMD.OPT_SHIFT)
	
	-- do it for some time
	return {action="wait", frames=STATIC_AREA_PATROL_FRAMES}
end


function moveAtkCenter(self)
	local radius = MED_RADIUS
	local atkPos = self.ai.unitHandler.unitGroups[UNIT_GROUP_ATTACKERS].centerPos 
	local basePos = self.ai.unitHandler.basePos
	
	local p = newPosition()
	p.y = 0
		
	if ( atkPos.x > 0 and atkPos.z >0) then
		p.x = atkPos.x-radius/2+random(1,radius)
		p.z = atkPos.z-radius/2+random(1,radius)
	elseif ( basePos.x > 0 and basePos.z > 0) then
		p.x = basePos.x-radius/2+random(1,radius)
		p.z = basePos.z-radius/2+random(1,radius)
	else
		-- do nothing
		return SKIP_THIS_TASK
	end

	spGiveOrderToUnit(self.unitId,CMD.MOVE,{p.x,p.y,p.z},EMPTY_TABLE)
		
	-- add another order to queue in case the first is invalid
	spGiveOrderToUnit(self.unitId,CMD.MOVE,{p.x - radius/2 + random( 1, radius),0,p.z - radius/2 + random( 1, radius)},CMD.OPT_SHIFT)
	return {action="wait", frames=120}
end

function activateAtkCenter(self)
	local radius = BIG_RADIUS
	local atkPos = self.ai.unitHandler.unitGroups[UNIT_GROUP_ATTACKERS].centerPos 
	local basePos = self.ai.unitHandler.basePos
	
	local p = newPosition()
	p.y = 0
	if ( atkPos.x > 0 and atkPos.z >0) then
		p.x = atkPos.x-radius/2+random(1,radius)
		p.z = atkPos.z-radius/2+random(1,radius)
	elseif ( basePos.x > 0 and basePos.z > 0) then
		p.x = basePos.x-radius/2+random(1,radius)
		p.z = basePos.z-radius/2+random(1,radius)
	else
		-- just activate
		spGiveOrderToUnit(self.unitId,CMD.ONOFF,TABLE_WITH_ONE,EMPTY_TABLE)

		return SKIP_THIS_TASK
	end
	
	if checkWithinDistance(self.pos, p,radius) then
		-- near target position, stop and activate
		spGiveOrderToUnit(self.unitId,CMD.STOP,EMPTY_TABLE,EMPTY_TABLE)
		spGiveOrderToUnit(self.unitId,CMD.ONOFF,TABLE_WITH_ONE,EMPTY_TABLE)
	else	
		-- far from target position, deactivate and move
		spGiveOrderToUnit(self.unitId,CMD.ONOFF,TABLE_WITH_ZERO,EMPTY_TABLE)
		local h = spGetGroundHeight(p.x,p.z)
		if (spGetGroundHeight(p.x,p.z) < 0) then
			for i=1,6,1 do
				local x = p.x-radius/2+random(1,radius)
				local z = p.z-radius/2+random(1,radius)
				if (spGetGroundHeight(x,z) > 0) then
					h = spGetGroundHeight(x,z)
					p.x = x
					p.z = z
					break	
				end
			end
		end

		spGiveOrderToUnit(self.unitId,CMD.MOVE,{p.x,h,p.z},EMPTY_TABLE)
	end
	
	return {action="wait", frames=120}
end

function patrolAtkCenter(self)
	local radius = MED_RADIUS
	
	local attackerGroup = self.ai.unitHandler.unitGroups[UNIT_GROUP_ATTACKERS]
	local atkStrength = attackerGroup.nearCenterCost
	--local raidersStrength = self.ai.unitHandler.unitGroups[UNIT_GROUP_RAIDERS].nearCenterCost
	local seaAtkStrength = self.ai.unitHandler.unitGroups[UNIT_GROUP_SEA_ATTACKERS].nearCenterCost

	if seaAtkStrength > atkStrength then
		attackerGroup = self.ai.unitHandler.unitGroups[UNIT_GROUP_SEA_ATTACKERS]
	end

	local atkPos = attackerGroup.centerPos
	local basePos = self.ai.unitHandler.basePos
	
	local p = newPosition()
	p.y = 0
		
	if ( atkPos.x > 0 and atkPos.z >0) then
		p.x = atkPos.x-radius/2+random(1,radius)
		p.z = atkPos.z-radius/2+random(1,radius)
	elseif ( basePos.x > 0 and basePos.z > 0) then
		p.x = basePos.x-radius/2+random(1,radius)
		p.z = basePos.z-radius/2+random(1,radius)
	else
		-- do nothing
		return SKIP_THIS_TASK
	end

	local f = spGetGameFrame()
	
	-- do not give the orders if already there
	if (distance(self.pos,p) > BIG_RADIUS) then
		spGiveOrderToUnit(self.unitId,CMD.MOVE,{p.x,p.y,p.z},EMPTY_TABLE)			
		spGiveOrderToUnit(self.unitId,CMD.PATROL,{p.x - BRIEF_AREA_PATROL_RADIUS/2 + random( 1, BRIEF_AREA_PATROL_RADIUS),0,p.z - BRIEF_AREA_PATROL_RADIUS/2 + random( 1, BRIEF_AREA_PATROL_RADIUS)},CMD.OPT_SHIFT)
	--elseif (f - self.idleFrame < 90 or self.distance(self.pos,p) > MED_RADIUS) then
	elseif (true) then
		spGiveOrderToUnit(self.unitId,CMD.PATROL,{p.x,p.y,p.z},EMPTY_TABLE)			
		spGiveOrderToUnit(self.unitId,CMD.PATROL,{p.x - BRIEF_AREA_PATROL_RADIUS/2 + random( 1, BRIEF_AREA_PATROL_RADIUS),0,p.z - BRIEF_AREA_PATROL_RADIUS/2 + random( 1, BRIEF_AREA_PATROL_RADIUS)},CMD.OPT_SHIFT)
	end
	
	return {action="wait", frames=120}
end

function commanderRoam(self)
	--local atkPos = self.ai.unitHandler.unitGroups[UNIT_GROUP_RAIDERS].centerPos
	local basePos = self.ai.unitHandler.basePos
	
	-- log("commander roam "..#(self.ai.unitHandler.raiderPath[PF_UNIT_AMPHIBIOUS]),self.ai) --DEBUG
	local raidingPathCellList = self.ai.unitHandler.raiderPath[PF_UNIT_AMPHIBIOUS]

	-- ensure safety only when moving far away from base
	if (distance(self.pos,basePos) < HUGE_RADIUS) then
		self:orderToClosestCellAlongPath(raidingPathCellList, {CMD.MOVE,CMD.MOVE}, false, false)
	else
		self:orderToClosestCellAlongPath(raidingPathCellList, {CMD.MOVE,CMD.MOVE}, false, true)
	end
	
	return {action="wait_idle", frames=120}
end


-- build forward defense, maybe
function commanderForwardDefense(self)
	-- non-classic mode only
	if (self.ai.useStrategies) then
		local currentStrategy = self.ai.currentStrategy
		local sStage = self.ai.currentStrategyStage
		roam = currentStrategy.stages[sStage].properties.roamingCommander or false

		local attackerGroup = self.ai.unitHandler.unitGroups[UNIT_GROUP_ATTACKERS]
		local atkPos = attackerGroup.centerPos
		local atkStrength = attackerGroup.nearCenterCost
		local raidersStrength = self.ai.unitHandler.unitGroups[UNIT_GROUP_RAIDERS].nearCenterCost

		-- do this only if roaming
		if (roam or (raidersStrength > atkStrength and (not self.ai.unitHandler.baseUnderAttack))) then
			action = defendNearbyBuildingsIfNeeded(self,0.1)
			if action ~= SKIP_THIS_TASK then
				return action
			end	
		end
	end
	
	
	
	return SKIP_THIS_TASK
end

function commanderPatrol(self)
	local radius = MED_RADIUS
	local attackerGroup = self.ai.unitHandler.unitGroups[UNIT_GROUP_ATTACKERS]
	local atkPos = attackerGroup.centerPos
	local atkStrength = attackerGroup.nearCenterCost
	--local raidersPos = self.ai.unitHandler.unitGroups[UNIT_GROUP_RAIDERS].centerPos
	local raidersStrength = self.ai.unitHandler.unitGroups[UNIT_GROUP_RAIDERS].nearCenterCost
	local enemyPos = attackerGroup.targetPos
	local basePos = self.ai.unitHandler.basePos
	local roam = false
	
	if (self.ai.useStrategies) then
		local currentStrategy = self.ai.currentStrategy
		local sStage = self.ai.currentStrategyStage
		roam = currentStrategy.stages[sStage].properties.roamingCommander or false
	end
	--Spring.Echo(spGetGameFrame().." raiders="..raidersStrength.." atk="..atkStrength)
	if (roam or (raidersStrength > atkStrength and (not self.ai.unitHandler.baseUnderAttack))) then
		--Spring.Echo(spGetGameFrame().." following raiders")
		return commanderRoam(self)
	end
	
	local p = newPosition()
	p.y = 0

	if ( atkPos.x > 0 and atkPos.z >0) then
		p.x = atkPos.x-radius/2+random(1,radius)
		p.z = atkPos.z-radius/2+random(1,radius)
	elseif ( basePos.x > 0 and basePos.z > 0) then
		p.x = basePos.x-radius/2+random(1,radius)
		p.z = basePos.z-radius/2+random(1,radius)
	else
		-- do nothing
		return SKIP_THIS_TASK
	end

	local f = spGetGameFrame()
	
	-- can't reach the attackers, patrol "in place"
	if not self.ai.mapHandler:checkConnection(self.pos, p,self.pFType) then
		-- check if it can't walk to base either
		if not self.ai.mapHandler:checkConnection(self.pos, basePos,self.pFType) then
			self.stuckCounter = self.stuckCounter + 1 
			--Spring.Echo(spGetGameFrame().." can't reach attackers or base! Stuck="..self.stuckCounter)
		else 
			self.stuckCounter = 0
		end
				
		if (self.stuckCounter == 5) then
			-- probably fell into a hole, selfdestruct!
			spGiveOrderToUnit(self.unitId,CMD.SELFD,EMPTY_TABLE,EMPTY_TABLE)
		else
			spGiveOrderToUnit(self.unitId,CMD.MOVE,{self.pos.x  - 120 + random( 1, 240),self.pos.y,self.pos.z - 120 + random( 1, 240)},EMPTY_TABLE)	
			spGiveOrderToUnit(self.unitId,CMD.PATROL,{self.pos.x - 120 + random( 1, 240),self.pos.y,self.pos.z -120 + random( 1, 240)},CMD.OPT_SHIFT)
			spGiveOrderToUnit(self.unitId,CMD.PATROL,{self.pos.x - 120 + random( 1, 240),self.pos.y,self.pos.z -120 + random( 1, 240)},CMD.OPT_SHIFT)
		end
	else
		self.stuckCounter = 0
		
		-- group attacking, move to the front line
		if (attackerGroup.task == TASK_ATTACK ) then
			-- multiple waypoints for zigzaggy behavior
			local altPos1 = newPosition()
			altPos1.x = (0.7*p.x+0.3*enemyPos.x) - COMMANDER_ATTACK_ZIGZAG_DISTANCE/2 + random( 1, COMMANDER_ATTACK_ZIGZAG_DISTANCE)
			altPos1.z = (0.7*p.z+0.3*enemyPos.z) - COMMANDER_ATTACK_ZIGZAG_DISTANCE/2 + random( 1, COMMANDER_ATTACK_ZIGZAG_DISTANCE)
			altPos1.y = spGetGroundHeight(altPos1.x,altPos1.z)

			local altPos2 = newPosition()
			altPos2.x = (0.6*p.x+0.4*enemyPos.x) - COMMANDER_ATTACK_ZIGZAG_DISTANCE/2 + random( 1, COMMANDER_ATTACK_ZIGZAG_DISTANCE)
			altPos2.z = (0.6*p.z+0.4*enemyPos.z) - COMMANDER_ATTACK_ZIGZAG_DISTANCE/2 + random( 1, COMMANDER_ATTACK_ZIGZAG_DISTANCE)
			altPos2.y = spGetGroundHeight(altPos2.x,altPos2.z)
			
			local altPos3 = newPosition()
			altPos3.x = (0.5*p.x+0.5*enemyPos.x) - COMMANDER_ATTACK_ZIGZAG_DISTANCE/2 + random( 1, COMMANDER_ATTACK_ZIGZAG_DISTANCE)
			altPos3.z = (0.5*p.z+0.5*enemyPos.z) - COMMANDER_ATTACK_ZIGZAG_DISTANCE/2 + random( 1, COMMANDER_ATTACK_ZIGZAG_DISTANCE)
			altPos3.y = spGetGroundHeight(altPos3.x,altPos3.z)
			
			spGiveOrderToUnit(self.unitId,CMD.MOVE,{altPos1.x,altPos1.y,altPos1.z},EMPTY_TABLE)
			spGiveOrderToUnit(self.unitId,CMD.MOVE,{altPos2.x,altPos2.y,altPos2.z},CMD.OPT_SHIFT)
			spGiveOrderToUnit(self.unitId,CMD.MOVE,{altPos3.x,altPos3.y,altPos3.z},CMD.OPT_SHIFT)
		else
		-- patrol/repair
			local firstCmd = CMD.PATROL
			-- move there or patrol if already nearby	
			if distance(self.pos,p) > BIG_RADIUS then
				firstCmd = CMD.MOVE
			end
				
			-- get a position to patrol 
			patrolPos = newPosition()
			patrolPos.x = p.x - BRIEF_AREA_PATROL_RADIUS/2 + random( 1, BRIEF_AREA_PATROL_RADIUS)
			patrolPos.z = p.z - BRIEF_AREA_PATROL_RADIUS/2 + random( 1, BRIEF_AREA_PATROL_RADIUS)
			patrolPos.y = spGetGroundHeight(patrolPos.x,patrolPos.z)
			 
			-- test if that position is reachable
			if self.ai.mapHandler:checkConnection(self.pos, p,self.pFType) and self.ai.mapHandler:checkConnection(self.pos, patrolPos,self.pFType) then
				spGiveOrderToUnit(self.unitId,firstCmd,{p.x,p.y,p.z},EMPTY_TABLE)
				spGiveOrderToUnit(self.unitId,CMD.PATROL,{patrolPos.x,patrolPos.y,patrolPos.z},CMD.OPT_SHIFT)
			else
				-- if not just patrol in place
				spGiveOrderToUnit(self.unitId,CMD.PATROL,{self.pos.x  - 60 + random( 1, 120),self.pos.y,self.pos.z - 60 + random( 1, 120)},EMPTY_TABLE)
				spGiveOrderToUnit(self.unitId,CMD.PATROL,{p.x - 60 + random( 1, 120),p.y,p.z- 60 + random( 1, 120)},CMD.OPT_SHIFT)
				spGiveOrderToUnit(self.unitId,CMD.PATROL,{p.x - 60 + random( 1, 120),p.y,p.z- 60 + random( 1, 120)},CMD.OPT_SHIFT)
			end
		end

	end
	
	return {action="wait", frames=120}
end

function scoutRandomly(self)
	local basePos = self.ai.unitHandler.basePos
	if (not basePos) then
		basePos = self.pos
	end
	
	-- select two random cells away from the base position
	local cells = self.ai.mapHandler.mapCells
	local cellCountX = math.ceil(Game.mapSizeX / CELL_SIZE)
	local cellCountZ = math.ceil(Game.mapSizeZ / CELL_SIZE)
	local p1 = nil
	local p2 = nil
	local sqMinRadius = HUGE_RADIUS * HUGE_RADIUS  
	local tries = 0
	local c1 = nil
	local c2 = nil
	
	while tries < 10 and (p1 == nil or p2 == nil) do
		c1 = cells[math.random(2,cellCountX-1)][math.random(2,cellCountZ-1)]		
		c2 = cells[math.random(2,cellCountX-1)][math.random(2,cellCountZ-1)]
		
		-- check min distance between cells and base and each other
		if (sqDistance(c1.p.x,c2.p.x,c1.p.z,c2.p.z) > sqMinRadius) and (sqDistance(basePos.x,c1.p.x,basePos.z,c1.p.z) > sqMinRadius) and (sqDistance(basePos.x,c2.p.x,basePos.z,c2.p.z) > sqMinRadius) then
			p1 = c1.p
			p2 = c2.p		
		end 
		
		tries = tries +1
	end
	
	if (p1 ~= nil and p2 ~= nil) then 	
		p1 = newPosition(p1.x,p1.y,p1.z)
		p2 = newPosition(p2.x,p2.y,p2.z)
	
		local f = spGetGameFrame()
		
		-- do not give the orders if already there
		if (distance(self.pos,p1) > BIG_RADIUS) then
			spGiveOrderToUnit(self.unitId,CMD.MOVE,{p1.x,p1.y,p1.z},EMPTY_TABLE)			
			spGiveOrderToUnit(self.unitId,CMD.PATROL,{p2.x,0,p2.z},CMD.OPT_SHIFT)
		else
			spGiveOrderToUnit(self.unitId,CMD.PATROL,{p1.x,p1.y,p1.z},EMPTY_TABLE)			
			spGiveOrderToUnit(self.unitId,CMD.PATROL,{p2.x,0,p2.z},CMD.OPT_SHIFT)
		end

	else
		--log("could not find scout cells!",self.ai)
		-- do nothing
		return SKIP_THIS_TASK
	end
	
	return {action="wait", frames=3000}
end

function moveBaseCenter(self)
	local radius = BIG_RADIUS
	local basePos = self.ai.unitHandler.basePos
	
	if ( basePos.x > 0 and basePos.z > 0 and farFromBaseCenter(self, BIG_RADIUS)) then
		p = newPosition()
		p.x = basePos.x-radius/2+random(1,radius)
		p.z = basePos.z-radius/2+random(1,radius)
		p.y = 0
		spGiveOrderToUnit(self.unitId,CMD.MOVE,{p.x,p.y,p.z},EMPTY_TABLE)
		
		-- add another order to queue in case the first is invalid
		spGiveOrderToUnit(self.unitId,CMD.MOVE,{p.x - radius/2 + random( 1, radius),p.y,p.z - radius/2 + random( 1, radius)},CMD.OPT_SHIFT)
	
		-- wait a bit to let the move order finish
		return {action="wait_idle", frames=300}
	end
	
	return SKIP_THIS_TASK
end


function moveVulnerablePos(self)
	local radius = BIG_RADIUS
	local cellPos = self.ai.unitHandler.mostVulnerableCell.p
	
	if ( cellPos.x > 0 and cellPos.z > 0 ) then
		p = newPosition()
		p.x = cellPos.x-radius/2+random(1,radius)
		p.z = cellPos.z-radius/2+random(1,radius)
		p.y = 0
		spGiveOrderToUnit(self.unitId,CMD.MOVE,{p.x,p.y,p.z},EMPTY_TABLE)
		
		-- add another order to queue in case the first is invalid
		spGiveOrderToUnit(self.unitId,CMD.MOVE,{p.x - radius/2 + random( 1, radius),p.y,p.z - radius/2 + random( 1, radius)},CMD.OPT_SHIFT)
	
		-- wait a bit to let the move order finish
		return {action="wait_idle", frames=1800}
	end
	
	return SKIP_THIS_TASK
end

-- move to a safe position before attempting to build expensive stuff
-- TODO better to just move to base center, needs improvement
function moveSafePos(self)
	local radius = BIG_RADIUS
	
	--[[
	local cellPos = self.ai.unitHandler.leastVulnerableCell.p
	
	if ( cellPos.x > 0 and cellPos.z > 0 ) then
		p = newPosition()
		p.x = cellPos.x-radius/2+random(1,radius)
		p.z = cellPos.z-radius/2+random(1,radius)
		p.y = 0


		spGiveOrderToUnit(self.unitId,CMD.MOVE,{p.x,p.y,p.z},EMPTY_TABLE)
		
		-- add another order to queue in case the first is invalid
		spGiveOrderToUnit(self.unitId,CMD.MOVE,{p.x - radius/2 + random( 1, radius),p.y,p.z - radius/2 + random( 1, radius)},CMD.OPT_SHIFT)
	
		-- wait a bit to let the move order finish
		return {action="wait_idle", frames=1800}
	end
	]]--
	
	return moveBaseCenter(self)
end


-- build storage if needed
function storageIfNeeded(self)
	local unitName = SKIP_THIS_TASK

	if unitName == SKIP_THIS_TASK then
		unitName = buildWithLimitedNumber(self, energyStorageByFaction[self.unitSide],1)
	end
	if unitName == SKIP_THIS_TASK then
		unitName = buildWithLimitedNumber(self, metalStorageByFaction[self.unitSide],1)
	end	
	if unitName == SKIP_THIS_TASK then
		local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(self.ai.id,"energy")

		if currentLevelE >= 0.9 * storageE then
			unitName = buildWithLimitedNumber(self, energyStorageByFaction[self.unitSide], math.floor(1+math.floor(incomeE/700),ENERGY_STORAGE_LIMIT)) 
		end
	end
	if unitName == SKIP_THIS_TASK then
		local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")

		if currentLevelM >= 0.9 * storageM then
			unitName = buildWithLimitedNumber(self, metalStorageByFaction[self.unitSide],math.floor(1+math.floor(incomeM/25),METAL_STORAGE_LIMIT))		
		end
	end

	return unitName
end

function windSolar(self)
	if ((Game.windMax+Game.windMin)/2 > 10) and (random(1,10) <=5) then
		return windByFaction[self.unitSide]
	else
		return solarByFaction[self.unitSide]
	end
end


-- how many unitName or similar units do we own
function countOwnUnits(self,unitName, maxCount, type)
	local unitCount = 0
	if unitName == SKIP_THIS_TASK then
		return 0
	end
	
	for uId,_ in pairs(self.ai.ownUnitIds) do
		local un = UnitDefs[spGetUnitDefID(uId)].name
		if ((unitName ~= nil and un == unitName) or (type ~= nil and setContains(unitTypeSets[type],un)) ) then
			unitCount = unitCount + 1
			if maxCount ~= nil and maxCount > 0 and unitCount >= maxCount then
				break
			end
		end
	end
	return unitCount
end

function buildWithLimitedNumber(self,tmpUnitName, maxNumber, type)
	local unitCount = 0

	if tmpUnitName == SKIP_THIS_TASK then
		return tmpUnitName
	end
	for uId,_ in pairs(self.ai.ownUnitIds) do
		local un = UnitDefs[spGetUnitDefID(uId)].name
		if un == tmpUnitName or (type ~= nil and setContains(unitTypeSets[type],un)) then
			unitCount = unitCount + 1
		end
		if unitCount >= maxNumber then
			break
		end
	end
	if unitCount >= maxNumber then
		return SKIP_THIS_TASK
	else
		return tmpUnitName
	end
end

function buildWithMinimalMetalIncome(self,unitName, minNumber)
	local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")

	if incomeM < minNumber then
		return SKIP_THIS_TASK
	else
		return unitName
	end
end

-- build something only if we produce at least this much energy, and our e-storage is at least 3/4 full (so probably no estall)
function buildWithMinimalEnergyIncome(self,unitName, minNumber)
	local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(self.ai.id,"energy")
	if ( incomeE < minNumber) or ( currentLevelE < 0.75 * storageE) then
		return SKIP_THIS_TASK
	else
		return unitName
	end
end

function buildWithExtraEnergyIncome(self,unitName, minNumber)
	local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(self.ai.id,"energy")
	if incomeE - expenseE < minNumber then
		return SKIP_THIS_TASK
	else
		return unitName
	end
end

function buildWithExtraMetalIncome(self,unitName, minNumber)
	local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")
	-- log("buildWithExtraMetalIncome: income "..res.income..", usage "..res.expense..", threshold "..minNumber, self.ai)
	if incomeM - expenseM < minNumber then
		return SKIP_THIS_TASK
	else
		return unitName
	end
end


function scoutPadIfNeeded(self)
	local unitName = scoutPadByFaction[self.unitSide] 
	unitName = buildWithLimitedNumber(self, unitName, 1) 
	
	-- if unit is far away from base center, move to center and then retry
	if unitName ~= SKIP_THIS_TASK and farFromBaseCenter(self)  then
		self:retry()
		return moveBaseCenter(self)
	end	
	
	return unitName
end

function airScoutIfNeeded(self)
	local unitName = airScoutByFaction[self.unitSide] 
	local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")

	unitName = buildWithLimitedNumber(self, unitName, 1 + math.floor(incomeM/30)) 
	return unitName
end


function lvl1PlantIfNeeded(self)
	-- exclude aircraft factories at first
	local excludeAir = 0 	
	if (countOwnUnits(self, nil,2,TYPE_L1_PLANT) < 1) then
		excludeAir = 1
	end

	local unitName = lev1PlantByFaction[self.unitSide][ random( 1, tableLength(lev1PlantByFaction[self.unitSide]) - excludeAir ) ] 
	local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")

	unitName = buildWithLimitedNumber(self, unitName, 1 + math.floor((30+incomeM)/70), TYPE_L1_PLANT) 
	
	-- if unit is far away from base center, move to center and then retry
	if unitName ~= SKIP_THIS_TASK and farFromBaseCenter(self)  then
		self:retry()
		return moveBaseCenter(self)
	end	
	
	return unitName
end


function lvl2PlantIfNeeded(self)
	-- exclude aircraft factories at first
	local excludeAir = 0 	
	if (countOwnUnits(self, nil,1,TYPE_L2_PLANT) < 1) then
		excludeAir = 1
	end

	local unitName = lev2PlantByFaction[self.unitSide][ random( 1, tableLength(lev2PlantByFaction[self.unitSide])- excludeAir ) ]
	local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")
	local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(self.ai.id,"energy")

	-- if low on energy, skip
	--if currentLevelE < 0.2*storageE or incomeE < 0.8*expenseE then
	--	return SKIP_THIS_TASK
	--end 

	unitName = buildWithLimitedNumber(self, unitName, 0 + math.floor((10+incomeM)/30), TYPE_L2_PLANT)

	-- if unit is far away from base center, move to center and then retry
	if unitName ~= SKIP_THIS_TASK and farFromBaseCenter(self)  then
		self:retry()
		return moveBaseCenter(self)
	end	
	
	return unitName
end

function upgradeCenterIfNeeded(self)
	-- skip this on easy mode
	if(self.isEasyMode) then
		return SKIP_THIS_TASK
	end
	
	if (countOwnUnits(self, nil,1,TYPE_UPGRADE_CENTER) > 0) then
		return SKIP_THIS_TASK
	end

	local unitName = upgradeCenterByFaction[self.unitSide]
	local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")
	local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(self.ai.id,"energy")

	-- if low on energy, skip
	if currentLevelE < 0.5*storageE or incomeE < expenseE + 100 then
		return SKIP_THIS_TASK
	end 

	-- if unit is far away from base center, move to center and then retry
	if unitName ~= SKIP_THIS_TASK and farFromBaseCenter(self)  then
		self:retry()
		return moveBaseCenter(self)
	end	
	
	return unitName
end


function lvl1WaterPlantIfNeeded(self)
	-- exclude aircraft factories at first
	local excludeAir = 0 	
	if (countOwnUnits(self, nil,2,TYPE_L1_PLANT) < 1) then
		excludeAir = 1
	end

	local unitName = lev1WaterPlantByFaction[self.unitSide][ random( 1, tableLength(lev1WaterPlantByFaction[self.unitSide]) - excludeAir ) ] 
	local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")

	unitName = buildWithLimitedNumber(self, unitName, 2 + math.floor(incomeM/30), TYPE_L1_PLANT) 
	
	-- if unit is far away from base center, move to center and then retry
	if unitName ~= SKIP_THIS_TASK and farFromBaseCenter(self)  then
		self:retry()
		return moveBaseCenter(self)
	end	
	
	return unitName
end


function lvl2WaterPlantIfNeeded(self)
	-- exclude aircraft factories at first
	local excludeAir = 0 	
	if (countOwnUnits(self, nil,1,TYPE_L2_PLANT) < 1) then
		excludeAir = 1
	end


	local unitName = lev2WaterPlantByFaction[self.unitSide][ random( 1, tableLength(lev2WaterPlantByFaction[self.unitSide])- excludeAir ) ]
	local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")

	unitName = buildWithLimitedNumber(self, unitName, 0 + math.floor((10+incomeM)/30), TYPE_L2_PLANT)

	-- if unit is far away from base center, move to center and then retry
	if unitName ~= SKIP_THIS_TASK and farFromBaseCenter(self)  then
		self:retry()
		return moveBaseCenter(self)
	end	
	
	return unitName
end


function brutalPlant(self)
	if self.isBrutalMode and not self.ai.unitHandler.brutalPlantDone then
		self.ai.unitHandler.brutalPlantDone = true
		return lvl1PlantIfNeeded(self)
	end
	
	return SKIP_THIS_TASK
end




function brutalAirPlant(self)
	if self.isBrutalMode and not self.ai.unitHandler.brutalAirPlantDone then
		if (countOwnUnits(self, nil,4,TYPE_L1_PLANT) < 3) then
			self.ai.unitHandler.brutalAirPlantDone = true
			return lev1PlantByFaction[self.unitSide][ tableLength(lev1PlantByFaction[self.unitSide]) ]		
		end
	end
	
	return SKIP_THIS_TASK
end


function brutalLightDefense(self)
	if self.isBrutalMode and not self.ai.unitHandler.brutalLightDefenseDone then
		self.ai.unitHandler.brutalLightDefenseDone = true
		return lltByFaction[self.unitSide]
		--return areaLimit_Llt(self)
	end
	
	return SKIP_THIS_TASK
end

function brutalAADefense(self)
	if self.isBrutalMode and not self.ai.unitHandler.brutalAADefenseDone then
		self.ai.unitHandler.brutalAADefenseDone = true
		if lightAAByFaction[self.unitSide] then
			return lightAAByFaction[self.unitSide]
		end
		return mediumAAByFaction[self.unitSide]
		--return areaLimit_LightAA(self)
	end
	
	return SKIP_THIS_TASK
end

function brutalHeavyDefense(self)
	if self.isBrutalMode and not self.ai.unitHandler.brutalHeavyDefenseDone then
		self.ai.unitHandler.brutalHeavyDefenseDone = true
		return lev1HeavyDefenseByFaction[self.unitSide][ random( 1, tableLength(lev1HeavyDefenseByFaction[self.unitSide]) ) ]
		--return areaLimit_L1HeavyDefense(self)
	end
	
	return SKIP_THIS_TASK
end


function respawnIfNeeded(self)
	local unitName = "commander_token"
	
    -- respawn commander on this spot only if there are no enemies nearby
	if areEnemiesNearby(self, self.pos, BIG_RADIUS) then
		-- log("enemies are nearby",self.ai)
		return SKIP_THIS_TASK
	else
		if buildWithLimitedNumber(self,unitName, 1, TYPE_COMMANDER) ~= SKIP_THIS_TASK then
			-- log("rebuilding commander",self.ai)
			return unitName
		else
			-- log("commander is alive and well",self.ai)
		end
	end
	
	return SKIP_THIS_TASK
end

function zephyrIfNeeded(self)
	return buildWithLimitedNumber(self,"aven_zephyr", 1, nil) 
end

function geoIfNeeded(self)
	-- don't attempt if there are no spots on the map
	if not self.ai.mapHandler.mapHasGeothermal then
		return SKIP_THIS_TASK
	end

	return buildEnergyIfNeeded(self,geoByFaction[self.unitSide])
end

function fusionIfNeeded(self)
	local unitName = SKIP_THIS_TASK

	if self.ai.useStrategies then
		unitName = buildWithMinimalMetalIncome(self,fusionByFaction[self.unitSide],30)
	else
		unitName = buildWithMinimalMetalIncome(self,buildEnergyIfNeeded(self,fusionByFaction[self.unitSide]),30)
	end
	
	-- if unit is far away from base center, move to center and then retry
	if unitName ~= SKIP_THIS_TASK and farFromBaseCenter(self)  then
		self:retry()
		return moveBaseCenter(self)
	end	

	return unitName
end



function mmakerIfNeeded(self)
	local unitName = SKIP_THIS_TASK

	local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(self.ai.id,"energy")
	
	if (incomeE > 1000 and currentLevelE > 0.5 * storageE) then
		unitName = mmakerByFaction[self.unitSide]
	end
	
	-- if unit is far away from base center, move to center and then retry
	if unitName ~= SKIP_THIS_TASK and farFromBaseCenter(self)  then
		self:retry()
		return moveBaseCenter(self)
	end	

	return unitName
end

function brutalFusion(self)
	if self.isBrutalMode then
		return fusionIfNeeded(self)
	end
	
	return SKIP_THIS_TASK
end

function roughFusionIfNeeded(self)
	local _,_,_,incomeE,_,_,_,_ = spGetTeamResources(self.ai.id,"energy")

	local unitName = SKIP_THIS_TASK
	if incomeE > 400 then
		unitName = buildEnergyIfNeeded(self,"sphere_hardened_fission_reactor")
	else
		unitName = buildEnergyIfNeeded(self,"sphere_fusion_reactor")
	end

	-- if unit is far away from base center, move to center and then retry
	if unitName ~= SKIP_THIS_TASK and farFromBaseCenter(self)  then
		self:retry()
		return moveBaseCenter(self)
	end

	return unitName
end


function patrolAtkCenterIfNeeded(self)
	if self.ai.unitHandler.attackPatrollerCount < self.ai.unitHandler.attackPatrollerCountTarget then
		self.noDelay = true
		self.specialRole = UNIT_ROLE_ATTACK_PATROLLER
		self:changeQueue(attackPatrollerQueue)
		self.ai.unitHandler.attackPatrollerCount = self.ai.unitHandler.attackPatrollerCount +1
		-- local selfPos = newPosition(spGetUnitPosition(self.unitId,false,false))
		-- log(self.unitName.." at ("..selfPos.x.." ; "..selfPos.z..") changed to atk patroller",self.ai)
	end
	return SKIP_THIS_TASK
end

-- how many of our own unitName or similar units there are in a radius around a position
function countOwnUnitsInRadius(self,unitName, pos, radius, maxCount, type)
	local ownUnitIds = self.ai.ownUnitIds
	local unitCount = 0

	local ud = nil
	--[[	
	local ownCell = getNearbyCellIfExists(self.ai.unitHandler.ownBuildingCells, pos)
	if (ownCell ~= nil) then 
		for uId,_ in pairs(ownCell.buildingIdSet) do
			ud = spGetUnitDefID(uId)		
			if ud ~= nil then
				un = UnitDefs[spGetUnitDefID(uId)].name
				if ((unitName ~= nil and un == unitName) or (type ~= nil and setContains(unitTypeSets[type],un)) ) then
					local upos = newPosition(spGetUnitPosition(uId,false,false))
					if checkWithinDistance(pos, upos,radius) then
						unitCount = unitCount + 1
					end
					if maxCount ~= nil and maxCount > 0 and unitCount >= maxCount then
						break
					end
				end
			else
				-- invalid uId entry in building id set, remove
				ownCell.buildingIdSet[uId] = nil 
			end
		end
	end
	]]--
	local buildingIdSet = self.ai.unitHandler.ownBuildingUDefById
	for uId,ud in pairs(buildingIdSet) do
		un = ud.name
		if ((unitName ~= nil and un == unitName) or (type ~= nil and setContains(unitTypeSets[type],un)) ) then
			local upos = newPosition(spGetUnitPosition(uId,false,false))
			if checkWithinDistance(pos, upos,radius) then
				unitCount = unitCount + 1
			end
			if maxCount ~= nil and maxCount > 0 and unitCount >= maxCount then
				break
			end
		end
	end
	
	return unitCount
end

function checkAreaLimit(self,unitName, builder, unitLimit, radius, type)
	-- this is special case, it means the unit will not be built anyway
	if unitName == nil or unitName == SKIP_THIS_TASK then
		return unitName
	end
		
	local pos,_ = self.ai.buildSiteHandler:getBuildSearchPos(self,UnitDefNames[unitName])
	if (pos ~= nil) then
		-- default radius is medium
		if ( radius  == nil ) then
		   radius = MED_RADIUS 
		end
		-- default type disregards similar units
		
		-- now check how many of the wanted unit or similar is nearby
		local NumberOfUnits = countOwnUnitsInRadius(self,unitName, pos, radius, unitLimit, type)
		local AllowBuilding = NumberOfUnits < unitLimit
		-- log(""..unitName.." wanted, with range limit of "..unitLimit..", with "..NumberOfUnits.." already there. The check is: "..tostring(AllowBuilding), self.ai)
		if AllowBuilding then
			return unitName
		else
			return SKIP_THIS_TASK
		end
	end
	return SKIP_THIS_TASK
end

function areaLimit_Llt(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	return checkAreaLimit(self,lltByFaction[self.unitSide], self.unitId, 1, SML_RADIUS, nil)
	
end


function areaLimit_LightAA(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	local unitName = lightAAByFaction[self.unitSide]

	return checkAreaLimit(self,unitName, self.unitId, 4, MED_RADIUS, TYPE_LIGHT_AA)
end



function areaLimit_WaterLightAA(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	local unitName = waterLightAAByFaction[self.unitSide]

	return checkAreaLimit(self,unitName, self.unitId, 4, MED_RADIUS, TYPE_LIGHT_AA)
end


function areaLimit_MediumAA(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	local unitName = mediumAAByFaction[self.unitSide]

	return checkAreaLimit(self,unitName, self.unitId, 2, MED_RADIUS, TYPE_LIGHT_AA)
end

function areaLimit_WaterMediumAA(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	local unitName = waterMediumAAByFaction[self.unitSide]

	return checkAreaLimit(self,unitName, self.unitId, 2, MED_RADIUS, TYPE_LIGHT_AA)
end

function areaLimit_L1HeavyDefense(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	--	if unit is far away from base center, skip construction
--	if farFromBaseCenter(self) then
--		return SKIP_THIS_TASK
--	end	
	
	local unitName = lev1HeavyDefenseByFaction[self.unitSide][ random( 1, tableLength(lev1HeavyDefenseByFaction[self.unitSide]) ) ]
	
	return checkAreaLimit(self,unitName, self.unitId, 1, MED_RADIUS, TYPE_HEAVY_DEFENSE)
end


function areaLimit_WaterL1HeavyDefense(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	--	if unit is far away from base center, skip construction
--	if farFromBaseCenter(self) then
--		return SKIP_THIS_TASK
--	end	
	
	local unitName = lev1WaterHeavyDefenseByFaction[self.unitSide][ random( 1, tableLength(lev1WaterHeavyDefenseByFaction[self.unitSide]) ) ]
	
	return checkAreaLimit(self,unitName, self.unitId, 1, MED_RADIUS, TYPE_HEAVY_DEFENSE)
end


function areaLimit_L1ArtilleryDefense(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	-- if unit is far away from base center, skip construction
--	if farFromBaseCenter(self) then
--		return SKIP_THIS_TASK
--	end	
	
	local unitName = lev1ArtilleryDefenseByFaction[self.unitSide][ random( 1, tableLength(lev1ArtilleryDefenseByFaction[self.unitSide]) ) ]
	
	return checkAreaLimit(self, unitName, self.unitId, 1, BIG_RADIUS, TYPE_ARTILLERY_DEFENSE)
end

function areaLimit_L2HeavyAA(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	-- if unit is far away from base center, skip construction
--	if farFromBaseCenter(self) then
--		return SKIP_THIS_TASK
--	end	
--	if self.ai.unitHandler.threatType ~= THREAT_AIR then
--		return SKIP_THIS_TASK
--	end	
	
	local unitName = heavyAAByFaction[self.unitSide][ random( 1, tableLength(heavyAAByFaction[self.unitSide]) ) ]

	return checkAreaLimit(self, unitName, self.unitId, 1, BIG_RADIUS, TYPE_HEAVY_AA)
end


function areaLimit_L2ArtilleryDefense(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	-- if unit is far away from base center, skip construction
--	if farFromBaseCenter(self) then
--		return SKIP_THIS_TASK
--	end	
	
	local unitName = lev2ArtilleryDefenseByFaction[self.unitSide][ random( 1, tableLength(lev2ArtilleryDefenseByFaction[self.unitSide]) ) ]

	return checkAreaLimit(self, unitName, self.unitId, 1, BIG_RADIUS, TYPE_ARTILLERY_DEFENSE)
end


function areaLimit_L2LongRangeArtillery(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	local unitName = lev2LongRangeArtilleryByFaction[self.unitSide][ random( 1, tableLength(lev2LongRangeArtilleryByFaction[self.unitSide]) ) ]
	
	return buildWithMinimalMetalIncome(self, buildWithMinimalEnergyIncome(self, checkAreaLimit(self, unitName, self.unitId, 4, BIG_RADIUS, TYPE_LONG_RANGE_ARTILLERY),1000),40)
end


function areaLimit_Radar(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	return checkAreaLimit(self,radarByFaction[self.unitSide], self.unitId, 1, BIG_RADIUS, nil)
	
end


function areaLimit_WaterRadar(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	return checkAreaLimit(self,waterRadarByFaction[self.unitSide], self.unitId, 1, BIG_RADIUS, nil)
	
end

function areaLimit_Sonar(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	return checkAreaLimit(self,sonarByFaction[self.unitSide], self.unitId, 1, BIG_RADIUS, nil)
	
end

function areaLimit_AdvRadar(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	return checkAreaLimit(self,advRadarByFaction[self.unitSide], self.unitId, 1, HUGE_RADIUS, nil)
	
end

function areaLimit_AdvSonar(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	return checkAreaLimit(self,advSonarByFaction[self.unitSide], self.unitId, 1, HUGE_RADIUS, nil)
	
end

function areaLimit_Jammer(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	return checkAreaLimit(self,jammerByFaction[self.unitSide], self.unitId, 1, BIG_RADIUS, nil)
	
end

function areaLimit_Respawner(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	return checkAreaLimit(self,respawnerByFaction[self.unitSide], self.unitId, 1, BIG_RADIUS, nil)
	
end

function airRepairPadIfNeeded(self)
	-- only make air pads if the team has air units
	-- TODO: air repair pads have been disabled
	if false and countOwnUnits(self,nil, 3, TYPE_AIR_ATTACKER) > 2 then
		return buildWithLimitedNumber(self,airRepairPadByFaction[self.unitSide], 5)
	end
	
	return SKIP_THIS_TASK
end

function getChoice(choice)
	if (type(choice) == "table") then
		return choice[ random( 1, tableLength(choice)) ] 
	else
		return choice
	end	
end

function choiceByType(self,airThreatChoice,defenseThreatChoice,normalThreatChoice,underWaterThreatChoice)
	if self.ai.unitHandler.threatType == THREAT_AIR then
		return getChoice(airThreatChoice)
	elseif self.ai.unitHandler.threatType == THREAT_DEFENSE then
		return getChoice(defenseThreatChoice)
	elseif underWaterThreatChoice~= nil and self.ai.unitHandler.threatType == THREAT_UNDERWATER then
		return getChoice(underwaterThreatChoice)		
	else
		return getChoice(normalThreatChoice)
	end
	return SKIP_THIS_TASK
end

function longRangeRocketChoice(self)

	-- avoid building nuke if your combined forces are relatively weak
	local totalAttackerCost = 0
	for gId,group in pairs(self.ai.unitHandler.unitGroups) do
		totalAttackerCost = totalAttackerCost + group.totalCost
	end
	if totalAttackerCost < MIN_FORCE_COST_BUILD_NUKE_THRESHOLD then
		return SKIP_THIS_TASK
	end

	-- TODO use other rockets
	return unblockableNukeByFaction[self.unitSide]
end

function unblockableNukeTargetting(self)
	local targetCell = self.ai.unitHandler.nukeTargetCell
	if (targetCell ~= nil) then
		
		local searchPos = targetCell.p
		local xMin = searchPos.x - 500
		local xMax = searchPos.x + 500
		local zMin = searchPos.z - 500
		local zMax = searchPos.z + 500
		local step = 80
		
		local bestPos = newPosition(searchPos.x,searchPos.y,searchPos.z)
		local bestValue = 0
		local value = 0
		local units = nil
		local testPos = newPosition(searchPos.x,searchPos.y,searchPos.z)
		for x = xMin, xMax, step do
			-- check x map bounds
			if (x > 0) and (x < Game.mapSizeX) then
				testPos.x = x
				for z = zMin, zMax, step do
					-- check z map bounds
					if (z > 0) and (z < Game.mapSizeZ) then
						testPos.z = z
						units = spGetUnitsInCylinder(testPos.x,testPos.z,300)
						value = 0
						if (units ~= nil) then
							for _,uId in pairs(units) do
								tId = spGetUnitTeam(uId)
								if (not spAreTeamsAllied(tId,self.ai.id)) then
									ud = UnitDefs[spGetUnitDefID(uId)]
									if ud ~= nil then
										if ud.speed == 0 then
											value = value + getWeightedCost(ud)
										elseif not ud.canFly then
											value = value + getWeightedCost(ud)	/ 4	-- mobiles might dodge it
										end
									end
								end
							end
						end
						
						if value > bestValue then
							bestPos.x = testPos.x
							bestPos.z = testPos.z
							bestValue = value
							
						end
						--Spring.MarkerAddPoint(testPos.x,500,testPos.z,value) --DEBUG
					end
				end
			end
		end
		
		-- launch nuke
		spGiveOrderToUnit(self.unitId,CMD.ATTACK,{bestPos.x,spGetGroundHeight(bestPos.x,bestPos.z),bestPos.z},EMPTY_TABLE)
	end

	return SKIP_THIS_TASK
end

function comsatTargetting(self)
	local bestPos = nil
	local basePos = self.ai.unitHandler.basePos
	local value = 0
	local bestValue = 0
	-- target most threatening cell, prioritizing for proximity to base
	for _,cell  in pairs(self.ai.unitHandler.enemyCellList) do
		
		value = (cell.attackerCost + cell.defenderCost + cell.airAttackerCost / 5) * (1500 / max(distance(basePos, cell.p),1500))

		if (value > bestValue) then
			bestValue = value
			bestPos = cell.p
		end		
	end
	
	if bestPos ~= nil then
		spGiveOrderToUnit(self.unitId,CMD.ATTACK,{bestPos.x,spGetGroundHeight(bestPos.x,bestPos.z),bestPos.z},EMPTY_TABLE)
	end

	return SKIP_THIS_TASK
end

function L1EnergyGenerator(self)
	-- if unit is far away from base center, move to center and then retry
	if farFromBaseCenter(self)  then
		self:retry()
		return moveBaseCenter(self)
	end	

	if (self.unitSide == "sphere") then
		return roughFusionIfNeeded(self)
	else
		if self.isWaterMode then
			return tidalByFaction[self.unitSide]
		else
			return windSolar(self)
		end
	end
end

------------------------------------ UPGRADES


--upgradePaths = {"offensive", "defensive", "defensive_regen", "speed", "mixed", "mixed_drones_utility", "mixed_drones_combat"}
upgradePathsByFaction = { [side1Name] = {"speed"}, [side2Name] = {"mixed","mixed_drones_utility","mixed_drones_combat"}, [side3Name] = {"offensive","mixed_drones_combat"}, [side4Name] = {"defensive","defensive_regen"}}
function selectUpgradeCenterQueue(self)
	if (not self.ai.upgradePath) then
		self.ai.upgradePath = upgradePathsByFaction[self.unitSide][ random( 1, tableLength(upgradePathsByFaction[self.unitSide]) ) ]
	end
	
	if self.ai.upgradePath then
		self:changeQueue(upgradeQueueByPath[self.ai.upgradePath])
		--log("UPGRADES: "..self.ai.upgradePath.." "..type(upgradeQueueByPath[self.ai.upgradePath]),self.ai)
	end

	return SKIP_THIS_TASK
end



------------------------------- COMMON



airScout = {
	scoutRandomly,
	{action = "wait", frames = 32}
}

atkSupporter = {
	moveAtkCenter,
	{action = "wait", frames = 32}
}

atkSupporterAct = {
	activateAtkCenter,
	{action = "wait", frames = 32}
}

atkPatroller = {
	patrolAtkCenter,
	{action = "cleanup", frames = CLEANUP_FRAMES},
	{action = "wait", frames = 32}
}


builderAtkPatroller = {
	metalExtractorNearbyIfSafe,
	{action = "cleanup", frames = CLEANUP_FRAMES},
	patrolAtkCenter
}

respawner = {
	respawnIfNeeded,
	{action = "wait", frames = 38}
}


scoutPad = {
	airScoutIfNeeded,
	{action = "wait", frames = 600}
}

staticBuilder = {		-- TODO classic AI should use these too...maybe
	{action = "wait", frames = 600}
}

upgradeCenter = {
	selectUpgradeCenterQueue,
	{action = "wait", frames = 38}
}

lRRocketPlatform = {
	longRangeRocketChoice,
	{action = "wait", frames = 38}
}

unblockableNuke = {
	unblockableNukeTargetting,
	{action = "wait", frames = 313}
}

comsatStation = {
	comsatTargetting,
	{action = "wait", frames = 313}
}

upgradeOffensive = {
	"upgrade_green_3_regen",
	"upgrade_red_1_damage",
	"upgrade_red_1_damage",
	"upgrade_red_1_range",
	"upgrade_red_1_range",
	"upgrade_red_1_range",
	"upgrade_blue_3_commander_stealth_drone",
	"upgrade_red_2_commander_damage",
	"upgrade_red_2_commander_range",
	{action = "wait", frames = 38}
}

upgradeDefensive = {
	"upgrade_green_3_regen",
	"upgrade_green_1_hp",
	"upgrade_green_1_hp",
	"upgrade_green_1_regen",
	"upgrade_green_1_hp",
	"upgrade_green_1_regen",
	"upgrade_blue_3_commander_stealth_drone",
	"upgrade_green_2_commander_hp",
	"upgrade_green_2_commander_regen",
	{action = "wait", frames = 38}
}

upgradeDefensiveRegen = {
	"upgrade_green_3_regen",
	"upgrade_green_1_regen",
	"upgrade_green_1_regen",
	"upgrade_green_1_regen",
	"upgrade_blue_1_speed",
	"upgrade_green_1_hp",
	"upgrade_blue_3_commander_stealth_drone",
	"upgrade_green_2_commander_hp",
	"upgrade_green_2_commander_regen",
	{action = "wait", frames = 38}
}

upgradeSpeed = {
	"upgrade_green_1_regen",
	"upgrade_green_1_regen",
	"upgrade_blue_1_speed",
	"upgrade_blue_1_speed",
	"upgrade_blue_1_speed",
	"upgrade_blue_3_commander_stealth_drone",
	"upgrade_blue_2_commander_speed",
	"upgrade_green_2_commander_regen",
	"upgrade_blue_3_speed",
	{action = "wait", frames = 38}
}

upgradeMixed = {
	"upgrade_green_3_regen",
	"upgrade_blue_1_speed",
	"upgrade_green_1_regen",
	"upgrade_blue_1_speed",
	"upgrade_blue_1_speed",
	"upgrade_green_1_hp",
	"upgrade_blue_3_commander_stealth_drone",
	"upgrade_green_2_commander_regen",
	"upgrade_green_2_commander_hp",
	{action = "wait", frames = 38}
}

upgradeMixedDronesUtility = {
	"upgrade_green_3_regen",
	"upgrade_blue_1_speed",
	"upgrade_green_1_regen",
	"upgrade_blue_1_speed",
	"upgrade_blue_1_speed",
	"upgrade_green_1_hp",
	"upgrade_blue_3_commander_stealth_drone",
	"upgrade_blue_3_commander_builder_drone",
	"upgrade_blue_3_commander_builder_drone",
	{action = "wait", frames = 38}
}

upgradeMixedDronesCombat = {
	"upgrade_green_3_regen",
	"upgrade_blue_1_speed",
	"upgrade_green_1_regen",
	"upgrade_blue_1_speed",
	"upgrade_blue_1_speed",
	"upgrade_green_1_hp",
	"upgrade_blue_3_commander_stealth_drone",	
	"upgrade_blue_2_commander_light_drones",
	"upgrade_blue_3_commander_medium_drone",
	{action = "wait", frames = 38}
}

------------------------------- AVEN


avenUCommander = {
	checkMorph,
	changeQueueToCommanderBaseBuilderIfNeeded,
	reclaimNearbyFeaturesIfNecessary,
	metalExtractorNearbyIfSafe,
	commanderPatrol,
	commanderForwardDefense
}

avenURoamingCommander = {
	checkMorph,
	changeQueueToCommanderBaseBuilderIfNeeded,
	reclaimNearbyFeaturesIfNecessary,
	metalExtractorNearbyIfSafe,
	commanderRoam,
	metalExtractorNearbyIfSafe,
	areaLimit_LightAA,
	areaLimit_Radar,
	commanderRoam
}




avenMexBuilder = {
	"aven_metal_extractor",
	"aven_metal_extractor",
	areaLimit_LightAA,
	"aven_metal_extractor",
	areaLimit_LightAA,
	"aven_metal_extractor",
	"aven_metal_extractor",
	"aven_metal_extractor",
	areaLimit_LightAA,
	areaLimit_Radar,
	restoreQueue	
}

avenLev1DefenseBuilder = {
	moveVulnerablePos,
	{action = "cleanup", frames = CLEANUP_FRAMES},
	areaLimit_LightAA,
	areaLimit_Radar,
	areaLimit_L1HeavyDefense,
	areaLimit_LightAA,
	{action = "cleanup", frames = CLEANUP_FRAMES},
	windSolarIfNeeded,
	areaLimit_L1ArtilleryDefense,
	restoreQueue
}

avenMexUpgrader = {
	moveSafePos,
	advMetalExtractor,
	advMetalExtractor,
	restoreQueue
}

avenLev2DefenseBuilder = {
	moveVulnerablePos,
	areaLimit_AdvRadar,	
	areaLimit_L2HeavyAA,
	areaLimit_L2ArtilleryDefense,
	areaLimit_L2HeavyAA,
	areaLimit_L2LongRangeArtillery,
	restoreQueue	
}


------------------------------- GEAR


gearUCommander = {
	checkMorph,
	changeQueueToCommanderBaseBuilderIfNeeded,
	reclaimNearbyFeaturesIfNecessary,
	metalExtractorNearbyIfSafe,
	commanderPatrol,
	commanderForwardDefense
}

gearURoamingCommander = {
	checkMorph,
	changeQueueToCommanderBaseBuilderIfNeeded,
	reclaimNearbyFeaturesIfNecessary,
	metalExtractorNearbyIfSafe,
	commanderRoam,
	metalExtractorNearbyIfSafe,
	areaLimit_LightAA,
	areaLimit_Radar,
	commanderRoam
}


gearMexBuilder = {
	"gear_metal_extractor",
	"gear_metal_extractor",
	areaLimit_LightAA,
	"gear_metal_extractor",
	{action = "cleanup", frames = CLEANUP_FRAMES},
	areaLimit_LightAA,
	"gear_metal_extractor",
	"gear_metal_extractor",
	"gear_metal_extractor",
	areaLimit_LightAA,
	areaLimit_Radar,
	restoreQueue
}


gearLev1DefenseBuilder = {
	moveVulnerablePos,
	areaLimit_LightAA,
	areaLimit_Radar,
	areaLimit_L1HeavyDefense,
	areaLimit_LightAA,
	{action = "cleanup", frames = CLEANUP_FRAMES},
	windSolarIfNeeded,
	areaLimit_L1ArtilleryDefense,
	restoreQueue
}


gearMexUpgrader = {
	moveSafePos,
	advMetalExtractor,
	advMetalExtractor,
	restoreQueue
}

gearLev2DefenseBuilder = {
	moveVulnerablePos,
	areaLimit_AdvRadar,	
	areaLimit_L2HeavyAA,
	areaLimit_L2ArtilleryDefense,
	{action = "cleanup", frames = CLEANUP_FRAMES},
	areaLimit_L2HeavyAA,
	areaLimit_L2LongRangeArtillery,
	restoreQueue	
}


------------------------------- CLAW


clawUCommander = {
	checkMorph,
	changeQueueToCommanderBaseBuilderIfNeeded,
	reclaimNearbyFeaturesIfNecessary,
	metalExtractorNearbyIfSafe,
	commanderPatrol,
	commanderForwardDefense
}



clawURoamingCommander = {
	checkMorph,
	changeQueueToCommanderBaseBuilderIfNeeded,
	reclaimNearbyFeaturesIfNecessary,
	metalExtractorNearbyIfSafe,
	commanderRoam,
	metalExtractorNearbyIfSafe,
	areaLimit_MediumAA,
	areaLimit_Radar,
	commanderRoam
}


clawMexBuilder = {
	"claw_metal_extractor",
	"claw_metal_extractor",
	"claw_metal_extractor",
	"claw_metal_extractor",
	{action = "cleanup", frames = CLEANUP_FRAMES},
	areaLimit_MediumAA,
	"claw_metal_extractor",
	"claw_metal_extractor",
	"claw_metal_extractor",
	"claw_metal_extractor",
	areaLimit_MediumAA,
	areaLimit_Radar,
	restoreQueue
}


clawLev1DefenseBuilder = {
	moveVulnerablePos,
	areaLimit_Radar,
	areaLimit_MediumAA,
	areaLimit_L1ArtilleryDefense,
	areaLimit_L1HeavyDefense,
	{action = "cleanup", frames = CLEANUP_FRAMES},
	areaLimit_MediumAA,
	windSolarIfNeeded,
	restoreQueue
}


clawMexUpgrader = {
	moveSafePos,
	advMetalExtractor,
	advMetalExtractor,
	restoreQueue
}

clawLev2DefenseBuilder = {
	moveVulnerablePos,
	areaLimit_AdvRadar,
	areaLimit_L2HeavyAA,
	areaLimit_L2ArtilleryDefense,
	{action = "cleanup", frames = CLEANUP_FRAMES},
	areaLimit_L2HeavyAA,
	areaLimit_L2LongRangeArtillery,
	restoreQueue	
}

------------------------------- SPHERE

sphereUCommander = {
	checkMorph,
	changeQueueToCommanderBaseBuilderIfNeeded,
	reclaimNearbyFeaturesIfNecessary,
	metalExtractorNearbyIfSafe,
	commanderPatrol,
	commanderForwardDefense
}

sphereURoamingCommander = {
	checkMorph,
	changeQueueToCommanderBaseBuilderIfNeeded,
	reclaimNearbyFeaturesIfNecessary,
	metalExtractorNearbyIfSafe,
	commanderRoam,
	metalExtractorNearbyIfSafe,
	areaLimit_MediumAA,
	areaLimit_Radar,
	commanderRoam
}


sphereMexBuilder = {
	"sphere_metal_extractor",
	"sphere_metal_extractor",
	"sphere_metal_extractor",
	"sphere_metal_extractor",
	areaLimit_MediumAA,
	{action = "cleanup", frames = CLEANUP_FRAMES},
	"sphere_metal_extractor",
	"sphere_metal_extractor",
	"sphere_metal_extractor",
	"sphere_metal_extractor",
	areaLimit_MediumAA,
	{action = "cleanup", frames = CLEANUP_FRAMES},
	areaLimit_Radar,
	restoreQueue
}

sphereLev1DefenseBuilder = {
	moveVulnerablePos,
	areaLimit_Radar,
	areaLimit_MediumAA,
	areaLimit_L1ArtilleryDefense,
	areaLimit_L1HeavyDefense,
	{action = "cleanup", frames = CLEANUP_FRAMES},
	areaLimit_MediumAA,
	restoreQueue
}


sphereMexUpgrader = {
	moveSafePos,
	advMetalExtractor,
	advMetalExtractor,
	restoreQueue
}

sphereLev2DefenseBuilder = {
	moveVulnerablePos,
	areaLimit_AdvRadar,	
	areaLimit_L2HeavyAA,
	--areaLimit_L2ArtilleryDefense,
	areaLimit_L2HeavyAA,
	{action = "cleanup", frames = CLEANUP_FRAMES},
	areaLimit_L2LongRangeArtillery,
	restoreQueue	
}

------------------------------- unit-queue table

mexUpgraderQueueByFaction = { [side1Name] = avenMexUpgrader, [side2Name] = gearMexUpgrader, [side3Name] = clawMexUpgrader, [side4Name] = sphereMexUpgrader}
mexBuilderQueueByFaction = { [side1Name] = avenMexBuilder, [side2Name] = gearMexBuilder, [side3Name] = clawMexBuilder, [side4Name] = sphereMexBuilder}
commanderAtkQueueByFaction = { [side1Name] = avenUCommander, [side2Name] = gearUCommander, [side3Name] = clawUCommander, [side4Name] = sphereUCommander}
commanderRoamingQueueByFaction = { [side1Name] = avenURoamingCommander, [side2Name] = gearURoamingCommander, [side3Name] = clawURoamingCommander, [side4Name] = sphereURoamingCommander}
commanderWaterQueueByFaction = { [side1Name] = avenWaterCommander, [side2Name] = gearWaterCommander, [side3Name] = clawWaterCommander, [side4Name] = sphereWaterCommander}
defenseBuilderQueueByFaction = { [side1Name] = avenLev1DefenseBuilder, [side2Name] = gearLev1DefenseBuilder, [side3Name] = clawLev1DefenseBuilder, [side4Name] = sphereLev1DefenseBuilder}
advancedDefenseBuilderQueueByFaction = { [side1Name] = avenLev2DefenseBuilder, [side2Name] = gearLev2DefenseBuilder, [side3Name] = clawLev2DefenseBuilder, [side4Name] = sphereLev2DefenseBuilder}
lightGroundRaiderQueueByFaction = { [side1Name] = avenL1GroundRaiders, [side2Name] = gearL1GroundRaiders, [side3Name] = clawL1GroundRaiders, [side4Name] = sphereL1GroundRaiders}
attackPatrollerQueue = builderAtkPatroller
upgradeQueueByPath = {offensive = upgradeOffensive, defensive = upgradeDefensive, defensive_regen = upgradeDefensiveRegen, speed = upgradeSpeed, mixed = upgradeMixed, mixed_drones_utility = upgradeMixedDronesUtility, mixed_drones_combat = upgradeMixedDronesCombat}



------------------------------------ action controllers for specific strategies  

-- check if conditions are met
function checkAllowedConditions(self,props)
	-- exclude if any matches
	if (props.excludeConditions) then
		for i,c in ipairs(props.excludeConditions) do
			if (self.ai.unitHandler.threatType == c) then
				return false
			elseif (c == CONDITION_WATER and self.isWaterMode) then
				return false
			end
		end
	end
	-- include if any matches
	if (props.includeConditions) then
		for i,c in ipairs(props.includeConditions) do
			if (self.ai.unitHandler.threatType == c) then
				return true
			elseif (c == CONDITION_WATER and self.isWaterMode) then
				return true
			end
		end
		return false
	end
	return true
end

function stratCommanderAction(self)
	local currentStrategy = self.ai.currentStrategy
	local currentStrategyName = self.ai.currentStrategyName
	local sStage = self.ai.currentStrategyStage
	local checkResult = SKIP_THIS_TASK
	local comAttackerMetalIncome = currentStrategy.stages[sStage].economy.comAttackerMetalIncome or 99999
	local comAttackerEnergyIncome = currentStrategy.stages[sStage].economy.comAttackerEnergyIncome or 99999
	local comMorphMetalIncome = currentStrategy.stages[sStage].economy.comMorphMetalIncome or 99999
	local comMorphEnergyIncome = currentStrategy.stages[sStage].economy.comMorphEnergyIncome or 99999
	local defenseDensityMult = currentStrategy.stages[sStage].properties.defenseDensityMult or 1
	local focusOnEndGameArmy =  self.ai.unitHandler.focusOnEndGameArmy
	local action = SKIP_THIS_TASK
	
	if self.isBrutalMode then
		local f = spGetGameFrame()
		if f < BRUTAL_STRATEGY_STAGES_DELAY_FRAMES then
			comMorphMetalIncome = comMorphMetalIncome * 6
			comMorphEnergyIncome = comMorphEnergyIncome * 6
			sStage = 1
		end	
	end
	
	-- current economy
	local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(self.ai.id,"energy")
	local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")
	
	-- check morph conditions
	if ((incomeM > comMorphMetalIncome and incomeE > comMorphEnergyIncome)) then
		action = checkMorph(self)
		if ( action ~= SKIP_THIS_TASK) then
			return action
		end
	end
	
	-- check build options on current strategy
	local minMetalIncome = currentStrategy.stages[sStage].economy.minMetalIncome
	local minEnergyIncome = currentStrategy.stages[sStage].economy.minEnergyIncome
	local targetMetalIncome = currentStrategy.stages[sStage].economy.metalIncome
	local targetEnergyIncome = currentStrategy.stages[sStage].economy.energyIncome

	-- factories and other key buildings
	local targetBuildings = currentStrategy.stages[sStage].buildings
	local buildsFactories = currentStrategy.stages[sStage].properties.commanderBuildsFactories
	local options = buildOptionsByPlant[self.builderType]
	if (options and targetBuildings) then
		for i,props in ipairs(targetBuildings) do
			local minCount = props.min 
			local uName = props.name
			if options[uName] == true and (buildsFactories or constructionTowers[uName]) then
				if (checkAllowedConditions(self,props) and countOwnUnits(self,uName, 99, nil) < minCount) then
		
					-- if unit is far away from base center, move to center and then retry
					if farFromBaseCenter(self)  then
						self:retry()
						return moveBaseCenter(self)
					end	
					
					return uName
				end
			end
		end
	end
	
	-- build a bit of energy generation early in the game
	--log("com checking energy : E="..incomeE.." minE="..minEnergyIncome,self.ai) --DEBUG
	if sStage == 1 and ((incomeE < minEnergyIncome - 100) or currentLevelE < 0.25*storageE) then
		
		action = L1EnergyGenerator(self)
		if (action ~= SKIP_THIS_TASK) then
			return action
		end
	end
	
	-- metal and energy generation : try to reach min income
	if (incomeM < comAttackerMetalIncome) then
		if not self.couldNotFindMetalSpot then
			if (sStage == 1) then
				action = mexByFaction[self.unitSide]
			else
				action = metalExtractorNearbyIfSafe(self)
			end
			if action ~= SKIP_THIS_TASK then
				return action
			end
		end
	end	

	if (incomeE < minEnergyIncome or currentLevelE < 0.25*storageE) then
		action = L1EnergyGenerator(self)
		if (action ~= SKIP_THIS_TASK) then
			return action
		end
	end
	
	-- check if there's a nearby unit to assist
	action = assistNearbyConstructionIfNeeded(self,false,true,1000)	-- exclude mobile units, include non-builders  
	if ( action ~= SKIP_THIS_TASK) then
		return action
	end		
	
	-- set up minimal defense if necessary
	action = defendNearbyBuildingsIfNeeded(self,0.1)
	if action ~= SKIP_THIS_TASK then
		return action
	end	

	-- check behavior type
	-- if has decent resource income and factories, go support the attackers
	local hasFactories = countOwnUnits(self,nil,2,TYPE_PLANT) > 0
	if (incomeM > comAttackerMetalIncome and incomeE > comAttackerEnergyIncome and hasFactories) then
		--log("com changing to attack mode",self.ai) --DEBUG
		self:changeQueue(commanderAtkQueueByFaction[self.unitSide])
		self.isAttackMode = true
		return SKIP_THIS_TASK
	end
	
	-- metal and energy generation : try to reach target income
	if (incomeM < targetMetalIncome) then
		if not self.couldNotFindMetalSpot then
			action = metalExtractorNearbyIfSafe(self)
			if action ~= SKIP_THIS_TASK then
				return action
			end
		end
	end	
	if (incomeE < targetEnergyIncome and incomeE < L1_ENERGY_EFF_THRESHOLD) then
		action = L1EnergyGenerator(self)
		if (action ~= SKIP_THIS_TASK) then
			return action
		end
	end

	self.couldNotFindGeoSpot = false
	self.couldNotFindMetalSpot = false
	if (hasFactories) then
		-- short patrol
		self.briefAreaPatrolFrames = 300
		return briefAreaPatrol(self)	
	end
	return SKIP_THIS_TASK
end


function stratStaticBuilderAction(self)
	--Spring.Echo(spGetGameFrame().."STATIC BUILDER ")
	local currentStrategy = self.ai.currentStrategy
	local currentStrategyName = self.ai.currentStrategyName
	local sStage = self.ai.currentStrategyStage
	-- current economy
	local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(self.ai.id,"energy")
	local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")
	
	local minMetalIncome = currentStrategy.stages[sStage].economy.minMetalIncome
	local minEnergyIncome = currentStrategy.stages[sStage].economy.minEnergyIncome
	local targetMetalIncome = currentStrategy.stages[sStage].economy.metalIncome
	local targetEnergyIncome = currentStrategy.stages[sStage].economy.energyIncome
	local defenseDensityMult = currentStrategy.stages[sStage].properties.defenseDensityMult or 1
	if (self.ai.humanDefenseDensityMult ~= nil) then
		defenseDensityMult = self.ai.humanDefenseDensityMult
	end
	local focusOnEndGameArmy =  self.ai.unitHandler.focusOnEndGameArmy		
	local action = SKIP_THIS_TASK
	
	if self.isBrutalMode then
		local f = spGetGameFrame()
		if f < BRUTAL_STRATEGY_STAGES_DELAY_FRAMES then
			sStage = 1
		end	
	end
	
	-- reset priority
	self:resetHighPriorityState()
	
	-- check if there's a nearby unit to assist
	action = assistNearbyConstructionIfNeeded(self,false,false,self.buildRange * 0.8)	-- exclude mobile units and non-builders 
	if ( action ~= SKIP_THIS_TASK) then
		return action
	end	
	
	-- factories and other key buildings
	local targetBuildings = currentStrategy.stages[sStage].buildings
	local options = buildOptionsByPlant[self.builderType]
	if (options and targetBuildings) then
		for i,props in ipairs(targetBuildings) do
			local minCount = props.min 
			local uName = props.name
			
			--if self:checkPreviousAttempts(uName) and setContains(unitTypeSets[TYPE_PLANT],uName) then
			if options[uName] == true and self:checkPreviousAttempts(uName) then
				if checkAllowedConditions(self,props) and (countOwnUnits(self,uName, minCount, nil) < minCount) then
					self:setHighPriorityState(1)
					return uName
				end
			end
		end
	end

	-- defense
	if defenseDensityMult > 0 and (not focusOnEndGameArmy) then
		if (self.unitSide == "claw" or self.unitSide == "sphere") then
			local unitName = mediumAAByFaction[self.unitSide]
			if self:checkPreviousAttempts(unitName) then
				action = checkAreaLimit(self,unitName, self.unitId, 1*defenseDensityMult, MED_RADIUS, TYPE_LIGHT_AA)
				if action ~= SKIP_THIS_TASK then
					self:setHighPriorityState(1)
					return action
				end
			end
		elseif(self.unitSide == "aven" or self.unitSide == "gear") then
			local unitName = lev1HeavyDefenseByFaction[self.unitSide][ random( 1, tableLength(lev1HeavyDefenseByFaction[self.unitSide]) ) ]
			if self:checkPreviousAttempts(unitName) then
				action = checkAreaLimit(self,unitName, self.unitId, 1*defenseDensityMult, MED_RADIUS, TYPE_HEAVY_DEFENSE)
				if action ~= SKIP_THIS_TASK then
					self:setHighPriorityState(1)
					return action
				end
			end
		end
	end
	
	self.couldNotFindGeoSpot = false
	self.couldNotFindMetalSpot = false
	
	return staticBriefAreaPatrol(self)
end

function stratMobileBuilderAction(self)
	local currentStrategy = self.ai.currentStrategy
	local currentStrategyName = self.ai.currentStrategyName
	local sStage = self.ai.currentStrategyStage
	
	-- current economy
	local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(self.ai.id,"energy")
	local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")
	
	local minMetalIncome = currentStrategy.stages[sStage].economy.minMetalIncome
	local minEnergyIncome = currentStrategy.stages[sStage].economy.minEnergyIncome
	local targetMetalIncome = currentStrategy.stages[sStage].economy.metalIncome
	local targetEnergyIncome = currentStrategy.stages[sStage].economy.energyIncome
	local defenseDensityMult = currentStrategy.stages[sStage].properties.defenseDensityMult or 1
	if (self.ai.humanDefenseDensityMult ~= nil) then
		defenseDensityMult = self.ai.humanDefenseDensityMult
	end
	local focusOnEndGameArmy =  self.ai.unitHandler.focusOnEndGameArmy
	local action = SKIP_THIS_TASK
	
	local brutalStartDelayActive = false
	if self.isBrutalMode then
		local f = spGetGameFrame()
		if f < BRUTAL_STRATEGY_STAGES_DELAY_FRAMES then
			brutalStartDelayActive = true
			sStage = 1
		end	
	end
	
	-- reset priority
	self:resetHighPriorityState()

	if (not self.isAdvBuilder) then
		-- check if there's a nearby unit to assist
		action = assistNearbyConstructionIfNeeded(self,false,true,1000)	-- exclude mobile units, include non-builders  
		if ( action ~= SKIP_THIS_TASK) then
			return action
		end
	end
	
	-- prioritize building some defenses if base is under attack
	if self.ai.unitHandler.baseUnderAttack then
		action = defendNearbyBuildingsIfNeeded(self, 0.2)
		if action ~= SKIP_THIS_TASK then
			self:setHighPriorityState(1)
			return action
		end	
	end
	
	-- for adv builders raise the min to trigger upgrading nearby extractors 
	if (self.isAdvBuilder and (incomeE < 15*incomeM) and (not self.ai.unitHandler.baseUnderAttack)) then
		minMetalIncome = targetMetalIncome
		minEnergyIncome = targetEnergyIncome
	end
	-- metal and energy generation : try to reach min income
	if (incomeM < minMetalIncome and currentLevelE > 0.7*storageE) then
		action = metalExtractorNearbyIfSafe(self)
		if action ~= SKIP_THIS_TASK then
			return action
		end
	end	
	if (incomeE < minEnergyIncome or currentLevelE < 0.7*storageE ) then
		action = geoNearbyIfSafe(self)
		if (action ~= SKIP_THIS_TASK) then
			return action
		end
		if (self.isAdvBuilder and sStage > 1) then
			action = fusionIfNeeded(self)
			if (action ~= SKIP_THIS_TASK) then
				return action
			end
		elseif incomeE < L1_ENERGY_EFF_THRESHOLD then
			action = L1EnergyGenerator(self)
			if (action ~= SKIP_THIS_TASK) then
				return action
			end
		end
	end

	-- level 2 builder
	if (self.isAdvBuilder) then
		local stdQueueCount = self.ai.unitHandler.advancedStandardQueueCount or 0
	
		if stdQueueCount > 1 then
			changeQueueToMexUpgraderIfNeeded(self)
			if (self.specialRole == UNIT_ROLE_MEX_UPGRADER) then
				return SKIP_THIS_TASK
			end
			changeQueueToAdvancedDefenseBuilderIfNeeded(self)
			if (self.specialRole == UNIT_ROLE_ADVANCED_DEFENSE_BUILDER) then
				return SKIP_THIS_TASK
			end
			patrolAtkCenterIfNeeded(self)
			if (self.specialRole == UNIT_ROLE_ATTACK_PATROLLER) then
				return SKIP_THIS_TASK
			end
		end
	else
	-- level 1 builder
		local stdQueueCount = self.ai.unitHandler.standardQueueCount or 0
		
		if stdQueueCount > 1 then
			changeQueueToMexBuilderIfNeeded(self)
			if (self.specialRole == UNIT_ROLE_MEX_BUILDER) then
				return SKIP_THIS_TASK
			end
			basePatrolIfNeeded(self)
			if (self.specialRole == UNIT_ROLE_BASE_PATROLLER) then
				return SKIP_THIS_TASK
			end
			changeQueueToDefenseBuilderIfNeeded(self)
			if (self.specialRole == UNIT_ROLE_DEFENSE_BUILDER) then
				return SKIP_THIS_TASK
			end	
			patrolAtkCenterIfNeeded(self)
			if (self.specialRole == UNIT_ROLE_ATTACK_PATROLLER) then
				return SKIP_THIS_TASK
			end	
		end
	end
	
	-- factories and other key buildings
	local targetBuildings = currentStrategy.stages[sStage].buildings
	local options = buildOptionsByPlant[self.builderType]
	if (targetBuildings and options) then
		for i,props in ipairs(targetBuildings) do
			local minCount = props.min
			local maxCount = props.max
			local uName = props.name
			if options[uName] == true and (checkAllowedConditions(self,props) and countOwnUnits(self,uName, 99, nil) < maxCount) then
	
				-- if unit is far away from base center, move to center and then retry
				if farFromBaseCenter(self)  then
					self:retry()
					return moveBaseCenter(self)
				end	

				--log(self.unitName.." trying to build a factory : "..uName,self.ai) --DEBUG	
				self:setHighPriorityState(1)			
				return uName
			end
		end
	end
	
	-- storage
	if (sStage > 1) then
		action = buildWithLimitedNumber(self, energyStorageByFaction[self.unitSide],sStage-1)
		if action ~= SKIP_THIS_TASK then
			return action
		end
		action = buildWithLimitedNumber(self, metalStorageByFaction[self.unitSide],1)
		if action ~= SKIP_THIS_TASK then
			return action
		end
	end
	
	-- set up minimal defense if necessary
	action = defendNearbyBuildingsIfNeeded(self, 0.1)
	if action ~= SKIP_THIS_TASK then
		return action
	end	
	
	if (incomeM > 40 and (not brutalStartDelayActive)) then
		action = buildWithLimitedNumber(self, comsatByFaction[self.unitSide],min(1 + floor(incomeM/30),6))
		if action ~= SKIP_THIS_TASK then
			return action
		end	
	end
	
	if not focusOnEndGameArmy then
		-- support buildings
		if (self.isAdvBuilder) then
			action = areaLimit_AdvRadar(self)
			if action ~= SKIP_THIS_TASK then
				return action
			end
			if (self.isWaterMode == true) then
				action = areaLimit_AdvSonar(self)
				if action ~= SKIP_THIS_TASK then
					return action
				end
			end
			action = areaLimit_Jammer(self)
			if action ~= SKIP_THIS_TASK then
				return action
			end		
		else
			action = areaLimit_Radar(self)
			if action ~= SKIP_THIS_TASK then
				return action
			end
			if (self.isWaterMode == true) then
				action = areaLimit_Sonar(self)
				if action ~= SKIP_THIS_TASK then
					return action
				end
			end
		end
	
		-- power nodes
		--log(spGetGameFrame().." power node check : nextNode="..tostring(self.ai.unitHandler.nextPowerNodeCell),self.ai)
		if (sStage > 1 and self.ai.unitHandler.nextPowerNodeCell) then
			action = buildWithLimitedNumber(self, powerNodeByFaction[self.unitSide],min(3 + floor(incomeM/15),20))
			if action ~= SKIP_THIS_TASK then
				return action
			end	
		end		
	end
	
	-- metal and energy generation : try to reach target income
	if (incomeM < targetMetalIncome) then
		if not self.couldNotFindMetalSpot then
			local action = metalExtractorNearbyIfSafe(self)
			if action ~= SKIP_THIS_TASK then
				--log(self.unitName.." HERE MEX adv="..tostring(self.isAdvBuilder).." act="..action,self.ai) --DEBUG
				return action
			end
		end
		if (self.isAdvBuilder) then
			action = mmakerIfNeeded(self)
			if (action ~= SKIP_THIS_TASK) then
				return action
			end
		end
	end	
	if (incomeE < targetEnergyIncome) then
		if not self.couldNotFindGeoSpot then
			action = geoNearbyIfSafe(self)
			if (action ~= SKIP_THIS_TASK) then
				return action
			end
		end
		if (self.isAdvBuilder and sStage > 1) then
			action = fusionIfNeeded(self)
			if (action ~= SKIP_THIS_TASK) then
				return action
			elseif incomeE < L1_ENERGY_EFF_THRESHOLD then
				action = L1EnergyGenerator(self)
				if (action ~= SKIP_THIS_TASK) then
					return action
				end
			end
		elseif incomeE < L1_ENERGY_EFF_THRESHOLD then
			action = L1EnergyGenerator(self)
			if (action ~= SKIP_THIS_TASK) then
				--log(self.unitName.." HERE L1ENERGY adv="..tostring(self.isAdvBuilder).." act="..action,self.ai) --DEBUG
				return action
			end
		end
	end
	
	--TODO builders very rarely get here
		
	-- if unit is far away from base center, move to center
	if farFromBaseCenter(self) then
		return moveBaseCenter(self)
	end	
	
	self.couldNotFindGeoSpot = false
	self.couldNotFindMetalSpot = false
	local hasFactories = countOwnUnits(self,nil,2,TYPE_PLANT) > 0

	if (hasFactories) then
		-- short patrol
		self.briefAreaPatrolFrames = 300
		return briefAreaPatrol(self)	
	end
	
	return SKIP_THIS_TASK
end

function stratPlantAction(self)
	local currentStrategy = self.ai.currentStrategy
	local currentStrategyName = self.ai.currentStrategyName
	local sStage = self.ai.currentStrategyStage
	
	if self.isBrutalMode then
		local f = spGetGameFrame()
		if f < BRUTAL_STRATEGY_STAGES_DELAY_FRAMES then
			sStage = 1
		end	
	end
	
	-- check recommended build options and build what it can
	local targetMobileUnits = currentStrategy.stages[sStage].mobileUnits
	local mobileUnitCount = self.ai.unitHandler.mobileCount 
	--log("mobiles="..mobileUnitCount,self.ai) --DEBUG
	if (targetMobileUnits and buildOptionsByPlant[self.unitName]) then
		-- get total weight
		local totalWeight = 0
		for i,props in ipairs(targetMobileUnits) do
			if (props.weight and props.weight > 0 and checkAllowedConditions(self,props)) then
				totalWeight = totalWeight + props.weight
			end
		end
		--log(self.unitName.." totalWeight="..totalWeight,self.ai) --DEBUG
		if totalWeight == 0 then
			totalWeight = 1
		end
		
		-- first pass, check which unit should be built
		local lowestFraction = math.huge
		local curFraction = math.huge
		local mostNeededUnit = SKIP_THIS_TASK
		local options = buildOptionsByPlant[self.unitName]
		if options then
			for i,props in ipairs(targetMobileUnits) do
				local uName = props.name
				if options[uName] == true and props.weight > 0 then
					local minCount = props.min 
					
					local currentCount =  countOwnUnits(self,uName, 9999, nil)
					--log(spGetGameFrame().." HERE2 plant "..uName.." cnt="..currentCount.." minCnt="..minCount.." maxCnt="..maxCnt.." curFrac="..props.weight*mobileUnitCount / totalWeight,self.ai) --DEBUG
					local maxCount = props.max
					if checkAllowedConditions(self,props) then
						if (mobileUnitCount == 0) then
							return uName
						end
						if currentCount < minCount then
							return uName
						end
						
						curFraction = currentCount / (props.weight*mobileUnitCount)
						if (currentCount < maxCount and curFraction < 5) then
							if (curFraction < lowestFraction) then
								lowestFraction = curFraction
								mostNeededUnit = uName
							end
						end
					end
				end
			end
			if mostNeededUnit ~= SKIP_THIS_TASK  then
				return mostNeededUnit
			end
		end
	end
	
	return SKIP_THIS_TASK
end
	
function stratUpgradeCenterAction(self)
	local currentStrategy = self.ai.currentStrategy
	local currentStrategyName = self.ai.currentStrategyName
	local sStage = self.ai.currentStrategyStage
	
	-- check recommended build options and build what it can
	local targetUpgrades = currentStrategy.upgradeList
	-- if upgrade list is undefined or empty, revert to "classic" upgrade behavior
	if ((not targetUpgrades) or #targetUpgrades == 0) then
		return selectUpgradeCenterQueue(self)
	end
	
	if (targetUpgrades) then
		for i,props in ipairs(targetUpgrades) do
			local maxCount = tonumber(props.max)
			local uName = props.name
			local curCount = self.ai.upgradesBuiltByName[uName] or 0
			if (curCount < maxCount) then
				--log(self.unitName.." trying to build upgrade : "..uName.." curCount="..tostring(curCount),self.ai) --DEBUG				
				return uName
			end
		end
	end

	return SKIP_THIS_TASK
end

-- set to wait to just use the automatic orders from the drone gadget
drone = {
	{action = "wait", frames = 300}
}

stratCommander = {
	stratCommanderAction,
	reclaimNearbyFeaturesIfNecessary
}

stratStaticBuilder = {
	stratStaticBuilderAction,
	reclaimNearbyFeaturesIfNecessary
}

stratMobileBuilder = {
	stratMobileBuilderAction,
	reclaimNearbyFeaturesIfNecessary
}

stratPlant = {
	stratPlantAction
}

stratUpgradeCenter = {
	stratUpgradeCenterAction,
	{action = "wait", frames = 64}
}

taskQueues = {
------------------- AVEN
	aven_commander_respawner = respawner,
	aven_scout_pad = scoutPad,
	aven_marky = atkSupporter,
	aven_eraser = atkSupporter,
	aven_seer = atkSupporter,
	aven_jammer = atkSupporter,
	aven_zephyr = atkSupporter,
	aven_perceptor = atkSupporter,
	aven_scoper = atkSupporter,
	aven_peeper = airScout,
	aven_long_range_rocket_platform = lRRocketPlatform,
	aven_premium_nuclear_rocket = unblockableNuke,
	aven_comsat_station = comsatStation,
	aven_trooper_hemg = atkSupporterAct,
	aven_cadence = atkSupporterAct,
	aven_light_drone = drone,
	aven_medium_drone = drone,
	aven_stealth_drone = drone,
	aven_adv_construction_drone = drone,
	aven_transport_drone = drone,	
------------------- GEAR
	gear_commander_respawner = respawner,
	gear_scout_pad = scoutPad,
	gear_voyeur = atkSupporter,
	gear_spectre = atkSupporter,
	gear_informer = atkSupporter,
	gear_deleter = atkSupporter,
	gear_zoomer = atkSupporter,
	gear_buoy = atkSupporter,		
	gear_fink = airScout,
	gear_long_range_rocket_platform = lRRocketPlatform,
	gear_premium_nuclear_rocket = unblockableNuke,
	gear_comsat_station = comsatStation,
	gear_caliber = atkSupporterAct,
	gear_light_drone = drone,
	gear_medium_drone = drone,
	gear_stealth_drone = drone,
	gear_adv_construction_drone = drone,
	gear_transport_drone = drone,	
------------------- CLAW
	claw_commander_respawner = respawner,
	claw_scout_pad = scoutPad,
	claw_revealer = atkSupporter,
	claw_shade = atkSupporter,
	claw_seer = atkSupporter,
	claw_jammer = atkSupporter,
	claw_haze = atkSupporter,
	claw_lensor = atkSupporter,
	claw_spotter = airScout,
	claw_hammer = atkSupporterAct,	
	claw_long_range_rocket_platform = lRRocketPlatform,
	claw_premium_nuclear_rocket = unblockableNuke,
	claw_comsat_station = comsatStation,
	claw_light_drone = drone,
	claw_medium_drone = drone,
	claw_stealth_drone = drone,
	claw_adv_construction_drone = drone,
	claw_transport_drone = drone,	
------------------- SPHERE
	sphere_commander_respawner = respawner,
	sphere_scout_pad = scoutPad,
	sphere_sensor = atkSupporter,
	sphere_rain = atkSupporter,
	sphere_scanner = atkSupporter,
	sphere_concealer = atkSupporter,
	sphere_orb = atkSupporter,
	sphere_shielder = atkSupporter,
	sphere_screener = atkSupporter,
	sphere_resolver = atkSupporter,	
	sphere_probe = airScout,
	sphere_long_range_rocket_platform = lRRocketPlatform,
	sphere_premium_nuclear_rocket = unblockableNuke,
	sphere_comsat_station = comsatStation,
	sphere_light_drone = drone,
	sphere_medium_drone = drone,
	sphere_stealth_drone = drone,
	sphere_adv_construction_drone = drone,
	sphere_transport_drone = drone	
}



sTaskQueues = {
------------------- AVEN
	aven_commander = stratCommander,
	aven_u1commander = stratCommander,
	aven_u2commander = stratCommander,
	aven_u3commander = stratCommander,
	aven_u4commander = stratCommander,
	aven_u5commander = stratCommander,
	aven_u6commander = stratCommander,
	aven_u7commander = stratCommander,
	aven_construction_vehicle = stratMobileBuilder,
	aven_construction_kbot = stratMobileBuilder,
	aven_construction_aircraft = stratMobileBuilder,
	aven_construction_ship = stratMobileBuilder,
	aven_adv_construction_vehicle = stratMobileBuilder,
	aven_adv_construction_kbot = stratMobileBuilder,
	aven_construction_hovercraft = stratMobileBuilder,
	aven_adv_construction_aircraft = stratMobileBuilder,	
	aven_adv_construction_sub = stratMobileBuilder,
	aven_nano_tower = stratStaticBuilder,
	aven_light_plant = stratPlant,
	aven_aircraft_plant = stratPlant,
	aven_shipyard = stratPlant,
	aven_adv_kbot_lab = stratPlant,
	aven_adv_vehicle_plant = stratPlant,
	aven_adv_aircraft_plant = stratPlant,
	aven_hovercraft_platform = stratPlant,
	aven_adv_shipyard = stratPlant,
	aven_upgrade_center = stratUpgradeCenter,
------------------- GEAR
	gear_commander = stratCommander,
	gear_u1commander = stratCommander,
	gear_u2commander = stratCommander,
	gear_u3commander = stratCommander,
	gear_u4commander = stratCommander,
	gear_u5commander = stratCommander,
	gear_u6commander = stratCommander,
	gear_u7commander = stratCommander,
	gear_construction_vehicle = stratMobileBuilder,
	gear_construction_kbot = stratMobileBuilder,
	gear_construction_aircraft = stratMobileBuilder,
	gear_construction_ship = stratMobileBuilder,
	gear_adv_construction_vehicle = stratMobileBuilder,
	gear_adv_construction_kbot = stratMobileBuilder,
	gear_adv_construction_aircraft = stratMobileBuilder,	
	gear_adv_construction_sub = stratMobileBuilder,
	gear_adv_construction_hydrobot = stratMobileBuilder,
	gear_nano_tower = stratStaticBuilder,
	gear_light_plant = stratPlant,
	gear_aircraft_plant = stratPlant,
	gear_shipyard = stratPlant,
	gear_adv_kbot_lab = stratPlant,
	gear_adv_vehicle_plant = stratPlant,
	gear_adv_aircraft_plant = stratPlant,
	gear_adv_shipyard = stratPlant,
	gear_hydrobot_plant = stratPlant,
	gear_upgrade_center = stratUpgradeCenter,
------------------- CLAW
	claw_commander = stratCommander,
	claw_u1commander = stratCommander,
	claw_u2commander = stratCommander,
	claw_u3commander = stratCommander,
	claw_u4commander = stratCommander,
	claw_u5commander = stratCommander,
	claw_u6commander = stratCommander,
	claw_u7commander = stratCommander,
	claw_construction_kbot = stratMobileBuilder,
	claw_construction_aircraft = stratMobileBuilder,
	claw_construction_ship = stratMobileBuilder,
	claw_adv_construction_vehicle = stratMobileBuilder,
	claw_adv_construction_kbot = stratMobileBuilder,
	claw_adv_construction_aircraft = stratMobileBuilder,	
	claw_adv_construction_spinbot = stratMobileBuilder,
	claw_adv_construction_ship = stratMobileBuilder,
	claw_nano_tower = stratStaticBuilder,
	claw_light_plant = stratPlant,
	claw_aircraft_plant = stratPlant,
	claw_shipyard = stratPlant,
	claw_adv_kbot_plant = stratPlant,
	claw_adv_vehicle_plant = stratPlant,
	claw_adv_aircraft_plant = stratPlant,
	claw_adv_shipyard = stratPlant,
	claw_spinbot_plant = stratPlant,
	claw_upgrade_center = stratUpgradeCenter,
------------------- SPHERE
	sphere_commander = stratCommander,
	sphere_u1commander = stratCommander,
	sphere_u2commander = stratCommander,
	sphere_u3commander = stratCommander,
	sphere_u4commander = stratCommander,
	sphere_u5commander = stratCommander,
	sphere_u6commander = stratCommander,
	sphere_u7commander = stratCommander,
	sphere_construction_vehicle = stratMobileBuilder,
	sphere_construction_aircraft = stratMobileBuilder,
	sphere_construction_ship = stratMobileBuilder,
	sphere_adv_construction_vehicle = stratMobileBuilder,
	sphere_adv_construction_kbot = stratMobileBuilder,
	sphere_construction_sphere = stratMobileBuilder,
	sphere_adv_construction_aircraft = stratMobileBuilder,	
	sphere_adv_construction_sub = stratMobileBuilder,
	sphere_pole = stratStaticBuilder,
	sphere_light_factory = stratPlant,
	sphere_aircraft_factory = stratPlant,
	sphere_shipyard = stratPlant,
	sphere_adv_kbot_factory = stratPlant,
	sphere_adv_vehicle_factory = stratPlant,
	sphere_adv_aircraft_factory = stratPlant,
	sphere_sphere_factory = stratPlant,
	sphere_adv_shipyard = stratPlant,
	sphere_upgrade_center = stratUpgradeCenter,
}

-- include default strategies
include("luarules/gadgets/ai/defaultStrategies.lua")