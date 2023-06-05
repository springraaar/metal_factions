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
local ENERGY_BOOSTED_MOVEMENT_SLOW_MOD = 0.25
local FLYING_PLANE_SLOW_MOD = 0.45
local ZEPHYR_RADIUS = 600
local ZEPHYR_MASS_COST_FACTOR = 1/100 -- applied twice per second
local WATER_HEIGHT_THRESHOLD = -5
local UNDERWATER_SLOW_SPEED_THRESHOLD = 0.9*30
local UNDERWATER_EXTRA_SPEED_MOD = 0.45


local spAddUnitDamage = Spring.AddUnitDamage
local spGetUnitExperience = Spring.GetUnitExperience
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitRadius = Spring.GetUnitRadius
local spGetUnitStates = Spring.GetUnitStates
local spSetAirMoveTypeData = Spring.MoveCtrl.SetAirMoveTypeData
local spSetGroundMoveTypeData = Spring.MoveCtrl.SetGroundMoveTypeData
local spSetGunshipMoveTypeData = Spring.MoveCtrl.SetGunshipMoveTypeData
local spGetUnitMoveTypeData = Spring.GetUnitMoveTypeData
local spGetUnitAllyTeam = Spring.GetUnitAllyTeam
local spGetUnitTeam = Spring.GetUnitTeam
local spGetUnitsInCylinder = Spring.GetUnitsInCylinder
local spGetUnitDefID = Spring.GetUnitDefID
local spGetAllUnits = Spring.GetAllUnits
local spGetGroundHeight = Spring.GetGroundHeight
local spGetGroundNormal = Spring.GetGroundNormal
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
local spGetTeamResources = Spring.GetTeamResources
local spSpawnCEG = Spring.SpawnCEG
local spGetUnitIsDead = Spring.GetUnitIsDead
local spSpawnProjectile = Spring.SpawnProjectile
local spAddUnitResource = Spring.AddUnitResource
local spDestroyUnit = Spring.DestroyUnit
local spPlaySoundFile = Spring.PlaySoundFile
local spGetUnitIsCloaked = Spring.GetUnitIsCloaked
local spSetUnitStealth = Spring.SetUnitStealth

local max = math.max
local min = math.min
local floor = math.floor
local abs = math.abs

local landSlowerDefIds = {
	[UnitDefNames["aven_catfish"].id] = true,
	[UnitDefNames["gear_proteus"].id] = true,
	[UnitDefNames["sphere_helix"].id] = true,
	[UnitDefNames["sphere_screener"].id] = true,
	[UnitDefNames["claw_bullfrog"].id] = true
}

local waterSlowerDefIds = {
	[UnitDefNames["aven_adv_construction_vehicle"].id] = true,
	[UnitDefNames["aven_kodiak"].id] = true,
	[UnitDefNames["aven_wheeler"].id] = true
}

local underwaterSlowerDefIds = {}
local allTerrainDefIds = {}

local flyingSphereDefIds = {
	[UnitDefNames["sphere_construction_sphere"].id] = true,
	[UnitDefNames["sphere_nimbus"].id] = true,
	[UnitDefNames["sphere_aster"].id] = true,
	[UnitDefNames["sphere_gazer"].id] = true,
	[UnitDefNames["sphere_magnetar"].id] = true,
	[UnitDefNames["sphere_chroma"].id] = true,
	[UnitDefNames["sphere_orb"].id] = true,
	[UnitDefNames["sphere_comet"].id] = true,
	[UnitDefNames["sphere_atom"].id] = true
}

