function gadget:GetInfo() 
	return {
			name    = "Jumpjets",
			desc    = "Gives units the jump ability",
			author  = "quantum, modified by raaar",
			date    = "May 14, 2008", -- updated in 2021, by raaar
			license = "GNU GPL, v2 or later",
			layer   = 0,
			enabled = true,
	}
end


if (not gadgetHandler:IsSyncedCode()) then return end

include("lualibs/custom_cmd.lua")

local PLAY_SOUND = false

local Spring    = Spring
local MoveCtrl  = Spring.MoveCtrl
local coroutine = coroutine
local Sleep     = coroutine.yield
local pairs     = pairs
local assert    = assert

local pi2    = math.pi*2
local random = math.random
local abs    = math.abs
local max    = math.max
local min    = math.min

local CMD_STOP   = CMD.STOP
local CMD_WAIT   = CMD.WAIT
local CMD_MOVE   = CMD.MOVE
local CMD_REMOVE = CMD.REMOVE
local privateTable = {private = true}

local spGetHeadingFromVector = Spring.GetHeadingFromVector
local spGetUnitPosition      = Spring.GetUnitPosition
local spGetUnitRotation      = Spring.GetUnitRotation
local spInsertUnitCmdDesc    = Spring.InsertUnitCmdDesc
local spRemoveUnitCmdDesc    = Spring.RemoveUnitCmdDesc
local spSetUnitRulesParam    = Spring.SetUnitRulesParam
local spGetUnitRulesParam    = Spring.GetUnitRulesParam
local spSetUnitNoMinimap     = Spring.SetUnitNoMinimap
local spGetUnitIsStunned     = Spring.GetUnitIsStunned
local spGetCommandQueue      = Spring.GetCommandQueue
local spGiveOrderToUnit      = Spring.GiveOrderToUnit
local spGetUnitVelocity      = Spring.GetUnitVelocity
local spSetUnitVelocity      = Spring.SetUnitVelocity
local spSetUnitNoSelect      = Spring.SetUnitNoSelect
local spSetUnitBlocking      = Spring.SetUnitBlocking
local spSetUnitMoveGoal      = Spring.SetUnitMoveGoal
local spGetGroundHeight      = Spring.GetGroundHeight
local spGetGroundNormal      = Spring.GetGroundNormal
local spTestMoveOrder        = Spring.TestMoveOrder
local spTestBuildOrder       = Spring.TestBuildOrder
local spGetGameSeconds       = Spring.GetGameSeconds
local spGetUnitHeading       = Spring.GetUnitHeading
local spSetUnitNoDraw        = Spring.SetUnitNoDraw
local spGetGameFrame         = Spring.GetGameFrame
local spGetUnitDefID         = Spring.GetUnitDefID
local spGetUnitTeam          = Spring.GetUnitTeam
local spDestroyUnit          = Spring.DestroyUnit
local spCreateUnit           = Spring.CreateUnit
local spCallCOBScript        = Spring.CallCOBScript
local spValidUnitID          = Spring.ValidUnitID
local spGetUnitIsDead        = Spring.GetUnitIsDead
local spSetUnitPosition      = Spring.SetUnitPosition
local spAddUnitImpulse       = Spring.AddUnitImpulse
local mcSetRotationVelocity  = MoveCtrl.SetRotationVelocity
local mcSetPosition          = MoveCtrl.SetPosition
local mcSetRotation          = MoveCtrl.SetRotation
local mcDisable              = MoveCtrl.Disable
local mcEnable               = MoveCtrl.Enable
local spSetUnitPhysics       = Spring.SetUnitPhysics

local spSetUnitLeaveTracks = Spring.SetUnitLeaveTracks -- or MoveCtrl.spSetUnitLeaveTracks --0.82 compatiblity

local emptyTable = {}

local coroutines = {}
local lastJumpPosition = {}
local landBoxSize = 60
local jumps = {}
local jumping = {}
local goalSet = {}


