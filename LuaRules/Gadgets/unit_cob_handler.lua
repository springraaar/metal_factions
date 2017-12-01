
function gadget:GetInfo()
  return {
    name      = "Cob Call Handler",
    desc      = "used to handle calls from cob scripts",
    author    = "raaar",
    date      = "Mar 2015",
    license   = "PD",
    layer     = 2,
    enabled   = true
  }
end

local spEcho = Spring.Echo
local spSetUnitWeaponState = Spring.SetUnitWeaponState
local spGetUnitWeaponState = Spring.GetUnitWeaponState
local spGetGameFrame = Spring.GetGameFrame

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
    return
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

-- checks if player has enough energy to enable or disable certain unit abilities
function checkEnergy(unitID, unitDefID, teamID, data)

	-- get team energy
	local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = Spring.GetTeamResources(teamID,"energy")

	-- if greater than threshold, return 1
	if currentLevelE > data then
		return 1
	end

	-- else return 0
	return 0
end

-- resets the reload status for a unit's weapons
function resetReload(unitID, unitDefID, teamID, data)
	local ud = UnitDefs[unitDefID]
	--Spring.Echo(ud.name.." reset its reload cycle")
	if ud.weapons and ud.weapons[1] and ud.weapons[1].weaponDef then
		for wNum,w in pairs(ud.weapons) do
			local weap=WeaponDefs[w.weaponDef]
		    if weap.isShield == false and weap.description ~= "No Weapon" then
		    	--Spring.Echo(ud.name.." reset reload cycle for weapon "..wNum)
		    	spSetUnitWeaponState(unitID,wNum,"reloadFrame",spGetGameFrame() + spGetUnitWeaponState(unitID,wNum,"reloadTime") * 30)
		    end
		end
    end
	    
	return 0
end


-- delays the reload timer for a unit's weapons (data = delay frames)
function delayReload(unitID, unitDefID, teamID, data)
	if data and data > 0 then
		local ud = UnitDefs[unitDefID]
		if ud.weapons and ud.weapons[1] and ud.weapons[1].weaponDef then
			for wNum,w in pairs(ud.weapons) do
				local weap=WeaponDefs[w.weaponDef]
			    if weap.isShield == false and weap.description ~= "No Weapon" then
			    	--Spring.Echo(ud.name.." reset reload cycle for weapon "..wNum)
			    	spSetUnitWeaponState(unitID,wNum,"reloadFrame",math.max(spGetUnitWeaponState(unitID,wNum,"reloadFrame"),spGetGameFrame()) + data)
			    end
			end
	    end
		    
		return 0
	end
end



function cobDebug(unitID, unitDefID, teamID, data)
	spEcho(data)
end


gadgetHandler:RegisterGlobal("cobDebug", cobDebug)
gadgetHandler:RegisterGlobal("checkEnergy", checkEnergy)
gadgetHandler:RegisterGlobal("resetReload", resetReload)
gadgetHandler:RegisterGlobal("delayReload", delayReload)
