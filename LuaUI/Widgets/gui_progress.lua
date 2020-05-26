function widget:GetInfo()
	return {
		name    = "Progress",
		desc    = "Show clock, progress and fps indicator and speed buttons on replays",
		author  = "raaar",
		date    = "2017",
		license = "PD",
		layer   = 0,
		enabled = true
	}
end

local Echo 							= Spring.Echo
local vsx, vsy 						= gl.GetViewSizes()
local bgClock						= {}
local bgFPS							= {}
local bgProgress					= {}
local bgSpdIncrease					= {}
local bgSpdDecrease					= {}
local bgPause						= {}
local clickables = {bgSpdIncrease,bgSpdDecrease,bgPause}
local glColor 						= gl.Color
local glRect						= gl.Rect
local glTexture 					= gl.Texture
local glTexRect 					= gl.TexRect
local glText	 					= gl.Text
local hh,mm,ss 
local seconds 

local refFontSize = 14
local refClockSizeX = 80
local refClockSizeY = 30
local refFPSSizeX = 80
local refFPSSizeY = 30
local refSpdSizeX = 30
local refSizeY = 30
local refShiftY = 40
local refProgressSizeX = 240
local refProgressSizeY = 30
local fontSize = refFontSize
local scaleFactor = 1

-- colors
local cLight						= {1, 1, 1, 0.5}
local cLightBorder						= {1, 1, 1, 1}
local cWhite						= {1, 1, 1, 1}
local cBorder						= {0, 0, 0, 1}		
local cBack							= {0, 0, 0, 0.5}


------- progress-related variables
local playTexture	= ":n:"..LUAUI_DIRNAME.."Images/play.dds"
local pauseTexture	= ":n:"..LUAUI_DIRNAME.."Images/pause.dds"
local gameProgressCalled = false
local showProgress = false
local isReplay = Spring.IsReplay()
local showSpeedButtons = isReplay
local spGetGameSpeed = Spring.GetGameSpeed
local spGetReplayLength = Spring.GetReplayLength
local gameSpeed = Game.gameSpeed
local CATCH_UP_THRESHOLD = 10 * gameSpeed -- only show the progress indicator if behind this much
local UPDATE_RATE_F = 10 -- frames
local UPDATE_RATE_S = UPDATE_RATE_F / gameSpeed
local t = UPDATE_RATE_S
local localFrame = Spring.GetGameFrame()
local percentStr = " ? "
local serverFrame
local lastFrame
local replayLengthFrames
local replayPaused = false
local running = (localFrame > 0)
local progressCaption = ""
local catchingPercent = "" 


local function estimateServerFrame()
	local speedFactor, _, isPaused = spGetGameSpeed()
	if running and not isPaused then
		serverFrame = serverFrame + math.ceil(speedFactor * UPDATE_RATE_F)
	end
end

local function parseFrameTime(frames)
	local secs = math.floor(frames / gameSpeed)
	local h = math.floor(secs / 3600)
	local m = math.floor((secs % 3600) / 60)
	local s = secs % 60
	if (h > 0) then
		return string.format('%02i:%02i:%02i', h, m, s)
	else
		return string.format('%02i:%02i', m, s)
	end
end

local function isOnButton(x, y, BLcornerX, BLcornerY,TRcornerX,TRcornerY)
	if BLcornerX == nil then return false end
	-- check if the mouse is in a rectangle

	return x >= BLcornerX and x <= TRcornerX
	                      and y >= BLcornerY
	                      and y <= TRcornerY
end


function updateSizesPositions()
	if (vsy > 1800) then
		scaleFactor=1.6
	elseif (vsy > 1400) then
		scaleFactor=1.4
	elseif (vsy > 1200) then
		scaleFactor=1.2
	else
		scaleFactor=1
	end
	fontSize = refFontSize * scaleFactor 
	
	bgClock.x1 = vsx - 10 - refClockSizeX * scaleFactor 
	bgClock.x2 = vsx - 10
	bgClock.y1 = vsy - 10 - refClockSizeY * scaleFactor - refShiftY * scaleFactor
	bgClock.y2 = vsy - 10 - refShiftY * scaleFactor
	
	bgFPS.x1 = vsx - 10 - refFPSSizeX * scaleFactor
	bgFPS.x2 = vsx - 10
	bgFPS.y1 = vsy - 10 - refFPSSizeY * scaleFactor - refShiftY * 2 * scaleFactor
	bgFPS.y2 = vsy - 10 - refShiftY * 2 * scaleFactor
	
	local offset = bgClock.x2 - bgClock.x1 + 10
	bgProgress.x1 = vsx - 10 - offset - refProgressSizeX * scaleFactor 
	bgProgress.x2 = vsx - 10 - offset
	bgProgress.y1 = vsy - 10 - refProgressSizeY * scaleFactor - refShiftY * scaleFactor
	bgProgress.y2 = vsy - 10 - refShiftY * scaleFactor
	
	offset = bgFPS.x2 - bgFPS.x1 + 10
	bgSpdIncrease.x1 = vsx - 10 - offset - refSpdSizeX * scaleFactor
	bgSpdIncrease.x2 = vsx - 10 - offset
	bgSpdIncrease.y1 = vsy - 10 - refSizeY * scaleFactor - refShiftY * 2 * scaleFactor
	bgSpdIncrease.y2 = vsy - 10 - refShiftY * 2 * scaleFactor

	offset = offset + 10 + refSpdSizeX * scaleFactor
	bgPause.x1 = vsx - 10 - offset - refSpdSizeX * scaleFactor
	bgPause.x2 = vsx - 10 - offset
	bgPause.y1 = vsy - 10 - refSizeY * scaleFactor - refShiftY * 2 * scaleFactor
	bgPause.y2 = vsy - 10 - refShiftY * 2 * scaleFactor
	
	offset = offset + 10 + refSpdSizeX * scaleFactor
	bgSpdDecrease.x1 = vsx - 10 - offset - refSpdSizeX * scaleFactor
	bgSpdDecrease.x2 = vsx - 10 - offset
	bgSpdDecrease.y1 = vsy - 10 - refSizeY * scaleFactor - refShiftY * 2 * scaleFactor
	bgSpdDecrease.y2 = vsy - 10 - refShiftY * 2 * scaleFactor
