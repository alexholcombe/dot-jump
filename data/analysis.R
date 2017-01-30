library(ggplot2)
library(reshape2)

rm(list=ls())

setwd('~/gitCode/dot-jump/data/')
dataFiles <- list.files(pattern='.txt')

nLines <- 0
for(rawFile in dataFiles){
  nLines <- nLines + length(readLines(rawFile))-1
}

types <- lapply(read.table(dataFiles[1], sep='\t', header=T, stringsAsFactors = F), class)
fullData <- data.frame(matrix(NA, nrow=nLines, ncol=length(types)))
for(col in 1:length(types)){
  if(types[col][[1]]!='factor'){
    fullData[,col] <- as.vector(fullData[,col], mode = types[col][[1]])a
  }
}
colnames(fullData) <- colnames(read.table(dataFiles[1], sep='\t', header=T))

startRow <- 1
for(rawFile in dataFiles){
  endRow <- length(readLines(rawFile))+startRow-2
  fullData[startRow:endRow,] <- read.table(rawFile, sep='\t', header =T, stringsAsFactors = F)
  startRow <- endRow + 1
}

fullData$accuracy <- as.logical(gsub(' ','',fullData$accuracy))

fullData$error <- fullData$responsePosInStream - fullData$correctPosInStream

ggplot(fullData, aes(x=error))+
  geom_histogram(binwidth=1)+
  facet_wrap(~subject)
