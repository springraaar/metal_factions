
function widget:GetInfo()
	return {
		name      = "Metal Factions Tooltip",
		desc      = "overrides default tooltip, shows shield and weapon info",
		author    = "raaar, based on a Kernel Panic widget by zwszg",
		date      = "September 2012",
		license   = "GNU GPL v2",
		layer     = 0,
		enabled   = true
	}
end

local frameSkip = 4       -- draw once every frameSkip+1 frames 
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

local TRANSPORT_MASS_LIMIT_LIGHT = 1200
local TRANSPORT_MASS_LIMIT_HEAVY = 3000  
local PARALYZE_DAMAGE_FACTOR = 0.33 -- paralyze damage adds this fraction as normal damage
local ONCE_RELOAD_THRESHOLD = 999

local noDamageWeaponDefIds = {
	[WeaponDefNames["comsat_beacon"].id] = true,
	[WeaponDefNames["scoper_beacon"].id] = true
}

local myPlayerID
local myTeamID
local myAllyTeamID
local nameByTeamID = {}
local addedBrightness = 0.2

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

function widget:Initialize()
	Spring.SendCommands({"tooltip 0"})
	
	Spring.SetDrawSelectionInfo(false)
	
	-- find shield weapon and its max power
	for _,ud in pairs(UnitDefs) do
		ud.shieldPower   = 0;
		local shieldDefID = ud.shieldWeaponDef
		ud.shieldPower = ((shieldDefID)and(WeaponDefs[shieldDefID].shieldPower))or(-1)
	end
	
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
  
-- format number  
-- TODO put this on a lib
function FormatNbr(x,digits)
	if x then
		local ret=string.format("%."..(digits or 0).."f",x)
		if digits and digits>0 then
			while true do
				local last = string.sub(ret,string.len(ret))
				if last=="0" or last=="." then
					ret = string.sub(ret,1,string.len(ret)-1)
				end
				if last~="0" then
					break
				end
			end
		end
		return ret
	else
		return ""
	end
end

-- generates upgrade data string for player
function GetTooltipUpgradeData(teamId)
	local NewTooltip = ""
	
	-- get upgrades for team
	local statusStr = spGetTeamRulesParam(teamId,"upgrade_status")
	local listStr = spGetTeamRulesParam(teamId,"upgrade_list")
	local modStr = spGetTeamRulesParam(teamId,"upgrade_modifiers")
	
	if (statusStr) then
		NewTooltip = NewTooltip..statusStr.."\n"
	end
	if (listStr) then
		NewTooltip = NewTooltip..listStr.."\n"
	end
	if (modStr) then
		NewTooltip = NewTooltip.." \nEFFECTS\n"..modStr
	end
			
	return NewTooltip
end


-- generates upgrade summary string for player
function GetTooltipUpgradeLabel(teamId)
	local NewTooltip = ""
	
	-- get upgrades for team
	local labelStr = spGetTeamRulesParam(teamId,"upgrade_label")
	
	if (labelStr) then
		NewTooltip = NewTooltip..labelStr
	else
		NewTooltip = NewTooltip.."Upgrades: \255\130\130\130[0]  [0]  [0]"
	end
			
	return NewTooltip
end

