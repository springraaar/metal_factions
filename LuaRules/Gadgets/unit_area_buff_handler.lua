function gadget:GetInfo()
   return {
      name = "Area Buff Handler",
      desc = "Handles unit movement speed modifiers and other area-related buffs",
      author = "raaar",
      date = "December 2015",
      license = "PD",
      layer = 1,
      enabled = true,
   }
end


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
    return
end


local LAND_WATER_MOD = 0.66
local ZEPHYR_REGEN_PER_SECOND = 4
local ZEPHYR_MOD = 1.25
local FLYING_SPHERE_SLOW_MOD = 0.25
local ZEPHYR_RADIUS = 600
local ZEPHYR_MASS_COST_FACTOR = 1/100 -- applied twice per second
local WATER_HEIGHT_THRESHOLD = -5

local spAddUnitDamage = Spring.AddUnitDamage
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitRadius = Spring.GetUnitRadius
local spGetUnitStates = Spring.GetUnitStates
local spSetAirMoveTypeData = Spring.MoveCtrl.SetAirMoveTypeData
local spSetGroundMoveTypeData = Spring.MoveCtrl.SetGroundMoveTypeData
local spSetGunshipMoveTypeData = Spring.MoveCtrl.SetGunshipMoveTypeData
local spGetUnitAllyTeam = Spring.GetUnitAllyTeam
local spGetUnitsInCylinder = Spring.GetUnitsInCylinder
local spGetUnitDefID = Spring.GetUnitDefID
local spGetAllUnits = Spring.GetAllUnits
local spGetGroundHeight = Spring.GetGroundHeight
local spGetUnitHealth = Spring.GetUnitHealth
local spSetUnitHealth = Spring.SetUnitHealth
local spUseUnitResource = Spring.UseUnitResource
local spGetUnitVelocity = Spring.GetUnitVelocity
local spSetRelativeVelocity = Spring.MoveCtrl.SetRelativeVelocity
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGetCommandQueue = Spring.GetCommandQueue
local spGetGameFrame = Spring.GetGameFrame
local spGetUnitIsActive = Spring.GetUnitIsActive
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spSetUnitRulesParam = Spring.SetUnitRulesParam
local spGetUnitWeaponState = Spring.GetUnitWeaponState
local max = math.max
local floor = math.floor

local AREA_CHECK_DELAY = 6
local COST_DELAY = 15
local REGEN_DELAY = 30		-- once per second
-- idle here means not taking damage for a while
local IDLE_REGEN_FRAMES = 30 * 25	-- 25 seconds
local IDLE_REGEN_FLAT = 2
local IDLE_REGEN_FRACTION = 0.003

 

local landSlowerDefIds = {
	[UnitDefNames["aven_catfish"].id] = true,
	[UnitDefNames["gear_proteus"].id] = true,
	[UnitDefNames["sphere_helix"].id] = true,
	[UnitDefNames["sphere_screener"].id] = true
}

local waterSlowerDefIds = {
	[UnitDefNames["aven_adv_construction_vehicle"].id] = true,
	[UnitDefNames["aven_kodiak"].id] = true,
	[UnitDefNames["aven_wheeler"].id] = true,
	[UnitDefNames["claw_predator"].id] = true,
	[UnitDefNames["claw_tempest"].id] = true,
	[UnitDefNames["aven_u5commander"].id] = true,
	[UnitDefNames["gear_barrel"].id] = true
}

local flyingSphereDefIds = {
	[UnitDefNames["sphere_construction_sphere"].id] = true,
	[UnitDefNames["sphere_aster"].id] = true,
	[UnitDefNames["sphere_gazer"].id] = true,
	[UnitDefNames["sphere_magnetar"].id] = true,
	[UnitDefNames["sphere_chroma"].id] = true

}


local zephyrDefIds = {
	[UnitDefNames["aven_zephyr"].id] = true
}
local zephyrIds = {}
local zephyrAffectedUnitIds = {}  -- (unitId,zephyrId)

local magnetarDefIds = {
	[UnitDefNames["sphere_magnetar"].id] = true
}
local magnetarIds = {}

local speedModifierUnitIds = {} -- (unitId,modifier)

local landSlowerUnitIds = {}
local waterSlowerUnitIds = {}
local lastDamageFrameUnitIds = {}
local flyingSphereUnitIds = {}
local allUnitIds = {}

-- mark unit as zephyr or unit with terrain speed modifiers
function gadget:UnitCreated(unitId, unitDefId, unitTeam)
	if (zephyrDefIds[unitDefId]) then
		zephyrIds[unitId] = true
	elseif (landSlowerDefIds[unitDefId]) then
		landSlowerUnitIds[unitId] = true
	elseif (waterSlowerDefIds[unitDefId]) then
		waterSlowerUnitIds[unitId] = true
	elseif (flyingSphereDefIds[unitDefId]) then
		flyingSphereUnitIds[unitId] = true
		
		if (magnetarDefIds[unitDefId]) then
			magnetarIds[unitId] = true
		end
	end	
	
	allUnitIds[unitId] = true
