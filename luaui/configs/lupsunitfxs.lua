-- note that the order of the MergeTable args matters for nested tables (such as colormaps)!

local presets = {}

effectUnitDefs = {

  --// SHIELDS //----------------------------
  -- big shields
  sphere_hermit = {
	{class='ShieldSphere', options=MergeTable({margin=3, heightFactor=0.5}, areaShieldSphere)}
  },
  sphere_shielder = {
	{class='ShieldSphere', options=MergeTable({margin=3, heightFactor=0.5}, areaShieldSphere)}
  },
  sphere_aegis = {
	{class='ShieldSphere', options=MergeTable({margin=3, heightFactor=0.5}, areaShieldSphere)}
  },
  sphere_screener = {
	{class='ShieldSphere', options=MergeTable({margin=3, heightFactor=0.5}, areaShieldSphere)}
  },
  -- small shields
  sphere_golem = {
	{class='ShieldSphere', options=MergeTable({margin=2, heightFactor=0.5}, areaShieldSphere)}
  },
  sphere_king_crab = {
	{class='ShieldSphere', options=MergeTable({margin=2, heightFactor=0.5}, areaShieldSphere)}
  },  
  sphere_charger = {
	{class='ShieldSphere', options=MergeTable({margin=2, heightFactor=0.5}, areaShieldSphere)}
  },
  sphere_rain = {
	{class='ShieldSphere', options=MergeTable({margin=2, heightFactor=0.5}, areaShieldSphere)}
  },
  sphere_pulsar = {
	{class='ShieldSphere', options=MergeTable({margin=2, heightFactor=0.5}, areaShieldSphere)}
  },
  sphere_monolith = {
	{class='ShieldSphere', options=MergeTable({margin=2, heightFactor=0.5}, areaShieldSphere)}
  },
  sphere_emerald_sphere = {
	{class='ShieldSphere', options=MergeTable({margin=2, heightFactor=0.5}, areaShieldSphere)}
  },  
  sphere_ruby_sphere = {
	{class='ShieldSphere', options=MergeTable({margin=2, heightFactor=0.5}, areaShieldSphere)}
  },  
  sphere_obsidian_sphere = {
	{class='ShieldSphere', options=MergeTable({margin=2, heightFactor=0.5}, areaShieldSphere)}
  },  
  sphere_banger = {
	{class='ShieldSphere', options=MergeTable({margin=2, heightFactor=0.5}, areaShieldSphere)}
  },  
  sphere_gazer = {
	{class='ShieldSphere', options=MergeTable({margin=2, heightFactor=0.75}, areaShieldSphere)}
  },
  sphere_comet = {
	{class='ShieldSphere', options=MergeTable({margin=2, heightFactor=0.65}, areaShieldSphere)}
  },
  sphere_construction_sphere = {
	{class='ShieldSphere', options=MergeTable({margin=2, heightFactor=0.75}, areaShieldSphere)}
  },
  sphere_aster = {
	{class='ShieldSphere', options=MergeTable({margin=2, heightFactor=0.75}, areaShieldSphere)}
  },
  sphere_chroma = {
	{class='ShieldSphere', options=MergeTable({margin=2, heightFactor=0.85}, areaShieldSphere)}
  },
  sphere_dipole = {
	{class='ShieldSphere', options=MergeTable({margin=2, heightFactor=0.65}, areaShieldSphere)}
  },
  sphere_atom = {
	{class='ShieldSphere', options=MergeTable({margin=2, heightFactor=0.65}, atomShieldSphere)}
  },
  sphere_stresser = {
	{class='ShieldSphere', options=MergeTable({margin=2, heightFactor=0.5}, areaShieldSphere)}
  },  
  sphere_u1commander = {
	{class='ShieldSphere', options=MergeTable({margin=2, heightFactor=0.5}, areaShieldSphere)}
  },
  sphere_u2commander = {
	{class='ShieldSphere', options=MergeTable({margin=2, heightFactor=0.5}, areaShieldSphere)}
  },
  sphere_u3commander = {
	{class='ShieldSphere', options=MergeTable({margin=2, heightFactor=0.5}, areaShieldSphere)}
  },
  sphere_u4commander = {
	{class='ShieldSphere', options=MergeTable({margin=2, heightFactor=0.5}, areaShieldSphere)}
  },
  sphere_u5commander = {
	{class='ShieldSphere', options=MergeTable({margin=2, heightFactor=0.5}, areaShieldSphere)}
  },
  sphere_u6commander = {
	{class='ShieldSphere', options=MergeTable({margin=2, heightFactor=0.5}, areaShieldSphere)}
  },
  
  --// AIRCRAFT JETS (and air shields)//----------------------------

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
  aven_scoper = {
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=35, piece="jp1", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=15, piece="ljp", onActive=true,down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=15, piece="rjp", onActive=true,down=true}}
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
  aven_stormfront = {
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=40, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=40, piece="rjp", onActive=true}},
	{class='AirJet',options={color={0.3,0.1,0}, width=7, length=40, piece="cjp", onActive=true}}    
  },  
  aven_gale = {
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=30, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=30, piece="rjp", onActive=true}}
  },
  aven_stealth_drone = {
    {class='AirJet',options={color={0.1,0.1,0}, width=3, length=20, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.1,0.1,0}, width=3, length=20, piece="rjp", onActive=true}}
  },
  aven_ghost = {
    {class='AirJet',options={color={0.1,0.1,0}, width=6, length=30, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.1,0.1,0}, width=6, length=30, piece="cjp", onActive=true}},
    {class='AirJet',options={color={0.1,0.1,0}, width=6, length=30, piece="rjp", onActive=true}}
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
    {class='AirJet',options={color={0.35,0.35,0.3}, width=12, length=85, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.35,0.35,0.3}, width=12, length=85, piece="rjp", onActive=true}}
  },
  aven_atlas_l = {
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=18, piece="tp1", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=18, piece="tp2", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=18, piece="tp3", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=18, piece="tp4", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=25, piece="cjp", onActive=true}}
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
  aven_transport_drone = {
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
  gear_zoomer = {
    {class='AirJet',options={color={0.3,0.1,0}, width=3, length=30, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=3, length=30, piece="rjp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=15, piece="ljp2", onActive=true,down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=15, piece="rjp2", onActive=true,down=true}}
  },
  gear_dash = {
    {class='AirJet',options={color={0.3,0.1,0}, width=3, length=30, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=3, length=30, piece="rjp", onActive=true}}
  },
  gear_firefly = {
    {class='AirJet',options={color={0.3,0.1,0}, width=3, length=25, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=3, length=25, piece="rjp", onActive=true}}
  },
  gear_seeker = {
    {class='AirJet',options={color={0.3,0.1,0}, width=3, length=25, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=3, length=25, piece="rjp", onActive=true}}
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
  gear_carrier_l = {
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=18, piece="tp1", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=18, piece="tp2", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=18, piece="tp3", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=18, piece="tp4", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=25, piece="cjp", onActive=true}}
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
  gear_transport_drone = {
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
  claw_lensor = {
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=25, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=25, piece="rjp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=15, piece="ljp2", onActive=true,down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=15, piece="rjp2", onActive=true,down=true}}
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
  claw_mover_l = {
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=18, piece="tp1", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=18, piece="tp2", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=18, piece="tp3", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=18, piece="tp4", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=25, piece="cjp", onActive=true}}
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
  claw_transport_drone = {
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
  claw_shredder = {
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=30, piece="cjp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=15, piece="ljp", onActive=true,down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=15, piece="rjp", onActive=true,down=true}}
  },
  claw_fury = {
    {class='AirJet',options={color={0.3,0.1,0}, width=10, length=35, piece="lj1p", onActive=true,down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=10, length=35, piece="lj2p", onActive=true,down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=10, length=35, piece="rj1p", onActive=true,down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=10, length=35, piece="rj2p", onActive=true,down=true}}
  },      
  claw_flayer = {
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=30, piece="lj1p", onActive=true,down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=30, piece="lj2p", onActive=true,down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=30, piece="rj1p", onActive=true,down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=30, piece="rj2p", onActive=true,down=true}}
  },
  ----------------- SPHERE
  sphere_probe = {
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=30, piece="jp1", onActive=true}}
  },
  sphere_resolver = {
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=30, piece="jp1", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=15, piece="ljp", onActive=true,down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=15, piece="rjp", onActive=true,down=true}}
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
  sphere_scrapper = {
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=27, piece="jp1", onActive=true}}
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
  sphere_blower = {
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=40, piece="jp1", onActive=true}}
  },  
  sphere_twilight = {
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=40, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=40, piece="rjp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=40, piece="cjp", onActive=true}},
    {class='ShieldSphere', options=MergeTable({margin=2, heightFactor=0.5}, areaShieldSphere)}
  },
  sphere_lifter_l = {
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=18, piece="tp1", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=18, piece="tp2", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=18, piece="tp3", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=18, piece="tp4", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=25, piece="cjp", onActive=true}}
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
  sphere_transport_drone = {
    {class='AirJet',options={color={0.3,0.1,0}, width=9, length=25, piece="tp1", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=9, length=25, piece="tp2", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=9, length=25, piece="tp3", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=9, length=25, piece="tp4", onActive=true, down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=35, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=35, piece="rjp", onActive=true}}
  },  
  sphere_spitfire = {
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=30, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=30, piece="rjp", onActive=true}},
    {class='ShieldSphere', options=MergeTable({margin=2, heightFactor=0.5}, areaShieldSphere)}
  },
  sphere_meteor = {
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=25, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=25, piece="rjp", onActive=true}},
	{class='AirJet',options={color={0.3,0.1,0}, width=6, length=25, piece="cjp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=30, piece="j1", onActive=true,down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=30, piece="j2", onActive=true,down=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=7, length=30, piece="j3", onActive=true,down=true}},
    {class='ShieldSphere', options=MergeTable({margin=2, heightFactor=0.5}, areaShieldSphere)}
  },
  sphere_neptune = {
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=25, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=25, piece="rjp", onActive=true}},
    {class='ShieldSphere', options=MergeTable({margin=2, heightFactor=0.35}, areaShieldSphere)}
  },  
  sphere_tycho = {
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=25, piece="ljp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=25, piece="rjp", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=8, length=25, piece="bjp", onActive=true,down=true}},
  },  

  --// OTHER
  
}

-- load presets from unitdefs
for i=1,#UnitDefs do
	local unitDef = UnitDefs[i]

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
