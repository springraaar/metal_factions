--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "test unit spawner",
    desc      = "spawns all units one by one after a few seconds on the top-left corner of map",
    author    = "raaar",
    date      = "whatever",
    license   = "whatever",
    layer     = 1000,
    enabled   = false
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then
-- BEGIN SYNCED
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
allUnits = {}
index = 1

function gadget:Initialize()
    for _,ud in pairs(UnitDefs) do
	allUnits[index] = ud.name
	index = index + 1
    end
end

local x = 300
local z = 300

local START_FRAME = 100

function gadget:GameFrame(n)
	if (n > START_FRAME and n <= START_FRAME+table.maxn(allUnits)) then
		local i = n -START_FRAME
		local nextUnit = ""
		if (i < table.maxn(allUnits) ) then
			nextUnit = allUnits[i+1]
		end

		Spring.CreateUnit(allUnits[i], x, 100, z, "s", 1)
        	x = x + 100
		if x > 2500 then
			x = 300
			z = z + 100
		end
		Spring.Echo("created "..allUnits[i].."    next is "..nextUnit)
	end
end          



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
else
-- END SYNCED
-- BEGIN UNSYNCED
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
end
-- END UNSYNCED
--------------------------------------------------------------------------------
