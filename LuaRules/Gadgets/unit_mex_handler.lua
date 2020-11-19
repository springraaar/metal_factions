function gadget:GetInfo() 
  return { 
    name      = "Metal Extractor Handler Gadget", 
    desc      = "Handles area metal max/moho/exploiter commands.", 
    author    = "raaar",
    date      = "2018", 
    license   = "PD", 
    layer     = 100, 
    enabled   = true 
  } 
end 

local insert = table.insert 
local remove = table.remove 

local spGetTeamUnits = Spring.GetTeamUnits 
local spGetUnitDefID = Spring.GetUnitDefID 
local spGiveOrderToUnit = Spring.GiveOrderToUnit 
local spGetUnitPosition = Spring.GetUnitPosition 
local spGetUnitHealth = Spring.GetUnitHealth 
local spGetUnitTeam = Spring.GetUnitTeam 
local spGetUnitAllyTeam = Spring.GetUnitAllyTeam
local spFindUnitCmdDesc = Spring.FindUnitCmdDesc 
local spInsertUnitCmdDesc = Spring.InsertUnitCmdDesc 
local spEditUnitCmdDesc = Spring.EditUnitCmdDesc
local spGetUnitsInCylinder = Spring.GetUnitsInCylinder
local spAreTeamsAllied = Spring.AreTeamsAllied
local spTestBuildOrder = Spring.TestBuildOrder
local spIsPosInLos = Spring.IsPosInLos
local spGetGroundHeight = Spring.GetGroundHeight
local spGetUnitIsStunned = Spring.GetUnitIsStunned

local MAP_EDGE_MARGIN = 50
local mapMinX = MAP_EDGE_MARGIN
local mapMaxX = Game.mapSizeX - MAP_EDGE_MARGIN
local mapMinZ = MAP_EDGE_MARGIN
local mapMaxZ = Game.mapSizeZ - MAP_EDGE_MARGIN

local basicMexIdByBuilderDefId = {}
local safeMexIdByBuilderDefId = {}
local hazardousMexIdByBuilderDefId = {}  
local builders = {} 


local basicMexDefIds = {
	[UnitDefNames['aven_metal_extractor'].id] = true,
	[UnitDefNames['gear_metal_extractor'].id] = true,
	[UnitDefNames['claw_metal_extractor'].id] = true,
	[UnitDefNames['sphere_metal_extractor'].id] = true
}

local safeMexDefIds = {
	[UnitDefNames['aven_moho_mine'].id] = true,
	[UnitDefNames['gear_moho_mine'].id] = true,
	[UnitDefNames['claw_moho_mine'].id] = true,
	[UnitDefNames['sphere_moho_mine'].id] = true
}

local hazardousMexDefIds = {
	[UnitDefNames['aven_exploiter'].id] = true,
	[UnitDefNames['gear_exploiter'].id] = true,
	[UnitDefNames['claw_exploiter'].id] = true,
	[UnitDefNames['sphere_exploiter'].id] = true
}

local CMD_RECLAIM = CMD.RECLAIM 
local CMD_STOP = CMD.STOP 
local CMD_INSERT = CMD.INSERT 
local CMD_OPT_INTERNAL = CMD.OPT_INTERNAL 

local CMD_UPGRADEMEX = 31244
local CMD_UPGRADEMEX2 = 31245
local CMD_AREAMEX = 31246  

local commandQueue = {}

local areaMexCmdDesc = { 
  id      = CMD_AREAMEX, 
  type    = CMDTYPE.ICON_UNIT_OR_AREA, 
  name    = ' ', -- 'Area Mex', 
  cursor  = 'Attack', 
  action  = 'areamex',
  texture = ":n:Luarules/Images/menu/areamex.png",
  tooltip = 'Click-drag to build Metal Extractors in an area.', 
  hidden  = false, 
  params  = {} 
} 


