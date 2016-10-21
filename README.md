# dot-jump
dot-jump task, continuing from Martini unpublished work

Dyslexia dot-jump experiment design considerations
We like the idea of making the distribution of dot positions non-uniform, so we can see whether dyslexics make use of the prior less.  The obvious way to do that is by making particular angles (e.g., northeast and east) more likely. However, this is not ideal because it may also bias participants' fixation positions- they'd tend to move their eyes in that direction.
An alternative, then, is to bias the distribution of radius, making certain eccentricities more likely. In fact, Brenner et al. (2008) already documented a low-eccentricity bias, and we could see whether dyslexics do that, and if they're responsive to other contingencies. BTW, it seems to me that because eccentricity isn't a circular variable, any natural incorporation of priors would cause one to be biased towards lower eccentricities, as that would reduce mean error. I don't know if you know what I mean, nor do I know whether Brenner et al. addressed this.

Brenner, E., Mamassian, P., & Smeets, J. B. (2008). If I saw it, it probably wasn’t far from where I was looking. Journal of Vision, 8(2), 7.1–10.

####Experiment and parameters

This program displays a dot that jumps between positions on a circle. The dot appears to flicker at a random position in the sequence. At the end of a trial, the participant sees the positions the dot took on that trial and has to indicate with a mouse press where the dot was when it flickered.

The dot (or whatever stimulus you desire) appears at `nDots` equally spaced locations on a circle with center coordinates `center` and a radius of `radius` degrees of visual angle. The dot appears for `itemMS` milliseconds with an SOA of `SOAMS`.

Based on Patrick's analysis code and the raw data from Paolo's script, the SOA was 66.667ms and the item appeared for 22.222ms.
* See DTDJ_Show_Models.m, line 30
* on time and off time on lines 10 and 11 of any of the raw data files

####Data output
These are the file headers. Coordinates are in degrees of visual angle and defined from the center of the window.

* subject: subject ID, string
* task: task ID, string
* staircase: staircase trial, logical (there is no code for a staircase)
* trialNum: trial number, integer
* responseX: center X coordinate of item nearest to mouse click
* responseY: center Y coordinate of item nearest to mouse click
* correctX: center X coordinate of the cued item
* correctY: center Y coordinate of the cued item
* clickX: X coordinate of the mouse click
* clickY: Y coordinate of the mouse click
* accuracy: was the item nearest to the mouse click the cued item?
* responsePosInStream: The item nearest to the mouse click's position in the trial sequence. Uses python indexes, so the first item is 0
* correctPosInStream: The cued item's position in the trial sequence.
* longFrames: The number of trial display frames .3 longer than the refresh rate of the monitor.

See test\_dot-jump\_data.txt for an example of the output

####Autopiloting
Selecting autopilot in the initial dialogue box brings adds some options to the experiment parameters
*autoTime: The temporal offset for the autopilot. This value is the difference in serial temporal position of the item selected by the autopilot relative to the cue. Positive values select later items. Negative values selecter earlier items.
*autoSpace: The offset in serial spatial position. Positive values select items clockwise from the cue. Negative values select items anticlockwise from the cue.
*randomTime: On each trial, adds a random selection from the normal distribution N(0,2), rounded to the nearest integer to the time offset.
*randomSpace: The same as randomTime, but to the spatial offset.
