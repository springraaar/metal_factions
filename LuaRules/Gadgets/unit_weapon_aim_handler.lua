function gadget:GetInfo()
   return {
      name = "Weapon Aim Handler Gadget",
      desc = "Overrides weapon targeting in some cases",
      author = "raaar",
      date = "2018",
      license = "PD",
      layer = 1,
      enabled = true,
   }
end

local Echo = Spring.Echo
local floor = math.floor
local ceil = math.ceil
local max = math.max
local spGetUnitWeaponTestRange = Spring.GetUnitWeaponTestRange 


local targetForUnitId = {}
local trackedWeaponDefIds = {}


-- track unit's weapons
local function trackWeapons(unitDefID)
	local ud = UnitDefs[unitDefID]
	if ud.weapons and ud.weapons[1] and ud.weapons[1].weaponDef then
		for wNum,w in pairs(ud.weapons) do
			if not trackedWeaponDefIds[w.weaponDef] then
				local weap=WeaponDefs[w.weaponDef]
			    if weap.isShield == false and weap.description ~= "No Weapon" then
					trackedWeaponDefIds[w.weaponDef] = true 
					Script.SetWatchWeapon(w.weaponDef,true)
			    end
		    end
		end
    end
end

-------------------------- SYNCED CODE ONLY
if (not gadgetHandler:IsSyncedCode()) then
	return false
end

-- mark units that targeted other units for attack
-- clear marking if STOP command is used
function gadget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOpts, cmdTag)
	if cmdID == CMD.ATTACK then
		--Spring.Echo("attacker="..unitID)
		--for i,v in ipairs(cmdParams) do
		--	Spring.Echo("cmdParams["..i.."]="..v)
		--end

		if cmdParams then
			local targetId = tonumber(cmdParams[1])
			if Spring.ValidUnitID(targetId) then
				--Spring.Echo("target is "..targetId.." / "..UnitDefs[Spring.GetUnitDefID(targetId)].name)
				targetForUnitId[unitID] = tonumber(cmdParams[1])
				trackWeapons(unitDefID) -- required for AllowWeaponTarget to be called
			end
		end		
	end
	if cmdID == CMD.STOP then
		targetForUnitId[unitID] = nil
		--Spring.Echo("target cleared for "..unitID)
	end
end

-- weapon target check
function gadget:AllowWeaponTarget(attackerID, targetID, attackerWeaponNum, attackerWeaponDefID, defaultPriority)
	--Spring.Echo(attackerID.." ALLOWTARGET "..targetID.." ?")
	--Spring.Echo(attackerID.." has line of fire to "..targetID.." ? "..tostring(Spring.GetUnitWeaponHaveFreeLineOfFire(attackerID,attackerWeaponNum,targetID)))
	
	if targetForUnitId[attackerID] then
		-- only do this if in range of the target
		if (spGetUnitWeaponTestRange(attackerID, attackerWeaponNum, targetForUnitId[attackerID]) == true) then
			--Spring.Echo("in range "..tonumber(targetForUnitId[attackerID]).." / "..UnitDefs[Spring.GetUnitDefID(targetForUnitId[attackerID])].name)

			-- if unit is marked as target, assume lowest priority value (highest priority)
			if targetForUnitId[attackerID] == targetID then
				--Spring.Echo("focus "..tonumber(targetID).." / "..UnitDefs[Spring.GetUnitDefID(targetID)].name)
				return true,defaultPriority
			else
				return false,defaultPriority
			end
		else
			-- out of range, clear target
			targetForUnitId[attackerID] = nil
		end
	end
	
	return true,defaultPriority
end

-- cleanup target markings when attacker or target is destroyed
function gadget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
	-- attacker destroyed
	if targetForUnitId[unitID] then
		targetForUnitId[unitID] = nil
	end
	
	-- target destroyed
	for uId,tId in pairs(targetForUnitId) do
		if tId == unitID then
			targetForUnitId[uId] = nil
		end
	end
end