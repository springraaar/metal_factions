function gadget:GetInfo()
   return {
      name = "Drone Handler",
      desc = "Spawns drones and gives orders.",
      author = "raaar",
      date = "June 2016",
      license = "PD",
      layer = 0,
      enabled = true,
   }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
include("LuaLibs/Util.lua")

if (not gadgetHandler:IsSyncedCode()) then
    return
end

local CMD_MOVE_STATE    = CMD.MOVE_STATE
local CMD_PATROL        = CMD.PATROL
local CMD_STOP          = CMD.STOP
local spGetGameFrame    = Spring.GetGameFrame
local spGetUnitTeam    = Spring.GetUnitTeam
local spGetTeamUnits    = Spring.GetTeamUnits
local spGetUnitCommands = Spring.GetUnitCommands
local spGetUnitDefID    = Spring.GetUnitDefID
local spGetUnitPosition = Spring.GetUnitPosition
local spSetUnitPosition = Spring.SetUnitPosition
local spGetUnitVelocity = Spring.GetUnitVelocity
local spSetUnitVelocity = Spring.SetUnitVelocity
local spGetUnitDirection = Spring.GetUnitDirection
local spSetUnitDirection = Spring.SetUnitDirection
local spGetUnitRotation = Spring.GetUnitRotation
local spSetUnitRotation = Spring.SetUnitRotation
local spSetUnitPhysics = Spring.SetUnitPhysics
local spGetUnitVectors = Spring.GetUnitVectors
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spCreateUnit = Spring.CreateUnit
local spGetUnitHealth = Spring.GetUnitHealth
local spSetUnitHealth = Spring.SetUnitHealth
local spGetAllUnits = Spring.GetAllUnits
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spSpawnCEG = Spring.SpawnCEG
local spGetTeamResources = Spring.GetTeamResources
local spUseUnitResource = Spring.UseUnitResource
local spDestroyUnit = Spring.DestroyUnit

local hmsx = Game.mapSizeX/2
local hmsz = Game.mapSizeZ/2
local fmod = math.fmod
local random = math.random

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local idleFrames = 30

local droneOwnersLimits = {}  -- set of drone unit names and limits by unit id  
local droneOwnersDrones = {}  -- set of drone unit names and quantities by unit id
local droneOwnersQueues = {}  -- list of drone unit names to be spawned by unit id
local droneOwnersLastBuildStepFrameNumber = {} -- last build step for each drone owner
local droneUnderConstruction = {}  -- list of drone ids under construction by owner id
local droneBuildStalled = {}

local markedForDestruction = {}
local DRONE_CHECK_DELAY = 15		-- 2 steps per second

local LIGHT_DRONE_BUILD_STEPS = 10
local MEDIUM_DRONE_BUILD_STEPS = 20	

local DRONE_REBUILD_DELAY_STEPS = 8
local DRONE_BUILD_ENERGY_FACTOR = 1.0		
local DRONE_BUILD_ENERGY_MIN = 500

local DRONE_CONSTRUCTION_Y = 100
local LIGHT_DRONE_LEASH_DISTANCE = 600
local BUILDER_DRONE_LEASH_DISTANCE = 600
local MEDIUM_DRONE_LEASH_DISTANCE = 600
local STEALTH_DRONE_LEASH_DISTANCE = 600

local SQ_LIGHT_DRONE_LEASH_DISTANCE = LIGHT_DRONE_LEASH_DISTANCE*LIGHT_DRONE_LEASH_DISTANCE
local SQ_BUILDER_DRONE_LEASH_DISTANCE = BUILDER_DRONE_LEASH_DISTANCE*BUILDER_DRONE_LEASH_DISTANCE
local SQ_MEDIUM_DRONE_LEASH_DISTANCE = MEDIUM_DRONE_LEASH_DISTANCE*MEDIUM_DRONE_LEASH_DISTANCE
local SQ_STEALTH_DRONE_LEASH_DISTANCE = STEALTH_DRONE_LEASH_DISTANCE*STEALTH_DRONE_LEASH_DISTANCE


