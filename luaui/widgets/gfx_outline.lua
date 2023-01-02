-- $Id: gfx_outline.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    gfx_outline.lua
--  brief:   Displays a nice cartoon like outline around units
--  author:  jK
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Outline",
    desc      = "Displays a nice cartoon like outline around units.",
    author    = "jK, modified by raaar",
    date      = "Dec 06, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = -10,
    enabled   = false
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--//textures
local offscreentex
local depthtex
local blurtex

--//shader
local depthShader
local blurShader_h
local blurShader_v
local uniformScreenXY, uniformScreenX, uniformScreenY

--// geometric
local vsx, vsy = 0,0
local resChanged = false

--// display lists
local enter2d,leave2d

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local GL_DEPTH_BITS = 0x0D56

local GL_DEPTH_COMPONENT   = 0x1902
local GL_DEPTH_COMPONENT16 = 0x81A5
local GL_DEPTH_COMPONENT24 = 0x81A6
local GL_DEPTH_COMPONENT32 = 0x81A7

--// speed ups
local ALL_UNITS       = Spring.ALL_UNITS
local spGetVisibleUnits = Spring.GetVisibleUnits
local spGetGameFrame = Spring.GetGameFrame
local spGetUnitViewPosition = Spring.GetUnitViewPosition 
local spGetCameraPosition = Spring.GetCameraPosition
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitHealth = Spring.GetUnitHealth
local spIsUnitInView = Spring.IsUnitInView 
local spIsUnitIcon = Spring.IsUnitIcon

local GL_MODELVIEW  = GL.MODELVIEW
local GL_PROJECTION = GL.PROJECTION
local GL_COLOR_BUFFER_BIT = GL.COLOR_BUFFER_BIT

local glUnit            = gl.Unit
local glCopyToTexture   = gl.CopyToTexture
local glRenderToTexture = gl.RenderToTexture
local glCallList        = gl.CallList

local glUseShader  = gl.UseShader
local glUniform    = gl.Uniform
local glUniformInt = gl.UniformInt

local glClear    = gl.Clear
local glTexRect  = gl.TexRect
local glColor    = gl.Color
local glTexture  = gl.Texture

local glResetMatrices = gl.ResetMatrices
local glMatrixMode    = gl.MatrixMode
local glPushMatrix    = gl.PushMatrix
local glLoadIdentity  = gl.LoadIdentity
local glPopMatrix     = gl.PopMatrix



local noOutlineUnitDefIds = {
	[UnitDefNames["sphere_magnetar"].id] = true,
	[UnitDefNames["cs_beacon"].id] = true,
	[UnitDefNames["scoper_beacon"].id] = true
}

local min = math.min
local outlinableUnitIds = {}

local OUTLINE_MIN_DISTANCE = 1000
local OUTLINE_MIN_SQDISTANCE = OUTLINE_MIN_DISTANCE * OUTLINE_MIN_DISTANCE



local function DrawVisibleUnits()
	local ux, uy, uz
	local dx, dy, dz, dist, distMod
	local cx,cy,cz = spGetCameraPosition()
	local bp
	local uId = 0
	local opacity
	for uId,data in pairs(outlinableUnitIds) do
		if not spIsUnitIcon(uId) and spIsUnitInView(uId) then
			opacity = 0.4

			ux, uy, uz = spGetUnitViewPosition(uId)
			if ux then
				_,_,_,_,bp = spGetUnitHealth(uId)
				dx, dy, dz = ux-cx, uy-cy, uz-cz
				dist = dx*dx + dy*dy + dz*dz
				distMod = (dist - 2*OUTLINE_MIN_SQDISTANCE) / OUTLINE_MIN_SQDISTANCE 
				
				if distMod > 0 then
					opacity = min(distMod,1) * opacity
					opacity = opacity * bp
				else
					opacity = 0
				end
				--Spring.Echo("unit "..UnitDefs[spGetUnitDefID(uId)].name.." distMod="..distMod.." opacity="..opacity)
	
				if opacity > 0 then
					glColor(0,0,0,opacity)
					glUnit(uId,true)
				end
			end
		end
	end
