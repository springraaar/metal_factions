function widget:GetInfo()
  return {
    name      = "Commander Name Tags",
    desc      = "Displays name tags above commanders.",
    author    = "Bluestone, Floris, tweaked by raaar",
    date      = "26 april 2018",
    license   = "GNU GPL, v2 or later",
    layer     = -10,
    enabled   = true,
  }
end

--------------------------------------------------------------------------------
-- config
--------------------------------------------------------------------------------

local nameScaling			= true
local useThickLeterring		= true
local heightOffset			= 50
local fontSize				= 15		-- not real fontsize, it will be scaled
local scaleFontAmount		= 120
local fontShadow			= true		-- only shows if font has a white outline
local shadowOpacity			= 0.35
local addedBrightness 		= 0.2

local font = gl.LoadFont("LuaUI/Fonts/FreeSansBold.otf", 55, 10, 10)
local shadowFont = gl.LoadFont("LuaUI/Fonts/FreeSansBold.otf", 55, 38, 1.6)

local vsx, vsy = Spring.GetViewGeometry()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local GetUnitTeam        		= Spring.GetUnitTeam
local GetPlayerInfo      		= Spring.GetPlayerInfo
local GetTeamInfo      			= Spring.GetTeamInfo
local GetPlayerList    		    = Spring.GetPlayerList
local GetTeamColor       		= Spring.GetTeamColor
local GetUnitDefID       		= Spring.GetUnitDefID
local GetAllUnits        		= Spring.GetAllUnits
local IsUnitInView	 	 		= Spring.IsUnitInView
local GetCameraPosition  		= Spring.GetCameraPosition
local GetUnitPosition    		= Spring.GetUnitPosition
local GetSpectatingState		= Spring.GetSpectatingState
local GetAIInfo 				= Spring.GetAIInfo 
local GetTeamLuaAI 				= Spring.GetTeamLuaAI

local glDepthTest        		= gl.DepthTest
local glAlphaTest        		= gl.AlphaTest
local glColor            		= gl.Color
local glTranslate        		= gl.Translate
local glBillboard        		= gl.Billboard
local glDrawFuncAtUnit   		= gl.DrawFuncAtUnit
local GL_GREATER     	 		= GL.GREATER
local GL_SRC_ALPHA				= GL.SRC_ALPHA	
local GL_ONE_MINUS_SRC_ALPHA	= GL.ONE_MINUS_SRC_ALPHA
local glBlending          		= gl.Blending
local glScale          			= gl.Scale
local max						= math.max
local min						= math.min
local glCallList				= gl.CallList

local diag						= math.diag

--------------------------------------------------------------------------------

local comms = {}
local glListByCommanderId = {}
local CheckedForSpec = false
local myTeamID = Spring.GetMyTeamID()
local myPlayerID = Spring.GetMyPlayerID()

--------------------------------------------------------------------------------

-- make text brighter
local function convertColor(r,g,b,a)
	local red = r + addedBrightness
	local green = g + addedBrightness
	local blue = b + addedBrightness
	red = max( red, 0 )
	green = max( green, 0 )
	blue = max( blue, 0 )
	red = min( red, 1 )
	green = min( green, 1 )
	blue = min( blue, 1 )
	return red,green,blue,a
end

