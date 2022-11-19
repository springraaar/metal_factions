function gadget:GetInfo()
   return {
      name = "Upgrade Handler",
      desc = "Handles upgrades.",
      author = "raaar",
      date = "March, 2016",
      license = "PD.",
      layer = 0,
      enabled = true,
   }
end

-- upgrade types
local TYPE_MINOR = 1
local TYPE_COMMANDER = 2
local TYPE_MAJOR = 3

-- upgrade limits by type
local limitsByType = {
	[TYPE_MINOR] = 5,
	[TYPE_COMMANDER] = 3,
	[TYPE_MAJOR] = 1
}

-- colors, for tooltip strings
local COLOR_RED = "\255\255\100\100"
local COLOR_GREEN = "\255\180\255\180"
local COLOR_BLUE = "\255\180\180\255" 
local COLOR_DEFAULT = "\255\255\255\255" 
local COLOR_DARK = "\255\130\130\130"

local modifierTypes = {"damage","range","hp","speed","regen","php_regen","light_drones","medium_drone","stealth_drone","builder_drone","transport_drone","jump"}

local modifiersByUpgrade = {
-- weapon / red
	
	upgrade_red_1_damage = { damage = 0.07, speed = -0.01, restrictions = "armed", limit = 3, type = TYPE_MINOR },
	upgrade_red_1_range = { range = 0.035, speed = -0.02, restrictions = "armed", limit = 3, type = TYPE_MINOR },

	upgrade_red_2_commander_damage = { damage = 0.22, restrictions = "commander", limit = 2, type = TYPE_COMMANDER },
	upgrade_red_2_commander_range = { range = 0.1, restrictions = "commander", limit = 1, type = TYPE_COMMANDER },
	
	upgrade_red_3_damage = { damage = 0.13, restrictions = "armed", limit = 1, type = TYPE_MAJOR },

-- armor / green

	upgrade_green_1_hp = { hp = 0.06, speed = -0.01, limit = 3, type = TYPE_MINOR },
	upgrade_green_1_regen = { regen = 1, php_regen = 0.001, limit = 3, type = TYPE_MINOR },

	upgrade_green_2_commander_regen = { regen = 8, php_regen = 0.003, restrictions = "commander", limit = 3, type = TYPE_COMMANDER },
	upgrade_green_2_commander_hp = { hp = 0.17, restrictions = "commander", limit = 2, type = TYPE_COMMANDER },

	upgrade_green_3_regen = { regen = 3, php_regen = 0.002, limit = 1, type = TYPE_MAJOR },
	upgrade_green_3_hp = { hp=0.12, limit = 1, type = TYPE_MAJOR },

-- utility / blue

	upgrade_blue_1_speed = { speed = 0.05, limit = 3, type = TYPE_MINOR },
	
	upgrade_blue_2_commander_speed = { speed = 0.14, restrictions = "commander", limit = 2, type = TYPE_COMMANDER },
	upgrade_blue_2_commander_light_drones = { light_drones = 1, restrictions = "commander", limit = 3, type = TYPE_COMMANDER },	

	upgrade_blue_3_commander_stealth_drone = { stealth_drone = 1, restrictions = "commander", limit = 3, type = TYPE_COMMANDER },
	upgrade_blue_3_commander_builder_drone = { builder_drone = 1, restrictions = "commander", limit = 3, type = TYPE_COMMANDER },
	upgrade_blue_3_commander_medium_drone = { medium_drone = 1, restrictions = "commander", limit = 3, type = TYPE_COMMANDER },
	upgrade_blue_3_commander_transport_drone = { transport_drone = 1, restrictions = "commander", limit = 3, type = TYPE_COMMANDER },
	
	upgrade_blue_3_commander_jump = { jump = 1, restrictions = "commander", limit = 3, type = TYPE_COMMANDER },
	
	upgrade_blue_3_speed = { speed=0.11, limit = 1, type = TYPE_MAJOR }
}


local upgradesByPlayerId = {}
GG.resetUpgrades = false
GG.upgradeCountsByTypeAndPlayerId = {}
local upgradeBuildOrdersByPlayerId = {}
local modifiersByPlayerId = {}
local modifiersByUnitId = {}
local processedUpgradeIds = {}


local UPGRADE_ORDER_CLEANUP_DELAY_FRAMES = 100

