function gadget:GetInfo()
   return {
      name = "Projectile Handler Gadget",
      desc = "Handles events triggered by projectile state changes",
      author = "raaar",
      date = "July 2013",
      license = "PD",
      layer = 0,
      enabled = true,
   }
end

-- oct 2018 : handles destructible rockets
-- jan 2018 : handles comsat projectiles
-- feb 2016 : handles magnetar projectiles
-- sep 2015 : handles area fire effects
-- sep 2015 : torpedos no longer target land targets and fixed explosion when over land or above threshold
-- aug 2015 : reworked code to track only specific projectiles
-- aug 2015 : added support for disruptor wave line area damage

local Echo = Spring.Echo
local floor = math.floor
local ceil = math.ceil
local abs = math.abs
local random = math.random
local spGetGameFrame = Spring.GetGameFrame
local spGetProjectilePosition = Spring.GetProjectilePosition
local spSetProjectileCollision = Spring.SetProjectileCollision
local spGetProjectileVelocity = Spring.GetProjectileVelocity
local spSetProjectileVelocity = Spring.SetProjectileVelocity
local spSetProjectileMoveControl = Spring.SetProjectileMoveControl
local spCreateUnit = Spring.CreateUnit
local spGetUnitTeam = Spring.GetUnitTeam
local spDestroyUnit = Spring.DestroyUnit
local spDeleteProjectile = Spring.DeleteProjectile
local spGetUnitHealth = Spring.GetUnitHealth
local spGetUnitPosition = Spring.GetUnitPosition
local spGetFeaturePosition = Spring.GetFeaturePosition
local spGetFeatureHealth = Spring.GetFeatureHealth
local spGetProjectileDamages = Spring.GetProjectileDamages
local spSetProjectileDamages = Spring.SetProjectileDamages
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spSetUnitRulesParam = Spring.SetUnitRulesParam
local spSetTeamRulesParam = Spring.SetTeamRulesParam
local spGetProjectileTarget = Spring.GetProjectileTarget
local spSetProjectileTarget = Spring.SetProjectileTarget
local spGetProjectileTeamID = Spring.GetProjectileTeamID
local spGetProjectileOwnerID = Spring.GetProjectileOwnerID
local spGetUnitNearestEnemy = Spring.GetUnitNearestEnemy
local spGetUnitIsDead = Spring.GetUnitIsDead
local spSetUnitNeutral = Spring.SetUnitNeutral
local spTestBuildOrder = Spring.TestBuildOrder
local spGetGroundHeight = Spring.GetGroundHeight
local spUnitDetach = Spring.UnitDetach
local spSetUnitShieldState = Spring.SetUnitShieldState
local spSpawnProjectile = Spring.SpawnProjectile
local spSetUnitNoDraw = Spring.SetUnitNoDraw
local spSetUnitNoSelect = Spring.SetUnitNoSelect
local spSetUnitNoMinimap = Spring.SetUnitNoMinimap
local spSetUnitRadiusAndHeight = Spring.SetUnitRadiusAndHeight
local spGetTeamList = Spring.GetTeamList
local spAreTeamsAllied = Spring.AreTeamsAllied
local spSetUnitEngineDrawMask = Spring.SetUnitEngineDrawMask

include("lualibs/util.lua")

-- aim point over target when far from it
local LONG_RANGE_ROCKET_FAR_FROM_TARGET_H = 1000		
local LONG_RANGE_ROCKET_FAR_TARGET_DIST = 900			

local HIGH_ANGLE_DESCENT_FAR_FROM_TARGET_H = 500
local HIGH_ANGLE_DESCENT_FAR_TARGET_DIST = 250

-- terminal phase
local LONG_RANGE_ROCKET_TERMINAL_SQDIST = 800*800
local LONG_RANGE_ROCKET_SUBMUNITION_SQDIST = 600*600

local LONG_RANGE_ROCKET_NON_TERMINAL_LIMIT_SQV = 277
local LONG_RANGE_PREMIUM_ROCKET_NON_TERMINAL_LIMIT_SQV = 2304
local LONG_RANGE_ROCKET_NON_TERMINAL_DECELERATION = 0.95    -- per frame
local LONG_RANGE_ROCKET_TERMINAL_ACCELERATION = 1.05   -- per frame 

local LONG_RANGE_ROCKET_SUB_TYPE_PYROCLASM = WeaponDefNames["gear_pyroclasm_submunition"].id
local LONG_RANGE_ROCKET_SUB_TYPE_IMPALER = WeaponDefNames["claw_impaler_submunition"].id


local submunitionRocketWeaponIds = {
	[WeaponDefNames["gear_pyroclasm_rocket"].id] = WeaponDefNames["gear_pyroclasm_submunition"].id,
	[WeaponDefNames["claw_impaler_rocket"].id] = WeaponDefNames["claw_impaler_submunition"].id
}


-- detonate when very close to target
local LONG_RANGE_ROCKET_DETONATE_SQDIST = 80*80

local DC_ROCKET_DEPLOY_LIMIT_H = 300
local DC_ROCKET_AUTO_BUILD_STEPS = 30
local DC_ROCKET_AUTO_BUILD_FRACTION_PER_STEP = 1/DC_ROCKET_AUTO_BUILD_STEPS
local DC_ROCKET_DEPLOY_DELAY_FRAMES = 30

local MD_WATCH_UPDATE_FRAMES = 30
local MD_WATCH_ALERT_SQDISTANCE = 3500*3500
local UNIT_RP_PUBLIC_TBL = {public = true}

