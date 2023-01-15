function gadget:GetInfo()
   return {
      name = "Power Grid Handler",
      desc = "Tracks power grid nodes and connections",
      author = "raaar",
      date = "2022",
      license = "PD",
      layer = 1,
      enabled = true,
   }
end


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
    return
end


local GRID_RADIUS = 516		-- 500 with a bit of slack		
local GRID_RADIUS_SQ = GRID_RADIUS*GRID_RADIUS
local GRID_CONNECTION_RADIUS = GRID_RADIUS
local GRID_CONNECTION_RADIUS_SQ = GRID_CONNECTION_RADIUS*GRID_CONNECTION_RADIUS


local METAL_EXTRACTION_FACTOR = 0.001
local ENERGY_STORAGE_GRID_FACTOR = 0.01 
local EXTRACTION_BONUS_GRID_STR_REFERENCE = 500

local GRID_CHECK_FRAMES = 30



local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitMoveTypeData = Spring.GetUnitMoveTypeData
local spGetUnitAllyTeam = Spring.GetUnitAllyTeam
local spGetUnitTeam = Spring.GetUnitTeam
local spGetUnitsInCylinder = Spring.GetUnitsInCylinder
local spGetUnitDefID = Spring.GetUnitDefID
local spGetAllUnits = Spring.GetAllUnits
local spGetGroundHeight = Spring.GetGroundHeight
local spGetUnitHealth = Spring.GetUnitHealth
local spSetUnitHealth = Spring.SetUnitHealth
local spUseUnitResource = Spring.UseUnitResource
local spGetGameFrame = Spring.GetGameFrame
local spGetUnitIsActive = Spring.GetUnitIsActive
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spSetUnitRulesParam = Spring.SetUnitRulesParam
local spSpawnCEG = Spring.SpawnCEG
local spGetUnitIsDead = Spring.GetUnitIsDead
local spSpawnProjectile = Spring.SpawnProjectile
local spGetUnitResources = Spring.GetUnitResources
local spGetAllyTeamList = Spring.GetAllyTeamList
local spCallCOBScript = Spring.CallCOBScript
local spSetUnitMetalExtraction = Spring.SetUnitMetalExtraction
local spSetUnitResourcing = Spring.SetUnitResourcing

local allyTeams = spGetAllyTeamList()


local max = math.max
local min = math.min
local floor = math.floor
local abs = math.abs

local nodeDefIds = {}

local gridBoosterDefIds = {}
local gridAffectedDefIds = {}

local nodeIds = {}
local boosterUnitIdsByAllyId = {}	-- allyId, unitId, {eStorage,mMult,gridId}
local affectedUnitIdsByAllyId = {}	-- allyId, unitId, {eStorage,mMult,gridId}
local nodesByAllyId = {}		-- allyId, nodeArray<nodePropertiesTable>

--------------------------------------------------- auxiliary functions

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end


function getGridDataObject(allyId, gridId)
	return {
		gridId = gridId,
		allyId = allyId,
		nodes = {},
		affectedExtractorIds = {},
		totalExtractionMult = 0,
		gridStrength = 0,
		extractionBonus = 0,
		gridLevel = 0,
		extraEnergyUse = 0,
		extraMetalIncome = 0
	}
end

function getGridExtractionBonus(grid)
	return 1 - EXTRACTION_BONUS_GRID_STR_REFERENCE*(1+grid.totalExtractionMult) / (EXTRACTION_BONUS_GRID_STR_REFERENCE*(1+grid.totalExtractionMult) + grid.gridStrength)
end

function getGridLevel(grid)
	if grid.gridStrength > 10000 then
		return 5
	elseif grid.gridStrength > 5000 then
		return 4
	elseif grid.gridStrength > 2000 then
		return 3
	elseif grid.gridStrength > 500 then
		return 2
	elseif grid.gridStrength > 10 then
		return 1
	end
	return 0
end