local spGetTeamUnits = Spring.GetTeamUnits 
local spGetUnitDefId = Spring.GetUnitDefID
local spGetGameFrame = Spring.GetGameFrame
local spSetUnitRulesParam = Spring.SetUnitRulesParam
local spSetTeamRulesParam = Spring.SetTeamRulesParam
local spGetTeamList = Spring.GetTeamList
local spSendMessageToTeam = Spring.SendMessageToTeam
local spSetUnitWeaponState = Spring.SetUnitWeaponState
local spGetTeamInfo = Spring.GetTeamInfo
local spGetUnitHealth = Spring.GetUnitHealth
local spSetUnitWeaponDamages = Spring.SetUnitWeaponDamages

local min = math.min
local floor = math.floor
local ceil = math.ceil
local modf = math.modf
local fmod = math.fmod


local builtinDroneUpgrades = {
	[UnitDefNames["gear_adv_construction_kbot"].id] = "upgrade_transport_drone",
	[UnitDefNames["gear_adv_construction_hydrobot"].id] = "upgrade_transport_drone"
}

local noUpgradeUnitDefIds = {
	[UnitDefNames["cs_beacon"].id] = true,
	[UnitDefNames["scoper_beacon"].id] = true
}

-- checks if unit is an upgrade module
function isUpgrade(unitDefId)
	if (UnitDefs[unitDefId].customParams.isupgrade) then
		return true
	end
	return false
end

-- format number
-- this is here because on the tooltip string generation for the widget
-- TODO put this on a lib
function formatNbr(x,digits)
	if x then
		local _,fractional = modf(x)
		if fractional==0 then
			return x
		elseif fractional<0.01 then
			return floor(x)
		elseif fractional>0.99 then
			return ceil(x)
		else
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
		end
	end
end

