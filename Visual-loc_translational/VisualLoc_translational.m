%% Visual hMT localizer using translational motion in four directions
%  (up- down- left and right-ward)

% by Mohamed Rezk 2018
% adapted by MarcoB 2020


% % % Different duratons for different number of repetitions (may add a few TRs to this number just for safety)
% % % Cfg.numRepetitions=7, Duration: 345.77 secs (5.76 mins), collect 139 + 4 Triggers = 143 TRs at least per run
% % % Cfg.numRepetitions=6, Duration: 297.86 secs (4.96 mins), collect 120 + 4 Triggers = 124 TRs at least per run
% % % Cfg.numRepetitions=5, Duration: 249.91 secs (4.17 mins), collect 100 + 4 Triggers = 104 TRs at least per run
% % % Cfg.numRepetitions=4, Duration: 201.91 secs (3.37 mins), collect 81 + 4 Triggers  = 85  TRs at least per run

%%

% Clear all the previous stuff
% clc; clear;
if ~ismac
    close all;
    clear Screen;
end

% make sure we got access to all the required functions and inputs
addpath(fullfile(pwd, 'subfun'))

% set and load all the parameters to run the experiment
[subjectName, runNumber, sessionNumber] = UserInputs;
[ExpParameters, Cfg] = SetParameters;

%%  Experiment

