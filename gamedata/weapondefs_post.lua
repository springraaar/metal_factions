
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    weapondefs_post.lua
--  brief:   weaponDef post processing
--  author:  Dave Rodgers
--
--  Copyright (C) 2008.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function isbool(x)   return (type(x) == 'boolean') end
local function istable(x)  return (type(x) == 'table')   end
local function isnumber(x) return (type(x) == 'number')  end
local function isstring(x) return (type(x) == 'string')  end

local function tobool(val)
  local t = type(val)
  if (t == 'nil') then
    return false
  elseif (t == 'boolean') then
    return val
  elseif (t == 'number') then
    return (val ~= 0)
  elseif (t == 'string') then
    return ((val ~= '0') and (val ~= 'false'))
  end
  return false
end

local noVerticalRangeBoostWeapons = {
	gear_u1commander_flamethrower = true,
	gear_pyro_flamethrower = true,
	gear_heater_flamethrower = true,
	gear_burner_flamethrower = true,
	gear_cube_flamethrower = true,
	claw_sword_laser = true,
	claw_u6commander_laser = true,
	claw_knife_laser = true

}

local function processSoundDefaults(wd)
	local forceSetVolume = (not wd.soundstartvolume) or (not wd.soundhitvolume)
	if not forceSetVolume then
		return
	end
	local defaultDamage = wd.damage and wd.damage.default
	if (not defaultDamage) then
		wd.soundstartvolume = 1
		wd.soundhitvolume = 1
		return
	end
	local soundVolume = 1.4 + math.sqrt(defaultDamage * 0.1) * 0.1
	if (not wd.soundstartvolume) then
		wd.soundstartvolume = soundVolume
	end
	if (not wd.soundhitvolume) then
		wd.soundhitvolume = soundVolume
	end
end

-- weapondef tweaking
for wdName, wd in pairs(WeaponDefs) do
	local hb = wd.heightBoostFactor
	
	-- auto detect ota weapontypes
	if (wd.weapontype==nil) then
		local rendertype = tonumber(wd.rendertype) or 0
		if (tobool(wd.dropped)) then
			wd.weapontype = "AircraftBomb"
		elseif (tobool(wd.vlaunch)) then
			wd.weapontype = "StarburstLauncher"
		elseif (tobool(wd.beamlaser)) then
			wd.weapontype = "BeamLaser"
		elseif (tobool(wd.isshield)) then
			wd.weapontype = "Shield"
		elseif (tobool(wd.waterweapon)) then
			wd.weapontype = "TorpedoLauncher"
		elseif (wdName:lower():find("disintegrator",1,true)) then
			wd.weapontype = "DGun"
		elseif (tobool(wd.lineofsight)) then
			if (rendertype==7) then
				wd.weapontype = "LightningCannon"
			elseif (wd.model and wd.model:lower():find("laser",1,true)) then
				wd.weapontype = "LaserCannon"
			elseif (tobool(wd.beamweapon)) then
				wd.weapontype = "LaserCannon"
			elseif (tobool(wd.smoketrail)) then
				wd.weapontype = "MissileLauncher"
			elseif (rendertype==4 and tonumber(wd.color)==2) then
				wd.weapontype = "EmgCannon"
			elseif (rendertype==5) then
				wd.weapontype = "Flame"
			--elseif(rendertype==1) then
			--  wd.weapontype = "MissileLauncher"
			else
				wd.weapontype = "Cannon"
			end
		else
			wd.weapontype = "Cannon"
		end
	end

	-- reduce cratering
	if (not wd.cratermult) then
		wd.cratermult = 0.1
	end
	if (wdName ~= "sphere_magnetar_blast") then
		if (noVerticalRangeBoostWeapons[wdName]) then
			wd.heightmod = 1
			wd.heightboostfactor = 0
		elseif (wd.weapontype == "BeamLaser" ) then
			wd.heightmod = 0.5		-- default was 1.0
		elseif (wd.weapontype == "Cannon" or wd.weapontype == "EmgCannon" ) then
			wd.heightmod = 0.5			-- default was 0.8
			wd.heightboostfactor = 1.1		-- default was -1.0
		elseif (wd.weapontype == "MissileLauncher" or wd.weapontype == "StarburstLauncher" ) then
			wd.cylindertargeting = 2
			wd.heightboostfactor = 1.1		-- default was -1.0
		end
		
		-- change visual intensity for EMG cannons, change weaponType
		if wd.weapontype == "EmgCannon" then
			wd.intensity = 0.1
			wd.weapontype = "Cannon"
		end
	end
	
	-- set explosion speed
	-- defaults are about 3-4 for most cases
	if (not wd.explosionSpeed) then
		wd.explosionSpeed = 8
	end

	-- force unit to retry the aim animation more often 
	-- without this it would only run twice per second (?)
	-- wd.allownonblockingaim = 1
	if (wd.tolerance ~= nil and wd.range ~= nil) then
		wd.firetolerance = 32000 -- wd.tolerance * 0.5
	end
	if not (wd.customparams) then
		wd.customparams = {}
	end
	if not (wd.customparams.reaimtime) then
		wd.customparams.reaimtime = 10
	end

	-- make weapon sounds relatively louder
	processSoundDefaults(wd)
end