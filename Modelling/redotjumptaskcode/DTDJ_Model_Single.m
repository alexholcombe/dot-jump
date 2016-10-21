% This script fits a single-episode model (M1) to error data from
% a dot-jump (DJ) task.
%
% You should have a folder named 'ModelOutput', where the model output will
% be saved. It will overwrite any saved output with the same name
% ('ModelOutput_DTDJ_ThisSample_Single.mat'). You should also have a folder
% named 'Data', where the compiled data from each sample should be (called 
% something like 'CompiledData_DTDJ_ThisSample.mat'). See the documentation
% for information regarding the format of this data file.
%
% The objective function DTDJ_pdf_Mixture_Single.m should be on the MATLAB 
% path.
%
% You should next run DTDJ_Show_Models to put everything together and get
% your final parameter estimates.
%
% The script requires the Statistics Toolbox.
%
% Plotting requires the function PolarToIm.m by Prakash Manandhar,
% available here:
% http://au.mathworks.com/matlabcentral/fileexchange/17933-polar-to-from-rectangular-transform-of-images/content/PolarRectangularConv0.1/PolarToIm.m
% Otherwise, you can just turn off plotting by setting the variable
% plotFits to 0.

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
% This section contains some things that will need to be set locally,
% depending on your directory structure and your data.

clear all;

% Provide the path
thisPath = '~/gitCode/dot-jump/testData/';

% Provide the path to the PolarToIm function.
addpath(genpath('~/Documents/MATLAB/Add-Ons/PolarRectangularConv0.1/'));
addpath(genpath('~/gitCode/dot-jump/Modelling/redotjumptaskcode/'))

% Provide a name for each sample,
% so files can be read and written with corresponding filenames.
sampleNames = {'Charlie'};

% Provide some properties of the data for each sample, in order
allNParticipants = [1];         % Number of participants
allNPositions = [24];            % Number of items in a stream on each trial
allNConditions = [1];             % Number of conditions

% Set some model-fitting parameters.
nReplicates = 1000;                          % Number of times to repeat each fit with different starting values
smallNonZeroNumber = 10^-5;                 % Useful number for when limits can't be exactly zero but can be anything larger
fitMaxIter = 10^4;                          % Maximum number of fit iterations
fitMaxFunEvals = 10^4;                      % Maximum number of model evaluations

% Set some parameter bounds. You want these large enough that they span the
% full reasonable range of mean (latency) and SD (precision), but small
% enough to prevent over-fitting to blips in the distributions. These
% values are about right in most cases, but might need some tweaking if
% e.g. you were analysing data with an unusually high or low item rate.
muBound_t = 4;      % Time
sigmaBound_t = 4;
muBound_x = pi/2;      % Space (radians)
kappaBounds_x = [1 500]; % The upper bound is just to stop NaNs;

% Ordinarily you wouldn't want to change these, but you might want to 
% provide a different function with a different number of parameters.
nFreeParameters = 5;
pdf_normmixture_single = @DTDJ_pdf_Mixture_Single;

% Just for diagnostics. Setting this to 1 will show the fitted
% distributions for every participant in every condition, so it's not practical
% to run it on large datasets.
plotFits = 1;

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------

% Declare global variables that need to be accessed by the objective
% function.
global xDomain;
global tDomain;
global xDomainPhi;
global theseErrorIndices;

% Add folders to the MATLAB path.
addpath(genpath(thisPath));
cd([thisPath 'Data']);

% Turn off this warning to prevent it from filling the command
% window. This is only a problem if you get it on most
% replicates of a fit.
warning('off', 'stats:mlecov:NonPosDefHessian');

% Determine number of samples
nSamples = numel(sampleNames);

