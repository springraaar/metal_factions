include("luarules/gadgets/ai/taskQueues.lua")
include("luarules/gadgets/ai/CommonUnitBehavior.lua")
 
TaskQueueBehavior = {}
TaskQueueBehavior.__index = TaskQueueBehavior

function TaskQueueBehavior.create()
   local obj = {}             -- our new object
   setmetatable(obj,TaskQueueBehavior)  -- make TaskQueueBehavior handle lookup
   return obj
end

-- set up inheritance
setmetatable(TaskQueueBehavior,{__index = CommonUnitBehavior})

function TaskQueueBehavior:name()
	return "TaskQueueBehavior"
end

function TaskQueueBehavior:internalName()
	return "taskqueuebehavior"
end

function TaskQueueBehavior:Init(ai, uId)
	self:commonInit(ai, uId)
	
	-- state properties
	self.active = false
	self.currentProject = nil
	self.waitLeft = 0
	self.reclaimedMex = false
	self.noDelay = false
	self.lastRetreatOrderFrame = -ORDER_DELAY_FRAMES - 1
	self.underAttackFrame = -UNDER_ATTACK_FRAMES - 1
	self.idleFrame = -INFINITY -- last frame where UnitIdle was called (may be unreliable)
	self.idleFrames = 0 -- count of consecutive frames where wait is 0, progress is false
						-- but unit has been with idle command queue
	self.isAttackMode = self.isUpgradedCommander and true or false
	self.delayCounter = 0
	self.specialRole = 0
	self.isWaterMode = false
	self.assistUnitId = 0
	self.cleanupMaxFeatures = 10
	self.isDrone = self.unitDef.customParams and self.unitDef.customParams.isdrone
	
	self.builderType = self.unitDef.customParams and self.unitDef.customParams.buildertype
	self.isStaticBuilder = constructionTowers[self.unitName] ~= nil
	self.isHighPriorityBuilder = setContains(unitTypeSets[TYPE_HIGH_PRIORITY],self.unitName)
	self.isMobileBuilder = self.unitDef.isMobileBuilder
	self.isAdvBuilder = (not self.isDrone) and self.isMobileBuilder and self.unitDef.modCategories["level2"]	
	self.isBuilder = self.isStaticBuilder or self.isMobileBuilder  
	self.buildRange = 0
	if (self.isStaticBuilder) then
		self.buildRange = self.unitDef.buildDistance
	end
	self.buildFailures = {} -- <unitName,lastAttemptFrame>
	self.couldNotFindMetalSpot = false
	self.couldNotFindGeoSpot = false
	self.beingUselessCounter = 0
	self.lastProgressFrame = 0
	self.nextMetalSpotPos = nil
	
	-- load queue
	if self:hasQueues() then
		self.queue = self:getQueue()
	end
	
	self.briefAreaPatrolFrames = BRIEF_AREA_PATROL_FRAMES 
	
	self:activate()
end

-- failed to build something, register the current frame and unit name
function TaskQueueBehavior:markBuildFailure(uName)
	self.buildFailures[uName] = spGetGameFrame()
end

-- if failed recently, return false, else clear the record and return true
function TaskQueueBehavior:checkPreviousAttempts(uName)
	local lastFailFrame = self.buildFailures[uName]
	if lastFailFrame then
		local f = spGetGameFrame()
		-- if it happened more less than ~15s ago, return false, else forget it happened
		if (f - lastFailFrame < 1000) then
			return false
		else
			self.buildFailures[uName] = nil
		end
	end
	return true
end

function TaskQueueBehavior:hasQueues()
	return (taskQueues[self.unitName] ~= nil)
end

function TaskQueueBehavior:builderRoleStr()
	if ((not self.isCommander) and self.isMobileBuilder and self.specialRole == 0) then
		if (self.isAdvBuilder) then
			return "advstd" 
		else 
			return "std"
		end
	elseif (self.specialRole == UNIT_ROLE_MEX_BUILDER) then
		 return "mex"
	elseif (self.specialRole == UNIT_ROLE_BASE_PATROLLER) then
		return "baseptl"
	elseif (self.specialRole == UNIT_ROLE_MEX_UPGRADER) then
		return "mexupg"
	elseif (self.specialRole == UNIT_ROLE_DEFENSE_BUILDER) then
		return "def"
	elseif (self.specialRole == UNIT_ROLE_ADVANCED_DEFENSE_BUILDER) then
		return "advdef"
	elseif (self.specialRole == UNIT_ROLE_ATTACK_PATROLLER) then
		return "atkptl"
	end

	return "???"
