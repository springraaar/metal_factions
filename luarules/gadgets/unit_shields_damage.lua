function gadget:GetInfo()
   return {
      name = "Handles damage mitigation and shield related stuff",
      desc = "Makes shields absorb AOE damage, prevents unit collision damage.",
      author = "raaar",
      date = "July 2013",
      license = "PD",
      layer = 0,
      enabled = true,
   }
end

-- feb 2016 : magnetar dmg handling, make stunned aircraft lose altitude
-- jan 2016 : added dmg taken to xp conversion
-- dec 2015 : added max fire aoe dmg
-- nov 2015 : tweaked fire dmg over time values and scale paralyze dmg with missing health %
-- sep 2015 : added fire dmg over time debuff handling
-- feb 2015 : excluded large shield units from special shield rules
-- jan 2015 : made paralyzer weapons deal % dmg to HP
-- mar 2014 : fixes for spring 97.0 : removed local pointers for spring functions and added missing syncedcode check!
-- Sep 2013 : also disables unit collision damage

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
    return
end


local COLVOL_SHIELD = 0
local COLVOL_BASE = 1
local PARALYZE_DAMAGE_FACTOR = 0.33 -- paralyze damage adds this fraction as normal damage
local PARALYZE_MISSING_HP_FACTOR = 2.0 -- how much paralyze damage is amplified by target's missing HP %
local DAMAGE_REPAIR_DISRUPT_FRAMES = 60 
local SUBMERGED_SURFACE_BLAST_DMG_FACTOR = 0.25 
local SUBMERGED_SURFACE_BLAST_DMG_THRESHOLD = 5

local UNIT_RECLAIM_FACTOR = 1.0

local ARMOR_L = 1
local ARMOR_M = 2
local ARMOR_H = 3
local POWER_L = 1
local POWER_M = 2
local POWER_H = 3

local INDIRECT_DMG_THRESHOLD = 0.85 
local H_ARMOR_INDIRECT_DMG_MULT = 0.8	-- H armor takes 20% less dmg from AOE

--local projectileHitShield = {}
local weaponDefIdByNameTable = {}
local weaponHitpowerTable = {}
local weaponDirectHitDmgPerArmorType = {}
local unitArmorTypeTable = {}
local baseUnitColvolTable = {}
local unitShieldColvolTable = {}
local aircraftTable = {}
local stunnedAircraftTable = {}
local unitBurningTable = {}
local unitBurningDPStepTable = {}
local unitStormDPStepTable = {}
local unitXPTable = {}
local damagedUnitFrameTable = {}
local cloakDisruptedUnitFrameTable = {}

local spGetUnitHealth = Spring.GetUnitHealth
local spSetUnitCollisionVolumeData = Spring.SetUnitCollisionVolumeData
local spGetUnitCollisionVolumeData = Spring.GetUnitCollisionVolumeData
local spSetUnitMidAndAimPos = Spring.SetUnitMidAndAimPos
local spSetUnitShieldState = Spring.SetUnitShieldState
local spGetUnitShieldState = Spring.GetUnitShieldState
local spAddUnitDamage = Spring.AddUnitDamage
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitRadius = Spring.GetUnitRadius
local spGetUnitExperience = Spring.GetUnitExperience
local spSetUnitExperience = Spring.SetUnitExperience
local spGetGroundHeight = Spring.GetGroundHeight
local spGetUnitDirection = Spring.GetUnitDirection
local spSetUnitVelocity = Spring.SetUnitVelocity
local spAddUnitImpulse = Spring.AddUnitImpulse
local spGetUnitIsStunned = Spring.GetUnitIsStunned
local spAreTeamsAllied = Spring.AreTeamsAllied
local spSetUnitDirection = Spring.SetUnitDirection
local spSetUnitRulesParam = Spring.SetUnitRulesParam
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spGetAllUnits = Spring.GetAllUnits
local spGetUnitVelocity = Spring.GetUnitVelocity
local spUseUnitResource = Spring.UseUnitResource
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitIsStunned = Spring.GetUnitIsStunned
local spGetUnitNearestEnemy = Spring.GetUnitNearestEnemy
local spGetGameFrame = Spring.GetGameFrame
local spGetUnitTransporter = Spring.GetUnitTransporter
local spGetTeamInfo = Spring.GetTeamInfo
local spAddTeamResource = Spring.AddTeamResource
local spSpawnCEG = Spring.SpawnCEG
local spPlaySoundFile = Spring.PlaySoundFile
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGetUnitsInCylinder = Spring.GetUnitsInCylinder
local spGetAllyTeamList = Spring.GetAllyTeamList
local spGetUnitAllyTeam = Spring.GetUnitAllyTeam
local spSetUnitLosState = Spring.SetUnitLosState
local spSetUnitLosMask = Spring.SetUnitLosMask    
local max = math.max
local random = math.random
local floor = math.floor

include("lualibs/util.lua")

local STEP_DELAY = 6 		-- process steps every N frames
local FIRE_DMG_PER_STEP = 6	-- 6 dmg every 6 frames, 30 frames per second -> 30 dps
local FIRE_DMG_PER_STEP_HEAVY = 3	-- 3 dmg every 6 frames, 30 frames per second -> 15 dps to heavy armor
local FIRE_DMG_STEPS = 35  -- 6 seconds
local FIRE_AOE_DMG_MAX_PER_STEP = 60 --- 300 dps
local STORM_AOE_DMG_MAX_PER_STEP = 100 --- 500 D dps, 166 dps

