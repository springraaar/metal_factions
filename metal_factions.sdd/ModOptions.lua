
--  Custom Options Definition Table format

--  NOTES:
--  - using an enumerated table lets you specify the options order

--
--  These keywords must be lowercase for LuaParser to read them.
--
--  key:      the string used in the script.txt
--  name:     the displayed name
--  desc:     the description (could be used as a tooltip)
--  type:     the option type
--  def:      the default value;
--  min:      minimum value for number options
--  max:      maximum value for number options
--  step:     quantization step, aligned to the def value
--  maxlen:   the maximum string length for string options
--  items:    array of item strings for list options
--  scope:    'all', 'player', 'team', 'allyteam'      <<< not supported yet >>>
--

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Example ModOptions.lua 
--

local options = {
	{
		key  = "StartingResources",
		name = "Starting Resources",
		desc = "Sets storage and amount of resources that players will start with",
		type = "section",
	},
	{
		key  = 'multipers',
		name = 'Multiper Settings',
		desc = 'Settings for multipliers.',
		type = "section",
	},
	{
      key="teamdeathmode",
      name="Team Game End Mode",
      desc="What it takes to eliminate a Team",
      type="list",
	  --section= 'xtagame',
      def="allyzerounits",
      items={
         {key="none", name="Never Die", desc="All Teams will stay alive regardless of what happends, gameover will never arrive."},
         {key="teamzerounits", name="Team Death on Zero Units", desc="The Team will die when it has 0 units."},
         {key="allyzerounits", name="AllyTeam Death on Zero units", desc="The Team will die when every Team in his AllyTeam have 0 units."},
      }
	},
	{
		key    = "MetalMult",
		name   = "Metal Extraction Multiplier",
		desc   = "Multiplies metal extraction rate. For use in large team games.",
		type   = "number",
		def    = 1,
		min    = 0,
		max    = 100,
		step   = 0.05,  -- quantization is aligned to the def value
						-- (step <= 0) means that there is no quantization
		section= "multipers",
	},
	{
		key    = "energyMult",
		name   = "Energy Multiplier",
		desc   = "Multiplies energy rate. For use in large team games.",
		type   = "number",
		def    = 1,
		min    = 0,
		max    = 100,
		step   = 0.05,  -- quantization is aligned to the def value
						-- (step <= 0) means that there is no quantization
		section= "multipers",
	},
	{
		key    = "workerMult",
		name   = "BuildSpeed Multiplier",
		desc   = "Multiplies buildspeed. For use in large team games.",
		type   = "number",
		def    = 1,
		min    = 0,
		max    = 100,
		step   = 0.05,  -- quantization is aligned to the def value
						-- (step <= 0) means that there is no quantization
		section= "multipers",
	},
	{
		key    = "velocityMult",
		name   = "Velocity Multiplier",
		desc   = "Multiplies unitspeed. Use in unison with health..1.3x is similar to BA",
		type   = "number",
		def    = 1,
		min    = 0,
		max    = 100,
		step   = 0.05,  -- quantization is aligned to the def value
						-- (step <= 0) means that there is no quantization
		section= "multipers",
	},
	{
		key    = "HitMult",
		name   = "Health Multiplier",
		desc   = "Multiplies unit health. Use in unison with speed.",
		type   = "number",
		def    = 1,
		min    = 0,
		max    = 100,
		step   = 0.05,  -- quantization is aligned to the def value
						-- (step <= 0) means that there is no quantization
		section= "multipers",
	},
	{
		key    = "startmetal",
		name   = "Starting metal",
		desc   = "Determines amount of metal and metal storage that each player will start with",
		type   = "number",
		section= "StartingResources",
		def    = 1000,
		min    = 0,
		max    = 10000,
		step   = 1,  -- quantization is aligned to the def value
					-- (step <= 0) means that there is no quantization
	},
	{
		key    = "startenergy",
		name   = "Starting energy",
		desc   = "Determines amount of energy and energy storage that each player will start with",
		type   = "number",
		section= "StartingResources",
		def    = 2500,
		min    = 0,
		max    = 10000,
		step   = 1,  -- quantization is aligned to the def value
					-- (step <= 0) means that there is no quantization
	}
}

return options
