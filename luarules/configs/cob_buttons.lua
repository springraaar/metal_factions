--[[ COB buttons definition description
	armcom5 = {
		{
		name     = "Shield",
		tooltip  = "Toggle shield",  -- equals to name if ommited
		cob      = "Shield",         -- only this is required, function name in unit's BOS/COB
		endcob   = "Shield",         -- called at the end of duration
		reload   = 0,                -- button is disabled until the reload time has passed, ommit for instant
		duration = 0,                -- how long it calls the function, ommit for instant
		position = 500,              -- button position in build/order menu, ommit for auto-assignment
		type     = CMDTYPE.ICON_MODE,               -- Optional, see LuaCMD CommandTypes on Spring Wiki for details
		params   = {'0', 'Shield Off', 'Shield On'}	-- Optional, see LuaCMD CommandTypes on Spring Wiki for details
		},
	},
]]--

return {}