end

function TaskQueueBehavior:resetHighPriorityState()
	local desiredStateNumber = self.isHighPriorityBuilder and 1 or 0
	local desiredState = self.isHighPriorityBuilder
	if (self.highPriorityBuilderState ~= desiredState) then
		self.highPriorityBuilderState = desiredState
		spGiveOrderToUnit(self.unitId,CMD_BUILDPRIORITY,{desiredStateNumber},{})
	end
end


function TaskQueueBehavior:setHighPriorityState(desiredStateNumber)
	local desiredState = desiredStateNumber == 1 and true or false
	if (self.highPriorityBuilderState ~= desiredState) then
		self.highPriorityBuilderState = desiredState
		spGiveOrderToUnit(self.unitId,CMD_BUILDPRIORITY,{desiredStateNumber},{})
	end
end


-- sets the index back one item
function TaskQueueBehavior:retry()
	if (self.idx ~= nil) then
		self.idx = self.idx - 1

		if (self.idx) < 1 then
			self.idx = nil
		end
	end
end

function TaskQueueBehavior:getQueue(queue)
	--log("queue is "..tostring(queue),self.ai)
	q = queue or (self.ai.useStrategies and sTaskQueues[self.unitName] or nil) or taskQueues[self.unitName]
	if type(q) == "function" then
		-- log("function table found!")
		q = q(self)
	end
	return q
end

function TaskQueueBehavior:changeQueue(queue)
	self.queue = self:getQueue(queue)
	self.idx = nil
	self.waitLeft = 0
	self.noDelay = false
	self.progress = true
	self.delayCounter = 0
end


