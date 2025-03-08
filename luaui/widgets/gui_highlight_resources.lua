
function widget:GetInfo()
	return {
		name      = 'Highlight Resource Spots',
		desc      = 'Highlights resource spots when in metal map view',
		author    = 'raaar, based on geo spot widget by Niobium',
		date      = '2025',
		license   = 'GNU GPL, v2 or later',
		layer     = 0,
		enabled   = true,
	}
end

----------------------------------------------------------------
-- Globals
----------------------------------------------------------------
local geoDisplayList
local mexDisplayList

----------------------------------------------------------------
-- Speedups
----------------------------------------------------------------
local glLineWidth = gl.LineWidth
local glDepthTest = gl.DepthTest
local glCallList = gl.CallList
local glTexCoord = gl.TexCoord
local glVertex = gl.Vertex
local glPushAttrib = gl.PushAttrib
local glPopAttrib = gl.PopAttrib
local glDepthTest = gl.DepthTest
local glDepthMask = gl.DepthMask
local glTexture = gl.Texture
local glColor = gl.Color
local glBeginEnd = gl.BeginEnd
local glPushMatrix = gl.PushMatrix
local glPopMatrix = gl.PopMatrix
local glTranslate = gl.Translate
local glRotate = gl.Rotate

local spGetMapDrawMode = Spring.GetMapDrawMode
local spGetGroundHeight = Spring.GetGroundHeight

local font = gl.LoadFont("luaui/fonts/FreeSansBold.otf", 55, 10, 10)


local max = math.max

VFS.Include("lualibs/util.lua")

local metalTextColor = {1,1,1}
local metalTextOutlineColor = {0,0,0}
local refWeight = 3.0

----------------------------------------------------------------
-- Functions
----------------------------------------------------------------
local function pillarVerts(x, y, z)
	gl.Color(1, 1, 0, 1)
	gl.Vertex(x, y, z)
	gl.Color(1, 1, 0, 0)
	gl.Vertex(x, y + 1000, z)
end

local function highlightGeos()
	local features = Spring.GetAllFeatures()
	for i = 1, #features do
		local fID = features[i]
		if FeatureDefs[Spring.GetFeatureDefID(fID)].geoThermal then
			local fx, fy, fz = Spring.GetFeaturePosition(fID)
			gl.BeginEnd(GL.LINE_STRIP, pillarVerts, fx, fy, fz)
		end
	end
end


local function draw3DText(text,ux,uy,uz,textSize,wColorFactor)  
	glPushMatrix()
	glDepthTest(false)
	glDepthMask(false)	
	glTranslate(ux, uy, uz)
	glRotate(270,1,0,0)
	font:Begin()
	font:SetTextColor(metalTextColor[1]*wColorFactor,metalTextColor[2]*wColorFactor,metalTextColor[3]*wColorFactor)
	font:SetOutlineColor(metalTextOutlineColor)
	font:Print(text, 0, 0, textSize, "con")
	font:End()
	glPopMatrix()
end

local function drawMSpotVertices(x,y,z)
	local s = 1
	local sx = 60
	local sz = 60
  
	glTexCoord(0,0)
	glVertex(x-sx,y,z-sz)

	glTexCoord(0,s)
	glVertex(x-sx,y,z+sz)

	glTexCoord(s,s)
	glVertex(x+sx,y,z+sz)

	glTexCoord(s,0)
	glVertex(x+sx,y,z-sz)

end

local function drawMSpot(x,y,z,weight)
	
	glPushAttrib(GL.ALL_ATTRIB_BITS)
	glDepthTest(false)
	glDepthMask(false)	
	glTexture(":a:luaui\\images\\metalSpot.png")-- Texture file	
	glColor(0.5,1,0.5,0.3)
	glBeginEnd(GL.QUADS,drawMSpotVertices,x,y,z)
	glTexture(false)
	glDepthMask(false)
	glDepthTest(false)	
	glPopAttrib()
	
	local wColorFactor = min(weight/refWeight,1.0) 
	draw3DText(weight,x,y,z+10,30,wColorFactor) 
end

local function highlightMex()
	local metalSpots = WG.metalSpots
	for i = 1, #metalSpots do
		local spot = metalSpots[i]
		drawMSpot(spot.x,spot.y+2,spot.z,string.format("%.2f",spot.worth))
	end
end



----------------------------------------------------------------
-- Callins
----------------------------------------------------------------
function widget:Shutdown()
	if geoDisplayList then
		gl.DeleteList(geoDisplayList)
	end
	if mexDisplayList then
		gl.DeleteList(mexDisplayList)
	end
end


function widget:DrawWorldPreUnit()  
	if spGetMapDrawMode() == 'metal' then
		if not mexDisplayList then
			mexDisplayList = gl.CreateList(highlightMex)
		end
		
		glPushAttrib(GL.ALL_ATTRIB_BITS)
		glCallList(mexDisplayList)
		glPopAttrib()
	end
end


function widget:DrawWorld()
	
	if spGetMapDrawMode() == 'metal' then
		if not geoDisplayList then
			geoDisplayList = gl.CreateList(highlightGeos)
		end
		
		glPushAttrib(GL.ALL_ATTRIB_BITS)
		glLineWidth(20)
		glDepthTest(true)
		glCallList(geoDisplayList)
		glLineWidth(1)
		glPopAttrib()
	end
end