% Safety loop: close the screen if code crashes
try
    %% Init the experiment
    [Cfg] = InitPTB(Cfg);
    
    [ExpParameters, Cfg]  = VisualDegree2Pixels(ExpParameters, Cfg);
    
    % % % REFACTOR THIS FUNCTION
    [ExpDesignParameters] = ExpDesign(ExpParameters);
    % % %
    
    % Visual degree to pixels converter
    [ExpParameters, Cfg] = VisualDegree2Pixels(ExpParameters, Cfg);
    
    % Empty vectors and matrices for speed
    % % %     blockNames     = cell(ExpParameters.numBlocks,1);
    logFile.blockOnsets    = zeros(ExpParameters.numBlocks, 1);
    logFile.blockEnds      = zeros(ExpParameters.numBlocks, 1);
    logFile.blockDurations = zeros(ExpParameters.numBlocks, 1);
    
    logFile.eventOnsets    = zeros(ExpParameters.numBlocks, ExpParameters.numEventsPerBlock);
    logFile.eventEnds      = zeros(ExpParameters.numBlocks, ExpParameters.numEventsPerBlock);
    logFile.eventDurations = zeros(ExpParameters.numBlocks, ExpParameters.numEventsPerBlock);
    
    logFile.allResponses = [] ;
    
    % Prepare for the output logfiles
    logFile = SaveOutput(subjectName, logFile, ExpParameters, ExpDesignParameters, 'open');
    
    % % % PUT IT RIGHT BEFORE STARTING THE EXPERIMENT
    % Show instructions
    if ExpParameters.Task1
        DrawFormattedText(Cfg.win,ExpParameters.TaskInstruction,...
            'center', 'center', Cfg.textColor);
        Screen('Flip', Cfg.win);
    end
    % % %
    
    % Prepare for fixation Cross
    if ExpParameters.Task1
        Cfg.xCoords = [-ExpParameters.fixCrossDimPix ExpParameters.fixCrossDimPix 0 0] + ExpParameters.xDisplacementFixCross;
        Cfg.yCoords = [0 0 -ExpParameters.fixCrossDimPix ExpParameters.fixCrossDimPix] + ExpParameters.yDisplacementFixCross;
        Cfg.allCoords = [Cfg.xCoords; Cfg.yCoords];
    end
    
    % Wait for space key to be pressed
    pressSpace4me
    
    % Wait for Trigger from Scanner
    Wait4Trigger(Cfg)
    
    % Show the fixation cross
    if ExpParameters.Task1
        Screen('DrawLines', Cfg.win, Cfg.allCoords,ExpParameters.lineWidthPix, ...
            Cfg.White , [Cfg.center(1) Cfg.center(2)], 1);
        Screen('Flip',Cfg.win);
    end
    
    %% Experiment Start
    Cfg.Experiment_start = GetSecs;
    
    WaitSecs(ExpParameters.onsetDelay);
    
    %% For Each Block
    for iBlock = 1:ExpParameters.numBlocks
        
        fprintf('Running Block %.0f \n',iBlock)
        
        logFile.blockOnsets(iBlock,1)= GetSecs-Cfg.Experiment_start;
        
        % For each event in the block
        for iEventsPerBlock = 1:ExpParameters.numEventsPerBlock
            
            logFile.iEventDirection = ExpDesignParameters.directions(iBlock,iEventsPerBlock);       % Direction of that event
            logFile.iEventSpeed = ExpDesignParameters.speeds(iBlock,iEventsPerBlock);               % Speed of that event
            % % % CAN IT BE PUT ON A STRUCT? IT IS ONLY A NUMBER NEEDED IN
            % DODOTMO
            iEventDuration = ExpParameters.eventDuration ;                        % Duration of normal events
            % % %
            logFile.iEventIsFixationTarget = ExpDesignParameters.fixationTargets(iBlock,iEventsPerBlock);
            
            % Event Onset
            logFile.eventOnsets(iBlock,iEventsPerBlock) = GetSecs-Cfg.Experiment_start;
            
            % % % REFACTORE
            % play the dots
            responseTimeWithinEvent = DoDotMo( Cfg, ExpParameters, logFile, iEventDuration);
            % % %
            
            %% logfile for responses
            if ~isempty(responseTimeWithinEvent)
                fprintf(ResponsesTxtLogFile,'%8.6f \n',responseTimeWithinEvent);
            end
            
            %% Event End and Duration
            logFile.eventEnds(iBlock,iEventsPerBlock) = GetSecs-Cfg.Experiment_start;
            logFile.eventDurations(iBlock,iEventsPerBlock) = logFile.eventEnds(iBlock,iEventsPerBlock) - logFile.eventOnsets(iBlock,iEventsPerBlock);
            
            % concatenate the new event responses with the old responses vector
            logFile.allResponses = [logFile.allResponses responseTimeWithinEvent];
            
            Screen('DrawLines', Cfg.win, Cfg.allCoords,ExpParameters.lineWidthPix, ...
                Cfg.White , [Cfg.center(1) Cfg.center(2)], 1);
            Screen('Flip',Cfg.win);
            
            
            
            
            % % % NEED TO ASSIGN THE TXT VARIABLE IN A STRUCTURE
            % Save the events txt logfile
            logFile = SaveOutput(subjectName, logFile, ExpParameters, ExpDesignParameters, ...
                'save Events', iBlock, iEventsPerBlock)
            % % %
            
            
            % wait for the inter-stimulus interval
            WaitSecs(ExpParameters.ISI);
        end
        
        logFile.blockEnds(iBlock,1)= GetSecs-Cfg.Experiment_start;          % End of the block Time
        logFile.blockDurations(iBlock,1)= logFile.blockEnds(iBlock,1) - logFile.blockOnsets(iBlock,1); % Block Duration
        
        %Screen('DrawTexture',Cfg.win,imagesTex.Event(1));
        Screen('DrawLines', Cfg.win, Cfg.allCoords,ExpParameters.lineWidthPix, ...
            Cfg.White , [Cfg.center(1) Cfg.center(2)], 1);
        Screen('Flip',Cfg.win);
        
        WaitSecs(ExpParameters.IBI);
        
        % % % NEED TO ASSIGN THE TXT VARIABLE IN A STRUCTURE
        % Save the block txt Logfile
        logFile = SaveOutput(subjectName, logFile, ExpParameters, ExpDesignParameters, ...
            'save Blocks', iBlock, iEventsPerBlock)
        % % %
        
    end
    
    % % % HERE needed for saving single vars, is it needed?
    blockNames = ExpDesignParameters.blockNames ;
    blockDurations = logFile.blockDurations;
    blockOnsets = logFile.blockOnsets;
    
    % % %
    
    % End of the run for the BOLD to go down
    WaitSecs(ExpParameters.endDelay);
    
    % close txt log files
    fclose(BlockTxtLogFile);
    fclose(EventTxtLogFile);
    fclose(ResponsesTxtLogFile);
    
    
    TotalExperimentTime = GetSecs-Cfg.Experiment_start;
    
    %% Save mat log files
    save(fullfile('logfiles',[subjectName,'_all.mat']))
    
    % % % CANNOT FIND THE VAR BLOCKDURATION
    save(fullfile('logfiles',[subjectName,'.mat']),...
        'Cfg', ...
        'allResponses', ...
        'blockDurations', ...
        'blockNames', ...
        'blockOnsets')
    % % %
    
    % Close the screen
    sca
    %     clear Screen;
    % Restore keyboard output to Matlab:
    ListenChar(0);
    
catch
    % if code crashes, closes serial port and screen
    sca
    % Restore keyboard output to Matlab:
    ListenChar(0);
    %     clear Screen;
    error(lasterror) %#ok<LERR> % show default error
end

