function varargout = runSession(varargin)
%
% Script for running a single subject through one scan, giving three blocks
% of food choice, once each with Natural, Health, and Decrease Focus
%
% Author: Cendri Hutcherson
% Last modified: Feb. 8, 2018

%% --------------- START NEW DATAFILE FOR CURRENT SESSION --------------- %
    studyid = 'fMRI Experiment Files'; % change this for every study
    homepath = determinePath(studyid);
if isempty(varargin)
    addpath([homepath filesep 'PTBScripts'])
    PTBParams = InitPTB(homepath,'DefaultSession','1');
else
    PTBParams = varargin{1};
    PTBParams.inERP = 0;
    Data.subjid = PTBParams.subjid;
    Data.ssnid = num2str(PTBParams.ssnid);
    Data.time = datestr(now);
 
    PTBParams.datafile = fullfile(PTBParams.homepath, 'SubjectData', ...
                         num2str(PTBParams.subjid), ['Data.' num2str(PTBParams.subjid) '.' Data.ssnid '.mat']);
    save(PTBParams.datafile, 'Data')
end

%% ----------------------- INITIALIZE VARIABLES ------------------------- %
PTBParams.imgpath = fullfile(PTBParams.homepath, 'PTBscripts');
% HEDIE: It's doubling up on PTBscripts in the file path, so I'm deleting
% "PTBScripts"
% PTBParams.imgpath = fullfile(PTBParams.homepath,'PTBScripts');
PTBParams.foodPath = fullfile(PTBParams.homepath,'FoodPics');

if mod(PTBParams.subjid, 2) % counterbalance left-right orientation of choice
    LRdrx = 'RL';
    PTBParams.RLOrder = 0;
else
    LRdrx = 'LR';
    PTBParams.RLOrder = 1;
end

% HEDIE: Deleted .png or .jpg since it was
% creating files that were .png.png, so MATLAB couldn't find them
[PTBParams.ChoiceScale, PTBParams.ChoiceScaleSize] = ... % makeTxtrFromImg([PTBParams.imgpath '/ChoiceScale' LRdrx '.png'], 'PNG', PTBParams)
    makeTxtrFromImg([PTBParams.imgpath '\ChoiceScale' LRdrx], 'PNG', PTBParams);

[PTBParams.NatInsrx, PTBParams.NatPicSize] = ...%makeTxtrFromImg(fullfile(PTBParams.imgpath, 'NatInsrx.png'), 'PNG', PTBParams)
    makeTxtrFromImg(fullfile(PTBParams.imgpath, 'NatInsrx'), 'PNG', PTBParams);

[PTBParams.RegInsrx1, PTBParams.RegPicSize1] = ...%makeTxtrFromImg(fullfile(PTBParams.imgpath, 'HealthInsrx.jpg'), 'JPG', PTBParams); % format is JPG for stupid reasons related to PPT. Stupid PPT!
    makeTxtrFromImg(fullfile(PTBParams.imgpath, 'HealthInsrx'), 'JPG', PTBParams);

[PTBParams.RegInsrx2, PTBParams.RegPicSize2] = ...% makeTxtrFromImg(fullfile(PTBParams.imgpath, 'DecreaseInsrx.png'), 'PNG', PTBParams);
    makeTxtrFromImg(fullfile(PTBParams.imgpath, 'DecreaseInsrx'), 'PNG', PTBParams);

%HEDIE: I deleted the function str2double since PTBParams is already a
%double, this seems to fix the problem. However, the function does need to
%be added in when running ONLY runSession, since PTBParams becomes a char
%and does need conversion
if(PTBParams.ssnid == 1)
    determineFoodOrder(PTBParams) % creates food order based on taste, health, and liking
end

% access trial order created by determineFoodOrder
load (fullfile(PTBParams.homepath, 'SubjectData', num2str(PTBParams.subjid), 'TaskOrder.mat'))

% create schedule for ITIs
m = 6;
if PTBParams.inMRI
    ITI = [zeros(m,1); ones(m,1); 2*ones(m,1); 3*ones(m,1); 4*ones(m,1)];
    ITI = ITI(randperm(length(ITI)));
else
    ITI = zeros(m*5,1);
end

