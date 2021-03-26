local versionNumber = "v1.9d"

function widget:GetInfo()
	return {
		name = "Prospector",
		desc = versionNumber .. " Tooltip for amount of metal extracted when placing metal extractors.",
		author = "Evil4Zerggin, modified by raaar",
		date = "9 January 2009",
		license = "GNU LGPL, v2.1 or later",
		layer = 1,
		enabled = true
	}
end

local textSize = 15

-- EDIT 2013/03/17 by raaar: no longer loads info from unitDef.extractSquare as it was removed in spring 93.1

------------------------------------------------
--speedups
------------------------------------------------
local GetActiveCommand = Spring.GetActiveCommand
local GetMouseState = Spring.GetMouseState
local TraceScreenRay = Spring.TraceScreenRay
local GetGroundInfo = Spring.GetGroundInfo
local GetGameFrame = Spring.GetGameFrame
local GetMapDrawMode = Spring.GetMapDrawMode

local glLineWidth = gl.LineWidth
local glColor = gl.Color
local glRect = gl.Rect
local glText = gl.Text
local glGetTextWidth = gl.GetTextWidth
local glPolygonMode = gl.PolygonMode
local glDrawGroundCircle = gl.DrawGroundCircle
local glUnitShape = gl.UnitShape

local glPopMatrix = gl.PopMatrix
local glPushMatrix = gl.PushMatrix
local glTranslate = gl.Translate

local GL_FRONT_AND_BACK = GL.FRONT_AND_BACK
local GL_FILL = GL.FILL

local floor = math.floor
local min, max = math.min, math.max
local sqrt = math.sqrt
local strFind = string.find
local strFormat = string.format

------------------------------------------------
--vars
------------------------------------------------

--unitDefID = {extractsMetal, extractSquare, oddX, oddZ}
local mexDefInfos = {}
local defaultDefID

local centerX, centerZ
local extraction = 0
local lastUnitDefID

local TEXT_CORRECT_Y = 1.25

local myTeamID
local METAL_MAP_SQUARE_SIZE = 16
local MEX_RADIUS = Game.extractorRadius
local MAP_SIZE_X = Game.mapSizeX
local MAP_SIZE_X_SCALED = MAP_SIZE_X / METAL_MAP_SQUARE_SIZE
local MAP_SIZE_Z = Game.mapSizeZ
local MAP_SIZE_Z_SCALED = MAP_SIZE_Z / METAL_MAP_SQUARE_SIZE

local ADVANCED_EXTRACTOR_RADIUS_FACTOR = 1.3 
local MIN_EXTRACTOR_RADIUS = 32
local ADV_MEX_RADIUS = MEX_RADIUS >= MIN_EXTRACTOR_RADIUS and (MEX_RADIUS*ADVANCED_EXTRACTOR_RADIUS_FACTOR) or (MIN_EXTRACTOR_RADIUS*ADVANCED_EXTRACTOR_RADIUS_FACTOR) 


local advMexDefIds = {
	[UnitDefNames['aven_moho_mine'].id] = true,
	[UnitDefNames['gear_moho_mine'].id] = true,
	[UnitDefNames['claw_moho_mine'].id] = true,
	[UnitDefNames['sphere_moho_mine'].id] = true,
	[UnitDefNames['aven_exploiter'].id] = true,
	[UnitDefNames['gear_exploiter'].id] = true,
	[UnitDefNames['claw_exploiter'].id] = true,
	[UnitDefNames['sphere_exploiter'].id] = true
}


------------------------------------------------
--H4X
------------------------------------------------
local once		   -- used to get the view sizes only once, because of reasons

------------------------------------------------
--helpers
------------------------------------------------

-- draw the info panel
local function DrawTextWithBackground(text, x, y, size, opt)
	local width = (glGetTextWidth(text) * size) + 8
	glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)
	
	glColor(0.0, 0.0, 0.0, 0.75)
	if (opt) then
		if (strFind(opt, "r")) then
			glRect(x, y, x - width, y + size * TEXT_CORRECT_Y)
		elseif (strFind(opt, "c")) then
			glRect(x + width * 0.5, y, x - width * 0.5, y + size * TEXT_CORRECT_Y)
		else
			glRect(x, y, x + width, y + size * TEXT_CORRECT_Y)
		end
	else
		glRect(x, y, x + width, y + size * TEXT_CORRECT_Y)
	end
	
	glColor(1, 1, 1, 0.85)
	
	glText(text, x+4, y, size, opt)
	
end