droneLeashSQDistances = {
	aven_light_drone = SQ_LIGHT_DRONE_LEASH_DISTANCE, 
	gear_light_drone = SQ_LIGHT_DRONE_LEASH_DISTANCE, 
	claw_light_drone = SQ_LIGHT_DRONE_LEASH_DISTANCE, 
	sphere_light_drone = SQ_LIGHT_DRONE_LEASH_DISTANCE,
	aven_medium_drone = SQ_MEDIUM_DRONE_LEASH_DISTANCE, 
	gear_medium_drone = SQ_MEDIUM_DRONE_LEASH_DISTANCE, 
	claw_medium_drone = SQ_MEDIUM_DRONE_LEASH_DISTANCE, 
	sphere_medium_drone = SQ_MEDIUM_DRONE_LEASH_DISTANCE,
	aven_adv_construction_drone = SQ_BUILDER_DRONE_LEASH_DISTANCE, 
	gear_adv_construction_drone = SQ_BUILDER_DRONE_LEASH_DISTANCE, 
	claw_adv_construction_drone = SQ_BUILDER_DRONE_LEASH_DISTANCE, 
	sphere_adv_construction_drone = SQ_BUILDER_DRONE_LEASH_DISTANCE,
	aven_stealth_drone = SQ_STEALTH_DRONE_LEASH_DISTANCE, 
	gear_stealth_drone = SQ_STEALTH_DRONE_LEASH_DISTANCE, 
	claw_stealth_drone = SQ_STEALTH_DRONE_LEASH_DISTANCE, 
	sphere_stealth_drone = SQ_STEALTH_DRONE_LEASH_DISTANCE,	
}


lightDrones = {
	"aven_light_drone", 
	"gear_light_drone", 
	"claw_light_drone", 
	"sphere_light_drone"
}

stealthDrones = {
	"aven_stealth_drone", 
	"gear_stealth_drone", 
	"claw_stealth_drone", 
	"sphere_stealth_drone"
}

avenDrones = {
	light_drones = "aven_light_drone",
	builder_drone = "aven_adv_construction_drone",
	medium_drone = "aven_medium_drone",
	stealth_drone = "aven_stealth_drone"
}
gearDrones = {
	light_drones = "gear_light_drone",
	builder_drone = "gear_adv_construction_drone",
	medium_drone = "gear_medium_drone",
	stealth_drone = "gear_stealth_drone"
}
clawDrones = {
	light_drones = "claw_light_drone",
	builder_drone = "claw_adv_construction_drone",
	medium_drone = "claw_medium_drone",
	stealth_drone = "claw_stealth_drone"
}
sphereDrones = {
	light_drones = "sphere_light_drone",
	builder_drone = "sphere_adv_construction_drone",
	medium_drone = "sphere_medium_drone",
	stealth_drone = "sphere_stealth_drone"
}


local droneNamesForUnitDefName = {
	aven_commander = avenDrones,
	aven_u1commander = avenDrones,
	aven_u2commander = avenDrones,
	aven_u3commander = avenDrones,
	aven_u4commander = avenDrones,
	aven_u5commander = avenDrones,	
	gear_commander = gearDrones,
	gear_u1commander = gearDrones,
	gear_u2commander = gearDrones,
	gear_u3commander = gearDrones,
	gear_u4commander = gearDrones,	
	gear_u5commander = gearDrones,
	claw_commander = clawDrones,
	claw_u1commander = clawDrones,
	claw_u2commander = clawDrones,
	claw_u3commander = clawDrones,
	claw_u4commander = clawDrones,
	claw_u5commander = clawDrones,
	sphere_commander = sphereDrones,
	sphere_u1commander = sphereDrones,
	sphere_u2commander = sphereDrones,
	sphere_u3commander = sphereDrones,
	sphere_u4commander = sphereDrones,
	sphere_u5commander = sphereDrones
}