% Cycle through each sample
for thisSample = 1:nSamples
    
    % Load the compiled data file for this sample.
    load(['CompiledData_DTDJ_' sampleNames{thisSample} '.mat']);

    % The following output to the command window is just to keep track of
    % what the program is doing.
    fprintf('\n\n%s\n\n', upper(sampleNames{thisSample}));

    % Build empty matrices for storing parameter estimates for each
    % participant, at each lag. Also build matrices to store upper and
    % lower bounds, and minimum negative log likelihoods.
    
    nParticipants = allNParticipants(thisSample);

    allT1Estimates = NaN(nParticipants,nFreeParameters);
    allT1LowerBounds = NaN(nParticipants,nFreeParameters);
    allT1UpperBounds = NaN(nParticipants,nFreeParameters);
    allT1MinNegLogLikelihoods = NaN(nParticipants,1);
    allT1MinNegLogLikelihoods_NullModel = NaN(nParticipants,1);
    allLRTestPVals = NaN(nParticipants,1);
    allNTrials = NaN(nParticipants,1);

    if plotFits
        pFig = figure('Color','white','Name',sampleNames{thisSample},'units','normalized','outerposition',[0 0 1 1]); %#ok<*UNRCH> %#ok<*MSNU>
        pNo = ceil(sqrt(nParticipants));
    end
    
    % Set fit options.
    options = statset('MaxIter', fitMaxIter, 'MaxFunEvals', fitMaxFunEvals, 'Display', 'iter');

    % Cycle through each participant.
    for thisParticipant = 1:nParticipants

        % Keep track of progress in the command window.
        fprintf('\nParticipant %d... ', thisParticipant);

        % Extract the relevant lists of T1 and T2 errors, T1 and T2 stream
        % positions, and corresponding conditions.
        theseErrorVals = squeeze(allT1ErrorCombinations(thisParticipant,:,:,:));
        allNTrials(thisParticipant) = size(theseErrorVals,1);
        trialList = 1:allNTrials(thisParticipant);
        
        % Calculate the domain of possible errors (xDomain).
        xPosition = unique(theseErrorVals(:,:,2));
        tPosition = unique(theseErrorVals(:,:,1));
        xDomain = min(xPosition):max(xPosition);
        xDomainPhi = pi*(xDomain/max(xDomain));
        tDomain = min(tPosition):max(tPosition);
        
        % Determine indices
        theseErrorVals(:,:,1) = theseErrorVals(:,:,1) - min(min(theseErrorVals(:,:,1))) + 1;
        theseErrorVals(:,:,2) = theseErrorVals(:,:,2) - min(min(theseErrorVals(:,:,2))) + 1;
        theseErrorIndices = sub2ind([length(xDomain) length(tDomain)],theseErrorVals(:,:,2),theseErrorVals(:,:,1));
        
        % Unpack the parameter bounds to feed into the model fitting.
        % These are set near the top of the script, but need to be
        % unpacked for each scenario.

        % Unpack mean (latency) bounds.
        mu_lb_t = -muBound_t;
        mu_ub_t = muBound_t;
        mu_lb_x = -muBound_x;
        mu_ub_x = muBound_x;

        % Unpack SD (precision) bounds.
        sigma_lb_t = 0.1; % Needs to be around this to prevent NaNs
        sigma_ub_t = sigmaBound_t;
        kappa_lb_x = kappaBounds_x(1);
        kappa_ub_x = kappaBounds_x(2);

        % Fit the model to the T1 distribution.

        % Keep track of the minimum negative log likelihood on each
        % replicate. Start at infinity so the first replicate
        % automatically qualifies as the best candidate up to that
        % point.
        minNegLogLikelihood = inf;

        % Cycle through a number of replicates of the fitting
        % procedure with different randomised starting values across
        % the range dictated by the bounds.

        for thisReplicate = 1:nReplicates

            % Randomise starting values for each parameter.
            pGuess = max([smallNonZeroNumber rand]);
            muGuess_x = (2*muBound_x*rand)-muBound_x;
            kappaGuess_x = rand*(kappaBounds_x(2)-kappaBounds_x(1))+kappaBounds_x(1);
            muGuess_t = (2*muBound_t*rand)-muBound_t;
            sigmaGuess_t = sigmaBound_t*rand+smallNonZeroNumber;

            % Compile to feed into the MLE function.
            parameterGuess = [pGuess muGuess_x kappaGuess_x muGuess_t sigmaGuess_t];
            parameterLowerBound = [smallNonZeroNumber mu_lb_x kappa_lb_x mu_lb_t sigma_lb_t];
            parameterUpperBound = [1 mu_ub_x kappa_ub_x mu_ub_t sigma_ub_t];

            % Ensure guesses satisfy bounds, and round them marginally
            % up or down if necessary.
            parameterGuess = max([parameterGuess;parameterLowerBound]);
            parameterGuess = min([parameterGuess;parameterUpperBound]);          
            
            % Run the MLE function. We're feeding it a dummy list of trials
            % so that it is happy, but we're actually using the global
            % variable to pass the relevant data.
            [currentEstimates, currentCIs] = mle(trialList, 'pdf', pdf_normmixture_single, 'start', parameterGuess, 'lower', parameterLowerBound, 'upper', parameterUpperBound, 'options', options);

            % Compute the negative log likelihood of the fitted model.
            thisNegLogLikelihood = -sum(log(pdf_normmixture_single(trialList,currentEstimates(1),currentEstimates(2),currentEstimates(3),currentEstimates(4),currentEstimates(5))));

            % Check whether this is lower than the lowest so far.
            if minNegLogLikelihood > thisNegLogLikelihood

                % If so, store this as the current best estimate.
                minNegLogLikelihood = thisNegLogLikelihood;
                bestEstimates = currentEstimates;
                bestEstimateCIs = currentCIs;

            end

        end

        % Enter the best estimates into the parameter matrices.
        allT1Estimates(thisParticipant,:) = bestEstimates;
        allT1LowerBounds(thisParticipant,:) = bestEstimateCIs(1,:);
        allT1UpperBounds(thisParticipant,:) = bestEstimateCIs(2,:);
        allT1MinNegLogLikelihoods(thisParticipant) = minNegLogLikelihood;

        % Now, compare this against a uniform distribution alone.
        thisNegLogLikelihood_NullModel = -sum(log(pdf_normmixture_single(trialList,0,0,10,0,1)));
        allT1MinNegLogLikelihoods_NullModel(thisParticipant) = thisNegLogLikelihood_NullModel;
        [h,pValue,stat,cValue] = lratiotest(-minNegLogLikelihood,-thisNegLogLikelihood_NullModel,nFreeParameters);
        allLRTestPVals(thisParticipant) = pValue;

        % Plot the distributions if required.
        if plotFits
            figure(pFig);
            subplot(pNo,pNo,thisParticipant);
            
            if h
                normComponent = normpdf(tDomain,bestEstimates(4),bestEstimates(5));
                vmComponent = (1/(2*pi*besseli(0,bestEstimates(2)))).*exp(bestEstimates(3)*cos(xDomainPhi-bestEstimates(2)));

                % Normalise both
                normComponent = normComponent/sum(normComponent);
                vmComponent = vmComponent/sum(vmComponent);

                % Combine and normalise
                fullPDF = vmComponent'*normComponent;
                fullPDF = bestEstimates(1)*(fullPDF/max(fullPDF(:)));
                minPos = .2;
                maxPos = 1;
                imgSize = 200;
                imgRes = 256;
                pdfImage = PolarToIm(rot90(fullPDF,3),minPos,maxPos,imgSize,imgSize);
                pdfImage = ((imgRes-1)/imgRes)*pdfImage;
                imgAxis = linspace(-maxPos,maxPos,imgSize);
                [xx,yy] = meshgrid(imgAxis);
                maskImage = (xx.^2+yy.^2) <= maxPos.^2;
                pdfImage = pdfImage.*maskImage + (1-maskImage);
                image(imgAxis,imgAxis,uint8(255*pdfImage));
                thisMap = cat(1, parula(imgRes-1), [1 1 1]);
                thisMap(imgRes,:) = [1 1 1];
                colormap(thisMap);
                axis image;
                axis off;
                hold on;
                rectangle('Position',[-minPos -minPos 2*minPos 2*minPos],'Curvature',1,'FaceColor','w','LineStyle','none');
                rectangle('Position',[-maxPos -maxPos 2*maxPos 2*maxPos],'Curvature',1,'EdgeColor','w','LineWidth',4);

                targetAngle = -pi/2;
                targetRadius = minPos + (maxPos-minPos)/2 - (maxPos-minPos)/48;
                [xx,yy] = pol2cart(targetAngle,targetRadius);
                scatter3(xx,yy,1,100,'kx');
                scatter3(xx,yy,1,141,'ko');
                
            else
               
                scatter(0,0,'rx');
                axis([-1 1 -1 1]);
                axis square;
                axis off;
                
            end
            
            title(['Participant ' num2str(thisParticipant)]);
            drawnow;
            
        end

    end

    % Keep track of progress in the command window.
    fprintf('\n\n');

    % Change directory to store model output.
    cd([thisPath 'ModelOutput']);
    
    % Save model output.
    save(['ModelOutput_DTDJ_' sampleNames{thisSample} '_Single.mat'], '-regexp', '^(?!(pFig)$).');

end

% Turn this warning back on.
warning('on', 'stats:mlecov:NonPosDefHessian');