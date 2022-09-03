
function widget:GetInfo()
	return {
		name      = "Metal Factions Tooltip",
		desc      = "overrides default tooltip, shows shield and weapon info",
		author    = "raaar, based on a Kernel Panic widget by zwzsg",
		date      = "September 2012",
		license   = "GNU GPL v2",
		layer     = 0,
		enabled   = true
	}
end


VFS.Include("lualibs/constants.lua")
VFS.Include("lualibs/util.lua")

local frameSkip = 9       -- draw once every frameSkip+1 frames 
local counter = 0
local xpArr = {
"",
"\255\255\100\0I",
"\255\255\120\50II",
"\255\240\140\75III",
"\255\220\150\100IV",
"\255\200\200\200V",
"\255\210\210\200VI",
"\255\220\220\200VII",
"\255\230\230\200VIII",
"\255\240\240\200IX",
"\255\255\255\200X"
}

local TIP_COLOR_PREFIX = "\255\180\180\0"

local tempTooltip = nil
local min = math.min
local max = math.max
local floor = math.floor
local ceil = math.ceil
local modf = math.modf
local GetMouseState = Spring.GetMouseState
local TraceScreenRay = Spring.TraceScreenRay
local spGetSelectedUnitsCount = Spring.GetSelectedUnitsCount
local spGetSelectedUnits = Spring.GetSelectedUnits
local spGetUnitIsCloaked = Spring.GetUnitIsCloaked
local spGetUnitExperience = Spring.GetUnitExperience
local spGetUnitVelocity = Spring.GetUnitVelocity
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spGetTeamRulesParam = Spring.GetTeamRulesParam
local spGetUnitTeam = Spring.GetUnitTeam
local spGetTeamColor = Spring.GetTeamColor
local spIsGUIHidden = Spring.IsGUIHidden
local spGetCurrentTooltip = Spring.GetCurrentTooltip
local spGetDrawFrame = Spring.GetDrawFrame 
local spGetActiveCommand = Spring.GetActiveCommand

local glBlending = gl.Blending
local glColor = gl.Color
local glRect = gl.Rect
local glLineWidth = gl.LineWidth
local glShape = gl.Shape
local glText = gl.Text	
local glGetTextWidth = gl.GetTextWidth

local glCreateList	= gl.CreateList
local glDeleteList	= gl.DeleteList
local glCallList	= gl.CallList

local tooltipGlList = nil

--local fontHandler = gl.LoadFont("luaui/fonts/EDENMB__.TTF",16,1)

local TRANSPORT_MASS_LIMIT_LIGHT = 600
local TRANSPORT_MASS_LIMIT_MEDIUM = 1350
local TRANSPORT_MASS_LIMIT_HEAVY = 3000  
local PARALYZE_DAMAGE_FACTOR = 0.33 -- paralyze damage adds this fraction as normal damage
local ONCE_RELOAD_THRESHOLD = 999

local windGroundMin,windGroundMax,windGroundRef = 0

-- cached tooltip strings 
local cachedTooltipWeaponDataKey = ""
local cachedTooltipWeaponDataStr = ""

local noDamageWeaponDefIds = {
	[WeaponDefNames["comsat_beacon"].id] = true,
	[WeaponDefNames["scoper_beacon"].id] = true
}

local weaponTargetLabels = {
	AIR2 = "\255\60\60\80AIR",
	AIR = "\255\200\200\255AIR",
	SURFACE = "\255\160\140\130SURFACE",
	WATER = "\255\64\64\255WATER"
}

local weaponHitPowerLabels = {
	["1"] = "\255\150\150\255(L)\255\255\255\255",
	["2"] = "\255\160\140\50(M)\255\255\255\255",
	["3"] = "\255\200\110\100(H)\255\255\255\255"
}
local armorTypeLabels = {
	["L"] = "\255\150\150\255(L)\255\255\255\255",
	["M"] = "\255\160\140\50(M)\255\255\255\255",
	["H"] = "\255\200\110\100(H)\255\255\255\255"
}

local myPlayerID
local myTeamID
local myAllyTeamID
local nameByTeamID = {}
local addedBrightness = 0.2

-- get build hotkey
local function buildHotkey(uName)
	local key = nil
	if (WG.customHotkeys and WG.customHotkeys["build_"..uName]) then
		key = WG.customHotkeys["build_"..uName]
	end
	if key ~= nil then
		return "      \255\100\255\100 Hotkey \""..string.upper(key).."\""
	end
	return ""
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

function formatTargets(targets)
	local tList = splitString(targets,",")
	local result = ""
	
	for i,label in pairs(tList) do
		result = result .. "  " .. tostring(weaponTargetLabels[label])
	end
	
	return result
end

