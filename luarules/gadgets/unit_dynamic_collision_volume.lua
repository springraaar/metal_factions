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


local spSetUnitCollisionVolumeData = Spring.SetUnitCollisionVolumeData
local spSetUnitMidAndAimPos = Spring.SetUnitMidAndAimPos
local spGetUnitHealth = Spring.GetUnitHealth
local spGetUnitCollisionVolumeData = Spring.GetUnitCollisionVolumeData
local spGetUnitMidAndAimPos = Spring.GetUnitMidAndAimPos
local spSetUnitRadiusAndHeight = Spring.SetUnitRadiusAndHeight 
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spSetUnitBlocking = Spring.SetUnitBlocking
local spGetUnitBlocking = Spring.GetUnitBlocking
local spGetUnitPosition = Spring.GetUnitPosition
local spGetGroundHeight = Spring.GetGroundHeight
local spGetUnitDefID = Spring.GetUnitDefID
local spGetGameFrame = Spring.GetGameFrame
local max = math.max

local popupUnits = {}		--list of pop-up style units
local unitCollisionVolume = include("luaRules/configs/collision_volumes.lua")	--pop-up style unit collision volume definitions
local unitXYZSizeOffset = {}     -- <uId,{sizeX,sizeY,sizeZ,offsetX,offsetY,offsetZ}>
local unitBlocking = {} --   <uId,{isBlocking, isSolidObjectCollidable,isProjectileCollidable,isRaySegmentCollidable,crushable,blockEnemyPushing,blockHeightChanges,builderID,blockFixRequired,ud}>


local BP_SIZE_LIMIT = 0.8
local BP_REDUCED_FP_LIMIT = 0.2
local BP_SIZE_MULTIPLIER = 1 / BP_SIZE_LIMIT
local SUBMERGED_RADIUS_FACTOR = 0.5

local lastSubmergedStatusByUnitId = {}
 
local submarines = {
	aven_lurker = true,
	aven_stinger = true,
	aven_piranha = true,
	aven_adv_construction_sub = true,
	gear_snake = true,
	gear_noser = true,
	gear_blowfish = true,
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
	aven_long_range_missile_platform = true,
	aven_skein = true
}

local constructionTowers = {
	aven_nano_tower = true,
	gear_nano_tower = true,
	claw_nano_tower = true,
	sphere_pole = true
}

local csBeaconIds = {}


function disableUnitBlocking(unitID,builderID,blockFixRequired,ud)
	if not (ud.isBuilding or constructionTowers[ud.name]) then
		local isb,issoc,ispc,isrsc,cr,bep,bhc = spGetUnitBlocking(unitID)
		unitBlocking[unitID] = {isb,issoc,ispc,isrsc,cr,bep,bhc,builderID,blockFixRequired,ud}
		-- prevent big units from making the previously built unit stuck
		spSetUnitBlocking(unitID,false,false,ispc,isrsc,cr,bep,bhc)	
	end
end


function restoreUnitBlocking(unitID)
	local bData = unitBlocking[unitID]
	spSetUnitBlocking(unitID,bData[1],bData[2],bData[3],bData[4],bData[5],bData[6],bData[7])
end 

