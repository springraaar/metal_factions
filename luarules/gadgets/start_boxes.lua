

function gadget:GetInfo() return {
	name     = "Startbox handler",
	desc     = "Handles startboxes",
	author   = "Sprung, modified by raaar",
	date     = "2015-05-19",
	license  = "PD",
	layer    = -math.huge, -- in particular, before mex_spot_finder (so mexes can depend on occupied boxes)
	enabled  = true,
} end

------------ code imported from DarkBlueDiamond's ZKL semi-compatible mod of MF 2.58 in november 2026
--TODO further cleanup required, lots of rulesParams set aren't used by MF at all


local gaiaAllyTeamID = select(6, Spring.GetTeamInfo(Spring.GetGaiaTeamID(), false))
local shuffleMode = Spring.GetModOptions().shuffle or "auto"
local startboxConfig
local rectBoxCoordsById = {}

if not gadgetHandler:IsSyncedCode() or VFS.FileExists("mission.lua") then return end

------------ code from startbox_utilities.lua

local function WrappedInclude(x)
	local env = getfenv()
	local prevGTC = env.GetTeamCount -- typically nil but also works otherwise
	env.GetTeamCount = Spring.Utilities.GetTeamCount -- for legacy mapside boxes
	local ret = VFS.Include(x, env)
	env.GetTeamCount = prevGTC
	return ret
end

local function GetStartboxName(midX, midZ)
	if (midX < 0.33) then
		if (midZ < 0.33) then
			return "North-West", "NW"
		elseif (midZ > 0.66) then
			return "South-West", "SW"
		else
			return "West", "W"
		end
	elseif (midX > 0.66) then
		if (midZ < 0.33) then
			return "North-East", "NE"
		elseif (midZ > 0.66) then
			return "South-East", "SE"
		else
			return "East", "E"
		end
	else
		if (midZ < 0.33) then
			return "North", "N"
		elseif (midZ > 0.66) then
			return "South", "S"
		else
			return "Center", "Center"
		end
	end
end

local function distance(a,b)
	return sqrt(pow(b.x-a.x,2)+pow(b.z-a.z,2))
end