function widget:Initialize()
	Spring.SendCommands({"tooltip 0"})
	
	Spring.SetDrawSelectionInfo(false)
	
	-- find shield weapon and its max power
	for _,ud in pairs(UnitDefs) do
		ud.shieldPower   = 0;
		local shieldDefID = ud.shieldWeaponDef
		ud.shieldPower = ((shieldDefID)and(WeaponDefs[shieldDefID].shieldPower))or(-1)
	end
	
	windGroundMin, windGroundMax = Spring.GetGroundExtremes()
	windGroundMin, windGroundMax = math.max(windGroundMin,0), math.max(windGroundMax,1)
	windGroundRef = 0.25*windGroundMax + 0.75*windGroundMin

	-- get players and teams info
	myPlayerID = Spring.GetLocalPlayerID()
	myTeamID = Spring.GetLocalTeamID()
	myAllyTeamID = Spring.GetLocalAllyTeamID()
	local teamList   = Spring.GetTeamList()
	for _,teamID in pairs(teamList) do
		local _,playerID,_,isAI, tside, tallyteam = Spring.GetTeamInfo(teamID)
		local name,version
		
		if isAI then
			_,_,_,_, name, version = Spring.GetAIInfo(teamID)
	
			local aiInfo = Spring.GetTeamLuaAI(teamID)
			if (aiInfo and string.sub(aiInfo,1,4) == "MFAI") then
				name = aiInfo
			else
				if type(version) == "string" then
					name = "AI:" .. name .. "-" .. version 
				else
					name = "AI:" .. name
				end
			end
		else
			name,_, _, _, _, _, _, _, _ = Spring.GetPlayerInfo(playerID)
		end
		
		nameByTeamID[teamID] = name == nil and "Uncontrolled" or name 
	end
end
 
 
function widget:Shutdown()
        Spring.SendCommands({"tooltip 1"})
end


-- generates upgrade data string for player
function getTooltipUpgradeData(teamId)
	local newTooltip = ""
	
	-- get upgrades for team
	local statusStr = spGetTeamRulesParam(teamId,"upgrade_status")
	local listStr = spGetTeamRulesParam(teamId,"upgrade_list")
	local modStr = spGetTeamRulesParam(teamId,"upgrade_modifiers")
	if listStr and listStr == 0 then
		listStr = ""
	end
	
	if (statusStr) then
		newTooltip = newTooltip..statusStr.."\n"
	end
	if (listStr) then
		newTooltip = newTooltip..listStr.."\n"
	end
	if (modStr) then
		newTooltip = newTooltip.." \nEFFECTS\n"..modStr
	end
			
	return newTooltip
end


-- generates upgrade summary string for player
function getTooltipUpgradeLabel(teamId)
	local newTooltip = "\255\255\255\255"
	
	-- get upgrades for team
	local labelStr = spGetTeamRulesParam(teamId,"upgrade_label")
	
	if (labelStr) then
		newTooltip = newTooltip..labelStr
	else
		newTooltip = newTooltip.."Upgrades: \255\130\130\130[0]  [0]  [0]"
	end
			
	return newTooltip
end

