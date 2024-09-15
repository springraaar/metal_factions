
function widget:GetInfo()
  return {
    name      = "Range Indicators",
    desc      = "Workaround for engine not displaying or scaling range indicators in some situations.",
    author    = "raaar",
    date      = "2024",
    license   = "PD",
    layer     = 1, 
    enabled   = true
  }
end


local spGetActiveCommand       = Spring.GetActiveCommand
local spGetCameraPosition      = Spring.GetCameraPosition
local spGetFeaturePosition     = Spring.GetFeaturePosition
local spGetGroundHeight        = Spring.GetGroundHeight
local spGetMouseState          = Spring.GetMouseState 
local spGetSelectedUnitsSorted = Spring.GetSelectedUnitsSorted
local spGetUnitPosition        = Spring.GetUnitPosition
local spGetUnitRadius          = Spring.GetUnitRadius
local spGetUnitStates          = Spring.GetUnitStates
local spTraceScreenRay         = Spring.TraceScreenRay
local spIsAboveMiniMap         = Spring.IsAboveMiniMap  
local spGetUnitDefId         = Spring.GetUnitDefID
local spGetUnitWeaponState   = Spring.GetUnitWeaponState
local spGetUnitTeam          = Spring.GetUnitTeam
local spGetTeamRulesParam    = Spring.GetTeamRulesParam
local spGetUnitSensorRadius  = Spring.GetUnitSensorRadius

local CMD_ATTACK             = CMD.ATTACK
local CMD_MANUALFIRE         = CMD.MANUALFIRE

local glBeginEnd             = gl.BeginEnd
local glCallList             = gl.CallList
local glCreateList           = gl.CreateList
local glColor                = gl.Color
local glDeleteList           = gl.DeleteList
local glDepthTest            = gl.DepthTest
local glDrawGroundCircle     = gl.DrawGroundCircle
local glLineWidth            = gl.LineWidth
local glLoadIdentity         = gl.LoadIdentity
local glPointSize            = gl.PointSize
local glPopMatrix            = gl.PopMatrix
local glPushMatrix           = gl.PushMatrix
local glRotate               = gl.Rotate
local glScale                = gl.Scale
local glTranslate            = gl.Translate
local glVertex               = gl.Vertex
local glTexCoord             = gl.TexCoord
local GL_LINE_LOOP           = GL.LINE_LOOP

local PI                     = math.pi
local atan                   = math.atan
local cos                    = math.cos
local sin                    = math.sin
local floor                  = math.floor
local max                    = math.max
local min                    = math.min
local sqrt                   = math.sqrt


VFS.Include("lualibs/util.lua")
VFS.Include("lualibs/custom_cmd.lua")

local vsx, vsy = gl.GetViewSizes()
local scaleFactor = 1
if (vsy > 1080) then
	scaleFactor = vsy / 1080
end	
local attackRangeColor = {1, 0.3, 0.3, 0.75}
local torpedoAttackRangeColor = {1, 0.3, 0.3, 0.75}		--TODO not used atm
local radarRangeColor = {0.3, 1, 0.3, 0.75}
local sonarRangeColor = {0.3, 0.3, 1, 0.75}
local deathBlastRangeColor = {0.5, 0, 0, 0.75}

local LINE_WIDTH = 1.8 * scaleFactor
local MINIMAP_LINE_WIDTH = 1.5 * scaleFactor
  
local shiftKeyHeld = false

local irrelevantWeaponDefIds = {}
for wDId,wd in pairs(WeaponDefs) do
	if wd.isShield or wd.description == "No Weapon" then
		irrelevantWeaponDefIds[wDId] = true
	end
end

---------------------------------- auxiliary functions

VFS.Include("lualibs/circles.lua")

-- add death blast range circle to draw list
local function addBlastRadiusIfRelevant(ud,x,y,z)
	local deathBlastWD = WeaponDefNames[ud.deathExplosion] 
	local selfDBlastWD = WeaponDefNames[ud.selfDExplosion]
	if ud.canSelfD or (deathBlastWD and deathBlastWD.damageAreaOfEffect > 100) or (ud.canSelfD and selfDBlastWD and selfDBlastWD.damageAreaOfEffect > 100 ) then
		local radius = max(deathBlastWD and deathBlastWD.damageAreaOfEffect or 0,(ud.canSelfD and selfDBlastWD) and selfDBlastWD.damageAreaOfEffect or 0)
		
		addCircle(x,y,z,radius,deathBlastRangeColor,false) 
	end
end

-- add various range circles to draw list, if relevant
-- uses unitDef/weaponDef information (not weapon state)
local function checkAddUnitRanges(ud,teamId,x,y,z)
	addBlastRadiusIfRelevant(ud,x,y,z)

	local rangeMult = spGetTeamRulesParam(teamId, "upgrade_armed_range_mult") or 1

	-- show range circles for all non-shield weapons
	if ud.weapons and ud.weapons[1] and ud.weapons[1].weaponDef then
		for wNum,w in pairs(ud.weapons) do
			local wd=WeaponDefs[w.weaponDef]
			if not irrelevantWeaponDefIds[w.weaponDef] then
				range = wd.range * rangeMult
				if range then
					addCircle(x,y,z,range,attackRangeColor,true)
				end
			end
		end
	end
  
	-- show radar and sonar range
	if ud.radarRadius and ud.radarRadius > 0 then
       	addCircle(x,y,z,ud.radarRadius*rangeMult,radarRangeColor,true)
	end
	if ud.sonarRadius and ud.sonarRadius > 0 then
		addCircle(x,y,z,ud.sonarRadius*rangeMult,sonarRangeColor,true)
	end
