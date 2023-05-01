include("colors.h.lua")
include("keysym.h.lua")

function widget:GetInfo()
	return {
		name      = "Message Console",
		desc      = "chat console",
		author    = "raaar, based on message separator widget by Kloot & BD",
		date      = "2022",
		license   = "PD",
		layer     = math.huge,
		enabled   = true
	}
end


local BOX_BORDER_SIZE				= 1
local PLAYER_MSG_BOX_MIN_W		= BOX_BORDER_SIZE * 4
local PLAYER_MSG_BOX_MIN_H		= BOX_BORDER_SIZE * 4
local FONT_MAX_SIZE				= 30
local ROSTER_SORT_TYPE			= 1
local SYSTEM_PREFIX_PATTERNS	= {"%[~"}
local NAME_PREFIX_PATTERNS		= {"%<", "%["}
local NAME_POSTFIX_PATTERNS		= {"%> ", "%] "}
local numPlayerMessages			= 0

local SHOW_KEY					= KEYSYMS.SPACE
-- how many game-logic frames to wait
-- before clearing message buffers at
-- normal (1x) speed, 30 frames per sec
local DELAY_BEFORE_CLEAR			= 15 * 30
-- clear boxes on resize since text
-- might otherwise end up outside them
 
local playerMsgHistory = {}
if (WG.playerMsgHistory) then
	playerMsgHistory = WG.playerMsgHistory 
else
	WG.playerMsgHistory = playerMsgHistory
end

local SYSTEM_MSG_HISTORY			= {}
-- "n": ignore embedded colors, "o/O": black/white outline
local FONT_RENDER_STYLES			= {"", "o", "O"}
local MIN_ALPHA					= 0.0
local MAX_ALPHA					= 1.0
local playerBoxAlpha			= MIN_ALPHA
local playerBoxFillColor			= {0.0, 0.0, 0.0, 0.6}
local playerBoxLineColor			= {0.0, 0.0, 0.0, 1}
local PLAYER_TEXT_OUTLINE_COLOR		= {0.00, 0.00, 0.20, 0.20}
local PLAYER_TEXT_DEFAULT_COLOR		= {0.7, 0.7, 0.7, 1.0}
local PLAYER_TEXT_SPECTATOR_COLOR	= {0.4, 0.5, 0.5, 1.0}
local SYSTEM_TEXT_COLOR				= { 1.0,  1.0,  1.0, 1.0}
local FILL_ALPHA = 0.6 
local LINE_ALPHA = 1.0
-- use color codes to define font colors, otherwise uses gl_Color, unfortunately, colored font with outline doesn't seems to be supported when this is off
local USE_COLOR_CODES = true
-- timer-related variables
local currentFrame				= 0
local lastPlayerMsgClearFrame	= 0
local lastPlayerMsgScrollFrame	= 0
-- table mapping names to colors
local PLAYER_COLOR_TABLE			= {}		-- indexed by player name
local TEAM_COLOR_TABLE				= {}

-- message patterns our filter should match
local MESSAGE_FILTERS = { 
	"ClientReadNet",
	"to access the quit menu",
	"ParseUniformsTable",
	"SDL_WINDOWEVENT"
}

-- has time to visually clear messages been reached?
-- (note: only used in scrollable-history mode)
local drawPlayerMessages		= true
-- which font render-style are we currently using?
-- (currently only set here in favor of formula)
local FONT_STYLES_INDEX			= 1
-- should key commands be enabled?
local KEYS_ENABLED				= 0
local LAST_LINE					= ""
local FILTER_SYSTEM_MESSAGES = 1
local MESSAGE_WRAPPING = 0 
local TEXT_OUTLINING = 0
local FONT_SIZE = 15
local FONT_RENDER_STYLE = FONT_RENDER_STYLES[1]
local BORDER_MASKS = { 0,0,0,0 }
local MAX_LINE_STRING_LENGTH = 75
local VISIBILITY_HINT_SHOWN = false
local scaleFactor = 1 
local scrollBarCoords = {x1=0,x2=0,y1=0,y2=0}
local SCROLLBAR_CLICK_TOLERANCE = 10 

