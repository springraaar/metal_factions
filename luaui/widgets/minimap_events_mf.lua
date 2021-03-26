function widget:GetInfo()
  return {
    name      = "Minimap Events (MF version)",
    desc      = "Display ally events and battle damages in the minimap",
    author    = "raaar, based on widget by trepan",
    date      = "2019",
    license   = "PD",
    layer     = 999999,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local GL_LINE_LOOP           = GL.LINE_LOOP
local GL_ONE                 = GL.ONE
local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA
local GL_POINTS              = GL.POINTS
local GL_QUADS               = GL.QUADS
local GL_SRC_ALPHA           = GL.SRC_ALPHA
local GL_TRIANGLE_FAN        = GL.TRIANGLE_FAN
local glBeginEnd             = gl.BeginEnd
local glBlending             = gl.Blending
local glCallList             = gl.CallList
local glColor                = gl.Color
local glCreateList           = gl.CreateList
local glDeleteList           = gl.DeleteList
local glLineWidth            = gl.LineWidth
local glLoadIdentity         = gl.LoadIdentity
local glPopMatrix            = gl.PopMatrix
local glPushMatrix           = gl.PushMatrix
local glRotate               = gl.Rotate
local glScale                = gl.Scale
local glSmoothing            = gl.Smoothing
local glTexCoord             = gl.TexCoord
local glTranslate            = gl.Translate
local glVertex               = gl.Vertex
local spGetFrameTimeOffset   = Spring.GetFrameTimeOffset
local spGetGameSeconds       = Spring.GetGameSeconds
local spGetUnitPosition      = Spring.GetUnitPosition
local spGetUnitViewPosition  = Spring.GetUnitViewPosition
local spIsUnitAllied         = Spring.IsUnitAllied
local spGetGameFrame         = Spring.GetGameFrame

local floor = math.floor

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local xMapSize = Game.mapX * 512
local yMapSize = Game.mapY * 512
local pxScale = 1  -- (xMapSize / minimap xPixels)
local pyScale = 1  -- (yMapSize / minimap yPixels)


local lineWidth = 2  -- set to 0 to remove outlines
local circleDivs = 16
local circleList = 0
local alpha = 0.2
local damageColor    = { 1.0, 0.2, 0.0, alpha }

local EVENT_DURATION_FRAMES = 45
local damageEvents = {}
local lastDamageEventZones = {}
local REDUNDANT_EVENT_FRAMES = 30
local zx = 0
local zz = 0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()

  circleList = glCreateList(function()
    glBeginEnd(GL_TRIANGLE_FAN, function()
      for i = 0, circleDivs - 1 do
        local r = 2.0 * math.pi * (i / circleDivs)
        local cosv = math.cos(r)
        local sinv = math.sin(r)
        glTexCoord(cosv, sinv)
        glVertex(cosv, 0, sinv)
      end
    end)
    if (lineWidth > 0) then
      glBeginEnd(GL_LINE_LOOP, function()
        for i = 0, circleDivs - 1 do
          local r = 2.0 * math.pi * (i / circleDivs)
          local cosv = math.cos(r)
          local sinv = math.sin(r)
          glTexCoord(cosv, sinv)
          glVertex(cosv, 0, sinv)
        end
      end)
    end
  end)
end


function widget:Shutdown()
  glDeleteList(circleList)
end

function widget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer)
	if (not spIsUnitAllied(unitID)) then
		return
	end
	if (damage <= 0) then
		return
	end
	
	local ud = UnitDefs[unitDefID]
	if (ud == nil) then
		return
	end

	local px,py,pz = spGetUnitPosition(unitID)
	if (px) then
		local f = spGetGameFrame()
		zx=floor(px/256)
		zz=floor(pz/256)
		
		local idx = zx.."_"..zz
		local oldFrame = lastDamageEventZones[idx]
		
		-- roughly filter out redundant events
		if (not oldFrame or f - oldFrame > REDUNDANT_EVENT_FRAMES) then
			table.insert(damageEvents,{px=px,pz=pz,f=f})
			lastDamageEventZones[idx] = f
		end
	end
end

function widget:DrawInMiniMap(xSize, ySize)
	if (next(damageEvents)  == nil) then
		return
	end
--  glSmoothing(false, false, false)
--  glBlending(GL_SRC_ALPHA, GL_ONE)
	glLineWidth(lineWidth)

	-- setup the pixel scales
	pxScale = xMapSize / xSize
	pyScale = yMapSize / ySize

	glPushMatrix()

	glLoadIdentity()
	glTranslate(0, 1, 0)
	glScale(1 / xMapSize, 1 / yMapSize, 1)
	glRotate(90, 1, 0, 0)

	local currentFrame = spGetGameFrame()
	local px,pz,f,scale
	for i,ev in pairs(damageEvents) do
	    px = ev.px
	    pz = ev.pz
	    f = ev.f
    
		scale = 20 * (1 - (currentFrame - f) / EVENT_DURATION_FRAMES) 
    
		if (scale > 1) then
    		--Spring.Echo("px="..px.." pz="..pz.." scale="..tonumber(scale))
			glColor(damageColor)
			glPushMatrix()
			glTranslate(px, 0, pz)
			glScale(scale*pxScale, 1, scale*pyScale)
			glCallList(circleList)
			glPopMatrix()
		else
			damageEvents[i] = nil
		end
	end


	glPopMatrix()
	glLineWidth(1)
	glColor(1,1,1,1)
--  glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
--  glSmoothing(true, true, false)
end

function widget:GameFrame(f)
	-- every few seconds, remove expired per-zone damage event entries
	if (f%176 == 0) then
		for idx,ef in pairs(lastDamageEventZones) do
			if (f - ef > REDUNDANT_EVENT_FRAMES) then
				--Spring.Echo("expired dmg event at "..idx)
				lastDamageEventZones[idx] = nil
			end
		end
	end
end 

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
