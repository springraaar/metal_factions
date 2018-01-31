include("LuaRules/Gadgets/ai/TaskQueues.lua")
 
TaskQueueBehavior = {}
TaskQueueBehavior.__index = TaskQueueBehavior

function TaskQueueBehavior.create()
   local obj = {}             -- our new object
   setmetatable(obj,TaskQueueBehavior)  -- make TaskQueueBehavior handle lookup
   return obj
end

function TaskQueueBehavior:Name()
	return "TaskQueueBehavior"
end

function TaskQueueBehavior:internalName()
	return "taskqueuebehavior"
end

function TaskQueueBehavior:Init(ai, uId)
	self.ai = ai
	self.isEasyMode = (self.ai.mode == "easy")
	self.isBrutalMode = (self.ai.mode == "brutal")
	
	-- unit properties
	self.unitId = uId
	self.unitDef = UnitDefs[spGetUnitDefID(uId)]
	self.unitDefId = self.unitDef.id
	self.unitName = self.unitDef.name
	self.unitSide = side1Name
	if string.find(self.unitName,"aven_") then
		self.unitSide = side1Name
	elseif string.find(self.unitName,"gear_") then
		self.unitSide = side2Name
	elseif string.find(self.unitName,"claw_")then
		self.unitSide = side3Name
	elseif string.find(self.unitName,"sphere_") then
		self.unitSide = side4Name
	end
	self.isCommander = setContains(unitTypeSets[TYPE_COMMANDER],self.unitName)
	self.isArmed = #self.unitDef.weapons > 0
	self.unitCost = getWeightedCostByName(self.unitName) 
	self.isMobileBuilder = not self.isCommander and self.unitDef.isMobileBuilder
	
	-- state properties
	self.active = false
	self.currentProject = nil
	self.waitLeft = 0
	self.lastWatchdogCheck = 0
	self.reclaimedMex = false
	self.noDelay = false
	self.lastRetreatOrderFrame = -ORDER_DELAY_FRAMES - 1
	self.underAttackFrame = -UNDER_ATTACK_FRAMES - 1
	self.idleFrame = -INFINITY -- last frame where UnitIdle was called (may be unreliable)
	self.idleFrames = 0 -- count of consecutive frames where wait is 0, progress is false
						-- but unit has been with idle command queue
	self.isSeriouslyDamaged = false
	self.isFullHealth = true
	self.isAttackMode = false
	self.delayCounter = 0
	self.pos = newPosition(spGetUnitPosition(uId,false,false))			
	self.specialRole = 0
	self.isWaterMode = false
	self.assistUnitId = 0
	self.pFType = getUnitPFType(self.unitDef)
	self.cleanupMaxFeatures = 10
	self.isFullyBuilt = false
	
	-- load queue
	if self:HasQueues() then
		self.queue = self:GetQueue()
	end
	
	self:Activate()
	self.ai.unitHandler.taskQueues[uId] = self
	self.waiting = {}
end

function TaskQueueBehavior:HasQueues()
	return (taskqueues[self.unitName] ~= nil)
end

function TaskQueueBehavior:UnitFinished(uId)
	if not self.active then
		return
	end
	if uId == self.unitId then
		self.isFullyBuilt = true
		self.progress = true
	end
end

function TaskQueueBehavior:UnitIdle(uId)
	if not self.active then
		return
	end
	if uId == self.unitId then
		self.idleFrame = spGetGameFrame()
		if( self.currentProject ~= "paused") then
			-- if unit was building an expensive base unit, and it is still alive and incomplete, repair it...
			if setContains(unitTypeSets[TYPE_BASE],self.currentProject) then
				local selfPos = newPosition(spGetUnitPosition(self.unitId,false,false))
				
				for _,uId2 in ipairs(Spring.GetUnitsInCylinder(selfPos.x,selfPos.z,400)) do
					local _,_,_,_,progress = spGetUnitHealth(uId2)
					local targetPos = newPosition(spGetUnitPosition(uId2,false,false))
				
					if (progress < 1 and checkWithinDistance(targetPos,selfPos,ASSIST_UNIT_RADIUS)) then
						-- order it to revert to resume previous queue item
						self:Retry()
						
						-- assist building		
						-- THIS THROWS AN ERROR : "GiveOrderToUnit() recursion is not permitted"
						-- spGiveOrderToUnit(self.unitId,CMD.REPAIR,{uId2},{})
						-- log(self.unitName.." resuming building "..self.currentProject.." at ("..targetPos.x..";"..targetPos.z..")") --DEBUG
						-- return
					end
				end
			end

			-- log("unit "..self.unitName.." is idle.", self.ai)
			self.progress = true
			self.currentProject = nil
			self.waitLeft = 0
			
		end
	end
