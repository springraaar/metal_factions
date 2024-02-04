--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Copyright (C) 2008.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------



function widget:GetInfo()
	return {
		name      = "AdvPlayersList",
		desc      = "Players list with useful information / shortcuts. Use tweakmode (ctrl+F11) to customize.",
		author    = "Marmoth. (Modified by raaar)",
		date      = "June 1, 2012",
		version   = "8.2",
		license   = "GNU GPL, v2 or later",
		layer     = -4,
		enabled   = true, 
		handler   = true,
	}
end

-- modified by raaar, oct 2016
--	. remade buttons
--	. added resource information and bars
--	. replaced rank with trueskill information
--  . removed tip draw check code as it wasn't working properly 
-- modified by raaar, aug 2015 : fixed MFAI label 


--------------------------------------------------------------------------------
-- SPEED UPS
--------------------------------------------------------------------------------

local Spring_GetGameSeconds      = Spring.GetGameSeconds
local Spring_GetAllyTeamList     = Spring.GetAllyTeamList
local Spring_GetTeamInfo         = Spring.GetTeamInfo
local Spring_GetTeamList         = Spring.GetTeamList
local Spring_GetPlayerInfo       = Spring.GetPlayerInfo
local Spring_GetPlayerList       = Spring.GetPlayerList
local Spring_GetTeamColor        = Spring.GetTeamColor
local Spring_GetLocalAllyTeamID  = Spring.GetLocalAllyTeamID
local Spring_GetLocalTeamID      = Spring.GetLocalTeamID
local Spring_GetLocalPlayerID    = Spring.GetLocalPlayerID
local Spring_ShareResources      = Spring.ShareResources
local Spring_GetTeamUnitCount    = Spring.GetTeamUnitCount
local Echo                       = Spring.Echo
local Spring_GetTeamResources    = Spring.GetTeamResources
local Spring_SendCommands        = Spring.SendCommands
local Spring_GetConfigInt        = Spring.GetConfigInt
local Spring_GetMouseState       = Spring.GetMouseState
local Spring_GetAIInfo           = Spring.GetAIInfo
local Spring_GetViewGeometry 	 = Spring.GetViewGeometry
local spGetGameFrame			 = Spring.GetGameFrame
local spGetTeamRulesParam        = Spring.GetTeamRulesParam
local spGetTimer                 = Spring.GetTimer
local spDiffTimers               = Spring.DiffTimers
local spGetGaiaTeamID            = Spring.GetGaiaTeamID 
local spGetUnitTeam              = Spring.GetUnitTeam
local spGetUnitAllyTeam          = Spring.GetUnitAllyTeam
local spGetSpectatingState       = Spring.GetSpectatingState
local spIsReplay                 = Spring.IsReplay

local gl_Texture          = gl.Texture
local gl_Rect             = gl.Rect
local gl_TexRect          = gl.TexRect
local gl_Color            = gl.Color
local gl_GetTextWidth     = gl.GetTextWidth
local gl_GetTextHeight    = gl.GetTextHeight
local gl_Text             = gl.Text

local glCreateList	= gl.CreateList
local glDeleteList	= gl.DeleteList
local glCallList	= gl.CallList

--local GetTextWidth        = fontHandler.GetTextWidth
--local UseFont             = fontHandler.UseFont
--fontHandler.LoadFont(self.font, floor(self.size*uiScale), floor(self.outlineWidth*uiScale), self.outlineWeight)
--local TextDraw            = fontHandler.Draw
--local TextDrawCentered    = fontHandler.DrawCentered
--local TextDrawRight       = fontHandler.DrawRight

-- use builtin font to allow scaling

local floor = math.floor
local ceil = math.ceil
local modf = math.modf
local max = math.max
local min = math.min

VFS.Include("lualibs/constants.lua")
VFS.Include("lualibs/util.lua")

--------------------------------------------------------------------------------
-- IMAGES
--------------------------------------------------------------------------------

local unitsPic        = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/units.png"
local energyPic       = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/energy.png"
local metalPic        = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/metal.png"
local notFirstPic     = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/notfirst.png"
local notFirstPicWO   = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/notfirstWO.png"
local pingPic         = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/ping.png"
local cpuPic          = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/cpu.png"
local specPic         = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/spec.png"
local selectPic       = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/select.png"
local barPic          = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/bar.png"
local hBarPic         = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/hbar.png"
local energyBarPic    = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/energybar.png"
local metalBarPic     = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/metalbar.png"
local amountPic       = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/amount.png"
local cpuPingPic      = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/cpuping.png"
local sharePic        = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/share.png"
local namePic         = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/name.png"
local IDPic           = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/ID.png"
local pointPic        = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/point.png"
local chatPic         = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/chat.png"
local chatTypePic     = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/chatType.png"
local lowPic          = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/low.png"
local settingsPic     = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/settings.png"
local sidePic         = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/side.png"
local rankPic         = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/ranks.png"
local arrowPic        = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/arrow.png"
local arrowdPic       = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/arrowd.png"
local takePic         = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/take.png"
local crossPic        = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/cross.png"
local pointbPic       = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/pointb.png"
local takebPic        = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/takeb.png"
local seespecPic      = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/seespec.png"
local resourcesPic      = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/resources.png"
local positionPic      = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/position.png"
local clearMarksPic     = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/clearMarks.png"

local sides           = {}  -- select side by team id
local sidePics        = {}  -- loaded in Sem_sidePics function
local sidePicsWO      = {}  -- loaded in Sem_sidePics function

--------------------------------------------------------------------------------
-- Fonts
--------------------------------------------------------------------------------

local font            = "luaui/fonts/FreeSansBold_14"
local fontWOutline    = "luaui/fonts/FreeSansBoldWOutline_14"     -- White outline for font (special font set)


--------------------------------------------------------------------------------
-- Colors
--------------------------------------------------------------------------------

local pingCpuColors   = {}


--------------------------------------------------------------------------------
-- Time Variables
--------------------------------------------------------------------------------


local blink           = true
local lastTime        = 0
local blinkTime       = 0
local now             = 0


--------------------------------------------------------------------------------
-- Tooltip
--------------------------------------------------------------------------------

local tipText                -- text of the tip

--------------------------------------------------------------------------------
-- Players counts and info
--------------------------------------------------------------------------------

-- local player info
local myAllyTeamID                           
local myTeamID			
local myPlayerID
local mySpecStatus = false
local specTarget = -1
local selectedUnitsTeamId = -1
local selectedUnitsAllyId = -1
	
--General players/spectator count and tables
local player = {}
local teamResources = {}
local allyTeamResources = {}
local allyTeamResourcesByDrawListIndex = {}

function formatNbr(x,digits)
	if x then
		local _,fractional = modf(x)
		if fractional==0 then
			return x
		elseif fractional<0.01 then
			return floor(x)
		elseif fractional>0.99 then
			return ceil(x)
		else
			local ret=string.format("%."..(digits or 0).."f",x)
			if digits and digits>0 then
				while true do
					local last = string.sub(ret,string.len(ret))
					if last=="0" or last=="." then
						ret = string.sub(ret,1,string.len(ret)-1)
					end
					if last~="0" then
						break
					end
				end
			end
			return ret
		end
	end
end

function round(num, idp)
  local mult = 10^(idp or 0)
  return floor(num * mult + 0.5) / mult
end

--------------------------------------------------------------------------------
-- Button check variable
--------------------------------------------------------------------------------

local clickToMove                  = nil    -- click detection for moving the widget
local moveStart                    = nil    -- position of the cursor before dragging the widget

local energyPlayer                 = nil    -- player to share energy with (nil when no energy sharing)
local metalPlayer                  = nil    -- player to share metal with(nil when no metal sharing)
local amountEM                     = 0      -- amount of metal/energy to share/ask
local amountEMMax                  = nil    -- max amount of metal/energy to share/ask
local sliderPosition               = 0      -- slider position in metal and energy sharing
local sliderOrigin                  = nil   -- position of the cursor before dragging the widget

local firstclick                   = 0		--
local doubleClick                  = false  -- deals with double click


--------------------------------------------------------------------------------
-- GEOMETRY VARIABLES
--------------------------------------------------------------------------------

local vsx,vsy                                    = gl.GetViewSizes()
local scaleFactor = 1
if (vsy ~= 1080) then
	scaleFactor = vsy/1080
else
	scaleFactor = 1
end

local openClose                                  = 0
local widgetTop                                  = 0
local widgetRight                                = 1
local widgetHeight                               = 0
local widgetWidth                                = 0
local widgetPosX                                 = vsx-200*scaleFactor
local widgetPosY                                 = 0

local expandDown                                 = false
local expandLeft                                 = false
local right
local localOffset    -- used by different functions to pass values
local localLeft      -- used by different functions to pass values
local localBottom    -- used by different functions to pass values

local activePlayers   = {}
local labelOffset     = 20 * scaleFactor
local separatorOffset = 3 * scaleFactor
local playerOffset    = 19 * scaleFactor
local drawList        = {}
local teamN


--------------- chat button stuff


local clearMarksButton				= {}
local chatTypeButton				= {}
local glColor 						= gl.Color
local glRect						= gl.Rect
local glTexture 					= gl.Texture
local glTexRect 					= gl.TexRect

local refFontSize = 14
local refBoxSizeX = 100
local refBoxSizeY = 30
local itemSizeY = 16 * scaleFactor 
local fontSize = refFontSize * scaleFactor
	
local cWhite						= {1, 1, 1, 1}

local addedBrightness = 0.2 -- to avoid white outline on players

local CHAT_ALL = 0
local CHAT_ALLIES = 1
local CHAT_SPECTATORS = 2

local chatType = CHAT_ALL
local chatTypeLabels = {
	[CHAT_ALL] = "Chat : All",
	[CHAT_ALLIES] = "Chat : Ally",
	[CHAT_SPECTATORS] = "Chat : Spec"

}

local latestLagWarningByPlayer = {}
local PLAYER_LAG_WARNING_THRESHOLD_MS = 5000
local PLAYER_LAG_WARNING_DELAY_F = 3000 -- 100s

local function isOnButton(x, y, BLcornerX, BLcornerY,TRcornerX,TRcornerY)
	if BLcornerX == nil then return false end
	-- check if the mouse is in a rectangle

	return x >= BLcornerX and x <= TRcornerX
	                      and y >= BLcornerY
	                      and y <= TRcornerY
end

function updateExtraButtonGeometry()
	if (vsy ~= 1080) then
		scaleFactor = vsy/1080
	else
		scaleFactor=1
	end

	fontSize = refFontSize * scaleFactor 
	chatTypeButton.x1 = vsx - 1 - refBoxSizeX*scaleFactor
	chatTypeButton.x2 = vsx - 1
	chatTypeButton.y1 = widgetPosY + widgetHeight + 1
	chatTypeButton.y2 = widgetPosY + widgetHeight + 1 + refBoxSizeY*scaleFactor

	--gl_Texture(chatTypePic)
	--gl_TexRect(chatTypeButton.x1 - 1 - (chatTypeButton.y2-chatTypeButton.y1), chatTypeButton.y1, chatTypeButton.x1 - 1, chatTypeButton.y2)
	
	clearMarksButton.x1 = chatTypeButton.x1 - 2 - (chatTypeButton.y2-chatTypeButton.y1)
	clearMarksButton.x2 = chatTypeButton.x1 - 2
	clearMarksButton.y1 = chatTypeButton.y1
	clearMarksButton.y2 = chatTypeButton.y2
end

function widget:IsAbove(mx,my)
	if not Spring.IsGUIHidden() then
		chatTypeButton.above = isOnButton(mx, my, chatTypeButton["x1"],chatTypeButton["y1"],chatTypeButton["x2"],chatTypeButton["y2"])
		clearMarksButton.above = isOnButton(mx, my, clearMarksButton["x1"],clearMarksButton["y1"],clearMarksButton["x2"],clearMarksButton["y2"])
	end
	return false		