-- figure out which units are metal extractors
local function SetupMexDefInfos() 
	local minExtractsMetal = 0
	
	defaultDefID = UnitDefNames["aven_metal_extractor"].id
	
	for unitDefID = 1,#UnitDefs do
		local unitDef = UnitDefs[unitDefID]
		local extractsMetal = unitDef.extractsMetal
		if (extractsMetal > 0) then
			mexDefInfos[unitDefID] = {}
			mexDefInfos[unitDefID][1] = extractsMetal
			mexDefInfos[unitDefID][2] = advMexDefIds[unitDefID]
			if (unitDef.xsize % 4 == 2) then
				mexDefInfos[unitDefID][3] = true
			end
			if (unitDef.zsize % 4 == 2) then
				mexDefInfos[unitDefID][4] = true
			end
			if not minExtractsMetal or extractsMetal < minExtractsMetal then
				defaultDefID = unitDefID
				minExtractsMetal = extractsMetal
			end
		end
	end
	
end

-- compute metal income per second for a given extractor and position
local function IntegrateMetal(mexDefInfo, x, z, forceUpdate)
	local newCenterX, newCenterZ
	
	if (mexDefInfo[3]) then
		newCenterX = (floor( x / METAL_MAP_SQUARE_SIZE) + 0.5) * METAL_MAP_SQUARE_SIZE
	else
		newCenterX = floor( x / METAL_MAP_SQUARE_SIZE + 0.5) * METAL_MAP_SQUARE_SIZE
	end
	
	if (mexDefInfo[4]) then
		newCenterZ = (floor( z / METAL_MAP_SQUARE_SIZE) + 0.5) * METAL_MAP_SQUARE_SIZE
	else
		newCenterZ = floor( z / METAL_MAP_SQUARE_SIZE + 0.5) * METAL_MAP_SQUARE_SIZE
	end
	
	if (centerX == newCenterX and centerZ == newCenterZ and not forceUpdate) then return end
	
	centerX = newCenterX
	centerZ = newCenterZ
	
	local startX = floor((centerX - MEX_RADIUS) / METAL_MAP_SQUARE_SIZE)
	local startZ = floor((centerZ - MEX_RADIUS) / METAL_MAP_SQUARE_SIZE)
	local endX = floor((centerX + MEX_RADIUS) / METAL_MAP_SQUARE_SIZE)
	local endZ = floor((centerZ + MEX_RADIUS) / METAL_MAP_SQUARE_SIZE)
	startX, startZ = max(startX, 0), max(startZ, 0)
	endX, endZ = min(endX, MAP_SIZE_X_SCALED - 1), min(endZ, MAP_SIZE_Z_SCALED - 1)
	
	local mult = mexDefInfo[1]
	local radius = mexDefInfo[2] and ADV_MEX_RADIUS or MEX_RADIUS
	local result = 0
	
	for i = startX, endX do
		for j = startZ, endZ do
			local cx, cz = (i + 0.5) * METAL_MAP_SQUARE_SIZE, (j + 0.5) * METAL_MAP_SQUARE_SIZE
			local dx, dz = cx - centerX, cz - centerZ
			local dist = sqrt(dx * dx + dz * dz)
			
			if (dist < radius) then
				local _,_, metal = GetGroundInfo(cx, cz)
				result = result + metal
			end
		end
	end
	
	extraction = result * mult
end


------------------------------------------------
--callins
------------------------------------------------

function widget:Initialize()
	SetupMexDefInfos() 
	myTeamID = Spring.GetMyTeamID()
	once = true
end

function widget:DrawScreen()
  if (once) then
		local viewSizeX, viewSizeY = widgetHandler:GetViewSizes()
		once = false
	end
	
	local mexDefInfo
	
	if GetGameFrame() < 1 then
		local drawMode = GetMapDrawMode()
		if drawMode == "metal" then
			mexDefInfo = mexDefInfos[defaultDefID]
		end
	else
		local _, cmd_id = GetActiveCommand()
		if (not cmd_id) then return end
		local unitDefID = -cmd_id
		local forceUpdate = false
		if (unitDefID ~= lastUnitDefID) then 
			forceUpdate = true
		end
		lastUnitDefID = unitDefID
		mexDefInfo = mexDefInfos[unitDefID]
	end
	
	if (not mexDefInfo) then return end
	
	local mx, my = GetMouseState()
	local _, coords = TraceScreenRay(mx, my, true, true)
	
	if (not coords) then return end

	IntegrateMetal(mexDefInfo, coords[1], coords[3], forceUpdate)

	-- draw info panel
	DrawTextWithBackground("\255\255\255\255Metal extraction: " .. strFormat("%.2f", extraction), mx, my, textSize)
	glColor(1, 1, 1, 1)
end