end

local MyDrawVisibleUnits = function()
  glClear(GL_COLOR_BUFFER_BIT,0,0,0,0)
  glPushMatrix()
  glResetMatrices()
  DrawVisibleUnits()
  glColor(1,1,1,1)
  glPopMatrix()
end

local blur_h = function()
  glClear(GL_COLOR_BUFFER_BIT,0,0,0,0)
  glUseShader(blurShader_h)
  glTexRect(-1-0.5/vsx,1+0.5/vsy,1+0.5/vsx,-1-0.5/vsy)
end

local blur_v = function()
  glClear(GL_COLOR_BUFFER_BIT,0,0,0,0)
  glUseShader(blurShader_v)
  glTexRect(-1-0.5/vsx,1+0.5/vsy,1+0.5/vsx,-1-0.5/vsy)
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	for _,unitID in ipairs(spGetVisibleUnits()) do
		widget:UnitCreated(unitID,spGetUnitDefID(unitID))
	end

  vsx, vsy = widgetHandler:GetViewSizes()

  depthShader = gl.CreateShader({
    fragment = [[
      uniform sampler2D tex0;
      uniform vec2 screenXY;

      void main(void)
      {
        vec2 texCoord = vec2( gl_FragCoord.x/screenXY.x , gl_FragCoord.y/screenXY.y );
        float depth  = texture2D(tex0, texCoord ).z;

        if (depth <= gl_FragCoord.z) {
          discard;
        }
        gl_FragColor = gl_Color;
      }
    ]],
    uniformInt = {
      tex0 = 0,
    },
    uniform = {
      screenXY = {vsx,vsy},
    },
  })

  blurShader_h = gl.CreateShader({
    fragment = [[
      uniform sampler2D tex0;
      uniform int screenX;

      const vec2 kernel = vec2(0.6,0.7);

      void main(void) {
        vec2 texCoord  = vec2(gl_TextureMatrix[0] * gl_TexCoord[0]);
        gl_FragColor = vec4(0.0);

        int i;
        int n = 1;
        float pixelsize = 1.0/float(screenX);
        for(i = 1; i < 3; ++i){
          gl_FragColor += kernel[n] * texture2D(tex0, vec2(texCoord.s + i*pixelsize,texCoord.t) );
          --n;
        }

        gl_FragColor += texture2D(tex0, texCoord );

        n = 0;
        for(i = -2; i < 0; ++i){
          gl_FragColor += kernel[n] * texture2D(tex0, vec2(texCoord.s + i*pixelsize,texCoord.t) );
          ++n;
        }
      }
    ]],
    uniformInt = {
      tex0 = 0,
      screenX = vsx,
    },
  })


  blurShader_v = gl.CreateShader({
    fragment = [[      uniform sampler2D tex0;
      uniform int screenY;

      const vec2 kernel = vec2(0.6,0.7);

      void main(void) {
        vec2 texCoord  = vec2(gl_TextureMatrix[0] * gl_TexCoord[0]);
        gl_FragColor = vec4(0.0);

        int i;
        int n = 1;
        float pixelsize = 1.0/float(screenY);
        for(i = 0; i < 2; ++i){
          gl_FragColor += kernel[n] * texture2D(tex0, vec2(texCoord.s,texCoord.t + i*pixelsize) );
          --n;
        }

        gl_FragColor += texture2D(tex0, texCoord );

        n = 0;
        for(i = -2; i < 0; ++i){
          gl_FragColor += kernel[n] * texture2D(tex0, vec2(texCoord.s,texCoord.t + i*pixelsize) );
          ++n;
        }
      }
    ]],
    uniformInt = {
      tex0 = 0,
      screenY = vsy,
    },
  })

  if (depthShader == nil) then
    Spring.Echo("Halo widget: depthcheck shader error: "..gl.GetShaderLog())
    widgetHandler:RemoveWidget()
    return false
  end
  if (blurShader_h == nil) then
    Spring.Echo("Halo widget: hblur shader error: "..gl.GetShaderLog())
    widgetHandler:RemoveWidget()
    return false
  end
  if (blurShader_v == nil) then
    Spring.Echo("Halo widget: vblur shader error: "..gl.GetShaderLog())
    widgetHandler:RemoveWidget()
    return false
  end

  uniformScreenXY = gl.GetUniformLocation(depthShader,  'screenXY')
  uniformScreenX  = gl.GetUniformLocation(blurShader_h, 'screenX')
  uniformScreenY  = gl.GetUniformLocation(blurShader_v, 'screenY')

  self:ViewResize(widgetHandler:GetViewSizes())

  enter2d = gl.CreateList(function()
    glUseShader(0)
    glMatrixMode(GL_PROJECTION); glPushMatrix(); glLoadIdentity()
    glMatrixMode(GL_MODELVIEW);  glPushMatrix(); glLoadIdentity()
  end)
  leave2d = gl.CreateList(function()
    glMatrixMode(GL_PROJECTION); glPopMatrix()
    glMatrixMode(GL_MODELVIEW);  glPopMatrix()
    glTexture(false)
    glUseShader(0)
  end)