local JUMP_UPG_SPEED_BONUS = 0.1
local JUMP_UPG_RANGE_BONUS = 0.1  
local JUMP_UPG_HEIGHT_BONUS = 0.1
local JUMP_UPG_RELOAD_REDUCTION = 0.25

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local jumpDefTemplates = {
	commander = {
		range = 400,
		speed = 5,
		reload = 15,
		delay = 0,
		height = 350,

		requiresUpgrade = true,			
		noJumpHandling =  false,
		rotateMidAir = false,
		cannotJumpMidair = false,
		jumpSpreadException = false,
	},
	grenado = {
		range = 250,
		speed = 6,
		reload = 15,
		delay = 0,
		height = 150,

		requiresUpgrade = false,			
		noJumpHandling =  false,
		rotateMidAir = false,
		cannotJumpMidair = false,
		jumpSpreadException = false,
	},
	hopper = {
		range = 400,
		speed = 6,
		reload = 10,
		delay = 0,
		height = 350,

		requiresUpgrade = false,			
		noJumpHandling =  false,
		rotateMidAir = false,
		cannotJumpMidair = false,
		jumpSpreadException = false,
	},
	flail = {
		range = 350,
		speed = 6,
		reload = 10,
		delay = 0,
		height = 300,

		requiresUpgrade = false,			
		noJumpHandling =  false,
		rotateMidAir = false,
		cannotJumpMidair = false,
		jumpSpreadException = false,
	},	
	pyro = {
		range = 350,
		speed = 6,
		reload = 10,
		delay = 0,
		height = 200,

		requiresUpgrade = false,			
		noJumpHandling =  false,
		rotateMidAir = false,
		cannotJumpMidair = false,
		jumpSpreadException = false,
	},
	exploder = {
		range = 350,
		speed = 6,
		reload = 10,
		delay = 0,
		height = 200,

		requiresUpgrade = false,			
		noJumpHandling =  false,
		rotateMidAir = false,
		cannotJumpMidair = false,
		jumpSpreadException = false,
	},
	commando = {
		range = 350,
		speed = 6,
		reload = 10,
		delay = 0,
		height = 300,

		requiresUpgrade = false,			
		noJumpHandling =  false,
		rotateMidAir = false,
		cannotJumpMidair = false,
		jumpSpreadException = false,
	},
	hydrobotcon = {
		range = 350,
		speed = 4.5,
		reload = 10,
		delay = 0,
		height = 300,

		requiresUpgrade = false,			
		noJumpHandling =  false,
		rotateMidAir = false,
		cannotJumpMidair = false,
		jumpSpreadException = false,
	},	
}
local baseJumpDefs = {}
local jumpDefsByUnitId = {}
local canJumpUnitIds = {}

for id, ud in pairs (UnitDefs) do
	local cp = ud.customParams
	if cp and cp.canjump == "1" then
		local jTemplate = jumpDefTemplates[cp.jumptype]
		local modifier = tonumber(cp.jumpmod)
		baseJumpDefs[id] = {
			range = jTemplate.range * modifier,
			speed = jTemplate.speed * modifier,
			reload = jTemplate.reload,
			delay = jTemplate.delay,
			height = jTemplate.height * modifier,

			requiresUpgrade = jTemplate.requiresUpgrade,			
			noJumpHandling =  jTemplate.noJumpHandling,
			rotateMidAir = jTemplate.rotateMidAir,
			cannotJumpMidair = jTemplate.cannotJumpMidair,
			jumpSpreadException = jTemplate.jumpSpreadException,
		}
	end
end

local jumpCmdDesc = {
	id      = CMD_JUMP,
	type    = CMDTYPE.ICON_MAP,
	name    = 'Jump',
	cursor  = 'Jump', -- add with LuaUI? No.
	action  = 'jump',
	tooltip = 'Jump to selected position',
}


local blockingStructure = {}
for udid = 1, #UnitDefs do
	local ud = UnitDefs[udid]
	if ud.isImmobile and not ud.customParams.mobilebuilding then
		blockingStructure[udid] = true
	end
end

