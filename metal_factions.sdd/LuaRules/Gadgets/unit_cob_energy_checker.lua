
function gadget:GetInfo()
  return {
    name      = "Cob Energy Checker",
    desc      = "used on cob checks if player has enough energy to enable or disable certain unit abilities",
    author    = "raaar",
    date      = "Mar 2015",
    license   = "PD",
    layer     = 2,
    enabled   = true
  }
end

-- TODO remove this and move logic to unit_estall_disable?

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
    return
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------


function checkEnergy(unitID, unitDefID, teamID, data)

	-- get team energy
	local currentLevelE,storageE,_,incomeE,expenseE,_,_,_ = Spring.GetTeamResources(teamID,"energy")

	-- if greater than threshold, return 1
	if currentLevelE > data then
		return 1
	end

	-- else return 0
	return 0
end


gadgetHandler:RegisterGlobal("checkEnergy", checkEnergy)