-- units that have energy boosted movement, values are min speeds at which drain is applied
local energyBoostedMovementDefIds = {
	[UnitDefNames["sphere_construction_sphere"].id] = 0.5,
	[UnitDefNames["sphere_nimbus"].id] = 0.5,
	[UnitDefNames["sphere_aster"].id] = 0.5,
	[UnitDefNames["sphere_gazer"].id] = 0.5,
	[UnitDefNames["sphere_magnetar"].id] = 0.5,
	[UnitDefNames["sphere_chroma"].id] = 0.5,
	[UnitDefNames["sphere_orb"].id] = 0.5,
	[UnitDefNames["sphere_comet"].id] = 1.0,
	[UnitDefNames["sphere_atom"].id] = 1.0,
	[UnitDefNames["sphere_dipole"].id] = 1.0,
	[UnitDefNames["sphere_cluster"].id] = 0.5,
	[UnitDefNames["sphere_cluster_module_laser"].id] = 0.5,
	[UnitDefNames["sphere_cluster_module_bomb"].id] = 0.5,
	[UnitDefNames["aven_ace"].id] = 10.0
}

local cometDefIds = {
	[UnitDefNames["sphere_comet"].id] = true,
	[UnitDefNames["sphere_atom"].id] = true
}


local covertOpsDefIds = {
	[UnitDefNames["aven_covert_ops_center"].id] = true,
	[UnitDefNames["gear_covert_ops_center"].id] = true,
	[UnitDefNames["claw_covert_ops_center"].id] = true
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
local magnetarAuraWeaponId = WeaponDefNames["sphere_magnetar_aura_blast"].id
local magnetarAuraEPerProjectile = 80 

GG.speedModifierUnitIds = {} -- (unitId,modifier)

local landSlowerUnitIds = {}
local waterSlowerUnitIds = {}
local underwaterSlowerUnitIds = {}
local allTerrainUnitIds = {}
local lastDamageFrameUnitIds = {}
local lastFrameDamageAmountByUnitId = {}
local energyBoostedMovementUnitIds = {}
local flyingSphereUnitIds = {}
local covertOpsUnitIds = {}
local allUnitIds = {}
local autoBuildUnitIds = {}
local latestHPByUnitId = {}
local recentHPGainByUnitId = {}
local lastCaptureStateByUnitId = {}

local EMPTY_TABLE = {}
local TABLE_WITH_ALT = {"alt"}
local UNIT_RP_PUBLIC_TBL = {public = true}


function gadget:Initialize()
	for _,ud in pairs(UnitDefs) do
		-- the "minwaterdepth" check is here to exclude ships and subs?
		if (ud.minWaterDepth and ud.minWaterDepth < 0) and (ud.isGroundUnit) and (ud.canMove == true) and (not string.find(tostring(ud.moveDef.name),"hover")) then
			underwaterSlowerDefIds[ud.id] = true
			--Spring.Echo(ud.name.." moves slower underwater floatonwater="..tostring(ud.floatonwater).." floater="..tostring(ud.floater).." waterline="..tostring(ud.waterline).." mindepth="..tostring(ud.minWaterDepth).." mdname="..tostring(ud.moveDef.name))
		end
		
		if (ud.isGroundUnit) and (ud.canMove == true) then
			local mdName = tostring(ud.moveDef.name)
			if mdName == "kbotat" or mdName == "kbotatuw" or mdName == "kbotatuw2" then
				allTerrainDefIds[ud.id] = true
			end
		end
	end
end


-- mark unit as zephyr or unit with terrain speed modifiers
function gadget:UnitCreated(unitId, unitDefId, unitTeam)
	if (zephyrDefIds[unitDefId]) then
		zephyrIds[unitId] = true
	elseif (landSlowerDefIds[unitDefId]) then
		landSlowerUnitIds[unitId] = true
	elseif (waterSlowerDefIds[unitDefId]) then
		waterSlowerUnitIds[unitId] = true
	elseif (underwaterSlowerDefIds[unitDefId]) then
		underwaterSlowerUnitIds[unitId] = UnitDefs[unitDefId]
	end
	if allTerrainDefIds[unitDefId] then
		allTerrainUnitIds[unitId] = UnitDefs[unitDefId]
	end
	if covertOpsDefIds[unitDefId] then
		covertOpsUnitIds[unitId] = true
	end
	if (energyBoostedMovementDefIds[unitDefId]) then
		energyBoostedMovementUnitIds[unitId] = true
		
		if (flyingSphereDefIds[unitDefId]) then
			flyingSphereUnitIds[unitId] = true
		end
		if (magnetarDefIds[unitDefId]) then
			magnetarIds[unitId] = true
		end
	end	
	
	allUnitIds[unitId] = true
end

-- apply speed modifier when the unit finishes construction
-- workaround to make it work with inherited move orders
function gadget:UnitFinished(unitId, unitDefId, unitTeam)
	if GG.speedModifierUnitIds then
		modifier = GG.speedModifierUnitIds[unitId]
		if modifier then
			--Spring.Echo("updated speed : modifier "..tostring(modifier))
			updateUnitSpeedModifier(unitId,modifier)
		end
	end
end

function gadget:GameFrame(n)
	local allUnits = spGetAllUnits()
	local DASH_SPEED_MOD = 0.3
	local DASH_SPEED_MOD_MIN = 0.3
	local DASH_SPEED_MOD_MAX = 0.6
	local DASH_BASE_SPEED_REF = 45

	-- idle here means not taking damage for a while
	local IDLE_REGEN_FRAMES = 30 * 20	-- 20 seconds
	local IDLE_REGEN_FLAT = 2
	local IDLE_REGEN_FRACTION = 0.002
	local AREA_CHECK_DELAY = 6
	local COST_DELAY = 15
	local REGEN_DELAY = 30		-- once per second
	local AUTO_BUILD_STEP_FRAMES = 5		-- 6 times per second
	local REGEN_EFFECT_DELAY = 10		
	
	local ENERGY_BOOSTED_MOVEMENT_CHECK_THRESHOLD = 2000
	
	local ALL_TERRAIN_SLOW_SPEED_THRESHOLD = 0.9*30
	local ALL_TERRAIN_EXTRA_SPEED_MOD = 0.45
	local ALL_TERRAIN_SLOPE_THRESHOLD = 0.3
	
	local autoBuildCEG = "autobuild" 
	local autoReclaimCEG = "autoreclaim"

	for uId,p in pairs(autoBuildUnitIds) do
		spSpawnCEG(p[4] and autoBuildCEG or autoReclaimCEG, p[1],p[2],p[3])
	end

	-- set rules param with experience, for public display
	local xp = 0
	for _,unitId in pairs(allUnits) do
		xp = spGetUnitExperience(unitId)
		if (xp) then
			spSetUnitRulesParam(unitId, "experience",xp,UNIT_RP_PUBLIC_TBL)
		end
	end
	
	if (n%AREA_CHECK_DELAY == 0) then
		-- clear affected unit list
		zephyrAffectedUnitIds = {}
		local newSpeedModifierUnitIds = {}
			
		-- check modifier for units around each zephyr
		local x,y,z,h,m,vx,vz,v,mData,spdMod,ud,maxSpeed = 0
		for unitId,data in pairs(zephyrIds) do
			
			-- if enabled, apply buff to nearby units that don't have it already
			if (spGetUnitStates(unitId).active) then
				local allyId = spGetUnitAllyTeam(unitId)
				x,y,z = spGetUnitPosition(unitId)
				
				-- get all friendly units in cylinder, add buff unless they have it already
				local unitsInRadius = spGetUnitsInCylinder(x,z,ZEPHYR_RADIUS)
				
				for _,uId in pairs(unitsInRadius) do
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
		for _,unitId in pairs(allUnits) do
			spdMod = spGetUnitRulesParam(unitId, "upgrade_speed")
			if spdMod then
				m = newSpeedModifierUnitIds[unitId]
				if (m == nil) then
					m = 1
				end
				newSpeedModifierUnitIds[unitId] = m + spdMod
			end
		end
	
		-- check speed modifiers due to dash
		for _,unitId in pairs(allUnits) do
			local dashFrames = spGetUnitRulesParam(unitId, "dashFrames")
			if dashFrames and dashFrames > 0 then
				local ud = UnitDefs[spGetUnitDefID(unitId)]
				local dashMult = 1.5 + 0.5 * (DASH_BASE_SPEED_REF-ud.speed) / DASH_BASE_SPEED_REF 
				local dashMod = max(DASH_SPEED_MOD_MIN,min(DASH_SPEED_MOD_MAX,DASH_SPEED_MOD*dashMult))
				
				m = newSpeedModifierUnitIds[unitId]
				if (m == nil) then
					m = 1
				end
				newSpeedModifierUnitIds[unitId] = m + dashMod
				--Spring.Echo(ud.name.." speed="..ud.speed.." dashMod="..dashMod)
			end
		end
		
		-- check modifier for units with land and water movement penalties
		for unitId,_ in pairs(landSlowerUnitIds) do
			x,y,z = spGetUnitPosition(unitId)
			if x then
				h = spGetGroundHeight(x,z)
				if ( h > WATER_HEIGHT_THRESHOLD ) then
					m = newSpeedModifierUnitIds[unitId]
					if (m == nil) then
						m = 1
					end
					newSpeedModifierUnitIds[unitId] = m * LAND_WATER_MOD
				end
			end
		end
		for unitId,_ in pairs(waterSlowerUnitIds) do
			x,y,z = spGetUnitPosition(unitId)
			if x then
				h = spGetGroundHeight(x,z)
				if ( h <= WATER_HEIGHT_THRESHOLD ) then
					m = newSpeedModifierUnitIds[unitId]
					if (m == nil) then
						m = 1
					end
					newSpeedModifierUnitIds[unitId] = m * LAND_WATER_MOD
				end
			end
		end
		for unitId,ud in pairs(underwaterSlowerUnitIds) do
			x,y,z = spGetUnitPosition(unitId)
			if x then
				h = spGetGroundHeight(x,z)
				if ( h <= WATER_HEIGHT_THRESHOLD ) then
					m = newSpeedModifierUnitIds[unitId]
					if (m == nil) then
						m = 1
					end

					maxSpeed = ud.speed * m
					if (maxSpeed > UNDERWATER_SLOW_SPEED_THRESHOLD) then
						newSpeedModifierUnitIds[unitId] = m * (UNDERWATER_SLOW_SPEED_THRESHOLD + (maxSpeed-UNDERWATER_SLOW_SPEED_THRESHOLD) * UNDERWATER_EXTRA_SPEED_MOD ) / maxSpeed
					end	
				end
			end
		end
		for unitId,ud in pairs(allTerrainUnitIds) do
			x,y,z = spGetUnitPosition(unitId)
			if x then
				_,_,_,h = spGetGroundNormal(x,z)
				if ( h > ALL_TERRAIN_SLOPE_THRESHOLD ) then
					m = newSpeedModifierUnitIds[unitId]
					if (m == nil) then
						m = 1
					end
					
					maxSpeed = ud.speed * m
					if (maxSpeed > ALL_TERRAIN_SLOW_SPEED_THRESHOLD) then
						newSpeedModifierUnitIds[unitId] = m * (ALL_TERRAIN_SLOW_SPEED_THRESHOLD + (maxSpeed-ALL_TERRAIN_SLOW_SPEED_THRESHOLD) * ALL_TERRAIN_EXTRA_SPEED_MOD ) / maxSpeed
					end	
				end
			end
		end
		
		-- check modifier for flying spheres
		local isActive = false
		local allowEnergyBoostedMovement = false
		local currentLevelE = 0
		local teamId = nil
		for unitId,_ in pairs(energyBoostedMovementUnitIds) do
			teamId = spGetUnitTeam(unitId)
			if teamId ~= nil then
				currentLevelE,_,_,_,_,_,_,_ = spGetTeamResources(teamId,"energy");
	
				allowEnergyBoostedMovement = currentLevelE > ENERGY_BOOSTED_MOVEMENT_CHECK_THRESHOLD
				if ( not allowEnergyBoostedMovement ) then
					m = newSpeedModifierUnitIds[unitId]
					if (m == nil) then
						m = 1
					end
					
					-- if it's the fast attack sphere, apply the debuff twice
					if (cometDefIds[spGetUnitDefID(unitId)]) then
						newSpeedModifierUnitIds[unitId] = m * ENERGY_BOOSTED_MOVEMENT_SLOW_MOD * ENERGY_BOOSTED_MOVEMENT_SLOW_MOD
					else
						newSpeedModifierUnitIds[unitId] = m * ENERGY_BOOSTED_MOVEMENT_SLOW_MOD 
					end
				end
				
				isActive = spGetUnitIsActive(unitId)
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
	
					spSetUnitRulesParam(unitId,"magnetar_power",reloadPercent,UNIT_RP_PUBLIC_TBL)
	
					-- trigger magnetar "aura" when active	
					if (isActive and reloadPercent > 99 and allowEnergyBoostedMovement) then
						_,_,_,x,y,z = spGetUnitPosition(unitId,true)
						local createdId = spSpawnProjectile(magnetarAuraWeaponId,{
							["pos"] = {x,y,z},
							["end"] = {x,y+5,z},
							["speed"] = {100,100,100},
							["owner"] = unitId
						})
						
						spUseUnitResource(unitId, "e", magnetarAuraEPerProjectile)
						if (createdId) then
							Spring.SetProjectileCollision(createdId)
						end
						Spring.PlaySoundFile('Sounds/MAGNETARAURAFIRE.wav', 1, x, y, z)
					end
				end
			end
		end		
		
		-- global modifier
		for unitId,modifier in pairs(GG.mobilityModifier) do
			m = newSpeedModifierUnitIds[unitId]
			if (m == nil) then
				m = 1
			end
			newSpeedModifierUnitIds[unitId] = m * modifier
		end
		
		-- apply speed modifiers
		for unitId,modifier in pairs(newSpeedModifierUnitIds) do
			local oldMod = GG.speedModifierUnitIds[unitId]
			if modifier ~= oldMod and (oldMod == nil or math.abs(modifier - oldMod) > 0.001) then
				--Spring.Echo("ggmod="..tostring(oldMod).." mod="..modifier)
				updateUnitSpeedModifier(unitId,modifier)
			end
		end
		for unitId,_ in pairs(GG.speedModifierUnitIds) do
			if not newSpeedModifierUnitIds[unitId] then
				updateUnitSpeedModifier(unitId,1)
			end
		end	
		
		GG.speedModifierUnitIds = newSpeedModifierUnitIds
	end
	
	
	-- unit hp regeneration
	-- capture rate degeneration
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
		-- and other properties
		local regen = 0
		local health,maxHealth,bp = 0
		for _,unitId in pairs(allUnits) do
			r = spGetUnitRulesParam(unitId, "upgrade_regen")
			if (not r) then
				r = 0
			end
			phpR = spGetUnitRulesParam(unitId, "upgrade_php_regen")
			if (not phpR) then
				phpR = 0
			end
			
			ud = UnitDefs[spGetUnitDefID(unitId)]
			-- hydrobot regen
			if (ud and ud.customParams and ud.customParams.hydrobotregen == "1") then
				-- check if on water
				_,_,_,_,y,_ = spGetUnitPosition(unitId,true)
				
				if (y < -2) then
					r = r + 2
					phpR = phpR + 0.001
				end
			end
				
			if (r > 0 or phpR > 0) then
				health,maxHealth,_,_,bp = spGetUnitHealth(unitId)
				
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
		for _,unitId in pairs(allUnits) do
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
		
		-- capture rate degeneration, if it didn't increase on the last second, the unit is not being captured
		-- start degenerating immediately
		local oldCaptureFraction = 0
		for _,unitId in pairs(allUnits) do
			oldCaptureFraction = lastCaptureStateByUnitId[unitId]
			if not oldCaptureFraction then
				oldCaptureFraction = 0
			end
			
			local health,maxHealth,_,cp,bp = spGetUnitHealth(unitId)
			--Spring.Echo("uId="..unitId.." cp="..tostring(cp).." oldcp="..oldCaptureFraction)
			if (cp and cp > 0 and cp <= oldCaptureFraction) then
				cp = max(cp-0.01,0)
				spSetUnitHealth(unitId, {capture = cp})
			end
			lastCaptureStateByUnitId[unitId] = cp
		end
	end
	

	if (n%AUTO_BUILD_STEP_FRAMES == 0) then
		local health,maxHealth,bp,x,y,z = 0
		local steps = 0

		-- check regeneration due to auto-build status
		for _,unitId in pairs(allUnits) do
			r = spGetUnitRulesParam(unitId, "auto_build_fraction_per_step")
			steps = spGetUnitRulesParam(unitId, "auto_build_steps")
			if (not r) then
				r = 0
				steps = 0
			else
				r = tonumber(r)
				steps = tonumber(steps)
			end
			if (r ~= 0 and steps > 0) then
				health,maxHealth,_,_,bp = spGetUnitHealth(unitId)
				
				if (bp and ((r > 0 and bp < 1 and health > 0) or (r < 0 and bp > 0 and health > 0))) then
					local newBp = bp + r
					local newHp = health + r * maxHealth
					if newBp > 1 then
						newBp = 1
					end
					if newHp > maxHealth then
						newHp = maxHealth
					end

					updateE = spGetUnitRulesParam(unitId, "auto_build_update_energy")
					updateM = spGetUnitRulesParam(unitId, "auto_build_update_metal")
					-- TODO auto-build with resource drain requires conditional metal/energy drain
					-- but isn't used atm
					-- (updating resources currently supported for auto-reclaim only)
					if (r < 0) then
						if bp < r then
							r = -bp
						end
					
						ud = UnitDefs[spGetUnitDefID(unitId)]
						if updateE and updateE > 0 then
							spAddUnitResource(unitId,"e",abs(r*ud.energyCost))												
						end
						if updateM and updateM > 0 then
							spAddUnitResource(unitId,"m",abs(r*ud.metalCost))												
						end
					end
					spSetUnitHealth(unitId, {health = newHp, build = newBp})

					if (newHp <= 0 or newBp <=0) then
						autoBuildUnitIds[unitId] = nil
						x,y,z = spGetUnitPosition(unitId)
						if x then
							local radius = tonumber(spGetUnitRadius(unitId))
							spSpawnCEG("bplasmaballbloom", x, y, z,0,1,0,radius,radius)
							spPlaySoundFile('Sounds/RECLAIM1.wav', 1, x, y, z)
						end
						spDestroyUnit(unitId, false, true)
					elseif steps > 1 or (not autoBuildUnitIds[unitId]) then
						x,y,z = spGetUnitPosition(unitId)
						if x then
							autoBuildUnitIds[unitId] = {x,y,z,r>0}
						end
					else
						autoBuildUnitIds[unitId] = nil
					end
					
					-- decrement available steps
					spSetUnitRulesParam(unitId,"auto_build_steps",(steps-1),UNIT_RP_PUBLIC_TBL)
				else
					autoBuildUnitIds[unitId] = nil
					spSetUnitRulesParam(unitId,"auto_build_steps",0,UNIT_RP_PUBLIC_TBL)
				end
			end
		end
	end
	
	if (n%COST_DELAY == 0) then
		local ud,v,vx,vz,cost = nil
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
		
		-- process E drain associated with movement
		for unitId,_ in pairs(energyBoostedMovementUnitIds) do
			ud = UnitDefs[spGetUnitDefID(unitId)]
			vx,_,vz,v = spGetUnitVelocity(unitId)
			if (vx ~= nil) then
				v = math.sqrt(vx*vx + vz*vz)
			end		
			if (v ~= nil and v > energyBoostedMovementDefIds[ud.id]) then
				cost = ud.customParams.energycostmoving * COST_DELAY / 30
				spUseUnitResource(unitId, "e", cost)
			end
		end		
	end
	
	-- track how many keystone buildings are active per team
	local uId,aId,cloaked
	-- covert ops
	local covertOpsByAllyId = {}
	for uId,_ in pairs(covertOpsUnitIds) do
		aId = spGetUnitAllyTeam(uId)
		_,_,_,_,bp = spGetUnitHealth(uId)
		local unitStates = spGetUnitStates(uId)
		
		if bp == 1 and unitStates.active then
			-- set a team rules param indicating
			if not covertOpsByAllyId[aId] then
				--Spring.Echo("f="..n.." allyId="..aId.." has covert ops enabled!")
				covertOpsByAllyId[aId] = true
			end
		end
	end
	-- update the buff state for units that may use it
	for _,uId in pairs(allUnits) do
		ud = UnitDefs[spGetUnitDefID(uId)]
		if not ud.stealth or ud.stealth == 0 then
			aId = spGetUnitAllyTeam(uId)
			cloaked = spGetUnitIsCloaked(uId) 
			if (covertOpsByAllyId[aId] and cloaked) then
				--Spring.Echo("f="..n.." uId="..uId.." stealth ON")
				spSetUnitStealth(uId,true)
				spSetUnitRulesParam(uId,"stealth",1,UNIT_RP_PUBLIC_TBL)
			else
				--Spring.Echo("f="..n.." uId="..uId.." stealth OFF")
				spSetUnitStealth(uId,false)
				spSetUnitRulesParam(uId,"stealth",0,UNIT_RP_PUBLIC_TBL)
			end
		end
	end
	
	-- update the unit rules param indicating % hp regenerated over the last second or so	
	local percentRegenPerSecond = 0
	for _,unitId in pairs(allUnits) do
		local health,maxHealth,_,_,bp = spGetUnitHealth(unitId)
		if (bp) then
			if not latestHPByUnitId[unitId] then
				latestHPByUnitId[unitId] = health
				recentHPGainByUnitId[unitId] = 0
				lastFrameDamageAmountByUnitId[unitId] = 0
			else
				recentHPGainByUnitId[unitId] = recentHPGainByUnitId[unitId] + lastFrameDamageAmountByUnitId[unitId] + health - latestHPByUnitId[unitId] 
				latestHPByUnitId[unitId] = health
				lastFrameDamageAmountByUnitId[unitId] = 0 -- reset counter
				
				if (n%REGEN_EFFECT_DELAY == 0) then
					percentRegenPerSecond = (recentHPGainByUnitId[unitId]) * (3000/REGEN_EFFECT_DELAY) / maxHealth
					--Spring.Echo("uId="..unitId.." hpGain="..percentRegenPerSecond)
					if (percentRegenPerSecond < 0) then 
						percentRegenPerSecond = 0
					end
					spSetUnitRulesParam(unitId,"recent_regen",percentRegenPerSecond,UNIT_RP_PUBLIC_TBL)
					recentHPGainByUnitId[unitId] = 0
				end
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
	if autoBuildUnitIds[unitId] then
		autoBuildUnitIds[unitId] = nil
	end
	if (landSlowerUnitIds[unitId]) then
		landSlowerUnitIds[unitId] = nil
	elseif (waterSlowerUnitIds[unitId]) then
		waterSlowerUnitIds[unitId] = nil
	elseif (underwaterSlowerUnitIds[unitId]) then
		underwaterSlowerUnitIds[unitId] = nil
	end
	if zephyrAffectedUnitIds[unitId] then
		zephyrAffectedUnitIds[unitId] = nil
	end
	if GG.speedModifierUnitIds[unitId] then
		GG.speedModifierUnitIds[unitId] = nil
	end
	if lastDamageFrameUnitIds[unitId] then
		lastDamageFrameUnitIds[unitId] = nil
	end
	if lastCaptureStateByUnitId[unitId] then
		lastCaptureStateByUnitId[unitId] = nil
	end	
	if (magnetarIds[unitId]) then
		magnetarIds[unitId] = nil
	end
	if allTerrainUnitIds[unitId] then
		allTerrainUnitIds[unitId] = nil
	end
	if covertOpsDefIds[unitDefId] then
		covertOpsUnitIds[unitId] = nil
	end
	if (energyBoostedMovementUnitIds[unitId]) then
		energyBoostedMovementUnitIds[unitId] = nil
		if (flyingSphereUnitIds[unitId]) then
			flyingSphereUnitIds[unitId] = nil
		end
		if (magnetarIds[unitId]) then
			magnetarIds[unitId] = nil
		end
	end	
	if (latestHPByUnitId[unitId]) then
		latestHPByUnitId[unitId] = nil
	end
	if (recentHPGainByUnitId[unitId]) then
		recentHPGainByUnitId[unitId] = nil
	end
	if lastFrameDamageAmountByUnitId[unitId] then
		lastFrameDamageAmountByUnitId[unitId] = nil
	end
	allUnitIds[unitId] = nil
end


-- applies movement speed modifier on unit
function updateUnitSpeedModifier(unitId, modifier)
	local unitDefId = spGetUnitDefID(unitId)
	if (unitDefId ~= nil) then
		local ud = UnitDefs[unitDefId]
		local spd =  ud.speed * modifier
		local turnRate = ud.turnRate
		-- disable turn rate for immobilized units
		if (modifier == 0) then
			turnRate = 0
		end
		--local isJumping = spGetUnitRulesParam(unitId,"is_jumping")
		--isJumping = isJumping and (isJumping == 1)
		 
		-- strafe air
		if (ud.canFly and ud.isStrafingAirUnit and not ud.hoverAttack) then 
			spSetAirMoveTypeData(unitId,{maxSpeed=spd,maxWantedSpeed=spd})
			--spSetAirMoveTypeData(unitId,"useWantedSpeed[0]",false)
			--spSetAirMoveTypeData(unitId,"useWantedSpeed[1]",false)
			--enforceSpeedChange(unitId,spd)
		-- hover air
		elseif (ud.canFly and ud.isHoveringAirUnit) then
			spSetGunshipMoveTypeData(unitId,{maxSpeed=spd,maxWantedSpeed=spd})
			--spSetGunshipMoveTypeData(unitId,"useWantedSpeed[0]",false)
			--spSetGunshipMoveTypeData(unitId,"useWantedSpeed[1]",false)
			--enforceSpeedChange(unitId,spd)
		-- ground
		elseif (ud.canMove and not ud.isBuilding) then	
			--if not isJumping then 
				spSetGroundMoveTypeData(unitId,{maxSpeed=spd,maxWantedSpeed=spd,turnRate=turnRate})
			--end
			--spSetGroundMoveTypeData(unitId,"useWantedSpeed[0]",false)
			--spSetGroundMoveTypeData(unitId,"useWantedSpeed[1]",false)
			--enforceSpeedChange(unitId,spd)
		end
	end
end

-- workaround for units not receiving the speed boost until receiving new orders
function enforceSpeedChange(unitId,speed)
	local cmds = spGetCommandQueue(unitId, 8)
	if #cmds >= 1 then
		for i,cmd in ipairs(cmds) do
			if cmds[i] and cmds[i].id == CMD.SET_WANTED_MAX_SPEED then
				spGiveOrderToUnit(unitId,CMD.REMOVE,{cmds[i].tag},EMPTY_TABLE)
			end
		end
		local params = {-1, CMD.SET_WANTED_MAX_SPEED, 0, speed}
		spGiveOrderToUnit(unitId, CMD.INSERT, params, TABLE_WITH_ALT)
		--Spring.Echo("order given to set speed="..speed.." for unit "..unitId)
	else
		spGiveOrderToUnit(unitId, CMD.STOP, EMPTY_TABLE, EMPTY_TABLE)
	end
end

-- mark when units take damage from enemies
function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
	lastDamageFrameUnitIds[unitID] = spGetGameFrame()
	if not paralyzer then 
		if not lastFrameDamageAmountByUnitId[unitID]  then
			lastFrameDamageAmountByUnitId[unitID] = damage
		else
			lastFrameDamageAmountByUnitId[unitID] = lastFrameDamageAmountByUnitId[unitID] + damage
		end
	end
end