local xd,zd,xd2,zd2
function checkWithinSQDistance(x1,x2,z1,z2,maxDistance,maxSQDistance)
	xd = x2-x1
	zd = z2-z1
	if (abs(xd) > maxDistance) then
		return false
	end
	if (abs(zd) > maxDistance) then
		return false
	end
	xd2 = xd*xd
	if (xd2 > maxSQDistance) then
		return false
	end
	zd2 = zd*zd
	if (zd2 > maxSQDistance) then
		return false
	end
	if (xd2 + zd2 > maxSQDistance) then
		return false
	end
	
	return true
end

--------------------------------------------------- callins

function gadget:Initialize()
	for _,ud in pairs(UnitDefs) do
		if (ud.customParams) then
			if ud.customParams.powergridnode == "1" then
				nodeDefIds[ud.id] = true
			elseif ud.customParams.boostspowergrid == "1" or ud.tidalGenerator == 1 or ud.energyStorage > 100 or ud.energyMake > 5 or ud.windGenerator > 0 then
				gridBoosterDefIds[ud.id] = true
			end
		end
		if (ud.extractsMetal and ud.extractsMetal > 0) then
			gridAffectedDefIds[ud.id] = true
		end		
	end
	
	for _,allyId in ipairs(allyTeams) do
		affectedUnitIdsByAllyId[allyId] = {}
		boosterUnitIdsByAllyId[allyId] = {}
		nodesByAllyId[allyId] = {}
	end
	
	for _,unitId in pairs(spGetAllUnits()) do
		gadget:UnitCreated(unitId,spGetUnitDefID(unitId),spGetUnitTeam(unitId))
	end
end

function gadget:UnitTaken(unitId, unitDefId, unitTeam, oldTeam)
	gadget:UnitDestroyed(unitId, unitDefId, unitTeam)
end

function gadget:UnitGiven(unitId, unitDefId, unitTeam, oldTeam)
	gadget:UnitCreated(unitId, unitDefId, unitTeam)
end

function gadget:UnitCreated(unitId, unitDefId, unitTeam)
	local allyId = spGetUnitAllyTeam(unitId)
	if (gridAffectedDefIds[unitDefId]) then
		local x,_,z = spGetUnitPosition(unitId)
		local ud = UnitDefs[unitDefId]
		affectedUnitIdsByAllyId[allyId][unitId] = {eMake=0,eUse=ud.energyUpkeep,eStorage=0,mMult=ud.extractsMetal/METAL_EXTRACTION_FACTOR,mExt=ud.extractsMetal,gridId=0,x=x,z=z,active=false}
	end
	if (gridBoosterDefIds[unitDefId]) then
		local x,_,z = spGetUnitPosition(unitId)
		local ud = UnitDefs[unitDefId]
		boosterUnitIdsByAllyId[allyId][unitId] = {eMake=0,eUse=0,eStorage=ud.energyStorage,mMult=0,mExt=ud.extractsMetal,gridId=0,x=x,z=z,active=false}
	end
	if (nodeDefIds[unitDefId]) then
		nodeIds[unitId] = true
		
		local x,_,z = spGetUnitPosition(unitId)
		--Spring.Echo(" node created at x="..x.." z="..z)
		local nearbyAlliedNodes = {}
		local node = {uId = unitId,x=x,z=z,gridId=nil,nearbyAlliedNodes=nearbyAlliedNodes,active=false}
		-- get nearby nodes
		local otherUx, otherUz, otherNodeNearbyAlliedNodes
		for i,otherNode in ipairs(nodesByAllyId[allyId]) do
			otherUx = otherNode.x
			otherUz = otherNode.z
			otherNodeNearbyAlliedNodes = otherNode.nearbyAlliedNodes

			if checkWithinSQDistance(x,otherUx,z,otherUz,GRID_CONNECTION_RADIUS,GRID_CONNECTION_RADIUS_SQ) then
				--Spring.Echo(" node connected to other node x="..otherUx.." z="..otherUz)
				table.insert(nearbyAlliedNodes,otherNode)
				table.insert(otherNodeNearbyAlliedNodes,node)
			end
		end
		table.insert(nodesByAllyId[allyId], node)
	end
