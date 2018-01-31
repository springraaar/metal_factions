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

-- jan 2018 : handles comsat projectiles
-- feb 2016 : handles magnetar projectiles
-- sep 2015 : handles area fire effects
-- sep 2015 : torpedos no longer target land targets and fixed explosion when over land or above threshold
-- aug 2015 : reworked code to track only specific projectiles
-- aug 2015 : added support for disruptor wave line area damage

local Echo = Spring.Echo
local floor = math.floor
local ceil = math.ceil
local GetGameFrame = Spring.GetGameFrame
local GetProjectileName = Spring.GetProjectileName
local GetProjectilePosition = Spring.GetProjectilePosition
local SetProjectileCollision = Spring.SetProjectileCollision
local GetProjectilesInRectangle = Spring.GetProjectilesInRectangle
local spCreateUnit = Spring.CreateUnit
local spGetUnitTeam = Spring.GetUnitTeam
local spDestroyUnit = Spring.DestroyUnit
local max = math.max

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

local fireAOEWeaponIds = {
	-- GEAR
	[WeaponDefNames["gear_canister"].id]=true,
	[WeaponDefNames["gear_eruptor"].id]=true,
	[WeaponDefNames["gear_canister_fireball"].id]=true,
	[WeaponDefNames["gear_eruptor_fireball"].id]=true,
	[WeaponDefNames["gear_firestorm_fireball"].id]=true,
	[WeaponDefNames["gear_u5commander_fireball"].id]=true
}

local torpedoWeaponIds = {
	-- AVEN
	[WeaponDefNames["aven_u1commander_torpedo"].id]=true,
	[WeaponDefNames["aven_commander_torpedo"].id]=true,
	[WeaponDefNames["aven_lurker_torpedo"].id]=true,
	[WeaponDefNames["aven_piranha_torpedo"].id]=true,
	[WeaponDefNames["aven_u4commander_torpedo"].id]=true,
	[WeaponDefNames["aven_u5commander_torpedo"].id]=true,
	-- GEAR
	[WeaponDefNames["gear_commander_torpedo"].id]=true,
	[WeaponDefNames["gear_u1commander_torpedo"].id]=true,
	[WeaponDefNames["gear_u2commander_torpedo"].id]=true,
	[WeaponDefNames["gear_u3commander_torpedo"].id]=true,
	[WeaponDefNames["gear_u4commander_torpedo"].id]=true,
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
	[WeaponDefNames["claw_spine_torpedo"].id]=true,
	[WeaponDefNames["claw_monster_torpedo"].id]=true,
	-- SPHERE
	[WeaponDefNames["sphere_commander_torpedo"].id]=true,
	[WeaponDefNames["sphere_u1commander_torpedo"].id]=true,
	[WeaponDefNames["sphere_u2commander_torpedo"].id]=true,
	[WeaponDefNames["sphere_u3commander_torpedo"].id]=true,
	[WeaponDefNames["sphere_u4commander_torpedo"].id]=true,
	[WeaponDefNames["sphere_u5commander_torpedo"].id]=true,
	[WeaponDefNames["sphere_carp_torpedo"].id]=true,
	[WeaponDefNames["sphere_pluto_torpedo"].id]=true,
	[WeaponDefNames["sphere_clam_torpedo"].id]=true,
	[WeaponDefNames["sphere_oyster_torpedo"].id]=true
}
local disruptorProjectiles = {}
local disruptorEffectProjectiles = {}
local torpedoProjectiles = {}
local fireAOEProjectiles = {}
local fireAOEEffectProjectiles = {}
local fireAOEPositions = {}
local magnetarProjectiles = {}
local comsatProjectiles = {}
local comsatBeaconDefId = UnitDefNames["cs_beacon"].id

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
end


-- execute action every frame for tracked projectiles, as necessary
function gadget:GameFrame(n)
	-- explode disruptor wave effect projectiles
	for id,ownerId in pairs(disruptorEffectProjectiles) do
		-- explode projectile
		SetProjectileCollision(id)
		
		-- remove table entry
		disruptorEffectProjectiles[id] = nil
	end

	-- explode fire aoe effect projectiles
	for id,ownerId in pairs(fireAOEEffectProjectiles) do
		-- explode projectile
		SetProjectileCollision(id)
		
		-- remove table entry
		fireAOEEffectProjectiles[id] = nil
	end
	
	-- TODO maybe this isn't really necessary...
	-- explode torpedos if they stray too high out of the water to prevent exploits
	local px,py,pz = 0
	local wasUnderwater = 0
	local h = 0
	for projID,_ in pairs(torpedoProjectiles) do
		px,py,pz = GetProjectilePosition(projID)
		h = Spring.GetGroundHeight(px,pz)
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
				SetProjectileCollision(projID)
				
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
		px,py,pz = GetProjectilePosition(projID)
		h = Spring.GetGroundHeight(px,pz)
			
		-- make main projectile explode
		SetProjectileCollision(projID)
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
		local px,py,pz = GetProjectilePosition(id)
		px = px - 15 + math.random(30)
		py = py - 15 + math.random(30)
		pz = pz - 15 + math.random(30)
		
		local createdId = Spring.SpawnProjectile(disruptorWeaponEffectId,{
			["pos"] = {px,py,pz},
			["end"] = {px,py+3,pz},
			["speed"] = {0,1,0},
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
end

-- remove tracked projectiles from table on destruction or trigger other effects
function gadget:ProjectileDestroyed(proID)
	if disruptorProjectiles[proID] then
		disruptorProjectiles[proID] = nil
	elseif torpedoProjectiles[proID] then
		torpedoProjectiles[proID] = nil
	elseif magnetarProjectiles[proID] then
		magnetarProjectiles[proID] = nil
	elseif fireAOEProjectiles[proID] then

		-- spawn fire effect at position
		local px,py,pz = GetProjectilePosition(proID)
		local h = Spring.GetGroundHeight(px,pz)
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
			local px,py,pz = GetProjectilePosition(proID)
			if px then
				spCreateUnit("cs_beacon",px,py+500,pz,0,teamId,false)
			end
		end
		comsatProjectiles[proID] = nil
	end
end

-- torpedo weapon target check
-- TODO this should work, but doesn't: engine bug
function gadget:AllowWeaponTarget(attackerID, targetID, attackerWeaponNum, attackerWeaponDefID, defaultPriority)
	if torpedoWeaponIds[attackerWeaponDefID] then
		-- if target is on land, return false
		local x,y,z = Spring.GetUnitPosition(targetID)
		local h = Spring.GetGroundHeight(x,z)
		
		if (h > 0 or y > 30) then
			return false,99999999
		end
	end

	return true,defaultPriority
end
