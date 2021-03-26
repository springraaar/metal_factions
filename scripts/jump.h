/*
** jump.h -- common jump functions
**
**  to use:
** - include after the unit-specific jump functions
**
*/


setHasJump(state) {
	hasJump = state;
}

setJumping(jumping,descending) {
	isJumping = jumping;
	isJumpDescending = descending;
}

jumpHandler(enabled,jumpFrames) {
	enabled = 0;
	jumpFrames = 0;
	while (TRUE) {
		// update jump gear visibility
		if (enabled != hasJump) {
			if (hasJump) {
				call-script showJumpGear();
			} else {
				call-script hideJumpGear();
			}
			
			enabled = hasJump;
		}

		// spawn jump thruster effects if jumping
		if (isJumping) {
			call-script showJumpEffects(isJumpDescending, jumpFrames);
			jumpFrames = jumpFrames + 1;
			if (jumpFrames > JUMP_SND_FRAMES) {  // play sound only every few frames
				jumpFrames = 1;
			}
		} else {
			jumpFrames = 0;
		}
		sleep 32; // 1 frame
	}
}

initJump() {
	hasJump = 0;
	isJumping = 0;
	isJumpDescending = 0;
	call-script hideJumpGear();
	start-script jumpHandler();
}