%% -------------------  WAIT FOR SCAN TRIGGER   --------------------------%
% if in scanner, wait for appropriate amount of time before starting task
if PTBParams.inMRI
    DrawFormattedText(PTBParams.win,'Prepare to begin...','center','center',PTBParams.white);
    Screen(PTBParams.win, 'Flip');
    waitForScanTrig(PTBParams)
    SessionStartTime = GetSecs();
    PTBParams.StartTime = SessionStartTime;
    datafile = PTBParams.datafile;
    logData(datafile,1,SessionStartTime);
    WaitSecs(5 * PTBParams.TR); % this allows for scanner equilibration
else
    SessionStartTime = GetSecs();
    PTBParams.StartTime = SessionStartTime;
    datafile = PTBParams.datafile;
    logData(datafile,1,SessionStartTime);
end

%HEDIE: Deleted str2double since PTBParams.ssnid is already a double
%HEDIE: also removed if statement for blockorder = [1 randperm(2) +1]; it
%likely can't work with only 2 conditions
blockorder = randperm(2); 

trial = 1;
for block = blockorder % for each session, run one block of each condition
    switch block
        case 1
            InsrxPic = PTBParams.NatInsrx;
            InsrxSize = PTBParams.NatPicSize;
            %HEDIE: Deleted str2double in all of these since PTBParams.ssnid is already a
            %double
            Food = FoodOrderNat(10*(PTBParams.ssnid - 1) + (1:10)); % select the appropriate trials
            Insrx = 'Respond Naturally';
        case 2
            InsrxPic = PTBParams.RegInsrx1;
            InsrxSize = PTBParams.RegPicSize1;
            Food = FoodOrderReg1(10*(PTBParams.ssnid - 1) + (1:10));
            Insrx = 'Focus on Healthiness';
         
    end   
        %otherwise
            %InsrxPic = PTBParams.RegInsrx2;
            %InsrxSize = PTBParams.RegPicSize2;
            %Food = FoodOrderReg2(10*(PTBParams.ssnid - 1) + (1:10));
            %Insrx = 'Decrease Desire';
    %end
    
    % First display screen giving the instruction for this block
    Screen('DrawTexture',PTBParams.win,InsrxPic,[],...
        findPicLoc(InsrxSize,[.5,.5],PTBParams,'ScreenPct',1));
    InsrxScreenOn = Screen('Flip',PTBParams.win);
    InsrxScreenOn = InsrxScreenOn - PTBParams.StartTime;
    WaitSecs(5);
    
    logData(datafile, block, Insrx,InsrxScreenOn);
    
    for t = 1:10
        TrialData = runChoiceTrial2(Food{t},Insrx,PTBParams);
        logData(datafile,trial,TrialData);
        WaitSecs(ITI(trial));
        trial = trial + 1;
    end
end

WaitSecs(PTBParams.TR * 3)

SessionEndTime = datestr(now);
logData(datafile,1,SessionEndTime);

%% ------------------------  CLEAN-UP AND END  -------------------------- %

if isempty(varargin)
    close all; Screen('CloseAll'); ListenChar(1);
end

%-------------------------------------------------------------------------%

%=========================================================================%
%                   FUNCTIONS CALLED BY MAIN SCRIPT                       %
%=========================================================================%

function path = determinePath(studyid)
	% determines path name, to enable some platform independence
	pathtofile = mfilename('fullpath');

	path = pathtofile(1:(regexp(pathtofile,studyid)+ length(studyid)));
    
function waitForScanTrig(PTBParams)
% Wait for '5' from scanner to begin the experiment.  Note that you still
% need to specify n-extra TRs at the beginning to allow for magnet 
% equilibration
 
FlushEvents('keyDown');
done = 0;
    while done == 0
        av = CharAvail();
        if av ~= 0
            if str2double(GetChar()) == 5
                done = 1;
                StartTime = GetSecs();
            end
        end
    end
     
DrawFormattedText(PTBParams.win,'+','center','center',PTBParams.white);
% DrawFormattedText(PTBParams.win,'Prepare to begin...','center','center',PTBParams.white);
Screen(PTBParams.win,'Flip');
   
