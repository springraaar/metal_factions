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
local spGetProjectileTarget = Spring.GetProjectileTarget
local spSetProjectileTarget = Spring.SetProjectileTarget
local spGetProjectileTeamID = Spring.GetProjectileTeamID
local spSetUnitNeutral = Spring.SetUnitNeutral
local spTestBuildOrder = Spring.TestBuildOrder
local spGetGroundHeight = Spring.GetGroundHeight
local spUnitDetach = Spring.UnitDetach

-- aim point over target when far from it
local LONG_RANGE_ROCKET_FAR_FROM_TARGET_H = 1000		
local LONG_RANGE_ROCKET_FAR_TARGET_DIST = 900			

-- detonate when very close to target
local LONG_RANGE_ROCKET_TERMINAL_DIST = 100

local DC_ROCKET_DEPLOY_LIMIT_H = 300
local DC_ROCKET_AUTO_BUILD_STEPS = 20
local DC_ROCKET_AUTO_BUILD_FRACTION_PER_STEP = 0.05
local DC_ROCKET_DEPLOY_DELAY_FRAMES = 30

local mapSizeX = Game.mapSizeX
local mapSizeZ = Game.mapSizeZ
local max = math.max
local min = math.min
local STEP_DELAY = 6 		-- process steps every N frames
local FIRE_AOE_STEPS = 100	-- 20 seconds

local projectileWasUnderwater = {}

local disruptorWeaponId = WeaponDefNames["aven_bass_disruptor"].id
local disruptorWeaponEffectId = WeaponDefNames["aven_bass_disruptor_effect"].id
local fireAOEWeaponEffectId = WeaponDefNames["gear_fire_effect"].id
local fireAOEWeaponEffectId2 = WeaponDefNames["gear_fire_effect2"].id
local magnetarWeaponId = WeaponDefNames["sphere_magnetar_blast"].id
local magnetarWeaponEffectId = WeaponDefNames["sphere_magnetar_blast_effect"].id
local comsatWeaponId = WeaponDefNames["comsat_beacon"].id
local dynamoWeaponId = WeaponDefNames["claw_dynamo_ring"].id

local DYNAMO_RING_MAX_DAMAGE = 5000
local DYNAMO_RING_BASE_DAMAGE = 3000
local DYNAMO_RING_GROUND_DAMAGE = 1500
local DYNAMO_RING_GROUND_HP = 800

local DYNAMO_RING_FEATURE_DISCOUNT = 0.25

local fireAOEWeaponIds = {
	-- GEAR
	[WeaponDefNames["gear_canister"].id]=true,
	[WeaponDefNames["gear_eruptor"].id]=true,
	[WeaponDefNames["gear_canister_fireball"].id]=true,
	[WeaponDefNames["gear_eruptor_fireball"].id]=true,
	[WeaponDefNames["gear_firestorm_rocket"].id]=true,
	[WeaponDefNames["gear_u5commander_fireball"].id]=true
}

local torpedoWeaponIds = {
	-- AVEN
	[WeaponDefNames["aven_u1commander_torpedo"].id]=true,
	[WeaponDefNames["aven_u2commander_torpedo"].id]=true,
	[WeaponDefNames["aven_u4commander_torpedo"].id]=true,
	[WeaponDefNames["aven_u5commander_torpedo"].id]=true,
	[WeaponDefNames["aven_u6commander_torpedo"].id]=true,
	[WeaponDefNames["aven_commander_torpedo"].id]=true,
	[WeaponDefNames["aven_lurker_torpedo"].id]=true,
	[WeaponDefNames["aven_piranha_torpedo"].id]=true,
	-- GEAR
	[WeaponDefNames["gear_commander_torpedo"].id]=true,
	[WeaponDefNames["gear_u1commander_torpedo"].id]=true,
	[WeaponDefNames["gear_u2commander_torpedo"].id]=true,
	[WeaponDefNames["gear_u3commander_torpedo"].id]=true,
	[WeaponDefNames["gear_u4commander_torpedo"].id]=true,
	[WeaponDefNames["gear_u5commander_torpedo"].id]=true,
	[WeaponDefNames["gear_snake_torpedo"].id]=true,
	[WeaponDefNames["gear_noser_torpedo"].id]=true,
	[WeaponDefNames["corssub_weapon"].id]=true,
	-- CLAW
	[WeaponDefNames["claw_commander_torpedo"].id]=true,
	[WeaponDefNames["claw_u1commander_torpedo"].id]=true,
	[WeaponDefNames["claw_u2commander_torpedo"].id]=true,
	[WeaponDefNames["claw_u3commander_torpedo"].id]=true,
	[WeaponDefNames["claw_u4commander_torpedo"].id]=true,
	[WeaponDefNames["claw_u5commander_torpedo"].id]=true,
	[WeaponDefNames["claw_u6commander_torpedo"].id]=true,
	[WeaponDefNames["claw_spine_torpedo"].id]=true,
	[WeaponDefNames["claw_monster_torpedo"].id]=true,
	-- SPHERE
	[WeaponDefNames["sphere_commander_torpedo"].id]=true,
	[WeaponDefNames["sphere_u1commander_torpedo"].id]=true,
	[WeaponDefNames["sphere_u2commander_torpedo"].id]=true,
	[WeaponDefNames["sphere_u3commander_torpedo"].id]=true,
	[WeaponDefNames["sphere_u4commander_torpedo"].id]=true,
	[WeaponDefNames["sphere_u5commander_torpedo"].id]=true,
	[WeaponDefNames["sphere_u6commander_torpedo"].id]=true,
	[WeaponDefNames["sphere_carp_torpedo"].id]=true,
	[WeaponDefNames["sphere_pluto_torpedo"].id]=true,
	[WeaponDefNames["sphere_clam_torpedo"].id]=true,
	[WeaponDefNames["sphere_oyster_torpedo"].id]=true
}


