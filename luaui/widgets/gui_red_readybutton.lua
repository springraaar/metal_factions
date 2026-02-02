function widget:GetInfo()
	return {
	name      = "Red Ready Button",
	desc      = "Ready Button. Requires Red UI Framework",
	author    = "raaar",
	date      = "2025",
	license   = "PD",
	layer     = -1,
	enabled   = true,
	handler   = true,
	}
end

local vsx, vsy = gl.GetViewSizes()
local maxFontSizeFactor = 1
if (vsy > 1080) then
	maxFontSizeFactor = vsy / 1080
end	

VFS.Include("lualibs/constants.lua")
VFS.Include("lualibs/custom_cmd.lua")
VFS.Include("lualibs/util.lua")
VFS.Include("luaui/headers/redui_aux.lua")

local spGetMyTeamID = Spring.GetMyTeamID
local spGetGameFrame = Spring.GetGameFrame

local readyState = 0
local syncReadyState = 0
local scrollIdx = 1
local mousePressed = false
local mouseOverMainPanel = false
local mouseOverScrollBar = false

local min = math.min
local max = math.max
local floor = math.floor

local mainPanel = {}

local CHECK_READY = 0


local margin = 6
local NETMSG_STARTPLAYING = 4 -- see BaseNetProtocol.h, packetID sent during the 3.2.1 countdown
local SYSTEM_ID = -1 -- see LuaUnsyncedRead::GetPlayerTraffic, playerID to get hosts traffic from
local STARTING_SOUND = "STARTING"
local READY_SOUND = "READY"
local myPlayerId = Spring.GetMyPlayerID()
local isFFA = false
local gameStarting = false
local readyingSeconds = 0
local maxReadyPlayersFound = 0
local startingSeconds = 0
local startingTimeSteps = 0
local startingStrArr = {
	"\255\0\255\0[ 3 ]  \255\128\128\128STARTING  \255\0\255\0[ 3 ]",
	"\255\0\255\0[ 2 ]  \255\128\128\128STARTING  \255\0\255\0[ 2 ]",
	"\255\0\255\0[ 1 ]  \255\128\128\128STARTING  \255\0\255\0[ 1 ]",
	"\255\0\255\0[ 0 ]  \255\128\128\128STARTING  \255\0\255\0[ 0 ]"
}
local startingSoundArr = {
	"STARTTICK",
	"STARTTICK",
	"STARTTICK",
	"STARTTICK"
}

local Config = {
	mainPanel = {
		px = CanvasX*0.5 - 310*0.5 ,py = CanvasY - (200),
		sx = 310,sy = 44, --background size
		
		fontsize = 10,
		maxFontsize = 18 * maxFontSizeFactor,
		margin = margin,
		padding = 0,
		cbackground = UI_BG_TEXT,
		cborder = UI_BORDER,
		clabel = UI_TEXT,
		
		name = "mainPanel",
		
		tooltip = {
			background ="\255\255\255\255Ready Button Panel.",
		},
	},
	baseButton = {
		sx = 80,sy = 32, --background size
		fontsize = 10,
		maxFontsize = 18 * maxFontSizeFactor,
		margin = margin,
		padding = 8,
		cbackground = UI_BTN_BG,
		cborder = UI_BTN_BORDER,
		clabel = UI_TEXT,
	},
	readyButton = {
		px = 0,py = 0,
		name = "readyButton",
		checkType = CHECK_READY,
		texture = "luaui/images/ready.png",
		selectedTexture = "luaui/images/readyChecked.png", 
		tooltip = {
			background ="\255\255\255\255Toggle readiness state.",
		},
	},

}

