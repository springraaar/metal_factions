function gadget:GetInfo()
  return {
    name      = "Dynamic collision volume & Hitsphere Scaledown",
    desc      = "Adjusts collision volume for pop-up style units & Reduces the diameter of default sphere collision volume for 3DO models",
    author    = "Deadnight Warrior (tweaked by raaar)",
    date      = "Dec 10, 2010",
    license   = "GNU GPL, v2 or later",
    layer     = 2,
    enabled   = true
  }
end


-- 2015 : reduce radius and height for submarines to prevent unwanted targeting from cannons, etc.
-- 2013 : ??

local popupUnits = {}		--list of pop-up style units
local unitCollisionVolume = include("LuaRules/Configs/CollisionVolumes.lua")	--pop-up style unit collision volume definitions

local submarines = {
	aven_lurker = true,
	aven_piranha = true,
	aven_adv_construction_sub = true,
	gear_snake = true,
	gear_noser = true,
	gear_adv_construction_sub = true,
	claw_spine = true,
	claw_monster = true,
	sphere_carp = true,
	sphere_pluto = true,
	sphere_adv_construction_sub = true
}

local respawners = {
	aven_commander_respawner = true,
	gear_commander_respawner = true,
	claw_commander_respawner = true,
	sphere_commander_respawner = true
}

if (gadgetHandler:IsSyncedCode()) then

	--Reduces the diameter of default (unspecified) collision volume for 3DO models,
	--for S3O models it's not needed and will in fact result in wrong collision volume
	function gadget:UnitCreated(unitID, unitDefID, unitTeam)
		if UnitDefs[unitDefID].model.type=="3do" then
			local xs, ys, zs, xo, yo, zo, vtype, htype, axis, _ = Spring.GetUnitCollisionVolumeData(unitID)

			-- added radius reduction for submarines
			if (submarines[UnitDefs[unitDefID].name]) then 
				Spring.SetUnitRadiusAndHeight(unitID, (xs+zs)*0.6/2, ys*0.6)
				return
			end

			-- added radius reduction for commander respawners
			if (respawners[UnitDefs[unitDefID].name]) then 
				Spring.SetUnitRadiusAndHeight(unitID, (xs+zs)*0.25, ys*0.5)
				return
			end

			-- added radius reduction for aircraft
			if (UnitDefs[unitDefID].canFly) then 
				if (UnitDefs[unitDefID].transportCapacity>0) then
					Spring.SetUnitRadiusAndHeight(unitID, (xs+zs)*0.6/2, ys*0.6)
				else
    				Spring.SetUnitRadiusAndHeight(unitID, (xs+zs)*0.6/2, ys*0.6)
				end
				return
			end
		end
	end

	--check if a unit is pop-up type (the list must be entered manually)
	function gadget:UnitFinished(unitID, unitDefID, unitTeam)
		local un = UnitDefs[unitDefID].name
		if unitCollisionVolume[un] then
			popupUnits[unitID]=un
		end
	end

	--check if a pop-up type unit was destroyed
	function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
		if popupUnits[unitID] then
			popupUnits[unitID] = nil
		end
	end

	
	--Dynamic adjustment of pop-up style of units' collision volumes based on
	--unit's ARMORED status, runs twice per second
	function gadget:GameFrame(n)
		if (n%15 ~= 0) then
			return
		end
		local p
		for unitID,name in pairs(popupUnits) do
			if Spring.GetUnitArmored(unitID) then
				p = unitCollisionVolume[name].off
			else
				p = unitCollisionVolume[name].on

				--[[ if units doesn't use ARMORED variable, uncomment this block to make it use ACTIVATION as well
				if ( Spring.GetUnitIsActive(unitID) ) then
					p = unitCollisionVolume[name].on
				else
					p = unitCollisionVolume[name].off
				end
				]]--

			end
			Spring.SetUnitCollisionVolumeData(unitID, p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9])
			Spring.SetUnitMidAndAimPos(unitID,0, p[2]*0.5, 0,0, p[2]*0.5,0,true)
		end
	end
end