local upgradeMexCmdDesc = { 
  id      = CMD_UPGRADEMEX, 
  type    = CMDTYPE.ICON_UNIT_OR_AREA, 
  name    = '  ', -- 'Upgrade Mex Safe', 
  cursor  = 'Attack', 
  action  = 'upgrademoho',
  texture = ":n:Luarules/Images/menu/mexupg.png",
  tooltip = 'Click-drag to upgrade an area to Advanced Metal Extractors. Safe, but relatively expensive.', 
  hidden  = false, 
  params  = {} 
} 

local upgradeMex2CmdDesc = { 
  id      = CMD_UPGRADEMEX2, 
  type    = CMDTYPE.ICON_UNIT_OR_AREA, 
  name    = '   ', -- 'Upgrade Mex Hazardous', 
  cursor  = 'Attack', 
  action  = 'upgradeexploiter',
  texture = ":n:Luarules/Images/menu/mexupg2.png",
  tooltip = 'Click-drag to upgrade an area to Exploiter Metal Extractors. Hazardous!', 
  hidden  = false, 
  params  = {} 
} 


------ functions

-- determine metal extractor construction options for each builder unit
function determine() 
	local tmpbuilders = {} 
	for unitDefID, unitDef in pairs(UnitDefs) do 
		if isBuilder(unitDef) then 
			insert(tmpbuilders, unitDefID) 
		end 
	end 
      
	for _, unitDefID in ipairs(tmpbuilders) do 
		local basicMexDefId,safeMexDefId,hazardousMexDefId = getMexDefIds(UnitDefs[unitDefID].buildOptions)        
		--Spring.Echo(UnitDefs[unitDefID].name.." basic="..tostring(basicMexDefId).." safe="..tostring(safeMexDefId).." hazardous="..tostring(hazardousMexDefId))
		if basicMexDefId then
			basicMexIdByBuilderDefId[unitDefID] = basicMexDefId
		end
		if safeMexDefId and hazardousMexDefId then 
			safeMexIdByBuilderDefId[unitDefID] = safeMexDefId
			hazardousMexIdByBuilderDefId[unitDefID] = hazardousMexDefId
		end 
	end 
end

-- returns safeMexDefId and hazardousMexDefId available on given build option list, if any
function getMexDefIds(buildOptions)  
	local basicMexDefId = nil
	local safeMexDefId = nil
	local hazardousMexDefId = nil
	
	for _, optionID in ipairs(buildOptions) do
		if (basicMexDefIds[optionID]) then
			basicMexDefId = optionID
		elseif (safeMexDefIds[optionID]) then
			safeMexDefId = optionID
		elseif (hazardousMexDefIds[optionID]) then
			hazardousMexDefId = optionID
		end
	end
	return basicMexDefId, safeMexDefId, hazardousMexDefId 
end 

function isBuilder(unitDef) 
  return (unitDef.isBuilder and unitDef.canAssist) 
end 

-- tracks list of builders for each team
function registerUnits() 
	local teams = Spring.GetTeamList() 
	for _, teamID in ipairs(teams) do 
		builders[teamID] = {} 
		for _, unitID in ipairs(spGetTeamUnits(teamID)) do 
			local unitDefID = spGetUnitDefID(unitID) 
			registerUnit(unitID, unitDefID, teamID)    
		end 
	end 
end 

-- get closest metal spot
function getClosestMexSpot(x,z, spotsInRange) 
	local bestDistance = nil 
	local bestSpot = nil
	local bestSpotIndex = nil

	for i,spot in ipairs(spotsInRange) do 
		local dist = getDistanceFromPosition(x,z, spot) 
		if not bestDistance or dist < bestDistance then 
			bestDistance = dist 
			bestSpot = spot 
			bestSpotIndex = i
		end 
	end
	 
	return bestSpotIndex,bestSpot 
end 


function unregisterUnit(unitID, unitDefID, unitTeam, destroyed) 
	if builders[unitTeam][unitID] then 
		builders[unitTeam][unitID] = nil 
	end 