end

function widget:ViewResize(viewSizeX, viewSizeY)
  vsx = viewSizeX
  vsy = viewSizeY

  gl.DeleteTexture(depthtex or 0)
  gl.DeleteTextureFBO(offscreentex or 0)
  gl.DeleteTextureFBO(blurtex or 0)

  depthtex = gl.CreateTexture(vsx,vsy, {
    border = false,
    format = GL_DEPTH_COMPONENT24,
    min_filter = GL.NEAREST,
    mag_filter = GL.NEAREST,
  })

  offscreentex = gl.CreateTexture(vsx,vsy, {
    border = false,
    min_filter = GL.LINEAR,
    mag_filter = GL.LINEAR,
    wrap_s = GL.CLAMP,
    wrap_t = GL.CLAMP,
    fbo = true,
    fboDepth = true,
  })

  blurtex = gl.CreateTexture(vsx,vsy, {
    border = false,
    min_filter = GL.LINEAR,
    mag_filter = GL.LINEAR,
    wrap_s = GL.CLAMP,
    wrap_t = GL.CLAMP,
    fbo = true,
  })

  resChanged = true
end


function widget:Shutdown()
  gl.DeleteTexture(depthtex)
  if (gl.DeleteTextureFBO) then
    gl.DeleteTextureFBO(offscreentex)
    gl.DeleteTextureFBO(blurtex)
  end

  if (gl.DeleteShader) then
    gl.DeleteShader(depthShader or 0)
    gl.DeleteShader(blurShader_h or 0)
    gl.DeleteShader(blurShader_v or 0)
  end

  gl.DeleteList(enter2d)
  gl.DeleteList(leave2d)
end


function widget:DrawWorldPreUnit()
  glCopyToTexture(depthtex, 0, 0, 0, 0, vsx, vsy)
  glTexture(depthtex)

  if (resChanged) then
    resChanged = false
    if (vsx==1) or (vsy==1) then return end
    glUseShader(depthShader)
    glUniform(uniformScreenXY,   vsx,vsy )
    glUseShader(blurShader_h)
    glUniformInt(uniformScreenX, vsx )
    glUseShader(blurShader_v)
    glUniformInt(uniformScreenY, vsy )
  end

  glUseShader(depthShader)
  glRenderToTexture(offscreentex,MyDrawVisibleUnits)

  glTexture(offscreentex)
  glRenderToTexture(blurtex, blur_h)
  glTexture(blurtex)
  glRenderToTexture(offscreentex, blur_v)

  glCallList(enter2d)
  glTexture(offscreentex)
  glTexRect(-1-0.5/vsx,1+0.5/vsy,1+0.5/vsx,-1-0.5/vsy)
  glCallList(leave2d)
end


function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	outlinableUnitIds[unitID] = nil
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	if not noOutlineUnitDefIds[unitDefID] then
		outlinableUnitIds[unitID] = true
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------