local destructibleWeaponIds = {
	-- AVEN
	[WeaponDefNames["aven_nuclear_rocket"].id]=true,
	[WeaponDefNames["aven_dc_rocket"].id]=true,
	-- GEAR
	[WeaponDefNames["gear_nuclear_rocket"].id]=true,
	[WeaponDefNames["gear_dc_rocket"].id]=true,
	-- CLAW
	[WeaponDefNames["claw_nuclear_rocket"].id]=true,
	[WeaponDefNames["claw_dc_rocket"].id]=true,
	-- SPHERE
	[WeaponDefNames["sphere_nuclear_rocket"].id]=true,
	[WeaponDefNames["sphere_dc_rocket"].id]=true
}

local dcRocketSpawnWeaponIds = {
	[WeaponDefNames["aven_dc_rocket"].id]=UnitDefNames["aven_nano_tower"].id,
	[WeaponDefNames["gear_dc_rocket"].id]=UnitDefNames["gear_nano_tower"].id,
	[WeaponDefNames["claw_dc_rocket"].id]=UnitDefNames["claw_nano_tower"].id,
	[WeaponDefNames["sphere_dc_rocket"].id]=UnitDefNames["sphere_pole"].id
}


local longRangeRocketOriginalTargetsById = {}
local disruptorProjectiles = {}
local disruptorEffectProjectiles = {}
local torpedoProjectiles = {}
local fireAOEProjectiles = {}
local fireAOEEffectProjectiles = {}
local fireAOEPositions = {}
local magnetarProjectiles = {}
local destructibleProjectiles = {}
local dcRockets = {}
local comsatProjectiles = {}
local comsatBeaconDefId = UnitDefNames["cs_beacon"].id
local dynamoProjectiles = {}
dcRocketSpawn = {}

-- is close enough on x-z plane to start diving toward target
function isCloseToTarget(px,pz,tx,tz)
	if (abs(px-tx) < LONG_RANGE_ROCKET_FAR_TARGET_DIST) and (abs(pz-tz) < LONG_RANGE_ROCKET_FAR_TARGET_DIST) then
		return true
	end 
	return false
end

-- is just about to hit the target
function isAboutToCollide(px,py,pz,tx,ty,tz)
	if (abs(px-tx) < LONG_RANGE_ROCKET_TERMINAL_DIST) and (abs(pz-tz) < LONG_RANGE_ROCKET_TERMINAL_DIST and abs(py-ty) < LONG_RANGE_ROCKET_TERMINAL_DIST) then
		return true
	end 
	return false
end

-------------------------- SYNCED CODE ONLY
if (not gadgetHandler:IsSyncedCode()) then
	return false
end


function gadget:Initialize()
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
	
	-- track comsat projectiles
	Script.SetWatchWeapon(comsatWeaponId,true)
	
	-- track dynamo projectiles
	Script.SetWatchWeapon(dynamoWeaponId,true)

	-- track destructible projectiles
	for id,_ in pairs(destructibleWeaponIds) do
		Script.SetWatchWeapon(id,true)
	end
end


