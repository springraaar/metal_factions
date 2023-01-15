-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

local ShieldSphereParticle = {}
ShieldSphereParticle.__index = ShieldSphereParticle

local sphereList
local shieldShader

local sin = math.sin
local cos = math.cos
local random = math.random
local COLOR_SHIFT_WEIGHT = 0.1

local SPHERE_DETAIL = 60

local spGetUnitShieldState = Spring.GetUnitShieldState 

local glDeleteTexture = gl.DeleteTexture
local glDeleteList = gl.DeleteList
local glCreateList = gl.CreateList

local glTexture = gl.Texture
local glColor = gl.Color
local glCulling = gl.Culling
local glTexCoord = gl.TexCoord
local glPushMatrix = gl.PushMatrix
local glPopMatrix = gl.PopMatrix
local glTranslate = gl.Translate
local glScale = gl.Scale
local glMatrixMode = gl.MatrixMode
local glTexGen = gl.TexGen

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

function ShieldSphereParticle.GetInfo()
  return {
    name      = "ShieldSphere",
    backup    = "", --// backup class, if this class doesn't work (old cards,ati's,etc.)
    desc      = "",

    layer     = -23, --// extreme simply z-ordering :x

    --// gfx requirement
    fbo       = false,
    shader    = true,
    rtt       = false,
    ctt       = false,
  }
end

ShieldSphereParticle.Default = {
  pos        = {0,0,0}, -- start pos
  layer      = -24,

  life       = 0,

  size       = 0,
  innerSize = 0,
  sizeGrowth = 0,

  margin     = 1,

  color  = { {0, 0, 0, 0} },
  goodColor  = { {0, 0, 0, 0} },
  badColor  = { {0, 0, 0, 0} },

  texture = "bitmaps/shield.png",
  shieldCurrent = 0,
  shieldMax = 1000,
  hitStrength = 0,
  uId = 0,
  repeatEffect = false,
}


function getHealthColor(goodColor, badColor, healthFraction, hitStrength)
	return {(healthFraction+3*hitStrength)*goodColor[1] +(1-healthFraction)*badColor[1],(healthFraction+3*hitStrength)*goodColor[2] +(1-healthFraction)*badColor[2],(healthFraction+3*hitStrength)*goodColor[3] +(1-healthFraction)*badColor[3],0.5*((healthFraction+3*hitStrength)*goodColor[4] +(1-healthFraction)*badColor[4])}
end

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

local glMultiTexCoord = gl.MultiTexCoord
local glCallList = gl.CallList

function ShieldSphereParticle:BeginDraw()
	gl.UseShader(shieldShader)
	glCulling(false)
end

function ShieldSphereParticle:EndDraw()
	glTexture(false)
	gl.UseShader(0)
	glColor(1,1,1,1)
	glMultiTexCoord(1, 1,1,1,1)
	glMultiTexCoord(2, 1,1,1,1)
	glMultiTexCoord(3, 1,1,1,1)
	glMultiTexCoord(4, 1,1,1,1)
	glCulling(false)
end


function ShieldSphereParticle:Draw()
	local color = self.color
	
	-- INNER SPHERE
	glMultiTexCoord(1, color[1],color[2],color[3],color[4]*0.5)
	glMultiTexCoord(2, color[1],color[2],color[3],color[4]*0.1)
	local pos = self.pos
	glMultiTexCoord(3, pos[1],pos[2],pos[3], 0)
	glMultiTexCoord(4, self.margin, self.innerSize, 1, 1)
	glCallList(sphereList)

	-- OUTER SPHERE
	glMultiTexCoord(1, color[1],color[2],color[3],color[4]*0.5)
	glMultiTexCoord(2, color[1],color[2],color[3],color[4]*0.1)
	local pos = self.pos
	glMultiTexCoord(3, pos[1],pos[2],pos[3], 0)
	glMultiTexCoord(4, self.margin, self.size, 1, 1)
	glCallList(sphereList)
	
end

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
function ShieldSphereParticle:Initialize()
  shieldShader = gl.CreateShader({
    vertex = [[
      #define pos gl_MultiTexCoord3
      #define margin gl_MultiTexCoord4.x
      #define size vec4(gl_MultiTexCoord4.yyy,1.0)

      varying float opac;
      varying vec4 color1;
      varying vec4 color2;

      void main()
      {
          gl_Position = gl_ModelViewProjectionMatrix * (gl_Vertex * size + pos);
          vec3 normal = gl_NormalMatrix * gl_Normal;
          vec3 vertex = vec3(gl_ModelViewMatrix * gl_Vertex);
          float angle = dot(normal,vertex)*inversesqrt( dot(normal,normal)*dot(vertex,vertex) ); //dot(norm(n),norm(v))
          opac = pow( abs( angle ) , margin);

          color1 = gl_MultiTexCoord1;
          color2 = gl_MultiTexCoord2;
      }
    ]],
    fragment = [[
      varying float opac;
      varying vec4 color1;
      varying vec4 color2;

      void main(void)
      {
          gl_FragColor =  mix(color1,color2,opac);
      }

    ]],
    uniform = {
      margin = 1,
    }
  })

  if (shieldShader == nil) then
    print(PRIO_MAJOR,"LUPS->Shield: critical shader error: "..gl.GetShaderLog())
    return false
  end

  sphereList = gl.CreateList(DrawSphere,0,0,0,1,SPHERE_DETAIL)
end

function ShieldSphereParticle:Finalize()
  gl.DeleteList(sphereList)
end


-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

function ShieldSphereParticle:CreateParticle()
  -- needed for repeat mode
  self.csize  = self.size
  self.clife  = self.life
  
  self.size      = self.csize or self.size
  self.innerSize = self.size*0.998-1
  self.life_incr = 1/self.life
  self.life = 0
  self.color = self.goodColorMap[1]
  self.goodColor = self.goodColorMap[1]
  self.badColor = self.badColorMap[1]

  self.updates = 0
  self.shieldCurrent = 0
  self.hitStrength = 0
  
  self.firstGameFrame = Spring.GetGameFrame()
  self.dieGameFrame   = self.firstGameFrame + self.clife
end

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

function ShieldSphereParticle:Update(n)
  if (self.life<1) then
    self.life     = self.life + n*self.life_incr
    self.updates = self.updates +1
    
    --Spring.Echo(n)
    local _,shieldCurrent = spGetUnitShieldState(self.uId)
	local hitStrength = (self.shieldCurrent - shieldCurrent) / self.shieldMax + 0.5*self.hitStrength
	--Spring.Echo("cur="..self.shieldCurrent.." max="..self.shieldMax.." hitStr="..hitStrength)
	if hitStrength < 0.05 then
		hitStrength = 0 
	end
	self.shieldCurrent = shieldCurrent
	self.hitStrength = hitStrength
    local healthFraction = shieldCurrent / self.shieldMax
    
    self.color = getHealthColor(self.goodColor,self.badColor,healthFraction,hitStrength)
  end
end

-- used if repeatEffect=true;
function ShieldSphereParticle:ReInitialize()
	self.size = self.csize
	self.life = 0
	self.color = self.goodColor
	self.dieGameFrame = self.dieGameFrame + self.clife
end

function ShieldSphereParticle.Create(Options)
  local newObject = MergeTable(Options, ShieldSphereParticle.Default)
  setmetatable(newObject,ShieldSphereParticle)  -- make handle lookup
  newObject:CreateParticle()
  return newObject
end

function ShieldSphereParticle:Destroy()
	glDeleteTexture(self.texture)
end

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

return ShieldSphereParticle