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

return {
  aven_podger = {
    {
      name     = "Self-Charge",
      tooltip  = "5 second timer 3 seconds to cancel, 4th second will minesweep Destruction after the 5th second!",
      cob      = "SelfD",  -- only this is required
      endcob   = "SelfD",
      reload   = 1,
      position = 500,
      duration = 1,              
    },
  },
  aven_spider = {
    {
      name     = "EMP overload",
      tooltip  = "1 second timer to overload the system, causing damage to the unit and area!",
      cob      = "Overload",
      reload   = 0.1,
      position = 500,
      duration = 1,                 
    },
  },
  gear_nin2commander = {
    {
      name     = "Shield",
      tooltip  = "Invulnerable for 10 seconds!",
      cob      = "ShieldStart",
      endcob   = "ShieldEnd",
      reload   = 60,
      duration = 10,
      position = 500,              
    },
  },
  aven_raven = {
    {
	name     = "Rocket type",
	tooltip  = "Select rocket type",
	cob      = "RocketType",
	type = CMDTYPE.ICON_MODE,			--button Style (togglable or multi-button)
	params = {'1', 'S.W.A.R.M', 'HE Rockets'},	--button Parameters, default value is 1, 'S.W.A.R.M'=0, 'HE Rockets'=1
    },
  },
}