function determineFoodOrder(PTBParams)

    subjRatingFile = fullfile(PTBParams.homepath,'SubjectData',num2str(PTBParams.subjid),...
        ['Data.', num2str(PTBParams.subjid), '.LikingRatings-Pre.mat']);
    
    if exist(subjRatingFile,'file')
        RateData = load(subjRatingFile);
        RateData = RateData.Data;

        RateData.Resp = cell2mat(RateData.Resp);

        
        for i = 1:length(RateData.Food)
            FoodStem{i} = RateData.Food{i}(1:(regexp(RateData.Food{i},'_','once') - 1));
        end

        uniqueFoods = unique(FoodStem);
        aveRating = zeros(length(uniqueFoods),1);
        for f = 1:length(uniqueFoods)
            aveRating(f) = mean(RateData.Resp(searchcell(RateData.Food,uniqueFoods{f},'contains')));
        end
        % assign foods to 3 groups of roughly equally liked foods
        [sortedResp indexResp] = sort(aveRating);
        uniqueFoods = uniqueFoods(indexResp);
    else
        [num, text] = xlsread(fullfile(PTBParams.homepath, 'FoodsToUse.xlsx'));
        foodnames = text(1:end,1);
        foodnames(cellfun(@(x)~ischar(x),foodnames)) = [];
        foodnames = deblank(foodnames);
        FoodOrder = foodnames(randperm(length(foodnames)));
        RateData.Food = FoodOrder;
        for i = 1:length(foodnames)
            FoodStem{i} = foodnames{i}(1:(regexp(foodnames{i},'_','once') - 1));
        end

        temp = unique(FoodStem);
        uniqueFoods = temp(randperm(length(temp)));
        indexResp = ones(length(foodnames),1);
    end

    RegForFood = [];
    %HEDIE: Block changed from 1:floor(length(indexResp)/3) --> indexResp/2
    for block = 1:floor(length(indexResp)/2)
        % creates a vector to divvy up foods over 3 conditions while
        % distributing liking ratings roughly equally
        %HEDIE:changed randperm from 3 to 2 since we're only doing 2
        %conditions
        RegForFood = [RegForFood, randperm(2)]; 
    end
    
    % assign foods to conditions
    
    FoodOrderNat = [];
    FoodOrderReg1 = [];
    %FoodOrderReg2 = [];

     %HEDIE: Made it RegForFood instead of RegForFood so each case would
     %only get 60 spots (120 total)
     for i = 1:(length(RegForFood))
        %HEDIE: For these to stop giving array concatenation errors, we had
        %to alter some of the food names in the excel spreadsheet thats
        %called on since we're fiding foods that CONTAIN a particular name
        %i.e. calling peanut not only found peanut but also peanutbutter
        %which created a 1x4 array instead of 1x2
        switch RegForFood (i)
            case 1
                FoodOrderNat = [FoodOrderNat RateData.Food(searchcell(RateData.Food,uniqueFoods{i},'contains'))];
                disp(FoodOrderNat)
            case 2
                FoodOrderReg1 = [FoodOrderReg1 RateData.Food(searchcell(RateData.Food,uniqueFoods{i},'contains'))];
                disp (FoodOrderReg1)
            %otherwise
                %FoodOrderReg2 = [FoodOrderReg2 RateData.Food(searchcell(RateData.Food,uniqueFoods{i},'contains'))];
                %disp (FoodOrderReg2)
        end
    end

    %HEDIE: Changed from 1:90 to 1:60 since we're only looking at 120 foods
    %instead of 270
    FoodOrderNat = FoodOrderNat(1:60);
    FoodOrderReg1 = FoodOrderReg1(1:60);
    %FoodOrderReg2 = FoodOrderReg2(1:90);

    FoodOrderNat = FoodOrderNat(randperm(length(FoodOrderNat)));
    FoodOrderReg1 = FoodOrderReg1(randperm(length(FoodOrderReg1)));
    %FoodOrderReg2 = FoodOrderReg2(randperm(length(FoodOrderReg2)));
    
    %[num, text] = xlsread(fullfile(PTBParams.homepath, 'FoodsToUse.xlsx'));
    %foodnames = text(1:end,1);
    %foodnames(cellfun(@(x)~ischar(x),foodnames)) = [];
    %foodnames = deblank(foodnames);
    
    datafile = PTBParams.datafile;
    %HEDIE: Deleted FoodOrderReg2 here 
    logData(datafile,1,FoodOrderNat,FoodOrderReg1);
        save(fullfile(PTBParams.homepath, 'SubjectData', num2str(PTBParams.subjid), 'TaskOrder.mat'), 'FoodOrderNat','FoodOrderReg1');





