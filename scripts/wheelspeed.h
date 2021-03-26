/*
** wheelspeed.h -- wheel speed control
**
**  to use:
** - include after signal definitions
**
** - add "start-script WheelSpeedControl();" to "Create()"
**
** - add "#define SPEEDUP_FACTOR 100"
*/

#ifndef WHEELSPEED_H_
#define WHEELSPEED_H_

//lua_cobDebug() { return 0; }

static-var wheelSpeed, wheelAcceleration, bMoving;


StartMoving()
{
 	bMoving = TRUE;
}

StopMoving()
{
 	bMoving = FALSE;
}

WheelSpeedControl(maxSpeed,currentSpeed)
{
	maxSpeed = get MAX_SPEED;
	bMoving = FALSE;
	while(TRUE)
	{
		currentSpeed = get CURRENT_SPEED;

		wheelSpeed = (currentSpeed*SPEEDUP_FACTOR) / maxSpeed * 728;
		//call-script lua_cobDebug(wheelSpeed);
		wheelAcceleration = wheelSpeed / 2;

		sleep 100;
	}
}

#endif