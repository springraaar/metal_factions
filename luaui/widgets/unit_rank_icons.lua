function widget:GetInfo() return {
	name      = "Rank Icons 2",
	desc      = "Adds a rank icon depending on experience next to units (needs Unit Icons)",
	author    = "trepan (idea quantum,jK), modified by CarRepairer, Sprung, raaar",
	date      = "2021",
	license   = "GNU GPL, v2 or later",
	layer     = 11,
	enabled   = true,
} end

local min   = math.min
local floor = math.floor
local max = math.max

local unitXp = {}

local spGetSpectatingState = Spring.GetSpectatingState
local spGetUnitRulesParam = Spring.GetUnitRulesParam

local clearingTable = {
	name = 'rank',
	texture = nil
}

local rankTexBase = 'luaui/images/ranks/'
local rankTextures = {
	rankTexBase ..'norank.png',
	rankTexBase .. 'I.png',
	rankTexBase .. 'II.png',
	rankTexBase .. 'III.png',
	rankTexBase .. 'IV.png',
	rankTexBase .. 'V.png',
	rankTexBase .. 'VI.png',
	rankTexBase .. 'VII.png',
	rankTexBase .. 'VIII.png',
	rankTexBase .. 'IX.png',
	rankTexBase .. 'X.png'
}

function widget:Initialize ()
	WG.icons.SetOrder ('rank', 1)

	local allUnits = Spring.GetAllUnits()
	for _,unitID in pairs (allUnits) do
		updateUnitRank(unitID)
	end
end

function updateUnitRank(unitID)
	local xp = unitXp[unitID]
	local xpIndex = 1
	if xp and xp > 0 then
		xpIndex = min(10,max(floor(11*xp/(xp+1)),0))+1
	end
	xpIndex = min(#rankTextures or 1, xpIndex)
	--Spring.Echo(unitID.." xpIndex="..xpIndex)
	WG.icons.SetUnitIcon (unitID, {
		name = 'rank',
		texture = rankTextures[xpIndex]
	})
end

function widget:UnitLeftLos(unitID, unitDefID, unitTeam)
	if not spGetSpectatingState() then
		WG.icons.SetUnitIcon(unitID, clearingTable)
		unitXp[unitID] = nil
	end
end

function widget:GameFrame(f)
	for _,uId in pairs(Spring.GetVisibleUnits()) do
		local xp = spGetUnitRulesParam(uId,"experience") or 0 --Spring.GetUnitExperience(uId)
		if unitXp[uId] then
			if xp ~= unitXp[uId] then
				unitXp[uId] = xp
				updateUnitRank(uId)
			end
		else
			unitXp[uId] = xp
			updateUnitRank(uId)
		end
	end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if (unitXp[unitID] ~= nil) then
		unitXp[unitID] = nil
	end
	WG.icons.SetUnitIcon(unitID, clearingTable)
end