end


function gadget:GameFrame(n)


	if (n%AREA_CHECK_DELAY == 0) then
		-- clear affected unit list
		zephyrAffectedUnitIds = {}
		local newSpeedModifierUnitIds = {}
			
		-- check modifier for units around each zephyr
		local x,y,z,h,m,spdMod = 0
		for unitId,data in pairs(zephyrIds) do
			
			-- if enabled, apply buff to nearby units that don't have it already
			if (spGetUnitStates(unitId).active) then
				local allyId = spGetUnitAllyTeam(unitId)
				x,y,z = spGetUnitPosition(unitId)
				
				-- get all friendly units in cylinder, add buff unless they have it already
				local unitsInRadius = spGetUnitsInCylinder(x,z,ZEPHYR_RADIUS)
				
				for _,uId in ipairs(unitsInRadius) do
					if not zephyrAffectedUnitIds[uId] then
						if (allyId == spGetUnitAllyTeam(uId)) then
	
							-- mark unit as being affected by this zephyr's aura
							zephyrAffectedUnitIds[uId] = unitId
						end
					end
				end
			end
		end
		for uId,zephyrId in pairs (zephyrAffectedUnitIds) do
			newSpeedModifierUnitIds[uId] = ZEPHYR_MOD  
		end
		
		-- check speed modifiers due to upgrades
		for _,unitId in ipairs(spGetAllUnits()) do
			spdMod = spGetUnitRulesParam(unitId, "upgrade_speed")
			if spdMod and spdMod ~= 0 then
				m = newSpeedModifierUnitIds[unitId]
				if (m == nil) then
					m = 1
				end
				newSpeedModifierUnitIds[unitId] = m + spdMod
			end
		end
		
		-- check modifier for units with land and water movement penalties
		for unitId,_ in pairs(landSlowerUnitIds) do
			x,y,z = spGetUnitPosition(unitId)
			h = spGetGroundHeight(x,z)
			if ( h > WATER_HEIGHT_THRESHOLD ) then
				m = newSpeedModifierUnitIds[unitId]
				if (m == nil) then
					m = 1
				end
				newSpeedModifierUnitIds[unitId] = m * LAND_WATER_MOD
			end
		end
		for unitId,_ in pairs(waterSlowerUnitIds) do
			x,y,z = spGetUnitPosition(unitId)
			h = spGetGroundHeight(x,z)
			if ( h <= WATER_HEIGHT_THRESHOLD ) then
				m = newSpeedModifierUnitIds[unitId]
				if (m == nil) then
					m = 1
				end
				newSpeedModifierUnitIds[unitId] = m * LAND_WATER_MOD
			end
		end
		-- check modifier for flying spheres
		local isActive = false
		for unitId,_ in pairs(flyingSphereUnitIds) do
			isActive = spGetUnitIsActive(unitId)
			if ( not isActive ) then
				m = newSpeedModifierUnitIds[unitId]
				if (m == nil) then
					m = 1
				end
				newSpeedModifierUnitIds[unitId] = m * FLYING_SPHERE_SLOW_MOD
			end
			
			-- set magnetar power level according to weapon reload status
			if (magnetarIds[unitId]) then
		        local _,loaded,reloadFrame = spGetUnitWeaponState(unitId,1)
		        local reloadTime = spGetUnitWeaponState(unitId,1,"reloadTime")
		        local reloadPercent = 100
		        local _,_,_,_,bp = spGetUnitHealth(unitId)
		        if bp < 1 then
		        	reloadPercent = 0
		        elseif (loaded==false) then
					reloadPercent = floor((1 - ((reloadFrame-n)/30) / reloadTime)*100);
		        end

				spSetUnitRulesParam(unitId,"magnetar_power",reloadPercent,{public = true})
			end
		end		
		
		-- apply speed modifiers
		for unitId,modifier in pairs(newSpeedModifierUnitIds) do
			if modifier ~= speedModifierUnitIds[unitId] then
				updateUnitSpeedModifier(unitId,modifier)
			end
		end
		for unitId,_ in pairs(speedModifierUnitIds) do
			if not newSpeedModifierUnitIds[unitId] then
				updateUnitSpeedModifier(unitId,1)
			end
		end	
		
		speedModifierUnitIds = newSpeedModifierUnitIds
	end
	
	
	-- unit hp regeneration
	if (n%REGEN_DELAY == 0) then
	
		-- zephyr aura regeneration 
		for unitId,_ in pairs(zephyrAffectedUnitIds) do
			local health,maxHealth,_,_,bp = spGetUnitHealth(unitId)

			if (bp and bp > 0.9) then
				if (health < maxHealth) then
					if maxHealth - health < ZEPHYR_REGEN_PER_SECOND then
						spSetUnitHealth(unitId,maxHealth)
					else
						spSetUnitHealth(unitId,health + ZEPHYR_REGEN_PER_SECOND)
					end
				end
			end
		end
		
		-- check regeneration due to upgrades
		local regen = 0
		for _,unitId in ipairs(spGetAllUnits()) do
			r = spGetUnitRulesParam(unitId, "upgrade_regen")
			if (not r) then
				r = 0
			end
			phpR = spGetUnitRulesParam(unitId, "upgrade_php_regen")
			if (not phpR) then
				phpR = 0
			end
			if (r > 0 or phpR > 0) then
				local health,maxHealth,_,_,bp = spGetUnitHealth(unitId)
				
				if (bp and bp > 0.9) then
					regen = r + phpR * maxHealth
					if (health < maxHealth) then
						if maxHealth - health < regen then
							spSetUnitHealth(unitId,maxHealth)
						else
							spSetUnitHealth(unitId,health + regen)
						end
					end
				end
				--Spring.Echo(unitId.." : upgraded regen : "..regen)
			end
		end
		
		-- idle regeneration
		for _,unitId in ipairs(spGetAllUnits()) do
			if (not lastDamageFrameUnitIds[unitId] or (n - lastDamageFrameUnitIds[unitId] > IDLE_REGEN_FRAMES) ) then
				local health,maxHealth,_,_,bp = spGetUnitHealth(unitId)
				
				if (bp and bp > 0.9) then
					regen = IDLE_REGEN_FLAT + IDLE_REGEN_FRACTION * maxHealth
					if (health < maxHealth) then
						if maxHealth - health < regen then
							spSetUnitHealth(unitId,maxHealth)
						else
							spSetUnitHealth(unitId,health + regen)
						end
					end
				end
			end
		end
	end
	
	if (n%COST_DELAY == 0) then
		local ud,v, cost = nil
		for unitId,zId in pairs(zephyrAffectedUnitIds) do
			ud = UnitDefs[spGetUnitDefID(unitId)]
			_,_,_,v = spGetUnitVelocity(unitId)
		
			if (v ~= nil and v > 0.2) then
				cost = ud.mass * ZEPHYR_MASS_COST_FACTOR
				if (ud.canFly) then
					cost = cost * 0.5
				end
				spUseUnitResource(zId, "e", cost)
			end
		end		
	end