end 

function registerUnit(unitID, unitDefID, unitTeam) 
	if basicMexIdByBuilderDefId[unitDefID] or safeMexIdByBuilderDefId[unitDefID] then 
		local builder = {} 
		local unitDef = UnitDefs[unitDefID] 
  
		builder.unitDefID = unitDefID    
		builder.buildDistance = unitDef.buildDistance 
		builder.humanName = unitDef.humanName 
		builder.teamID = unitTeam 
		builders[unitTeam][unitID] = builder 
    	addLayoutCommands(unitID,unitDefID)
	end 
end 


-- get distance between two positions
function getDistanceFromPosition(x1, z1, pos) 
	local x2, z2 = pos.x, pos.z 
	return math.sqrt((x1-x2)^2 + (z1-z2)^2) 
end 


-- find closest build site for a unit near a search position
function findClosestBuildSite(unitDefId, searchPos, searchRadius)
	local testPos = { x = searchPos.x, y = searchPos.y, z = searchPos.z}
	 
	local xMin = searchPos.x - searchRadius
	local xMax = searchPos.x + searchRadius
	local zMin = searchPos.z - searchRadius
	local zMax = searchPos.z + searchRadius
	local step = 8
	local ud = UnitDefs[unitDefId]
	
	--Spring.Echo("finding closest build site for "..ud.name.." x: "..xMin.."-"..xMax.."z: "..zMin.."-"..zMax)
	local valid = false
	local groundMetal = 0
	local isMetalMap = GG.isMetalMap
	
	-- first, test the target position directly
	if spTestBuildOrder(unitDefId, testPos.x, testPos.y, testPos.z,0) > 0 then
		return testPos
	end
	
	-- test nearby positions
	for x = xMin, xMax, step do
		-- check x map bounds
		if (x > mapMinX) and (x < mapMaxX) then

			testPos.x = x
			for z = zMin, zMax, step do
				-- check z map bounds
				if (z > mapMinZ) and (z < mapMaxZ) then
					testPos.z = z
					
					-- check radius to avoid the "corners"
					if getDistanceFromPosition(x,z,searchPos) < searchRadius then
					
						-- check if unit can be built
						if spTestBuildOrder(unitDefId, testPos.x, testPos.y, testPos.z,0) > 0 then
							valid = true
	
							-- on metal maps, check if spot actually has metal
							-- (some metal maps have zones without metal)
							if (isMetalMap == true and ud.extractsMetal > 0) then
								 _,_, groundMetal = spGetGroundInfo(x, z)
								if groundMetal == 0 then
									valid = false								
								end
							end
	
							if (valid == true) then
								return testPos
							end
						end
					end
				end
			end
		end	
	end
	
	return nil
end


-- build metal extractor at or near the spot's position
function buildExtractor(spot, unitId, extractorId,opt)
	
	-- if the unit's owner can't see the spot, return its center
	local h = spGetGroundHeight(spot.x,spot.z)
	local inLos = spIsPosInLos(spot.x,h+20,spot.z,spGetUnitAllyTeam(unitId))

	if (not inLos) then
		spGiveOrderToUnit(unitId,-extractorId,{spot.x,h,spot.z},opt)
		--Spring.Echo("unit "..unitId.." trying to build "..UnitDefs[extractorId].name.." OUT OF LOS near ("..spot.x..","..spot.z..")")
	else
		--Spring.Echo("IN LOS")
		local buildPos = findClosestBuildSite(extractorId, spot, 70)
	
		if buildPos ~= nil then
			--Spring.Echo("unit "..unitId.." building "..UnitDefs[extractorId].name.." at ("..spot.x..","..spot.z..")")
			spGiveOrderToUnit(unitId,-extractorId,{buildPos.x,buildPos.y,buildPos.z},opt)
		else 
			--Spring.Echo("unit "..unitId.." could NOT build "..UnitDefs[extractorId].name.." near ("..spot.x..","..spot.z..")")
		end
	end
