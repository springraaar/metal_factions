-- note that the order of the MergeTable args matters for nested tables (such as colormaps)!

local presets = {
	commandAuraRed = {
		{class='StaticParticles', options=commandCoronaRed},
		{class='GroundFlash', options=MergeTable(groundFlashRed, {radiusFactor=3.5,mobile=true,life=60,
			colormap={ {1, 0.2, 0.2, 1},{1, 0.2, 0.2, 0.85},{1, 0.2, 0.2, 1} }})},
	},
	commandAuraOrange = {
	    {class='StaticParticles', options=commandCoronaOrange},
		{class='GroundFlash', options=MergeTable(groundFlashOrange, {radiusFactor=3.5,mobile=true,life=math.huge,
			colormap={ {0.8, 0, 0.2, 1},{0.8, 0, 0.2, 0.85},{0.8, 0, 0.2, 1} }})},
	},
	commandAuraGreen = {
		{class='StaticParticles', options=commandCoronaGreen},
		{class='GroundFlash', options=MergeTable(groundFlashGreen, {radiusFactor=3.5,mobile=true,life=math.huge,
			colormap={ {0.2, 1, 0.2, 1},{0.2, 1, 0.2, 0.85},{0.2, 1, 0.2, 1} }})},
	},
	commandAuraBlue = {
		{class='StaticParticles', options=commandCoronaBlue},
		{class='GroundFlash', options=MergeTable(groundFlashBlue, {radiusFactor=3.5,mobile=true,life=math.huge,
			colormap={ {0.2, 0.2, 1, 1},{0.2, 0.2, 1, 0.85},{0.2, 0.2, 1, 1} }})},
	},	
	commandAuraViolet = {
		{class='StaticParticles', options=commandCoronaViolet},
		{class='GroundFlash', options=MergeTable(groundFlashViolet, {radiusFactor=3.5,mobile=true,life=math.huge,
			colormap={ {0.8, 0, 0.8, 1},{0.8, 0, 0.8, 0.85},{0.8, 0, 0.8, 1} }})},
	},	
	
	commAreaShield = {
		{class='ShieldJitter', options={delay=0, life=math.huge, heightFactor = 0.75, size=350, strength = .001, precision=50, repeatEffect=true, quality=4}},
	},
	
	commandShieldRed = {
		{class='ShieldSphere', options=MergeTable({colormap1 = {{1, 0.1, 0.1, 0.6}}, colormap2 = {{1, 0.1, 0.1, 0.15}}}, commandShieldSphere)},
--		{class='StaticParticles', options=commandCoronaRed},
--		{class='GroundFlash', options=MergeTable(groundFlashRed, {radiusFactor=3.5,mobile=true,life=60,
--			colormap={ {1, 0.2, 0.2, 1},{1, 0.2, 0.2, 0.85},{1, 0.2, 0.2, 1} }})},	
	},
	commandShieldOrange = {
		{class='ShieldSphere', options=MergeTable({colormap1 = {{0.8, 0.3, 0.1, 0.6}}, colormap2 = {{0.8, 0.3, 0.1, 0.15}}}, commandShieldSphere)},
	},	
	commandShieldGreen = {
		{class='ShieldSphere', options=MergeTable({colormap1 = {{0.1, 1, 0.1, 0.6}}, colormap2 = {{0.1, 1, 0.1, 0.15}}}, commandShieldSphere)},
	},
	commandShieldBlue= {
		{class='ShieldSphere', options=MergeTable({colormap1 = {{0.1, 0.1, 0.8, 0.6}}, colormap2 = {{0.1, 0.1, 1, 0.15}}}, commandShieldSphere)},
	},	
	commandShieldViolet = {
		{class='ShieldSphere', options=MergeTable({colormap1 = {{0.6, 0.1, 0.75, 0.6}}, colormap2 = {{0.6, 0.1, 0.75, 0.15}}}, commandShieldSphere)},
	},	
}

