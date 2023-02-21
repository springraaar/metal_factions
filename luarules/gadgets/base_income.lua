function gadget:GetInfo()
   return {
      name = "Base Income",
      desc = "Adds base E and M income for all teams",
      author = "raaar",
      date = "February 2014",
      license = "PD",
      layer = 0,
      enabled = true,
   }
end

-- localization
local Echo = Spring.Echo
local spGetTeamList = Spring.GetTeamList
local spGetTeamInfo = Spring.GetTeamInfo
local spGetTeamLuaAI = Spring.GetTeamLuaAI
local spAreTeamsAllied = Spring.AreTeamsAllied
local spGetGameFrame = Spring.GetGameFrame
local spAddTeamResource = Spring.AddTeamResource

-- base metal and energy income every 15 frames
local BASE_METAL_INCOME = 5
local BASE_ENERGY_INCOME = 50

--SYNCED CODE
if (gadgetHandler:IsSyncedCode()) then

function gadget:GameFrame(n) 
	local teamList = spGetTeamList()
	
	-- every 15 frames, add income for each team 
	if n%15 == 0 then
		for i=1,#teamList do
			local id = teamList[i]
		
			spAddTeamResource(id,"metal",BASE_METAL_INCOME)
			spAddTeamResource(id,"energy",BASE_ENERGY_INCOME)	
		end
	end
end

end


