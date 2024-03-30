function gadget:GetInfo()
	return {
		name	= "Optional Buildoptions Handler",
		desc	= "Adjusts optional build options from factories to match the owner's configuration.",
		author	= "raaar",
		date	= "2023",
		license	= "PD",
		layer	= 0,
		enabled	= true
	}
end

--TODO reloading luarules ingame clears optional build options for all players

local spFindUnitCmdDesc = Spring.FindUnitCmdDesc 
local spInsertUnitCmdDesc = Spring.InsertUnitCmdDesc 
local spEditUnitCmdDesc = Spring.EditUnitCmdDesc
local spGetTeamList = Spring.GetTeamList 
local spGetPlayerInfo = Spring.GetPlayerInfo
local spSendLuaRulesMsg = Spring.SendLuaRulesMsg
local spGetAllUnits = Spring.GetAllUnits
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitTeam = Spring.GetUnitTeam

include("lualibs/constants.lua")
include("lualibs/util.lua")

local EXTERNAL_CMD_SETOPTIONALUNITS = "SETOPTIONALUNITS"

local optionalUnitDefIds = {}
local optionalUnitNames = {}

optionalUnitDefIdsByTeam = {}

------------------------------------------ SYNCED

if (gadgetHandler:IsSyncedCode()) then


------------------------- auxiliary functions

local function checkUnitBuildOptions(unitId,teamId)
	-- check each optional unit that the factory has on its build list
	for udId,enabled in pairs(optionalUnitDefIdsByTeam[teamId]) do
		local cmdDescId = spFindUnitCmdDesc(unitId, -udId)
		if (cmdDescId) then
			local cmdArray = {disabled = (not enabled)}
			--Spring.Echo("uId="..unitId..", tId="..teamId..", optionalBuildOpt["..UnitDefs[udId].name.."]="..tostring(enabled))
			spEditUnitCmdDesc(unitId, cmdDescId, cmdArray)
		end
	end
end

local function loadOptionalUnitsFromArrayForTeam(teamId,unitsArray)
	optionalUnitDefIdsByTeam[teamId], countByFaction = getOptionalUnitsFromArray(teamId,unitsArray)
	
	-- fill in the remaining entries with false
	local teamOptTable = optionalUnitDefIdsByTeam[teamId]
	for unitId,_ in pairs(optionalUnitDefIds) do
		if teamOptTable[unitId] == nil then
			teamOptTable[unitId] = false
		end
	end
end
GG.loadOptionalUnitsFromArrayForTeam = loadOptionalUnitsFromArrayForTeam

------------------------- engine callins

function gadget:Initialize()
	-- build list of optional units
	for id, ud in pairs (UnitDefs) do
		local cp = ud.customParams
		if cp and cp.optional == "1" then
			--Spring.Echo(ud.name.." is OPTIONAL unit")
			optionalUnitDefIds[ud.id] = true
			optionalUnitNames[ud.name] = true
		end
	end
	
	-- init optional unit status table for each team
	local gaiaTeamID = Spring.GetGaiaTeamID()
	local teams = Spring.GetTeamList()
	for i = 1,#teams do
		local teamId = teams[i]
		local teamOptTable = {}
		optionalUnitDefIdsByTeam[teamId] = teamOptTable
		for unitId,_ in pairs(optionalUnitDefIds) do
			teamOptTable[unitId] = false
		end
    end
    
    -- testing, add an optional unit to team 1
	--optionalUnitDefIdsByTeam[0][UnitDefNames["claw_flayer"].id] = false
    --optionalUnitDefIdsByTeam[1][UnitDefNames["claw_flayer"].id] = true
end

function gadget:UnitCreated(unitId, unitDefId, teamId)
	local ud = UnitDefs[unitDefId]
	if ud.isBuilder then
		checkUnitBuildOptions(unitId,teamId)
	end
end


function gadget:RecvLuaMsg(msg, playerId)
	--Spring.Echo("received lua msg from player "..playerId..": "..msg) --DEBUG
	local pName,active,spectator,teamId,allyId,_,_,_,_,_ = spGetPlayerInfo(playerId)

	if (active and not spectator) and (string.find(msg,EXTERNAL_CMD_SETOPTIONALUNITS) ~= nil ) then
		-- extract text from message properly (compressed text may have the separator)
		local optionalUnitsTextCompressed = string.sub(msg,string.len(EXTERNAL_CMD_SETOPTIONALUNITS)+2)
		local optionalUnitsText = VFS.ZlibDecompress(optionalUnitsTextCompressed)
		
		optionalUnitDefIdsByTeam[teamId], countByFaction = getOptionalUnitsFromText(teamId,optionalUnitsText)
		
		-- fill in the remaining entries with false
		local teamOptTable = optionalUnitDefIdsByTeam[teamId]
		for unitId,_ in pairs(optionalUnitDefIds) do
			if teamOptTable[unitId] == nil then
				teamOptTable[unitId] = false
			end
		end
	end
end

-- fix the optional build options for builders immediately after the game starts
-- as the updated options were set and locked-in after they spawned 
local startSpawnedBuildersFixRequired = true
function gadget:GameFrame(f)
	if f > 0 and startSpawnedBuildersFixRequired then
		startSpawnedBuildersFixRequired = false
		for _,uId in ipairs(spGetAllUnits()) do
			gadget:UnitCreated(uId, spGetUnitDefID(uId), spGetUnitTeam(uId))
		end
	end
end

------------------------------------------ UNSYNCED
else

local optionalUnitsSet = false


function gadget:GameStart()
	if ( optionalUnitsSet == false ) then
		optionalUnitsSet = true

		-- try to load optional list from local file, send to luarules
		local text = VFS.FileExists(optionalUnitsFile) and VFS.LoadFile(optionalUnitsFile) or defaultOptionalUnitsText
		local compressedText = VFS.ZlibCompress(text)
		local str = EXTERNAL_CMD_SETOPTIONALUNITS.."|"..compressedText

		--Spring.Echo("optional unit selection set")
		spSendLuaRulesMsg(str)
	end
end


end

