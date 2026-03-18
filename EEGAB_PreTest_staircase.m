function [] = EEGAB_PreTest_staircase() 
clearvars; close all; clc;
%% Get sub&Exp information
expinfo   = [];
dlgprompt = {'Subject ID:',...
             'Age:'...
             'Reversal:'...
             'Count_rev:'...
             'Quitcase:'};
dlgname       = 'Sub&Exp Information';
numlines      = 1;
defaultanswer = {'S','0','5','3','30'};
ans1              = inputdlg(dlgprompt,dlgname,numlines,defaultanswer);
expinfo.id        = ans1{1};
expinfo.age       = str2num(ans1{2});
expinfo.reversal  = str2num(ans1{3});
expinfo.countrev  = str2num(ans1{4});
expinfo.outtrials = str2num(ans1{5});

expinfo.stdura    = 6; %6 frames = 100ms when the fresh rate is 60 Hz
expinfo.stimdura  = 2;
expinfo.visangle  = 1.5;
expinfo.backcolr  = [0;0;0];
expinfo.basecolr  = [0;105;0];
expinfo.instcolr  = [105;105;105];
expinfo.seqlength = 9;%不规律呈现时的字母个数
                      % 虽然这里长度是9，但是在后面通过lettlist_perm = [Shuffle(lettlist) Shuffle(lettlist)];来呈现18个字母
expinfo.stepsize  = 1;
expinfo.unitcolr  = 15;
expinfo.steprange = [0 10];

sexStrList    = {'Female','Male'};
handStrList   = {'Right','Left'};
[sexidx,v]    = listdlg('PromptString','Gender:','SelectionMode','Single','ListString',sexStrList);
expinfo.sex   = sexStrList{sexidx};
if ~v; expinfo.sex  = 'NA'; end
[handidx,v]   = listdlg('PromptString','Handedness:','SelectionMode','Single','ListString',handStrList);
expinfo.hand  = handStrList{handidx};
if ~v; expinfo.hand = 'NA'; end

 % Key assignment 
KbName('UnifyKeyNames');
spaceKey   = KbName('space');
enterKey   = KbName('return');
quitKey    = KbName('escape');
respKey1   = KbName('7');
respKey2   = KbName('8');
respKey3   = KbName('9');
respKey4   = KbName('4');
respKey5   = KbName('5');
respKey6   = KbName('6'); 
respKey7   = KbName('1');
respKey8   = KbName('2');
respKey9   = KbName('3'); 
respKeys   = [respKey1, respKey2, respKey3, respKey4, respKey5, respKey6, respKey7, respKey8, respKey9];
while KbCheck; end
ListenChar(2); 

% Set the folder and filename for data save
destdir = './EEGData/PretestData/';
if ~exist(destdir,'dir'), mkdir(destdir); end
expinfo.path2save = strcat(destdir,expinfo.id,'Pre_',mfilename,'_',datestr(now,30));

data         = [];
data.expinfo = expinfo;
save(expinfo.path2save,'data');