end


function drawElement(el,content,isImage)
	if el.above then
		glColor(cLight)
	else
		glColor(cBack)
	end
	glRect(el.x1,el.y1,el.x2,el.y2)
	glColor(cWhite)
	if (isImage) then
		glTexture(content)
		glTexRect(el.x1+1, el.y1+1, el.x2-1, el.y2-1)
		--gl.Flush()
		gl.ResetState()
	else
		glText(content,(el.x1 + el.x2) /2, (el.y1 + el.y2) / 2-fontSize/2,fontSize,"c")
	end
	if el.above then
		glColor(cLightBorder)
	else
		glColor(cBorder)
	end
	glRect(el.x1,el.y1,el.x1+1,el.y2)
	glRect(el.x2-1,el.y1,el.x2,el.y2)
	glRect(el.x1,el.y1,el.x2,el.y1+1)
	glRect(el.x1,el.y2-1,el.x2,el.y2)
end

----------------------------- CALLINS

function widget:GameProgress (n) -- happens every 300 frames
	serverFrame = n
	if (not gameProgressCalled) then
		Echo("server at frame "..n)
		gameProgressCalled = true
	end
end

function widget:GameFrame(n)
	localFrame = n
end

function widget:GameStart()
	running = true
	--widget:GameProgress(2000)
	if (isReplay) then
		replayLengthFrames = spGetReplayLength()
		--Spring.Echo("replay length = "..replayLengthFrames)
		serverFrame = 0
	end
end


function widget:GameOver()
	widgetHandler:RemoveCallIn("Update")
end

function widget:Update(dt)
	if not serverFrame then
		return
	end

	t = t - dt
	if t > 0 then
		return
	end
	t = t + UPDATE_RATE_S

	if (not isReplay) then
		estimateServerFrame()
	end

	local framesLeft = serverFrame - localFrame
	-- workaround to detect that replay isn't paused...
	if (isReplay and localFrame and lastFrame ) then
	 	if (localFrame > lastFrame) then
			replayPaused = false
		else
			replayPaused = true
		end
	end
	lastFrame = localFrame
	
	--Spring.Echo("serverFrame="..serverFrame.." localFrame="..localFrame)
	if isReplay or framesLeft > CATCH_UP_THRESHOLD then
		if not showProgress then
			showProgress = true
		end
	else
		if showProgress then
			showProgress = false
		end
		return
	end
	
	if isReplay then
		if (replayLengthFrames and replayLengthFrames > 0) then
			percentStr = math.floor(localFrame*100 / replayLengthFrames)
		end
		progressCaption = "Progress : " .. percentStr .. "%"
	else
		if (serverFrame and serverFrame > 0) then
			percentStr = math.floor(localFrame*100 / serverFrame)
		end
		progressCaption = "Synching : " .. percentStr .. "% (" .. parseFrameTime(framesLeft).." ahead)"
	end 

end


function widget:ViewResize(viewSizeX, viewSizeY)
	vsx,vsy = widgetHandler:GetViewSizes()
	updateSizesPositions()
end

function widget:Initialize()
	updateSizesPositions()
end


function widget:DrawScreen()
			
	-- clock
	seconds = Spring.GetGameSeconds()
	hh = math.floor(seconds / 3600)
	mm = math.floor(seconds % 3600 / 60)
	ss = math.floor(seconds % 3600 % 60)
   	hh = hh < 10 and "0"..hh or hh
   	mm = mm < 10 and "0"..mm or mm
   	ss = ss < 10 and "0"..ss or ss
	drawElement(bgClock,hh..":"..mm..":"..ss,false)

	-- fps indicator
	drawElement(bgFPS,"FPS: "..Spring.GetFPS(),false)
	
	-- progress indicator
	if (showProgress) then
		drawElement(bgProgress,progressCaption,false)
		if (showSpeedButtons) then
			--local speedFactor, _, isPaused = spGetGameSpeed()
			--Spring.Echo("speedFactor="..tostring(speedFactor).." isPaused="..tostring(isPaused))
			drawElement(bgSpdIncrease,"+",false)
			drawElement(bgPause,replayPaused and playTexture or pauseTexture,true)
			drawElement(bgSpdDecrease,"-",false)
		end
	end
end


function widget:MousePress(mx, my, mButton)
	if not Spring.IsGUIHidden() then
		if (showSpeedButtons) then
			if bgSpdIncrease.above then		
				Spring.SendCommands("speedup")
			elseif bgSpdDecrease.above then		
				Spring.SendCommands("slowdown")
			elseif bgPause.above then		
				if (replayPaused) then
					Spring.SendCommands("pause 0")
				else
					Spring.SendCommands("pause 1")
				end
			end
		end
	end
	
	return false
 end	

function widget:IsAbove(mx,my)
	if not Spring.IsGUIHidden() then
		for _,b in pairs(clickables) do
			b.above = isOnButton(mx, my, b["x1"],b["y1"],b["x2"],b["y2"])
		end
	end
	
	return false		
end	