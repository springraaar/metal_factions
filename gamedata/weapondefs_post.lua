
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
		if (wd.weapontype == "BeamLaser" ) then
			wd.heightmod = 0.5		-- default was 1.0
		end
		if (wd.weapontype == "Cannon" or wd.weapontype == "EmgCannon" ) then
			wd.heightmod = 0.5			-- default was 0.8
			wd.heightboostfactor = 1.1		-- default was -1.0
		end
		
		-- change intensity for EMG cannons, change weaponType
		if wd.weapontype == "EmgCannon" then
			wd.intensity = 0.1
			wd.weapontype = "Cannon"
		end
	
		--wd.cylindertargeting = 1
		--wd.avoidground=0
	end
	
	-- force unit to retry the aim animation more often 
	-- without this it would only run twice per second (?)
	-- wd.allownonblockingaim = 1
	if (wd.tolerance ~= nil and wd.range ~= nil) then
		wd.firetolerance = wd.tolerance
	end
end