end

-- cleanup when some units are destroyed
function gadget:UnitDestroyed(unitId, unitDefId, unitTeam)
	if (zephyrIds[unitId]) then
		zephyrIds[unitId] = nil
		for uId,zId in pairs(zephyrAffectedUnitIds) do
			if (zId == unitId) then
				zephyrAffectedUnitIds[uId] = nil
			end		
		end
	end
	if (landSlowerUnitIds[unitId]) then
		landSlowerUnitIds[unitId] = nil
	end
	if (waterSlowerUnitIds[unitId]) then
		waterSlowerUnitIds[unitId] = nil
	end
	if zephyrAffectedUnitIds[unitId] then
		zephyrAffectedUnitIds[unitId] = nil
	end
	if speedModifierUnitIds[unitId] then
		speedModifierUnitIds[unitId] = nil
	end
	if lastDamageFrameUnitIds[unitId] then
		lastDamageFrameUnitIds[unitId] = nil
	end	
	if (magnetarIds[unitId]) then
		magnetarIds[unitId] = nil
	end
	
	allUnitIds[unitId] = nil
end


-- applies movement speed modifier on unit
function updateUnitSpeedModifier(unitId, modifier)
	local unitDefId = spGetUnitDefID(unitId)
	if (unitDefId ~= nil) then
		local ud = UnitDefs[unitDefId]
		local spd =  ud.speed * modifier
		
		-- strafe air
		if (ud.canFly and ud.isStrafingAirUnit and not ud.hoverAttack) then 
			spSetAirMoveTypeData(unitId,{maxSpeed=spd})
			enforceSpeedChange(unitId,spd)
		-- hover air
		elseif (ud.canFly and ud.isHoveringAirUnit) then
			spSetGunshipMoveTypeData(unitId,{maxSpeed=spd})
			enforceSpeedChange(unitId,spd)
		-- ground
		elseif (ud.canMove and not ud.isBuilding) then	
			spSetGroundMoveTypeData(unitId,{maxSpeed=spd})
			enforceSpeedChange(unitId,spd)
		end
	end
end

-- workaround for units not receiving the speed boost until receiving new orders
function enforceSpeedChange(unitId,speed)
	local cmds = spGetCommandQueue(unitId, 8)
	if #cmds >= 1 then
		for i,cmd in ipairs(cmds) do
			if cmds[i] and cmds[i].id == CMD.SET_WANTED_MAX_SPEED then
				spGiveOrderToUnit(unitId,CMD.REMOVE,{cmds[i].tag},{})
			end
		end
		local params = {-1, CMD.SET_WANTED_MAX_SPEED, 0, speed}
		spGiveOrderToUnit(unitId, CMD.INSERT, params, {"alt"})
	end
end

-- mark when units take damage from enemies
function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
	lastDamageFrameUnitIds[unitID] = spGetGameFrame()
end