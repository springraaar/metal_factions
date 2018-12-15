function gadget:GetInfo()
  return {
    name      = "Dynamic collision volume & Hitsphere Scaledown",
    desc      = "Adjusts collision volume for pop-up style units & Reduces the diameter of default sphere collision volume for 3DO models",
    author    = "Deadnight Warrior (tweaked by raaar)",
    date      = "April 2017",
    license   = "GNU GPL, v2 or later",
    layer     = -1,
    enabled   = true
  }
end


local spGetAllUnits = Spring.GetAllUnits
local spSetUnitCollisionVolumeData = Spring.SetUnitCollisionVolumeData
local spSetUnitMidAndAimPos = Spring.SetUnitMidAndAimPos
local spGetUnitHealth = Spring.GetUnitHealth
local spGetUnitCollisionVolumeData = Spring.GetUnitCollisionVolumeData
local spGetUnitMidAndAimPos = Spring.GetUnitMidAndAimPos
local spSetUnitRadiusAndHeight = Spring.SetUnitRadiusAndHeight 

local popupUnits = {}		--list of pop-up style units
local unitCollisionVolume = include("LuaRules/Configs/CollisionVolumes.lua")	--pop-up style unit collision volume definitions
local unitYSizeOffset = {}     -- <uId,{sizeY,offsetY}>
local BP_SIZE_LIMIT = 0.8
local BP_SIZE_MULTIPLIER = 1 / BP_SIZE_LIMIT

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

local flyingSpheres = {
	sphere_construction_sphere = true,
	sphere_nimbus = true,
	sphere_orb = true,
	sphere_aster = true,
	sphere_gazer = true,
	sphere_comet = true,
	sphere_magnetar = true,
	sphere_chroma = true
}

local respawners = {
	aven_commander_respawner = true,
	gear_commander_respawner = true,
	claw_commander_respawner = true,
	sphere_commander_respawner = true
}

local airFactories = {
	aven_aircraft_plant = true,
	aven_adv_aircraft_plant = true,
	gear_aircraft_plant = true,
	gear_adv_aircraft_plant = true,
	claw_aircraft_plant = true,
	claw_adv_aircraft_plant = true,
	sphere_aircraft_factory = true,
	sphere_adv_aircraft_factory = true,
	sphere_sphere_factory = true,
	aven_long_range_missile_platform = true
}

local csBeaconIds = {}

