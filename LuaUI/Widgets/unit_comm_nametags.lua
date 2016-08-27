local versionNumber = "1.2c"

function widget:GetInfo()
  return {
    name      = "Commander Name Tags" .. versionNumber,
    desc      = "Displays a name tag above each commander.",
    author    = "Evil4Zerggin, Jools (tweaked by raaar)",
    date      = "6 Jan 2012",
    license   = "GNU GPL, v2 or later",
    layer     = -10,
    enabled   = true  --  loaded by default?
  }
end

-- Changelog: 1.2: Modified commander detection due to change in spring 85.0. Decoys also get the tag to avoid detection.
-- Changelog: 1.2a: Increased font size and heightoffset.
-- Changelog: 1.2b: Increased font size a bit more.
-- Changelog: 1.2b: Increased font size a bit more.

--------------------------------------------------------------------------------
-- constants
--------------------------------------------------------------------------------
local heightOffset = 32
local fontSize = 8
local addedBrightness = 0.2
--------------------------------------------------------------------------------
-- speed-ups
--------------------------------------------------------------------------------

local spGetUnitTeam         = Spring.GetUnitTeam
local spGetTeamInfo         = Spring.GetTeamInfo
local spGetPlayerInfo       = Spring.GetPlayerInfo
local spGetTeamColor        = Spring.GetTeamColor
local spGetUnitViewPosition = Spring.GetUnitViewPosition
local spGetVisibleUnits     = Spring.GetVisibleUnits
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetCameraPosition   = Spring.GetCameraPosition
local glColor             = gl.Color
local glText              = gl.Text
local glPushMatrix        = gl.PushMatrix
local glTranslate         = gl.Translate
local glBillboard         = gl.Billboard
local glPopMatrix         = gl.PopMatrix
local ceil = math.ceil
local max = math.max
local min = math.min

--------------------------------------------------------------------------------
-- helper functions
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

-- get player name and team color
local function getUnitPlayerName(unitID)
	local team = spGetUnitTeam(unitID)
	local player,isAI,side,name
	_,player,_,isAI,side,_,_,_ = spGetTeamInfo(team)
	if isAI then
		name = side
	else
		name = spGetPlayerInfo(player)
	end
	local r, g, b, a = convertColor(spGetTeamColor(team))

	if name == nil or #name < 1 then name = ("Team " .. team) end
	--name = string.upper(name)
	return name, {r, g, b, a,}
end

-- draw player name at commander's position
local function DrawUnitPlayerName(unitID, height, scale)
	local ux, uy, uz = spGetUnitViewPosition(unitID)
	local name, color = getUnitPlayerName(unitID)
	glPushMatrix()
	glTranslate(ux, uy + height, uz )
	glBillboard()
  
	glColor(color)
	glText(name, 0, 0, fontSize * scale, "cns")
	glText(name, 0, 0, fontSize * scale, "cn")
	glPopMatrix()
end


--------------------------------------------------------------------------------
-- callins
--------------------------------------------------------------------------------

function widget:DrawWorld()
	local visibleUnits = spGetVisibleUnits(ALL_UNITS,nil,true)
  
	local _,y,_ = spGetCameraPosition()
  
	local scale = 1 + y / 1100
	for i=1,#visibleUnits do
    	local unitID    = visibleUnits[i]
    	local unitDefID = spGetUnitDefID(unitID)
    	local unitDef   = UnitDefs[unitDefID or -1]
		local cp 		= unitDef.customParams or nil

		if unitDef and cp and cp.iscommander then
			local height    = unitDef.height+heightOffset
			DrawUnitPlayerName(unitID, height, scale)
		end
	end
end