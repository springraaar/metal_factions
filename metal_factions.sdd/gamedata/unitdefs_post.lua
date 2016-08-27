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

-- unitdef tweaking
if (true) then
	for name in pairs(UnitDefs) do

		local mv = UnitDefs[name].maxvelocity
		local ac = UnitDefs[name].acceleration
		local sd = UnitDefs[name].sightdistance

		if (sd) then

			-- airlos = los, and increase los 20%
			sd = sd * 1.2
			UnitDefs[name].losemitheight = 80
			UnitDefs[name].radaremitheight = 120
			UnitDefs[name].sightdistance = sd
			UnitDefs[name].airsightdistance = sd

			-- level ground beneath structures
			UnitDefs[name].levelground = true

			-- disable radar inaccuracy
			UnitDefs[name].istargetingupgrade = true
		end

		-- increase slope tolerance for buildings
		UnitDefs[name].maxslope = 30
	
		-- standardize idleautoheal and idletime
		-- set to 0, done through gadget now
		UnitDefs[name].idletime = 0
		UnitDefs[name].idleautoheal = 0
		
		
		if (mv) then
			-- disable transporting enemy units
			UnitDefs[name].transportbyenemy = 0
			
			-- disable unit tracks
			UnitDefs[name].leavetracks = 0
  
			-- disable speed penalty when turning
			UnitDefs[name].turninplaceanglelimit = 90.0
			UnitDefs[name].turninplacespeedlimit = mv

			-- make sure low acceleration units are able to beat drag
			local minAcceleration = mv / 80
			if ( tonumber(ac) < minAcceleration ) then
				UnitDefs[name].acceleration = minAcceleration
			end
			
			-- remove excessive brakerate from aircraft
			local canFly = UnitDefs[name].canfly
			local br = tonumber(UnitDefs[name].brakerate)
			if (canFly) then
				if (br > 0.5) then
					UnitDefs[name].brakerate = br / 5
				end
			end
		end
	end
end