-- generates weapon data string for unit
function GetTooltipWeaponData(ud, xpMod, rangeMod, dmgMod)
	local NewTooltip = ""
	
	if not rangeMod then
		rangeMod = 1
	end
	if not dmgMod then
		dmgMod = 1
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
				NewTooltip = NewTooltip.. "\n\255\100\255\255Paralyze: "..FormatNbr(paralyzeDmg,0).."/once \255\255\213\213Damage: \255\255\170\170"..FormatNbr(normalDmg,0).."/once"
	        else
	        	local normalDmg = dmgMod * weap.damages[Game.armorTypes.default]
	        	NewTooltip = NewTooltip.."\n\255\255\213\213Damage: \255\255\170\170"..FormatNbr(normalDmg,0).."/once"
	        end
	    end
    elseif ud.weapons and ud.weapons[1] and ud.weapons[1].weaponDef then
		for _,w in pairs(ud.weapons) do
			local weap=WeaponDefs[w.weaponDef]
			if weap.isShield == false and weap.description ~= "No Weapon" then
				local weapon_action="Dmg/s"
				local reloadTime = weap.reload / xpMod
				local isBeamLaser = weap.type == "BeamLaser"
				local damage = dmgMod * (weap.damages[Game.armorTypes.default] * (weap.projectiles*weap.salvoSize)) 
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
							actionStr = "Paralyze: \255\100\255\255"..FormatNbr(paralyzeDmg,0).."\255\255\255\255"..(reloadTime >= ONCE_RELOAD_THRESHOLD and " once" or ("/"..FormatNbr(reloadTime,2).."s"))
							actionStr = actionStr.." Dmg: \255\255\255\255"..FormatNbr(normalDmg,0).."\255\255\255\255"..(reloadTime >= ONCE_RELOAD_THRESHOLD and " once" or ("/"..FormatNbr(reloadTime,2).."s"))
						else
							actionStr = "Dmg/s: \255\255\255\255"..FormatNbr(damage,0).."\255\255\255\255"..(reloadTime >= ONCE_RELOAD_THRESHOLD and " once" or ("/"..FormatNbr(reloadTime,2).."s"))
						end
					else 
						if (isDisruptor) then
							local paralyzeDps = dps
							local normalDps = paralyzeDps * PARALYZE_DAMAGE_FACTOR
							actionStr = "Paralyze/s: \255\100\255\255"..FormatNbr(paralyzeDps,0).."\255\255\255\255"
							actionStr = actionStr.." Dmg/s: \255\255\255\255"..FormatNbr(normalDps,0).."\255\255\255\255"
						else
							actionStr = "Dmg/s: \255\255\255\255"..FormatNbr(dps,1).."\255\255\255\255"
						end
					end
					
					local hitpower = "L"
					
					if ( weap.damages[Game.armorTypes.default] == weap.damages[Game.armorTypes.armor_heavy] ) then
						hitpower = "H"
					elseif ( weap.damages[Game.armorTypes.default] == weap.damages[Game.armorTypes.armor_medium] ) then
						hitpower = "M"
					end
					actionStr = actionStr.."("..hitpower..")"
				end       
				NewTooltip = NewTooltip.."\n\255\255\255\255"..weap.description.."    "..actionStr.."     Range: "..FormatNbr(range,2)
			
				if energyPerSecond  > 0 then
					NewTooltip = NewTooltip.."     \255\255\255\0E"..(reloadTime >= 5 and "" or "/s")..": "..FormatNbr((reloadTime >= 5 and energyPerSecond*reloadTime or energyPerSecond),1)
				end
				
				if weap.waterWeapon then
					NewTooltip = NewTooltip.."    \255\64\64\255WATER"
				end
			end
		end
	end
    
	return NewTooltip
end
 
-- generates build power string in m/s as a function of build speed
function GetTooltipBuildPower(buildSpeed)
	
	-- time is 11 * weighted_cost_metal
	-- time = 11 * (m + e/60) / spd
	-- m + e/60 = time * spd / 11
	-- non-aircraft have 5x e cost as metal, so
	-- m + 5m/60 = time * spd / 11
	-- 13m/12 = time * spd / 11
	-- m/time = 12*spd / (11*13) 
	
	return "\255\255\255\150Build Power: ".. FormatNbr(12 * buildSpeed / (11*13),1).." metal/s"
end

-- get tooltip mass/transportability label
function GetTooltipTransportability(ud)
	if ud.speed > 0 then
		local transpStr = ""
		if ud.mass < TRANSPORT_MASS_LIMIT_LIGHT then
			transpStr = "light"
		elseif ud.mass < TRANSPORT_MASS_LIMIT_HEAVY then
			transpStr = "heavy"
		else 
			transpStr = "no transport"
		end
	
		return "     \255\200\200\200Mass: ".. FormatNbr(ud.mass,0).." ("..transpStr..")"
	else
		return ""
	end	