local BURNING_CEG = "burneffect"
local BURNING_SOUND = "Sounds/BURN1.wav"

local EMP_CEG = "ElectricSequenceSML2"
local EMP_SOUND = 'Sounds/Lashit.wav'

local UNIT_DAMAGE_DEALT_XP = 0.12    	-- 100%HP damage dealt to enemy unit of equal value is converted to experience using this factor

local UNIT_DAMAGE_TAKEN_XP = 0.06		-- 100%HP damage taken from enemies is converted to experience using this factor
										-- currently set to half as much as fully damaging and enemy unit of equal power

local RECLOAK_DELAY_FRAMES = 150
local CLOAK_MOVING_THRESHOLD = 0.3 
local DECLOAK_DAMAGE_THRESHOLD = 3

local LONG_RANGE_ROCKET_CHAIN_DAMAGE_FACTOR = 0.1  -- shot down long range rockets dmg fraction against rockets in flight 

local EMPTY_TABLE = {}

local disruptorWaveEffectWeaponDefId = WeaponDefNames["aven_bass_disruptor_effect"].id
local disruptorWaveUnitDefId = UnitDefNames["aven_bass"].id
local magnetarUnitDefId = UnitDefNames["sphere_magnetar"].id
local magnetarWeaponDefId = WeaponDefNames["sphere_magnetar_blast"].id
local magnetarAuraWeaponDefId = WeaponDefNames["sphere_magnetar_aura_blast"].id
local fireBurnDOTWeaponDefId = WeaponDefNames["gear_fire_burn_damage"].id

local notDirectlyUpgradedWeaponDefIds = {
	[-1] = true,		-- burning damage
	[WeaponDefNames["sphere_magnetar_aura_blast"].id] = true,
	[WeaponDefNames["aven_bass_disruptor_effect"].id] = true,
	[WeaponDefNames["gear_fire_effect"].id] = true,
	[WeaponDefNames["gear_fire_effect2"].id] = true,
	[fireBurnDOTWeaponDefId] = true
}

local scoperBeaconDefIds = {
	[UnitDefNames["cs_beacon"].id] = true,
	[UnitDefNames["scoper_beacon"].id] = true
}
local dronerWeaponDefIds = {
	[WeaponDefNames["aven_skein_beacon"].id] = true
}

local burningImmuneDefIds = {
	[UnitDefNames["gear_pyro"].id] = true,
	[UnitDefNames["gear_heater"].id] = true,
	[UnitDefNames["gear_u1commander"].id] = true,
	[UnitDefNames["gear_u5commander"].id] = true,
	[UnitDefNames["gear_firestorm"].id] = true,
	[UnitDefNames["gear_cloakable_cube"].id] = true,
	[UnitDefNames["gear_cube"].id] = true,
	[UnitDefNames["gear_burner"].id] = true
}

local burningEffectWeaponDefIds = {}

local burningAOEPerStepWeaponDefIds = {
	[WeaponDefNames["gear_fire_effect"].id] = true,
	[WeaponDefNames["gear_fire_effect2"].id] = true
}
local stormAOEPerStepWeaponDefIds = {
	[WeaponDefNames["disruptor_storm_effect"].id] = true
}

local largeShieldUnitDefIds = {}
local largeShieldUnits = {}	-- table with visibility for each ally team
local dmgModDeadUnits = {} -- for units that deal damage after they die
							-- workaround for unitRulesParams no longer being available

local upgradeFinishedDefIds = {
	[WeaponDefNames["upgrade_red"].id] = true,
	[WeaponDefNames["upgrade_green"].id] = true,
	[WeaponDefNames["upgrade_blue"].id] = true
}

local expDmgScalingWeaponDefIds = {}

local reducedDamageLongRangeRocketsWeaponDefIds = {
	[WeaponDefNames["aven_nuclear_rocket_d"].id] = true,
	[WeaponDefNames["aven_nuclear_rocket"].id] = true,
	[WeaponDefNames["aven_dc_rocket_d"].id] = true,
	[WeaponDefNames["aven_dc_rocket"].id] = true,
	[WeaponDefNames["aven_lightning_rocket_d"].id] = true,
	[WeaponDefNames["aven_lightning_rocket"].id] = true,
	[WeaponDefNames["gear_nuclear_rocket_d"].id] = true,
	[WeaponDefNames["gear_nuclear_rocket"].id] = true,
	[WeaponDefNames["gear_dc_rocket_d"].id] = true,
	[WeaponDefNames["gear_dc_rocket"].id] = true,
	[WeaponDefNames["gear_pyroclasm_rocket_d"].id] = true,
	[WeaponDefNames["gear_pyroclasm_rocket"].id] = true,
	[WeaponDefNames["claw_nuclear_rocket_d"].id] = true,
	[WeaponDefNames["claw_nuclear_rocket"].id] = true,
	[WeaponDefNames["claw_dc_rocket_d"].id] = true,
	[WeaponDefNames["claw_dc_rocket"].id] = true,
	[WeaponDefNames["claw_impaler_rocket_d"].id] = true,
	[WeaponDefNames["claw_impaler_rocket"].id] = true,
	[WeaponDefNames["sphere_nuclear_rocket_d"].id] = true,
	[WeaponDefNames["sphere_nuclear_rocket"].id] = true,
	[WeaponDefNames["sphere_dc_rocket_d"].id] = true,
	[WeaponDefNames["sphere_dc_rocket"].id] = true,
	[WeaponDefNames["sphere_meteorite_rocket_d"].id] = true,
	[WeaponDefNames["sphere_meteorite_rocket"].id] = true
}

