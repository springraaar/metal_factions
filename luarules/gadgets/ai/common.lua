

----------------------------- CONSTANTS

TESTCONSTANT=100

-- general configuration options
DEBUG = true
DELAY_BUILDING_IF_LOW_RESOURCES = true
DELAY_BUILDING_IF_LOW_RESOURCES_LIMIT = 15
ASSIST_EXPENSIVE_BASE_UNITS = true
ASSIST_UNIT_COST = 600
ASSIST_UNIT_RADIUS = 1500
FORCE_COST_REFERENCE = 1200
ATK_FAIL_TOLERANCE_COST = 500 
FORCE_SIZE_MOD_METAL = 0.02
FREE_METAL_SPOT_EXPANSION_THRESHOLD = 0.8
ORDER_DELAY_FRAMES = 150
RAIDING_PARTY_TOLERANCE_FRAMES = 18000
BUILD_SPREAD_DISTANCE = 50
BUILD_CELL_BUILDING_LIMIT = 8 
UNIT_RETREAT_HEALTH = 0.6
ASSAULT_RETREAT_HEALTH = 0.2
UNIT_EVADE_WAYPOINTS = 2
UNDER_ATTACK_FRAMES = 100
IDLE_FRAMES_PROGRESS_LIMIT = 20
CLEANUP_FRAMES = 900
METAL_SPOT_MIN_RELATIVE_VALUE = 0.2
BASE_UNDER_ATTACK_FRAMES = 1200		-- 40s 
BASE_VULNERABILITY_THRESHOLD_FACTOR = 0.0
BUILD_ORDER_VALIDITY_FRAMES = 500
ATTACK_ENEMY_THREAT_EVALUATION_FACTOR = 1.1
DEFENSE_ENEMY_THREAT_EVALUATION_FACTOR = 0.1	-- for when the core base is under attack
ATTACK_PERSISTENCE_THREAT_EVALUATION_FACTOR = 0.8
AIR_ATTACKER_EVALUATION_FACTOR = 0.5
DEFENDER_EVALUATION_FACTOR = 2
ATTACKER_DISTANCE_EVALUATION_FACTOR = 1
AIR_ATTACKER_DISTANCE_EVALUATION_FACTOR = 1
ATTACK_ENEMY_THREAT_EVALUATION_EASY_FACTOR = 0.40
ATTACK_ENEMY_THREAT_EVALUATION_BRUTAL_FACTOR = 0.7
ENEMY_STRATEGIC_COST_FACTOR = 2
ENEMY_EXTRACTOR_COST_FACTOR = 5
EASY_RANDOM_TIME_WASTE_PROBABILITY = 0.5 
EASY_RANDOM_TIME_WASTE_FRAMES = 120
-- base income values are per half second
BRUTAL_BASE_INCOME_METAL = 17.5
BRUTAL_BASE_INCOME_ENERGY = 400
BRUTAL_BASE_INCOME_METAL_PER_MIN = 0.3
BRUTAL_BASE_INCOME_ENERGY_PER_MIN = 3
ALL_IN_ADVANTAGE_THRESHOLD = 1.4
CELL_VALUE_RETARGET_PREFERENCE_FACTOR = 2
ENGAGE_THREAT_FACTOR = 0.5
MIN_FORCE_COST_BUILD_NUKE_THRESHOLD = 35000
BRUTAL_STRATEGY_STAGES_DELAY_FRAMES = 200*30 
END_GAME_ARMY_MOBILE_RATIO_THRESHOLD = 0.4
END_GAME_ARMY_UNIT_CAP_THRESHOLD = 0.6
GROUP_NEAR_CENTER_THRESHOLD = 0.66			-- more than 2/3rds units and cost near center
L1_ENERGY_EFF_THRESHOLD = 1000

COMBAT_EFFICIENCY_HISTORY_STEP_FRAMES = 30*60
COMBAT_EFFICIENCY_HISTORY_CHECK_STEPS = 10 
COMBAT_EFFICIENCY_FORCE_SIZE_MOD_MIN = 1
COMBAT_EFFICIENCY_FORCE_SIZE_MOD_MAX = 5

FRAMES_PER_MIN = 30 * 60

ARMOR_LIGHT = 1
ARMOR_MEDIUM = 2
ARMOR_HEAVY = 3
hpEvaluationFactorByArmorType = {
	[ARMOR_LIGHT] = 0.66,
	[ARMOR_MEDIUM] = 1.0,
	[ARMOR_HEAVY] = 1.5
}


BUILDER_UNIT_LIMIT = 7
ENERGY_STORAGE_LIMIT = 3
METAL_STORAGE_LIMIT = 2

CELL_SIZE = 512
ALONG_PATH_REVERSE_SQ_DIST_PENALTY = CELL_SIZE*CELL_SIZE*3
ALONG_PATH_PANIC_SQ_DIST = 1300*1300
PF_CELL_SIZE = 128
PF_TYPE_LAND = 0
PF_TYPE_LAND_SLOPE = 1
PF_TYPE_LAND_STEEP_SLOPE = 2
PF_TYPE_WATER_SHALLOW = 3
PF_TYPE_WATER_SLOPE = 4
PF_TYPE_WATER_STEEP_SLOPE = 5
PF_TYPE_WATER_DEEP = 6

PF_UNIT_LAND = 0
PF_UNIT_LAND_AT = 1
PF_UNIT_AMPHIBIOUS = 2
PF_UNIT_AMPHIBIOUS_FLOATER = 3
PF_UNIT_AMPHIBIOUS_AT = 4
PF_UNIT_WATER = 5
PF_UNIT_WATER_DEEP = 5
PF_UNIT_AIR = 6

PF_MOVEDEF_CONVERSION = {
	["smallboat"] = PF_UNIT_WATER,
	["mediumboat"] = PF_UNIT_WATER,
	["largeboat"] = PF_UNIT_WATER,
	["largeboat2"] = PF_UNIT_WATER_DEEP,

	["kbotht2"] = PF_UNIT_LAND,
	["kbotht3"] = PF_UNIT_LAND,
	["kbotht4"] = PF_UNIT_LAND,
	["kbotuw3"] = PF_UNIT_AMPHIBIOUS,
	["kbotuw4"] = PF_UNIT_AMPHIBIOUS,
	["kbotat"] = PF_UNIT_LAND_AT,
	["tankbh3"] = PF_UNIT_LAND,
	["tankdh3"] = PF_UNIT_AMPHIBIOUS,
	["kbotds2"] = PF_UNIT_AMPHIBIOUS,
	
	["tankhover2"] = PF_UNIT_AMPHIBIOUS_FLOATER,
	["tankhover3"] = PF_UNIT_AMPHIBIOUS_FLOATER,
	["tankhover4"] = PF_UNIT_AMPHIBIOUS_FLOATER,
	["tankhover5"] = PF_UNIT_AMPHIBIOUS_FLOATER,
	["tanksh2"] = PF_UNIT_LAND,
	["tanksh3"] = PF_UNIT_LAND,
	["tanksh4"] = PF_UNIT_LAND,
	["tankbh4"] = PF_UNIT_AMPHIBIOUS,
	["tankdh5"] = PF_UNIT_AMPHIBIOUS,
	["tankdh6"] = PF_UNIT_AMPHIBIOUS,
	["boatsub"] = PF_UNIT_WATER_DEEP,
	["kbotatuw"] = PF_UNIT_AMPHIBIOUS_AT,
	["kbotatuw2"] = PF_UNIT_AMPHIBIOUS_AT
}

PF_NAMES = {
	[PF_UNIT_LAND] = "PF_UNIT_LAND",
	[PF_UNIT_LAND_AT] = "PF_UNIT_LAND_AT", 
	[PF_UNIT_AMPHIBIOUS] = "PF_UNIT_AMPHIBIOUS",
	[PF_UNIT_AMPHIBIOUS_FLOATER] = "PF_UNIT_AMPHIBIOUS_FLOATER",
	[PF_UNIT_AMPHIBIOUS_AT] = "PF_UNIT_AMPHIBIOUS_AT",
	[PF_UNIT_WATER] = "PF_UNIT_WATER",
	[PF_UNIT_WATER_DEEP] = "PF_UNIT_WATER_DEEP",
	[PF_UNIT_AIR] = "PF_UNIT_AIR"
}

