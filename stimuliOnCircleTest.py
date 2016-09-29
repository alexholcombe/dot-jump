from psychopy import visual, monitors
from math import cos, sin, radians, degrees
import copy

monitorname = 'testmonitor'
monitorwidth = 45
viewdist = 57

widthPix = 1280
heightPix = 1024
units = 'degs'
bgColor = (-1,-1,-1)
scrn = 1
fullscr = 0
waitBlanking = True
allowGUI = True
waitBlank = True

mon = monitors.Monitor(monitorname,width=monitorwidth, distance=viewdist)
myWin = visual.Window(monitor=mon,size=(widthPix,heightPix),allowGUI=allowGUI,units=units,color=bgColor,colorSpace='rgb',fullscr=fullscr,screen=scrn,waitBlanking=waitBlank) #Holcombe lab monitor

circle = visual.Circle(myWin, radius = .5, fillColor = (1,1,1) )
nDots = 18
radius = 8
center = (0,0)

def stimuliOnCircle(nDots, radius, center, stimulusObject):
    if len(center) > 2 or len(center) < 2:
        print('Center coords must be list of length 2')
        return None
    spacing = 360./nDots
    stimuli = []
    for dot in range(nDots):
        angle = dot*spacing
        if angle == 0:
            xpos = radius
            ypos = 0
        elif angle == 90:
            xpos = 0
            ypos = radius
        elif angle == 180:
            xpos = -radius
            ypos = 0
        elif angle == 270:
            xpos = 0
            ypos = -radius
        elif angle%90!=0:
            xpos = radius*cos(radians(angle))
            ypos = radius*sin(radians(angle))
        stim = copy.copy(stimulusObject)
        stim.pos = [pos + offset for pos,offset in zip((xpos,ypos), center)]
        stimuli.append(stim)
    return stimuli

stimuli = stimuliOnCircle(nDots, radius, center, circle)
for stimulus in stimuli:
    print stimulus.pos

for i in range(120):
    circle.pos = (0,0)
    circle.draw()
    if i%10 in range(1):
        for item in stimuli:
            item.draw()
    myWin.flip()


