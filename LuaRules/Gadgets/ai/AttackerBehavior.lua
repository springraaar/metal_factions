include("LuaRules/Gadgets/ai/Common.lua")
 
AttackerBehavior = {}
AttackerBehavior.__index = AttackerBehavior

function AttackerBehavior.create()
   local obj = {}             -- our new object
   setmetatable(obj,AttackerBehavior)  -- make AttackerBehavior handle lookup
   return obj
end

function AttackerBehavior:Name()
	return "AttackerBehavior"
end

function AttackerBehavior:internalName()
	return "attackerbehavior"
end


function AttackerBehavior:Init(ai, uId)
	self.ai = ai
	
	-- unit properties
	self.unitId = uId
	self.unitDef = UnitDefs[spGetUnitDefID(uId)]
	self.unitName = self.unitDef.name
	self.unitCost = getWeightedCostByName(self.unitName)
	self.lastOrderFrame = 0
	self.lastRetreatOrderFrame = 0
	self.underAttackFrame = 0
	self.isSeriouslyDamaged = false
	self.isFullHealth = true
	self.isBasePatrolling = false
	self.pFType = getUnitPFType(self.unitDef)
	self.pos = newPosition(spGetUnitPosition(uId,false,false))
	
	self:Activate()
end

function AttackerBehavior:UnitFinished(uId)
	if uId == self.unitId then
		if setContains(unitTypeSets[TYPE_AIR_ATTACKER],self.unitName) then
			self.ai.unitHandler:AddRecruit(self,UNIT_GROUP_AIR_ATTACKERS)
		elseif setContains(unitTypeSets[TYPE_SEA_ATTACKER],self.unitName) then
			self.ai.unitHandler:AddRecruit(self,UNIT_GROUP_SEA_ATTACKERS)
		else
			self.ai.unitHandler:AddRecruit(self,UNIT_GROUP_ATTACKERS)
		end
	end
end


function AttackerBehavior:UnitDestroyed(uId)
	if uId == self.unitId then
		self.ai.unitHandler:RemoveRecruit(self,UNIT_GROUP_ATTACKERS)
		self.ai.unitHandler:RemoveRecruit(self,UNIT_GROUP_AIR_ATTACKERS)
		self.ai.unitHandler:RemoveRecruit(self,UNIT_GROUP_SEA_ATTACKERS)
	end
end

function AttackerBehavior:UnitTaken(uId)
	if uId == self.unitId then
		self.ai.unitHandler:RemoveRecruit(self,UNIT_GROUP_ATTACKERS)
		self.ai.unitHandler:RemoveRecruit(self,UNIT_GROUP_AIR_ATTACKERS)
		self.ai.unitHandler:RemoveRecruit(self,UNIT_GROUP_SEA_ATTACKERS)
	end
end

function AttackerBehavior:UnitDamaged(uId)
	if uId == self.unitId then
		local tmpFrame = spGetGameFrame()
		self.underAttackFrame = tmpFrame
	end
end


function AttackerBehavior:UnitIdle(uId)
	if uId == self.unitId then
		-- do something here?
	end
end

function AttackerBehavior:AttackCell(centerPos, cell)
	local tmpFrame = spGetGameFrame()

	if (self.lastOrderFrame or 0) + ORDER_DELAY_FRAMES < tmpFrame then
		local selfPos = newPosition(spGetUnitPosition(self.unitId,false,false))
		self.isBasePatrolling = false

		local targetRadius = FORCE_TARGET_RADIUS
		targetRadius = targetRadius * (1 + 0.02 * self.ai.unitHandler.attackerCount)
				
		-- check current target
		local cmdTable = spGetCommandQueue(self.unitId,1)
		if ( cmdTable and table.getn(cmdTable) > 0 and (cmdTable[1]["id"] == CMD.ATTACK or cmdTable[1]["id"] == CMD.FIGHT) and cmdTable[1]["params"] ) then
			local currentTargetPos = newPosition(cmdTable[1]["params"][1],cmdTable[1]["params"][2],cmdTable[1]["params"][3])
			-- log("current attack pos = ("..currentTargetPos.x..","..currentTargetPos.z..")")
			
			-- skip order if already targeting the same cell
			if (checkWithinDistance(currentTargetPos, cell.p, targetRadius)) then
				-- log("skip order : unit already targetting that cell at ("..currentTargetPos.x..";"..currentTargetPos.z..")")
				return
			end
		end
		
		local p = newPosition()
		p.x = cell.p.x -targetRadius/2 + random(1,targetRadius)
		p.z = cell.p.z -targetRadius/2 + random(1,targetRadius)
		p.y = 0
		self.target = p
		
		self.lastOrderFrame = tmpFrame
		if self.active then
			spGiveOrderToUnit(self.unitId,CMD.FIGHT,{self.target.x,self.target.y,self.target.z},{})
			-- log(self.unitName.." ("..selfPos.x..";"..selfPos.z..") attacking position ("..p.x..";"..p.z..") ") --DEBUG
		end
	end