end

-- sets the index back one item
function TaskQueueBehavior:Retry()
	if (self.idx ~= nil) then
		self.idx = self.idx - 1

		if (self.idx) < 1 then
			self.idx = nil
		end
	end
end

function TaskQueueBehavior:UnitDestroyed(uId)
	if self.unitId ~= nil then
		if uId == self.unitId then

			-- clear sleeping status
			if self.waiting ~= nil then
				for k,v in pairs(self.waiting) do
					self.ai.modules.sleep.Kill(self.waiting[k])
				end
			end
			self.waiting = nil
			self.unitId = nil

			-- clear unitHandler's reference
			self.ai.unitHandler.taskQueues[uId] = nil
		end
	end
end

function TaskQueueBehavior:UnitTaken(uId)
	if self.unitId ~= nil then
		if uId == self.unitId then

			-- clear sleeping status
			if self.waiting ~= nil then
				for k,v in pairs(self.waiting) do
					self.ai.modules.sleep.Kill(self.waiting[k])
				end
			end
			self.waiting = nil
			self.unitId = nil

			-- clear unitHandler's reference
			self.ai.unitHandler.taskQueues[uId] = nil
		end
	end
end

function TaskQueueBehavior:UnitDamaged(uId)
	if uId == self.unitId then
		local tmpFrame = spGetGameFrame()
		self.underAttackFrame = tmpFrame
	end
end

function TaskQueueBehavior:GetQueue(queue)
	--log("queue is "..tostring(queue),self.ai)
	q = queue or taskqueues[self.unitName]
	if type(q) == "function" then
		-- log("function table found!")
		q = q(self)
	end
	return q
end

function TaskQueueBehavior:ChangeQueue(queue)
	self.queue = self:GetQueue(queue)
	self.idx = nil
	self.waitLeft = 0
	self.noDelay = false
	self.progress = true
	self.delayCounter = 0
end

function TaskQueueBehavior:Update()
	local f = spGetGameFrame()
	self.pos = newPosition(spGetUnitPosition(self.unitId,false,false))
	
	local health,maxHealth,_,_,bp = spGetUnitHealth(self.unitId)
	self.isFullyBuilt = (bp > 0.999)
	if (health/maxHealth < UNIT_RETREAT_HEALTH) then
		self.isSeriouslyDamaged = true
		self.isFullHealth = false
	else
		self.isSeriouslyDamaged = false
		if (health/maxHealth > 0.99) then
			self.isFullHealth = true
		end
	end

	if (self.waitLeft > 0 ) then
		self.waitLeft = math.max(self.waitLeft - 1,0)
		-- if self.waitLeft == 0 then
			-- log("wait is over",self.ai)
		-- end
	end
	
	if(not self.unitDef.isBuilding) then
		-- retreat if necessary
		if (self.isSeriouslyDamaged or self.isCommander ) and f - self.underAttackFrame < UNDER_ATTACK_FRAMES  then
			
			-- retry current project when safe
			if(self.currentProject ~= nil and self.currentProject ~= "paused" and self.currentProject ~= "custom") then
				self:Retry()
			end
			
			self:Retreat()
			return
		end
		
		-- if is commander and base is under attack, go help!
		if (self.isCommander and self.ai.unitHandler.baseUnderAttack) then
			if self.isAttackMode == false and (countOwnUnits(self,nil,1,TYPE_PLANT) > 0 ) then
				spGiveOrderToUnit(self.unitId,CMD.STOP,{},{})
				self:ChangeQueue(commanderAtkQueueByFaction[self.unitSide])
				self.isAttackMode = true
				-- log("changed to attack commander!",self.ai)
			end
		end
	end
	
	if fmod(f,10) == 9 then
		if (self.waitLeft == 0) then
			-- progress queue if unit is idle
			if not self.progress and self.isFullyBuilt and self.currentProject == nil then
				local cmds = spGetUnitCommands(self.unitId,0)
				if (cmds <= 0) then
					self.idleFrames = self.idleFrames +10 
				
					if (self.idleFrames > IDLE_FRAMES_PROGRESS_LIMIT) then
						log(self.unitName.." was weirdly idle, progressing queue",self.ai)
						self.progress = true
					end
				else
					self.idleFrames = 0
				end
			end
		
			if self.progress == true then
				self.currentProject = nil
				self.idleFrames = 0
				-- log(self.unitName.." progressing queue",self.ai)
				self:ProgressQueue()
				return
			end
		end		
	end
