/*
** aimhelper2.h -- provides support for continuous aim (turret 2)
**
**  to use:
** - include after var definitions
** - requires aimhelper2 piece
**
** - add "call-script stopAimHelper2(hSpeed,pSpeed);" to "Create()"
** - add "call-script updateAimHelper2(heading,pitch,hSpeed,pSpeed,hTolerance,pTolerance);" to "AimWeapon(...)" before the signal/signal mask
** - add "call-script stopAimHelper2(hSpeed,pSpeed);" to "RestoreAfterDelay(...)" after the delay
**
*/

#ifndef AIMHELPER2_H_
#define AIMHELPER2_H_

#define SIG_AIM_HELPER_2	32

piece aimhelper2;
static-var aimHelperHeading2, aimHelperPitch2, aimReady2, aimHelperRunning2, aimHelperHTolerance2, aimHelperPTolerance2, toleranceCheckPassed2;

//TODO finish this


// check if new orientation is within tolerance of old one
// returns true if successful
isAimWithinTolerance2(heading,pitch,oldHeading,oldPitch,hTolerance,pTolerance) {

	// if the unit is aiming backwards, the heading values "flip" when they reach 180 or -180
	// validate that case separately
	if ( (get ABS(heading) > (<180> -hTolerance) && get ABS(oldHeading) > (<180> -hTolerance))  && get ABS(pitch - oldPitch) < pTolerance) {
		toleranceCheckPassed2 = TRUE;
		return;
	} 
	if ( get ABS(heading - oldHeading)  > hTolerance || get ABS(pitch - oldPitch) > pTolerance) {
		toleranceCheckPassed2 = FALSE;
		return;
	}
	
	toleranceCheckPassed2 = TRUE;
	return;
}

// stop aim helper
stopAimHelper2(hSpeed,pSpeed) {
	aimReady2 = FALSE;
	signal SIG_AIM_HELPER_2;
	turn aimhelper2 to y-axis <0> speed hSpeed;
	turn aimhelper2 to x-axis <0> speed pSpeed;
	aimHelperHeading2 = <0>;
	aimHelperPitch2 = <0>;
	aimHelperRunning2 = FALSE;
	toleranceCheckPassed2 = FALSE;
}

// run aim helper
runAimHelper2(hSpeed,pSpeed) {
	set-signal-mask SIG_AIM_HELPER_2;
	aimHelperRunning2 = TRUE;
	var currentHeading, currentPitch, targetHeading, targetPitch;
	currentHeading = <-333>;
	currentPitch = <-333>;
	while (TRUE) {
		targetHeading = aimHelperHeading2;
		targetPitch = aimHelperPitch2;
		aimReady2 = FALSE;
		// turn helper to target orientation
		turn aimhelper2 to y-axis targetHeading speed hSpeed;
		turn aimhelper2 to x-axis <0.000000> - targetPitch speed pSpeed;

		call-script isAimWithinTolerance2(targetHeading,targetPitch,currentHeading,currentPitch,aimHelperHTolerance2,aimHelperPTolerance2);
		// if within tolerance, set aimReady immediately, else wait for turn before doing so
		if(toleranceCheckPassed2) {
			aimReady2 = TRUE;
			wait-for-turn aimhelper2 around y-axis;
			wait-for-turn aimhelper2 around x-axis;
			currentHeading = targetHeading;
			currentPitch = targetPitch;
		} else {
			wait-for-turn aimhelper2 around y-axis;
			wait-for-turn aimhelper2 around x-axis;
			currentHeading = targetHeading;
			currentPitch = targetPitch;
			aimReady2 = TRUE;
		}

		sleep 10; // 1 frame + wait-for-turn frames
	}
}

// update aim helper (start it if it's stopped)
updateaimhelper2(heading,pitch,hSpeed,pSpeed,hTolerance,pTolerance) {
	aimHelperHTolerance2 = hTolerance;
	aimHelperPTolerance2 = pTolerance;
	
	//call-script lua_cobDebug(heading, aimHelperHeading2);
	call-script isAimWithinTolerance2(heading,pitch,aimHelperHeading2,aimHelperPitch2,aimHelperHTolerance2,aimHelperPTolerance2);
	// clear aimReady if target orientation changed significantly
	if(!toleranceCheckPassed2) {
		aimReady2 = FALSE;
	}
	
	// update target orientation
	aimHelperHeading2 = heading;
	aimHelperPitch2 = pitch;

	//call-script lua_cobDebug(heading);
	// start helper if not running
	if (!aimHelperRunning2)	{
		start-script runaimhelper2(hSpeed,pSpeed);
	} 
}

#endif