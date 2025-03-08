
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
local spGetSelectedUnits       = Spring.GetSelectedUnits
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
local spGetSelectedUnitsCount = Spring.GetSelectedUnitsCount

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

local wDProperties = {}  
local selectedUnitsByDefIdWCost = {}
local selectedUnitsCount = 0

---------------------------------- auxiliary functions

VFS.Include("lualibs/circles.lua")


local function getRangeType(wd)
	if wd.heightMod and wd.heightMod == 1 then
		return RANGE_TYPE_SPH
	elseif wd.heightMod and wd.heightMod == 0.5 then
		if wd.cylinderTargeting == 1 then
			return RANGE_TYPE_CYL
		elseif wd.heightBoostFactor > 0 then
			return RANGE_TYPE_EHB
		else
			return RANGE_TYPE_ELL
		end
	end
	return nil
end

-- add death blast range circle to draw list
local function addBlastRadiusIfRelevant(ud,x,y,z)
	local deathBlastWD = WeaponDefNames[ud.deathExplosion] 
	local selfDBlastWD = WeaponDefNames[ud.selfDExplosion]
	if (ud.isImmobile and deathBlastWD and deathBlastWD.damageAreaOfEffect > 100) or (ud.canSelfD and selfDBlastWD and selfDBlastWD.damageAreaOfEffect > 100 and (not (ud.customParams and ud.customParams.iscommander))) then
		local radius = max(deathBlastWD and deathBlastWD.damageAreaOfEffect or 0,(ud.canSelfD and selfDBlastWD) and selfDBlastWD.damageAreaOfEffect or 0)
		
		addCircle(x,y,z,radius,deathBlastRangeColor,false,RANGE_TYPE_SPH) 
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
					addCircle(x,y+ud.model.midy,z,range,attackRangeColor,true,wDProperties[wd.id])
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

	local selUnitId = nil
	local hoveredUnitId = nil
 
 	local newSelCount = spGetSelectedUnitsCount()
 	if newSelCount ~= selectedUnitsCount then
 		selectedUnitsCount = newSelCount
 		
 		selectedUnitsByDefIdWCost = {}
 		local selectedUnitsByDefId = spGetSelectedUnitsSorted()
		local cost = 0

		for unitDefId, unitIds in pairs(selectedUnitsByDefId) do
			cost = UnitDefs[unitDefId].metalCost
			selectedUnitsByDefIdWCost[unitDefId]={unitIds=unitIds,cost=cost}
		end
 	end
 	if selectedUnitsCount > 0 then
 		selUnitId = spGetSelectedUnits()[1] 
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
	-- (*) cap at 10 most expensive units for performance reasons
	if selUnitId and (cmd == CMD_ATTACK or cmd == CMD_MANUALFIRE or cmd == CMD_UNIT_SET_TARGET or cmd == CMD_UNIT_SET_TARGET_NO_GROUND) then
		local fx,fy,fz,wd,ud
		local count = 0
		local skip = false

		for unitDefId,data in spairs(selectedUnitsByDefIdWCost,function(t,a,b) return t[b].cost < t[a].cost end) do
			ud = UnitDefs[unitDefId]
			local selUnitIds = data.unitIds
			if (skip) then
				break
			end
			for _,selUnitId in pairs(selUnitIds) do 
				fx, fy, fz = spGetUnitPosition(selUnitId)
				if fx then
					-- get the unit's range circles
					range = 0
					if (unitDefId ~= nil) then
						addBlastRadiusIfRelevant(ud,fx,fy,fz)
			
						-- show range circles for all non-shield weapons
						if ud.weapons and ud.weapons[1] and ud.weapons[1].weaponDef then
							for wNum,w in pairs(ud.weapons) do
								wd=WeaponDefs[w.weaponDef]
								if not irrelevantWeaponDefIds[w.weaponDef] then
									range = spGetUnitWeaponState(selUnitId,wNum,"range")
									if range then
										addCircle(fx,fy+ud.model.midy,fz,range,attackRangeColor,true,wDProperties[wd.id])
									end
								end
							end
						end
					end
					count = count + 1
					if count >= 10 then
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
	
	-- collect properties by weapon def id
	for i=1,#WeaponDefs do
		local wd = WeaponDefs[i]

		if not irrelevantWeaponDefIds[wd.id] then
			props = {}
			
			props.weaponType = wd.weaponType
			props.cylinderTargeting = wd.cylinderTargeting
			props.projectilespeed = wd.projectilespeed
			props.heightBoostFactor = wd.heightBoostFactor
			props.heightMod = wd.heightMod
			props.myGravity = wd.myGravity
			props.rangeType = getRangeType(wd)
			
			wDProperties[wd.id] = props
		end
	end
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

		-- clear complex circle displaylists not being displayed
		for key,cdl in pairs(complexCircleDLists) do
			if not complexCircleDListKeysRecentlyAdded[key] then
				complexCircleDLists[key] = nil
			end
		end
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
	-- trigger cleanup of dlists not in use, relevant ones get reinserted
	complexCircleDListKeysRecentlyAdded = {}
	
	glLineWidth(LINE_WIDTH)
	for _,circle in ipairs(circlesToDraw) do
		drawGroundCircle(circle[1],circle[2],circle[3],circle[4],circle[5],circle[6])
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

