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
setwd('~/gitCode/dot-jump/')

testData <- read.table('testData/charliefixedcue.txt',sep='\t', stringsAsFactors = F, header = T)

#clean up the accuracy column
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
  responseX <- testData$responseX[row]
  responseY <- testData$responseY[row]
  
  if(!0 %in% c(responseX, responseY)){
    angle <-  atan2(responseY, responseX) #rad
    if(angle<0){
      angle <- 2*pi - abs(angle)
    }  
  }else if(responseX==0 & responseY>0){
    angle = pi/2
  }else if(responseX==0 & responseY<0){
    angle = (3*pi)/2
  }else if(responseX>0 & responseY==0){
    angle = 0
  }else if(responseX<0 & responseY==0){
    angle = pi
  }
  thisResponseSpatial <- round(angle/spacing)
  thisResponseSpatial <- thisResponseSpatial
  print(paste(responseX, responseY, angle, thisResponseSpatial))
  responseSpatial <- c(responseSpatial, thisResponseSpatial)
  correctSpatial <- c(correctSpatial, 
                      testData[row, 'position10']
                      )
}

#add this information to the data
testData$responseSpatial <- responseSpatial
testData$correctSpatial <- correctSpatial

#Within a single row, the original data has this format:
### T1-P: spatial position of cued item
### T1-repP: spatial position response
### T1-T: temporal position of cued item, starts at 1
### T1-repT: temporal position of response
### then 24 cells, each representing an item in the stream. The serial position of the cell represents the temporal position of the item

positionCols <- paste0('position', 0:23)

#column ordering for matlab
expectedFormat <- testData[,c('correctSpatial','responseSpatial', 'correctPosInStream','responsePosInStream',positionCols)]


#Shift the positions to match the matlab code's expectations (I'll change this in the experiment code eventually)
for(col in 1:ncol(expectedFormat)){
  if(!col %in% c(3,4)){
    temp <- expectedFormat[,col]
    for(item in 1:length(temp)){
      if(temp[item]<5){temp[item] <- temp[item]+20 
      }else if(temp[item]>=5){temp[item] <- temp[item]-4}
    }
  } else{ #If it's a time column
    temp <- expectedFormat[,col]
    temp <- temp + 1
  }
  temp <- as.integer(temp)
  expectedFormat[,col] <- temp
}

colnames(expectedFormat) <- c('T1-P','T1-repP', 'T1-T','T1-repT', rep(NULL, times=24))

write.table(x = expectedFormat, file = 'testData/Charlie/Charlie1.txt', sep='\t',row.names = F, col.names = F)