end
	
	
-- generates new tooltip 
function GenerateNewTooltip()
	local CurrentTooltip = Spring.GetCurrentTooltip()
 
	if tempTooltip and frameSkip > 0 then
		counter = counter +1
		if (counter % (frameSkip+1) ~= 0) then
			return tempTooltip
		end
	end
 
	local NewTooltip = ""
	local HotkeyTooltip = ""
	local FoundTooltipType = nil
	local mx,my,gx,gy,gz,id
 
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
 
        
	if spGetSelectedUnitsCount()>1 then
		NewTooltip=NewTooltip.."\255\255\255\255"..spGetSelectedUnitsCount().."\255\255\255\255 units selected\255\255\255\255\n"
	end
        
	 
	local TerrainType = string.match(CurrentTooltip,"Terrain type: (.+)\nSpeeds T/K/H/S ")
	local TerrainSpeeds = string.match(CurrentTooltip,"Speeds T/K/H/S (.+)\nHardness")
	if TerrainType~=nil then
		NewTooltip=NewTooltip.."\255\255\255\64"..TerrainType
		if TerrainSpeeds~=nil then
			TerrainSpeedList={}
			for Speed in string.gmatch(TerrainSpeeds,"[0-7]+.[0-7]+") do
				table.insert(TerrainSpeedList,Speed)
			end
			if #TerrainSpeedList>=1 then
				local DiffSpeed = false
				for _,Speeds in pairs(TerrainSpeedList) do
					if Speeds~=TerrainSpeedList[1] then
						DiffSpeed = true
					end
				end
				for i=1,#TerrainSpeedList do
					while true do
						local last = string.sub(TerrainSpeedList[i],string.len(TerrainSpeedList[i]))
						if last=="0" or last=="." then
							TerrainSpeedList[i] = string.sub(TerrainSpeedList[i],1,string.len(TerrainSpeedList[i])-1)
						end
						if last~="0" then
							break
						end
					end
				end
				if DiffSpeed then
					--NewTooltip=NewTooltip.."\nSpeeds x "..TerrainSpeeds
				else
					--NewTooltip=NewTooltip.."\nSpeed x"..TerrainSpeedList[1]
				end
			end
		end
		if gx and gz then
			--NewTooltip=NewTooltip.."\n\n("..(32)*floor((gx+16)/32)..","..(32)*floor((gz+16)/32)..")"
			NewTooltip=NewTooltip.."\n\n("..floor(gx+0.5)..","..floor(gz+0.5)..")"
			
			local h = Spring.GetGroundHeight(gx,gz)
			local airMeshH = Spring.GetSmoothMeshHeight(gx,gz)
			local _,_,_,slope = Spring.GetGroundNormal(gx,gz,true)  
			--NewTooltip=NewTooltip.."\n\nAltitude "..floor(h).."\n\nAir Mesh Altitude "..floor(airMeshH)
			NewTooltip=NewTooltip.."\n\nAltitude "..floor(h).."\n\nAir Mesh Altitude "..floor(airMeshH).."\n\nSlope "..slope
		end
		FoundTooltipType="terrain"
	end
 
	local buildpower = 1
	
	-- compute total buildpower of units selected 
	if spGetSelectedUnitsCount() >= 1 then
		for _,u in pairs(spGetSelectedUnits()) do
			local def=UnitDefs[Spring.GetUnitDefID(u)]
			buildpower = buildpower + def.buildSpeed
		end
	end   

	local unitpre = string.match(CurrentTooltip,"(.-)\nBuild:") or string.match(CurrentTooltip,"(.-)\n\255\255\255\255Build:") or ""
	local unitname = string.match(CurrentTooltip,"Build: (.+) %- ")
	local unitdesc = string.match(CurrentTooltip," %- (.+)\nHealth ")
	local unithealth = string.match(CurrentTooltip,"Health (.+)\nMetal")
	local unitbuildtime = string.match(CurrentTooltip.."\n","Build time (.-)\n")
	local unitmetalcost = string.match(CurrentTooltip,"Metal cost (.-)\nEnergy cost ")
	local unitenergycost = string.match(CurrentTooltip,"\nEnergy cost (.-).Build time ")

	if unitname and unitdesc and unithealth and unitbuildtime then
		local fud = nil
		for _,ud in pairs(UnitDefs) do
			--[[
			Spring.Echo("ud.humanName=",ud.humanName)
			Spring.Echo("ud.tooltip=",ud.tooltip)
			Spring.Echo("ud.health=",ud.health)
			Spring.Echo("ud.buildTime=",ud.buildTime)
			]]--
			if ud.humanName==unitname and ud.tooltip==unitdesc and ""..ud.health==unithealth and
				""..ud.buildTime==unitbuildtime then
				fud=ud
				break
			end
		end
		if fud then
			local armorTypeStr= "L"
			if ( Game.armorTypes[fud.armorType] == "armor_heavy" ) then armorTypeStr = "H"
			elseif ( Game.armorTypes[fud.armorType] == "armor_medium" ) then armorTypeStr = "M" end
			
			-- old build time expression : floor((29+floor(31+fud.buildTime/(buildpower/32)))/30)
			local buildTimeStr = FormatNbr(fud.buildTime/buildpower,2)
			NewTooltip = NewTooltip.."\n"..unitpre.."\n"..fud.humanName.." ("..fud.tooltip..")\n"..
				"\255\200\200\200Metal: "..unitmetalcost.."    \255\255\255\0Energy: "..unitenergycost..""..
				"\255\213\213\255".."    Build time: ".."\255\170\170\255"..
				buildTimeStr.."s".."    "..GetTooltipTransportability(fud).."\n"..
				"\255\200\200\200Health: ".."\255\200\200\200"..fud.health.."("..armorTypeStr..")"
				if fud.shieldPower > 0 then NewTooltip=NewTooltip.."\255\135\135\255     Shield: "..FormatNbr(fud.shieldPower) end
					
			-- weapons
			if fud.canKamikaze or (fud.weapons and fud.weapons[1] and fud.weapons[1].weaponDef) then
				NewTooltip = NewTooltip..GetTooltipWeaponData(fud,1)
			end
			
			-- build power
			if fud.buildSpeed and fud.buildSpeed > 0 then
				NewTooltip = NewTooltip.."\n"..GetTooltipBuildPower(fud.buildSpeed).."\255\255\255\255\n"
			end
			
			-- speed
			NewTooltip = NewTooltip.."\255\255\255\255\n"
			if fud.speed and fud.speed>0 then
				NewTooltip = NewTooltip.."\255\193\255\187Speed: \255\134\255\121"..FormatNbr(fud.speed,2).."\255\255\255\255"
			else
				-- show where buildings can be built
				if (fud.minWaterDepth > 0) then
					NewTooltip = NewTooltip.."Buildable on \255\64\64\255WATER\255\255\255\255\n"
				elseif (fud.maxWaterDepth < 100) then
					NewTooltip = NewTooltip.."Buildable on \255\200\200\200LAND\255\255\255\255\n"
				else
					NewTooltip = NewTooltip.."Buildable on \255\200\200\200LAND\255\255\255\255,\255\64\64\255WATER\255\255\255\255\n"
				end
			end
			FoundTooltipType="knownbuildbutton"
			
			if fud.windGenerator > 1 then
			   	local minWindE = FormatNbr((fud.windGenerator/25)*Game.windMin,0)
				local maxWindE = FormatNbr((fud.windGenerator/25)*Game.windMax,0)
				NewTooltip = NewTooltip.."Generates \255\255\255\0"..minWindE.."-"..maxWindE.." E/s\255\255\255\255 (up to +20% on higher ground) \n"
			elseif fud.tidalGenerator == 1 then
				NewTooltip = NewTooltip.."Generates \255\255\255\0"..Game.tidal.." E/s\255\255\255\255\n"
			end
			
			if fud.customParams.tip then
				NewTooltip = NewTooltip.."\n\255\180\180\180"..fud.customParams.tip.."\255\255\255\255\n"
			end
		else
			local buildTimeStr = FormatNbr(ud.buildTime/buildpower,2)
		    NewTooltip = NewTooltip.."\n"..unitpre.."\n"..unitname.." ("..unitdesc..")\n"..
		            "\255\255\213\213Health: ".."\255\255\170\170"..unithealth..
		            "\n\255\213\213\255Build time: ".."\255\170\170\255"..
		            buildTimeStr.."s"..
		            "\255\255\255\255\n"
		    FoundTooltipType="unknownbuildbutton"
		end
	end
 
	local isItLiveUnitTooltip = string.match(CurrentTooltip,"Experience (.+) Cost ")
	if isItLiveUnitTooltip or CurrentTooltip=="" then

		-- id being calculated way above
		if not id and spGetSelectedUnitsCount()>=1 then
			id = spGetSelectedUnits()[spGetSelectedUnitsCount()]
		end
                
		-- many units
		if id and spGetSelectedUnitsCount()>1 then
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
			NewTooltip = NewTooltip.."\255\200\200\200Metal: "..totalMetalCost.."    \255\255\255\0Energy: "..totalEnergyCost.."\n"
			
			-- health totals					
			NewTooltip = NewTooltip.."\255\200\200\200Health: ".."\255\200\200\200"..floor(totalHealth).."\255\200\200\200/\255\200\200\200"..floor(totalMaxHealth)
			if anyShield then NewTooltip=NewTooltip.."\255\135\135\255      Shield: "..FormatNbr(math.min(totalShieldPower,totalMaxShieldPower)).."/"..FormatNbr(totalMaxShieldPower) end
			
			-- energy and metal upkeep totals
			if true then
				NewTooltip = NewTooltip.."\n\255\200\200\200Metal: \255\0\255\0+"..FormatNbr(totalMetalMake,1).."\255\255\255\255/\255\255\0\0"..FormatNbr(-totalMetalUse,1)
				NewTooltip = NewTooltip.."    \255\255\255\0Energy: \255\0\255\0+"..FormatNbr(totalEnergyMake,1).."\255\255\255\255/\255\255\0\0"..FormatNbr(-totalEnergyUse,1)
			end
			FoundTooltipType="liveunit"

		-- one unit
		elseif id or spGetSelectedUnitsCount()==1 then
			local u=id
			local ud=UnitDefs[Spring.GetUnitDefID(u)]
			
			local metalMake,metalUse,energyMake,energyUse = Spring.GetUnitResources(u)
			local isFriendly = metalMake ~= nil       -- assume only friendly units have this info
			local teamID = spGetUnitTeam(id) 
			
			-- build progress, health and shield
			local health,maxHealth,paralyzeDamage,captureProgress,buildProgress = Spring.GetUnitHealth(u)
			stunned_or_beingbuilt, stunned, beingbuilt = Spring.GetUnitIsStunned(u)
			NewTooltip = NewTooltip.."\n"..ud.humanName.." ("..ud.tooltip..")"
			-- owner
			local r,g,b = spGetTeamColor(teamID)
			r,g,b,_ = convertColor(r,g,b,0)
			NewTooltip = NewTooltip.." \255"..string.char(floor(255*r))..string.char(floor(255*g))..string.char(floor(255*b))..nameByTeamID[teamID]
			
			local hpMod = spGetUnitRulesParam(u,"upgrade_hp")
			if not hpMod then
				hpMod = 1
			else
				hpMod = 1 + hpMod
			end
			health = health * hpMod
			maxHealth = maxHealth * hpMod
			-- experience
			local xp = spGetUnitExperience(u)
			local xpMod = 1
			if xp and xp>0 then
				local xpIndex = min(10,max(floor(11*xp/(xp+1)),0))+1
				xpMod = 1+0.35*(xp/(xp+1))
				if(xpIndex > 1) then
					NewTooltip = NewTooltip.."\255\255\255\255    Experience: "..xpArr[xpIndex]
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
				NewTooltip = NewTooltip.."\255\194\173\255   PARALYZED"
			end
			-- cloaking
			if spGetUnitIsCloaked(u) then
				NewTooltip = NewTooltip.."\255\170\170\170   CLOAKED"
			end        
			-- alliance
			if isFriendly == false then
				NewTooltip = NewTooltip.."    \255\255\0\0ENEMY"	
			end

			NewTooltip = NewTooltip.."\n"
			if buildProgress and buildProgress<1 then
				NewTooltip = NewTooltip.."\255\213\213\255".."Build progress: ".."\255\170\170\255"..FormatNbr(100*buildProgress).."%\n"
			end

			-- cost
			NewTooltip = NewTooltip.."\255\200\200\200Metal: "..ud.metalCost.."    \255\255\255\0Energy: "..ud.energyCost.."    "..GetTooltipTransportability(ud).."\n"
		
		
			local armorTypeStr= "L"
			if ( Game.armorTypes[ud.armorType] == "armor_heavy" ) then armorTypeStr = "H"
			elseif ( Game.armorTypes[ud.armorType] == "armor_medium" ) then armorTypeStr = "M" end
		
			local hasShield, ShieldPower=Spring.GetUnitShieldState(id)
			local maxShieldPower = ud.shieldPower
			if (health ~= nil) then
				NewTooltip = NewTooltip.."\255\200\200\200Health: ".."\255\200\200\200"..floor(health).."\255\200\200\200/\255\200\200\200"..floor(maxHealth).."("..armorTypeStr..")"
				if hasShield then NewTooltip=NewTooltip.."\255\135\135\255      Shield: "..FormatNbr(math.min(ShieldPower,maxShieldPower)).."/"..FormatNbr(maxShieldPower) end
			end
		    
			-- energy and metal upkeep
			if isFriendly then
				NewTooltip = NewTooltip.."    \255\200\200\200Metal: \255\0\255\0+"..FormatNbr(metalMake,1).."\255\255\255\255/\255\255\0\0"..FormatNbr(-metalUse,1)
				NewTooltip = NewTooltip.."    \255\255\255\0Energy: \255\0\255\0+"..FormatNbr(energyMake,1).."\255\255\255\255/\255\255\0\0"..FormatNbr(-energyUse,1)
				-- NewTooltip=NewTooltip.."\255\255\255\0     +E/M ratio: "..FormatNbr(energyMake / ud.metalCost,4).."\n"
			end
		
			-- weapons
			NewTooltip = NewTooltip..GetTooltipWeaponData(ud,xpMod,rangeMod,dmgMod).."\n"
		  
			-- build power
			if ud.buildSpeed and ud.buildSpeed > 0 then
				NewTooltip = NewTooltip.."\n"..GetTooltipBuildPower(ud.buildSpeed)..  "\255\255\255\255\n"
			end
                        
			-- upgrades (upgrade centers only)
			local isUpgradeCenter = string.find(ud.name, "upgrade_center")
			local teamId = spGetUnitTeam(u)
			if isUpgradeCenter then
				NewTooltip = NewTooltip..GetTooltipUpgradeData(teamId).."\n\n"
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
				NewTooltip = NewTooltip.."\255\193\255\187Speed: \255\134\255\121"..FormatNbr(speed).."\255\193\255\187/\255\134\255\121"..FormatNbr(ud.speed*speedMod,2).."\255\255\255\255      "
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
				 
				NewTooltip = NewTooltip.."\255\255\255\255Transport: "..FormatNbr(min(2,(currentCapacityUsage/ud.transportCapacity))*50,0).."% / "..FormatNbr((currentMassUsage/ud.transportMass)*100,0).."%      "
			end

			-- upgrade summary
			if not isUpgradeCenter then
				NewTooltip = NewTooltip..GetTooltipUpgradeLabel(spGetUnitTeam(u))
			end
 						
			if ud.customParams.tip then
				NewTooltip = NewTooltip.."\n\255\180\180\180"..ud.customParams.tip.."\255\255\255\255\n"
			end
 
			FoundTooltipType="liveunit"
		end
	end
 
	local hotkeys = string.match(CurrentTooltip.."\n","Hotkeys: (.-)\n")
	if hotkeys then
		HotkeyTooltip = "\n\255\255\196\128Hotkeys: ".."\255\255\128\001"..hotkeys.."\255\255\255\255"
		CurrentTooltip=string.gsub(CurrentTooltip.."\n","Hotkeys: .-\n","")
		NewTooltip=NewTooltip..HotkeyTooltip
		CurrentTooltip=CurrentTooltip..HotkeyTooltip
	end
 
	local action = string.match(CurrentTooltip,"(.-)\n")
	if action then
		action = string.match(action,"(.-): ")
		if action then
			CurrentTooltip=string.gsub(CurrentTooltip,"(.-): ","",1)
			CurrentTooltip="\255\170\255\170"..action..":\255\255\255\255 "..CurrentTooltip
		end
	end
  
	if FoundTooltipType then
		tempTooltip = NewTooltip
		return NewTooltip
	else
		tempTooltip = CurrentTooltip
		return CurrentTooltip
	end
