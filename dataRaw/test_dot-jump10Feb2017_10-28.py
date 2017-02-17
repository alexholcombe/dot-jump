
from __future__ import print_function
__author__ = """Alex "O." Holcombe, Charles Ludowici, """ ## double-quotes will be silently removed, single quotes will be left, eg, O'Connor
import time, sys, platform, os
from math import atan, atan2, pi, cos, sin, sqrt, ceil, radians, degrees
import numpy as np
import psychopy, psychopy.info
import copy
from psychopy import visual, sound, monitors, logging, gui, event, core, data
from string import ascii_uppercase
try:
    from helpersAOH import accelerateComputer, openMyStimWindow
except Exception as e:
   print(e); print('Problem loading helpersAOH. Check that the file helpersAOH.py in the same directory as this file')
   print('Current directory is ',os.getcwd())

eyeTracking = False

if eyeTracking:
    try:
        import eyelinkEyetrackerForPsychopySUPA3
    except Exception as e:
        print(e)
        print('Problem loading eyelinkEyetrackerForPsychopySUPA3. Check that the file eyelinkEyetrackerForPsychopySUPA3.py in the same directory as this file')
        print('While a different version of pylink might make your eyetracking code work, your code appears to generally be out of date. Rewrite your eyetracker code based on the SR website examples')
        #Psychopy v1.83.01 broke this, pylink version prevents EyelinkEyetrackerForPsychopySUPA3 stuff from importing. But what really needs to be done is to change eyetracking code to more modern calls, as indicated on SR site
        eyeTracking = False

expname= "dot-jump"
demo = False; exportImages = False
autopilot = False
subject='test'


###############################
### Setup the screen parameters    ##########
###############################
allowGUI = False
units='deg' #'cm'
waitBlank=False
refreshRate= 85 *1.0;  #160 #set to the framerate of the monitor
fullscrn=True; #show in small window (0) or full screen (1)
scrn=True
stimulusType = 'circle'


if True: #just so I can indent all the below
#which screen to display the stimuli. 0 is home screen, 1 is second screen
        # create a dialog from dictionary
        infoFirst = { 'Autopilot':autopilot, 'Check refresh etc':True, 'Use second screen':scrn, 'Fullscreen (timing errors if not)': fullscrn, 'Screen refresh rate': refreshRate, 'Stimulus type': stimulusType}
        OK = gui.DlgFromDict(dictionary=infoFirst,
            title='MOT',
            order=['Autopilot','Check refresh etc', 'Use second screen', 'Screen refresh rate', 'Fullscreen (timing errors if not)'],
            tip={'Check refresh etc': 'To confirm refresh rate and that can keep up, at least when drawing a grating',
                    'Use second Screen': ''},
            )
        if not OK.OK:
            print('User cancelled from dialog box'); logging.info('User cancelled from dialog box'); core.quit()
        autopilot = infoFirst['Autopilot']
        checkRefreshEtc = infoFirst['Check refresh etc']
        scrn = infoFirst['Use second screen']
        print('scrn = ',scrn, ' from dialog box')
        fullscrn = infoFirst['Fullscreen (timing errors if not)']
        refreshRate = infoFirst['Screen refresh rate']
        stimulusType = infoFirst['Stimulus type']

        #monitor parameters
        widthPix = 1024 #1440  #monitor width in pixels
        heightPix =768  #900 #monitor height in pixels
        monitorwidth = 37 #28.5 #monitor width in centimeters
        viewdist = 55.; #cm
        pixelperdegree = widthPix/ (atan(monitorwidth/viewdist) /np.pi*180)
        bgColor = [-1,-1,-1] #black background
        monitorname = 'testMonitor' # 'mitsubishi' #in psychopy Monitors Center

        mon = monitors.Monitor(monitorname,width=monitorwidth, distance=viewdist)#fetch the most recent calib for this monitor
        mon.setSizePix( (widthPix,heightPix) )
        myWin = openMyStimWindow(mon,widthPix,heightPix,bgColor,allowGUI,units,fullscrn,scrn,waitBlank)
        myWin.setRecordFrameIntervals(False)

        trialsPerCondition = 1 #default value

        refreshMsg2 = ''
        if not checkRefreshEtc:
            refreshMsg1 = 'REFRESH RATE WAS NOT CHECKED'
            refreshRateWrong = False
        else: #checkRefreshEtc
            runInfo = psychopy.info.RunTimeInfo(
                    win=myWin,    ## a psychopy.visual.Window() instance; None = default temp window used; False = no win, no win.flips()
                    refreshTest='grating', ## None, True, or 'grating' (eye-candy to avoid a blank screen)
                    verbose=True, ## True means report on everything
                    userProcsDetailed=True  ## if verbose and userProcsDetailed, return (command, process-ID) of the user's processes
                    )
            print('Finished runInfo- which assesses the refresh and processes of this computer')
            refreshMsg1 = 'Median frames per second ='+ str( np.round(1000./runInfo["windowRefreshTimeMedian_ms"],1) )
            refreshRateTolerancePct = 3
            pctOff = abs( (1000./runInfo["windowRefreshTimeMedian_ms"]-refreshRate) / refreshRate)
            refreshRateWrong =  pctOff > (refreshRateTolerancePct/100.)
            if refreshRateWrong:
                refreshMsg1 += ' BUT'
                refreshMsg1 += ' program assumes ' + str(refreshRate)
                refreshMsg2 =  'which is off by more than' + str(round(refreshRateTolerancePct,0)) + '%!!'
            else:
                refreshMsg1 += ', which is close enough to desired val of ' + str( round(refreshRate,1) )
            myWinRes = myWin.size
            myWin.allowGUI =True
            myWin.close() #have to close window to show dialog box