PF_DIST_MOD = {
	[PF_UNIT_LAND] = {
		[PF_TYPE_LAND] = 1,
		[PF_TYPE_LAND_SLOPE] = 1,
		[PF_TYPE_LAND_STEEP_SLOPE] = math.huge,
		[PF_TYPE_WATER_SHALLOW] = 1,
		[PF_TYPE_WATER_SLOPE] = math.huge,
		[PF_TYPE_WATER_STEEP_SLOPE] = math.huge,
		[PF_TYPE_WATER_DEEP] = math.huge
	}, 
	[PF_UNIT_AMPHIBIOUS] = {
		[PF_TYPE_LAND] = 1,
		[PF_TYPE_LAND_SLOPE] = 1,
		[PF_TYPE_LAND_STEEP_SLOPE] = math.huge,
		[PF_TYPE_WATER_SHALLOW] = 1,
		[PF_TYPE_WATER_SLOPE] = 1,
		[PF_TYPE_WATER_STEEP_SLOPE] = 1,
		[PF_TYPE_WATER_DEEP] = 1
	},
	[PF_UNIT_WATER] = {
		[PF_TYPE_LAND] = math.huge,
		[PF_TYPE_LAND_SLOPE] = math.huge,
		[PF_TYPE_LAND_STEEP_SLOPE] = math.huge,
		[PF_TYPE_WATER_SHALLOW] = 1,
		[PF_TYPE_WATER_SLOPE] = 1,
		[PF_TYPE_WATER_STEEP_SLOPE] = 1,
		[PF_TYPE_WATER_DEEP] = 1
	}
}


PF_STEEP_SLOPE_THRESHOLD = 0.25
PF_DEEP_WATER_THRESHOLD = -15
PF_STEEP_SLOPE_HEIGHT_THRESHOLD = 60

INFINITY = math.huge

ENERGY_METAL_VALUE = 1/60

-- threats to AI success

THREAT_NORMAL = 0
THREAT_AIR = 1
THREAT_DEFENSE = 2
THREAT_UNDERWATER = 3
THREAT_ASSAULT = 4


THREAT_ASSAULT_THRESHOLD = 0.35
THREAT_AIR_THRESHOLD = 0.2
THREAT_DEFENSE_THRESHOLD = 0.2
THREAT_UNDERWATER_THRESHOLD = 0.2


ASSAULT_HEALTH_COST_RATIO = 3
ASSAULT_SPEED_THRESHOLD = 45

-- special build conditions

CONDITION_WATER = 1000


-- AI tasks

TASK_DELAY_FRAMES = 400
HUMAN_TASK_DELAY_FRAMES = 5400
BRIEF_AREA_PATROL_FRAMES = 2400
ATK_FAIL_TOLERANCE_FRAMES = 1800
DANGER_CELL_FORGET_FRAMES = 900
STATIC_AREA_PATROL_FRAMES = 300

TASK_IDLE = 0
TASK_ATTACK = 1
TASK_DEFEND = 2
TASK_RETREAT = 3
TASK_AIR_ATTACK = 999	-- remove?

UNIT_ROLE_MEX_BUILDER = 1
UNIT_ROLE_BASE_PATROLLER = 2
UNIT_ROLE_MEX_UPGRADER = 3
UNIT_ROLE_DEFENSE_BUILDER = 4
UNIT_ROLE_ADVANCED_DEFENSE_BUILDER = 5
UNIT_ROLE_ATTACK_PATROLLER = 6

-- AI unit groups

UNIT_GROUP_ATTACKERS = 0
UNIT_GROUP_AIR_ATTACKERS = 1
UNIT_GROUP_SEA_ATTACKERS = 2
UNIT_GROUP_RAIDERS = 3

-- Map terrain profiles
MAP_PROFILE_LAND_FLAT = 0
MAP_PROFILE_LAND_RUGGED = 1
MAP_PROFILE_WATER = 2
MAP_PROFILE_MIXED = 3
MAP_PROFILE_AIRONLY = 4


-- commands
include("lualibs/custom_cmd.lua")

CMD_FEATURE_ID_OFFSET = Game.maxUnits

-- external commands

EXTERNAL_CMD_SETBEACON = "SETBEACON"
EXTERNAL_CMD_REMOVEBEACON = "REMOVEBEACON"
EXTERNAL_CMD_STRATEGY = "STRATEGY"
EXTERNAL_CMD_STATUS = "STATUS"
EXTERNAL_CMD_COMPAD = "COMPAD"
EXTERNAL_CMD_DEFMULT = "DEFMULT"
EXTERNAL_CMD_COMMORPH = "COMMORPH"
EXTERNAL_CMD_LOADCUSTOMSTRATEGIES = "LOADCUSTOMSTRATEGIES"
EXTERNAL_CMD_BEACONTYPE = "BEACONTYPE"
EXTERNAL_CMD_RESIGN = "RESIGN"

EXTERNAL_RESPONSE_SETMARKER = "SETMARKER"
EXTERNAL_RESPONSE_REMOVEMARKER = "REMOVEMARKER"


BEACON_DURATION_FRAMES = 30*120
BEACON_BASE_RETREAT_DISTANCE = 900

-- strategy json constants

strategyJsonReplacement = {
	MANY = 100,
	THREAT_NORMAL = THREAT_NORMAL,
	THREAT_AIR = THREAT_AIR,
	THREAT_DEFENSE = THREAT_DEFENSE,
	THREAT_UNDERWATER = THREAT_UNDERWATER,
	THREAT_ASSAULT = THREAT_ASSAULT,
	CONDITION_WATER = CONDITION_WATER
}

FULL_AI_TEAM_ENEMY_STRATEGY_OVERRIDE_FRAMES = 1800


-- reference distances

SML_RADIUS = 300
MED_RADIUS = 600
BIG_RADIUS = 900
HUGE_RADIUS = 1800
DEFENSE_CHECK_RADIUS = 1400
EXPANSION_SAFETY_RADIUS = 1800
CLUSTER_RADIUS = 1000
FORCE_RADIUS = 250
FORCE_RADIUS_AIR = 600
FORCE_RADIUS_RAIDERS = 200
FORCE_INCLUSION_RADIUS = 800
FORCE_INCLUSION_RADIUS_AIR = 800
FORCE_INCLUSION_RADIUS_RAIDERS = 500
FORCE_TARGET_RADIUS = 500
RETREAT_RADIUS = 500
BRIEF_AREA_PATROL_RADIUS = 600
BASE_AREA_PATROL_RADIUS = 900
MAP_EDGE_MARGIN = 100
BUILD_SEARCH_RADIUS = 300
UNIT_EVADE_DISTANCE = 200
UNIT_EVADE_STRAFE_DISTANCE = 100
BASE_VULNERABILITY_THRESHOLD_DISTANCE = 1500
BASE_DESPERATION_DEFENSE_THRESHOLD_DISTANCE = 1200
BASE_DESPERATION_DEFENSE_THRESHOLD_SQDISTANCE = BASE_DESPERATION_DEFENSE_THRESHOLD_DISTANCE*BASE_DESPERATION_DEFENSE_THRESHOLD_DISTANCE
DEVALUATION_DISTANCE = 500
BASE_UNDER_ATTACK_RADIUS = 800
MORPH_CHECK_RADIUS = 1300
EVADE_EDGE_MARGIN = 300			-- TODO this is still not working properly
COMMANDER_ATTACK_ZIGZAG_DISTANCE = 200
PNODE_CONNECTION_RADIUS = 490
PNODE_CONNECTION_SQRADIUS = PNODE_CONNECTION_RADIUS*PNODE_CONNECTION_RADIUS

-- reference unit types
TYPE_LIGHT_DEFENSE = 1
TYPE_HEAVY_DEFENSE = 2
TYPE_ARTILLERY_DEFENSE = 3
TYPE_LONG_RANGE_ARTILLERY = 4

