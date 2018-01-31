function widget:GetInfo()
	return {
		name    = "Menu Button",
		desc    = "Show a simple menu button",
		author  = "raaar",
		date    = "2016",
		license = "PD",
		layer   = 1001,
		enabled = true
	}
end

local Echo 							= Spring.Echo
local vsx, vsy 						= gl.GetViewSizes()
local posX, posY					= vsx/2, vsy/2
local ButtonMenu					= {}
local glColor 						= gl.Color
local glRect						= gl.Rect
local glTexture 					= gl.Texture
local glTexRect 					= gl.TexRect
local TextDraw            = fontHandler.Draw
local TextDrawCentered    = fontHandler.DrawCentered
local TextDrawRight       = fontHandler.DrawRight

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


function widget:Initialize()
	ButtonMenu.x1 = vsx - 60
	ButtonMenu.x2 = vsx - 10
	ButtonMenu.y1 = vsy - 40
	ButtonMenu.y2 = vsy - 10
end


function widget:DrawScreen()
		
	-- draw menu button
	if ButtonMenu.above then
		glColor(cLight)
	else
		glColor(cBack)
	end
	glRect(ButtonMenu.x1,ButtonMenu.y1,ButtonMenu.x2,ButtonMenu.y2)
	
	glColor(cWhite)
	-- menu button text
	TextDrawCentered("MENU", (ButtonMenu.x1 + ButtonMenu.x2) /2, ButtonMenu.y1 + 10 )

	-- menu button border
	if ButtonMenu.above then
		glColor(cLightBorder)
	else
		glColor(cBorder)
	end
	glRect(ButtonMenu.x1,ButtonMenu.y1,ButtonMenu.x1+1,ButtonMenu.y2)
	glRect(ButtonMenu.x2-1,ButtonMenu.y1,ButtonMenu.x2,ButtonMenu.y2)
	glRect(ButtonMenu.x1,ButtonMenu.y1,ButtonMenu.x2,ButtonMenu.y1+1)
	glRect(ButtonMenu.x1,ButtonMenu.y2-1,ButtonMenu.x2,ButtonMenu.y2)
	
end

function widget:MousePress(mx, my, mButton)
	if not Spring.IsGUIHidden() then
		if ButtonMenu.above then		
			if not WG.menuShown then
				Spring.SendCommands("quitmenu")
				WG.menuShown = true
			end
		end
	end
	
	return false
 end	

function widget:IsAbove(mx,my)
	if not Spring.IsGUIHidden() then
		ButtonMenu.above = IsOnButton(mx, my, ButtonMenu["x1"],ButtonMenu["y1"],ButtonMenu["x2"],ButtonMenu["y2"])
	end
	
	return false		
end	

function widget:GameOver()
	widgetHandler:RemoveWidget()
end