##
### END Setup of the screen parameters    ##############################################################################################
####################################
askUserAndConfirmExpParams = True

if autopilot:
    subject = 'autoTest'
###############################
### Ask user exp params    ##############################################################################################
## askUserAndConfirmExpParams
if askUserAndConfirmExpParams:
    dlgLabelsOrdered = list() #new dialog box
    myDlg = gui.Dlg(title=expname, pos=(200,400))
    if not autopilot:
        myDlg.addField('Subject code :', subject)
        dlgLabelsOrdered.append('subject')
    else:
        myDlg.addField('Subject code :', subject)
        dlgLabelsOrdered.append('subject')
        myDlg.addField('autoPilotTime:', 0, tip='Auto response time relative to cue')
        myDlg.addField('randomTime:',False, tip = 'Add (rounded) gaussian N(0,2) error to time offset?')
        myDlg.addField('autoPilotSpace:',0, tip='Auto response position relative to cue')
        myDlg.addField('randomSpace:',False, tip = 'Add (rounded) gaussian N(0,2) error to space offset?')
        dlgLabelsOrdered.append('autoPilotTime')
        dlgLabelsOrdered.append('randomTime')
        dlgLabelsOrdered.append('autoPilotSpace')
        dlgLabelsOrdered.append('randomSpace')
    myDlg.addField('Trials per condition (default=' + str(trialsPerCondition) + '):', trialsPerCondition, tip=str(trialsPerCondition))
    myDlg.addField('Central task', False)
    dlgLabelsOrdered.append('trialsPerCondition')
    dlgLabelsOrdered.append('Central task')
    myDlg.addText(refreshMsg1, color='Black')
    if refreshRateWrong:
        myDlg.addText(refreshMsg2, color='Red')
    msgWrongResolution = ''
    if checkRefreshEtc and (not demo) and (myWinRes != [widthPix,heightPix]).any():
        msgWrongResolution = 'Instead of desired resolution of '+ str(widthPix)+'x'+str(heightPix)+ ' pixels, screen apparently '+ str(myWinRes[0])+ 'x'+ str(myWinRes[1])
        myDlg.addText(msgWrongResolution, color='Red')
        print(msgWrongResolution); logging.info(msgWrongResolution)
    myDlg.addText('Note: to abort press ESC at response time', color='DimGrey') #works in PsychoPy1.84
    #myDlg.addText('Note: to abort press ESC at a trials response screen', color=[-1.,1.,-1.]) #color names not working for some pre-1.84 versions
    myDlg.show()
    if myDlg.OK: #unpack information from dialogue box
       thisInfo = myDlg.data #this will be a list of data returned from each field added in order
       name=thisInfo[dlgLabelsOrdered.index('subject')]
       if len(name) > 0: #if entered something
         subject = name #change subject default name to what user entered
       trialsPerCondition = int( thisInfo[ dlgLabelsOrdered.index('trialsPerCondition') ] ) #convert string to integer
       print('trialsPerCondition=',trialsPerCondition)
       centralTask = thisInfo[dlgLabelsOrdered.index('Central task')]
       logging.info('trialsPerCondition ='+str(trialsPerCondition))
       if autopilot:
           autoSpace = thisInfo[dlgLabelsOrdered.index('autoPilotSpace')]
           autoTime = thisInfo[dlgLabelsOrdered.index('autoPilotTime')]
           randomTime = thisInfo[dlgLabelsOrdered.index('randomTime')]
           randomSpace = thisInfo[dlgLabelsOrdered.index('randomSpace')]