-- upgrade jump defs for unit id
local function updateJumpDefsForUnitId(unitId, unitDefId)
	local jumpUpgrades = spGetUnitRulesParam(unitId, "upgrade_jump")
	local baseJumpDef = baseJumpDefs[unitDefId]
	local extraUpgrades = jumpUpgrades or 0
	if (baseJumpDef.requiresUpgrade) then
		extraUpgrades = math.max(extraUpgrades -1,0)
	end
	if baseJumpDef then
		if (not baseJumpDef.requiresUpgrade) or (jumpUpgrades and jumpUpgrades >= 1) then
			if (not jumpDefsByUnitId[unitId] or (jumpDefsByUnitId[unitId].currentUpgrades ~= jumpUpgrades)) then
				-- enable jump
				spCallCOBScript(unitId, "setHasJump", 0, 1)
				spSetUnitRulesParam(unitId, "jumpReload", 1)
				spInsertUnitCmdDesc(unitId, CMD_JUMP, jumpCmdDesc)
			
				local jumpDef = {
					currentUpgrades = jumpUpgrades,
					range = baseJumpDef.range*(1 + extraUpgrades*JUMP_UPG_RANGE_BONUS),
					speed = baseJumpDef.speed*(1 + extraUpgrades*JUMP_UPG_SPEED_BONUS),
					reload = baseJumpDef.reload*(1 - extraUpgrades*JUMP_UPG_RELOAD_REDUCTION),
					delay = baseJumpDef.delay,
					height = baseJumpDef.height*(1 + extraUpgrades*JUMP_UPG_HEIGHT_BONUS),
		
					requiresUpgrade = baseJumpDef.requiresUpgrade,			
					noJumpHandling = baseJumpDef.noJumpHandling,
					rotateMidAir = baseJumpDef.rotateMidAir,
					cannotJumpMidair = baseJumpDef.cannotJumpMidair,
					jumpSpreadException = baseJumpDef.jumpSpreadException,
				}
				jumpDefsByUnitId[unitId] = jumpDef
				spSetUnitRulesParam(unitId,"jump_range",jumpDef.range)
			end
		else
			-- disable jump
			spSetUnitRulesParam(unitId,"jump_range",0)
			jumpDefsByUnitId[unitId] = nil
			spCallCOBScript(unitId, "setHasJump", 0, 0)
			spSetUnitRulesParam(unitId, "jumpReload", 1)
			spRemoveUnitCmdDesc(unitId, CMD_JUMP)
		end
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function spTestMoveOrderX(unitDefID, x, y, z)
	-- Note that spTestMoveOrder returns true for jumping underwater.
	return spTestMoveOrder(unitDefID, x, y, z, 0, 0, 0, true, true, true)
end


local function GetLandStructureCheckValues(x, z, myRadius)
	-- The largest structure radius is 60 elmos (mahlazer)
	local units = Spring.GetUnitsInCylinder(x,z, 60 + myRadius)
	
	local smallestDistance = 60 + myRadius
	local structureID = false
	local smallestObjectRadius = 0
	
	-- Find the nearby structure which most likely caused the jump
	-- to be a structure jump.
	local spGetUnitRadius = Spring.GetUnitRadius
	
	for i = 1, #units do
		local unitID = units[i]
		local unitDefID = spGetUnitDefID(unitID)
		if blockingStructure[unitDefID] then
			local radius = spGetUnitRadius(unitID)
			local sx, sy, sz = spGetUnitPosition(unitID)
			
			-- If the unit overlaps the center then distance is negative
			local dist = math.sqrt((sx - x)^2 + (sz - z)^2) - radius
			if dist < smallestDistance then
				structureID = unitID
				smallestDistance = dist
				smallestObjectRadius = radius
			end
		end
	end
	
	local featureID = false
	if smallestDistance > myRadius then
		-- No sufficiently close structure was found, 
		-- check whether the blocking was due to a feature.
		local features = Spring.GetFeaturesInCylinder(x,z, 60 + myRadius)
		
		local spGetFeatureBlocking = Spring.GetFeatureBlocking
		local spGetFeatureRadius   = Spring.GetFeatureRadius
		local spGetFeaturePosition = Spring.GetFeaturePosition
		
		local featureDist = 60 + myRadius
		local featureRadius = 0
		
		for i = 1, #features do
			local fid = features[i]
			local blocking = spGetFeatureBlocking(fid)
			if blocking then
				local radius = spGetFeatureRadius(fid)
				local sx, sy, sz = spGetFeaturePosition(fid)
				
				local dist = math.sqrt((sx - x)^2 + (sz - z)^2) - radius
				if dist < featureDist then
					featureID = fid
					featureDist = dist
					featureRadius = radius
				end
			end
		end
		
		-- Replace closest structure with feature if the feature is closer
		if featureID and featureDist < smallestDistance then
			structureID = false
			smallestObjectRadius = featureRadius
		end
	end
	
	if structureID then
		-- Mid position, not base position.
		local _, _, _, sx, sy, sz = spGetUnitPosition(structureID, true)
		return {x = sx, y = sy, z = sz, distSq = (smallestObjectRadius + myRadius)^2}
	elseif featureID then
		local _, _, _, sx, sy, sz = Spring.GetFeaturePosition(featureID, true)
		return {x = sx, y = sy, z = sz, distSq = (smallestObjectRadius + myRadius)^2}
	end
	
	return false