local mapSizeX = Game.mapSizeX
local mapSizeZ = Game.mapSizeZ
local max = math.max
local min = math.min
local STEP_DELAY = 6 		-- process steps every N frames
local FIRE_AOE_STEPS = 100	-- 20 seconds
local FIRE_AOE_STEPS_AIR = 35	-- 7 seconds
local FIRE_AOE_STEPS_AIR_H = 100

local projectileWasUnderwater = {}

local disruptorWeaponId = WeaponDefNames["aven_bass_disruptor"].id
local disruptorWeaponEffectId = WeaponDefNames["aven_bass_disruptor_effect"].id
local fireAOEWeaponEffectId = WeaponDefNames["gear_fire_effect"].id
local fireAOEWeaponEffectId2 = WeaponDefNames["gear_fire_effect2"].id
local magnetarWeaponId = WeaponDefNames["sphere_magnetar_blast"].id
local magnetarWeaponEffectId = WeaponDefNames["sphere_magnetar_blast_effect"].id
local comsatWeaponId = WeaponDefNames["comsat_beacon"].id
local scoperWeaponId = WeaponDefNames["scoper_beacon"].id
local dynamoWeaponId = WeaponDefNames["claw_dynamo_ring"].id
local atomWeaponId = WeaponDefNames["sphere_atom_cannon"].id

local DYNAMO_RING_MAX_DAMAGE = 5000
local DYNAMO_RING_BASE_DAMAGE = 3000
local DYNAMO_RING_GROUND_DAMAGE = 1500
local DYNAMO_RING_GROUND_HP = 800

local DYNAMO_RING_FEATURE_DISCOUNT = 0.25

local fireAOEWeaponIds = {
	-- GEAR
	[WeaponDefNames["gear_canister"].id]=true,
	[WeaponDefNames["gear_eruptor"].id]=true,
	[WeaponDefNames["gear_mass_burner"].id]=true,
	[WeaponDefNames["gear_canister_fireball"].id]=true,
	[WeaponDefNames["gear_eruptor_fireball"].id]=true,
	[WeaponDefNames["gear_firestorm_missile"].id]=true,
	[WeaponDefNames["gear_igniter_missile"].id]=true,
	[WeaponDefNames["gear_incendiary_mine_missile"].id]=true,
	[WeaponDefNames["gear_u1commander_missile"].id]=true,
	[WeaponDefNames["gear_barrel_missile2"].id]=true,
	[WeaponDefNames["gear_pyroclasm_submunition"].id]=true,
	[WeaponDefNames["gear_pyroclasm_rocket_d"].id]=true,
	[WeaponDefNames["gear_u5commander_fireball"].id]=true
}

local torpedoWeaponIds = {}



local smartTrackingWeaponIds = {
	-- AVEN
	[WeaponDefNames["aven_falcon_missile"].id]=true,
	-- GEAR
	[WeaponDefNames["gear_vector_missile"].id]=true,
	[WeaponDefNames["gear_u1commander_missile"].id]=true,
	[WeaponDefNames["gear_firestorm_missile"].id]=true,
	-- CLAW
	[WeaponDefNames["claw_x_aabomb"].id]=true,
	-- SPHERE
	[WeaponDefNames["sphere_blower_aabomb"].id]=true
}

local destructibleWeaponIds = {
	-- AVEN
	[WeaponDefNames["aven_premium_nuclear_rocket"].id]=true,
	[WeaponDefNames["aven_nuclear_rocket"].id]=true,
	[WeaponDefNames["aven_dc_rocket"].id]=true,
	[WeaponDefNames["aven_lightning_rocket"].id]=true,
	-- GEAR
	[WeaponDefNames["gear_premium_nuclear_rocket"].id]=true,
	[WeaponDefNames["gear_nuclear_rocket"].id]=true,
	[WeaponDefNames["gear_dc_rocket"].id]=true,
	[WeaponDefNames["gear_pyroclasm_rocket"].id]=true,
	-- CLAW
	[WeaponDefNames["claw_premium_nuclear_rocket"].id]=true,
	[WeaponDefNames["claw_nuclear_rocket"].id]=true,
	[WeaponDefNames["claw_dc_rocket"].id]=true,
	[WeaponDefNames["claw_impaler_rocket"].id]=true,
	-- SPHERE
	[WeaponDefNames["sphere_premium_nuclear_rocket"].id]=true,
	[WeaponDefNames["sphere_nuclear_rocket"].id]=true,
	[WeaponDefNames["sphere_dc_rocket"].id]=true,
	[WeaponDefNames["sphere_meteorite_rocket"].id]=true
}

local highAngleDescentWeaponIds = {
	-- AVEN
	[WeaponDefNames["aven_merl_rocket"].id]=true,
	[WeaponDefNames["aven_ambassador_rocket"].id]=true,
	[WeaponDefNames["aven_ranger_rocket"].id]=true
}

local premiumRocketWeaponIds = {
	-- AVEN
	[WeaponDefNames["aven_premium_nuclear_rocket"].id]=true,
	-- GEAR
	[WeaponDefNames["gear_premium_nuclear_rocket"].id]=true,
	-- CLAW
	[WeaponDefNames["claw_premium_nuclear_rocket"].id]=true,
	-- SPHERE
	[WeaponDefNames["sphere_premium_nuclear_rocket"].id]=true
}