local longRangeRocketsDefIds = {
	[UnitDefNames["aven_premium_nuclear_rocket"].id] = true,
	[UnitDefNames["aven_nuclear_rocket"].id] = true,
	[UnitDefNames["aven_dc_rocket"].id] = true,
	[UnitDefNames["aven_lightning_rocket"].id] = true,
	[UnitDefNames["gear_premium_nuclear_rocket"].id] = true,
	[UnitDefNames["gear_nuclear_rocket"].id] = true,
	[UnitDefNames["gear_dc_rocket"].id] = true,
	[UnitDefNames["gear_pyroclasm_rocket"].id] = true,
	[UnitDefNames["claw_premium_nuclear_rocket"].id] = true,
	[UnitDefNames["claw_nuclear_rocket"].id] = true,
	[UnitDefNames["claw_dc_rocket"].id] = true,
	[UnitDefNames["claw_impaler_rocket"].id] = true,
	[UnitDefNames["sphere_premium_nuclear_rocket"].id] = true,
	[UnitDefNames["sphere_nuclear_rocket"].id] = true,
	[UnitDefNames["sphere_dc_rocket"].id] = true,
	[UnitDefNames["sphere_meteorite_rocket"].id] = true
}

local deathFireballDefIds = {
	[UnitDefNames["gear_canister"].id] = "gear_canister_fireball",
	[UnitDefNames["gear_eruptor"].id] = "gear_eruptor_fireball",
	[UnitDefNames["gear_mass_burner"].id] = "gear_eruptor_fireball"

}
local notWaterWeaponDefIds = {}
local ignoreShieldWeaponDefIds = {}

local targetDefId = UnitDefNames["target"].id
local targetDamage = 0

-- more reusable locals
-- TODO may be a bad idea because 60 upvalues limit and dubious performance gains 
local d,x,y,z,xo,yo,zo,h,dx,dy,dz, vx,vy,vz,factor,vType,tType,axis
local armorType,hitpower,factor
local defMod,wDmg,correctedDamage
local health,maxHealth
local frac,takenDef,dealtDef
local f, damagedFrame,buildBlocked,incomeMult,metalAmount
local UNIT_RP_PUBLIC_TBL = {public = true}

------------------------------------------------ auxiliary functions


-- set unit collision volume data
function SetColvol(unitID, colvolType)
	if colvolType == COLVOL_SHIELD then
		d = unitShieldColvolTable[unitID]
	else
		d = baseUnitColvolTable[unitID]
	end
	if d ~= nil then
		spSetUnitCollisionVolumeData(unitID, d[1],d[2],d[3], d[4],d[5],d[6],d[7],d[8],d[9])
		--spSetUnitMidAndAimPos(unitID,0, d[2]*0.5, 0,0, d[2]*0.5,0,true)   -- disabled : this shifts the collision volume as well	
	end
end

-- long range rockets that were shot down deal reduced dmg to others in flight
local function checkPreventLRRChainExploding(damage,unitDefID,weaponDefID)
	if (longRangeRocketsDefIds[unitDefID] == true and reducedDamageLongRangeRocketsWeaponDefIds[weaponDefID] == true) then
		return true
	end
	return false
end

local function checkSubmergedSurfaceBlastDampening(unitID,weaponDefID) 
	local fullySubmergedDepth = spGetUnitRulesParam(unitID, "fullySubmergedDepth")
	if fullySubmergedDepth and fullySubmergedDepth > SUBMERGED_SURFACE_BLAST_DMG_THRESHOLD then
		if (notWaterWeaponDefIds[weaponDefID]) then
			return true
		end
	end
	return false
end