end


function TaskQueueBehavior:ProgressQueue()
	self.progress = false
	
	-- log("plants="..countOwnUnits(self,nil,5,TYPE_PLANT),self.ai)
	-- log("l1plants="..countOwnUnits(self,nil,5,TYPE_L1_PLANT),self.ai)
	-- log("l2plants="..countOwnUnits(self,nil,2,TYPE_L2_PLANT),self.ai)
	
	if self.queue ~= nil then
		local idx, val = next(self.queue,self.idx)
		self.idx = idx
		if idx == nil or val == nil or val == "" then
			self.idx = nil
			self.progress = true
			return
		end
		local value = val

		-- preprocess item
		if type(value) == "table" then
			if value.action == "randomness" then
				local probability = value.probability
				if probability ~= nil then
					if(random(1,100)/100 <= probability ) then
						value = value.value	
					else
						value = SKIP_THIS_TASK
					end
				else 
					value = SKIP_THIS_TASK
				end
			end
		end

		-- process queue item, check for low resources or nearby similar units being built
		self:ProcessItem(value, DELAY_BUILDING_IF_LOW_RESOURCES, ASSIST_EXPENSIVE_BASE_UNITS)
	end
end

function TaskQueueBehavior:ProcessItem(value, checkResources, checkAssistNearby)
	local f = spGetGameFrame()
	self.lastWatchdogCheck = f	-- TODO: reintegrate watchdog or remove it?
	local success = false
	local p = false
	local selfPos = newPosition(spGetUnitPosition(self.unitId,false,false))
	local ud = nil
	
	-- evaluate any functions here, they may return tables
	while type(value) == "function" do
		value = value(self)
	end
	
	local baseUnderAttack = self.ai.unitHandler.baseUnderAttack
	
	-- on easy mode, randomly waste time
	if(self.isEasyMode and value ~= nil and type(value) ~= "table" and value ~= SKIP_THIS_TASK) then
		if (random() < EASY_RANDOM_TIME_WASTE_PROBABILITY) then
			self:Retry()
			value = {action = "wait", frames = EASY_RANDOM_TIME_WASTE_FRAMES}
		end
	end
	
	if value ~= nil and type(value) ~= "table" and value ~= SKIP_THIS_TASK then
		ud = UnitDefNames[value]
		if ud ~= nil then
			-- if building a builder, check for unit limit
			if (ud.isBuilder and countOwnUnits(self,ud.name,BUILDER_UNIT_LIMIT) >= BUILDER_UNIT_LIMIT) then
				value = SKIP_THIS_TASK
				checkResources = false
				checkAssistNearby = false
			end		

			-- if building an unnecessary unit and low on resources, delay building for a few seconds
			if(checkResources and (not self.noDelay)) then			
				local currentLevelM,storageM,_,incomeM,expenseM,_,_,_ = spGetTeamResources(self.ai.id,"metal")
				local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(self.ai.id,"energy")
	
				local check = false
				if (#ud.weapons > 0 ) then
					if( baseUnderAttack == false ) then
						check = true
					end
				else
					if( baseUnderAttack == true ) then
						check = true
					end
				end
	
				-- delay building for a few seconds
				if not (setContains(unitTypeSets[TYPE_COMMANDER], value) ) then
					local stallingE = (incomeE - expenseE < 20) and (currentLevelE < 0.30 * storageE)
					local stallingM = (incomeM - expenseM < 1) and (currentLevelM < 0.1 * storageM)

					if check and ( (stallingM and (not setContains(unitTypeSets[TYPE_EXTRACTOR],value)) ) or (stallingE and (not setContains(unitTypeSets[TYPE_ENERGYGENERATOR],value)) ) ) then
						self:Retry()
									
						if self.delayCounter > DELAY_BUILDING_IF_LOW_RESOURCES_LIMIT then
							self.delayCounter = 0
							value = SKIP_THIS_TASK
							checkAssistNearby = false
						else
							self.delayCounter = self.delayCounter + 1
							-- log("WARNING: "..self.unitName.." delays building "..value.." because of low resources", self.ai)
							value = {action = "wait", frames = 60}
						end
					end
				end
			end
			-- check if there is another copy of the unit already under construction nearby
			if (checkAssistNearby and setContains(unitTypeSets[TYPE_BASE], value) and getWeightedCost(ud) > ASSIST_UNIT_COST) then
				for uId,_ in pairs(self.ai.ownUnitIds) do
					if (UnitDefs[spGetUnitDefID(uId)].name == value ) then
						local _,_,_,_,progress = spGetUnitHealth(uId)
						local targetPos = newPosition(spGetUnitPosition(uId,false,false))
	
						if (progress < 1 and distance(selfPos, targetPos) < ASSIST_UNIT_RADIUS) then
							-- assist building
							spGiveOrderToUnit(self.unitId,CMD.REPAIR,{uId},{})
							
							-- log(self.unitName.." goes to assist building "..value.." at ("..unit:newPosition().x..";"..unit:newPosition().z..")")
							value = {action = "wait_idle", frames = 1800}
							break
						end
					end
				end
			end
		end
	end
	
	
	
	if type(value) == "table" then
		local action = value.action
		-- wait until idle
		if action == "wait_idle" then
			self.waitLeft = value.frames
			self.currentProject = "custom"
			return
		end
		-- wait until timer runs out, then progress
		if action == "wait" then
			self.waitLeft = value.frames
			self.currentProject = "paused"
			self.progress = true
			return
		end
		-- reclaim features within 500 range until the wait timer ends
		if action == "cleanup" then
			wrecks = spGetFeaturesInSphere(selfPos.x,selfPos.y,selfPos.z, 500)
			-- we only want to reclaim the first one
			self.waitLeft = value.frames
			--Spring.Echo(self.unitName.." CLEANUP "..value.frames.." frames ".." found="..tostring(#wrecks))
			if (#wrecks > 0) then
				spGiveOrderToUnit( self.unitId, CMD.RECLAIM, { self.pos.x, self.pos.y, self.pos.z, 500 }, {} )
			end	
				
			self.progress = true
		end
	else
		if value ~= SKIP_THIS_TASK then
			if value ~= nil then
				ud = UnitDefNames[value]
			else
				ud = nil
				value = "nil"
			end
			--log("building "..value)
			success = false
			if ud ~= nil then
				if true then  -- assume unit can build target
					if ud.extractsMetal > 0 or ud.needGeo == true then
						-- find a free spot
						p = newPosition(selfPos.x,selfPos.y,selfPos.z)
						if ud.extractsMetal > 0 then
							if (self.ai.mapHandler.isMetalMap == true) then
								p = self.ai.buildSiteHandler:ClosestBuildSpot(self, ud,  BUILD_SPREAD_DISTANCE)
							else
								p = self.ai.buildSiteHandler:ClosestFreeSpot(self, ud, p, true, "metal", self.unitDef, self.unitId)
							end
						else
							p = self.ai.buildSiteHandler:ClosestFreeSpot(self, ud, p, true, "geo", self.unitDef, self.unitId)
						end
						
						if p ~= nil then
							spGiveOrderToUnit(self.unitId,-ud.id,{p.x,p.y,p.z},{})
							success = true
							self.progress = false
						else
							self.progress = true
						end
					elseif self.unitDef.isFactory then
						-- ignore placement for mobile units
						spGiveOrderToUnit(self.unitId,-ud.id,{selfPos.x,selfPos.y,selfPos.z},{})
						success = true
						self.progress = false
					else
						-- defense placement
						if #ud.weapons > 0 and ud.isBuilding then
							p = self.ai.buildSiteHandler:ClosestBuildSpot(self, ud,  BUILD_SPREAD_DISTANCE)
							if p ~= nil then
								spGiveOrderToUnit(self.unitId,-ud.id,{p.x,p.y,p.z},{})
								success = true
							else
								success = false
							end
						-- misc placement
						else
							if (not setContains(unitTypeSets[TYPE_SUPPORT],value) ) then
								local spreadDistance = (setContains(unitTypeSets[TYPE_FUSION],value) and 0 or BUILD_SPREAD_DISTANCE) 
								
								p = self.ai.buildSiteHandler:ClosestBuildSpot(self, ud, spreadDistance)
								if p ~= nil then
									spGiveOrderToUnit(self.unitId,-ud.id,{p.x,p.y,p.z},{})
									success = true
								else
									-- log(self.unitName.." at ( "..selfPos.x.." ; "..selfPos.z..") could not find build spot for "..value,self.ai)
									success = false
								end
							else
								spGiveOrderToUnit(self.unitId,-ud.id,{0,0,0},{})
								success = true
							end
						end
						self.progress = not success
					end
				else
					self.progress = true
					 --log("WARNING: bad task: "..self.unitName.." cannot build "..value, self.ai)
				end
			else
				--log("Cannot build:"..value..", couldn't grab the unit type from the engine", self.ai)
				self.progress = true
			end
			if success then
				self.currentProject = value
			else
				self.currentProject = nil
			end
		else
			self.progress = true
			self.currentProject = nil
		end
	end
end


function TaskQueueBehavior:Retreat()
	local tmpFrame = spGetGameFrame()
	
	if (self.lastRetreatOrderFrame or 0) + ORDER_DELAY_FRAMES < tmpFrame then
		local selfPos = newPosition(spGetUnitPosition(self.unitId,false,false))
	
		if not self.isCommander and ( abs(selfPos.x - self.ai.unitHandler.basePos.x) > RETREAT_RADIUS or abs(selfPos.z - self.ai.unitHandler.basePos.z) > RETREAT_RADIUS  ) then
			spGiveOrderToUnit(self.unitId,CMD.MOVE,{self.ai.unitHandler.basePos.x - BIG_RADIUS/2 + random( 1, BIG_RADIUS),0,self.ai.unitHandler.basePos.z - BIG_RADIUS/2 + random( 1, BIG_RADIUS)},{})
		else
			self:EvadeIfNeeded(selfPos)
		end

		self.lastRetreatOrderFrame = tmpFrame
		self.progress = true
		self.currentProject = "custom"
		self.waitLeft = 200			
	end	
end

function TaskQueueBehavior:EvadeIfNeeded(selfPos)
	local tmpFrame = spGetGameFrame()
	
	-- only evade if under attack
	if( tmpFrame - self.underAttackFrame < UNDER_ATTACK_FRAMES) then
	
		local threatPos = nil
		local threatCost = nil
		local biggestThreatPos = nil
		local biggestThreatCost = 0
		local closestCell = nil
		local xIndex,zIndex = getCellXZIndexesForPosition(selfPos)
		
		-- find most threatening nearby enemy cell
		local xi,zi = 0
		local enemyCell = nil
		-- check nearby cells
		for dxi = -2, 2 do
			for dzi = -2, 2 do
				xi = xIndex + dxi
				zi = zIndex + dzi
				if (xi >=0) and (zi >= 0) then
					if self.ai.unitHandler.enemyCells[xi] then
						enemyCell = self.ai.unitHandler.enemyCells[xi][zi]
						if enemyCell ~= nil then
							threatCost = enemyCell.combinedThreatCost
							if (threatCost > biggestThreatCost ) then
								biggestThreatPos = enemyCell.p
								biggestThreatCost = threatCost
							end
						end													
					end
				end
			end
		end
		-- if none nearby, run from biggest enemy cluster
		for _,enemyCell in ipairs(self.ai.unitHandler.enemyCellList) do
			threatCost = enemyCell.combinedThreatCost
			if (threatCost > biggestThreatCost ) then
				biggestThreatPos = enemyCell.p
				biggestThreatCost = threatCost
			end		
		end

		if biggestThreatPos ~= nil then
			-- if the threat is cheaper than armed unit, strafe only without backing				
			self:Evade(biggestThreatPos, (biggestThreatCost > self.unitCost or (not self.isArmed) ) and UNIT_EVADE_DISTANCE or 100)
			
			return true
		end
	end
	return false
end

function TaskQueueBehavior:Evade(threatPos, moveDistance)
	local selfPos = self.pos

	local vx = selfPos.x - threatPos.x
	local vz = selfPos.z - threatPos.z
	
	local norm = sqrt(vx*vx + vz*vz)		
	vx = vx / norm  
	vz = vz / norm
	
	-- change movement vector if near edge of map
	local nearEdge = false
	local aux = pos.x + vx * moveDistance
	if (aux > Game.mapSizeX - EVADE_EDGE_MARGIN or aux < EVADE_EDGE_MARGIN) then
		nearEdge = true
	end
	aux = pos.z + vz * moveDistance
	if not nearEdge and (aux > Game.mapSizeZ - EVADE_EDGE_MARGIN or aux < EVADE_EDGE_MARGIN) then
		 nearEdge = true
	end
	-- move towards least vulnerable cell
	if (nearEdge) then
		local safePos = self.ai.unitHandler.leastVulnerableCell.p			
		vx = safePos.x - selfPos.x
		vz = safePos.z - selfPos.z

		norm = sqrt(vx*vx + vz*vz)		
		vx = vx / norm  
		vz = vz / norm
	end
	
	--Spring.Echo(self.unitName.." EVADE self=("..selfPos.x..","..selfPos.z..")".." threat=("..threatPos.x..","..threatPos.z..")".." escape=("..vx..","..vz..")")
	vxNormal = vz
	vzNormal = -vx
			
	local pos = newPosition(selfPos.x,0,selfPos.z)
	local increment = moveDistance / UNIT_EVADE_WAYPOINTS
	local strafeSign = 1 
	local strafeDistance = 0
	
	local ordersGiven = 0
	for i=1,UNIT_EVADE_WAYPOINTS do
		strafeSign = random(1,10) > 5 and 1 or -1
		strafeDistance = strafeSign * random(1,UNIT_EVADE_STRAFE_DISTANCE)
		
		pos.x = pos.x + vx * increment + vxNormal * strafeDistance
		pos.z = pos.z + vz * increment + vzNormal * strafeDistance
		-- Echo(pos.x.." ; "..pos.z)
		if  spTestMoveOrder(self.unitDef.id,pos.x,0,pos.z,0,0,0,true,true) then
			ordersGiven = ordersGiven + 1 
			spGiveOrderToUnit(self.unitId,CMD.MOVE,{pos.x,0,pos.z},i > 1 and CMD.OPT_SHIFT or {})
		end
	end
	
	if (ordersGiven == 0) then
		--Spring.Echo(self.unitName.." RUN TO BASE!")
		spGiveOrderToUnit(self.unitId,CMD.MOVE,{self.ai.unitHandler.basePos.x - BIG_RADIUS/2 + random( 1, BIG_RADIUS),0,self.ai.unitHandler.basePos.z - BIG_RADIUS/2 + random( 1, BIG_RADIUS)},{})
	end
end



function TaskQueueBehavior:Activate()
	self.progress = true
	self.active = true
end

function TaskQueueBehavior:Deactivate()
	self.active = false
end