end

local function CheckStructureCollision(data, x, y, z)
	return (data.x - x)^2 + (data.y - y)^2 + (data.z - z)^2 < data.distSq
end

local function GetDist2Sqr(a, b)
	local x, z = (a[1] - b[1]), (a[3] - b[3])
	return (x*x + z*z)
end

local function GetDist3(a, b)
	local x, y, z = (a[1] - b[1]), (a[2] - b[2]), (a[3] - b[3])
	return (x*x + y*y + z*z)^0.5
end

local function Approach(unitID, cmdParams, range)
	spSetUnitMoveGoal(unitID, cmdParams[1],cmdParams[2],cmdParams[3], range)
end

local function StartScript(fn)
	local co = coroutine.create(fn)
	coroutines[#coroutines + 1] = co
end

local function Jump(unitID, goal, origCmdParams, mustJump)
	goal[2]                = spGetGroundHeight(goal[1],goal[3])
	local start            = {spGetUnitPosition(unitID)}

	local startHeight      = spGetGroundHeight(start[1],start[3])
	start[2] = math.max(start[2], startHeight)
	
	local fakeUnitID
	local unitDefID        = spGetUnitDefID(unitID)
	local jumpDef          = jumpDefsByUnitId[unitID]
	local defSpeed         = jumpDef.speed
	local delay            = jumpDef.delay
	local height           = jumpDef.height
	local cannotJumpMidair = jumpDef.cannotJumpMidair
	local reloadTime       = (jumpDef.reload or 0)*30
	local teamID           = spGetUnitTeam(unitID)
	
	if (not mustJump) and ((cannotJumpMidair and abs(startHeight - start[2]) > 1)) then --or (startHeight < -UnitDefs[unitDefID].maxWaterDepth)) then
		return false, true
	end
	
	local rotateMidAir = jumpDef.rotateMidAir
	local env
	
	local vector = {goal[1] - start[1],
	                goal[2] - start[2],
	                goal[3] - start[3]}
	
	-- vertex of the parabola
	local vertex = {start[1] + vector[1]*0.5,
	                start[2] + vector[2]*0.5 + (1-(2*0.5-1)^2)*height,
	                start[3] + vector[3]*0.5}
	
	local lineDist = GetDist3(start, goal)
	if lineDist == 0 then lineDist = 0.00001 end
	local flightDist = GetDist3(start, vertex) + GetDist3(vertex, goal)
	local speed = defSpeed * lineDist/flightDist
	local step = speed/lineDist
	local duration = math.ceil(1/step)+1
	--Spring.Echo("lineDist="..lineDist.." flightDist="..flightDist.." speed="..speed.." step="..step)
	local maxImpulse = 2*defSpeed
	 
	if not mustJump then
		-- check if there is no wall in between
		local x,z = start[1],start[3]
		local wallStep = 0.015
		--Spring.Echo("Gadget", x, start[2], z, "vec", vector[1], vector[2], vector[3], "step", wallStep)
		for i = 0, 1, wallStep do
			x = x + vector[1]*wallStep
			z = z + vector[3]*wallStep
			if ((spGetGroundHeight(x,z) - 30) > (start[2] + vector[2]*i + (1 - (2*i - 1)^2)*height)) then
				return false, false -- FIXME: should try to use SetMoveGoal instead of jumping!
			end
		end
	end

	-- pick shortest turn direction
	local rotUnit      = 2^16 / (pi2)
	local startHeading = spGetUnitHeading(unitID) + 2^15
	local goalHeading  = spGetHeadingFromVector(vector[1], vector[3]) + 2^15
	if (goalHeading >= startHeading + 2^15) then
		startHeading = startHeading + 2^16
	elseif (goalHeading < startHeading - 2^15)	then
		goalHeading = goalHeading + 2^16
	end
	local turn = goalHeading - startHeading
	
	jumping[unitID] = {vector[1]*step, vector[2]*step, vector[3]*step}

	--mcEnable(unitID) -- disable engine physics? original did this
	spSetUnitVelocity(unitID,0,0,0)
	--spSetUnitLeaveTracks(unitID, false)
	
	spSetUnitRulesParam(unitID, "is_jumping", 1)
	spSetUnitRulesParam(unitID, "jump_goal_x", goal[1], privateTable)
	spSetUnitRulesParam(unitID, "jump_goal_z", goal[3], privateTable)
	spCallCOBScript(unitID, "setJumping", 0, 1, 0)


	--env = Spring.UnitScript.GetScriptEnv(unitID)
	
	if (delay == 0) then
		--spCallCOBScript(unitID, "beginJump", 0)
		--Spring.UnitScript.CallAsUnit(unitID,env.beginJump,turn,lineDist,flightDist,duration)
		if rotateMidAir then
			mcSetRotation(unitID, 0, (2^15 - startHeading)/rotUnit, 0) -- keep current heading
			mcSetRotationVelocity(unitID, 0, -turn/rotUnit*step, 0)
		end
		if PLAY_SOUND and (not cannotJumpMidair) then	-- don't make sound if we jump with legs instead of jets
			--GG.PlayFogHiddenSound("Jump", UnitDefs[unitDefID].mass/10, start[1], start[2], start[3])
		end
	else
		--Spring.UnitScript.CallAsUnit(unitID,env.preJump,turn,lineDist,flightDist,duration)
	end
	spSetUnitRulesParam(unitID,"jumpReload",0)

	local function JumpLoop()
		if delay > 0 then
			for i = delay, 1, -1 do
				Sleep()
			end
			
			if (not spValidUnitID(unitID) or spGetUnitIsDead(unitID)) then 
				return 
			end
			--Spring.UnitScript.CallAsUnit(unitID,env.beginJump)
			--spCallCOBScript(unitID, "beginJump", 0)
			if PLAY_SOUND and (not cannotJumpMidair) then	-- don't make sound if we jump with legs instead of jets
				--GG.PlayFogHiddenSound("Jump", UnitDefs[unitDefID].mass/10, start[1], start[2], start[3])
			end

			if rotateMidAir then
				mcSetRotation(unitID, 0, (2^15 - startHeading)/rotUnit, 0) -- keep current heading
				mcSetRotationVelocity(unitID, 0, -turn/rotUnit*step, 0)
			end
		end

		-- detach from transport	
		--TODO remove?
		--local attachedTransport = Spring.GetUnitTransporter(unitID)
		--if (attachedTransport) then
		--	--local envTrans = Spring.UnitScript.GetScriptEnv(attachedTransport)
		--	if (envTrans.ForceDropUnit) then
		--		--Spring.UnitScript.CallAsUnit(attachedTransport,envTrans.ForceDropUnit)
		--	end
		--end
	
		local hitStructure, structureCollisionData
		local halfJump
		local i = 0
		while i <= 1 do
			if (not spValidUnitID(unitID) or spGetUnitIsDead(unitID)) then 
				return 
			end

			local x0, y0, z0 = spGetUnitPosition(unitID)
			local vx0, vy0, vz0 = spGetUnitVelocity(unitID)
			local vx, vy, vz = 0
			local x = start[1] + vector[1]*i
			local y = start[2] + vector[2]*i + (1-(2*i-1)^2)*height -- parabola
			local z = start[3] + vector[3]*i
			
			--mcSetPosition(unitID, x, y, z)  -- force position? disabled / original did this
			
			if x0 then
				--jumping[unitID] = {x - x0, y - y0, z - z0}
				
				-- slow start
				local boostMod = 0.6 + 0.4*i 
				
				vx = boostMod*(x - x0)  
				vy = boostMod*(y - y0) 
				vz = boostMod*(z - z0) 
				
				jumping[unitID] = {vx, vy, vz}
				
				-- turn the unit upright in case it wasn't
				local rx,ry,rz = spGetUnitRotation(unitID)
				Spring.SetUnitRotation(unitID,rx/2,ry,rz/2)
				
				--Spring.Echo(spGetGameFrame().." : set impulse=("..((x - x0))..","..((y - y0))..","..((z - z0))..")  oldv=("..(vx0)..","..(vy0)..","..(vz0)..")")
				
				-- behave differently underwater
				if (y0 < 0 and i < 0.5) then
					spSetUnitPhysics(unitID, x0, y0, z0, vx, vy, vz, rx, ry, rz, 0,0,0) -- remove water drag
					spAddUnitImpulse(unitID,vx, min(vy,maxImpulse/2), vz)
				else
					spSetUnitVelocity(unitID, 0, 0, 0) -- disable gravity effect
					if (i < 0.5) then
						spAddUnitImpulse(unitID,vx, min(vy,maxImpulse), vz)
					else
						spAddUnitImpulse(unitID,vx, max(vy,-maxImpulse), vz)
					end
				end
				
				--spSetUnitVelocity(unitID, (x - x0), (y - y0), (z - z0))  -- original did this 
			end

			--Spring.UnitScript.CallAsUnit(unitID, env.jumping, i * 100)
		
			if (not halfJump and i > 0.5) then
				spCallCOBScript(unitID, "setJumping", 0, 1, 1)
				halfJump = true
				
				-- Do structure collision here to prevent early collision (perhaps a rejump onto the same structure?)
				-- If the move order test fails it means the command must have been allowed because the ground
				-- was otherwise high and flat enough for pathing. This means that a structure (or feature) is at the
				-- land location.
				if not spTestMoveOrderX(unitDefID, goal[1], goal[2], goal[3]) then
					local radius = Spring.GetUnitRadius(unitID)
					structureCollisionData = GetLandStructureCheckValues(goal[1], goal[3], radius)
				end
			end
			
			if structureCollisionData and CheckStructureCollision(structureCollisionData, x, y, z) then
				hitStructure = {x, y, z}
				break
			end
			
			Sleep()
			i = i + step
		end

		--Spring.UnitScript.CallAsUnit(unitID,env.endJump)
		if PLAY_SOUND then
			--GG.PlayFogHiddenSound("JumpLand", UnitDefs[unitDefID].mass/10, goal[1], goal[2], goal[3])
		end
		local jumpEndTime = spGetGameSeconds()
		lastJumpPosition[unitID] = origCmdParams
		jumping[unitID] = nil
		--spSetUnitLeaveTracks(unitID, true)
		--spSetUnitVelocity(unitID, 0, 0, 0)
		spSetUnitRulesParam(unitID, "is_jumping", 0)
		spCallCOBScript(unitID, "setJumping", 0, 0, 0)
		--mcDisable(unitID)      -- original did this

		if spValidUnitID(unitID) and (not spGetUnitIsDead(unitID)) then
			spGiveOrderToUnit(unitID,CMD_WAIT, {}, 0)
			spGiveOrderToUnit(unitID,CMD_WAIT, {}, 0)
		end
		
		if hitStructure then
			-- Add unstick impulse to make the jumper bound on the structure.
			spAddUnitImpulse(unitID, 3,0,3)
			spAddUnitImpulse(unitID, 0,-0.5,0)
			spAddUnitImpulse(unitID, -3,0,-3)
			-- Set position because the unit may snap to the ground.
			spSetUnitPosition(unitID, hitStructure[1], hitStructure[2], hitStructure[3])
		end

		Sleep()
		
		local morphedTo = spGetUnitRulesParam(unitID, "wasMorphedTo")
		if morphedTo then
			lastJumpPosition[morphedTo] = lastJumpPosition[unitID]
			lastJumpPosition[unitID] = nil
			unitID = morphedTo
		end
		
		if spValidUnitID(unitID) and (not spGetUnitIsDead(unitID)) then
			spSetUnitVelocity(unitID, 0, 0, 0) -- prevent the impulse capacitor
		end

		local reloadSpeed = 1/reloadTime
		local reloadAmount = reloadSpeed -- Start here because we just did a sleep for impulse capacitor fix
		
		while reloadAmount < 1 do
			morphedTo = spGetUnitRulesParam(unitID, "wasMorphedTo")
			if morphedTo then 
				unitID = morphedTo 
			end
			if (not spValidUnitID(unitID) or spGetUnitIsDead(unitID)) then 
				return 
			end

			local stunnedOrInbuild = spGetUnitIsStunned(unitID)
			local reloadFactor = (stunnedOrInbuild and 0) or spGetUnitRulesParam(unitID, "totalReloadSpeedChange") or 1
			reloadAmount = reloadAmount + reloadSpeed*reloadFactor
			spSetUnitRulesParam(unitID,"jumpReload",reloadAmount)
			Sleep()
		end
	end

	StartScript(JumpLoop)
	return true, false
