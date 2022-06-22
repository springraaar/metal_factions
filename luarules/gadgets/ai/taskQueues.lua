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
				spGiveOrderToUnit( self.unitId, CMD.RECLAIM, {CMD_FEATURE_ID_OFFSET+fId}, i == 1 and {} or CMD.OPT_SHIFT )
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
	
							spGiveOrderToUnit(self.unitId,morphCmd,{},{})
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
						spGiveOrderToUnit(self.unitId,morphCmd,{},{})
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
					spGiveOrderToUnit(self.unitId,CMD.GUARD,{tq.unitId},{})
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
								spGiveOrderToUnit(self.unitId,CMD.REPAIR,{uId},{})
								return {action="wait_idle", frames=300}
							end
						end
					-- if not fully built, assist if you can
					elseif includeMobiles or (ud.speed == 0 and (not setContains(unitTypeSets[TYPE_NUKE],ud.name))) then
						if includeNonBuilders or ud.isBuilder then
							un = ud.name
							if self.ai.mapHandler:checkConnection(selfPos, uPos,self.pFType) then
								--log("assisting nearby unit under construction",self.ai) --DEBUG
								spGiveOrderToUnit(self.unitId,CMD.REPAIR,{uId},{})
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


-- check if nearby metal resources are mostly on land or on water
function checkLandOrWater(self)
	local result = "land"
	--TODO : make it work with water maps
	--[[
	if self.unitId ~= nil then

		local landSpots = 0
		local waterSpots = 0
		local xi,zi = getCellXZIndexesForPosition(self.pos)
		local mapCell = self.ai.mapHandler.mapCells[xi][zi]
		if (mapCell.isWater == true or mapCell.isDeepWater == true) then
			waterSpots = mapCell.metalSpotCount 
		else
			landSpots = mapCell.metalSpotCount
		end
		waterSpots = waterSpots + mapCell.nearbyWaterMetalSpotCount
		landSpots = landSpots + mapCell.nearbyLandMetalSpotCount

		if ( waterSpots > landSpots ) then
			result = "water"
		end
	end
	--]]
	
	return result
end


-- check if nearby metal resources are mostly on land or on water
function setWaterMode(self)
	self.isWaterMode = true
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
	if not self.ai.useStrategies and friendlyExtractorCount > 10 and incomeM > 30 and storageM > 500 and currentLevelM >= 0.9 * storageM and incomeM > expenseM then
		return SKIP_THIS_TASK
	end

	if self.isAdvBuilder then
		unitName = advMetalExtractor(self)
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
			if (self.ai.useStrategies) then 
				self:changeQueue(stratCommander)
			else
				self:changeQueue(commanderBaseBuilderQueueByFaction[self.unitSide])
			end
			self.isAttackMode = false
			--log("changed to base builder commander!",self.ai)
		end
	end
	return SKIP_THIS_TASK
end

function changeQueueToRoamingCommanderIfNeeded(self)

	-- TODO roaming commanders are ineffective, make them work
	--if(self.isUpgradedCommander ) and naturallyRoamingCommanders[self.unitName]) then
	--	self:changeQueue(commanderRoamingQueueByFaction[self.unitSide])
	--	self.isAttackMode = true
	--	-- log("changed to roaming commander!",self.ai)
	--end

	return SKIP_THIS_TASK
end


function changeQueueToCommanderAttackerIfNeeded(self)
	local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")
	local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(self.ai.id,"energy")

	-- if has decent resource income and factories, go support the attackers
	if (incomeM > 22 and incomeE > 250 and countOwnUnits(self,nil,2,TYPE_PLANT) > 0 ) then
		
		if(self.isUpgradedCommander) then
			self:changeQueue(taskQueues[self.unitName])
		else
			self:changeQueue(commanderAtkQueueByFaction[self.unitSide])
		end
		self.isAttackMode = true
		--log("changed to attack commander!",self.ai)
	end

	return SKIP_THIS_TASK
end


function changeQueueToWaterCommanderIfNeeded(self)
	if(checkLandOrWater(self) == "water") then
		self:changeQueue(commanderWaterQueueByFaction[self.unitSide])

		self.isWaterMode = true
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
		-- log("buildEnergyIfNeeded: income "..incomeE..", usage "..expenseE..", building more energy",self.ai)
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