-- generates weapon data string for unit
function getTooltipWeaponData(ud, xpMod, rangeMod, dmgMod)
	local newTooltip = ""
	if not rangeMod then
		rangeMod = 1
	end
	if not dmgMod then
		dmgMod = 1
	end
	-- use cache	
	cKey = floor(spGetDrawFrame()/60)..ud.id..xpMod..rangeMod..dmgMod
	if (cKey == cachedTooltipWeaponDataKey) then
		return cachedTooltipWeaponDataStr
	end
	
	if ud.canKamikaze then
	    local weapname=ud.selfDExplosion
	    local weap=nil
	    for wid,weaponDef in pairs(WeaponDefs) do
	        if weaponDef.name==weapname then
	        	weap=WeaponDefs[wid]
	        end
	    end
	    if weap then
	        local weapon_action="Damage"
	        if weap.damages and weap.damages.paralyzeDamageTime and weap.damages.paralyzeDamageTime>0 then
                weapon_action="Paralyze"
                local paralyzeDmg = dmgMod * weap.damages[Game.armorTypes.default]
                local normalDmg = PARALYZE_DAMAGE_FACTOR * paralyzeDmg
				newTooltip = newTooltip.. "\n\255\100\255\255Paralyze: "..formatNbr(paralyzeDmg,0).."/once \255\255\213\213Damage: \255\255\170\170"..formatNbr(normalDmg,0).."/once"
	        else
	        	local normalDmg = dmgMod * weap.damages[Game.armorTypes.default]
	        	newTooltip = newTooltip.."\n\255\255\213\213Damage: \255\255\170\170"..formatNbr(normalDmg,0).."/once"
	        end
	        
			local hitpower = 0
			if ( weap.customParams and weap.customParams.hitpower) then
				hitpower = weap.customParams.hitpower
			end
			newTooltip = newTooltip..weaponHitPowerLabels[weap.customParams.hitpower]
	    end
    elseif ud.weapons and ud.weapons[1] and ud.weapons[1].weaponDef then
		for _,w in pairs(ud.weapons) do
			local weap=WeaponDefs[w.weaponDef]
			if weap.isShield == false and weap.description ~= "No Weapon" then
				local weapon_action="Dmg/s"
				local reloadTime = weap.reload
				local isBeamLaser = weap.type == "BeamLaser"
				local damage = dmgMod * (weap.damages[Game.armorTypes.default] * (weap.projectiles*weap.salvoSize)) * xpMod 
				local dps = damage / reloadTime
				local energyPerSecond = (weap.energyCost * (weap.salvoSize)) / reloadTime
				local isDisruptor = false
				local actionStr = ""
			
				local range = weap.range * rangeMod
				if (noDamageWeaponDefIds[w.weaponDef]) then
					if (weap.customParams and weap.customParams.action) then
						actionStr = weap.customParams.action
					else
						actionStr = "no damage"
					end
				else
					if weap.damages and weap.damages.paralyzeDamageTime and weap.damages.paralyzeDamageTime>0 then
						isDisruptor = true
					end
					
					if (reloadTime > 5) then
						if (isDisruptor) then
							local paralyzeDmg = damage
							local normalDmg = paralyzeDmg * PARALYZE_DAMAGE_FACTOR
							actionStr = "Paralyze: \255\100\255\255"..formatNbr(paralyzeDmg,0).."\255\255\255\255"..(reloadTime >= ONCE_RELOAD_THRESHOLD and " once" or ("/"..formatNbr(reloadTime,2).."s"))
							actionStr = actionStr.." Dmg: \255\255\255\255"..formatNbr(normalDmg,0).."\255\255\255\255"..(reloadTime >= ONCE_RELOAD_THRESHOLD and " once" or ("/"..formatNbr(reloadTime,2).."s"))
						else
							actionStr = "Dmg/s: \255\255\255\255"..formatNbr(damage,0).."\255\255\255\255"..(reloadTime >= ONCE_RELOAD_THRESHOLD and " once" or ("/"..formatNbr(reloadTime,2).."s"))
						end
					else 
						if (isDisruptor) then
							local paralyzeDps = dps
							local normalDps = paralyzeDps * PARALYZE_DAMAGE_FACTOR
							actionStr = "Paralyze/s: \255\100\255\255"..formatNbr(paralyzeDps,0).."\255\255\255\255"
							actionStr = actionStr.." Dmg/s: \255\255\255\255"..formatNbr(normalDps,0).."\255\255\255\255"
						else
							actionStr = "Dmg/s: \255\255\255\255"..formatNbr(dps,1).."\255\255\255\255"
						end
					end
					
					local hitpower = 0
					if ( weap.customParams and weap.customParams.hitpower) then
						hitpower = weap.customParams.hitpower
					end
					actionStr = actionStr..weaponHitPowerLabels[weap.customParams.hitpower]
				end       
				newTooltip = newTooltip.."\n\255\255\255\255"..weap.description.."    "..actionStr.."     Range: "..formatNbr(range,2)
			
				if energyPerSecond  > 0 then
					newTooltip = newTooltip.."     \255\255\255\0E"..(reloadTime >= 5 and "" or "/s")..": "..formatNbr((reloadTime >= 5 and energyPerSecond*reloadTime or energyPerSecond),1)
				end
				
				if (weap.customParams and weap.customParams.targets) then
					newTooltip = newTooltip.."     \255\255\255\255Targets: "..formatTargets(weap.customParams.targets)
				else
					if weap.waterWeapon then
						newTooltip = newTooltip.."     \255\255\255\255Targets: \255\64\64\255WATER"
					end
				end
			end
		end
	end
    
    cachedTooltipWeaponDataKey = cKey
	cachedTooltipWeaponDataStr = newTooltip
	return newTooltip
end
 
-- generates build power string in m/s as a function of build speed
function getTooltipBuildPower(buildSpeed)
	
	-- time is 11 * weighted_cost_metal
	-- time = 11 * (m + e/60) / spd
	-- m + e/60 = time * spd / 11
	-- non-aircraft have 5x e cost as metal, so
	-- m + 5m/60 = time * spd / 11
	-- 13m/12 = time * spd / 11
	-- m/time = 12*spd / (11*13) 
	
	return "\255\255\255\150Build Power: ".. formatNbr(12 * buildSpeed / (11*13),1).." metal/s"
end

-- get tooltip mass/transportability label
function getTooltipTransportability(ud)
	if ud.speed > 0 then
		local transpStr = ""
		if ud.cantBeTransported  then 
			transpStr = "no transport"
		elseif ud.mass <= TRANSPORT_MASS_LIMIT_LIGHT then
			transpStr = "light"
		elseif ud.mass <= TRANSPORT_MASS_LIMIT_MEDIUM then
			transpStr = "medium"
		elseif ud.mass <= TRANSPORT_MASS_LIMIT_HEAVY then
			transpStr = "heavy"
		else 
			transpStr = "no transport"
		end
	
		return "     \255\200\200\200Mass: ".. formatNbr(ud.mass,0).." ("..transpStr..")"
	else
		return ""
	end	
