

------------------------------------ strategy definition
local MANY = 100


-- upgrades options : "offensive", "defensive", "defensive_regen", "speed", "mixed", "mixed_drones_utility", "mixed_drones_combat"
-- conditions : THREAT_AIR, THREAT_GROUND, THREAT_STATIC, THREAT_UNDERWATER, CONDITION_WATER


--------------------------------------- AVEN

avenLandAssault = {
	name = "avenLandAssault",
	commanderMorphs = { "Alpha Form","Omega Form","Zeta Form" },
	upgrades = "speed",
	stages = {
		------------------ STAGE 1
		{
			economy = {
				minMetalIncome = 15,
				minEnergyIncome = 200,
				metalIncome = 50,
				energyIncome = 350,
				comMorphMetalIncome = 50,		-- delay morph
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = false
			},
			properties = {
				commanderBuildsFactories = false,
				raiderSpeedThreshold = 85,
				enemyThreatEstimationMult = 1.6,
				defenseDensityMult = 1,
				forceSpreadFactor = 0.5
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 0,
				mexUpgraders = 0,
				advancedDefenseBuilders = 0
			},
			factories = {
				{name="aven_nano_tower",min=1,max=1},
				{name="aven_light_plant",min=1,max=1},
				{name="aven_commander_respawner",min=1,max=1}
			},
			mobileUnits = {
				{name="aven_construction_kbot",min=1,max=6,weight=0.2},
				{name="aven_trooper_laser",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="aven_trooper_laser",min=0,max=MANY,weight=0.3},
				{name="aven_wheeler",min=0,max=MANY,weight=0.3},
				{name="aven_bold",min=0,max=MANY,weight=0.3},
				{name="aven_runner",min=0,max=MANY,weight=0.2}
			}
		},
		------------------ STAGE 2
		{
			economy = {
				minMetalIncome = 30,
				minEnergyIncome = 300,
				metalIncome = 200,
				energyIncome = 5000,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = false
			},
			properties = {
				commanderBuildsFactories = false,
				raiderSpeedThreshold = 85,
				enemyThreatEstimationMult = 1.6,
				defenseDensityMult = 1,
				forceSpreadFactor = 0.5
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 2,
				mexUpgraders = 1,
				advancedDefenseBuilders = 0
			},
			factories = {
				{name="aven_nano_tower",min=1,max=3},
				{name="aven_adv_vehicle_plant",min=1,max=1},
				{name="aven_light_plant",min=1,max=1},
				{name="aven_commander_respawner",min=1,max=2},
				{name="aven_scout_pad",min=1,max=1},
				{name="aven_upgrade_center",min=1,max=1}
			},
			mobileUnits = {
				{name="aven_construction_kbot",min=2,max=4,weight=0.2},
				{name="aven_adv_construction_vehicle",min=1,max=3,weight=0.2},
				{name="aven_trooper_laser",min=0,max=MANY,weight=0.2,includeConditions={THREAT_AIR}},
				{name="aven_trooper_laser",min=0,max=MANY,weight=0.3},
				{name="aven_kodiak",min=2,max=MANY,weight=0.4,includeConditions={THREAT_AIR}},
				{name="aven_kodiak",min=0,max=MANY,weight=0.2},
				{name="aven_centurion",min=3,max=MANY,weight=0.3},
				{name="aven_kodiak",min=0,max=MANY,weight=0.1},
				{name="aven_jammer",min=1,max=1,weight=0.01},
				{name="aven_bold",min=0,max=MANY,weight=0.6},
				{name="aven_samson",min=0,max=MANY,weight=0.6},
				{name="aven_racer",min=0,max=MANY,weight=0.2},
				{name="aven_runner",min=0,max=MANY,weight=0.3}
			}
		},
		------------------ STAGE 3
		{
			economy = {
				minMetalIncome = 60,
				minEnergyIncome = 1500,
				metalIncome = 9999,
				energyIncome = 99999,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = true
			},
			properties = {
				commanderBuildsFactories = false,
				raiderSpeedThreshold = 85,
				enemyThreatEstimationMult = 1.6,
				defenseDensityMult = 1,
				forceSpreadFactor = 0.7
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 4,
				mexUpgraders = 1,
				advancedDefenseBuilders = 0
			},				
			factories = {
				{name="aven_nano_tower",min=1,max=4},
				{name="aven_adv_vehicle_plant",min=1,max=2},
				{name="aven_light_plant",min=1,max=1},				
				{name="aven_commander_respawner",min=2,max=2},
				{name="aven_upgrade_center",min=1,max=1},
				{name="aven_adv_aircraft_plant",min=1,max=1},
				{name="aven_scout_pad",min=1,max=1}
			},
			mobileUnits = {
				{name="aven_construction_kbot",min=2,max=6,weight=0.2},
				{name="aven_adv_construction_vehicle",min=2,max=6,weight=0.2},
				{name="aven_trooper_laser",min=1,max=MANY,weight=0.2,includeConditions={THREAT_AIR}},
				{name="aven_centurion",min=0,max=MANY,weight=0.4},
				{name="aven_kodiak",min=2,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="aven_kodiak",min=0,max=MANY,weight=0.2},
				{name="aven_jammer",min=1,max=1,weight=0.01},
				{name="aven_bold",min=0,max=MANY,weight=0.6},
				{name="aven_samson",min=0,max=MANY,weight=0.4},
				{name="aven_falcon",min=3,max=MANY,weight=0.3,includeConditions={THREAT_AIR}},
				{name="aven_albatross",min=3,max=MANY,weight=1,includeConditions={THREAT_UNDERWATER}},
				{name="aven_zephyr",min=1,max=1,weight=0.01},
				{name="aven_racer",min=0,max=MANY,weight=0.2},
				{name="aven_runner",min=0,max=MANY,weight=0.3}
			}
		},
		------------------ STAGE 4
		{
			economy = {
				minMetalIncome = 90,
				minEnergyIncome = 2500,
				metalIncome = 9999,
				energyIncome = 99999,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = true
			},
			properties = {
				commanderBuildsFactories = false,
				raiderSpeedThreshold = 85,
				enemyThreatEstimationMult = 1.6,
				defenseDensityMult = 1,
				forceSpreadFactor = 0.7
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 4,
				mexUpgraders = 1,
				advancedDefenseBuilders = 1
			},				
			factories = {
				{name="aven_nano_tower",min=1,max=6},
				{name="aven_adv_vehicle_plant",min=1,max=2},
				{name="aven_light_plant",min=1,max=1},				
				{name="aven_commander_respawner",min=2,max=2},
				{name="aven_upgrade_center",min=1,max=1},
				{name="aven_adv_aircraft_plant",min=1,max=1},
				{name="aven_scout_pad",min=1,max=1},
				{name="aven_long_range_rocket_platform",min=1,max=1}
			},
			mobileUnits = {
				{name="aven_construction_kbot",min=2,max=6,weight=0.2},
				{name="aven_adv_construction_vehicle",min=2,max=6,weight=0.2},
				{name="aven_trooper_laser",min=1,max=MANY,weight=0.4,includeConditions={THREAT_AIR}},
				{name="aven_centurion",min=0,max=MANY,weight=0.4},
				{name="aven_kodiak",min=0,max=MANY,weight=0.4},
				{name="aven_jammer",min=1,max=1,weight=0.01},
				{name="aven_bold",min=0,max=MANY,weight=0.6},
				{name="aven_samson",min=0,max=MANY,weight=0.4},
				{name="aven_falcon",min=3,max=MANY,weight=0.3,includeConditions={THREAT_AIR}},
				{name="aven_albatross",min=3,max=MANY,weight=1,includeConditions={THREAT_UNDERWATER}},
				{name="aven_zephyr",min=1,max=1,weight=0.01},
				{name="aven_racer",min=0,max=MANY,weight=0.2},
				{name="aven_runner",min=0,max=MANY,weight=0.3}
			}
		},					
	}
}


avenLandSkirmisher = {
	name = "avenLandSkirmisher",
	commanderMorphs = { "Delta Form","Gamma Form" },
	upgrades = "offensive",
	stages = {
		------------------ STAGE 1
		{
			economy = {
				minMetalIncome = 15,
				minEnergyIncome = 200,
				metalIncome = 50,
				energyIncome = 350,
				comMorphMetalIncome = 50,		-- delay morph
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = false
			},
			properties = {
				commanderBuildsFactories = false,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.2,
				defenseDensityMult = 1,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 0,
				mexUpgraders = 0,
				advancedDefenseBuilders = 0
			},
			factories = {
				{name="aven_nano_tower",min=1,max=1},
				{name="aven_light_plant",min=1,max=1},
				{name="aven_commander_respawner",min=1,max=1}
			},
			mobileUnits = {
				{name="aven_construction_kbot",min=1,max=6,weight=0.2},
				{name="aven_trooper_laser",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="aven_bold",min=1,max=MANY,weight=1,includeConditions={THREAT_ASSAULT}},
				{name="aven_samson",min=0,max=MANY,weight=0.3},
				{name="aven_duster",min=0,max=MANY,weight=0.3},
				{name="aven_runner",min=0,max=MANY,weight=0.2},				
				{name="aven_trooper",min=0,max=MANY,weight=0.1}
			}
		},
		------------------ STAGE 2
		{
			economy = {
				minMetalIncome = 30,
				minEnergyIncome = 300,
				metalIncome = 200,
				energyIncome = 5000,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = false
			},
			properties = {
				commanderBuildsFactories = false,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.2,
				defenseDensityMult = 1,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 2,
				mexUpgraders = 1,
				advancedDefenseBuilders = 0
			},
			factories = {
				{name="aven_nano_tower",min=1,max=3},
				{name="aven_adv_kbot_lab",min=1,max=1},
				{name="aven_light_plant",min=1,max=1},
				{name="aven_aircraft_plant",min=1,max=1},
				{name="aven_commander_respawner",min=1,max=2},
				{name="aven_scout_pad",min=1,max=1},
				{name="aven_upgrade_center",min=1,max=1}
			},
			mobileUnits = {
				{name="aven_construction_kbot",min=2,max=4,weight=0.2},
				{name="aven_adv_construction_kbot",min=1,max=3,weight=0.2},
				{name="aven_trooper_laser",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="aven_shocker",min=1,max=MANY,weight=1,includeConditions={THREAT_ASSAULT}},
				{name="aven_weaver",min=3,max=MANY,weight=0.6},
				{name="aven_sniper",min=3,max=MANY,weight=0.3},
				{name="aven_bolter",min=3,max=MANY,weight=0.3},
				{name="aven_eraser",min=1,max=1,weight=0.01},
				{name="aven_duster",min=0,max=MANY,weight=0.3},
				{name="aven_samson",min=0,max=MANY,weight=0.3},
				{name="aven_runner",min=0,max=MANY,weight=0.2},
				{name="aven_stalker",min=0,max=MANY,weight=0.2},
				{name="aven_scoper",min=1,max=1,weight=0.01}
			}
		},
		------------------ STAGE 3
		{
			economy = {
				minMetalIncome = 60,
				minEnergyIncome = 1500,
				metalIncome = 9999,
				energyIncome = 99999,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = true
			},
			properties = {
				commanderBuildsFactories = false,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.2,
				defenseDensityMult = 1,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 4,
				mexUpgraders = 1,
				advancedDefenseBuilders = 0
			},				
			factories = {
				{name="aven_nano_tower",min=1,max=4},
				{name="aven_adv_kbot_lab",min=1,max=2},
				{name="aven_light_plant",min=1,max=1},
				{name="aven_aircraft_plant",min=1,max=1},					
				{name="aven_commander_respawner",min=2,max=2},
				{name="aven_upgrade_center",min=1,max=1},
				{name="aven_adv_vehicle_plant",min=1,max=1},
				{name="aven_scout_pad",min=1,max=1}
			},
			mobileUnits = {
				{name="aven_construction_kbot",min=2,max=6,weight=0.2},
				{name="aven_adv_construction_kbot",min=2,max=3,weight=0.2},
				{name="aven_adv_construction_vehicle",min=2,max=3,weight=0.2},
				{name="aven_trooper_laser",min=1,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="aven_shocker",min=1,max=MANY,weight=1,includeConditions={THREAT_ASSAULT}},
				{name="aven_weaver",min=3,max=MANY,weight=0.6},
				{name="aven_sniper",min=3,max=MANY,weight=0.3},
				{name="aven_merl",min=2,max=MANY,weight=0.4},
				{name="aven_bolter",min=3,max=MANY,weight=0.3},
				{name="aven_eraser",min=1,max=1,weight=0.01},
				{name="aven_duster",min=0,max=MANY,weight=0.3},
				{name="aven_samson",min=0,max=MANY,weight=0.3},
				{name="aven_runner",min=0,max=MANY,weight=0.2},
				{name="aven_stalker",min=0,max=MANY,weight=0.2},
				{name="aven_scoper",min=1,max=1,weight=0.01}				
			}
		},
		------------------ STAGE 4
		{
			economy = {
				minMetalIncome = 90,
				minEnergyIncome = 2500,
				metalIncome = 9999,
				energyIncome = 99999,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = true
			},
			properties = {
				commanderBuildsFactories = false,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.2,
				defenseDensityMult = 1,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 4,
				mexUpgraders = 1,
				advancedDefenseBuilders = 1
			},				
			factories = {
				{name="aven_nano_tower",min=1,max=6},
				{name="aven_adv_kbot_lab",min=1,max=2},
				{name="aven_adv_vehicle_plant",min=1,max=2},
				{name="aven_light_plant",min=1,max=1},				
				{name="aven_commander_respawner",min=2,max=2},
				{name="aven_upgrade_center",min=1,max=1},
				{name="aven_adv_aircraft_plant",min=1,max=1},
				{name="aven_scout_pad",min=1,max=1},
				{name="aven_long_range_rocket_platform",min=1,max=1}
			},
			mobileUnits = {
				{name="aven_construction_kbot",min=2,max=6,weight=0.2},
				{name="aven_adv_construction_kbot",min=2,max=3,weight=0.2},
				{name="aven_adv_construction_vehicle",min=2,max=6,weight=0.2},
				{name="aven_trooper_laser",min=1,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="aven_shocker",min=1,max=MANY,weight=1,includeConditions={THREAT_ASSAULT}},
				{name="aven_weaver",min=3,max=MANY,weight=0.6},
				{name="aven_sniper",min=3,max=MANY,weight=0.3},
				{name="aven_merl",min=2,max=MANY,weight=0.4},
				{name="aven_bolter",min=3,max=MANY,weight=0.3},
				{name="aven_eraser",min=1,max=1,weight=0.01},
				{name="aven_duster",min=0,max=MANY,weight=0.3},
				{name="aven_samson",min=0,max=MANY,weight=0.3},
				{name="aven_runner",min=0,max=MANY,weight=0.2},
				{name="aven_stalker",min=0,max=MANY,weight=0.2},
				{name="aven_scoper",min=1,max=2,weight=0.05},				
				{name="aven_falcon",min=3,max=MANY,weight=0.3,includeConditions={THREAT_AIR}},
				{name="aven_albatross",min=3,max=MANY,weight=1,includeConditions={THREAT_UNDERWATER}}
			}
		},					
	}
}


