function gadget:GetInfo()
   return {
      name = "Weapon Aim Handler Gadget",
      desc = "Overrides weapon targeting in some cases",
      author = "raaar",
      date = "2018",
      license = "PD",
      layer = 10,
      enabled = true,
   }
end

local Echo = Spring.Echo
local floor = math.floor
local ceil = math.ceil
local max = math.max
local spGetUnitWeaponTestRange = Spring.GetUnitWeaponTestRange 
local spGetGroundHeight = Spring.GetGroundHeight
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitWeaponTarget = Spring.GetUnitWeaponTarget
local spSetUnitTarget = Spring.SetUnitTarget
local spGetUnitDefID = Spring.GetUnitDefID
local spGetGameFrame = Spring.GetGameFrame
local spGetUnitHealth = Spring.GetUnitHealth
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spSetUnitWeaponState = Spring.SetUnitWeaponState
local spSetUnitWeaponDamages = Spring.SetUnitWeaponDamages

local targetForUnitId = {}
local trackedWeaponDefIds = {}
local lastPriorityForUnitId = {}

local AA_FLAT_RANGE_EXTENSION = 80 

-- slave weapon indexes (master,slave)
local slaveWeaponIndexesByUnitDefId = {
	-- AVEN
	[UnitDefNames["aven_commander"].id] = {3,1},
	[UnitDefNames["aven_u1commander"].id] = {3,1},
	[UnitDefNames["aven_u2commander"].id] = {3,1},
	[UnitDefNames["aven_u5commander"].id] = {3,1},
	[UnitDefNames["aven_magnum"].id] = {2,1},
	[UnitDefNames["aven_raptor"].id] = {1,2},
	-- GEAR	
	[UnitDefNames["gear_commander"].id] = {3,1},
	[UnitDefNames["gear_u3commander"].id] = {3,1},
	-- CLAW
	[UnitDefNames["claw_brute"].id] = {1,2},
	-- SPHERE
	[UnitDefNames["sphere_charger"].id] = {1,2},
}

-- done unit def ids
local droneDefIds = {}

-- unit ids with slaved weapons
local slaveWeaponIndexesByUnitId = {}


local airTargettingWeaponIndexesByUnitDefId = {}
local airTargettingWeaponIndexesByUnitId = {}	-- [uId][wNum] = true/false	

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


-- updates weapon base range + upgrade modifiers on unit
function updateUnitWeaponRange(unitId, wNum, range)
	-- get modifier from upgrades
	local modifier = spGetUnitRulesParam(unitId,"upgrade_range") or 0
	
	local modRange = range * (1 + modifier)
	spSetUnitWeaponState(unitId,wNum,"range",modRange)
	spSetUnitWeaponDamages(unitId,wNum,"dynDamageRange",modRange)
end

-------------------------- SYNCED CODE ONLY
if (not gadgetHandler:IsSyncedCode()) then
	return false
end