end

function gadget:UnitDestroyed(unitId, unitDefId, unitTeam)
	local allyId = spGetUnitAllyTeam(unitId)
	if (gridAffectedDefIds[unitDefId]) then
		if affectedUnitIdsByAllyId[allyId][unitId] then
			affectedUnitIdsByAllyId[allyId][unitId] = nil
		end
	end
	if (gridBoosterDefIds[unitDefId]) then
		if boosterUnitIdsByAllyId[allyId][unitId] then
			boosterUnitIdsByAllyId[allyId][unitId] = nil
		end
	end
	if (nodeDefIds[unitDefId]) then
		nodeIds[unitId] = nil
		local removeIndex = 0
		local removeIndex2 = 0
		-- remove from each node's nearbyNodes list
		for i,node in ipairs(nodesByAllyId[allyId]) do
			removeIndex2 = 0
			for j,nearbyNode in ipairs(node.nearbyAlliedNodes) do
				if nearbyNode.uId == unitId then
					removeIndex2 = j
					break
				end
			end
			if removeIndex2 > 0 then
				table.remove(node.nearbyAlliedNodes,removeIndex2)
			end
			if node.uId == unitId then
				removeIndex = i
			end
		end
		-- remove from node list
		if removeIndex > 0 then
			table.remove(nodesByAllyId[allyId],removeIndex)	
		end
	end
end

