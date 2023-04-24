function widget:GetInfo()
	return {
		name      = "Power Grid UI",
		desc      = "Handles UI related to the power grid.",
		author    = "raaar",
		date      = "2022",
		license   = "PD",
		layer     = 0,
		enabled   = true
	}
end

local spGetActiveCommand = Spring.GetActiveCommand
local spGetBuildSpacing = Spring.GetBuildSpacing
local spSetBuildSpacing = Spring.SetBuildSpacing
local spGetCommandQueue = Spring.GetCommandQueue
local spIsAboveMiniMap = Spring.IsAboveMiniMap
local spTraceScreenRay = Spring.TraceScreenRay
local spGetSelectedUnits = Spring.GetSelectedUnits
local spFindUnitCmdDesc = Spring.FindUnitCmdDesc
local spGetMouseState = Spring.GetMouseState 
local spGetTimer = Spring.GetTimer
local spDiffTimers = Spring.DiffTimers
local spGetVisibleUnits = Spring.GetVisibleUnits
local spGetAllUnits = Spring.GetAllUnits
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spGetGroundHeight = Spring.GetGroundHeight
local spGetSelectedUnitsCount = Spring.GetSelectedUnitsCount
local spGetUnitAllyTeam = Spring.GetUnitAllyTeam
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitPosition = Spring.GetUnitPosition
local spGetMyAllyTeamID = Spring.GetMyAllyTeamID
local spGetGameFrame = Spring.GetGameFrame
local spGetSpectatingState = Spring.GetSpectatingState

VFS.Include("lualibs/util.lua")

local sqrt = math.sqrt
local acos = math.acos
local atan = math.atan
local floor = math.floor
local cos = math.cos
local pi = math.pi
local abs = math.abs
local min    = math.min
local max    = math.max
local sin    = math.sin

local oldSpacing = nil
local spacingOverridden = false

powerNodeCmdNames = {
	aven_power_node = true,
	gear_power_node = true,
	claw_power_node = true,
	sphere_power_node = true
}

local NODE_SPACING = math.floor(480/16)		--- a bit smaller than the node connection radius


local mxClick=0
local myClick=0
local inMinimapClick = false
local posClick = nil


local circlesToDraw = {}
local NODE_OVERLAY_RADIUS = 508
local selectedUId = 0
local selectedGridId = nil
local forceRefresh = false
local isBuildingPowerNode = false

local gridColorByLevel = {
	[0] = {0.2,0.2,0.2,1},
	[1] = {0.6,0.2,0.2,1},
	[2] = {0.8,0.6,0.2,1},
	[3] = {1.0,1.0,0.2,1},
	[4] = {0.9,0.9,0.9,1},
	[5] = {0.8,0.8,1.0,1}
}


local TWO_PI = math.pi * 2

local glVertex = gl.Vertex
local glCreateList = gl.CreateList
local glDeleteList = gl.DeleteList
local glCallList = gl.CallList
local glDepthMask = gl.DepthMask
local glCulling = gl.Culling
local glStencilTest = gl.StencilTest
local glDepthClamp = gl.DepthClamp
local glColor = gl.Color
local glColorMask = gl.ColorMask
local glStencilOp = gl.StencilOp
local glStencilMask = gl.StencilMask
local glStencilFunc = gl.StencilFunc
local glDepthTest = gl.DepthTest
local glColorMask = gl.ColorMask
local glBeginEnd = gl.BeginEnd
local glPushMatrix = gl.PushMatrix
local glTranslate = gl.Translate
local glScale = gl.Scale
local glPopMatrix = gl.PopMatrix

GL.KEEP      = 0x1E00
GL.INCR_WRAP = 0x8507
GL.DECR_WRAP = 0x8508
GL.INCR      = 0x1E02
GL.DECR      = 0x1E03
GL.INVERT    = 0x150A

local stencilBit1 = 0x01
local stencilBit2 = 0x10

local heightMargin = 2000
local minheight, maxheight = Spring.GetGroundExtremes()  --the returned values do not change even if we terraform the map
local averageGroundHeight = (minheight + maxheight) / 2
local shapeHeight = heightMargin + (maxheight - minheight) + heightMargin