local dcRocketSpawnWeaponIds = {
	[WeaponDefNames["aven_dc_rocket"].id]=UnitDefNames["aven_nano_tower"].id,
	[WeaponDefNames["gear_dc_rocket"].id]=UnitDefNames["gear_nano_tower"].id,
	[WeaponDefNames["claw_dc_rocket"].id]=UnitDefNames["claw_nano_tower"].id,
	[WeaponDefNames["sphere_dc_rocket"].id]=UnitDefNames["sphere_pole"].id
}


local longRangeRocketOriginalTargetsById = {}
local highAngleDescentProjectiles = {}
local highAngleDescentOriginalTargetsById = {}
local disruptorProjectiles = {}
local disruptorEffectProjectiles = {}
local torpedoProjectiles = {}
local smartTrackingProjectiles = {}
local fireAOEProjectiles = {}
local fireAOEEffectProjectiles = {}
local fireAOEPositions = {}
local magnetarProjectiles = {}
local destructibleProjectiles = {}
local dcRockets = {}
local submunitionRockets = {}
local premiumRockets = {}
local comsatProjectiles = {}
local comsatBeaconDefId = UnitDefNames["cs_beacon"].id
local scoperProjectiles = {}
local scoperBeaconDefId = UnitDefNames["scoper_beacon"].id
local dynamoProjectiles = {}
dcRocketSpawn = {}

-- is close enough on x-z plane to start diving toward target
function isCloseToTarget(px,pz,tx,tz,dist)
	if (abs(px-tx) < dist) and (abs(pz-tz) < dist) then
		return true
	end 
	return false
end

-- is close enough to enter the terminal phase
function isTerminalPhase(px,py,pz,tx,ty,tz)
	if (px-tx)*(px-tx)+(py-ty)*(py-ty)+(pz-tz)*(pz-tz) < LONG_RANGE_ROCKET_TERMINAL_SQDIST then
		return true
	end 
	return false
end


-- is close enough to enter the terminal phase
function isSubmunitionDeploymentPhase(px,py,pz,tx,ty,tz)
	if (px-tx)*(px-tx)+(py-ty)*(py-ty)+(pz-tz)*(pz-tz) < LONG_RANGE_ROCKET_SUBMUNITION_SQDIST then
		return true
	end 
	return false
end

-- is just about to hit the target
function isAboutToCollide(px,py,pz,tx,ty,tz)
	if (px-tx)*(px-tx)+(py-ty)*(py-ty)+(pz-tz)*(pz-tz) < LONG_RANGE_ROCKET_DETONATE_SQDIST then
		return true
	end 
	return false
end

-- make unit invisible and unselectable
--[[
(from engine code)
enum DrawFlags : uint8_t {
	SO_NODRAW_FLAG = 0, // must be 0
	SO_OPAQUE_FLAG = 1,
	SO_ALPHAF_FLAG = 2,
	SO_REFLEC_FLAG = 4,
	SO_REFRAC_FLAG = 8,
	SO_SHOPAQ_FLAG = 16,
	SO_SHTRAN_FLAG = 32,
	SO_DRICON_FLAG = 128,
};

]]--
function applyNonInteractiveProperties(uId)
	--Spring.Echo("applying non-interactive properties to unitId="..uId)
	--spSetUnitEngineDrawMask(uId, 128)
	spSetUnitNoDraw(uId,true)
	spSetUnitNoSelect(uId,true)
	spSetUnitNoMinimap(uId,true)
	spSetUnitRadiusAndHeight(uId,0,0)
end


--- update enemy launch counts
local LATEST_LRR_LAUNCH_STREAK_FRAMES = 25*30
local latestLRRLaunchesByTeamId = {}	-- frame,count 


-------------------------- SYNCED CODE ONLY
if (not gadgetHandler:IsSyncedCode()) then
	return false
end


function gadget:Initialize()
    for _,wd in pairs(WeaponDefs) do  
		if wd and wd.type == "TorpedoLauncher" then
			torpedoWeaponIds[wd.id] = true
		end
	end 

	-- track disruptor wave projectiles
	Script.SetWatchWeapon(disruptorWeaponId,true)
	
	-- track magnetar projectiles
	Script.SetWatchWeapon(magnetarWeaponId,true)
	
	-- track torpedoes fired from submarines
	for id,_ in pairs(torpedoWeaponIds) do
		Script.SetWatchWeapon(id,true)
	end

	-- track fire aoe projectiles
	for id,_ in pairs(fireAOEWeaponIds) do
		Script.SetWatchWeapon(id,true)
	end
	
	-- track comsat and scoper projectiles
	Script.SetWatchWeapon(comsatWeaponId,true)
	Script.SetWatchWeapon(scoperWeaponId,true)
	
	-- track dynamo projectiles
	Script.SetWatchWeapon(dynamoWeaponId,true)

	for id,_ in pairs(smartTrackingWeaponIds) do
		Script.SetWatchWeapon(id,true)
	end

	-- track destructible projectiles
	for id,_ in pairs(destructibleWeaponIds) do
		Script.SetWatchWeapon(id,true)
	end
	
	-- track destructible projectiles
	for id,_ in pairs(highAngleDescentWeaponIds) do
		Script.SetWatchWeapon(id,true)
	end
end