end
	
-- update tooltip gl list
function updateTooltipGlList(text)
	local vsx,vsy = gl.GetViewSizes() 
	local fontSize = max(8,vsy/72)
	local nttString = ''
	local nttList = {}

	nttString = text:gsub("\n+", "\n")
	nttList = {}    
	local maxWidth = 0
	local width = 0
	for line in string.gmatch(nttString,"[^\r\n]+") do
		table.insert(nttList,line)
		width = glGetTextWidth(line)
		if width>maxWidth then
			maxWidth = width
		end
	end
	local lineCount = #nttList
	local xTooltipSize = fontSize*(1+maxWidth)
	local yTooltipSize = fontSize*(1+lineCount)
	local x1,y1,x2,y2 = 0,0,xTooltipSize,yTooltipSize
	glDeleteList(tooltipGlList)
	tooltipGlList = glCreateList(function()
		glBlending(GL.SRC_ALPHA,GL.ONE_MINUS_SRC_ALPHA) -- default
		glColor(0.0,0.0,0.0,0.6)  --background
		glRect(x1,y1,x2,y2)
		glColor(0.0,0.0,0.0,1)  --border
		glLineWidth(1)
		glShape(GL.LINE_LOOP,{	{v={x1,y2}},{v={x2,y2}},{v={x2,y1}},{v={x1,y1}},})
		glColor(1,1,1,1)
		
		glText(trim(nttString),x1+fontSize*0.5,y1+fontSize*(lineCount+0.5-1),fontSize,'o')
		--for k=1,lineCount do
		--	glText(nttList[k],x1+fontSize*0.5,y1+fontSize*(lineCount+0.5-k),fontSize,'o')
		--end	
	end)
end

-- updates the tooltip as necessary
function updateTooltip()
	if tempTooltip and frameSkip > 0 then
		counter = counter +1
		if (counter % (frameSkip+1) ~= 0) then
			return
		end
	end
	
	updateTooltipGlList(generateNewTooltip())
end

