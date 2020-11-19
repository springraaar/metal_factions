function widget:GetInfo()
    return {
        name      = "Long Range Rocket Warning",
        desc      = "Shows a warning overlay when long range rockets are launched",
        author    = "raaar",
        date      = "2020",
        license   = "PD",
        layer     = 111,
        enabled   = true
    }
end

---------------------------------------------------------------------------------------------------
--  Declarations
---------------------------------------------------------------------------------------------------

local spGetTeamRulesParam = Spring.GetTeamRulesParam
local spGetMyTeamID = Spring.GetMyTeamID
local spGetMyAllyTeamID = Spring.GetMyAllyTeamID
local spGetTeamList = Spring.GetTeamList
local spAreTeamsAllied = Spring.AreTeamsAllied

local vignetteTexture	= ":n:"..LUAUI_DIRNAME.."Images/vignette.dds"
local alliedSignTexture = { ":n:"..LUAUI_DIRNAME.."Images/alliedRocketWarningx1.dds",
 ":n:"..LUAUI_DIRNAME.."Images/alliedRocketWarningx2.dds",
 ":n:"..LUAUI_DIRNAME.."Images/alliedRocketWarningx3.dds",
 ":n:"..LUAUI_DIRNAME.."Images/alliedRocketWarningx4.dds",
 ":n:"..LUAUI_DIRNAME.."Images/alliedRocketWarningx5.dds"
}
local enemySignTexture = { ":n:"..LUAUI_DIRNAME.."Images/alliedRocketWarningx1.dds",
 ":n:"..LUAUI_DIRNAME.."Images/alliedRocketWarningx2.dds",
 ":n:"..LUAUI_DIRNAME.."Images/alliedRocketWarningx3.dds",
 ":n:"..LUAUI_DIRNAME.."Images/alliedRocketWarningx4.dds",
 ":n:"..LUAUI_DIRNAME.."Images/alliedRocketWarningx5.dds"
}

local duration = 10
local maxOpacity = 0.9
local alliedOpacity = 0
local enemyOpacity = 0
local currentAlliedSignTexture = alliedSignTexture[1]
local currentEnemySignTexture = enemySignTexture[1]
local alliedYRelOffset = -0.1
local enemyYRelOffset = -0.132
local yRelSize = 0.04
local xRelSize = 0.15

local myTeamId = Spring.GetMyTeamID()
local myAllyId = Spring.GetMyAllyTeamID()
local oldAlliedLaunches = 0
local oldEnemyLaunches = 0

--------------------------------------------------------------------------------
function rebuildAlliedDList()
	local vsx, vsy = gl.GetViewSizes()
	--if alliedDList ~= nil then
	--	gl.DeleteList(alliedDList)
	--end	
	alliedDList = gl.CreateList(function()
		--gl.Texture(vignetteTexture)
		--gl.TexRect(-(vsx/25), -(vsy/25), vsx+(vsx/25), vsy+(vsy/25))
		gl.Texture(currentAlliedSignTexture)
		gl.TexRect(vsx - vsx*xRelSize - 20, vsy/2 + vsy*alliedYRelOffset +vsy*yRelSize/2, vsx-20, vsy/2 - vsy*yRelSize/2 + vsy*alliedYRelOffset)
		gl.Texture(false)
	end)	
end

function rebuildEnemyDList()
	local vsx, vsy = gl.GetViewSizes()
	--if enemyDList ~= nil then
	--	gl.DeleteList(enemyDList)
	--end	
	enemyDList = gl.CreateList(function()
		--gl.Texture(vignetteTexture)
		--gl.TexRect(-(vsx/25), -(vsy/25), vsx+(vsx/25), vsy+(vsy/25))
		gl.Texture(currentEnemySignTexture)
		gl.TexRect(vsx - vsx*xRelSize - 20, vsy/2 + vsy*enemyYRelOffset +vsy*yRelSize/2, vsx-20, vsy/2 - vsy*yRelSize/2 + vsy*enemyYRelOffset)
		gl.Texture(false)
	end)
end

function createList()
	rebuildAlliedDList()
	rebuildEnemyDList()
end

function widget:Initialize()
	Spring.LoadSoundDef("LuaRules/Configs/sound_defs.lua")
	createList()
	if Spring.IsReplay() or Spring.GetGameFrame() > 0 then
		widget:PlayerChanged()
	end
end


function widget:PlayerChanged(playerID)
	myTeamId = Spring.GetMyTeamID()
	if Spring.GetSpectatingState() and Spring.GetGameFrame() > 0 then
		widgetHandler:RemoveWidget(self)
	end
end


function widget:GameFrame(f)
	local myLaunches = spGetTeamRulesParam(myTeamId, "latestLRRLaunches") or 0
	local alliedLaunches = myLaunches
	local enemyLaunches = 0
	for _,tId in pairs(spGetTeamList())  do
		if (tId ~= myTeamId) then
			if (spAreTeamsAllied(myTeamId,tId)) then
				alliedLaunches = alliedLaunches + (spGetTeamRulesParam(tId, "latestLRRLaunches") or 0)
			else 
				enemyLaunches = enemyLaunches + (spGetTeamRulesParam(tId, "latestLRRLaunches") or 0)
			end
		end
	end
	
	--Spring.Echo("alliedLaunches="..alliedLaunches.." enemyLaunches="..enemyLaunches)
	
	-- add the recent launches from all allies
	if alliedLaunches > oldAlliedLaunches then
		oldAlliedLaunches = alliedLaunches
		local index = math.max(math.min(alliedLaunches,5),1)
		currentAlliedSignTexture = alliedSignTexture[index]
		rebuildAlliedDList()		
		alliedOpacity = maxOpacity
	elseif alliedLaunches == 0 then
		oldAlliedLaunches = 0
		currentAlliedSignTexture = alliedSignTexture[1]
		alliedOpacity = 0
	end
	-- add the recent launches from all allies
	if enemyLaunches > oldEnemyLaunches then
		if oldEnemyLaunches == 0 then
			Spring.PlaySoundFile('WARNING1', 1)
		end
		oldEnemyLaunches = enemyLaunches
		local index = math.max(math.min(enemyLaunches,5),1)
		currentEnemySignTexture = enemySignTexture[index]
		rebuildEnemyDList()
		enemyOpacity = maxOpacity
	elseif enemyLaunches == 0 then
		oldEnemyLaunches = 0
		currentEnemySignTexture = enemySignTexture[1]
		enemyOpacity = 0
	end
end

function widget:ViewResize(newX,newY)
	if alliedDList ~= nil then
		gl.DeleteList(alliedDList)
	end
	if enemyDList ~= nil then
		gl.DeleteList(enemyDList)
	end
	createList()
end


function widget:Update(dt)
	if alliedOpacity > 0 then
		alliedOpacity = alliedOpacity - (maxOpacity * (dt/duration))
	end
	if enemyOpacity > 0 then
		enemyOpacity = enemyOpacity - (maxOpacity * (dt/duration))
	end	
end

function widget:DrawScreen()
	if alliedOpacity > 0.01 then
		gl.Color(0.1,0.3,1,alliedOpacity > 0.3 and maxOpacity or alliedOpacity)
		gl.CallList(alliedDList)
	end
	if enemyOpacity > 0.01 then
		gl.Color(1,0.2,0.1,enemyOpacity > 0.3 and maxOpacity or enemyOpacity)
		gl.CallList(enemyDList)
	end
end

function widget:Shutdown()
	if alliedDList ~= nil then
		gl.DeleteList(alliedDList)
	end
	if enemyDList ~= nil then
		gl.DeleteList(enemyDList)
	end
end
