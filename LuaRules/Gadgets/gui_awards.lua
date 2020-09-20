function gadget:GetInfo()
  return {
    name      = "Awards",
    desc      = "Processes game information and shows awards when it ends",
    author    = "raaar, based on BA gadget by Bluestone",
    date      = "Apr 2017",
    license   = "GPLv2",
    layer     = 10, 
    enabled   = true
  }
end


local IMG_PATH = "LuaRules/Images/awards/"
local AWARD_OFFSET = 550
local AWARD_ECODMG = AWARD_OFFSET+1
local AWARD_DMG = AWARD_OFFSET+2
local AWARD_EFF = AWARD_OFFSET+3
local AWARD_COM = AWARD_OFFSET+4
local AWARD_DMGREC = AWARD_OFFSET+5
local AWARD_SLEEP = AWARD_OFFSET+6

local AWARD_TEXT = {
	[AWARD_ECODMG] = 'RAIDER : Destroying enemy resource production',
	[AWARD_DMG] = 'DESTROYER : Destroying enemy units',
	[AWARD_EFF] = 'EFFICIENCY : Killed value / Lost value',
	[AWARD_COM] = 'COMMANDER : Fighting with Commander'
}

local AWARD_OTHERS = AWARD_OFFSET+7

local COMMANDER_XP_AWARD_THRESHOLD = 0.3 -- about II on the converted scale
local EFFICIENCY_AWARD_THRESHOLD = 1.0

-------------------------------------------------- SYNCED CODE
if (gadgetHandler:IsSyncedCode()) then 

local SpAreTeamsAllied = Spring.AreTeamsAllied

local teamInfo = {}
local coopInfo = {}
local present = {}

local econUnitDefIDs = {
	--------- AVEN
	[UnitDefNames["aven_solar_collector"].id] = true,
	[UnitDefNames["aven_wind_generator"].id] = true,
	[UnitDefNames["aven_tidal_generator"].id] = true,
	[UnitDefNames["aven_metal_extractor"].id] = true,
	[UnitDefNames["aven_moho_mine"].id] = true,
	[UnitDefNames["aven_exploiter"].id] = true,
	[UnitDefNames["aven_fusion_reactor"].id] = true,
	[UnitDefNames["aven_mobile_fusion"].id] = true,
	[UnitDefNames["aven_geothermal_powerplant"].id] = true,
	[UnitDefNames["aven_energy_storage"].id] = true,
	[UnitDefNames["aven_metal_storage"].id] = true,
	
	--------- GEAR
	[UnitDefNames["gear_solar_collector"].id] = true,
	[UnitDefNames["gear_wind_generator"].id] = true,
	[UnitDefNames["gear_tidal_generator"].id] = true,
	[UnitDefNames["gear_metal_extractor"].id] = true,
	[UnitDefNames["gear_moho_mine"].id] = true,
	[UnitDefNames["gear_exploiter"].id] = true,
	[UnitDefNames["gear_fusion_power_plant"].id] = true,
	[UnitDefNames["gear_geothermal_powerplant"].id] = true,
	[UnitDefNames["gear_energy_storage"].id] = true,
	[UnitDefNames["gear_metal_storage"].id] = true,
	
	--------- CLAW	
	[UnitDefNames["claw_solar_collector"].id] = true,
	[UnitDefNames["claw_wind_generator"].id] = true,
	[UnitDefNames["claw_tidal_generator"].id] = true,
	[UnitDefNames["claw_adv_fusion_reactor"].id] = true,
	[UnitDefNames["claw_metal_extractor"].id] = true,
	[UnitDefNames["claw_moho_mine"].id] = true,
	[UnitDefNames["claw_exploiter"].id] = true,
	[UnitDefNames["claw_geothermal_powerplant"].id] = true,
	[UnitDefNames["claw_energy_storage"].id] = true,
	[UnitDefNames["claw_metal_storage"].id] = true,
	
	--------- SPHERE
	[UnitDefNames["sphere_tidal_generator"].id] = true,
	[UnitDefNames["sphere_fusion_reactor"].id] = true,
	[UnitDefNames["sphere_adv_fusion_reactor"].id] = true,
	[UnitDefNames["sphere_metal_extractor"].id] = true,
	[UnitDefNames["sphere_moho_mine"].id] = true,
	[UnitDefNames["sphere_exploiter"].id] = true,
	[UnitDefNames["sphere_geothermal_powerplant"].id] = true,
	[UnitDefNames["sphere_energy_storage"].id] = true,
	[UnitDefNames["sphere_metal_storage"].id] = true
}

-- checks if unit is an economy unit
function isEcon(unitDefID) 
	if econUnitDefIDs[unitDefID] == true then
		return true
	end
	return false
end

-- checks if unit is a commander
function isCommander(unitDefId)
	if (UnitDefs[unitDefId].customParams.iscommander) then
		return true
	end
	return false
end

-- get weighted cost in equivalent metal units 
function getWeightedCost(metal, energy)
	return metal + energy / 60
end