end

-- add commands to a unit's build menu
function addLayoutCommands(unitID,unitDefID) 
	local insertID = 
		spFindUnitCmdDesc(unitID, CMD.CLOAK)      or 
		spFindUnitCmdDesc(unitID, CMD.ONOFF)      or 
		spFindUnitCmdDesc(unitID, CMD.TRAJECTORY) or 
		spFindUnitCmdDesc(unitID, CMD.REPEAT)     or 
		spFindUnitCmdDesc(unitID, CMD.MOVE_STATE) or 
		spFindUnitCmdDesc(unitID, CMD.FIRE_STATE) or 
		123456 -- back of the pack 
    
    local inserted = 1
	if basicMexIdByBuilderDefId[unitDefID] then
		updateCommand(unitID, insertID + inserted, areaMexCmdDesc)
		inserted = inserted +1
		--Spring.Echo(UnitDefs[unitDefID].name.." has area mex button")  
	end
    if safeMexIdByBuilderDefId[unitDefID] then
		updateCommand(unitID, insertID + inserted, upgradeMexCmdDesc)
		inserted = inserted +1  
		updateCommand(unitID, insertID + inserted, upgradeMex2CmdDesc)
		
		--Spring.Echo(UnitDefs[unitDefID].name.." has upg buttons")
	end
end 

-- add a command to a unit's build menu
function updateCommand(unitID, insertID, cmd) 
	local cmdDescId = spFindUnitCmdDesc(unitID, cmd.id) 
	if not cmdDescId then 
		spInsertUnitCmdDesc(unitID, insertID, cmd) 
	else 
		spEditUnitCmdDesc(unitID, cmdDescId, cmd) 
	end 
end 