TYPE_RAIDER = 5
TYPE_SCOUT = 6
TYPE_TANK = 7
TYPE_SUPPORT = 8
TYPE_ARTILLERY = 9

TYPE_AIR_FIGHTER = 10
TYPE_AIR_BOMBER = 11
TYPE_AIR_GUNSHIP = 12

TYPE_L1_PLANT = 13
TYPE_L2_PLANT = 14

TYPE_MEX = 15
TYPE_MOHO = 16

TYPE_ECONOMY = 17
TYPE_PLANT = 18
TYPE_ATTACKER = 19
TYPE_AIR_ATTACKER = 20

TYPE_L1_CONSTRUCTOR = 21
TYPE_L2_CONSTRUCTOR = 22

TYPE_BASE = 23
TYPE_LIGHT_AA = 24
TYPE_COMMANDER = 25
TYPE_UPGRADED_COMMANDER = 26
TYPE_HEAVY_AA = 27
TYPE_EXTRACTOR = 28
TYPE_STRATEGIC = 29
TYPE_MEDIUM_AA = 30
TYPE_SEA_ATTACKER = 31
TYPE_AMPHIBIOUS_ATTACKER = 31
TYPE_FUSION = 32
TYPE_UPGRADE_CENTER = 33
TYPE_ENERGYGENERATOR = 34
TYPE_RESPAWNER = 35
TYPE_HAZMOHO = 36
TYPE_HIGH_PRIORITY = 37
TYPE_UW_DEFENSE = 38
TYPE_FAKE_WEAPON = 39
TYPE_NUKE = 40
TYPE_PNODE = 41

-- Taskqueuebehavior skips this name
SKIP_THIS_TASK = "s"

-- this unit is used to check for underwater metal spots
UWMetalSpotCheckUnit = "sphere_clam"

-- this unit is used to check for water sectors
WaterUnitName = "gear_tidal_generator"
LAND_TEST_UNIT = "gear_light_plant"
WATER_TEST_UNIT = "gear_tidal_generator"
DEEP_WATER_TEST_UNIT = "gear_shipyard"
UNDERWATER_THRESHOLD = - 5

NANO_TOWER_PLANT_TEST_DEF_ID = UnitDefNames["aven_adv_aircraft_plant"].id

-- side names
side1Name = "aven"
side2Name = "gear"
side3Name = "claw"
side4Name = "sphere"


------------------------------------------------------


--------------------------- COMMON FUNCTIONS
sqrt = math.sqrt
max = math.max
min = math.min
abs = math.abs
fmod = math.fmod
random = math.random
floor = math.floor
echo = Spring.Echo

spGetGameFrame = Spring.GetGameFrame
spTestBuildOrder = Spring.TestBuildOrder
spGetTeamResources = Spring.GetTeamResources
spGetUnitPosition = Spring.GetUnitPosition
spGetUnitDefID = Spring.GetUnitDefID
spGetUnitHealth = Spring.GetUnitHealth
spGetFeaturesInSphere = Spring.GetFeaturesInSphere
spGetFeaturesInCylinder = Spring.GetFeaturesInCylinder
spGetFeatureDefID = Spring.GetFeatureDefID
spGetFeatureResources = Spring.GetFeatureResources
spGiveOrderToUnit = Spring.GiveOrderToUnit
spTestMoveOrder = Spring.TestMoveOrder
spGetGroundInfo = Spring.GetGroundInfo
spGetAIInfo = Spring.GetAIInfo
spGetGroundHeight = Spring.GetGroundHeight
spGetGroundNormal = Spring.GetGroundNormal
spGetUnitDefDimensions = Spring.GetUnitDefDimensions
spGetCommandQueue = Spring.GetCommandQueue
spGetFeatureDefID = Spring.GetFeatureDefID
spGetFeaturePosition = Spring.GetFeaturePosition
spGetUnitMoveTypeData = Spring.GetUnitMoveTypeData
spGetUnitRulesParam = Spring.GetUnitRulesParam
spGetTeamRulesParam = Spring.GetTeamRulesParam
spSetTeamRulesParam = Spring.SetTeamRulesParam
spAddTeamResource = Spring.AddTeamResource
spGetUnitCommands = Spring.GetUnitCommands
spGetUnitsInCylinder = Spring.GetUnitsInCylinder
spMarkerAddPoint = Spring.MarkerAddPoint
spMarkerErasePosition = Spring.MarkerErasePosition
spGetUnitNearestEnemy = Spring.GetUnitNearestEnemy
spGetUnitTeam = Spring.GetUnitTeam
spAreTeamsAllied = Spring.AreTeamsAllied
spGetTeamUnits = Spring.GetTeamUnits
spTransferUnit = Spring.TransferUnit

EMPTY_TABLE = {}
TABLE_WITH_ZERO = {0}
TABLE_WITH_ONE = {1}

function splitString (input, sep)
	if sep == nil then
		sep = "%s"
	end
	local t={}
	for str in string.gmatch(input, "([^"..sep.."]+)") do
		table.insert(t, str)
	end
	return t
end

function addToSet(set, key)
	set[key] = true
end

function removeFromSet(set, key)
	set[key] = nil
end

function setContains(set, key)
	return set[key] ~= nil
end

function tableContains(tab, key)
    for index, value in ipairs(tab) do
        if value == key then
            return true
        end
    end

    return false
end


function listToSet (list)
	local set = {}
	for _, l in ipairs(list) do 
		-- if value is a table, add each value within into the set
		if type(l) == "table" then
			for k, _ in pairs(listToSet(l)) do
				set[k] = true
			end
		-- otherwise, add value to set
		else
			set[l] = true
		end 
	
	end
	return set
end

-- used on BuildSiteHandler
function distSort(t,a,b)
	return t[b].dist > t[a].dist
end

function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

function tableToSet (table)
	local set = {}
	for _, v in pairs(table) do 
		-- if value is a table, add each value within into the set
		if type(v) == "table" then
			for k, _ in pairs(tableToSet(v)) do
				addToSet(set, k)
			end
		-- otherwise, add value to set
		else
			addToSet(set, v)
		end 
	end
	return set
end

function tableLength(T)
	local count = 0
	if ( T ~= nil) then
		for _ in pairs(T) do count = count + 1 end
	end
	return count
end

function printTable(table)
	for k, v in pairs(table) do 
		log("table["..tostring(k).."]="..tostring(v))	
	end
end

function log(inStr, ai)
	if DEBUG then
		if( ai ~= nil ) then
			echo("player "..ai.id.." : "..inStr)
		else
			echo(inStr)
		end
	end
end

local xd,zd,xd2,zd2,sqDist
function distance(pos1,pos2)
	xd = pos1.x-pos2.x
	zd = pos1.z-pos2.z
	dist = sqrt(xd*xd + zd*zd)
	return dist
end

function sqDistance(x1,x2,z1,z2)
	xd = x1-x2
	zd = z1-z2
	sqDist = xd*xd + zd*zd
	return sqDist
end

function checkWithinDistance(pos,center,maxDistance)
	
	xd = pos.x-center.x
	zd = pos.z-center.z
	if (abs(xd) > maxDistance) then
		return false
	end
	if (abs(zd) > maxDistance) then
		return false
	end
	
	sqDist = maxDistance*maxDistance	
	xd2 = xd*xd
	if xd2 > sqDist then
		return false
	end
	zd2 = zd*zd
	if zd2 > sqDist then
		return false
	end
	if (xd2 + zd2 > sqDist) then
		return false
	end
	
	return true
end

function getUnitPFType(unitDef)
	pFtype = nil
	
	if unitDef ~= nil and (not unitDef.isImmobile) then
		if (unitDef.canFly) then
			pFType = PF_UNIT_AIR
		else
			pFType = PF_MOVEDEF_CONVERSION[unitDef.moveDef.name]
		
			--log("PF for "..unitDef.name.." is "..tostring(unitDef.moveDef.name).." conv="..tostring(PF_NAMES[pFType]))
		end
	end

	return pFType