local function checkDroneBeaconTargetting(attackerID,weaponDefID,unitID)
	if(dronerWeaponDefIds[weaponDefID]) then
		local dronesByName = GG.droneOwnersDrones[attackerID]
		if dronesByName then
			for uName,uIdSet in pairs(dronesByName) do
				--Spring.Echo("set had "..#uIdSet.." drones")
				for _,uId in pairs(uIdSet) do
					-- order each drone to attack the target
					spGiveOrderToUnit(uId,CMD.FIGHT,{unitID},EMPTY_TABLE)
				end 
			end
		end
		return 1
	end
	return 0
end


------------------------------------------------ engine callins

function gadget:Initialize()
	-- find units armor types and large shield unit def ids
    for _,ud in pairs(UnitDefs) do
    	if ud.name == "sphere_aegis" or ud.name == "sphere_shielder" or ud.name == "sphere_screener" or ud.name == "sphere_hermit" then
    		largeShieldUnitDefIds[ud.id] = true
    	end
    	
		armorType = ARMOR_L
        if ( Game.armorTypes[ud.armorType] == "armor_heavy" ) then armorType = ARMOR_H
        elseif ( Game.armorTypes[ud.armorType] == "armor_medium" ) then armorType = ARMOR_M end

		unitArmorTypeTable[ud.id] = armorType
    end

	-- find weapon hitpower, paralyzer status and max damage for each armor type
    for _,wd in pairs(WeaponDefs) do        
		hitpower = POWER_L
 		if (not wd.waterWeapon) then
			notWaterWeaponDefIds[wd.id] = true
		end
 		if wd.customParams then
			if wd.customParams.hitpower then
				hitpower = tonumber(wd.customParams.hitpower)
			end
			local burnType = wd.customParams.burn
			if burnType and tonumber(burnType) > 0 then
				burningEffectWeaponDefIds[wd.id] = true
			end
			if wd.customParams.ignoreshield and tonumber(wd.customParams.ignoreshield) == 1 then
				ignoreShieldWeaponDefIds[wd.id] = true
			end
		end
 		
 		if wd.customParams and wd.customParams.expdmgscaling then
 			expDmgScalingWeaponDefIds[wd.id] = true
 		end
    	weaponDefIdByNameTable[wd.name] = wd.id
    	weaponHitpowerTable[wd.id] = hitpower
    	if (wd.damages) then
    		if wd.type == "BeamLaser" and wd.beamtime and wd.beamtime > 0 then
    			--Spring.Echo(wd.name.." bt="..wd.beamtime)
    			local perFrameDmgMult = floor(wd.beamtime / 0.0333333)
    			weaponDirectHitDmgPerArmorType[wd.id] = {wd.damages[2]/perFrameDmgMult,wd.damages[3]/perFrameDmgMult,wd.damages[1]/perFrameDmgMult}	-- convert order H,L,M to L,M,H
    		else
    			weaponDirectHitDmgPerArmorType[wd.id] = {wd.damages[2],wd.damages[3],wd.damages[1]}	-- convert order H,L,M to L,M,H
    		end 
    	end
    	
    	-- track all projectiles
		Script.SetWatchWeapon(wd.id,true)
    end
end

-- add base collision volume of shielded unit to table
-- add aircrafts to list
function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	shieldEnabled,oldShieldPower = spGetUnitShieldState(unitID)
	if shieldEnabled and oldShieldPower > 0 then
		local ud = UnitDefs[unitDefID]
		local shieldDefID = ud.shieldWeaponDef
		if  (largeShieldUnitDefIds[unitDefID] == true) then
			-- record that it's a large shield unit and the shield radius
			-- used for visibility workaround
			local allyTeamVisibility = {}
			for _,allyId in pairs(spGetAllyTeamList()) do
				allyTeamVisibility[allyId] = false
			end
			largeShieldUnits[unitID] =  {radius=WeaponDefs[shieldDefID].shieldRadius+600,allyTeamVisibility=allyTeamVisibility}
		else
			-- add base colvol to table 
			xs, ys, zs, xo, yo, zo, vType, tType, axis, _ = spGetUnitCollisionVolumeData(unitID)
			baseUnitColvolTable[unitID] = {xs,ys,zs,xo,yo,zo,vType,tType,axis}
		
			-- get shield colvol and add it to table
			diameter = WeaponDefs[shieldDefID].shieldRadius * 2
			unitShieldColvolTable[unitID] = {diameter,diameter,diameter,xo,yo,zo,3,1,0}
		end
	end
	
	if (UnitDefs[unitDefID].canFly) then
		aircraftTable[unitID] = true
	end
end

-- clear damage modifier for dead unit if unitID is reused
function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	dmgModDeadUnits[unitID] = nil
end

-- process update steps every N frames
-- process aircraft altitude loss every frame
function gadget:GameFrame(n)
	
	-- make stunned aircraft fall
	-- TODO this should be reviewed and moved to unit physics handler
	
	for unitId,_ in pairs(stunnedAircraftTable) do  
		x,y,z = spGetUnitPosition(unitId)
		h = spGetGroundHeight(x,z)
		
		factor = math.min((y - h) / 70,3)
		if (y > (h+70)) then
			dx,dy,dz = spGetUnitDirection(unitId)
			vx,vy,vz,v = spGetUnitVelocity(unitId)
			-- not moving much, push them down
			if (vx and vy >= -0.1 and v < 0.2) then
				spAddUnitImpulse(unitId,dx * factor,dy-1 * factor,dz * factor)
			end
			
			--spSetUnitVelocity(unitId,dx * factor,dy-1 * factor,dz * factor)
		else
			--dx,dy,dz = spGetUnitDirection(unitId)
			--spSetUnitVelocity(unitId,0,0,0)
			--spSetUnitDirection(unitId,dx,0,dz)
		end
	end

	-- update "on fire" label for all units
	for _,unitID in pairs(spGetAllUnits()) do
		if(unitBurningTable[unitID]) then
			spSetUnitRulesParam(unitID,"on_fire",1,UNIT_RP_PUBLIC_TBL)
		else
			spSetUnitRulesParam(unitID,"on_fire",0,UNIT_RP_PUBLIC_TBL)
		end
	end

	-- handle target damage, for test purposes
	if (n%1800 == 0) then
		if targetDamage > 0 then
			Spring.Echo(n.." dps="..(targetDamage / 60))
			targetDamage = 0
		end
	end
	
	
	-- process area shield visibility
	for unitID,data in pairs(largeShieldUnits) do
		local allyTeamVisibility = data.allyTeamVisibility 
		-- actually check proximity only once per second
		if (n%30 == 0) then
			-- assume invisible
			for aId,_ in pairs(allyTeamVisibility) do
				allyTeamVisibility[aId] = false
			end 
			_,_,_,x,_,z = spGetUnitPosition(unitID,true)
			for _,uId in pairs( spGetUnitsInCylinder( x, z, data.radius )) do
				-- if there's an enemy within avg ground-LOS + shield radius of it
				-- make it visible
				local aId = spGetUnitAllyTeam(uId)
				if not allyTeamVisibility[aId] then
					allyTeamVisibility[aId] = true
				end
			end 
		end
		
		-- enforce visiblility if necessary
		for aId,visible in pairs(allyTeamVisibility) do
			if visible then
				--Spring.Echo(n.." : area shield "..unitID.." is visible to allyTeam "..aId)
				spSetUnitLosMask( unitID, aId, 15)
				spSetUnitLosState( unitID, aId, 15)
			else
				spSetUnitLosMask( unitID, aId, 0)
			end
		end 
	end
	

	if (n%STEP_DELAY ~= 0) then
		return
	end

	-- clear burn and storm aoe dmg counter
	unitBurningDPStepTable = {}
	unitStormDPStepTable = {}
		
	-- process shield colvol changes for shielded units
	for unitID,data in pairs(unitShieldColvolTable) do
		local shieldEnabled,shieldPower = spGetUnitShieldState(unitID)
		if shieldEnabled and shieldPower > 100 then
			SetColvol(unitID, COLVOL_SHIELD)
		else
			SetColvol(unitID, COLVOL_BASE)
		end
	end


	-- process burn debuff for burning units
	local dmg, radius = 0
	
	for unitID,data in pairs(unitBurningTable) do	
		_,_,_,x,y,z = spGetUnitPosition(unitID,true)
		
		if y and y > -10 then
			-- apply damage
			armorType = unitArmorTypeTable[data.unitDefID]
			if (armorType == ARMOR_H) then
				dmg = FIRE_DMG_PER_STEP_HEAVY
			else
				dmg = FIRE_DMG_PER_STEP
			end
			spAddUnitDamage(unitID,dmg,0,data.attackerID,fireBurnDOTWeaponDefId)
	
			-- spawn CEG
			radius = spGetUnitRadius(unitID)
			if radius ~= nil then
				h = radius / 3
				spSpawnCEG(BURNING_CEG, x - h + 2*h*random(), y+h, z - h + 2*h*random(), 0, 1, 0,radius ,radius)
				spPlaySoundFile(BURNING_SOUND, 1, x, y+h, z)
		
				-- update table
				if (data.steps > 1) then
					data.steps = data.steps - 1
					unitBurningTable[unitID] = data
				else
					unitBurningTable[unitID] = nil
				end
			else
				unitBurningTable[unitID] = nil
			end
		else
			unitBurningTable[unitID] = nil
		end
	end
	
	-- process unit XP gain
	local xp = 0
	for unitId,addedXP in pairs(unitXPTable) do  
		xp = spGetUnitExperience(unitId)
		if (xp) then
			spSetUnitExperience(unitId, xp + addedXP)
		end
		
		unitXPTable[unitId] = nil
	end

	-- mark stunned aircraft
	local stunned = false
	for unitId,_ in pairs(aircraftTable) do  
		_,stunned,_ = spGetUnitIsStunned(unitId)
		if (stunned) then
			stunnedAircraftTable[unitId] = true
		else
			stunnedAircraftTable[unitId] = nil			
		end
	end
end

-- cleanup and/or spawn extra effects when some units are destroyed
function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)

	-- store damage modifier from upgrades, for projectiles in flight
	local dmgMod = spGetUnitRulesParam(unitID, "upgrade_damage")
	if (dmgMod) then
		dmgModDeadUnits[unitID] = dmgMod
	else 
		dmgModDeadUnits[unitID] = 0
	end

	-- remove entries from tables when unit is destroyed
	if largeShieldUnits[unitID] ~= nil then
		largeShieldUnits[unitID] = nil
	end
	if baseUnitColvolTable[unitID] then
		baseUnitColvolTable[unitID] = nil
	end
	if unitBurningTable[unitID] ~= nil then
		unitBurningTable[unitID] = nil
	end
	if aircraftTable[unitID] ~= nil then
		aircraftTable[unitID] = nil
	end
	if stunnedAircraftTable[unitID] ~= nil then
		stunnedAircraftTable[unitID] = nil
	end	
	if unitXPTable[unitID] ~= nil then
		unitXPTable[unitID] = nil
	end
	if damagedUnitFrameTable[unitID] ~= nil then
		damagedUnitFrameTable[unitID] = nil
	end
	if cloakDisruptedUnitFrameTable[unitID] ~= nil then
		cloakDisruptedUnitFrameTable[unitID] = nil
	end
	
	-- spawn a fireball when some units die	
	local fireballName = deathFireballDefIds[unitDefID]
	if fireballName then
		x,y,z = spGetUnitPosition(unitID)
		_,_,_,_,bp = spGetUnitHealth(unitID)

		if bp > 0.999 then
			local createdId = Spring.SpawnProjectile(WeaponDefNames[fireballName].id,{
				["pos"] = {x,y,z},
				["end"] = {x,0,z},
				["speed"] = {0,-5,0},
				["owner"] = unitID
			})
		end
	end
