--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local modOptions
if (Spring.GetModOptions) then
  modOptions = Spring.GetModOptions()
end


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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Metal Bonus
--

if (modOptions and modOptions.metalmult) then
  for name in pairs(UnitDefs) do
    local em = UnitDefs[name].extractsmetal
    if (em) then
      UnitDefs[name].extractsmetal = em * modOptions.metalmult
    end
  end
end
--------------------------------------------------------------------------------
-- Hitpoint Bonus
--

if (modOptions and modOptions.hitmult) then
  for name in pairs(UnitDefs) do
    local em = UnitDefs[name].maxdamage
    if (em) then
      UnitDefs[name].maxdamage = em * modOptions.hitmult 
    end
  end
end
--------------------------------------------------------------------------------
-- Velocity Bonus
--

if (modOptions and modOptions.velocitymult) then
  for name in pairs(UnitDefs) do
    local em = UnitDefs[name].maxvelocity
    if (em) then
      UnitDefs[name].maxvelocity = em * modOptions.velocitymult
    end
  end
end
--------------------------------------------------------------------------------
-- Build Bonus
--

if (modOptions and modOptions.workermult) then
  for name in pairs(UnitDefs) do
    local em = UnitDefs[name].workertime
    if (em) then
      UnitDefs[name].workertime = em * modOptions.workermult 
    end
  end
end
--------------------------------------------------------------------------------
-- Energy Bonus
--

if (modOptions and modOptions.energymult) then
  for name in pairs(UnitDefs) do
    local em = UnitDefs[name].energymake
    if (em) then
      UnitDefs[name].energymake = em * modOptions.energymult
    end
  end
end

if (modOptions and modOptions.energymult) then
  for name in pairs(UnitDefs) do
    local em = UnitDefs[name].totalEnergyOut
    if (em) then
      UnitDefs[name].totalEnergyOut = em * modOptions.energymult
    end
  end
end

local function disableunits(unitlist)
  for name, ud in pairs(UnitDefs) do
    if (ud.buildoptions) then
      for _, toremovename in ipairs(unitlist) do
        for index, unitname in pairs(ud.buildoptions) do
          if (unitname == toremovename) then
            table.remove(ud.buildoptions, index)
          end
        end
      end
    end
  end
end

local reducedDecalSizeUnits = {
	aven_wind_generator = true,
	gear_wind_generator = true,
	claw_wind_generator = true
}

-- unitdef tweaking
if (true) then
	for name,unitDef in pairs(UnitDefs) do

		local mv = unitDef.maxvelocity
		local ac = unitDef.acceleration
		local sd = unitDef.sightdistance

		if (sd) then

			-- airlos = los, and increase los 20%
			sd = sd * 1.2
			unitDef.losemitheight = 80
			unitDef.radaremitheight = 120
			unitDef.sightdistance = sd
			unitDef.airsightdistance = sd

			-- level ground beneath structures
			unitDef.levelground = true

			-- disable radar inaccuracy
			unitDef.istargetingupgrade = true
		end

		-- increase slope tolerance for buildings
		unitDef.maxslope = 30
	
		-- standardize idleautoheal and idletime
		-- set to 0, done through gadget now
		unitDef.idletime = 0
		unitDef.idleautoheal = 0
		
		
		if (mv and mv > 0) then
			-- disable transporting enemy units
			unitDef.transportbyenemy = 0
			
			-- disable unit tracks
			unitDef.leavetracks = 0
  
			-- disable speed penalty when turning
			unitDef.turninplaceanglelimit = 90.0
			unitDef.turninplacespeedlimit = mv

			-- make sure low acceleration units are able to beat drag
			local minAcceleration = mv / 80
			if ( tonumber(ac) < minAcceleration ) then
				unitDef.acceleration = minAcceleration
			end
			
			-- remove excessive brakerate from aircraft
			local canFly = unitDef.canfly
			local br = tonumber(unitDef.brakerate)
			if (canFly) then
				if (br > 0.5) then
					unitDef.brakerate = br / 5
				end
			end
		else
			local factionBuilding = false
			
			if string.sub(name,1,5) == "aven_" then
				unitDef.buildinggrounddecaltype = "building_aven.dds"
				factionBuilding = true
			elseif string.sub(name,1,5) == "gear_" then  
				unitDef.buildinggrounddecaltype = "building_gear.dds"
				factionBuilding = true
			elseif string.sub(name,1,5) == "claw_" then
				unitDef.buildinggrounddecaltype = "building_claw.dds"
				factionBuilding = true
			elseif string.sub(name,1,7) == "sphere_" then
				unitDef.buildinggrounddecaltype = "building_sphere.dds"
				factionBuilding = true
			end
			local fpMod = 1.5
			if (factionBuilding == true and not (unitDef.floater or unitDef.waterline)) then
				unitDef.usebuildinggrounddecal = true
				if (reducedDecalSizeUnits[name] ) then
					fpMod = 0.85
				end
				unitDef.buildinggrounddecalsizex = unitDef.footprintx * fpMod
				unitDef.buildinggrounddecalsizey = unitDef.footprintz * fpMod
				unitDef.buildinggrounddecaldecayspeed = 0.01
			end
		end
	end
end