-- add command to queue
function addCommandToQueue(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	table.insert(commandQueue, {unitID,unitDefID,teamID,cmdID,cmdParams,cmdOptions})
end


-- process command
function processCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	local builder = builders[teamID][unitID]
	local x, y, z, radius 
	if not cmdParams[2] then
		-- Unit targeted
		if cmdID ~= CMD_UPGRADEMEX and cmdID ~= CMD_UPGRADEMEX2 then 
			return false 
		end 
   
		if builder then 
			local mexID = cmdParams[1] 
      		x,y,z = spGetUnitPosition(mexID)
      		radius = 100
		else
		 	return false
		end 
	else
		--Circle 
		x, y, z, radius = cmdParams[1], cmdParams[2], cmdParams[3], cmdParams[4] 
	end

	local spots = GG.metalSpots
	local spotsInRange = {}
	if builder then
		local ux,_,uz = spGetUnitPosition(unitID) 
		local replacementDefId = nil
		
		if cmdID == CMD_AREAMEX then
			replacementDefId = basicMexIdByBuilderDefId[builder.unitDefID]
		elseif cmdID == CMD_UPGRADEMEX then
			replacementDefId = safeMexIdByBuilderDefId[builder.unitDefID]
		elseif cmdID == CMD_UPGRADEMEX2 then
			replacementDefId = hazardousMexIdByBuilderDefId[builder.unitDefID]			
		end
		
		if replacementDefId == nil then
			return false
		end
		
		-- get spots in range of the target position
		for _,spot in pairs(spots) do 
			if getDistanceFromPosition(x, z, spot) < radius then 
				spotsInRange[#spotsInRange+1] = spot
			end 
		end
		
		-- get order for each spot within radius, starting by whichever's closest to the builder
		local nSpots = #spotsInRange
		local i = 0
		local spotIdx, spot
		while i < nSpots do
			if i == 0 or spot == nil then
				-- use unit position
				spotIdx, spot = getClosestMexSpot(ux,uz,spotsInRange)
			else
				-- use previous spot's position
				spotIdx, spot = getClosestMexSpot(spot.x,spot.z,spotsInRange)
			end
			
			if spot ~= nil then
				table.remove(spotsInRange, spotIdx)
				
				-- if there is already an extractor there, skip
				local nearbyUnits = spGetUnitsInCylinder(spot.x,spot.z,120)
				local alreadyBuilt = false
				for _,uId in pairs(nearbyUnits) do
					local uTeamId = spGetUnitTeam(uId)
					
					local _,_,_,_,bp = spGetUnitHealth(uId)
					if (cmdID == CMD_AREAMEX and (basicMexDefIds[spGetUnitDefID(uId)] or safeMexDefIds[spGetUnitDefID(uId)] or  hazardousMexDefIds[spGetUnitDefID(uId)])) then
						if teamID == uTeamId or spAreTeamsAllied(teamID,uTeamId) then
							alreadyBuilt = true
							if bp < 1 then
								-- finish the one already being built
								spGiveOrderToUnit(unitID,CMD.REPAIR,{uId},CMD.OPT_SHIFT)
							end
						end 
					elseif ((cmdID == CMD_UPGRADEMEX or cmdID == CMD_UPGRADEMEX2) and (safeMexDefIds[spGetUnitDefID(uId)] or hazardousMexDefIds[spGetUnitDefID(uId)] )) then
						if teamID == uTeamId or spAreTeamsAllied(teamID,uTeamId) then
							alreadyBuilt = true
							if bp < 1 then
								-- finish the one already being built
								spGiveOrderToUnit(unitID,CMD.REPAIR,{uId},CMD.OPT_SHIFT)
							end
						end 
					end
				end
				
				-- build new one
				if not alreadyBuilt then 
					buildExtractor(spot, unitID, replacementDefId,CMD.OPT_SHIFT)
				end
			end
			i = i + 1
		end
		
		Spring.PlaySoundFile('GENERICCMD', 1)
		return true, true
	end
	return false
end

------------------------------------------------ SYNCED
if (gadgetHandler:IsSyncedCode()) then 


function gadget:Initialize()  
	determine()
	registerUnits()  
	
	Spring.LoadSoundDef("LuaRules/Configs/sound_defs.lua")
end 


function gadget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam) 
	unregisterUnit(unitID, unitDefID, unitTeam, true) 
end 


function gadget:UnitTaken(unitID, unitDefID, unitTeam, newTeam) 
	unregisterUnit(unitID, unitDefID, unitTeam, false) 
end 


-- register builders
function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID) 
  registerUnit(unitID, unitDefID, unitTeam) 
end 

function gadget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam) 
  registerUnit(unitID, unitDefID, unitTeam) 
end 



-- handle commands
function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions, cmdTag, synced)
	if cmdID == CMD_UPGRADEMEX or cmdID == CMD_UPGRADEMEX2 or cmdID == CMD_AREAMEX then 
		--return processCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
		return addCommandToQueue(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	else
		return true
	end
end

function gadget:CommandFallback(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions) 
	if cmdID ~= CMD_UPGRADEMEX and cmdID ~= CMD_UPGRADEMEX2 and cmdID ~= CMD_AREAMEX then 
		return false 
	end 
  
	--return processCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	return addCommandToQueue(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
end 



-- process command queue
function gadget:GameFrame(n)
	for idx,cmdData in pairs(commandQueue) do
		-- if shift was not used, stop current queue before adding orders
		local _,stunned,_ = spGetUnitIsStunned(cmdData[1])
		-- stun check done to prevent this cancelling morph
		if (cmdData[6] and (not cmdData[6].shift) and (not stunned)) then
			spGiveOrderToUnit(cmdData[1],CMD.STOP,{},{})
		end
		processCommand(cmdData[1], cmdData[2], cmdData[3], cmdData[4], cmdData[5], cmdData[6])
		commandQueue[idx] = nil
	end
end 

------------------------------------------------ UNSYNCED
else 

	-- do nothing

end
