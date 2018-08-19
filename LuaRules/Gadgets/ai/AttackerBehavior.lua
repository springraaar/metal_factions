include("LuaRules/Gadgets/ai/Common.lua")
include("LuaRules/Gadgets/ai/CommonUnitBehavior.lua")
 
AttackerBehavior = {}
AttackerBehavior.__index = AttackerBehavior

function AttackerBehavior.create()
   local obj = {}             -- our new object
   setmetatable(obj,AttackerBehavior)  -- make AttackerBehavior handle lookup
   return obj
end

-- set up inheritance
setmetatable(AttackerBehavior,{__index = CommonUnitBehavior})

function AttackerBehavior:Name()
	return "AttackerBehavior"
end

function AttackerBehavior:internalName()
	return "attackerbehavior"
end


function AttackerBehavior:Init(ai, uId)
	self:CommonInit(ai, uId)

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
		self.ai.unitHandler:RemoveRecruit(self,UNIT_GROUP_RAIDERS)
	end
end

function AttackerBehavior:UnitTaken(uId)
	if uId == self.unitId then
		self.ai.unitHandler:RemoveRecruit(self,UNIT_GROUP_ATTACKERS)
		self.ai.unitHandler:RemoveRecruit(self,UNIT_GROUP_AIR_ATTACKERS)
		self.ai.unitHandler:RemoveRecruit(self,UNIT_GROUP_SEA_ATTACKERS)
		self.ai.unitHandler:RemoveRecruit(self,UNIT_GROUP_RAIDERS)
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

function AttackerBehavior:Retreat()
	local tmpFrame = spGetGameFrame()
	
	if (self.lastRetreatOrderFrame or 0) + ORDER_DELAY_FRAMES < tmpFrame then
		local selfPos = self.pos
	
		if ( abs(selfPos.x - self.ai.unitHandler.basePos.x) > RETREAT_RADIUS or abs(selfPos.z - self.ai.unitHandler.basePos.z) > RETREAT_RADIUS  ) then
			spGiveOrderToUnit(self.unitId,CMD.MOVE,{self.ai.unitHandler.basePos.x - BIG_RADIUS/2 + random( 1, BIG_RADIUS),0,self.ai.unitHandler.basePos.z - BIG_RADIUS/2 + random( 1, BIG_RADIUS)},{})
		else
			self:EvadeIfNeeded()
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


-- to prevent artillery from chasing into enemy fire
-- this will issue Hold Pos order to units that need it
function AttackerBehavior:SetMoveState()
	if (self.unitDef.maxWeaponRange and tonumber(self.unitDef.maxWeaponRange) > 850 ) then
		spGiveOrderToUnit(self.unitId,CMD.MOVE_STATE,{0}, {})
	end
end

