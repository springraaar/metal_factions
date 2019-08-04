/*
** aimhelper1.h -- provides support for continuous aim (turret 1)
**
**  to use:
** - include after var definitions
** - requires aimhelper1 piece
**
** - add "call-script stopAimHelper1(hSpeed,pSpeed);" to "Create()"
** - add "call-script updateAimHelper1(heading,pitch,hSpeed,pSpeed,hTolerance,pTolerance);" to "AimWeapon(...)" before the signal/signal mask
** - add "call-script stopAimHelper1(hSpeed,pSpeed);" to "RestoreAfterDelay(...)" after the delay
**
*/

#ifndef AIMHELPER1_H_
#define AIMHELPER1_H_

#define SIG_AIM_HELPER_1	16

piece aimhelper1;
static-var aimHelperHeading1, aimHelperPitch1, aimReady1, aimHelperRunning1, aimHelperHTolerance1, aimHelperPTolerance1, toleranceCheckPassed1;

//TODO finish this


// check if new orientation is within tolerance of old one
// returns true if successful
isAimWithinTolerance1(heading,pitch,oldHeading,oldPitch,hTolerance,pTolerance) {

	// if the unit is aiming backwards, the heading values "flip" when they reach 180 or -180
	// validate that case separately
	if ( (get ABS(heading) > (<180> -hTolerance) && get ABS(oldHeading) > (<180> -hTolerance))  && get ABS(pitch - oldPitch) < pTolerance) {
		toleranceCheckPassed1 = TRUE;
		return;
	} 
	if ( get ABS(heading - oldHeading)  > hTolerance || get ABS(pitch - oldPitch) > pTolerance) {
		toleranceCheckPassed1 = FALSE;
		return;
	}
	
	toleranceCheckPassed1 = TRUE;
	return;
}

// stop aim helper
stopAimHelper1(hSpeed,pSpeed) {
	aimReady1 = FALSE;
	signal SIG_AIM_HELPER_1;
	turn aimhelper1 to y-axis <0> speed hSpeed;
	turn aimhelper1 to x-axis <0> speed pSpeed;
	aimHelperHeading1 = <0>;
	aimHelperPitch1 = <0>;
	aimHelperRunning1 = FALSE;
	toleranceCheckPassed1 = FALSE;
}

// run aim helper
runAimHelper1(hSpeed,pSpeed) {
	set-signal-mask SIG_AIM_HELPER_1;
	aimHelperRunning1 = TRUE;
	var currentHeading, currentPitch, targetHeading, targetPitch;
	currentHeading = <-333>;
	currentPitch = <-333>;
	while (TRUE) {
		targetHeading = aimHelperHeading1;
		targetPitch = aimHelperPitch1;
		aimReady1 = FALSE;
		// turn helper to target orientation
		turn aimhelper1 to y-axis targetHeading speed hSpeed;
		turn aimhelper1 to x-axis <0.000000> - targetPitch speed pSpeed;

		call-script isAimWithinTolerance1(targetHeading,targetPitch,currentHeading,currentPitch,aimHelperHTolerance1,aimHelperPTolerance1);
		// if within tolerance, set aimReady immediately, else wait for turn before doing so
		if(toleranceCheckPassed1) {
			aimReady1 = TRUE;
			wait-for-turn aimhelper1 around y-axis;
			wait-for-turn aimhelper1 around x-axis;
			currentHeading = targetHeading;
			currentPitch = targetPitch;
		} else {
			wait-for-turn aimhelper1 around y-axis;
			wait-for-turn aimhelper1 around x-axis;
			currentHeading = targetHeading;
			currentPitch = targetPitch;
			aimReady1 = TRUE;
		}

		sleep 10; // 1 frame + wait-for-turn frames
	}
}

// update aim helper (start it if it's stopped)
updateAimHelper1(heading,pitch,hSpeed,pSpeed,hTolerance,pTolerance) {
	aimHelperHTolerance1 = hTolerance;
	aimHelperPTolerance1 = pTolerance;
	
	//call-script lua_cobDebug(heading, aimHelperHeading1);
	call-script isAimWithinTolerance1(heading,pitch,aimHelperHeading1,aimHelperPitch1,aimHelperHTolerance1,aimHelperPTolerance1);
	// clear aimReady if target orientation changed significantly
	if(!toleranceCheckPassed1) {
		aimReady1 = FALSE;
	}
	
	// update target orientation
	aimHelperHeading1 = heading;
	aimHelperPitch1 = pitch;

	//call-script lua_cobDebug(heading);
	// start helper if not running
	if (!aimHelperRunning1)	{
		start-script runAimHelper1(hSpeed,pSpeed);
	} 
}

#endif