end

-- if unit has active shield with power > 0, drain damage from shield first instead of going directly to hp
function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
	-- disable scoper damage
	if(scoperBeaconDefIds[attackerDefID]) then
		return 0
	end

	-- drone beacon
	if checkDroneBeaconTargetting(attackerID,weaponDefID,unitID) == 1 then
		return 0
	end
			
	-- disable bass self-damage
	if (weaponDefID == disruptorWaveEffectWeaponDefId and unitDefID == disruptorWaveUnitDefId) then
		return 0
	end
	-- disable magnetar self-damage
	if ( unitDefID == magnetarUnitDefId and (weaponDefID == magnetarWeaponDefId or weaponDefID == magnetarAuraWeaponDefId)) then
		return 0,0	
	end
	-- disable upgrade finished effect self-damage
	if (upgradeFinishedDefIds[weaponDefID]) then
		return 0
	end
	
	-- disables unit collision damage
	if (weaponDefID == -3) then
		return 0
	end
	
	-- sharply reduce self-damage in general
	if (unitID == attackerID) then
		damage = damage * 0.33	-- SELF_DAMAGE_FACTOR
	end
	
	-- reduce damage from non-water weapons' AOE to submerged units
	if checkSubmergedSurfaceBlastDampening(unitID,weaponDefID) then
		damage = damage * SUBMERGED_SURFACE_BLAST_DMG_FACTOR
	end
	
	-- long range rockets that were shot down deal reduced dmg to others in flight
	if checkPreventLRRChainExploding(unitDefID,weaponDefID) then
		damage = damage * LONG_RANGE_ROCKET_CHAIN_DAMAGE_FACTOR
		--Spring.Echo("Chain damage reduced "..damage)
	end
	
	-- show animation for AOE damage from disruptor weapons 
	if (weaponDefID == disruptorWaveEffectWeaponDefId or weaponDefID == magnetarWeaponDefId or weaponDefID == magnetarAuraWeaponDefId) then
		local showEffect = false
		if weaponDefID == magnetarAuraWeaponDefId then
			if random() < 0.2 then
				showEffect = true
			end
		else 
			showEffect = true
		end
		
		if (showEffect) then
			_,_,_,x,y,z = spGetUnitPosition(unitID,true)
			if x ~= nil then
				spSpawnCEG(EMP_CEG, x - 10 + random(20), y, z - 10 + random(20), 0, 1, 0,30 ,30)
				spPlaySoundFile(EMP_SOUND, 0.5, x, y, z)
			end
		end
	end
	 
	-- increase damage due to veteran status for most weapons
	-- to compensate for not getting reload time reduction
	local xpMod = 1 
	if (expDmgScalingWeaponDefIds[weaponDefID]) then
		if attackerID and attackerID > 0 then
			local xp = spGetUnitExperience(attackerID)
			xpMod = 1
            if xp and xp > 0 then
        		xpMod = 1+0.35*(xp/(xp+1))
            end		 
        	damage = damage	* xpMod
        	--Spring.Echo("xpMod : "..xpMod)
		end
	end

	-- increase damage based on attacker's damage modifiers, if any
	-- do this only for weapons which weren't directly upgraded
	local dmgMod = 0
	if attackerID and attackerID > 0  and notDirectlyUpgradedWeaponDefIds[weaponDefID] then 
		if dmgModDeadUnits[attackerID] then
			dmgMod = dmgModDeadUnits[attackerID]
		else
			dmgMod = spGetUnitRulesParam(attackerID, "upgrade_damage")
		end
		if dmgMod and dmgMod ~= 0 then
			damage = damage	* (1 + dmgMod)
			--Spring.Echo("dmgMod : "..(1+dmgMod))
		end
	end
	
	local armorType = unitArmorTypeTable[unitDefID]
	local applyHAOEDmgReduction = false
	if armorType == ARMOR_H then
		local wDmg = weaponDirectHitDmgPerArmorType[weaponDefID]
		if wDmg and wDmg[ARMOR_H] then
			local directHitDmg = wDmg[ARMOR_H] * (1+dmgMod)*xpMod
			if damage < INDIRECT_DMG_THRESHOLD * directHitDmg then
				--Spring.Echo("AOE HIT : dmg="..damage.." dhdmg="..directHitDmg.." fraction="..(damage/directHitDmg))
				applyHAOEDmgReduction = true
			end
		end
	end
	
	-- add/refresh burning debuff
	if ( burningEffectWeaponDefIds[weaponDefID] and (not burningImmuneDefIds[unitDefID])) then
		unitBurningTable[unitID] = {steps = FIRE_DMG_STEPS,unitDefID = unitDefID, attackerID = attackerID}
	end
	
	-- limit AOE dps of lingering area effects
	if ( burningAOEPerStepWeaponDefIds[weaponDefID]) then
		-- limit fire aoe damage
		local finalDamage = damage
		
		local oldDmg = unitBurningDPStepTable[unitID]
		local newDmg = 0
		if oldDmg == nil then
			oldDmg = 0
		end
		
		newDmg = oldDmg + finalDamage
		
		if oldDmg < FIRE_AOE_DMG_MAX_PER_STEP and newDmg > FIRE_AOE_DMG_MAX_PER_STEP then
			finalDamage = FIRE_AOE_DMG_MAX_PER_STEP - oldDmg
		elseif newDmg > FIRE_AOE_DMG_MAX_PER_STEP then
			finalDamage = 0
		end
		
		--if newDmg > FIRE_AOE_DMG_MAX_PER_STEP then
		--	Spring.Echo("Fire AOE damage prevented : threshold="..(FIRE_AOE_DMG_MAX_PER_STEP*5).." total="..(newDmg*5))
		--end
		
		unitBurningDPStepTable[unitID] = newDmg
		
		damage = finalDamage 
	
	elseif ( stormAOEPerStepWeaponDefIds[weaponDefID] ) then 
		-- limit storm aoe damage
		local finalDamage = damage
		
		local oldDmg = unitStormDPStepTable[unitID]
		local newDmg = 0
		if oldDmg == nil then
			oldDmg = 0
		end
		
		newDmg = oldDmg + finalDamage
		
		if oldDmg < STORM_AOE_DMG_MAX_PER_STEP and newDmg > STORM_AOE_DMG_MAX_PER_STEP then
			finalDamage = STORM_AOE_DMG_MAX_PER_STEP - oldDmg
		elseif newDmg > STORM_AOE_DMG_MAX_PER_STEP then
			finalDamage = 0
		end
		
		--if newDmg > STORM_AOE_DMG_MAX_PER_STEP then
		--	Spring.Echo("Storm AOE damage prevented : threshold="..(STORM_AOE_DMG_MAX_PER_STEP*5).." total="..(newDmg*5))
		--end
		
		unitStormDPStepTable[unitID] = newDmg
		damage = finalDamage 
	end

	-- get unit shield status
	local shieldEnabled,oldShieldPower = spGetUnitShieldState(unitID)
	if shieldEnabled and oldShieldPower > 0 and not (largeShieldUnitDefIds[unitDefID] == true) and (not ignoreShieldWeaponDefIds[weaponDefID]) then
		local newShieldPower = oldShieldPower
		local damageAbsorbedByShield = 0
		local hitpower = weaponHitpowerTable[weaponDefID]
		local correctedDamage = damage
		local factor = 1
		
		if (hitpower ~= nil and armorType ~= nil) then
			if (hitpower == POWER_L and armorType == ARMOR_H) then
		    	factor = 4
			elseif (hitpower == POWER_L and armorType == ARMOR_M) then
				factor = 2
			elseif (hitpower == POWER_M and armorType == ARMOR_H) then
				factor = 2
			end
			correctedDamage = damage * factor
		end
	  
		-- calculate how much dmg the shield absorbed
		if correctedDamage < oldShieldPower then
			newShieldPower = oldShieldPower - correctedDamage
			damageAbsorbedByShield = correctedDamage
	    else 
	    	newShieldPower = 0
			damageAbsorbedByShield = oldShieldPower 
		end

		-- update shield state
		spSetUnitShieldState(unitID, newShieldPower)

		-- Echo("unit " .. unitID .. " ("..armorType.. ") : shield absorbed " .. math.floor(damageAbsorbedByShield) .. " damage ("..hitPower.. ") ".. math.floor(oldShieldPower) .. " -> " .. math.floor(newShieldPower).. " unit takes "..math.max(math.ceil((correctedDamage - damageAbsorbedByShield)/factor),0))
		damage = math.max(math.ceil((correctedDamage - damageAbsorbedByShield)/factor),0)
	end
	
	
	-- apply H aoe dmg reduction, if relevant
	if applyHAOEDmgReduction then
		damage = damage * H_ARMOR_INDIRECT_DMG_MULT
	end
	
	-- decrease damage based on defender's hp modifiers, if any 
	defMod = spGetUnitRulesParam(unitID, "upgrade_hp")
	if defMod and defMod ~= 0 then
		damage = damage	/ (1 + defMod)
		--Spring.Echo("takes less dmg : "..(1/ (1 + defMod)))
	end
	
	-- adds % of paralyzer damage as normal damage to HP
	if (paralyzer) then
		spAddUnitDamage(unitID,damage*PARALYZE_DAMAGE_FACTOR,0,attackerID)

		-- units being transported do not take paralyze damage to avoid a bug where they'd reload and start firing!
		if spGetUnitTransporter(unitID) ~= nil then
			return 0,0
		end
	
		-- amplify paralyzer damage for lower hp units
		health,maxHealth,_,_,_ = spGetUnitHealth(unitID)
		local factor = 1 + (1 - max(health,0)/maxHealth) * PARALYZE_MISSING_HP_FACTOR
		damage = damage * factor
	end
	
	-- immobilized units are considered "stuck" and can't be pushed around
	if GG.mobilityModifier and GG.mobilityModifier[unitID] == 0 then
		return damage, 0
	end
	
	return damage