-- Make sure that you start with a clear stencil and that you
-- clear it using gl.Clear(GL.STENCIL_BUFFER_BIT, 0)
-- after finishing all the merged volumes
function glDrawMergedVolume(vol_dlist)
	glDepthMask(false)
	if (glDepthClamp) then glDepthClamp(true) end
	glStencilTest(true)
	glCulling(false)
	glDepthTest(true)
	glColorMask(false, false, false, false)
	glStencilOp(GL.KEEP, GL.INVERT, GL.KEEP)
	--gl.StencilOp(GL.KEEP, GL.INVERT, GL.KEEP)
	glStencilMask(1)
	glStencilFunc(GL.ALWAYS, 0, 1)
	
	glCallList(vol_dlist)
	
	glCulling(GL.FRONT)
	glDepthTest(false)
	glColorMask(true, true, true, true)
	glStencilOp(GL.KEEP, GL.INCR, GL.INCR)
	glStencilMask(3)
	glStencilFunc(GL.EQUAL, 1, 3)
	
	glCallList(vol_dlist)
	
	if (glDepthClamp) then glDepthClamp(false) end
	glStencilTest(false)
	-- gl.DepthTest(true)
	glCulling(false)
end


local function createSinCosTable(divs)
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


function glDrawMyCylinder(x,y,z, height,radius,divs)
	divs = divs or 25
	local sinTable, cosTable = createSinCosTable(divs)
	local bottomY = y - (height / 2)
	local topY    = y + (height / 2)

	glBeginEnd(GL.TRIANGLE_STRIP, function()
		--// top
		for i = #sinTable, 1, -1 do
			glVertex(x + radius*sinTable[i], topY, z + radius*cosTable[i])
			glVertex(x, topY, z)
		end

		--// degenerate
		glVertex(x, topY   , z)
		glVertex(x, bottomY, z)
		glVertex(x, bottomY, z)

		--// bottom
		for i = #sinTable, 1, -1 do
			glVertex(x + radius*sinTable[i], bottomY, z + radius*cosTable[i])
			glVertex(x, bottomY, z)
		end

		--// degenerate
		glVertex(x, bottomY, z)
		glVertex(x, bottomY, z+radius)
		glVertex(x, bottomY, z+radius)
		
		--// sides
		for i = 1, #sinTable do
			local rx = x + radius * sinTable[i]
			local rz = z + radius * cosTable[i]
			glVertex(rx, topY   , rz)
			glVertex(rx, bottomY, rz)
		end
	end)
end

local cylinder = glCreateList(glDrawMyCylinder,0,0,0,1,1,35)

function glDrawMergedGroundCircle(x,z,radius)
	glPushMatrix()
	--gl.Translate(x, averageGroundHeight, z)
	glTranslate(x, averageGroundHeight, z)
	glScale(radius, shapeHeight, radius)
	glDrawMergedVolume(cylinder)
	glPopMatrix()
end



----------------------------- callins


function widget:MousePress(mx, my, mButton)
	mxClick=mx
	myClick=my
	inMinimapClick = spIsAboveMiniMap(mx, my)
	--Spring.Echo("mclick x="..mx.." y="..my)
	_, posClick = spTraceScreenRay(mxClick, myClick, true, inMinimap)
end

function widget:MouseRelease(mx, my, mButton)
	posClick = nil
end
	
