
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


GFX_LOW = 0
GFX_MEDIUM = 1
GFX_HIGH = 2

-------------------------------------------- WIDGET HANDLING

function disableWidget(name)
	Spring.SendCommands("disablewidget "..name)
end

function enableWidget(name)
	Spring.SendCommands("enablewidget "..name)
end

-------------------------------------------- GENERIC
-- sets, tables, string manipulation, etc. 


function tableValToStr ( v )
	if "string" == type( v ) then
		v = string.gsub( v, "\n", "\\n" )
		if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
			return "'" .. v .. "'"
		end
		return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
	else
		return "table" == type( v ) and table.tostring( v ) or tostring( v )
	end
end

function tableKeyToStr ( k )
	if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
		return k
	else
		return "[" .. tableValToStr( k ) .. "]"
	end
end

function tableToString( tbl )
	local result, done = {}, {}
	for k, v in ipairs( tbl ) do
		table.insert( result, tableValToStr( v ) )
		done[ k ] = true
	end
	for k, v in pairs( tbl ) do
		if not done[ k ] then
			table.insert( result,tableKeyToStr( k ) .. "=" .. tableValToStr( v ) )
		end
	end
	return "{" .. table.concat( result, "," ) .. "}"
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

function mergeTable(table1,table2)
	local result = {}
	for i,v in pairs(table2) do 
		if (type(v)=='table') then
			result[i] = mergeTable(v,{})
		else
			result[i] = v
		end
	end
	for i,v in pairs(table1) do 
		if (result[i]==nil) then
			if (type(v)=='table') then
				if (type(result[i])~='table') then result[i] = {} end
				result[i] = mergeTable(v,result[i])
			else
				result[i] = v
			end
		end
	end
	return result
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

-- trim string
function trim(s)
   return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
end

-- convert number to string with N decimal digits
function formatNbr(x,digits)
	if x then
		local ret=string.format("%."..(digits or 0).."f",x)
		if digits and digits>0 then
			while true do
				local last = string.sub(ret,string.len(ret))
				if last=="0" or last=="." then
					ret = string.sub(ret,1,string.len(ret)-1)
				end
				if last~="0" then
					break
				end
			end
		end
		return ret
	else
		return ""
	end
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
	if (ud.customParams and ud.customParams.iscommander) then
		return true
	end
	return false
end