function gadget:Initialize()

	-- find unit defs for some types
	for id,ud in pairs(UnitDefs) do
		-- drones
		if (ud.customParams and ud.customParams.isdrone) then
			droneDefIds[ud.id] = true
			--Spring.Echo(ud.name.." is drone")
		end
		
		-- units with aaRangeBoosted weapons 
		if ud.weapons and ud.weapons[1] and ud.weapons[1].weaponDef then
			for wNum,w in pairs(ud.weapons) do
				local wd=WeaponDefs[w.weaponDef]
				if wd.customParams and wd.customParams.aarangeboost == "1" then
					if not airTargettingWeaponIndexesByUnitDefId[id] then
						airTargettingWeaponIndexesByUnitDefId[id] = {}
					end
					airTargettingWeaponIndexesByUnitDefId[id][wNum] = wd.range
				end
			end
		end
	end
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
	--Spring.Echo(attackerID.." ALLOWTARGET "..targetID.." ? prio="..tostring(defaultPriority))
	--Spring.Echo(attackerID.." has line of fire to "..targetID.." ? "..tostring(Spring.GetUnitWeaponHaveFreeLineOfFire(attackerID,attackerWeaponNum,targetID)))
	
	if defaultPriority == nil then
		if lastPriorityForUnitId[attackerID] then
			defaultPriority = lastPriorityForUnitId[attackerID] 
		else
			defaultPriority = 1000
		end
	else
		lastPriorityForUnitId[attackerID] = defaultPriority
	end
	

	if targetForUnitId[attackerID] then
		-- only do this if in range of the target
		if (spGetUnitWeaponTestRange(attackerID, attackerWeaponNum, targetForUnitId[attackerID]) == true) then
			--Spring.Echo("in range "..tonumber(targetForUnitId[attackerID]).." / "..UnitDefs[Spring.GetUnitDefID(targetForUnitId[attackerID])].name)

			-- if unit is marked as target, reject all other targets
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
	
	
	if targetID and tonumber(targetID) > 0 then
		-- avoid aiming at targets that are marked as about to die
		local defId = spGetUnitDefID(targetID)
		if defId then
			if (GG.lessThan500HPTargetDefIds[defId]) then
				local f = spGetGameFrame()
				local lastFireFrame = GG.unitFireFrameByTargetId[targetID]
				if ( lastFireFrame and (f - lastFireFrame < GG.OKP_FRAMES) ) then
					--Spring.Echo("f="..f.."unit "..attackerID.." refuses to aim at target "..tostring(targetID))
					return false,defaultPriority
				end
			elseif (GG.okpIncendiaryWeaponDefIds[attackerWeaponDefID]) then
				local f = spGetGameFrame()
				local lastFireFrame = GG.unitFireFrameByTargetIdIncendiary[targetID]
				if ( lastFireFrame and (f - lastFireFrame < GG.OKP_FRAMES) ) then
					--Spring.Echo("f="..f.."unit "..attackerID.." refuses to aim at target "..tostring(targetID))
					return false,defaultPriority
				end
			end 
			
			if (droneDefIds[defId]) then
				local _,_,_,_,bp = spGetUnitHealth(targetID)
				if bp < 0.5 then
					--Spring.Echo("frame="..spGetGameFrame().." drone under construction : SKIP")
					return false,defaultPriority
				end
			end
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

	if slaveWeaponIndexesByUnitId[unitID] then
		slaveWeaponIndexesByUnitId[unitID] = nil
	end
	if airTargettingWeaponIndexesByUnitId[unitID] then
		airTargettingWeaponIndexesByUnitId[unitID] = nil
	end	
end


-- enforce slave weapon target to be the same as master weapon
function gadget:GameFrame(n)
	for unitId,data in pairs(slaveWeaponIndexesByUnitId) do
		local masterIdx = data[1]
		local slaveIdx = data[2]
		local m1,m2,masterTarget = spGetUnitWeaponTarget(unitId,masterIdx)
		local s1,s2,slaveTarget = spGetUnitWeaponTarget(unitId,slaveIdx)
		
		if masterTarget ~= nil and slaveTarget ~= nil and type(slaveTarget) ~= "table" and type(masterTarget) ~= "table" and slaveTarget ~= masterTarget then
			Spring.SetUnitTarget(unitId,masterTarget)
			targetForUnitId[unitId] = masterTarget
			--Spring.Echo("unit targets overridden, f="..n.." m="..tostring(masterTarget).." s="..tostring(slaveTarget))
		end
	end
	
	local unitDefId, ud, targetDef, isAttackingAir, tType,isUser,target = 0
	-- modify the range of certain weapons depending on whether they're targetting air units
	for unitId,wTable in pairs(airTargettingWeaponIndexesByUnitId) do
		unitDefId = spGetUnitDefID(unitId)
		if (unitDefId ~= nil) then
			for wNum,wRange in pairs(airTargettingWeaponIndexesByUnitDefId[unitDefId]) do
			    isAttackingAir = false
				-- check if weapon is targetting air unit 
				tType,isUser,target = spGetUnitWeaponTarget(unitId,wNum)
		    	--Spring.Echo(" type="..tType.." t="..tostring(target))
				if tType and tType <= 1 and target then
					targetDef = UnitDefs[spGetUnitDefID(target)]
					if (targetDef and targetDef.canFly) then
						isAttackingAir = true
					end
				end

				-- started attacking air, update
				if (isAttackingAir and (not wTable[wNum])) then
					wTable[wNum] = true	
					
					-- increase range
					updateUnitWeaponRange(unitId, wNum, wRange + AA_FLAT_RANGE_EXTENSION)
					--Spring.Echo(n.." increased range")
				end
				
				-- stopped attacking air, update range
				if ((not isAttackingAir) and wTable[wNum] == true) then
					wTable[wNum] = false
					
					-- revert to default range
					updateUnitWeaponRange(unitId, wNum, wRange)
					--Spring.Echo(n.." restored range")
				end
		    end
		end
	end
end



function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	if slaveWeaponIndexesByUnitDefId[unitDefID] then
		slaveWeaponIndexesByUnitId[unitID] = slaveWeaponIndexesByUnitDefId[unitDefID]
	end
	if airTargettingWeaponIndexesByUnitDefId[unitDefID] then
		airTargettingWeaponIndexesByUnitId[unitID] = {}	
	end
end