function gadget:GameStart()
	--make table of teams eligible for awards
	local allyTeamIDs = Spring.GetAllyTeamList()
	local gaiaTeamID = Spring.GetGaiaTeamID()
	for i=1,#allyTeamIDs do
		local teamIDs = Spring.GetTeamList(allyTeamIDs[i])
		for j=1,#teamIDs do
			local _,_,_,isAiTeam = Spring.GetTeamInfo(teamIDs[j])
			local isLuaAI = (Spring.GetTeamLuaAI(teamIDs[j]) ~= "")
			local isGaiaTeam = (teamIDs[j] == gaiaTeamID)
			--TODO Exclude AIs?
			--if ((not isAiTeam) and (not isLuaAi) and (not isGaiaTeam)) then
			if ((not isGaiaTeam)) then
				local playerIDs = Spring.GetPlayerList(teamIDs[j])
				local numPlayers = 0
				for _,playerID in pairs(playerIDs) do
					local _,_,isSpec = Spring.GetPlayerInfo(playerID) 
					if not isSpec then 
						numPlayers = numPlayers + 1
					end
				end
				if isLuaAI then
					numPlayers = 1
				end
				--Spring.Echo("team ".. teamIDs[j] .." is lua AI="..tostring(isLuaAI).." and has "..tostring(numPlayers).." players")
				
				if numPlayers > 0 then
					present[teamIDs[j]] = true
					teamInfo[teamIDs[j]] = {ecoKillValue=0, killValue=0, lossValue=0, otherDmg=0, dmgDealt=0, ecoUsed=0, dmgRatio=0, ecoProd=0, lastKill=0, dmgRec=0, sleepTime=0, unitsCost=0, comXP=0, present=true,}
					coopInfo[teamIDs[j]] = {players=numPlayers,}
				else
					present[teamIDs[j]] = false
				end
			else
				present[teamIDs[j]] = false
			end
		end
	end
end


-- track commander XP for each team
function gadget:GameFrame(n)
	local teamUnits = {}
	for teamId,_ in pairs(teamInfo) do
		teamUnits = Spring.GetTeamUnits(teamId)
		
		for _,unitId in pairs(teamUnits) do
			if ( isCommander(Spring.GetUnitDefID(unitId))) then
				local xp = Spring.GetUnitExperience(unitId)
				
				-- commander experience can now be lost
				--if (xp > teamInfo[teamId].comXP) then
					teamInfo[teamId].comXP = xp
				--end
			end
		end
	end
end


function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
	if (not unitDefID) or (not teamID) then return end

	--Spring.Echo("attackerID="..tostring(attackerID).." attackerTeamID="..tostring(attackerTeamID))
	local ud = UnitDefs[unitDefID]
	local cost = getWeightedCost(ud.metalCost,ud.energyCost)
	if (teamInfo[teamID] and attackerID and attackerTeamID) then
		teamInfo[teamID].lossValue = (teamInfo[teamID].lossValue or 0) + cost
	end
	if not attackerTeamID then return end
	if attackerTeamID == gaiaTeamID then return end
	if not present[attackerTeamID] then return end
	if SpAreTeamsAllied(teamID, attackerTeamID) then return end
	
	--keep track of who didn't kill for longest (sleeptimes)
	local curTime = Spring.GetGameSeconds()
	if (curTime - teamInfo[attackerTeamID].lastKill > teamInfo[attackerTeamID].sleepTime) then
		teamInfo[attackerTeamID].sleepTime = curTime - teamInfo[attackerTeamID].lastKill
	end
	teamInfo[attackerTeamID].lastKill = curTime

	--keep track of kills/losses
	teamInfo[attackerTeamID].killValue = teamInfo[attackerTeamID].killValue + cost
	if isEcon(unitDefID) then
		teamInfo[attackerTeamID].ecoKillValue = teamInfo[attackerTeamID].ecoKillValue + cost
	else
		teamInfo[attackerTeamID].otherDmg = teamInfo[attackerTeamID].otherDmg + cost --currently not using this but recording it for interest
	end		
	--Spring.Echo(teamInfo[attackerTeamID].killValue, teamInfo[attackerTeamID].ecoKillValue, teamInfo[attackerTeamID].otherDmg)
end

function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
    if not teamID then return end
    if teamID==gaiaTeamID then return end
    if not present[teamID] then return end
    if not unitDefID then return end
    
    local ud = UnitDefs[unitDefID]
	local cost = getWeightedCost(ud.metalCost,ud.energyCost)
    
    teamInfo[teamID].unitsCost = teamInfo[teamID].unitsCost + cost
    
    --Spring.Echo(teamID, teamInfo[teamID].unitsCost)
end

function gadget:UnitTaken(unitID, unitDefID, teamID, newTeam)
	if not newTeam then return end 
    if newTeam==gaiaTeamID then return end
	if not present[newTeam] then return end
    if not present[teamID] then return end
	if not unitDefID then return end --should never happen

	local ud = UnitDefs[unitDefID]
	local cost = getWeightedCost(ud.metalCost,ud.energyCost)

	teamInfo[newTeam].unitsCost = teamInfo[newTeam].unitsCost + cost 
end


