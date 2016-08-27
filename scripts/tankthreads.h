/*
** tankthreads.h -- standard thread animation
**
**  to use:
** - include after signal definitions
**
** - add "start-script AnimateTracks();" to "Create()"
**
** - add "#define SPEEDUP_FACTOR 100" (lower makes animation slower : recommended 80-100)
*/



#ifndef TANKTHREADS_H_
#define TANKTHREADS_H_

static-var bMoving;

StartMoving()
{
 	bMoving = TRUE;
}

StopMoving()
{
 	bMoving = FALSE;
}

AnimateTracks(current,maxSpeed,currentSpeed, delay)
{
	maxSpeed = get MAX_SPEED;
	current = 0;
	bMoving = FALSE;
	while(TRUE)
	{
		currentSpeed = get CURRENT_SPEED;
		
		delay = 140 * 100 / SPEEDUP_FACTOR;
		if ( currentSpeed > 0 AND bMoving )
		{
			delay = delay - ((currentSpeed * 100) / maxSpeed);
			
			if( current == 0 )
			{
				turn t1 to y-axis <180.000000> now;
				turn t2 to y-axis <180.000000> now;
			}
			if( current == 1 )
			{
				turn t1 to y-axis <0.000000> now;
				turn t2 to y-axis <0.000000> now;
			}
			
			current = current + 1;
			if( current == 2 )
			{
				current = 0;
			}
		}
		
		if( delay > 0)
		{
			sleep delay;
		}
		if( delay <= 0)
		{
			sleep 100;
		}
	}
}

#endif