function gadget:GameFrame(n)
	--if n == 15 then
	--	for x=256,Game.mapSizeX,492 do
	--		for z=256,Game.mapSizeZ,492 do
	--			Spring.CreateUnit("aven_power_node",x,Spring.GetGroundHeight(x,z),z,"s",0)
	--		end
	--	end
	--end
	
	if (n%GRID_CHECK_FRAMES == 0) then

		local ux,uz,nx,nz,eMake,eStorage,uId,nId,gridNodeList,gridId,grid,bp,mChange,eChange
		for _,allyId in ipairs(allyTeams) do
			gridNodes = nodesByAllyId[allyId]
			grids = {}

			-- check node activation, reset gridId
			for i,node in ipairs(gridNodes) do
				_,_,_,_,bp = spGetUnitHealth(node.uId)
				if bp < 1 then
					node.active = false
				else
					node.active = true
				end
				
				node.gridId = nil
			end

			-- check node connections, set the gridId for each node
			local outerIter = 0
			local innerIter = 0
			local gridMax = 1
			
			local val = 0
			local currentGridId, otherGridId
			local first = true
			local changed = true
			local numNodes = #gridNodes
			while changed == true do
				changed = false
				-- iterate to find grid id for each node
				for i,node in ipairs(gridNodes) do
					uId = node.uId
					ux = node.x
					uz = node.z
					currentGridId = node.gridId
					otherGridId = nil
			
					if not node.active then
						currentGridId = nil
						node.gridId = nil
						spSetUnitRulesParam(uId,"powerGridId",0)
						spSetUnitRulesParam(uId,"powerGridStrength",0)
						spSetUnitRulesParam(uId,"powerGridTotalExtractionMult",0)
						spSetUnitRulesParam(uId,"powerGridExtractionBonus",0)
						spSetUnitRulesParam(uId,"powerGridLevel",0)
						spCallCOBScript(uId, "setGridLevel", 0, 0)
					else
						
						if currentGridId == nil then
							node.gridId = gridMax
							currentGridId = gridMax
							gridMax = gridMax + 1
							changed = true
						end
						--Spring.Echo("node at ("..ux..","..uz..") has "..(#(node.nearbyAlliedNodes)).." nearby allied nodes")
				
						for j,otherNode in ipairs(node.nearbyAlliedNodes) do
							otherUId = otherNode.uId
							otherUx = otherNode.x
							otherUz = otherNode.z
							otherGridId = otherNode.gridId 
							
							-- set same grid if other node is active
							if otherNode.active then
								if currentGridId ~= otherGridId then
									currentGridId = min(currentGridId or math.huge,otherGridId or math.huge)
									node.gridId = currentGridId
									otherNode.gridId = currentGridId
									changed = true
								end
							end
							innerIter = innerIter + 1
						end
					end
				end	
				outerIter = outerIter + 1
			
				if outerIter > numNodes then
					break
				end
			end
			--Spring.Echo("grid connections for allyTeam "..allyId.." done outerIter="..outerIter.." innerIter="..innerIter)
			
			-- insert grid objects
			-- check grid strength
			for i,node in ipairs(gridNodes) do
				if node.active then
					gridId = node.gridId
					grid = grids[gridId]
					if not grid then
						grid = getGridDataObject(allyId, gridId)
						grids[gridId] = grid
					end
					table.insert(grid.nodes,node)
				end
			end
			for uId,props in pairs(boosterUnitIdsByAllyId[allyId]) do
				_,_,eMake,_ = spGetUnitResources(uId)
				_,_,_,_,bp = spGetUnitHealth(uId)
				ux,_,uz = spGetUnitPosition(uId)
				props.x=ux
				props.z=uz
				props.eMake = eMake
				props.active = bp == 1
				props.gridId = 0
			end
			
			for gridId,grid in pairs(grids) do
				gridNodeList = grid.nodes
				-- check if unit is within range of any grid node
				for uId,props in pairs(boosterUnitIdsByAllyId[allyId]) do
					if props.active then
						for i,node in ipairs(gridNodeList) do
							if node.active then
								nx = node.x
								nz = node.z
								if checkWithinSQDistance(props.x,nx,props.z,nz,GRID_RADIUS,GRID_RADIUS_SQ) then
									grid.gridStrength = grid.gridStrength + props.eMake + props.eStorage*ENERGY_STORAGE_GRID_FACTOR
									--Spring.Echo(uId.." is in grid "..gridId)
									props.gridId = gridId
									break
								end
							end
						end 
					end
				end
			end

			-- check grid total extractor multiplier
			local gridFound = false
			for uId,props in pairs(affectedUnitIdsByAllyId[allyId]) do
				ux=props.x
				uz=props.z
				props.gridId = 0
				gridFound = false
				_,_,_,_,bp = spGetUnitHealth(uId)
				props.active = bp == 1
				if props.active then
					for gridId,grid in pairs(grids) do
						gridNodeList = grid.nodes
						if gridFound then
							break
						end
						for i,node in ipairs(gridNodeList) do
							if node.active then
								nx = node.x
								nz = node.z
								if checkWithinSQDistance(ux,nx,uz,nz,GRID_RADIUS,GRID_RADIUS_SQ) then
									grid.totalExtractionMult = grid.totalExtractionMult + props.mMult
									table.insert(grid.affectedExtractorIds,uId)
									props.gridId = gridId
									gridFound = true
									break
								end 
							end
						end 
					end
				end
			end
			
			-- set grid extraction bonus and rules params for each node
			for gridId,grid in pairs(grids) do
				grid.extractionBonus = getGridExtractionBonus(grid)
				gridNodeList = grid.nodes
				grid.gridLevel = getGridLevel(grid)
				-- set rules params for each node (they all have a grid, even if it's only itself)
				for i,node in ipairs(gridNodeList) do
					nId = node.uId
					spSetUnitRulesParam(nId,"powerGridId",grid.gridId)
					spSetUnitRulesParam(nId,"powerGridStrength",grid.gridStrength)
					spSetUnitRulesParam(nId,"powerGridTotalExtractionMult",grid.totalExtractionMult)
					spSetUnitRulesParam(nId,"powerGridExtractionBonus",grid.extractionBonus)
					spSetUnitRulesParam(nId,"powerGridLevel",grid.gridLevel)
					spCallCOBScript(nId, "setGridLevel", 0, grid.gridLevel)
				end
				--Spring.Echo("grid "..gridId.." strength="..grid.gridStrength.." ext="..grid.totalExtractionMult.." bonus="..grid.extractionBonus.." level="..grid.gridLevel)
			end
			-- set rules params for each affected unit
			for uId,props in pairs(affectedUnitIdsByAllyId[allyId]) do
				grid = grids[props.gridId]
				if props.gridId and props.gridId > 0 and props.active then
					spSetUnitRulesParam(uId,"powerGridId",grid.gridId)
					spSetUnitRulesParam(uId,"powerGridStrength",grid.gridStrength)
					spSetUnitRulesParam(uId,"powerGridTotalExtractionMult",grid.totalExtractionMult)
					spSetUnitRulesParam(uId,"powerGridExtractionBonus",grid.extractionBonus)
					spSetUnitRulesParam(uId,"powerGridLevel",grid.gridLevel)
					-- change metal extraction
					--Spring.Echo("extraction="..Spring.GetMetalExtraction ( props.x, props.z ).." amount="..Spring.GetMetalAmount ( props.x, props.z ).." unitExtraction="..Spring.GetUnitMetalExtraction ( uId ) )
					
					mMake,_,_,_ = spGetUnitResources(uId)
					eChange = props.eUse*(grid.extractionBonus)
					spSetUnitMetalExtraction(uId,props.mExt*(1+grid.extractionBonus))
					spSetUnitResourcing( uId, "cue", eChange)
					grid.extraEnergyUse = grid.extraEnergyUse + eChange
					grid.extraMetalIncome = grid.extraMetalIncome + grid.extractionBonus*mMake  
				else
					spSetUnitRulesParam(uId,"powerGridId",0)
					spSetUnitRulesParam(uId,"powerGridStrength",0)
					spSetUnitRulesParam(uId,"powerGridTotalExtractionMult",0)
					spSetUnitRulesParam(uId,"powerGridExtractionBonus",0)
					spSetUnitRulesParam(uId,"powerGridLevel",0)
					if props.active then
						--Spring.Echo(props.mExt)
						spSetUnitMetalExtraction(uId,props.mExt)
						spSetUnitResourcing( uId, "cue", 0)
					end 
				end
			end
			
			-- set rules params for each booster unit
			for uId,props in pairs(boosterUnitIdsByAllyId[allyId]) do
				grid = grids[props.gridId]
				if props.gridId and props.gridId > 0 and props.active then
					--Spring.Echo("gridId="..gridId.." grid="..tostring(grid))
					spSetUnitRulesParam(uId,"powerGridId",grid.gridId)
					spSetUnitRulesParam(uId,"powerGridStrength",grid.gridStrength)
					spSetUnitRulesParam(uId,"powerGridTotalExtractionMult",grid.totalExtractionMult)
					spSetUnitRulesParam(uId,"powerGridExtractionBonus",grid.extractionBonus)
					spSetUnitRulesParam(uId,"powerGridLevel",grid.gridLevel)
				else
					spSetUnitRulesParam(uId,"powerGridId",0)
					spSetUnitRulesParam(uId,"powerGridStrength",0)
					spSetUnitRulesParam(uId,"powerGridTotalExtractionMult",0)
					spSetUnitRulesParam(uId,"powerGridExtractionBonus",0)
					spSetUnitRulesParam(uId,"powerGridLevel",0)
				end
			end

			-- set grid extra metal income and energy drain as rules params on each node
			for gridId,grid in pairs(grids) do
				gridNodeList = grid.nodes
				for i,node in ipairs(gridNodeList) do
					nId = node.uId
					spSetUnitRulesParam(nId,"powerGridExtraEnergyUse",grid.extraEnergyUse)
					spSetUnitRulesParam(nId,"powerGridExtraMetalIncome",grid.extraMetalIncome)
				end
			end
		end
	end
end