end

function AttackerBehavior:AttackRegroupCenterIfNeeded(centerPos, radius)
	local tmpFrame = spGetGameFrame()

	local selfPos = newPosition(spGetUnitPosition(self.unitId,false,false))
	if ( abs(selfPos.x - centerPos.x) > radius or abs(selfPos.z - centerPos.z) > radius  ) then
		p = newPosition()
		p.x = centerPos.x-radius/2+random(1,radius)
		p.z = centerPos.z-radius/2+random(1,radius)
		p.y = 0
		if (self.lastOrderFrame or 0) + ORDER_DELAY_FRAMES < tmpFrame then
			self.lastOrderFrame = tmpFrame - ORDER_DELAY_FRAMES/2
			spGiveOrderToUnit(self.unitId,CMD.MOVE,{p.x,p.y,p.z},{})
			self.isBasePatrolling = false
		end
		-- log(self.unitName.." ("..selfPos.x..";"..selfPos.z..") moving to center of force at ("..p.x..";"..p.z..")") --DEBUG
		return true
	end
	return false
end


function AttackerBehavior:SupportGroundAttackers(radius)
	local tmpFrame = spGetGameFrame()
	
	if (self.lastOrderFrame or 0) + ORDER_DELAY_FRAMES < tmpFrame then
		local selfPos = newPosition(spGetUnitPosition(self.unitId,false,false))
		local x = self.ai.unitHandler.recruitsCenterPos.x
		local z = self.ai.unitHandler.recruitsCenterPos.z
		
		spGiveOrderToUnit(self.unitId,CMD.MOVE,{x - (radius + random( 1, radius)),0,z},{})
	
		spGiveOrderToUnit(self.unitId,CMD_PATROL,{x + (radius + random( 1, radius)),0,z},CMD.OPT_SHIFT)
		
		spGiveOrderToUnit(self.unitId,CMD_PATROL,{x,0,z + (radius + random( 1, radius))},CMD.OPT_SHIFT)
		
		spGiveOrderToUnit(self.unitId,CMD_PATROL,{x,0,z - (radius + random( 1, radius))},CMD.OPT_SHIFT)

		-- log(self.unitName.." ("..selfPos.x..";"..selfPos.z..") supporting ground force at ("..x..";"..z..")") --DEBUG		
		self.lastOrderFrame = tmpFrame
		self.isBasePatrolling = false
	end	
end


function AttackerBehavior:Retreat()
	local tmpFrame = spGetGameFrame()
	
	if (self.lastRetreatOrderFrame or 0) + ORDER_DELAY_FRAMES < tmpFrame then
		local selfPos = newPosition(spGetUnitPosition(self.unitId,false,false))
	
		if ( abs(selfPos.x - self.ai.unitHandler.basePos.x) > RETREAT_RADIUS or abs(selfPos.z - self.ai.unitHandler.basePos.z) > RETREAT_RADIUS  ) then
			spGiveOrderToUnit(self.unitId,CMD.MOVE,{self.ai.unitHandler.basePos.x - BIG_RADIUS/2 + random( 1, BIG_RADIUS),0,self.ai.unitHandler.basePos.z - BIG_RADIUS/2 + random( 1, BIG_RADIUS)},{})
		else
			self:EvadeIfNeeded(selfPos)
		end

		self.lastRetreatOrderFrame = tmpFrame
		self.isBasePatrolling = false
	end	
end