else:
       print('User cancelled from dialog box.'); logging.info('User cancelled from dialog box')
       logging.flush()
       core.quit()
### Ask user exp params
## END askUserAndConfirmExpParams ###############################
##############################################################################################

if os.path.isdir('.'+os.sep+'dataRaw'):
    dataDir='dataRaw'
else:
    msg= 'dataRaw directory does not exist, so saving data in present working directory'
    print(msg); logging.info(msg)
    dataDir='.'
timeAndDateStr = time.strftime("%d%b%Y_%H-%M", time.localtime())
fileNameWithPath = dataDir+os.sep+subject+ '_' + expname+timeAndDateStr
if not demo and not exportImages:
    saveCodeCmd = 'cp \'' + sys.argv[0] + '\' '+ fileNameWithPath + '.py'
    os.system(saveCodeCmd)  #save a copy of the code as it was when that subject was run
    logF = logging.LogFile(fileNameWithPath+'.log',
        filemode='w',#if you set this to 'a' it will append instead of overwriting
        level=logging.INFO)#info, data, warnings, and errors will be sent to this logfile
if demo or exportImages:
  logging.console.setLevel(logging.ERROR)  #only show this level's and higher messages
logging.console.setLevel(logging.WARNING) #DEBUG means set the console to receive nearly all messges, INFO is for everything else, INFO, EXP, DATA, WARNING and ERROR
if refreshRateWrong:
    logging.error(refreshMsg1+refreshMsg2)
else: logging.info(refreshMsg1+refreshMsg2)
longerThanRefreshTolerance = 0.27
longFrameLimit = round(1000./refreshRate*(1.0+longerThanRefreshTolerance),3) # round(1000/refreshRate*1.5,2)
msg = 'longFrameLimit='+ str(longFrameLimit) +' Recording trials where one or more interframe interval exceeded this figure '
logging.info(msg); print(msg)
if msgWrongResolution != '':
    logging.error(msgWrongResolution)

myWin = openMyStimWindow(mon,widthPix,heightPix,bgColor,allowGUI,units,fullscrn,scrn,waitBlank)

runInfo = psychopy.info.RunTimeInfo(
        win=myWin,    ## a psychopy.visual.Window() instance; None = default temp window used; False = no win, no win.flips()
        refreshTest='grating', ## None, True, or 'grating' (eye-candy to avoid a blank screen)
        verbose=True, ## True means report on everything
        userProcsDetailed=True  ## if verbose and userProcsDetailed, return (command, process-ID) of the user's processes
        )
msg = 'second window opening runInfo mean ms='+ str( runInfo["windowRefreshTimeAvg_ms"] )
logging.info(msg); print(msg)
logging.info(runInfo)
logging.info('gammaGrid='+str(mon.getGammaGrid()))
logging.info('linearizeMethod='+str(mon.getLinearizeMethod()))


####Functions. Save time by automating processes like stimulus creation and ordering
############################################################################

def oneFrameOfStim(n, itemFrames, SOAFrames, cueFrames, cuePos, shuffledStimuli, centralStimuli,centralTask):
    #n: the frame
    #trialObjects:  List of stimuli to display
    #cuePos: cue serial temporal position
    #cueFrames: Number of frames to display the cue
    #itemFrames: Number of frames to display the item
    #SOAFrames: Stimulus Onset Asynchrony in frames
    cueFrame = cuePos * SOAFrames
    cueMax = cueFrame + cueFrames
    showIdx = int(np.floor(n/SOAFrames))
    periObj = shuffledStimuli[showIdx]
    if centralTask:
        centralObj = centralStimuli[showIdx]
    drawObject = n%SOAFrames < itemFrames
    if drawObject and not centralTask:
        if n >= cueFrame and n < cueMax:
            obj.draw()
            cue.draw()
        else:
            obj.draw()
    elif drawObject and centralTask:
        periObj.draw(); centralObj.draw()
    return True


