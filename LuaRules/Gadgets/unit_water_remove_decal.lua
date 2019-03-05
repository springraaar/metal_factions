function gadget:GetInfo()
   return {
      name = "Ground decal removal",
      desc = "Removes ground decal for floating buildings when built over water.",
      author = "raaar",
      date = "2019",
      license = "PD",
      layer = 10,
      enabled = true,
   }
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
    return
end


local MIN_WATER_DEPTH = 10

local spGetGroundHeight = Spring.GetGroundHeight
local spGetUnitPosition = Spring.GetUnitPosition
local spRemoveBuildingDecal = Spring.RemoveBuildingDecal
local removeDecalUnitIds = {}

-- removes ground decal for floating buildings when built over water
function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	local ud = UnitDefs[unitDefID] 
	if ud and ud.isBuilding and (ud.floatOnWater)  then
		local x,_,z = 0
		x,_,z = spGetUnitPosition(unitID)
		local h = spGetGroundHeight(x,z)
		if h < -MIN_WATER_DEPTH then
			removeDecalUnitIds[unitID] = true
		end
	end
end

-- process update steps every N frames
-- process aircraft altitude loss every frame
function gadget:GameFrame(n)
	for uId,_ in pairs(removeDecalUnitIds) do
		spRemoveBuildingDecal(uId)   -- this is going to change to removeObjectDecal on 105.0
		removeDecalUnitIds[uId] = nil
	end
end