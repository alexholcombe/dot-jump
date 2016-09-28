# dot-jump
dot-jump task, continuing from Martini unpublished work

##Experiment and parameters

This program displays a dot that jumps between positions on a circle. The dot appears to flicker at a random position in the sequence. At the end of a trial, the participant sees the positions the dot took on that trial and has to indicate with a mouse press where the dot was when it flickered. 

The dot (or whatever stimulus you desire) appears at `nDots` equally spaced locations on a circle with center coordinates `center` and a radius of `radius` degrees of visual angle. The dot appears for `itemMS` milliseconds with an SOA of `SOAMS`. 

##Data output
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