avenAir = {
	name = "avenAir",
	commanderMorphs = { "Delta Form","Gamma Form" },
	upgrades = "defensive",
	stages = {
		------------------ STAGE 1
		{
			economy = {
				minMetalIncome = 15,
				minEnergyIncome = 200,
				metalIncome = 50,
				energyIncome = 350,
				comMorphMetalIncome = 50,		-- delay morph
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = false
			},
			properties = {
				commanderBuildsFactories = false,
				roamingCommander = true,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.3,
				defenseDensityMult = 2,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 0,
				mexUpgraders = 0,
				advancedDefenseBuilders = 0
			},
			factories = {
				{name="aven_nano_tower",min=1,max=1},
				{name="aven_aircraft_plant",min=1,max=1},
				{name="aven_commander_respawner",min=1,max=1}
			},
			mobileUnits = {
				{name="aven_construction_aircraft",min=1,max=6,weight=0.2},
				{name="aven_swift",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="aven_twister",min=0,max=MANY,weight=0.5},
				{name="aven_tornado",min=0,max=MANY,weight=0.3},
				{name="aven_gale",min=0,max=MANY,weight=0.1}
			}
		},
		------------------ STAGE 2
		{
			economy = {
				minMetalIncome = 30,
				minEnergyIncome = 300,
				metalIncome = 200,
				energyIncome = 5000,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = false
			},
			properties = {
				commanderBuildsFactories = false,
				roamingCommander = true,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.3,
				defenseDensityMult = 2,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 0,
				mexUpgraders = 1,
				advancedDefenseBuilders = 0
			},
			factories = {
				{name="aven_nano_tower",min=1,max=3},
				{name="aven_adv_aircraft_plant",min=1,max=1},
				{name="aven_aircraft_plant",min=1,max=1},
				{name="aven_commander_respawner",min=1,max=2},
				{name="aven_scout_pad",min=1,max=1},
				{name="aven_upgrade_center",min=1,max=1}
			},
			mobileUnits = {
				{name="aven_construction_aircraft",min=2,max=4,weight=0.2},
				{name="aven_adv_construction_aircraft",min=1,max=3,weight=0.2},
				{name="aven_falcon",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="aven_falcon",min=1,max=MANY,weight=0.2},
				{name="aven_icarus",min=1,max=MANY,weight=0.3},
				{name="aven_gale",min=1,max=MANY,weight=0.3},
				{name="aven_gryphon",min=3,max=MANY,weight=0.6},
				{name="aven_albatross",min=1,max=MANY,weight=0.1},
				{name="aven_albatross",min=3,max=MANY,weight=1,includeConditions={THREAT_UNDERWATER}}
			}
		},
		------------------ STAGE 3
		{
			economy = {
				minMetalIncome = 60,
				minEnergyIncome = 1500,
				metalIncome = 9999,
				energyIncome = 99999,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = true
			},
			properties = {
				commanderBuildsFactories = false,
				roamingCommander = true,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.3,
				defenseDensityMult = 2,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 0,
				mexUpgraders = 1,
				advancedDefenseBuilders = 0
			},				
			factories = {
				{name="aven_nano_tower",min=1,max=4},
				{name="aven_adv_aircraft_plant",min=1,max=2},
				{name="aven_aircraft_plant",min=1,max=1},				
				{name="aven_commander_respawner",min=2,max=2},
				{name="aven_upgrade_center",min=1,max=1},
				{name="aven_adv_vehicle_plant",min=1,max=1},
				{name="aven_scout_pad",min=1,max=1}
			},
			mobileUnits = {
				{name="aven_construction_aircraft",min=2,max=6,weight=0.2},
				{name="aven_adv_construction_aircraft",min=2,max=5,weight=0.2},
				{name="aven_falcon",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="aven_falcon",min=1,max=MANY,weight=0.2},
				{name="aven_icarus",min=1,max=MANY,weight=0.6},
				{name="aven_gale",min=1,max=MANY,weight=0.3},
				{name="aven_gryphon",min=3,max=MANY,weight=0.6},
				{name="aven_albatross",min=1,max=MANY,weight=0.1},
				{name="aven_albatross",min=3,max=MANY,weight=1,includeConditions={THREAT_UNDERWATER}}
			}
		},
		------------------ STAGE 4
		{
			economy = {
				minMetalIncome = 90,
				minEnergyIncome = 2500,
				metalIncome = 9999,
				energyIncome = 99999,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = true
			},
			properties = {
				commanderBuildsFactories = false,
				roamingCommander = true,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.3,
				defenseDensityMult = 2,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 0,
				mexUpgraders = 1,
				advancedDefenseBuilders = 1
			},				
			factories = {
				{name="aven_nano_tower",min=1,max=6},
				{name="aven_adv_aircraft_plant",min=2,max=3},
				{name="aven_aircraft_plant",min=1,max=1},				
				{name="aven_commander_respawner",min=2,max=2},
				{name="aven_upgrade_center",min=1,max=1},
				{name="aven_scout_pad",min=1,max=1},
				{name="aven_long_range_rocket_platform",min=1,max=1}
			},
			mobileUnits = {
				{name="aven_construction_aircraft",min=2,max=6,weight=0.2},
				{name="aven_adv_construction_aircraft",min=2,max=5,weight=0.2},
				{name="aven_falcon",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="aven_falcon",min=1,max=MANY,weight=0.2},
				{name="aven_icarus",min=1,max=MANY,weight=0.6},
				{name="aven_gale",min=1,max=MANY,weight=0.3},
				{name="aven_gryphon",min=3,max=MANY,weight=0.6},
				{name="aven_albatross",min=1,max=MANY,weight=0.1},
				{name="aven_albatross",min=3,max=MANY,weight=1,includeConditions={THREAT_UNDERWATER}}
			}
		},					
	}
}


avenAmphibious = {
	name = "avenAmphibious",
	commanderMorphs = { "Delta Form","Gamma Form" },
	upgrades = "offensive",
	stages = {
		------------------ STAGE 1
		{
			economy = {
				minMetalIncome = 15,
				minEnergyIncome = 200,
				metalIncome = 50,
				energyIncome = 350,
				comMorphMetalIncome = 50,		-- delay morph
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 40,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = false
			},
			properties = {
				commanderBuildsFactories = false,
				roamingCommander = true,
				raiderSpeedThreshold = 90,
				amphibiousRaiders = true,
				amphibiousMainForce = true,
				enemyThreatEstimationMult = 1.4,
				defenseDensityMult = 2,
				forceSpreadFactor = 0.7
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 0,
				mexUpgraders = 0,
				advancedDefenseBuilders = 0
			},
			factories = {
				{name="aven_nano_tower",min=1,max=1},
				{name="aven_hovercraft_platform",min=1,max=1},
				{name="aven_commander_respawner",min=1,max=1}
			},
			mobileUnits = {
				{name="aven_construction_hovercraft",min=0,max=1,weight=0.15},
				{name="aven_swatter",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="aven_skimmer",min=0,max=MANY,weight=0.3},
				{name="aven_slider",min=0,max=MANY,weight=0.3}
			}
		},
		------------------ STAGE 2
		{
			economy = {
				minMetalIncome = 30,
				minEnergyIncome = 300,
				metalIncome = 200,
				energyIncome = 5000,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = false
			},
			properties = {
				commanderBuildsFactories = false,
				roamingCommander = false,
				raiderSpeedThreshold = 90,
				amphibiousRaiders = true,
				amphibiousMainForce = true,
				enemyThreatEstimationMult = 1.3,
				defenseDensityMult = 2,
				forceSpreadFactor = 0.7
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 0,
				mexUpgraders = 1,
				advancedDefenseBuilders = 0
			},
			factories = {
				{name="aven_nano_tower",min=1,max=3},
				{name="aven_hovercraft_platform",min=1,max=1},
				{name="aven_commander_respawner",min=1,max=2},
				{name="aven_scout_pad",min=1,max=1},
				{name="aven_upgrade_center",min=1,max=1}
			},
			mobileUnits = {
				{name="aven_construction_hovercraft",min=2,max=4,weight=0.25},
				{name="aven_swatter",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="aven_skimmer",min=0,max=MANY,weight=0.3},
				{name="aven_slider",min=0,max=MANY,weight=0.6},
				{name="aven_slider_s",min=2,max=MANY,weight=1,includeConditions={THREAT_UNDERWATER}},
				{name="aven_slider_s",min=0,max=MANY,weight=0.1},
				{name="aven_swatter",min=1,max=MANY,weight=0.3},
				{name="aven_turbulence",min=0,max=MANY,weight=0.1}
			}
		},
		------------------ STAGE 3
		{
			economy = {
				minMetalIncome = 60,
				minEnergyIncome = 1500,
				metalIncome = 9999,
				energyIncome = 99999,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = true
			},
			properties = {
				commanderBuildsFactories = false,
				roamingCommander = false,
				amphibiousRaiders = true,
				amphibiousMainForce = true,
				raiderSpeedThreshold = 90,
				enemyThreatEstimationMult = 1.3,
				defenseDensityMult = 2,
				forceSpreadFactor = 0.7
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 4,
				mexUpgraders = 1,
				advancedDefenseBuilders = 0
			},				
			factories = {
				{name="aven_nano_tower",min=1,max=4},
				{name="aven_hovercraft_platform",min=1,max=2},
				{name="aven_commander_respawner",min=2,max=2},
				{name="aven_upgrade_center",min=1,max=1},
				{name="aven_adv_aircraft_plant",min=1,max=1},
				{name="aven_scout_pad",min=1,max=1}
			},
			mobileUnits = {
				{name="aven_construction_hovercraft",min=2,max=4,weight=0.25},
				{name="aven_construction_aircraft",min=2,max=4,weight=0.25},
				{name="aven_swatter",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="aven_skimmer",min=0,max=MANY,weight=0.3},
				{name="aven_slider",min=0,max=MANY,weight=0.6},
				{name="aven_slider_s",min=2,max=MANY,weight=1,includeConditions={THREAT_UNDERWATER}},
				{name="aven_slider_s",min=0,max=MANY,weight=0.1},
				{name="aven_swatter",min=1,max=MANY,weight=0.3},
				{name="aven_turbulence",min=0,max=MANY,weight=0.1},
				{name="aven_excalibur",min=0,max=MANY,weight=0.1},
				{name="aven_falcon",min=3,max=MANY,weight=0.3,includeConditions={THREAT_AIR}},
				{name="aven_albatross",min=3,max=MANY,weight=1,includeConditions={THREAT_UNDERWATER}},
				{name="aven_albatross",min=1,max=MANY,weight=0.1},
			}
		},
		------------------ STAGE 4
		{
			economy = {
				minMetalIncome = 90,
				minEnergyIncome = 2500,
				metalIncome = 9999,
				energyIncome = 99999,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = true
			},
			properties = {
				commanderBuildsFactories = false,
				roamingCommander = false,
				amphibiousRaiders = true,
				amphibiousMainForce = true,
				raiderSpeedThreshold = 90,
				enemyThreatEstimationMult = 1.3,
				defenseDensityMult = 2,
				forceSpreadFactor = 0.7
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 4,
				mexUpgraders = 1,
				advancedDefenseBuilders = 1
			},				
			factories = {
				{name="aven_nano_tower",min=1,max=6},
				{name="aven_hovercraft_platform",min=1,max=2},
				{name="aven_commander_respawner",min=2,max=2},
				{name="aven_upgrade_center",min=1,max=1},
				{name="aven_adv_aircraft_plant",min=1,max=1},
				{name="aven_scout_pad",min=1,max=1},
				{name="aven_long_range_rocket_platform",min=1,max=1}
			},
			mobileUnits = {
				{name="aven_construction_hovercraft",min=2,max=4,weight=0.3},
				{name="aven_adv_construction_aircraft",min=2,max=4,weight=0.3},
				{name="aven_swatter",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="aven_skimmer",min=0,max=MANY,weight=0.2},
				{name="aven_slider",min=0,max=MANY,weight=0.6},
				{name="aven_slider_s",min=2,max=MANY,weight=1,includeConditions={THREAT_UNDERWATER}},
				{name="aven_swatter",min=1,max=MANY,weight=0.3},
				{name="aven_tsunami",min=0,max=MANY,weight=0.2},
				{name="aven_turbulence",min=0,max=MANY,weight=0.2},
				{name="aven_excalibur",min=0,max=MANY,weight=0.1},
				{name="aven_falcon",min=3,max=MANY,weight=0.3,includeConditions={THREAT_AIR}},
				{name="aven_albatross",min=3,max=MANY,weight=1,includeConditions={THREAT_UNDERWATER}},
				{name="aven_albatross",min=1,max=MANY,weight=0.1},
				{name="aven_zephyr",min=1,max=1,weight=0.1}
			}
		},					
	}
}


