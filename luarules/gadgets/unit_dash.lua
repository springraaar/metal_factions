function gadget:GetInfo() 
	return {
			name    = "Dash",
			desc    = "Gives units the dash ability",
			author  = "raaar",
			date    = "2022",
			license = "PD",
			layer   = 0,
			enabled = true,
	}
end


if (not gadgetHandler:IsSyncedCode()) then return end

include("lualibs/custom_cmd.lua")

local random = math.random
local abs    = math.abs
local max    = math.max
local min    = math.min

local privateTable = {private = true}

local spInsertUnitCmdDesc    = Spring.InsertUnitCmdDesc
local spRemoveUnitCmdDesc    = Spring.RemoveUnitCmdDesc
local spSetUnitRulesParam    = Spring.SetUnitRulesParam
local spGetUnitRulesParam    = Spring.GetUnitRulesParam
local spGetGameSeconds       = Spring.GetGameSeconds
local spGetGameFrame         = Spring.GetGameFrame
local spGetUnitDefID         = Spring.GetUnitDefID
local spValidUnitID          = Spring.ValidUnitID
local spGetUnitIsDead        = Spring.GetUnitIsDead
local spGetUnitRadius        = Spring.GetUnitRadius
local spGetUnitPosition      = Spring.GetUnitPosition
local spSpawnCEG             = Spring.SpawnCEG
local spPlaySoundFile        = Spring.PlaySoundFile
local spGetUnitCollisionVolumeData = Spring.GetUnitCollisionVolumeData
local spGetUnitHealth        = Spring.GetUnitHealth

local DASH_FRAMES = 4*30 			-- 4s dash time
local DASH_RELOAD_FRAMES = 60*30	-- 60s dash reload

local canDashUnitIds = {}
local dashingUnitIds = {}	-- dash frames and reloadFrames left by unit id

local dashCmdDesc = {
	id      = CMD_DASH,
	type    = CMDTYPE.ICON,
	name    = 'Dash',
	cursor  = 'Dash',
	action  = 'dash',
	tooltip = 'Dash: Boost movement speed 40-70% for 4 seconds, 1 minute reload',
}


-- update dash properties for unit id
local function updateDashDefsForUnitId(unitId, unitDefId)
	local ud = UnitDefs[unitDefId]
	if not ud.isImmobile then
		-- enable dash
		canDashUnitIds[unitId] = unitDefId
		spSetUnitRulesParam(unitId, "dashReload", 1)
		spSetUnitRulesParam(unitId, "dashFrames", 0)
		spSetUnitRulesParam(unitId, "dashReloadFrames", 0)
		
		spInsertUnitCmdDesc(unitId, CMD_DASH, dashCmdDesc)
		--Spring.Echo("DASH ENABLED FOR "..ud.name)
	end
end


----------------------------------------------- callins


function gadget:Initialize()
	Spring.SetCustomCommandDrawData(CMD_DASH, "Dash", {0, 1, 0, 0.7})
	Spring.AssignMouseCursor("Dash", "cursorDash", true, true)
	gadgetHandler:RegisterCMDID(CMD_DASH)
	for _, unitID in pairs(Spring.GetAllUnits()) do
		gadget:UnitCreated(unitID, Spring.GetUnitDefID(unitID))
	end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	updateDashDefsForUnitId(unitID, unitDefID)
end

function gadget:UnitDestroyed(oldUnitID, unitDefID)
	if canDashUnitIds[oldUnitID] then
		canDashUnitIds[oldUnitID] = nil
		if dashingUnitIds[oldUnitID] then
			dashingUnitIds[oldUnitID] = nil
		end
	end
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if cmdID == CMD.INSERT and cmdParams[2] == CMD_DASH then
		return gadget:AllowCommand(unitID, unitDefID, teamID, CMD_DASH, {}, cmdParams[3])
	end
	
	if cmdID == CMD_DASH then
		local isJumping = spGetUnitRulesParam(unitID,"is_jumping")
		isJumping = isJumping and (isJumping == 1)
		local _,_,_,_,bp = spGetUnitHealth(unitID)
		
		if (bp and bp == 1) and (not isJumping) and canDashUnitIds[unitID] and not dashingUnitIds[unitID] then 
			dashingUnitIds[unitID] = {frames = DASH_FRAMES,reloadFrames = DASH_RELOAD_FRAMES}
			spSetUnitRulesParam(unitID, "dashReload", 0)
			spSetUnitRulesParam(unitID, "dashFrames", DASH_FRAMES)
			spSetUnitRulesParam(unitID, "dashReloadFrames", DASH_RELOAD_FRAMES)
			
			-- add dash effect
			local xs, _, _, _, _, _, _, _, _, _ = spGetUnitCollisionVolumeData(unitID)
			local px,py,pz = spGetUnitPosition(unitID)
			spSpawnCEG("DASHSTART", px, py, pz, 0, 1, 0,xs ,xs)
			spPlaySoundFile("DASHSTART", 0.7, px, py, pz)
		end
		
		return false  -- processed in the previous lines
	end
	
	return true -- allowed
end

function gadget:GameFrame(n)
	for uId, data in pairs(dashingUnitIds) do
		local frames = data.frames
		local reloadFrames = data.reloadFrames
		
		if frames > 0 then
			frames = frames - 1
			data.frames = frames
			spSetUnitRulesParam(uId, "dashFrames", frames)
		elseif reloadFrames > 0 then
			reloadFrames = reloadFrames - 1
			data.reloadFrames = reloadFrames
			spSetUnitRulesParam(uId, "dashReload", (DASH_RELOAD_FRAMES - reloadFrames) / DASH_RELOAD_FRAMES)
			spSetUnitRulesParam(uId, "dashFrames", 0)
			spSetUnitRulesParam(uId, "dashReloadFrames", reloadFrames)
		else
			dashingUnitIds[uId] = nil
			spSetUnitRulesParam(uId, "dashReload", 1)
		end
	end
end