-- execute action every frame for tracked projectiles, as necessary
function gadget:GameFrame(n)
	-- handle team rules for the nuke warning widget
	for _,tId in pairs(spGetTeamList()) do
		local lInfo = latestLRRLaunchesByTeamId[tId] 	
		if (lInfo) then
			-- streak expired, remove
			if (n - lInfo.frame) > LATEST_LRR_LAUNCH_STREAK_FRAMES then
				latestLRRLaunchesByTeamId[tId] = nil
				spSetTeamRulesParam(tId,"latestLRRLaunches",0,{public=true})
			end
		end
	end

	-- explode disruptor wave effect projectiles
	for id,ownerId in pairs(disruptorEffectProjectiles) do
		-- explode projectile
		spSetProjectileCollision(id)
		
		-- remove table entry
		disruptorEffectProjectiles[id] = nil
	end

	-- explode fire aoe effect projectiles
	for id,ownerId in pairs(fireAOEEffectProjectiles) do
		-- explode projectile
		spSetProjectileCollision(id)
		
		-- remove table entry
		fireAOEEffectProjectiles[id] = nil
	end
	
	-- dc rocket construction tower spawn
	for id,info in pairs(dcRocketSpawn) do
		if (info and n > info.frame) then
			local test = false
			local fBlockingId = 0
			
			local canBuild = false
			test,fBlockingId = spTestBuildOrder(info.defId,info.px,info.py,info.pz,0) 
			-- adjust position if stuff is in the way
			if test == 2 and not fBlockingId then
				canBuild = true
			end
			
			local dxi = 0
			local dzi = 0
			local xi = 0
			local zi = 0
			local h = 0
			local searchOrder = {0,-1,1,-2,2,-3,3}
			if (not canBuild) then

				-- check nearby cells
				for dxi in ipairs(searchOrder) do
					if (canBuild) then
						break
					end
					for dzi in ipairs(searchOrder) do
						xi = info.px + dxi * 60
						zi = info.pz + dzi * 60
						if (xi >=0) and (zi >= 0) and not (dxi == 0 and dzi == 0) and (xi < mapSizeX) and (zi < mapSizeZ)  then
							h = spGetGroundHeight(xi,zi)
							test,fBlockingId = spTestBuildOrder(info.defId,xi,h,zi,0) 
							if test == 2 and not fBlockingId then
								canBuild = true
								info.px = xi
								info.py = h
								info.pz = zi
								break
							end
						end
					end
				end
			end
			
			if canBuild then
				local uId = spCreateUnit(info.defId,info.px,info.py,info.pz,0,info.teamId,true,true)
				-- set it to auto-build itself
				if uId then
					spSetUnitRulesParam(uId,"auto_build_fraction_per_step",DC_ROCKET_AUTO_BUILD_FRACTION_PER_STEP,UNIT_RP_PUBLIC_TBL)	
					spSetUnitRulesParam(uId,"auto_build_steps",DC_ROCKET_AUTO_BUILD_STEPS,UNIT_RP_PUBLIC_TBL)
				end
				-- also add a cs beacon temporarily over it to provide los
				uId = spCreateUnit("cs_beacon",info.px,info.py+500,info.pz,0,info.teamId,false)
				if uId then
					spSetUnitNeutral(uId,true)
					applyNonInteractiveProperties(uId)
				end
			end
			
			dcRocketSpawn[id] = nil
		end
	end
	
	-- handle high angle descent projectiles
	local px,py,pz = 0
	local ot = nil
	local tType,st = nil
	for id,ownerId in pairs(highAngleDescentProjectiles) do
		px,py,pz = spGetProjectilePosition(id)
		ot = highAngleDescentOriginalTargetsById[id]
		tType,st = spGetProjectileTarget(id)
		
		if (px and ot) then
			if (tType == string.byte('u') or tType == string.byte('f')) then
				st = ot
			end
			
			if (isCloseToTarget(px,pz,st[1],st[3],HIGH_ANGLE_DESCENT_FAR_TARGET_DIST)) then
				-- if close to original target, go towards it
				spSetProjectileTarget(id,ot[1],ot[2],ot[3])
			end
		end
	
	end
	
	-- handle destructible long range projectiles
	local nearCollision = false
	local MDWatchCheck = n%MD_WATCH_UPDATE_FRAMES == 0
	if MDWatchCheck == true then
		-- clear MD alert status
		for unitId,_ in pairs(GG.enableMDWatchList) do
			spSetUnitRulesParam(unitId,"md_alert",0,UNIT_RP_PUBLIC_TBL)
		end		
	end
	local alreadyAlertedMDUnitIds = {}
	for id,ownerId in pairs(destructibleProjectiles) do
		px,py,pz = spGetProjectilePosition(id)
		ot = longRangeRocketOriginalTargetsById[id]
		nearCollision = false
		tType,st = spGetProjectileTarget(id)
		
		--Spring.Echo("projectile px="..tostring(px).." otx="..tostring(ot[1]))
		if (px and ot) then
			-- mark all enemy units with MD ability within a certain radius as "alerted"
			for unitId,_ in pairs(GG.enableMDWatchList) do
				--Spring.Echo("checking MD watch unit "..unitId)
				if not alreadyAlertedMDUnitIds[unitId] and (not spAreTeamsAllied(spGetUnitTeam(ownerId),spGetUnitTeam(unitId))) then 
					ux,_,uz = spGetUnitPosition(unitId)
					if ux then
						--Spring.Echo("MD watch unit "..unitId.." sqdist="..sqDistance(px,ux,pz,uz))
						if sqDistance(px,ux,pz,uz) < MD_WATCH_ALERT_SQDISTANCE then
							--Spring.Echo("incoming enemy missiles near MD watch unit "..unitId)
							spSetUnitRulesParam(unitId,"md_alert",1,UNIT_RP_PUBLIC_TBL)
							alreadyAlertedMDUnitIds[unitId] = true
						end
					end
				end
			end
		
			if (tType == string.byte('u') or tType == string.byte('f')) then
				st = ot
			end

			-- restrict the speed of long range rockets when they're far from target
			local vx,vy,vz = spGetProjectileVelocity(id)
			if vx then
				local sqV = vx*vx+vy*vy+vz*vz
				if not isTerminalPhase(px,py,pz,ot[1],ot[2],ot[3]) then
					if premiumRockets[id] then
						if (sqV > LONG_RANGE_PREMIUM_ROCKET_NON_TERMINAL_LIMIT_SQV) then 
							--spSetProjectileMoveControl(id,true)
							spSetProjectileVelocity(id,vx*LONG_RANGE_ROCKET_NON_TERMINAL_DECELERATION,vy*LONG_RANGE_ROCKET_NON_TERMINAL_DECELERATION,vz*LONG_RANGE_ROCKET_NON_TERMINAL_DECELERATION)
						end
					else
						if (sqV > LONG_RANGE_ROCKET_NON_TERMINAL_LIMIT_SQV) then 
							--spSetProjectileMoveControl(id,true)
							spSetProjectileVelocity(id,vx*LONG_RANGE_ROCKET_NON_TERMINAL_DECELERATION,vy*LONG_RANGE_ROCKET_NON_TERMINAL_DECELERATION,vz*LONG_RANGE_ROCKET_NON_TERMINAL_DECELERATION)
						end
					end
				else
					-- terminal phase : speed up
					spSetProjectileVelocity(id,vx*LONG_RANGE_ROCKET_TERMINAL_ACCELERATION,vy*LONG_RANGE_ROCKET_TERMINAL_ACCELERATION,vz*LONG_RANGE_ROCKET_TERMINAL_ACCELERATION)
					
					-- if has submunitions, check distance and deploy them
					if submunitionRockets[id] and vy < 0 and isSubmunitionDeploymentPhase(px,py,pz,ot[1],ot[2],ot[3]) then
						local dirx,diry,dirz = 0
						local v = math.sqrt(sqV)
						dirx = vx/v
						diry = vy/v
						dirz = vz/v
					
						if (submunitionRockets[id] == LONG_RANGE_ROCKET_SUB_TYPE_PYROCLASM) then
							--Spring.Echo("target x="..ot[1].." y="..ot[2].." z="..ot[3])
							-- spawn submunitions
							Spring.SetUnitTarget(ownerId,ot[1],ot[2],ot[3],false,false,2)
							Spring.SetUnitTarget(ownerId,ot[1],ot[2],ot[3],false,false,3)
							Spring.SetUnitTarget(ownerId,ot[1],ot[2],ot[3],false,false,4)
							Spring.SetUnitTarget(ownerId,ot[1],ot[2],ot[3],false,false,5)
							Spring.SetUnitTarget(ownerId,ot[1],ot[2],ot[3],false,false,6)
							Spring.SetUnitTarget(ownerId,ot[1],ot[2],ot[3],false,false,7)
							Spring.UnitWeaponFire(ownerId,2)
							Spring.UnitWeaponFire(ownerId,3)
							Spring.UnitWeaponFire(ownerId,4)
							Spring.UnitWeaponFire(ownerId,5)
							Spring.UnitWeaponFire(ownerId,6)
							Spring.UnitWeaponFire(ownerId,7)
						elseif (submunitionRockets[id] == LONG_RANGE_ROCKET_SUB_TYPE_IMPALER) then
							--Spring.Echo("target x="..ot[1].." y="..ot[2].." z="..ot[3])
							-- spawn submunitions
							--local createdId = spSpawnProjectile(LONG_RANGE_ROCKET_SUB_TYPE_IMPALER,{
							--	["pos"] = {px,py,pz},
							--	["end"] = {ot[1],ot[2],ot[3]},
							--	["speed"] = {dirx*1500,diry*1500,dirz*1500},
							--	["owner"] = ownerId
							--})
							Spring.SetUnitTarget(ownerId,ot[1],ot[2],ot[3],false,false,2)
							Spring.UnitWeaponFire(ownerId,2)
						end
						
						-- remove projectile
						nearCollision = true
						--spSetProjectileCollision(id)
						--GG.destructibleProjectilesDestroyed[ownerId] = nil
					end
				end
				--Spring.Echo("projectile velocity sq = "..tostring(sqV))
			end
			
			if (isCloseToTarget(px,pz,st[1],st[3],LONG_RANGE_ROCKET_FAR_TARGET_DIST)) then
				-- if close to original target, go towards it
				spSetProjectileTarget(id,ot[1],ot[2],ot[3])
				
				-- mark projectile for explosion
				if isAboutToCollide(px,py,pz,ot[1],ot[2],ot[3]) then
					nearCollision = true
				end
			end
		end
		
		-- remove destructible projectiles if the owner died
		if (GG.destructibleProjectilesDestroyed and GG.destructibleProjectilesDestroyed[ownerId] == true) then
			--Spring.Echo("projectile removed because unit "..ownerId.." was destroyed")
			-- remove projectile (unit was reclaimed or explosion already happened when it died)
			spDeleteProjectile(id)
			GG.destructibleProjectilesDestroyed[ownerId] = nil
		elseif(nearCollision) then
			-- detonate when very close to target, to avoid the owner bouncing off the ground
			--Spring.Echo("projectile removed and unit "..ownerId.." detonated properly")			
			spSetProjectileCollision(id)
			GG.destructibleProjectilesDestroyed[ownerId] = nil
		end
	end
	
	-- TODO maybe this isn't really necessary...
	-- explode torpedos if they stray too high out of the water to prevent exploits
	local px,py,pz = 0
	local tx,ty,tz = 0
	local vx,vy,vz = 0
	local wasUnderwater = 0
	local h = 0
	for projID,_ in pairs(torpedoProjectiles) do
		px,py,pz = spGetProjectilePosition(projID)
		h = spGetGroundHeight(px,pz)
		-- mark underwater projectiles
		if (py < -5) then
			projectileWasUnderwater[projID] = n
			-- Echo("projectile "..projID.." was underwater")
		end
		
		
		-- if near target, pop out of water
		-- do this to hit hovercraft
		local _,targetId = spGetProjectileTarget(projID)
		if (type(targetId) == "number" and targetId > 0) then
			tx,ty,tz = spGetUnitPosition(targetId)
			if ty and ty >= 0 and ty < 20 and isCloseToTarget(px,pz,tx,tz,20) then
				vx,vy,vz = spGetProjectileVelocity(projID)
				spSetProjectileVelocity( projID, vx,5,vz)
			end
		end
		
		-- test underwater projectiles (entries are only valid for 60 seconds)
		-- if they strayed too high out of the water, blow them up!
		wasUnderwater = projectileWasUnderwater[projID]
		if wasUnderwater ~= nil and wasUnderwater > 0 and (n - wasUnderwater) < 18000 then
			if py > 100 or h > 5 then
				spSetProjectileCollision(projID)
				
				-- remove table entry
				projectileWasUnderwater[projID] = nil
			end
		end
	end
	
	
	-- handle smart tracking projectiles
	for projID,ownerID in pairs(smartTrackingProjectiles) do
	
		-- if the target was a unit that died, chase something else
		local _,targetId = spGetProjectileTarget(projID)
		if (type(targetId) == "number" and targetId > 0) then
			local isDead = spGetUnitIsDead(targetId)
			if (isDead == nil or isDead == true) then
				--px,py,pz = spGetProjectilePosition(projID)
				
				local isDeadOwner = spGetUnitIsDead(ownerID)
				if (isDeadOwner == false) then
					newTargetId = spGetUnitNearestEnemy(ownerID)
					if (newTargetId) then
						spSetProjectileTarget(newTargetId,'u')
						--Spring.Echo("projectile "..projID.." changing target from "..targetId.." to "..newTargetId)
					else 
						--spSetProjectileCollision(projID)
						--Spring.Echo("projectile "..projID.." has nothing to do : become dumb")
						smartTrackingProjectiles[projID] = nil
					end  
				else
					--spSetProjectileCollision(projID)
					--Spring.Echo("projectile "..projID.." lost target : explode")
					--Spring.Echo("projectile "..projID.." has nothing to do : become dumb")
					smartTrackingProjectiles[projID] = nil
				end
			end
		end
	end	

	--- handle magnetar projectiles
	local v = 40
	local axz,axy,vx,vy,vz = 0
	for projID,ownerId in pairs(magnetarProjectiles) do
		
		-- get position
		px,py,pz = spGetProjectilePosition(projID)
		h = spGetGroundHeight(px,pz)
			
		-- make main projectile explode
		spSetProjectileCollision(projID)
		magnetarProjectiles[projID] = nil
		
		
		-- generate secondary projectiles
		-- TODO do it, or remove this
		--[[
		--]]
		for i=1,20,1 do
			axz = math.pi * (2 - math.random(200) / 100)
			axy = - math.pi * 0.5 * (math.random(100) / 100)

			if axz > math.pi then
				axy = -axy
			end
			vx = v * math.sin(axz) * math.cos(axy)
			vy = v * math.sin(axz) * math.sin(axy)
			vy = math.min(-10,vy)
			vz = v * math.cos(axz) 
		
			local createdId = spSpawnProjectile(magnetarWeaponEffectId,{
				["pos"] = {px,py,pz},
				["end"] = {px+vx,py+vy,pz+vz},
				["speed"] = {vx,vy,vz},
				["owner"] = ownerId
			})
		end
		
	end
	
	-- generate disruptor wave effect projectiles
	for id,ownerId in pairs(disruptorProjectiles) do
		local px,py,pz = spGetProjectilePosition(id)
		px = px - 15 + math.random(30)
		py = py - 15 + math.random(30)
		pz = pz - 15 + math.random(30)
		
		local vx,vy,vz = spGetProjectileVelocity(id)
		
		local createdId = spSpawnProjectile(disruptorWeaponEffectId,{
			["pos"] = {px,py,pz},
			["end"] = {px,py+3,pz},
			["speed"] = {vx,vy,vz},
			["owner"] = ownerId
		})
		
		disruptorEffectProjectiles[createdId] = ownerId
	end

	-- generate fire aoe effect projectiles
	if(n%STEP_DELAY == 0) then
		for id,data in pairs(fireAOEPositions) do

			local createdId = spSpawnProjectile(data.effect,{
				["pos"] = {data.px,data.py,data.pz},
				["end"] = {data.px,data.py+3,data.pz},
				["speed"] = {0,1,0},
				["owner"] = data.ownerId
			})
			fireAOEEffectProjectiles[createdId] = data.ownerId

			-- update table
			if (data.steps > 1) then
				data.steps = data.steps - 1
				fireAOEPositions[id] = data
			else
				fireAOEPositions[id] = nil
			end
		end
	end
