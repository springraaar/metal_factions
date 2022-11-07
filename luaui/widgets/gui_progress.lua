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
local bgSpdDisp						= {}
local bgSpdIncrease					= {}
local bgSpdDecrease					= {}
local bgPause						= {}
local clickables = {bgSpdIncrease,bgSpdDecrease,bgPause}
local glColor 						= gl.Color
local glRect						= gl.Rect
local glTexture 					= gl.Texture
local glTexRect 					= gl.TexRect
local glText	 					= gl.Text
local glCreateList	= gl.CreateList
local glDeleteList	= gl.DeleteList
local glCallList	= gl.CallList
local spGetTimer    = Spring.GetTimer
local spDiffTimers  = Spring.DiffTimers
local spGetGameSeconds = Spring.GetGameSeconds

local hh,mm,ss 
local seconds 

local refFontSize = 14
local refClockSizeX = 80
local refClockSizeY = 30
local refFPSSizeX = 80
local refFPSSizeY = 30
local refSpdSizeX = 30
local refSpdDispSizeX = 60
local refSizeY = 30
local refShiftY = 40
local refProgressSizeX = 240
local refProgressSizeY = 30
local fontSize = refFontSize
local scaleFactor = 1

local floor = math.floor

-- colors
local cLight						= {1, 1, 1, 0.5}
local cLightBorder						= {1, 1, 1, 1}
local cWhite						= {1, 1, 1, 1}
local cBorder						= {0, 0, 0, 1}		
local cBack							= {0, 0, 0, 0.6}
local cRed							= {1, 0.2, 0.2, 1}

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

local glList = nil
local glListRefreshIdx = -1
local refTimer = spGetTimer()

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
	if (vsy > 1080) then
		scaleFactor = vsy/1080
	else
		scaleFactor = 1
	end
	fontSize = refFontSize * scaleFactor 
	
	local margin = 10*scaleFactor
	bgClock.x1 = vsx - margin - refClockSizeX * scaleFactor 
	bgClock.x2 = vsx - margin
	bgClock.y1 = vsy - margin - refClockSizeY * scaleFactor - refShiftY * scaleFactor
	bgClock.y2 = vsy - margin - refShiftY * scaleFactor
	
	bgFPS.x1 = vsx - margin - refFPSSizeX * scaleFactor
	bgFPS.x2 = vsx - margin
	bgFPS.y1 = vsy - margin - refFPSSizeY * scaleFactor - refShiftY * 2 * scaleFactor
	bgFPS.y2 = vsy - margin - refShiftY * 2 * scaleFactor
	
	local offset = bgClock.x2 - bgClock.x1 + margin
	bgProgress.x1 = vsx - margin - offset - refProgressSizeX * scaleFactor 
	bgProgress.x2 = vsx - margin - offset
	bgProgress.y1 = vsy - margin - refProgressSizeY * scaleFactor - refShiftY * scaleFactor
	bgProgress.y2 = vsy - margin - refShiftY * scaleFactor
	
	offset = bgFPS.x2 - bgFPS.x1 + margin
	bgSpdDisp.x1 = vsx - margin - offset - refSpdDispSizeX * scaleFactor
	bgSpdDisp.x2 = vsx - margin - offset
	bgSpdDisp.y1 = vsy - margin - refSizeY * scaleFactor - refShiftY * 2 * scaleFactor
	bgSpdDisp.y2 = vsy - margin - refShiftY * 2 * scaleFactor

	offset = offset + margin + bgSpdDisp.x2 - bgSpdDisp.x1 
	bgSpdIncrease.x1 = vsx - margin - offset - refSpdSizeX * scaleFactor
	bgSpdIncrease.x2 = vsx - margin - offset
	bgSpdIncrease.y1 = vsy - margin - refSizeY * scaleFactor - refShiftY * 2 * scaleFactor
	bgSpdIncrease.y2 = vsy - margin - refShiftY * 2 * scaleFactor

	offset = offset + margin + refSpdSizeX * scaleFactor
	bgPause.x1 = vsx - margin - offset - refSpdSizeX * scaleFactor
	bgPause.x2 = vsx - margin - offset
	bgPause.y1 = vsy - margin - refSizeY * scaleFactor - refShiftY * 2 * scaleFactor
	bgPause.y2 = vsy - margin - refShiftY * 2 * scaleFactor
	
	offset = offset + margin + refSpdSizeX * scaleFactor
	bgSpdDecrease.x1 = vsx - margin - offset - refSpdSizeX * scaleFactor
	bgSpdDecrease.x2 = vsx - margin - offset
	bgSpdDecrease.y1 = vsy - margin - refSizeY * scaleFactor - refShiftY * 2 * scaleFactor
	bgSpdDecrease.y2 = vsy - margin - refShiftY * 2 * scaleFactor
end


function drawElement(el,content,isImage,textColor)
	if el.above then
		glColor(cLight)
	else
		glColor(cBack)
	end
	glRect(el.x1,el.y1,el.x2,el.y2)
	if textColor then
		glColor(textColor)
	else
		glColor(cWhite)
	end
	if (isImage) then
		glTexture(content)
		glTexRect(el.x1+1, el.y1+1, el.x2-1, el.y2-1)
		glTexture(false)
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
	--Echo("progress "..n)
	if (not gameProgressCalled) then
		--Echo("server at frame "..n)
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
		if (replayLengthFrames) then
			replayLengthFrames = replayLengthFrames * 30
		end
		--Spring.Echo("replay length = "..replayLengthFrames)
		serverFrame = 0
	end
end


function widget:GameOver()
	--widgetHandler:RemoveCallIn("Update")
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
		if (replayLengthFrames and replayLengthFrames > 0 and localFrame > replayLengthFrames ) then
			progressCaption = "Progress : 100% ("..parseFrameTime(replayLengthFrames)..")"
		else
			progressCaption = "Progress : " .. percentStr .. "%"
		end
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
	local refreshIdx = floor(spDiffTimers(spGetTimer(),refTimer)*5)
	-- refresh gl list only a few times per second
	if (not glList) or refreshIdx ~= glListRefreshIdx then
		if (glList) then
			glDeleteList(glList)
		end 

		-- clock
		seconds = spGetGameSeconds()
		hh = math.floor(seconds / 3600)
		mm = math.floor(seconds % 3600 / 60)
		ss = math.floor(seconds % 3600 % 60)
	   	hh = hh < 10 and "0"..hh or hh
	   	mm = mm < 10 and "0"..mm or mm
	   	ss = ss < 10 and "0"..ss or ss
		glList = glCreateList(function()
			drawElement(bgClock,hh..":"..mm..":"..ss,false)
		
			-- fps indicator
			drawElement(bgFPS,"FPS: "..Spring.GetFPS(),false)
			
			-- speed indicator
			local speedFactor, actualSpeedFactor, isPaused = spGetGameSpeed()
			if actualSpeedFactor < speedFactor or speedFactor ~= 1 then
				local color = cWhite
				if actualSpeedFactor < speedFactor then
					color = cRed
				end
				drawElement(bgSpdDisp,isPaused and "-" or (string.format('x%.2f', actualSpeedFactor)),false,color)
			end
			
			-- progress indicator, speed buttons
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
		end)
		glListRefreshIdx = refreshIdx
	end
	glCallList(glList)

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