--------------------------------------- GEAR


gearLandAssault = {
	name = "gearLandAssault",
	commanderMorphs = { "Blazer Form","Devastator Form","Infernal Form" },
	upgrades = "speed",
	stages = {
		------------------ STAGE 1
		{
			economy = {
				minMetalIncome = 15,
				minEnergyIncome = 200,
				metalIncome = 50,
				energyIncome = 350,
				comMorphMetalIncome = 50,		-- delay morph
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = false
			},
			properties = {
				commanderBuildsFactories = false,
				raiderSpeedThreshold = 85,
				enemyThreatEstimationMult = 1.6,
				defenseDensityMult = 1,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 0,
				mexUpgraders = 0,
				advancedDefenseBuilders = 0
			},
			factories = {
				{name="gear_nano_tower",min=1,max=1},
				{name="gear_light_plant",min=1,max=1},
				{name="gear_commander_respawner",min=1,max=1}
			},
			mobileUnits = {
				{name="gear_construction_kbot",min=1,max=6,weight=0.2},
				{name="gear_crasher",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="gear_instigator",min=0,max=MANY,weight=0.2},
				{name="gear_assaulter",min=0,max=MANY,weight=0.4},
				{name="gear_harasser",min=0,max=MANY,weight=0.15}
			}
		},
		------------------ STAGE 2
		{
			economy = {
				minMetalIncome = 30,
				minEnergyIncome = 300,
				metalIncome = 200,
				energyIncome = 5000,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = false
			},
			properties = {
				commanderBuildsFactories = false,
				raiderSpeedThreshold = 85,
				enemyThreatEstimationMult = 1.6,
				defenseDensityMult = 1,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 2,
				mexUpgraders = 1,
				advancedDefenseBuilders = 0
			},
			factories = {
				{name="gear_nano_tower",min=1,max=3},
				{name="gear_adv_vehicle_plant",min=1,max=1},
				{name="gear_light_plant",min=1,max=1},
				{name="gear_commander_respawner",min=1,max=2},
				{name="gear_scout_pad",min=1,max=1},
				{name="gear_upgrade_center",min=1,max=1}
			},
			mobileUnits = {
				{name="gear_construction_kbot",min=2,max=4,weight=0.2},
				{name="gear_adv_construction_vehicle",min=1,max=3,weight=0.2},
				{name="gear_crasher",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="gear_reaper",min=3,max=MANY,weight=0.3},
				{name="gear_thresher",min=0,max=MANY,weight=0.2},
				{name="gear_thresher",min=1,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="gear_deleter",min=1,max=1,weight=0.01},
				{name="gear_assaulter",min=0,max=MANY,weight=0.6},
				{name="gear_instigator",min=0,max=MANY,weight=0.6},
				{name="gear_harasser",min=0,max=MANY,weight=0.3}				
			}
		},
		------------------ STAGE 3
		{
			economy = {
				minMetalIncome = 60,
				minEnergyIncome = 1500,
				metalIncome = 9999,
				energyIncome = 99999,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = true
			},
			properties = {
				commanderBuildsFactories = false,
				raiderSpeedThreshold = 85,
				enemyThreatEstimationMult = 1.6,
				defenseDensityMult = 1,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 4,
				mexUpgraders = 1,
				advancedDefenseBuilders = 0
			},				
			factories = {
				{name="gear_nano_tower",min=1,max=4},
				{name="gear_adv_vehicle_plant",min=1,max=2},
				{name="gear_light_plant",min=1,max=1},				
				{name="gear_commander_respawner",min=2,max=2},
				{name="gear_upgrade_center",min=1,max=1},
				{name="gear_adv_aircraft_plant",min=1,max=1},
				{name="gear_scout_pad",min=1,max=1}
			},
			mobileUnits = {
				{name="gear_construction_kbot",min=2,max=6,weight=0.2},
				{name="gear_adv_construction_vehicle",min=2,max=6,weight=0.2},
				{name="gear_crasher",min=1,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="gear_reaper",min=3,max=MANY,weight=0.3},
				{name="gear_deleter",min=1,max=1,weight=0.01},
				{name="gear_thresher",min=1,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="gear_tremor",min=1,max=MANY,weight=0.1},
				{name="gear_thresher",min=0,max=MANY,weight=0.2},
				{name="gear_assaulter",min=0,max=MANY,weight=0.6},
				{name="gear_instigator",min=0,max=MANY,weight=0.6},
				{name="gear_vector",min=3,max=MANY,weight=0.3,includeConditions={THREAT_AIR}},
				{name="gear_whirlpool",min=3,max=MANY,weight=0.3,includeConditions={THREAT_UNDERWATER}},
				{name="gear_firestorm",min=1,max=1,weight=0.1},
				{name="gear_harasser",min=0,max=MANY,weight=0.3}				
			}
		},
		------------------ STAGE 4
		{
			economy = {
				minMetalIncome = 90,
				minEnergyIncome = 2500,
				metalIncome = 9999,
				energyIncome = 99999,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = true
			},
			properties = {
				commanderBuildsFactories = false,
				raiderSpeedThreshold = 85,
				enemyThreatEstimationMult = 1.6,
				defenseDensityMult = 1,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 4,
				mexUpgraders = 1,
				advancedDefenseBuilders = 1
			},				
			factories = {
				{name="gear_nano_tower",min=1,max=6},
				{name="gear_adv_vehicle_plant",min=1,max=2},
				{name="gear_light_plant",min=1,max=1,weight=1},				
				{name="gear_commander_respawner",min=2,max=2},
				{name="gear_upgrade_center",min=1,max=1},
				{name="gear_adv_aircraft_plant",min=1,max=1},
				{name="gear_scout_pad",min=1,max=1},
				{name="gear_long_range_rocket_platform",min=1,max=1}
			},
			mobileUnits = {
				{name="gear_construction_kbot",min=2,max=6,weight=0.2},
				{name="gear_adv_construction_vehicle",min=2,max=6,weight=0.2},
				{name="gear_adv_construction_aircraft",min=1,max=4,weight=0.2},
				{name="gear_crasher",min=1,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="gear_reaper",min=3,max=MANY,weight=0.3},
				{name="gear_deleter",min=1,max=1,weight=0.01},
				{name="gear_thresher",min=1,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="gear_tremor",min=1,max=MANY,weight=0.1},
				{name="gear_thresher",min=0,max=MANY,weight=0.2},
				{name="gear_assaulter",min=0,max=MANY,weight=0.6},
				{name="gear_instigator",min=0,max=MANY,weight=0.6},
				{name="gear_vector",min=3,max=MANY,weight=0.3,includeConditions={THREAT_AIR}},
				{name="gear_whirlpool",min=3,max=MANY,weight=0.3,includeConditions={THREAT_UNDERWATER}},								
				{name="gear_firestorm",min=1,max=1,weight=0.1},
				{name="gear_harasser",min=0,max=MANY,weight=0.3}
			}
		},					
	}
}



gearLandSkirmisher = {
	name = "gearLandSkirmisher",
	commanderMorphs = { "Dominator Form","Blazer Form" },
	upgrades = "offensive",
	stages = {
		------------------ STAGE 1
		{
			economy = {
				minMetalIncome = 15,
				minEnergyIncome = 200,
				metalIncome = 50,
				energyIncome = 350,
				comMorphMetalIncome = 50,		-- delay morph
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = false
			},
			properties = {
				commanderBuildsFactories = false,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.2,
				defenseDensityMult = 1,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 0,
				mexUpgraders = 0,
				advancedDefenseBuilders = 0
			},
			factories = {
				{name="gear_nano_tower",min=1,max=1},
				{name="gear_light_plant",min=1,max=1},
				{name="gear_commander_respawner",min=1,max=1}
			},
			mobileUnits = {
				{name="gear_construction_kbot",min=1,max=6,weight=0.2},
				{name="gear_harasser",min=0,max=MANY,weight=0.2},
				{name="gear_box",min=0,max=MANY,weight=0.5,includeConditions={THREAT_AIR}},
				{name="gear_kano",min=0,max=MANY,weight=1,includeConditions={THREAT_ASSAULT}},
				{name="gear_crasher",min=0,max=MANY,weight=0.6},
				{name="gear_thud",min=0,max=MANY,weight=0.3}
			}
		},
		------------------ STAGE 2
		{
			economy = {
				minMetalIncome = 30,
				minEnergyIncome = 300,
				metalIncome = 200,
				energyIncome = 5000,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = false
			},
			properties = {
				commanderBuildsFactories = false,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.2,
				defenseDensityMult = 1,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 2,
				mexUpgraders = 1,
				advancedDefenseBuilders = 0
			},
			factories = {
				{name="gear_nano_tower",min=1,max=3},
				{name="gear_adv_kbot_lab",min=1,max=1},
				{name="gear_light_plant",min=1,max=1},
				{name="gear_commander_respawner",min=1,max=2},
				{name="gear_scout_pad",min=1,max=1},
				{name="gear_upgrade_center",min=1,max=1}
			},
			mobileUnits = {
				{name="gear_construction_kbot",min=2,max=4,weight=0.2},
				{name="gear_adv_construction_kbot",min=1,max=3,weight=0.2},
				{name="gear_box",min=0,max=MANY,weight=0.6,includeConditions={THREAT_AIR}},
				{name="gear_cube",min=0,max=MANY,weight=1,includeConditions={THREAT_ASSAULT}},
				{name="gear_barrel",min=3,max=MANY,weight=0.4},
				{name="gear_moe",min=3,max=MANY,weight=0.4},
				{name="gear_big_bob",min=3,max=MANY,weight=0.3},
				{name="gear_spectre",min=1,max=1,weight=0.01},
				{name="gear_voyeur",min=1,max=1,weight=0.01},
				{name="gear_crasher",min=0,max=MANY,weight=0.3},
				{name="gear_thud",min=0,max=MANY,weight=0.3},
				{name="gear_harasser",min=0,max=MANY,weight=0.2},
				{name="gear_psycho",min=0,max=MANY,weight=0.2}
			}
		},
		------------------ STAGE 3
		{
			economy = {
				minMetalIncome = 60,
				minEnergyIncome = 1500,
				metalIncome = 9999,
				energyIncome = 99999,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = true
			},
			properties = {
				commanderBuildsFactories = false,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.2,
				defenseDensityMult = 1,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 4,
				mexUpgraders = 1,
				advancedDefenseBuilders = 0
			},				
			factories = {
				{name="gear_nano_tower",min=1,max=4},
				{name="gear_adv_kbot_lab",min=1,max=2},
				{name="gear_light_plant",min=1,max=1},				
				{name="gear_commander_respawner",min=2,max=2},
				{name="gear_upgrade_center",min=1,max=1},
				{name="gear_adv_vehicle_plant",min=1,max=1},
				{name="gear_scout_pad",min=1,max=1}
			},
			mobileUnits = {
				{name="gear_construction_kbot",min=2,max=6,weight=0.2},
				{name="gear_adv_construction_kbot",min=2,max=3,weight=0.2},
				{name="gear_adv_construction_vehicle",min=2,max=3,weight=0.2},
				{name="gear_box",min=0,max=MANY,weight=0.6,includeConditions={THREAT_AIR}},
				{name="gear_cube",min=0,max=MANY,weight=1,includeConditions={THREAT_ASSAULT}},
				{name="gear_barrel",min=3,max=MANY,weight=0.4},
				{name="gear_moe",min=3,max=MANY,weight=0.4},
				{name="gear_big_bob",min=3,max=MANY,weight=0.3},
				{name="gear_spectre",min=1,max=1,weight=0.01},
				{name="gear_voyeur",min=1,max=1,weight=0.01},
				{name="gear_luminator",min=0,max=MANY,weight=0.1},
				{name="gear_eruptor",min=0,max=MANY,weight=0.3},
				{name="gear_mobile_artillery",min=0,max=MANY,weight=0.3},
				{name="gear_crasher",min=0,max=MANY,weight=0.3},
				{name="gear_harasser",min=0,max=MANY,weight=0.2},
				{name="gear_psycho",min=0,max=MANY,weight=0.2}
			}
		},
		------------------ STAGE 4
		{
			economy = {
				minMetalIncome = 90,
				minEnergyIncome = 2500,
				metalIncome = 9999,
				energyIncome = 99999,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = true
			},
			properties = {
				commanderBuildsFactories = false,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.2,
				defenseDensityMult = 1,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 4,
				mexUpgraders = 1,
				advancedDefenseBuilders = 1
			},				
			factories = {
				{name="gear_nano_tower",min=1,max=6},
				{name="gear_adv_kbot_lab",min=1,max=2},
				{name="gear_adv_vehicle_plant",min=1,max=2},
				{name="gear_light_plant",min=1,max=1},				
				{name="gear_commander_respawner",min=2,max=2},
				{name="gear_upgrade_center",min=1,max=1},
				{name="gear_adv_aircraft_plant",min=1,max=1},
				{name="gear_scout_pad",min=1,max=1},
				{name="gear_long_range_rocket_platform",min=1,max=1}
			},
			mobileUnits = {
				{name="gear_construction_kbot",min=2,max=6,weight=0.2},
				{name="gear_adv_construction_kbot",min=1,max=3,weight=0.15},
				{name="gear_adv_construction_vehicle",min=2,max=3,weight=0.2},
				{name="gear_adv_construction_aircraft",min=2,max=3,weight=0.2},
				{name="gear_box",min=0,max=MANY,weight=0.6,includeConditions={THREAT_AIR}},
				{name="gear_cube",min=0,max=MANY,weight=1,includeConditions={THREAT_ASSAULT}},				
				{name="gear_barrel",min=3,max=MANY,weight=0.4},
				{name="gear_moe",min=3,max=MANY,weight=0.4},
				{name="gear_big_bob",min=3,max=MANY,weight=0.3},
				{name="gear_spectre",min=1,max=1,weight=0.01},
				{name="gear_voyeur",min=1,max=1,weight=0.01},
				{name="gear_luminator",min=0,max=MANY,weight=0.1},
				{name="gear_eruptor",min=0,max=MANY,weight=0.3},
				{name="gear_mobile_artillery",min=0,max=MANY,weight=0.3},
				{name="gear_crasher",min=0,max=MANY,weight=0.3},
				{name="gear_harasser",min=0,max=MANY,weight=0.2},
				{name="gear_psycho",min=0,max=MANY,weight=0.2},
				{name="gear_zoomer",min=1,max=2,weight=0.02},
				{name="gear_vector",min=3,max=MANY,weight=0.3,includeConditions={THREAT_AIR}},
				{name="gear_whirlpool",min=3,max=MANY,weight=1,includeConditions={THREAT_UNDERWATER}}
			}
		},					
	}
}



