function widget:GetInfo()
    return {
        name      = "Commander Hurt Warning",
        desc      = "Shows a warning overlay when commander is out of view and gets damaged",
        author    = "Floris (modified by raaar)",
        date      = "February 2018",
        license   = "GNU GPL, v2 or whatever",
        layer     = 111,
        enabled   = true
    }
end

---------------------------------------------------------------------------------------------------
--  Declarations
---------------------------------------------------------------------------------------------------

local vignetteTexture	= ":n:"..LUAUI_DIRNAME.."Images/vignette.dds"
local signTexture	= ":n:"..LUAUI_DIRNAME.."Images/commanderWarning.dds"


local duration = 1.2
local maxOpacity = 0.6
local opacity = 0

local scaleFactor = 1
local myTeamID = Spring.GetMyTeamID()

local comUnitDefIDs = {}
for unitDefID, unitDef in pairs(UnitDefs) do
	if unitDef and unitDef.customParams.iscommander then
		comUnitDefIDs[unitDefID] = true
	end
end

--------------------------------------------------------------------------------

function createList()
	local vsx, vsy = gl.GetViewSizes()
	if (vsy > 1080) then
		scaleFactor = vsy/1080
	else
		scaleFactor = 1
	end
	dList = gl.CreateList(function()
		gl.Texture(vignetteTexture)
		gl.TexRect(-(vsx/25), -(vsy/25), vsx+(vsx/25), vsy+(vsy/25))
		gl.Texture(signTexture)
		gl.TexRect(vsx - 100*scaleFactor, vsy/2 +53*scaleFactor, vsx-20*scaleFactor, vsy/2 - 53*scaleFactor)
		gl.Texture(false)
	end)
end

function widget:Initialize()
	createList()
	if Spring.IsReplay() or Spring.GetGameFrame() > 0 then
		widget:PlayerChanged()
	end
end


function widget:PlayerChanged(playerID)
	myTeamID = Spring.GetMyTeamID()
	if Spring.GetSpectatingState() and Spring.GetGameFrame() > 0 then
		widgetHandler:RemoveWidget(self)
	end
end


function widget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer)
	if unitTeam == myTeamID and comUnitDefIDs[unitDefID] and not Spring.IsUnitVisible(unitID) then
		if Spring.GetSpectatingState() then
			widgetHandler:RemoveWidget(self)
		end
		opacity = maxOpacity
		--Spring.Echo("COMMANDER UNDER ATTACK!!!")
	end
end

function widget:ViewResize(newX,newY)
	if dList ~= nil then
		gl.DeleteList(dList)
	end
	createList()
end


function widget:Update(dt)
	if opacity > 0 then
		opacity = opacity - (maxOpacity * (dt/duration))
	end
end

function widget:DrawScreen()
	if opacity > 0.01 then
		gl.Color(1,0.5,0,opacity > 0.3 and maxOpacity or opacity)
		gl.CallList(dList)
	end
end

function widget:Shutdown()
	if dList ~= nil then
		gl.DeleteList(dList)
	end
end