end	


--------------------------------------------------
-- Modules
--------------------------------------------------


local modules = {}
local modulesCount = 0
local m_rank;     modulesCount = modulesCount + 1
local m_side;     modulesCount = modulesCount + 1
local m_ID;       modulesCount = modulesCount + 1
local m_name;     modulesCount = modulesCount + 1
local m_share;    modulesCount = modulesCount + 1
local m_resources;     modulesCount = modulesCount + 1
local m_position;     modulesCount = modulesCount + 1
local m_chat;     modulesCount = modulesCount + 1
local m_cpuping;  modulesCount = modulesCount + 1
local m_diplo;    modulesCount = modulesCount + 1
local m_spec;     modulesCount = modulesCount + 1


local m_point;    modulesCount = modulesCount + 1  -- those 3 are not considered as normal module since they dont take any place and wont affect other's position
local m_take;     modulesCount = modulesCount + 1
local m_seespec;  modulesCount = modulesCount + 1


m_rank = {
	spec      = true,
	play      = true,
	active    = true,
	width     = 30 * scaleFactor,
	position  = 2,
	posX      = 0,
	pic       = rank8,
}

m_side = {
	spec      = true,
	play      = true,
	active    = true,
	width     = 19 * scaleFactor,
	position  = 3,
	posX      = 0,
	pic       = sidePic,
}

m_ID = {
	spec      = true,
	play      = true,
	active    = false,
	width     = 22 * scaleFactor,
	position  = 4,
	posX      = 0,
	pic       = IDPic,
}

m_name = {
	spec      = true,
	play      = true,
	active    = true,
	width     = 0,
	position  = 5,
	posX      = 0,
	pic       = namePic,
}

m_cpuping = {
	spec      = true,
	play      = true,
	active    = true,
	width     = 25 * scaleFactor,
	position  = 6,
	posX      = 0,
	pic       = cpuPingPic,
}

m_share = {
	spec      = false,
	play      = true,
	active    = true,
	width     = 56 * scaleFactor,
	position  = 7,
	posX      = 0,
	pic       = sharePic,
}


m_resources = {
	spec      = true,
	play      = true,
	active    = true,
	width     = 50 * scaleFactor,
	position  = 8,
	posX      = 0,
	pic       = resourcesPic,
}

m_chat = {
	spec      = false,
	play      = true,
	active    = true,
	width     = 19 * scaleFactor,
	position  = 10,
	posX      = 0,
	pic       = chatPic,
}

m_spec = {
	spec      = true,
	play      = false,
	active    = true,
	width     = 19 * scaleFactor,
	position  = 11,
	posX      = 0,
	pic       = specPic,
}


m_position = {
	spec      = true,
	play      = true,
	active    = true,
	width     = 40 * scaleFactor,
	position  = 9,
	posX      = 0,
	pic       = positionPic,
}

--[[m_diplo = {
	spec      = false,
	play      = true,
	active    = false,
	width     = 19 * scaleFactor,
	position  = 11,
	posX      = 0,
	pic       = diplomacyPic,		
}]]

modules = {
	m_rank,
	m_ID,
	m_side,
	m_name,
	m_cpuping,
	m_share,
	m_resources,
	m_spec,
	m_chat,
	m_position,
--	m_diplo,
}

m_point = {
	active = true,
	pic = pointbPic,
}

m_take = {
	active = true,
	pic = takePic,
}

m_seespec = {
	active = true,
	pic = seespecPic,
}


-- get text dimensions
function GetTextWidth(text)
	return gl_GetTextWidth(text)*fontSize
end  
function GetTextHeight(text)
	return gl_GetTextHeight(text)*fontSize
end  

-- draw text
function TextDraw(text,x,y,options)
	options = options or "on"
	gl_Text(text,x,y,fontSize,options)
end
function TextDrawCentered(text,x,y)
	return TextDraw(text,x,y,"onc")
end
function TextDrawRight(text,x,y)
	return TextDraw(text,x,y,"onr")
end

-- make text brighter to avoid white outline
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

function SetModulesPositionX()
	m_name.width = SetMaxPlayerNameWidth()
	table.sort(modules, function(v1,v2)
		return v1.position < v2.position
	end)
	pos = 1
	for _,module in ipairs(modules) do
		module.posX = pos
		if module.active == true then
			if mySpecStatus == true then
				if module.spec == true then
					pos = pos + module.width
				end
			else
				if module.play == true then
					pos = pos + module.width
					
				end
			end
		end
	end
	widgetWidth = pos + 1
	if widgetWidth < 20 then
		widgetWidth = 20
	end
	if widgetWidth + widgetPosX > vsx then
	  widgetPosX = vsx - widgetWidth
	end
	if widgetRight - widgetWidth < 0 then
		widgetRight = widgetWidth
	end
	if expandLeft == true then
		widgetPosX  = widgetRight - widgetWidth
	else
		widgetRight = widgetPosX + widgetWidth
	end
end

function SetMaxPlayerNameWidth()

	-- determines the maximal player name width (in order to set the width of the widget)

	local t = Spring_GetPlayerList()
	local maxWidth = GetTextWidth("- aband. units -")+4+100 -- minimal width = minimal standard text width
	local name = ""
	local nextWidth = 0
	--UseFont(font)
	if not t then
		t = {}
	end 
	for _,wplayer in ipairs(t) do
		name = Spring_GetPlayerInfo(wplayer)
		nextWidth = GetTextWidth(name)+4+100
		if nextWidth > maxWidth then
			maxWidth = nextWidth
		end
	end
  return maxWidth
end

function GeometryChange()
	if (vsy ~= 1080) then
		scaleFactor = vsy/1080
	else
		scaleFactor=1
	end
	
	itemSizeY = 16 * scaleFactor 
	widgetPosX = vsx-200*scaleFactor
	labelOffset     = 20 * scaleFactor
	separatorOffset = 3 * scaleFactor
	playerOffset    = 19 * scaleFactor
	
	widgetRight = widgetWidth + widgetPosX
	if widgetRight > vsx then
		widgetRight = vsx
		widgetPosX = widgetRight - widgetWidth
	end
	if widgetPosX + widgetWidth/2 > vsx/2 then
		right = true
	else
		right = false
	end
end


function InitializePlayers()
	myPlayerID = Spring_GetLocalPlayerID()
	myTeamID = Spring_GetLocalTeamID()
	myAllyTeamID = Spring_GetLocalAllyTeamID()
	for i = 0, 64 do
		player[i] = {} 
	end
	GetAllPlayers()
end

function GetAllPlayers()
	local noplayer
	local tside,ingameSide
	local allteams   = Spring_GetTeamList()
	teamN = table.maxn(allteams) - 1               --remove gaia
	for i = 0,teamN-1 do
		_,_,_,_,tside = Spring_GetTeamInfo(i)
		ingameSide = spGetTeamRulesParam(i,"faction_selected")
		if ingameSide then
			tside = ingameSide
		end
		sides[i] = tside
	
		local teamPlayers = Spring_GetPlayerList(i, true)
		if not teamPlayers then
			teamPlayers = {}
		end
		player[i + 32] = CreatePlayerFromTeam(i)
		for _,playerID in ipairs(teamPlayers) do
			player[playerID] = CreatePlayer(playerID)
		end
	end
	specPlayers = Spring_GetTeamList()
	for _,playerID in ipairs(specPlayers) do
		local active,_,spec = Spring_GetPlayerInfo(playerID)
		if spec == true then
			if active == true then
				player[playerID] = CreatePlayer(playerID)
			end
		end
	end
end

function Init()
	SetPingCpuColors()
	InitializePlayers()
	SetSidePics()
	SortList()
	SetModulesPositionX()
	GeometryChange()
	updateExtraButtonGeometry()
end

function widget:Initialize()
	Init()
	
	-- participating on a team, change chat type to "ally"
	-- disabled because it makes the chat popup appear
	--chatType = CHAT_ALLIES
	--Spring.SendCommands("ChatAlly")
end

function CreatePlayer(playerID)

	local tname,_, tspec, tteam, tallyteam, tping, tcpu, tcountry, trank = Spring_GetPlayerInfo(playerID)
	local _,_,_,_, tside, tallyteam,incomeMult                         = Spring_GetTeamInfo(tteam)
	local tred, tgreen, tblue                                            = Spring_GetTeamColor(tteam)
	tred,tgreen,tblue,_ = convertColor(tred,tgreen,tblue,0) 
	
	local tskill = GetSkill(playerID)
	

	tpingLvl = GetPingLvl(tping)
	tcpuLvl  = GetCpuLvl(tcpu)
	tping    = tping * 1000 - ((tping * 1000) % 1)
	tcpu     = tcpu  * 100  - ((tcpu  *  100) % 1)
	
	return {
		rank             = trank,
		skill            = tskill, 
		name             = tname,
		team             = tteam,
		allyteam         = tallyteam,
		red              = tred,
		green            = tgreen,
		blue             = tblue,
		dark             = GetDark(tred,tgreen,tblue),
		side             = tside,
		pingLvl          = tpingLvl,
		cpuLvl           = tcpuLvl,
		ping             = tping,
		cpu              = tcpu,
		tdead            = false,
		spec             = tspec,
		incomeMult		 = incomeMult,
		storageM     = nil,
		storageE     = nil,
		currentM     = nil,
		currentE     = nil,
		relIncome     = nil
	}
	
end

function CreatePlayerFromTeam(teamID)
	local _,_, isDead, isAI, tside, tallyteam,incomeMult = Spring_GetTeamInfo(teamID)
	local tred, tgreen, tblue                 = Spring_GetTeamColor(teamID)
	tred,tgreen,tblue,_ = convertColor(tred,tgreen,tblue,0) 
	local tname, ttotake, tdead
	local tskill = GetSkill(teamID)

	if isAI then
		if (spGetTeamRulesParam(teamID,"ai_resigned") == "1") then
			if Spring_GetTeamUnitCount(teamID) > 0  then
				tname = "- aband. units -"
				ttotake = true
				tdead = false
			else
				tname = "- dead team -"
				ttotake = false
				tdead = true
			end
		else
			local version
			_,_,_,_, tname, version = Spring_GetAIInfo(teamID)
	
			local aiInfo = Spring.GetTeamLuaAI(teamID)
			if (aiInfo and string.sub(aiInfo,1,4) == "MFAI") then
				tname = aiInfo
				-- add the team id to the name
				tname = tname:gsub( "MFAI", "["..teamID.."] MFAI")
			else
				if type(version) == "string" then
					tname = "AI:" .. tname .. "-" .. version 
				else
					tname = "AI:" .. tname
				end
			end
	
			ttotake = false
			tdead = false
		end
	else
	
		if Spring_GetGameSeconds() < 0.1 then
		
			tname = "no player yet"
			ttotake = false
			tdead = false
		
		else
		
			if Spring_GetTeamUnitCount(teamID) > 0  then
				tname = "- aband. units -"
				ttotake = true
				tdead = false
			else
				tname = "- dead team -"
				ttotake = false
				tdead = true
			end
		
		end
	end


	return {
		rank             = 8, -- "don't know which" value
		skill             = tskill,
		name             = tname,
		team             = teamID,
		allyteam         = tallyteam,
		red              = tred,
		green            = tgreen,
		blue             = tblue,
		dark             = GetDark(tred, tgreen, tblue),
		side             = tside,
		totake           = ttotake,
		dead             = tdead,
		spec             = false,
		incomeMult		 = incomeMult,
		storageM     = nil,
		storageE     = nil,
		currentM     = nil,
		currentE     = nil,
		relIncome     = nil	
	}
	
end

