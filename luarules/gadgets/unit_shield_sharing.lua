function gadget:GetInfo()
   return {
      name = "Shield Sharing",
      desc = "Handles shield sharing.",
      author = "raaar",
      date = "2018",
      license = "PD",
      layer = 0,
      enabled = true,
   }
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

include("LuaLibs/Util.lua")

local spGetUnitShieldState = Spring.GetUnitShieldState
local spSetUnitShieldState = Spring.SetUnitShieldState
local spAreTeamsAllied = Spring.AreTeamsAllied
local spGetUnitTeam = Spring.GetUnitTeam

if (not gadgetHandler:IsSyncedCode()) then
    return
end


local SHIELD_SHARING_THRESHOLD_FRACTION = 0.9	-- drain from nearby ally shields if below this value
local SHIELD_SHARING_MIN_FRACTION = 0.5
local SHIELD_SHARING_MIN_FRACTION_SML = 0.5
local SHIELD_SHARING_SHARED_FRACTION_PER_STEP = 0.01 -- 2% per second
local SHIELD_SHARING_SHARED_FRACTION_PER_STEP_SML = 0.005 -- 1% per second
local SHIELD_SHARING_CAP_FRACTION = 0.03 -- 6% per second, or 3x the normal regen rate
local SHIELD_SHARING_EFF = 1.0
local SHIELD_SHARING_EFF_SML = 1.0

local SHIELD_SHARING_STEP_FRAMES = 15	-- twice per second

local shieldMaxByDefIds = {}
local shieldSQRadiusByDefIds = {}

local largeShieldDefIds = {
	[UnitDefNames["sphere_screener"].id] = true,
	[UnitDefNames["sphere_hermit"].id] = true,
	[UnitDefNames["sphere_shielder"].id] = true,
	[UnitDefNames["sphere_aegis"].id] = true
}
local smallShieldDefIds = {}


local largeShieldUnits = {}
local shieldUnits = {}

local alreadySharedUnitIds = {}

-- load shielded unit unitdef ids
function gadget:Initialize()
	for _,ud in pairs(UnitDefs) do
	
		if ud.weapons and ud.weapons[1] and ud.weapons[1].weaponDef then
			for wNum,w in pairs(ud.weapons) do
				local wd=WeaponDefs[w.weaponDef]
			    if wd.isShield == true then
			    	shieldMaxByDefIds[ud.id] = wd.shieldPower
					shieldSQRadiusByDefIds[ud.id] = wd.shieldRadius * wd.shieldRadius
			    end
			end
	    end
	end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	if largeShieldDefIds[unitDefID] then
		largeShieldUnits[unitID] = unitDefID
	end
	if shieldMaxByDefIds[unitDefID] then
		shieldUnits[unitID] = unitDefID
	end
end

-- extra income for wind generators
function gadget:GameFrame(n)
	if (n%SHIELD_SHARING_STEP_FRAMES ~= 0) then
		return
	end
	
	alreadySharedUnitIds = {} -- units are only allowed to give off shield to others once per check
	
	-- for each large shield unit, get nearby shielded units
	local x,x2,z,z2,oldShieldPower,oldShieldPower2,maxShieldPower,maxShieldPower2,amountDrained,powerFraction,powerFraction2,amountNeeded,amountAvailable,drainFromSmlShield,drainLimit,totalAmountDrained
	for uId,uDefId in pairs(largeShieldUnits) do
		shieldEnabled,oldShieldPower = spGetUnitShieldState(uId)
		
		x,_,z = spGetUnitPosition(uId)
		newShieldPower = oldShieldPower
		maxShieldPower = shieldMaxByDefIds[uDefId]
		powerFraction = (oldShieldPower / maxShieldPower)
		drainLimit = maxShieldPower * SHIELD_SHARING_CAP_FRACTION
		totalAmountDrained = 0 
		
		-- if shield is below threshold, try to drain from nearby allied shields
		if shieldEnabled and oldShieldPower > 0 and powerFraction < SHIELD_SHARING_THRESHOLD_FRACTION then
			teamId = spGetUnitTeam(uId)
			
			-- for each nearby allied shielded unit...			
			for uId2,uDefId2 in pairs(shieldUnits) do
				if (uId2 ~= uId and not alreadySharedUnitIds[uId2]) then
					--Echo(uId2.." hasn't shared yet")
					teamId2 = spGetUnitTeam(uId2)			
					if (spAreTeamsAllied(teamId,spGetUnitTeam(uId2))) then
						x2,_,z2 = spGetUnitPosition(uId2)
						if (sqDistance(x,x2,z,z2) < shieldSQRadiusByDefIds[uDefId]) then
							--Echo(uId2.." in range")
							amountDrained = 0
							amountNeeded = (maxShieldPower - newShieldPower)
							maxShieldPower2 = shieldMaxByDefIds[uDefId2]
							shieldEnabled,oldShieldPower2 = spGetUnitShieldState(uId2)
							
							if(shieldEnabled) then
								--Echo(uId2.." has shield to share")
								powerFraction2 = (oldShieldPower2 / maxShieldPower2)
								newShieldPower2 = oldShieldPower2
								drainFromSmlShield = false
								-- another large shield
								if (largeShieldUnits[uId2]) then
									if (powerFraction2 > SHIELD_SHARING_MIN_FRACTION) then
										amountAvailable = min(max(oldShieldPower2 - maxShieldPower2 * SHIELD_SHARING_MIN_FRACTION,0), maxShieldPower2 * SHIELD_SHARING_SHARED_FRACTION_PER_STEP) 
										amountDrained = min(amountNeeded,amountAvailable)
									end
								-- just a small shield
								else 
									drainFromSmlShield = true
									if (powerFraction2 > SHIELD_SHARING_MIN_FRACTION_SML) then
										amountAvailable = min(max(oldShieldPower2 - maxShieldPower2 * SHIELD_SHARING_MIN_FRACTION_SML,0), maxShieldPower2 * SHIELD_SHARING_SHARED_FRACTION_PER_STEP_SML) 
										amountDrained = min(amountNeeded,amountAvailable)
										
										--Echo(uId2.." available="..amountAvailable.." drained="..amountDrained)
									end
								end
								
								if (amountDrained > 0) then
									alreadySharedUnitIds[uId2] = true
									totalAmountDrained = totalAmountDrained + amountDrained * (drainFromSmlShield and SHIELD_SHARING_EFF_SML or SHIELD_SHARING_EFF)
									
									newShieldPower = newShieldPower + amountDrained * (drainFromSmlShield and SHIELD_SHARING_EFF_SML or SHIELD_SHARING_EFF)
									newShieldPower2 = newShieldPower2 - amountDrained
									
									--Echo("large shield on "..uId.." absorbs "..amountDrained.." from shield on "..uId2)
	
									spSetUnitShieldState(uId, newShieldPower)
									spSetUnitShieldState(uId2, newShieldPower2)

									if (totalAmountDrained >= drainLimit) then
										--Echo("large shield on "..uId.." absorbed "..totalAmountDrained.." which is past the limit of "..drainLimit.." and will not absorb any more")
										break
									end
									
									-- TODO draw some animation
								end
							end
						end	
					end
				end
			end
		end
	end

end


-- cleanup when shielded units are destroyed
function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)

	if largeShieldDefIds[unitDefID] then
		largeShieldUnits[unitID] = nil
	end
	if shieldMaxByDefIds[unitDefID] then
		shieldUnits[unitID] = nil
	end
	
end

