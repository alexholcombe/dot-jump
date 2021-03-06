from __future__ import print_function
__author__ = """Alex "O." Holcombe, Charles Ludowici, """ ## double-quotes will be silently removed, single quotes will be left, eg, O'Connor
import time, sys, platform, os
from math import atan, pi, cos, sin, sqrt, ceil
import numpy as np
import psychopy, psychopy.info
from psychopy import visual, sound, monitors, logging, gui, event
try:
    from helpersAOH import accelerateComputer, openMyStimWindow
except Exception as e: 
   print(e); print('Problem loading helpersAOH. Check that the file helpersAOH.py in the same directory as this file')
   print('Current directory is ',os.getcwd())
   
eyeTracking = False
try:
    import eyelinkEyetrackerForPsychopySUPA3   
except Exception as e: 
    print(e)
    print('Problem loading eyelinkEyetrackerForPsychopySUPA3. Check that the file eyelinkEyetrackerForPsychopySUPA3.py in the same directory as this file')
    #Psychopy v1.83.01 mistakenly included an old version of pylink which prevents EyelinkEyetrackerForPsychopySUPA3 stuff from importing
    eyeTracking = False

expname= "dot-jump"
demo = False; exportImages = False
autopilot = False
subject='test'
###############################
### Setup the screen parameters    ##############################################################################################
##
allowGUI = False
units='deg' #'cm'
fullscrn=False
waitBlank=False
if True: #just so I can indent all the below
        refreshRate= 85 *1.0;  #160 #set to the framerate of the monitor
        fullscrn=0; #show in small window (0) or full screen (1) 
        scrn=0 #which screen to display the stimuli. 0 is home screen, 1 is second screen
        # create a dialog from dictionary 
        infoFirst = { 'Autopilot':autopilot, 'Check refresh etc':True, 'Screen to use':scrn, 'Fullscreen (timing errors if not)': fullscrn, 'Screen refresh rate': refreshRate }
        OK = gui.DlgFromDict(dictionary=infoFirst, 
            title='MOT', 
            order=['Autopilot','Check refresh etc', 'Screen to use', 'Screen refresh rate', 'Fullscreen (timing errors if not)'], 
            tip={'Check refresh etc': 'To confirm refresh rate and that can keep up, at least when drawing a grating',
                    'Screen to use': '0 means primary screen, 1 means second screen'},
            )
        if not OK.OK:
            print('User cancelled from dialog box'); logging.info('User cancelled from dialog box'); core.quit()
        autopilot = infoFirst['Autopilot']
        checkRefreshEtc = infoFirst['Check refresh etc']
        scrn = infoFirst['Screen to use']
        print('scrn = ',scrn, ' from dialog box')
        fullscrn = infoFirst['Fullscreen (timing errors if not)']
        refreshRate = infoFirst['Screen refresh rate']
        
        #monitor parameters
        widthPix = 1024 #1440  #monitor width in pixels
        heightPix =768  #900 #monitor height in pixels
        monitorwidth = 40.5 #28.5 #monitor width in centimeters
        viewdist = 55.; #cm
        pixelperdegree = widthPix/ (atan(monitorwidth/viewdist) /np.pi*180)
        bgColor = [-1,-1,-1] #black background
        monitorname = 'testMonitor' # 'mitsubishi' #in psychopy Monitors Center
        
        mon = monitors.Monitor(monitorname,width=monitorwidth, distance=viewdist)#fetch the most recent calib for this monitor
        mon.setSizePix( (widthPix,heightPix) )
        myWin = openMyStimWindow(mon,widthPix,heightPix,bgColor,allowGUI,units,fullscrn,scrn,waitBlank)
        myMouse = event.Mouse(visible = 'true',win=myWin)
        myWin.setRecordFrameIntervals(False)
        
        mon = monitors.Monitor(monitorname,width=monitorwidth, distance=viewdist)#fetch the most recent calib for this monitor
        mon.setSizePix( (widthPix,heightPix) )
        myWin = openMyStimWindow(mon,widthPix,heightPix,bgColor,allowGUI,units,fullscrn,scrn,waitBlank)
        myMouse = event.Mouse(visible = 'true',win=myWin)
        myWin.setRecordFrameIntervals(False)
        
        trialsPerCondition = 2 #default value
        
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
###############################
### Ask user exp params    ##############################################################################################
## askUserAndConfirmExpParams
if askUserAndConfirmExpParams:
    dlgLabelsOrdered = list() #new dialog box
    myDlg = gui.Dlg(title=expname, pos=(200,400))
    if not autopilot:
        myDlg.addField('Subject code :', subject)
        dlgLabelsOrdered.append('subject')
    myDlg.addField('Trials per condition (default=' + str(trialsPerCondition) + '):', trialsPerCondition, tip=str(trialsPerCondition))
    dlgLabelsOrdered.append('trialsPerCondition')
    pctCompletedBreak = 50
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
       if not autopilot:
           name=thisInfo[dlgLabelsOrdered.index('subject')]
           if len(name) > 0: #if entered something
             subject = name #change subject default name to what user entered
           trialsPerCondition = int( thisInfo[ dlgLabelsOrdered.index('trialsPerCondition') ] ) #convert string to integer
           print('trialsPerCondition=',trialsPerCondition)
           logging.info('trialsPerCondition ='+str(trialsPerCondition))
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
fileNameWithPath = dataDir+'/'+subject+ '_' + expname+timeAndDateStr
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
msg='Window opened'; print(msg); logging.info(msg)
myMouse = event.Mouse(visible = 'true',win=myWin)
msg='Mouse enabled'; print(msg); logging.info(msg)
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

stimList = []
#Set up the factorial design (list of all conditions)
for targetOffset in [-1.00, 1.00]: 
                for objToCueQuadrant in range(4):
                    stimList.append( {'numCuesEachRing':numCuesEachRing,'numObjsEachRing':numObjsEachRing,'targetOffset':targetOffset,
                                                'cueLeadTime':cueLeadTime,'speed':speed,'objToCueQuadrant':objToCueQuadrant,'direction':direction} )
                                                
def oneFrameOfStim():
	pass
	
def oneTrial():
	#number of locations
	#SOA, duration
	pass


expStop = False

trialNum=0; numTrialsCorrect=0; expStop=False; framesSaved=0;
print('Starting experiment of',trials.nTotal,'trials. Current trial is trial ',trialNum)
NextRemindCountText.setText( str(trialNum) + ' of ' + str(trials.nTotal)     )
NextRemindCountText.draw()
myWin.flip()
#end of header
trialClock = core.Clock()
stimClock = core.Clock()
thisTrial = trials.next()
ts = list();

if eyetracking:
    if getEyeTrackingFileFromEyetrackingMachineAtEndOfExperiment:
        eyeMoveFile=('EyeTrack_'+subject+'_'+timeAndDateStr+'.EDF')
    tracker=Tracker_EyeLink(myWin,trialClock,subject,1, 'HV5',(255,255,255),(0,0,0),False,(widthPix,heightPix))

while trialNum < trials.nTotal and expStop==False:
	print("Doing trialNum",trialNum)
	