local function createMainPanel(r)
	local background = {"rectangle",
		px=r.px,py=r.py,
		sx=r.sx,sy=r.sy,
		color=r.cbackground,
		border=r.cborder,
		movable=r.dragbutton,
		obeyScreenEdge = true,
		
		padding=r.padding,
		
		--overrideCursor = true,
		overrideClick = {1},
	}
	New(background)
	
	local offsetY = 0
	local offsetX = 0
	
	local text = {"text",
		px=background.px+r.margin,py=background.py+r.margin+10,fontsize=r.fontsize,maxFontsize=40 * maxFontSizeFactor,
		caption="",
		options="n", --disable colorcodes
	}
	local lb = New(text)
	lb.caption = "Choose start position, then press "
	lb.color = r.clabel
	lb.fontsize = r.fontsize * 1.3


	local lbStarting = New(text)
	lbStarting.caption = ""
	lbStarting.color = r.clabel
	lbStarting.fontsize = r.fontsize * 2.5
	lbStarting.options = "cno"
	lbStarting.py = background.py+r.margin+5
	lbStarting.px = background.px+background.sx*0.5
	lbStarting.sx = background.sx
	
	background.mouseOver = function(mx,my,self) 
		mouseOverMainPanel = true
	end	
	background.mouseNotOver = function(mx,my,self)
		mouseOverMainPanel = false
	end
	
	offsetX = 218
	
	-- ready
	local bt = Copy(Config.readyButton)
	bt = mergeTable(bt,Config.baseButton)
	bt.px = r.px + r.margin + offsetX
	bt.py = r.py + r.margin + offsetY
	local readyButton = createButton(bt,"",function(mx,my,self)
		toggleReadyState()
	end)

	offsetX = 0

	background.movableSlaves = {
		readyButton,lb,lbStarting
	}

	local returnTable = {
		["background"] = background,
		["label"] = lb,
		["labelStarting"] = lbStarting,
		["readyButton"] = readyButton,
		enable = function()
			background.active = nil
			lb.active = nil
			lbStarting.active = nil
			readyButton.enable()
		end,
		disable = function()
			background.active = false
			lb.active = false
			lbStarting.active = false
			readyButton.disable()
		end	
	}
	
	return returnTable
end

function createButton(r,label,lClickHandler,rClickHandler)
	local background = {"rectangle",
		px=r.px,py=r.py,
		sx=r.sx,sy=r.sy,
		color=r.cbackground,
		border=r.cborder,
		movable=r.dragbutton,
		obeyScreenEdge = true,
		
		isSelected = false,
		padding=r.padding,
		overrideCursor = true,
		overrideClick = {1}
	}
	
	if r.texture then
		background.texture = r.texture
		background.textureColor = r.textureColor
	end
	if r.selectedValue ~= nil then
		background.selectedValue = r.selectedValue
		background.checkType = r.checkType
	end
	New(background)

	local text = {"text",
		px=background.px+r.margin,py=background.py+r.margin,fontsize=r.fontsize,maxFontsize=20 * maxFontSizeFactor,
		caption=r.name,
		options="n", --disable colorcodes
	}
	local lb = New(text)
	lb.caption = label
	lb.color = r.clabel

	background.movableSlaves = {
		lb
	}

	-- mouse over handling	
	background.mouseOver = function(mx,my,self) 
		setTooltip(r.tooltip.background)
		if self.isSelected == true then
			self.color = UI_BTN_BG_SELECTED_OVER
			self.border = UI_BTN_BORDER_SELECTED_OVER			
		else
			self.color = UI_BTN_BG_OVER
			self.border = UI_BTN_BORDER_OVER
		end
	end	
	background.mouseNotOver = function(mx,my,self)
		if self.isSelected == true then
			self.color = UI_BTN_BG_SELECTED
			self.border = UI_BTN_BORDER_SELECTED
		else
			self.color = UI_BTN_BG
			self.border = UI_BTN_BORDER
		end 
	end	
		
	background.onUpdate = function(self)
		if r.checkType then
			if r.checkType == CHECK_READY then 
				background.isSelected = readyState == 1
			end
		end
		
		if self.isSelected == true then
			if r.selectedTexture then
				background.texture = r.selectedTexture
			end
		else
			if r.texture then
				background.texture = r.texture
			end
		end 
	end
	
	-- click handling
	background.mouseClick = {}
	if lClickHandler then
		table.insert(background.mouseClick,{1,lClickHandler})
	end
	if rClickHandler then
		table.insert(background.mouseClick,{3,rClickHandler})
	end
	
	return {
		["background"] = background,
		["label"] = lb,
		enable = function()
			background.active = nil
			lb.active = nil
		end,
		disable = function()
			background.active = false
			lb.active = false
		end
	}
end

function showReadyPanel()
	mainPanel.enable()
	WG.readyPanelShown = true
end

function hideReadyPanel()
	mainPanel.disable()
	WG.readyPanelShown = false
end
WG.showReadyPanel = showReadyPanel
WG.hideReadyPanel = hideReadyPanel

function toggleReadyState()
	if syncReadyState == 0 then
		readyState = 1
	else
		readyState = 0
	end
	
	Spring.SendLuaRulesMsg("READYSTATE|"..readyState)
end


