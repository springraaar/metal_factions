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
local abs = math.abs
local sin = math.sin
local cos = math.cos
local sqrt = math.sqrt
local pow = math.pow
local spGetCameraState = Spring.GetCameraState

RANGE_TYPE_DEF = 0		-- infinitely tall cylinder (default)
RANGE_TYPE_SPH = 1		-- sphere (lasers)
RANGE_TYPE_CYL = 2		-- 2x tall cylinder
RANGE_TYPE_ELL = 3		-- 2x tall ellipsoid (most weapons)
RANGE_TYPE_EHB = 4		-- 2x tall ellipsoid + height boost/penalty (cannons)

timeSinceLastCircleUpdate = math.huge
minimapTransformDList = 0
refMinimapCircleDList = 0

complexCircleDLists = {}
complexCircleDListKeysRecentlyAdded = {}
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

-- for range indicators across the ground
local sinTable64, cosTable64 = createSinCosTable(64)


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
	local camState = spGetCameraState()
	if camState.flipped == 1 then
		x = Game.mapSizeX - x
		z = Game.mapSizeZ - z
	end

	glColor(color)
	glPushMatrix()
	glTranslate(x, z, 0)
	glScale(radius, radius, 1)
	glCallList(refMinimapCircleDList)
	glPopMatrix()
end

function drawGroundCircle(x,y,z,radius,color,rType)
	-- comparison with cylinder range, for debug purposes
	--glColor(0,1,0,1)
	--glDrawGroundCircle(x, y, z, radius, 50)
	glColor(color)
	local wDProps = nil 
	if type(rType) == "table" then
		wDProps = rType
		rType = wDProps.rangeType
	end 

	if rType and rType > 0 then
		local gh,hDif,radiusFactor,mRadius,vx,vz,tries,stepSize,normDistance
		local invRadius = 1/radius
		local tries = 12
		local key = x+y+z+radius+color[1]+color[2]+color[3]+rType
		if rType == RANGE_TYPE_SPH or rType == RANGE_TYPE_ELL or rType == RANGE_TYPE_EHB then
			if not complexCircleDLists[key] then
				local heightMod = wDProps and wDProps.heightMod or 0
				local maxVRange = heightMod*radius
				local heightBoostFactor = wDProps and 1.67*wDProps.heightBoostFactor or 0
				local upwardsSpeedFactor = wDProps and (0.0+11/wDProps.projectilespeed)*heightBoostFactor or 0
				local downwardsSpeedFactor = wDProps and (0.1+4/wDProps.projectilespeed)*heightBoostFactor or 0
				
				complexCircleDLists[key] = glCreateList(glBeginEnd,GL_LINE_LOOP, function()
					for i = #sinTable64, 1, -1 do
						hDif = 0
						radiusFactor = 0.01
						normDistance = 0
						stepSize = 0.5
						for j=1,tries do
							mRadius = radiusFactor * radius
							vx = x + mRadius*sinTable64[i]
							vz = z + mRadius*cosTable64[i]
							gh = spGetGroundHeight(vx,vz)
							hDifRaw = y-gh
							hDif = abs(hDifRaw)*heightMod
	
							if stepSize < 0.01 then
								break
							end
							
							if rType == RANGE_TYPE_EHB then
								-- apply height boost/penalty
								--TODO flawed, but better than before..
								local hBFactor = 1 
								if (hDifRaw > 0) then
									-- edge is lower ground
									hBFactor = 1 + downwardsSpeedFactor*hDif*invRadius
								else
									-- edge is higher ground
									hBFactor = 1 - upwardsSpeedFactor*hDif*invRadius
								end
							
								normDistance = sqrt((radiusFactor)^2+(hDif*invRadius)^2)
								if normDistance > hBFactor or radiusFactor > hBFactor then
									stepSize = stepSize * 0.5
									radiusFactor = radiusFactor-stepSize 
								else
									radiusFactor = radiusFactor+stepSize						
								end							
							else
								normDistance = pow(radiusFactor,2)+pow(hDif*invRadius,2)
								if normDistance > 1.00 or radiusFactor > 1.00 then
									stepSize = stepSize * 0.5
									radiusFactor = radiusFactor-stepSize 
								else
									radiusFactor = radiusFactor+stepSize						
								end
							end
														
							--if i == 16 then
							--	Spring.MarkerErasePosition(vx,gh,vz)
							--	Spring.MarkerAddPoint(vx,gh,vz,string.format("%.1f",normDistance))
							--end
	 					end
						glVertex(vx,min(gh,y+maxVRange)+1, vz)
					end
				end)
			end
			complexCircleDListKeysRecentlyAdded[key]=true
			glCallList(complexCircleDLists[key])
		elseif rType == RANGE_TYPE_CYL then
			-- just assume it has no height restrictions for now
			glDrawGroundCircle(x, y, z, radius, 50)
		else
			glDrawGroundCircle(x, y, z, radius, 50)
		end
	else
		glDrawGroundCircle(x, y, z, radius, 50)
	end
end

function addCircle(x,y,z,radius,color,minimap,type)
	circlesToDraw[#circlesToDraw+1] = {x,y,z,radius,color,type}
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
	for key,cdl in pairs(complexCircleDLists) do
		glDeleteList(cdl)
		complexCircleDLists[key] = nil
	end
end