-- generates new tooltip 
function generateNewTooltip()
	local currentTooltip = spGetCurrentTooltip() 
	local newTooltip = ""
	local hotkeyTooltip = ""
	local foundTooltipType = nil
	local mx,my,gx,gy,gz,id
	local selectedUnitsCount = spGetSelectedUnitsCount()
	mx,my = GetMouseState()
	if mx and my then
		local _,pos = TraceScreenRay(mx,my,true,true)
		if pos then
			gx,gy,gz=unpack(pos)
		end
		local kind,var1 = TraceScreenRay(mx,my,false,true)
		if kind=="unit" then
			id = var1
		end
	end
 
	local terrainType = string.match(currentTooltip,"Terrain type: (.+)\nSpeeds T/K/H/S ")
	if terrainType~=nil then
		newTooltip="\255\255\255\64"..terrainType
		if gx and gz then
			newTooltip=newTooltip.."\255\255\255\255\n("..floor(gx+0.5)..","..floor(gz+0.5)..")"
			
			local h = Spring.GetGroundHeight(gx,gz)
			local airMeshH = Spring.GetSmoothMeshHeight(gx,gz)
			local _,_,_,slope = Spring.GetGroundNormal(gx,gz,true)  
			newTooltip=newTooltip.."\n\nAltitude "..floor(h).."\n\nAir Mesh Altitude "..floor(airMeshH).."\n\nSlope "..slope
		end
		foundTooltipType="terrain"
		tempTooltip = newTooltip
		return newTooltip		
	end
 
	local buildpower = 1

	if selectedUnitsCount>1 then
		newTooltip="\255\255\255\255"..selectedUnitsCount.."\255\255\255\255 units selected\255\255\255\255\n"
	end
	
	-- compute total buildpower of units selected 
	if selectedUnitsCount >= 1 then
		for _,u in pairs(spGetSelectedUnits()) do
			local def=UnitDefs[Spring.GetUnitDefID(u)]
			buildpower = buildpower + def.buildSpeed
		end
	end  
	--Spring.Echo("\n"..currentTooltip) 
	
	
	local buildOrderUnitDefName = nil
	if string.sub(currentTooltip,1,9) == "buildunit" then
		buildOrderUnitDefName = string.match(currentTooltip,"buildunit_(.+)Build:")
		newTooltip = newTooltip.."\255\255\255\150Build:\255\255\255\255\n"
	elseif string.sub(currentTooltip,1,9) == "morphunit" then
		buildOrderUnitDefName = string.match(currentTooltip,"morphunit_(.+)Morph to")
		buildOrderUnitDefName = string.gsub(buildOrderUnitDefName, "[\128-\255]", "")
		newTooltip = newTooltip..string.sub(currentTooltip,11+string.len(buildOrderUnitDefName)).."\255\255\255\255\n\n"
	else
		-- check if it's an active build order
		local _, cmdID = spGetActiveCommand()
		if (cmdID and cmdID < 0) then
			local ud = UnitDefs[-cmdID]
			if ud then 
				buildOrderUnitDefName = ud.name
			end 
		end 
		newTooltip = newTooltip.."\255\255\255\150Build:\255\255\255\255\n"
	end
	
	if buildOrderUnitDefName then
		local fud = UnitDefNames[buildOrderUnitDefName]
		if fud then
			local armorTypeStr= "L"
			if ( Game.armorTypes[fud.armorType] == "armor_heavy" ) then armorTypeStr = "H"
			elseif ( Game.armorTypes[fud.armorType] == "armor_medium" ) then armorTypeStr = "M" end
			
			-- old build time expression : floor((29+floor(31+fud.buildTime/(buildpower/32)))/30)
			local buildTimeStr = formatNbr(fud.buildTime/buildpower,2)
			newTooltip = newTooltip.."\n\n"..fud.humanName.." ("..fud.tooltip..")"..buildHotkey(fud.name).."\n"..
				"\255\200\200\200Metal: "..fud.metalCost.."    \255\255\255\0Energy: "..fud.energyCost..""..
				"\255\213\213\255".."    Build time: ".."\255\170\170\255"..
				buildTimeStr.."s".."    "..getTooltipTransportability(fud).."\n"..
				"\255\200\200\200Health: ".."\255\200\200\200"..fud.health..armorTypeLabels[armorTypeStr]
				if fud.shieldPower > 0 then newTooltip=newTooltip.."\255\135\135\255     Shield: "..formatNbr(fud.shieldPower) end
					
			-- weapons
			if fud.canKamikaze or (fud.weapons and fud.weapons[1] and fud.weapons[1].weaponDef) then
				newTooltip = newTooltip..getTooltipWeaponData(fud,1)
			end
			
			-- build power
			if fud.buildSpeed and fud.buildSpeed > 1 then
				newTooltip = newTooltip.."\n"..getTooltipBuildPower(fud.buildSpeed).."\255\255\255\255\n"
			end
			
			-- speed
			newTooltip = newTooltip.."\255\255\255\255\n"
			if fud.speed and fud.speed>0 then
				newTooltip = newTooltip.."\255\193\255\187Speed: \255\134\255\121"..formatNbr(fud.speed,2).."\255\255\255\255"
			else
				-- show where buildings can be built
				if (fud.minWaterDepth > 0) then
					newTooltip = newTooltip.."Buildable on \255\64\64\255WATER\255\255\255\255\n"
				elseif (fud.maxWaterDepth < 100) then
					newTooltip = newTooltip.."Buildable on \255\200\200\200LAND\255\255\255\255\n"
				else
					newTooltip = newTooltip.."Buildable on \255\200\200\200LAND\255\255\255\255,\255\64\64\255WATER\255\255\255\255\n"
				end
			end
			
			if fud.windGenerator > 1 then
				
				local minWindE = WIND_INCOME_MULTIPLIER * math.min(Game.windMin,WIND_STR_CAP)
				local maxWindE = WIND_INCOME_MULTIPLIER * math.min(Game.windMax,WIND_STR_CAP)
				local avgWindE = (minWindE + maxWindE) / 2
				-- rescale to compensate for avg being higher than arithmetic avg
				minWindE = minWindE * EXCESS_WIND_REDUCTION_MULT
				maxWindE = maxWindE * EXCESS_WIND_REDUCTION_MULT
				
			   	local factor = 1
			   	if gy then
				   	if gy >= windGroundMax then
						factor = 1 + WIND_ALTITUDE_EXTRA_INCOME_FRACTION
					elseif gy < windGroundRef then
						factor = 1
					else
						factor = 1 + ((gy-windGroundRef) / (windGroundMax-windGroundRef)) * WIND_ALTITUDE_EXTRA_INCOME_FRACTION
					end
				end
				minWindE = minWindE * factor 
				maxWindE = maxWindE * factor
				avgWindE = avgWindE * factor
			   	minWindE = formatNbr(minWindE,0)
			   	maxWindE = formatNbr(maxWindE,0)
			   	avgWindE = formatNbr(avgWindE,0)
				
				newTooltip = newTooltip.."Generates \255\255\255\0"..minWindE.."-"..maxWindE.." E/s (avg "..avgWindE..")\255\155\155\155 (Altitude Bonus: +"..formatNbr((factor-1)*100,1).."%)\255\255\255\255  \n"
			elseif fud.tidalGenerator == 1 then
				newTooltip = newTooltip.."Generates \255\255\255\0"..Game.tidal.." E/s\255\255\255\255\n"
			end
			
			if fud.customParams.tip then
				newTooltip = newTooltip.."\n"..TIP_COLOR_PREFIX..fud.customParams.tip.."\255\255\255\255\n"
			end
			
			foundTooltipType="knownbuildbutton"
			tempTooltip = newTooltip
			return newTooltip	
		end
	end
 
	local isItLiveUnitTooltip = string.match(currentTooltip,"Experience (.+) Cost ")
	if isItLiveUnitTooltip or currentTooltip=="" then

		-- id being calculated way above
		if not id and selectedUnitsCount >=1 then
			id = spGetSelectedUnits()[selectedUnitsCount]
		end
                
		-- many units
		if id and selectedUnitsCount >1 then
			local totalMetalMake = 0
			local totalMetalUse = 0 
			local totalEnergyMake = 0
			local totalEnergyUse = 0
			local totalHealth = 0
			local totalMaxHealth = 0
			local totalShieldPower = 0
			local totalMaxShieldPower = 0
			local totalEnergyCost = 0
			local totalMetalCost = 0
			local anyShield = false
					
			for _,u in pairs(spGetSelectedUnits()) do
			
				local hpMod = spGetUnitRulesParam(u,"upgrade_hp")
				if not hpMod then
					hpMod = 1
				else
					hpMod = 1 + hpMod
				end
				local ud=UnitDefs[Spring.GetUnitDefID(u)]
				local metalMake,metalUse,energyMake,energyUse = Spring.GetUnitResources(u)
				local health,maxHealth,paralyzeDamage,captureProgress,buildProgress = Spring.GetUnitHealth(u)						
				health = health * hpMod
				maxHealth = maxHealth * hpMod
				local hasShield, ShieldPower=Spring.GetUnitShieldState(u)
				local maxShieldPower = ud.shieldPower
				if(hasShield) then
					anyShield = true
				end
				
				-- energy and metal cost
				totalEnergyCost = totalEnergyCost + ud.energyCost
				totalMetalCost = totalMetalCost + ud.metalCost
										
				if (health and maxHealth) then
				    totalHealth = totalHealth + health
				    totalMaxHealth = totalMaxHealth + maxHealth
				end
				if (hasShield) then
				    totalShieldPower = totalShieldPower + ShieldPower
				    totalMaxShieldPower = totalMaxShieldPower + maxShieldPower
				end
				
				-- energy and metal upkeep
				if( metalMake and metalUse and energyMake and energyUse) then
					totalMetalMake = totalMetalMake + metalMake
					totalMetalUse = totalMetalUse + metalUse
					totalEnergyMake = totalEnergyMake + energyMake
					totalEnergyUse = totalEnergyUse + energyUse							
				end
			end
					
			-- cost
			newTooltip = newTooltip.."\255\200\200\200Metal: "..totalMetalCost.."    \255\255\255\0Energy: "..totalEnergyCost.."\n"
			
			-- health totals					
			newTooltip = newTooltip.."\255\200\200\200Health: ".."\255\200\200\200"..floor(totalHealth).."\255\200\200\200/\255\200\200\200"..floor(totalMaxHealth)
			if anyShield then newTooltip=newTooltip.."\255\135\135\255      Shield: "..formatNbr(math.min(totalShieldPower,totalMaxShieldPower)).."/"..formatNbr(totalMaxShieldPower) end
			
			-- energy and metal upkeep totals
			if true then
				newTooltip = newTooltip.."\n\255\200\200\200Metal: \255\0\255\0+"..formatNbr(totalMetalMake,1).."\255\255\255\255/\255\255\0\0"..formatNbr(-totalMetalUse,1)
				newTooltip = newTooltip.."    \255\255\255\0Energy: \255\0\255\0+"..formatNbr(totalEnergyMake,1).."\255\255\255\255/\255\255\0\0"..formatNbr(-totalEnergyUse,1)
			end
			foundTooltipType="liveunit"
			tempTooltip = newTooltip
			return newTooltip	
		-- one unit
		elseif id or selectedUnitsCount ==1 then
			local u=id
			local ud=UnitDefs[Spring.GetUnitDefID(u)]
			
			local metalMake,metalUse,energyMake,energyUse = Spring.GetUnitResources(u)
			local isFriendly = metalMake ~= nil       -- assume only friendly units have this info
			local teamID = spGetUnitTeam(id) 
			
			-- build progress, health and shield
			local health,maxHealth,paralyzeDamage,captureProgress,buildProgress = Spring.GetUnitHealth(u)
			stunned_or_beingbuilt, stunned, beingbuilt = Spring.GetUnitIsStunned(u)
			newTooltip = ud.humanName.." ("..ud.tooltip..")"
			-- owner
			local r,g,b = spGetTeamColor(teamID)
			r,g,b,_ = convertColor(r,g,b,0)
			newTooltip = newTooltip.." \255"..string.char(floor(255*r))..string.char(floor(255*g))..string.char(floor(255*b))..nameByTeamID[teamID]
			
			local hpMod = spGetUnitRulesParam(u,"upgrade_hp")
			if not hpMod then
				hpMod = 1
			else
				hpMod = 1 + hpMod
			end
			health = health * hpMod
			maxHealth = maxHealth * hpMod
			-- experience
			local xp = spGetUnitRulesParam(u,"experience") or 0
			local xpMod = 1
			if xp and xp>0 then
				local xpIndex = min(10,max(floor(11*xp/(xp+1)),0))+1
				xpMod = 1+0.35*(xp/(xp+1))
				if(xpIndex > 1) then
					newTooltip = newTooltip.."\255\255\255\255    Experience: "..xpArr[xpIndex]
				end
			end
			local dmgMod = spGetUnitRulesParam(u,"upgrade_damage")
			if not dmgMod then
				dmgMod = 1
			else
				dmgMod = 1 + dmgMod
			end
			local rangeMod = spGetUnitRulesParam(u,"upgrade_range")
			if not rangeMod then
				rangeMod = 1
			else
				rangeMod = 1 + rangeMod
			end
												
						                        
			-- paralysis
			if stunned then
				newTooltip = newTooltip.."\255\194\173\255   PARALYZED"
			end
			-- cloaking
			if spGetUnitIsCloaked(u) then
				newTooltip = newTooltip.."\255\170\170\170   CLOAKED"
			end        
			-- alliance
			if isFriendly == false then
				newTooltip = newTooltip.."    \255\255\0\0ENEMY"	
			end

			newTooltip = newTooltip.."\n"
			if buildProgress and buildProgress<1 then
				newTooltip = newTooltip.."\255\213\213\255".."Build progress: ".."\255\170\170\255"..formatNbr(100*buildProgress).."%\n"
			end

			-- cost
			newTooltip = newTooltip.."\255\200\200\200Metal: "..ud.metalCost.."    \255\255\255\0Energy: "..ud.energyCost.."    "..getTooltipTransportability(ud).."\n"
		
		
			local armorTypeStr= "L"
			if ( Game.armorTypes[ud.armorType] == "armor_heavy" ) then armorTypeStr = "H"
			elseif ( Game.armorTypes[ud.armorType] == "armor_medium" ) then armorTypeStr = "M" end
		
			local hasShield, ShieldPower=Spring.GetUnitShieldState(id)
			local maxShieldPower = ud.shieldPower
			if (health ~= nil) then
				newTooltip = newTooltip.."\255\200\200\200Health: ".."\255\200\200\200"..floor(health).."\255\200\200\200/\255\200\200\200"..floor(maxHealth)..armorTypeLabels[armorTypeStr]
				if hasShield then newTooltip=newTooltip.."\255\135\135\255      Shield: "..formatNbr(math.min(ShieldPower,maxShieldPower)).."/"..formatNbr(maxShieldPower) end
			end
		    
			-- energy and metal upkeep
			if isFriendly then
				newTooltip = newTooltip.."    \255\200\200\200Metal: \255\0\255\0+"..formatNbr(metalMake,1).."\255\255\255\255/\255\255\0\0"..formatNbr(-metalUse,1)
				newTooltip = newTooltip.."    \255\255\255\0Energy: \255\0\255\0+"..formatNbr(energyMake,1).."\255\255\255\255/\255\255\0\0"..formatNbr(-energyUse,1)
				-- newTooltip=newTooltip.."\255\255\255\0     +E/M ratio: "..formatNbr(energyMake / ud.metalCost,4).."\n"

				if ud.windGenerator > 1 then
					local eMade = spGetUnitRulesParam(u,"energy_made")
					local eMadeFrames = spGetUnitRulesParam(u,"energy_made_frames")
					if (eMadeFrames and eMadeFrames > 0) then
						newTooltip = newTooltip.."\n\255\255\255\0Avg E/s produced: "..formatNbr(eMade*30 / eMadeFrames,2).."\255\255\255\255\n"
					end
				end
			end
		
			-- weapons
			newTooltip = newTooltip..getTooltipWeaponData(ud,xpMod,rangeMod,dmgMod).."\n"
		  
			-- build power
			if ud.buildSpeed and ud.buildSpeed > 1 then
				newTooltip = newTooltip.."\n"..getTooltipBuildPower(ud.buildSpeed)..  "\255\255\255\255\n"
			end
                        
			-- upgrades (upgrade centers only)
			local isUpgradeCenter = string.find(ud.name, "upgrade_center")
			local teamId = spGetUnitTeam(u)
			if isUpgradeCenter then
				newTooltip = newTooltip..getTooltipUpgradeData(teamId).."\n\n"
			end
						
			-- speed
			if ud.speed and ud.speed>0 then
				local speedMod = spGetUnitRulesParam(u,"upgrade_speed")
				if not speedMod then
					speedMod = 1
				else
					speedMod = 1 + speedMod
				end
				
				local vx,vy,vz = spGetUnitVelocity(u)
				local speed = 30*math.sqrt(vx*vx+vz*vz)
				newTooltip = newTooltip.."\255\193\255\187Speed: \255\134\255\121"..formatNbr(speed).."\255\193\255\187/\255\134\255\121"..formatNbr(ud.speed*speedMod,2).."\255\255\255\255      "
			end

			if ud.transportCapacity>0 and ud.transportMass>0 and isFriendly then
				local currentCapacityUsage = 0 
				local currentMassUsage = 0
				
				-- get sum of mass and size for all transported units                                
				for _,tUnit in pairs(Spring.GetUnitIsTransporting(u)) do
					local tUd=UnitDefs[Spring.GetUnitDefID(tUnit)]
					currentCapacityUsage = currentCapacityUsage + tUd.xsize 
					currentMassUsage = currentMassUsage + tUd.mass
				end
				 
				newTooltip = newTooltip.."\255\255\255\255Transport: "..formatNbr(min(2,(currentCapacityUsage/ud.transportCapacity))*50,0).."% / "..formatNbr((currentMassUsage/ud.transportMass)*100,0).."%      "
			end

			-- upgrade summary
			if not isUpgradeCenter then
				newTooltip = newTooltip..getTooltipUpgradeLabel(spGetUnitTeam(u))
			end
 						
			if ud.customParams.tip then
				newTooltip = newTooltip.."\n"..TIP_COLOR_PREFIX..ud.customParams.tip.."\255\255\255\255\n"
			end
			
			--[[
			metalExtraction = Spring.GetUnitMetalExtraction(u)
			if (metalExtraction) then
				local x,y,z = Spring.GetUnitPosition(u)
				local metalAmount = Spring.GetMetalAmount(x, z )
				local refExtr = Spring.GetMetalExtraction(x, z )  
				newTooltip = newTooltip.."\nextracts="..metalExtraction.." amount="..metalAmount.." refExtr="..refExtr
			end
 			]]--
 			
			foundTooltipType="liveunit"
			tempTooltip = newTooltip
			return newTooltip	
		end
	end
 
	local hotkeys = string.match(currentTooltip.."\n","Hotkeys: (.-)\n")
	if hotkeys then
		hotkeyTooltip = "\n\255\255\196\128Hotkeys: ".."\255\255\128\001"..hotkeys.."\255\255\255\255"
		currentTooltip=string.gsub(currentTooltip.."\n","Hotkeys: .-\n","")
		newTooltip=newTooltip..hotkeyTooltip
		currentTooltip=currentTooltip..hotkeyTooltip
	end
 
	local action = string.match(currentTooltip,"(.-)\n")
	if action then
		action = string.match(action,"(.-): ")
		if action then
			currentTooltip=string.gsub(currentTooltip,"(.-): ","",1)
			currentTooltip="\255\170\255\170"..action..":\255\255\255\255 "..currentTooltip
		end
	end
  
	if foundTooltipType then
		tempTooltip = newTooltip
		return newTooltip
	else
		tempTooltip = currentTooltip
		return currentTooltip
	end
