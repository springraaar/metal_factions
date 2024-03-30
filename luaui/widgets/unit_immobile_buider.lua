--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    unit_immobile_buider.lua
--  brief:   sets immobile builders to ROAMING, and gives them a PATROL order
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "ImmobileBuilder",
    desc      = "Sets immobile builders to ROAM, with a PATROL command",
    author    = "trepan, modified by raaar",
    date      = "2007-2022",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local CMD_MOVE_STATE    = CMD.MOVE_STATE
local CMD_PATROL        = CMD.PATROL
local CMD_STOP          = CMD.STOP
local spGetGameFrame    = Spring.GetGameFrame
local spGetMyTeamID     = Spring.GetMyTeamID
local spGetTeamUnits    = Spring.GetTeamUnits
local spGetUnitCommands = Spring.GetUnitCommands
local spGetUnitDefID    = Spring.GetUnitDefID
local spGetUnitPosition = Spring.GetUnitPosition
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGetFeaturePosition = Spring.GetFeaturePosition
local spGetFeatureRadius = Spring.GetFeatureRadius
local spValidUnitID = Spring.ValidUnitID
local spValidFeatureID = Spring.ValidFeatureID
local spGetUnitStates = Spring.GetUnitStates

local hmsx = Game.mapSizeX/2
local hmsz = Game.mapSizeZ/2

local BUILD_RADIUS = 300
local BUILD_RADIUS_SQUARED = BUILD_RADIUS*BUILD_RADIUS

local function sqDistance(x1,z1,x2,z2)
	return ((x2-x1)^2+(z2-z1)^2)
end

local function printArr(a)
	local str = "["
	for i = 1, #a do
		if i > 1 then
	    	str=str..","
	    end
	    str=str..tostring(a[i])
	end
	str=str.."]"
	
	return str
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- if this is >0, then commands are re-issued for immobile
-- builders that have been idling for the number of game frames
-- (in case a player accidentally STOPs them)

local idleFrames = 30
local idlers = {}
local immobileBuilders = {}

