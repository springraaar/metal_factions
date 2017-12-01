/*
** spinbot.h -- spinbot animation speed and angle control
**
**  to use:
** - include after signal definitions
**
** - add "start-script WheelSpeedControl();" to "Create()"
**
** - add "#define SPEEDUP_FACTOR 100"
*/

#ifndef SPINBOT_H_
#define SPINBOT_H_


static-var wheelSpeed, wheelAcceleration, pivotAngle, oldSpeed, bMoving;


WheelSpeedControl(maxSpeed,currentSpeed)
{
	maxSpeed = get MAX_SPEED;
	bMoving = FALSE;
	while(TRUE)
	{
		currentSpeed = get CURRENT_SPEED;

		wheelSpeed = (currentSpeed*SPEEDUP_FACTOR) / maxSpeed * 360;
		wheelAcceleration = wheelSpeed / 2;

		// changes with acceleration ?
		//pivotAngle = (currentSpeed - oldSpeed)* 100 / maxSpeed;
		//pivotAngle = pivotAngle  * <1.000000>;

		if (currentSpeed > oldSpeed/2) {
			pivotAngle = <5.000000>;
		}
		if (currentSpeed < oldSpeed && get ABS(currentSpeed) < 3*maxSpeed/4) {
			pivotAngle = <-5.000000>;
		}
		if (get ABS(currentSpeed) < maxSpeed/4){
			pivotAngle = <0.000000>;
		}


		//get PRINT(pivotAngle / <1>,currentSpeed);
		oldSpeed = currentSpeed;
		sleep 30;
	}
}

#endif