end

--TODO is this actually useful?
-- a bit convoluted for this but might be
-- useful for lua unit scripts
local function UpdateCoroutines() 
	local newCoroutines = {} 
	for i = 1, #coroutines do 
		local co = coroutines[i] 
		if (coroutine.status(co) ~= "dead") then 
			newCoroutines[#newCoroutines + 1] = co 
		end 
	end 
	coroutines = newCoroutines 
	for i = 1, #coroutines do 
		assert(coroutine.resume(coroutines[i]))
	end
end

function gadget:Initialize()
	Spring.SetGameRulesParam("jumpJets", 1)
	Spring.SetCustomCommandDrawData(CMD_JUMP, "Jump", {0, 1, 0, 0.7})
	Spring.AssignMouseCursor("Jump", "cursorJump", true, true)
	gadgetHandler:RegisterCMDID(CMD_JUMP)
	for _, unitID in pairs(Spring.GetAllUnits()) do
		gadget:UnitCreated(unitID, Spring.GetUnitDefID(unitID))
	end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	if (not baseJumpDefs[unitDefID]) then
		return
	end
	canJumpUnitIds[unitID] = unitDefID
	updateJumpDefsForUnitId(unitID,unitDefID)
end

-- Makes wrecks continue inertially instead of falling straight down
function gadget:UnitDamaged(unitID)
	local jump_dir = jumping[unitID]
	if (Spring.GetUnitHealth(unitID) < 0) and jump_dir then
		mcDisable(unitID)
		spAddUnitImpulse(unitID,jump_dir[1],jump_dir[2],jump_dir[3])
		jumping[unitID] = nil
	end
end

function gadget:UnitDestroyed(oldUnitID, unitDefID)
	if jumping[oldUnitID] then
		jumping[oldUnitID] = nil -- empty old unit's data
	end
	if canJumpUnitIds[oldUnitID] then
		canJumpUnitIds[oldUnitID] = nil
	end
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)

	if cmdID == CMD.INSERT and cmdParams[2] == CMD_JUMP then
		return gadget:AllowCommand(unitID, unitDefID, teamID, CMD_JUMP, {cmdParams[4], cmdParams[5], cmdParams[6]}, cmdParams[3])
	end
	
	if not jumpDefsByUnitId[unitID] then 
		if cmdID == CMD_JUMP then
			return false
		end
		return true
	end
	
	if (jumpDefsByUnitId[unitID].noJumpHandling) then 
		return true
	end
	
	if cmdID == CMD_JUMP and cmdParams[3] then
		if spTestMoveOrderX(unitDefID, cmdParams[1], cmdParams[2], cmdParams[3]) then
			return true
		else
			-- Check whether the terrain is the source of the blockage. If it is not then
			-- conclude that the blockage is a structure.
			-- Jumping into water is allowed.
			
			local normal = select(2, spGetGroundNormal(cmdParams[1],cmdParams[3]))
			-- Most of the time the normal will be close to 1 because structures are built on
			-- flat ground. This check captures high slope tolerance things such as Windgens and
			-- small turrets.
			if normal < 0.6 then
				-- Ground is too steep for bots to walk on.
				return false
			end
			
			-- Ground is fine, must contain a blocking structure.
			return true
		end
	end
	if goalSet[unitID] then
		goalSet[unitID] = nil
	end
	return true -- allowed