function widget:Update()
	local idx,cmdId,cmdType,cmdName = spGetActiveCommand()
	local myAllyId = spGetMyAllyTeamID() 
	
	-- building a power node, set spacing
	local pNCmdSet  = powerNodeCmdNames[cmdName]
	if isBuildingPowerNode ~= pNCmdSet then
		isBuildingPowerNode = pNCmdSet
		forceRefresh = true
	end
	
	if isBuildingPowerNode then
		if not spacingOverridden then
			oldSpacing = spGetBuildSpacing()
			--Spring.Echo("spacing was "..oldSpacing)
			spSetBuildSpacing(NODE_SPACING)
			spacingOverridden = true
		else
			-- spacing already overridden, but the spacing setting is square and the 
			-- user wants it to fit the node radius which requires further adjustments 
			local mx,my = spGetMouseState()
			local inMinimap = spIsAboveMiniMap(mx, my)
			local _, pos = spTraceScreenRay(mx, my, true, inMinimap)
			if pos and posClick then
				local px = posClick[1]
				local pz = posClick[3]
				local tx = pos[1]
				local tz = pos[3]
				local dx = tx - px
				local dz = tz - pz
				local hypot = sqrt(dx*dx+dz*dz)
				dx = dx/hypot
				dz = dz/hypot
				if dx ~= 0 and dz ~= 0 then
					local angle = abs(atan(dz/dx))
					if angle > pi / 4 then
						angle = abs(angle - pi/2)	
					end
					local newSpacing = floor(cos(angle) * NODE_SPACING)-1
					--Spring.Echo("dx="..dx.." dz="..dz.." angle="..(angle*180/pi))
					spSetBuildSpacing(newSpacing)
				end
			end
		end
	elseif spacingOverridden then
		spSetBuildSpacing(oldSpacing)
		spacingOverridden = false
	end
	
	
	-- check unit selection, update drawlist for power grid overlay
	circlesToDraw = {}
	local gridId = nil
	local allyId = nil
	if spGetSelectedUnitsCount() >= 1 then
		--Spring.Echo(spGetGameFrame().." selected 1 unit")
		local units = spGetSelectedUnits()
		for _,uId in ipairs(units) do
			local ud = UnitDefs[Spring.GetUnitDefID(uId)]
			allyId = spGetUnitAllyTeam(uId)
			if ud and ud.customParams and ud.customParams.powergridnode == "1" then
				gridId = spGetUnitRulesParam(uId,"powerGridId")
				break
			end
		end
	end  
	if gridId ~= selectedGridId or allyId ~= selectedAllyId then
		selectedGridId = gridId
		selectedAllyId = allyId
		forceRefresh = true
	end

	if isBuildingPowerNode or selectedGridId then
		local spec, fullSpec = spGetSpectatingState()
		local ud2,px,py,pz,gridId2,gridLevel2,refColor,color,highlight,allyId2
		local units = spGetAllUnits()
		local circleList = {} 
		for _,uId2 in ipairs(units) do
		 	ud2 = UnitDefs[spGetUnitDefID(uId2)]
		 	if ud2 and ud2.customParams and ud2.customParams.powergridnode == "1" then
				allyId2 = spGetUnitAllyTeam(uId2)
				if (selectedAllyId and allyId2 == selectedAllyId) or (allyId2 == myAllyId) or spec then
					gridId2 = spGetUnitRulesParam(uId2,"powerGridId")
					local gridStrength2 = spGetUnitRulesParam(uId2,"powerGridStrength")
					--local totalExtractionMult2 = spGetUnitRulesParam(uId2,"powerGridTotalExtractionMult")
					--local extractionBonus2 = spGetUnitRulesParam(uId2,"powerGridExtractionBonus")
					gridLevel2 = spGetUnitRulesParam(uId2,"powerGridLevel")
					px,py,pz = spGetUnitPosition(uId2)
					if gridId2 and gridId2 > 0 then
						refColor = gridColorByLevel[gridLevel2]
						color = {refColor[1],refColor[2],refColor[3],refColor[4]}
						highlight = (selectedGridId and gridId2 == selectedGridId and selectedAllyId and selectedAllyId == allyId2) and 1 or 0
						if highlight == 1 then
							color[4] = 0.4
						else
							color[4] = 0.2
						end
						circleList[#circleList+1]={uId=uId2,hl=highlight,str=gridStrength2,x=px,y=spGetGroundHeight(px,pz),z=pz,color=color, radius = NODE_OVERLAY_RADIUS}
					end
				end
		 	end
		end
		
		-- sort image list by highlight and grid strength
		for _, c in spairs(circleList, function(t,a,b) 
			local check = 0
			if t[b].hl ~= t[a].hl then
				check = t[b].hl - t[a].hl
			elseif t[b].str ~= t[a].str then
				check = t[b].str - t[a].str
			end
			
			return check < 0
		end) do
			circlesToDraw[#circlesToDraw+1] = c 
		end
	end
end

local glList = nil
local glListRefreshIdx = -1
local refTimer = spGetTimer()
function widget:DrawWorldPreUnit()
	local refreshIdx = floor(spDiffTimers(spGetTimer(),refTimer)*1)
	-- refresh gl list only once per second
	if (not glList) or refreshIdx ~= glListRefreshIdx or forceRefresh then
		forceRefresh = false
		if (glList) then
			glDeleteList(glList)
		end 
		glList = glCreateList(function()
			for i,c in ipairs(circlesToDraw) do
				glColor(c.color)
				--Spring.Echo("drawing "..i.." uId="..tostring(c.uId).." hl="..tostring(c.hl).." str="..tostring(c.str))
				glDrawMergedGroundCircle(c.x,c.z,c.radius)
			end
		end)
		glListRefreshIdx = refreshIdx
	end
	glCallList(glList)
	gl.Clear(GL.STENCIL_BUFFER_BIT, 0)
end