end

-- handle XP modifier when units take damage from enemies
function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
	if (unitDefID == targetDefId) then
		targetDamage = targetDamage + damage
		return
	end

	if (attackerTeam and (not spAreTeamsAllied(unitTeam,attackerTeam))) and (not paralyzer) then
		-- add entry to table
		if unitXPTable[unitID] == nil then
			unitXPTable[unitID] = 0
		end
		
		-- assign experience to unit that took damage
		health,maxHealth,_,_,_ = spGetUnitHealth(unitID) 
		frac = damage / maxHealth
		if frac > 1 then
			frac = 1
		end 
		
		unitXPTable[unitID] = unitXPTable[unitID] + frac * UNIT_DAMAGE_TAKEN_XP
		if attackerID > 0 then
			-- add entry to table
			if unitXPTable[attackerID] == nil then
				unitXPTable[attackerID] = 0
			end

			-- assign experience to unit that dealt damage		
			dealtDef = UnitDefs[attackerDefID]
			takenDef = UnitDefs[unitDefID]
			if (dealtDef.power > 0) then
				frac = (takenDef.power / dealtDef.power) * frac
				unitXPTable[attackerID] = unitXPTable[attackerID] + frac * UNIT_DAMAGE_DEALT_XP
			end
		end
	end
	if (damage > DECLOAK_DAMAGE_THRESHOLD ) then
		cloakDisruptedUnitFrameTable[unitID] = spGetGameFrame()
		damagedUnitFrameTable[unitID] = spGetGameFrame()
		--Spring.Echo("UNIT DAMAGED unitId="..unitID.." f="..spGetGameFrame())
	end 
