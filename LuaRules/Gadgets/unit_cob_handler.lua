
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
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spSetUnitRulesParam = Spring.SetUnitRulesParam
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

-- delays the reload timer for a unit's weapons
-- if delay <= 10 frames, delay is relative to previous reload frame
-- (so it only affects weapons still reloading)
-- else, delay is relative to current frame
function delayReload(unitID, unitDefID, teamID, delay)
	if delay and delay > 0 then
		local ud = UnitDefs[unitDefID]
		if ud.weapons and ud.weapons[1] and ud.weapons[1].weaponDef then
			for wNum,w in pairs(ud.weapons) do
				local weap=WeaponDefs[w.weaponDef]
			    if weap.isShield == false and weap.description ~= "No Weapon" then
			    	local reloadFrame = spGetUnitWeaponState(unitID,wNum,"reloadFrame")
					
					if delay > 10 then
						-- force weapon into reload after at least delay frames 
						reloadFrame = math.max(reloadFrame,spGetGameFrame()) + delay
					else
			    	  -- adds delay frames to weapon's reload frame (which may be in the past)
			    		reloadFrame = reloadFrame + delay
			    	end
			    	
			    	--Spring.Echo(ud.name.." reset reload cycle for weapon "..wNum)
			    	spSetUnitWeaponState(unitID,wNum,"reloadFrame",reloadFrame)
			    end
			end
	    end
		    
		return 0
	end
end


-- returns the next free build point, if any
-- for factories with multiple pads
function getBuildPt(unitID, unitDefID, teamID)
	
	-- if this is called, allowUnitCreation was already called and set a unit rules parameter with the piece number
	local buildPt = spGetUnitRulesParam(unitID,"build_pt")
	
	return buildPt
end

-- sets the current height level (0-10)
-- for units like fortification gates that can be raised or lowered
function setHeightLevel(unitID, unitDefID, teamID, heightLevel)
	
	spSetUnitRulesParam(unitID,"height_level",heightLevel)
	
	return 0
end

function cobDebug(unitID, unitDefID, teamID, data1, data2)
	spEcho("uId="..unitID.." f="..spGetGameFrame().." DEBUG1="..data1.." DEBUG2="..tostring(data2))
end




gadgetHandler:RegisterGlobal("cobDebug", cobDebug)
gadgetHandler:RegisterGlobal("checkEnergy", checkEnergy)
gadgetHandler:RegisterGlobal("resetReload", resetReload)
gadgetHandler:RegisterGlobal("delayReload", delayReload)
gadgetHandler:RegisterGlobal("getBuildPt", getBuildPt)
gadgetHandler:RegisterGlobal("setHeightLevel", setHeightLevel)
gadgetHandler:RegisterGlobal("delayReload", delayReload)