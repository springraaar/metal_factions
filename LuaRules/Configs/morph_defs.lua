--[[   Morph Definition File

Morph parameters description
local morphDefs = {		--beginig of morphDefs
	unitname = {		--unit being morphed
		into = 'newunitname',		--unit in that will morphing unit morph into
		time = 12,			--time required to complete morph process (in seconds)
		require = 'requnitname',	--unit requnitname must be present in team for morphing to be enabled
		metal = 10,			--required metal for morphing process     note: if you ommit M and/or E costs, morph costs the
		energy = 10,			--required energy for morphing process		difference in costs between unitname and newunitname
		xp = 0.07,			--required experience for morphing process (will be deduced from unit xp after morph, default=0)
		rank = 1,			--required unit rank for morphing to be enabled, if ommited, morph doesn't require rank
		tech = 2,			--required tech level of a team for morphing to be enabled (1,2,3), if ommited, morph doesn't require tech
		cmdname = 'Ascend',		--if ommited will default to "Upgrade"
		texture = 'MyIcon.dds',		--if ommited will default to [newunitname] buildpic, textures should be in "LuaRules/Images/Morph"
		text = 'Description',		--if ommited will default to "Upgrade into a [newunitname]", else it's "Description"
						--you may use "$$unitname" and "$$into" in 'text', both will be replaced with human readable unit names 
	},
}				--end of morphDefs
--]]
--------------------------------------------------------------------------------


local devolution = (-1 > 0)