def oneTrial(stimuli, centralTask,randomInteger, cuePos):
    if centralTask:
        dotOrder = np.arange(len(stimuli[0]))
        np.random.shuffle(dotOrder)
        shuffledStimuli = [stimuli[0][i] for i in dotOrder]
        centralOrder = np.arange(len(stimuli[0]))
        np.random.shuffle(centralOrder)
        centralStimuli = [stimuli[1][i] for i in centralOrder]
        replacedText = centralStimuli[cuePos].text
        #deepcopying the central stimuli throws a series of attribute errors. 
        #But because what we do here creates a reference to, rather than a copy of, the global object
        #we end up with numerals in the global stimuli[1] object that need replacing
        centralStimuli[cuePos].text = str(randomInteger)
    else:
        dotOrder = np.arange(len(stimuli))
        np.random.shuffle(dotOrder)
        shuffledStimuli = [stimuli[i] for i in dotOrder]
        centralStimuli = [] #an empty list to avoid too many if else statements
    ts = []
    myWin.flip(); myWin.flip() #Make sure raster at top of screen (unless not in blocking mode), and give CPU a chance to finish other tasks
    t0 = trialClock.getTime()
    for n in range(trialFrames):
        if not centralTask:
            fixation.draw()
        oneFrameOfStim(n, itemFrames, SOAFrames, cueFrames, cuePos, shuffledStimuli, centralStimuli, centralTask)
        myWin.flip()
        ts.append(trialClock.getTime() - t0)
    return True, shuffledStimuli, dotOrder, ts, centralStimuli, replacedText

def getResponse(trialStimuli):
    if autopilot:
        spacing = 360./nDots
        autoResponseIdx = cuePos + autoTime #The serial position of the response in the stream
        if randomTime:
            autoResponseIdx += int(round( np.random.normal(0,2) ))
        itemAtTemporalSelection = trialStimuli[autoResponseIdx]
        unshuffledPositions = [dot.pos.tolist() for dot in stimuli]
        itemSpatial = unshuffledPositions.index(itemAtTemporalSelection.pos.tolist())
        itemSpatial = itemSpatial + autoSpace
        if randomSpace:
            itemSpatial += int(round( np.random.normal(0,2) ))
        while itemSpatial>23:
            itemSpatial = itemSpatial - 23
        #Once we have temporal pos of selected item relative to start of the trial
        #Need to get the serial spatial pos of this item, so that we can select items around it based on the autoSpace offset
        selectionTemporal = trialStimuli.index(stimuli[itemSpatial]) #This seems redundant, but it tests that the item we've selected in space is the cued item in time. if the temporal and spatial offsets are 0, it should be the same as cuePos.
        accuracy = cuePos == selectionTemporal
        mousePos = (stimuli[itemSpatial].pos[0],stimuli[itemSpatial].pos[1])
        expStop = False
        item = stimuli[itemSpatial]
        return accuracy, item, expStop, mousePos
    elif not autopilot:
        myMouse = event.Mouse(visible = False,win=myWin)
        responded = False
        expStop = False
        event.clearEvents()
        mousePos = (1e6,1e6)
        escape = event.getKeys()
        myMouse.setPos((0,0))
        myMouse.setVisible(True)
        while not responded:
            for item in trialStimuli:
                item.draw()
            instruction.draw()
            if drawProgress: #Draw progress message
                progress.draw()
            myWin.flip()
            button = myMouse.getPressed()
            mousePos = myMouse.getPos()
            escapeKey = event.getKeys()
            if button[0]:
                print('click detected')
                responded = True
                print('getResponse mousePos:',mousePos)
            elif len(escapeKey)>0:
                if escapeKey[0] == 'q':
                    expStop = True
                    responded = True
                    return False, np.random.choice(trialStimuli), expStop, (0,0)
        clickDistances = []
        for item in trialStimuli:
            x = mousePos[0] - item.pos[0]
            y = mousePos[1] - item.pos[1]
            distance = sqrt(x**2 + y**2)
            clickDistances.append(distance)
        if not expStop:
            minDistanceIdx = clickDistances.index(min(clickDistances))
            accuracy = minDistanceIdx == cuePos
            item = trialStimuli[minDistanceIdx]
            myMouse.setVisible(False)
        return accuracy, item, expStop, mousePos


