-- variables and functions for drawing circumferences on the ground and on the minimap

local glCreateList = gl.CreateList
local glDeleteList = gl.DeleteList
local glCallList = gl.CallList
local glBeginEnd = gl.BeginEnd
local glColor = gl.Color
local glPushMatrix = gl.PushMatrix
local glPopMatrix = gl.PopMatrix
local GL_LINE_LOOP = GL.LINE_LOOP
local glLoadIdentity = gl.LoadIdentity
local glTranslate = gl.Translate
local glScale = gl.Scale
local glDrawGroundCircle = gl.DrawGroundCircle
local glVertex = gl.Vertex
local sin = math.sin
local cos = math.cos

timeSinceLastCircleUpdate = math.huge
minimapTransformDList = 0
refMinimapCircleDList = 0

minimapCirclesToDraw = {}	-- x,z,radius,color
circlesToDraw = {}		-- x,y,z,radius,color


local TWO_PI = math.pi * 2
function createSinCosTable(divs)
	local sinTable = {}
	local cosTable = {}

	local divAngle = TWO_PI / divs
	local alpha = 0
	local i = 1
	repeat
		sinTable[i] = sin(alpha)
		cosTable[i] = cos(alpha)

		alpha = alpha + divAngle
		i = i + 1
	until (alpha >= TWO_PI)
	sinTable[i] = 0.0 -- sin(TWO_PI)
	cosTable[i] = 1.0 -- cos(TWO_PI)

	return sinTable, cosTable
end


function drawRefMinimapCircle(x,y,radius,divs)
	divs = divs or 25
	local sinTable, cosTable = createSinCosTable(divs)

	glBeginEnd(GL_LINE_LOOP, function()
		for i = #sinTable, 1, -1 do
			glVertex(x + radius*sinTable[i], y + radius*cosTable[i], 0)
		end
	end)
end


function drawMinimapCircle(x,z,radius,color)
	glColor(color)
	glPushMatrix()
	glTranslate(x, z, 0)
	glScale(radius, radius, 1)
	glCallList(refMinimapCircleDList)
	glPopMatrix()
end

function drawGroundCircle(x,y,z,radius,color)
	glColor(color)
	glDrawGroundCircle(x, y, z, radius, 50)
end

function addCircle(x,y,z,radius,color,minimap)
	circlesToDraw[#circlesToDraw+1] = {x,y,z,radius,color}
	if (minimap) then
		minimapCirclesToDraw[#minimapCirclesToDraw+1] = {x,z,radius,color}
	end
end

function initCircleDLists()
	minimapTransformDList = glCreateList(function()
		glLoadIdentity()
		glTranslate(0, 1, 0)
		glScale(1 / Game.mapSizeX, -1 / Game.mapSizeZ, 1)
	end)
	refMinimapCircleDList = glCreateList(drawRefMinimapCircle,0,0,1,35)
end

function removeCircleDLists()
	glDeleteList(minimapTransformDList)
	glDeleteList(refMinimapCircleDList)
end