--gets the name, color, and height of the commander
local function GetCommAttributes(unitID, unitDefID)
  local team = GetUnitTeam(unitID)
  if team == nil then
    return nil
  end
  local players = GetPlayerList(team)
  local isAI,side
  local name = "????"
  
  _,_,_,isAI,side,_,_,_ = GetTeamInfo(team)
  if isAI then
    local version
    _,_,_,_, name, version = GetAIInfo(team)

    local aiInfo = GetTeamLuaAI(team)
    if (string.sub(aiInfo,1,4) == "MFAI") then
	  name = aiInfo
    else
      if type(version) == "string" then
        name = "AI:" .. name .. "-" .. version
      else
        name = "AI:" .. name
      end
    end	  
  else
    if (#players>0) then
      for _,pID in ipairs(players) do
        local pname,active,spec = GetPlayerInfo(pID)
        if active and not spec then
          name = pname
          break
        end
      end
    end
  end

  local r, g, b, a = convertColor(GetTeamColor(team))
  local bgColor = {0,0,0,1}
  if (r + g*1.2 + b*0.4) < 0.8 then
		bgColor = {1,1,1,1}
  end
  local height = UnitDefs[unitDefID].height + heightOffset
  return {name, {r, g, b, a}, height, bgColor, unitID}
end

local function RemoveLists()
    for id, list in pairs(glListByCommanderId) do
        gl.DeleteList(glListByCommanderId[id])
    end
    glListByCommanderId = {}
end

local function createGlListForCommanderId(attributes)
    if glListByCommanderId[attributes[5]] ~= nil then
        gl.DeleteList(glListByCommanderId[attributes[5]])
    end
	glListByCommanderId[attributes[5]] = gl.CreateList( function()
		local outlineColor = {0,0,0,1}
		if (attributes[2][1] + attributes[2][2]*1.2 + attributes[2][3]*0.4) < 0.8 then  -- try to keep these values the same as the playerlist
			outlineColor = {1,1,1,1}
		end
		if useThickLeterring then
			if outlineColor[1] == 1 and fontShadow then
			  glTranslate(0, -(fontSize/44), 0)
			  shadowFont:Begin()
			  shadowFont:SetTextColor({0,0,0,shadowOpacity})
			  shadowFont:SetOutlineColor({0,0,0,shadowOpacity})
			  shadowFont:Print(attributes[1], 0, 0, fontSize, "con")
			  shadowFont:End()
			  glTranslate(0, (fontSize/44), 0)
			end
			font:SetTextColor(outlineColor)
			font:SetOutlineColor(outlineColor)
			
			font:Print(attributes[1], -(fontSize/38), -(fontSize/33), fontSize, "con")
			font:Print(attributes[1], (fontSize/38), -(fontSize/33), fontSize, "con")
		end
		font:Begin()
		font:SetTextColor(attributes[2])
		font:SetOutlineColor(outlineColor)
		font:Print(attributes[1], 0, 0, fontSize, "con")
		font:End()
	end)
end

local function DrawName(attributes)
	if glListByCommanderId[attributes[5]] == nil then
		createGlListForCommanderId(attributes)
	end
	glTranslate(0, attributes[3], 0)
	glBillboard()
	if nameScaling then
		glScale(usedFontSize/fontSize,usedFontSize/fontSize,usedFontSize/fontSize)
	end
	glCallList(glListByCommanderId[attributes[5]])

	if nameScaling then
		glScale(1,1,1)
	end
end

function widget:ViewResize()
  vsx,vsy = Spring.GetViewGeometry()
end

function widget:DrawWorld()
  if Spring.IsGUIHidden() then return end
  -- untested fix: when you resign, to also show enemy com playernames  (because widget:PlayerChanged() isnt called anymore)
  if not CheckedForSpec and Spring.GetGameFrame() > 1 then
	  if GetSpectatingState() then
		CheckedForSpec = true
		CheckAllComs()
	  end
  end
  
  glDepthTest(true)
  glAlphaTest(GL_GREATER, 0)
  glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
   
  local camX, camY, camZ = GetCameraPosition()
  
  for unitID, attributes in pairs(comms) do
    
    -- calc opacity
	if IsUnitInView(unitID) then
		local x,y,z = GetUnitPosition(unitID)
		camDistance = diag(camX-x, camY-y, camZ-z) 
		
	    usedFontSize = (fontSize*0.7) + (camDistance/scaleFontAmount)
	    
		glDrawFuncAtUnit(unitID, false, DrawName, attributes)
	end
  end
  
  glAlphaTest(false)
  glColor(1,1,1,1)
  glDepthTest(false)
end

--------------------------------------------------------------------------------

function CheckCom(unitID, unitDefID, unitTeam)
  if (unitDefID and UnitDefs[unitDefID] and UnitDefs[unitDefID].customParams.iscommander) then
      comms[unitID] = GetCommAttributes(unitID, unitDefID)
  end
end

function CheckAllComs()
  local allUnits = GetAllUnits()
  for _, unitID in pairs(allUnits) do
    local unitDefID = GetUnitDefID(unitID)
    if (unitDefID and UnitDefs[unitDefID].customParams.iscommander) then
      comms[unitID] = GetCommAttributes(unitID, unitDefID)
    end
  end
end

function widget:Initialize()
    CheckAllComs()
end

function widget:Shutdown()
    RemoveLists()
end

function widget:PlayerChanged(playerID)
  RemoveLists()
  CheckAllComs() -- handle substitutions, etc
end
    
function widget:UnitCreated(unitID, unitDefID, unitTeam)
  CheckCom(unitID, unitDefID, unitTeam)
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
  comms[unitID] = nil
end

function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
  CheckCom(unitID, unitDefID, unitTeam)
end

function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
  CheckCom(unitID, unitDefID, unitTeam)
end

function widget:UnitEnteredLos(unitID, unitTeam)
  CheckCom(unitID, GetUnitDefID(unitID), unitTeam)
end