end

function gadget:CommandFallback(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions) -- Only calls for custom commands
	if (not jumpDefsByUnitId[unitID]) then
		return false
	end

	if (jumpDefsByUnitId[unitID].noJumpHandling) then
		return true, false
	end
	
	if (cmdID ~= CMD_JUMP) then
		return false
	end

	if not spValidUnitID(unitID) then
		return true, true
	end

	if ((spGetUnitRulesParam(unitID, "orbitalDrop") or 0) == 1) then
		return true, false
	end

	if (jumping[unitID]) then
		return true, false -- command was used but don't remove it (unit is still jumping)
	end

	if lastJumpPosition[unitID] then
		if abs(lastJumpPosition[unitID][1] - cmdParams[1]) < 1 and 
				abs(lastJumpPosition[unitID][3] - cmdParams[3]) < 1 then
			return true, true -- command was used, remove it (unit finished jump)
		end
		lastJumpPosition[unitID] = nil
	end
	
	local t = spGetGameSeconds()
	local x, y, z = spGetUnitPosition(unitID)
	local distSqr = GetDist2Sqr({x, y, z}, cmdParams)
	local jumpDef = jumpDefsByUnitId[unitID]
	local range   = jumpDef.range

	if (distSqr < (range*range)) then
		if (spGetUnitRulesParam(unitID, "jumpReload") >= 1) and spGetUnitRulesParam(unitID,"disarmed") ~= 1 then
			local coords = table.concat(cmdParams)
			local currFrame = spGetGameFrame()
			for allCoords, oldStuff in pairs(jumps) do
				if currFrame-oldStuff[2] > 150 then 
					jumps[allCoords] = nil --empty jump table (used for randomization) after 5 second. Use case: If infinite wave of unit has same jump coordinate then jump coordinate won't get infinitely random
				end
			end
			if (not jumps[coords]) or jumpDef.jumpSpreadException then
				local didJump, removeCommand = Jump(unitID, cmdParams, cmdParams)
				if not didJump then
					return true, removeCommand -- command was used
				end
				jumps[coords] = {1, currFrame} --memorize coordinate so that next unit can choose different landing site
				return true, false -- command was used but don't remove it (unit have not finish jump yet)
			else
				local r = landBoxSize*jumps[coords][1]^0.5/2
				local randpos = {
					cmdParams[1] + random(-r, r),
					cmdParams[2],
					cmdParams[3] + random(-r, r)}
				local didJump, removeCommand = Jump(unitID, randpos, cmdParams)
				if not didJump then
					return true, removeCommand -- command was used
				end
				jumps[coords][1] = jumps[coords][1] + 1
				return true, false -- command was used but don't remove it(unit have not finish jump yet)
			end
		end
	else
		if not goalSet[unitID] then
			Approach(unitID, cmdParams, range)
			goalSet[unitID] = true
		end
	end

	return true, false -- command was used but don't remove it