gearAir = {
	name = "gearAir",
	commanderMorphs = { "Devastator Form","Builder Form","Infernal Form" },
	upgrades = "defensive",
	stages = {
		------------------ STAGE 1
		{
			economy = {
				minMetalIncome = 15,
				minEnergyIncome = 200,
				metalIncome = 50,
				energyIncome = 350,
				comMorphMetalIncome = 50,		-- delay morph
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = false
			},
			properties = {
				commanderBuildsFactories = false,
				roamingCommander = true,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.3,
				defenseDensityMult = 2,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 0,
				mexUpgraders = 0,
				advancedDefenseBuilders = 0
			},
			factories = {
				{name="gear_nano_tower",min=1,max=1},
				{name="gear_aircraft_plant",min=1,max=1},
				{name="gear_commander_respawner",min=1,max=1}
			},
			mobileUnits = {
				{name="gear_construction_aircraft",min=1,max=6,weight=0.2},
				{name="gear_zipper",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="gear_dash",min=0,max=MANY,weight=0.6},
				{name="gear_zipper",min=0,max=MANY,weight=0.6},
				{name="gear_knocker",min=0,max=MANY,weight=0.3}
			}
		},
		------------------ STAGE 2
		{
			economy = {
				minMetalIncome = 30,
				minEnergyIncome = 300,
				metalIncome = 200,
				energyIncome = 5000,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = false
			},
			properties = {
				commanderBuildsFactories = false,
				roamingCommander = true,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.3,
				defenseDensityMult = 2,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 0,
				mexUpgraders = 1,
				advancedDefenseBuilders = 0
			},
			factories = {
				{name="gear_nano_tower",min=1,max=3},
				{name="gear_adv_aircraft_plant",min=1,max=1},
				{name="gear_aircraft_plant",min=1,max=1},
				{name="gear_commander_respawner",min=1,max=2},
				{name="gear_scout_pad",min=1,max=1},
				{name="gear_upgrade_center",min=1,max=1}
			},
			mobileUnits = {
				{name="gear_construction_aircraft",min=2,max=4,weight=0.2},
				{name="gear_adv_construction_aircraft",min=1,max=3,weight=0.2},
				{name="gear_vector",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="gear_vector",min=1,max=MANY,weight=0.2},
				{name="gear_stratos",min=1,max=MANY,weight=0.3},
				{name="gear_firestorm",min=1,max=MANY,weight=0.3},
				{name="gear_whirlpool",min=1,max=MANY,weight=0.1},
				{name="gear_whirlpool",min=3,max=MANY,weight=1,includeConditions={THREAT_UNDERWATER}}
			}
		},
		------------------ STAGE 3
		{
			economy = {
				minMetalIncome = 60,
				minEnergyIncome = 1500,
				metalIncome = 9999,
				energyIncome = 99999,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = true
			},
			properties = {
				commanderBuildsFactories = false,
				roamingCommander = true,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.3,
				defenseDensityMult = 2,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 0,
				mexUpgraders = 1,
				advancedDefenseBuilders = 0
			},				
			factories = {
				{name="gear_nano_tower",min=1,max=4},
				{name="gear_adv_aircraft_plant",min=1,max=2},
				{name="gear_aircraft_plant",min=1,max=1},				
				{name="gear_commander_respawner",min=2,max=2},
				{name="gear_upgrade_center",min=1,max=1},
				{name="gear_adv_vehicle_plant",min=1,max=1},
				{name="gear_scout_pad",min=1,max=1}
			},
			mobileUnits = {
				{name="gear_construction_aircraft",min=2,max=6,weight=0.2},
				{name="gear_adv_construction_aircraft",min=2,max=5,weight=0.2},
				{name="gear_vector",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="gear_vector",min=1,max=MANY,weight=0.2},
				{name="gear_stratos",min=1,max=MANY,weight=0.6},
				{name="gear_firestorm",min=1,max=MANY,weight=0.3},
				{name="gear_whirlpool",min=1,max=MANY,weight=0.1},
				{name="gear_whirlpool",min=3,max=MANY,weight=1,includeConditions={THREAT_UNDERWATER}}
			}
		},
		------------------ STAGE 4
		{
			economy = {
				minMetalIncome = 90,
				minEnergyIncome = 2500,
				metalIncome = 9999,
				energyIncome = 99999,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = true
			},
			properties = {
				commanderBuildsFactories = false,
				roamingCommander = true,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.3,
				defenseDensityMult = 2,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 0,
				mexUpgraders = 1,
				advancedDefenseBuilders = 1
			},				
			factories = {
				{name="gear_nano_tower",min=1,max=6},
				{name="gear_adv_aircraft_plant",min=2,max=3},
				{name="gear_aircraft_plant",min=1,max=1},				
				{name="gear_commander_respawner",min=2,max=2},
				{name="gear_upgrade_center",min=1,max=1},
				{name="gear_scout_pad",min=1,max=1},
				{name="gear_long_range_rocket_platform",min=1,max=1}
			},
			mobileUnits = {
				{name="gear_construction_aircraft",min=2,max=6,weight=0.2},
				{name="gear_adv_construction_aircraft",min=2,max=5,weight=0.2},
				{name="gear_vector",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="gear_vector",min=1,max=MANY,weight=0.2},
				{name="gear_stratos",min=1,max=MANY,weight=0.6},
				{name="gear_firestorm",min=1,max=MANY,weight=0.3},
				{name="gear_whirlpool",min=1,max=MANY,weight=0.1},
				{name="gear_whirlpool",min=3,max=MANY,weight=1,includeConditions={THREAT_UNDERWATER}}
			}
		},					
	}
}


gearAmphibious = {
	name = "gearAmphibious",
	commanderMorphs = { "Blazer Form","Devastator Form" },
	upgrades = "offensive",
	stages = {
		------------------ STAGE 1
		{
			economy = {
				minMetalIncome = 15,
				minEnergyIncome = 200,
				metalIncome = 50,
				energyIncome = 350,
				comMorphMetalIncome = 50,		-- delay morph
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 40,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = false
			},
			properties = {
				commanderBuildsFactories = false,
				roamingCommander = true,
				raiderSpeedThreshold = 75,
				amphibiousRaiders = true,
				amphibiousMainForce = true,
				enemyThreatEstimationMult = 1.4,
				defenseDensityMult = 2,
				forceSpreadFactor = 0.7
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 0,
				mexUpgraders = 0,
				advancedDefenseBuilders = 0
			},
			factories = {
				{name="gear_nano_tower",min=1,max=1},
				{name="gear_aircraft_plant",min=1,max=1},
				{name="gear_commander_respawner",min=1,max=1}
			},
			mobileUnits = {
				{name="gear_construction_aircraft",min=1,max=2,weight=0.2},
				{name="gear_zipper",min=0,max=MANY,weight=0.6},
				{name="gear_knocker",min=0,max=MANY,weight=0.3}
			}
		},
		------------------ STAGE 2
		{
			economy = {
				minMetalIncome = 25,
				minEnergyIncome = 250,
				metalIncome = 200,
				energyIncome = 5000,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = false
			},
			properties = {
				commanderBuildsFactories = false,
				roamingCommander = false,
				raiderSpeedThreshold = 75,
				amphibiousRaiders = true,
				amphibiousMainForce = true,
				enemyThreatEstimationMult = 1.4,
				defenseDensityMult = 2,
				forceSpreadFactor = 0.7
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 0,
				mexUpgraders = 1,
				advancedDefenseBuilders = 0
			},
			factories = {
				{name="gear_nano_tower",min=1,max=3},
				{name="gear_adv_aircraft_plant",min=1,max=1},
				{name="gear_adv_shipyard",min=1,max=1,includeConditions={CONDITION_WATER}},
				{name="gear_adv_vehicle_plant",min=1,max=1,excludeConditions={CONDITION_WATER}},
				{name="gear_commander_respawner",min=1,max=2},
				{name="gear_upgrade_center",min=1,max=1},
				{name="gear_scout_pad",min=1,max=1}
			},
			mobileUnits = {
				{name="gear_construction_aircraft",min=1,max=4,weight=0.2},
				{name="gear_adv_construction_aircraft",min=1,max=4,weight=0.2},
				{name="gear_proteus",min=1,max=MANY,weight=0.4},
				{name="gear_vector",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="gear_whirlpool",min=2,max=MANY,weight=1,includeConditions={THREAT_UNDERWATER}},
				{name="gear_stratos",min=1,max=MANY,weight=0.2}
			}
		},
		------------------ STAGE 3
		{
			economy = {
				minMetalIncome = 60,
				minEnergyIncome = 1500,
				metalIncome = 9999,
				energyIncome = 99999,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = true
			},
			properties = {
				commanderBuildsFactories = false,
				roamingCommander = false,
				amphibiousRaiders = true,
				amphibiousMainForce = true,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.4,
				defenseDensityMult = 2,
				forceSpreadFactor = 0.7
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 1,
				mexUpgraders = 1,
				advancedDefenseBuilders = 0
			},				
			factories = {
				{name="gear_nano_tower",min=1,max=4},
				{name="gear_adv_aircraft_plant",min=1,max=2},
				{name="gear_adv_shipyard",min=1,max=2,includeConditions={CONDITION_WATER}},
				{name="gear_adv_vehicle_plant",min=1,max=1,excludeConditions={CONDITION_WATER}},
				{name="gear_commander_respawner",min=1,max=2},
				{name="gear_upgrade_center",min=1,max=1},
				{name="gear_scout_pad",min=1,max=1}
			},
			mobileUnits = {
				{name="gear_construction_aircraft",min=2,max=4,weight=0.2},
				{name="gear_adv_construction_aircraft",min=2,max=4,weight=0.2},
				{name="gear_proteus",min=1,max=MANY,weight=0.4},
				{name="gear_vector",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="gear_whirlpool",min=2,max=MANY,weight=1,includeConditions={THREAT_UNDERWATER}},
				{name="gear_stratos",min=1,max=MANY,weight=0.4}
			}
		},
		------------------ STAGE 4
		{
			economy = {
				minMetalIncome = 90,
				minEnergyIncome = 2500,
				metalIncome = 9999,
				energyIncome = 99999,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = true
			},
			properties = {
				commanderBuildsFactories = false,
				roamingCommander = false,
				amphibiousRaiders = true,
				amphibiousMainForce = true,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.4,
				defenseDensityMult = 2,
				forceSpreadFactor = 0.7
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 4,
				mexUpgraders = 1,
				advancedDefenseBuilders = 1
			},				
			factories = {
				{name="gear_nano_tower",min=1,max=5},
				{name="gear_adv_aircraft_plant",min=1,max=2},
				{name="gear_commander_respawner",min=2,max=2},
				{name="gear_upgrade_center",min=1,max=1},
				{name="gear_adv_shipyard",min=1,max=2,includeConditions={CONDITION_WATER}},
				{name="gear_adv_vehicle_plant",min=1,max=1,excludeConditions={CONDITION_WATER}},
				{name="gear_long_range_rocket_platform",min=1,max=1},
				{name="gear_scout_pad",min=1,max=1}
			},
			mobileUnits = {
				{name="gear_construction_aircraft",min=2,max=4,weight=0.2},
				{name="gear_adv_construction_aircraft",min=2,max=4,weight=0.2},
				{name="gear_proteus",min=1,max=MANY,weight=0.4},
				{name="gear_vector",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="gear_whirlpool",min=2,max=MANY,weight=1,includeConditions={THREAT_UNDERWATER}},
				{name="gear_stratos",min=1,max=MANY,weight=0.4}
			}
		},	
	}
}


--------------------------------------- CLAW