function gadget:GameOver(winningAllyTeams)
	--calculate average damage dealt
	local avgKillValue = 0 
	local numTeams = 0
	for teamID,_ in pairs(teamInfo) do
		avgKillValue = avgKillValue + teamInfo[teamID].killValue
		numTeams = numTeams + 1
	end
	avgKillValue = avgKillValue / (math.max(1,numTeams))
	
	--get other stuff from engine stats
	for teamID,_ in pairs(teamInfo) do
		local cur_max = Spring.GetTeamStatsHistory(teamID)
		local stats = Spring.GetTeamStatsHistory(teamID, 0, cur_max)
		teamInfo[teamID].dmgDealt = teamInfo[teamID].dmgDealt + stats[cur_max].damageDealt	
		teamInfo[teamID].dmgRec = stats[cur_max].damageReceived
		teamInfo[teamID].ecoUsed = teamInfo[teamID].ecoUsed + getWeightedCost(stats[cur_max].metalUsed,stats[cur_max].energyUsed)
		--Spring.Echo("TEAM"..teamID.." unitsCost="..teamInfo[teamID].unitsCost.." killValue="..teamInfo[teamID].killValue.." avgKillValue="..avgKillValue.." lossValue="..teamInfo[teamID].lossValue)
		if teamID ~= gaiaTeamID and teamInfo[teamID].killValue >= 0.25 * avgKillValue and avgKillValue > 500 then 
			if teamInfo[teamID].lossValue > 0 then
				teamInfo[teamID].dmgRatio = teamInfo[teamID].killValue / teamInfo[teamID].lossValue
			else 
				teamInfo[teamID].dmgRatio = 1000
			end
		else
			teamInfo[teamID].dmgRatio = 0
		end
		
		teamInfo[teamID].ecoProd = getWeightedCost(stats[cur_max].metalProduced,stats[cur_max].energyProduced) 
	end

	--take account of coop
	for teamID,_ in pairs(teamInfo) do
		teamInfo[teamID].ecoKillValue = teamInfo[teamID].ecoKillValue / coopInfo[teamID].players
		teamInfo[teamID].lossValue = teamInfo[teamID].lossValue / coopInfo[teamID].players
		teamInfo[teamID].killValue = teamInfo[teamID].killValue / coopInfo[teamID].players
		teamInfo[teamID].otherDmg = teamInfo[teamID].otherDmg / coopInfo[teamID].players
		teamInfo[teamID].dmgRec = teamInfo[teamID].dmgRec / coopInfo[teamID].players 
		
		--Spring.Echo('team '..tostring(teamID)..' killed '..teamInfo[teamID].killValue)
	end
	
	--award awards
	local ecoKillAward, ecoKillAwardSec, ecoKillAwardThi, ecoKillScore, ecoKillScoreSec, ecoKillScoreThi = -1,-1,-1,0,0,0
	local fightKillAward, fightKillAwardSec, fightKillAwardThi, fightKillScore, fightKillScoreSec, fightKillScoreThi = -1,-1,-1,0,0,0
	local effKillAward, effKillAwardSec, effKillAwardThi, effKillScore, effKillScoreSec, effKillScoreThi = -1,-1,-1,0,0,0
	local comAward, comAwardSec, comAwardThi, comScore, comScoreSec, comScoreThi = -1,-1,-1,0,0,0
	local ecoAward, ecoScore = -1,0
	local dmgRecAward, dmgRecScore = -1,0
	local sleepAward, sleepScore = -1,0
	for teamID,_ in pairs(teamInfo) do	
		--deal with sleep times
		local curTime = Spring.GetGameSeconds()
		if (curTime - teamInfo[teamID].lastKill > teamInfo[teamID].sleepTime) then
			teamInfo[teamID].sleepTime = curTime - teamInfo[teamID].lastKill
		end
		--eco killing award
		if ecoKillScore < teamInfo[teamID].ecoKillValue then
			ecoKillScoreThi = ecoKillScoreSec
			ecoKillAwardThi = ecoKillAwardSec
			ecoKillScoreSec = ecoKillScore
			ecoKillAwardSec = ecoKillAward
			ecoKillScore = teamInfo[teamID].ecoKillValue
			ecoKillAward = teamID
		elseif ecoKillScoreSec < teamInfo[teamID].ecoKillValue then
			ecoKillScoreThi = ecoKillScoreSec
			ecoKillAwardThi = ecoKillAwardSec
			ecoKillScoreSec = teamInfo[teamID].ecoKillValue
			ecoKillAwardSec = teamID
		elseif ecoKillScoreThi < teamInfo[teamID].ecoKillValue then
			ecoKillScoreThi = teamInfo[teamID].ecoKillValue
			ecoKillAwardThi = teamID		
		end
		-- general killing award
		if fightKillScore < teamInfo[teamID].killValue then
			fightKillScoreThi = fightKillScoreSec
			fightKillAwardThi = fightKillAwardSec
			fightKillScoreSec = fightKillScore
			fightKillAwardSec = fightKillAward
			fightKillScore = teamInfo[teamID].killValue
			fightKillAward = teamID
		elseif fightKillScoreSec < teamInfo[teamID].killValue then
			fightKillScoreThi = fightKillScoreSec
			fightKillAwardThi = fightKillAwardSec
			fightKillScoreSec = teamInfo[teamID].killValue
			fightKillAwardSec = teamID
		elseif fightKillScoreThi < teamInfo[teamID].killValue then
			fightKillScoreThi = teamInfo[teamID].killValue
			fightKillAwardThi = teamID		
		end
		--efficiency ratio award
		if effKillScore < teamInfo[teamID].dmgRatio then
			effKillScoreThi = effKillScoreSec
			effKillAwardThi = effKillAwardSec
			effKillScoreSec = effKillScore
			effKillAwardSec = effKillAward
			effKillScore = teamInfo[teamID].dmgRatio 
			effKillAward = teamID
		elseif effKillScoreSec < teamInfo[teamID].dmgRatio then
			effKillScoreThi = effKillScoreSec
			effKillAwardThi = effKillAwardSec
			effKillScoreSec = teamInfo[teamID].dmgRatio 
			effKillAwardSec = teamID
		elseif effKillScoreThi < teamInfo[teamID].dmgRatio then
			effKillScoreThi = teamInfo[teamID].dmgRatio 
			effKillAwardThi = teamID		
		end

		-- commander award
		if comScore < teamInfo[teamID].comXP then
			comScoreThi = comScoreSec
			comAwardThi = comAwardSec
			comScoreSec = comScore
			comAwardSec = comAward
			comScore = teamInfo[teamID].comXP 
			comAward = teamID
		elseif comScoreSec < teamInfo[teamID].comXP then
			comScoreThi = comScoreSec
			comAwardThi = comAwardSec
			comScoreSec = teamInfo[teamID].comXP 
			comAwardSec = teamID
		elseif comScoreThi < teamInfo[teamID].comXP then
			comScoreThi = teamInfo[teamID].comXP 
			comAwardThi = teamID		
		end
		
		--eco prod award
		if ecoScore < teamInfo[teamID].ecoProd then
			ecoScore = teamInfo[teamID].ecoProd
			ecoAward = teamID		
		end
		--most damage rec award
		if dmgRecScore < teamInfo[teamID].dmgRec then
			dmgRecScore = teamInfo[teamID].dmgRec
			dmgRecAward = teamID		
		end
		--longest sleeper award
		if sleepScore < teamInfo[teamID].sleepTime and teamInfo[teamID].sleepTime > 12*60 then
			sleepScore = teamInfo[teamID].sleepTime
			sleepAward = teamID		
		end
	end	


	local winnersUndetermined = (next(winningAllyTeams) == nil)
	
	--tell unsynced
	SendToUnsynced("ReceiveAwards", ecoKillAward, ecoKillAwardSec, ecoKillAwardThi, ecoKillScore, ecoKillScoreSec, ecoKillScoreThi, 
									fightKillAward, fightKillAwardSec, fightKillAwardThi, fightKillScore, fightKillScoreSec, fightKillScoreThi, 
									effKillAward, effKillAwardSec, effKillAwardThi, effKillScore, effKillScoreSec, effKillScoreThi, 
									comAward, comAwardSec, comAwardThi, comScore, comScoreSec, comScoreThi,
									ecoAward, ecoScore, 
									dmgRecAward, dmgRecScore, 
									sleepAward, sleepScore, winnersUndetermined)
	
	--Spring.Echo("awards sent to unsynced")
