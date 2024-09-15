function gadget:GetInfo()
   return {
      name = "Physics Handler",
      desc = "Handles some aspects of unit and feature physics",
      author = "raaar",
      date = "2016",
      license = "PD",
      layer = 1,
      enabled = true,
   }
end


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

include("lualibs/util.lua")

if (not gadgetHandler:IsSyncedCode()) then
    return
end


local spAddUnitDamage = Spring.AddUnitDamage
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitRotation = Spring.GetUnitRotation
local spGetUnitDirection = Spring.GetUnitDirection
local spGetUnitRadius = Spring.GetUnitRadius
local spGetUnitDefID = Spring.GetUnitDefID
local spGetGroundHeight = Spring.GetGroundHeight
local spGetSmoothMeshHeight = Spring.GetSmoothMeshHeight
local spGetUnitHealth = Spring.GetUnitHealth
local spSetUnitHealth = Spring.SetUnitHealth
local spUseUnitResource = Spring.UseUnitResource
local spGetUnitVelocity = Spring.GetUnitVelocity
local spSetRelativeVelocity = Spring.MoveCtrl.SetRelativeVelocity
local spSetUnitVelocity = Spring.SetUnitVelocity
local spSetUnitPhysics = Spring.SetUnitPhysics
local spSetUnitRotation = Spring.SetUnitRotation
local spSetUnitPosition = Spring.SetUnitPosition
local spSetUnitDirection = Spring.SetUnitDirection
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGetCommandQueue = Spring.GetCommandQueue
local spGetGameFrame = Spring.GetGameFrame
local spGetUnitIsActive = Spring.GetUnitIsActive
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spSetUnitRulesParam = Spring.SetUnitRulesParam
local spCallCOBScript = Spring.CallCOBScript
local spGetFeatureVelocity = Spring.GetFeatureVelocity
local spGetFeaturePosition = Spring.GetFeaturePosition
local spGetFeatureRadius = Spring.GetFeatureRadius
local spPlaySoundFile = Spring.PlaySoundFile
local spSpawnCEG = Spring.SpawnCEG
local spSetProjectileCollision = Spring.SetProjectileCollision
local spGetProjectilePosition = Spring.GetProjectilePosition
local spGetProjectileVelocity = Spring.GetProjectileVelocity
local spSpawnProjectile = Spring.SpawnProjectile
local spDestroyUnit = Spring.DestroyUnit
local spUnitDetach = Spring.UnitDetach
local spGetUnitTransporter = Spring.GetUnitTransporter
local spGetUnitIsTransporting = Spring.GetUnitIsTransporting
local spGetGroundNormal = Spring.GetGroundNormal
local spSetFeatureMidAndAimPos = Spring.SetFeatureMidAndAimPos
local spSetFeatureVelocity = Spring.SetFeatureVelocity
local spSetFeaturePosition = Spring.SetFeaturePosition
local spSetFeatureRotation = Spring.SetFeatureRotation
local spSetFeatureMoveCtrl = Spring.SetFeatureMoveCtrl
local spGetFeatureCollisionVolumeData = Spring.GetFeatureCollisionVolumeData
local spSetFeaturePhysics = Spring.SetFeaturePhysics
local spSetFeatureResources = Spring.SetFeatureResources
local spCreateFeature = Spring.CreateFeature
local spAddUnitImpulse = Spring.AddUnitImpulse
local spGetUnitCollisionVolumeData = Spring.GetUnitCollisionVolumeData
local spGetFeatureDefID = Spring.GetFeatureDefID 
local spGetFeatureTeam = Spring.GetFeatureTeam 
local spGetFeatureDirection = Spring.GetFeatureDirection
local spDestroyFeature = Spring.DestroyFeature
local spCreateUnit = Spring.CreateUnit
local spSetFeatureResurrect = Spring.SetFeatureResurrect
local spGetFeatureResources = Spring.GetFeatureResources

local random = math.random
local floor = math.floor
local min = math.min
local abs = math.abs

local WATER_DEALS_DAMAGE = Game.waterDamage > 0

local groundCollisionCEG = "COLLISION"
local waterCollisionCEG = "COLLISION"

local groundCollisionSound = "Sounds/XPLOSML2.wav"
local waterCollisionSound = "Sounds/SPLSLRG.wav"

local nanoExplosionCEG = "NANOFRAMEBLAST"
local nanoExplosionSound = "Sounds/NECRNAN2.wav"
local extraDeathEffectsCEG = "EXTRADEATHEFFECTS"

local STUCK_CHECK_DELAY_FRAMES = 10
local MOVING_CHECK_DELAY_FRAMES = 10
local COLLISION_SPEED_THRESHOLD = 5
local COLLISION_SPEED_MOD = 0.1
local GROUND_COLLISION_H_THRESHOLD = 30

