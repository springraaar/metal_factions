--[[  from Spring Wiki, info about CollisionVolumeData
Spring.GetUnitCollisionVolumeData ( number unitID ) -> 
	number scaleX, number scaleY, number scaleZ, number offsetX, number offsetY, number offsetZ,
	number volumeType, number testType, number primaryAxis, boolean disabled

Spring.SetUnitCollisionVolumeData ( number unitID, number scaleX, number scaleY, number scaleZ,
					number offsetX, number offsetY, number offsetX,
					number vType, number tType, number Axis ) -> nil

   possible vType constants
     DISABLED = -1  disables collision volume and collision detection for that unit, do not use
     ELLIPSOID = 0
     CYLINDER =  1
     BOX =       2
     SPHERE =    3
     FOOTPRINT = 4  intersection of sphere and footprint-prism, makes a sphere collision volume, default
	 
   possible tType constants, for non-sphere collision volumes use 1
     COLVOL_TEST_DISC = 0
     COLVOL_TEST_CONT = 1

   possible Axis constants, use non-zero only for Cylinder test
     COLVOL_AXIS_X = 0
     COLVOL_AXIS_Y = 1
     COLVOL_AXIS_Z = 2
]]--

--Collision volume definitions, ones entered here are for XTA, for other mods modify apropriatly

local unitCollisionVolume = {}

	unitCollisionVolume["aven_advanced_sonar_station"] = {
		on={63,70,63,0,-7,0,0,1,0},
		off={24,40,24,0,-5,0,0,1,0},
	}
	unitCollisionVolume["aven_seaplane_platform"] = {
		on={105,66,105,0,33,0,2,1,0},
		off={105,44,105,0,0,0,2,1,0},
	}
	unitCollisionVolume["aven_targeting_facility"] = {
		on={62,34,62,0,0,0,2,1,0},
		off={55,78,55,0,-19.5,0,0,1,0},
	}
	unitCollisionVolume["gear_doomsday_machine"] = {
		on={55,112,55,0,-3,0,2,1,0},
		off={48,86,48,0,-15,0,2,1,0},
	}
	unitCollisionVolume["gear_moho_metal_maker"] = {
		on={60,60,60,0,0,0,1,1,1},
		off={50,92,50,0,-22.5,0,0,1,0},
	}
	unitCollisionVolume["gear_targeting_facility"] = {
		on={64,20,64,0,0,0,1,1,1},
		off={38,20,38,0,0,0,1,1,1},
	}
--	unitCollisionVolume["gear_toaster"] = {
--		on={44,23,44,0,0,0,2,1,0},
--		off={44,8,44,0,-9,0,2,1,0},
--	}
	unitCollisionVolume["gear_viper"] = {
		on={67,136,67,0,-21,0,0,1,0},
		off={51,20,53,0,-12,0,2,1,0},
	}

return unitCollisionVolume