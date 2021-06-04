
-------------------------------------------- FUNCTION ALIASES

sqrt = math.sqrt
max = math.max
min = math.min
abs = math.abs
fmod = math.fmod
random = math.random
floor = math.floor
Echo = Spring.Echo

spGetGameFrame = Spring.GetGameFrame
spTestBuildOrder = Spring.TestBuildOrder
spGetTeamResources = Spring.GetTeamResources
spGetUnitPosition = Spring.GetUnitPosition
spGetUnitDefID = Spring.GetUnitDefID
spGetUnitHealth = Spring.GetUnitHealth
spGetFeaturesInSphere = Spring.GetFeaturesInSphere
spGiveOrderToUnit = Spring.GiveOrderToUnit
spTestMoveOrder = Spring.TestMoveOrder
spGetGroundInfo = Spring.GetGroundInfo
spGetGroundHeight = Spring.GetGroundHeight
spGetGroundNormal = Spring.GetGroundNormal
spGetUnitDefDimensions = Spring.GetUnitDefDimensions
spGetCommandQueue = Spring.GetCommandQueue
spGetFeatureDefID = Spring.GetFeatureDefID
spGetFeaturePosition = Spring.GetFeaturePosition
spGetUnitMoveTypeData = Spring.GetUnitMoveTypeData
spGetAllUnits = Spring.GetAllUnits
spGetTeamInfo = Spring.GetTeamInfo
spGetTeamList = Spring.GetTeamList
spGetPlayerList = Spring.GetPlayerList
spGetPlayerInfo = Spring.GetPlayerInfo
spDestroyUnit = Spring.DestroyUnit

-------------------------------------------- CONSTANTS
ENERGY_METAL_VALUE = 1/60




-------------------------------------------- GENERIC
-- sets, tables, string manipulation, etc. 



function addToSet(set, key)
	set[key] = true
end

function removeFromSet(set, key)
	set[key] = nil
end

function setContains(set, key)
	return set[key] ~= nil
end

function listToSet (list)
	local set = {}
	for _, l in ipairs(list) do set[l] = true end
	return set
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


function splitString(input, sep)
	if sep == nil then
		sep = "%s"
	end
	local t={}
	for str in string.gmatch(input, "([^"..sep.."]+)") do
		table.insert(t, str)
	end
	return t
end


-------------------------------------------- OTHER


function log(inStr, ai)
	if DEBUG then
		if( ai ~= nil ) then
			Echo("player "..ai.id.." : "..inStr)
		else
			Echo(inStr)
		end
	end
end

local xd
local zd
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

function getWeightedCost(ud)
	if (ud ~= nil) then
		return ud.metalCost + ud.energyCost * ENERGY_METAL_VALUE
	end

	return 0
end

-- checks if unit is a commander
function isCommander(ud)
	if (ud.customParams.iscommander) then
		return true
	end
	return false
end