end




-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
else  -- UNSYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local glCreateList = gl.CreateList
local glCallList = gl.CallList
local glDeleteList = gl.DeleteList
local glBeginEnd = gl.BeginEnd
local glPushMatrix = gl.PushMatrix
local glPopMatrix = gl.PopMatrix
local glTranslate = gl.Translate
local glColor = gl.Color
local glScale = gl.Scale
local glVertex = gl.Vertex
local glRect = gl.Rect
local glTexture = gl.Texture
local glTexRect = gl.TexRect
local GL_LINE_LOOP = GL.LINE_LOOP
local glText = gl.Text


local widgetScale = 1
local vsx, vsy = Spring.GetViewGeometry()

local drawAwards = false 
local cx,cy --coords for center of screen
local bx,by --coords for top left hand corner of box
local w = 900 
local h = 550
local bgMargin = 6

--h = 520-bgMargin-bgMargin
--w = 1050-bgMargin-bgMargin

local Background
local awardList = {}
local myTeamId = -1

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

local xpArrSimple = {
"",
"I",
"II",
"III",
"IV",
"V",
"VI",
"VII",
"VIII",
"IX",
"X"
}

local red = "\255"..string.char(171)..string.char(51)..string.char(51)
local blue = "\255"..string.char(51)..string.char(51)..string.char(151)
local green = "\255"..string.char(51)..string.char(151)..string.char(51)
local white = "\255"..string.char(251)..string.char(251)..string.char(251)
local yellow = "\255"..string.char(251)..string.char(251)..string.char(11)
local quitColour  
local graphColour

local playerListByTeam = {} --does not contain specs
local myPlayerID = Spring.GetMyPlayerID()


function round(num, idp)
  return string.format("%." .. (idp or 0) .. "f", num)
end

function getXPStr(xp, simple)
	local xpIndex = math.min(10,math.max(math.floor(11*xp/(xp+1)),0))+1
	return tostring(round(xp,2))..' : '..(simple and xpArrSimple[xpIndex] or xpArr[xpIndex])
end

function getEffStr(eff)
	if eff and tonumber(eff) > 999 then
		return 'PERFECT'
	else
		return eff
	end
end

function getScoreStr(type,score)
	if type == 'award_com' then
		return getXPStr(score)
	elseif type == 'award_eff' then
		return getEffStr(score)
	else
		return score	
	end
end


function gadget:Initialize()
	--register actions to SendToUnsynced messages
	gadgetHandler:AddSyncAction("ReceiveAwards", ProcessAwards)	
	
	--for testing
	--FirstAward = CreateAward('award_ecodmg',0,'Destroying enemy resource production', white, 1,1,1,24378,1324,132,100) 
	--SecondAward = CreateAward('award_dmg',0,'Destroying enemy units and defenses',white, 1,1,1,24378,1324,132,200) 
	--ThirdAward = CreateAward('award_eff',0,'Effective use of resources',white,1,1,1,24378,1324,132,300) 
 	--ThirdAward = CreateAward('award_com',0,'Fighting with commander',white,1,1,1,24378,1324,132,400)
	--OtherAwards = CreateAward('',2,'',white,1,1,1,3,100,1000,500)

	local tId = Spring.GetLocalTeamID()

	--load a list of players for each team into playerListByTeam
	local teamList = Spring.GetTeamList()
	for _,teamID in pairs(teamList) do
		local playerList = Spring.GetPlayerList(teamID)
		local list = {} --without specs
		for _,playerID in pairs(playerList) do
			local name, _, isSpec = Spring.GetPlayerInfo(playerID)
			if not isSpec then
				if teamID == tId then
					myTeamId = tId
				end
				table.insert(list, name)
			end
		end
		playerListByTeam[teamID] = list
	end