effectUnitDefs = {

	--// ENERGY STORAGE //--------------------
  core_energy_storage = {
    {class='GroundFlash',options=groundFlashCorestor},
  },
  lost_energy_storage = {
    {class='GroundFlash',options=groundFlashCorestor},
  },
  arm_energy_storage = {
    {class='GroundFlash',options=groundFlashArmestor},
  },

  --// AIRCRAFT JETS //----------------------------

  ----------------- AVEN
  aven_peeper = {
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=30, piece="jp1", onActive=true}}
  },
  aven_light_drone = {
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=25, piece="jp1", onActive=true}}
  },
  aven_adv_construction_drone = {
    {class='AirJet',options={color={0.3,0.1,0}, width=3, length=20, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=3, length=20, piece="rjp", onActive=true}}
  },    
  aven_swift = {
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=35, piece="jp1", onActive=true}}
  },
  aven_twister = {
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=30, piece="jp1", onActive=true}}
  },
  aven_tornado = {
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=30, piece="jp1", onActive=true}}
  },  
  aven_thunder = {
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=30, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=30, piece="rjp", onActive=true}}
  },
  aven_stealth_drone = {
    {class='AirJet',options={color={0.1,0.1,0}, width=3, length=20, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.1,0.1,0}, width=3, length=20, piece="rjp", onActive=true}}
  },
  aven_medium_drone = {
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=20, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=20, piece="rjp", onActive=true}}
  },  
  aven_construction_aircraft = {
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=30, piece="jp1", onActive=true}}
  },
  aven_adv_construction_aircraft = {
    {class='AirJet',options={color={0.3,0.1,0}, width=8, length=30, piece="jp1", onActive=true}}
  },  
  aven_falcon = {
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=45, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=45, piece="rjp", onActive=true}}
  },
  aven_talon = {
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=45, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=45, piece="rjp", onActive=true}}
  },
  aven_gryphon = {
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=40, piece="jp1", onActive=true}}
  },
  aven_albatross = {
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=40, piece="jp1", onActive=true}}
  },  
  aven_ace = {
    {class='AirJet',options={color={0.35,0.2,0}, width=7, length=55, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.35,0.2,0}, width=7, length=55, piece="rjp", onActive=true}}
  },
  aven_atlas = {
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=25, piece="tp1", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=25, piece="tp2", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=25, piece="tp3", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=25, piece="tp4", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=30, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=30, piece="rjp", onActive=true}}
  },   
  aven_atlas_b = {
    {class='AirJet',options={color={0.3,0.1,0}, width=9, length=25, piece="tp1", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=9, length=25, piece="tp2", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=9, length=25, piece="tp3", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=9, length=25, piece="tp4", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=35, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=35, piece="rjp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=8, length=40, piece="cjp", onActive=true}}
  },
  aven_icarus = {
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=35, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=35, piece="rjp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=35, piece="cjp", onActive=true}}
  },    
  aven_zephyr = {
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=40, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=40, piece="rjp", onActive=true}}
  },    
  ----------------- GEAR
  gear_fink = {
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=30, piece="jp1", onActive=true}}
  },
  gear_light_drone = {
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=25, piece="jp1", onActive=true}}
  },    
  gear_stealth_drone = {
    {class='AirJet',options={color={0.1,0.1,0}, width=3, length=20, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.1,0.1,0}, width=3, length=20, piece="rjp", onActive=true}}
  },
  gear_medium_drone = {
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=20, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=20, piece="rjp", onActive=true}}
  },  
  gear_adv_construction_drone = {
    {class='AirJet',options={color={0.3,0.1,0}, width=3, length=20, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=3, length=20, piece="rjp", onActive=true}}
  },   
  gear_dash = {
    {class='AirJet',options={color={0.3,0.1,0}, width=3, length=30, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=3, length=30, piece="rjp", onActive=true}}
  },
  gear_zipper = {
    {class='AirJet',options={color={0.3,0.1,0}, width=3, length=25, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=3, length=25, piece="rjp", onActive=true}}
  },  
  gear_construction_aircraft = {
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=30, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=30, piece="rjp", onActive=true}}
  },
  gear_adv_construction_aircraft = {
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=30, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=30, piece="rjp", onActive=true}}
  },  
  gear_vector = {
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=35, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=35, piece="rjp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=3, length=30, piece="ljp2", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=3, length=30, piece="rjp2", onActive=true}}
  },
  gear_shadow = {
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=30, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=30, piece="rjp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=30, piece="ljp2", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=30, piece="rjp2", onActive=true}}
  },
  gear_cascade = {
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=50, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=50, piece="rjp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=50, piece="ljp2", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=50, piece="rjp2", onActive=true}}
  },
  gear_whirlpool = {
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=30, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=30, piece="rjp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=30, piece="ljp2", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=30, piece="rjp2", onActive=true}}
  },
  gear_stratos = {
    {class='AirJet',options={color={0.3,0.1,0}, width=8, length=25, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=8, length=25, piece="rjp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=25, piece="ljp2", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=25, piece="rjp2", onActive=true}}
  },  
  gear_firestorm = {
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=30, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=30, piece="rjp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=30, piece="ljp2", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=30, piece="rjp2", onActive=true}}
  },
  gear_carrier = {
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=25, piece="tp1", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=25, piece="tp2", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=25, piece="tp3", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=25, piece="tp4", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=30, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=30, piece="rjp", onActive=true}}
  },   
  gear_carrier_b = {
    {class='AirJet',options={color={0.3,0.1,0}, width=9, length=25, piece="tp1", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=9, length=25, piece="tp2", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=9, length=25, piece="tp3", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=9, length=25, piece="tp4", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=35, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=35, piece="rjp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=8, length=40, piece="cjp", onActive=true}}
  },
  gear_knocker = {
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=25, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=30, piece="rjp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=25, piece="cjp", onActive=true}}
  },     

  ----------------- CLAW
  claw_spotter = {
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=30, piece="jp1", onActive=true}}
  },
  claw_light_drone = {
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=25, piece="jp1", onActive=true}}
  },    
  claw_medium_drone = {
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=25, piece="jp1", onActive=true}}
  },
  claw_adv_construction_drone = {
    {class='AirJet',options={color={0.3,0.1,0}, width=3, length=20, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=3, length=20, piece="rjp", onActive=true}}
  },  
  claw_hornet = {
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=35, piece="jp1", onActive=true}}
  },
  claw_x = {
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=40, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=40, piece="rjp", onActive=true}}
  },
  claw_boomer = {
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=25, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=25, piece="rjp", onActive=true}}
  },  
  claw_boomer_m = {
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=25, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=25, piece="rjp", onActive=true}}
  },  
  claw_construction_aircraft = {
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=30, piece="jp1", onActive=true}}
  },
  claw_adv_construction_aircraft = {
    {class='AirJet',options={color={0.3,0.1,0}, width=8, length=30, piece="jp1", onActive=true}}
  },
  claw_mover = {
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=25, piece="tp1", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=25, piece="tp2", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=25, piece="tp3", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=25, piece="tp4", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=30, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=30, piece="rjp", onActive=true}}
  },   
  claw_mover_b = {
    {class='AirJet',options={color={0.3,0.1,0}, width=9, length=25, piece="tp1", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=9, length=25, piece="tp2", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=9, length=25, piece="tp3", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=9, length=25, piece="tp4", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=35, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=35, piece="rjp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=8, length=40, piece="cjp", onActive=true}}
  }, 
  claw_trident = {
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=35, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=35, piece="rjp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=35, piece="cjp", onActive=true}}
  },
  claw_blizzard = {
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=35, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=35, piece="rjp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=35, piece="cjp", onActive=true}}
  },
  claw_havoc = {
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=30, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=30, piece="rjp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=30, piece="cjp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=25, piece="jp1", onActive=true,down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=25, piece="jp2", onActive=true,down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=25, piece="jp3", onActive=true,down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=25, piece="jp4", onActive=true,down=true}}
  },  
  ----------------- SPHERE
  sphere_probe = {
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=30, piece="jp1", onActive=true}}
  },
  sphere_light_drone = {
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=25, piece="jp1", onActive=true}}
  },
  sphere_medium_drone = {
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=20, piece="jp1", onActive=true}}
  },   
  sphere_moth = {
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=25, piece="jp1", onActive=true}}
  },  
  sphere_construction_aircraft = {
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=30, piece="jp1", onActive=true}}
  },
  sphere_adv_construction_aircraft = {
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=30, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=30, piece="rjp", onActive=true}}
  },    
  sphere_manta = {
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=40, piece="jp1", onActive=true}}
  },  
  sphere_twilight = {
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=40, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=40, piece="rjp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=40, piece="cjp", onActive=true}}
  },
  sphere_lifter = {
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=25, piece="tp1", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=25, piece="tp2", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=25, piece="tp3", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=25, piece="tp4", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=30, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=30, piece="rjp", onActive=true}}
  },   
  sphere_lifter_b = {
    {class='AirJet',options={color={0.3,0.1,0}, width=9, length=25, piece="tp1", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=9, length=25, piece="tp2", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=9, length=25, piece="tp3", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=9, length=25, piece="tp4", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=35, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=35, piece="rjp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=8, length=40, piece="cjp", onActive=true}}
  },
  sphere_spitfire = {
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=30, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=30, piece="rjp", onActive=true}}
  },
  sphere_meteor = {
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=25, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=25, piece="rjp", onActive=true}},
	{class='AirJet',options={color={0.3,0.1,0}, width=6, length=25, piece="cjp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=30, piece="j1", onActive=true,down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=30, piece="j2", onActive=true,down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=30, piece="j3", onActive=true,down=true}}
  },
  sphere_neptune = {
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=25, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=25, piece="rjp", onActive=true}}
  },  
  sphere_tycho = {
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=25, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=25, piece="rjp", onActive=true}}
  },  

  --// OTHER
  roost = {
		{class='SimpleParticles', options=roostDirt},
		{class='SimpleParticles', options=MergeTable({delay=60},roostDirt)},
		{class='SimpleParticles', options=MergeTable({delay=120},roostDirt)},
  },
   
}
 
