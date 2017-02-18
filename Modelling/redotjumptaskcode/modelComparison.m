clear all;

% Add directories
usePath = '~/gitCode/dot-jump/';
likelihoodDirectory = 'data/modelOutput/';
addpath(usePath)

% Task parameters
sampleNames = {'endogenousCue','variableCue'};
modelNames = {'logNormal','normal'};

nSamples = numel(sampleNames);
nParticipants = [2 5];
nModels = numel(modelNames);
nParams = 3;

% allBIC(:,:,1) = logNormal BIC
% allBIC(:,:,2) = normal BIC
allBICs = NaN(nSamples, max(nParticipants), nModels);


cd([usePath likelihoodDirectory])

for thisModel = 1:nModels
    load([modelNames{thisModel} 'ModelLikelihood'])
    for thisSample = 1:nSamples
       for thisParticipant = 1:nParticipants(thisSample)
           [thisAIC thisBIC] = aicbic(-allMinNegLogLikelihoods_byParticipant(thisSample, thisParticipant),nParams, allNTrials_byParticipant(thisSample, thisParticipant));
           allBICs(thisSample, thisParticipant, thisModel) = thisBIC;
       end
    end
end

deltaBIC = allBICs(:,:,1) - allBICs(:,:,2);