end


--[[function gadget:ViewResize(viewSizeX, viewSizeY)
	vsx,vsy = viewSizeX,viewSizeY
	if drawAwards then
		
	end
end
]]--

function formatForParser(num)
	return 'AWARD'..tostring(num)
end

-- message with the status for each team and player to show in chat logs
function generateEndGameMessage(ecoKillAward,ecoKillScore,fightKillAward,fightKillScore,effKillAward,effKillScore,comAward,comScore,winnersUndetermined)

	local statusMsg = '-------------------------------------------\n'
	for _,allyId in pairs(Spring.GetAllyTeamList()) do
		local teams = Spring.GetTeamList(allyId)
		
		if #teams > 0 and teams[1] ~= Spring.GetGaiaTeamID() then
		
			statusMsg = statusMsg..'--------- TEAM '..allyId..'\n' 
			for _,teamId in pairs(teams) do
				statusMsg = statusMsg..FindPlayerName(teamId)
				local winStatus = ''
				if (teamId >= 0) then
					winStatus = Spring.GetTeamRulesParam(teamId,'victory_status')
				end
				
				local endType = 'undetermined'
				if (not winnersUndetermined) then
					if teamId >= 0 and winStatus and winStatus == 1 then
						endType = 'WIN'
					elseif teamId >= 0 then
					 	endType = 'LOSE'
					end
				end
				
				statusMsg = statusMsg..' | '..endType
				local gotAward = false
				
				-- check if player won any of the awards
				if ecoKillAward == teamId then
					statusMsg = statusMsg..' | '
					statusMsg = statusMsg..'RAIDER ('..math.floor(ecoKillScore)..')'
					gotAward = true
				end
				if fightKillAward == teamId then
					if gotAward then
						statusMsg = statusMsg..', '
					else 
						statusMsg = statusMsg..' | '
					end
					gotAward = true
					statusMsg = statusMsg..'DESTROYER ('..math.floor(fightKillScore)..')'
				end
				if effKillAward == teamId and effKillScore > EFFICIENCY_AWARD_THRESHOLD then
					if gotAward then
						statusMsg = statusMsg..', '
					else
						statusMsg = statusMsg..' | '
					end
					gotAward = true
					statusMsg = statusMsg..'EFFICIENCY ('..getEffStr(round(effKillScore,2))..')'
				end
				if comAward == teamId and comScore > COMMANDER_XP_AWARD_THRESHOLD then
					if gotAward then
						statusMsg = statusMsg..', '
					else
						statusMsg = statusMsg..' | '
					end
					gotAward = true
					statusMsg = statusMsg..'COMMANDER ('..getXPStr(comScore,true)..')'
				end
				--Spring.Echo("winner team "..teamId)
				
				statusMsg = statusMsg..'\n'
			end		
		end
	end
	statusMsg = statusMsg..'-------------------------------------------'
	
	return statusMsg
end


-- message with the status for each team and player for replay analyzer
-- TEAMN;AI;RESULT;FACTION;AWARDLIST (format is <AWARD1>!<SCORE1>:<AWARD2>!<SCORE2>:...)
local PARSER_DELIMITER = "05.-P-097;05.-P-097;"
local PARSER_SEPARATOR = ";"
local PARSER_AWARD_SEPARATOR = ":"
local PARSER_AWARD_SCORE_SEPARATOR = "!"
function generateMFParserEndGameMessage(ecoKillAward,ecoKillScore,fightKillAward,fightKillScore,effKillAward,effKillScore,comAward,comScore,winnersUndetermined)
	local message = '\n'..PARSER_DELIMITER..'\n'
	for _,allyId in pairs(Spring.GetAllyTeamList()) do
		local teams = Spring.GetTeamList(allyId)
		
		if #teams > 0 and teams[1] ~= Spring.GetGaiaTeamID() then
			for _,teamId in pairs(teams) do
				message = message..teamId
				local winStatus = ''
				local faction = ''
				if (teamId >= 0) then
					winStatus = Spring.GetTeamRulesParam(teamId,'victory_status')
					faction = Spring.GetTeamRulesParam(teamId,'faction')
					if (not faction) then
						faction = select(5, Spring.GetTeamInfo(teamId))
					end
				end

				local endType = 'undetermined'
				if (not winnersUndetermined and teamId >= 0) then
					if winStatus and winStatus == 1 then
						endType = 'win'
					else
					 	endType = 'lose'
					end
				end

				local _,_, _, isAI, _,_ = Spring.GetTeamInfo(teamId)
				message = message..PARSER_SEPARATOR..(isAI and 1 or 0)..PARSER_SEPARATOR..endType..PARSER_SEPARATOR..faction
				local gotAward = false
				
				-- check if player won any of the awards
				if ecoKillAward == teamId then
					message = message..PARSER_SEPARATOR
					message = message..'RAIDER'..PARSER_AWARD_SCORE_SEPARATOR..math.floor(ecoKillScore)
					gotAward = true
				end
				if fightKillAward == teamId then
					if gotAward then
						message = message..PARSER_AWARD_SEPARATOR
					else 
						message = message..PARSER_SEPARATOR
					end
					gotAward = true
					message = message..'DESTROYER'..PARSER_AWARD_SCORE_SEPARATOR..math.floor(fightKillScore)
				end
				if effKillAward == teamId and effKillScore > EFFICIENCY_AWARD_THRESHOLD then
					if gotAward then
						message = message..PARSER_AWARD_SEPARATOR
					else
						message = message..PARSER_SEPARATOR
					end
					gotAward = true
					message = message..'EFFICIENCY'..PARSER_AWARD_SCORE_SEPARATOR..getEffStr(round(effKillScore,2))
				end
				if comAward == teamId and comScore > COMMANDER_XP_AWARD_THRESHOLD then
					if gotAward then
						message = message..PARSER_AWARD_SEPARATOR
					else
						message = message..PARSER_SEPARATOR
					end
					gotAward = true
					message = message..'COMMANDER'..PARSER_AWARD_SCORE_SEPARATOR..tostring(round(comScore,2))
				end
				--Spring.Echo("winner team "..teamId)
				
				message = message..'\n'
			end		
		end
	end
	message = message..PARSER_DELIMITER
	
	return message