function SortList()
	local teamList
	local myOldSpecStatus = mySpecStatus
	
	_,_, mySpecStatus,_,_,_,_,_,_ = Spring_GetPlayerInfo(myPlayerID)
	
	-- checks if a team has died
	if mySpecStatus ~= myOldSpecStatus then
		if mySpecStatus == true then
			teamList = Spring_GetTeamList()
			for _, team in ipairs(teamList) do
				_,_, isDead = Spring_GetTeamInfo(team)
				if isDead == false then
					Spec(team,true)
					break
				end
			end
		end
	end
	
	myAllyTeamID = Spring_GetLocalAllyTeamID()
	myTeamID = Spring_GetLocalTeamID()
	
	drawList = {}
	drawListOffset = {}
	vOffset = 0
	
	-- calls the (cascade) sorting for players
	vOffset = SortAllyTeams(vOffset) 
	
	-- calls the sortings for specs if see spec is on
	if m_seespec.active == true then
		vOffset = SortSpecs(vOffset) 
	end
	
	-- set the widget height according to space needed to show team
	widgetHeight = vOffset + 3
	
	
	-- move the widget if list is too long
	if widgetHeight + widgetPosY > vsy then
		widgetPosY = vsy - widgetHeight
	end
	
	if widgetTop - widgetHeight < 0 then
		widgetTop = widgetHeight
	end
	
	-- set the widget Y position or the top of the widget according to expand direction
	if expandDown == true then
		widgetPosY = widgetTop - widgetHeight
	else
		widgetTop = widgetPosY + widgetHeight
	end
	
end