function TaskQueueBehavior:progressQueue()
	self.progress = false
	self.lastProgressFrame = spGetGameFrame() 
	
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
	
		-- reset build priority
		self:resetHighPriorityState()
		
		-- process queue item, check for low resources or nearby similar units being built
		self:processItem(value, DELAY_BUILDING_IF_LOW_RESOURCES, ASSIST_EXPENSIVE_BASE_UNITS)
		
		-- reset the mex building position
		self.nextMetalSpotPos = nil
		
		if (self.isMobileBuilder and value ~= SKIP_THIS_TASK) then
			local cmds = spGetUnitCommands(self.unitId,3)
			local cmdCount = 0
			if (cmds and (#cmds >= 0)) then
				cmdCount = #cmds
			end
			--[[
			if (self.isCommander) then
				Spring.MarkerAddPoint(self.pos.x,100,self.pos.z,tostring(tostring(self.isAttackMode).." "..cmdCount.." "..tostring(self.currentProject))) --DEBUG
			else
				Spring.MarkerAddPoint(self.pos.x,100,self.pos.z,tostring(self:builderRoleStr().." "..cmdCount.." "..tostring(self.currentProject))) --DEBUG
			end
			]]--
			-- if the unit processed something but is still with an empty command queue, do something!
			if cmdCount == 0 then
				local radius = MED_RADIUS
				local basePos = self.ai.unitHandler.basePos
				
				self.beingUselessCounter = self.beingUselessCounter + 1
				if (self.beingUselessCounter > 1) then
					
					if ( basePos.x > 0 and basePos.z > 0) then
						
						-- if unit is "disconnected" from base, order it to move a bit
						-- may be due to map hander's pathing map resolution being too low
						if not self.ai.mapHandler:checkConnection(self.ai.unitHandler.basePos, self.pos,self.pFType) then									

							--log(self.unitName.." is being useless, move (counter="..self.beingUselessCounter..")",self.ai) --DEBUG
							p = newPosition()
							p.x = basePos.x-radius/2+random(1,radius)
							p.z = basePos.z-radius/2+random(1,radius)
							p.y = spGetGroundHeight(p.x,p.z)
							spGiveOrderToUnit(self.unitId,CMD.STOP,{p.x,p.y,p.z},{})
							spGiveOrderToUnit(self.unitId,CMD.MOVE,{p.x,p.y,p.z},CMD.OPT_SHIFT)
							
							-- add another order to queue in case the first is invalid
							spGiveOrderToUnit(self.unitId,CMD.MOVE,{p.x - radius/2 + random( 1, radius),p.y,p.z - radius/2 + random( 1, radius)},CMD.OPT_SHIFT)
						else
						-- patrol a bit, do some good
	
							--log(self.unitName.." is being useless, patrol (counter="..self.beingUselessCounter..")",self.ai) --DEBUG
							p = newPosition()
							p.x = basePos.x-radius/2+random(1,radius)
							p.z = basePos.z-radius/2+random(1,radius)
							p.y = spGetGroundHeight(p.x,p.z)
							spGiveOrderToUnit(self.unitId,CMD.STOP,{p.x,p.y,p.z},{})
							spGiveOrderToUnit(self.unitId,CMD.PATROL,{p.x,p.y,p.z},CMD.OPT_SHIFT)
							
							-- add another order to queue in case the first is invalid
							spGiveOrderToUnit(self.unitId,CMD.PATROL,{p.x - radius/2 + random( 1, radius),p.y,p.z - radius/2 + random( 1, radius)},CMD.OPT_SHIFT)
						end
					
						self.progress = true
						self.currentProject = "custom"
						self.waitLeft = 120	
					end
				end
			else
				--if (self.beingUselessCounter > 0 ) then
				--	log(self.unitName.." is being useful??? (counter="..self.beingUselessCounter..") proj="..tostring(self.currentProject),self.ai) --DEBUG
				--end
				-- assume it's doing something
				self.beingUselessCounter = 0
			end
		end
	end
end

function TaskQueueBehavior:processItem(value, checkResources, checkAssistNearby)
	local f = spGetGameFrame()
	local success = false
	local p = false
	local selfPos = self.pos
	local ud = nil
	
	-- evaluate any functions here, they may return tables
	while type(value) == "function" do
		value = value(self)
	end
		
	local baseUnderAttack = self.ai.unitHandler.baseUnderAttack
	
	-- on easy mode, randomly waste time
	if(self.isEasyMode and value ~= nil and type(value) ~= "table" and value ~= SKIP_THIS_TASK) then
		if (random() < EASY_RANDOM_TIME_WASTE_PROBABILITY) then
			self:retry()
			value = {action = "wait", frames = EASY_RANDOM_TIME_WASTE_FRAMES}
		end
	end
	
	if (not self.ai.useStrategies) and value ~= nil and type(value) ~= "table" and value ~= SKIP_THIS_TASK then
		ud = UnitDefNames[value]
		if ud ~= nil then
			-- if building a builder, check for unit limit
			if (ud.isBuilder and countOwnUnits(self,ud.name,BUILDER_UNIT_LIMIT) >= BUILDER_UNIT_LIMIT) then
				value = SKIP_THIS_TASK
				checkResources = false
				checkAssistNearby = false
			end		

			-- if building an unnecessary unit and low on resources, delay building for a few seconds
			if(checkResources and (not self.noDelay)) and (not self.isCommander) then			
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
						self:retry()
									
						if self.delayCounter > DELAY_BUILDING_IF_LOW_RESOURCES_LIMIT then
							self.delayCounter = 0
							value = SKIP_THIS_TASK
							checkAssistNearby = false
						else
							self.delayCounter = self.delayCounter + 1
							--log("WARNING: "..self.unitName.." delays building "..value.." because of low resources", self.ai) --DEBUG
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
						local assistRadius = self.isStaticBuilder and self.buildRange or ASSIST_UNIT_RADIUS
						if (progress < 1 and distance(selfPos, targetPos) < assistRadius) then
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
			self.currentProject = "waiting"
			self.progress = true
			return
		end
		-- reclaim features within 500 range until the wait timer ends
		if action == "cleanup" then
			wrecks = spGetFeaturesInCylinder(selfPos.x,selfPos.z, 500)
			--log(self.unitName.." CLEANUP "..value.frames.." frames ".." found="..tostring(#wrecks),self.ai)
			if (#wrecks > 0) then
				self.waitLeft = value.frames
				spGiveOrderToUnit( self.unitId, CMD.RECLAIM, { self.pos.x, self.pos.y, self.pos.z, 500 }, {} )
			end	
				
			self.progress = true
		end
	else
		if value ~= SKIP_THIS_TASK then
			--[[
			if (self.isCommander) then
				Spring.MarkerAddPoint(self.pos.x,100,self.pos.z,tostring(tostring(self.isAttackMode).." value="..tostring(value))) --DEBUG
			else
				Spring.MarkerAddPoint(self.pos.x,100,self.pos.z,tostring(self:builderRoleStr().." value="..tostring(value))) --DEBUG
			end
			]]--
			if value ~= nil then
				ud = UnitDefNames[value]
			else
				ud = nil
				value = "nil"
			end
			
			-- TODO only assigned if a build spot was actually found
			-- assign high priority to AI normal priority builders building metal extractors, factories and fusion reactors
			--if not self.isHighPriorityBuilder then
			--	if setContains(unitTypeSets[TYPE_ECONOMY],value) or setContains(unitTypeSets[TYPE_PLANT],value) then
			--		spGiveOrderToUnit(self.unitId,CMD_BUILDPRIORITY,{1},{})
			--	end
			--end
						
			--log("building "..value)
			success = false
			if ud ~= nil then
				if true then  -- assume unit can build target
					if ud.extractsMetal > 0 or ud.needGeo == true then
						local advMetal = setContains(unitTypeSets[TYPE_MOHO],value)
						
						-- find a free spot
						p = newPosition(selfPos.x,selfPos.y,selfPos.z)
						if ud.extractsMetal > 0 then
							if (self.ai.mapHandler.isMetalMap == true) then
								p = self.ai.buildSiteHandler:closestBuildSpot(self, ud,  BUILD_SPREAD_DISTANCE)
							else
								if self.nextMetalSpotPos ~= nil then
									p = self.nextMetalSpotPos
								else
									p = self.ai.buildSiteHandler:closestFreeSpot(self, ud, p, true, advMetal and "advMetal" or "metal", self.unitDef)
								end
							end
						else
							p = self.ai.buildSiteHandler:closestFreeSpot(self, ud, p, true, "geo", self.unitDef, self.unitId)
						end
						
						if p ~= nil then
							if ud.needGeo then
								spGiveOrderToUnit(self.unitId,-ud.id,{p.x,p.y,p.z},{})
							else
								if (advMetal) then
									spGiveOrderToUnit(self.unitId,setContains(unitTypeSets[TYPE_HAZMOHO],value) and CMD_UPGRADEMEX2 or CMD_UPGRADEMEX,{p.x,p.y,p.z,150},{})
								else
									spGiveOrderToUnit(self.unitId,CMD_AREAMEX,{p.x,p.y,p.z,150},{})
									
								end
							end
							
							-- assign high priority to AI normal priority builders building metal extractors, factories and fusion reactors
							self:setHighPriorityState(1)

							success = true
							self.progress = false
							if ud.needGeo then
								self.couldNotFindGeoSpot = false
							else
								self.couldNotFindMetalSpot = false
							end 
						else
							--log(self.unitName.." at ( "..selfPos.x.." ; "..selfPos.z..") could not find build spot for "..value,self.ai)
							if ud.needGeo then
								self.couldNotFindGeoSpot = true
							else
								self.couldNotFindMetalSpot = true
							end 
							self.progress = true
						end
					elseif self.unitDef.isFactory then
						-- ignore placement for mobile units
						spGiveOrderToUnit(self.unitId,-ud.id,{selfPos.x,selfPos.y,selfPos.z},{})
						success = true
						self.progress = false
					elseif self.isStaticBuilder then
						-- for construction towers building factories or defense
						local spreadDistance = setContains(unitTypeSets[TYPE_L2_PLANT],value) and 0 or (BUILD_SPREAD_DISTANCE*0.7)
						
						p = self.ai.buildSiteHandler:staticClosestBuildSpot(self, ud, spreadDistance)
						if p ~= nil then
							spGiveOrderToUnit(self.unitId,-ud.id,{p.x,p.y,p.z},{})
							
							success = true
						else
							--log(self.unitName.." at ( "..selfPos.x.." ; "..selfPos.z..") could not find build spot for "..value,self.ai)
							-- mark that the attempt failed
							self:markBuildFailure(ud.name)
							success = false
						end
						
						self.progress = not success
					else
						self.couldNotFindGeoSpot = false
						self.couldNotFindMetalSpot = false
							
						-- defense placement
						if #ud.weapons > 0 and ud.isBuilding then
							p = self.ai.buildSiteHandler:closestBuildSpot(self, ud,  BUILD_SPREAD_DISTANCE)
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
								
								p = self.ai.buildSiteHandler:closestBuildSpot(self, ud, spreadDistance)
								if p ~= nil then
									
									
									-- if it's a cheap multi-build structure, queue further orders
									local shift = multiBuildBuildings[ud.name]
									if (shift and shift > 0) then
										--Spring.Echo("MULTIBUILD "..ud.name)
										spGiveOrderToUnit(self.unitId,-ud.id,{p.x-shift,p.y,p.z-shift},{})
										spGiveOrderToUnit(self.unitId,-ud.id,{p.x-shift,p.y,p.z+shift},CMD.OPT_SHIFT)
										spGiveOrderToUnit(self.unitId,-ud.id,{p.x+shift,p.y,p.z-shift},CMD.OPT_SHIFT)
										spGiveOrderToUnit(self.unitId,-ud.id,{p.x+shift,p.y,p.z+shift},CMD.OPT_SHIFT)
									else
										spGiveOrderToUnit(self.unitId,-ud.id,{p.x,p.y,p.z},{})
									end
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
						
						if (success) then
							-- assign high priority to AI normal priority builders building metal extractors, factories and fusion reactors
							if setContains(unitTypeSets[TYPE_ECONOMY],value) or setContains(unitTypeSets[TYPE_PLANT],value) then
								self:setHighPriorityState(1)
							end
						end
						
						self.progress = not success
					end
				else
					self.progress = true
					--log("WARNING: bad task: "..self.unitName.." cannot build "..value, self.ai)
				end
			else
				log("Cannot build:"..value..", couldn't grab the unit type from the engine", self.ai)
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


function TaskQueueBehavior:retreat()
	local tmpFrame = spGetGameFrame()
	
	if (self.lastRetreatOrderFrame or 0) + ORDER_DELAY_FRAMES < tmpFrame then
		local selfPos = self.pos


		if not self.isCommander and ( abs(selfPos.x - self.ai.unitHandler.basePos.x) > RETREAT_RADIUS or abs(selfPos.z - self.ai.unitHandler.basePos.z) > RETREAT_RADIUS  ) then
			local px = self.ai.unitHandler.basePos.x - BIG_RADIUS/2 + random( 1, BIG_RADIUS)
			local pz = self.ai.unitHandler.basePos.z - BIG_RADIUS/2 + random( 1, BIG_RADIUS)
			
			spGiveOrderToUnit(self.unitId,CMD.MOVE,{px,spGetGroundHeight(px,pz),pz},{})
		else
			self:evadeIfNeeded()
		end

		self.lastRetreatOrderFrame = tmpFrame
		self.progress = true
		self.currentProject = "custom"
		self.waitLeft = 200			
	end	
end


function TaskQueueBehavior:activate()
	self.progress = true
	self.active = true
	-- add to unit handler
	self.ai.unitHandler.taskQueues[self.unitId] = self
end

function TaskQueueBehavior:deactivate()
	self.active = false
	-- remove from unit handler
	self.ai.unitHandler.taskQueues[self.unitId] = nil
end

----------------------- engine event handlers


function TaskQueueBehavior:UnitDestroyed(uId)
	if uId == self.unitId then
		self:deactivate()
	end
end

function TaskQueueBehavior:UnitTaken(uId)
	if uId == self.unitId then
		self:deactivate()
	end
end

function TaskQueueBehavior:UnitDamaged(uId)
	if uId == self.unitId then
		local tmpFrame = spGetGameFrame()
		self.underAttackFrame = tmpFrame
	end
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
		if( self.currentProject ~= "waiting" and not setContains(unitTypeSets[TYPE_EXTRACTOR],self.currentProject)) then
			-- if unit was building an expensive base unit, and it is still alive and incomplete, repair it...
			if setContains(unitTypeSets[TYPE_BASE],self.currentProject) then
				local selfPos = self.pos
				
				for _,uId2 in ipairs(Spring.GetUnitsInCylinder(selfPos.x,selfPos.z,400)) do
					local _,_,_,_,progress = spGetUnitHealth(uId2)
					local targetPos = newPosition(spGetUnitPosition(uId2,false,false))
				
					if (progress < 1 and checkWithinDistance(targetPos,selfPos,ASSIST_UNIT_RADIUS)) then
						-- order it to revert to resume previous queue item
						self:retry()
						
						-- assist building		
						-- THIS THROWS AN ERROR : "GiveOrderToUnit() recursion is not permitted"
						-- spGiveOrderToUnit(self.unitId,CMD.REPAIR,{uId2},{})
						-- log(self.unitName.." resuming building "..self.currentProject.." at ("..targetPos.x..";"..targetPos.z..")") --DEBUG
						-- return
					end
				end
			end

			--log("unit "..self.unitName.." is idle.", self.ai) --DEBUG
			self.progress = true
			self.currentProject = nil
			self.waitLeft = 0
			
		end
	end
end


function TaskQueueBehavior:GameFrame(f)
	-- don't do anything until there has been one data collection
	if not self.ai.unitHandler.collectedData then
		return
	end
	
	self.pos = newPosition(spGetUnitPosition(self.unitId,false,false))
	
	--[[
    if (self.isMobileBuilder) then
		local cmds = spGetUnitCommands(self.unitId,3)
		local cmdCount = 0
		if (cmds and (#cmds >= 0)) then
			cmdCount = #cmds
		end
		if (self.isCommander) then
			Spring.MarkerAddPoint(self.pos.x,100,self.pos.z,tostring(tostring(self.isAttackMode).." "..cmdCount.." "..tostring(self.currentProject))) --DEBUG
		else
			Spring.MarkerAddPoint(self.pos.x,100,self.pos.z,tostring(self:builderRoleStr().." "..cmdCount.." "..tostring(self.currentProject))) --DEBUG
		end
	end
	]]--
	
	-- check health and built status	
	local health,maxHealth,_,_,bp = spGetUnitHealth(self.unitId)
	self.isFullyBuilt = (bp >= 1)
	local retreatHealth = self.isCommander and self.ai.commanderRetreatHealth or (self.isAssault and self.ai.assaultRetreatHealth or self.ai.otherRetreatHealth)
	if (health/maxHealth < retreatHealth) then
		self.isSeriouslyDamaged = true
		self.isFullHealth = false
	else
		self.isSeriouslyDamaged = false
		if (health/maxHealth > 0.99) then
			self.isFullHealth = true
		end
	end

	-- not finished yet, wait
	if (not self.isFullyBuilt) then
		return
	end

	-- adjust strategy if started without land connection to enemies
	if (f < 100 and self.ai.useStrategies and (not self.ai.strategyOverride)) then 
		local enemyUnitIds = self.ai.enemyUnitIds
		
		local hasLandConnection = false
		local hasAmphibiousConnection = false
		if enemyUnitIds ~= nil then
			local ePos = nil
			for eId,_ in pairs (enemyUnitIds) do
				ud = UnitDefs[spGetUnitDefID(eId)]
				local eName = ud.name
				if ( setContains(unitTypeSets[TYPE_COMMANDER],eName)) then
					ePos = newPosition(spGetUnitPosition(eId,false,false))

					if self.ai.mapHandler:checkConnection(self.pos, ePos,PF_UNIT_LAND) then			
						hasLandConnection = true
					end
					if not self.ai.mapHandler.waterDoesDamage and self.ai.mapHandler:checkConnection(self.pos, ePos,PF_UNIT_AMPHIBIOUS) then			
						hasAmphibiousConnection = true
					end
				end
			end
			
			if self.ai.autoChangeStrategies and ((not hasLandConnection) and (not hasAmphibiousConnection)) then
				viableStrategyStrList = {"air"}
				strategyStr = viableStrategyStrList[random( 1, #viableStrategyStrList)]
				if self.ai.currentStrategyStr ~= strategyStr and (not tableContains(viableStrategyStrList,self.ai.currentStrategyStr)) then
					self.ai:messageAllies("no land or amphibious connection found to enemy commanders, change strategy to \""..strategyStr.."\"")
					self.ai.strategyOverride = true
					self.ai:setStrategy(self.unitSide,strategyStr,false)
				end
			elseif self.ai.autoChangeStrategies and ((not hasLandConnection) and hasAmphibiousConnection) then
				viableStrategyStrList = {"air","amphibious"}
				strategyStr = viableStrategyStrList[random( 1, #viableStrategyStrList)]
				if self.ai.currentStrategyStr ~= strategyStr and (not tableContains(viableStrategyStrList,self.ai.currentStrategyStr)) then
					self.ai:messageAllies("no land connection found to enemy commanders, change strategy to \""..strategyStr.."\"")
					self.ai.strategyOverride = true
					self.ai:setStrategy(self.unitSide,strategyStr,false)
				end
			end
		end
	end

	-- check water mode
	if spGetGroundHeight(self.pos.x,self.pos.z) < -5 and not self.ai.mapHandler.waterDoesDamage then
		self.isWaterMode = true
	else
		self.isWaterMode = false
	end

	if (self.waitLeft > 0 ) then
		self.waitLeft = math.max(self.waitLeft - 1,0)
		if (self.waitLeft == 0) then
			self.progress = true
		end
		--if self.isCommander and self.waitLeft == 0 then
		--	log("wait is over, progress="..tostring(self.progress),self.ai) --DEBUG
		--end
	end
	
	if(not self.unitDef.isBuilding) then
		-- retreat if necessary
		if (self.isSeriouslyDamaged or self.isCommander ) and f - self.underAttackFrame < UNDER_ATTACK_FRAMES  then
			
			-- retry current project when safe
			if(self.currentProject ~= nil and self.currentProject ~= "waiting" and self.currentProject ~= "custom") then
				self:retry()
			end

			-- check if you can engage
			if (not self.isSeriouslyDamaged) and self.isArmed and self:engageIfNeeded() then
				self.lastRetreatOrderFrame = f
				self.progress = true
				self.currentProject = "custom"
				self.waitLeft = 200
				return
			end
			-- evade or retreat
			self:avoidEnemyAndRetreat()
			return
		end
		
		-- if is commander and base is under attack, go help!
		if (self.isCommander and self.ai.unitHandler.baseUnderAttack) then
			if countOwnUnits(self,nil,1,TYPE_PLANT) > 0  then
				--spGiveOrderToUnit(self.unitId,CMD.STOP,{},{})
				self:retreat()
			end
			--[[
			if self.isAttackMode == false and (countOwnUnits(self,nil,1,TYPE_PLANT) > 0 ) then
				spGiveOrderToUnit(self.unitId,CMD.STOP,{},{})
				self:changeQueue(commanderAtkQueueByFaction[self.unitSide])
				self.isAttackMode = true
				--log("changed to attack commander!",self.ai)
			end
			]]--
		end
	end
	
	if self.isCommander or (fmod(f,10) == 9) then
		if (self.waitLeft == 0) then
			-- progress queue if unit is supposed to be doing something but is actually idle
			if not self.progress and self.isBuilder then
				local cmds = spGetUnitCommands(self.unitId,3)
				if (not cmds or #cmds <= 0) then
					self.idleFrames = self.idleFrames + (self.isCommander and 1 or 10) 
				
					if (self.idleFrames > IDLE_FRAMES_PROGRESS_LIMIT) then
						--log(self.unitName.." was weirdly idle for "..self.idleFrames.." , progressing queue",self.ai) --DEBUG
						self.progress = true
					end
				else
					if (f - self.lastProgressFrame > 1000 and self.isBuilder and (self.currentProject == nil or self.currentProject == "custom" or self.currentProject == "waiting")) then
						--log(self.unitName.." stuck on patrol? frames="..(f - self.lastProgressFrame).." wait="..self.waitLeft.." progress="..tostring(self.progress).." currentProj="..tostring(self.currentProject),self.ai) --DEBUG		
						self.progress = true
					end
					self.idleFrames = 0
				end
			end
		 	
			if self.progress == true then
				self.currentProject = nil
				self.idleFrames = 0
				self:progressQueue()
				return
			end
		end		
	end
end