end


-- repopulate lists of circles to draw
local function updateCirclesToDraw()
	minimapCirclesToDraw = {}	-- x,z,radius,color
	circlesToDraw = {}		-- x,y,z,radius,color
 
	local selectedUnitsByDefId = spGetSelectedUnitsSorted()
	local selUnitId = nil
	local hoveredUnitId = nil
	
	-- get one of the selected units of the most expensive kind
	local cost = 0
	local maxCost = 0
	for unitDefId, unitIds in pairs(selectedUnitsByDefId) do
		cost = UnitDefs[unitDefId].metalCost
		if cost >= maxCost then
			selUnitId = unitIds[1]
			maxCost = cost
		end
	end

  	local mx, my = spGetMouseState()
	local mouseTargetType, mouseTarget = spTraceScreenRay(mx, my)
  
	if (mouseTargetType == "ground") then
		tx = mouseTarget[1]
		ty = mouseTarget[2]
		tz = mouseTarget[3]
	elseif (mouseTargetType == "unit") then
		hoveredUnitId = mouseTarget		
		tx,ty,tz = spGetUnitPosition(mouseTarget)
	elseif (mouseTargetType == "feature") then
		tx,ty,tz = spGetFeaturePosition(mouseTarget)
	end  
  
	if (not tx) then return end
	local _, cmd, _ = spGetActiveCommand()
  	local range = 0
  
	-- if trying to build a building, draw its range and sensor indicators
	if selUnitId and (cmd and cmd < 0) then 
		local unitDefId = -cmd
		local ud = UnitDefs[unitDefId]
		
		-- get build position
		if tx then
			local selTeamId = spGetUnitTeam(selUnitId)
			checkAddUnitRanges(ud,selTeamId,tx,ty,tz)
		end
    	return
	end
  
	-- if holding shift while hovering over a unit, draw its range and sensor indicators
	if hoveredUnitId and shiftKeyHeld then
		if tx then
			-- get the unit's range circles
			local range = 0
			local unitDefId = spGetUnitDefId(hoveredUnitId)
			if (unitDefId ~= nil) then
				local ud = UnitDefs[unitDefId]
				
				local selTeamId = spGetUnitTeam(hoveredUnitId)
				checkAddUnitRanges(ud,selTeamId,tx,ty,tz)
			end
		end
		return
	end
  
	-- if issuing attack order with selected units, draw range indicators for ALL(*) of them
	-- (*) cap at 100 units for performance reasons
	if selUnitId and (cmd == CMD_ATTACK or cmd == CMD_MANUALFIRE or cmd == CMD_UNIT_SET_TARGET or cmd == CMD_UNIT_SET_TARGET_NO_GROUND) then
		local fx,fy,fz,wd,ud
		local count = 0
		local skip = false
		for unitDefId,selUnitIds in pairs(selectedUnitsByDefId) do
			if (skip) then
				break
			end
			for _,selUnitId in pairs(selUnitIds) do 
				fx, fy, fz = spGetUnitPosition(selUnitId)
				if fx then
					-- get the unit's range circles
					range = 0
					if (unitDefId ~= nil) then
						ud = UnitDefs[unitDefId]
						addBlastRadiusIfRelevant(ud,fx,fy,fz)
			
						-- show range circles for all non-shield weapons
						if ud.weapons and ud.weapons[1] and ud.weapons[1].weaponDef then
							for wNum,w in pairs(ud.weapons) do
								wd=WeaponDefs[w.weaponDef]
								if not irrelevantWeaponDefIds[w.weaponDef] then
									range = spGetUnitWeaponState(selUnitId,wNum,"range")
									if range then
										addCircle(fx,fy,fz,range,attackRangeColor,true)
									end
								end
							end
						end
					end
					count = count + 1
					if count >= 100 then
						skip = true
						break
					end
				end
			end
		end
		return
	end
end

---------------------------------- engine callins


function widget:Initialize()
	initCircleDLists()
end


function widget:Shutdown()
	removeCircleDLists()
end

function widget:Update(dt)
	timeSinceLastCircleUpdate = timeSinceLastCircleUpdate + dt
	-- limit circles update rate to 30x per second 
	if timeSinceLastCircleUpdate > 0.03 then
		updateCirclesToDraw()
		timeSinceLastCircleUpdate = 0
	end
end

function widget:DrawInMiniMap(sx, sz)
	glPushMatrix()
	glCallList(minimapTransformDList)
	
	glLineWidth(MINIMAP_LINE_WIDTH)
	for _,circle in ipairs(minimapCirclesToDraw) do
		drawMinimapCircle(circle[1],circle[2],circle[3],circle[4])
	end
	glPopMatrix()
	glColor(1,1,1,1)
end

function widget:DrawWorld()
	glLineWidth(LINE_WIDTH)
	for _,circle in ipairs(circlesToDraw) do
		drawGroundCircle(circle[1],circle[2],circle[3],circle[4],circle[5])
	end
	glColor(1,1,1,1)
end

function widget:KeyPress(key, mods, isRepeat)
	if mods.shift then
		shiftKeyHeld = true
	end
end

function widget:KeyRelease(key, mods)
	if not mods.shift then
		shiftKeyHeld = false
	end
end