local AIRCRAFT_DEBRIS_METAL_FACTOR = 0.3

local COMSAT_SCAN_DURATION_FRAMES = 900		-- 30s

local SCOPER_SCAN_DURATION_FRAMES = 25		-- about 1s

local moveAnimationUnitIds = {}
local unitPhysicsById = {}
local featureIds = {}
local featurePhysicsById = {}
local magnetarUnitIds = {}
local comsatBeacons = {}
local scoperBeacons = {}
local comsatBeaconDefId = UnitDefNames["cs_beacon"].id
local scoperBeaconDefId = UnitDefNames["scoper_beacon"].id

local noWreckDefIds = {}
local dropWreckShardsDefIds = {}
local nanoDestructionMightLeaveWreckDefIds = {}


local TOTEM_COST_FRACTION = 0.03
local TOTEM_MAX_CHARGES = 1000
local TOTEM_MAX_METAL = 300
local TOTEM_SQ_RADIUS = 600*600
local totemDefId = UnitDefNames["claw_totem"].id
local totemUnitIds = {}

local TOMBSTONE_COST_FRACTION = 1
local TOMBSTONE_MAX_CHARGES = 1000
local TOMBSTONE_MAX_METAL = 1000
local TOMBSTONE_SQ_RADIUS = 600*600
local tombstoneDefId = UnitDefNames["claw_tombstone"].id
local tombstoneUnitIds = {}

local maxSlopeByUnitDefId = {}
local floatingGroundDefIds = {}
local stuckGroundUnitIds = {}

local autoResurrectFeatureDefIds = {
	[FeatureDefNames["sphere_returner_dead"].id] = {"sphere_returner",60*30},
	[FeatureDefNames["sphere_revenant_dead"].id] = {"sphere_revenant",60*30}
}
local autoResurrectFeatures = {}   -- featureID, {unitName,creationFrame,totalFrames,remainingFrames,teamId} 
local createCEG = "buildcreated"
local buildCEG = "buildprogress"

GG.destructibleProjectilesDestroyed = {}


local destructibleProjectileDefIds = {
	[UnitDefNames["aven_premium_nuclear_rocket"].id] = true,
	[UnitDefNames["aven_nuclear_rocket"].id] = true,
	[UnitDefNames["aven_dc_rocket"].id] = true,
	[UnitDefNames["aven_lightning_rocket"].id] = true,
	[UnitDefNames["gear_premium_nuclear_rocket"].id] = true,
	[UnitDefNames["gear_nuclear_rocket"].id] = true,
	[UnitDefNames["gear_dc_rocket"].id] = true,
	[UnitDefNames["gear_pyroclasm_rocket"].id] = true,
	[UnitDefNames["claw_premium_nuclear_rocket"].id] = true,
	[UnitDefNames["claw_nuclear_rocket"].id] = true,
	[UnitDefNames["claw_dc_rocket"].id] = true,
	[UnitDefNames["claw_impaler_rocket"].id] = true,
	[UnitDefNames["sphere_premium_nuclear_rocket"].id] = true,
	[UnitDefNames["sphere_nuclear_rocket"].id] = true,
	[UnitDefNames["sphere_dc_rocket"].id] = true,
	[UnitDefNames["sphere_meteorite_rocket"].id] = true
}
local destructibleProjectileUnitIds = {}
local destructibleProjectileInitialPositionByUnitId = {}

-- these are used to warp back aircraft that flew off the map due to an engine bug
local mapSizeX = Game.mapSizeX
local mapSizeZ = Game.mapSizeZ


local function sqDistance(x1,x2,z1,z2)
	return (x2-x1)*(x2-x1)+(z2-z1)*(z2-z1)
end 
 