local droneBuildCEG = "dronebuild"


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function getUnitPositionAndDirection(unitId)
	local x,y,z,dx,dy,dz
	x,y,z = spGetUnitPosition(unitId)
	dx,dy,dz = spGetUnitDirection(unitId)
			
	return x, y, z, dx, dy, dz
end

local function isDrone(ud)
  return(ud and ud.customParams and ud.customParams.isdrone)
end


local function drainEnergyIfAvailable(unitId, ownerId, minE, drainE)
	local teamId = spGetUnitTeam(unitId)

	-- get team energy
	local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = spGetTeamResources(teamId,"energy")

	-- if greater than threshold, drain energy and return success
	if currentLevelE > minE then
		spUseUnitResource(ownerId,"e",drainE)
		return true
	end

	-- else return failure
	return false
end


function gadget:Initialize()

end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)

end


function gadget:UnitGiven(unitID, unitDefID, unitTeam)

end


function gadget:GameFrame(n)
	-- used to avoid "DestroyUnit() recursion is not permitted" errors
	-- when commander is morphed
	for uId,ownerId in pairs(markedForDestruction) do
		spDestroyUnit(uId)
		-- markedForDestruction table is cleaned up ahead
	end
	
	if fmod(n,DRONE_CHECK_DELAY) == 0 then
		
		-- update table of units with drones
		local hasDrones = nil
		for _,unitId in ipairs(spGetAllUnits()) do
			local uName = UnitDefs[spGetUnitDefID(unitId)].name
			local set = {} 
			
			hasLight = spGetUnitRulesParam(unitId, "upgrade_light_drones")
			if hasLight then
				hasLight = tonumber(hasLight)
			end
			hasMedium = spGetUnitRulesParam(unitId, "upgrade_medium_drone")
			if hasMedium then
				hasMedium = tonumber(hasMedium)
			end
			hasBuilder = spGetUnitRulesParam(unitId, "upgrade_builder_drone")
			if hasBuilder then
				hasBuilder = tonumber(hasBuilder)
			end
			hasStealth = spGetUnitRulesParam(unitId, "upgrade_stealth_drone")
			if hasStealth then
				hasStealth = tonumber(hasStealth)
			end
						
			if hasLight and hasLight > 0 then
				set[droneNamesForUnitDefName[uName]["light_drones"]] = 2
			end
			if hasMedium and hasMedium > 0 then
				set[droneNamesForUnitDefName[uName]["medium_drone"]] = 1
			end
			if hasBuilder and hasBuilder > 0 then
				set[droneNamesForUnitDefName[uName]["builder_drone"]] = 1
			end
			if hasStealth and hasStealth > 0 then
				set[droneNamesForUnitDefName[uName]["stealth_drone"]] = 1
			end

			droneOwnersLimits[unitId] = set
			if droneOwnersQueues[unitId] == nil then
				droneOwnersQueues[unitId] = {}
			end
			if droneOwnersDrones[unitId] == nil then
				droneOwnersDrones[unitId] = {}
			end
			if droneOwnersLastBuildStepFrameNumber[unitId] == nil then
				droneOwnersLastBuildStepFrameNumber[unitId] = 0
			end
		end

		
		-- for each droner unit
		local x, y, z, dx, dy, dz, up, px, py, pz
		local teamId, inQueue
		for ownerId,limits in pairs(droneOwnersLimits) do

			-- check rebuild delay
			if (n - droneOwnersLastBuildStepFrameNumber[ownerId]) >= (DRONE_REBUILD_DELAY_STEPS * DRONE_CHECK_DELAY) then
				-- if has less drones than the allowed limits alive + in queue, add to queue
				for uName,uLimit in pairs(limits) do
					inQueue = 0
					-- count drones of that type previously added to build queue
					if #droneOwnersQueues[ownerId] > 0 then
 						for i,n in ipairs(droneOwnersQueues[ownerId]) do
 							if n == uName then
 								inQueue = inQueue + 1
 							end
 						end
 					end
					--Spring.Echo("QUEUE "..uName.." : "..inQueue.." ALIVE : "..(droneOwnersDrones[ownerId][uName] and #droneOwnersDrones[ownerId][uName] or 0) )
					if not droneOwnersDrones[ownerId][uName] or (#droneOwnersDrones[ownerId][uName] + inQueue < uLimit) then
						table.insert(droneOwnersQueues[ownerId],1,uName)
					end
				end
			
				-- if queue is not empty, remove from queue and spawn new drone
				if #droneOwnersQueues[ownerId] > 0 then
					-- get team
					teamId = spGetUnitTeam(ownerId)
				
					local uName = table.remove(droneOwnersQueues[ownerId])
					--droneOwnersQueues[ownerId][#droneOwnersQueues[ownerId]]
					--droneOwnersQueues[ownerId][#droneOwnersQueues[ownerId]] = nil

					if (not droneOwnersDrones[ownerId][uName]) then
						droneOwnersDrones[ownerId][uName] = {}
					end
					
					-- check again if count of drones already alive is below limit
					-- do this because of reasons
					if #droneOwnersDrones[ownerId][uName] < limits[uName] then
						-- spawn drone
						x, y, z, dx, dy, dz = getUnitPositionAndDirection(ownerId)
						if y then		
							_,up,_ = spGetUnitVectors(ownerId)
							px = x + up[1] * DRONE_CONSTRUCTION_Y
							py = y + up[2] * DRONE_CONSTRUCTION_Y
							pz = z + up[3] * DRONE_CONSTRUCTION_Y
							local droneId = spCreateUnit(uName,px,py,pz,0,teamId,true)
							
							if droneId and droneId > 0 then
								spSetUnitDirection(droneId, dx, dy, dz)
								-- add to drone owner's set
								droneOwnersDrones[ownerId][uName][#(droneOwnersDrones[ownerId][uName]) + 1] = droneId
							end
							
							droneOwnersLastBuildStepFrameNumber[ownerId] = n
						end
					else
						--Spring.Echo("extra "..uName.." was in queue")
					end
				end
			end
		end
		
		-- for each drone
		local ox, oy, oz, odx, ody, odz
		for ownerId,drones in pairs(droneOwnersDrones) do
			ox, oy, oz, odx, ody, odz = getUnitPositionAndDirection(ownerId)
			
			for uName,uIdSet in pairs(drones) do
				for i,uId in pairs(uIdSet) do

					--Spring.Echo("uName "..uName.." : "..uId)
					-- update build percentage if not built
					local hp,maxHp,_,_,bp = spGetUnitHealth(uId)
					local newBp = bp
					local newHp = hp
					local drainE = 0
					if not bp or markedForDestruction[uId] then
						--Spring.Echo("uName "..uName.." : "..uId.." is dead!")
						table.remove(uIdSet,i)
						
						droneUnderConstruction[uId] = nil
					else
						if bp < 1 then
							if lightDrones[uName] then
								newBp = bp + 1 / LIGHT_DRONE_BUILD_STEPS
								newHp = hp + (1 / LIGHT_DRONE_BUILD_STEPS)*maxHp
								ud = UnitDefNames[uName]								
								drainE = ud.energyCost * DRONE_BUILD_ENERGY_FACTOR / LIGHT_DRONE_BUILD_STEPS
							else
								newBp = bp + 1 / MEDIUM_DRONE_BUILD_STEPS
								newHp = hp + (1 / MEDIUM_DRONE_BUILD_STEPS)*maxHp
								ud = UnitDefNames[uName]								
								drainE = ud.energyCost * DRONE_BUILD_ENERGY_FACTOR / MEDIUM_DRONE_BUILD_STEPS
							end
							if newBp > 1 then
								newBp = 1
							end
							if newHp > maxHp then
								newHp = maxHp
							end
							
							--Spring.Echo("drone hp="..hp.." newHp="..newHp)
							
							-- check resources
							if drainEnergyIfAvailable(uId,ownerId,DRONE_BUILD_ENERGY_MIN, drainE ) then
								spSetUnitHealth(uId, {health = newHp, build = newBp})
								droneBuildStalled[uId] = nil
							else
								droneBuildStalled[uId] = bp
							end
							
							droneOwnersLastBuildStepFrameNumber[ownerId] = n
							droneUnderConstruction[uId] = ownerId
						else
							droneUnderConstruction[uId] = nil
							droneBuildStalled[uId] = nil
							
							-- if too far from owner, move closer
							x,_,z = spGetUnitPosition(uId)
							if ox and oz and (sqDistance(x,ox,z,oz) > droneLeashSQDistances[uName]) then
								spGiveOrderToUnit(uId, CMD.MOVE, { (x+ox)/2, 0, (z+oz)/2 }, {})
							else
								-- if idle, fight or patrol nearby position
								local cmds = spGetUnitCommands(uId)
			      				if (cmds and (#cmds <= 0)) then
			      					if stealthDrones[uName] then
										spGiveOrderToUnit(uId, CMD.MOVE, { ox + random(-200,200) , 0, oz + random(-200,200) }, {})
			      					else
			        					spGiveOrderToUnit(uId, CMD.FIGHT, { ox + random(-200,200) , 0, oz + random(-200,200) }, {})
			        				end
								end
							end
						end
					end
				end
			end
		end
	end
	
	-- update position and speed for drones under construction
	-- match owner's position to "attach" them to point above owner
	-- also show effect
	local ox, oy, oz, odx, ody, odz, ovx, ovy, ovz, orx, ory, orz, px,py,pz
	for uId,ownerId in pairs(droneUnderConstruction) do
		if markedForDestruction[uId] then
			markedForDestruction[uId] = nil
		else
			ox, oy, oz, odx, ody, odz = getUnitPositionAndDirection(ownerId)
			ovx,ovy,ovz = spGetUnitVelocity(ownerId)
			orx,ory,rvz = spGetUnitRotation(ownerId)
	
			if ox then
				_,up,_ = spGetUnitVectors(ownerId)
				px = ox + up[1] * DRONE_CONSTRUCTION_Y
				py = oy + up[2] * DRONE_CONSTRUCTION_Y
				pz = oz + up[3] * DRONE_CONSTRUCTION_Y
	
				spSetUnitPhysics(uId,px,py,pz,ovx,ovy,ovz,orx,ory,0,0,0,0)
				
				if not droneBuildStalled[uId] then
					if fmod(n,2) == 0 then
						spSpawnCEG(droneBuildCEG, px,py,pz)
					end
				end
			end
		end
	end
end

-- process units destroyed: drones or drone owners are relevant
function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	local ud = UnitDefs[unitDefID] 
	if isDrone(ud) then
		--Spring.Echo("drone died "..unitID)
		droneUnderConstruction[unitID] = nil
		for ownerId,drones in pairs(droneOwnersDrones) do
			for uName,uIdSet in pairs(drones) do
				for i,uId in ipairs(uIdSet) do
					if uId == unitID then
						--Spring.Echo("uName "..uName.." : "..uId.." is dead!")
						table.remove(uIdSet,i)
						return
					end
				end 
			end
		end
	elseif isCommander(ud) then
		if droneOwnersDrones[unitID] then

			-- kill all drones owned by the dying commander
			local drones = droneOwnersDrones[unitID]
			for uName,uIdSet in pairs(drones) do
				--Spring.Echo("set had "..#uIdSet.." drones")
				for _,uId in pairs(uIdSet) do
					--Spring.Echo("Commander died, killing drone "..uId)
					markedForDestruction[uId] = unitID
				end 
			end
			
			-- empty sets
			droneOwnersLimits[unitID] = nil
			droneOwnersDrones[unitID] = nil
			droneOwnersQueues[unitID] = nil
			droneOwnersLastBuildStepFrameNumber[unitID] = nil
		end
	end
end


function gadget:UnitIdle(unitID, unitDefID, unitTeam)

end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
