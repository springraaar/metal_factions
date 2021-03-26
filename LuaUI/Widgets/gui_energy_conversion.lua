
function widget:GetInfo()
	return {
		name      = 'Energy Conversion Info',
		desc      = 'Displays energy conversion info',
		author    = 'Niobium (modified by Jools, Deadnight Warrior and raaar)',
		date      = 'May 2011',
		license   = 'GNU GPL v2',
		layer     = 0,
		enabled   = true,
		handler   = true
	}
end

-- raaar 2019 : set to a position offset from the top-right corner to fit with MF UI, restore position on load 
-- Updates: 2014.09: Made it possible to unload widget and handle mmakers manually. Jools.

--------------------------------------------------------------------------------
-- Var
--------------------------------------------------------------------------------
local alterLevelFormat = string.char(137) .. '%i'
local operationPrefix = 'energyconversion:'

local X, Y = Spring.GetViewGeometry()
local px, py = X-150, Y-230
local sx, sy = 140, 80
local scaling, fontSize, col1, col2, row1, row2, row3, row4
local onsidemargin = 2

local hoverLeft, hoverRight, hoverBottom, hoverTop, barBottom, barTop
--------------------------------------------------------------------------------
-- Speedups
--------------------------------------------------------------------------------
local format = string.format
local floor = math.floor

local glColor = gl.Color
local glRect = gl.Rect
local glPushMatrix = gl.PushMatrix
local glPopMatrix = gl.PopMatrix
local glTranslate = gl.Translate
local glBeginText = gl.BeginText
local glEndText = gl.EndText
local glText = gl.Text
local Echo = Spring.Echo

local spGetMyTeamID = Spring.GetMyTeamID
local spGetTeamRulesParam = Spring.GetTeamRulesParam
local spSendLuaRulesMsg = Spring.SendLuaRulesMsg
local spGetSpectatingState = Spring.GetSpectatingState

VFS.Include("lualibs/custom_cmd.lua")
local displayWindow = true
--------------------------------------------------------------------------------
-- Funcs
--------------------------------------------------------------------------------

function widget:Initialize()
	local playerID = Spring.GetMyPlayerID()
	local _, _, spec, _, _, _, _, _ = Spring.GetPlayerInfo(playerID)
	
	if ( spec == true ) then
		Spring.Echo("widget", LOG.INFO, "<Energy Conversion Info> Spectator mode. Widget removed.")
		displayWindow = false
		widgetHandler:RemoveWidget(self)
		return false
	end
	scaling = 1 --Y/1200
	sx, sy, fontSize = sx*scaling, sy*scaling, 12*scaling
	col1, col2, row1, row2, row3, row4 = 135*scaling, 69*scaling, 5*scaling, 21*scaling,37*scaling,53*scaling
	hoverLeft = 49*scaling
	hoverRight = 135*scaling
	hoverBottom = 39*scaling
	hoverTop = 51*scaling
	barBottom = 44*scaling
	barTop = 46*scaling
	
	local cmds = widgetHandler.commands
	local n = #(widgetHandler.commands)
	
	for i=1,n do
		if (cmds[i].id == CMD_ENERGYCONVERT) then
			cmds[i].hidden = false
		end
    end
	spSendLuaRulesMsg(table.concat({operationPrefix,1}))
end

function widget:Shutdown()
		
	local cmds = widgetHandler.commands
	local n = #(widgetHandler.commands)

	for i=1,n do
		if (cmds[i].id == CMD_ENERGYCONVERT) then
			cmds[i].hidden = true
		end
	end
	spSendLuaRulesMsg(table.concat({operationPrefix,0}))
end

function widget:CommandsChanged()
    
	local cmds = widgetHandler.commands
	local n = #(widgetHandler.commands)
	
	for i=1,n do
		if (cmds[i].id == CMD_ENERGYCONVERT) then
			cmds[i].hidden = false
		end
	end
end

function widget:DrawScreen()
    if not displayWindow then return end
	
    -- Var
    local myTeamID = spGetMyTeamID()
    local curLevel = spGetTeamRulesParam(myTeamID, 'mmLevel') or 0
    local curUsage = spGetTeamRulesParam(myTeamID, 'mmUse') or 0
    local curCapacity = spGetTeamRulesParam(myTeamID, 'mmCapacity') or 0
	
	if curCapacity <= 0 then return end
	
	local Mprod = curUsage/120
	local display
	if Mprod >= 1 then 
		display = format('%i.', Mprod) .. floor((Mprod-floor(Mprod))*10)
    else
		display = format('0.%i', curUsage/6)
	end
    -- Positioning
    glPushMatrix()
        glTranslate(px, py, 0)
        
        -- Panel
        glColor(0, 0, 0, 0.5)
        glRect(0, 0, sx, sy)
        
        -- Border
        glColor(0, 0, 0, 1)
       	glRect(0,0,1,sy)
		glRect(sx-1,0,sx,sy)
		glRect(0,0,sx,1)
		glRect(0,sy-1,sx,sy)
        
        -- Text
        glColor(1, 1, 1, 1)
        glBeginText()
            glText('Energy Conversion', col2, row4, fontSize, 'cd')
            glText('Hover:', row1, row3, fontSize, 'd')
            glText('E usage:', row1, row2, fontSize, 'd')
            glText('M production:', row1, row1, fontSize, 'd')
            glText(format('%i / %i', curUsage, curCapacity), col1, row2, fontSize, 'dr')
            glText(display, col1, row1, fontSize, 'dr')
        glEndText()
        
        -- Bar
        glRect(hoverLeft, barBottom, hoverRight, barTop)
        
        -- Slider
        local sliderX = hoverLeft + (hoverRight - hoverLeft) * curLevel
        glColor(1, 0, 0, 0.75)
        glRect(sliderX - 2, hoverBottom, sliderX + 2, hoverTop)
        
    glPopMatrix()
end

function widget:TeamDied(teamID)
	
	if teamID == spGetMyTeamID() then
		displayWindow = false	
		widgetHandler:RemoveWidget(self)
		return
	end
end

function widget:MousePress(mx, my, mButton)
	if displayWindow then
		if mButton == 2 or mButton == 3 then
			if mx >= px and my >= py and mx < px + sx and my < py + sy then
				return true
			end
		elseif mButton == 1 and not spGetSpectatingState() then
			local dx, dy = mx - px, my - py
			if dx >= hoverLeft and dy >= hoverBottom and dx < hoverRight and dy < hoverTop then
				local newShare = 100 * (dx - hoverLeft) / (hoverRight - hoverLeft) -- [0, 100)
				spSendLuaRulesMsg(format(alterLevelFormat, newShare))
				return true
			end
		end
	end
end

function widget:MouseMove(mx, my, dx, dy, mButton)
    -- Dragging
	if displayWindow then
		if mButton == 2 or mButton == 3 then
			if px+sx+onsidemargin+dx>=0 and px+onsidemargin+dx<=X then px = px + dx end
			if py+sy+onsidemargin+dy>=0 and py+onsidemargin+dy<=Y then py = py + dy end
		end
	end
end

--[[
function widget:GetConfigData()
	local vsx, vsy = gl.GetViewSizes()
	return {px / vsx, py / vsy}
end

function widget:SetConfigData(data)
	local vsx, vsy = gl.GetViewSizes()
	px = math.floor(math.max(0, vsx * math.min(data[1] or 0, 0.95)))
	py = math.floor(math.max(0, vsy * math.min(data[2] or 0, 0.95)))
end

]]--