local trackedCommands = {
	[CMD.RECLAIM] = true,
	[CMD.REPAIR] = true,
	[CMD.GUARD] = true
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function IsImmobileBuilder(ud)
	return(ud and ud.isBuilder and not ud.canMove and not ud.isFactory)
end


local function SetupUnit(unitID)
	-- set immobile builders (nanotowers?) to the ROAM movestate,
	-- and give them a PATROL order (does not matter where, afaict)
	local x, y, z = spGetUnitPosition(unitID)
	if (x) then
		local cmds = spGetUnitCommands(unitID,5)
		if (cmds and (#cmds == 0)) then
			if (x > hmsx) then
				x = x - 25
			else
				x = x + 25
			end
			if (z > hmsz) then
				z = z - 25
			else
				z = z + 25
			end
			spGiveOrderToUnit(unitID, CMD_PATROL, { x, y, z }, {})
			spGiveOrderToUnit(unitID, CMD_MOVE_STATE, { 2 }, CMD.OPT_SHIFT)
		end
	end
end

if (idleFrames > 0) then

function widget:Initialize()
	for _,unitID in ipairs(spGetTeamUnits(spGetMyTeamID())) do
		local unitDefID = spGetUnitDefID(unitID)
		if (IsImmobileBuilder(UnitDefs[unitDefID])) then
			immobileBuilders[unitID] = true
			SetupUnit(unitID)
		end
	end
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	if (unitTeam ~= spGetMyTeamID()) then
		return
	end
	if (IsImmobileBuilder(UnitDefs[unitDefID])) then
		idlers[unitID] = spGetGameFrame()
	end
end


function widget:UnitGiven(unitID, unitDefID, unitTeam)
 	widget:UnitCreated(unitID, unitDefID, unitTeam)
	widget:UnitFinished(unitID, unitDefID, unitTeam)
end


function widget:GameFrame(frame)
	local cmds,cmd1,tx,tz,x,z
	 
	for unitID,_ in pairs(immobileBuilders) do
		-- ensure they're not on hold position
		local states = spGetUnitStates(unitID)
		if states then
			if states["movestate"] == 0 then
				-- stop the unit to trigger setup
				--Spring.Echo("Immobile builder "..unitID.." was set to hold position : change to roam")
				spGiveOrderToUnit(unitID, CMD_MOVE_STATE, { 2 }, CMD.OPT_SHIFT)
			end
		end 

		cmds = spGetUnitCommands(unitID,5)
		-- if first command targets something outside build radius, cancel it
		if (cmds and (#cmds > 0)) then
			idlers[unitID] = nil
			--Spring.Echo("NOT IDLE "..unitID.." frame="..frame)
			for i,cmd in ipairs(cmds) do
				if trackedCommands[cmd["id"]] and cmd["params"] then
	  	  			--Spring.Echo(CMD[cmd["id"]].." params="..printArr(cmd["params"]))
					if cmd["params"] then
						local featureExtraRadius = 0
						if #cmd["params"] == 1 or #cmd["params"] == 5 then
							local targetId = tonumber(cmd["params"][1])
							-- subtract maxunits from reclaim commands which target specific features
							if cmd["id"] == CMD.RECLAIM and targetId > Game.maxUnits then
								targetId = targetId - Game.maxUnits
								featureExtraRadius = spGetFeatureRadius(targetId)
								tx,_,tz = spGetFeaturePosition(cmd["id"] == CMD.RECLAIM and (targetId) or targetId)
								-- Spring.Echo("FEATURE "..CMD[cmd["id"]].." cmds="..printArr(cmd["params"]).." at ("..tostring(tx)..","..tostring(tz)..") buildeeRadius="..buildeeBuildRadius)
							else
								tx,_,tz = spGetUnitPosition(targetId)
								--Spring.Echo("UNIT "..CMD[cmd["id"]].." "..printArr(cmd["params"]))
							end
						else
							tx = cmd["params"][1]
							tz = cmd["params"][3]
							--Spring.Echo("OTHER "..CMD[cmd["id"]].." "..printArr(cmd["params"]))
						end
						
						x,_,z = spGetUnitPosition(unitID)
						if featureExtraRadius and featureExtraRadius > 0 then
							local testRadiusSQ = featureExtraRadius + BUILD_RADIUS
							testRadiusSQ = testRadiusSQ*testRadiusSQ
							if (tx and tz and sqDistance(x,z,tx,tz) > testRadiusSQ) then
								spGiveOrderToUnit(unitID, CMD_STOP,{},{})
								--Spring.Echo("Immobile builder at ("..tostring(x)..","..tostring(z)..") cannot reach ("..tostring(tx)..","..tostring(tz).."): orders canceled")
							end
						elseif (tx and tz and sqDistance(x,z,tx,tz) > BUILD_RADIUS_SQUARED) then
							spGiveOrderToUnit(unitID, CMD_STOP,{},{})
							--Spring.Echo("Immobile builder at ("..tostring(x)..","..tostring(z)..") cannot reach ("..tostring(tx)..","..tostring(tz).."): orders canceled")
						end
					end		
				end
			end
		else
			if (not idlers[unitID]) then
				idlers[unitID] = frame
			end
		end
	end
  
	for unitID, f in pairs(idlers) do
		if ((frame - f) > idleFrames) then
			idlers[unitID] = nil
			local cmds = spGetUnitCommands(unitID,5)
			if (not cmds) or (#cmds == 0) then
				--Spring.Echo("SETUP PATROL "..unitID.." frame="..frame)
				SetupUnit(unitID)
			end
		end
	end  
end


function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if idlers[unitID] then
		idlers[unitID] = nil
	end
	if immobileBuilders[unitID] then
		immobileBuilders[unitID] = nil
	end
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	if (unitTeam ~= spGetMyTeamID()) then
		return
	end
	if (IsImmobileBuilder(UnitDefs[unitDefID])) then
		immobileBuilders[unitID] = true
	end
end

function widget:UnitIdle(unitID, unitDefID, unitTeam)
	if (unitTeam ~= spGetMyTeamID()) then
		return
	end
	if (immobileBuilders[unitID]) then
		idlers[unitID] = spGetGameFrame()
	end
end


end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