end

function ProcessAwards(_,ecoKillAward, ecoKillAwardSec, ecoKillAwardThi, ecoKillScore, ecoKillScoreSec, ecoKillScoreThi, 
						fightKillAward, fightKillAwardSec, fightKillAwardThi, fightKillScore, fightKillScoreSec, fightKillScoreThi, 
						effKillAward, effKillAwardSec, effKillAwardThi, effKillScore, effKillScoreSec, effKillScoreThi,
						comAward, comAwardSec, comAwardThi, comScore, comScoreSec, comScoreThi, 
						ecoAward, ecoScore, 
						dmgRecAward, dmgRecScore, 
						sleepAward, sleepScore,winnersUndetermined)

	--fix geometry
	vsx,vsy = Spring.GetViewGeometry()
    cx = vsx/2 
    cy = vsy/2 
	bx = cx - w/2
	by = cy - h/2 - 45
	
    --record who won which awards in chat message (for demo parsing by replays.springrts.com)
	--make all values positive, as unsigned ints are easier to parse
	local ecoKillLine    = ''
	local fightKillLine  = ''
	local effKillLine    = ''
	local commanderLine    = ''
  
	-- create awards
	CreateBackground(winnersUndetermined)
	local awardOffset = 100
	if ecoKillAward > -1 then
		table.insert(awardList,CreateAward('award_ecodmg',0,AWARD_TEXT[AWARD_ECODMG], white, ecoKillAward, ecoKillAwardSec, ecoKillAwardThi, ecoKillScore, ecoKillScoreSec, ecoKillScoreThi, awardOffset))
		ecoKillLine    = formatForParser(AWARD_ECODMG) .. tostring(1+ecoKillAward) .. ':' .. tostring(ecoKillScore) .. formatForParser(AWARD_ECODMG) .. tostring(1+ecoKillAwardSec) .. ':' .. tostring(ecoKillScoreSec) .. formatForParser(AWARD_ECODMG) .. tostring(1+ecoKillAwardThi) .. ':' .. tostring(ecoKillScoreThi)
		awardOffset = awardOffset + 100
	end
	if fightKillAward > -1 then
		table.insert(awardList,CreateAward('award_dmg',0,AWARD_TEXT[AWARD_DMG],white, fightKillAward, fightKillAwardSec, fightKillAwardThi, fightKillScore, fightKillScoreSec, fightKillScoreThi, awardOffset))
		fightKillLine  = formatForParser(AWARD_DMG) .. tostring(1+fightKillAward) .. ':' .. tostring(fightKillScore) .. formatForParser(AWARD_DMG) .. tostring(1+fightKillAwardSec) .. ':' .. tostring(fightKillScoreSec) .. formatForParser(AWARD_DMG) .. tostring(1+fightKillAwardThi) .. ':' .. tostring(fightKillScoreThi)
		awardOffset = awardOffset + 100
	end
	if effKillAward > -1 and effKillScore > EFFICIENCY_AWARD_THRESHOLD then
		table.insert(awardList,CreateAward('award_eff',0,AWARD_TEXT[AWARD_EFF],white,effKillAward, effKillAwardSec, effKillAwardThi, effKillScore, effKillScoreSec, effKillScoreThi, awardOffset))
		effKillLine    = formatForParser(AWARD_EFF) .. tostring(1+effKillAward) ..  ':' .. tostring(effKillScore) .. formatForParser(AWARD_EFF) .. tostring(1+effKillAwardSec) .. ':' .. tostring(effKillScoreSec) .. formatForParser(AWARD_EFF) .. tostring(1+effKillAwardThi) .. ':' .. tostring(effKillScoreThi)
		awardOffset = awardOffset + 100
	end
	if comAward > -1 and comScore > COMMANDER_XP_AWARD_THRESHOLD then
		table.insert(awardList,CreateAward('award_com',0,AWARD_TEXT[AWARD_COM],white,comAward, comAwardSec, comAwardThi, comScore, comScoreSec, comScoreThi, awardOffset))
		commanderLine    = formatForParser(AWARD_COM) .. tostring(1+comAward) ..  ':' .. tostring(comScore) .. formatForParser(AWARD_COM) .. tostring(1+comAwardSec) .. ':' .. tostring(comScoreSec) .. formatForParser(AWARD_COM) .. tostring(1+comAwardThi) .. ':' .. tostring(comScoreThi)
		awardOffset = awardOffset + 100
	end
	-- other awards
	table.insert(awardList,CreateAward('',2,'',white, ecoAward, dmgRecAward, sleepAward, ecoScore, dmgRecScore, sleepScore, awardOffset))

	-- send message for parser
	local awardsMsg = ecoKillLine .. fightKillLine .. effKillLine .. commanderLine
	Spring.SendLuaRulesMsg(awardsMsg)
	
	-- message with the status for each team and player to show in chat logs
	local statusMsg = generateEndGameMessage(ecoKillAward,ecoKillScore,fightKillAward,fightKillScore,effKillAward,effKillScore,comAward,comScore,winnersUndetermined)
	Spring.SendMessage(statusMsg)
	Spring.SendLuaRulesMsg(statusMsg)

	local mfParserMsg = generateMFParserEndGameMessage(ecoKillAward,ecoKillScore,fightKillAward,fightKillScore,effKillAward,effKillScore,comAward,comScore,winnersUndetermined)
	Spring.SendLuaRulesMsg(mfParserMsg)
	
	drawAwards = true
	
	--don't show graph
	Spring.SendCommands('endgraph 0')	
