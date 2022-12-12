function runNewRatingTrials(varargin)
%
% Script for running a single subject through a ratings task, to collect measures of 
% subjective perceptions of fat, sodium, carb, sugar, protein, and vitamin content for the food choice
% decision-making task
%
% Author: Hedie Mahmoudian
% Last modified: May 22, 2022

% try % for debugging purposes

%% --------------- START NEW DATAFILE FOR CURRENT SESSION --------------- %
studyid = 'fMRI Experiment Files'; % change this for every study

if isempty(varargin)
    homepath = determinePath(studyid);
    addpath([homepath filesep 'PTBScripts'])
    PTBParams = InitPTB(homepath,'DefaultSession','NewAttributeRatings-Post');
else
    PTBParams = varargin{1};
    PTBParams.inERP = 0;
    Data.subjid = PTBParams.subjid;
    Data.ssnid = 'NewAttributeRatings-Post';
    Data.time = datestr(now);
 
    PTBParams.datafile = fullfile(PTBParams.homepath, 'SubjectData', ...
                         num2str(PTBParams.subjid), ['Data.' num2str(PTBParams.subjid) '.' Data.ssnid '.mat']);
    save(PTBParams.datafile, 'Data')
end

%% ----------------------- INITIALIZE VARIABLES ------------------------- %
imgpath = [PTBParams.homepath 'PTBscripts/'];
PTBParams.foodPath = fullfile(PTBParams.homepath,'FoodPics');
% load names of foods
PTBParams.nFoods = 270;
[num, text] = xlsread(fullfile(PTBParams.homepath, 'FoodsToUse.xlsx'));
foodnames = text(1:end,1);
foodnames(cellfun(@(x)~ischar(x),foodnames)) = [];
foodnames = deblank(foodnames);
PTBParams.FoodNames = foodnames;

SessionStartTime = GetSecs();
trial = 1;
datafile = PTBParams.datafile;
logData(datafile,trial,SessionStartTime);

%HEDIE: CHANGE ALL NUMERICAL VALUES TO MATCH NEWLY MADE INSTRUCTIONS 
insrx = 54;
while insrx >=54 && insrx < 56
    if insrx == 54
        showInstruction(insrx,PTBParams,'RequiredKeys',{'RightArrow','right'});
        insrx = insrx + 1;
    else
        Resp = showInstruction(insrx,PTBParams,'RequiredKeys',{'RightArrow','LeftArrow','right','left'});
        if strcmp(Resp,'LeftArrow') || strcmp(Resp,'left')
            insrx = insrx - 1;
        else
            insrx = insrx + 1;
        end
    end
end

%HEDIE:  Deleted Liking Rating Keys since we don't need it, we're using
%sliding scale instead 
% [PTBParams.RateKeys, PTBParams.RateKeysSize] = ...
%                 makeTxtrFromImg([imgpath 'LikingRatingKeys.png'], 'PNG', PTBParams);

%HEDIE: Edited TrialData.Attribute from 'Liking' to new attribute
%HEDIE: Changed # of foods from length(PTBParams.FoodNames) to just 120
trial = 1;
for food = randperm(270, 120)
    Attribute = 'Fat';
    TrialData = NewgetFoodRating(food, PTBParams, Attribute);
    TrialData.Attribute = Attribute;
    logData(PTBParams.datafile, trial, TrialData)
    trial = trial + 1;
end

ratingOrder = {'Sodium', 'Carbs', 'Sugar', 'Protein', 'Vitamins'};
ratingOrder = ratingOrder(randperm(length(ratingOrder)));

% if mod(PTBParams.subjid,2)
%     KeyOrder = 'RL';
% else
%     KeyOrder = 'LR';
% end
           

%HEDIE: EDIT ALL NUMBERS FOR INSTRUCTIONS AND LOAD SLIDING SCALE....?
for r = 1:length(ratingOrder)
    switch ratingOrder{r}
        case 'Sodium'
            insrx = 56;
            % load in pictures of taste rating keys
%             [PTBParams.RateKeys, PTBParams.RateKeysSize] = ...
%                 makeTxtrFromImg([imgpath 'TasteRatingKeys.png'], 'PNG', PTBParams);
            
        case 'Carbs'
            insrx = 57;
            % load in pictures of health rating keys
%             [PTBParams.RateKeys, PTBParams.RateKeysSize] = ...
%                 makeTxtrFromImg([imgpath 'HealthRatingKeys.png'], 'PNG', PTBParams);
         
        case 'Sugar'
            insrx = 58;
            % load in pictures of health rating keys
%             [PTBParams.RateKeys, PTBParams.RateKeysSize] = ...
%                 makeTxtrFromImg([imgpath 'HealthRatingKeys.png'], 'PNG', PTBParams);

        case 'Protein'
            insrx = 59;
            % load in pictures of health rating keys
%             [PTBParams.RateKeys, PTBParams.RateKeysSize] = ...
%                 makeTxtrFromImg([imgpath 'HealthRatingKeys.png'], 'PNG', PTBParams);
        
        case 'Vitamins'
            insrx = 60;
            % load in pictures of health rating keys
%             [PTBParams.RateKeys, PTBParams.RateKeysSize] = ...
%                 makeTxtrFromImg([imgpath 'HealthRatingKeys.png'], 'PNG', PTBParams);
    end
    
    showInstruction(insrx, PTBParams,'RequiredKeys',{'RightArrow','right'});
    
    %HEDIE: Changed # of foods from length(PTBParams.FoodNames) to just 120
    for food = randperm(270, 120)
        Attribute = ratingOrder{r};
        TrialData = NewgetFoodRating(food, PTBParams, Attribute);
        TrialData.Attribute = Attribute;
        logData(PTBParams.datafile, trial, TrialData)
        trial = trial + 1;
    end

end

SessionEndTime = datestr(now);
trial = 1;
datafile = PTBParams.datafile;
logData(datafile,trial,SessionEndTime);
    
% catch ME
%     ME
%     ME.stack.file
%     ME.stack.line
%     ME.stack.name
%     Screen('CloseAll');
%     ListenChar(1);
% end



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