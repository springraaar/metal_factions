function widget:GetInfo()
  return {
    name      = "Unit Auto-Groups",
    desc      = "Allows assigning unit types to auto-join groups on creation",
    author    = "raaar",
    date      = "2024",
    license   = "PD",
    layer     = 10,
    enabled   = true
  }
end

local spGetMyTeamID = Spring.GetMyTeamID
local spGetMyPlayerID = Spring.GetMyPlayerID
local spSetUnitGroup = Spring.SetUnitGroup
local spSendMessageToPlayer = Spring.SendMessageToPlayer 
local spGetSelectedUnitsCounts = Spring.GetSelectedUnitsCounts
local spGetSelectedUnits  = Spring.GetSelectedUnits
local spGetTeamUnits = Spring.GetTeamUnits
local spGetTeamUnitsSorted = Spring.GetTeamUnitsSorted 
local spSelectUnitArray = Spring.SelectUnitArray

WG.autoGroupByUDefId = {}
local autoGroupByUDefId = WG.autoGroupByUDefId

local KEY0=48
local KEY9=57

local myTeamId = spGetMyTeamID()
local myPlayerId = spGetMyPlayerID()

-------------------------------------------- auxiliary functions

function resetAutoGroups()
	WG.autoGroupByUDefId = {}
	autoGroupByUDefId = WG.autoGroupByUDefId
end

-------------------------------------------- engine callins

function widget:Initialize()

end


function widget:KeyPress(key, mods, isRepeat)
	if (mods.alt and key >= KEY0 and key <= KEY9) then
		local n = key - KEY0
		if n == 0 then
			-- clear autogroups
			resetAutoGroups()
			spSendMessageToPlayer(myPlayerId,"Unit Auto-Group assignments cleared") 
		else
			-- assign selected unit types to auto-group
			local sCounts,_ = spGetSelectedUnitsCounts()
			for udId,count in pairs(sCounts) do
				autoGroupByUDefId[udId] = n 		
			end
			-- assign already built units to the group as well
			local teamUnits = spGetTeamUnitsSorted(myTeamId)
			for udId,list in pairs(teamUnits) do
				if sCounts[udId] then
					for _,uId in pairs(list) do
						spSetUnitGroup(uId, n)	
						-- add them to the selection as well
						spSelectUnitArray(list,true) 
					end
				end
			end
			 
			spSendMessageToPlayer(myPlayerId,"Selected unit types assigned to Auto-Group "..n) 
		end
		return true
	end
end

function widget:KeyRelease()
end

function widget:UnitCreated(unitId,unitDefId,unitTeam)
	if unitTeam == myTeamId and autoGroupByUDefId[unitDefId] then
		local groupNumber = autoGroupByUDefId[unitDefId]
		if groupNumber then 
			spSetUnitGroup(unitId, groupNumber)
		end 
	end
end