-- update player modifiers
function updatePlayerModifiers(teamId)
	
	-- clear previous modifiers
	modifiersByPlayerId[teamId] = {}
	playerMods = { commander = {}, armed = {}, other = {}}
	
	local commanderMods = {} 
	local armedMods = {}
	local otherMods = {}
	
	-- load mod data
	for upName,amount in pairs(upgradesByPlayerId[teamId]) do
		local modifiers = modifiersByUpgrade[upName]
		local commanderOnly = modifiers.restrictions == "commander"
		local armedOnly = modifiers.restrictions == "armed"  
		
		for modName,value in pairs(modifiers) do
			if modName ~= "restrictions" and modName ~= "limit" and modName ~= "type" then
				if not commanderMods[modName] then
					commanderMods[modName] = 0
				end
				commanderMods[modName] = commanderMods[modName] + value * amount
				if (not commanderOnly) then
					if not armedMods[modName] then
						armedMods[modName] = 0
					end
					armedMods[modName] = armedMods[modName] + value * amount
					if (not armedOnly) then
						if not otherMods[modName] then
							otherMods[modName] = 0
						end					
						otherMods[modName] = otherMods[modName] + value * amount
					end
				end
			end
		end
	end
	
	playerMods.commander = commanderMods
	playerMods.armed = armedMods
	playerMods.other = otherMods
	
	-- set global upgrade data strings for player (for tooltip)
	local minorCount = 0
	local commanderCount = 0
	local majorCount = 0
	local redCount = 0
	local greenCount = 0
	local blueCount = 0
	local playerUpgradesList = ""
	local playerUpgradesModifiers = ""

	-- modifiers
	for type,mods in pairs(playerMods) do
		playerUpgradesModifiers = playerUpgradesModifiers..type..": " 
		
		local count = 0
		local modStr = nil
		for modName,modValue in pairs(mods) do
			if count > 0 then
				playerUpgradesModifiers = playerUpgradesModifiers..", "
				if count%8 == 0 then
					playerUpgradesModifiers = playerUpgradesModifiers.."\n"
				end
			end

			modStr = ""
			if (modName == "damage") then
				modStr = COLOR_RED.."damage +"..formatNbr(modValue*100,0).."%"
			elseif (modName == "range") then
				modStr = COLOR_RED.."range +"..formatNbr(modValue*100,1).."%"
			elseif (modName == "speed") then
				modStr = (modValue > 0 and COLOR_BLUE or "").."speed "..(modValue > 0 and "+" or "")..formatNbr(modValue*100,0).."%"
			elseif (modName == "hp") then
				modStr = COLOR_GREEN.."hp "..(modValue > 0 and "+" or "")..formatNbr(modValue*100,0).."%"
			elseif (modName == "regen") then
				modStr = COLOR_GREEN.."regen "..formatNbr(modValue,0).." HP/s"
			elseif (modName == "php_regen") then
				modStr = COLOR_GREEN.."regen "..formatNbr(modValue*100,1).."% HP/s"
			elseif (modName == "light_drones") then
				modStr = COLOR_BLUE.."light drones"
			elseif (modName == "builder_drone") then
				modStr = COLOR_BLUE.."builder drone"
			elseif (modName == "medium_drone") then
				modStr = COLOR_BLUE.."medium drone"
			elseif (modName == "stealth_drone") then
				modStr = COLOR_BLUE.."stealth drone"
			elseif (modName == "transport_drone") then
				modStr = COLOR_BLUE.."transport drone"				
			elseif (modName == "jump") then
				modStr = COLOR_BLUE.."jump thrusters"				
			else
				modStr = modName
			end
	
			playerUpgradesModifiers = playerUpgradesModifiers .. modStr..COLOR_DEFAULT
			
			count = count + 1
		end	
		playerUpgradesModifiers = playerUpgradesModifiers .."\n"
	end
	
	local colorStr = ""
	-- upgrades
	local count = 0
	for upName,amount in pairs(upgradesByPlayerId[teamId]) do
		if count > 0 then
			playerUpgradesList = playerUpgradesList..", "
			if count%4 == 0 then
				playerUpgradesList = playerUpgradesList.."\n"
			end
		end
		local modifiers = modifiersByUpgrade[upName]
		
		if modifiers.type == TYPE_MINOR then
			minorCount = minorCount + amount 
		elseif modifiers.type == TYPE_COMMANDER then
			commanderCount = commanderCount + amount
		elseif modifiers.type == TYPE_MAJOR then
			majorCount = majorCount + amount 
		end
		
		colorStr = COLOR_RED
		if string.find(upName, "green") then
			colorStr = COLOR_GREEN
			greenCount = greenCount + amount
		elseif string.find(upName, "blue") then
			colorStr = COLOR_BLUE
			blueCount = blueCount + amount
		else
			redCount = redCount + amount
		end
		
		playerUpgradesList = playerUpgradesList..colorStr..UnitDefNames[upName].humanName..(amount > 1 and ("(x"..amount..")") or "")..COLOR_DEFAULT
		
		count = count + 1
	end

	GG.upgradeCountsByTypeAndPlayerId[teamId] = { [TYPE_MINOR] = minorCount, [TYPE_COMMANDER] = commanderCount, [TYPE_MAJOR] = majorCount }
	local playerUpgradesStr = "UPGRADES        minor: "..minorCount.."/"..limitsByType[TYPE_MINOR].."       commander: "..commanderCount.."/"..limitsByType[TYPE_COMMANDER].."      major: "..majorCount.."/"..limitsByType[TYPE_MAJOR]
	local playerUpgradesLabelStr = "Upgrades: "..(redCount > 0 and COLOR_RED or COLOR_DARK).." ["..redCount.."]"..(greenCount > 0 and COLOR_GREEN or COLOR_DARK).."  ["..greenCount.."]"..(blueCount > 0 and COLOR_BLUE or COLOR_DARK).."  ["..blueCount.."]"..COLOR_DEFAULT

	-- player upgrade status
	spSetTeamRulesParam(teamId,"upgrade_label", playerUpgradesLabelStr,{public = true})
	spSetTeamRulesParam(teamId,"upgrade_status", playerUpgradesStr,{public = true})
	spSetTeamRulesParam(teamId,"upgrade_list",playerUpgradesList,{public = true})
	spSetTeamRulesParam(teamId,"upgrade_modifiers",playerUpgradesModifiers,{public = true})
	-- for AI
	spSetTeamRulesParam(teamId,"upgrade_allowed_minor", (limitsByType[TYPE_MINOR]-minorCount),{public = true})
	spSetTeamRulesParam(teamId,"upgrade_allowed_commander", (limitsByType[TYPE_COMMANDER]-commanderCount),{public = true})
	spSetTeamRulesParam(teamId,"upgrade_allowed_major", (limitsByType[TYPE_MAJOR]-majorCount),{public = true})
	
	modifiersByPlayerId[teamId] = playerMods
end