def drawStimuli(nDots, radius, center, stimulusObject, centralTask,  sameEachTime = True):
    if len(center) > 2 or len(center) < 2:
        print('Center coords must be list of length 2')
        return None
    if not sameEachTime and not isinstance(stimulusObject, (list, tuple)):
        print('You want different objects in each position, but your stimuli is not a list or tuple')
        return None
    if not sameEachTime and isinstance(stimulusObject, (list, tuple)) and len(stimulusObject)!=nDots:
        print('You want different objects in each position, but the number of positions does not equal the number of items')
        return None
    spacing = 360./nDots
    stimuli = []
    centralLetters = np.random.choice([char for char in ascii_uppercase], nDots, replace = False)
    centralStimuli = []
    for dot in range(nDots): #have to specify positions for multiples of 90deg because python (computers in general?) can't store exact value of pi and thus cos(pi/2) = 6.123e-17, not 0
        if centralTask:
            centralStimuli.append(visual.TextStim(myWin,text = centralLetters[dot],pos=(0,0),colorSpace='rgb',color=(1,1,1),alignHoriz='center', alignVert='center',height=ltrHeight,units=units))
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
        if sameEachTime:
            stim = copy.copy(stimulusObject)
        elif not sameEachTime:
            stim = stimulusObject[dot]
        stim.pos = (xpos,ypos)
        stimuli.append(stim)
    if centralTask:
        return [stimuli, centralStimuli]
    else:
        return stimuli

def checkTiming(ts):
    interframeIntervals = np.diff(ts) * 1000
    #print(interframeIntervals)
    frameTimeTolerance=.3 #proportion longer than refreshRate that will not count as a miss
    longFrameLimit = np.round(1000/refreshRate*(1.0+frameTimeTolerance),2)
    idxsInterframeLong = np.where( interframeIntervals > longFrameLimit ) [0] #frames that exceeded 150% of expected duration
    numCasesInterframeLong = len( idxsInterframeLong )
    if numCasesInterframeLong > 0:
        print(numCasesInterframeLong,'frames of', trialFrames,'were longer than',str(1000/refreshRate*(1.0+frameTimeTolerance)))
    return numCasesInterframeLong



######Create visual objects, noise masks, response prompts etc. ###########
######Draw your stimuli here if they don't change across trials, but other parameters do (like timing or distance)
######If you want to automate your stimuli. Do it in a function below and save clutter.
######For instance, maybe you want random pairs of letters. Write a function!
###########################################################################
#Calculate size of stimuli in original experiment
OGWidth = 1024
OGHeight = 768
OGDiag = sqrt(OGWidth**2 + OGHeight**2)
OGDiagInch = 17
OGDiagCM = OGDiagInch * 2.54
OGpixelPerDegree = OGDiag/((atan(OGDiagCM/57.))*(180/np.pi))
print('OGPPD', OGpixelPerDegree)



radiusPix = 200
radius = radiusPix/OGpixelPerDegree #circle radius
center = (0,0) #circle centre


fixSize = .1
fixation= visual.Circle(myWin, radius = fixSize , fillColor = (1,1,1), units=units)

cueRadiusPix = 360
cueRadiusDeg = cueRadiusPix/OGpixelPerDegree
cue = visual.Circle(myWin, radius = cueRadiusDeg, fillColor = None, lineColor = (1,1,1), units = units)

instruction = visual.TextStim(myWin,pos=(0, -(radius+1)),colorSpace='rgb',color=(1,1,1),alignHoriz='center', alignVert='center',height=.75,units=units)
instructionText = 'Click the dot that was on screen with the cue.'
instruction.text = instructionText

progress = visual.TextStim(myWin,pos=(0, -(radius+2.5)),colorSpace='rgb',color=(1,1,1),alignHoriz='center', alignVert='center',height=.75,units=units)

##Set up stimuli
stimulusSizePix = 20.
stimulusSizeDeg = stimulusSizePix/OGpixelPerDegree
stimulus = visual.Circle(myWin, radius = stimulusSizeDeg, fillColor = (1,1,1) )
nDots = 24
ltrHeight = 2 #deg

sameEachTime = True #same item each position?