end



function CreateBackground(winnersUndetermined)	
	if Background then
		glDeleteList(Background)
	end
	
	if (WG ~= nil and WG['guishader_api'] ~= nil) then
		WG['guishader_api'].InsertRect(math.floor(bx), math.floor(by), math.floor(bx + w), math.floor(by + h),'awards')
	end
	
	local victoryStatus = 0
	local endType = ''
	if (myTeamId >= 0) then
		victoryStatus = Spring.GetTeamRulesParam(myTeamId,'victory_status')
	end
	--Spring.Echo('player team was '..myTeamId)
	if winnersUndetermined then
		endType = 'undetermined'
	else
		if myTeamId >= 0 and victoryStatus and victoryStatus == 1 then
			endType = 'victory'
		elseif myTeamId >= 0 then
		 	endType = 'defeat'
		end
	end
	
	Background = glCreateList(function()
		-- background
		gl.Color(0,0,0,0.8)
		glRect(bx-bgMargin, by-bgMargin, bx + w +bgMargin,by + h+bgMargin)
		-- content area
		gl.Color(0.33,0.33,0.33,0.15)
		glRect(bx, by, bx + w, by + h)
		
		glColor(1,1,1,1)
		if endType ~= '' then 
			glTexture(':l:'..IMG_PATH..endType..'.png')
			glTexRect(bx + w/2 - 220, by + h - 75, bx + w/2 + 120, by + h - 5)
		end
		
		glText('Score', bx + w/2 + 275, by + h - 65, 15, "o") 
	
	end)	
end

function colourNames(teamID)
		if teamID < 0 then return "" end
    	nameColourR,nameColourG,nameColourB,nameColourA = Spring.GetTeamColor(teamID)
		--the first \255 is just a tag (not colour setting) no part can end with a zero due to engine limitation (C)

		--half-assed compensation to avoid white outline which makes reading harder, not easier..
		local compensation = 0
		local checkFactor = 0.8*nameColourR + 1.2*nameColourG + 0.6*nameColourB
		if checkFactor  < 1 then
			compensation = 80
		elseif checkFactor < 2.6 then
			compensation = 80  / (checkFactor)
		end

		R255 = math.min(math.floor(nameColourR*255) +compensation,255)  
        G255 = math.min(math.floor(nameColourG*255) +compensation,255)
        B255 = math.min(math.floor(nameColourB*255) +compensation,255)

        if ( R255%10 == 0) then
                R255 = R255+1
        end
        if( G255%10 == 0) then
                G255 = G255+1
        end
        if ( B255%10 == 0) then
                B255 = B255+1
        end
	return "\255"..string.char(R255)..string.char(G255)..string.char(B255) --works thanks to zwzsg
end 



function FindPlayerName(teamID)
	local plList = playerListByTeam[teamID]
	local name 
	if plList[1] then
		name = plList[1]
		if #plList > 1 then
			name = name .. " (coop)"
		end
	else
		local _,_, isDead, isAI, side, allyteam = Spring.GetTeamInfo(teamID)
		
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
			name = "(unknown)"
		end
	end

	return name
end