end

-- add tracked projectiles to table on creation
function gadget:ProjectileCreated(proID, proOwnerID, weaponDefID)

	-- make atom firing drain own shield
	if (atomWeaponId == weaponDefID) then
		spSetUnitShieldState(proOwnerID, 0)
	end
	if smartTrackingWeaponIds[weaponDefID] then
		smartTrackingProjectiles[proID] = proOwnerID
	end
	
	if weaponDefID == disruptorWeaponId then
		disruptorProjectiles[proID] = proOwnerID
		return
	end
	if torpedoWeaponIds[weaponDefID] then
		torpedoProjectiles[proID] = true
		return
	end
	if highAngleDescentWeaponIds[weaponDefID] then
		highAngleDescentProjectiles[proID] = proOwnerID
		
		local tType,tInfo = spGetProjectileTarget(proID)
		if (tType == string.byte('u')) then
			 local x,y,z = spGetUnitPosition(tInfo)
			 if (x) then
			 	highAngleDescentOriginalTargetsById[proID] = {x,y,z}
			 	tInfo = {x,y,z}
			 end
		elseif (tType == string.byte('f')) then
			 local x,y,z = spGetFeaturePosition(tInfo)
			 if (x) then
			 	highAngleDescentOriginalTargetsById[proID] = {x,y,z}
			 	tInfo = {x,y,z}
			 end
		else
			highAngleDescentOriginalTargetsById[proID] = tInfo
		end
		
		-- if far from original target, go towards the point high above it, randomly offset to spread out
		spSetProjectileTarget(proID,tInfo[1]+50-random(100),tInfo[2]+HIGH_ANGLE_DESCENT_FAR_FROM_TARGET_H,tInfo[3]+50-random(100))
		return
	end
	
	if destructibleWeaponIds[weaponDefID] then
		destructibleProjectiles[proID] = proOwnerID
		spSetUnitRulesParam(proOwnerID,"destructible_projectile_id",proID,UNIT_RP_PUBLIC_TBL)
		spUnitDetach(proOwnerID)
		
		-- mark projectile launch
		local teamId = spGetUnitTeam(proOwnerID)
		lInfo = latestLRRLaunchesByTeamId[teamId]
		if not lInfo then
			lInfo = {frame=0,count=0}
		end
		lInfo.frame = spGetGameFrame()
		lInfo.count = lInfo.count+1
		latestLRRLaunchesByTeamId[teamId] = lInfo
		spSetTeamRulesParam(teamId,"latestLRRLaunches",lInfo.count,{public=true})
		
		local tType,tInfo = spGetProjectileTarget(proID)
		if (tType == string.byte('u')) then
			 local x,y,z = spGetUnitPosition(tInfo)
			 if (x) then
			 	longRangeRocketOriginalTargetsById[proID] = {x,y,z}
			 	tInfo = {x,y,z}
			 end
		elseif (tType == string.byte('f')) then
			 local x,y,z = spGetFeaturePosition(tInfo)
			 if (x) then
			 	longRangeRocketOriginalTargetsById[proID] = {x,y,z}
			 	tInfo = {x,y,z}
			 end
		else
			longRangeRocketOriginalTargetsById[proID] = tInfo
		end
		
		-- if far from original target, go towards the point high above it, randomly offset to spread out
		if (premiumRocketWeaponIds[weaponDefID]) then
			spSetProjectileTarget(proID,tInfo[1]+50-random(100),tInfo[2]+LONG_RANGE_ROCKET_FAR_FROM_TARGET_H*2,tInfo[3]+50-random(100))
		else
			spSetProjectileTarget(proID,tInfo[1]+200-random(400),tInfo[2]+LONG_RANGE_ROCKET_FAR_FROM_TARGET_H,tInfo[3]+200-random(400))
		end
		
		if (dcRocketSpawnWeaponIds[weaponDefID]) then
			dcRockets[proID] = dcRocketSpawnWeaponIds[weaponDefID]
		end
		
		if (submunitionRocketWeaponIds[weaponDefID]) then
			submunitionRockets[proID] = submunitionRocketWeaponIds[weaponDefID]
		end
		
		if (premiumRocketWeaponIds[weaponDefID]) then
			premiumRockets[proID] = true
		end
		
		return
	end	
	if weaponDefID == magnetarWeaponId then
		magnetarProjectiles[proID] = proOwnerID
		return
	end
	if fireAOEWeaponIds[weaponDefID] then
		fireAOEProjectiles[proID] = proOwnerID
		return
	end
	if weaponDefID == comsatWeaponId then
		comsatProjectiles[proID] = proOwnerID
		return
	end
	if weaponDefID == scoperWeaponId then
		scoperProjectiles[proID] = proOwnerID
		return
	end

	if weaponDefID == dynamoWeaponId then
		dynamoProjectiles[proID] = DYNAMO_RING_MAX_DAMAGE
		return
	end	