-- Compensate for gl.Text y positioning change between 0.80.0 and 0.80.1
if not gl.TextAdjusted then
   local glText = gl.Text
   gl.Text = function(text,x,y,size,options)
      if text then
	      if size then
	         glText(text,x,y+size/4,size,options)
	      else
	         glText(text,x,y,size,options)
	      end
      end
   end
   gl.TextAdjusted = true
end
local SendCommands = Spring.SendCommands
local GetMouseState = Spring.GetMouseState
local GetPlayerRoster = Spring.GetPlayerRoster
local GetTeamColor = Spring.GetTeamColor
local GetGameFrame = Spring.GetGameFrame
local spGetPlayerList = Spring.GetPlayerList
local spGetPlayerInfo = Spring.GetPlayerInfo
local spGetTeamList = Spring.GetTeamList
local spGetGameSeconds = Spring.GetGameSeconds
local spGetTimer = Spring.GetTimer
local spDiffTimers = Spring.DiffTimers
local spGetLastUpdateSeconds = Spring.GetLastUpdateSeconds
local spGetDrawFrame = Spring.GetDrawFrame

local math_ceil 		= math.ceil
local math_floor 		= math.floor
local math_min 			= math.min
local math_max			= math.max
local string_char		= string.char
local gl_Color 			= gl.Color
local gl_Text 			= gl.Text
local gl_GetTextWidth 	= gl.GetTextWidth
local gl_Rect 			= gl.Rect

local glCreateList	= gl.CreateList
local glDeleteList	= gl.DeleteList
local glCallList	= gl.CallList

local glListRefreshIdx = -1
local glListRefreshKey = nil
local glList = nil
local refTimer = spGetTimer()

local mousePressed = false

function widget:Initialize()
	-- disable default console
	SendCommands({"console 0"})

	setDefaultUserVars(-1, -1, false)
	buildTable()
end

function widget:Shutdown()
	-- enable default console
	SendCommands({"console 1"})
end


function convertColor(colorarray)
	local red = math_ceil(colorarray[1]*255) --+ 100
	local green = math_ceil(colorarray[2]*255) --+ 100
	local blue = math_ceil(colorarray[3]*255) --+ 100
	-- hack to avoid outline
	red = 50+red * 1.1
	green = 50+green * 1.1
	blue = 50+blue * 1.1
	--if red + green < 255 then
	--	red = red + 50
	--	green = green + 50
	--end
	red = math_max( red, 1 )
	green = math_max( green, 1 )
	blue = math_max( blue, 1 )
	red = math_min( red, 255 )
	green = math_min( green, 255 )
	blue = math_min( blue, 255 )
	return string_char(255,red,green,blue)
end

function widget:KeyPress(key, modifier, isRepeat)
	if (key == SHOW_KEY) then
		playerBoxAlpha = MAX_ALPHA
		drawPlayerMessages = true
		-- scroll to latest message
		scrollToLatestPlayerMessage()
		return
	end
end

