library(ggplot2)
library(reshape2)

rm(list=ls())

setwd('~/gitCode/dot-jump/dataRaw/Endogenous Cue/')
dataFiles <- list.files(pattern='.txt')

nLines <- length(dataFiles)*250
# for(rawFile in dataFiles){
#   print(rawFile)
#   print(length(readLines(rawFile))-1)
#   nLines <- nLines+(length(readLines(rawFile))-250)-1
# }

types <- lapply(read.table(dataFiles[1], sep='\t', header=T, stringsAsFactors = F), class)
fullData <- data.frame(matrix(NA, nrow=nLines, ncol=length(types)))
for(col in 1:length(types)){
  if(types[col][[1]]!='factor'){
    fullData[,col] <- as.vector(fullData[,col], mode = types[col][[1]])
  }
}
colnames(fullData) <- colnames(read.table(dataFiles[1], sep='\t', header=T))

abortedPracticeAttempts <- c()

startRow <- 1
for(rawFile in dataFiles){
  temp <- read.table(rawFile, sep='\t', header =T, stringsAsFactors = F)
  if(nrow(temp)<250) abortedPracticeAttempts <- c(abortedPracticeAttempts, rawFile)
  else{
    discard <- nrow(temp) - 250
    print(paste(rawFile, discard))
    temp <- temp[-c(1:discard),]
    endRow <- nrow(temp)+startRow-1
    fullData[startRow:endRow,] <- temp
    startRow <- endRow + 1 
  }
}

fullData$accuracy <- as.logical(gsub(' ','',fullData$accuracy))

fullData$error <- fullData$responsePosInStream - fullData$correctPosInStream

ggplot(fullData, aes(x=error))+
  geom_histogram(binwidth=1)+
  facet_wrap(~subject)


numPositions <- 24

#spacing of those positions
spacing <- (2*pi)/numPositions

#Left out cuePos from experiment dataFile, this recovers it
fullData$correctSpatial <- NA
for(row in 1:nrow(fullData)){
  fullData$correctSpatial[row] <- fullData[row, paste0('position', fullData$correctPosInStream[row])]
}

positionCols <- paste0('position', 0:23)

#column ordering for matlab
expectedFormat <- fullData[,c('subject', 'correctSpatial','responseSpatialPos', 'correctPosInStream','responsePosInStream',positionCols)]


#Shift the positions to match the matlab code's expectations (I'll change this in the experiment code eventually)
for(col in 2:ncol(expectedFormat)){
  temp <- expectedFormat[,col] #Sometimes there are weird formatting errors. Doubles or floats that the MM code can't deal with. So select every collumn and make it an int vector
  if(col %in% c(4,5)){ #If it's a time column
    temp <- temp + 1
  }
  temp <- as.integer(temp)
  expectedFormat[,col] <- temp
}

for(ID in unique(expectedFormat$subject)){
  temp <- expectedFormat[expectedFormat$subject==ID,-1]
  ID <- gsub(' ','',ID) #Why does python include so many extra spaces in character columns?
  write.table(temp, paste0('../../data/wrangled/endogenousCue/',ID,'.txt'), sep='\t', row.names = F, col.names = F)
}