function AttackerBehavior:BasePatrol()
	local tmpFrame = spGetGameFrame()
	
	if (self.lastOrderFrame or 0) + ORDER_DELAY_FRAMES < tmpFrame then
		local baseX = self.ai.unitHandler.basePos.x
		local baseZ = self.ai.unitHandler.basePos.z
		local selfPos = newPosition(spGetUnitPosition(self.unitId,false,false))
		
		if not self.isBasePatrolling or not checkWithinDistance(selfPos,self.ai.unitHandler.basePos,2*HUGE_RADIUS)  then
			spGiveOrderToUnit(self.unitId,CMD.MOVE,{baseX - (BIG_RADIUS + random( 1, BIG_RADIUS)),0,baseZ},{})
			spGiveOrderToUnit(self.unitId,CMD_PATROL,{baseX + (BIG_RADIUS + random( 1, BIG_RADIUS)),0,baseZ},CMD.OPT_SHIFT)
			spGiveOrderToUnit(self.unitId,CMD_PATROL,{baseX,0,baseZ + (BIG_RADIUS + random( 1, BIG_RADIUS))},CMD.OPT_SHIFT)	
			spGiveOrderToUnit(self.unitId,CMD_PATROL,{baseX,0,baseZ - (BIG_RADIUS + random( 1, BIG_RADIUS))},CMD.OPT_SHIFT)		
			
			self.isBasePatrolling = true
			--self.lastOrderFrame = tmpFrame
		end
	end	
end


function AttackerBehavior:Activate()
	self.active = true
end

function AttackerBehavior:Update()
	local tmpFrame = spGetGameFrame()
	
	self.pos = newPosition(spGetUnitPosition(self.unitId,false,false))

	local health,maxHealth,_,_,_ = spGetUnitHealth(self.unitId)
	if (health/maxHealth < UNIT_RETREAT_HEALTH) then
		self.isSeriouslyDamaged = true
		self.isFullHealth = false
	else
		self.isSeriouslyDamaged = false
		if (health/maxHealth > 0.85) then
			self.isFullHealth = true
		end
	end

	if (self.lastRetreatOrderFrame or 0) + ORDER_DELAY_FRAMES < tmpFrame then
		if self.isSeriouslyDamaged then
			self:Retreat()
		end
	end	
end


-- TODO : old shard cfg code, make this work
-- to prevent artillery from chasing into enemy fire
-- this will issue Hold Pos order to units that need it
function AttackerBehavior:SetMoveState()
	local thisUnit = self.unit
	if thisUnit then
		local unitName = thisUnit:Internal():Name()
		local CMD_MOVE_STATE = 50
		local MOVESTATE_HOLDPOS = 0
		local MOVESTATE_ROAM = 2
		if holdPositionList[unitName] then
			floats = api.vectorFloat()
			floats:push_back(MOVESTATE_HOLDPOS)
			thisUnit:Internal():ExecuteCustomCommand(CMD.MOVE_STATE, floats)
		end
		if roamList[unitName] then
			floats = api.vectorFloat()
			floats:push_back(MOVESTATE_ROAM)
			thisUnit:Internal():ExecuteCustomCommand(CMD.MOVE_STATE, floats)
		end
	end
end


function AttackerBehavior:EvadeIfNeeded()
	local tmpFrame = spGetGameFrame()
	
	-- only evade if under attack
	if( tmpFrame - self.underAttackFrame < UNDER_ATTACK_FRAMES) then
		local selfPos = newPosition(spGetUnitPosition(self.unitId,false,false))
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

function AttackerBehavior:Evade(threatPos, moveDistance)
	local selfPos = newPosition(spGetUnitPosition(self.unitId,false,false))

	local vx = selfPos.x - threatPos.x
	local vz = selfPos.z - threatPos.z
	
	local norm = sqrt(vx*vx + vz*vz)		
	vx = vx / norm  
	vz = vz / norm

	-- change movement vector if near edge of map
	local nearEdge = false
	local aux = pos.x + vx * moveDistance
	if (aux > Game.mapSizeX or aux < 0) then
		nearEdge = true
	end
	aux = pos.z + vz * moveDistance
	if not nearEdge and (aux > Game.mapSizeZ or aux < 0) then
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
		
	vxNormal = vz
	vzNormal = -vx
			
	local pos = newPosition(selfPos.x,0,selfPos.z)
	local increment = moveDistance / UNIT_EVADE_WAYPOINTS
	local strafeSign = 1 
	local strafeDistance = 0
	
	for i=1,UNIT_EVADE_WAYPOINTS do
		strafeSign = random(1,10) > 5 and 1 or -1
		strafeDistance = strafeSign * random(1,UNIT_EVADE_STRAFE_DISTANCE)
		
		pos.x = pos.x + vx * increment + vxNormal * strafeDistance
		pos.z = pos.z + vz * increment + vzNormal * strafeDistance
		-- log(pos.x.." ; "..pos.z)
		if  spTestMoveOrder(self.unitDef.id,pos.x,0,pos.z,0,0,0,true,true) then
			spGiveOrderToUnit(self.unitId,CMD.MOVE,{pos.x,0,pos.z},i > 1 and CMD.OPT_SHIFT or {})
		end
	end
	
end
