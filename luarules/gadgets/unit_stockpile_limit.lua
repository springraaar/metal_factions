function gadget:GetInfo()
    return {
        name      = 'Stockpile control',
        desc      = 'Limits Stockpile to set amount',
        author    = 'Bluestone, Damgam',
        version   = 'v1.0',
        date      = '23/04/2013',
		license   = "GNU GPL, v2 or later",
        layer     = 0,
        enabled   = true
    }
end


if gadgetHandler:IsSyncedCode() then -- SYNCED --

	local CMD_STOCKPILE = CMD.STOCKPILE
	local CMD_INSERT = CMD.INSERT
	local StockpileDesiredTarget = {}

	local spGetUnitStockpile	= Spring.GetUnitStockpile
	local spGiveOrderToUnit	= Spring.GiveOrderToUnit
	local spSetUnitStockpile = Spring.SetUnitStockpile
	
	----------------------------------------------------------------------------
	-- Config
	----------------------------------------------------------------------------
	local defaultStockpileLimit = 99
	local isStockpilingUnit = { -- number represents maximum stockpile
		[UnitDefNames['aven_comsat_station'].id] = 3,
		[UnitDefNames['gear_comsat_station'].id] = 3,
		[UnitDefNames['claw_comsat_station'].id] = 3,
		[UnitDefNames['sphere_comsat_station'].id] = 3
	}
	local initialStockpile = {
		[UnitDefNames['aven_comsat_station'].id] = 1,
		[UnitDefNames['gear_comsat_station'].id] = 1,
		[UnitDefNames['claw_comsat_station'].id] = 1,
		[UnitDefNames['sphere_comsat_station'].id] = 1
	}

	----------------------------------------------------------------------------


	local canStockpile = {}
	for udid, ud in pairs(UnitDefs) do
		if ud.canStockpile then
			canStockpile[udid] = true
		end
	end

	function UpdateStockpile(unitID, unitDefID)
		local MaxStockpile = math.min(isStockpilingUnit[unitDefID] or defaultStockpileLimit, StockpileDesiredTarget[unitID])

		local stock,queued = spGetUnitStockpile(unitID)
		if queued and stock then
			local count = stock + queued - MaxStockpile
			while count < 0  do
				if count < -100 then
					spGiveOrderToUnit(unitID, CMD.STOCKPILE, {}, { "ctrl", "shift" })
					count = count + 100
				elseif count < -20 then
					spGiveOrderToUnit(unitID, CMD.STOCKPILE, {}, { "ctrl" })
					count = count + 20
				elseif count < -5 then
					spGiveOrderToUnit(unitID, CMD.STOCKPILE, {}, { "shift" })
					count = count + 5
				else
					spGiveOrderToUnit(unitID, CMD.STOCKPILE, {}, 0)
					count = count + 1
				end
			end
			while count > 0 do
				if count >= 100 then
					spGiveOrderToUnit(unitID, CMD.STOCKPILE, {}, { "ctrl", "shift", "right" })
					count = count - 100
				elseif count >= 20 then
					spGiveOrderToUnit(unitID, CMD.STOCKPILE, {}, { "ctrl", "right" })
					count = count - 20
				elseif count >= 5 then
					spGiveOrderToUnit(unitID, CMD.STOCKPILE, {}, { "shift", "right" })
					count = count - 5
				else
					spGiveOrderToUnit(unitID, CMD.STOCKPILE, {}, { "right" })
					count = count - 1
				end
			end
		end
	end

	function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions, cmdTag, playerID, fromSynced, fromLua) -- Can't use StockPileChanged because that doesn't get called when the stockpile queue changes
		if unitID then
			if cmdID == CMD_STOCKPILE or (cmdID == CMD_INSERT and cmdParams[2]==CMD_STOCKPILE) then
				local pile,pileQ = spGetUnitStockpile(unitID)
				if pile == nil then
					return true
				end
				local pilelimit = math.min(isStockpilingUnit[unitDefID] or defaultStockpileLimit, StockpileDesiredTarget[unitID])
				local addQ = 1
				if cmdOptions.shift then
					if cmdOptions.ctrl then
						addQ = 100
					else
						addQ = 5
					end
				elseif cmdOptions.ctrl then
					addQ = 20
				end
				if cmdOptions.right then
					addQ = -addQ
				end
				if fromLua == true then 	-- fromLua is *true* if command is sent from a gadget and *false* if it's sent by a player
					if pile+pileQ+addQ <= pilelimit then
						return true
					else
						return false
					end
				else
					StockpileDesiredTarget[unitID] = math.max(math.min(StockpileDesiredTarget[unitID] + addQ, isStockpilingUnit[unitDefID] or defaultStockpileLimit),0) -- let's make sure desired target doesn't go above maximum of this unit
					UpdateStockpile(unitID, unitDefID)
					return false
				end
			end
		end
		return true
	end

	function gadget:UnitCreated(unitID, unitDefID, unitTeam)
		if canStockpile[unitDefID] then
			StockpileDesiredTarget[unitID] = isStockpilingUnit[unitDefID] or defaultStockpileLimit
			if initialStockpile[unitDefID] then
				spSetUnitStockpile(unitID,1)
			end
			UpdateStockpile(unitID, unitDefID)
		end
	end
	
	function gadget:UnitGiven(unitID, unitDefID, unitTeam)
		if canStockpile[unitDefID] then
			StockpileDesiredTarget[unitID] = isStockpilingUnit[unitDefID] or defaultStockpileLimit
			UpdateStockpile(unitID, unitDefID)
		end
	end
	
	function gadget:UnitCaptured(unitID, unitDefID, unitTeam)
		if canStockpile[unitDefID] then
			StockpileDesiredTarget[unitID] = isStockpilingUnit[unitDefID] or defaultStockpileLimit
			UpdateStockpile(unitID, unitDefID)
		end
	end

	function gadget:StockpileChanged(unitID, unitDefID, unitTeam)
		UpdateStockpile(unitID, unitDefID)
	end

	function gadget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
		StockpileDesiredTarget[unitID] = nil
	end
end

