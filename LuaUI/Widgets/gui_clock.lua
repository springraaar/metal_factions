function widget:GetInfo()
	return {
		name    = "Clock",
		desc    = "Show a simple clock indicator",
		author  = "raaar",
		date    = "2017",
		license = "PD",
		layer   = 0,
		enabled = true
	}
end

local Echo 							= Spring.Echo
local vsx, vsy 						= gl.GetViewSizes()
local bgClock					= {}
local bgFPS					= {}
local glColor 						= gl.Color
local glRect						= gl.Rect
local glTexture 					= gl.Texture
local glTexRect 					= gl.TexRect
local TextDraw            = fontHandler.Draw
local TextDrawCentered    = fontHandler.DrawCentered
local TextDrawRight       = fontHandler.DrawRight
local hh,mm,ss 
local seconds 

local refFontSize = 14
local refClockSizeX = 80
local refClockSizeY = 30
local refFPSSizeX = 80
local refFPSSizeY = 30
local refShiftY = 40
local fontSize = refFontSize
local scaleFactor = 1

-- colors
local cLight						= {1, 1, 1, 0.5}
local cLightBorder						= {1, 1, 1, 1}
local cWhite						= {1, 1, 1, 1}
local cBorder						= {0, 0, 0, 1}		
local cBack							= {0, 0, 0, 0.5}

local function IsOnButton(x, y, BLcornerX, BLcornerY,TRcornerX,TRcornerY)
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
end

function widget:ViewResize(viewSizeX, viewSizeY)
	vsx,vsy = widgetHandler:GetViewSizes()
	
	updateSizesPositions()
end

function widget:Initialize()
	
end

function widget:Initialize()
	updateSizesPositions()
end


function widget:DrawScreen()
		
			
	-- draw menu button
	glColor(cBack)
	glRect(bgClock.x1,bgClock.y1,bgClock.x2,bgClock.y2)
	glColor(cWhite)
	
	-- get time
	seconds = Spring.GetGameSeconds()
	hh = math.floor(seconds / 3600)
	mm = math.floor(seconds % 3600 / 60)
	ss = math.floor(seconds % 3600 % 60)
   	hh = hh < 10 and "0"..hh or hh
   	mm = mm < 10 and "0"..mm or mm
   	ss = ss < 10 and "0"..ss or ss
	
	-- clock text
	--TextDrawCentered(, (bgClock.x1 + bgClock.x2) /2, bgClock.y1 + 10 )
	gl.Text(hh..":"..mm..":"..ss,(bgClock.x1 + bgClock.x2) /2, (bgClock.y1 + bgClock.y2) / 2-fontSize/2,fontSize,"c")

	-- clock border
	glColor(cBorder)
	glRect(bgClock.x1,bgClock.y1,bgClock.x1+1,bgClock.y2)
	glRect(bgClock.x2-1,bgClock.y1,bgClock.x2,bgClock.y2)
	glRect(bgClock.x1,bgClock.y1,bgClock.x2,bgClock.y1+1)
	glRect(bgClock.x1,bgClock.y2-1,bgClock.x2,bgClock.y2)
	

	-- fps indicator
	glColor(cBack)
	glRect(bgFPS.x1,bgFPS.y1,bgFPS.x2,bgFPS.y2)
	glColor(cWhite)
	gl.Text("FPS: "..Spring.GetFPS(),(bgFPS.x1 + bgFPS.x2) /2, (bgFPS.y1 + bgFPS.y2) / 2-fontSize/2,fontSize,"c")
	glColor(cBorder)
	glRect(bgFPS.x1,bgFPS.y1,bgFPS.x1+1,bgFPS.y2)
	glRect(bgFPS.x2-1,bgFPS.y1,bgFPS.x2,bgFPS.y2)
	glRect(bgFPS.x1,bgFPS.y1,bgFPS.x2,bgFPS.y1+1)
	glRect(bgFPS.x1,bgFPS.y2-1,bgFPS.x2,bgFPS.y2)
	
	
	
end
