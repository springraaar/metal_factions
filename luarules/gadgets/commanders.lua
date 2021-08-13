function gadget:GetInfo()
   return {
      name = "Commander Handler",
      desc = "Handles commander experience and build restrictions.",
      author = "raaar",
      date = "September, 2012",
      license = "GNU GPL, v2 or later.",
      layer = 0,
      enabled = true,
   }
end

-- august 2015 : modified to use commander tokens
-- september 2013 : added code to prevent commander transfer and block build orders to prevent multiple commanders from being built


local commanderXp = {}
local commanderName = {}
local commanderMoveState = {}
local commanderBuildOrderFrameByTeam = {}
local commanderTokensByTeam = {}

local spGetUnitsInCylinder = Spring.GetUnitsInCylinder
local GetTeamUnits = Spring.GetTeamUnits 
local GetUnitDefId = Spring.GetUnitDefID
local GetGameFrame = Spring.GetGameFrame
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGetUnitStates = Spring.GetUnitStates
local spSetUnitCosts = Spring.SetUnitCosts
local AreTeamsAllied = Spring.AreTeamsAllied
local spGetTeamList = Spring.GetTeamList

local markedWreckPositions = {}
local damagedByEnemyByUnitIdFrame = {}
local FRIENDLY_FIRE_EXPLOIT_THRESHOLD_FRAMES = 600 -- 20s
local WRECK_FIX_DELAY_FRAMES = 2
local COMMANDER_RESPAWN_EXPERIENCE_FACTOR = 0.9
local COMMANDER_REBUILD_LOCK_FRAMES = 10

local replacementFeature = "aven_ucommander_heap"
-- TODO: hacky, needs replacement
local ADV_COM_WRECK_METAL = 1000

local advCommanderDefIds = {
	[UnitDefNames['aven_u1commander'].id] = true,
	[UnitDefNames['aven_u2commander'].id] = true,
	[UnitDefNames['aven_u3commander'].id] = true,
	[UnitDefNames['aven_u4commander'].id] = true,
	[UnitDefNames['aven_u5commander'].id] = true,
	[UnitDefNames['aven_u6commander'].id] = true,
	[UnitDefNames['gear_u1commander'].id] = true,
	[UnitDefNames['gear_u2commander'].id] = true,
	[UnitDefNames['gear_u3commander'].id] = true,
	[UnitDefNames['gear_u4commander'].id] = true,
	[UnitDefNames['gear_u5commander'].id] = true,
	[UnitDefNames['gear_u6commander'].id] = true,
	[UnitDefNames['claw_u1commander'].id] = true,
	[UnitDefNames['claw_u2commander'].id] = true,
	[UnitDefNames['claw_u3commander'].id] = true,
	[UnitDefNames['claw_u4commander'].id] = true,
	[UnitDefNames['claw_u5commander'].id] = true,
	[UnitDefNames['claw_u6commander'].id] = true,
	[UnitDefNames['sphere_u1commander'].id] = true,
	[UnitDefNames['sphere_u2commander'].id] = true,
	[UnitDefNames['sphere_u3commander'].id] = true,
	[UnitDefNames['sphere_u4commander'].id] = true,	
	[UnitDefNames['sphere_u5commander'].id] = true,
	[UnitDefNames['sphere_u6commander'].id] = true
}


local commanderPadDefIds = {
	[UnitDefNames['aven_commander_respawner'].id] = true,
	[UnitDefNames['gear_commander_respawner'].id] = true,
	[UnitDefNames['claw_commander_respawner'].id] = true,
	[UnitDefNames['sphere_commander_respawner'].id] = true
}

-- checks if unit is a commander
function isCommander(unitDefId)
	if (UnitDefs[unitDefId].customParams.iscommander) then
		return true
	end
	return false
end

-- checks if unit is a commander token
function isCommanderToken(unitDefId)
	if (UnitDefs[unitDefId].customParams.iscommandertoken) then
		return true
	end
	return false
end

function getCommanderTokenMod(teamId)
	local result = 1
	if (commanderName[teamId]) then
		local ud = UnitDefNames[commanderName[teamId]]
		-- being morphed adds 50% to the respawn time
		if ud and advCommanderDefIds[ud.id] then
			result = result + 0.5
		end
		
		-- being upgraded adds up to another 50% to the respawn time 
		local upgrades = GG.upgradeCountsByTypeAndPlayerId[teamId]
		if upgrades then
			local minorCount = upgrades[1] or 0
			local commanderCount = upgrades[2] or 0
			local majorCount = upgrades[3] or 0
			result = result + 0.5*((minorCount+2*majorCount)/7+2*commanderCount/3)/3
		end
	end
	
	return result