% set other parameters
viewDistance = 600; % viewing distance (mm)
whichScreen  = 0; % screen index for use
winRect      = []; % initial window size, empty indicates a whole screen window
pixelDepth   = 32;
numBuffer    = 2;
stereoMode   = 0;
multiSample  = 0;
imagingMode  = [];
%% Standard coding practice, use try/catch to allow cleanup on error.
try
    % This script calls Psychtoolbox commands available only in
    % OpenGL-based versions of Psychtoolbox. The Psychtoolbox command
    % AssertPsychOpenGL will issue an error message if someone tries to
    % execute this script on a computer without an OpenGL Psychtoolbox.
    AssertOpenGL;
    
    % Screen is able to do a lot of configuration and performance checks on
    % open, and will print out a fair amount of detailed information when
    % it does. These commands supress that checking behavior and just let
    % the program go straight into action. See ScreenTest for an example of
    % how to do detailed checking.
    oldVisualDebugLevel    = Screen('Preference','VisualDebugLevel',3);
    oldSuppressAllWarnings = Screen('Preference','SuppressAllWarnings',1);
    
    % Open a screen window and get window information.
    [winPtr, winRect] = Screen('OpenWindow',whichScreen,expinfo.backcolr,winRect,pixelDepth,numBuffer,stereoMode,multiSample,imagingMode);
    Screen('BlendFunction',winPtr,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
    Screen('TextSize',winPtr,35);
    Screen('TextFont',winPtr,'Kaiti');
    [x0,y0] = RectCenter(winRect);
    ifi = Screen('GetFlipInterval', winPtr);
    [width_mm, height_mm] = Screen('DisplaySize', whichScreen);
    screenSize    = [width_mm, height_mm];
    winResolution = [winRect(3)-winRect(1),winRect(4)-winRect(2)];
    ppd = viewDistance*tan(pi/180)*winResolution./screenSize;
    ppd = round(ppd);
    stimsize = ppd(1)*expinfo.visangle;
    ovalsize = ppd(1)*expinfo.visangle*1.5;
    
    % Hide mouse curser and set the priority level
    HideCursor;
    priorityLevel = MaxPriority(winPtr);
    Priority(priorityLevel);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % TASK SESSION
    lettlist  = 'ABCDFGHJKMNPQRSTUVWXYZ';%n=22去掉E，O，I，L
    T1loc     = [5 6 7];%T1和T2的位置都随机
    T2loc     = [3 4 5 6 7 8 9 10];
    textstr2  = ['请在呈现序列中找到最后的绿色字母，\n'...
        '序列结束后立刻回答并按回车键确认，\n'...
        '如果不小心输错请按空格键清空答案。\n'...
        '明白要求后请按空格键开始测试。'];
    textstr4  = '请输入最后出现的绿色字母:';
    
    for n = 1:length(lettlist)
        Lett{n}   = imread(['.\stim\' lettlist(n) '.png'],'png');
        for i     = 1:size(Lett{n},1)
            for j = 1:size(Lett{n},2)
                if Lett{n}(i,j,1:3) ~= expinfo.backcolr
                    Lett{n}(i,j,1:3) = expinfo.instcolr;
                end
            end
        end
    end
    fix   = imread('.\stim\1.png','png');
    for i = 1:size(fix,1)
        for j = 1:size(fix,2)
            if fix(i,j,1:3) ~= expinfo.backcolr
                fix(i,j,1:3) = expinfo.instcolr;
            end
        end
    end
    textfix     = Screen('MakeTexture',winPtr,fix);
    [~,~,alpha] = imread('.\stim\Oval.png','png');
    oval        = MaskImageIn(alpha);
    for i = 1:size(oval,1)
        for j = 1:size(oval,2)
            if oval(i,j,1:3) ~= expinfo.backcolr
                oval(i,j,1:3) = expinfo.instcolr;
            end
        end
    end
    textoval  = Screen('MakeTexture',winPtr,oval);
    %% start pretest  
    flag = 0; 
    while 1
        if flag == 1;break;end %如果被试选择不继续练习，则退出
        rng('Shuffle');
        data.seq     = [1 1];%被试选择继续练习则重新生成数据，只记录当次结果
        for i = unique(data.seq)
            id = find(data.seq == i);
            data.double(id([1 2])) = Shuffle([1 2]);%双阶梯任务的起始点，1=从最暗开始，2=从最亮开始
        end

        for blk = 1:length(data.seq)
            % present the instruction
            textstr1    = ['下面开始预测试第' num2str(blk) '组:']; 
            BoundsRect1 = Screen('TextBounds',winPtr,double(textstr1));
            DrawFormattedText(winPtr,double(textstr1),x0-500-(BoundsRect1(3)-BoundsRect1(1))/2,y0-300-(BoundsRect1(4)-BoundsRect1(2))/2,expinfo.instcolr);
            BoundsRect2 = RectOfMatrix(double(textstr2));
            DrawFormattedText(winPtr,double(textstr2),x0-500-(BoundsRect2(3)-BoundsRect2(1))/2,y0-200-(BoundsRect2(4)-BoundsRect2(2))/2,expinfo.instcolr,[],[],[],2);
            Screen('Flip',winPtr);
            while 1
                [keydown, ~, keycode] = KbCheck;
                if keydown
                    while KbCheck; end
                    if keycode(spaceKey)|| keycode(quitKey); break; end
                end
            end
            Screen('FillRect',winPtr,expinfo.backcolr);
            Screen('Flip',winPtr);
            if keycode(quitKey); break; end

            % set staircase parameters
            count_of_n_of_reversals  = 0;
            expthresholds = zeros(expinfo.reversal, 1);%拐点的数量
            trl           = 1;
            n_threshold   = 1;
            n_down        = 0;%记录该参数是为了设置几次正确才可以调节阈值
            pos           = 0;
            neg           = 0;
            
            % start each trial
            trlT  = 0;
            while count_of_n_of_reversals < expinfo.reversal
                lettlist_perm  = [Shuffle(lettlist) Shuffle(lettlist)];
                % 将 lettlist 列表通过 Shuffle 函数打乱 两次，然后将这两次打乱后的结果拼接成一个新的列表。
                % lettlist = [1 2 3 4];
                % lettlist_perm = [Shuffle(lettlist) Shuffle(lettlist)];
                % lettlist_perm = [3 1 4 2 4 3 1 2];

                
                if trl == 1
                    if data.double(blk) == 1
                        StimulusLevel  = expinfo.steprange(1);%初始试次为最亮或最暗
                    elseif data.double(blk) == 2
                        StimulusLevel  = expinfo.steprange(2);
                    end
                end
                numstim    = expinfo.stimdura;%frame of stim
                numISI     = expinfo.stdura-numstim;%单个字母总呈现时长-字母本身呈现时长=间隔时长
                T1pos      = T1loc(randperm(length(T1loc),1));%T1和T2的时间位置
                T2pos      = T2loc(randperm(length(T2loc),1));
                lettlist_perm  = lettlist_perm(1:T1pos+T2pos+2);%字母长度进一步缩减
                T1lett = Lett{ismember(lettlist,lettlist_perm(T1pos))};
                T2lett = Lett{ismember(lettlist,lettlist_perm(T1pos+T2pos))};
                targetcolr = [0 StimulusLevel*expinfo.unitcolr+expinfo.basecolr(2) 0];%难度的调节：目标字母的亮度
                
                for i = 1:size(T1lett,1)
                    for j = 1:size(T1lett,2)
                        if T1lett(i,j,1:3) ~= expinfo.backcolr
                            T1lett(i,j,1:3) = targetcolr;
                        end
                    end
                end
                for i = 1:size(T2lett,1)
                    for j = 1:size(T2lett,2)
                        if T2lett(i,j,1:3) ~= expinfo.backcolr
                            T2lett(i,j,1:3) = targetcolr;
                        end
                    end
                end
                textt1 = Screen('MakeTexture',winPtr,T1lett);
                textt2 = Screen('MakeTexture',winPtr,T2lett);
                
                ISIframe = length(lettlist_perm);%刺激数量决定空屏呈现数量
                ISIseq   = repmat(numISI,1,ISIframe);
                
                Screen('DrawTexture',winPtr,textfix,[],[x0-stimsize/2,y0-stimsize/2,x0+stimsize/2,y0+stimsize/2]);
                Screen('Flip',winPtr);
                WaitSecs(1.5);
%                 while 1
%                     [keydown, ~, keycode] = KbCheck;
%                     if keydown
%                         while KbCheck; end
%                         if keycode(spaceKey); break; end
%                     end
%                 end
                
                time1 = GetSecs;  tpoint = []; ISI = [];
                for stim = 1:length(lettlist_perm)
                    isi1 = GetSecs;
                    for num = 1:ISIseq(stim)
                        Screen('FillRect',winPtr,expinfo.backcolr);
                        Screen('DrawTexture',winPtr,textoval,[],[x0-ovalsize/2,y0-ovalsize/2,x0+ovalsize/2,y0+ovalsize/2]);
                        Screen('Flip',winPtr);% Screen time of background
                    end
                    isi2 = GetSecs; ISI = [ISI isi2-isi1]; isi1 = isi2;
                    textlett = Screen('MakeTexture',winPtr,Lett{ismember(lettlist,lettlist_perm(stim))});
                    Screen('DrawTexture',winPtr,textlett,[],[x0-stimsize/2,y0-stimsize/2,x0+stimsize/2,y0+stimsize/2]);
                    if stim == T1pos
                        Screen('DrawTexture',winPtr,textt1,[],[x0-stimsize/2,y0-stimsize/2,x0+stimsize/2,y0+stimsize/2]);
                        time2 = GetSecs; tpoint = [tpoint time2-time1];
                    elseif stim == T1pos+T2pos
                        Screen('DrawTexture',winPtr,textt2,[],[x0-stimsize/2,y0-stimsize/2,x0+stimsize/2,y0+stimsize/2]);
                        time2 = GetSecs; tpoint = [tpoint time2-time1];
                    end
                    Screen('DrawTexture',winPtr,textoval,[],[x0-ovalsize/2,y0-ovalsize/2,x0+ovalsize/2,y0+ovalsize/2]);
                    for num = 1:numstim-1
                        Screen('Flip',winPtr,0,1);%前面几帧呈现完不消失
                    end
                    Screen('Flip',winPtr);%最后一帧呈现完消失
                end
                time3 = GetSecs;
                
                % wait for a response
                resp = []; resptime = []; xlocation = []; ylocation = []; resphistory = []; textshown = [];
                BoundsRect4   = Screen('TextBounds',winPtr,double(textstr4));
                DrawFormattedText(winPtr,double(textstr4),x0-(BoundsRect4(3)-BoundsRect4(1))/2,y0-200-(BoundsRect4(4)-BoundsRect4(2))/2,expinfo.instcolr);
                
                if T2pos <= 4
                    shownstim = Shuffle(lettlist_perm(T1pos-(9-T2pos-1-2):T1pos+T2pos+2));
                elseif T2pos >= 5
                    shownstim = Shuffle([lettlist_perm(T1pos-1:T1pos+2) lettlist_perm(T1pos+T2pos-2:T1pos+T2pos+2)]);
                end
                for num = 1:9
                    textlett = Screen('MakeTexture',winPtr,Lett{ismember(lettlist,shownstim(num))});
                    if num <= 3
                        Screen('DrawTexture',winPtr,textlett,[],[x0+(num-2)*100-stimsize/2,y0-100-stimsize/2,x0+(num-2)*100+stimsize/2,y0-100+stimsize/2]);
                    elseif num <= 6
                        Screen('DrawTexture',winPtr,textlett,[],[x0+(num-5)*100-stimsize/2,y0-stimsize/2,x0+(num-5)*100+stimsize/2,y0+stimsize/2]);
                    elseif num <= 9
                        Screen('DrawTexture',winPtr,textlett,[],[x0+(num-8)*100-stimsize/2,y0+100-stimsize/2,x0+(num-8)*100+stimsize/2,y0+100+stimsize/2]);
                    end
                end
                Screen('Flip',winPtr);
                bodyimage = Screen('GetImage',winPtr,[]);
                texbody   = Screen('MakeTexture',winPtr,bodyimage);
                
                while 1
                    [keydown, secs, keycode] = KbCheck;
                    if keydown && numel(find(keycode)) == 1
                        while KbCheck; end
                        if numel(find(find(keycode) == respKeys)) == 1
                            target      = find(find(keycode) == respKeys);
                            resp        = [resp shownstim(target)];
                            resptime    = [resptime secs-time3];
                            resphistory = [resphistory shownstim(target)];
                            if (0 < target)&&(target < 4)
                                xlocation = [xlocation x0+(target-2)*100];
                                ylocation = [ylocation y0-100];
                            elseif (3 < target)&&(target < 7)
                                xlocation = [xlocation x0+(target-5)*100];
                                ylocation = [ylocation y0];
                            elseif (6 < target)&&(target < 10)
                                xlocation = [xlocation x0+(target-8)*100];
                                ylocation = [ylocation y0+100];
                            end
                            shownlett = Lett{ismember(lettlist,shownstim(target))};
                            for i = 1:size(shownlett,1)
                                for j = 1:size(shownlett,2)
                                    if shownlett(i,j,:) ~= expinfo.backcolr
                                        shownlett(i,j,:) = targetcolr;
                                    end
                                end
                            end
                            textshown = [textshown Screen('MakeTexture',winPtr,shownlett)];
                        elseif keycode(spaceKey)
                            xlocation = []; ylocation = []; resp = []; textshown =[];
                        end
                        
                        respmax = 1;
                        if length(resp) > respmax %超过最大值无法继续输入
                            resptime  = resptime(1:end+respmax-length(resp)); resphistory = resphistory(1:end+respmax-length(resp));
                            xlocation = xlocation(1:respmax); ylocation = ylocation(1:respmax); resp = resp(1:respmax); textshown = textshown(1:2);
                        elseif length(resp) == respmax && respmax == 2 %同一个字母输入两次只算一次
                            if resp(1) == resp(2)
                                resp      = resp(1); textshown = textshown(1);
                                xlocation = xlocation(1);
                                ylocation = ylocation(1);
                            end
                        end
                        
                        Screen('PreloadTextures',winPtr,texbody);
                        Screen('DrawTexture',winPtr,texbody);
                        for r = 1:length(resp)
                            Screen('DrawTexture',winPtr,textshown(r),[],[xlocation(r)-stimsize/2,ylocation(r)-stimsize/2,xlocation(r)+stimsize/2,ylocation(r)+stimsize/2]);
                        end
                        Screen('Flip',winPtr);
                        if (keycode(enterKey)&&length(resp) == respmax)||(keycode(quitKey)); break; end
                    end
                end
                if keycode(quitKey);break; end
                
                if resp - lettlist_perm(T1pos+T2pos) == 0 %判断T2回答的正确率
                    acc = 1;
                else
                    acc = 0;
                end
                
                rowofoutput (trl, 1) = trl;
                rowofoutput (trl, 2) = StimulusLevel;
                rowofoutput (trl, 3) = acc;
                if acc == 1
                    n_down = n_down+1;
                    if n_down == 4
                        n_down = 0;
                        pos    = 1;
                        trend  = 1;
                        if StimulusLevel > expinfo.steprange(1)
                            StimulusLevel = StimulusLevel - expinfo.stepsize;
                        end
                        if pos == 1 && neg == -1%出现拐点
                            count_of_n_of_reversals    = count_of_n_of_reversals+1;
                            expthresholds(n_threshold) = (StimulusLevel + rowofoutput(trl, 2))/2;
                            n_threshold = n_threshold + 1;
                            pos = trend;
                            neg = trend;
                        end  
                    end
                else
                    neg    = -1;
                    trend  = -1;
                    n_down = 0;
                    if StimulusLevel < expinfo.steprange(2)
                        StimulusLevel = StimulusLevel + expinfo.stepsize;
                    end
                    if pos == 1 && neg == -1%出现拐点
                        count_of_n_of_reversals = count_of_n_of_reversals + 1;
                        % calculate the threshold
                        expthresholds(n_threshold) = (StimulusLevel + rowofoutput(trl, 2))/2;
                        n_threshold = n_threshold+1;
                        pos = trend;
                        neg = trend;
                    end   
                end
                rowofoutput (trl, 4) = count_of_n_of_reversals;
                
                % save all the results after each trial
                data.lettseq{blk}{trl,:}     = lettlist_perm;
                data.lett{blk}(trl,:)        = [lettlist_perm(T1pos) lettlist_perm(T1pos+T2pos)];
                data.T1T2pos{blk}{trl,:}     = [T1pos T2pos];
                data.staircase{blk}(trl,:)   = rowofoutput(trl,:);
                data.resp{blk}(trl,:)        = resp;
                data.resptime{blk}{trl,:}    = resptime;
                data.resphistory{blk}{trl,:} = resphistory;
                data.letttime{blk}(trl,:)    = time3-time1;
                data.T1T2point{blk}(trl,:)   = tpoint;
                data.ISI{blk}{trl,:}         = ISI;
                save(expinfo.path2save,'data');
                if trl >= expinfo.outtrials
                    if (sum(rowofoutput(trl-expinfo.outtrials+1:trl,2)) == expinfo.steprange(1)*expinfo.outtrials)||...%如果连续n个试次都处于最低或者最高难度则退出练习
                            (sum(rowofoutput(trl-expinfo.outtrials+1:trl,2)) == expinfo.steprange(2)*expinfo.outtrials)
                        break;
                    end
                end
                trl = trl+1;  
                trlT = trlT + 1 ;
                if trlT == 36
                    textstr6    = '请稍作休息,休息结束后，请按空格键自行开始';
                    BoundsRect6 = Screen('TextBounds',winPtr,double(textstr6));
                    Screen('FillRect',winPtr,expinfo.backcolr);
                    DrawFormattedText(winPtr,double(textstr6),x0-50-(BoundsRect6(3)-BoundsRect6(1))/2,y0-(BoundsRect6(4)-BoundsRect6(2))/2,expinfo.instcolr);
                    Screen('Flip',winPtr);
                    while 1
                        [keydown, ~, keycode] = KbCheck;
                        if keydown
                            while KbCheck; end
                            if keycode(spaceKey)|| keycode(quitKey); break; end
                        end
                    end
                    trlT = 0;
                end 
            end
            
            % give feedback
            data.thresholds(:,blk) = expthresholds;
            data.mean_thres(blk)   = round(mean(expthresholds(end-expinfo.countrev+1:end)));%取最后几个拐点的平均值计算阈值
            accfin = data.staircase{blk}(:,3);
            data.mean_acc(blk)     = length(find(accfin(data.staircase{blk}(:,4) >= expinfo.countrev-1) == 1))/length(accfin(data.staircase{blk}(:,4) >= expinfo.countrev-1));
            save(expinfo.path2save,'data');
        end
        
        if mean(data.mean_acc)>= 0.7
            textstr5   = '恭喜您通过预测试！请联系主试';
        else
            textstr5   = '很遗憾您未能通过预测试！';
        end
        textstr6 = ['您的正确率分别是' num2str(data.mean_acc(data.double == 1)) '和' num2str(data.mean_acc(data.double == 2)) '\n'...
                '刺激呈现阈值分别是' num2str(data.mean_thres(data.double == 1)*expinfo.unitcolr+expinfo.basecolr(2)) '和' num2str(data.mean_thres(data.double == 2)*expinfo.unitcolr+expinfo.basecolr(2)) '\n'...
                '平均的刺激呈现阈值是' num2str(round(mean(data.mean_thres)*expinfo.unitcolr)+expinfo.basecolr(2)) '\n'...
                '请勿按键，静待主试操作'];
        BoundsRect5   = RectOfMatrix(double(textstr5));
        DrawFormattedText(winPtr,double(textstr5),x0-600-(BoundsRect5(3)-BoundsRect5(1))/2,y0-300-(BoundsRect5(4)-BoundsRect5(2))/2,expinfo.instcolr,[],[],[],2);
        BoundsRect6   = RectOfMatrix(double(textstr6));
        DrawFormattedText(winPtr,double(textstr6),x0-600-(BoundsRect6(3)-BoundsRect6(1))/2,y0-200-(BoundsRect6(4)-BoundsRect6(2))/2,expinfo.instcolr,[],[],[],2);
        Screen('Flip',winPtr);
        WaitSecs(10.0);
        
        while 1
            [keydown, ~, keycode] = KbCheck;
            if keydown
                while KbCheck; end
                if keycode(enterKey) || keycode(spaceKey); break; end
            end
        end
        Screen('FillRect',winPtr,expinfo.backcolr);
        Screen('Flip',winPtr);
        if keycode(enterKey); flag = 1; end
    end
    
    figure;
    for blk = 1:length(data.seq)
        subplot(1,2,blk)
        plot(data.staircase{blk}(:,2)*expinfo.unitcolr+expinfo.basecolr(2))
        m = 1;
        reversal = nan(size(data.staircase{blk},1),1);
        for i = 1:size(data.staircase{blk},1)
            re = find(data.staircase{blk}(:,4)== m);
            reversal(re(1)) = data.staircase{blk}(re(1),2);
            m = m+1;
            if m > data.staircase{blk}(end,4)
                break;
            end
        end
        hold on
        plot(reversal*data.expinfo.unitcolr+expinfo.basecolr(2),'o')
        legend('stimlevel','reversal point')
        title([num2str(blk) ' ' num2str(data.mean_acc(blk)) ' ' num2str(data.mean_thres(blk))])
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % The end statement of the experiment
    DrawFormattedText(winPtr,double('实验结束。'),150,y0-40,expinfo.instcolr);
    DrawFormattedText(winPtr,double('非常感谢！'),150,y0+40,expinfo.instcolr);
    Screen('Flip',winPtr);
    WaitSecs(2.0);
    Screen('FillRect',winPtr,expinfo.backcolr);
    Screen('Flip',winPtr);
    Screen('CloseAll');
    ShowCursor;
    fclose('all');
    Priority(0);
    % Restore preferences
    Screen('Preference', 'VisualDebugLevel', oldVisualDebugLevel);
    Screen('Preference', 'SuppressAllWarnings', oldSuppressAllWarnings);
    ListenChar(0);
    
catch
    % Catch error.
    Screen('FillRect',winPtr,expinfo.backcolr);
    Screen('Flip',winPtr);
    Screen('CloseAll');
    ShowCursor;
    fclose('all');
    Priority(0);
    % Restore preferences
    Screen('Preference', 'VisualDebugLevel', oldVisualDebugLevel);
    Screen('Preference', 'SuppressAllWarnings', oldSuppressAllWarnings);
    ListenChar(0);
    psychrethrow(psychlasterror);
end % try ... catch %