end

function getOwnUnits()
	return self.ai.ownUnitIds
end

function getFriendlies()
	return self.ai.friendlyUnitIds
end

function getEnemies()
	return self.ai.enemyUnitIds
end

function getWeightedCost(ud)
	if (ud ~= nil) then
		return ud.metalCost + ud.energyCost * ENERGY_METAL_VALUE
	end

	return 0
end

function getWeightedCostByName(uName)
	if (uName ~= nil) then
		return getWeightedCost(UnitDefNames[uName])
	end

	return 0
end


-- create new position obj from coordinates
function newPosition(x,y,z)
	x = x or 0
	y = y or 0
	z = z or 0

    local self = { x=x, y=y, z=z, toArray = function() return {self.x, self.y, self.z} end}
    return self
end

-- checks if position are within map bounds
function checkWithinMapBounds(x,z)
	if (x and z) then
		if (x >= 0 and x <= Game.mapSizeX and z >= 0 and z <= Game.mapSizeZ) then
			return true
		end
	else
		--echo("map bounds check with invalid data x="..tostring(x).." z="..tostring(z))
	end
	
	return false
end

-- retrieve cell x,z indexes for position (general purpose cells)
local _cellX,_cellZ
function getCellXZIndexesForPosition(pos)
	if pos ~= nil then
		_cellX = pos.x - pos.x%CELL_SIZE
		_cellZ = pos.z - pos.z%CELL_SIZE
		_cellX = _cellX / CELL_SIZE
		_cellZ = _cellZ / CELL_SIZE
		return	_cellX, _cellZ
	end
end

-- retrieve cell x,z indexes for position (smaller pathfinding cells)
function getPFCellXZIndexesForPosition(pos)
	if pos ~= nil then
		_cellX = pos.x - pos.x%PF_CELL_SIZE
		_cellZ = pos.z - pos.z%PF_CELL_SIZE
		_cellX = _cellX / PF_CELL_SIZE
		_cellZ = _cellZ / PF_CELL_SIZE
		return	_cellX, _cellZ
	end
end

function getCellFromTableIfExists(table,xIndex,zIndex)
	if table ~= nil then
		if (table[xIndex] ~= nil) then
			return table[xIndex][zIndex]
		end
	end
	
	return nil