end

-------------------------- SYNCED CODE ONLY
if (not gadgetHandler:IsSyncedCode()) then
	return false
end

-- load xp when commanders are created
function gadget:UnitCreated(unitId, unitDefId, teamId)

  	-- if commander token is created, adjust cost and build time
  	if isCommanderToken(unitDefId) then
  		local tokensTable = commanderTokensByTeam[teamId]
  		if not tokensTable then
  			tokensTable = {}
  			commanderTokensByTeam[teamId] = tokensTable
  		end
  		tokensTable[unitId] = true
  	
  		local mod = getCommanderTokenMod(teamId)
  		--Spring.Echo("commander respawn mod for team "..teamId.." value="..tostring(mod))
  		
  		if mod > 1 then
  			local ud = UnitDefs[unitDefId]
  			spSetUnitCosts(unitId,{buildTime=ud.buildTime*mod})
  		end
  	
	-- if commander is created, manage xp
	elseif isCommander(unitDefId) then
		if (not commanderXp[teamId] or not commanderName[teamId]) then
			commanderXp[teamId] = 0
			commanderName[teamId] = UnitDefs[unitDefId].name
			-- Spring.Echo("commander set for team "..teamId.." value="..commanderName[teamId])
			
			-- print morph commands
			-- local cmdList = Spring.GetUnitCmdDescs(unitId)
			-- for _,c in ipairs(cmdList) do
				--if c["action"] == "morph" then 
					--for key,value in pairs(c) do
					    --Spring.Echo("   "..tostring(key).."="..tostring(value))
					--end
				--end
			--end
		end

		-- if previous xp > 0 found, set xp 
		if (commanderXp[teamId] and commanderXp[teamId] > 0) then
			Spring.SetUnitExperience(unitId, commanderXp[teamId])
			--Spring.Echo("experience set for team "..teamId.." value="..commanderXp[teamId])
		end
		-- if previous move state found, set it
		if (commanderMoveState[teamId]) then
			spGiveOrderToUnit(unitId, CMD.MOVE_STATE, {commanderMoveState[teamId]}, {})
		end
	end
end