-- update unit modifiers
function updateUnitModifiers(unitId, unitDefId, teamId)
	local ud = UnitDefs[unitDefId]
	local unitMods = nil
	local oldUnitMods = modifiersByUnitId[unitId]
	
	-- check what type of unit it is and get the corresponding modifier list
	if ud.customParams.iscommander then
		unitMods = modifiersByPlayerId[teamId].commander
	else
		local hasWeapons = false
		local weap = nil
		if ud.weapons and ud.weapons[1] and ud.weapons[1].weaponDef then
			for _,w in pairs(ud.weapons) do
				weap=WeaponDefs[w.weaponDef]
				if weap.isShield == false and weap.description ~= "No Weapon" then
					hasWeapons = true
				end
			end
		end
		
		if hasWeapons then
			unitMods = modifiersByPlayerId[teamId].armed
		else
			unitMods = modifiersByPlayerId[teamId].other
		end
	end
	
	modifiersByUnitId[unitId] = unitMods
	
	-- keep drone upgrades set for some units
	--if builtinDroneUpgrades[unitDefId] then
	--	modifiersByUnitId[unitId][builtinDroneUpgrades[unitDefId]] = 1
	--end	

	-- clear existing modifiers
	for _,modName in pairs(modifierTypes) do
		spSetUnitRulesParam(unitId,"upgrade_"..modName,0,{public = true})
	end	
	if GG.speedModifierUnitIds then 
		GG.speedModifierUnitIds[unitId] = nil
	end
	
	if unitMods then
		local hasRange = false
		local hasDamage = false
		-- set unit rules parameters for use by other gadgets
		for modName,modValue in pairs(unitMods) do
			spSetUnitRulesParam(unitId,"upgrade_"..modName,modValue,{public = true})
			
			if (modName == "range") then
				hasRange = true
				updateUnitWeaponRange(unitId, modValue)
			elseif (modName == "damage") then
				hasDamage = true
				updateUnitWeaponDamage(unitId, modValue)
			end
		end
		
		if ( not hasRange ) then
			updateUnitWeaponRange(unitId, 0)
		end
		if (not hasDamage) then
			updateUnitWeaponDamage(unitId, 0)
		end 
	end
	
	-- keep drone upgrades set for some units
	if builtinDroneUpgrades[unitDefId] then
		spSetUnitRulesParam(unitId, builtinDroneUpgrades[unitDefId],1,{public = true})
	end
end

-- applies weapon range modifier on unit
function updateUnitWeaponRange(unitId, modifier)
	local unitDefId = spGetUnitDefId(unitId)
	if (unitDefId ~= nil) then
		local ud = UnitDefs[unitDefId]

		-- update range for all non-shield weapons, if any
		if ud.weapons and ud.weapons[1] and ud.weapons[1].weaponDef then
			for wNum,w in pairs(ud.weapons) do
				local weap=WeaponDefs[w.weaponDef]
			    if weap.isShield == false and weap.description ~= "No Weapon" then
	                local range = weap.range * (1 + modifier)
	
					spSetUnitWeaponState(unitId,wNum,"range",range)
					spSetUnitWeaponDamages(unitId,wNum,"dynDamageRange",range)
					--Spring.Echo("range changed to "..range)
			    end
			end
	    end
	end
end
-- applies weapon damage modifier on unit
function updateUnitWeaponDamage(unitId, modifier)
	local unitDefId = spGetUnitDefId(unitId)
	if (unitDefId ~= nil) then
		local ud = UnitDefs[unitDefId]

		-- update damage for all non-shield weapons, if any
		if ud.weapons and ud.weapons[1] and ud.weapons[1].weaponDef then
			for wNum,w in pairs(ud.weapons) do
				local wd=WeaponDefs[w.weaponDef]
			    if wd.isShield == false and wd.description ~= "No Weapon" then
					for aNum,aType in pairs (Game.armorTypes) do
						local originalDamage = wd.damages[aNum] or wd.damages[0]
						--Spring.Echo(ud.name.." W"..wNum.." vs "..aType.." dmg="..originalDamage*(1+modifier))
						
						spSetUnitWeaponDamages(unitId,wNum,aNum,originalDamage*(1+modifier))	
					end
			    end
			end
	    end
	    
	    -- if unit has offensive explosion, boost its damage as well
	    if ud.customParams and ud.customParams.offensiveexplosion == "1" then
	    	local selfDName = ud.selfDExplosion
	    	local deathName = ud.deathExplosion
	    	local selfDWD = WeaponDefNames[selfDName]
	    	local deathWD = WeaponDefNames[deathName]
	    	local originalDamage = 0
	    	for aNum,aType in pairs (Game.armorTypes) do
	    		originalDamage = selfDWD.damages[aNum] or selfDWD.damages[0]
	    		spSetUnitWeaponDamages(unitId,"selfDestruct",aNum,originalDamage*(1+modifier))
				--Spring.Echo(ud.name.." selfD vs "..aType.." dmg="..originalDamage*(1+modifier))
	    		originalDamage = deathWD.damages[aNum] or deathWD.damages[0]
	    		spSetUnitWeaponDamages(unitId,"explode",aNum,originalDamage*(1+modifier))
	    		--Spring.Echo(ud.name.." death vs "..aType.." dmg="..originalDamage*(1+modifier))
	    	end
	    end
	end