end

function gadget:AllowUnitBuildStep(builderID, builderTeam, unitID, unitDefID, part)
	-- Spring.Echo("STEP builderId="..builderID.." unitId="..unitID.." part="..part)
	
	cloakDisruptedUnitFrameTable[builderID] = spGetGameFrame()
	-- check if building is allowed
	buildBlocked = spGetUnitRulesParam(unitID,"build_block")
	if part > 0 and buildBlocked and buildBlocked == 1 then
		return false
	end 
	
	-- if unit got damaged recently, deny half of the build steps
	f = spGetGameFrame()
	damagedFrame = damagedUnitFrameTable[unitID] 
	if damagedFrame and (f - damagedFrame < DAMAGE_REPAIR_DISRUPT_FRAMES) then
		if f%2 == 0 then
			return false
		end
	end

	-- reimburse excess metal retrieved from reclaiming units
	-- fix for exploit where players with bonus could get extra metal from building and reclaiming their units
	if (part < 0) then
		_,_,_,_,_,_,incomeMult = spGetTeamInfo(builderTeam)
		if (incomeMult and incomeMult > 1) then
			metalAmount = UnitDefs[unitDefID].metalCost * part * (1-incomeMult) * UNIT_RECLAIM_FACTOR
			--Spring.Echo("reclaiming "..part.." bonus="..incomeMult.." m="..metalAmount)
			spUseUnitResource(builderID,"m",metalAmount)
		end
	end
	return true