-- replace commander token with the real commander when finished
function gadget:UnitFinished(unitId, unitDefId, teamId)
	if isCommanderToken(unitDefId) then
		-- Spring.Echo("commander token finished for team "..teamId.." value="..commanderName[teamId])
		-- get token current position
		local bpx,bpy,bpz = Spring.GetUnitPosition(unitId)
		
		-- replace token with commander
		if (commanderName[teamId]) then
			
			-- get the commander pad that built it
			local nearbyUnits = spGetUnitsInCylinder(bpx,bpz,50,teamId)
			local padId = nil			
			for i,pId in pairs(nearbyUnits) do
				if commanderPadDefIds[GetUnitDefId(pId)] then
					padId = pId
					break
				end
			end
			local cId = Spring.CreateUnit(commanderName[teamId],bpx,bpy,bpz,"s",teamId)
		
			if padId ~= nil and cId ~= nil then
				local cmdQueue = Spring.GetUnitCommands(padId, 20)
				if (#cmdQueue>0) then 
					for i,cmd in pairs(cmdQueue) do
						spGiveOrderToUnit(cId, cmd.id, cmd.params, cmd.options)
					end
				end
			end
		
			-- destroy token
			Spring.DestroyUnit(unitId)
		end
	end
end

-- save xp when commanders are destroyed
function gadget:UnitDestroyed(unitId, unitDefId, teamId)
	-- cleanup commander tokens table
	if isCommanderToken(unitDefId) then
		local tokensTable = commanderTokensByTeam[teamId]
  		if tokensTable and tokensTable[unitId] then
  			tokensTable[unitId] = nil
  		end
	-- if unit is commander, save data for player
	elseif ( isCommander(unitDefId)) then
		local xp = Spring.GetUnitExperience(unitId)
		if (commanderXp[teamId]) then
			commanderXp[teamId] = COMMANDER_RESPAWN_EXPERIENCE_FACTOR * xp
			--Spring.Echo("experience saved for team "..teamId.." value="..commanderXp[teamId])
		end
		local states = spGetUnitStates(unitId)
		if (states) then
			commanderMoveState[teamId] = states["movestate"]
			--Spring.Echo("move state saved for team "..teamId.." value="..commanderMoveState[teamId])
		end
		if (commanderName[teamId]) then
			commanderName[teamId] = UnitDefs[unitDefId].name
			--Spring.Echo("commander name saved for team "..teamId.." value="..commanderName[teamId])
		end
		
		-- if not damaged by enemies recently, mark wreck position
		if advCommanderDefIds[unitDefId] and not damagedByEnemyByUnitIdFrame[unitId] or (not damagedByEnemyByUnitIdFrame[unitId] or (GetGameFrame() - damagedByEnemyByUnitIdFrame[unitId] > FRIENDLY_FIRE_EXPLOIT_THRESHOLD_FRAMES)) then
			-- check if commander was fully built, to prevent morph triggering this
			local _,_,_,_,bp = Spring.GetUnitHealth(unitId)
			
			if bp > 0.999 then
				local bpx,bpy,bpz = Spring.GetUnitPosition(unitId)
				markedWreckPositions[unitId] = {x=bpx,y=bpy,z=bpz,frame=GetGameFrame()}
			end
		end
		
		damagedByEnemyByUnitIdFrame[unitId] = nil
	end
end

-- blocks commander transfers between players
-- also prevents transferring units to enemies in general
function gadget:AllowUnitTransfer(unitId, unitDefId, oldTeam, newTeam, capture)
	if( isCommander(unitDefId) or isCommanderToken(unitDefId)) then
 		Spring.SendMessageToTeam(oldTeam,"Commanders can't be given!")
 		return false
	elseif (not AreTeamsAllied(oldTeam, newTeam) and not capture) then
 		Spring.SendMessageToTeam(oldTeam,"Can't give units to enemies!")
 		return false
	end  
	return true
end


-- blocks construction of multiple commanders
function gadget:AllowUnitCreation(unitDefId,builderId,teamId,x,y,z)
	if (isCommander(unitDefId) or isCommanderToken(unitDefId)) then
		-- abort if team owns any commanders
		local ud = nil
		for _,u in ipairs(GetTeamUnits(teamId)) do
			ud = UnitDefs[GetUnitDefId(u)]
			if (ud.customParams.iscommander or ud.customParams.iscommandertoken) then
 				-- Spring.Echo("Commander is alive or being respawned!")
				return false
			end
		end
		
		-- abort if team tried successfully ordered another commander to be built in this frame
		local frame = GetGameFrame()
		local lastBuildFrame = commanderBuildOrderFrameByTeam[teamId]
		--Spring.Echo("frame="..frame.."   lastBuildFrame="..tostring(lastBuildFrame))
		if ( lastBuildFrame ~= nil and (frame - lastBuildFrame < COMMANDER_REBUILD_LOCK_FRAMES)) then
			--Spring.Echo("Not allowed to build multiple commanders!")
			return false
		end
		
		-- mark current team and frame, and allow build order
		commanderBuildOrderFrameByTeam[teamId] = frame
		return true
	end
	
	return true
end

-- mark commanders who took damage from enemies
function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
	if isCommander(unitDefID) then
		if (attackerTeam ~= nil and not AreTeamsAllied(unitTeam,attackerTeam)) then
			damagedByEnemyByUnitIdFrame[unitID] = GetGameFrame()
		end
	end 
end

function gadget:GameFrame(n)

	-- replace adv commander wreck if commander was killed without being hit by enemies recently
	for id,pos in pairs(markedWreckPositions) do
		if (GetGameFrame() - pos.frame > WRECK_FIX_DELAY_FRAMES) then
			local wrecks = Spring.GetFeaturesInRectangle(pos.x-30,pos.z-30,pos.x+30,pos.z+30)
			local replaced = false
			--Spring.Echo("commander at ("..pos.x..";"..pos.z..") killed by friendly fire")
						
			for _,wId in ipairs(wrecks) do
				if not replaced then
					-- if it is an adv commander wreckage, replace it 
					local m,_,_,_,_ = Spring.GetFeatureResources(wId)
					if m == ADV_COM_WRECK_METAL then
						local x,y,z = Spring.GetFeaturePosition(wId)
						Spring.DestroyFeature(wId)			
						Spring.CreateFeature(replacementFeature,x,y,z)
						replaced = true
					end
				end
			end
		
			-- clear table
			markedWreckPositions[id] = nil
		end
	end
	
	-- clean up excess token build orders, the AllowUnitCreation checks are not enough 
	for _,teamId in pairs (spGetTeamList()) do
		local tokensTable = commanderTokensByTeam[teamId]
  		
  		if tokensTable then
  			local firstId = nil
	  		
	  		for uId,_ in pairs(tokensTable) do
  				if not firstId then
  					firstId = uId
  				else
  					--Spring.Echo("found redundant commander token : tId="..teamId.." uId="..uId.." : deleting..")
  					Spring.DestroyUnit(uId,false,true)
  				end	
  			end
  		end
	end	
end