clawLandAssault = {
	name = "clawLandAssault",
	commanderMorphs = { "Brawler Form","Grinder Form","Assassin Form" },
	upgrades = "speed",
	stages = {
		------------------ STAGE 1
		{
			economy = {
				minMetalIncome = 15,
				minEnergyIncome = 200,
				metalIncome = 50,
				energyIncome = 350,
				comMorphMetalIncome = 50,		-- delay morph
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = false
			},
			properties = {
				commanderBuildsFactories = false,
				raiderSpeedThreshold = 78,
				enemyThreatEstimationMult = 1.6,
				defenseDensityMult = 1,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 0,
				mexUpgraders = 0,
				advancedDefenseBuilders = 0
			},
			factories = {
				{name="claw_nano_tower",min=1,max=1},
				{name="claw_light_plant",min=1,max=1},
				{name="claw_commander_respawner",min=1,max=1}
			},
			mobileUnits = {
				{name="claw_construction_kbot",min=1,max=6,weight=0.1},
				{name="claw_grunt",min=0,max=MANY,weight=0.7,includeConditions={THREAT_AIR}},
				{name="claw_jester",min=0,max=MANY,weight=0.7,includeConditions={THREAT_AIR}},
				{name="claw_grunt",min=0,max=MANY,weight=0.2},
				{name="claw_piston",min=0,max=MANY,weight=0.2},
				{name="claw_boar",min=0,max=MANY,weight=0.4},
				{name="claw_knife",min=0,max=MANY,weight=0.2}
			}
		},
		------------------ STAGE 2
		{
			economy = {
				minMetalIncome = 30,
				minEnergyIncome = 300,
				metalIncome = 200,
				energyIncome = 5000,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = false
			},
			properties = {
				commanderBuildsFactories = false,
				raiderSpeedThreshold = 78,
				enemyThreatEstimationMult = 1.6,
				defenseDensityMult = 1,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 2,
				mexUpgraders = 1,
				advancedDefenseBuilders = 0
			},
			factories = {
				{name="claw_nano_tower",min=1,max=3},
				{name="claw_adv_vehicle_plant",min=1,max=1},
				{name="claw_light_plant",min=1,max=1},
				{name="claw_commander_respawner",min=1,max=2},
				{name="claw_scout_pad",min=1,max=1},
				{name="claw_upgrade_center",min=1,max=1}
			},
			mobileUnits = {
				{name="claw_construction_kbot",min=2,max=4,weight=0.1},
				{name="claw_adv_construction_vehicle",min=1,max=3,weight=0.1},
				{name="claw_jester",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="claw_armadon",min=3,max=MANY,weight=0.3},
				{name="claw_ravager",min=1,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="claw_ravager",min=0,max=MANY,weight=0.4},
				{name="claw_jammer",min=1,max=1,weight=0.01},
				{name="claw_boar",min=0,max=MANY,weight=0.6},
				{name="claw_knife",min=0,max=MANY,weight=0.3}
			}
		},
		------------------ STAGE 3
		{
			economy = {
				minMetalIncome = 60,
				minEnergyIncome = 1500,
				metalIncome = 9999,
				energyIncome = 99999,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = true
			},
			properties = {
				commanderBuildsFactories = false,
				raiderSpeedThreshold = 78,
				enemyThreatEstimationMult = 1.6,
				defenseDensityMult = 1,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 4,
				mexUpgraders = 1,
				advancedDefenseBuilders = 0
			},				
			factories = {
				{name="claw_nano_tower",min=1,max=3},
				{name="claw_adv_vehicle_plant",min=1,max=2},
				{name="claw_light_plant",min=1,max=1},				
				{name="claw_commander_respawner",min=2,max=2},
				{name="claw_upgrade_center",min=1,max=1},
				{name="claw_adv_aircraft_plant",min=1,max=1},
				{name="claw_scout_pad",min=1,max=1}
			},
			mobileUnits = {
				{name="claw_construction_kbot",min=2,max=6,weight=0.1},
				{name="claw_adv_construction_vehicle",min=2,max=6,weight=0.1},
				{name="claw_jester",min=1,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="claw_armadon",min=3,max=MANY,weight=0.3},
				{name="claw_jammer",min=1,max=1,weight=0.01},
				{name="claw_ravager",min=1,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="claw_mega",min=1,max=MANY,weight=0.1},
				{name="claw_ravager",min=0,max=MANY,weight=0.2},
				{name="claw_boar",min=0,max=MANY,weight=0.6},
				{name="claw_grunt",min=0,max=MANY,weight=0.6},
				{name="claw_x",min=3,max=MANY,weight=0.3,includeConditions={THREAT_AIR}},
				{name="claw_trident",min=3,max=MANY,weight=0.3,includeConditions={THREAT_UNDERWATER}},
				{name="claw_havoc",min=1,max=1,weight=0.1},
				{name="claw_knife",min=0,max=MANY,weight=0.3}
			}
		},
		------------------ STAGE 4
		{
			economy = {
				minMetalIncome = 90,
				minEnergyIncome = 2500,
				metalIncome = 9999,
				energyIncome = 99999,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = true
			},
			properties = {
				commanderBuildsFactories = false,
				raiderSpeedThreshold = 78,
				enemyThreatEstimationMult = 1.6,
				defenseDensityMult = 1,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 4,
				mexUpgraders = 1,
				advancedDefenseBuilders = 1
			},				
			factories = {
				{name="claw_nano_tower",min=1,max=3},
				{name="claw_adv_vehicle_plant",min=1,max=2},
				{name="claw_light_plant",min=1,max=1,weight=1},				
				{name="claw_commander_respawner",min=2,max=2},
				{name="claw_upgrade_center",min=1,max=1},
				{name="claw_adv_aircraft_plant",min=1,max=1},
				{name="claw_scout_pad",min=1,max=1},
				{name="claw_long_range_rocket_platform",min=1,max=1}
			},
			mobileUnits = {
				{name="claw_construction_kbot",min=2,max=6,weight=0.1},
				{name="claw_adv_construction_vehicle",min=2,max=6,weight=0.1},
				{name="claw_jester",min=1,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="claw_armadon",min=3,max=MANY,weight=0.3},
				{name="claw_jammer",min=1,max=1,weight=0.01},
				{name="claw_ravager",min=1,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="claw_mega",min=1,max=MANY,weight=0.1},
				{name="claw_ravager",min=0,max=MANY,weight=0.6},
				{name="claw_boar",min=0,max=MANY,weight=0.6},
				{name="claw_x",min=3,max=MANY,weight=0.3,includeConditions={THREAT_AIR}},
				{name="claw_trident",min=3,max=MANY,weight=0.3,includeConditions={THREAT_UNDERWATER}},								
				{name="claw_havoc",min=1,max=1,weight=0.1},
				{name="claw_knife",min=0,max=MANY,weight=0.4}
			}
		},					
	}
}



clawLandSkirmisher = {
	name = "clawLandSkirmisher",
	commanderMorphs = { "Aggressor Form","Assassin Form" },
	upgrades = "offensive",
	stages = {
		------------------ STAGE 1
		{
			economy = {
				minMetalIncome = 15,
				minEnergyIncome = 200,
				metalIncome = 50,
				energyIncome = 350,
				comMorphMetalIncome = 50,		-- delay morph
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = false
			},
			properties = {
				commanderBuildsFactories = false,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.2,
				defenseDensityMult = 1,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 0,
				mexUpgraders = 0,
				advancedDefenseBuilders = 0
			},
			factories = {
				{name="claw_nano_tower",min=1,max=1},
				{name="claw_light_plant",min=1,max=1},
				{name="claw_commander_respawner",min=1,max=1}
			},
			mobileUnits = {
				{name="claw_construction_kbot",min=1,max=6,weight=0.2},
				{name="claw_knife",min=0,max=MANY,weight=0.2},
				{name="claw_grunt",min=0,max=MANY,weight=0.5,includeConditions={THREAT_AIR}},
				{name="claw_jester",min=0,max=MANY,weight=0.6},
				{name="claw_roller",min=0,max=MANY,weight=0.3},
				{name="claw_piston",min=0,max=MANY,weight=1,includeConditions={THREAT_ASSAULT}},				
				{name="claw_piston",min=0,max=MANY,weight=0.3}
			}
		},
		------------------ STAGE 2
		{
			economy = {
				minMetalIncome = 30,
				minEnergyIncome = 300,
				metalIncome = 200,
				energyIncome = 5000,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = false
			},
			properties = {
				commanderBuildsFactories = false,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.2,
				defenseDensityMult = 1,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 2,
				mexUpgraders = 1,
				advancedDefenseBuilders = 0
			},
			factories = {
				{name="claw_nano_tower",min=1,max=3},
				{name="claw_adv_kbot_plant",min=1,max=1},
				{name="claw_light_plant",min=1,max=1},
				{name="claw_commander_respawner",min=1,max=1},
				{name="claw_scout_pad",min=1,max=1},
				{name="claw_upgrade_center",min=1,max=1}
			},
			mobileUnits = {
				{name="claw_construction_kbot",min=2,max=4,weight=0.2},
				{name="claw_adv_construction_kbot",min=1,max=3,weight=0.2},
				{name="claw_grunt",min=0,max=MANY,weight=0.6,includeConditions={THREAT_AIR}},
				{name="claw_brute",min=0,max=MANY,weight=1,includeConditions={THREAT_ASSAULT}},				
				{name="claw_bishop",min=3,max=MANY,weight=0.4},
				{name="claw_crawler",min=3,max=MANY,weight=0.4},
				{name="claw_shrieker",min=3,max=MANY,weight=0.3},
				{name="claw_shade",min=1,max=1,weight=0.01},
				{name="claw_revealer",min=1,max=1,weight=0.01},
				{name="claw_jester",min=0,max=MANY,weight=0.3},
				{name="claw_ringo",min=0,max=MANY,weight=0.2},
				{name="claw_centaur",min=0,max=MANY,weight=0.2}
			}
		},
		------------------ STAGE 3
		{
			economy = {
				minMetalIncome = 60,
				minEnergyIncome = 1500,
				metalIncome = 9999,
				energyIncome = 99999,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = true
			},
			properties = {
				commanderBuildsFactories = false,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.2,
				defenseDensityMult = 1,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 4,
				mexUpgraders = 1,
				advancedDefenseBuilders = 0
			},				
			factories = {
				{name="claw_nano_tower",min=1,max=4},
				{name="claw_adv_kbot_plant",min=1,max=2},
				{name="claw_light_plant",min=1,max=1},				
				{name="claw_commander_respawner",min=2,max=2},
				{name="claw_upgrade_center",min=1,max=1},
				{name="claw_adv_vehicle_plant",min=1,max=1},
				{name="claw_scout_pad",min=1,max=1}
			},
			mobileUnits = {
				{name="claw_construction_kbot",min=2,max=6,weight=0.2},
				{name="claw_adv_construction_kbot",min=2,max=3,weight=0.2},
				{name="claw_adv_construction_vehicle",min=2,max=3,weight=0.2},
				{name="claw_brute",min=0,max=MANY,weight=0.6,includeConditions={THREAT_AIR}},
				{name="claw_brute",min=0,max=MANY,weight=1,includeConditions={THREAT_ASSAULT}},				
				{name="claw_bishop",min=3,max=MANY,weight=0.4},
				{name="claw_crawler",min=3,max=MANY,weight=0.4},
				{name="claw_shrieker",min=3,max=MANY,weight=0.3},
				{name="claw_shade",min=1,max=1,weight=0.01},
				{name="claw_revealer",min=1,max=1,weight=0.01},
				{name="claw_dynamo",min=0,max=MANY,weight=0.1},
				{name="claw_pounder",min=0,max=MANY,weight=0.3},
				{name="claw_jester",min=0,max=MANY,weight=0.3},
				{name="claw_ringo",min=0,max=MANY,weight=0.2},
				{name="claw_centaur",min=0,max=MANY,weight=0.2}
			}
		},
		------------------ STAGE 4
		{
			economy = {
				minMetalIncome = 90,
				minEnergyIncome = 2500,
				metalIncome = 9999,
				energyIncome = 99999,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = true
			},
			properties = {
				commanderBuildsFactories = false,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.2,
				defenseDensityMult = 1,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 4,
				mexUpgraders = 1,
				advancedDefenseBuilders = 1
			},				
			factories = {
				{name="claw_nano_tower",min=1,max=6},
				{name="claw_adv_kbot_plant",min=1,max=2},
				{name="claw_adv_vehicle_plant",min=1,max=2},
				{name="claw_light_plant",min=1,max=1},				
				{name="claw_commander_respawner",min=2,max=2},
				{name="claw_upgrade_center",min=1,max=1},
				{name="claw_adv_aircraft_plant",min=1,max=1},
				{name="claw_scout_pad",min=1,max=1},
				{name="claw_long_range_rocket_platform",min=1,max=1}
			},
			mobileUnits = {
				{name="claw_construction_kbot",min=2,max=6,weight=0.2},
				{name="claw_adv_construction_kbot",min=2,max=3,weight=0.2},
				{name="claw_adv_construction_vehicle",min=2,max=3,weight=0.2},
				{name="claw_brute",min=0,max=MANY,weight=0.6,includeConditions={THREAT_AIR}},
				{name="claw_armadon",min=0,max=MANY,weight=1,includeConditions={THREAT_ASSAULT}},
				{name="claw_bishop",min=3,max=MANY,weight=0.4},
				{name="claw_crawler",min=3,max=MANY,weight=0.4},
				{name="claw_shrieker",min=3,max=MANY,weight=0.3},
				{name="claw_shade",min=1,max=1,weight=0.01},
				{name="claw_revealer",min=1,max=1,weight=0.01},
				{name="claw_dynamo",min=0,max=MANY,weight=0.1},
				{name="claw_pounder",min=0,max=MANY,weight=0.3},
				{name="claw_jester",min=0,max=MANY,weight=0.3},
				{name="claw_ringo",min=0,max=MANY,weight=0.2},
				{name="claw_centaur",min=0,max=MANY,weight=0.2},
				{name="claw_lensor",min=1,max=2,weight=0.02},
				{name="claw_x",min=3,max=MANY,weight=0.3,includeConditions={THREAT_AIR}},
				{name="claw_trident",min=3,max=MANY,weight=1,includeConditions={THREAT_UNDERWATER}},
				{name="claw_trident",min=0,max=MANY,weight=0.1},
			}
		},					
	}
}