function reclaimNearestMexIfNeeded(self)
	-- try to find nearest mex
	local ownUnitIds = self.ai.ownUnitIds
	local tooClose = 2000
	local mexUnitId = nil
	local closestDistance = INFINITY
	local mexPos = nil
	local dist = 0
	
	for uId,_ in pairs(ownUnitIds) do
		if setContains(unitTypeSets[TYPE_MEX],UnitDefs[spGetUnitDefID(uId)].name) then
			dist = INFINITY
			-- if it's not 100% HP, then don't touch it (unless there's REALLY no better choice)
			-- this prevents a situation when engineer reclaims a mex that is still being built by someone else
			mexPos = newPosition(spGetUnitPosition(uId,false,false))
			local _,_,_,_,progress = spGetUnitHealth(uId)
			
			if( (mexPos.y > UNDERWATER_THRESHOLD and self.isWaterMode) or (mexPos.y < UNDERWATER_THRESHOLD and not self.isWaterMode) ) then
				dist = INFINITY
			elseif progress < 1 then
				dist = INFINITY
			elseif areEnemiesNearby(self, mexPos, tooClose) then
				dist = INFINITY
			else
				dist = distance(self.pos,mexPos) 
			end
			
			if dist < closestDistance then
				mexUnitId = uId
				closestDistance = dist
			end
		end
	end

	if mexUnitId ~= nil then
		-- command the engineer to reclaim the mex
		spGiveOrderToUnit(self.unitId,CMD.RECLAIM,{mexUnitId},{})
		-- log("MexUpgradeBehavior: unit "..self.unitName.." goes to reclaim a mex",self.ai)
		
		-- we'll build the moho here
		self.mexPos = mexPos
		self.reclaimedMex = true

		-- wait until it finishes
		return {action="wait_idle", frames=1800}
	end
	
	return SKIP_THIS_TASK
end

function mohoIfMexReclaimed(self)
	if (self.reclaimedMex) then
		self.reclaimedMex = false
		self.noDelay = true
		local unitName = nil
		
		if(self.isWaterMode == true) then
			unitName = UWMohoMineByFaction[self.unitSide]
		else
			unitName = mohoMineByFaction[self.unitSide]
		end
		-- log("goes to build a moho mine where the mex was reclaimed : "..unitName,self.ai)
		return unitName		
	else
		return SKIP_THIS_TASK
	end
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
			spGiveOrderToUnit(self.unitId,CMD.PATROL,{movePos.x,movePos.y,movePos.z},{})
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
		spGiveOrderToUnit(self.unitId,CMD.PATROL,{movePos.x,movePos.y,movePos.z},{})
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
	spGiveOrderToUnit(self.unitId,CMD.PATROL,{movePos.x,movePos.y,movePos.z},{})
	movePos.x=selfPos.x + (radius + random( 1, radius))
	spGiveOrderToUnit(self.unitId,CMD.PATROL,{movePos.x,movePos.y,movePos.z},CMD.OPT_SHIFT)
	
	-- do it for some time
	return {action="wait", frames=STATIC_AREA_PATROL_FRAMES}
end

function commanderBriefAreaPatrol(self)
	--if (countOwnUnitsInRadius(self,nil, self.pos, 600, 4, TYPE_L1_PLANT) < 1 and countOwnUnitsInRadius(self,nil, self.pos, 600, 4, TYPE_L2_PLANT) < 1) then
		-- do nothing
		--return SKIP_THIS_TASK
	--end
	
	return briefAreaPatrol(self)
end

function exitPlant(self)
	local radius = 100
	p = newPosition()
	p.x = self.pos.x
	p.z = self.pos.z+100
	p.y = self.pos.y
	spGiveOrderToUnit(self.unitId,CMD.MOVE,{p.x,p.y,p.z},{})

	-- log(self.unitName.." ("..self.pos.x..";"..self.pos.z..") exiting factory to ("..p.x..";"..p.z..")",self.ai) --DEBUG

	-- wait a bit to let the move order finish
	return {action="wait_idle", frames=200}
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

	spGiveOrderToUnit(self.unitId,CMD.MOVE,{p.x,p.y,p.z},{})
		
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
		spGiveOrderToUnit(self.unitId,CMD.ONOFF,{1},{})

		return SKIP_THIS_TASK
	end
	
	if checkWithinDistance(self.pos, p,radius) then
		-- near target position, stop and activate
		spGiveOrderToUnit(self.unitId,CMD.STOP,{},{})
		spGiveOrderToUnit(self.unitId,CMD.ONOFF,{1},{})
	else	
		-- far from target position, deactivate and move
		spGiveOrderToUnit(self.unitId,CMD.ONOFF,{0},{})
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

		spGiveOrderToUnit(self.unitId,CMD.MOVE,{p.x,h,p.z},{})
	end
	
	return {action="wait", frames=120}
end

function patrolAtkCenter(self)
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

	local f = spGetGameFrame()
	
	-- do not give the orders if already there
	if (distance(self.pos,p) > BIG_RADIUS) then
		spGiveOrderToUnit(self.unitId,CMD.MOVE,{p.x,p.y,p.z},{})			
		spGiveOrderToUnit(self.unitId,CMD.PATROL,{p.x - BRIEF_AREA_PATROL_RADIUS/2 + random( 1, BRIEF_AREA_PATROL_RADIUS),0,p.z - BRIEF_AREA_PATROL_RADIUS/2 + random( 1, BRIEF_AREA_PATROL_RADIUS)},CMD.OPT_SHIFT)
	--elseif (f - self.idleFrame < 90 or self.distance(self.pos,p) > MED_RADIUS) then
	elseif (true) then
		spGiveOrderToUnit(self.unitId,CMD.PATROL,{p.x,p.y,p.z},{})			
		spGiveOrderToUnit(self.unitId,CMD.PATROL,{p.x - BRIEF_AREA_PATROL_RADIUS/2 + random( 1, BRIEF_AREA_PATROL_RADIUS),0,p.z - BRIEF_AREA_PATROL_RADIUS/2 + random( 1, BRIEF_AREA_PATROL_RADIUS)},CMD.OPT_SHIFT)
	end
	
	return {action="wait", frames=120}
end

function commanderRoam(self)
	--local atkPos = self.ai.unitHandler.unitGroups[UNIT_GROUP_RAIDERS].centerPos
	local basePos = self.ai.unitHandler.basePos
	
	--log("commander roam "..#(self.ai.unitHandler.raiderPath[PF_UNIT_AMPHIBIOUS]),self.ai) --DEBUG
	
	-- if far away, move there first
	if (distance(self.pos,basePos) < HUGE_RADIUS) then
		self:orderToClosestCellAlongPath(self.ai.unitHandler.raiderPath[PF_UNIT_AMPHIBIOUS], {CMD.MOVE,CMD.MOVE}, false, true)
	else
		self:orderToClosestCellAlongPath(self.ai.unitHandler.raiderPath[PF_UNIT_AMPHIBIOUS], {CMD.MOVE,CMD.MOVE}, false, true)
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
			spGiveOrderToUnit(self.unitId,CMD.SELFD,{},{})
		else
			spGiveOrderToUnit(self.unitId,CMD.MOVE,{self.pos.x  - 120 + random( 1, 240),self.pos.y,self.pos.z - 120 + random( 1, 240)},{})	
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
			
			spGiveOrderToUnit(self.unitId,CMD.MOVE,{altPos1.x,altPos1.y,altPos1.z},{})
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
				spGiveOrderToUnit(self.unitId,firstCmd,{p.x,p.y,p.z},{})
				spGiveOrderToUnit(self.unitId,CMD.PATROL,{patrolPos.x,patrolPos.y,patrolPos.z},CMD.OPT_SHIFT)
			else
				-- if not just patrol in place
				spGiveOrderToUnit(self.unitId,CMD.PATROL,{self.pos.x  - 60 + random( 1, 120),self.pos.y,self.pos.z - 60 + random( 1, 120)},{})
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
			spGiveOrderToUnit(self.unitId,CMD.MOVE,{p1.x,p1.y,p1.z},{})			
			spGiveOrderToUnit(self.unitId,CMD.PATROL,{p2.x,0,p2.z},CMD.OPT_SHIFT)
		else
			spGiveOrderToUnit(self.unitId,CMD.PATROL,{p1.x,p1.y,p1.z},{})			
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
		spGiveOrderToUnit(self.unitId,CMD.MOVE,{p.x,p.y,p.z},{})
		
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
		spGiveOrderToUnit(self.unitId,CMD.MOVE,{p.x,p.y,p.z},{})
		
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


		spGiveOrderToUnit(self.unitId,CMD.MOVE,{p.x,p.y,p.z},{})
		
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
		unitName = buildWithMinimalMetalIncome(self,fusionByFaction[self.unitSide],40)
	else
		unitName = buildWithMinimalMetalIncome(self,buildEnergyIfNeeded(self,fusionByFaction[self.unitSide]),40)
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

	local ownCell = getNearbyCellIfExists(self.ai.unitHandler.ownBuildingCells, pos)
	local ud = nil
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
	
	return unitCount
end

function checkAreaLimit(self,unitName, builder, unitLimit, radius, type)
	-- this is special case, it means the unit will not be built anyway
	if unitName == nil or unitName == SKIP_THIS_TASK then
		return unitName
	end
		
	local pos = self.ai.buildSiteHandler:getBuildSearchPos(self,UnitDefNames[unitName])
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

	return checkAreaLimit(self,advRadarByFaction[self.unitSide], self.unitId, 1, BIG_RADIUS, nil)
	
end

function areaLimit_AdvSonar(self)
	if self.unitId == nil then
		return SKIP_THIS_TASK
	end

	return checkAreaLimit(self,advSonarByFaction[self.unitSide], self.unitId, 1, BIG_RADIUS, nil)
	
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
		spGiveOrderToUnit(self.unitId,CMD.ATTACK,{bestPos.x,spGetGroundHeight(bestPos.x,bestPos.z),bestPos.z},{})
	end

	return SKIP_THIS_TASK
end

function comsatTargetting(self)
	local bestPos = nil
	local basePos = self.ai.unitHandler.basePos
	local value = 0
	local bestValue = 0
	-- target most threathening cell, prioritizing for proximity to base
	for _,cell  in pairs(self.ai.unitHandler.enemyCellList) do
		
		value = (cell.attackerCost + cell.defenderCost + cell.airAttackerCost / 5) * (1500 / max(distance(basePos, cell.p),1500))

		if (value > bestValue) then
			bestValue = value
			bestPos = cell.p
		end		
	end
	
	if bestPos ~= nil then
		spGiveOrderToUnit(self.unitId,CMD.ATTACK,{bestPos.x,spGetGroundHeight(bestPos.x,bestPos.z),bestPos.z},{})
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
	"upgrade_red_2_commander_damage",
	"upgrade_red_2_commander_range",
	"upgrade_green_2_commander_regen",
	{action = "wait", frames = 38}
}

upgradeDefensive = {
	"upgrade_green_3_regen",
	"upgrade_green_1_hp",
	"upgrade_green_1_hp",
	"upgrade_green_1_regen",
	"upgrade_green_1_hp",
	"upgrade_green_1_regen",
	"upgrade_green_2_commander_hp",
	"upgrade_green_2_commander_regen",
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
	"upgrade_green_2_commander_hp",
	"upgrade_green_2_commander_regen",
	"upgrade_green_2_commander_regen",
	{action = "wait", frames = 38}
}

upgradeSpeed = {
	"upgrade_green_1_regen",
	"upgrade_green_1_regen",
	"upgrade_blue_1_speed",
	"upgrade_blue_1_speed",
	"upgrade_blue_1_speed",
	"upgrade_blue_2_commander_speed",
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
	"upgrade_green_2_commander_regen",
	"upgrade_red_2_commander_damage",
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
	"upgrade_blue_2_commander_light_drones",
	"upgrade_blue_3_commander_medium_drone",
	"upgrade_blue_3_commander_medium_drone",
	{action = "wait", frames = 38}
}

------------------------------- AVEN

-- choices by threat type : AIR, DEFENSES, NORMAL[, UNDERWATER]

function avenL2KbotChoice(self) return choiceByType(self,"aven_weaver",{"aven_knight","aven_bolter"},{"aven_bolter","aven_shocker","aven_dervish","aven_knight","aven_magnum","aven_raptor"}) end
function avenL1LightChoice(self) return choiceByType(self,"aven_samson",{"aven_bold","aven_duster","aven_duster"},{"aven_samson","aven_trooper","aven_warrior"}) end
function avenL2VehicleChoice(self) return choiceByType(self,{"aven_javelin","aven_kodiak"},{"aven_merl","aven_merl","aven_centurion"},{"aven_centurion","aven_kodiak"}) end
function avenL2AirChoice(self) return choiceByType(self,"aven_falcon",{"aven_gryphon", "aven_talon"},{"aven_gryphon","aven_falcon","aven_icarus"},"aven_albatross") end
function avenL2HoverChoice(self) return choiceByType(self,"aven_swatter",{"aven_turbulence", "aven_excalibur","aven_excalibur"},{"aven_slider","aven_swatter","aven_skimmer"},"aven_slider_s") end
function avenL2KbotRadar(self) return buildWithLimitedNumber(self,"aven_marky",1) end
function avenL2KbotRadarJammer(self) return buildWithLimitedNumber(self,"aven_eraser",1) end
function avenL2VehicleRadar(self) return buildWithLimitedNumber(self,"aven_seer",1) end
function avenL2VehicleRadarJammer(self) return buildWithLimitedNumber(self,"aven_jammer",1) end
function avenL2HoverIntel(self) return buildWithLimitedNumber(self,"aven_perceptor",1) end
function avenL1ShipChoice(self) return choiceByType(self,{"aven_skeeter","aven_vanguard"},"aven_crusader",{"aven_skeeter","aven_vanguard"},"aven_lurker") end
function avenL2ShipChoice(self) return choiceByType(self,"aven_fletcher",{"aven_conqueror","aven_emperor"},{"aven_conqueror","aven_piranha","aven_fletcher"},"aven_piranha") end
function avenScoper(self) return buildWithLimitedNumber(self,"aven_scoper",1) end

avenCommander = {
	brutalPlant,
	brutalAirPlant,
	brutalLightDefense,
	brutalAADefense,
	brutalHeavyDefense,
	moveBaseCenter,
	checkMorph,
	windSolarIfNeeded,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	windSolarIfNeeded,
	windSolarIfNeeded,
	lvl1PlantIfNeeded,
	--commanderBriefAreaPatrol,
	areaLimit_L1HeavyDefense,
	changeQueueToCommanderAttackerIfNeeded,
	changeQueueToCommanderBaseBuilderIfNeeded,	
	changeQueueToWaterCommanderIfNeeded,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	windSolarIfNeeded,
	areaLimit_Llt,
	windSolarIfNeeded,
	windSolarIfNeeded,
	windSolarIfNeeded,
	moveBaseCenter,
	areaLimit_Respawner,
	scoutPadIfNeeded,
	areaLimit_Llt,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	areaLimit_Radar,
	windSolarIfNeeded,
	windSolarIfNeeded,
	windSolarIfNeeded,
	windSolarIfNeeded,
	changeQueueToCommanderAttackerIfNeeded
}


avenWaterCommander = {
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	tidalIfNeeded,
	areaLimit_WaterLlt,
	tidalIfNeeded,
	areaLimit_Respawner,
	areaLimit_WaterLlt,	
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	areaLimit_WaterRadar,		
	lvl1ShipyardIfNeeded,
	briefAreaPatrol,
	areaLimit_Llt,
	storageIfNeeded,
	storageIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	areaLimit_Respawner,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	changeQueueToCommanderAttackerIfNeeded,
	lvl2ShipyardIfNeeded,
	briefAreaPatrol,
	upgradeCenterIfNeeded,
	restoreQueue
}

avenUCommander = {
	checkMorph,
	changeQueueToCommanderBaseBuilderIfNeeded,
	changeQueueToRoamingCommanderIfNeeded,
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


avenLev1Con = {
	{action = "cleanup", frames = CLEANUP_FRAMES},
	exitPlant,
	metalExtractorNearbyIfSafe,
	windSolarIfNeeded,
	moveBaseCenter,
	windSolarIfNeeded,
	areaLimit_Respawner,
	scoutPadIfNeeded,
	lvl2PlantIfNeeded,
	lvl1PlantIfNeeded,
	changeQueueToMexBuilderIfNeeded,
	basePatrolIfNeeded,
	changeQueueToDefenseBuilderIfNeeded,
	patrolAtkCenterIfNeeded,
	assistOtherBuilderIfNeeded,
	windSolarIfNeeded,
	metalExtractorNearbyIfSafe,
	areaLimit_L1HeavyDefense,
	areaLimit_LightAA,
	geoIfNeeded,
	windSolarIfNeeded,
	windSolarIfNeeded,
	upgradeCenterIfNeeded,
	metalExtractorNearbyIfSafe,
	briefAreaPatrol,
	areaLimit_L1ArtilleryDefense,
	storageIfNeeded,
	areaLimit_LightAA,
	lvl2PlantIfNeeded,
	lvl1PlantIfNeeded,
	briefAreaPatrol,
	windSolarIfNeeded,
	areaLimit_L1HeavyDefense,
	windSolarIfNeeded,
	areaLimit_L1ArtilleryDefense,
	areaLimit_Radar,
	windSolarIfNeeded,
	storageIfNeeded,
	geoIfNeeded,
	areaLimit_Respawner,	
	moveBaseCenter
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


avenLev2Con = {
	{action = "cleanup", frames = CLEANUP_FRAMES},
	exitPlant,
	brutalFusion,
	airRepairPadIfNeeded,
	areaLimit_Respawner,
	changeQueueToMexUpgraderIfNeeded,
	changeQueueToAdvancedDefenseBuilderIfNeeded,
	moveSafePos,
	fusionIfNeeded,
	lvl1PlantIfNeeded,
	lvl2PlantIfNeeded,
	upgradeCenterIfNeeded,
	areaLimit_L2HeavyAA,
	areaLimit_AdvRadar,
	areaLimit_L2ArtilleryDefense,
	moveVulnerablePos,
	areaLimit_L2LongRangeArtillery,
	airRepairPadIfNeeded,
	{action = "cleanup", frames = CLEANUP_FRAMES},
	moveBaseCenter	
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

avenL1GroundRaiders = {
	"aven_runner",
	"aven_kit",
	"aven_wheeler",
	"aven_runner",
	"aven_kit",
	"aven_wheeler",
	"aven_runner",
	restoreQueue	
}

avenLightPlant = {
	"aven_runner",
	"aven_samson",
	"aven_construction_kbot",
	{action = "randomness", probability = 0.5, value = "aven_construction_kbot"},
	changeQueueToLightGroundRaidersIfNeeded,
	avenL1LightChoice,
	avenL1LightChoice,
	avenL1LightChoice,
	"aven_trooper",
	"aven_bold",
	{action = "randomness", probability = 0.25, value = "aven_trooper"},
	{action = "randomness", probability = 0.25, value = "aven_warrior"},
	"aven_duster",
	{action = "wait", frames = 128}
}

avenAircraftPlant = {
	"aven_swift",
	"aven_construction_aircraft",
	{action = "randomness", probability = 0.3, value = "aven_construction_aircraft"},
	"aven_swift",
	"aven_tornado",
	"aven_swift",
	"aven_twister",
	"aven_swift",
	avenScoper,
	{action = "wait", frames = 128}
}

avenShipPlant = {
	"aven_skeeter",
	"aven_construction_ship",
	avenL1ShipChoice,
	avenL1ShipChoice,
	avenL1ShipChoice,
	{action = "wait", frames = 128}
}

avenAdvAircraftPlant = {
	"aven_falcon",
	"aven_adv_construction_aircraft",
	avenScoper,
	avenL2AirChoice,
	avenL2AirChoice,
	avenL2AirChoice,
	"aven_falcon",
	"aven_gryphon",
	"aven_icarus",
	zephyrIfNeeded,
	{action = "wait", frames = 128}
}

avenAdvKbotLab = {
	"aven_stalker",
	{action = "randomness", probability = 0.5, value = "aven_stalker"},
	{action = "randomness", probability = 0.5, value = "aven_stalker"},
	"aven_adv_construction_kbot",
	avenL2KbotRadar,
	avenL2KbotRadarJammer,
	"aven_knight",
	avenL2KbotChoice,
	avenL2KbotChoice,
	avenL2KbotChoice,
	avenL2KbotRadar,
	avenL2KbotRadarJammer,
	"aven_bolter",
	"aven_weaver",
	"aven_sniper",
	{action = "wait", frames = 128}
}

avenAdvVehiclePlant = {
	"aven_racer",
	{action = "randomness", probability = 0.5, value = "aven_racer"},
	{action = "randomness", probability = 0.5, value = "aven_racer"},
	"aven_javelin",
	"aven_adv_construction_vehicle",
	avenL2VehicleRadar,
	avenL2VehicleRadarJammer,
	"aven_kodiak",
	avenL2VehicleChoice,
	avenL2VehicleChoice,
	avenL2VehicleChoice,
	avenL2VehicleRadar,
	avenL2VehicleRadarJammer,
	"aven_centurion",
	"aven_merl",	
	"aven_penetrator",
	{action = "wait", frames = 128}
}


avenAdvShipPlant = {
	"aven_piranha",
	"aven_adv_construction_sub",
	avenL2ShipChoice,
	avenL2ShipChoice,
	avenL2ShipChoice,
	{action = "wait", frames = 128}
}


avenHovercraftPlant = {
	"aven_skimmer",
	"aven_construction_hovercraft",
	"aven_swatter",
	avenL2HoverIntel,
	avenL2HoverChoice,
	avenL2HoverChoice,
	avenL2HoverChoice,
	"aven_slider",
	"aven_excalibur",
	avenL2HoverIntel,
	{action = "randomness", probability = 0.5, value = "aven_turbulence"},
	{action = "randomness", probability = 0.3, value = "aven_tsunami"},
	{action = "wait", frames = 128}
}

------------------------------- GEAR

-- choices by threat type : AIR, DEFENSES, NORMAL[, UNDERWATER]

function gearL2KbotChoice(self) return choiceByType(self,{"gear_titan","gear_barrel"},{"gear_big_bob","gear_moe","gear_moe","gear_lesser_luminator"},{"gear_big_bob","gear_pyro","gear_moe","gear_psycho","gear_titan","gear_barrel"}) end
function gearL1LightChoice(self) return choiceByType(self,"gear_crasher",{"gear_assaulter","gear_thud","gear_thud"},{"gear_crasher","gear_kano","gear_box","gear_instigator","gear_pinion"}) end
function gearL2VehicleChoice(self) return choiceByType(self,"gear_marauder",{"gear_mobile_artillery","gear_reaper","gear_eruptor"},{"gear_reaper","gear_marauder","gear_rhino","gear_flareon"}) end
function gearL2AirChoice(self) return choiceByType(self,"gear_vector",{"gear_stratos","gear_firestorm"},{"gear_vector","gear_stratos","gear_firestorm"},"gear_whirlpool") end
function gearL2KbotRadar(self) return buildWithLimitedNumber(self,"gear_voyeur",1) end
function gearL2KbotRadarJammer(self) return buildWithLimitedNumber(self,"gear_spectre",1) end
function gearL2VehicleRadar(self) return buildWithLimitedNumber(self,"gear_informer",1) end
function gearL2VehicleRadarJammer(self) return buildWithLimitedNumber(self,"gear_deleter",1) end
function gearL1ShipChoice(self) return choiceByType(self,{"gear_searcher","gear_viking"},"gear_enforcer",{"gear_searcher","gear_viking"},"gear_snake") end
function gearL2ShipChoice(self) return choiceByType(self,"gear_shredder",{"gear_executioner","gear_edge"},{"gear_executioner","gear_noser"},"gear_noser") end
function gearL2HydrobotChoice(self) return choiceByType(self,{"gear_hopper","gear_stilts"},{"gear_caliber","gear_rexapod"},{"gear_salamander","gear_metalhead","gear_caliber","gear_stilts"},"gear_marooner") end
function gearScoper(self) return buildWithLimitedNumber(self,"gear_zoomer",1) end

gearCommander = {
	brutalPlant,
	brutalAirPlant,	
	brutalLightDefense,
	brutalAADefense,
	brutalHeavyDefense,
	moveBaseCenter,
	checkMorph,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	windSolarIfNeeded,
	windSolarIfNeeded,
	lvl1PlantIfNeeded,
	--commanderBriefAreaPatrol,
	areaLimit_L1HeavyDefense,	
	changeQueueToCommanderAttackerIfNeeded,
	changeQueueToCommanderBaseBuilderIfNeeded,
	changeQueueToWaterCommanderIfNeeded,	
	windSolarIfNeeded,
	areaLimit_Llt,
	windSolarIfNeeded,
	windSolarIfNeeded,	
	windSolarIfNeeded,	
	moveBaseCenter,
	areaLimit_Respawner,
	scoutPadIfNeeded,
	areaLimit_Llt,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	areaLimit_Radar,		
	windSolarIfNeeded,
	windSolarIfNeeded,
	windSolarIfNeeded,
	changeQueueToCommanderAttackerIfNeeded
}


gearWaterCommander = {
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	tidalIfNeeded,
	areaLimit_WaterLlt,
	tidalIfNeeded,
	areaLimit_Respawner,	
	areaLimit_WaterLlt,	
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	areaLimit_WaterRadar,		
	lvl1ShipyardIfNeeded,
	briefAreaPatrol,
	areaLimit_Llt,
	storageIfNeeded,
	storageIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	areaLimit_Respawner,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	changeQueueToCommanderAttackerIfNeeded,
	lvl2ShipyardIfNeeded,
	briefAreaPatrol,
	upgradeCenterIfNeeded,
	restoreQueue
}

gearUCommander = {
	checkMorph,
	changeQueueToCommanderBaseBuilderIfNeeded,
	changeQueueToRoamingCommanderIfNeeded,
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


gearLev1Con = {
	{action = "cleanup", frames = CLEANUP_FRAMES},
	exitPlant,
	metalExtractorNearbyIfSafe,
	windSolarIfNeeded,
	moveBaseCenter,
	windSolarIfNeeded,
	areaLimit_Respawner,	
	scoutPadIfNeeded,
	lvl2PlantIfNeeded,
	lvl1PlantIfNeeded,
	changeQueueToMexBuilderIfNeeded,
	basePatrolIfNeeded,
	changeQueueToDefenseBuilderIfNeeded,
	patrolAtkCenterIfNeeded,
	assistOtherBuilderIfNeeded,
	windSolarIfNeeded,
	metalExtractorNearbyIfSafe,
	areaLimit_L1HeavyDefense,
	areaLimit_LightAA,
	geoIfNeeded,
	windSolarIfNeeded,
	windSolarIfNeeded,
	windSolarIfNeeded,
	upgradeCenterIfNeeded,
	metalExtractorNearbyIfSafe,
	briefAreaPatrol,
	areaLimit_L1ArtilleryDefense,
	storageIfNeeded,
	areaLimit_LightAA,
	lvl2PlantIfNeeded,
	lvl1PlantIfNeeded,
	briefAreaPatrol,
	windSolarIfNeeded,
	areaLimit_L1HeavyDefense,
	windSolarIfNeeded,
	areaLimit_L1ArtilleryDefense,
	areaLimit_Radar,
	geoIfNeeded,
	windSolarIfNeeded,
	storageIfNeeded,
	areaLimit_Respawner,	
	moveBaseCenter
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


gearLev2Con = {
	{action = "cleanup", frames = CLEANUP_FRAMES},
	exitPlant,
	brutalFusion,
	airRepairPadIfNeeded,
	areaLimit_Respawner,
	changeQueueToMexUpgraderIfNeeded,
	changeQueueToAdvancedDefenseBuilderIfNeeded,
	moveSafePos,
	fusionIfNeeded,
	lvl1PlantIfNeeded,
	lvl2PlantIfNeeded,
	upgradeCenterIfNeeded,
	areaLimit_L2HeavyAA,
	areaLimit_AdvRadar,
	areaLimit_L2ArtilleryDefense,
	moveVulnerablePos,
	areaLimit_L2LongRangeArtillery,
	airRepairPadIfNeeded,
	{action = "cleanup", frames = CLEANUP_FRAMES},
	moveBaseCenter
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

gearL1GroundRaiders = {
	"gear_harasser",
	{action = "randomness", probability = 0.5, value = "gear_igniter"},
	{action = "randomness", probability = 0.5, value = "gear_igniter"},
	"gear_harasser",
	"gear_igniter",
	"gear_harasser",
	"gear_harasser",
	restoreQueue	
}

gearLightPlant = {
	"gear_harasser",
	"gear_construction_kbot",
	{action = "randomness", probability = 0.5, value = "gear_construction_kbot"},
	"gear_pinion",
	changeQueueToLightGroundRaidersIfNeeded,
	gearL1LightChoice,
	gearL1LightChoice,
	gearL1LightChoice,
	"gear_instigator",
	"gear_assaulter",	
	"gear_kano",
	"gear_canister",
	{action = "wait", frames = 128}
}

gearAircraftPlant = {
	"gear_dash",
	"gear_construction_aircraft",
	{action = "randomness", probability = 0.3, value = "gear_construction_aircraft"},	
	"gear_dash",
	"gear_zipper",
	"gear_dash",
	"gear_knocker",
	"gear_dash",
	gearScoper,
	{action = "wait", frames = 128}
}

gearShipPlant = {
	"gear_searcher",
	"gear_construction_ship",
	gearL1ShipChoice,
	gearL1ShipChoice,
	gearL1ShipChoice,
	{action = "wait", frames = 128}
}

gearAdvAircraftPlant = {
	"gear_vector",
	"gear_adv_construction_aircraft",
	gearScoper,
	gearL2AirChoice,
	gearL2AirChoice,
	gearL2AirChoice,
	"gear_vector",
	"gear_firestorm",
	"gear_stratos",
	{action = "wait", frames = 128}
}

gearAdvKbotLab = {
	"gear_psycho",
	{action = "randomness", probability = 0.5, value = "gear_psycho"},
	{action = "randomness", probability = 0.5, value = "gear_psycho"},
	gearL2KbotRadar,
	gearL2KbotRadarJammer,
	"gear_moe",
	"gear_adv_construction_kbot",
	"gear_cube",
	gearL2KbotChoice,
	gearL2KbotChoice,
	gearL2KbotChoice,
	"gear_moe",
	"gear_big_bob",	
	gearL2KbotRadar,
	gearL2KbotRadarJammer,
	"gear_titan",
	"gear_lesser_luminator",
	{action = "randomness", probability = 0.1, value = "gear_luminator"},
	{action = "wait", frames = 128}
}

gearAdvVehiclePlant = {
	"gear_marauder",
	"gear_adv_construction_vehicle",
	"gear_igniter",
	gearL2VehicleRadar,
	gearL2VehicleRadarJammer,
	gearL2VehicleChoice,
	gearL2VehicleChoice,
	gearL2VehicleChoice,
	"gear_reaper",
	"gear_mobile_artillery",	
	gearL2VehicleRadar,
	gearL2VehicleRadarJammer,
	"gear_eruptor",
	"gear_tremor",	
	{action = "randomness", probability = 0.2, value = "gear_might"},
	{action = "wait", frames = 128}
}


gearAdvShipPlant = {
	"gear_noser",
	"gear_adv_construction_sub",
	gearL2ShipChoice,
	gearL2ShipChoice,
	gearL2ShipChoice,
	{action = "wait", frames = 128}
}

gearHydrobotPlant = {
	"gear_salamander",
	"gear_adv_construction_hydrobot",
	gearL2HydrobotChoice,
	gearL2HydrobotChoice,
	gearL2HydrobotChoice,
	{action = "wait", frames = 128}
}

------------------------------- CLAW

-- choices by threat type : AIR, DEFENSES, NORMAL[, UNDERWATER]

function clawL1LandChoice(self) return choiceByType(self,"claw_jester",{"claw_grunt","claw_piston","claw_roller"},{"claw_grunt","claw_boar","claw_piston","claw_roller","claw_ringo"}) end
function clawL2KbotChoice(self) return choiceByType(self,"claw_bishop",{"claw_shrieker","claw_brute","claw_crawler"},{"claw_centaur","claw_brute"}) end
function clawL2VehicleChoice(self) return choiceByType(self,"claw_ravager",{"claw_pounder","claw_pounder","claw_armadon"},{"claw_halberd","claw_ravager","claw_mega","claw_dynamo"}) end
function clawL2AirChoice(self) return choiceByType(self,"claw_x","claw_blizzard",{"claw_x","claw_blizzard"},"claw_trident") end
function clawL2SpinbotChoice(self) return choiceByType(self,{"claw_dizzy","claw_tempest"},"claw_gyro",{"claw_mace","claw_predator","claw_gyro","claw_dizzy"}) end
function clawL2KbotRadar(self) return buildWithLimitedNumber(self,"claw_revealer",1) end
function clawL2KbotRadarJammer(self) return buildWithLimitedNumber(self,"claw_shade",1) end
function clawL2VehicleRadar(self) return buildWithLimitedNumber(self,"claw_seer",1) end
function clawL2VehicleRadarJammer(self) return buildWithLimitedNumber(self,"claw_jammer",1) end
function clawL1ShipChoice(self) return choiceByType(self,{"claw_speeder","claw_striker"},"claw_sword",{"claw_speeder","claw_striker"},"claw_spine") end
function clawL2ShipChoice(self) return choiceByType(self,"claw_predator",{"claw_maul","claw_wrecker"},{"claw_drakkar","claw_monster"},"claw_monster") end
function clawL2SpinbotRadar(self) return buildWithLimitedNumber(self,"claw_haze",1) end
function clawScoper(self) return buildWithLimitedNumber(self,"claw_lensor",1) end

clawCommander = {
	brutalPlant,
	brutalAirPlant,	
	brutalLightDefense,
	brutalAADefense,
	brutalHeavyDefense,
	moveBaseCenter,
	checkMorph,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	windSolarIfNeeded,
	windSolarIfNeeded,
	lvl1PlantIfNeeded,
	--commanderBriefAreaPatrol,
	areaLimit_MediumAA,
	--areaLimit_MediumAA,
	changeQueueToCommanderAttackerIfNeeded,
	changeQueueToCommanderBaseBuilderIfNeeded,
	changeQueueToWaterCommanderIfNeeded,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	windSolarIfNeeded,
	areaLimit_Llt,
	windSolarIfNeeded,
	windSolarIfNeeded,
	windSolarIfNeeded,
	moveBaseCenter,
	areaLimit_Respawner,
	scoutPadIfNeeded,
	areaLimit_Llt,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	areaLimit_Radar,
	windSolarIfNeeded,
	windSolarIfNeeded,
	windSolarIfNeeded,
	changeQueueToCommanderAttackerIfNeeded
}


clawWaterCommander = {
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	tidalIfNeeded,
	areaLimit_WaterLlt,
	tidalIfNeeded,
	areaLimit_Respawner,	
	areaLimit_WaterLlt,	
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	areaLimit_WaterRadar,		
	lvl1ShipyardIfNeeded,
	briefAreaPatrol,
	areaLimit_WaterLlt,
	storageIfNeeded,
	storageIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	areaLimit_Respawner,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	changeQueueToCommanderAttackerIfNeeded,
	lvl2ShipyardIfNeeded,
	briefAreaPatrol,
	upgradeCenterIfNeeded,
	restoreQueue
}

clawUCommander = {
	checkMorph,
	changeQueueToCommanderBaseBuilderIfNeeded,
	changeQueueToRoamingCommanderIfNeeded,
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

clawLev1Con = {
	{action = "cleanup", frames = CLEANUP_FRAMES},
	exitPlant,
	metalExtractorNearbyIfSafe,
	windSolarIfNeeded,
	moveBaseCenter,
	windSolarIfNeeded,
	areaLimit_Respawner,
	scoutPadIfNeeded,
	lvl2PlantIfNeeded,
	lvl1PlantIfNeeded,
	changeQueueToMexBuilderIfNeeded,
	basePatrolIfNeeded,
	changeQueueToDefenseBuilderIfNeeded,
	patrolAtkCenterIfNeeded,
	assistOtherBuilderIfNeeded,
	windSolarIfNeeded,
	metalExtractorNearbyIfSafe,
	areaLimit_L1HeavyDefense,
	areaLimit_MediumAA,
	geoIfNeeded,
	windSolarIfNeeded,
	windSolarIfNeeded,
	windSolarIfNeeded,
	upgradeCenterIfNeeded,
	metalExtractorNearbyIfSafe,
	briefAreaPatrol,
	areaLimit_L1ArtilleryDefense,
	storageIfNeeded,
	areaLimit_MediumAA,
	lvl2PlantIfNeeded,
	lvl1PlantIfNeeded,
	briefAreaPatrol,
	windSolarIfNeeded,
	areaLimit_L1HeavyDefense,
	windSolarIfNeeded,
	areaLimit_L1ArtilleryDefense,
	areaLimit_Radar,
	geoIfNeeded,
	windSolarIfNeeded,
	storageIfNeeded,
	areaLimit_Respawner,	
	moveBaseCenter
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


clawLev2Con = {
	{action = "cleanup", frames = CLEANUP_FRAMES},
	exitPlant,
	brutalFusion,
	airRepairPadIfNeeded,
	areaLimit_Respawner,
	changeQueueToMexUpgraderIfNeeded,
	changeQueueToAdvancedDefenseBuilderIfNeeded,
	moveSafePos,
	fusionIfNeeded,
	lvl1PlantIfNeeded,
	lvl2PlantIfNeeded,
	upgradeCenterIfNeeded,
	areaLimit_L2HeavyAA,
	areaLimit_AdvRadar,	
	areaLimit_L2ArtilleryDefense,
	moveVulnerablePos,
	areaLimit_L2LongRangeArtillery,
	airRepairPadIfNeeded,
	{action = "cleanup", frames = CLEANUP_FRAMES},
	moveBaseCenter
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

clawL1GroundRaiders = {
	"claw_knife",
	{action = "randomness", probability = 0.5, value = "claw_ringo"},
	{action = "randomness", probability = 0.5, value = "claw_ringo"},
	"claw_knife",
	"claw_ringo",
	"claw_knife",
	restoreQueue	
}

clawPlant = {
	"claw_knife",
	"claw_jester",
	"claw_construction_kbot",
	{action = "randomness", probability = 0.5, value = "claw_construction_kbot"},
	changeQueueToLightGroundRaidersIfNeeded,
	clawL1LandChoice,
	clawL1LandChoice,
	clawL1LandChoice,
	"claw_roller",
	"claw_grunt",
	"claw_boar",
	{action = "wait", frames = 128}
}


clawAircraftPlant = {
	"claw_hornet",
	"claw_construction_aircraft",
	{action = "randomness", probability = 0.3, value = "claw_construction_aircraft"},
	"claw_hornet",
	"claw_boomer",
	"claw_hornet",
	"claw_boomer_m",
	"claw_hornet",
	clawScoper,
	{action = "wait", frames = 128}
}

clawShipPlant = {
	"claw_speeder",
	"claw_construction_ship",
	clawL1ShipChoice,
	clawL1ShipChoice,
	clawL1ShipChoice,
	{action = "wait", frames = 128}
}

clawAdvAircraftPlant = {
	"claw_x",
	"claw_adv_construction_aircraft",
	clawScoper,
	clawL2AirChoice,
	clawL2AirChoice,
	clawL2AirChoice,
	"claw_x",
	"claw_blizzard",
	"claw_x",
	{action = "randomness", probability = 0.3, value = "claw_havoc"},
	{action = "wait", frames = 128}
}

clawAdvKbotLab = {
	"claw_centaur",
	{action = "randomness", probability = 0.5, value = "claw_centaur"},
	{action = "randomness", probability = 0.5, value = "claw_centaur"},
	"claw_adv_construction_kbot",
	clawL2KbotRadar,
	clawL2KbotRadarJammer,
	"claw_brute",
	clawL2KbotChoice,
	clawL2KbotChoice,
	clawL2KbotChoice,
	"claw_nucleus",
	"claw_bishop",	
	clawL2KbotRadar,
	clawL2KbotRadarJammer,
	"claw_shrieker",
	{action = "wait", frames = 128}
}

clawAdvVehiclePlant = {
	"claw_ravager",
	"claw_adv_construction_vehicle",
	clawL2VehicleRadar,
	clawL2VehicleRadarJammer,
	clawL2VehicleChoice,
	clawL2VehicleChoice,
	clawL2VehicleChoice,
	"claw_halberd",
	"claw_pounder",
	{action = "randomness", probability = 0.5, value = "claw_dynamo"},	
	clawL2VehicleRadar,
	clawL2VehicleRadarJammer,
	{action = "randomness", probability = 0.3, value = "claw_pike"},
	"claw_armadon",	
	{action = "wait", frames = 128}
}

clawAdvShipPlant = {
	"claw_monster",
	"claw_adv_construction_ship",
	clawL2ShipChoice,
	clawL2ShipChoice,
	clawL2ShipChoice,
	{action = "wait", frames = 128}
}

clawSpinbotPlant = {
	"claw_dizzy",
	"claw_adv_construction_spinbot",
	clawL2SpinbotRadar,
	"claw_gyro",
	clawL2SpinbotChoice,
	clawL2SpinbotChoice,
	clawL2SpinbotChoice,
	"claw_gyro",
	clawL2SpinbotRadar,
	"claw_tempest",
	{action = "randomness", probability = 0.3, value = "claw_tempest"},
	{action = "wait", frames = 128}
}


------------------------------- SPHERE


-- choices by threat type : AIR, DEFENSES, NORMAL[, UNDERWATER]

function sphereL1LandChoice(self) return choiceByType(self,{"sphere_needles","sphere_needles","sphere_slicer"},"sphere_rock",{"sphere_bit","sphere_rock","sphere_gaunt","sphere_double"}) end
function sphereL2KbotChoice(self) return choiceByType(self,{"sphere_chub","sphere_chub","sphere_hermit"},{"sphere_ark","sphere_ark","sphere_golem"},{"sphere_hanz","sphere_chub"}) end
function sphereL2VehicleChoice(self) return choiceByType(self,"sphere_pulsar",{"sphere_slammer","sphere_slammer","sphere_bulk"},{"sphere_pulsar","sphere_trax","sphere_bulk"}) end
function sphereL2AirChoice(self) return choiceByType(self,"sphere_twilight","sphere_meteor",{"sphere_meteor","sphere_spitfire","sphere_twilight"},"sphere_neptune") end
function sphereL2SphereChoice(self) return choiceByType(self,"sphere_aster","sphere_gazer",{"sphere_nimbus","sphere_gazer"}) end
function sphereL2KbotRadar(self) return buildWithLimitedNumber(self,"sphere_sensor",1) end
function sphereL2KbotRadarJammer(self) return buildWithLimitedNumber(self,"sphere_rain",2) end
function sphereL2VehicleRadar(self) return buildWithLimitedNumber(self,"sphere_scanner",1) end
function sphereL2VehicleRadarJammer(self) return buildWithLimitedNumber(self,"sphere_concealer",2) end
function sphereL1ShipChoice(self) return choiceByType(self,"sphere_reacher","sphere_endeavour",{"sphere_skiff","sphere_endeavour"},"sphere_carp") end
function sphereL2ShipChoice(self) return choiceByType(self,"sphere_stalwart",{"sphere_stalwart"},{"sphere_helix","sphere_pluto"},"sphere_pluto") end
function sphereL2SphereIntelligence(self) return buildWithLimitedNumber(self,"sphere_orb",1) end
function sphereScoper(self) return buildWithLimitedNumber(self,"sphere_resolver",1) end


sphereCommander = {
	brutalPlant,
	brutalAirPlant,	
	brutalLightDefense,
	brutalAADefense,
	brutalHeavyDefense,
	moveBaseCenter,
	checkMorph,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,	
	roughFusionIfNeeded,
	lvl1PlantIfNeeded,
	--commanderBriefAreaPatrol,
	areaLimit_MediumAA,
	changeQueueToCommanderAttackerIfNeeded,
	changeQueueToCommanderBaseBuilderIfNeeded,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	areaLimit_Llt,
	moveBaseCenter,
	roughFusionIfNeeded,
	areaLimit_Respawner,
	scoutPadIfNeeded,
	areaLimit_Llt,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	areaLimit_Radar,		
	changeQueueToWaterCommanderIfNeeded,
	changeQueueToCommanderAttackerIfNeeded
}


sphereWaterCommander = {
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	tidalIfNeeded,
	areaLimit_WaterLlt,
	tidalIfNeeded,
	areaLimit_Respawner,	
	areaLimit_WaterLlt,	
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	areaLimit_WaterRadar,		
	lvl1ShipyardIfNeeded,
	briefAreaPatrol,
	areaLimit_WaterLlt,
	storageIfNeeded,
	storageIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	areaLimit_Respawner,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	tidalIfNeeded,
	changeQueueToCommanderAttackerIfNeeded,
	lvl2ShipyardIfNeeded,
	briefAreaPatrol,
	upgradeCenterIfNeeded,
	restoreQueue
}

sphereUCommander = {
	checkMorph,
	changeQueueToCommanderBaseBuilderIfNeeded,
	changeQueueToRoamingCommanderIfNeeded,
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

sphereLev1Con = {
	{action = "cleanup", frames = CLEANUP_FRAMES},
	exitPlant,
	metalExtractorNearbyIfSafe,
	moveBaseCenter,
	areaLimit_Respawner,
	scoutPadIfNeeded,
	roughFusionIfNeeded,	
	lvl2PlantIfNeeded,
	lvl1PlantIfNeeded,
	changeQueueToMexBuilderIfNeeded,
	basePatrolIfNeeded,
	changeQueueToDefenseBuilderIfNeeded,
	patrolAtkCenterIfNeeded,
	assistOtherBuilderIfNeeded,
	areaLimit_Radar,	
	metalExtractorNearbyIfSafe,
	metalExtractorNearbyIfSafe,
	geoIfNeeded,
	moveSafePos,
	roughFusionIfNeeded,
	roughFusionIfNeeded,
	storageIfNeeded,
	storageIfNeeded,
	areaLimit_MediumAA,	
	moveBaseCenter,
	areaLimit_L1ArtilleryDefense,
	upgradeCenterIfNeeded,
	areaLimit_Respawner,
	areaLimit_L1HeavyDefense,
	areaLimit_MediumAA,
	areaLimit_L1ArtilleryDefense,
	geoIfNeeded,
	areaLimit_MediumAA,
	briefAreaPatrol,
	roughFusionIfNeeded,
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


sphereLev2Con = {
	{action = "cleanup", frames = CLEANUP_FRAMES},
	exitPlant,
	brutalFusion,
	airRepairPadIfNeeded,
	areaLimit_Respawner,
	changeQueueToMexUpgraderIfNeeded,
	changeQueueToAdvancedDefenseBuilderIfNeeded,
	moveSafePos,
	fusionIfNeeded,
	lvl1PlantIfNeeded,
	lvl2PlantIfNeeded,
	upgradeCenterIfNeeded,
	areaLimit_L2HeavyAA,
	areaLimit_AdvRadar,	
--	areaLimit_L2ArtilleryDefense,
	moveVulnerablePos,
	areaLimit_L2HeavyAA,
	areaLimit_L2LongRangeArtillery,
	airRepairPadIfNeeded,
	{action = "cleanup", frames = CLEANUP_FRAMES},
	moveBaseCenter	
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

sphereL1GroundRaiders = {
	"sphere_trike",
	{action = "randomness", probability = 0.5, value = "sphere_double"},
	{action = "randomness", probability = 0.5, value = "sphere_double"},
	{action = "randomness", probability = 0.5, value = "sphere_double"},
	"sphere_trike",
	"sphere_double",
	"sphere_trike",
	restoreQueue	
}

spherePlant = {
	"sphere_trike",
	"sphere_needles",
	"sphere_construction_vehicle",
	{action = "randomness", probability = 0.5, value = "sphere_construction_vehicle"},
	changeQueueToLightGroundRaidersIfNeeded,
	{action = "randomness", probability = 0.5, value = "sphere_double"},
	sphereL1LandChoice,
	sphereL1LandChoice,
	sphereL1LandChoice,
	"sphere_slicer",
	"sphere_bit",
	"sphere_gaunt",
	{action = "wait", frames = 128}
}


sphereAircraftPlant = {
	"sphere_moth",
	"sphere_construction_aircraft",
	{action = "randomness", probability = 0.5, value = "sphere_construction_aircraft"},	
	"sphere_moth",
	"sphere_moth",
	"sphere_moth",
	"sphere_moth",
	"sphere_tycho",
	sphereScoper,
	{action = "wait", frames = 128}
}

sphereShipPlant = {
	"sphere_skiff",
	"sphere_construction_ship",
	sphereL1ShipChoice,
	sphereL1ShipChoice,
	sphereL1ShipChoice,
	{action = "wait", frames = 128}
}

sphereAdvAircraftPlant = {
	"sphere_spitfire",
	"sphere_adv_construction_aircraft",
	sphereScoper,
	sphereL2AirChoice,
	sphereL2AirChoice,
	sphereL2AirChoice,
	"sphere_twilight",
	"sphere_meteor",
	{action = "wait", frames = 128}
}

sphereAdvKbotLab = {
	"sphere_hanz",
	"sphere_adv_construction_kbot",
	sphereL2KbotRadar,
	sphereL2KbotRadarJammer,
	"sphere_chub",
	sphereL2KbotChoice,
	sphereL2KbotChoice,
	sphereL2KbotChoice,
	"sphere_charger",
	sphereL2KbotRadar,
	sphereL2KbotRadarJammer,
	"sphere_golem",	
	"sphere_hermit",
	{action = "wait", frames = 128}
}

sphereAdvVehiclePlant = {
	"sphere_quad",
	{action = "randomness", probability = 0.5, value = "sphere_quad"},
	{action = "randomness", probability = 0.5, value = "sphere_quad"},
	"sphere_trax",
	"sphere_adv_construction_vehicle",
	sphereL2VehicleRadar,
	sphereL2VehicleRadarJammer,
	sphereL2VehicleChoice,
	sphereL2VehicleChoice,
	sphereL2VehicleChoice,
	"sphere_slammer",
	sphereL2VehicleRadar,
	sphereL2VehicleRadarJammer,
	"sphere_bulk",
	"sphere_shielder",
	{action = "wait", frames = 128}
}

sphereSpherePlant = {
	"sphere_nimbus",
	"sphere_nimbus",
	"sphere_construction_sphere",
	sphereL2SphereIntelligence,
	sphereL2SphereChoice,
	sphereL2SphereChoice,
	sphereL2SphereChoice,
	"sphere_gazer",
	sphereL2SphereIntelligence,
	{action = "randomness", probability = 0.2, value = "sphere_chroma"},
	{action = "wait", frames = 128}
}

sphereAdvShipPlant = {
	"sphere_monster",
	"sphere_adv_construction_ship",
	sphereL2ShipChoice,
	sphereL2ShipChoice,
	sphereL2ShipChoice,
	{action = "wait", frames = 128}
}


------------------------------- unit-queue table

mexUpgraderQueueByFaction = { [side1Name] = avenMexUpgrader, [side2Name] = gearMexUpgrader, [side3Name] = clawMexUpgrader, [side4Name] = sphereMexUpgrader}
mexBuilderQueueByFaction = { [side1Name] = avenMexBuilder, [side2Name] = gearMexBuilder, [side3Name] = clawMexBuilder, [side4Name] = sphereMexBuilder}
commanderBaseBuilderQueueByFaction = { [side1Name] = avenCommander, [side2Name] = gearCommander, [side3Name] = clawCommander, [side4Name] = sphereCommander}
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
	 


	-- factories
	local targetFactories = currentStrategy.stages[sStage].factories
	local buildsFactories = currentStrategy.stages[sStage].properties.commanderBuildsFactories
	if (targetFactories) then
		for i,props in ipairs(targetFactories) do
			local minCount = props.min 
			local uName = props.name
			if (buildsFactories or constructionTowers[uName]) then
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
	if (incomeM > comAttackerMetalIncome and incomeE > comAttackerEnergyIncome and countOwnUnits(self,nil,2,TYPE_PLANT) > 0) then
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
	if (incomeE < targetEnergyIncome) then
		action = L1EnergyGenerator(self)
		if (action ~= SKIP_THIS_TASK) then
			return action
		end
	end


	self.couldNotFindGeoSpot = false
	self.couldNotFindMetalSpot = false
	-- short patrol
	self.briefAreaPatrolFrames = 300
	return briefAreaPatrol(self)
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
	
	-- factories (only level 1 and 2 plants)
	local targetFactories = currentStrategy.stages[sStage].factories
	if (targetFactories) then
		for i,props in ipairs(targetFactories) do
			local minCount = props.min 
			local uName = props.name
			
			if self:checkPreviousAttempts(uName) and setContains(unitTypeSets[TYPE_PLANT],uName) then
				if checkAllowedConditions(self,props) and (countOwnUnits(self,uName, minCount, nil) < minCount) then
					return uName
				end
			end
		end
	end

	-- defense
	if defenseDensityMult > 0 then
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

	-- other production buildings
	local targetFactories = currentStrategy.stages[sStage].factories
	if (targetFactories) then
		for i,props in ipairs(targetFactories) do
			local minCount = props.min 
			local uName = props.name
			if self:checkPreviousAttempts(uName) and not setContains(unitTypeSets[TYPE_PLANT],uName) then
				if checkAllowedConditions(self,props) and (countOwnUnits(self,uName, 99, nil) < minCount) then
					return uName
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
	if (self.ai.unitHandler.baseUnderAttack) then
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
	if (incomeM < minMetalIncome and currentLevelE > 0.5*storageE) then
		action = metalExtractorNearbyIfSafe(self)
		if action ~= SKIP_THIS_TASK then
			return action
		end
	end	
	if (incomeE < minEnergyIncome or currentLevelE < 0.5*storageE ) then
		action = geoNearbyIfSafe(self)
		if (action ~= SKIP_THIS_TASK) then
			return action
		end
		if (self.isAdvBuilder) then
			action = fusionIfNeeded(self)
			if (action ~= SKIP_THIS_TASK) then
				return action
			else
				action = L1EnergyGenerator(self)
				if (action ~= SKIP_THIS_TASK) then
					return action
				end
			end
		else
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
	
	-- factories
	local targetFactories = currentStrategy.stages[sStage].factories
	if (targetFactories) then
		for i,props in ipairs(targetFactories) do
			local minCount = props.min
			local maxCount = props.max
			local uName = props.name
			if (checkAllowedConditions(self,props) and countOwnUnits(self,uName, 99, nil) < maxCount) then
	
				-- if unit is far away from base center, move to center and then retry
				if farFromBaseCenter(self)  then
					self:retry()
					return moveBaseCenter(self)
				end	

				--log(self.unitName.." trying to build a factory : "..uName,self.ai) --DEBUG				
				return uName
			end
		end
	end
	
	-- set up minimal defense if necessary
	action = defendNearbyBuildingsIfNeeded(self, 0.1)
	if action ~= SKIP_THIS_TASK then
		return action
	end	
	
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
	if (incomeM > 50 and (not brutalStartDelayActive)) then
		action = buildWithLimitedNumber(self, comsatByFaction[self.unitSide],min(1 + floor(incomeM/30),6))
		if action ~= SKIP_THIS_TASK then
			return action
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
			else
				action = L1EnergyGenerator(self)
				if (action ~= SKIP_THIS_TASK) then
					return action
				end
			end
		else
			action = L1EnergyGenerator(self)
			if (action ~= SKIP_THIS_TASK) then
				--log(self.unitName.." HERE L1ENERGY adv="..tostring(self.isAdvBuilder).." act="..action,self.ai) --DEBUG
				return action
			end
		end
	end
		
	-- if unit is far away from base center, move to center
	if farFromBaseCenter(self) then
		return moveBaseCenter(self)
	end	
	
	self.couldNotFindGeoSpot = false
	self.couldNotFindMetalSpot = false
	--log(self.unitName.." brief area patrol ",self.ai) --DEBUG
	-- short patrol
	self.briefAreaPatrolFrames = 300
	return briefAreaPatrol(self)
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
	-- factories
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
					--Spring.Echo(spGetGameFrame().." HERE2 plant "..uName.." cnt="..currentCount.." maxCnt="..props.weight*mobileUnitCount / totalWeight) --DEBUG
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
	aven_commander = avenCommander,
	aven_u1commander = avenUCommander,
	aven_u2commander = avenUCommander,
	aven_u3commander = avenUCommander,
	aven_u4commander = avenUCommander,
	aven_u5commander = avenUCommander,
	aven_u6commander = avenUCommander,
	aven_construction_vehicle = avenLev1Con,
	aven_construction_kbot = avenLev1Con,
	aven_construction_aircraft = avenLev1Con,
	aven_construction_ship = avenLev1Con,
	aven_adv_construction_vehicle = avenLev2Con,
	aven_adv_construction_kbot = avenLev2Con,
	aven_construction_hovercraft = avenLev2Con,
	aven_adv_construction_aircraft = avenLev2Con,	
	aven_adv_construction_sub = avenLev2Con,
	aven_nano_tower = staticBuilder,
	aven_light_plant = avenLightPlant,
	aven_aircraft_plant = avenAircraftPlant,
	aven_shipyard = avenShipPlant,
	aven_adv_kbot_lab = avenAdvKbotLab,
	aven_adv_vehicle_plant = avenAdvVehiclePlant,
	aven_adv_aircraft_plant = avenAdvAircraftPlant,
	aven_hovercraft_platform = avenHovercraftPlant,
	aven_adv_shipyard = avenAdvShipPlant,
	aven_upgrade_center = upgradeCenter,
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
------------------- GEAR
	gear_commander_respawner = respawner,
	gear_commander = gearCommander,
	gear_u1commander = gearUCommander,
	gear_u2commander = gearUCommander,
	gear_u3commander = gearUCommander,
	gear_u4commander = gearUCommander,
	gear_u5commander = gearUCommander,
	gear_u6commander = gearUCommander,
	gear_construction_vehicle = gearLev1Con,
	gear_construction_kbot = gearLev1Con,
	gear_construction_aircraft = gearLev1Con,
	gear_construction_ship = gearLev1Con,
	gear_adv_construction_vehicle = gearLev2Con,
	gear_adv_construction_kbot = gearLev2Con,
	gear_adv_construction_aircraft = gearLev2Con,	
	gear_adv_construction_sub = gearLev2Con,
	gear_adv_construction_hydrobot = gearLev2Con,
	gear_nano_tower = staticBuilder,
	gear_light_plant = gearLightPlant,
	gear_aircraft_plant = gearAircraftPlant,
	gear_shipyard = gearShipPlant,
	gear_adv_kbot_lab = gearAdvKbotLab,
	gear_adv_vehicle_plant = gearAdvVehiclePlant,
	gear_adv_aircraft_plant = gearAdvAircraftPlant,
	gear_adv_shipyard = gearAdvShipPlant,
	gear_hydrobot_plant = gearHydrobotPlant,
	gear_upgrade_center = upgradeCenter,
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
------------------- CLAW
	claw_commander_respawner = respawner,
	claw_commander = clawCommander,
	claw_u1commander = clawUCommander,
	claw_u2commander = clawUCommander,
	claw_u3commander = clawUCommander,
	claw_u4commander = clawUCommander,
	claw_u5commander = clawUCommander,
	claw_u6commander = clawUCommander,
	claw_construction_kbot = clawLev1Con,
	claw_construction_aircraft = clawLev1Con,
	claw_construction_ship = clawLev1Con,
	claw_adv_construction_vehicle = clawLev2Con,
	claw_adv_construction_kbot = clawLev2Con,
	claw_adv_construction_aircraft = clawLev2Con,	
	claw_adv_construction_spinbot = clawLev2Con,
	claw_adv_construction_ship = clawLev2Con,
	claw_nano_tower = staticBuilder,
	claw_light_plant = clawPlant,
	claw_aircraft_plant = clawAircraftPlant,
	claw_shipyard = clawShipPlant,
	claw_adv_kbot_plant = clawAdvKbotLab,
	claw_adv_vehicle_plant = clawAdvVehiclePlant,
	claw_adv_aircraft_plant = clawAdvAircraftPlant,
	claw_adv_shipyard = clawAdvShipPlant,
	claw_spinbot_plant = clawSpinbotPlant,
	claw_upgrade_center = upgradeCenter,
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
------------------- SPHERE
	sphere_commander_respawner = respawner,
	sphere_commander = sphereCommander,
	sphere_u1commander = sphereUCommander,
	sphere_u2commander = sphereUCommander,
	sphere_u3commander = sphereUCommander,
	sphere_u4commander = sphereUCommander,
	sphere_u5commander = sphereUCommander,
	sphere_u6commander = sphereUCommander,
	sphere_construction_vehicle = sphereLev1Con,
	sphere_construction_aircraft = sphereLev1Con,
	sphere_construction_ship = sphereLev1Con,
	sphere_adv_construction_vehicle = sphereLev2Con,
	sphere_adv_construction_kbot = sphereLev2Con,
	sphere_construction_sphere = atkPatroller,
	sphere_adv_construction_aircraft = sphereLev2Con,	
	sphere_adv_construction_sub = sphereLev2Con,
	sphere_pole = staticBuilder,
	sphere_light_factory = spherePlant,
	sphere_aircraft_factory = sphereAircraftPlant,
	sphere_shipyard = sphereShipPlant,
	sphere_adv_kbot_factory = sphereAdvKbotLab,
	sphere_adv_vehicle_factory = sphereAdvVehiclePlant,
	sphere_adv_aircraft_factory = sphereAdvAircraftPlant,
	sphere_sphere_factory = sphereSpherePlant,
	sphere_adv_shipyard = sphereAdvShipPlant,
	sphere_upgrade_center = upgradeCenter,
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
	sphere_comsat_station = comsatStation	
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