-- execute action every frame for tracked projectiles, as necessary
function gadget:GameFrame(n)
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
					spSetUnitRulesParam(uId,"auto_build_fraction_per_step",DC_ROCKET_AUTO_BUILD_FRACTION_PER_STEP,{public = true})	
					spSetUnitRulesParam(uId,"auto_build_steps",DC_ROCKET_AUTO_BUILD_STEPS,{public = true})
				end
				-- also add a cs beacon temporarily over it to provide los
				uId = spCreateUnit("cs_beacon",info.px,info.py+500,info.pz,0,info.teamId,false)
				if uId then
					spSetUnitNeutral(uId,true)
				end
			end
			
			dcRocketSpawn[id] = nil
		end
	end
	
	-- handle destructible long range projectiles
	local px,py,pz = 0
	local ot = nil
	local tType,st = nil
	local nearCollision = false
	for id,ownerId in pairs(destructibleProjectiles) do
		px,py,pz = spGetProjectilePosition(id)
		ot = longRangeRocketOriginalTargetsById[id]
		nearCollision = false
		tType,st = spGetProjectileTarget(id)
		
		--Spring.Echo("projectile px="..tostring(px).." otx="..tostring(ot[1]))
		if (px and ot) then
			if (tType == string.byte('u') or tType == string.byte('f')) then
				st = ot
			end
			
			if (isCloseToTarget(px,pz,st[1],st[3])) then
				-- if close to original target, go towards it
				spSetProjectileTarget(id,ot[1],ot[2],ot[3])
				
				-- remove owner, the projectile
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
	local wasUnderwater = 0
	local h = 0
	for projID,_ in pairs(torpedoProjectiles) do
		px,py,pz = spGetProjectilePosition(projID)
		h = spGetGroundHeight(px,pz)
		-- mark underwater projectiles
		if (py < -5) then
			projectileWasUnderwater[projID] = n
			-- Echo("projectile "..projID.." was underwater")
			return
		end
		
		-- test underwater projectiles (entries are only valid for 60 seconds)
		-- if they strayed too high out of the water, blow them up!
		wasUnderwater = projectileWasUnderwater[projID]
		if wasUnderwater ~= nil and wasUnderwater > 0 and (n - wasUnderwater) < 18000 then
			if py > 20 or h > 5 then
				spSetProjectileCollision(projID)
				
				-- remove table entry
				projectileWasUnderwater[projID] = nil
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
		
			local createdId = Spring.SpawnProjectile(magnetarWeaponEffectId,{
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
		
		local createdId = Spring.SpawnProjectile(disruptorWeaponEffectId,{
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

			local createdId = Spring.SpawnProjectile(data.effect,{
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
	if weaponDefID == disruptorWeaponId then
		disruptorProjectiles[proID] = proOwnerID
		return
	end
	if torpedoWeaponIds[weaponDefID] then
		torpedoProjectiles[proID] = true
		return
	end
	if destructibleWeaponIds[weaponDefID] then
		destructibleProjectiles[proID] = proOwnerID
		spSetUnitRulesParam(proOwnerID,"destructible_projectile_id",proID,{public = true})
		spUnitDetach(proOwnerID)
		
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
		spSetProjectileTarget(proID,tInfo[1]+200-random(400),tInfo[2]+LONG_RANGE_ROCKET_FAR_FROM_TARGET_H,tInfo[3]+200-random(400))
		
		if (dcRocketSpawnWeaponIds[weaponDefID]) then
			dcRockets[proID] = dcRocketSpawnWeaponIds[weaponDefID]
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
	if weaponDefID == dynamoWeaponId then
		dynamoProjectiles[proID] = DYNAMO_RING_MAX_DAMAGE
		return
	end	
end

-- remove tracked projectiles from table on destruction or trigger other effects
function gadget:ProjectileDestroyed(proID)
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
		end


		-- remove the unit (no explosion)
		spDestroyUnit(destructibleProjectiles[proID],true)
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

		-- do not spawn fire effect in water
		if (h > 0) then
			fireAOEPositions[proID]={px=px,py=h+5,pz=pz,steps=FIRE_AOE_STEPS,ownerId=fireAOEProjectiles[proID],effect=effect}
		end
		fireAOEProjectiles[proID] = nil
	elseif comsatProjectiles[proID] then
		-- spawn unit to provide LOS
		local ownerId = comsatProjectiles[proID]
		if ownerId then
			local teamId = spGetUnitTeam(ownerId)
			local px,py,pz = spGetProjectilePosition(proID)
			if px then
				local uId = spCreateUnit("cs_beacon",px,py+500,pz,0,teamId,false)
				if uId then
					spSetUnitNeutral(uId,true)
				end
			end
		end
		comsatProjectiles[proID] = nil
	elseif dynamoProjectiles[proID] then
		dynamoProjectiles[proID] = nil
	end
end

-- torpedo weapon target check
-- TODO this should work, but doesn't: engine bug
function gadget:AllowWeaponTarget(attackerID, targetID, attackerWeaponNum, attackerWeaponDefID, defaultPriority)
	if torpedoWeaponIds[attackerWeaponDefID] then
		-- if target is on land, return false
		local x,y,z = Spring.GetUnitPosition(targetID)
		local h = spGetGroundHeight(x,z)
		
		if (h > 0 or y > 30) then
			return false,99999999
		end
	end

	return true,defaultPriority
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