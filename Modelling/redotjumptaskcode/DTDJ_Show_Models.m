% This script takes the model outputs generated by DTDJ_Model_Single and
% extracts the parameters from the best model. The script generates summary
% figures of the parameters for each sample.
%
% There should be a folder called 'CSV', where CSV data files suitable for
% reading in to JASP (https://jasp-stats.org/) will be created.
%
% You should have a folder named 'ModelOutput', where the model output from
% DTDJ_Model_Single (which will be called something like 
% 'ModelOutput_DTDJ_ThisSample_Single.mat') should be. You should also have 
% a folder named 'Data', where the compiled data from each sample should be 
% (called something like 'CompiledData_DTDJ_ThisSample.mat').
%
% The script requires the Statistics Toolbox, for the nanmean() function, 
% and possibly some other things.

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
% This section contains some things that will need to be set locally,
% depending on your directory structure and your data.

%add path for functions
addpath(genpath('~/gitCode/dot-jump/Modelling/redotjumptaskcode/'))


% Provide the path.
thisPath = '~/gitCode/dot-jump/testData/';

% Provide a name for each sample,
% so files can be read and written with corresponding filenames.
sampleNames = {'Pilot'};

% Provide some properties of the data for each sample, in order.
allRates = [15];               % Item rate (items/sec)
allNParticipants = [2];       % Number of participants
allNConditions = [1];
nConditions = 1;

% Set the alpha value for t-tests
alphaVal = .05;

% Provide some paramater limits for accepting or rejecting models.

% You might want to set a minimum efficacy to accept a model when you don't
% have many trials per lag. If efficacy is very low, estimates for latency
% and precision are going to be based on very few trials and could be way
% off.
efficacyLimit = 0.01;

% The following two parameters should generally be set just a fraction
% below the limits that were set during model fitting. This stops us from
% accepting a model where the parameter estimates converged at the limit,
% suggesting it's no good.
latencyLimit = 3.9;
precisionLimit = 3.9;
biasLimit = 0.9; % Radians
spreadLimits = [1.1 499];

% Set the colours used in the plots.
plotMarker = {'o','^'};
thisRGB = [1 3]; % Which RGB channel(s) correspond to each color?
thisIntensity = [.8 .8]; % What is the default intensity for each of these channels?

sampleColor = {'r','b'};
sampleIcon = {'ro-','b^:'};
zeroPointY = -50; % Y-value at which to show zero crossing
modelAxes = [-100 1100 -70 170];

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------

% Add folders to the MATLAB path
addpath(genpath(thisPath));

% Calculate the multiplication factor to turn lags into 
allFactors = 1000./allRates;

% Calculate the number of samples
nSamples = numel(sampleNames);

% Make some matrices for keeping track of included and excluded models
dumpedOnPrecisionLimit = zeros(1,nSamples);
dumpedOnLatencyLimit = zeros(1,nSamples);
dumpedOnEfficacyLimit = zeros(1,nSamples);
dumpedOnBiasLimit = zeros(1,nSamples);
dumpedOnSpreadLimit = zeros(1,nSamples);
dumpedAsNull = zeros(1,nSamples);

% Make some matrices for storing model parameters
allPerformance = NaN(nSamples,max(allNParticipants));
allEfficacy = NaN(nSamples,max(allNParticipants));
allLatency = NaN(nSamples,max(allNParticipants));
allPrecision = NaN(nSamples,max(allNParticipants));
allBias = NaN(nSamples,max(allNParticipants));
allSpread = NaN(nSamples,max(allNParticipants));

for thisSample = 1:nSamples

    % Fetch number of participants for this sample
    nParticipants = allNParticipants(thisSample);

    % Load data for the single-episode model (M1)
    load(['modelOutput/ModelOutput_DTDJ_' sampleNames{thisSample} '_Single.mat']);
    
    % Then do calculations for each participant...
    for thisParticipant = 1:nParticipants

        % Check the parameters satisfy the bounds set earlier
        noGoodE = abs(allT1Estimates(thisParticipant,1)) < efficacyLimit;
        noGoodB = abs(allT1Estimates(thisParticipant,2)) > biasLimit;
        noGoodS = (abs(allT1Estimates(thisParticipant,3)) < spreadLimits(1)) | abs(allT1Estimates(thisParticipant,3)) > spreadLimits(2);
        noGoodL = abs(allT1Estimates(thisParticipant,4)) > latencyLimit;
        noGoodP = abs(allT1Estimates(thisParticipant,5)) > precisionLimit;
        noGoodN = allLRTestPVals(thisParticipant) > alphaVal;

        % If they don't, add it to the tally of rejected models
        noGood = any([noGoodE noGoodL noGoodP noGoodN]);
        dumpedOnEfficacyLimit(thisSample) = dumpedOnEfficacyLimit(thisSample) + noGoodE;
        dumpedOnLatencyLimit(thisSample) = dumpedOnLatencyLimit(thisSample) + noGoodL;
        dumpedOnPrecisionLimit(thisSample) = dumpedOnPrecisionLimit(thisSample) + noGoodP;
        dumpedAsNull(thisSample) = dumpedAsNull(thisSample) + noGoodN;

        % Otherwise, include these as final model parameters
        if noGood
            allEfficacy(thisSample,thisParticipant) = 0;
            allLatency(thisSample,thisParticipant) = NaN;
            allPrecision(thisSample,thisParticipant) = NaN;
            allBias(thisSample,thisParticipant) = NaN;
            allSpread(thisSample,thisParticipant) = NaN;
        else
            allEfficacy(thisSample,thisParticipant) = allT1Estimates(thisParticipant,1);
            allLatency(thisSample,thisParticipant) = allT1Estimates(thisParticipant,4)*allFactors(thisSample); % ms
            allPrecision(thisSample,thisParticipant) = allT1Estimates(thisParticipant,5)*allFactors(thisSample); % ms
            allBias(thisSample,thisParticipant) = allT1Estimates(thisParticipant,2)*(180/pi); % Degrees
            allSpread(thisSample,thisParticipant) = k2sd(allT1Estimates(thisParticipant,3))*(180/pi);
        end
        
    end
    
end
        
% ---------------------------------------------------------------------    
% Now we calculate raw accuracy.

% Load the data.
cd([thisPath 'Data']);

 for thisSample = 1:nSamples
     
     load(['CompiledData_DTDJ_' sampleNames{thisSample} '.mat']);
     nParticipants = allNParticipants(thisSample);
     
    % Cycle through each participant
    for thisParticipant = 1:allNParticipants(thisSample)
            
        theseT1Error = squeeze(allT1ErrorPosition(thisParticipant,1,:));
        nError = numel(theseT1Error);

        % Calculate the number of exactly correct responses.
        T1Correct = sum(theseT1Error==0);

        % Calculate the proportion of exactly correct responses.
        allPerformance(thisSample,thisParticipant) = T1Correct/nError;
    end
    
 end
 
% Calculate mean parameters across participants.
Performance_M = squeeze(nanmean(allPerformance,2));
Efficacy_M = squeeze(nanmean(allEfficacy,2));
Latency_M = squeeze(nanmean(allLatency,2));
Precision_M = squeeze(nanmean(allPrecision,2));
Bias_M = squeeze(nanmean(allBias,2));
Spread_M = squeeze(nanmean(allSpread,2));

% Calculate standard deviations across participants.
Performance_SD = squeeze(nanstd(allPerformance,[],2));
Efficacy_SD = squeeze(nanstd(allEfficacy,[],2));
Latency_SD = squeeze(nanstd(allLatency,[],2));
Precision_SD = squeeze(nanstd(allPrecision,[],2));
Bias_SD = squeeze(nanstd(allBias,[],2));
Spread_SD = squeeze(nanstd(allSpread,[],2));

% Tally the number of participants contributing to these means.
Performance_N = squeeze(sum(~isnan(allPerformance),2));
Efficacy_N = squeeze(sum(~isnan(allEfficacy),2));
Latency_N = squeeze(sum(~isnan(allLatency),2));
Precision_N = squeeze(sum(~isnan(allPrecision),2));
Bias_N = squeeze(sum(~isnan(allBias),2));
Spread_N = squeeze(sum(~isnan(allSpread),2));

% Calculate the standard error of the mean.
Performance_SEM = Performance_SD./sqrt(Performance_N);
Efficacy_SEM = Efficacy_SD./sqrt(Efficacy_N);
Latency_SEM = Latency_SD./sqrt(Latency_N);
Precision_SEM = Precision_SD./sqrt(Precision_N);
Bias_SEM = Bias_SD./sqrt(Latency_N);
Spread_SEM = Spread_SD./sqrt(Precision_N);

% ---------------------------------------------------------------------
% This section contains code for creating the figure of parameter
% estimates.
    
Parameter_Figure = figure('color','white','name','All Parameters');

% Plot accuracy
subplot(2,4,1);
colormap gray;

    theseBars = bar(Performance_M');
    hold on;
    
    if nConditions > 1
    
        for thisSample = 1:nSamples

            % Get the position of the bars
            barPos = theseBars(thisSample).XData + theseBars(thisSample).XOffset;

            % Draw errorbars
            for thisCondition = 1:nConditions
                line(barPos(thisCondition)*ones(1,2), Performance_M(thisSample) + [-Performance_SEM(thisSample) Performance_SEM(thisSample)],'Color','k');
            end

        end
        
        axis([0 nConditions+1 -0.1 1.1]);
        
    else
        
        % Get the position of the bars
        barPos = theseBars.XData + theseBars.XOffset;
        
        % Draw errorbars
        for thisSample = 1:nSamples
            line(barPos(thisSample)*ones(1,2), Performance_M(thisSample) + [-Performance_SEM(thisSample) Performance_SEM(thisSample)],'Color','k');
        end
            
        axis([0 nSamples+1 -0.1 1.1]);
        set(gca,'XTick',1:nSamples,'XTickLabel',sampleNames);
        
    end
    
    set(gca,'TickDir','out','YMinorTick','on');
    title('Accuracy');
    box on;
    axis square;

% Plot efficacy
subplot(2,4,2);
colormap gray;

    theseBars = bar(Efficacy_M');
    hold on;
    
    if nConditions > 1
    
        for thisSample = 1:nSamples

            % Get the position of the bars
            barPos = theseBars(thisSample).XData + theseBars(thisSample).XOffset;

            % Draw errorbars
            for thisCondition = 1:nConditions
                line(barPos(thisCondition)*ones(1,2), Efficacy_M(thisSample) + [-Efficacy_SEM(thisSample) Efficacy_SEM(thisSample)],'Color','k');
            end

        end
        
        axis([0 nConditions+1 -0.1 1.1]);
        
    else
        
        % Get the position of the bars
        barPos = theseBars.XData + theseBars.XOffset;
        
        % Draw errorbars
        for thisSample = 1:nSamples
            line(barPos(thisSample)*ones(1,2), Efficacy_M(thisSample) + [-Efficacy_SEM(thisSample) Efficacy_SEM(thisSample)],'Color','k');
        end
            
        axis([0 nSamples+1 -0.1 1.1]);
        set(gca,'XTick',1:nSamples,'XTickLabel',sampleNames);
        
    end
    
    set(gca,'TickDir','out','YMinorTick','on');
    title('Efficacy');
    box on;
    axis square;
    
% Plot latency
subplot(2,4,3);
hold on;

    theseBars = bar(Latency_M');
    hold on;

    if nConditions > 1

        for thisSample = 1:nSamples

            % Get the position of the bars
            barPos = theseBars(thisSample).XData + theseBars(thisSample).XOffset;

            % Draw errorbars
            for thisCondition = 1:nConditions
                line(barPos(thisCondition)*ones(1,2), Latency_M(thisSample) + [-Latency_SEM(thisSample) Latency_SEM(thisSample)],'Color','k');
            end

        end

        axis([0 nConditions+1 -60 60]);

    else

        % Get the position of the bars
        barPos = theseBars.XData + theseBars.XOffset;

        % Draw errorbars
        for thisSample = 1:nSamples
            line(barPos(thisSample)*ones(1,2), Latency_M(thisSample) + [-Latency_SEM(thisSample) Latency_SEM(thisSample)],'Color','k');
        end

        axis([0 nSamples+1 -60 60]);
        set(gca,'XTick',1:nSamples,'XTickLabel',sampleNames);

    end

    set(gca,'TickDir','out','YMinorTick','on');
    title('Latency');
    box on;
    axis square;

% Plot precision
subplot(2,4,5);
hold on;

    theseBars = bar(Precision_M');
    hold on;

    if nConditions > 1

        for thisSample = 1:nSamples

            % Get the position of the bars
            barPos = theseBars(thisSample).XData + theseBars(thisSample).XOffset;

            % Draw errorbars
            for thisCondition = 1:nConditions
                line(barPos(thisCondition)*ones(1,2), Precision_M(thisSample) + [-Precision_SEM(thisSample) Precision_SEM(thisSample)],'Color','k');
            end

        end

        axis([0 nConditions+1 -15 165]);

    else

        % Get the position of the bars
        barPos = theseBars.XData + theseBars.XOffset;

        % Draw errorbars
        for thisSample = 1:nSamples
            line(barPos(thisSample)*ones(1,2), Precision_M(thisSample) + [-Precision_SEM(thisSample) Precision_SEM(thisSample)],'Color','k');
        end

        axis([0 nSamples+1 -15 165]);
        set(gca,'XTick',1:nSamples,'XTickLabel',sampleNames);

    end

    set(gca,'TickDir','out','YMinorTick','on','YDir','reverse');
    title('Precision');
    box on;
    axis square;
    
% Plot bias
subplot(2,4,6);
hold on;

    theseBars = bar(Bias_M');
    hold on;

    if nConditions > 1

        for thisSample = 1:nSamples

            % Get the position of the bars
            barPos = theseBars(thisSample).XData + theseBars(thisSample).XOffset;

            % Draw errorbars
            for thisCondition = 1:nConditions
                line(barPos(thisCondition)*ones(1,2), Bias_M(thisSample) + [-Bias_SEM(thisSample) Bias_SEM(thisSample)],'Color','k');
            end

        end

        axis([0 nConditions+1 -12 12]);

    else

        % Get the position of the bars
        barPos = theseBars.XData + theseBars.XOffset;

        % Draw errorbars
        for thisSample = 1:nSamples
            line(barPos(thisSample)*ones(1,2), Bias_M(thisSample) + [-Bias_SEM(thisSample) Bias_SEM(thisSample)],'Color','k');
        end

        axis([0 nSamples+1 -12 12]);
        set(gca,'XTick',1:nSamples,'XTickLabel',sampleNames);

    end

    set(gca,'TickDir','out','YMinorTick','on');
    title('Bias');
    box on;
    axis square;
    
    % Plot spread
    subplot(2,4,7);
    hold on;

    theseBars = bar(Spread_M');
    hold on;

    if nConditions > 1

        for thisSample = 1:nSamples

            % Get the position of the bars
            barPos = theseBars(thisSample).XData + theseBars(thisSample).XOffset;

            % Draw errorbars
            for thisCondition = 1:nConditions
                line(barPos(thisCondition)*ones(1,2), Spread_M(thisSample) + [-Spread_SEM(thisSample) Spread_SEM(thisSample)],'Color','k');
            end

        end

        axis([0 nConditions+1 -2 22]);

    else

        % Get the position of the bars
        barPos = theseBars.XData + theseBars.XOffset;

        % Draw errorbars
        for thisSample = 1:nSamples
            line(barPos(thisSample)*ones(1,2), Spread_M(thisSample) + [-Spread_SEM(thisSample) Spread_SEM(thisSample)],'Color','k');
        end

        axis([0 nSamples+1 -2 22]);
        set(gca,'XTick',1:nSamples,'XTickLabel',sampleNames);

    end

    set(gca,'TickDir','out','YMinorTick','on','YDir','reverse');
    title('Spread');
    box on;
    axis square;
    
% Plot maps for cases and controls
pdf_normmixture_single = @DTDJ_pdf_Mixture_Single;

% Calculate the domain of possible errors (xDomain).
xPosition = unique(allT1ErrorCombinations(:,:,:,2));
tPosition = unique(allT1ErrorCombinations(:,:,:,1));
xDomain = min(xPosition):max(xPosition);
xDomainPhi = pi*(xDomain/max(xDomain));
tDomain = min(tPosition):max(tPosition);
    
for thisSample = 1:nSamples
    
    subplot(2,4,4*thisSample);

    % Provide the path to the PolarToIm function.
    addpath(genpath('~/Documents/MATLAB/Add-Ons/PolarRectangularConv0.1/'));

    theseParams = [Efficacy_M(thisSample) Latency_M(thisSample)/allFactors(thisSample) ...
        Precision_M(thisSample)/allFactors(thisSample) Bias_M(thisSample)*(pi/180) ...
        sd2k(Spread_M(thisSample)*(pi/180))];
    
    normComponent = normpdf(tDomain,theseParams(2),theseParams(3));
    vmComponent = (1/(2*pi*besseli(0,theseParams(4)))).*exp(theseParams(5)*cos(xDomainPhi-theseParams(4)));

    % Normalise both
    normComponent = normComponent/sum(normComponent);
    vmComponent = vmComponent/sum(vmComponent);

    % Combine and normalise
    fullPDF = vmComponent'*normComponent;
    fullPDF = theseParams(1)*(fullPDF/max(fullPDF(:)));
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
    title(sampleNames{thisSample});
    rectangle('Position',[-minPos -minPos 2*minPos 2*minPos],'Curvature',1,'FaceColor','w','LineStyle','none');
    rectangle('Position',[-maxPos -maxPos 2*maxPos 2*maxPos],'Curvature',1,'EdgeColor','w','LineWidth',4);

    targetAngle = -pi/2;
    targetRadius = minPos + (maxPos-minPos)/2 - (maxPos-minPos)/48;
    [xx,yy] = pol2cart(targetAngle,targetRadius);
    scatter3(xx,yy,1,100,'kx');
    scatter3(xx,yy,1,141,'ko');

end
    
% Write the data to a *.csv file for analysis in JASP
cd([thisPath 'CSV']);
writeFile = fopen('DTDJ_AllData.csv','w');  % Overwrite file
fprintf(writeFile,'Group,'); % Header
for thisCondition = 1:max(allNConditions)
    fprintf(writeFile,'Accuracy_C%d,Efficacy_C%d,Latency_C%d,Precision_C%d,Bias_C%d,Spread_C%d',thisCondition*ones(1,6));
end

for thisSample = 1:nSamples
    for thisParticipant = 1:allNParticipants(thisSample)
        fprintf(writeFile,'\n%d',thisSample); % Group
        
        for thisCondition = 1:allNConditions(thisSample)
            fprintf(writeFile,',%.4f,%.4f,%.4f,%.4f,%.4f,%.4f', allPerformance(thisSample,thisParticipant), ...
                allEfficacy(thisSample,thisParticipant), allLatency(thisSample,thisParticipant), ...
                allPrecision(thisSample,thisParticipant), allBias(thisSample,thisParticipant), ...
                allSpread(thisSample,thisParticipant));
        end
    end
end
  
% Work out proportion of excluded models.
totalModels = sum(allNParticipants.*allNConditions);
excludedModels = (sum(dumpedOnEfficacyLimit)+sum(dumpedOnLatencyLimit)+sum(dumpedOnPrecisionLimit))/totalModels;
fprintf('\n\n%.1f%% of models excluded.\n\n', 100*excludedModels);

