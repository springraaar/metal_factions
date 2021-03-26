/*
** aimhelper3.h -- provides support for continuous aim (turret 3)
**
**  to use:
** - include after var definitions
** - requires aimhelper3 piece
**
** - add "call-script stopAimHelper3(hSpeed,pSpeed);" to "Create()"
** - add "call-script updateAimHelper3(heading,pitch,hSpeed,pSpeed,hTolerance,pTolerance);" to "AimWeapon(...)" before the signal/signal mask
** - add "call-script stopAimHelper3(hSpeed,pSpeed);" to "RestoreAfterDelay(...)" after the delay
**
*/

#ifndef AIMHELPER3_H_
#define AIMHELPER3_H_

#define SIG_AIM_HELPER_3	64

piece aimhelper3;
static-var aimHelperHeading3, aimHelperPitch3, aimReady3, aimHelperRunning3, aimHelperHTolerance3, aimHelperPTolerance3, toleranceCheckPassed3;


// check if new orientation is within tolerance of old one
// returns true if successful
isAimWithinTolerance3(heading,pitch,oldHeading,oldPitch,hTolerance,pTolerance) {

	// if the unit is aiming backwards, the heading values "flip" when they reach 180 or -180
	// validate that case separately
	if ( (get ABS(heading) > (<180> -hTolerance) && get ABS(oldHeading) > (<180> -hTolerance))  && get ABS(pitch - oldPitch) < pTolerance) {
		toleranceCheckPassed3 = TRUE;
		return;
	} 
	if ( get ABS(heading - oldHeading)  > hTolerance || get ABS(pitch - oldPitch) > pTolerance) {
		toleranceCheckPassed3 = FALSE;
		return;
	}
	
	toleranceCheckPassed3 = TRUE;
	return;
}

// stop aim helper
stopAimHelper3(hSpeed,pSpeed) {
	aimReady3 = FALSE;
	signal SIG_AIM_HELPER_3;
	turn aimhelper3 to y-axis <0> speed hSpeed;
	turn aimhelper3 to x-axis <0> speed pSpeed;
	aimHelperHeading3 = <0>;
	aimHelperPitch3 = <0>;
	aimHelperRunning3 = FALSE;
	toleranceCheckPassed3 = FALSE;
}

// run aim helper
runAimHelper3(hSpeed,pSpeed) {
	set-signal-mask SIG_AIM_HELPER_3;
	aimHelperRunning3 = TRUE;
	var currentHeading, currentPitch, targetHeading, targetPitch;
	currentHeading = <-333>;
	currentPitch = <-333>;
	while (TRUE) {
		targetHeading = aimHelperHeading3;
		targetPitch = aimHelperPitch3;
		aimReady3 = FALSE;
		// turn helper to target orientation
		turn aimhelper3 to y-axis targetHeading speed hSpeed;
		turn aimhelper3 to x-axis <0.000000> - targetPitch speed pSpeed;

		call-script isAimWithinTolerance3(targetHeading,targetPitch,currentHeading,currentPitch,aimHelperHTolerance3,aimHelperPTolerance3);
		// if within tolerance, set aimReady immediately, else wait for turn before doing so
		if(toleranceCheckPassed3) {
			aimReady3 = TRUE;
			wait-for-turn aimhelper3 around y-axis;
			wait-for-turn aimhelper3 around x-axis;
			currentHeading = targetHeading;
			currentPitch = targetPitch;
		} else {
			wait-for-turn aimhelper3 around y-axis;
			wait-for-turn aimhelper3 around x-axis;
			currentHeading = targetHeading;
			currentPitch = targetPitch;
			aimReady3 = TRUE;
		}

		sleep 10; // 1 frame + wait-for-turn frames
	}
}

// update aim helper (start it if it's stopped)
updateAimHelper3(heading,pitch,hSpeed,pSpeed,hTolerance,pTolerance) {
	aimHelperHTolerance3 = hTolerance;
	aimHelperPTolerance3 = pTolerance;
	
	//call-script lua_cobDebug(heading, aimHelperHeading3);
	call-script isAimWithinTolerance3(heading,pitch,aimHelperHeading3,aimHelperPitch3,aimHelperHTolerance3,aimHelperPTolerance3);
	// clear aimReady if target orientation changed significantly
	if(!toleranceCheckPassed3) {
		aimReady3 = FALSE;
	}
	
	// update target orientation
	aimHelperHeading3 = heading;
	aimHelperPitch3 = pitch;

	//call-script lua_cobDebug(heading);
	// start helper if not running
	if (!aimHelperRunning3)	{
		start-script runAimHelper3(hSpeed,pSpeed);
	} 
}

#endif