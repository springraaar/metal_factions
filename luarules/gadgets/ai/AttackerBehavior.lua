include("luarules/gadgets/ai/common.lua")
include("luarules/gadgets/ai/CommonUnitBehavior.lua")
 
AttackerBehavior = {}
AttackerBehavior.__index = AttackerBehavior

function AttackerBehavior.create()
   local obj = {}             -- our new object
   setmetatable(obj,AttackerBehavior)  -- make AttackerBehavior handle lookup
   return obj
end

-- set up inheritance
setmetatable(AttackerBehavior,{__index = CommonUnitBehavior})

function AttackerBehavior:name()
	return "AttackerBehavior"
end

function AttackerBehavior:internalName()
	return "attackerbehavior"
end


function AttackerBehavior:Init(ai, uId)
	self:commonInit(ai, uId)

	self:activate()
end

function AttackerBehavior:attackCell(centerPos, cell)
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
		p.y = spGetGroundHeight(p.x,p.z)
		self.target = p
		
		self.lastOrderFrame = tmpFrame
		if self.active then
			spGiveOrderToUnit(self.unitId,CMD.FIGHT,{self.target.x,self.target.y,self.target.z},EMPTY_TABLE)
			-- log(self.unitName.." ("..selfPos.x..";"..selfPos.z..") attacking position ("..p.x..";"..p.z..") ") --DEBUG
		end
	end
end

function AttackerBehavior:attackRegroupCenterIfNeeded(centerPos, radius)
	local tmpFrame = spGetGameFrame()

	local selfPos = newPosition(spGetUnitPosition(self.unitId,false,false))
	if ( abs(selfPos.x - centerPos.x) > radius or abs(selfPos.z - centerPos.z) > radius  ) then
		local spread = radius/2
		p = newPosition()
		p.x = centerPos.x-spread/2+random(1,spread)
		p.z = centerPos.z-spread/2+random(1,spread)
		p.y = spGetGroundHeight(p.x,p.z)
		if (self.lastOrderFrame or 0) + ORDER_DELAY_FRAMES < tmpFrame then
			self.lastOrderFrame = tmpFrame - ORDER_DELAY_FRAMES/2
			spGiveOrderToUnit(self.unitId,CMD.MOVE,{p.x,p.y,p.z},EMPTY_TABLE)
			self.isBasePatrolling = false
		end
		-- log(self.unitName.." ("..selfPos.x..";"..selfPos.z..") moving to center of force at ("..p.x..";"..p.z..")") --DEBUG
		return true
	end
	return false
end

function AttackerBehavior:retreat()
	local tmpFrame = spGetGameFrame()
	
	if (self.lastRetreatOrderFrame or 0) + ORDER_DELAY_FRAMES < tmpFrame then
		local selfPos = self.pos
		local basePos = self.ai.unitHandler.basePos
	
		if ( abs(selfPos.x - basePos.x) > RETREAT_RADIUS or abs(selfPos.z - basePos.z) > RETREAT_RADIUS  ) then
			local px = basePos.x - BIG_RADIUS/2 + random( 1, BIG_RADIUS)
			local pz = basePos.z - BIG_RADIUS/2 + random( 1, BIG_RADIUS)
			local h = spGetGroundHeight(px,pz)
			spGiveOrderToUnit(self.unitId,CMD.MOVE,{px,h,pz},EMPTY_TABLE)
		else
			self:evadeIfNeeded()
		end

		self.lastRetreatOrderFrame = tmpFrame
		self.isBasePatrolling = false
	end	
end

function AttackerBehavior:basePatrol()
	local tmpFrame = spGetGameFrame()
	
	if (self.lastOrderFrame or 0) + ORDER_DELAY_FRAMES < tmpFrame then
		local selfPos = self.pos
		local basePos = self.ai.unitHandler.basePos

		local baseX = basePos.x
		local baseZ = basePos.z
		local h = spGetGroundHeight(selfPos.x,selfPos.z)
		if not self.isBasePatrolling or not checkWithinDistance(selfPos,basePos,2*HUGE_RADIUS)  then
			spGiveOrderToUnit(self.unitId,CMD.MOVE,{baseX - (BIG_RADIUS + random( 1, BIG_RADIUS)),h,baseZ},EMPTY_TABLE)
			spGiveOrderToUnit(self.unitId,CMD.PATROL,{baseX + (BIG_RADIUS + random( 1, BIG_RADIUS)),h,baseZ},CMD.OPT_SHIFT)
			spGiveOrderToUnit(self.unitId,CMD.PATROL,{baseX,h,baseZ + (BIG_RADIUS + random( 1, BIG_RADIUS))},CMD.OPT_SHIFT)	
			spGiveOrderToUnit(self.unitId,CMD.PATROL,{baseX,h,baseZ - (BIG_RADIUS + random( 1, BIG_RADIUS))},CMD.OPT_SHIFT)		
			
			self.isBasePatrolling = true
			--self.lastOrderFrame = tmpFrame
		end
	end	
end


function AttackerBehavior:activate()
	self.active = true
	-- add to unit handler
	if setContains(unitTypeSets[TYPE_AIR_ATTACKER],self.unitName) then
		self.ai.unitHandler:addRecruit(self,UNIT_GROUP_AIR_ATTACKERS)
	elseif setContains(unitTypeSets[TYPE_SEA_ATTACKER],self.unitName) then
		self.ai.unitHandler:addRecruit(self,UNIT_GROUP_SEA_ATTACKERS)
	else
		self.ai.unitHandler:addRecruit(self,UNIT_GROUP_ATTACKERS)
	end	
end


function AttackerBehavior:deactivate()
	self.active = false
	-- remove from unit handler
	self.ai.unitHandler:removeRecruit(self,UNIT_GROUP_ATTACKERS)
	self.ai.unitHandler:removeRecruit(self,UNIT_GROUP_AIR_ATTACKERS)
	self.ai.unitHandler:removeRecruit(self,UNIT_GROUP_SEA_ATTACKERS)
	self.ai.unitHandler:removeRecruit(self,UNIT_GROUP_RAIDERS)	
end



-- to prevent artillery from chasing into enemy fire
-- this will issue Hold Pos order to units that need it
function AttackerBehavior:setMoveState()
	if (self.unitDef.maxWeaponRange and tonumber(self.unitDef.maxWeaponRange) > 850 ) then
		spGiveOrderToUnit(self.unitId,CMD.MOVE_STATE,TABLE_WITH_ZERO, EMPTY_TABLE)
	end
end

----------------------- engine event handlers

function AttackerBehavior:UnitDestroyed(uId)
	if uId == self.unitId then
		self:deactivate()
	end
end

function AttackerBehavior:UnitTaken(uId)
	if uId == self.unitId then
		self:deactivate()	
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


function AttackerBehavior:GameFrame(f)
	
	self.pos = newPosition(spGetUnitPosition(self.unitId,false,false))

	local health,maxHealth,_,_,_ = spGetUnitHealth(self.unitId)
	if health then
		local retreatHealth = self.isAssault and self.ai.assaultRetreatHealth or self.ai.otherRetreatHealth
		if (health/maxHealth < retreatHealth) then
			self.isSeriouslyDamaged = true
			self.isFullHealth = false
		else
			self.isSeriouslyDamaged = false
			if (health/maxHealth > 0.85) then
				self.isFullHealth = true
			end
		end
	
		if (self.lastRetreatOrderFrame or 0) + ORDER_DELAY_FRAMES < f then
			if self.isSeriouslyDamaged then
				self:retreat()
			end
		end	
	end
end