end

-- check if a given upgrade can be built by player
-- returns false if not available or the smallest number of buildable upgrades
-- if beingBuilt
function checkLimit(name, teamId, ignoreBeingBuilt)
	local limit = modifiersByUpgrade[name].limit or 1
	local type = modifiersByUpgrade[name].type
	local beingBuilt = 0
	local typeBeingBuilt = 0
	local ud = nil
	if (not ignoreBeingBuilt) then
		for _,uId in ipairs(spGetTeamUnits(teamId)) do
			ud = UnitDefs[spGetUnitDefId(uId)]
			
			local health,maxHealth,_,_,bp = spGetUnitHealth(uId)
			
			-- if it's finished but unitfinished has not yet triggered, trigger it
			-- else increment current being-built counters
			if (bp and bp > 0.99) then
				gadget:UnitFinished(uId, ud.id, teamId)
			else
				if (ud.name == name) then
					beingBuilt = beingBuilt + 1
					typeBeingBuilt = typeBeingBuilt + 1
				elseif (isUpgrade(ud.id) and modifiersByUpgrade[ud.name].type == type) then
					typeBeingBuilt = typeBeingBuilt + 1
				end
			end
		end
	end
	-- check for limit by type
	local typeCount = GG.upgradeCountsByTypeAndPlayerId[teamId][type]
	local typeLimit = limitsByType[type]
	
	--local orders = upgradeBuildOrdersByPlayerId[teamId][name] or 0 
	--local typeOrders = upgradeBuildOrdersByTypePlayerId[teamId][type] or 0
	local orders = 0
	local typeOrders = 0
	local upgrades = upgradesByPlayerId[teamId][name] or 0
	if (orders + beingBuilt + upgrades < limit) and (typeOrders + typeBeingBuilt + typeCount < typeLimit) then
		return math.min(limit - (orders + beingBuilt + upgrades),typeLimit - (typeOrders + typeBeingBuilt + typeCount))
	end
	
	
	local _,_,_,isAI,_,_ = spGetTeamInfo(teamId)
	if (not isAI) then
		--spSendMessageToTeam( teamId, "\""..UnitDefNames[name].humanName.."\" : own limit or type limit reached : construction aborted : orders="..orders.." beingbuilt="..beingBuilt.." upgrades="..upgrades.." limit="..limit.." typeorders="..typeOrders.." typeBeingBuilt="..typeBeingBuilt.." typecount="..typeCount.." typelimit="..typeLimit)
		spSendMessageToTeam( teamId, "\""..UnitDefNames[name].humanName.."\" : own limit or type limit reached : upgrade construction aborted")
	end
	if (ignoreBeingBuilt) then
		return 0
	end
	return false
end

-- reset upgrades for all teams and units
function resetUpgrades()
	local teamList = spGetTeamList()

	for i=1,#teamList do
		local teamId = teamList[i]
		
		upgradesByPlayerId[teamId] = {}
		GG.upgradeCountsByTypeAndPlayerId[teamId] = { [TYPE_MINOR] = 0, [TYPE_COMMANDER] = 0, [TYPE_MAJOR] = 0 }
		upgradeBuildOrdersByPlayerId[teamId] = {}
		modifiersByPlayerId[teamId] = {}
		
		-- player upgrade status string, for tooltip
		local playerUpgradesStr = "UPGRADES        minor: 0/"..limitsByType[TYPE_MINOR].."       commander: 0/"..limitsByType[TYPE_COMMANDER].."      major: 0/"..limitsByType[TYPE_MAJOR]
		spSetTeamRulesParam(teamId,"upgrade_status", playerUpgradesStr,{public = true})
		
		updatePlayerModifiers(teamId)
		
		-- reset upgrades for the units as well
		local ud = nil
		for _,uId in ipairs(spGetTeamUnits(teamId)) do
			ud = UnitDefs[spGetUnitDefId(uId)]
			--Spring.Echo("updating upgrades for unit "..uId.."/"..ud.name)			
			updateUnitModifiers(uId, ud.id, teamId)
		end
	end
