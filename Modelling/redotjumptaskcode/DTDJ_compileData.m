% This script takes the individual data files and compiles them in a format
% used by the modeling script.

clear all; %#ok<CLSCR>

plots = 0;

allGroups = {'variableCue', 'endogenousCue'};
dataDirectory = '~/gitCode/dot-jump/data/wrangled/';
saveDirectory = '~/gitCode/dot-jump/data/modelOutput/';


% Specify the format of the data in the text files.

dataFormats = '%d%d%d%d';
nPositions = 24;
possTimeErrors = -18:15; % Possible time errors
possPositionErrors = -11:12; % Possible position errors

IDLength = 13 %number of characters in filenames that correspond to unique ID

for thisPosition = 1:nPositions
    dataFormats = strcat(dataFormats, '%d');
end

dataFormats = {dataFormats; dataFormats};

% For each group, specify the columns containing certain data, in this
% order:
% 1: T1 Time
% 2: T1 Position
% 3: T1 Response Time
% 4: T1 Response Position

dataColumns = [3 1 4 2; ...
    3 1 4 2];

% Specify the maximum number of trials. We do this so that we can build the
% data matrices to this size. They'll be trimmed afterwards to the actual
% maximum number of trials, but we want to avoid the matrices expanding
% after they're built. That's because we want NaNs in empty cells, not
% zeros. So make sure this is definitely higher than the actual maximum
% number of trials.

nTrialsMaxEstimate = 200;

% Calculate the number of groups.
nGroups = numel(allGroups);

% Calculate the number of possible time errors.
nPossTimeErrors = numel(possTimeErrors);