effectUnitDefsXmas = {

  arm_commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,3.8,0.7}, emitVector={0.3,0.7,0.3}, width=3.4, height=9, ballSize=1.3, piecenum=8, piece="head"}},
  },
  arm_scommander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,3.8,0.7}, emitVector={0.3,0.7,0.3}, width=3.4, height=9, ballSize=1.3, piecenum=8, piece="head"}},
  },
  arm_u0commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,3.8,0.7}, emitVector={0.3,0.7,0.3}, width=3.4, height=9, ballSize=1.3, piecenum=8, piece="head"}},
  },
  arm_ucommander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,3.8,0.7}, emitVector={0.3,0.7,0.3}, width=3.4, height=9, ballSize=1.3, piecenum=8, piece="head"}},
  },
  arm_u2commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,3.8,0.7}, emitVector={0.3,0.7,0.3}, width=3.4, height=9, ballSize=1.3, piecenum=8, piece="head"}},
  },
  arm_u3commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,3.8,0.7}, emitVector={0.3,0.7,0.3}, width=3.4, height=9, ballSize=1.3, piecenum=8, piece="head"}},
  },
  arm_u4commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,3.8,0.7}, emitVector={0.3,0.7,0.3}, width=3.4, height=9, ballSize=1.3, piecenum=8, piece="head"}},
  },
  arm_decoy_commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,3.8,0.7}, emitVector={0.3,0.7,0.3}, width=3.4, height=9, ballSize=1.3, piecenum=8, piece="head"}},
  },
  core_commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,5.2,2.1}, emitVector={0.3,0.7,0.3}, width=3.4, height=8, ballSize=1.1, piecenum=16, piece="head"}},
  },
  core_scommander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,5.2,2.1}, emitVector={0.3,0.7,0.3}, width=3.4, height=8, ballSize=1.1, piecenum=16, piece="head"}},
  },
  core_u0commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,5.2,2.1}, emitVector={0.3,0.7,0.3}, width=3.4, height=8, ballSize=1.1, piecenum=16, piece="head"}},
  },
  core_ucommander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,5.2,2.1}, emitVector={0.3,0.7,0.3}, width=3.4, height=8, ballSize=1.1, piecenum=16, piece="head"}},
  },
  core_u2commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,5.2,2.1}, emitVector={0.3,0.7,0.3}, width=3.4, height=8, ballSize=1.1, piecenum=16, piece="head"}},
  },
  core_u3commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,5.2,2.1}, emitVector={0.3,0.7,0.3}, width=3.4, height=8, ballSize=1.1, piecenum=16, piece="head"}},
  },
  core_u4commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,5.2,2.1}, emitVector={0.3,0.7,0.3}, width=3.4, height=8, ballSize=1.1, piecenum=16, piece="head"}},
  },
  core_decoy_commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,5.2,2.1}, emitVector={0.3,0.7,0.3}, width=3.4, height=8, ballSize=1.1, piecenum=16, piece="head"}},
  },
  -- lost commanders
  lost_commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,9.2,3.1}, emitVector={0.3,0.7,0.3}, width=3.4, height=8, ballSize=1.1, piecenum=18, piece="head"}},
  },
  lost_u0commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,9.2,3.1}, emitVector={0.3,0.7,0.3}, width=3.4, height=8, ballSize=1.1, piecenum=18, piece="head"}},
  },
  lost_ucommander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,9.2,3.1}, emitVector={0.3,0.7,0.3}, width=3.4, height=8, ballSize=1.1, piecenum=18, piece="head"}},
  },
  lost_u2commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,9.2,3.1}, emitVector={0.3,0.7,0.3}, width=3.4, height=8, ballSize=1.1, piecenum=18, piece="head"}},
  },
  lost_u3commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,9.2,3.1}, emitVector={0.3,0.7,0.3}, width=3.4, height=8, ballSize=1.1, piecenum=18, piece="head"}},
  },
  lost_u4commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,9.2,3.1}, emitVector={0.3,0.7,0.3}, width=3.4, height=8, ballSize=1.1, piecenum=18, piece="head"}},
  },
  lost_decoy_commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,9.2,3.1}, emitVector={0.3,0.7,0.3}, width=3.4, height=8, ballSize=1.1, piecenum=18, piece="head"}},
  },
}

