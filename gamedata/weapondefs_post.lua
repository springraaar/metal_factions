
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
-- NOTE : property names are lower case
for wdName, wd in pairs(WeaponDefs) do

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
		-- change visual intensity for EMG cannons, change weaponType
		if wd.weapontype == "EmgCannon" then
			wd.intensity = 0.1
			wd.weapontype = "Cannon"
		end
		
		
		if (noVerticalRangeBoostWeapons[wdName]) then
			wd.heightmod = 1
			wd.heightboostfactor = 0
		elseif (wd.weapontype == "BeamLaser") then
			wd.heightmod = 1.0		-- default was 1.0
			-- fading effect for beams proportional to damage
			if wd.damage and wd.damage.default then
				if not wd.beamttl then
					local defaultDamage = tonumber(wd.damage.default)
					if (wdName:lower():find("_beam",1,true)) then
						wd.beamttl = 4 + defaultDamage / 130
					else
						wd.beamttl = 0 + defaultDamage / 130
					end
				end
				
				if not wd.beamdecay then
					wd.beamdecay = 0.9
				end
				
				-- update thickness and outer layer brightness, increase beamtime
				if (wdName:lower():find("_beam",1,true)) then
					-- sphere lightning beams
					wd.thickness=tonumber(wd.thickness)*1.8
					wd.corethickness=0.55
					wd.laserflaresize = 1
					if wd.rgbcolor then
						local colorStr = ""
						for w in wd.rgbcolor:gmatch("%S+") do 
							colorStr = colorStr.." "..(tonumber(w)*1.0)
						end
						wd.rgbcolor = colorStr
					end
					wd.texture2 = "light"
				elseif (wdName:lower():find("_heatray",1,true)) then
					-- gear heatrays
					wd.thickness=tonumber(wd.thickness)*6
					wd.corethickness=0.9
					wd.laserflaresize = 1.8
					if wd.rgbcolor then
						local colorStr = ""
						for w in wd.rgbcolor:gmatch("%S+") do 
							colorStr = colorStr.." "..(tonumber(w)*0.7)
						end
						wd.rgbcolor = colorStr
					end
				else
					-- other beamlasers
					wd.thickness=tonumber(wd.thickness)*2.5
					wd.corethickness=0.25
					wd.laserflaresize = 2.5
					-- make outer color a function of the core color
					if wd.rgbcolor2 then
						local colorStr = ""
						for w in wd.rgbcolor2:gmatch("%S+") do 
							colorStr = colorStr.." "..(math.max(tonumber(w)*0.55-0.1,0.165))
						end
						wd.rgbcolor = colorStr
					end
					-- add 1 frame to short beam times
					local bt = tonumber(wd.beamtime)
					if bt < 0.1 then
						wd.beamtime = bt + 0.034
					end
				end
			end
		elseif (wd.weapontype == "LaserCannon") then
			wd.heightmod = 1.0		-- default was 1.0
		elseif (wd.weapontype == "Cannon" or wd.weapontype == "EmgCannon" ) then
			--if wd.range and tonumber(wd.range) > 380 then
				wd.heightmod = 0.5			-- default was 0.8
			--else
			--	wd.heightmod = 1
			--end

			-- set heightboostfactor to let them hit further against lower ground to compensate for range reduction against higher ground
			-- only for gravity-affected projectiles with curved trajectories
			if (not wd.mygravity and not wd.heightboostfactor) then
				wd.heightboostfactor=0.6
			end
			-- override mygravity for cannons if not specified
			if (not wd.mygravity) then
				wd.mygravity = 0.17
			end
			
			if (wdName:lower():find("_emg",1,true)) or (wdName:lower():find("_hemg",1,true)) then
				wd.size = tonumber(wd.size) * 2
			end
		elseif (wd.weapontype == "MissileLauncher" ) then
			wd.heightmod = 0.5			-- default was 0.8
		elseif (wd.weapontype == "StarburstLauncher" ) then
			wd.cylindertargeting = 2
		end

		-- increase projectile velocity (more relevant for slow projectiles, especially if they're long ranged)
		if wd.weaponvelocity and wd.range then
			wd.weaponvelocity=tonumber(wd.weaponvelocity)*1.05+tonumber(wd.range)*0.03+25
		end

		-- range compensation for lasercannons due to engine bug
		-- https://springrts.com/mantis/view.php?id=6384
		if (wd.weapontype == "LaserCannon") then
			local oRange = tonumber(wd.range)
			if oRange > 0 then
				wd.range = oRange + 20
			end 
		end
	end
	

	-- force unit to retry the aim animation more often 
	-- without this it would only run twice per second (?)
	-- wd.allownonblockingaim = 1
	if (wd.tolerance ~= nil and wd.range ~= nil) then
		wd.firetolerance = math.max(tonumber(wd.tolerance),8000)
	end
	if not (wd.customparams) then
		wd.customparams = {}
	end
	if not (wd.customparams.reaimtime) then
		wd.customparams.reaimtime = 7
	end

	if wd.areaofeffect then
		local aoe = tonumber(wd.areaofeffect)
		local edge = tonumber(wd.edgeeffectiveness) or 0

		-- set minimum aoe to 12
		if aoe < 10 then
			wd.areaofeffect = 12
		end

		-- increase edge effectiveness by 0.2
		if edge < 0.8 then
			wd.edgeeffectiveness = edge + 0.2
		end

		-- set explosion speed
		-- defaults are about 3-4 for most cases
		if (not wd.explosionspeed) then
			wd.explosionspeed = 7 + aoe*0.02
		end
	end

	if wd.weapontype == "Shield" then
		wd.visibleshield = false
		wd.visibleshieldhitframes = 0
		wd.visibleshieldrepulse = false
	end

	-- TODO disabled for now because it'd make walls untargetable
	--wd.avoidNeutral = 1

	if (wd.customparams.hitpower) and tonumber(wd.customparams.hitpower) == 1 and not wd.impulsefactor then
		wd.impulsefactor = 0.3
	end

	-- disable engine explosion scars
	-- TODO enable them eventually?
	wd.explosionscar = false


	-- make weapon sounds relatively louder
	processSoundDefaults(wd)
end