end
 
 
local FontSize
local xTooltipSize = 0
local yTooltipSize = 0
 
function widget:DrawScreenEffects(vsx,vsy)
        WG.KP_ToolTip=nil
        if Spring.IsGUIHidden() then
                return
        end
 
        local nttString = GenerateNewTooltip()
        local nttList = {}
        local maxWidth = 0
        for line in string.gmatch(nttString,"[^\r\n]+") do
                table.insert(nttList,"\255\255\255\255"..line)
                if gl.GetTextWidth(line)>maxWidth then
                        maxWidth=gl.GetTextWidth(line)
                end
        end
 
        if not FontSize then
                FontSize = max(8,4+vsy/100)
        end
 
        xTooltipSize = FontSize*(1+maxWidth)
        yTooltipSize = FontSize*(1+#nttList)
 
        -- Bottom left position by default
        local x1,y1,x2,y2=0,0,xTooltipSize,yTooltipSize
 
        -- Note: this line is done even if the KP_ToolTip is devoid of text
        -- The only case where KP_ToolTip is nil are when the widget is off or the GUI is hidden
        WG.KP_ToolTip={x1=x1,y1=y1,x2=x2,y2=y2,xSize=xTooltipSize,ySize=yTooltipSize,FontSize=FontSize}
 
        gl.Blending(GL.SRC_ALPHA,GL.ONE_MINUS_SRC_ALPHA) -- default
        if WG.MidKnightBG then
                gl.Color(1,1,1,1)
                gl.Texture("bitmaps/tooltipbg.png")
                gl.TexRect(x1,y1,x2*1.2,y2*1.2,0.01,0.99,0.99,0.01)
                gl.Texture(false)
        else
                gl.Color(0.0,0.0,0.0,0.5)  --background
                gl.Rect(x1,y1,x2,y2)
                gl.Color(0.0,0.0,0.0,1)  --border
                gl.LineWidth(1)
                gl.Shape(GL.LINE_LOOP,{
                        {v={x1,y2}},{v={x2,y2}},
                        {v={x2,y1}},{v={x1,y1}},})
                gl.Color(1,1,1,1)
        end
        for k=1,#nttList do
                gl.Text(nttList[k],x1+FontSize/2,y1+FontSize*(#nttList+0.5-k),FontSize,'o')
        end
        gl.Text("\255\255\255\255 ",0,0,FontSize,'o') -- Reset color to white for other widgets using gl.Text
end
 
 
--function widget:MouseWheel(up,value)
--        local xMouse,yMouse = GetMouseState()
--        if xMouse < xTooltipSize and yMouse < yTooltipSize and not Spring.IsGUIHidden() then
--                if up then
--                        FontSize = max(FontSize - 1,2)
--                else
--                        FontSize = FontSize + 1
--                end
--                return true
--        end
--        return false
--end