local morphDefs = {
------------------------------------------------ AVEN
	aven_commander = 	{
		{
			into = 'aven_u1commander',
			time = 30,
			cmdname = 'Alpha Form',
			energy = 10000,
			metal = 1200,
			text = 'Morph to Alpha Form : Increased speed, HP and firepower.'
		},
		{
			into = 'aven_u2commander',
			time = 30,
			cmdname = 'Delta Form',
			energy = 10000,
			metal = 1200,
			text = 'Morph to Delta Form : Missile/Cannon skirmisher with greatly increased range.'
		},
		{
			into = 'aven_u3commander',
			time = 30,
			cmdname = 'Omega Form',
			energy = 10000,
			metal = 1200,
			text = 'Morph to Omega Form : Increased speed and greatly increased HP, but shorter range. Disruptor weapon stuns light units.'
		},
		{
			into = 'aven_u4commander',
			time = 30,
			cmdname = 'Builder Form',
			energy = 10000,
			metal = 1200,
			text = 'Morph to Builder Form : Greatly increased build speed and build range.'
		},
		{
			into = 'aven_u5commander',
			time = 30,
			cmdname = 'Zeta Form',
			energy = 10000,
			metal = 1200,
			text = 'Morph to Zeta Form : Greatly increased speed. Reduced build speed and combat attributes.'
		},
		{
			into = 'aven_u6commander',
			time = 30,
			cmdname = 'Gamma Form',
			energy = 10000,
			metal = 1200,
			text = 'Morph to Gamma Form : Laser skirmisher with increased range and firepower against heavy units.'
		}
	},
------------------------------------------------ GEAR
	gear_commander = 	{
		{
			into = 'gear_u1commander',
			time = 30,
			cmdname = 'Raider Form',
			energy = 10000,
			metal = 1200,
			text = 'Morph to Raider Form : Greatly increased speed and firepower against light units and structures. Shorter range.'
		},
		{
			into = 'gear_u2commander',
			time = 30,
			cmdname = 'Dominator Form',
			energy = 10000,
			metal = 1200,
			text = 'Morph to Dominator Form : Artillery form with greatly increased range and twin heavy cannons.'
		},
		{
			into = 'gear_u3commander',
			time = 30,
			cmdname = 'Devastator Form',
			energy = 10000,
			metal = 1200,
			text = 'Morph to Devastator Form : Greatly increased HP and firepower. Heavy armor. Slower speed.'
		},
		{
			into = 'gear_u4commander',
			time = 30,
			cmdname = 'Builder Form',
			energy = 10000,
			metal = 1200,
			text = 'Morph to Builder Form : Greatly increased build speed and build range.'
		},
		{
			into = 'gear_u5commander',
			time = 30,
			cmdname = 'Infernal Form',
			energy = 10000,
			metal = 1200,
			text = 'Morph to Infernal Form : Greatly increased HP and weapon area of effect. Heavy armor. Slower speed.'
		}

	},	
------------------------------------------------ CLAW
	claw_commander = 	{
		{
			into = 'claw_u1commander',
			time = 30,
			cmdname = 'Breaker Form',
			energy = 10000,
			metal = 1200,
			text = 'Morph to Breaker Form : Increased HP and greatly increased firepower against heavy units. Slightly slower speed.'
		},
		{
			into = 'claw_u2commander',
			time = 30,
			cmdname = 'Aggressor Form',
			energy = 10000,
			metal = 1200,
			text = 'Morph to Aggressor Form : Greatly increased range and anti-air capability.'
		},
		{
			into = 'claw_u3commander',
			time = 30,
			cmdname = 'Assassin Form',
			energy = 10000,
			metal = 1200,
			text = 'Morph to Assassin Form : Greatly increased speed and damage per shot. Increased range.'
		},
		{
			into = 'claw_u4commander',
			time = 30,
			cmdname = 'Builder Form',
			energy = 10000,
			metal = 1200,
			text = 'Morph to Builder Form : Greatly increased build speed and build range.'
		},
		{
			into = 'claw_u5commander',
			time = 30,
			cmdname = 'Grinder Form',
			energy = 10000,
			metal = 1200,
			text = 'Morph to Grinder Form : Greatly increased firepower. Slower speed.'
		},
		{
			into = 'claw_u6commander',
			time = 30,
			cmdname = 'Slayer Form',
			energy = 10000,
			metal = 1200,
			text = 'Morph to Slayer Form : Greatly increased speed and firepower. Reduced range.'
		}
	},	
------------------------------------------------ SPHERE
	sphere_commander = 	{
		{
			into = 'sphere_u1commander',
			time = 30,
			cmdname = 'Emerald Form',
			energy = 10000,
			metal = 1200,
			text = 'Morph to Emerald Form : Greatly increased speed and firepower against light units and aircraft.'
		},
		{
			into = 'sphere_u2commander',
			time = 30,
			cmdname = 'Ruby Form',
			energy = 10000,
			metal = 1200,
			text = 'Morph to Ruby Form : Increased HP and firepower.'
		},
		{
			into = 'sphere_u3commander',
			time = 30,
			cmdname = 'Obsidian Form',
			energy = 10000,
			metal = 1200,
			text = 'Morph to Obsidian Form : Greatly increased HP and firepower. Heavy armor. Slower speed.'
		},
		{
			into = 'sphere_u4commander',
			time = 30,
			cmdname = 'Builder Form',
			energy = 10000,
			metal = 1200,
			text = 'Morph to Builder Form : Greatly increased build speed and build range.'
		},
		{
			into = 'sphere_u5commander',
			time = 30,
			cmdname = 'Gazer Form',
			energy = 10000,
			metal = 1200,
			text = 'Morph to Gazer Form : Greatly increased range. Heavy armor. Slower speed.'
		},
		{
			into = 'sphere_u6commander',
			time = 30,
			cmdname = 'Nova Form',
			energy = 10000,
			metal = 1200,
			text = 'Morph to Nova Form : Weapon has huge area of effect and can shoot in high-trajectory mode. Heavy armor. Slower speed.'
		}		
	}
}

--
-- Here's an example of why active configuration
-- scripts are better then static TDF files...
--

--
-- devolution, babe  (useful for testing)
--
if (devolution) then
  local devoDefs = {}
  for src,data in pairs(morphDefs) do
    devoDefs[data.into] = { into = src, time = 10, metal = 1, energy = 1 }
  end
  for src,data in pairs(devoDefs) do
    morphDefs[src] = data
  end
end


return morphDefs

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
