function widget:GetInfo()
  return {
    name      = "Jump Range",
    desc      = " Cursor indicator for jump range when giving jump command.",
    author    = "raaar",
    date      = "2021",
    license   = "GNU LGPL, v2.1 or later",
    layer     = 1, 
    enabled   = true
  }
end

-- custom commands
VFS.Include("lualibs/custom_cmd.lua")


local spGetActiveCommand       = Spring.GetActiveCommand
local spGetCameraPosition      = Spring.GetCameraPosition
local spGetFeaturePosition     = Spring.GetFeaturePosition
local spGetGroundHeight        = Spring.GetGroundHeight
local spGetMouseState          = Spring.GetMouseState 
local spGetSelectedUnits       = Spring.GetSelectedUnits
local spGetUnitPosition        = Spring.GetUnitPosition
local spTraceScreenRay         = Spring.TraceScreenRay
local spGetUnitDefId         = Spring.GetUnitDefID
local spGetUnitWeaponState   = Spring.GetUnitWeaponState
local spGetUnitRulesParam    = Spring.GetUnitRulesParam
local g                      = Game.gravity
local GAME_SPEED             = 30
local g_f                    = g / GAME_SPEED / GAME_SPEED
local glBeginEnd             = gl.BeginEnd
local glCallList             = gl.CallList
local glCreateList           = gl.CreateList
local glColor                = gl.Color
local glDeleteList           = gl.DeleteList
local glDepthTest            = gl.DepthTest
local glDrawGroundCircle     = gl.DrawGroundCircle
local glLineWidth            = gl.LineWidth
local glPointSize            = gl.PointSize
local glPopMatrix            = gl.PopMatrix
local glPushMatrix           = gl.PushMatrix
local glRotate               = gl.Rotate
local glScale                = gl.Scale
local glTranslate            = gl.Translate
local glVertex               = gl.Vertex
local GL_LINES               = GL.LINES
local GL_LINE_LOOP           = GL.LINE_LOOP
local GL_POINTS              = GL.POINTS
local PI                     = math.pi
local atan                   = math.atan
local cos                    = math.cos
local sin                    = math.sin
local floor                  = math.floor
local max                    = math.max
local min                    = math.min
local sqrt                   = math.sqrt

local vsx, vsy = gl.GetViewSizes()
local scaleFactor = 1
if (vsy > 1080) then
	scaleFactor = vsy / 1080
end	

local selJumpUnits = {}  -- id, range table

local function getMouseTargetPosition()
	local mx, my = spGetMouseState()
  	local mouseTargetType, mouseTarget = spTraceScreenRay(mx, my)
  
	if (mouseTargetType == "ground") then
		return mouseTarget[1], mouseTarget[2], mouseTarget[3]
	elseif (mouseTargetType == "unit") then
		return spGetUnitPosition(mouseTarget)
	elseif (mouseTargetType == "feature") then
		return spGetFeaturePosition(mouseTarget)
	else
		return nil
	end
end


local function updateSelection()
	local selIds = spGetSelectedUnits()
	selJumpUnits = {}
	for _,uId in pairs(selIds) do
		local jRange = spGetUnitRulesParam(uId,"jump_range")
		if (jRange) then
			jRange = tonumber(jRange)
			if jRange > 0 then
				selJumpUnits[uId] = jRange
			end
		end 
	end
end


----------------------- engine event handlers

function widget:DrawWorld()
	updateSelection()
  
	local tx, ty, tz = getMouseTargetPosition()
	if (not tx) then return end
	local _, cmd, _ = spGetActiveCommand()
	local info, unitID
	local fx, fy, fz = 0
	
	if cmd == CMD_JUMP then
		for uId,range in pairs(selJumpUnits) do
			local fx, fy, fz = spGetUnitPosition(uId)
			if fx then
				glColor(0, 0.5, 0.0, 1)
				glLineWidth(2*scaleFactor)
				glDrawGroundCircle(fx, fy, fz, range, 50)
				glColor(1,1,1,1)
			end
		end
	end
end
