function gadget:GetInfo()
    return {
        name      = "Spawn",
        desc      = "spawns start unit and sets storage levels",
        author    = "Tobi Vollebregt (modified by raaar)",
        date      = "January, 2010",
        license   = "GNU GPL, v2 or later",
        layer     = math.huge,
        enabled   = true
    }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- synced only
if (not gadgetHandler:IsSyncedCode()) then
    return false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local modOptions = Spring.GetModOptions()
local commanders = {"aven_commander","gear_commander","claw_commander","sphere_commander"}

local validSide = {
	random = true,
	aven = true,
	gear = true,
	claw = true,
	sphere = true
}


local function GetStartUnit(teamID)
    local side = select(5, Spring.GetTeamInfo(teamID))
    if (not validSide[side]) then
    	side = "random"
    end

	-- check for ingame faction selection
	local ingameSide = Spring.GetTeamRulesParam(teamID,"faction_selected")
	if ingameSide and validSide[ingameSide] then
		side = ingameSide
	end

    return Spring.GetSideData(side)
end

local function SpawnStartUnit(teamID)
    local startUnit = GetStartUnit(teamID)
    local factionStr = ''
	local wasRandom = false
    if startUnit == "random" then
    	factionStr = 'random_'
    	local idx = math.random(1,#commanders)
       	startUnit = commanders[idx]
       	wasRandom = true
    end
 
    factionStr = factionStr..string.sub(startUnit,0,string.find(startUnit,"_")-1) 
    Spring.SetTeamRulesParam(teamID, 'faction', factionStr , {public=true})
    if wasRandom then
    	Spring.SendMessageToTeam( teamID, "Random faction assigned : "..string.upper(string.sub(startUnit,0,string.find(startUnit,"_")-1) ) )
    end
        
    if (startUnit and startUnit ~= "") then
		-- spawn the specified start unit
		local x,y,z
		-- use mfai start position if set, else get it normally
		if (GG.mFAIStartPosByTeamId[teamID]) then
			local startPos = GG.mFAIStartPosByTeamId[teamID]
			if (startPos ~= nil) then
				x=startPos.x
				y=startPos.y
				z=startPos.z
			end
		else
        	x,y,z = Spring.GetTeamStartPosition(teamID)
        end
        -- snap to 16x16 grid
        x, z = 16*math.floor((x+8)/16), 16*math.floor((z+8)/16)
        y = Spring.GetGroundHeight(x, z)
        -- facing toward map center
        local facing=math.abs(Game.mapSizeX/2 - x) > math.abs(Game.mapSizeZ/2 - z)
            and ((x>Game.mapSizeX/2) and "west" or "east")
            or ((z>Game.mapSizeZ/2) and "north" or "south")
        local unitID = Spring.CreateUnit(startUnit, x, y, z, facing, teamID)

		-- spawn test units
		--local xpArr = {0.1, 0.3, 0.4, 0.7, 1, 1.3, 1.8, 2.7, 4.5, 10}
		--for i=0,9 do
		--	local uId = Spring.CreateUnit("aven_trooper", 100+i*50,100,100,"s",teamID)
		--	Spring.SetUnitExperience(uId,xpArr[i%10 +1],100)
		--end
    end

    -- set start resources, either from mod options or custom team keys
    local teamOptions = select(7, Spring.GetTeamInfo(teamID))
    --local m = teamOptions.startmetal  or modOptions.startmetal  or 1500
    --local e = teamOptions.startenergy or modOptions.startenergy or 4000
	local m = 1500
    local e = 4000
    
    -- using SetTeamResource to get rid of any existing resource without affecting stats
    -- using AddTeamResource to add starting resource and counting it as income
    if (m and tonumber(m) ~= 0) then
        Spring.SetTeamResource(teamID, "ms", tonumber(m))
        Spring.SetTeamResource(teamID, "m", 0)
        Spring.AddTeamResource(teamID, "m", tonumber(m))
    end
    if (e and tonumber(e) ~= 0) then
        Spring.SetTeamResource(teamID, "es", tonumber(e))
        Spring.SetTeamResource(teamID, "e", 0)
        Spring.AddTeamResource(teamID, "e", tonumber(e))
    end
end


function gadget:GameStart()
    -- only activate if engine didn't already spawn units (compatibility)
    if (#Spring.GetAllUnits() > 0) then
        return
    end

    -- spawn start units
    local gaiaTeamID = Spring.GetGaiaTeamID()
    local teams = Spring.GetTeamList()
    for i = 1,#teams do
        local teamID = teams[i]
        -- don't spawn a start unit for the Gaia team
        if (teamID ~= gaiaTeamID) then
            SpawnStartUnit(teamID)
        end
    end
end