end

-- remove tracked projectiles from table on destruction or trigger other effects
function gadget:ProjectileDestroyed(proID)
	if smartTrackingProjectiles[proID] then
		smartTrackingProjectiles[proID] = nil
	end
	if highAngleDescentProjectiles[proID] then
		highAngleDescentProjectiles[proID] = nil
		highAngleDescentOriginalTargetsById[proID] = nil
	end
	if destructibleProjectiles[proID] then
		-- if was a DC rocket, exploding near the ground
		-- spawn construction tower at position
		if(dcRockets[proID]) then
			local px,py,pz = spGetProjectilePosition(proID)
			local h = spGetGroundHeight(px,pz)

			if px and abs(py - h) < DC_ROCKET_DEPLOY_LIMIT_H then
				dcRocketSpawn[proID]={frame=spGetGameFrame()+DC_ROCKET_DEPLOY_DELAY_FRAMES,px=px,py=h,pz=pz,defId=dcRockets[proID],teamId=spGetProjectileTeamID(proID)}
			end
			
			dcRockets[proID] = nil
		elseif submunitionRockets[proID] then
			submunitionRockets[proID] = nil
		elseif premiumRockets[proID] then
			premiumRockets[proID] = nil
		end

		-- remove the unit (no explosion)
		spDestroyUnit(destructibleProjectiles[proID],false,true)
		--Spring.Echo("unit removed because projectile "..proID.." was destroyed")
		destructibleProjectiles[proID] = nil
		longRangeRocketOriginalTargetsById[proID] = nil
	end

	if disruptorProjectiles[proID] then
		disruptorProjectiles[proID] = nil
	elseif torpedoProjectiles[proID] then
		torpedoProjectiles[proID] = nil
	elseif magnetarProjectiles[proID] then
		magnetarProjectiles[proID] = nil
	elseif fireAOEProjectiles[proID] then

		-- spawn fire effect at position
		local px,py,pz = spGetProjectilePosition(proID)
		local h = spGetGroundHeight(px,pz)
		local weaponDefId = Spring.GetProjectileDefID(proID)
		local effect = fireAOEWeaponEffectId
		if ((WeaponDefs[weaponDefId].customParams.burnaoe) == "2") then
			effect = fireAOEWeaponEffectId2
		end

		-- do not spawn fire effect in water, and spawn with reduced duration in air
		if (h > 0) then
			local steps = FIRE_AOE_STEPS
			if (py - h > FIRE_AOE_STEPS_AIR_H) then
				steps = FIRE_AOE_STEPS_AIR
			end

			fireAOEPositions[proID]={px=px,py=py,pz=pz,steps=steps,ownerId=fireAOEProjectiles[proID],effect=effect}
		end
		fireAOEProjectiles[proID] = nil
	elseif comsatProjectiles[proID] then
		-- spawn unit to provide LOS
		local ownerId = comsatProjectiles[proID]
		if ownerId then
			local teamId = spGetUnitTeam(ownerId)
			local px,py,pz = spGetProjectilePosition(proID)
			if px and teamId ~= nil and teamId >= 0 then
				local uId = spCreateUnit("cs_beacon",px,py+500,pz,0,teamId,false)
				if uId then
					spSetUnitNeutral(uId,true)
					applyNonInteractiveProperties(uId)
				end
			end
		end
		comsatProjectiles[proID] = nil
	elseif scoperProjectiles[proID] then
		-- spawn unit to provide LOS
		local ownerId = scoperProjectiles[proID]
		if ownerId then
			local teamId = spGetUnitTeam(ownerId)
			local px,py,pz = spGetProjectilePosition(proID)
			if px and teamId ~= nil and teamId >= 0 then
				local uId = spCreateUnit("scoper_beacon",px,py+200,pz,0,teamId,false)
				if uId then
					spSetUnitNeutral(uId,true)
					applyNonInteractiveProperties(uId)
				end
			end
		end
		scoperProjectiles[proID] = nil		
	elseif dynamoProjectiles[proID] then
		dynamoProjectiles[proID] = nil
	end
