function TrialData = NewgetFoodRating(foodnum, PTBParams, Attribute)
% function TrialData = getFoodRating(foodnum, PTBParams)
%
% foodnum = specifies which food to display
% PTBParams = structure specifying various study parameters
%

%% 1. DISPLAY TRIAL TYPE FOR 500 ms + jittered fixation
Screen('DrawDots',PTBParams.win, [0;0], 10, [255,0,0]', PTBParams.ctr, 1);
TrialStartTime = Screen(PTBParams.win, 'Flip');
%% 2. DISPLAY FOOD FOR UP TO 4 SECONDS

% load food picture for trial
Food = PTBParams.FoodNames{foodnum};
FoodType = fullfile(PTBParams.foodPath,Food);
%[FoodTexture, FoodSize] = makeTxtrFromImg(fullfile(PTBParams.foodPath,Food),'JPG', PTBParams);
%picLoc = findPicLoc(FoodSize,[.5,.45],PTBParams,'ScreenPct',.4);
%Screen('DrawTexture', PTBParams.win, FoodTexture,[],picLoc);

%HEDIE: Commented out findPicLoc for RateKeysSize since we don't need
%rating keys
% picLoc = findPicLoc(PTBParams.RateKeysSize,[.5,.85],PTBParams,'ScreenPct',.4);
% Screen('DrawTexture', PTBParams.win, PTBParams.RateKeys,[],picLoc);

FoodOnTime = Screen(PTBParams.win,'Flip',TrialStartTime + .25);

% [Resp, RT] = collectResponse([],[],PTBParams.numKeys(1:6),PTBParams.KbDevice);
% Resp = str2double(Resp(1));
% RT = RT - FoodOnTime;

%Response Keys
KbName ('UnifyKeyNames');

% Input for slide scale
%HEDIE: I think I need to use switch cases for the question and anchor
% if mod(PTBParams.subjid,2)
%     KeyOrder = 'RL';
% else
%     KeyOrder = 'LR';
% end
           
%HEDIE: Switch case for questions & anchors 
switch Attribute 
    case 'Fat'
        question = 'How fatty is this food?';
        anchors = {'No Fat', 'Lots of Fat'};
    case 'Sodium'
        question = 'How salty is this food?';
        anchors = {'No Sodium', 'Lots of Sodium'};
    case 'Carbs'
        question = 'How full of carbs is this food?';
        anchors = {'No Carbs', 'Lots of Carbs'};
    case 'Sugar'
        question = 'How sugary is this food?';
        anchors = {'No Sugar', 'Lots of Sugar'};
    case 'Protein'
        question = 'How full of protein is this food?';
        anchors = {'No Protein', 'Lots of Protein'};
    case 'Vitamins'
        question = 'How full of vitamins is this food?';
        anchors = {'No Vitamins', 'Lots of Vitamins'};
end

rect = PTBParams.rect;
picSize = size(imread(FoodType, 'JPG'));
picCtr = [.5,.45];

[position, RT, answer] = slideScale(PTBParams.win, ...
    question, ...
   ...
   rect, ...
    anchors, ...
    'range', 2, ...
    'device', 'keyboard', ...
    'responsekeys', [KbName('return') KbName('LeftArrow') KbName('RightArrow')], ...
    'stepsize', 10, ...
    'scalacolor', [255 255 255], ...
    'startposition', 'center', ...
    'image', imread(FoodType, 'JPG'), ...
    'picloc', findPicLoc(picSize, picCtr,PTBParams, 'ScreenPct', .4));

%% 3. DISPLAY FIXATION

Screen('DrawDots',PTBParams.win, [0;0], 10, [255,0,0]', PTBParams.ctr, 1);
FixationOnTime = Screen(PTBParams.win, 'Flip');

WaitSecs(.05);


%% 4. ADD TRIAL DATA TO STRUCTURE FOR OUTPUT
%HEDIE: Edited most of trial data to give us info from slide scale
TrialData.Food = Food;
TrialData.RT = RT;
TrialData.TrialStartTime = TrialStartTime;
TrialData.FoodOnTime = FoodOnTime;
TrialData.position = position;
TrialData.answer = answer;

%% 5. CLEAN UP
%
%Screen('Close', stimuli);