effectUnitDefsStPatrick = {}
 
for i,f in pairs(effectUnitDefsXmas) do
	
	if f and (f[1]) and (f[1].options) and (f[1].options.color) then
		f[1].options.color = {0.1,0.7,0,1}
		effectUnitDefsStPatrick[i] = f
	end
end
 
 
local levelScale = {
    1,
    1.1,
    1.2,
    1.25,
    1.3,
}

-- load presets from unitdefs
for i=1,#UnitDefs do
	local unitDef = UnitDefs[i]
	
	if unitDef.customParams and unitDef.customParams.commtype then
		local s = levelScale[tonumber(unitDef.customParams.level) or 1]
		if unitDef.customParams.commtype == "1" then
			effectUnitDefsXmas[unitDef.name] = {
				{class='SantaHat', options={color={0,0.7,0,1}, pos={0,4*s,0.35*s}, emitVector={0.3,1,0.2}, width=2.7*s, height=6*s, ballSize=0.7*s, piece="head"}},
			}
		elseif unitDef.customParams.commtype == "2" then
			effectUnitDefsXmas[unitDef.name] = {
				{class='SantaHat', options={pos={0,6*s,2*s}, emitVector={0.4,1,0.2}, width=2.7*s, height=6*s, ballSize=0.7*s, piece="head"}},
			}
		elseif unitDef.customParams.commtype == "3" then 
			effectUnitDefsXmas[unitDef.name] = {
				{class='SantaHat', options={color={0,0.7,0,1}, pos={1.5*s,4*s,0.5*s}, emitVector={0.7,1.6,0.2}, width=2.2*s, height=6*s, ballSize=0.7*s, piece="head"}},
			}
		elseif unitDef.customParams.commtype == "4" then 
			effectUnitDefsXmas[unitDef.name] = {
				{class='SantaHat', options={pos={0,3.8*s,0.35*s}, emitVector={0,1,0}, width=2.7*s, height=6*s, ballSize=0.7*s, piece="head"}},
			}
		elseif unitDef.customParams.commtype == "5" then 
			effectUnitDefsXmas[unitDef.name] = {
				{class='SantaHat', options={color={0,0,0.7,1}, pos={0,0,0}, emitVector={0,1,0.1}, width=2.7*s, height=6*s, ballSize=0.7*s, piece="hat"}},
			}	    
		elseif unitDef.customParams.commtype == "6" then 
			effectUnitDefsXmas[unitDef.name] = {
				{class='SantaHat', options={color={0,0,0.7,1}, pos={0,0,0}, emitVector={0,1,-0.1}, width=4.05*s, height=9*s, ballSize=1.05*s, piece="hat"}},
			}	    
		end
	end
	if unitDef.customParams then
		local fxTableStr = unitDef.customParams.lups_unit_fxs
		if fxTableStr then
			local fxTableFunc = loadstring("return "..fxTableStr)
			local fxTable = fxTableFunc()
			effectUnitDefs[unitDef.name] = effectUnitDefs[unitDef.name] or {}
			for i=1,#fxTable do	-- for each item in preset table
				local toAdd = presets[fxTable[i]]
				for i=1,#toAdd do
					table.insert(effectUnitDefs[unitDef.name],toAdd[i])	-- append to unit's lupsFX table
				end
			end
		end
	end
end