end

function widget:DrawScreen()
	if spIsGUIHidden() then
		return
	end

	updateTooltip()
	glCallList(tooltipGlList)
	
--[[
	nttString = generateNewTooltip()
	nttList = {}    
	local maxWidth = 0
	local width = 0
	for line in string.gmatch(nttString,"[^\r\n]+") do
		table.insert(nttList,line)
		width = glGetTextWidth(line)
		if width>maxWidth then
			maxWidth = width
		end
	end
	local lineCount = #nttList

 	local x1,y1,x2,y2=0,0,xTooltipSize,yTooltipSize
	xTooltipSize = fontSize*(1+maxWidth)
	yTooltipSize = fontSize*(1+lineCount)
  
	glBlending(GL.SRC_ALPHA,GL.ONE_MINUS_SRC_ALPHA) -- default
	glColor(0.0,0.0,0.0,0.6)  --background
	glRect(x1,y1,x2,y2)
	glColor(0.0,0.0,0.0,1)  --border
	glLineWidth(1)
	glShape(GL.LINE_LOOP,{	{v={x1,y2}},{v={x2,y2}},{v={x2,y1}},{v={x1,y1}},})	gl.Color(1,1,1,1)
	
	glText(trim(nttString),x1+fontSize*0.5,y1+fontSize*(lineCount+0.5-1),fontSize,'o')
	
	]]--
	--for k=1,lineCount do
		--glText(nttList[k],x1+fontSize*0.5,y1+fontSize*(lineCount+0.5-k),fontSize,'o')
		--glText("bla",0,y1+fontSize*(lineCount+0.5-k),fontSize,'o')
		--glText("bla",0,y1+fontSize*(lineCount+0.5-k),fontSize,'o')
		--glText("bla",0,y1+fontSize*(lineCount+0.5-k),fontSize,'o')
		--glText("bla",0,y1+fontSize*(lineCount+0.5-k),fontSize,'o')
		--glText("bla",0,y1+fontSize*(lineCount+0.5-k),fontSize,'o')
	--end
end
 

