library(ggplot2)

setwd('~/gitCode/dot-jump/dataRaw/Endogenous Cue/')

for(file in list.files(pattern='.txt')){
  charlie <- read.table(file, sep='\t', header =T)
}

charlie$accuracy <- as.logical(charlie$accuracy)
charlie$error <- charlie$responsePosInStream - charlie$correctPosInStream
charlie$errorMS <- charlie$error*66.667

charliePlot <- ggplot(charlie, aes(x=errorMS))+
  geom_histogram(binwidth = 66.667)+
  scale_x_continuous(breaks=round(((-17:16)*66.667),1))

ggsave('endogenousDotJump.png', charliePlot, height = 15, width = 15)