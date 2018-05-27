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

-- may 2018 : increased income from 6 / 60 to 8 / 80
-- nov 2015 : fixed energy income frames to match engine change and increased E income

-- localization
local Echo = Spring.Echo
local spGetTeamList = Spring.GetTeamList
local spGetTeamInfo = Spring.GetTeamInfo
local spGetTeamLuaAI = Spring.GetTeamLuaAI
local spAreTeamsAllied = Spring.AreTeamsAllied
local spGetGameFrame = Spring.GetGameFrame
local spAddTeamResource = Spring.AddTeamResource

-- base metal and energy income every 15 frames
local BASE_METAL_INCOME = 4
local BASE_ENERGY_INCOME = 40

--SYNCED CODE
if (gadgetHandler:IsSyncedCode()) then

function gadget:GameFrame() 
	local teamList = spGetTeamList()
	
	-- every 16 frames, add income for each team 
	if math.fmod(spGetGameFrame(),15) == 0 then
		for i=1,#teamList do
			local id = teamList[i]
		
			spAddTeamResource(id,"metal",BASE_METAL_INCOME)
			spAddTeamResource(id,"energy",BASE_ENERGY_INCOME)	
		end
	end
end

end