end


-------------------------- SYNCED CODE ONLY
if (not gadgetHandler:IsSyncedCode()) then
	return false
end

function gadget:Initialize()
	resetUpgrades()
end

function gadget:UnitCreated(unitId, unitDefId, teamId)
	if (noUpgradeUnitDefIds[unitDefId]) then
		return
	end
	
	local name = UnitDefs[unitDefId].name
	local n = 0

	-- apply modifiers
	if not isUpgrade(unitDefId) then
		updateUnitModifiers(unitId, unitDefId, teamId)
	else
		if (not upgradeBuildOrdersByPlayerId[teamId][name]) then
			upgradeBuildOrdersByPlayerId[teamId][name] = {}
		end
		upgradeBuildOrdersByPlayerId[teamId][name][unitId] = true
		
		--Spring.Echo(name.." created at frame "..Spring.GetGameFrame())
	end
end

-- apply upgrade when finished
function gadget:UnitFinished(unitId, unitDefId, teamId)
	if isUpgrade(unitDefId) then
		if not processedUpgradeIds[unitId] then
			-- Spring.Echo("upgrade finished for team "..teamId.." value="..UnitDefs[unitDefId].name)
			local name = UnitDefs[unitDefId].name
			
			-- destroy token
			Spring.DestroyUnit(unitId)
			
			-- update modifiers for team
			if not upgradesByPlayerId[teamId][name] then
				upgradesByPlayerId[teamId][name] = 0
			end
			upgradesByPlayerId[teamId][name] = upgradesByPlayerId[teamId][name] + 1
			updatePlayerModifiers(teamId)
			
			-- apply modifiers for all units in team
			local ud = nil
			for _,uId in ipairs(spGetTeamUnits(teamId)) do
				ud = UnitDefs[spGetUnitDefId(uId)]
				updateUnitModifiers(uId, ud.id, teamId)
			end
			
			processedUpgradeIds[unitId] = true
		end
	end
end

-- blocks upgrade transfers between players
function gadget:AllowUnitTransfer(unitId, unitDefId, oldTeam, newTeam, capture)
	if( isUpgrade(unitDefId)) then
 		Spring.Echo("upgrades can't be given!")
 		return false
	end  
	return true
end



-- blocks construction of multiple upgrades of the same type for the same team
function gadget:AllowUnitCreation(unitDefId,builderId,teamId,x,y,z)
	
	-- check if upgrade is within limits 
	if (isUpgrade(unitDefId)) then
		local name = UnitDefs[unitDefId].name
		if (not checkLimit(name, teamId)) then
			return false
		end
	end
	
	return true
end


-- cleanup
function gadget:UnitDestroyed(unitId, unitDefId, teamId)
	if isUpgrade(unitDefId) then
		local name = UnitDefs[unitDefId].name
		
		if (upgradeBuildOrdersByPlayerId[teamId]) then
			local beingBuilt = upgradeBuildOrdersByPlayerId[teamId][name]
			if beingBuilt and beingBuilt[unitId] then
				beingBuilt[unitId] = nil
			end
		end
	end
end


-- clean up excess upgrade build orders
function gadget:GameFrame(n)
	-- check upgrade reset token
	if GG.resetUpgrades then
		resetUpgrades()
		GG.resetUpgrades = false
	end
	
	for _,teamId in pairs (spGetTeamList()) do
		local countByType = {}
		for name,beingBuilt in pairs(upgradeBuildOrdersByPlayerId[teamId]) do
			if beingBuilt and next(beingBuilt) ~= nil then
				local type = modifiersByUpgrade[name].type
				local typeLimit = limitsByType[type]
				if (not countByType[type]) then
					countByType[type] = GG.upgradeCountsByTypeAndPlayerId[teamId][type]
				end
				local allowed = checkLimit(name, teamId,true)

				-- let upgrades be built until the limit is reached
				-- make the rest disappear
				for uId,_ in pairs(beingBuilt) do
					if (allowed > 0 and countByType[type] < typeLimit ) then
						allowed = allowed - 1
						countByType[type] = countByType[type] + 1
					else
						Spring.DestroyUnit(uId,false,true)
						--Spring.Echo("removed "..uId.." / "..name)
						-- table is cleared on unitdestroyed
					end
				end
			end
		end
	end
end