local function getBestSpreadStartPosArr(teamStartPosArr, teamCount)
	local bestDistanceSum = 0
	local N = #teamStartPosArr
	local bestSubset = {}
	
	local function choose(start, remaining, current)
		--Spring.Echo("CHOOSE start="..start.." remaining="..remaining.." #current="..#current)
		if remaining == 0 then
			-- here we have a unique subset of teamCount elements from teamStartPosArr, check for best distances
			local distanceSum = 0
			for i=1,#current do
				for j=1,#current do
					if j ~= i then
						distanceSum = distanceSum + distance(current[i],current[j])
					end
				end
			end
			
			-- if bigger spread so far, update best  
			if distanceSum > bestDistanceSum then
				bestDistanceSum = distanceSum
				bestSubset = {}
				for _,el in pairs(current) do
					bestSubset[#bestSubset+1] = el
				end
			end
			
			return
		end
		
		for i=start,N-remaining do
			current[#current+1] = teamStartPosArr[i+1]
			choose(i+1, remaining-1, current)
			current[#current] = nil		-- remove last
		end	
	end
	
	-- start recursion that'll populate bestSubset
	choose(0,teamCount,{})
	  
	return bestSubset
end

local function ParseBoxes(teamCount)
	local mapsideBoxes = "mapconfig/map_startboxes.lua"
	local modsideBoxes = "luarules/configs/startBoxes/" .. (Game.mapName or "") .. ".lua"

	local startBoxConfig

	-- in case of FFA, if the number of team start locations is >= than the number of allyTeams, use smart startbox generation
	local smartFFABoxOverride = false
	local bestSpreadStartPosArr = {}
	if teamCount > 2 then

		local mapInfo = VFS.FileExists("mapinfo.lua") and VFS.Include("mapinfo.lua") or false
		local teamStartPosMap = mapInfo.teams
		local teamStartPosCount = #teamStartPosMap
		local teamStartPosArr = {}
				
		-- more start positions than teams, try to run the algorithm 
		if teamStartPosCount >= teamCount then
			Spring.Echo("3+ team FFA detected, no boxes set and same or more start positions defined : trying smart start box algorithm...")
			for i,t in ipairs(teamStartPosMap) do
				teamStartPosArr[#teamStartPosArr+1] = t.startpos
			end
			
			bestSpreadStartPosArr = getBestSpreadStartPosArr(teamStartPosArr, teamCount)

			if #bestSpreadStartPosArr == teamCount then
				smartFFABoxOverride = true
			end
		end
	end
	
	if smartFFABoxOverride then
		Spring.SetGameRulesParam("start_box_mode","smartffa")
		Spring.Echo("Using start boxes set by smart FFA box override")
		
		startBoxConfig = {}
		for i=1,#bestSpreadStartPosArr  do
			local pos = bestSpreadStartPosArr[i]
			
			local midX = pos.x
			local midZ = pos.z

			local xMin = max(0,min(Game.mapSizeX,midX-0.05*Game.mapSizeX))
			local zMin = max(0,min(Game.mapSizeZ,midZ-0.05*Game.mapSizeZ))
			local xMax = max(0,min(Game.mapSizeX,midX+0.05*Game.mapSizeX))
			local zMax = max(0,min(Game.mapSizeZ,midZ+0.05*Game.mapSizeZ))

			local name = "Team "..tostring(i-1)
			startBoxConfig[i-1] = {
				boxes = {{
					{xMin, zMin},
					{xMin, zMax},
					{xMax, zMax},
					{xMax, zMin},
				}},
				startpoints = {
					{midX, midZ}
				},
				nameLong = name,
				nameShort = name
			}
		end

	elseif VFS.FileExists(modsideBoxes) then
		Spring.SetGameRulesParam("start_box_mode","game")
		Spring.Echo("Using start boxes set by game package")
		startBoxConfig = WrappedInclude (modsideBoxes)
	elseif VFS.FileExists(mapsideBoxes) then
		Spring.SetGameRulesParam("start_box_mode","map")
		Spring.Echo("Using start boxes set by map")
		startBoxConfig = WrappedInclude(mapsideBoxes)
	else
		startBoxConfig = { }
		local startboxString = Spring.GetModOptions().startboxes
		local startboxStringLoadedBoxes = false
		if startboxString then
			Spring.SetGameRulesParam("start_box_mode","host")
			Spring.Echo("Using start boxes set by host/lobby (springie)")
			local springieBoxes = loadstring(startboxString)()
			for id, box in pairs(springieBoxes) do
				startboxStringLoadedBoxes = true -- Autohost always sends a table. Often it is empty.
				local midX = (box[1]+box[3]) / 2
				local midZ = (box[2]+box[4]) / 2

				box[1] = box[1]*Game.mapSizeX
				box[2] = box[2]*Game.mapSizeZ
				box[3] = box[3]*Game.mapSizeX
				box[4] = box[4]*Game.mapSizeZ

				local longName, shortName = GetStartboxName(midX, midZ)

				startBoxConfig[id] = {
					boxes = {{
						{box[1], box[2]},
						{box[1], box[4]},
						{box[3], box[4]},
						{box[3], box[2]},
					}},
					startpoints = {
						{(box[1]+box[3]) / 2, (box[2]+box[4]) / 2}
					},
					nameLong = longName,
					nameShort = shortName
				}
			end
		end
		
		if not startboxStringLoadedBoxes then
			if Game.mapSizeZ > Game.mapSizeX then
				startBoxConfig[0] = {
					boxes = {{
						{0, 0},
						{0, Game.mapSizeZ * 0.2},
						{Game.mapSizeX, Game.mapSizeZ * 0.2},
						{Game.mapSizeX, 0}
					}},
					startpoints = {
						{Game.mapSizeX * 0.5, Game.mapSizeZ * 0.1}
					},
					nameLong = "North",
					nameShort = "N"
				}
				startBoxConfig[1] = {
					boxes = {{
						{0, Game.mapSizeZ * 0.8},
						{0, Game.mapSizeZ},
						{Game.mapSizeX, Game.mapSizeZ},
						{Game.mapSizeX, Game.mapSizeZ * 0.8}
					}},
					startpoints = {
						{Game.mapSizeX * 0.5, Game.mapSizeZ * 0.9}
					},
					nameLong = "South",
					nameShort = "S"
				}
			else
				startBoxConfig[0] = {
					boxes = {{
						{0, 0},
						{0, Game.mapSizeZ},
						{Game.mapSizeX * 0.2, Game.mapSizeZ},
						{Game.mapSizeX * 0.2, 0},
					}},
					startpoints = {
						{Game.mapSizeX * 0.1, Game.mapSizeZ * 0.5}
					},
					nameLong = "West",
					nameShort = "W"
				}
				startBoxConfig[1] = {
					boxes = {{
						{Game.mapSizeX * 0.8, 0},
						{Game.mapSizeX * 0.8, Game.mapSizeZ - 1},
						{Game.mapSizeX, Game.mapSizeZ - 1},
						{Game.mapSizeX, 0},
					}},
					startpoints = {
						{Game.mapSizeX * 0.9, Game.mapSizeZ * 0.5}
					},
					nameLong = "East",
					nameShort = "E"
				}
			end
		end
	end

	-- fix rendering z-fighting
	for boxid, box in pairs(startBoxConfig) do
		for i = 1, #box.boxes do
			for j = 1, #box.boxes[i] do
				if box.boxes[i][j][2] > Game.mapSizeZ - 1 then
					box.boxes[i][j][2] = Game.mapSizeZ - 1
				end
			end
		end
	end

	return startBoxConfig
end

--------------------

------ code from teamFunctions.lua

Spring.Utilities = Spring.Utilities or {}

local teamCount
local is1v1, isTeams, isBigTeams, isSmallTeams, isChickens, isCoop, isCompStomp, isFFA, isTeamFFA, isSandbox, isPlanetWars = false, false, false, false, false, false, false, false, false, false, false
do
	local gaiaAllyTeamID = select(6, Spring.GetTeamInfo(Spring.GetGaiaTeamID(), false))
	local allyTeamList = Spring.GetAllyTeamList()
	local actualAllyTeamList = {}
	local entirelyHumanAllyTeams = {}
	for i = 1, #allyTeamList do
		local teamList = Spring.GetTeamList(allyTeamList[i]) or {}
		local allyteamEntirelyHuman = true
		if ((#teamList > 0) and (allyTeamList[i] ~= gaiaAllyTeamID)) then
			local isTeamValid = true
			for j = 1, #teamList do
				if select (4, Spring.GetTeamInfo(teamList[j], false)) then
					allyteamEntirelyHuman = false
				end
				local luaAI = Spring.GetTeamLuaAI(teamList[j])
				if luaAI and luaAI:find("Chicken") then
					isChickens = true
					isTeamValid = false
				end
			end
			if isTeamValid then
				actualAllyTeamList[#actualAllyTeamList+1] = allyTeamList[i]
			end
			if allyteamEntirelyHuman then
				entirelyHumanAllyTeams[#entirelyHumanAllyTeams+1] = allyTeamList[i]
			end
		end
	end
	teamCount = #actualAllyTeamList

	if teamCount > 2 then
		isFFA = true
		for i = 1, teamCount do
			if #Spring.GetTeamList(actualAllyTeamList[i]) > 1 then
				isTeamFFA = true
				break
			end
		end
		isChickens = false
	elseif teamCount < 2 then
		isSandbox = not isChickens
	else
		isChickens = false
		local cnt1 = #Spring.GetTeamList(actualAllyTeamList[1])
		local cnt2 = #Spring.GetTeamList(actualAllyTeamList[2])
		if cnt1 == 1 and cnt2 == 1 then
			is1v1 = true
		else
			isTeams = true
			if cnt1 <= 4 and cnt2 <= 4 then
				isSmallTeams = true
			else
				isBigTeams = true
			end
		end
	end

	if #entirelyHumanAllyTeams == 1 then
		isCompStomp = true
		isCoop = (#Spring.GetTeamList(entirelyHumanAllyTeams[1]) > 1)
	end

	if Spring.GetModOptions().planet then
		isPlanetWars = true
	end
end

function Spring.Utilities.GetTeamCount()
	return teamCount
end

Spring.Utilities.Gametype = {
	is1v1        = function () return is1v1        end,
	isTeams      = function () return isTeams      end,
	isBigTeams   = function () return isBigTeams   end,
	isSmallTeams = function () return isSmallTeams end,
	isChickens   = function () return isChickens   end,
	isCoop       = function () return isCoop       end,
	isCompStomp  = function () return isCompStomp  end,
	isTeamFFA    = function () return isTeamFFA    end,
	isFFA        = function () return isFFA        end,
	isSandbox    = function () return isSandbox    end,
	isPlanetWars = function () return isPlanetWars end,
}



-------------------

VFS.Include("lualibs/mathExt.lua", nil, VFS.ZIP)
VFS.Include("lualibs/util.lua", nil, VFS.ZIP)


local function GetAverageStartpoint(boxID)
	local box = startboxConfig[boxID]
	local startpoints = box.startpoints

	local x, z = 0, 0
	for i = 1, #startpoints do
		x = x + startpoints[i][1]
		z = z + startpoints[i][2]
	end
	x = x / #startpoints
	z = z / #startpoints
	
	return x, z
end

-- find the rectangular box that contains all the polygons for a given start box 
local function GetRectangularBoxCoords(boxID)
	local xMin = Game.mapSizeX
	local zMin = Game.mapSizeZ
	local xMax = 0
	local zMax = 0
	local x,z

	local box = startboxConfig[boxID]
	-- iterate through polygon vertexes and find the box what contains them all
	local polygons = box.boxes
	for i = 1, #polygons do
		local polygon = polygons[i]
		for j = 1, #polygon do
			local vertex = polygon[j]  
			x=vertex[1]
			z=vertex[2]
			
			if x < xMin then
				xMin = x
			end
			if x > xMax then
				xMax = x
			end
			if z < zMin then
				zMin = z
			end
			if z > zMax then
				zMax = z
			end
		end
	end
	
	return xMin, zMin, xMax, zMax
end




local function RectangularizeTrapezoid(edgeA, edgeB)
	local vector = Spring.Utilities.Vector
	local origin = edgeA[1]
	local unit = vector.Unit(vector.Subtract(edgeA[2], edgeA[1]))

	if (edgeA[1][1] < edgeA[1][2]) ~= (edgeB[1][1] < edgeB[1][2]) then
		-- Swap points if lines are passed backwards
		edgeB[1], edgeB[2] = edgeB[2], edgeB[1]
	end
	
	local distANear, distAFar = 0, vector.AbsVal(vector.Subtract(edgeA[2], edgeA[1]))
	local distBNear, distBFar = vector.Dot(vector.Subtract(edgeB[1], edgeA[1]), unit), vector.Dot(vector.Subtract(edgeB[2], edgeA[1]), unit)
	
	local nearDist, farDist = math.max(distANear, distBNear), math.min(distAFar, distBFar)
	
	edgeA[1] = vector.Add(origin, vector.Mult(nearDist, unit))
	edgeA[2] = vector.Add(origin, vector.Mult(farDist, unit))
	local normal = vector.Normal(vector.Subtract(edgeB[1], edgeA[1]), unit)
	return {edgeA[1], vector.Subtract(edgeA[2], edgeA[1]), normal}
end

local function GetBoxID(allyTeamID)
	local teamID = Spring.GetTeamList(allyTeamID)[1]
	if not teamID then
		return
	end
	local boxID = Spring.GetTeamRulesParam(teamID, "start_box_id")
	return boxID
end


local function CheckStartbox (boxID, x, z)
	if not boxID then
		return true
	end

	local box = startboxConfig[boxID] and startboxConfig[boxID].boxes
	if not box then
		return true
	end

	for i = 1, #box do
		local x1, z1, x2, z2, x3, z3 = unpack(box[i])
		if (math.cross_product(x, z, x1, z1, x2, z2) <= 0
		and math.cross_product(x, z, x2, z2, x3, z3) <= 0
		and math.cross_product(x, z, x3, z3, x1, z1) <= 0
		) then
			return true
		end
	end

	return false
end

-- name, elo, clanShort, clanLong, isAI
local function GetPlayerInfo (teamID)
	local _,playerID,_,isAI = Spring.GetTeamInfo(teamID, false)

	if isAI then
		return select(2, Spring.GetAIInfo(teamID)), -1000, "", "", true
	end

	local name = Spring.GetPlayerInfo(playerID, false) or "?"
	local customKeys = select(10, Spring.GetPlayerInfo(playerID)) or {}
	local clanShort = customKeys.clan     or ""
	local clanLong  = customKeys.clanfull or ""
	local elo       = customKeys.elo      or "0"
	return name, tonumber(elo), clanShort, clanLong, false
end

-- returns full name, short name, clan full name, clan short name
local function GetTeamNames (allyTeamID)
	if allyTeamID == gaiaAllyTeamID then
		return "Neutral", "Neutral" -- more descriptive than "Gaia"
	end


	local teamList = Spring.GetTeamList(allyTeamID) or {}
	if #teamList == 0 then
		return "Empty", "Empty"
	end

	local clanShortName, clanLongName
	local clanFirst = true
	local leaderName = ""
	local leaderElo = -2000
	local bots = 0
	local humans = 0
	for i = 1, #teamList do
		local name, elo, clanShort, clanLong, isAI = GetPlayerInfo(teamList[i])
		if not isAI then
			if clanFirst then
				clanShortName = clanShort
				clanLongName  = clanLong
				clanFirst = false
			else
				if clanShort ~= clanShortName then
					clanShortName = ""
					clanLongName = ""
				end
			end
		end

		if elo > leaderElo then
			leaderName = name
			leaderElo = elo
		end

		if isAI then
			bots = bots + 1
		else
			humans = humans + 1
		end
	end

	if humans == 1 then
		return leaderName, leaderName
	end

	if humans == 0 then
		return "AI", "AI"
	end

	local boxCount = 0
	for _ in pairs(startboxConfig) do
		boxCount = boxCount + 1
	end

	if ((shuffleMode == "off")
		or (Spring.Utilities.GetTeamCount() == 2 and shuffleMode == "shuffle")
		or (boxCount == 2 and shuffleMode == "allshuffle"))
	then
		local boxID = Spring.GetTeamRulesParam(teamList[1], "start_box_id")
		if boxID then
			local box = startboxConfig[boxID]
			if box.nameLong and box.nameShort then
				return box.nameLong, box.nameShort, clanLongName, clanShortName
			end
		end
	end

	return ("Team " .. leaderName), leaderName, clanLongName, clanShortName
end

function hasStartBox(xMin,xMax,zMin,zMax)
	if xMin > 1 then
		return true
	end
	if zMin > 1 then
		return true
	end
	if xMax < Game.mapSizeX-1 then
		return true
	end
	if zMax < Game.mapSizeZ-1 then
		return true
	end
	
	return false
end

function gadget:Initialize()
	local startBoxesSet = false
	
	-- filter out fake teams (empty or Gaia)
	local allyTeamList = Spring.GetAllyTeamList()
	local actualAllyTeamList = {}
	for i = 1, #allyTeamList do
		local allyId = allyTeamList[i]
		local teamList = Spring.GetTeamList(allyId) or {}
		if ((#teamList > 0) and (allyId ~= gaiaAllyTeamID)) then
			local xMin, zMin, xMax, zMax = Spring.GetAllyTeamStartBox(allyId)
			if hasStartBox(xMin,xMax,zMin,zMax) then
				startBoxesSet = true
			end	
		
			actualAllyTeamList[#actualAllyTeamList+1] = {allyId, math.random()}
		end
	end

	-- abort zk-style start box handling if host/lobby set start boxes
	--TODO support challenge maps
	if startBoxesSet then
		Spring.SetGameRulesParam("start_box_mode","host")
		Spring.Echo("Using start boxes set by host/lobby")
		return
	end	

	if shuffleMode == "auto" then
		if Spring.Utilities.GetTeamCount() > 2 then
			shuffleMode = "shuffle"
		elseif Spring.Utilities.GetTeamCount() == 2 then
			shuffleMode = "allshuffle"
		else
			-- 1 team: chickens
			shuffleMode = "off"
		end
	end
	Spring.SetGameRulesParam("shuffleMode", shuffleMode)

	startboxConfig = ParseBoxes(teamCount)

	GG.startBoxConfig = startboxConfig
	GG.CheckStartbox = CheckStartbox

	Spring.SetGameRulesParam("startbox_max_n", #startboxConfig)
	Spring.SetGameRulesParam("startbox_recommended_startpos", 1)

	for box_id, rawbox in pairs(startboxConfig) do
		local polygons = rawbox.boxes
		Spring.SetGameRulesParam("startbox_n_" .. box_id, #polygons)
		for i = 1, #polygons do
			local polygon = polygons[i]
			Spring.SetGameRulesParam("startbox_polygon_" .. box_id .. "_" .. i, #polygons[i])
			for j = 1, #polygons[i] do
				Spring.SetGameRulesParam("startbox_polygon_x_" .. box_id .. "_" .. i .. "_" .. j, polygons[i][j][1])
				Spring.SetGameRulesParam("startbox_polygon_z_" .. box_id .. "_" .. i .. "_" .. j, polygons[i][j][2])
			end
		end

		-- convert the parsed start boxes into rectangular engine start boxes
		-- TODO other properties set are not actually used in MF, for now
		local xMin,zMin,xMax,zMax = GetRectangularBoxCoords(box_id)
		rectBoxCoordsById[box_id] = {xMin,zMin,xMax,zMax}

		local startposes = rawbox.startpoints
		Spring.SetGameRulesParam("startpos_n_" .. box_id, #startposes)
		for i = 1, #startposes do
			Spring.SetGameRulesParam("startpos_x_" .. box_id .. "_" .. i, startposes[i][1])
			Spring.SetGameRulesParam("startpos_z_" .. box_id .. "_" .. i, startposes[i][2])
		end
		
		
	end

	for id, rawbox in pairs(startboxConfig) do
		rawbox.boxes = math.triangulate(rawbox.boxes)
	end

	if (shuffleMode == "off") or (shuffleMode == "disable") then

		for i = 1, #allyTeamList do
			local allyTeamID = allyTeamList[i]
			local boxID = allyTeamList[i]
			if startboxConfig[boxID] then
				local teamList = Spring.GetTeamList(allyTeamID) or {}
				for j = 1, #teamList do
					Spring.SetTeamRulesParam(teamList[j], "start_box_id", boxID)
				end
			end
		end

	elseif (shuffleMode == "shuffle") then

		local randomizedSequence = {}
		for i = 1, #actualAllyTeamList do
			randomizedSequence[#randomizedSequence + 1] = {actualAllyTeamList[i][1], math.random()}
		end
		table.sort(randomizedSequence, function(a, b) return (a[2] < b[2]) end)

		for i = 1, #actualAllyTeamList do
			local allyTeamID = actualAllyTeamList[i][1]
			local boxID = randomizedSequence[i][1]
			if startboxConfig[boxID] then
				local teamList = Spring.GetTeamList(allyTeamID) or {}
				for j = 1, #teamList do
					Spring.SetTeamRulesParam(teamList[j], "start_box_id", boxID)
				end
			end
		end

	elseif (shuffleMode == "allshuffle") then

		local randomizedSequence = {}
		for id in pairs(startboxConfig) do
			randomizedSequence[#randomizedSequence + 1] = {id, math.random()}
		end
		table.sort(randomizedSequence, function(a, b) return (a[2] < b[2]) end)
		table.sort(actualAllyTeamList, function(a, b) return (a[2] < b[2]) end)

		for i = 1, #actualAllyTeamList do
			local allyTeamID = actualAllyTeamList[i][1]
			local boxID = randomizedSequence[i] and randomizedSequence[i][1]
			if boxID and startboxConfig[boxID] then
				local teamList = Spring.GetTeamList(allyTeamID) or {}
				for j = 1, #teamList do
					Spring.SetTeamRulesParam(teamList[j], "start_box_id", boxID)
				end
			end
		end
	end

	local clans = {}
	for i = 1, #allyTeamList do
		local allyTeamID = allyTeamList[i]
		local longName, shortName, clanLong, clanShort = GetTeamNames(allyTeamID)
		Spring.SetGameRulesParam("allyteam_short_name_" .. allyTeamID, shortName)
		Spring.SetGameRulesParam("allyteam_long_name_"  .. allyTeamID, longName)
		if clanLong and clanLong ~= "" then
			clans[clanLong] = clans[clanLong] or {0, clanShort, allyTeamID}
			clans[clanLong][1] = clans[clanLong][1] + 1
		end
	end

	for clanName, clan in pairs(clans) do
		if (clan[1] == 1) and (clanName ~= "") then
			Spring.SetGameRulesParam("allyteam_short_name_" .. clan[3], clan[2])
			Spring.SetGameRulesParam("allyteam_long_name_"  .. clan[3], clanName)
		end
	end
	
	-- AllyTeam 'origin'
	for i = 1, #allyTeamList do
		local allyTeamID = allyTeamList[i]
		local boxID = GetBoxID(allyTeamID)
		if boxID then
			local boxX, boxZ = GetAverageStartpoint(boxID)
			if boxX and boxZ then
				local teamID = Spring.GetTeamList(allyTeamID)[1]
				Spring.SetTeamRulesParam(teamID, "allyteam_origin_x", boxX)
				Spring.SetTeamRulesParam(teamID, "allyteam_origin_z", boxZ)
				--Spring.MarkerAddPoint(boxX, 0, boxZ, "ally origin " .. allyTeamID)
			end
			
			-- convert the parsed start boxes into rectangular engine start boxes
			-- TODO other properties set earlier are not actually used in MF, for now
			local rectCoords = rectBoxCoordsById[boxID]
			local xMin,zMin,xMax,zMax = rectCoords[1],rectCoords[2],rectCoords[3],rectCoords[4]
			Spring.SetAllyTeamStartBox(allyTeamID, xMin, zMin, xMax, zMax)
			Spring.Echo("Start box for allyTeam "..allyTeamID.." set to ("..xMin..","..zMin..","..xMax..","..zMax..")")
		end
	end
end