clawAir = {
	name = "clawAir",
	commanderMorphs = { "Aggressor Form","Brawler Form" },
	upgrades = "defensive",
	stages = {
		------------------ STAGE 1
		{
			economy = {
				minMetalIncome = 15,
				minEnergyIncome = 200,
				metalIncome = 50,
				energyIncome = 350,
				comMorphMetalIncome = 50,		-- delay morph
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = false
			},
			properties = {
				commanderBuildsFactories = false,
				roamingCommander = true,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.3,
				defenseDensityMult = 1,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 0,
				mexUpgraders = 0,
				advancedDefenseBuilders = 0
			},
			factories = {
				{name="claw_nano_tower",min=1,max=1},
				{name="claw_aircraft_plant",min=1,max=1},
				{name="claw_commander_respawner",min=1,max=1}
			},
			mobileUnits = {
				{name="claw_construction_aircraft",min=1,max=6,weight=0.2},
				{name="claw_hornet",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="claw_shredder",min=0,max=MANY,weight=0.6},
				{name="claw_boomer_m",min=0,max=MANY,weight=0.6}
			}
		},
		------------------ STAGE 2
		{
			economy = {
				minMetalIncome = 30,
				minEnergyIncome = 300,
				metalIncome = 200,
				energyIncome = 5000,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = false
			},
			properties = {
				commanderBuildsFactories = false,
				roamingCommander = true,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.3,
				defenseDensityMult = 1,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 0,
				mexUpgraders = 1,
				advancedDefenseBuilders = 0
			},
			factories = {
				{name="claw_nano_tower",min=1,max=3},
				{name="claw_adv_aircraft_plant",min=1,max=1},
				{name="claw_aircraft_plant",min=1,max=1},
				{name="claw_commander_respawner",min=1,max=2},
				{name="claw_scout_pad",min=1,max=1},
				{name="claw_upgrade_center",min=1,max=1}
			},
			mobileUnits = {
				{name="claw_construction_aircraft",min=2,max=4,weight=0.2},
				{name="claw_adv_construction_aircraft",min=1,max=3,weight=0.2},
				{name="claw_x",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="claw_x",min=1,max=MANY,weight=0.2},
				{name="claw_havoc",min=1,max=MANY,weight=0.3},
				{name="claw_blizzard",min=1,max=MANY,weight=0.3},
				{name="claw_shredder",min=1,max=MANY,weight=0.6},
				{name="claw_trident",min=3,max=MANY,weight=1,includeConditions={THREAT_UNDERWATER}},
				{name="claw_trident",min=1,max=MANY,weight=0.1}
			}
		},
		------------------ STAGE 3
		{
			economy = {
				minMetalIncome = 60,
				minEnergyIncome = 1500,
				metalIncome = 9999,
				energyIncome = 99999,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = true
			},
			properties = {
				commanderBuildsFactories = false,
				roamingCommander = true,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.3,
				defenseDensityMult = 1,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 0,
				mexUpgraders = 1,
				advancedDefenseBuilders = 0
			},				
			factories = {
				{name="claw_nano_tower",min=1,max=4},
				{name="claw_adv_aircraft_plant",min=1,max=2},
				{name="claw_aircraft_plant",min=1,max=1},				
				{name="claw_commander_respawner",min=2,max=2},
				{name="claw_upgrade_center",min=1,max=1},
				{name="claw_adv_vehicle_plant",min=1,max=1},
				{name="claw_scout_pad",min=1,max=1}
			},
			mobileUnits = {
				{name="claw_construction_aircraft",min=2,max=6,weight=0.2},
				{name="claw_adv_construction_aircraft",min=2,max=5,weight=0.2},
				{name="claw_x",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="claw_x",min=1,max=MANY,weight=0.2},
				{name="claw_havoc",min=1,max=MANY,weight=0.6},
				{name="claw_blizzard",min=1,max=MANY,weight=0.3},
				{name="claw_shredder",min=1,max=MANY,weight=0.6},
				{name="claw_trident",min=3,max=MANY,weight=1,includeConditions={THREAT_UNDERWATER}},
				{name="claw_trident",min=1,max=MANY,weight=0.1}
			}
		},
		------------------ STAGE 4
		{
			economy = {
				minMetalIncome = 90,
				minEnergyIncome = 2500,
				metalIncome = 9999,
				energyIncome = 99999,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = true
			},
			properties = {
				commanderBuildsFactories = false,
				roamingCommander = true,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.3,
				defenseDensityMult = 1,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 0,
				mexUpgraders = 1,
				advancedDefenseBuilders = 1
			},				
			factories = {
				{name="claw_nano_tower",min=1,max=6},
				{name="claw_adv_aircraft_plant",min=2,max=3},
				{name="claw_aircraft_plant",min=1,max=1},				
				{name="claw_commander_respawner",min=2,max=2},
				{name="claw_upgrade_center",min=1,max=1},
				{name="claw_scout_pad",min=1,max=1},
				{name="claw_long_range_rocket_platform",min=1,max=1}
			},
			mobileUnits = {
				{name="claw_construction_aircraft",min=2,max=6,weight=0.2},
				{name="claw_adv_construction_aircraft",min=2,max=5,weight=0.2},
				{name="claw_x",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="claw_x",min=1,max=MANY,weight=0.2},
				{name="claw_havoc",min=1,max=MANY,weight=0.6},
				{name="claw_blizzard",min=1,max=MANY,weight=0.3},
				{name="claw_shredder",min=1,max=MANY,weight=0.6},
				{name="claw_trident",min=3,max=MANY,weight=1,includeConditions={THREAT_UNDERWATER}},
				{name="claw_trident",min=1,max=MANY,weight=0.1}
			}
		},					
	}
}


clawAmphibious = {
	name = "clawAmphibious",
	commanderMorphs = { "Aggressor Form","Brawler Form" },
	upgrades = "offensive",
	stages = {
		------------------ STAGE 1
		{
			economy = {
				minMetalIncome = 15,
				minEnergyIncome = 200,
				metalIncome = 50,
				energyIncome = 350,
				comMorphMetalIncome = 50,		-- delay morph
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 40,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = false
			},
			properties = {
				commanderBuildsFactories = false,
				roamingCommander = true,
				raiderSpeedThreshold = 75,
				amphibiousRaiders = true,
				amphibiousMainForce = true,
				enemyThreatEstimationMult = 1.4,
				defenseDensityMult = 1,
				forceSpreadFactor = 0.7
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 0,
				mexUpgraders = 0,
				advancedDefenseBuilders = 0
			},
			factories = {
				{name="claw_nano_tower",min=1,max=1},
				{name="claw_spinbot_plant",min=1,max=1},
				{name="claw_commander_respawner",min=1,max=1}
			},
			mobileUnits = {
				{name="claw_adv_construction_spinbot",min=1,max=2,weight=0.2},
				{name="claw_dizzy",min=0,max=MANY,weight=0.6},
				{name="claw_mace",min=1,max=MANY,weight=0.4,excludeConditions={THREAT_AIR}}
			}
		},
		------------------ STAGE 2
		{
			economy = {
				minMetalIncome = 25,
				minEnergyIncome = 250,
				metalIncome = 200,
				energyIncome = 5000,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = false
			},
			properties = {
				commanderBuildsFactories = false,
				roamingCommander = false,
				raiderSpeedThreshold = 75,
				amphibiousRaiders = true,
				amphibiousMainForce = true,
				enemyThreatEstimationMult = 1.4,
				defenseDensityMult = 1,
				forceSpreadFactor = 0.7
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 0,
				mexUpgraders = 1,
				advancedDefenseBuilders = 0
			},
			factories = {
				{name="claw_nano_tower",min=1,max=3},
				{name="claw_spinbot_plant",min=1,max=1},
				{name="claw_commander_respawner",min=1,max=2},
				{name="claw_scout_pad",min=1,max=1},
				{name="claw_upgrade_center",min=1,max=1}
			},
			mobileUnits = {
				{name="claw_adv_construction_spinbot",min=1,max=4,weight=0.35},
				{name="claw_dizzy",min=1,max=MANY,weight=0.4,includeConditions={THREAT_AIR}},
				{name="claw_dizzy",min=1,max=MANY,weight=0.4},
				{name="claw_mace",min=1,max=MANY,weight=0.4,excludeConditions={THREAT_AIR}},
				{name="claw_predator",min=1,max=MANY,weight=0.4},
				{name="claw_dancer",min=1,max=MANY,weight=1.2,includeConditions={THREAT_UNDERWATER}},
				{name="claw_dancer",min=1,max=MANY,weight=0.4},
				{name="claw_gyro",min=1,max=MANY,weight=0.4},
				{name="claw_haze",min=1,max=1,weight=0.01}
			}
		},
		------------------ STAGE 3
		{
			economy = {
				minMetalIncome = 60,
				minEnergyIncome = 1500,
				metalIncome = 9999,
				energyIncome = 99999,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = true
			},
			properties = {
				commanderBuildsFactories = false,
				roamingCommander = false,
				amphibiousRaiders = true,
				amphibiousMainForce = true,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.4,
				defenseDensityMult = 1,
				forceSpreadFactor = 0.7
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 4,
				mexUpgraders = 1,
				advancedDefenseBuilders = 0
			},				
			factories = {
				{name="claw_nano_tower",min=1,max=4},
				{name="claw_adv_aircraft_plant",min=1,max=2},
				{name="claw_spinbot_plant",min=1,max=2},
				{name="claw_commander_respawner",min=1,max=2},
				{name="claw_scout_pad",min=1,max=1},
				{name="claw_upgrade_center",min=1,max=1},
				{name="claw_adv_shipyard",min=1,max=1,includeConditions={CONDITION_WATER}}
			},
			mobileUnits = {
				{name="claw_construction_aircraft",min=2,max=4,weight=0.25},
				{name="claw_adv_construction_aircraft",min=2,max=4,weight=0.25},
				{name="claw_adv_construction_spinbot",min=1,max=2,weight=0.25},
				{name="claw_dizzy",min=1,max=MANY,weight=0.4,includeConditions={THREAT_AIR}},
				{name="claw_tempest",min=1,max=MANY,weight=0.4},
				{name="claw_mace",min=1,max=MANY,weight=0.4,excludeConditions={THREAT_AIR}},
				{name="claw_predator",min=1,max=MANY,weight=0.4},
				{name="claw_dancer",min=1,max=MANY,weight=1.2,includeConditions={THREAT_UNDERWATER}},
				{name="claw_dancer",min=1,max=MANY,weight=0.4},
				{name="claw_gyro",min=1,max=MANY,weight=0.7},
				{name="claw_haze",min=1,max=1,weight=0.01},
				{name="claw_bullfrog",min=1,max=MANY,weight=0.4},
				{name="claw_lensor",min=1,max=2,weight=0.02},
				{name="claw_shredder",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="claw_trident",min=2,max=MANY,weight=1,includeConditions={THREAT_UNDERWATER}},
				{name="claw_blizzard",min=1,max=MANY,weight=0.4}
			}
		},
		------------------ STAGE 4
		{
			economy = {
				minMetalIncome = 90,
				minEnergyIncome = 2500,
				metalIncome = 9999,
				energyIncome = 99999,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = true
			},
			properties = {
				commanderBuildsFactories = false,
				roamingCommander = false,
				amphibiousRaiders = true,
				amphibiousMainForce = true,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.4,
				defenseDensityMult = 1,
				forceSpreadFactor = 0.7
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 4,
				mexUpgraders = 1,
				advancedDefenseBuilders = 1
			},				
			factories = {
				{name="claw_nano_tower",min=1,max=6},
				{name="claw_adv_aircraft_plant",min=1,max=2},
				{name="claw_spinbot_plant",min=1,max=2},
				{name="claw_commander_respawner",min=2,max=2},
				{name="claw_upgrade_center",min=1,max=1},
				{name="claw_scout_pad",min=1,max=1},
				{name="claw_long_range_rocket_platform",min=1,max=1},
				{name="claw_adv_shipyard",min=1,max=1,includeConditions={CONDITION_WATER}}
			},
			mobileUnits = {
				{name="claw_construction_aircraft",min=2,max=4,weight=0.25},
				{name="claw_adv_construction_aircraft",min=2,max=4,weight=0.25},
				{name="claw_adv_construction_spinbot",min=1,max=2,weight=0.25},
				{name="claw_dizzy",min=1,max=MANY,weight=0.4,includeConditions={THREAT_AIR}},
				{name="claw_tempest",min=1,max=MANY,weight=0.4},
				{name="claw_mace",min=1,max=MANY,weight=0.4,excludeConditions={THREAT_AIR}},
				{name="claw_predator",min=1,max=MANY,weight=0.4},
				{name="claw_dancer",min=1,max=MANY,weight=1.2,includeConditions={THREAT_UNDERWATER}},
				{name="claw_dancer",min=1,max=MANY,weight=0.4},
				{name="claw_gyro",min=1,max=MANY,weight=0.7},
				{name="claw_haze",min=1,max=1,weight=0.01},
				{name="claw_bullfrog",min=1,max=MANY,weight=0.4},
				{name="claw_lensor",min=1,max=2,weight=0.02},
				{name="claw_shredder",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="claw_trident",min=2,max=MANY,weight=1,includeConditions={THREAT_UNDERWATER}},
				{name="claw_blizzard",min=1,max=MANY,weight=0.4}
			}
		},					
	}
}



--------------------------------------- SPHERE


