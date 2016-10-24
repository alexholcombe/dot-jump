#Generate data for dot-jump mixture modelling
folderName <- 'simulatedData'

folderPresent <- any(dir()==folderName)
if(!folderPresent){dir.create(folderName)}

nTrials <- 250
nItems <- 24
spatialOffset <- 0
temporalOffset <- 0
participants <- 3
groupName <- paste0('spatial',spatialOffset,'Temporal',temporalOffset,'Participant')

trialData <- data.frame(matrix(data=NA, nrow=(nTrials*participants), ncol = (nItems+4)))


for(participant in 1:participants){
  for(trial in 1:nTrials){
    trial <- (participant-1)*nTrials+trial
    print(trial)
    trialData[trial,3] <- 11
    trialData[trial,5:28] <- sample(1:24)
    trialData[trial,1] <- trialData[trial,(trialData[trial,3]+4)] #spatial position of cued item
    trialData[trial,2] <- trialData[trial,1]+spatialOffset #response in space
    trialData[trial,4] <- trialData[trial,3]+temporalOffset #response in time
  }
}

for(participant in 1:participants){
  startRow <- participant*nTrials-(nTrials-1)
  endRow <- participant*nTrials
  print(paste('startRow', startRow, 'endRow', endRow))
  write.table(trialData[startRow:endRow,], paste0(folderName,'/',groupName,participant,'.txt'),row.names = FALSE,col.names = FALSE,sep='\t')
  
}