end

-- handle ring damage
function handleRingDamage(projId, damage, unitHp)
	local remainingDamage = dynamoProjectiles[projId] - min(damage,unitHp)
	local expired = false
	--Spring.Echo("ring! "..projId.." / dmg="..damage.." remDmg="..remainingDamage)
	
	-- already hit for enough damage
	if (remainingDamage < 0) then
		expired = true
	-- hit a tough object
	elseif unitHp > 0 and (unitHp > remainingDamage) then
		expired = true
	end
	
	-- remove ring, or update the damage
	if (expired) then
		spDeleteProjectile(projId)
		-- spawn a bigger explosion
		px,py,pz = spGetProjectilePosition(projId)
		Spring.SpawnCEG("ringblastwrapper", px, py, pz,0,1,0,3000,3000)
		Spring.PlaySoundFile('Sounds/ringhit.wav', 1, px, py, pz)
	else
		dynamoProjectiles[projId] = remainingDamage
	end
end

-- dynamo ring damage tracking
function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
	if (dynamoProjectiles[projectileID]) then
		local hp,_,_,_,_ = spGetUnitHealth(unitID)
		handleRingDamage(projectileID, damage,hp)
	end
end

-- TODO changing this to featureDamaged fixes the issue with the features jumping when hit
-- currently set impulse to 0, so features can no longer be pushed around
function gadget:FeaturePreDamaged(featureID, featureDefID, featureTeam, damage, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
	if (dynamoProjectiles[projectileID]) then
		local hp,_,_ = spGetFeatureHealth(featureID)
		handleRingDamage(projectileID, damage * DYNAMO_RING_FEATURE_DISCOUNT,hp * DYNAMO_RING_FEATURE_DISCOUNT)
	end
	
	return damage,0
end

-- ground explosions for rings are limited 
function gadget:Explosion(weaponDefID, px, py, pz, attackerID, projectileID)
	if (dynamoProjectiles[projectileID]) then
		h = spGetGroundHeight(px,pz)
		if (py < h + 3 or py < 3) then
			--Spring.Echo("dynamo projectile GROUND impact at frame="..spGetGameFrame())
			handleRingDamage(projectileID, DYNAMO_RING_GROUND_DAMAGE,DYNAMO_RING_GROUND_HP)
		end
	end
end