if (gadgetHandler:IsSyncedCode()) then

	--Reduces the diameter of default (unspecified) collision volume for 3DO models,
	--for S3O models it's not needed and will in fact result in wrong collision volume
	function gadget:UnitCreated(unitID, unitDefID, unitTeam)
		local xs, ys, zs, xo, yo, zo, vtype, htype, axis, _ = spGetUnitCollisionVolumeData(unitID)

		-- added radius reduction for submarines
		if (submarines[UnitDefs[unitDefID].name]) then 
			spSetUnitRadiusAndHeight(unitID, (xs+zs)*0.6/2, ys*0.6)
		-- added radius reduction for commander respawners
		elseif (respawners[UnitDefs[unitDefID].name]) then 
			spSetUnitRadiusAndHeight(unitID, (xs+zs)*0.25, ys*0.5)
		-- added radius reduction for aircraft
		elseif (UnitDefs[unitDefID].name == "cs_beacon") then
			csBeaconIds[unitID] = true
		elseif (UnitDefs[unitDefID].canFly) then 
			if (UnitDefs[unitDefID].transportCapacity>0) then
				spSetUnitRadiusAndHeight(unitID, (xs+zs)*0.6/2, ys*0.6)
			else
				if (flyingSpheres[UnitDefs[unitDefID].name]) then
					spSetUnitRadiusAndHeight(unitID, (xs+zs)*0.6/2, ys*0.6)
				else
					spSetUnitRadiusAndHeight(unitID, (xs+zs)*0.6/2, ys*0.6)
				end
			end
		end
		
		if not csBeaconIds[unitID] then
			unitYSizeOffset[unitID] = {ys,yo}
		end

		-- reduce size of aircraft factories
		if (airFactories[UnitDefs[unitDefID].name]) then 
			spSetUnitRadiusAndHeight(unitID, (xs+zs)*0.25, ys*0.5)
		end
		
		-- reduce size of unit under construction
		local _,_,_,_,bp = spGetUnitHealth(unitID)
		local val  = 1
		-- only affect units under construction
		if (bp < BP_SIZE_LIMIT) then
			val = math.max(bp*BP_SIZE_MULTIPLIER,0.1)
			ys = ys * val
			yo = yo * val
			spSetUnitCollisionVolumeData(unitID, xs, ys, zs, xo, yo, zo, vtype, htype, axis)
			spSetUnitMidAndAimPos(unitID,0, ys*0.5, 0,0, ys*0.5,0,true)
		end
		
	end


	function gadget:UnitFinished(unitID, unitDefID, unitTeam)
		if not csBeaconIds[unitID] then
			-- check if a unit is pop-up type (the list must be entered manually)
			local un = UnitDefs[unitDefID].name
			if unitCollisionVolume[un] then
				popupUnits[unitID]=un
			end
	
			-- set height to expected value for fully built unit
			if unitYSizeOffset[unitID] then
				local xs, ys, zs, xo, yo, zo, vtype, htype, axis,_ = spGetUnitCollisionVolumeData(unitID)
				local data = unitYSizeOffset[unitID]
				ys = data[1]
				yo = data[2]
				
				spSetUnitCollisionVolumeData(unitID, xs, ys, zs, xo, yo, zo, vtype, htype, axis)
				spSetUnitMidAndAimPos(unitID,0, ys*0.5, 0,0, ys*0.5,0,true)
			end
		end
	end

	--check if a pop-up type unit was destroyed
	function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
		if popupUnits[unitID] then
			popupUnits[unitID] = nil
		end
		if csBeaconIds[unitID] then
			csBeaconIds[unitID] = nil
		end
		if unitYSizeOffset[unitID] then
			unitYSizeOffset[unitID] = nil
		end
	end

	
	--Dynamic adjustment of collision sizes
	function gadget:GameFrame(n)

		-- adjust pop-up style of units' collision volumes based on ARMORED status
		-- runs twice per second
		if (n%15 == 0) then
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
				spSetUnitCollisionVolumeData(unitID, p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9])
				spSetUnitMidAndAimPos(unitID,0, p[2]*0.5, 0,0, p[2]*0.5,0,true)
			end
		end

		-- adjust collision volume height based on build %
		-- runs 6 times per second
		if (n%5 == 0) then
			local xs, ys, zs, xo, yo, zo, vtype, htype, axis, disabled
			local val = 0
			for uId,data in pairs(unitYSizeOffset) do
				local _,_,_,_,bp = spGetUnitHealth(uId)
				
				-- only affect units under construction
				-- height grows until build % reaches 60
				if (bp < BP_SIZE_LIMIT) then
					xs, ys, zs, xo, yo, zo, vtype, htype, axis,_ = spGetUnitCollisionVolumeData(uId)
	
					val = math.max(bp*BP_SIZE_MULTIPLIER,0.1)
					ys = data[1] * val
					yo = data[2] * val
					spSetUnitCollisionVolumeData(uId, xs, ys, zs, xo, yo, zo, vtype, htype, axis)
					spSetUnitMidAndAimPos(uId,0, ys*0.5, 0,0, ys*0.5,0,true)
				end
			end
		end
		
		-- remove collision volume for cs beacons
		-- this is here because it wasn't working on unitcreated, for some reason 
		for unitID,_ in pairs(csBeaconIds) do
			spSetUnitRadiusAndHeight(unitID, 1, 1)
			spSetUnitCollisionVolumeData(unitID, 1, 1, 1, 0, 0,0, -1, 1, 0)
			csBeaconIds[unitID] = nil
		end
	end
end