function CreateAward(pic, award, note, noteColour, winnerID, secondID, thirdID, winnerScore, secondScore, thirdScore, offset)
	local winnerName, secondName, thirdName
	
	--award is: 0 for a normal award, 2 for the minor awards
	
	if winnerID >= 0 then
		winnerName = FindPlayerName(winnerID)
	else
		winnerName = "(not awarded)"
	end
	
	if secondID >= 0 then
		secondName = FindPlayerName(secondID)
	else
		secondName = "(not awarded)"
	end
	
	if thirdID >= 0 then
		thirdName = FindPlayerName(thirdID)
	else
		thirdName = "(not awarded)"
	end
		
	thisAward = glCreateList(function()

		--names
		if award ~= 2 then	--if its a normal award
			glColor(1,1,1,1)
			local pic = ':l:'.. IMG_PATH .. pic ..'.png'
			glTexture(pic)
			glTexRect(bx + 12, by + h - offset - 70, bx + 108, by + h - offset + 25)

			glText(colourNames(winnerID) .. winnerName, bx + 120, by + h - offset - 10, 20, "o")
			glText(noteColour .. note, bx + 120, by + h - offset - 50, 16, "o") 
		else -- minor awards (just text)
			local heightoffset = 0
			if winnerID >=0 then
				glText(colourNames(winnerID) .. winnerName .. white .. ' produced the most metal (' .. math.floor(winnerScore) .. ').', bx + 70, by + h - offset - 10 - heightoffset, 14, "o")
				heightoffset = heightoffset + 17
			end
			if secondID >= 0 then
				glText(colourNames(secondID) .. secondName .. white .. ' took the most damage (' .. math.floor(secondScore) .. ').', bx + 70, by + h - offset - 10 - heightoffset, 14, "o")
				heightoffset = heightoffset + 17
			end
			if thirdID >= 0 then
				glText(colourNames(thirdID) .. thirdName .. white .. ' slept longest, for ' .. math.floor(thirdScore/60) .. ' minutes.', bx + 70, by + h - offset - 10 - heightoffset, 14, "o")
			end
		end
		
		--scores
		if award == 0 then --normal awards			
			if winnerID >= 0 then
				if pic == 'award_eff' or pic == 'award_com' then winnerScore = round(winnerScore, 2) else winnerScore = math.floor(winnerScore) end 
				glText(colourNames(winnerID) .. getScoreStr(pic,winnerScore), bx + w/2 + 275, by + h - offset - 5, 14, "o")
			else
				glText('-', bx + w/2 + 275, by + h - offset - 5, 17, "o")			
			end
			
			if secondScore > 0 or thirdScore > 0 then
				glText('Runners up:', bx + 500, by + h - offset - 5, 14, "o")
			end
			
			if secondScore > 0 then
				if pic == 'award_eff' or pic == 'award_com' then secondScore = round(secondScore, 2) else secondScore = math.floor(secondScore) end 
				glText(colourNames(secondID) .. secondName, bx + 520, by + h - offset - 25, 14, "o")
				glText(colourNames(secondID) .. getScoreStr(pic,secondScore), bx + w/2 + 275, by + h - offset - 25, 14, "o")
			end
			
			if thirdScore > 0 then
				if pic == 'award_eff' or pic == 'award_com' then thirdScore = round(thirdScore, 2) else thirdScore = math.floor(thirdScore) end
				glText(colourNames(thirdID) .. thirdName, bx + 520, by + h - offset - 45, 14, "o")
				glText(colourNames(thirdID) .. getScoreStr(pic,thirdScore), bx + w/2 + 275, by + h - offset - 45, 14, "o")
			end
		end
		
	
	end)
	
	return thisAward
end



local quitX = 150
local graphsX = 300

function gadget:MousePress(x,y,button)
	if button ~= 1 then return end
	if drawAwards then
		x,y = correctMouseForScaling(x,y)
		if (x > bx+w-quitX-5) and (x < bx+w-quitX+16*gl.GetTextWidth('Quit')+5) and (y>by+50-5) and (y<by+50+16+5) then --quit button
			Spring.SendCommands("quitforce")
		end
		if (x > bx+w-graphsX-5) and (x < bx+w-graphsX+16*gl.GetTextWidth('Show Graphs')+5) and (y>by+50-5) and (y<by+50+16+5) then
			Spring.SendCommands('endgraph 1')
			if (WG ~= nil and WG['guishader_api'] ~= nil) then
				WG['guishader_api'].RemoveRect('awards')
			end
			drawAwards = false
		end	
	end
end

function correctMouseForScaling(x,y)
	x = x - (((x/vsx)-0.5) * vsx)*((widgetScale-1)/widgetScale)
	y = y - (((y/vsy)-0.5) * vsy)*((widgetScale-1)/widgetScale)
	return x,y
end

function gadget:DrawScreen()

	if not drawAwards then return end
	
  vsx,vsy = Spring.GetViewGeometry()
  widgetScale = (0.70 + (vsx*vsy / 7500000))
  
	glPushMatrix()
		glTranslate(-(vsx * (widgetScale-1))/2, -(vsy * (widgetScale-1))/2, 0)
		glScale(widgetScale, widgetScale, 1)
		
		if Background then
			glCallList(Background)
		end 
		
		-- draw all awards
		for _,awd in pairs(awardList) do
			glCallList(awd)
		end
		
		--draw buttons, wastefully, but it doesn't matter now game is over
		local x1,y1 = Spring.GetMouseState()
		local x,y = correctMouseForScaling(x1,y1)
		
		if (x > bx+w-quitX-5) and (x < bx+w-quitX+16*gl.GetTextWidth('Quit')+5) and (y>by+50-5) and (y<by+50+16+5) then
			quitColour = "\255"..string.char(201)..string.char(51)..string.char(51)
		else
			quitColour = "\255"..string.char(201)..string.char(201)..string.char(201)
		end
		if (x > bx+w-graphsX-5) and (x < bx+w-graphsX+16*gl.GetTextWidth('Show Graphs')+5) and (y>by+50-5) and (y<by+50+16+5) then
			graphColour = "\255"..string.char(201)..string.char(51)..string.char(51)
		else
			graphColour = "\255"..string.char(201)..string.char(201)..string.char(201)
		end
		glText(quitColour .. 'Quit', bx+w-quitX, by+50, 16, "o")
		glText(graphColour .. 'Show Graphs', bx+w-graphsX, by+50, 16, "o")	
	glPopMatrix()
end



function gadget:Shutdown()
	Spring.SendCommands('endgraph 1')
	if (WG ~= nil and WG['guishader_api'] ~= nil) then
		WG['guishader_api'].RemoveRect('awards')
	end
end

end