% Cycle through each group
for thisGroup = 1:nGroups

    % Output where we are to the command window.
    fprintf('\n\n%s\n', upper(allGroups{thisGroup}));

    % Specify the correct data format.
    dataFormat = dataFormats{thisGroup};

    % Get a list of files
    cd([dataDirectory allGroups{thisGroup}]);
    allContents = dir;
    allContents = {allContents.name};
    removeThese = strncmp('.',allContents,1);    % Find invalid entries (beginning with '.')
    allFiles = allContents(~removeThese);
    nTotalFiles = numel(allFiles);

    allParticipants = cell(1,nTotalFiles);

    % Get a list of unique participants.
    for thisFile = 1:nTotalFiles

        thisFileName = allFiles{thisFile};
        allParticipants{thisFile} = thisFileName(1:IDLength);

    end

    allParticipants = unique(allParticipants);
    nParticipants = numel(allParticipants);

    % Set up data structures. The second, redundant dimension in these
    % structures is there for compatibility with the modeling script, which
    % allows for data to be separated into blocks.

    allT1Time = NaN(nParticipants,1,nTrialsMaxEstimate);
    allT1ResponseTime = NaN(nParticipants,1,nTrialsMaxEstimate);
    allT1Position = NaN(nParticipants,1,nTrialsMaxEstimate);
    allT1ResponsePosition = NaN(nParticipants,1,nTrialsMaxEstimate);

    allT1ErrorTime = NaN(nParticipants,1,nTrialsMaxEstimate);
    allT1ErrorPosition = NaN(nParticipants,1,nTrialsMaxEstimate);
    allT1ErrorMatrix = zeros(nParticipants,nPossTimeErrors,nPositions);
    allT1ErrorCombinations = NaN(nParticipants,nTrialsMaxEstimate,min([nPossTimeErrors nPositions]),2);

    nTrialsMaxActual = 0; % Start at zero, then compare each time

    % For each participant...

    for thisParticipant = 1:nParticipants

        participantID = allParticipants(thisParticipant);
        fprintf('\nParticipant %2d (%s)...', thisParticipant, participantID{:});

        % Find the relevant files
        theseFiles = find(strncmp(allFiles,participantID,IDLength));
        nFiles = numel(theseFiles);

        startTrial = 1; % Location in the data matrix to start entering data

        % For each file...

        for thisFile = 1:nFiles

            % Open file.
            fileID = fopen(allFiles{theseFiles(thisFile)});

            % Read in the data.
            thisRead = textscan(fileID,dataFormat,'Delimiter',' \t','HeaderLines',0,'MultipleDelimsAsOne',1);

            % Set the bounds in the data matrix for data entry.
            nTrials = numel(thisRead{dataColumns(thisGroup,1)});
            endTrial = startTrial+nTrials-1;

            % 1: T1 Time
            % 2: T1 Position
            % 3: T1 Response Time
            % 4: T1 Response Position

            % Enter the data.
            allT1Time(thisParticipant,1,startTrial:endTrial) = double(thisRead{dataColumns(thisGroup,1)});
            allT1Position(thisParticipant,1,startTrial:endTrial) = double(thisRead{dataColumns(thisGroup,2)});
            allT1ResponseTime(thisParticipant,1,startTrial:endTrial) = double(thisRead{dataColumns(thisGroup,3)});
            allT1ResponsePosition(thisParticipant,1,startTrial:endTrial) = double(thisRead{dataColumns(thisGroup,4)});
            allT1ErrorTime(thisParticipant,1,startTrial:endTrial) = double(thisRead{dataColumns(thisGroup,3)})-double(thisRead{dataColumns(thisGroup,1)});

            % Array is circular, so we need to work out the minimum
            % absolute error.
            [minError,minPos] = min(mod([double(thisRead{dataColumns(thisGroup,4)})-double(thisRead{dataColumns(thisGroup,2)}),double(thisRead{dataColumns(thisGroup,2)})-double(thisRead{dataColumns(thisGroup,4)})],nPositions),[],2);
            thisError = (3-(2*minPos)) .* minError; % Adds the appropriate sign

            allT1ErrorPosition(thisParticipant,1,startTrial:endTrial) = thisError;

            % Add these trials to the error matrix. Add one count to every
            % possible combination of spatial/temporal errors on that
            % trial.
            allSequence = double([thisRead{5:28}]); % Sequence of positions on every trial
            allTimeError =  repmat(1:24,nTrials,1) - repmat(double(thisRead{dataColumns(thisGroup,1)}),1,nPositions);
            allPositionErrorA = mod(allSequence - repmat(double(thisRead{dataColumns(thisGroup,4)}),1,nPositions),nPositions);
            allPositionErrorB = mod(repmat(double(thisRead{dataColumns(thisGroup,4)}),1,nPositions) - allSequence, nPositions);
            [minError,minPos] = min(cat(3,allPositionErrorA,allPositionErrorB),[],3);
            allPositionError = (3-(2*minPos)) .* minError; % Adds the appropriate sign

            allT1ErrorCombinations(thisParticipant,startTrial:endTrial,:,:) = cat(3,allTimeError, allPositionError);
            assignin('base',sprintf('%sAllTime', participantID{:}), allTimeError)
            assignin('base',sprintf('%sAllPos', participantID{:}), allPositionError)
            nCombinations = numel(allTimeError);
            
            for thisCombination = 1:nCombinations
                thisTimePos = find(possTimeErrors==allTimeError(thisCombination));
                thisPosPos = find(possPositionErrors==allPositionError(thisCombination));
                allT1ErrorMatrix(thisParticipant,thisTimePos,thisPosPos) ...
                    = allT1ErrorMatrix(thisParticipant,thisTimePos,thisPosPos) + 1;
            end
            
            assignin('base',participantID{:}, allT1ErrorMatrix(thisParticipant,:,:))
            % Close file.
            fclose(fileID);

            % Location in the data matrix to continue entering data.
            startTrial = endTrial + 1;

        end
        if plots
            figure;
            imagesc(squeeze(allT1ErrorMatrix(thisParticipant,:,:)));
            axis square;
            colormap(gray);
        end

        % If this is the highest number of trials per participant so far,
        % store that number.
        nTrialsMaxActual = max([nTrialsMaxActual endTrial]);

    end

    % Truncate the data matrices
    allT1Time = allT1Time(:,:,1:nTrialsMaxActual);
    allT1ResponseTime = allT1ResponseTime(:,:,1:nTrialsMaxActual);
    allT1Position = allT1Position(:,:,1:nTrialsMaxActual);
    allT1ResponsePosition = allT1ResponsePosition(:,:,1:nTrialsMaxActual);
    allT1ErrorTime = allT1ErrorTime(:,:,1:nTrialsMaxActual);
    allT1ErrorPosition = allT1ErrorPosition(:,:,1:nTrialsMaxActual);
    allT1ErrorCombinations = allT1ErrorCombinations(:,1:nTrialsMaxActual,:,:);

    % Save and end
    cd(saveDirectory);
    fileName = ['CompiledData_DTDJ_' allGroups{thisGroup}];
    save(fileName,'allT1Time','allT1Position','allT1ResponseTime','allT1ResponsePosition','allT1ErrorTime','allT1ErrorPosition','allT1ErrorMatrix','allT1ErrorCombinations','allParticipants');

end