if (gadgetHandler:IsSyncedCode()) then

	--Reduces the diameter of default (unspecified) collision volume for 3DO models,
	--for S3O models it's not needed and will in fact result in wrong collision volume
	function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
		local xs, ys, zs, xo, yo, zo, vtype, htype, axis, _ = spGetUnitCollisionVolumeData(unitID)
		local ud = UnitDefs[unitDefID]
		-- added radius reduction for submarines
		if (submarines[ud.name]) then 
			spSetUnitRadiusAndHeight(unitID, (xs+zs)*0.4/2, ys*0.4)
		-- added radius reduction for commander respawners
		elseif (respawners[ud.name]) then 
			spSetUnitRadiusAndHeight(unitID, (xs+zs)*0.25, ys*0.5)
		-- added radius reduction for aircraft
		elseif (ud.name == "cs_beacon" or ud.name == "scoper_beacon") then
			csBeaconIds[unitID] = true
		elseif (ud.canFly) then 
			if (ud.transportCapacity>0) then
				spSetUnitRadiusAndHeight(unitID, (xs+zs)*0.7/2, ys*0.7)
			else
				spSetUnitRadiusAndHeight(unitID, (xs+zs)*0.7/2, ys*0.7)
			end
		end
		
		if not csBeaconIds[unitID] then
			unitXYZSizeOffset[unitID] = {xs,ys,zs,xo,yo,zo}
			
			if not (ud.isBuilding or constructionTowers[ud.name]) then
				disableUnitBlocking(unitID,builderID,spGetGameFrame(),ud)
			end
		end

		-- reduce size of aircraft factories
		if (airFactories[ud.name]) then 
			spSetUnitRadiusAndHeight(unitID, (xs+zs)*0.25, ys*0.5)
		end
		
		-- reduce size of unit under construction
		local _,_,_,_,bp = spGetUnitHealth(unitID)
		local val  = 1
		-- only affect units under construction
		if (bp < BP_SIZE_LIMIT) then
			val = math.max(bp*BP_SIZE_MULTIPLIER,0.1)
			xs = xs * val
			ys = ys * val
			zs = zs * val
			xo = xo * val
			yo = yo * val
			zo = zo * val
			spSetUnitCollisionVolumeData(unitID, xs, ys, zs, xo, yo, zo, vtype, htype, axis)
			spSetUnitMidAndAimPos(unitID,0, ys*0.5, 0,0, ys*0.75+yo,0,true)
		end
	end


	function gadget:UnitFinished(unitID, unitDefID, unitTeam)
		if not csBeaconIds[unitID] then
			-- check if a unit is pop-up type (the list must be entered manually)
			local ud = UnitDefs[unitDefID]
			local un = ud.name
			if unitCollisionVolume[un] then
				popupUnits[unitID]=un
			end
	
			-- set height to expected value for fully built unit
			if unitXYZSizeOffset[unitID] then
				local xs, ys, zs, xo, yo, zo, vtype, htype, axis,_ = spGetUnitCollisionVolumeData(unitID)
				local data = unitXYZSizeOffset[unitID]
				xs = data[1]
				ys = data[2]
				zs = data[3]
				xo = data[4]
				yo = data[5]
				zo = data[6]
				
				-- restore the blocking status							
				if (unitBlocking[unitID]) then
					if not ud.canFly then 
						restoreUnitBlocking(unitID)
					else
						-- for flying units, mark it
						-- it needs some checks before the block status to avoid locking the factory
						-- TODO remove when engine gets fixed
						unitBlocking[unitID][9] = true			
					end
				end
				
				spSetUnitCollisionVolumeData(unitID, xs, ys, zs, xo, yo, zo, vtype, htype, axis)
				spSetUnitMidAndAimPos(unitID,0, ys*0.5, 0,0, ys*0.75+yo,0,true)
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
		if unitXYZSizeOffset[unitID] then
			unitXYZSizeOffset[unitID] = nil
		end
		if unitBlocking[unitID] then
			unitBlocking[unitID] = nil 
		end
		if lastSubmergedStatusByUnitId[unitID] then
			lastSubmergedStatusByUnitId[unitID] = nil
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
				spSetUnitMidAndAimPos(unitID,0, p[2]*0.5, 0,0, p[2]*0.75+p[5],0,true)
			end
		end

		-- adjust collision volume height based on build %
		-- runs 6 times per second
		if (n%5 == 0) then
			local xs, ys, zs, xo, yo, zo, vtype, htype, axis, disabled
			local py,h
			local val = 0
			for uId,data in pairs(unitXYZSizeOffset) do
				local _,_,_,_,bp = spGetUnitHealth(uId)
				
				-- only affect units under construction
				-- height grows until build % reaches 60
				if (bp < BP_SIZE_LIMIT) then
					xs, ys, zs, xo, yo, zo, vtype, htype, axis,_ = spGetUnitCollisionVolumeData(uId)
	
					val = math.max(bp*BP_SIZE_MULTIPLIER,0.1)
					-- adjust height level of gates 
					local heightLevel = spGetUnitRulesParam(uId,"height_level")
					if (type(heightLevel) == "number") then
						val = math.max( val * heightLevel / 10, 0.03)
					end
					ys = data[2] * val
					yo = data[5] * val

					-- prevent big units from making the previously built unit stuck
					-- only applies to mobile units
					if (unitBlocking[unitID] and bp < BP_REDUCED_FP_LIMIT) then
						xs = data[1] * val
						xo = data[4] * val
						zs = data[3] * val
						zo = data[6] * val

						local bData = unitBlocking[unitID]
						spSetUnitBlocking(unitID,false,false,bData[3],bData[4],bData[5],bData[6],bData[7])	
					else
						xs = data[1]
						xo = data[4]
						zs = data[3]
						zo = data[6]
					end
					
					spSetUnitCollisionVolumeData(uId, xs, ys, zs, xo, yo, zo, vtype, htype, axis)
					spSetUnitMidAndAimPos(uId,0, ys*0.5, 0,0, ys*0.75+yo,0,true)
				else
					-- adjust height level of gates 
					local heightLevel = spGetUnitRulesParam(uId,"height_level")
					if (type(heightLevel) == "number") then
						xs, ys, zs, xo, yo, zo, vtype, htype, axis,_ = spGetUnitCollisionVolumeData(uId)
		
						val = 1
						-- adjust height level of gates 
						local heightLevel = spGetUnitRulesParam(uId,"height_level")
						if (type(heightLevel) == "number") then
							val = math.max( val * heightLevel / 10, 0.03)
						end
						ys = data[2] * val
						yo = data[5] * val
						
						spSetUnitCollisionVolumeData(uId, xs, ys, zs, xo, yo, zo, vtype, htype, axis)
						spSetUnitMidAndAimPos(uId,0, ys*0.5, 0,0, ys*0.75+yo,0,true)

						-- force gates to not be blocking if they're fully lowered 						
						local isb,issoc,ispc,isrsc,cr,bep,bhc = spGetUnitBlocking(uId)
						if heightLevel == 0 then
							spSetUnitBlocking(uId,false,false,ispc,isrsc,cr,bep,bhc)	
						else
							spSetUnitBlocking(uId,true,true,ispc,isrsc,cr,bep,bhc)
						end
					end
					
				 
					-- adjust targetting radius for units as they get in and out of water
					local ud = UnitDefs[spGetUnitDefID(uId)]
					if (not ud.shieldPower and not ud.canFly and not ud.waterLine) then
						local fullySubmergedDepth = spGetUnitRulesParam(uId, "fullySubmergedDepth")
						if fullySubmergedDepth and fullySubmergedDepth > 5 then
							if (not lastSubmergedStatusByUnitId[unitID]) then
							
								xs = data[1] * SUBMERGED_RADIUS_FACTOR
								ys = data[2] * SUBMERGED_RADIUS_FACTOR
								zs = data[3] * SUBMERGED_RADIUS_FACTOR
								
								-- Spring.Echo(uId.." submerged")
								spSetUnitRadiusAndHeight(uId, (xs+zs)/2, ys)
								lastSubmergedStatusByUnitId[uId] = true
							end
						else
							if (lastSubmergedStatusByUnitId[uId]) then
								xs = data[1]
								ys = data[2]
								zs = data[3]
								
								-- Spring.Echo(uId.." emerged")
								spSetUnitRadiusAndHeight(uId, (xs+zs)/2, ys)
								lastSubmergedStatusByUnitId[uId] = false
							end
						end
					end
					
					-- restore the blocking status for flying units
					-- but only after get high above the factory
					-- TODO : workaround for engine issue, remove when possible
					if bp == 1 then		
						local data = unitBlocking[uId] 
						if data then
							local blockFixRequired = data[9]
							if ud.canFly and blockFixRequired then
								px,py,pz = spGetUnitPosition(uId)
								if (px) then
									h = max(spGetGroundHeight(px,pz),0)
									if h and py > h + 60 then 
										data[9] = false
										restoreUnitBlocking(uId)
										--Spring.Echo("blocking restored for flying unit "..uId.." h="..(py-h))
									end
								end
							
							end
						end
					end
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