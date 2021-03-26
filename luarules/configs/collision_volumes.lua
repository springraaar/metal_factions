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

--Collision volume definitions
-- sizeX,sizeY,sizeZ,offsetX,offsetY,offsetZ,volumeType,testType,primaryAxis

local unitCollisionVolume = {}

--------------------------------------------- AVEN

--------------------------------------------- GEAR
unitCollisionVolume["gear_toaster"] = {
	on={44,30,44,0,0,0,2,1,0},
	off={44,15,44,0,0,0,2,1,0},
}

unitCollisionVolume["gear_missilator"] = {
	on={60,60,60,0,0,0,2,1,0},
	off={60,22,60,0,0,0,2,1,0},
}

unitCollisionVolume["gear_light_laser_tower"] = {
	on={30,60,30,0,0,0,2,1,0},
	off={30,15,30,0,0,0,2,1,0},
}

unitCollisionVolume["gear_pulverizer"] = {
	on={30,60,30,0,0,0,2,1,0},
	off={30,15,30,0,0,0,2,1,0},
}

unitCollisionVolume["gear_beamer"] = {
	on={38,60,38,0,0,0,2,1,0},
	off={38,15,38,0,0,0,2,1,0},
}

unitCollisionVolume["gear_burner"] = {
	on={50,40,50,0,0,0,1,1,1},
	off={50,20,50,0,0,0,1,1,1},
}

--------------------------------------------- CLAW

unitCollisionVolume["claw_hyper"] = {
	on={60,50,60,0,0,0,2,1,0},
	off={60,18,60,0,0,0,2,1,0},
}

unitCollisionVolume["claw_hazard"] = {
	on={30,60,30,0,0,0,2,1,0},
	off={30,15,30,0,0,0,2,1,0},
}

--------------------------------------------- SPHERE

return unitCollisionVolume