sphereLandAssault = {
	name = "sphereLandAssault",
	commanderMorphs = { "Emerald Form","Ruby Form","Builder Form" },
	upgrades = "speed",
	stages = {
		------------------ STAGE 1
		{
			economy = {
				minMetalIncome = 15,
				minEnergyIncome = 200,
				metalIncome = 50,
				energyIncome = 350,
				comMorphMetalIncome = 50,		-- delay morph
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = false
			},
			properties = {
				commanderBuildsFactories = false,
				raiderSpeedThreshold = 70,
				enemyThreatEstimationMult = 1.6,
				defenseDensityMult = 1,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 0,
				mexUpgraders = 0,
				advancedDefenseBuilders = 0
			},
			factories = {
				{name="sphere_pole",min=1,max=1},
				{name="sphere_light_factory",min=1,max=1},
				{name="sphere_commander_respawner",min=1,max=1}
			},
			mobileUnits = {
				{name="sphere_construction_vehicle",min=1,max=6,weight=0.2},
				{name="sphere_slicer",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="sphere_slicer",min=0,max=MANY,weight=0.2},
				{name="sphere_crustle",min=0,max=MANY,weight=0.2},
				{name="sphere_rock",min=0,max=MANY,weight=0.2},
				{name="sphere_gaunt",min=0,max=MANY,weight=0.4},
				{name="sphere_double",min=0,max=MANY,weight=0.2}
			}
		},
		------------------ STAGE 2
		{
			economy = {
				minMetalIncome = 30,
				minEnergyIncome = 300,
				metalIncome = 200,
				energyIncome = 5000,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = false
			},
			properties = {
				commanderBuildsFactories = false,
				raiderSpeedThreshold = 70,
				enemyThreatEstimationMult = 1.6,
				defenseDensityMult = 1,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 2,
				mexUpgraders = 1,
				advancedDefenseBuilders = 0
			},
			factories = {
				{name="sphere_pole",min=1,max=3},
				{name="sphere_adv_vehicle_factory",min=1,max=1},
				{name="sphere_light_factory",min=1,max=1},
				{name="sphere_commander_respawner",min=1,max=2},
				{name="sphere_scout_pad",min=1,max=1},
				{name="sphere_upgrade_center",min=1,max=1}
			},
			mobileUnits = {
				{name="sphere_construction_vehicle",min=2,max=4,weight=0.2},
				{name="sphere_adv_construction_vehicle",min=1,max=3,weight=0.2},
				{name="sphere_slicer",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="sphere_trax",min=3,max=MANY,weight=0.3},
				{name="sphere_bulk",min=3,max=MANY,weight=0.3},
				{name="sphere_pulsar",min=1,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="sphere_pulsar",min=0,max=MANY,weight=0.4},
				{name="sphere_concealer",min=1,max=1,weight=0.01},
				{name="sphere_double",min=0,max=MANY,weight=0.2},
				{name="sphere_quad",min=0,max=MANY,weight=0.2}
			}
		},
		------------------ STAGE 3
		{
			economy = {
				minMetalIncome = 60,
				minEnergyIncome = 1500,
				metalIncome = 9999,
				energyIncome = 99999,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = true
			},
			properties = {
				commanderBuildsFactories = false,
				raiderSpeedThreshold = 70,
				enemyThreatEstimationMult = 1.6,
				defenseDensityMult = 1,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 4,
				mexUpgraders = 1,
				advancedDefenseBuilders = 0
			},				
			factories = {
				{name="sphere_pole",min=1,max=4},
				{name="sphere_adv_vehicle_factory",min=1,max=2},
				{name="sphere_light_factory",min=1,max=1},				
				{name="sphere_commander_respawner",min=2,max=2},
				{name="sphere_upgrade_center",min=1,max=1},
				{name="sphere_adv_aircraft_factory",min=1,max=1},
				{name="sphere_scout_pad",min=1,max=1}
			},
			mobileUnits = {
				{name="sphere_construction_vehicle",min=2,max=6,weight=0.2},
				{name="sphere_adv_construction_vehicle",min=2,max=6,weight=0.2},
				{name="sphere_slicer",min=1,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="sphere_bulk",min=3,max=MANY,weight=0.3},
				{name="sphere_concealer",min=1,max=1,weight=0.01},
				{name="sphere_pulsar",min=1,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="sphere_shielder",min=1,max=6,weight=0.1},
				{name="sphere_pulsar",min=0,max=MANY,weight=0.2},
				{name="sphere_trax",min=0,max=MANY,weight=0.6},
				{name="sphere_crustle",min=0,max=MANY,weight=0.6},
				{name="sphere_twilight",min=3,max=MANY,weight=0.3,includeConditions={THREAT_AIR}},
				{name="sphere_neptune",min=3,max=MANY,weight=0.3,includeConditions={THREAT_UNDERWATER}},
				{name="sphere_meteor",min=1,max=1,weight=0.1}
			}
		},
		------------------ STAGE 4
		{
			economy = {
				minMetalIncome = 90,
				minEnergyIncome = 2500,
				metalIncome = 9999,
				energyIncome = 99999,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = true
			},
			properties = {
				commanderBuildsFactories = false,
				raiderSpeedThreshold = 70,
				enemyThreatEstimationMult = 1.6,
				defenseDensityMult = 1,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 4,
				mexUpgraders = 1,
				advancedDefenseBuilders = 1
			},				
			factories = {
				{name="sphere_pole",min=1,max=6},
				{name="sphere_adv_vehicle_factory",min=1,max=2},
				{name="sphere_light_factory",min=1,max=1,weight=1},				
				{name="sphere_commander_respawner",min=2,max=2},
				{name="sphere_upgrade_center",min=1,max=1},
				{name="sphere_adv_aircraft_factory",min=1,max=1},
				{name="sphere_scout_pad",min=1,max=1},
				{name="sphere_long_range_rocket_platform",min=1,max=1}
			},
			mobileUnits = {
				{name="sphere_construction_vehicle",min=2,max=6,weight=0.2},
				{name="sphere_adv_construction_vehicle",min=2,max=6,weight=0.2},
				{name="sphere_slicer",min=1,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="sphere_bulk",min=3,max=MANY,weight=0.3},
				{name="sphere_concealer",min=1,max=1,weight=0.01},
				{name="sphere_pulsar",min=1,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="sphere_shielder",min=1,max=6,weight=0.1},
				{name="sphere_pulsar",min=0,max=MANY,weight=0.2},
				{name="sphere_trax",min=0,max=MANY,weight=0.6},
				{name="sphere_crustle",min=0,max=MANY,weight=0.6},
				{name="sphere_twilight",min=3,max=MANY,weight=0.3,includeConditions={THREAT_AIR}},
				{name="sphere_neptune",min=3,max=MANY,weight=0.3,includeConditions={THREAT_UNDERWATER}},
				{name="sphere_meteor",min=1,max=1,weight=0.1}
			}
		},					
	}
}



sphereLandSkirmisher = {
	name = "sphereLandSkirmisher",
	commanderMorphs = { "Nova Form","Gazer Form" },
	upgrades = "offensive",
	stages = {
		------------------ STAGE 1
		{
			economy = {
				minMetalIncome = 15,
				minEnergyIncome = 200,
				metalIncome = 50,
				energyIncome = 350,
				comMorphMetalIncome = 50,		-- delay morph
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = false
			},
			properties = {
				commanderBuildsFactories = false,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.2,
				defenseDensityMult = 1,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 0,
				mexUpgraders = 0,
				advancedDefenseBuilders = 0
			},
			factories = {
				{name="sphere_pole",min=1,max=1},
				{name="sphere_light_factory",min=1,max=1},
				{name="sphere_commander_respawner",min=1,max=1}
			},
			mobileUnits = {
				{name="sphere_construction_vehicle",min=1,max=6,weight=0.2},
				{name="sphere_trike",min=0,max=MANY,weight=0.2},
				{name="sphere_double",min=0,max=MANY,weight=0.2},
				{name="sphere_slicer",min=0,max=MANY,weight=0.5,includeConditions={THREAT_AIR}},
				{name="sphere_needles",min=0,max=MANY,weight=0.6},
				{name="sphere_gaunt",min=0,max=MANY,weight=0.4},
				{name="sphere_rock",min=0,max=MANY,weight=0.3}
			}
		},
		------------------ STAGE 2
		{
			economy = {
				minMetalIncome = 30,
				minEnergyIncome = 300,
				metalIncome = 200,
				energyIncome = 5000,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = false
			},
			properties = {
				commanderBuildsFactories = false,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.2,
				defenseDensityMult = 1,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 2,
				mexUpgraders = 1,
				advancedDefenseBuilders = 0
			},
			factories = {
				{name="sphere_pole",min=1,max=3},
				{name="sphere_adv_kbot_factory",min=1,max=1},
				{name="sphere_light_factory",min=1,max=1},
				{name="sphere_commander_respawner",min=1,max=2},
				{name="sphere_scout_pad",min=1,max=1},
				{name="sphere_upgrade_center",min=1,max=1}
			},
			mobileUnits = {
				{name="sphere_construction_vehicle",min=2,max=4,weight=0.2},
				{name="sphere_adv_construction_kbot",min=1,max=3,weight=0.2},
				{name="sphere_slicer",min=0,max=MANY,weight=0.6,includeConditions={THREAT_AIR}},
				{name="sphere_masher",min=0,max=MANY,weight=0.4},
				{name="sphere_ark",min=0,max=MANY,weight=0.4},
				{name="sphere_rain",min=1,max=3,weight=0.1},
				{name="sphere_golem",min=0,max=MANY,weight=0.2},
				{name="sphere_sensor",min=1,max=1,weight=0.01},
				{name="sphere_gaunt",min=0,max=MANY,weight=0.3},
				{name="sphere_double",min=0,max=MANY,weight=0.3}
			}
		},
		------------------ STAGE 3
		{
			economy = {
				minMetalIncome = 60,
				minEnergyIncome = 1500,
				metalIncome = 9999,
				energyIncome = 99999,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = true
			},
			properties = {
				commanderBuildsFactories = false,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.2,
				defenseDensityMult = 1,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 4,
				mexUpgraders = 1,
				advancedDefenseBuilders = 0
			},				
			factories = {
				{name="sphere_pole",min=1,max=4},
				{name="sphere_adv_kbot_factory",min=1,max=2},
				{name="sphere_light_factory",min=1,max=1},				
				{name="sphere_commander_respawner",min=2,max=2},
				{name="sphere_upgrade_center",min=1,max=1},
				{name="sphere_adv_vehicle_factory",min=1,max=1},
				{name="sphere_scout_pad",min=1,max=1}
			},
			mobileUnits = {
				{name="sphere_construction_vehicle",min=2,max=6,weight=0.2},
				{name="sphere_adv_construction_kbot",min=2,max=3,weight=0.2},
				{name="sphere_adv_construction_vehicle",min=2,max=3,weight=0.2},
				{name="sphere_slicer",min=0,max=MANY,weight=0.6,includeConditions={THREAT_AIR}},
				{name="sphere_ark",min=3,max=MANY,weight=0.4},
				{name="sphere_masher",min=3,max=MANY,weight=0.4},
				{name="sphere_golemr",min=3,max=MANY,weight=0.3},
				{name="sphere_rain",min=1,max=3,weight=0.1},
				{name="sphere_sensor",min=1,max=1,weight=0.01},
				{name="sphere_hermit",min=0,max=MANY,weight=0.1},
				{name="sphere_slammer",min=0,max=MANY,weight=0.3},
				{name="sphere_needles",min=0,max=MANY,weight=0.3},
				{name="sphere_double",min=0,max=MANY,weight=0.2},
				{name="sphere_quad",min=0,max=MANY,weight=0.2}
			}
		},
		------------------ STAGE 4	
		{
			economy = {
				minMetalIncome = 90,
				minEnergyIncome = 2500,
				metalIncome = 9999,
				energyIncome = 99999,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = true
			},
			properties = {
				commanderBuildsFactories = false,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.2,
				defenseDensityMult = 1,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 4,
				mexUpgraders = 1,
				advancedDefenseBuilders = 1
			},				
			factories = {
				{name="sphere_pole",min=1,max=6},
				{name="sphere_adv_kbot_factory",min=1,max=2},
				{name="sphere_adv_vehicle_factory",min=1,max=2},
				{name="sphere_light_factory",min=1,max=1},
				{name="sphere_commander_respawner",min=2,max=2},
				{name="sphere_upgrade_center",min=1,max=1},
				{name="sphere_adv_aircraft_factory",min=1,max=1},
				{name="sphere_scout_pad",min=1,max=1},
				{name="sphere_long_range_rocket_platform",min=1,max=1}
			},
			mobileUnits = {
				{name="sphere_construction_vehicle",min=2,max=6,weight=0.2},
				{name="sphere_adv_construction_kbot",min=2,max=3,weight=0.2},
				{name="sphere_adv_construction_vehicle",min=2,max=3,weight=0.2},
				{name="sphere_adv_construction_aircraft",min=2,max=3,weight=0.2},
				{name="sphere_slicer",min=0,max=MANY,weight=0.6,includeConditions={THREAT_AIR}},
				{name="sphere_ark",min=3,max=MANY,weight=0.4},
				{name="sphere_masher",min=3,max=MANY,weight=0.4},
				{name="sphere_golemr",min=3,max=MANY,weight=0.3},
				{name="sphere_rain",min=1,max=3,weight=0.1},
				{name="sphere_sensor",min=1,max=1,weight=0.01},
				{name="sphere_hermit",min=0,max=MANY,weight=0.1},
				{name="sphere_slammer",min=0,max=MANY,weight=0.3},
				{name="sphere_needles",min=0,max=MANY,weight=0.3},
				{name="sphere_double",min=0,max=MANY,weight=0.3},
				{name="sphere_quad",min=0,max=MANY,weight=0.3},
				{name="sphere_resolver",min=1,max=2,weight=0.01},
				{name="sphere_twilight",min=3,max=MANY,weight=0.3,includeConditions={THREAT_AIR}},
				{name="sphere_neptune",min=3,max=MANY,weight=1,includeConditions={THREAT_UNDERWATER}},
				{name="sphere_resolver",min=1,max=2,weight=0.1},
				{name="sphere_neptune",min=0,max=MANY,weight=0.1}
			}
		},					
	}
}