end

function gadget:UnitFromFactory(unitID, unitDefID, unitTeam, facID, facDefID)
	if jumpDefsByUnitId[unitID] then
		-- The first command in the queue is a move command added by the engine.
		local cmdID_1, cmdID_2, cmdTag_1
		if Spring.Utilities.COMPAT_GET_ORDER then
			local queue = Spring.GetCommandQueue(unitID, 2)
			if queue and queue[1] and queue[2] then
				cmdID_1, cmdID_2, cmdTag_1 = queue[1].id, queue[2].id, queue[1].tag
			end
		else
			cmdID_1, _, cmdTag_1 = Spring.GetUnitCurrentCommand(unitID)
			cmdID_2 = Spring.GetUnitCurrentCommand(unitID, 2)
		end
		if cmdID_1 and cmdID_2 then
			if cmdID_1 == CMD_MOVE and cmdID_2 == CMD_JUMP then
				Spring.GiveOrderToUnit(unitID, CMD_REMOVE, {cmdTag_1}, 0)
			end
		end
	end
end

function gadget:GameFrame(n)
	UpdateCoroutines()
	for coords, queue_n_age in pairs(jumps) do 
		if n-queue_n_age[2] > 300 then
			jumps[coords] = nil
		end
	end
	
	-- update jump status every half second
	if (n % 15 == 0) then
		-- update jump ability
		for uId,uDefId in pairs(canJumpUnitIds) do
			updateJumpDefsForUnitId(uId,uDefId)
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Save/Load

function gadget:Load(zip)
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		if spGetUnitRulesParam(unitID, "is_jumping") == 1 then
			local goalX = spGetUnitRulesParam(unitID, "jump_goal_x")
			local goalZ = spGetUnitRulesParam(unitID, "jump_goal_z")
			if goalX and goalZ then
				local goal = {goalX, 0, goalZ}
				Jump(unitID, goal, goal, true)
			end
		end
	end
end