if stimulusType=='circle':
    stimulus = visual.Circle(myWin, radius = stimulusSizeDeg, units = units, fillColor = (1,1,1) )
    stimuli = drawStimuli(nDots, radius, center, stimulus, centralTask, sameEachTime)
    stimForDataFile = 'circle'
if stimulusType=='letter':
    letter = np.random.choice([i for i in ascii_uppercase], size = 1)[0]
    stimulus = visual.TextStim(myWin, text = letter, font ='Sloan', height = stimulusSizeDeg*2, units = units,  color = (1,1,1), alignHoriz='center', alignVert='center' )
    stimuli = drawStimuli(nDots, radius, center, stimulus, sameEachTime)
    stimForDataFile = letter

###Trial timing parameters
SOAMS = 66.667
itemMS = 22.222
ISIMS = SOAMS - itemMS
trialMS = SOAMS * nDots
cueMS = itemMS

SOAFrames = int(np.floor(SOAMS/(1000./refreshRate)))
itemFrames =  int(np.floor(itemMS/(1000./refreshRate)))
ISIFrames =  int(np.floor(ISIMS/(1000./refreshRate)))

trialFrames = int(nDots*SOAFrames)

cueFrames = int(np.floor(cueMS/(1000./refreshRate)))
print('cueFrames=',cueFrames)
print('itemFrames=',itemFrames)
print('refreshRate =', refreshRate)
print('cueMS from frames =', cueFrames*(1000./refreshRate))
print('num of SOAs in the trial:', trialFrames/SOAFrames)

#######################
## Factorial design ###
#######################
numResponsesPerTrial = 1 #default. Used to create headers for dataFile
stimList = []
#cuePositions = [dot for dot in range(nDots) if dot not in [0,nDots-1]]
cuePositions = [pos for pos in range(8,17)]
print('cuePositions: ',cuePositions)
#cuePositions = cuePositions[2:(nDots-3)] #drop the first and final two dots
#Set up the factorial design (list of all conditions)

for cuePos in cuePositions:
    stimList.append({'cuePos':cuePos})

trials = data.TrialHandler(stimList, nReps = trialsPerCondition) #trialsPerCondition on line 80 so that it's in the setup dialogue box. Change it there to change dialogue box default. 


####Create output file###
#########################################################################
dataFile = open(fileNameWithPath + '.txt', 'w')
numResponsesPerTrial = 1

#headers for initial datafile rows, they don't get repeated. These appear in the file in the order they appear here.
oneOffHeaders = [
    'subject',
    'task',
    'staircase',
    'trialNum',
    'stimulus',
    'monitorWidth',
    'monitorHeight',
    'stimHeight ',
    'ISI',
    'SOA',
    'centralTask',
    'centralStream'
]

for header in oneOffHeaders:
    print(header, '\t', end='', file=dataFile)

#Headers for duplicated datafile rows. These are repeated using numResponsesPerTrial. For instance, we might have two responses in a trial.
duplicatedHeaders = [
    'responseSpatialPos',
    'responseX',
    'responseY',
    'correctX',
    'correctY',
    'clickX',
    'clickY',
    'accuracy',
    'responsePosInStream',
    'correctPosInStream'
]

if numResponsesPerTrial == 1:
    for header in duplicatedHeaders:
        print(header, '\t', end='', file=dataFile)

elif numResponsesPerTrial > 1:
    for response in range(numResponsesPerTrial):
        for header in duplicatedHeaders:
            print(header+str(response), '\t', end='', file=dataFile)

for pos in range(nDots):
    print('position'+str(pos),'\t',end='',file=dataFile)

#Headers done. Do a new line
print('longFrames',file=dataFile)

expStop = False
drawProgress = False #draw the progress message?

trialNum=0; numTrialsCorrect=0;  framesSaved=0;
print('Starting experiment of',trials.nTotal,'trials. Current trial is trial ',trialNum)
#NextRemindCountText.setText( str(trialNum) + ' of ' + str(trials.nTotal)     )
#NextRemindCountText.draw()
myWin.flip()
#end of header
trialClock = core.Clock()
stimClock = core.Clock()

if eyeTracking:
    if getEyeTrackingFileFromEyetrackingMachineAtEndOfExperiment:
        eyeMoveFile=('EyeTrack_'+subject+'_'+timeAndDateStr+'.EDF')
    tracker=Tracker_EyeLink(myWin,trialClock,subject,1, 'HV5',(255,255,255),(0,0,0),False,(widthPix,heightPix))