local x,y,z,vx,vy,vz,v,h,rx,ry,rz, enableGC,rv
local nx,ny,nz,slope
local physics, transportedUnits
local function updateUnitPhysics(unitId)
	x,y,z = spGetUnitPosition(unitId)
	vx,vy,vz,v = spGetUnitVelocity(unitId)
	rx,ry,rz = spGetUnitRotation(unitId)
	
	if not x then
		return
	end	
	
	if comsatBeacons[unitId] or scoperBeacons[unitId] then
		spSetUnitVelocity(unitId,0,0,0)
	end
	-- force physics for magnetar to prevent it from being pushed away 
	if magnetarUnitIds[unitId] == true then
		local dashFrames = spGetUnitRulesParam(unitId, "dashFrames")
		if (not dashFrames or dashFrames == 0) then
			local smHeight = spGetSmoothMeshHeight(x,z)
			h = y - smHeight
			if (h > 100 and vy > 0.01) or v > 1.5 then
				--Spring.Echo("enforced vy for magnetar vy="..vy.." v="..v)
				spSetUnitVelocity(unitId,vx * 0.8/v,0,vz * 0.8/v)
			end
		end
	end
	
	-- force stuck ground units to slide down the slope, give them a push
	if stuckGroundUnitIds[unitId] == true then
		nx,ny,nz,slope = spGetGroundNormal(x,z,true)
		h = abs(y - spGetGroundHeight(x,z))
		if (v < 0.3 and h < 10 ) then
			--Spring.Echo("moving stuck unit at ("..x..";"..y..";"..z..") n=("..nx..";"..ny..";"..nz..") slope="..slope)
		
			spSetUnitPosition(unitId,x+(5+random(10))*nx,y+1*ny,z+(5+random(10))*nz)
			local dx,dy,dz = spGetUnitDirection(unitId) 
			spSetUnitDirection(unitId,0.7*dx+0.3*nx,dy,0.7*dz+0.3*nz)
			spAddUnitImpulse(unitId,0.1*nx,0.1,0.1*nz)
		end
	end
	
	-- force physics to prevent idle air transports carrying stuff from diving into fog, lava, etc.
	-- TODO workaround for spring engine bug, remove when possible
	if WATER_DEALS_DAMAGE then
		transportedUnits = spGetUnitIsTransporting(unitId)
		if (transportedUnits and #transportedUnits > 0) then
			local groundHeight = spGetGroundHeight(x,z)
			if (groundHeight < 0 and y < 250 and vy < 0) then
				--Spring.Echo("enforced vy for air transport vy="..vy.." v="..v)
				spSetUnitVelocity(unitId,vx,y < 200 and 2 or (2*abs(y-200) / 200),vz)
			end
		end
	end
	 
	-- attach destructible unit ids to the projectile if it's in flight 
	if destructibleProjectileUnitIds[unitId] == true then
		if not destructibleProjectileInitialPositionByUnitId[unitId] then
			destructibleProjectileInitialPositionByUnitId[unitId] = {x=x,y=y,z=z}
		end
		
		local proId = spGetUnitRulesParam(unitId,"destructible_projectile_id")
		if (proId) then
			x,y,z = spGetProjectilePosition(proId)
			vx,vy,vz,v = spGetProjectileVelocity(proId)
			
			if(spGetUnitTransporter(unitId)) then
				--Spring.Echo("proj. still attached! "..unitId.." x="..tostring(x).." vx="..tostring(vx))
				spUnitDetach(unitId)
			end
			
			if (x and vx) then
				--Spring.Echo("v="..(v*30))
				--Spring.Echo(spGetGameFrame().." vx="..tostring(vx/v).." vy="..tostring(vy/v).." vz="..tostring(vz/v))
				spSetUnitPhysics(unitId,x+2*vx,y+2*vy,z+2*vz,vx,vy,vz,0,0,0,0,0,0)
				--Spring.SetUnitDirection(unitId,vx/v,vy/v,vz/v)
				--spSetUnitPhysics(unitId,x+3*vx,y+3*vy,z+3*vz,vx,vy,vz,0,0,0,0,0,0)
				--Spring.SetUnitDirection(unitId,0,-1,0)
			end
		--else
			--local p = destructibleProjectileInitialPositionByUnitId[unitId]
			-- hold it in place
			--spSetUnitPhysics(unitId,p.x,p.y,p.z,0,0,0,0,0,0,0,0,0)
		end
	end
end

local function updateFeaturePhysics(featureId)
	x,y,z = spGetFeaturePosition(featureId)
	vx,vy,vz,v = spGetFeatureVelocity(featureId)
end

-- checks if a unit is stuck by testing slope
local function checkStuck(unitId,defId,x,y,z,v)
	if (maxSlopeByUnitDefId[defId] and v < 0.1) then
		if (spGetUnitTransporter(unitId)) then
			return false
		end
		
		h = spGetGroundHeight(x,z)
		if (y-h > 5) then
			return false
		end
		
		if spGetUnitRulesParam(unitId, "is_jumping") == 1 then
			return false
		end
		
		-- floating stuff over water doesn't get stuck
		if (floatingGroundDefIds[defId] and h < 0) then
			return false
		end
	
		_,_,_,slope = spGetGroundNormal(x,z)
		if slope > maxSlopeByUnitDefId[defId] then
			return true
		end
		
		-- check nearby positions, justincase
		for dx=-8,8,16 do
			for dz=-8,8,16 do
				_,_,_,slope = spGetGroundNormal(x+dx,z+dz)
				if slope > maxSlopeByUnitDefId[defId] then
					return true
				end
			end
		end
	end
	return false
end

local function randomNegative(scale)
	return (random() * scale * 2 - scale)
end

local function setFeaturePhysics(featureId,x,y,z,vx,vy,vz)
	spSetFeatureMoveCtrl(featureId,false,1,1,1,1,1,1,1,1,1)
	spSetFeaturePosition(featureId,x,y,z)
	spSetFeatureVelocity(featureId,vx,vy,vz)
	spSetFeatureRotation(featureId,randomNegative(1),randomNegative(1),randomNegative(1))
end

local function isDrone(ud)
  return(ud and ud.customParams and ud.customParams.isdrone)
end

local function isFeatureSpawner(ud)
  return(ud and ud.isFeature == true)
end

-- check if relevant enemy unit that was destroyed is within radius of totems or similar units
local function checkDeathTrackersRadius(ud,unitId)
	local metalCost = 0
	if ud.customParams and ud.customParams.iscommander then
		metalCost = 500
		--Spring.Echo("commander died")
	else
		metalCost = ud.metalCost
	end
	
	-- totem
	local totalTotemChargesToAdd = TOTEM_COST_FRACTION * metalCost * TOTEM_MAX_CHARGES / TOTEM_MAX_METAL  
	local physics = unitPhysicsById[unitId]
	local totemPhysics = nil
	local affectedTotemIds = {}
	for tId,_ in pairs(totemUnitIds) do
		totemPhysics = unitPhysicsById[tId]
		if sqDistance(physics[1],totemPhysics[1],physics[3],totemPhysics[3]) < TOTEM_SQ_RADIUS then
			affectedTotemIds[#affectedTotemIds+1] = tId
		end
	end
	local affectedTotems = #affectedTotemIds
	for _,tId in ipairs(affectedTotemIds) do
		--Spring.Echo("totem "..tId.." charges="..floor(totalTotemChargesToAdd / affectedTotems))
		spCallCOBScript(tId, "addCharges", 0, floor(totalTotemChargesToAdd / affectedTotems))
	end
	
	-- tombstone
	local totalTombstoneChargesToAdd = TOMBSTONE_COST_FRACTION * metalCost * TOMBSTONE_MAX_CHARGES / TOMBSTONE_MAX_METAL  
	local physics = unitPhysicsById[unitId]
	local tombstonePhysics = nil
	local affectedTombstoneIds = {}
	for tId,_ in pairs(tombstoneUnitIds) do
		tombstonePhysics = unitPhysicsById[tId]
		if sqDistance(physics[1],tombstonePhysics[1],physics[3],tombstonePhysics[3]) < TOMBSTONE_SQ_RADIUS then
			affectedTombstoneIds[#affectedTombstoneIds+1] = tId
		end
	end
	local affectedTombstones = #affectedTombstoneIds
	for _,tId in ipairs(affectedTombstoneIds) do
		-- Spring.Echo("tombstone "..tId.." charges="..floor(totalTombstoneChargesToAdd / affectedTombstones))
		spCallCOBScript(tId, "addCharges", 0, floor(totalTombstoneChargesToAdd / affectedTombstones))
	end
end


------------------------------------------- engine callins

function gadget:Initialize()
	for defId,ud in pairs(UnitDefs) do
		local cp = ud.customParams
		if cp and cp.nowreck == "1" then
			noWreckDefIds[defId] = true
		end
		if (not ud.isImmobile) and not (ud.canFly) then
			if ud.moveDef and ud.moveDef.maxSlope and ud.moveDef.maxSlope < 0.5 then
				maxSlopeByUnitDefId[defId] = ud.moveDef.maxSlope
				--Spring.Echo(ud.name.." maxSlope="..ud.moveDef.maxSlope)
				
				if (string.find(tostring(ud.moveDef.name),"hover")) then
					floatingGroundDefIds[defId] = true
				end
			end 
		end

		if (not noWreckDefIds[defId]) and ud.canFly == true and (not destructibleProjectileDefIds[defId]) and (defId ~= comsatBeaconDefId) and (defId ~= scoperBeaconDefId) and (not isDrone(ud)) and tostring(ud.wreckName) == ''  then
			dropWreckShardsDefIds[defId] = true
		elseif (not isDrone(ud)) and (not isFeatureSpawner(ud)) and (tostring(ud.wreckName) ~= '') then
			nanoDestructionMightLeaveWreckDefIds[defId] = true
		end

	end
end

function gadget:UnitCreated(unitId, unitDefId, unitTeam)
	local ud = UnitDefs[unitDefId]
	
	if (ud.isGroundUnit) and (not ud.isBuilding) and (not ud.isImmobile) then
		moveAnimationUnitIds[unitId] = true
	end
	
	if ud.name == "sphere_magnetar" then
		magnetarUnitIds[unitId] = true
	end
	if (unitDefId == totemDefId ) then
		totemUnitIds[unitId] = true
	elseif (unitDefId == tombstoneDefId ) then
		tombstoneUnitIds[unitId] = true
	end

	if (unitDefId == comsatBeaconDefId ) then
		comsatBeacons[unitId] = 1
	end
	if (unitDefId == scoperBeaconDefId ) then
		scoperBeacons[unitId] = 1
	end
	
	if destructibleProjectileDefIds[unitDefId] then
		destructibleProjectileUnitIds[unitId] = true
	end

	-- x,y,z,vx,vy,vz,h,enableGC,rx,ry,rz,v
	unitPhysicsById[unitId] = {0,0,0,0,0,0,0,false,0,0,0,0}
end

function gadget:GameFrame(n)
	
	-- increment counter for comsat beacons, remove the ones that expired
	for uId,frames in pairs(comsatBeacons) do
		if (frames >= COMSAT_SCAN_DURATION_FRAMES) then
			spDestroyUnit(uId,false,true)
			comsatBeacons[uId] = nil
		else
			comsatBeacons[uId] = frames + 1
		end
	end
	for uId,frames in pairs(scoperBeacons) do
		--local ud = UnitDefs[spGetUnitDefID(uId)]
		--Spring.Echo(uId.." "..(ud and ud.name or "dead")) 
		
		if (frames >= SCOPER_SCAN_DURATION_FRAMES) then
			spDestroyUnit(uId,false,true)
			scoperBeacons[uId] = nil
		else 
			scoperBeacons[uId] = frames + 1
		end
	end
	local doMoveAnimCheck = n%MOVING_CHECK_DELAY_FRAMES == 0
	local doStuckCheck = n%STUCK_CHECK_DELAY_FRAMES == 0
	local ys,submergedDepth,fullySubmergedDepth
	-- check unit physics
	for unitId,oldPhysics in pairs(unitPhysicsById) do
		local defId = spGetUnitDefID(unitId)
		
		-- get updated physics
		updateUnitPhysics(unitId)

		if x then
			groundHeight = spGetGroundHeight(x,z)
			h = y - groundHeight
			-- prevent repeated collisions when walking down slopes
			if h > GROUND_COLLISION_H_THRESHOLD then
				enableGC = true
			else 
				enableGC = oldPhysics[8]
			end
			
			-- workaround for engine not calling StartMoving when it should in some situations
			if (doMoveAnimCheck) then
				if moveAnimationUnitIds[unitId] then
					-- a sort of rotational speed
					rv = abs(rx - oldPhysics[9]) + abs(ry - oldPhysics[10]) + abs(rz - oldPhysics[11])  
					
					--Spring.Echo("vx="..vx.." vz="..vz.." rx="..rx.." ry="..ry.." rz="..rz.." rv="..rv)
					if abs(vx) > 0.1 or abs(vz) > 0.1 or rv > 0 then
						if abs(h) < 3 or y <= 0 then
							spCallCOBScript(unitId,"StartMoving",0)
						end
					else
						spCallCOBScript(unitId,"StopMoving",0)			
					end
				end
			end

			if (groundHeight > 0) then
				-- check for high speed ground impact
				if oldPhysics[7] > 0 and h <= 0 and enableGC == true then
					
					-- only trigger this if moving fast
					if abs(oldPhysics[5]) > COLLISION_SPEED_THRESHOLD then
						local radius = spGetUnitRadius(unitId) * 2 * (1 + COLLISION_SPEED_MOD * abs(oldPhysics[5]))
						--Spring.Echo("unit "..unitId.." ground collision at frame "..n.." radius="..radius.." speed="..abs(oldPhysics[5]))
						spSpawnCEG(groundCollisionCEG, x,groundHeight+5,z,0,1,0,radius,radius)
						spPlaySoundFile(groundCollisionSound, math.min(1,math.max(0.2,radius/50)), x, y, z)
						enableGC = false
					end
				end
			else
				-- check for high speed water impact
				if (oldPhysics[2] > 0 and y <= 0) or (oldPhysics[2] <= 0 and y > 0 ) then
					if abs(oldPhysics[5]) > COLLISION_SPEED_THRESHOLD then
						local radius = spGetUnitRadius(unitId) * 2 * (1 + COLLISION_SPEED_MOD * abs(oldPhysics[5]))
						-- ascending collision is less intense
						if oldPhysics[5] > 0 then
							radius = radius * 0.66
						end
						
						--Spring.Echo("unit "..unitId.." water collision at frame "..n.." radius="..radius)
						spSpawnCEG(waterCollisionCEG, x,3,z,0,1,0,radius,radius)
						spPlaySoundFile(waterCollisionSound, math.min(1,math.max(0.2,radius/50)), x, y, z)
						enableGC = false
					end
				end
			end
		
			-- check if unit is stuck
			if (doStuckCheck) then
				if (checkStuck(unitId,defId,x,y,z,v)) then
					if not stuckGroundUnitIds[unitId] then
						--Spring.Echo(unitId.." is stuck!")
						stuckGroundUnitIds[unitId] = true
					end
				else
					if stuckGroundUnitIds[unitId] then
						--Spring.Echo(unitId.." is no longer stuck")
						stuckGroundUnitIds[unitId] = nil
					end
				end
			end
			
			-- update submerged status
			 _, ys, _, _, _, _, _, _, _,_ = spGetUnitCollisionVolumeData(unitId)
			submergedDepth = 0
			fullySubmergedDepth = 0
			if (groundHeight < 0) then
				if (y < 0) then
					submergedDepth = abs(y)
					if (submergedDepth > ys) then
						fullySubmergedDepth = submergedDepth - ys
					end
				end
			end
			spSetUnitRulesParam(unitId,"submergedDepth",submergedDepth)
			spSetUnitRulesParam(unitId,"fullySubmergedDepth",fullySubmergedDepth)
			--Spring.Echo("unitId="..unitId.." submergedDepth="..submergedDepth.." fullySubmergedDepth="..fullySubmergedDepth)
			
			-- update physics
			oldPhysics[1] = x
			oldPhysics[2] = y
			oldPhysics[3] = z
			oldPhysics[4] = vx
			oldPhysics[5] = vy
			oldPhysics[6] = vz
			oldPhysics[7] = h
			oldPhysics[8] = enableGC
			oldPhysics[9] = rx
			oldPhysics[10] = ry
			oldPhysics[11] = rz
			oldPhysics[12] = v
		end
	end

	-- feature physics
	local arInfo,sx,recLeft, progress, tId,size
	for featureId,oldPhysics in pairs(featurePhysicsById) do
		-- handle auto-resurrection
		arInfo = autoResurrectFeatures[featureId]
		if arInfo then
			arInfo[4] = arInfo[4] - 1
			if arInfo[4] < 900 then -- only start 30s later
				_,_,_,_,recLeft,_ = spGetFeatureResources(featureId)
				if recLeft == 1 then
					progress = 1 - arInfo[4]/(arInfo[3]-900) 
					spSetFeatureResurrect(featureId, arInfo[1],0,progress )
					sx = spGetFeatureCollisionVolumeData(featureId)
					
					-- show effects					
					size = sx*0.25*(1+2*progress)
					x = oldPhysics[1]
					y = oldPhysics[2]
					z = oldPhysics[3]

					if arInfo[4] % 3 == 0 then
						spSpawnCEG( buildCEG, x -size*0.5 +random()*size, y+random()*size+3, z-size*0.5+random()*size,0,1,0,1,size*0.15)
						spSpawnCEG( buildCEG, x -size*0.5 +random()*size, y+random()*size+3, z-size*0.5+random()*size,0,1,0,1,size*0.15)
					end
					
					-- if finished.. 
					if progress == 1 then
						tId = spGetFeatureTeam(featureId)
						local dx,dy,dz = spGetFeatureDirection(featureId)
							 			
						-- remove the feature
						spDestroyFeature(featureId)
						 
						-- spawn the unit with 50% hp
						local uId = spCreateUnit(arInfo[1],x,y,z,0,tId,false)
						if uId then
							Spring.SetUnitDirection(uId,dx,dy,dz)
							local _,maxHealth,_,_,_ = Spring.GetUnitHealth(uId) 
							spSetUnitHealth(uId,maxHealth * 0.5)
							spSpawnCEG( createCEG, x , y+3, z,0,1,0,1,size*0.2)
						end
					end
				else
					-- already partially reclaimed, disable auto-resurrect
					spSetFeatureResurrect(featureId, arInfo[1],0,0 )
					autoResurrectFeatures[featureId] = nil
				end
			end
		end
	
		-- get updated physics
		updateFeaturePhysics(featureId)
		
		groundHeight = spGetGroundHeight(x,z)
		h = y - groundHeight
		-- prevent repeated collisions when sliding down slopes
		if h > GROUND_COLLISION_H_THRESHOLD then
			enableGC = true
		else 
			enableGC = oldPhysics[8]
		end
		
		if (groundHeight > 0) then
			-- check for high speed ground impact
			if oldPhysics[7] > 0 and h <= 0 and enableGC == true then
				
				-- only trigger this if moving fast
				if abs(oldPhysics[5]) > COLLISION_SPEED_THRESHOLD then
					local radius = spGetFeatureRadius(featureId) * 2 * (1 + COLLISION_SPEED_MOD * abs(oldPhysics[5]))
					--Spring.Echo("feature "..featureId.." ground collision at frame "..n.." radius="..radius)
					spSpawnCEG(groundCollisionCEG, x,groundHeight+5,z,0,1,0,radius,radius)
					spPlaySoundFile(groundCollisionSound, math.min(1,math.max(0.2,radius/50)), x, y, z)
					enableGC = false
				end
			end
		else
			-- check for high speed water impact
			if oldPhysics[2] > 0 and y <= 0 then
				if abs(oldPhysics[5]) > COLLISION_SPEED_THRESHOLD then
					local radius = spGetFeatureRadius(featureId) * 2 * (1 + COLLISION_SPEED_MOD * abs(oldPhysics[5]))
					--Spring.Echo("feature "..featureId.." water collision at frame "..n.." radius="..radius)
					spSpawnCEG(waterCollisionCEG, x,3,z,0,1,0,radius,radius)
					spPlaySoundFile(waterCollisionSound, math.min(1,math.max(0.2,radius/50)), x, y, z)
					enableGC = false
				end
			end
		end
		
		-- update physics
		oldPhysics[1] = x
		oldPhysics[2] = y
		oldPhysics[3] = z
		oldPhysics[4] = vx
		oldPhysics[5] = vy
		oldPhysics[6] = vz
		oldPhysics[7] = h
		oldPhysics[8] = enableGC
	end
end

-- cleanup when some units are destroyed
function gadget:UnitDestroyed(unitId, unitDefId, unitTeam,attackerId, attackerDefId, attackerTeamId)
	-- remove entries from tables when unit is destroyed
	if (moveAnimationUnitIds[unitId]) then
		moveAnimationUnitIds[unitId] = nil
	end

	if magnetarUnitIds[unitId] then
		magnetarUnitIds[unitId] = nil
	end
	if (totemUnitIds[unitId] ) then
		totemUnitIds[unitId] = nil
	elseif (tombstoneUnitIds[unitId] ) then
		tombstoneUnitIds[unitId] = nil
	end
	
	if comsatBeacons[unitId] then
		comsatBeacons[unitId] = nil
	end
	if scoperBeacons[unitId] then
		scoperBeacons[unitId] = nil
	end	
	
	if stuckGroundUnitIds[unitId] then
		stuckGroundUnitIds[unitId] = nil
	end
	
	if destructibleProjectileDefIds[unitDefId] then
		destructibleProjectileUnitIds[unitId] = nil
		destructibleProjectileInitialPositionByUnitId[unitId] = nil
		GG.destructibleProjectilesDestroyed[unitId] = true
	end

	local _,_,_,_,bp = spGetUnitHealth(unitId)
	-- if unit is an aircraft which leaves no wreckage, spawn some debris
	local ud = UnitDefs[unitDefId]
	if dropWreckShardsDefIds[unitDefId] == true then
		if bp > 0.999 or (attackerId ~= nil and bp > 0.5) then
			--Spring.Echo("aircraft destroyed "..tostring(ud.wreckName))
			local physics = unitPhysicsById[unitId]
			if (physics ~= nil) then
				--Spring.Echo("aircraft destroyed had physics!")
				local metalAmount = ud.metalCost * AIRCRAFT_DEBRIS_METAL_FACTOR
				local fId = nil
				local radius = spGetUnitRadius(unitId) * 0.8 + ud.metalCost *0.002 
				local spawnName = nil
				local smallPieceV = 2
				local largePieceV = 1
				
				--Spring.Echo("radius="..tostring(radius).." metalAmount="..tostring(metalAmount).." vx="..physics[4].." vy="..physics[5].." vz="..physics[6])
				if metalAmount < 300 then
					-- spawn small debris only
					for i=0,metalAmount,50 do
						spawnName = "debris"..tostring(random(3))
						--Spring.Echo("spawning "..spawnName)
						fId = spCreateFeature(spawnName,physics[1],physics[2],physics[3],random(4)-1)
						if (fId) then
							setFeaturePhysics(fId,physics[1] + random(radius),physics[2],physics[3] + random(radius),randomNegative(smallPieceV)+physics[4],randomNegative(smallPieceV)+physics[5],randomNegative(smallPieceV)+physics[6])
							if metalAmount < 50 then
								spSetFeatureResources(fId,metalAmount,0)
							end
						end
					end
				else 
					-- spawn small debris
					for i=0,floor(metalAmount/2),50 do
						spawnName = "debris"..tostring(random(3))
						--Spring.Echo("spawning "..spawnName)
						fId = spCreateFeature(spawnName,physics[1],physics[2],physics[3],random(4)-1)	
						if (fId) then
							setFeaturePhysics(fId,physics[1] + random(radius),physics[2],physics[3] + random(radius),randomNegative(smallPieceV)+physics[4],randomNegative(smallPieceV)+physics[5],randomNegative(smallPieceV)+physics[6])
						end
					end
					-- spawn large debris
					for i=0,floor(metalAmount/2),100 do
						spawnName = "debris"..tostring(random(4,6))
						--Spring.Echo("spawning "..spawnName)
						fId = spCreateFeature(spawnName,physics[1],physics[2],physics[3],math.random(4)-1)
						if (fId) then
							setFeaturePhysics(fId,physics[1] + random(radius),physics[2],physics[3] + random(radius),randomNegative(largePieceV)+physics[4],randomNegative(largePieceV)+physics[5],randomNegative(largePieceV)+physics[6])
						end
					end
				end
				-- spawn extra death effects
				--Spring.Echo("spawning death effects for "..unitId.." radius="..radius)
				spSpawnCEG(extraDeathEffectsCEG, physics[1],physics[2],physics[3],0,1,0,radius,radius)
			end
		end
	-- unit was not fully built but leaves wreckage		
	elseif (nanoDestructionMightLeaveWreckDefIds[unitDefId] and attackerId ~= nil) then
		--Spring.Echo("attackerId="..tostring(attackerId).." attackerDefId="..tostring(attackerDefId).." attackerTeamId="..tostring(attackerTeamId))
		
		local physics = unitPhysicsById[unitId]
		
		if (physics ~= nil) then
			local radius = spGetUnitRadius(unitId) * 0.8
			local dx,dy,dz = spGetUnitDirection(unitId)
			--Spring.Echo("dx="..tostring(dx).." dz="..tostring(dz))
			
			-- bigger effect for expensive units
			radius = radius + ud.metalCost *0.002 

			
			if (bp > 0.5) then
				-- under construction but past halfway, spawn explosion and wreck
				if (bp < 1) then
					local dir = 0
					if abs(dx) > abs(dz) then
						if dx > 0 then
							dir = 1
						else 
							dir = 3
						end
					else
						if dz > 0 then
							dir = 0
						else 
							dir = 2
						end
					end
					--Spring.Echo("dir="..dir)
					
					-- create actual explosion
					local createdId = spSpawnProjectile(WeaponDefNames[ud.deathExplosion].id,{
						["pos"] = {physics[1],physics[2]+radius*0.33,physics[3]},
						["end"] = {physics[1],physics[2]+radius*0.33,physics[3]},
						["speed"] = {0,1,0},
						["owner"] = unitTeam
					})
					if (createdId) then
						spSetProjectileCollision(createdId)
					end
					
					-- create feature
					fId = spCreateFeature(ud.wreckName,physics[1],physics[2],physics[3],dir)
				end
				
				-- spawn extra death effects
				--Spring.Echo("spawning death effects for "..unitId.." radius="..radius)
				spSpawnCEG(extraDeathEffectsCEG, physics[1],physics[2],physics[3],0,1,0,radius,radius)
			end
		end	
	end

	-- if nano frame, spawn effects
	if bp < 1 and bp > 0.35 then
		local physics = unitPhysicsById[unitId]
		if (physics ~= nil) then
			local radius = spGetUnitRadius(unitId)
						
			-- bigger effect for expensive units
			radius = radius + ud.metalCost / 1000 
			
			spSpawnCEG(nanoExplosionCEG, physics[1],physics[2],physics[3],0,1,0,radius,radius)
			spPlaySoundFile(nanoExplosionSound, math.min(1,math.max(0.2,radius/50)), physics[1], physics[2], physics[3])
		end
	end

	-- charge totems and tombstones (only from fully built units)
	if ud and bp == 1 and (not destructibleProjectileDefIds[unitDefId]) and (unitDefId ~= comsatBeaconDefId) and (unitDefId ~= scoperBeaconDefId) and not isDrone(ud) then
		checkDeathTrackersRadius(ud,unitId)
	end

	unitPhysicsById[unitId] = nil
end

function gadget:FeatureCreated(featureId, allyTeam)
	featureIds[featureId] = true
	-- x,y,z,vx,vy,vz,h,enableGC
	featurePhysicsById[featureId] = {0,0,0,0,0,0,0,false}
	
	-- adjust the collision volume positions
	local xs, ys, zs, xo, yo, zo, vtype, htype, axis, _ = spGetFeatureCollisionVolumeData(featureId)
	if (xs and xo) then
		spSetFeatureMidAndAimPos(featureId,0, ys*0.5, 0,0, ys*0.75+yo,0,true)
	end
	
	local arDefInfo = autoResurrectFeatureDefIds[spGetFeatureDefID(featureId)]
	if arDefInfo then
		-- Spring.Echo("auto-resurrect feature "..featureId)
		autoResurrectFeatures[featureId] = {arDefInfo[1],spGetGameFrame(),arDefInfo[2],arDefInfo[2]}
	end
end

-- cleanup when features are destroyed
function gadget:FeatureDestroyed(featureId, allyTeam)
	featureIds[featureId] = nil
	featurePhysicsById[featureId] = nil
	autoResurrectFeatures[featureId] = nil
end


-- prevent nano frames from using self-D
function gadget:AllowCommand(unitId, unitDefId, unitTeam, cmdId, cmdParams, cmdOptions, cmdTag, synced)
	if cmdId == CMD.SELFD then
		local _,_,_,_,bp = spGetUnitHealth(unitId)
		if bp < 1 then
			return false
		end
	end 
	return true
end