function SortAllyTeams(vOffset)
	-- adds ally teams to the draw list (own ally team first)
	-- (labels and separators are drawn)
	local allyTeamID
	local allyTeamList = Spring_GetAllyTeamList()
	local firstEnemy = true
	allyTeamsCount = table.maxn(allyTeamList)-1
	
	-- find own ally team
	for allyTeamID = 0, allyTeamsCount - 1 do
		if allyTeamID == myAllyTeamID  then
			vOffset = vOffset + labelOffset
			table.insert(drawListOffset, vOffset)
			table.insert(drawList, -2)  -- "Allies" label
			if (allyTeamResources[allyTeamID] and allyTeamResources[allyTeamID].relIncome) then
				allyTeamResourcesByDrawListIndex[#drawList] = allyTeamResources[allyTeamID]
			end
			vOffset = SortTeams(allyTeamID, vOffset)	-- Add the teams from the allyTeam		
			break
		end
	end
	
	-- add the others
	for allyTeamID = 0, allyTeamsCount-1 do
		if allyTeamID ~= myAllyTeamID then
			--if firstEnemy == true then
				vOffset = vOffset + labelOffset
				table.insert(drawListOffset, vOffset)
				table.insert(drawList, -3) -- "Enemies" label
			--	firstEnemy = false
			--else
				--vOffset = vOffset + separatorOffset
				--table.insert(drawListOffset, vOffset)
				--table.insert(drawList, -4) -- Enemy teams separator
			--end
			if (allyTeamResources[allyTeamID] and allyTeamResources[allyTeamID].relIncome) then
				allyTeamResourcesByDrawListIndex[#drawList] = allyTeamResources[allyTeamID]
			end			
			vOffset = SortTeams(allyTeamID, vOffset) -- Add the teams from the allyTeam 
		end
	end
	
	return vOffset
end

function SortTeams(allyTeamID, vOffset)
	-- Adds teams to the draw list (own team first)
	--(teams are not visible as such unless they are empty or AI)
	local teamID
	local teamsList = Spring_GetTeamList(allyTeamID)
	
	-- add own team first (if in own ally team)
	if myAllyTeamID == allyTeamID then
		table.insert(drawListOffset, vOffset)
		table.insert(drawList, -1)
		vOffset = SortPlayers(myTeamID,allyTeamID,vOffset) -- adds players from the team	
	end
	
	-- add other teams
	for _,teamID in ipairs(teamsList) do
		if teamID ~= myTeamID then
			table.insert(drawListOffset, vOffset)
			table.insert(drawList, -1)
			vOffset = SortPlayers(teamID,allyTeamID,vOffset) -- adds players form the team
		end  
	end
	
	return vOffset
end

function SortPlayers(teamID,allyTeamID,vOffset)
	-- Adds players to the draw list (self first)
	
	local playersList       = Spring_GetPlayerList(teamID,true)
	if not playersList then
		playersList = {}
	end
	local noPlayer          = true
	local _,_,_, isAi = Spring_GetTeamInfo(teamID)
	
	-- add own player (if not spec)
	if myTeamID == teamID then
		if player[myPlayerID].name ~= nil then
			if mySpecStatus == false then
				vOffset = vOffset + playerOffset
				table.insert(drawListOffset, vOffset)
				table.insert(drawList, myPlayerID) -- new player (with ID)
				player[myPlayerID].posY = vOffset
				noPlayer = false
			end
		end
	end
	
	-- add other players (if not spec)
	for _,playerID in ipairs(playersList) do
		if playerID ~= myPlayerID then
			if player[playerID].name ~= nil then
				if player[playerID].spec ~= true then
					vOffset = vOffset + playerOffset
					table.insert(drawListOffset, vOffset)
					table.insert(drawList, playerID) -- new player (with ID)
					player[playerID].posY = vOffset
					noPlayer = false
				end
			end
		end
	end
	
	-- add AI teams
	if isAi == true then
		vOffset = vOffset + playerOffset
		table.insert(drawListOffset, vOffset)
		table.insert(drawList, 32 + teamID) -- new AI team (instead of players)
		player[32 + teamID].posY = vOffset
		noPlayer = false
	end
	
	-- ad no player token if no player found in this team at this point
	if noPlayer == true then
		vOffset = vOffset + playerOffset
		table.insert(drawListOffset, vOffset)
		table.insert(drawList, 32 + teamID)  -- no players team
		player[32 + teamID].posY = vOffset
	end
	return vOffset
end

function SortSpecs(vOffset)
	-- Adds specs to the draw list
	
	local playersList = Spring_GetPlayerList(_,true)
	local noSpec = true
	if not playersList then
		playersList = {}
	end 
	
	for _,playerID in ipairs(playersList) do
		_,active,spec = Spring_GetPlayerInfo(playerID)
		if spec == true then
			if player[playerID].name ~= nil then
				
				-- add "Specs" label if first spec
				if noSpec == true then
					vOffset = vOffset + labelOffset
					table.insert(drawListOffset, vOffset)
					table.insert(drawList, -5)
					noSpec = false
				end
				
				-- add spectator
				vOffset = vOffset + playerOffset
				table.insert(drawListOffset, vOffset)
				table.insert(drawList, playerID)
				player[playerID].posY = vOffset
				noPlayer = false
			end
		end
	end
	return vOffset
end



---------------------------------------------------------------------------------------------------
--  Draw
---------------------------------------------------------------------------------------------------
local glList = nil
local glListRefreshIdx = -1
local refTimer = spGetTimer()
function widget:DrawScreen()

	local vOffset                 = 0         -- position of the next object to draw
	local firstDrawnPlayer, firstEnemy, previousAllyTeam = true, true, nil
	local mouseX,mouseY           = Spring_GetMouseState()

	-- sets font
	--UseFont(font)
	
	-- updates resources for the sharing
	UpdateResources()
	CheckTime()
	
	-- check unit selection, change spectator view
	local spec, specFullView = spGetSpectatingState()
	if spec then
		CheckUnitSelection()
	end
	
	-- cancels the drawing if GUI is hidden
	if Spring.IsGUIHidden() then
		return
	end
	
	local refreshIdx = floor(spDiffTimers(spGetTimer(),refTimer)*5)
	local forceRefresh = isOnButton(mouseX, mouseY, widgetPosX, widgetPosY,widgetPosX + widgetWidth,chatTypeButton.y2)
	
	-- refresh gl list only a few times per second, unless mouse is over the widget
	if (not glList) or forceRefresh or refreshIdx ~= glListRefreshIdx then
		if (glList) then
			glDeleteList(glList)
		end 
		glList = glCreateList(function()
			-- draws the background
			DrawBackground()
			
			-- draw chat type button
			if chatTypeButton.above then
				tipText = "Click to change the chat mode between All/Allies/Spectators"
				glColor(UI_BTN_BG_OVER)
			else
				glColor(UI_BTN_BG)
			end
			glRect(chatTypeButton.x1,chatTypeButton.y1,chatTypeButton.x2,chatTypeButton.y2)
			glColor(UI_BTN_TEXT)
			-- chat button text
			gl_Text(chatTypeLabels[chatType],(chatTypeButton.x1 + chatTypeButton.x2) /2, (chatTypeButton.y1 + chatTypeButton.y2) / 2-GetTextHeight(chatTypeLabels[chatType])/2,fontSize,"c")
			-- chat type button border
			if chatTypeButton.above then
				glColor(UI_BTN_BORDER_OVER)
			else
				glColor(UI_BTN_BORDER)
			end
			glRect(chatTypeButton.x1,chatTypeButton.y1,chatTypeButton.x1+1,chatTypeButton.y2)
			glRect(chatTypeButton.x2-1,chatTypeButton.y1,chatTypeButton.x2,chatTypeButton.y2)
			glRect(chatTypeButton.x1,chatTypeButton.y1,chatTypeButton.x2,chatTypeButton.y1+1)
			glRect(chatTypeButton.x1,chatTypeButton.y2-1,chatTypeButton.x2,chatTypeButton.y2)
			gl_Color(1,1,1,1)

			-- draw clear marks button
			if clearMarksButton.above then
				tipText = "Click to clear player drawings on the map"
				glColor(UI_BTN_BG_OVER)
			else
				glColor(UI_BTN_BG)
			end
			glRect(clearMarksButton.x1,clearMarksButton.y1,clearMarksButton.x2,clearMarksButton.y2)
			glColor(cWhite)
			gl_Texture(clearMarksPic)
			gl_TexRect(clearMarksButton.x1, clearMarksButton.y1, clearMarksButton.x2, clearMarksButton.y2)
			gl_Texture(false)
			if clearMarksButton.above then
				glColor(UI_BTN_BORDER_OVER)
			else
				glColor(UI_BTN_BORDER)
			end
			glRect(clearMarksButton.x1,clearMarksButton.y1,clearMarksButton.x1+1,clearMarksButton.y2)
			glRect(clearMarksButton.x2-1,clearMarksButton.y1,clearMarksButton.x2,clearMarksButton.y2)
			glRect(clearMarksButton.x1,clearMarksButton.y1,clearMarksButton.x2,clearMarksButton.y1+1)
			glRect(clearMarksButton.x1,clearMarksButton.y2-1,clearMarksButton.x2,clearMarksButton.y2)
			gl_Color(1,1,1,1)
						
			-- draws the main list
			DrawList()
		
			-- draws share energy/metal sliders
			DrawShareSlider()

		end)
		glListRefreshIdx = refreshIdx
	end
	glCallList(glList)
end

function UpdateResources()
	if energyPlayer ~= nil then
		if energyPlayer.team == myTeamID then
			local current,storage = Spring_GetTeamResources(myTeamID,"energy")
			amountEMMax = storage - current
			amountEM = amountEMMax*sliderPosition/39
			amountEM = amountEM-(amountEM%1)			
		else
			amountEMMax = Spring_GetTeamResources(myTeamID,"energy")
			amountEM = amountEMMax*sliderPosition/39
			amountEM = amountEM-(amountEM%1)
		end
	end
	if metalPlayer ~= nil then
		if metalPlayer.team == myTeamID then
			local current, storage = Spring_GetTeamResources(myTeamID,"metal")
			amountEMMax = storage - current
			amountEM = amountEMMax*sliderPosition/39
			amountEM = amountEM-(amountEM%1)			
		else
			amountEMMax = Spring_GetTeamResources(myTeamID,"metal")
			amountEM = amountEMMax*sliderPosition/39
			amountEM = amountEM-(amountEM%1)
		end
	end
end

function CheckTime()
	local period = 0.4
	now = os.clock()
	if  now > (lastTime + period) then
		lastTime = now
		CheckPlayersChange()
		if blink == true then
			blink = false
		else
			blink = true
		end
		for playerID =0, 31 do
			if player[playerID] ~= nil then
				if player[playerID].pointTime ~= nil then
					if player[playerID].pointTime <= now then
						player[playerID].pointX = nil
						player[playerID].pointY = nil
						player[playerID].pointZ = nil
						player[playerID].pointTime = nil
					end
				end
			end
		end
	end 
end

function DrawBackground()
	-- draws background rectangle
	gl_Color(0,0,0,0.6)                              
	gl_Rect(widgetPosX,widgetPosY, widgetPosX + widgetWidth, widgetPosY + widgetHeight - 1)
	
	-- draws black border
	gl_Color(0,0,0,1)
	gl_Rect(widgetPosX,widgetPosY, widgetPosX + widgetWidth, widgetPosY+1)
	gl_Rect(widgetPosX,widgetPosY + widgetHeight  - 2, widgetPosX + widgetWidth, widgetPosY + widgetHeight  - 1)
	gl_Rect(widgetPosX , widgetPosY, widgetPosX + 1, widgetPosY + widgetHeight  - 1)
	gl_Rect(widgetPosX + widgetWidth - 1, widgetPosY, widgetPosX + widgetWidth, widgetPosY + widgetHeight  - 1)
	gl_Color(1,1,1,1)		
end

function DrawList()
	local mouseX,mouseY = Spring_GetMouseState()
	local leader

	for i, drawObject in ipairs(drawList) do
		if drawObject == -5 then
			DrawLabel("SPECS", drawListOffset[i])
		elseif drawObject == -4 then
			DrawSeparator(drawListOffset[i])
		elseif drawObject == -3 then
			DrawLabel("ENEMIES", drawListOffset[i])
		elseif drawObject == -2 then
			DrawLabel("ALLIES", drawListOffset[i])
		elseif drawObject == -1 then
			leader = true
		else
			DrawPlayer(drawObject, leader, drawListOffset[i], mouseX, mouseY)
			leader = false
		end
		if mySpecStatus == true and allyTeamResourcesByDrawListIndex[i] then
			--Spring.Echo("idx="..i.." offset="..drawListOffset[i].." obj="..drawObject.." inc="..allyTeamResourcesByDrawListIndex[i].relIncome)
			DrawRelativeIncome(widgetPosY + widgetHeight -drawListOffset[i], allyTeamResourcesByDrawListIndex[i].relIncome, true)
		end
	end

	DrawTip(mouseX, mouseY)
end

function DrawLabel(text, vOffset)
	if widgetWidth < 67 then
		text = string.sub(text, 0, 1)
	end
	TextDraw(text, widgetPosX + 2, widgetPosY + widgetHeight -vOffset+1)
	gl_Color(1,1,1,0.5)
	gl_Rect(widgetPosX+1, widgetPosY + widgetHeight -vOffset-1, widgetPosX + widgetWidth-1, widgetPosY + widgetHeight -vOffset-2)
	gl_Color(0,0,0,0.6)
	gl_Rect(widgetPosX+1, widgetPosY + widgetHeight -vOffset-2, widgetPosX + widgetWidth-1, widgetPosY + widgetHeight -vOffset-3)
	gl_Color(1,1,1)
end

function DrawSeparator(vOffset)
	gl_Rect(widgetPosX+1, widgetPosY + widgetHeight -vOffset-1, widgetPosX + widgetWidth-1, widgetPosY + widgetHeight -vOffset-2)
	gl_Color(0,0,0)
	gl_Rect(widgetPosX+1, widgetPosY + widgetHeight -vOffset-2, widgetPosX + widgetWidth-1, widgetPosY + widgetHeight -vOffset-3)
	gl_Color(1,1,1)
end

function DrawPlayer(playerID, leader, vOffset, mouseX, mouseY)
	tipY           = nil
	local rank     = player[playerID].rank
	local skill     = player[playerID].skill
	local name     = player[playerID].name
	local team     = player[playerID].team
	local allyteam = player[playerID].allyteam
	local side     = player[playerID].side
	local red      = player[playerID].red
	local green    = player[playerID].green
	local blue     = player[playerID].blue
	local dark     = player[playerID].dark
	local pingLvl  = player[playerID].pingLvl
	local cpuLvl   = player[playerID].cpuLvl
	local ping     = player[playerID].ping
	local cpu      = player[playerID].cpu    
	local spec     = player[playerID].spec
	local totake   = player[playerID].totake
	local needm    = player[playerID].needm
	local neede    = player[playerID].neede
	local dead     = player[playerID].dead
	local incomeMult     = player[playerID].incomeMult
	local posY     = widgetPosY + widgetHeight - vOffset
	local hasResourceInfo = nil
	local energyLevel, metalLevel, relIncome
	if (teamResources[team] ~= nil) then
		hasResourceInfo = true
		energyLevel   = teamResources[team].currentE / teamResources[team].storageE
		metalLevel   = teamResources[team].currentM / teamResources[team].storageM
		relIncome = teamResources[team].relIncome
	end

	if mouseY >= posY and mouseY <= posY + itemSizeY then tipY = true end
	
	if spec == false then
		if leader == true then                              -- take / share buttons
			if mySpecStatus == false then
				if allyteam == myAllyTeamID then
					if m_take.active == true then
						if totake == true then
							DrawTakeSignal(posY)
							if tipY == true then TakeTip(mouseX) end
						end
					end
					if m_share.active == true and dead ~= true then
						DrawShareButtons(posY, needm, neede)
						if tipY == true then ShareTip(mouseX, playerID) end
					end
				end
			else
				if m_spec.active == true then
					DrawSpecButton(team, posY)                           -- spec button
					if tipY == true then SpecTip(mouseX) end
				end
			end
			gl_Color(red,green,blue,1)	
			if m_rank.active == true then
			--	if playerID < 32 then
					DrawRank(skill, posY, dark)
			--	end
			end
			if m_ID.active == true then
			--	if playerID < 32 then
					DrawID(team, posY, dark)
			--	end
			end
		end

		local nameColorStr = GetPlayerColorStr(red,green,blue)
		gl_Color(red,green,blue,1)
		if m_side.active == true then                        
			DrawSidePic(team, posY, leader, dark)   
		end
		gl_Color(1,1,1,1)	
		if m_name.active == true then
			if (incomeMult ~= 1) then
				DrawName(nameColorStr..name.." \255\255\255\255[+"..math.round(100*(incomeMult-1)).."%]", posY, dark)
			else
				DrawName(nameColorStr..name, posY, dark)
			end
		end
		if m_resources.active == true and hasResourceInfo then
			DrawResourceBars(posY, energyLevel, metalLevel)
			if tipY == true then resourcesTip(mouseX, teamResources[team]) end
		end
		if m_position.active == true and relIncome ~= nil then
			DrawRelativeIncome(posY, relIncome,not mySpecStatus)
		end
			
	else
		gl_Color(1,1,1,1)	
		if m_name.active == true then
			DrawName("\255\153\178\178"..name, posY, false)
		end		
	end

	if m_cpuping.active == true then
		if cpuLvl ~= nil then                              -- draws CPU usage and ping icons (except AI and ghost teams)
			DrawPingCpu(pingLvl,cpuLvl,posY)
			if tipY == true then PingCpuTip(mouseX, ping, cpu) end
		end
	end

	gl_Color(1,1,1,1)
	if playerID < 32 then
	
		if m_chat.active == true and mySpecStatus == false then
			if playerID ~= myPlayerID then
				DrawChatButton(posY)
			end
		end
		
		if m_point.active == true then
			if player[playerID].pointTime ~= nil then
				if player[playerID].allyteam == myAllyTeamID or mySpecStatus == true then
					--if blink == true then
						DrawPoint(posY, player[playerID].pointTime-now)
					--end
					if tipY == true then PointTip(mouseX) end
				end
			end
		end
		
	end
	leader = false
	gl_Texture(false)
end

function DrawTakeSignal(posY)
	if blink == true then -- Draws a blinking rectangle if the player of the same team left (/take option)
		if right == true then
			gl_Color(1,0.95,0)
			gl_Texture(arrowPic)
			gl_TexRect(widgetPosX - 11*scaleFactor, posY, widgetPosX - 1, posY + itemSizeY)
			gl_Color(1,1,1)
			gl_Texture(takePic)
			gl_TexRect(widgetPosX - 57*scaleFactor, posY - 1, widgetPosX - 12*scaleFactor, posY + itemSizeY +1)			
		else
			local leftPosX = widgetPosX + widgetWidth
			gl_Color(1,0.95,0)
			gl_Texture(arrowPic)
			gl_TexRect(leftPosX + 11*scaleFactor, posY, leftPosX + 1, posY + itemSizeY)
			gl_Color(1,1,1)
			gl_Texture(takePic)
			gl_TexRect(leftPosX + 12*scaleFactor, posY - 1, leftPosX + 57*scaleFactor, posY + itemSizeY+1)	
		end
	end	
end

function DrawShareButtons(posY, needm, neede)
	gl_Texture(unitsPic)                       -- Share UNIT BUTTON
	gl_TexRect(m_share.posX + widgetPosX  + 1, posY, m_share.posX + widgetPosX  + 17*scaleFactor, posY + itemSizeY)
	gl_Texture(energyPic)                      -- share ENERGY BUTTON
	gl_TexRect(m_share.posX + widgetPosX  + 19*scaleFactor, posY, m_share.posX + widgetPosX  + 35*scaleFactor, posY + itemSizeY)
	gl_Texture(metalPic)                       -- share METAL BUTTON
	gl_TexRect(m_share.posX + widgetPosX  + 37*scaleFactor, posY, m_share.posX + widgetPosX  + 54*scaleFactor, posY + itemSizeY)
	gl_Texture(lowPic)
	if needm == true then
		gl_TexRect(m_share.posX + widgetPosX  + 37*scaleFactor, posY, m_share.posX + widgetPosX  + 54*scaleFactor, posY + itemSizeY)
	end
	if neede == true then
		gl_TexRect(m_share.posX + widgetPosX  + 19*scaleFactor, posY, m_share.posX + widgetPosX  + 35*scaleFactor, posY + itemSizeY)	
	end
	gl_Texture(false)
end

function DrawSpecButton(team, posY)
	gl_Texture(specPic)
	gl_TexRect(m_spec.posX + widgetPosX  + 1, posY, m_spec.posX + widgetPosX  + 17*scaleFactor, posY + itemSizeY)
	if specTarget == team then 
		gl_Texture(selectPic)
		gl_TexRect(m_spec.posX + widgetPosX  + 1, posY, m_spec.posX + widgetPosX  + 17*scaleFactor, posY + itemSizeY)
	end
	gl_Texture(false)
end

function DrawChatButton(posY)
	gl_Texture(chatPic)
	gl_TexRect(m_chat.posX + widgetPosX  + 1, posY, m_chat.posX + widgetPosX  + 17*scaleFactor, posY + itemSizeY)	
end

function DrawSidePic(team, posY, leader, dark)
	if leader == true then
		gl_Texture(sidePics[team])                       -- sets side image (for leaders)
	else
		gl_Texture(notFirstPic)                          -- sets image for not leader of team players
	end
	gl_TexRect(m_side.posX + widgetPosX  + 1, posY, m_side.posX + widgetPosX  + 17*scaleFactor, posY + itemSizeY) -- draws side image
	if dark == true then	-- draws outline if player color is dark
		--gl_Color(1,1,1)
		if leader == true then
			gl_Texture(sidePicsWO[team])
		else
			gl_Texture(notFirstPicWO)
		end
		gl_TexRect(m_side.posX + widgetPosX +1, posY,m_side.posX + widgetPosX +17*scaleFactor, posY + itemSizeY)
		gl_Texture(false)
	end
	gl_Texture(false)	
end

function DrawRank(skill, posY, dark)

--  rank
--	if rank < 8 then
--		DrawRankImage("luaui/images/advplayerslist/ranks/rank"..rank..".png", posY)
--	else
--		DrawRankImage("luaui/images/advplayerslist/ranks/rank_unknown.png", posY)
--	end
	
	--  show TS skill value instead, if available
	gl_Color(1,1,1,1)
	--UseFont(font)
	TextDraw(skill, m_rank.posX + widgetPosX + 3*scaleFactor, posY + 3*scaleFactor)
	gl_Color(1,1,1,1)
	
end

function DrawRankImage(rankImage, posY)
		gl_Color(1,1,1)
		gl_Texture(rankImage)
		gl_TexRect(widgetPosX + 2, posY, widgetPosX + 18*scaleFactor, posY + itemSizeY)
end

function DrawName(name, posY, dark)
	TextDraw(name, m_name.posX + widgetPosX + 3*scaleFactor, posY + 3*scaleFactor) -- draws name
	--if dark == true then                                   -- draws outline if player color is dark
		--UseFont(fontWOutline)
		--TextDraw(name, m_name.posX + widgetPosX + 3*scaleFactor, posY + 3*scaleFactor)
		--UseFont(font)
	--end
	gl_Color(1,1,1)
end

function DrawID(playerID, posY, dark)
	TextDrawCentered(playerID..".", m_ID.posX + widgetPosX + 10*scaleFactor, posY + 3*scaleFactor) -- draws name
	if dark == true then                                  -- draws outline if player color is dark
		gl_Color(1,1,1)
		--UseFont(fontWOutline)
		TextDrawCentered(playerID..".", m_ID.posX + widgetPosX + 10*scaleFactor, posY + 3*scaleFactor)
		--UseFont(font)
	end
	gl_Color(1,1,1)
end

function DrawPingCpu(pingLvl, cpuLvl, posY)
	gl_Color(pingCpuColors[pingLvl].r,pingCpuColors[pingLvl].g,pingCpuColors[pingLvl].b)
	gl_Texture(pingPic)
	gl_TexRect(m_cpuping.posX + widgetPosX  + 13*scaleFactor, posY, m_cpuping.posX + widgetPosX  + 23*scaleFactor, posY + itemSizeY)
	gl_Color(pingCpuColors[cpuLvl].r,pingCpuColors[cpuLvl].g,pingCpuColors[cpuLvl].b)
	gl_Texture(cpuPic)
	gl_TexRect(m_cpuping.posX + widgetPosX  + 1, posY, m_cpuping.posX + widgetPosX  + 11*scaleFactor, posY + itemSizeY)	
end

function DrawPoint(posY,pointtime)
	if right == true then
		gl_Color(1,0,0,pointtime/20)
		gl_Texture(arrowPic)
		gl_TexRect(widgetPosX - 11*scaleFactor, posY, widgetPosX - 1, posY+ itemSizeY)
		gl_Color(1,1,1,pointtime/20)
		gl_Texture(pointPic)
		gl_TexRect(widgetPosX - 28*scaleFactor, posY, widgetPosX - 12*scaleFactor, posY + itemSizeY)
	else
		leftPosX = widgetPosX + widgetWidth
		gl_Color(1,0,0,pointtime/20)
		gl_Texture(arrowPic)
		gl_TexRect(leftPosX + 11*scaleFactor, posY, leftPosX + 1, posY + itemSizeY)
		gl_Color(1,1,1,pointtime/20)
		gl_Texture(pointPic)
		gl_TexRect(leftPosX + 28*scaleFactor, posY, leftPosX + 12*scaleFactor, posY + itemSizeY)	
	end
	gl_Color(1,1,1,1)
end

function TakeTip(mouseX)
	if right == true then
		if mouseX >= widgetPosX - 57*scaleFactor and mouseX <= widgetPosX - 1 then
			tipText = "Click to take abandoned units"
		end
	else
		local leftPosX = widgetPosX + widgetWidth
		if mouseX >= leftPosX + 1 and mouseX <= leftPosX + 57*scaleFactor then
			tipText = "Click to take abandoned units"
		end		
	end
end

function ShareTip(mouseX, playerID)
	if playerID == myPlayerID then
		if mouseX >= m_share.posX + widgetPosX  + 1 and mouseX <= m_share.posX + widgetPosX  + 17*scaleFactor then
			tipText = "Double click to ask for Unit support"
		elseif mouseX >= m_share.posX + widgetPosX  + 19*scaleFactor and mouseX <= m_share.posX + widgetPosX  + 35*scaleFactor then
			tipText = "Click and drag to ask for Energy"
		elseif mouseX >= m_share.posX + widgetPosX  + 37*scaleFactor and mouseX <= m_share.posX + widgetPosX  + 53*scaleFactor then
			tipText = "Click and drag to ask for Metal"
		end
	else
		if mouseX >= m_share.posX + widgetPosX  + 1 and mouseX <= m_share.posX + widgetPosX  + 17*scaleFactor then
			tipText = "Double click to share Units"
		elseif mouseX >= m_share.posX + widgetPosX  + 19*scaleFactor and mouseX <= m_share.posX + widgetPosX  + 35*scaleFactor then
			tipText = "Click and drag to share Energy"
		elseif mouseX >= m_share.posX + widgetPosX  + 37*scaleFactor and mouseX <= m_share.posX + widgetPosX  + 53*scaleFactor then
			tipText = "Click and drag to share Metal"
		end
	end
end

function SpecTip(mouseX)
	if mouseX >= m_spec.posX + widgetPosX  + 1 and mouseX <= m_spec.posX + widgetPosX  + 17*scaleFactor then
		tipText = "Click to toggle between player and global view"
	end	
end

function PingCpuTip(mouseX, pingLvl, cpuLvl)
	if mouseX >= m_cpuping.posX + widgetPosX  + 13*scaleFactor and mouseX <=  m_cpuping.posX + widgetPosX  + 23*scaleFactor then
		tipText = "Ping: "..pingLvl.." ms"
	elseif mouseX >= m_cpuping.posX + widgetPosX  + 1 and mouseX <=  m_cpuping.posX + widgetPosX  + 11*scaleFactor then		
		tipText = "Cpu Usage: "..cpuLvl.."%"
	end
end

function resourcesTip(mouseX, res)
	if mouseX >= m_resources.posX + widgetPosX  + 13*scaleFactor and mouseX <=  m_resources.posX + widgetPosX  + 50*scaleFactor then
		tipText = " \255\230\230\230M: "..floor(res.currentM).."/"..floor(res.storageM).." (+"..formatNbr(res.incomeM,1)..")"
		tipText = tipText.."  \255\255\255\0E: "..floor(res.currentE).."/"..floor(res.storageE).." (+"..floor(res.incomeE)..")\255\255\255\255"
	end
end

function PointTip(mouseX)
	if right == true then
		if mouseX >= widgetPosX - 28*scaleFactor and mouseX <= widgetPosX - 1 then
			tipText = "Click to reach the last point set by the player"
		end
	else
		local leftPosX = widgetPosX + widgetWidth
		if mouseX >= leftPosX + 1 and mouseX <= leftPosX + 28*scaleFactor then
			tipText = "Click to reach the last point set by the player"
		end
	end
end

function DrawTip(mouseX, mouseY)
		if tipText ~= nil then
			local tw = GetTextWidth(tipText) + 14*scaleFactor
			if right ~= true then tw = -tw end
			gl_Color(0.7,0.7,0.7,0.5)
			gl_Rect(mouseX-tw,mouseY,mouseX,mouseY+30*scaleFactor) -- !! to be changed if the widget can be anywhere on the screen
			gl_Color(1,1,1,1)
			if right == true then
				TextDrawRight(tipText,mouseX-7*scaleFactor,mouseY+10*scaleFactor)
			else
				TextDraw(tipText,mouseX+7*scaleFactor,mouseY+10*scaleFactor)
			end
		end
		tipText        = nil
end

function DrawShareSlider()
	local posY
	if energyPlayer ~= nil then
		posY = widgetPosY + widgetHeight - energyPlayer.posY
		gl_Texture(barPic)
		gl_TexRect(m_share.posX + widgetPosX  + 18*scaleFactor,posY-3*scaleFactor,m_share.posX + widgetPosX  + 36*scaleFactor,posY+58*scaleFactor)
		gl_Texture(energyPic)
		gl_TexRect(m_share.posX + widgetPosX  + 19*scaleFactor,posY+sliderPosition,m_share.posX + widgetPosX  + 35*scaleFactor,posY+itemSizeY+sliderPosition)
		gl_Texture(amountPic)
		if right == true then
			gl_TexRect(m_share.posX + widgetPosX  - 28*scaleFactor,posY-1+sliderPosition, m_share.posX + widgetPosX  + 19*scaleFactor,posY+itemSizeY+1+sliderPosition)
			gl_Texture(false)
			TextDrawCentered(amountEM.."", m_share.posX + widgetPosX  - 5*scaleFactor,posY+3*scaleFactor+sliderPosition)
		else
			gl_TexRect(m_share.posX + widgetPosX  + 76*scaleFactor,posY-1+sliderPosition, m_share.posX + widgetPosX  + 31*scaleFactor,posY+itemSizeY+1+sliderPosition)
			gl_Texture(false)
			TextDrawCentered(amountEM.."", m_share.posX + widgetPosX  + 55*scaleFactor,posY+3*scaleFactor+sliderPosition)				
		end
	elseif metalPlayer ~= nil then
		posY = widgetPosY + widgetHeight - metalPlayer.posY
		gl_Texture(barPic)
		gl_TexRect(m_share.posX + widgetPosX  + 36*scaleFactor,posY-3*scaleFactor,m_share.posX + widgetPosX  + 54*scaleFactor,posY+58*scaleFactor)
		gl_Texture(metalPic)
		gl_TexRect(m_share.posX + widgetPosX  + 37*scaleFactor, posY+sliderPosition,m_share.posX + widgetPosX  + 53*scaleFactor,posY+itemSizeY+sliderPosition)
		gl_Texture(amountPic)
		if right == true then
			gl_TexRect(m_share.posX + widgetPosX  - 12*scaleFactor,posY-1+sliderPosition, m_share.posX + widgetPosX  + 35*scaleFactor,posY+itemSizeY+1+sliderPosition)
			gl_Texture(false)
			TextDrawCentered(amountEM.."", m_share.posX + widgetPosX  + 11*scaleFactor,posY+3*scaleFactor+sliderPosition)
		else
			gl_TexRect(m_share.posX + widgetPosX  + 88*scaleFactor,posY-1+sliderPosition, m_share.posX + widgetPosX  + 47*scaleFactor,posY+itemSizeY+1+sliderPosition)
			gl_Texture(false)
			TextDrawCentered(amountEM.."", m_share.posX + widgetPosX  + 71*scaleFactor,posY+3*scaleFactor+sliderPosition)
		end
	end
end


function DrawResourceBars(posY, energyLevel, metalLevel)

	if (energyLevel ~= nil and metalLevel ~= nil) then
		energyLevel = max(energyLevel,0)
		metalLevel = max(metalLevel,0)
		
		gl_Color(1,1,1)
		gl_Texture(hBarPic)
		gl_TexRect(m_resources.posX + widgetPosX + 0, posY, m_resources.posX + widgetPosX + 50*scaleFactor, posY + 18*scaleFactor)
	
		gl_Color(1,1,1)
		gl_Texture(metalBarPic)
		gl_TexRect(m_resources.posX + widgetPosX + 2, posY + 3*scaleFactor , m_resources.posX + widgetPosX + metalLevel * 48*scaleFactor , posY + 7*scaleFactor)
	
		gl_Color(1,1,1)
		gl_Texture(energyBarPic)
		gl_TexRect(m_resources.posX + widgetPosX + 2, posY + 11*scaleFactor, m_resources.posX + widgetPosX + energyLevel * 48 * scaleFactor, posY + 15*scaleFactor)
		
	
		gl_Texture(false)
		
	end
end

function DrawRelativeIncome(posY, relIncome, highlight)
	if relIncome ~= nil then
		local level = 1	
		if relIncome < 0 then
			relIncome = 0
		end
		if relIncome < 100 then
			level = relIncome / 100
		end
		--gl_Color(1,max(1,2*level),level)
		if (highlight) then
			gl_Color(1,1,1,1)
		else
			gl_Color(0.6,0.6,0.6,1)
		end
		TextDraw(relIncome.."%", m_position.posX + widgetPosX + 20*scaleFactor, posY + 3*scaleFactor,"nc")
		--gl_Rect(m_position.posX + widgetPosX + 0, posY + 0, m_position.posX + widgetPosX + 40*scaleFactor, posY + 18*scaleFactor)
		gl_Color(1,1,1)
	end
end


function GetCpuLvl(cpuUsage)

	-- set the 5 cpu usage levels (green to red)

	if cpuUsage < 0.15 then return 1
	elseif cpuUsage < 0.3 then return 2
	elseif cpuUsage < 0.45 then return 3
	elseif cpuUsage < 0.65 then return 4
	else return 5
	end

end

function GetPingLvl(ping)

	-- set the 5 ping levels (green to red)

	if ping < 0.15 then return 1
	elseif ping < 0.3 then return 2
	elseif ping < 0.7 then return 3
	elseif ping < 1.5 then return 4
	else return 5
	end
end

function SetSidePics()

-- Loads the side pics and side pics outlines for each side.
-- It first tries to look if there is any image in the mod file for the specific side
-- then it looks in the user files for specific side
-- if none of those are found, uses default image and notify the missing image.
-- Include new function that determines dynamic side, 1 = arm, 2 = core. Expand at will to include more factions.

	teamList = Spring_GetTeamList()
	for _, team in ipairs(teamList) do
		teamside = sides[team]
		if teamside then
			if VFS.FileExists(LUAUI_DIRNAME.."images/advplayerslist/"..teamside..".png") then
				sidePics[team] = ":n:luaui/images/advplayerslist/"..teamside..".png"
				if VFS.FileExists(LUAUI_DIRNAME.."images/advplayerslist/"..teamside.."WO.png") then
					sidePicsWO[team] = ":n:luaui/images/advplayerslist/"..teamside.."WO.png"
				else
					sidePicsWO[team] = ":n:luaui/images/advplayerslist/noWO.png"
				end
			else
				if VFS.FileExists(LUAUI_DIRNAME.."images/advplayerslist/"..teamside.."_default.png") then
					sidePics[team] = ":n:luaui/images/advplayerslist/"..teamside.."_default.png"
					if VFS.FileExists(LUAUI_DIRNAME.."images/advplayerslist/"..teamside.."WO_default.png") then
						sidePicsWO[team] = ":n:luaui/images/advplayerslist/"..teamside.."WO_default.png"
					else
						sidePicsWO[team] = ":n:luaui/images/advplayerslist/noWO.png"
					end
				else
					--if teamside ~= "" then
					--	Echo("Image missing for side "..teamside..", using default.")
					--end
					sidePics[team] = ":n:"..LUAUI_DIRNAME.."images/advplayerslist/default.png"
					sidePicsWO[team] = ":n:"..LUAUI_DIRNAME.."images/advplayerslist/defaultWO.png"
				end
			end
		end
	end
end

function SetPingCpuColors()

	-- Sets the colors for ping and CPU icons (green to red)

	pingCpuColors = {
	[1] = {r = 0, g = 1, b = 0},
	[2] = {r = 0.7, g = 1, b = 0},
	[3] = {r = 1, g = 1, b = 0},
	[4] = {r = 1, g = 0.6, b = 0},
	[5] = {r = 1, g = 0, b = 0}
	}
end

function GetDark(red,green,blue)                  	

	-- Determines if the player color is dark. (to determine if white outline is needed)

	if red*1.2 + green*1.1 + blue*0.8 < 0.9 then return true end
	return false
end

function GetPlayerColorStr(red,green,blue)                  	
	if red and green and blue then
		return "\255"..string.char(floor(red*255))..string.char(floor(green*255))..string.char(floor(blue*255))
	end

	return "\255\255\255\255"
end

function changeToPlayerView(teamID)
	Spring_SendCommands("specfullview 6")
	Spring_SendCommands("specteam "..teamID)
	if (Spring.GetMapDrawMode() ~= "los") then
		Spring_SendCommands("togglelos")
	end
	specTarget = teamID
end

function changeToGlobalView()
	Spring_SendCommands("specfullview 3")
	if (Spring.GetMapDrawMode() ~= "normal") then
		Spring_SendCommands("togglelos")
	end
	specTarget = -1
end


function Spec(teamID, forceFullView)
	if specTarget ~= teamID and not forceFullView then
		selectedUnitsTeamId = -1
		selectedUnitsAllyId = -1
		Spring_SendCommands("deselect")
		changeToPlayerView(teamID)
	else
		selectedUnitsTeamId = -1
		selectedUnitsAllyId = -1
		Spring_SendCommands("deselect")
		changeToGlobalView()
	end
end

function CheckUnitSelection()
	local selectedUnits = Spring.GetSelectedUnits()
	local newSelectedUnitsTeamIds = {}
	local newSelectedUnitsAllyIds = {}
	local multipleAllyTeamsSelected = false
	local newSelectedUnitsTeamId = -1
	local newSelectedUnitsAllyId = -1 
	
	local tId = 0
	local aId = 0
	for _,uId in ipairs(selectedUnits) do
		tId = spGetUnitTeam(uId)
		if tId then
			aId = spGetUnitAllyTeam(uId)
			
			newSelectedUnitsTeamIds[tId] = true
			newSelectedUnitsAllyIds[aId] = true
		end
	end

	for tId,_ in pairs(newSelectedUnitsTeamIds) do
		if newSelectedUnitsTeamId == -1 then
			newSelectedUnitsTeamId = tId
			break
		end
	end
	for aId,_ in pairs(newSelectedUnitsAllyIds) do
		if newSelectedUnitsAllyId == -1 then
			newSelectedUnitsAllyId = aId
		else
			multipleAllyTeamsSelected = true
		end
	end
	if multipleAllyTeamsSelected then
		newSelectedUnitsAllyId = -1
	end
	
	--Spring.Echo("allyId="..newSelectedUnitsAllyId.." teamId="..newSelectedUnitsTeamId)
	-- alliances changed
	if selectedUnitsAllyId ~= newSelectedUnitsAllyId then
		-- revert to global view
		if newSelectedUnitsAllyId == -1 then
			changeToGlobalView()
		else
			changeToPlayerView(newSelectedUnitsTeamId)
		end
	else
		-- team/player changed
		if newSelectedUnitsAllyId ~= -1 then
			if selectedUnitsTeamId ~= newSelectedUnitsTeamId then
				changeToPlayerView(newSelectedUnitsTeamId)
			end
		end
	end
	
	selectedUnitsTeamId = newSelectedUnitsTeamId
	selectedUnitsAllyId = newSelectedUnitsAllyId
end

function widget:MousePress(x,y,button)
	-- check chat type button first
	if not Spring.IsGUIHidden() then
		if chatTypeButton.above then	
			if (chatType == CHAT_ALL) then
				chatType = CHAT_ALLIES
				Spring.SendCommands("ChatAlly")
			elseif (chatType == CHAT_ALLIES) then
				chatType = CHAT_SPECTATORS
				Spring.SendCommands("ChatSpec")
			elseif (chatType == CHAT_SPECTATORS) then
				chatType = CHAT_ALL
				Spring.SendCommands("ChatAll")
			end
		elseif clearMarksButton.above then	
			Spring.SendCommands("clearmapmarks")
		end
	end
	
	local t = false       -- true if the object is a team leader
	local clickedPlayer
	local posY
	if button == 1 then
		sliderPosition = 0
		amountEM = 0
		if mySpecStatus == true then
			for _,i in ipairs(drawList) do  -- i = object #
				
				if t == true then
					clickedPlayer = player[i]
					posY = widgetPosY + widgetHeight - clickedPlayer.posY
					if m_spec.active == true then
						if IsOnRect(x, y, m_spec.posX + widgetPosX +1, posY, m_spec.posX + widgetPosX +17*scaleFactor,posY+itemSizeY) then --spec button
							teamToSpec = clickedPlayer.team
							Spring_SendCommands{"specteam "..teamToSpec}
							Spec(teamToSpec)
							return true
						end
					end
				end
				
				if i == -1 then
					t = true
				else
					t = false
					if m_point.active == true then
						if i > -1 and i < 32 then
							clickedPlayer = player[i]
							if clickedPlayer.pointTime ~= nil then
								posY = widgetPosY + widgetHeight - clickedPlayer.posY
								if right == true then
									if IsOnRect(x,y, widgetPosX - 28*scaleFactor, posY - 1,widgetPosX - 12*scaleFactor, posY + itemSizeY+1) then                           --point button
										Spring.SetCameraTarget(clickedPlayer.pointX,clickedPlayer.pointY,clickedPlayer.pointZ,1)          --                                       --
										return true                                                                                       --
									end                                                                                                   --
								else                                                                                                      --
									if IsOnRect(x,y, widgetPosX + widgetWidth + 12*scaleFactor, posY-1,widgetPosX + widgetWidth + 28*scaleFactor, posY + itemSizeY+1) then --
										Spring.SetCameraTarget(clickedPlayer.pointX,clickedPlayer.pointY,clickedPlayer.pointZ,1)                                                  --
										return true
									end
								end
							end
						end
					end
				end
			end
		else
			for _,i in ipairs(drawList) do
				if t == true then
					clickedPlayer = player[i]
					posY = widgetPosY + widgetHeight - clickedPlayer.posY
					if clickedPlayer.allyteam == myAllyTeamID then
						if m_take.active == true then
							if clickedPlayer.totake == true then
								if right == true then
									if IsOnRect(x,y, widgetPosX - 57*scaleFactor, posY - 1,widgetPosX - 12*scaleFactor, posY + itemSizeY+1) then                            --take button
										Take()                                                                                             --
										return true                                                                                        --
									end                                                                                                    --
								else                                                                                                       --
									if IsOnRect(x,y, widgetPosX + widgetWidth + 12*scaleFactor, posY-1,widgetPosX + widgetWidth + 57*scaleFactor, posY + itemSizeY+1) then  --
										Take()                                                                                             --
										return true
									end
								end
							end
						end
						if m_share.active == true and clickedPlayer.dead ~= true then
							if IsOnRect(x, y, m_share.posX + widgetPosX +1, posY, m_share.posX + widgetPosX +17*scaleFactor,posY+itemSizeY) then       -- share units button
								if release ~= nil then                                                                                --
									if release >= now then                                                                            --
										if clickedPlayer.team == myTeamID then                                                        --
											Spring_SendCommands("say a: I need unit support!")                                        -- (ask)
										else                                                                                          --
											local suc = Spring.GetSelectedUnitsCount()
											Spring_SendCommands("say a: I gave "..suc.." units to "..clickedPlayer.name..".")
											local su = Spring.GetSelectedUnits()
											for _,uid in ipairs(su) do
												local ux,uy,uz = Spring.GetUnitPosition(uid)
												Spring.MarkerAddPoint(ux,uy,uz)
											end
											Spring_ShareResources(clickedPlayer.team, "units")                                                            --
										end
									end
									release = nil
								else	
									firstclick = now+1
								end
								return true
							end
							if IsOnRect(x, y, m_share.posX + widgetPosX +17*scaleFactor, posY, m_share.posX + widgetPosX +33*scaleFactor,posY+itemSizeY) then      -- share energy button (initiates the slider)
								energyPlayer = clickedPlayer
								return true
							end
							if IsOnRect(x, y, m_share.posX + widgetPosX +33*scaleFactor, posY, m_share.posX + widgetPosX +49*scaleFactor,posY+itemSizeY) then      -- share metal button (initiates the slider)
								metalPlayer = clickedPlayer
								return true
							end
						end
					end
				end
				if i == -1 then
					t = true
				else
					t = false
					if i > -1 and i < 32 then
						clickedPlayer = player[i]
						posY = widgetPosY + widgetHeight - clickedPlayer.posY
						if m_chat.active == true then
							if IsOnRect(x, y, m_chat.posX + widgetPosX +1, posY, m_chat.posX + widgetPosX +17*scaleFactor,posY+itemSizeY) then                            --chat button
								Spring_SendCommands("chatall","pastetext /w "..clickedPlayer.name..' \1')
								return true                                                                                                                --
							end
						end
						if m_point.active == true then
							if clickedPlayer.pointTime ~= nil then
								if clickedPlayer.allyteam == myAllyTeamID then
									if right == true then
										if IsOnRect(x,y, widgetPosX - 28*scaleFactor, posY - 1,widgetPosX - 12*scaleFactor, posY + itemSizeY+1) then
											Spring.SetCameraTarget(clickedPlayer.pointX,clickedPlayer.pointY,clickedPlayer.pointZ,1)
											return true
										end
									else
										if IsOnRect(x,y, widgetPosX + widgetWidth + 12*scaleFactor, posY-1,widgetPosX + widgetWidth + 28*scaleFactor, posY + itemSizeY+1) then
											Spring.SetCameraTarget(clickedPlayer.pointX,clickedPlayer.pointY,clickedPlayer.pointZ,1)
											return true
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

function widget:MouseMove(x,y,dx,dy,button)
  local moveStartX, moveStartY
	if energyPlayer ~= nil or metalPlayer ~= nil then                            -- move energy/metal share slider
		if sliderOrigin == nil then
			sliderOrigin = y
		end
		sliderPosition = y-sliderOrigin
		if sliderPosition < 0 then sliderPosition = 0 end
		if sliderPosition > 39*scaleFactor then sliderPosition = 39*scaleFactor end
	end
end

function widget:MouseRelease(x,y,button)
	if button == 1 then
		if firstclick ~= nil then                                                  -- double click system for share units
			release = firstclick
			firstclick = nil
		else
			release = nil
		end
		if energyPlayer ~= nil then                                                -- share energy/metal mouse release
			if energyPlayer.team == myTeamID then
				if amountEM == 0 then
					Spring_SendCommands("say a: I need Energy!")
				else
					Spring_SendCommands("say a: I need "..amountEM.." Energy!")
				end
			else
				Spring_ShareResources(energyPlayer.team,"energy",amountEM)
			end
			sliderOrigin = nil
			amountEMMax = nil
			sliderPosition = nil
			amountEM = nil
			energyPlayer = nil
		end
		
		if metalPlayer ~= nil then
			if metalPlayer.team == myTeamID then
				if amountEM == 0 then
					Spring_SendCommands("say a: I need Metal!")
				else
					Spring_SendCommands("say a: I need "..amountEM.." Metal!")
				end
			else
				Spring_ShareResources(metalPlayer.team,"metal",amountEM)
			end
			sliderOrigin = nil
			amountEMMax = nil
			sliderPosition = nil
			amountEM = nil
			metalPlayer = nil
		end
	end
end

function widget:MapDrawCmd(playerID, cmdType, px, py, pz)           -- get the points drawn (to display point indicator)
	if m_point.active == true then
		if cmdType == "point" then
			player[playerID].pointX = px
			player[playerID].pointY = py
			player[playerID].pointZ = pz
			player[playerID].pointTime = now + 20
		end
	end
end

function IsOnRect(x, y, BLcornerX, BLcornerY,TRcornerX,TRcornerY)

	-- check if the mouse is in a rectangle

	return x >= BLcornerX and x <= TRcornerX
	                      and y >= BLcornerY
	                      and y <= TRcornerY

end

local function DrawGreyRect()
	gl_Color(0.2,0.2,0.2,0.8)                                   -- draw show/hide modules buttons
	gl_Rect(widgetPosX, widgetPosY, widgetPosX + widgetWidth, widgetPosY + widgetHeight)
	gl_Color(1,1,1,1)
end

local function DrawTweakButton(module, image)
	gl_Texture(image)
	gl_TexRect(localLeft + localOffset, localBottom + 11*scaleFactor, localLeft + localOffset + 16*scaleFactor, localBottom + 27*scaleFactor)
	if module.active ~= true then
		gl_Texture(crossPic)
		gl_TexRect(localLeft + localOffset, localBottom + 11*scaleFactor, localLeft + localOffset + 16*scaleFactor, localBottom + 27*scaleFactor)
	end
	localOffset = localOffset + 16*scaleFactor
end

local function DrawTweakButtons()
	
	local minSize = (modulesCount-1) * 16*scaleFactor + 2
	localLeft     = widgetPosX
	localBottom   = widgetPosY + widgetHeight - 28*scaleFactor
	localOffset   = 1
	
	if localLeft + minSize > vsx then localLeft = vsx - minSize end
	if localBottom < 0 then localBottom = 0 end

	
	DrawTweakButton(m_rank, rankPic)
	DrawTweakButton(m_side, sidePic)	
	DrawTweakButton(m_ID, IDPic)
	DrawTweakButton(m_name, namePic)
	DrawTweakButton(m_cpuping, cpuPingPic)
	DrawTweakButton(m_share, sharePic)
	DrawTweakButton(m_spec, specPic)
	DrawTweakButton(m_point, pointbPic)
	DrawTweakButton(m_take, takebPic)
	DrawTweakButton(m_seespec, seespecPic)
	DrawTweakButton(m_chat, chatPic)
end

local function DrawArrows()
	gl_Color(1,1,1,0.4)
	gl_Texture(arrowdPic)
	if expandDown == true then
		gl_TexRect(widgetPosX, widgetPosY - 12*scaleFactor, widgetRight, widgetPosY - 4*scaleFactor)
	else
		gl_TexRect(widgetPosX, widgetTop + 12*scaleFactor, widgetRight, widgetTop + 4*scaleFactor)
	end
		gl_Texture(arrowPic)
	if expandLeft == true then
		gl_TexRect(widgetPosX - 4*scaleFactor, widgetPosY, widgetPosX - 12*scaleFactor, widgetTop)
	else
		gl_TexRect(widgetRight + 4*scaleFactor, widgetPosY, widgetRight + 12*scaleFactor, widgetTop)
	end
	gl_Color(1,1,1,1)
	gl_Texture(false)
end

function widget:TweakDrawScreen()

	DrawGreyRect()
	DrawTweakButtons()
	DrawArrows()

end

local function checkButton(module, x, y)
		if IsOnRect(x, y, localLeft + localOffset, localBottom + 11*scaleFactor, localLeft + localOffset + 16*scaleFactor, localBottom + 27*scaleFactor) then
			module.active = not module.active
			SetModulesPositionX()
			localOffset = localOffset + itemSizeY
			return true
		else
			localOffset = localOffset + itemSizeY
			return false
		end
end

function widget:TweakMousePress(x,y,button)
	if button == 1 then
		
		localLeft = widgetPosX
		localBottom = widgetPosY + widgetHeight - 28*scaleFactor
		localOffset = 1
		if localBottom < 0 then localBottom = 0 end
		if localLeft + 181*scaleFactor > vsx then localLeft = vsx - 181*scaleFactor end
		
		if checkButton(m_rank,    x, y) then return true end
		if checkButton(m_side,    x, y) then return true end
		if checkButton(m_ID,      x, y) then return true end
		if checkButton(m_name,    x, y) then return true end
		if checkButton(m_cpuping, x, y) then return true end
		if checkButton(m_share,   x, y) then return true end
		if checkButton(m_spec,    x, y) then return true end
		if checkButton(m_point,   x, y) then return true end
		if checkButton(m_take,    x, y) then return true end
		if checkButton(m_seespec, x, y) then return true end
		if checkButton(m_chat,    x, y) then return true end

		if IsOnRect(x, y, widgetPosX, widgetPosY, widgetPosX + widgetWidth, widgetPosY + widgetHeight) then
			clickToMove = true
			return true
		end
	end
end


function widget:TweakMouseMove(x,y,dx,dy,button)
	if clickToMove ~= nil then
		if moveStartX == nil then                                                      -- move widget on y axis
			moveStartX = x - widgetPosX
		end
		if moveStartY == nil then                                                      -- move widget on y axis
			moveStartY = y - widgetPosY
		end
		widgetPosX = widgetPosX + dx
		widgetPosY = widgetPosY + dy
				
		if widgetPosY <= 0 then
			widgetPosY = 0
			expandDown = false
		end
		if widgetPosY + widgetHeight >= vsy then
			widgetPosY = vsy - widgetHeight
			expandDown = true
		end
		if widgetPosX <= 0 then
			widgetPosX = 0
			expandLeft = false
		end
		if widgetPosX + widgetWidth >= vsx then
			widgetPosX = vsx - widgetWidth
			expandLeft = true
		end
		widgetTop   = widgetPosY + widgetHeight
		widgetRight = widgetPosX + widgetWidth
		if widgetPosX + widgetWidth/2 > vsx/2 then
			right = true
		else
			right = false
		end
	end
end

function widget:TweakMouseRelease(x,y,button)
	clickToMove = nil                                              -- ends the share slider process
end

function widget:GetConfigData(data)      -- send
	if m_side ~= nil then
	return {
		vsx                = vsx,
		vsy                = vsy,
		widgetPosX         = widgetPosX,
		widgetPosY         = widgetPosY,
		widgetRight        = widgetRight,
		widgetTop          = widgetTop,
		expandDown         = expandDown,
		expandLeft         = expandLeft,
		m_rankActive       = m_rank.Active,
		m_sideActive       = m_side.active,
		m_IDActive         = m_ID.active,
		m_nameActive       = m_name.active,
		m_cpupingActive    = m_cpuping.active,
		m_shareActive      = m_share.active,
		m_specActive       = m_spec.active,
		m_pointActive      = m_point.active,
		m_takeActive       = m_take.active,
		m_seespecActive    = m_seespec.active,
		m_chatActive       = m_chat.active,
		m_resourcesActive       = m_resources.active,
		m_positionActive       = m_position.active,
	}
	end
end

function widget:SetConfigData(data)      -- load
	if false then -- DISABLED
	if data.expandDown ~= nil and data.widgetRight ~= nil then
		expandDown   = data.expandDown
		expandLeft   = data.expandLeft
		local oldvsx = data.vsx
		local oldvsy = data.vsy
		if oldvsx == nil then
			oldvsx = vsx
			oldvsy = vsy		
		end
		local dx     = vsx - oldvsx
		local dy     = vsy - oldvsy
		if expandDown == true then
			widgetTop  = data.widgetTop + dy
			if widgetTop > vsy then
				widgetTop = vsy
			end
		else
			widgetPosY = data.widgetPosY
		end
		if expandLeft == true then
			widgetRight = data.widgetRight + dx
			if widgetRight > vsx then
				widgetRight = vsx
			end
		else
			widgetPosX  = data.widgetPosX
		end
	end
	m_rank.active         = SetDefault(data.m_rankActive, true)
	m_side.active         = SetDefault(data.m_sideActive, true)
	m_ID.active           = SetDefault(data.m_IDActive, false)
	m_name.active         = SetDefault(data.m_nameActive, true)
	m_cpuping.active      = SetDefault(data.m_cpupingActive, true)
	m_share.active        = SetDefault(data.m_shareActive, true)
	m_spec.active         = SetDefault(data.m_specActive, true)
	m_point.active        = SetDefault(data.m_pointActive, true)
	m_take.active         = SetDefault(data.m_takeActive, true)
	m_seespec.active      = SetDefault(data.m_seespecActive, true)
	m_chat.active         = SetDefault(data.m_chatActive, false)
	m_resources.active         = SetDefault(data.m_resourcesActive, true)
	m_position.active         = SetDefault(data.m_positionActive, true)
	end -- DISABLED
end

function SetDefault(value, default)
	if value == nil then
		return default
	else
		return value
	end
end

function weightedIncome(metal, energy)
	return metal + energy/60
end


function GetSkill(playerID)
	local customtable = select(10,Spring_GetPlayerInfo(playerID)) -- player custom table
	local unknown = "\255"..string.char(160)..string.char(160)..string.char(160) .. "?"

	if (customtable and type(customtable) == "table") then
		local tsMu = customtable.skill
		local tsSigma = customtable.skilluncertainty
		local tskill = ""
		if tsMu then
			tskill = tsMu and tonumber(tsMu:match("%d+%.?%d*")) or 0
			tskill = round(tskill,0)
			if string.find(tsMu, ")") then
				tskill = "\255"..string.char(190)..string.char(140)..string.char(140) .. tskill -- ')' means inferred from lobby rank
			else
			
				-- show privacy mode
				local priv = ""
				if string.find(tsMu, "~") then -- '~' means privacy mode is on
					priv = "\255"..string.char(200)..string.char(200)..string.char(200) .. "*" 		
				end
				
				--show sigma
				if tsSigma then -- 0 is low sigma, 3 is high sigma
					tsSigma=tonumber(tsSigma)
					local tsRed, tsGreen, tsBlue 
					if tsSigma > 2 then
						tsRed, tsGreen, tsBlue = 190, 130, 130
					elseif tsSigma == 2 then
						tsRed, tsGreen, tsBlue = 140, 140, 140
					elseif tsSigma == 1 then
						tsRed, tsGreen, tsBlue = 195, 195, 195
					elseif tsSigma < 1 then
						tsRed, tsGreen, tsBlue = 250, 250, 250
					end
					tskill = priv .. "\255"..string.char(tsRed)..string.char(tsGreen)..string.char(tsBlue) .. tskill
				else
					tskill = priv .. "\255"..string.char(195)..string.char(195)..string.char(195) .. tskill --should never happen
				end
			end
		else
			tskill = unknown
		end
		return tskill
	end
	
	return unknown
end

function CheckPlayersChange()
	local sorting = false
	local updateSidePics = false
	local f = spGetGameFrame() 

	-- reset ally team income counter
	for _,allyId in ipairs(Spring_GetAllyTeamList()) do
		if allyTeamResources[allyId] then
			allyTeamResources[allyId].income = 0
			allyTeamResources[allyId].relIncome = 0
		else
			allyTeamResources[allyId] = {
				income = 0,
				relIncome = 0
			}
		end
	end

	-- track resources for all teams, if allowed
	local maxIncome = 0
	local maxAllyIncome = 0
	for _,teamId in ipairs(Spring_GetTeamList()) do
	
		-- track resource income and usage
		local currentE,storageE,_,incomeE,_,_,_,_ = Spring_GetTeamResources(teamId,"energy")
		local currentM,storageM,_,incomeM,_,_,_,_ = Spring_GetTeamResources(teamId,"metal")
		local _,_,_,_,_,allyId,_,_ = Spring_GetTeamInfo(teamId)

		if currentE ~= nil then
			local income = weightedIncome(incomeM,incomeE)
			
			teamResources[teamId] = {
				currentE = currentE,
				storageE = storageE,
				currentM = currentM,
				storageM = storageM,
				incomeE = incomeE,
				incomeM = incomeM,
				income = income,
				relIncome = 0
			}
			
			if allyTeamResources[allyId] then
				allyTeamResources[allyId].income = allyTeamResources[allyId].income + income
			else
				allyTeamResources[allyId] = {
					income = income,
					relIncome = 0
				}
			end
			
			if income > maxIncome then
				maxIncome = income
			end
			if allyTeamResources[allyId] and allyTeamResources[allyId].income > maxAllyIncome then
				maxAllyIncome = allyTeamResources[allyId].income
			end
		end
	end
	
	for _,teamId in ipairs(Spring_GetTeamList()) do
		-- set relative resource position
		if (teamResources[teamId]) then
			if maxIncome > 0 then
				teamResources[teamId].relIncome = floor(teamResources[teamId].income * 100 / maxIncome)
			end
		end
		
		-- get updated rows for resigned AIs
		if spGetTeamRulesParam(teamId,"ai_resigned") == "1" and (not player[teamId+32].resignProcessed) then
			player[teamId+32] = CreatePlayerFromTeam(teamId)
			player[teamId+32].resignProcessed = true	
			sorting = true	
		end
		
		-- update sides
		local ingameSide = spGetTeamRulesParam(teamId,"faction_selected")
		if ingameSide and ingameSide ~= sides[teamId] then
			updateSidePics = true
			sides[teamId] = ingameSide
		end
	end
	
	-- set relative resource position for ally teams
	for _,allyId in ipairs(Spring_GetAllyTeamList()) do
		if (allyTeamResources[allyId]) then
			if maxAllyIncome > 0 then
				allyTeamResources[allyId].relIncome = floor(allyTeamResources[allyId].income * 100 / maxAllyIncome)
				--Spring.Echo("allyTeam="..allyId.." relIncome="..allyTeamResources[allyId].relIncome)
			end
		end
	end
	
	for i = 0,31 do
		local name,active,spec,teamID,allyTeamID,pingTime,cpuUsage, country, rank = Spring_GetPlayerInfo(i)
		if active == false then
			if player[i].name ~= nil then                -- NON SPEC PLAYER LEAVING
				if player[i].spec==false then
					if table.maxn(Spring_GetPlayerList(player[i].team,true)) == 0 then
						player[player[i].team + 32] = CreatePlayerFromTeam(player[i].team)
						sorting = true
					end
				end
				
				player[i].name = nil
				player[i] = {}
				
				sorting = true
			end
		elseif active == true and name ~= nil then
			if spec ~= player[i].spec then                                           -- PLAYER SWITCHING TO SPEC STATUS
				if spec == true then
					if table.maxn(Spring_GetPlayerList(player[i].team,true)) == 0 then   -- (update the no players team)
						player[player[i].team + 32] = CreatePlayerFromTeam(player[i].team)
					end
					if player[i].team ~= nil then
						-- send message to yourself to signal the player's change to spectator
						Spring.SendMessageToPlayer(myPlayerID,"<PLAYER"..i.."> resigned and is now spectating" )
					end

					player[i].team = nil                                                 -- remove team
				end
				player[i].spec = spec                                                  -- consider player as spec
				sorting = true
			end
			if teamID ~= player[i].team then                                               -- PLAYER CHANGING TEAM
				if table.maxn(Spring_GetPlayerList(player[i].team,true)) == 0 then           -- check if there is no more player in the team + update
					player[player[i].team + 32] = CreatePlayerFromTeam(player[i].team)         
				end
				player[i].team = teamID
				local r,g,b = Spring_GetTeamColor(teamID)
				r,g,b,_ = convertColor(r,g,b,0) 
				player[i].red, player[i].green, player[i].blue = r,g,b
				player[i].dark = GetDark(player[i].red, player[i].green, player[i].blue)
				player[i].skill = GetSkill(i) 
				sorting = true
			end
			if player[i].name == nil then
				player[i] = CreatePlayer(i)
			end
			if allyTeamID ~= player[i].allyteam then
				player[i].allyteam = allyTeamID
				updateTake(allyTeamID)
				sorting = true
			end
			
			-- Update stall / cpu / ping info / resources for each player
			
			if player[i].spec == false then
				player[i].needm   = GetNeed("metal",player[i].team)
				player[i].neede   = GetNeed("energy",player[i].team)
				player[i].rank = rank
			else
				player[i].needm   = false
				player[i].neede   = false
			end

			player[i].pingLvl = GetPingLvl(pingTime)
			player[i].cpuLvl  = GetCpuLvl(cpuUsage)
			player[i].ping    = pingTime*1000-((pingTime*1000)%1)
			player[i].cpu     = cpuUsage*100-((cpuUsage*100)%1)
			
			-- send warning message to yourself if player is lagging behind
			if player[i].spec == false and (not spIsReplay()) then
				if (tonumber(player[i].ping) > PLAYER_LAG_WARNING_THRESHOLD_MS and (f > 0 and (not latestLagWarningByPlayer[i] or f - latestLagWarningByPlayer[i] > PLAYER_LAG_WARNING_DELAY_F ))) then
					Spring.SendMessageToPlayer(myPlayerID,"WARNING: <PLAYER"..i.."> is lagging behind "..(floor(tonumber(player[i].ping)/1000)).."s" )
					Spring.SendCommands("pause 1") -- pause the game
					latestLagWarningByPlayer[i] = f
				end
			end
		end
	end
	if sorting == true then    -- sorts the list again if change needs it
		SortList()
		SetModulesPositionX()    -- change the X size if needed (change of widest name)
	end
	if updateSidePics == true then
		SetSidePics()
	end
	updateExtraButtonGeometry()
end

function updateTake(allyTeamID)
	for i = 0,teamN-1 do
		if player[i + 32].allyTeam == allyTeamID then
			player[i + 32] = CreatePlayerFromTeam(i)
		end
	end
end

function GetNeed(resType,teamID)
	local current, _, pull, income = Spring_GetTeamResources(teamID, resType)
		if current == nil then return false end
	local loss =  pull - income
	if loss > 0 then
		if loss*5 > current then
			return true
		end
	end
	return false
end

function Take()

	-- sends the /take command to spring

	Spring_SendCommands{"take"}
	Spring_SendCommands{"say a: I took the abandoned units."}
	for i = 0,63 do
		if player[i].allyteam == myAllyTeamID then
			if player[i].totake == true then
				player[i] = CreatePlayerFromTeam(player[i].team)
				SortList()
			end
		end
	end
	return
end

function widget:GameStart()
	-- remove engine player list
	Spring.SendCommands("info 0")
	
	Init()
end

function widget:TeamDied(teamID)
	player[teamID+32]        = CreatePlayerFromTeam(teamID)
	player[teamID+32].totake = false
	SortList()
	updateExtraButtonGeometry()
end

function widget:ViewResize(viewSizeX, viewSizeY)
	local dx, dy = vsx - viewSizeX, vsy - viewSizeY
	Echo("view resized from "..vsx.."*"..vsy.." to "..viewSizeX.."*"..viewSizeY.." edown="..tostring(expandDown).." eleft="..tostring(expandLeft))
	vsx, vsy = viewSizeX, viewSizeY
	if expandDown == true then
		widgetTop  = widgetTop - dy
		widgetPosY = widgetTop - widgetHeight
	end
	if expandLeft == true then
		widgetRight = widgetRight - dx
		widgetPosX  = widgetRight - widgetWidth
	end
	-- force widget to the bottom right corner
	widgetRight = vsx
	widgetPosX = widgetRight - widgetWidth
	
	updateExtraButtonGeometry()
end


-- Coord in % (resize) geometry will not be done
-- ajouter les décryptages de messages "widget:AddConsoleLine(line,priority)" appelé à chaque fois qu'il doit ajouter une ligne