function reloadMessageBox(msgHistory)
	Spring.Echo("message history had "..tostring(#msgHistory).." lines")
	playerMsgHistory = msgHistory
	numPlayerMessages = #msgHistory
	scrollToLatestPlayerMessage()
end
WG.reloadMessageBox = reloadMessageBox

function mouseOverPlayerMessageBox(x, y)
	-- use <BOX_BORDER_SIZE>-pixel borders to make resizing less problematic
	if (x > (PLAYER_MSG_BOX_X_MIN + BOX_BORDER_SIZE) and x < (PLAYER_MSG_BOX_X_MAX - BOX_BORDER_SIZE)) then
		if (y < (PLAYER_MSG_BOX_Y_MAX - BOX_BORDER_SIZE) and y > (PLAYER_MSG_BOX_Y_MIN + BOX_BORDER_SIZE)) then
			return true
		end
	end

	return false
end

function mouseOverPlayerMessageBoxScrollBar(x, y)
	if (x > scrollBarCoords.x1 - SCROLLBAR_CLICK_TOLERANCE and x < scrollBarCoords.x2 + SCROLLBAR_CLICK_TOLERANCE) then
		if (y < scrollBarCoords.y2 and y > scrollBarCoords.y1) then
			return true
		end
	end

	return false
end

function handleScrollBar(mx,my,button)
	if (mouseOverPlayerMessageBoxScrollBar(mx,my) and numPlayerMessages > 15) then
		local scrollBarFraction = 1 - (my - scrollBarCoords.y1)/(scrollBarCoords.y2 - scrollBarCoords.y1)
		
		-- scroll to match the fraction
		local curMin = messageFrameMin
		local targetMin = 1 + math_floor(numPlayerMessages * scrollBarFraction)
		local shift = targetMin - curMin
		
		messageFrameMin = messageFrameMin + shift
		messageFrameMax = messageFrameMax + shift
		
		lastPlayerMsgScrollFrame = currentFrame
		return true
	end
	
	return false
end

function widget:MouseMove(mx,my,dx,dy,button)
	return handleScrollBar(mx,my,button)
end

function widget:MouseRelease(mx,my,button)
	mousePressed = false
	return handleScrollBar(mx,my,button)
end

function widget:MousePress(mx,my,button)
	mousePressed = true
	return handleScrollBar(mx,my,button)
end

function widget:MouseWheel(up, value)
	local x,y,_,_,_ = GetMouseState()
	-- scroll history only if there's some messages on screen already, don't scroll if gui is hidden
	if mouseOverPlayerMessageBox( x, y ) and numPlayerMessages > 0 and drawPlayerMessages then
		-- if we are in non-transparent rendering mode
		-- then make sure scrolling causes box to appear
		-- (as well as any messages in box)
		playerBoxAlpha = MAX_ALPHA
		drawPlayerMessages = true
		if up then
			local steps = 3
			while (messageFrameMin > 1 and steps > 0) do
				messageFrameMin = messageFrameMin - 1
				messageFrameMax = messageFrameMax - 1
				steps = steps - 1
			end
			lastPlayerMsgScrollFrame = currentFrame
		else
			local steps = 3
			while (messageFrameMax < numPlayerMessages and steps > 0) do
				messageFrameMin = messageFrameMin + 1
				messageFrameMax = messageFrameMax + 1
				steps = steps - 1
			end
			lastPlayerMsgScrollFrame = currentFrame
		end
		return true
	end
	return false
end

-- set default values for user-configurable vars
-- if they haven't yet been initialized (called
-- (from Initialize() and ViewResize() call-ins)
function setDefaultUserVars(sizeX, sizeY, useParams)

	if (useParams == true) then
		SIZE_X = sizeX
		SIZE_Y = sizeY
	else
		-- get dimensions of our OGL viewport
		SIZE_X, SIZE_Y = widgetHandler:GetViewSizes()
		--Spring.Echo("VIEWPORT SX="..tonumber(SIZE_X).." SY="..tonumber(SIZE_Y))
	end

	if (SIZE_X > 1 and SIZE_Y > 1) then
		
		if (SIZE_Y ~= 1080) then
			scaleFactor = SIZE_Y / 1080
		else
			scaleFactor = 1
		end
		
		-- default positions and dimensions of message boxes are relative to viewport size
		if ((PLAYER_MSG_BOX_W == nil or PLAYER_MSG_BOX_H == nil)) then
			PLAYER_MSG_BOX_X_MIN = (SIZE_X / 4)
			PLAYER_MSG_BOX_X_MAX = (SIZE_X / 4) * 3

			PLAYER_MSG_BOX_W = PLAYER_MSG_BOX_X_MAX - PLAYER_MSG_BOX_X_MIN
			PLAYER_MSG_BOX_H = (SIZE_Y / 8)

			PLAYER_MSG_BOX_Y_MAX = SIZE_Y - 10 - (60) * scaleFactor
			PLAYER_MSG_BOX_Y_MIN = PLAYER_MSG_BOX_Y_MAX - PLAYER_MSG_BOX_H
		else
			-- turn serialized relative coordinates into absolute ones again
			-- (if coordinates are already absolute then we should reposition
			-- and/or resize boxes, but for now just do nothing)
			if ((PLAYER_MSG_BOX_X_MIN < 1 and PLAYER_MSG_BOX_Y_MAX < 1)) then
				PLAYER_MSG_BOX_X_MIN = PLAYER_MSG_BOX_X_MIN * SIZE_X
				PLAYER_MSG_BOX_Y_MAX = PLAYER_MSG_BOX_Y_MAX * SIZE_Y
				
				-- restore message box dimensions
				PLAYER_MSG_BOX_X_MAX = PLAYER_MSG_BOX_X_MIN + PLAYER_MSG_BOX_W
				PLAYER_MSG_BOX_Y_MIN = PLAYER_MSG_BOX_Y_MAX - PLAYER_MSG_BOX_H
			end
		end
		
		FONT_SIZE = 15 * scaleFactor
		
		MAX_NUM_PLAYER_MESSAGES = math_floor((PLAYER_MSG_BOX_H - FONT_SIZE) / FONT_SIZE)

		messageFrameMin = 1
		messageFrameMax = MAX_NUM_PLAYER_MESSAGES
	end
end


function clearPlayerMessageHistory()
	playerMsgHistory = {}
	numPlayerMessages = 0
end


function scrollToLatestPlayerMessage()
	while (messageFrameMax < numPlayerMessages) do
		messageFrameMin = messageFrameMin + 1
		messageFrameMax = messageFrameMax + 1
	end
end


-- if our viewport is resized then we need to
-- reposition (and resize?) our message boxes
-- accordingly since they might end up outside
-- viewport (note: also called on startup with
-- nil parameters!)
function widget:ViewResize(newSizeX, newSizeY)
	if (newSizeX ~= nil and newSizeY ~= nil) then
		if (newSizeX > 1 and newSizeY > 1) then
			setDefaultUserVars(newSizeX, newSizeY, true)
			
			-- scroll to latest message
			scrollToLatestPlayerMessage()
		end
	end
end

-- process console line
function processConsoleLine(line, playerName, playerColor, playerFontStyle)
	--[[
	if (FILTER_SYSTEM_MESSAGES == 1) then
		for _,str in pairs(MESSAGE_FILTERS) do
			if (string.find(line, str) ~= nil) then
				return
			end
		end
	end
	]]--
	
	-- autoscroll if bottom of message
	-- frame is equal to last message
	if (messageFrameMax == numPlayerMessages) then
		messageFrameMin = messageFrameMin + 1
		messageFrameMax = messageFrameMax + 1
	end

	-- check if it's a system message, and use its style instead
	if string.len(playerName) == 0 then
		playerName = "SYSTEM"
		playerColor = SYSTEM_TEXT_COLOR
		playerFontStyle = FONT_RENDER_STYLES[2]
	end

	drawPlayerMessages = true

	lastPlayerMsgClearFrame = currentFrame
	playerMsgHistory[numPlayerMessages + 1] = {playerColor, playerFontStyle, getTimeStr()..line}
	numPlayerMessages = numPlayerMessages + 1
	playerBoxAlpha = MAX_ALPHA

end


-- add message to player or system buffer
function widget:AddConsoleLine(line)
	if (string.len(line) > 0) then
		if (FILTER_SYSTEM_MESSAGES == 1) then
			for _,str in pairs(MESSAGE_FILTERS) do
				if (string.find(line, str) ~= nil) then
					return
				end
			end
		end
	
		local playerName = getPlayerName(line)
		local playerColor = getPlayerColor(playerName)
		local playerFontStyle = getPlayerFontStyle(playerColor)
		local prefix = ""
		local lineSep = ""	
		if ( line == LAST_LINE ) then
			return -- drop duplicate messages
		end
		LAST_LINE = line
	
		-- MFAI lines, apply team color
		local aiPos = string.find(line, "--- AI")
		if (aiPos) then
			local teamId = string.match(line,"%-%-%- AI (%d+):")
			playerColor = TEAM_COLOR_TABLE["t"..teamId]
			playerName = " " -- to fool processConsoleLine into colouring the text..
			if (playerColor == nil) then
				playerColor = PLAYER_TEXT_DEFAULT_COLOR 
			end
		end
	
		if (string.len(playerName) > 0) then
			prefix = string.sub(line,1,string.find(line, " "))
			-- lineSep was "...", "-" might be an option but maybe it's best to leave it empty
		end
		
		if(string.len(line) < MAX_LINE_STRING_LENGTH and string.find(line,'\n',1,true) ==nil) then
			processConsoleLine(line,playerName,playerColor,playerFontStyle)
		else
			local nextStr = line
			local currentStr = ""
			local iter = 0
			local idx = 0
			local cutoffIndex = MAX_LINE_STRING_LENGTH
			while (string.len(nextStr) > 0) do
				iter = iter +1
				idx,_ = string.find(nextStr,'\n',1,true)

				if iter < 30 and idx ~= nil and idx <= MAX_LINE_STRING_LENGTH then
					currentStr = string.sub(nextStr, 1 , idx-1)
					nextStr = prefix..string.sub(nextStr, idx + 1)
				elseif  (iter < 30 and string.len(nextStr) > MAX_LINE_STRING_LENGTH) then
					cutoffIndex = MAX_LINE_STRING_LENGTH
					-- if cutoff index is not a space, backtrack until a space is found to avoid breaking words
					for shift=0,30 do
						if (cutoffIndex-shift > 1) then
							if nextStr:sub(cutoffIndex-shift,cutoffIndex-shift) == " " then
								cutoffIndex = cutoffIndex - shift
								break
							end
						end
					end
				
					currentStr = string.sub(nextStr, 1 , cutoffIndex)..lineSep
					nextStr = prefix..lineSep..string.sub(nextStr, cutoffIndex + 1)
				else 
					currentStr = nextStr
					nextStr = ""
				end
				
				--processConsoleLine(iter.."!"..string.len(currentStr).." vs "..string.len(nextStr).."! "..currentStr,playerName,playerColor,playerFontStyle)
				processConsoleLine(currentStr,playerName,playerColor,playerFontStyle)
			end
		end
	end
end

function drawAllElements()
	-- show message box and scroll to latest message on mouse over if it was invisible
	local mx,my,_,_,_ = GetMouseState()
	if (not drawPlayerMessages) and mouseOverPlayerMessageBox( mx, my ) then
		drawVisibilityHint()
	end
	
	-- is it time to scroll back to the latest message?
	if ((currentFrame - lastPlayerMsgScrollFrame) > DELAY_BEFORE_CLEAR) then
		scrollToLatestPlayerMessage()
	end
	
	
	playerBoxFillColor[4] = FILL_ALPHA * playerBoxAlpha
	playerBoxLineColor[4] = LINE_ALPHA * playerBoxAlpha
	drawBox(PLAYER_MSG_BOX_X_MIN, PLAYER_MSG_BOX_Y_MAX, PLAYER_MSG_BOX_W, PLAYER_MSG_BOX_H, playerBoxFillColor, playerBoxLineColor)
	
	local y = PLAYER_MSG_BOX_Y_MAX - (FONT_SIZE + 6)
	
	-- because playerMsgHistory is never reset to {}
	-- while scrollable history enabled we need another
	-- way to determine if we should draw messages
	if (drawPlayerMessages == true) then
		drawScrollBar()
	
		for index = messageFrameMin, messageFrameMax, 1 do
			if (index <= numPlayerMessages) then
				if playerMsgHistory[index] ~= nil then
					local playerColor = playerMsgHistory[index][1]
					local playerFontStyle = playerMsgHistory[index][2]
					local playerMessage = playerMsgHistory[index][3]
					local playerMessageWidth = (gl_GetTextWidth(playerMessage) * FONT_SIZE )
		
	
					local text = playerMessage
					local style = playerFontStyle
					if ( USE_COLOR_CODES ) then
						local colorcode = convertColor(playerColor)
						text = colorcode..playerMessage
					else
						style = playerFontStyle.."n"
					end
					gl_Color(playerColor)
					gl_Text(text, PLAYER_MSG_BOX_X_MIN+5, y, FONT_SIZE, style)
				end
			end
	
			y = y - FONT_SIZE
		end
	end
end

function widget:DrawScreen()
	currentFrame = GetGameFrame()
	
	-- is it time to hide message box
	if ((currentFrame - lastPlayerMsgClearFrame) > DELAY_BEFORE_CLEAR) and ((currentFrame - lastPlayerMsgScrollFrame) > DELAY_BEFORE_CLEAR) then
		drawPlayerMessages = false

		lastPlayerMsgClearFrame = currentFrame
		playerBoxAlpha = MIN_ALPHA
	end

	-- workaround for AMD gpu crashing due to display list usage on this widget
	if Platform.glHaveAMD then
		drawAllElements()
	else
		local refreshIdx = math_floor(spDiffTimers(spGetTimer(),refTimer)*3)
		local refreshKey = messageFrameMax
		-- refresh gl list only a few times per second
		if (not glList) or refreshIdx ~= glListRefreshIdx or refreshKey ~= glListRefreshKey then
			if (glList) then
				glDeleteList(glList)
			end 
			glList = glCreateList(drawAllElements)
			
			glListRefreshKey = refreshKey
			glListRefreshIdx = refreshIdx
		end
		glCallList(glList)
	end
end

function buildTable()
	--local playerRoster = GetPlayerRoster(ROSTER_SORT_TYPE)
	local playerIds = spGetPlayerList()
	for index,pId in ipairs(playerIds) do
		local playerName,active,spectator,playerTeam = spGetPlayerInfo(pId)
		if (not spectator) then
			local r, g, b, a = GetTeamColor(playerTeam)
			PLAYER_COLOR_TABLE[playerName] = {r, g, b, a}
		else
			PLAYER_COLOR_TABLE[playerName] = PLAYER_TEXT_SPECTATOR_COLOR
		end
	end
	
	local teamIds = spGetTeamList() 
	for _,tId in ipairs (teamIds) do
		local r, g, b, a = GetTeamColor(tId)
		TEAM_COLOR_TABLE["t"..tId] = {r, g, b, a}
	end
	
	
end


-- extract a player name from a text message
-- (note: this can generate false positives if
-- player has name of form "<XYZ>" or "[XYZ]"
-- for certain system messages since strings
-- returned will then be "XYZ>" and "XYZ]"
-- rather than "")
function getPlayerName(playerMessage)
	-- if on loading sequence, assume it's not a player
	if (string.find(playerMessage, SYSTEM_PREFIX_PATTERNS[1]) == 1) then
		return ""
	end

	local i1 = string.find(playerMessage, NAME_PREFIX_PATTERNS[1])
	local i2 = string.find(playerMessage, NAME_POSTFIX_PATTERNS[1])

	if (i1 ~= nil and i2 ~= nil and i1 == 1) then
		-- player messages start with "<" so start index is 2
		return (string.sub(playerMessage, 2, i2 - 1))
	end

	local j1 = string.find(playerMessage, NAME_PREFIX_PATTERNS[2])
	local j2 = string.find(playerMessage, NAME_POSTFIX_PATTERNS[2])

	if (j1 ~= nil and j2 ~= nil and j1 == 1) then
		-- spectator messages start with "[" so start index is 2
		return (string.sub(playerMessage, 2, j2 - 1))
	end

	-- no match found
	return ""
end


-- get a player's team-color
function getPlayerColor(playerName)
	-- this should have O(log n) or O(1) time complexity
	local playerColor = PLAYER_COLOR_TABLE[playerName]

	if (playerColor ~= nil) then
		return playerColor
	else
		-- if playerName was not valid key then getPlayerName()
		-- either found no match at all or false positive one,
		-- or table missing entry for actual player (due to
		-- pathing delays etc.)
		if (string.len(playerName) > 0) then
			-- rebuild table in case this was message from real player (ie.
			-- getPlayerName() found true positive) we didn't know about yet
			buildTable()
		end

		local playerColor = PLAYER_COLOR_TABLE[playerName]
		if (playerColor ~= nil) then
			return playerColor
		else
			return PLAYER_TEXT_DEFAULT_COLOR
		end
	end
end


-- get a player's font outline-mode string
-- (only used if font outlining is enabled)
function getPlayerFontStyle(playerColor)

	local luminance  = (playerColor[1] * 0.299) + (playerColor[2] * 0.587) + (playerColor[3] * 0.114)

	if (luminance > 0.25) then
		-- black outline
		playerFontStyle = FONT_RENDER_STYLES[2]
	else
		-- white outline
		playerFontStyle = FONT_RENDER_STYLES[3]
	end

	--font:SetOutlineColor(0,0,0,1)
	return playerFontStyle
end


function drawBox(left, top, width, height, fillColor, lineColor)
	if (width < 2 or height < 2) then
		return false
	end

	gl_Color(lineColor)
	--gl_Rect(left - 1, top + 1, left + width + 1, top - height - 1)
	
	-- left/right border
	gl_Rect(left - 1, top + 1, left, top - height - 1)
	gl_Rect(left + width, top + 1, left + width + 1, top - height - 1)
	-- top/bottom border
	gl_Rect(left - 1, top + 1, left + width + 1, top)
	gl_Rect(left - 1, top - height, left + width + 1, top - height - 1)

	gl_Color(fillColor)
	gl_Rect(left, top, left + width, top - height)
end

-- draw scroll bar
function drawScrollBar()

	local boxWidth = FONT_SIZE/1.5
	local boxHeight = PLAYER_MSG_BOX_H-10
	
	scrollBarCoords.x1 = PLAYER_MSG_BOX_X_MAX - (boxWidth+5)
	scrollBarCoords.x2 = PLAYER_MSG_BOX_X_MAX - 5 
	scrollBarCoords.y1 = PLAYER_MSG_BOX_Y_MAX - 5 - boxHeight
	scrollBarCoords.y2 = PLAYER_MSG_BOX_Y_MAX - 5
		
	-- outer box
	drawBox(PLAYER_MSG_BOX_X_MAX - (boxWidth+5), scrollBarCoords.y2, boxWidth, boxHeight, {0.1, 0.1, 0.1, 0.6},  {0.4, 0.4, 0.4, 1})

	-- messageFrameMin : first line visible
	-- messageFrameMax : last line visible
	-- numPlayerMessages : number of message lines
	
	local viewFraction = 1
	local viewLines = (messageFrameMax - messageFrameMin)
	if numPlayerMessages > 0 and numPlayerMessages > viewLines then
		viewFraction = viewLines / numPlayerMessages
	end
	local barWidth = boxWidth / 3
	local maxBarHeight = boxHeight-4
	local minBarHeight = 2*FONT_SIZE
	local barHeight =  math.max(minBarHeight,viewFraction*maxBarHeight)
	local barOffset = 0
	local remainingHeight = maxBarHeight - barHeight
	
	if (numPlayerMessages > viewLines) then
		barOffset = math_min(math_max(0,remainingHeight * (messageFrameMin-1) / (numPlayerMessages - viewLines -1)),maxBarHeight-barHeight)
	end 
	
	-- inner box / bar
	drawBox(PLAYER_MSG_BOX_X_MAX - (boxWidth+5)+(boxWidth-barWidth)/2, PLAYER_MSG_BOX_Y_MAX-7-barOffset, barWidth, barHeight, {1.0, 1.0, 1.0, 1},  {0.8, 0.8,0.8, 1})
	
end

-- draw hint to show chat
function drawVisibilityHint()
	drawBox(PLAYER_MSG_BOX_X_MIN, PLAYER_MSG_BOX_Y_MAX, PLAYER_MSG_BOX_W, 26, {0.0, 0.0, 0.0, 0.6},  {0.0, 0.0, 0.0, 1})
	gl_Color(SYSTEM_TEXT_COLOR)
	gl_Text(">>>>>>>> Press SPACE to view chat", PLAYER_MSG_BOX_X_MIN +5, PLAYER_MSG_BOX_Y_MAX - (FONT_SIZE + 6), FONT_SIZE, FONT_RENDER_STYLES[2])
end

function getTimeStr()
	local seconds = spGetGameSeconds()
	return "["..string.format("%.2d:%.2d", math_floor(seconds/60), seconds%60).."] "
end