while trialNum < trials.nTotal and expStop==False:
    print(float(trialNum)/trials.nTotal)
    if trials.nTotal > 0 and trialNum > 0:
        if(float(trialNum)/trials.nTotal)%.2 == 0:
            print('setting progress text')
            progress.text = 'You have completed ' + str(trialNum) + ' of ' + str(trials.nTotal) + ' trials.'
            drawProgress = True
        else:
            drawProgress = False
    fixation.draw()
    myWin.flip()
    if not autopilot:
        core.wait(1)
    trial = trials.next()
#    print('trial idx is',trials.thisIndex)
    cuePos = trial.cuePos
#    print(cuePos)
    print("Doing trialNum",trialNum)
    randomInteger = np.random.random_integers(1,9,1)[0]
    trialDone, trialStimuli, trialStimuliOrder, ts, centralStimuli, replacedText = oneTrial(stimuli,centralTask,randomInteger, cuePos)
    print('centralStimuli global')
    print([i.text for i in centralStimuli])
    print('stimuli[1] global')
    print([i.text for i in stimuli[1]])
    #Shift positions so that the list starts at 1, which is positioned at (0,radius), and increases clockwise. This is what the MM code expects
    MMPositions = list() #Mixture modelling positions
    for dotPos in trialStimuliOrder:
        if dotPos < (nDots/4):
            MMPositions.append(dotPos + 19)
        elif dotPos >= (nDots/4):
            MMPositions.append(dotPos -5)
    nBlips = checkTiming(ts)

    if trialDone:
        accuracy, response, expStop, clickPos = getResponse(trialStimuli)
        responseCoord = response.pos.tolist()
        if centralTask:
            spatialCoords= [item.pos.tolist() for item in stimuli[0]]
        else:
            spatialCoords= [item.pos.tolist() for item in stimuli]
        try:
            responseSpatialRelativeToXAxis  = spatialCoords.index(responseCoord)
        except ValueError:
            print('coord not in list')
        if responseSpatialRelativeToXAxis < (nDots/4):
            responseSpatial = responseSpatialRelativeToXAxis + 19
        elif responseSpatialRelativeToXAxis >= (nDots/4):
            responseSpatial = responseSpatialRelativeToXAxis - 5
        trialPositions = [item.pos.tolist() for item in trialStimuli]
        responseTemporal = trialPositions.index(responseCoord)
#        print('trial positions in sequence:',trialPositions)
#        print('position of item nearest to click:',responseSpatial)
#        print('Position in sequence of item nearest to click:',responseTemporal)

        correctSpatial = trialStimuli[cuePos].pos
        correctTemporal = cuePos
        print(subject,'\t',
        'dot-jump','\t',
        False,'\t',
        trialNum,'\t',    
        stimForDataFile,'\t',
        widthPix,'\t',
        heightPix,'\t',
        stimulusSizeDeg*2,'\t',
        ISIMS,'\t',
        SOAMS,'\t',
        centralTask, '\t', 
        sep='', 
        end='', 
        file=dataFile)

        if centralTask:
            print(''.join([i.text for i in centralStimuli]),'\t', sep='', end='', file=dataFile)
        else:
            print('NA','\t', sep='', end='', file=dataFile)
        
        print(
        responseSpatial,'\t',
        responseCoord[0],'\t',
        responseCoord[1],'\t',
        correctSpatial[0],'\t',
        correctSpatial[1],'\t',
        clickPos[0],'\t',
        clickPos[1],'\t',
        accuracy,'\t',
        responseTemporal,'\t',
        correctTemporal,'\t',
        sep='',
        end='',
        file = dataFile
        )
        for dot in range(nDots):
            print(MMPositions[dot], '\t',sep='',end='', file=dataFile)
        print(nBlips, file=dataFile)
        globalReplaced = [position for position,item in enumerate(stimuli[1]) if item.text.isdigit()][0] #which of the items in the global stimuli object has been replaced by a digit?
        print(globalReplaced)
        stimuli[1][globalReplaced].text = replacedText #otherwise you get n digit stimuli on trial n
        trialNum += 1
        dataFile.flush()
if expStop:
    print('Participant cancelled experiment on trial', trialNum)
    dataFile.flush()