end
local _xIndex,_zIndex
function getAdjacentCellList(table,pos)
	_xIndex,_zIndex = getCellXZIndexesForPosition(pos)
	local cells = {}
	
	if _xIndex >=0 and _zIndex >=0 then
		for dxi = -1, 1 do
			for dzi = -1, 1 do
				xi = _xIndex + dxi
				zi = _zIndex + dzi
				cell = getCellFromTableIfExists(table,xi,zi)
				if(cell ~= nil) then
					cells[#cells+1] = cell
				end 
			end
		end		
	end
	
	return cells
end

function getNearbyCellIfExists(table,pos)
	_xIndex,_zIndex = getCellXZIndexesForPosition(pos)
	local cell = nil
	if _xIndex >=0 and _zIndex >=0 then
		cell = getCellFromTableIfExists(table,_xIndex,_zIndex)
		if(cell ~= nil) then
			return cell
		end
		
		-- grab a nearby cell
		for dxi = -1, 1 do
			for dzi = -1, 1 do
				xi = _xIndex + dxi
				zi = _zIndex + dzi
				if (xi >=0) and (zi >= 0) and not (dxi == 0 and dzi == 0) then
					return getCellFromTableIfExists(table,xi,zi)
				end
			end
		end		
	end
	
	return cell
end


-- get combined cost of armed enemies inside and near a cell
function getCombinedThreatCost(cell)
	return (cell.attackerCost+cell.defenderCost*DEFENDER_EVALUATION_FACTOR+cell.airAttackerCost*AIR_ATTACKER_EVALUATION_FACTOR)+(cell.nearbyAttackerCost+cell.nearbyDefenderCost*DEFENDER_EVALUATION_FACTOR+cell.nearbyAirAttackerCost*AIR_ATTACKER_EVALUATION_FACTOR)
end

-- get combined cost of armed enemies inside a cell
function getInternalThreatCost(cell)
	return (cell.attackerCost+cell.defenderCost*DEFENDER_EVALUATION_FACTOR+cell.airAttackerCost*AIR_ATTACKER_EVALUATION_FACTOR)
end

-- get combined cost of armed enemies inside and near a cell, excluding bad AA
function getCombinedThreatCostExcludingBadAA(cell)
	return ((cell.attackerCost-cell.badAAAttackerCost)+(cell.defenderCost-cell.badAADefenderCost)*DEFENDER_EVALUATION_FACTOR+(cell.airAttackerCost-cell.badAAAirAttackerCost)*AIR_ATTACKER_EVALUATION_FACTOR)+((cell.nearbyAttackerCost-cell.nearbyBadAAAttackerCost)+(cell.nearbyDefenderCost-cell.nearbyBadAADefenderCost)*DEFENDER_EVALUATION_FACTOR+(cell.nearbyAirAttackerCost-cell.nearbyBadAAAirAttackerCost)*AIR_ATTACKER_EVALUATION_FACTOR)
end

-- get combined cost of armed enemies inside a cell, excluding bad AA
function getInternalThreatCostExcludingBadAA(cell)
	return ((cell.attackerCost-cell.badAAAttackerCost)+(cell.defenderCost-cell.badAADefenderCost)*DEFENDER_EVALUATION_FACTOR+(cell.airAttackerCost-cell.badAAAirAttackerCost)*AIR_ATTACKER_EVALUATION_FACTOR)
end

------------------------------------------------------




--------------------------------- UNIT LISTS

buildOptionsByPlant = {}
for name,ud in pairs(UnitDefNames) do
	if (ud.customParams and ud.customParams.builtby) then
		local plantNames = splitString(ud.customParams.builtby,",")
		
		for i,pName in ipairs(plantNames) do
			-- create table if missing 
			if (not buildOptionsByPlant[pName]) then
				buildOptionsByPlant[pName] = {}
			end
			
			buildOptionsByPlant[pName][name] = true
		end
	end
end
-- for name,_ in pairs(buildOptionsByPlant["aven_light_plant"]) do
-- 	Spring.Echo("BUILDOPTION "..name)
-- end

-- build ranges for stationary constructors
-- for use until a way to get those automatically is provided
constructionTowers = {
	gear_nano_tower = 200,
	aven_nano_tower = 200,
	claw_nano_tower = 200,
	sphere_pole = 200,
}

-- pathfinding restrictions by factory
-- default is PF_UNIT_LAND
pFConnectionRestrictionsByPlant = {
	----------- AVEN
	aven_shipyard = PF_UNIT_AMPHIBIOUS,
	aven_adv_shipyard = PF_UNIT_AMPHIBIOUS,
	aven_hovercraft_platform = PF_UNIT_AMPHIBIOUS,
	aven_aircraft_plant = PF_UNIT_AIR,
	aven_adv_aircraft_plant = PF_UNIT_AIR,
	aven_scout_pad = PF_UNIT_AIR,
	aven_commander_respawner = PF_UNIT_AMPHIBIOUS,
	aven_upgrade_center = PF_UNIT_AIR,
	aven_nano_tower = PF_UNIT_AIR,
	----------- GEAR
	gear_shipyard = PF_UNIT_AMPHIBIOUS,
	gear_adv_shipyard = PF_UNIT_AMPHIBIOUS,
	gear_aircraft_plant = PF_UNIT_AIR,
	gear_adv_aircraft_plant = PF_UNIT_AIR,
	gear_scout_pad = PF_UNIT_AIR,
	gear_commander_respawner = PF_UNIT_AMPHIBIOUS,
	gear_upgrade_center = PF_UNIT_AIR,
	gear_nano_tower = PF_UNIT_AIR,
	----------- CLAW
	claw_shipyard = PF_UNIT_AMPHIBIOUS,
	claw_adv_shipyard = PF_UNIT_AMPHIBIOUS,
	claw_spinbot_plant = PF_UNIT_AMPHIBIOUS,
	claw_aircraft_plant = PF_UNIT_AIR,
	claw_adv_aircraft_plant = PF_UNIT_AIR,
	claw_scout_pad = PF_UNIT_AIR,
	claw_commander_respawner = PF_UNIT_AMPHIBIOUS,
	claw_upgrade_center = PF_UNIT_AIR,
	claw_nano_tower = PF_UNIT_AIR,
	----------- SPHERE
	sphere_shipyard = PF_TYPE_AMPHIBIOUS,
	sphere_adv_shipyard = PF_TYPE_AMPHIBIOUS,
	sphere_sphere_factory = PF_UNIT_AIR,
	sphere_aircraft_factory = PF_UNIT_AIR,
	sphere_adv_aircraft_factory = PF_UNIT_AIR,
	sphere_scout_pad = PF_UNIT_AIR,
	sphere_commander_respawner = PF_UNIT_AMPHIBIOUS,
	sphere_upgrade_center = PF_UNIT_AIR,
	sphere_nano_tower = PF_UNIT_AIR
}


-- buildings that should be built in sets (generally cheap economy buildings)
multiBuildBuildings = {
	aven_solar_collector = 40,
	aven_wind_generator = 40,
	aven_tidal_generator = 32,
	gear_solar_collector = 40,
	gear_wind_generator = 40,
	gear_tidal_generator = 32,
	claw_solar_collector = 40,
	claw_wind_generator = 40,
	claw_tidal_generator = 32,
	sphere_tidal_generator = 32,
	aven_metal_maker = 48,
	gear_metal_maker = 48,
	claw_metal_maker = 48,
	sphere_metal_maker = 48
}

attackerList = 
{
------------------------------------------------ AVEN
----------- l1
	"aven_runner",
	"aven_trooper",
	"aven_trooper_laser",
	"aven_trooper_hemg",
	"aven_wheeler",
	"aven_kit",
	"aven_warrior",
	"aven_jethro",

	"aven_bold",
	"aven_jeffy",
	"aven_samson",
	"aven_duster",

	"aven_swift",
	"aven_tornado",
	"aven_twister",
----------- l2
	"aven_rover",
	"aven_magnum",
	"aven_sniper",
	"aven_dazer",
	"aven_weaver",
	"aven_spiker",
	"aven_shocker",
	"aven_knight",
	"aven_dervish",
	"aven_bolter",
	"aven_commando",
	"aven_stalker",
	"aven_raptor",
	
	"aven_racer",
	"aven_centurion",
	"aven_tribune",
	"aven_javelin",
	"aven_slider",
	"aven_slider_s",	
	"aven_swatter",
	"aven_skimmer",
	"aven_salvo",
	"aven_excalibur",
	"aven_turbulence",		
	"aven_penetrator",
	"aven_merl",
	"aven_priest",
	"aven_kodiak",
	"aven_tsunami",
	"aven_catfish",
	"aven_valiant",

	"aven_icarus",
	"aven_gryphon",
	"aven_falcon",
	"aven_talon",

------------------------------------------------ GEAR
----------- l1
	"gear_pinion",
	"gear_thud",
	"gear_kano",
	"gear_crasher",
	"gear_box",
	"gear_harasser",
	"gear_canister",
	"gear_instigator",
	"gear_assaulter",
	"gear_igniter",
	
	"gear_dash",
	"gear_zipper",
	"gear_knocker",

----------- l2
	"gear_bandit",
	"gear_cube",
	"gear_cloakable_cube",
	"gear_rager",
	"gear_moe",
	"gear_rattler",
	"gear_psycho",
	"gear_titan",
	"gear_big_bob",
	"gear_barrel",
	"gear_pyro",

	"gear_metalhead",
	"gear_hopper",
	"gear_salamander",
	"gear_stilts",
	"gear_marauder",
	"gear_marooner",
	"gear_overcharger",
	"gear_rexapod",
	"gear_proteus",
	"gear_heater",
	"gear_reaper",
	"gear_thresher",
	"gear_tremor",
	"gear_diplomat",
	"gear_rhino",
	"gear_tensor",
	"gear_might",
	"gear_mobile_artillery",
	"gear_eruptor",
	"gear_flareon",
	"gear_luminator",
	"gear_lesser_luminator",

	"gear_vector",
	"gear_stratos",
	"gear_whirlpool",
	"gear_firestorm",
	
------------------------------------------------ CLAW
	"claw_wolverine",
	"claw_grunt",
	"claw_piston",
	"claw_chisel",
	"claw_jester",
	"claw_ringo",
	"claw_boar",
	"claw_knife",
	"claw_roller",
	"claw_centaur",
	"claw_brute",
	"claw_nucleus",
	"claw_bishop",
	"claw_sickle",
	"claw_pounder",
	"claw_shrieker",
	"claw_armadon",
	"claw_bullfrog",
	"claw_mega",
	"claw_ravager",
	"claw_breaker",
	"claw_halberd",
	"claw_crawler",
	"claw_cutter",
	"claw_flail",
	"claw_scythe",
	"claw_trajector",
	"claw_speeder",
	"claw_striker",
	"claw_sword",
	"claw_wrecker",
	"claw_drakkar",
	"claw_spine",
	"claw_monster",
	"claw_hornet",
	"claw_boomer",
	"claw_boomer_m",
	"claw_x",
	"claw_blizzard",
	"claw_havoc",
	"claw_predator",
	"claw_tempest",
	"claw_dizzy",
	"claw_gyro",
	"claw_dancer",
	"claw_mace",
	"claw_lash",
	"claw_dynamo",
	"claw_pike",
------------------------------------------------ SPHERE
	"sphere_mite",
	"sphere_bit",
	"sphere_gaunt",
	"sphere_slicer",
	"sphere_rock",
	"sphere_needles",
	"sphere_crustle",
	"sphere_trike",
	"sphere_double",
	"sphere_hanz",
	"sphere_tick",
	"sphere_masher",
	"sphere_trax",
	"sphere_pulsar",
	"sphere_glare",
	"sphere_quad",
	"sphere_reaver",
	"sphere_bulk",
	"sphere_monolith",
	"sphere_slammer",
	"sphere_golem",
	"sphere_chub",
	"sphere_ark",
	"sphere_hanz",
	"sphere_charger",
	"sphere_skiff",
	"sphere_reacher",
	"sphere_endeavour",
	"sphere_helix",
	"sphere_needles",
	"sphere_moth",
	"sphere_tycho",
	"sphere_spitfire",
	"sphere_meteor",
	"sphere_twilight",
	"sphere_hermit",
	"sphere_nimbus",
	"sphere_aster",
	"sphere_gazer",
	"sphere_comet",
	"sphere_atom",
	"sphere_chroma",
	"sphere_dipole",
	"sphere_cluster",
	"sphere_cluster_module_laser",
	"sphere_cluster_module_bomb"
}


airAttackerList = 
{
------------------------------------------------ AVEN
----------- l1

	"aven_swift",
	"aven_tornado",
	"aven_twister",
	"aven_gale",
----------- l2
	"aven_icarus",
	"aven_gryphon",
	"aven_falcon",
	"aven_talon",
	"aven_ace",
	"aven_ghost",
	"aven_albatross",

------------------------------------------------ GEAR
----------- l1
	"gear_dash",
	"gear_zipper",
	"gear_knocker",

----------- l2

	"gear_vector",
	"gear_stratos",
	"gear_firestorm",
	"gear_whirlpool",

------------------------------------------------ CLAW
----------- l1
	"claw_hornet",
	"claw_boomer",
	"claw_boomer_m",
	"claw_shredder",
----------- l2
	"claw_x",
	"claw_blizzard",
	"claw_havoc",
	"claw_trident",
------------------------------------------------ SPHERE
----------- l1
	"sphere_moth",
	"sphere_tycho",
	"sphere_blower",
----------- l2
	"sphere_meteor",
	"sphere_twilight",
	"sphere_spitfire",      
	"sphere_neptune"
}


unitAbleToHitUnderwater = {
------------------------------------------------ AVEN
	aven_commander = true,
	aven_u1commander = true,
	aven_u2commander = true,
	aven_u3commander = true,
	aven_u4commander = true,
	aven_u5commander = true,
	aven_u6commander = true,
	aven_lurker = true,
	aven_stinger = true,
	aven_skeeter = true,
	aven_torpedo_launcher = true,
	aven_piranha = true,
	aven_slider_s = true,
	aven_advanced_torpedo_launcher = true,
	aven_albatross = true,
	aven_pelter = true,
------------------------------------------------ GEAR
	gear_commander = true,
	gear_u1commander = true,
	gear_u2commander = true,
	gear_u3commander = true,
	gear_u4commander = true,
	gear_u5commander = true,
	gear_u6commander = true,
	gear_snake = true,
	gear_viking = true,
	gear_torpedo_launcher = true,
	gear_noser = true,
	gear_advanced_torpedo_launcher = true,
	gear_whirlpool = true,
	gear_metalhead = true,
	gear_marooner = true,
	gear_lobber = true,
	gear_rexapod = true,
------------------------------------------------ CLAW
	claw_commander = true,
	claw_u1commander = true,
	claw_u2commander = true,
	claw_u3commander = true,
	claw_u4commander = true,
	claw_u5commander = true,
	claw_u6commander = true,
	claw_spine = true,
	claw_sinker = true,
	claw_monster = true,
	claw_dancer = true,
	claw_cutter = true,
	claw_trident = true,
	claw_nailer = true,
	claw_cache = true,		
------------------------------------------------ SPHERE
	sphere_commander = true,
	sphere_u1commander = true,
	sphere_u2commander = true,
	sphere_u3commander = true,
	sphere_u4commander = true,
	sphere_u5commander = true,
	sphere_u6commander = true,
	sphere_carp = true,
	sphere_skiff = true,
	sphere_targe = true,
	sphere_clam = true,
	sphere_pluto = true,
	sphere_oyster = true,
	sphere_crab = true,
	sphere_slugger = true,
	sphere_cluster = true,
	sphere_cluster_module_bomb = true,
	sphere_neptune = true
}


seaAttackerList = 
{
------------------------------------------------ AVEN
----------- l1

	"aven_skeeter",
	"aven_crusader",
	"aven_vanguard",
	"aven_lurker",
	"aven_stinger",
----------- l2
	"aven_ranger",
	"aven_conqueror",
	"aven_piranha",
	"aven_emperor",
	"aven_fletcher",
	"aven_rush",
	"aven_valiant",
------------------------------------------------ GEAR
----------- l1
	"gear_searcher",
	"gear_enforcer",
	"gear_viking",
	"gear_snake",
	"gear_blowfish",

----------- l2

	"gear_noser",
	"gear_executioner",
	"gear_edge",
	"gear_jigsaw",
	"gear_strainer",
------------------------------------------------ CLAW
----------- l1
	"claw_speeder",
	"claw_striker",
	"claw_sword",
	"claw_spine",
	"claw_hunter",
----------- l2
	"claw_drakkar",
	"claw_monster",
	"claw_wrecker",
	"claw_maul",
	"claw_phalanx",	
------------------------------------------------ SPHERE
----------- l1
	"sphere_skiff",
	"sphere_endeavour",
	"sphere_carp",
	"sphere_reacher",
	"sphere_targe",
----------- l2
	"sphere_pluto",
	"sphere_stalwart",
	"sphere_stresser"
}

l1ConstructorList = 
{
------------------------------------------------ AVEN
	"aven_construction_kbot",
	"aven_construction_aircraft",
	"aven_construction_ship",
	"aven_nano_tower",
------------------------------------------------ GEAR
	"gear_construction_kbot",
	"gear_construction_aircraft",
	"gear_construction_ship",
	"gear_nano_tower",	
------------------------------------------------ CLAW
	"claw_construction_kbot",
	"claw_construction_aircraft",
	"claw_construction_ship",
	"claw_nano_tower",

------------------------------------------------ SPHERE
	"sphere_construction_vehicle",
	"sphere_construction_aircraft",
	"sphere_construction_ship",
	"sphere_pole"
}


l2ConstructorList = 
{
------------------------------------------------ AVEN
	"aven_adv_construction_kbot",
	"aven_adv_construction_vehicle",
	"aven_adv_construction_aircraft",
	"aven_adv_construction_sub",
	"aven_construction_hovercraft",	
------------------------------------------------ GEAR
	"gear_adv_construction_kbot",
	"gear_adv_construction_vehicle",
	"gear_adv_construction_aircraft",
	"gear_adv_construction_sub",
	"gear_adv_construction_hydrobot",
------------------------------------------------ CLAW
	"claw_adv_construction_kbot",
	"claw_adv_construction_vehicle",
	"claw_adv_construction_aircraft",
	"claw_adv_construction_ship",
	"claw_adv_construction_spinbot",	

------------------------------------------------ SPHERE
	"sphere_adv_construction_kbot",
	"sphere_adv_construction_vehicle",
	"sphere_adv_construction_aircraft",
	"sphere_construction_sphere",
	"sphere_adv_construction_sub"
}


supporterList = 
{
------------------------------------------------ AVEN
	"aven_peeper",
	"aven_marky",
	"aven_eraser",
	"aven_seer",
	"aven_jammer",
	"aven_perceptor",
	"aven_zephyr",
	"aven_scoper",
------------------------------------------------ GEAR
	"gear_fink",
	"gear_informer",
	"gear_deleter",
	"gear_voyeur",
	"gear_spectre",
	"gear_zoomer",	
------------------------------------------------ CLAW
	"claw_spotter",
	"claw_revealer",
	"claw_shade",
	"claw_seer",
	"claw_jammer",
	"claw_haze",
	"claw_lensor",
------------------------------------------------ SPHERE
	"sphere_probe",
	"sphere_rain",
	"sphere_sensor",
	"sphere_scanner",
	"sphere_concealer",
	"sphere_orb",
	"sphere_screener",
	"sphere_shielder",
	"sphere_resolver"
}

fakeWeaponUnits = {
	aven_comsat_station = true,
	aven_scoper = true,
	gear_comsat_station = true,
	gear_zoomer = true,
	claw_comsat_station = true,
	claw_lensor = true,
	sphere_comsat_station = true,
	sphere_resolver = true
}


-- units that the AI won't target
neutralUnits = {
	------------------------------------------------ AVEN
	aven_dragons_teeth = true,
	aven_fortification_wall = true,
	aven_large_fortification_wall = true,
	aven_fortification_gate = true,
	------------------------------------------------ GEAR
	gear_dragons_teeth = true,
	gear_fortification_wall = true,
	gear_large_fortification_wall = true,
	gear_fortification_gate = true,
	gear_mine = true,
	gear_incendiary_mine = true,
	------------------------------------------------ CLAW
	claw_dragons_teeth = true,
	claw_fortification_wall = true,
	claw_large_fortification_wall = true,
	claw_fortification_gate = true,
	------------------------------------------------ SPHERE
	sphere_dragons_teeth = true,
	sphere_fortification_wall = true,
	sphere_large_fortification_wall = true,
	sphere_fortification_gate = true,	
	------------------------------------------------ other
	cs_beacon = true,
	scoper_beacon = true
}


-- extra threat value
-- for units which are unarmed but can help thwart the AI's attacks 
extraThreatValue = {
	sphere_shielder = 5000,
	sphere_aegis = 6000,
	aven_nano_tower = 300,
	gear_nano_tower = 300,
	claw_nano_tower = 300,
	sphere_pole = 300
}



-- TODO : not used atm
naturallyRoamingCommanders = {
------------------------------------------------ AVEN
	"aven_u1commander",
	"aven_u3commander",
	"aven_u5commander",
------------------------------------------------ GEAR
	"gear_u1commander",
------------------------------------------------ CLAW
	"claw_u3commander",
	"claw_u6commander",
------------------------------------------------ SPHERE
	"sphere_u1commander"
}


lltByFaction = { [side1Name] = "aven_light_laser_tower", [side2Name] = "gear_light_laser_tower", [side3Name] = "claw_drill", [side4Name] = "sphere_stir"}
lightAAByFaction = { [side1Name] = "aven_defender", [side2Name] = "gear_pulverizer", [side4Name] = "sphere_shooter"}
mediumAAByFaction = { [side3Name] = "claw_gemini", [side4Name] = "sphere_shine"}
heavyAAByFaction = { [side1Name] = {"aven_warden"}, [side2Name] = {"gear_missilator"}, [side3Name] = {"claw_hyper"}, [side4Name] = {"sphere_stark"}}
lev1HeavyDefenseByFaction = {[side1Name] = {"aven_sentinel"}, [side2Name] = {"gear_blaze","gear_beamer"}, [side3Name] = {"claw_piercer"}, [side4Name] = {"sphere_stout"}}
lev1ArtilleryDefenseByFaction = {[side1Name] = {"aven_gunner"}, [side2Name] = {"gear_toaster"}, [side3Name] = {"claw_thumper"}, [side4Name] = {"sphere_lancer"}}
lev2ArtilleryDefenseByFaction = {[side1Name] = {"aven_guardian"}, [side2Name] = {"gear_punisher"}, [side3Name] = {"claw_massacre"}, [side4Name] = {"sphere_banger"}}
lev2LongRangeArtilleryByFaction = {[side1Name] = {"aven_standoff"}, [side2Name] = {"gear_intimidator"}, [side3Name] = {"claw_longhorn"}, [side4Name] = {"sphere_bastion"}}
respawnerByFaction = {[side1Name] = "aven_commander_respawner", [side2Name] = "gear_commander_respawner", [side3Name] = "claw_commander_respawner", [side4Name] = "sphere_commander_respawner"}
lev1PlantByFaction = {[side1Name] = {"aven_light_plant","aven_aircraft_plant"}, [side2Name] = {"gear_light_plant","gear_aircraft_plant"}, [side3Name] = {"claw_light_plant","claw_aircraft_plant"}, [side4Name] = {"sphere_light_factory","sphere_aircraft_factory"}}
lev2PlantByFaction = {[side1Name] = {"aven_adv_kbot_lab","aven_adv_vehicle_plant","aven_hovercraft_platform","aven_adv_aircraft_plant"}, [side2Name] = {"gear_adv_kbot_lab","gear_adv_vehicle_plant","gear_adv_aircraft_plant","gear_hydrobot_plant"}, [side3Name] = {"claw_adv_kbot_plant","claw_adv_vehicle_plant","claw_spinbot_plant","claw_adv_aircraft_plant"}, [side4Name] = {"sphere_adv_vehicle_factory","sphere_adv_kbot_factory","sphere_sphere_factory","sphere_adv_aircraft_factory"}}
solarByFaction = { [side1Name] = "aven_solar_collector", [side2Name] = "gear_solar_collector", [side3Name] = "claw_solar_collector"}
windByFaction = { [side1Name] = "aven_wind_generator", [side2Name] = "gear_wind_generator", [side3Name] = "claw_wind_generator", [side4Name] = "sphere_wind_generator"}
geoByFaction = { [side1Name] = "aven_geothermal_powerplant", [side2Name] = "gear_geothermal_powerplant", [side3Name] = "claw_geothermal_powerplant", [side4Name] = "sphere_geothermal_powerplant"}
energyStorageByFaction = { [side1Name] = "aven_energy_storage", [side2Name] = "gear_energy_storage", [side3Name] = "claw_energy_storage", [side4Name] = "sphere_energy_storage"}
metalStorageByFaction = { [side1Name] = "aven_metal_storage", [side2Name] = "gear_metal_storage", [side3Name] = "claw_metal_storage", [side4Name] = "sphere_metal_storage"}
radarByFaction = { [side1Name] = "aven_radar_tower", [side2Name] = "gear_radar_tower", [side3Name] = "claw_radar_tower", [side4Name] = "sphere_radar_tower"}
commanderByFaction = {[side1Name] = "aven_commander", [side2Name] = "gear_commander", [side3Name] = "claw_commander", [side4Name] = "sphere_commander"}
mexByFaction =  { [side1Name] = "aven_metal_extractor", [side2Name] = "gear_metal_extractor", [side3Name] = "claw_metal_extractor", [side4Name] = "sphere_metal_extractor"}
hazMexByFaction =  { [side1Name] = "aven_exploiter", [side2Name] = "gear_exploiter", [side3Name] = "claw_exploiter", [side4Name] = "sphere_exploiter"}
mohoMineByFaction = { [side1Name] = "aven_moho_mine", [side2Name] = "gear_moho_mine", [side3Name] = "claw_moho_mine", [side4Name] = "sphere_moho_mine"}
powerNodeByFaction = { [side1Name] = "aven_power_node", [side2Name] = "gear_power_node", [side3Name] = "claw_power_node", [side4Name] = "sphere_power_node"}
fusionByFaction = { [side1Name] = "aven_fusion_reactor", [side2Name] = "gear_fusion_power_plant", [side3Name] = "claw_adv_fusion_reactor", [side4Name] = "sphere_adv_fusion_reactor"}
advRadarByFaction = { [side1Name] = "aven_advanced_radar_tower", [side2Name] = "gear_advanced_radar_tower", [side3Name] = "claw_advanced_radar_tower", [side4Name] = "sphere_adv_radar_tower"}
commanderMorphByFaction = {[side1Name] = {"aven_u1commander","aven_u2commander","aven_u3commander","aven_u4commander","aven_u5commander","aven_u6commander"}, [side2Name] = {"gear_u1commander","gear_u2commander","gear_u3commander","gear_u4commander","gear_u5commander","gear_u6commander"}, [side3Name] = {"claw_u1commander","claw_u2commander","claw_u3commander","claw_u4commander","claw_u5commander","claw_u6commander"}, [side4Name] = {"sphere_u1commander","sphere_u2commander","sphere_u3commander","sphere_u4commander","sphere_u5commander","sphere_u6commander"}}
airRepairPadByFaction = { [side1Name] = "aven_air_repair_pad", [side2Name] = "gear_air_repair_pad", [side3Name] = "claw_air_repair_pad", [side4Name] = "sphere_air_repair_pad"}
commanderMorphCmdByFaction = {[side1Name] = {31433,31434,31435,31436}, [side2Name] = {31427,31428,31429,31430}, [side3Name] = {31423,31424,31425,31426}, [side4Name] = {31412,31413,31414,31415}}
nanoTowerFaction =  { [side1Name] = "aven_nano_tower", [side2Name] = "gear_nano_tower", [side3Name] = "claw_nano_tower", [side4Name] = "sphere_pole"}
upgradeCenterByFaction = { [side1Name] = "aven_upgrade_center", [side2Name] = "gear_upgrade_center", [side3Name] = "claw_upgrade_center", [side4Name] = "sphere_upgrade_center"}
scoutPadByFaction =  { [side1Name] = "aven_scout_pad", [side2Name] = "gear_scout_pad", [side3Name] = "claw_scout_pad", [side4Name] = "sphere_scout_pad"}
airScoutByFaction =  { [side1Name] = "aven_peeper", [side2Name] = "gear_fink", [side3Name] = "claw_spotter", [side4Name] = "sphere_probe"}
fusionByFaction = { [side1Name] = "aven_fusion_reactor", [side2Name] = "gear_fusion_power_plant", [side3Name] = "claw_adv_fusion_reactor", [side4Name] = "sphere_adv_fusion_reactor"}
UWMexByFaction =  { [side1Name] = "aven_metal_extractor", [side2Name] = "gear_metal_extractor", [side3Name] = "claw_metal_extractor", [side4Name] = "sphere_metal_extractor"}
UWMohoMineByFaction = { [side1Name] = "aven_moho_mine", [side2Name] = "gear_moho_mine", [side3Name] = "claw_moho_mine", [side4Name] = "sphere_moho_mine"}
tidalByFaction = { [side1Name] = "aven_tidal_generator", [side2Name] = "gear_tidal_generator", [side3Name] = "claw_tidal_generator", [side4Name] = "sphere_tidal_generator"} 
waterLltByFaction = { [side1Name] = "aven_light_laser_tower", [side2Name] = "gear_light_laser_tower", [side3Name] = "claw_drill", [side4Name] = "sphere_stir"}
UWFusionByFaction = { [side1Name] = "aven_fusion_reactor", [side2Name] = "gear_fusion_power_plant", [side3Name] = "claw_adv_fusion_reactor", [side4Name] = "sphere_adv_fusion_reactor"}
waterLightAAByFaction = { [side1Name] = "aven_defender", [side2Name] = "gear_pulverizer"}
lev1WaterHeavyDefenseByFaction = {[side1Name] = {"aven_sentinel"}, [side2Name] = {"gear_blaze"}, [side3Name] = {"claw_piercer"}}
lev1TorpedoDefenseByFaction = {[side1Name] = "aven_torpedo_launcher", [side2Name] = "gear_torpedo_launcher", [side3Name] = "claw_sinker", [side4Name] = "sphere_clam"}
lev2TorpedoDefenseByFaction = {[side1Name] = "aven_advanced_torpedo_launcher", [side2Name] = "gear_advanced_torpedo_launcher", [side3Name] = "claw_nailer", [side4Name] = "sphere_oyster"}
waterRadarByFaction = { [side1Name] = "aven_radar_tower", [side2Name] = "gear_radar_tower", [side3Name] = "claw_radar_tower", [side4Name] = "sphere_radar_tower"}
sonarByFaction = { [side1Name] = "aven_sonar_station", [side2Name] = "gear_sonar_station", [side3Name] = "claw_sonar_station", [side4Name] = "sphere_sonar_station"}
advSonarByFaction = { [side1Name] = "aven_advanced_sonar_station", [side2Name] = "gear_advanced_sonar_station", [side3Name] = "claw_advanced_sonar_station", [side4Name] = "sphere_advanced_sonar_station"}
jammerByFaction = { [side1Name] = "aven_radar_jamming_tower", [side2Name] = "gear_radar_jamming_tower", [side3Name] = "claw_radar_jamming_tower", [side4Name] = "sphere_radar_jamming_tower"}
mmakerByFaction =  { [side1Name] = "aven_metal_maker", [side2Name] = "gear_metal_maker", [side3Name] = "claw_metal_maker", [side4Name] = "sphere_metal_maker"}
rocketPlatformByFaction =  { [side1Name] = "aven_long_range_rocket_platform", [side2Name] = "gear_long_range_rocket_platform", [side3Name] = "claw_long_range_rocket_platform", [side4Name] = "sphere_long_range_rocket_platform"}
unblockableNukeByFaction =  { [side1Name] = "aven_premium_nuclear_rocket", [side2Name] = "gear_premium_nuclear_rocket", [side3Name] = "claw_premium_nuclear_rocket", [side4Name] = "sphere_premium_nuclear_rocket"}
comsatByFaction =  { [side1Name] = "aven_comsat_station", [side2Name] = "gear_comsat_station", [side3Name] = "claw_comsat_station", [side4Name] = "sphere_comsat_station"}



unitTypeSets = {
	[TYPE_LIGHT_DEFENSE] = tableToSet({lltByFaction,waterLltByFaction}),
	[TYPE_HEAVY_DEFENSE] = tableToSet({lev1HeavyDefenseByFaction,lev1WaterHeavyDefenseByFaction}),
	[TYPE_ARTILLERY_DEFENSE] = tableToSet({lev1ArtilleryDefenseByFaction,lev2ArtilleryDefenseByFaction}),
	[TYPE_LONG_RANGE_ARTILLERY] = tableToSet(lev2LongRangeArtilleryByFaction),
	[TYPE_RESPAWNER]= tableToSet(respawnerByFaction),
	[TYPE_L1_PLANT] = tableToSet(lev1PlantByFaction),
	[TYPE_L2_PLANT] = tableToSet({lev2PlantByFaction,{"aven_adv_shipyard","gear_adv_shipyard","claw_adv_shipyard","sphere_adv_shipyard"}}),
	[TYPE_FUSION] = tableToSet(fusionByFaction),
	[TYPE_MEX] = tableToSet({mexByFaction,UWMexByFaction}),
	[TYPE_MOHO] = tableToSet({mohoMineByFaction,UWMohoMineByFaction,hazMexByFaction}),
	[TYPE_HAZMOHO] = tableToSet(hazMexByFaction),
	[TYPE_EXTRACTOR] = tableToSet({mexByFaction,hazMexByFaction,UWMexByFaction,mohoMineByFaction,UWMohoMineByFaction}),
	[TYPE_PNODE] = tableToSet(powerNodeByFaction),
	[TYPE_ENERGYGENERATOR] = tableToSet({solarByFaction,windByFaction,geoByFaction,fusionByFaction,tidalByFaction,{"sphere_fusion_reactor","sphere_hardened_fission_reactor","aven_bio_dome","gear_mass_burner","claw_totem"}}),
	[TYPE_ECONOMY] = tableToSet({tidalByFaction,mexByFaction,hazMexByFaction,mohoMineByFaction,mmakerByFaction,solarByFaction,windByFaction,geoByFaction,fusionByFaction,energyStorageByFaction,metalStorageByFaction,powerNodeByFaction,{"sphere_fusion_reactor","sphere_hardened_fission_reactor","aven_bio_dome","gear_mass_burner","claw_totem"}}),
	[TYPE_PLANT] = tableToSet({lev1PlantByFaction,lev2PlantByFaction}),
	[TYPE_UW_DEFENSE] = tableToSet({lev1TorpedoDefenseByFaction,lev2TorpedoDefenseByFaction}),		
	[TYPE_ATTACKER] = listToSet({attackerList,airAttackerList,seaAttackerList}),
	[TYPE_AIR_ATTACKER] = listToSet(airAttackerList),
	[TYPE_SEA_ATTACKER] = listToSet(seaAttackerList),
	[TYPE_AMPHIBIOUS_ATTACKER] = listToSet(seaAttackerList),
	[TYPE_L1_CONSTRUCTOR] = listToSet(l1ConstructorList),		-- not used
	[TYPE_L2_CONSTRUCTOR] = listToSet(l2ConstructorList),		-- not used
	[TYPE_BASE] = tableToSet({mohoMineByFaction,geoByFaction,fusionByFaction,lvl1PlantByFaction,lvl2PlantByFaction,lev1HeavyDefenseByFaction,lev1ArtilleryDefenseByFaction,lev2ArtilleryDefenseByFaction,lev2LongRangeArtilleryByFaction,heavyAAByFaction,comsatByFaction}),
	[TYPE_LIGHT_AA] = tableToSet(lightAAByFaction),
	[TYPE_MEDIUM_AA] = tableToSet(mediumAAByFaction),
	[TYPE_HEAVY_AA] = tableToSet(heavyAAByFaction),
	[TYPE_SUPPORT] = listToSet(supporterList),
	[TYPE_COMMANDER] = tableToSet({commanderByFaction,commanderMorphByFaction}),
	[TYPE_UPGRADED_COMMANDER] = tableToSet({commanderMorphByFaction}),
	[TYPE_STRATEGIC] = tableToSet({lev1ArtilleryDefenseByFaction,lev2ArtilleryDefenseByFaction,lev2LongRangeArtilleryByFaction,mexByFaction, UWMexByFaction, mohoMineByFaction,UWMohoMineByFaction,fusionByFaction,UWFusionByFaction,rocketPlatformByFaction}),
	[TYPE_UPGRADE_CENTER] = tableToSet(upgradeCenterByFaction),
	[TYPE_HIGH_PRIORITY] = tableToSet({commanderByFaction,commanderMorphByFaction,respawnerByFaction,rocketPlatformByFaction,upgradeCenterByFaction}),
	[TYPE_FAKE_WEAPON] = tableToSet({comsatByFaction}),
	[TYPE_NUKE] = tableToSet({unblockableNukeByFaction})
}