end


function gadget:AllowFeatureBuildStep(builderID, builderTeam, featureID, featureDefID, part)
	-- reimburse excess metal retrieved from reclaiming features when bonus resource multiplier is set
	if (part < 0) then
		_,_,_,_,_,_,incomeMult = spGetTeamInfo(builderTeam)
		if (incomeMult and incomeMult > 1) then
			metalAmount = FeatureDefs[featureDefID].metal * part * (1-incomeMult)
			--Spring.Echo("reclaiming "..part.." bonus="..incomeMult.." m="..metalAmount)
			spUseUnitResource(builderID,"m",metalAmount)
		end
	end
	return true
end

-- assume weapons are being tracked, mark unit to disrupt cloak
function gadget:ProjectileCreated(proID, proOwnerID, weaponDefID)
	if (proOwnerID and (not burningAOEPerStepWeaponDefIds[weaponDefID])) then
		cloakDisruptedUnitFrameTable[proOwnerID] = spGetGameFrame() 
	end
end

-- prevent units from cloaking a few seconds after being disrupted or doing something disrupting
function gadget:AllowUnitCloak(unitId,enemyId)
	-- if there's a nearby enemy within cloak radius, decloak
	if enemyId ~= nil and (not scoperBeaconDefIds[spGetUnitDefID(enemyId)]) then
		return false
	end

	if (cloakDisruptedUnitFrameTable[unitId] and cloakDisruptedUnitFrameTable[unitId] + RECLOAK_DELAY_FRAMES > spGetGameFrame()  ) then
		return false
	end
	
	local unitDefId = unitId and spGetUnitDefID(unitId)
	local ud = unitDefId and UnitDefs[unitDefId]
	if not ud then
		return false
	end

	local stunnedOrBeingBuilt = spGetUnitIsStunned(unitId)
	if stunnedOrBeingBuilt then
		return false
	end

	-- if it's on water, decloak
	local submergedDepth = spGetUnitRulesParam(unitId, "submergedDepth")
	if submergedDepth and submergedDepth > 5 then
		return false
	end

	local jumpState = spGetUnitRulesParam(unitId, "is_jumping")
	if jumpState and jumpState == 1 then
		return false
	end
	
	-- if it's going to return true, apply energy drain
	-- (it stopped worked on 104.0.1 xxxx maintenance)
	local speed = select(4, spGetUnitVelocity(unitId))
	local moving = speed and speed > CLOAK_MOVING_THRESHOLD
	local cost = moving and ud.cloakCostMoving or ud.cloakCost

	
	if not spUseUnitResource(unitId, "e", cost/2) then -- SlowUpdate happens twice a second.
		return false
	end
	
	return true
end
