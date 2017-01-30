#Convert positions from the experiment output, which is 0 at (radius, 0) and
#increases clockwise around the circle, to the position expected by the matlab
#code, which is 1 at (0, radius) and increases clockwise around the circle

#Within a single row, the original data has this format:
### T1-P: spatial position of cued item
### T1-repP: spatial position response
### T1-T: temporal position of cued item, starts at 1
### T1-repP: temporal position of response
### then 24 cells, each representing an item in the stream. The serial position of the cell represents the temporal position of the item
rm(list = ls())
setwd('~/gitCode/dot-jump/data/')



groupName = 'Pilot'

if(!dir.exists(groupName)) dir.create(groupName)

dataFiles <- list.files()
dataFiles <- dataFiles[grep(pattern = paste0(groupName,'(?=[0-9])'), x = dataFiles, perl=T)]

for(participant in 1:length(dataFiles)){
  #clean up the accuracy column
  testData <- read.table(paste0(groupName,participant,'.txt'),sep='\t', stringsAsFactors = F, header = T)
  assign(paste0('part',participant), testData)
  testData$accuracy <- gsub(pattern = ' ',replacement = '',x = testData$accuracy)
  testData$accuracy <- as.logical(testData$accuracy)
  
  #number of positions on the circle
  numPositions <- 24
  
  #spacing of those positions
  spacing <- (2*pi)/numPositions
  
  #compute the serial spatial position of the response on the circle, and get the serial spatial position of the correct answer
  responseSpatial <- c()
  correctSpatial <- c()
  
  for(row in 1:nrow(testData)){
    correctSpatial <- c(correctSpatial,
                        testData[row, 'position10']
                        )
  }
  
  #add this information to the data
  testData$correctSpatial <- correctSpatial
  
  #Within a single row, the original data has this format:
  ### T1-P: spatial position of cued item
  ### T1-repP: spatial position response
  ### T1-T: temporal position of cued item, starts at 1
  ### T1-repT: temporal position of response
  ### then 24 cells, each representing an item in the stream. The serial position of the cell represents the temporal position of the item
  
  positionCols <- paste0('position', 0:23)
  
  #column ordering for matlab
  expectedFormat <- testData[,c('correctSpatial','responseSpatialPos', 'correctPosInStream','responsePosInStream',positionCols)]
  
  
  #Shift the positions to match the matlab code's expectations (I'll change this in the experiment code eventually)
  for(col in 1:ncol(expectedFormat)){
    temp <- expectedFormat[,col] #Sometimes there are weird formatting errors. Doubles or floats that the MM code can't deal with. So select every collumn and make it an int vector
    if(col %in% c(3,4)){ #If it's a time column
      temp <- temp + 1
    }
    temp <- as.integer(temp)
    expectedFormat[,col] <- temp
  }
  
  
  write.table(x = expectedFormat, file = paste0(groupName,'/', groupName,'Circle',participant,'.txt'), sep='\t',row.names = F, col.names = F)
}