function getScale(vsx,lx,vsy,ly)
	local hConstrainedScale = vsx/lx
	local vConstrainedScale = vsy/ly
	
	if (vConstrainedScale < hConstrainedScale) then
		return vConstrainedScale
	end
	return vsy/ly
end

------------------------------------ callins

function widget:Initialize()
	if Spring.GetSpectatingState() or Spring.IsReplay() then
		widgetHandler:RemoveWidget(self)
		return
	end
	
	PassedStartupCheck = RedUIchecks()
	if (not PassedStartupCheck) then return end

	
	mainPanel = createMainPanel(Config.mainPanel)
	showReadyPanel()
	AutoResizeObjects()
end

function widget:Shutdown()
end


function widget:GameSetup(state, ready, playerStates)
	local spec, fullview = Spring.GetSpectatingState()
	-- sends a "I arrived" message
	-- NOTE: Spring.GetGameRulesParam("player_" .. Spring.GetMyPlayerID() .. "_joined") seems to be always nil!
	--if not spec and not ihavejoined and Spring.GetGameRulesParam("player_" .. Spring.GetMyPlayerID() .. "_joined") == nil then
	--	Spring.SendLuaRulesMsg("joined_game")
	--	ihavejoined = true
	--end
	
	syncReadyState = Spring.GetGameRulesParam("player_" .. myPlayerId .. "_readyState")

	-- check when the 3.2.1 countdown starts
	if not gameStarting and ((Spring.GetPlayerTraffic(SYSTEM_ID, NETMSG_STARTPLAYING) or 0) > 0) then
		gameStarting = true		-- ugly but effective (can also detect by parsing state string)
		mainPanel.readyButton.disable()
		mainPanel.label.caption = ""
		mainPanel.labelStarting.caption = startingStrArr[1]
		Spring.PlaySoundFile(STARTING_SOUND, 0.5)
	end
	if gameStarting then
		startingSeconds = startingSeconds + Spring.GetLastUpdateSeconds()
		local timeSteps = math.floor(startingSeconds)
		if (timeSteps > startingTimeSteps and timeSteps < 4) then
			local idx = math.max(1,math.min(timeSteps+1,4))
			Spring.PlaySoundFile(startingSoundArr[idx], 0.5)
			startingTimeSteps = timeSteps
			mainPanel.labelStarting.caption = startingStrArr[idx]
		end
	end 
	
	-- if we can't choose startpositions, no need for ready button etc
	if Game.startPosType ~= 2 then
		-- additionally automatically set readyState to true if this is a FFA game
		--if isFFA and (not readied or not ready) then
		--	readyState = 1
		--end
		return true, true
	end

	-- starts game after a specified amount of time after all players have joined
	--if Spring.GetGameRulesParam("all_players_joined") == 1 and not gameStarting and auto_ready then
	--	auto_ready_timer = auto_ready_timer - Spring.GetLastUpdateSeconds()
	--end
	--if auto_ready_timer <=0 and auto_ready == true then
	--	return true, true
	--end

	-- only return true, true once ALL players are ready
	ready = true
	local readyPlayersFound = 0
	local playerList = Spring.GetPlayerList()
	for _, playerID in pairs(playerList) do
		--Spring.Echo("player "..playerID.." spec="..tostring(spectator).." srs="..tostring(Spring.GetGameRulesParam("player_" .. playerID .. "_readyState")))
		local _, _, spectator = Spring.GetPlayerInfo(playerID)
		if spectator == false then
			local srs = Spring.GetGameRulesParam("player_" .. playerID .. "_readyState")
			if srs == 0 or srs == 4 then
				ready = false
			else
				readyPlayersFound = readyPlayersFound + 1
			end
		end
	end
	
	if readyPlayersFound > maxReadyPlayersFound then
		Spring.PlaySoundFile(READY_SOUND, 0.5)
		maxReadyPlayersFound = readyPlayersFound
	end
	
	-- delay readying for an extra second
	if ready then
		readyingSeconds = readyingSeconds + Spring.GetLastUpdateSeconds()
	else
		readyingSeconds = 0
	end
	if readyingSeconds < 1 then
		ready = false
	end
	
	return true, ready
end

function widget:MousePress(mx, my, mButton)
	if (WG.readyPanelShown and readyState == 1) then 	
		return true
	end
end	

function widget:GameStart()
	hideReadyPanel()
	--widgetHandler:RemoveWidget(self)
end

function widget:Update()
	if spGetGameFrame() > 0 then
		hideReadyPanel()
	else
		AutoResizeObjects()
	end
end