sphereAir = {
	name = "sphereAir",
	commanderMorphs = { "Emerald Form","Ruby Form","Obsidian Form" },
	upgrades = "defensive",
	stages = {
		------------------ STAGE 1
		{
			economy = {
				minMetalIncome = 15,
				minEnergyIncome = 200,
				metalIncome = 50,
				energyIncome = 350,
				comMorphMetalIncome = 50,		-- delay morph
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = false
			},
			properties = {
				commanderBuildsFactories = false,
				roamingCommander = true,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.3,
				defenseDensityMult = 2,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 0,
				mexUpgraders = 0,
				advancedDefenseBuilders = 0
			},
			factories = {
				{name="sphere_pole",min=1,max=1},
				{name="sphere_aircraft_factory",min=1,max=1},
				{name="sphere_commander_respawner",min=1,max=1}
			},
			mobileUnits = {
				{name="sphere_construction_aircraft",min=1,max=6,weight=0.2},
				{name="sphere_moth",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="sphere_moth",min=0,max=MANY,weight=0.4},
				{name="sphere_blower",min=0,max=MANY,weight=0.6},
				{name="sphere_tycho",min=0,max=MANY,weight=0.4}
			}
		},
		------------------ STAGE 2
		{
			economy = {
				minMetalIncome = 30,
				minEnergyIncome = 300,
				metalIncome = 200,
				energyIncome = 5000,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = false
			},
			properties = {
				commanderBuildsFactories = false,
				roamingCommander = true,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.3,
				defenseDensityMult = 2,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 0,
				mexUpgraders = 1,
				advancedDefenseBuilders = 0
			},
			factories = {
				{name="sphere_pole",min=1,max=3},
				{name="sphere_adv_aircraft_factory",min=1,max=1},
				{name="sphere_aircraft_factory",min=1,max=1},
				{name="sphere_commander_respawner",min=1,max=2},
				{name="sphere_scout_pad",min=1,max=1},
				{name="sphere_upgrade_center",min=1,max=1}
			},
			mobileUnits = {
				{name="sphere_construction_aircraft",min=2,max=4,weight=0.2},
				{name="sphere_adv_construction_aircraft",min=1,max=3,weight=0.2},
				{name="sphere_twilight",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="sphere_twilight",min=1,max=MANY,weight=0.4},
				{name="sphere_meteor",min=1,max=MANY,weight=0.3},
				{name="sphere_spitfire",min=1,max=MANY,weight=0.3},
				{name="sphere_blower",min=1,max=MANY,weight=0.6},
				{name="sphere_neptune",min=3,max=MANY,weight=1,includeConditions={THREAT_UNDERWATER}},
				{name="sphere_neptune",min=1,max=MANY,weight=0.1}
			}
		},
		------------------ STAGE 3
		{
			economy = {
				minMetalIncome = 60,
				minEnergyIncome = 1500,
				metalIncome = 9999,
				energyIncome = 99999,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = true
			},
			properties = {
				commanderBuildsFactories = false,
				roamingCommander = true,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.3,
				defenseDensityMult = 2,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 0,
				mexUpgraders = 1,
				advancedDefenseBuilders = 0
			},				
			factories = {
				{name="sphere_pole",min=1,max=4},
				{name="sphere_adv_aircraft_factory",min=1,max=2},
				{name="sphere_aircraft_factory",min=1,max=1},				
				{name="sphere_commander_respawner",min=2,max=2},
				{name="sphere_upgrade_center",min=1,max=1},
				{name="sphere_scout_pad",min=1,max=1}
			},
			mobileUnits = {
				{name="sphere_construction_aircraft",min=2,max=6,weight=0.2},
				{name="sphere_adv_construction_aircraft",min=2,max=5,weight=0.2},
				{name="sphere_twilight",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="sphere_twilight",min=1,max=MANY,weight=0.2},
				{name="sphere_meteor",min=1,max=MANY,weight=0.6},
				{name="sphere_spitfire",min=1,max=MANY,weight=0.3},
				{name="sphere_blower",min=1,max=MANY,weight=0.6},
				{name="sphere_neptune",min=3,max=MANY,weight=1,includeConditions={THREAT_UNDERWATER}},
				{name="sphere_neptune",min=1,max=MANY,weight=0.1}
			}
		},
		------------------ STAGE 4
		{
			economy = {
				minMetalIncome = 90,
				minEnergyIncome = 2500,
				metalIncome = 9999,
				energyIncome = 99999,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = true
			},
			properties = {
				commanderBuildsFactories = false,
				roamingCommander = true,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.3,
				defenseDensityMult = 2,
				forceSpreadFactor = 1
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 0,
				mexUpgraders = 1,
				advancedDefenseBuilders = 1
			},				
			factories = {
				{name="sphere_pole",min=1,max=6},
				{name="sphere_adv_aircraft_factory",min=2,max=3},
				{name="sphere_aircraft_factory",min=1,max=1},				
				{name="sphere_commander_respawner",min=2,max=2},
				{name="sphere_upgrade_center",min=1,max=1},
				{name="sphere_scout_pad",min=1,max=1},
				{name="sphere_long_range_rocket_platform",min=1,max=1}
			},
			mobileUnits = {
				{name="sphere_construction_aircraft",min=2,max=6,weight=0.2},
				{name="sphere_adv_construction_aircraft",min=2,max=5,weight=0.2},
				{name="sphere_twilight",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="sphere_twilight",min=1,max=MANY,weight=0.2},
				{name="sphere_meteor",min=1,max=MANY,weight=0.6},
				{name="sphere_spitfire",min=1,max=MANY,weight=0.3},
				{name="sphere_blower",min=1,max=MANY,weight=0.6},
				{name="sphere_neptune",min=3,max=MANY,weight=1,includeConditions={THREAT_UNDERWATER}},
				{name="sphere_neptune",min=1,max=MANY,weight=0.1}
			}
		},					
	}
}


sphereAmphibious = {
	name = "sphereAmphibious",
	commanderMorphs = { "Emerald Form","Ruby Form" },
	upgrades = "speed",
	stages = {
		------------------ STAGE 1
		{
			economy = {
				minMetalIncome = 15,
				minEnergyIncome = 200,
				metalIncome = 50,
				energyIncome = 350,
				comMorphMetalIncome = 50,		-- delay morph
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 40,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = false
			},
			properties = {
				commanderBuildsFactories = false,
				roamingCommander = true,
				raiderSpeedThreshold = 75,
				amphibiousRaiders = true,
				amphibiousMainForce = true,
				enemyThreatEstimationMult = 1.4,
				defenseDensityMult = 2,
				forceSpreadFactor = 0.7
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 0,
				mexUpgraders = 0,
				advancedDefenseBuilders = 0
			},
			factories = {
				{name="sphere_pole",min=1,max=1},
				{name="sphere_sphere_factory",min=1,max=1},
				{name="sphere_commander_respawner",min=1,max=1}
			},
			mobileUnits = {
				{name="sphere_construction_aircraft",min=1,max=3,weight=0.2},
				{name="sphere_nimbus",min=0,max=MANY,weight=0.6},
				{name="sphere_aster",min=1,max=MANY,weight=0.2,includeConditions={THREAT_AIR}},
				{name="sphere_aster",min=0,max=MANY,weight=0.2}
			}
		},
		------------------ STAGE 2
		{
			economy = {
				minMetalIncome = 25,
				minEnergyIncome = 250,
				metalIncome = 200,
				energyIncome = 5000,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = false
			},
			properties = {
				commanderBuildsFactories = false,
				roamingCommander = true,
				raiderSpeedThreshold = 75,
				amphibiousRaiders = true,
				amphibiousMainForce = true,
				enemyThreatEstimationMult = 1.4,
				defenseDensityMult = 2,
				forceSpreadFactor = 0.7
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 0,
				mexUpgraders = 1,
				advancedDefenseBuilders = 0
			},
			factories = {
				{name="sphere_pole",min=1,max=3},
				{name="sphere_sphere_factory",min=1,max=1},
				{name="sphere_commander_respawner",min=1,max=2},
				{name="sphere_scout_pad",min=1,max=1},
				{name="sphere_upgrade_center",min=1,max=1}
			},
			mobileUnits = {
				{name="sphere_construction_aircraft",min=0,max=4,weight=0.2},
				{name="sphere_construction_sphere",min=1,max=4,weight=0.2},
				{name="sphere_aster",min=1,max=MANY,weight=0.8,includeConditions={THREAT_AIR}},
				{name="sphere_nimbus",min=1,max=MANY,weight=0.5},
				{name="sphere_aster",min=1,max=MANY,weight=0.3},
				{name="sphere_gazer",min=0,max=MANY,weight=0.3},
				{name="sphere_orb",min=1,max=1,weight=0.01}
			}
		},
		------------------ STAGE 3
		{
			economy = {
				minMetalIncome = 60,
				minEnergyIncome = 1500,
				metalIncome = 9999,
				energyIncome = 99999,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = true
			},
			properties = {
				commanderBuildsFactories = false,
				roamingCommander = true,
				amphibiousRaiders = true,
				amphibiousMainForce = true,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.4,
				defenseDensityMult = 2,
				forceSpreadFactor = 0.7
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 2,
				mexUpgraders = 1,
				advancedDefenseBuilders = 0
			},				
			factories = {
				{name="sphere_pole",min=1,max=4},
				{name="sphere_adv_aircraft_factory",min=1,max=1},
				{name="sphere_sphere_factory",min=1,max=1},
				{name="sphere_commander_respawner",min=1,max=2},
				{name="sphere_scout_pad",min=1,max=1},
				{name="sphere_upgrade_center",min=1,max=1}
			},
			mobileUnits = {
				{name="sphere_construction_aircraft",min=2,max=4,weight=0.2},
				{name="sphere_adv_construction_aircraft",min=2,max=4,weight=0.2},
				{name="sphere_construction_sphere",min=1,max=2,weight=0.2},
				{name="sphere_aster",min=1,max=MANY,weight=0.8,includeConditions={THREAT_AIR}},
				{name="sphere_aster",min=1,max=MANY,weight=0.4},
				{name="sphere_gazer",min=1,max=MANY,weight=0.4},
				{name="sphere_orb",min=1,max=1,weight=0.01},
				{name="sphere_resolver",min=1,max=2,weight=0.1},
				{name="sphere_blower",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="sphere_neptune",min=2,max=MANY,weight=1,includeConditions={THREAT_UNDERWATER}},
				{name="sphere_neptune",min=1,max=MANY,weight=0.2},
				{name="sphere_meteor",min=1,max=MANY,weight=0.4}
			}
		},
		------------------ STAGE 4
		{
			economy = {
				minMetalIncome = 90,
				minEnergyIncome = 2500,
				metalIncome = 9999,
				energyIncome = 99999,
				comMorphMetalIncome = 26,
				comMorphEnergyIncome = 250,
				comAttackerMetalIncome = 20,
				comAttackerEnergyIncome = 250,
				useHazardousExtractors = true
			},
			properties = {
				commanderBuildsFactories = false,
				roamingCommander = true,
				amphibiousRaiders = true,
				amphibiousMainForce = true,
				raiderSpeedThreshold = 75,
				enemyThreatEstimationMult = 1.4,
				defenseDensityMult = 2,
				forceSpreadFactor = 0.7
			},
			builderRoles = {
				mexBuilders = 1,
				basePatrollers = 0,
				defenseBuilders = 0,
				attackPatrollers = 3,
				mexUpgraders = 1,
				advancedDefenseBuilders = 1
			},				
			factories = {
				{name="sphere_pole",min=1,max=6},
				{name="sphere_adv_aircraft_factory",min=1,max=2},
				{name="sphere_sphere_factory",min=1,max=1},
				{name="sphere_commander_respawner",min=2,max=2},
				{name="sphere_upgrade_center",min=1,max=1},
				{name="sphere_scout_pad",min=1,max=1},
				{name="sphere_long_range_rocket_platform",min=1,max=1}
			},
			mobileUnits = {
				{name="sphere_construction_aircraft",min=2,max=4,weight=0.2},
				{name="sphere_adv_construction_aircraft",min=2,max=4,weight=0.2},
				{name="sphere_construction_sphere",min=1,max=2,weight=0.2},
				{name="sphere_aster",min=1,max=MANY,weight=0.8,includeConditions={THREAT_AIR}},
				{name="sphere_aster",min=1,max=MANY,weight=0.4},
				{name="sphere_gazer",min=1,max=MANY,weight=0.4},
				{name="sphere_orb",min=1,max=1,weight=0.01},
				{name="sphere_chroma",min=1,max=MANY,weight=0.2},
				{name="sphere_resolver",min=1,max=2,weight=0.1},
				{name="sphere_blower",min=0,max=MANY,weight=1,includeConditions={THREAT_AIR}},
				{name="sphere_neptune",min=2,max=MANY,weight=1,includeConditions={THREAT_UNDERWATER}},
				{name="sphere_neptune",min=1,max=MANY,weight=0.2},
				{name="sphere_meteor",min=1,max=MANY,weight=0.4}
			}
		},					
	}
}

-- id strings for strategies available by default
availableStrategyIds = {"assault","air","skirmisher","amphibious"}

-- mapping between faction + strategy identifier string and set of strategies to use 
strategyTable = {
	-------- AVEN
	aven_assault={avenLandAssault},
	aven_skirmisher={avenLandSkirmisher},
	aven_air={avenAir},
	aven_amphibious={avenAmphibious},
	
	-------- GEAR
	gear_assault={gearLandAssault},
	gear_skirmisher={gearLandSkirmisher},
	gear_air={gearAir},
	gear_amphibious={gearAmphibious},	

	-------- CLAW
	claw_assault={clawLandAssault},
	claw_skirmisher={clawLandSkirmisher},
	claw_air={clawAir},
	claw_amphibious={clawAmphibious},
	
	-------- SPHERE
	sphere_assault={sphereLandAssault},
	sphere_skirmisher={sphereLandSkirmisher},
	sphere_air={sphereAir},
	sphere_amphibious={sphereAmphibious}
}

playerAvailableStrategyOwner = {} -- name, allyId
-- id strings for strategies available by for each player
playerAvailableStrategyIds = {}

-- mapping between player + faction + strategy identifier string and set of strategies to use
-- players' custom strategies are stored here
playerStrategyTable = {}
