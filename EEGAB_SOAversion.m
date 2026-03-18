function [] = EEGAB_SOAversion()
%% 本代码于2025年4月15日修改
% 单任务和双任务数据保存的时候需要分别创建数据集，否则无法正常保存且会跳出去
clearvars; close all; clc;
%% Get subject information
expinfo   = [];
dlgprompt = {'Subject ID:',...
    'Age:',...
    'Seq:',...
    'Target color:'};
dlgname       = 'Sub&Exp Information';
numlines      = 1;
defaultanswer = {'S','0','','0'};
ans1          = inputdlg(dlgprompt,dlgname,numlines,defaultanswer);
expinfo.id      = ans1{1};
expinfo.age     = str2num(ans1{2});
expinfo.seq     = str2num(ans1{3});
expinfo.tarcolr = [0 str2num(ans1{4}) 0];

expinfo.stdura    = 6;%6 frames = 100ms when the fresh rate is 60 Hz
expinfo.stimdura  = 2;
expinfo.visangle  = 1.5;
expinfo.backcolr  = [0;0;0];
expinfo.instcolr  = [105;105;105];

expinfo.seqlength = 18;
expinfo.withnblk  = 60 * 1;%rest for 1 minutes


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
respKeys1  = [respKey1, respKey2, respKey3, respKey4, respKey5, respKey6, respKey7, respKey8, respKey9]; %respKeys
while KbCheck; end
ListenChar(2);
if expinfo.seq == 1
    expinfo.sequence = [1 2 2 1];
else
    expinfo.sequence = [2 1 1 2];
end

% Set the folder and filename for data save

% if ~exist('./dataEEG/SOA_IR/EEG/','dir'), mkdir('./dataEEG/SOA_IR/EEG/'); end
% expinfo.path2save = strcat('./dataEEG/SOA_IR/EEG/',expinfo.id,'_',expinfo.session,'_',expinfo.condition,'_',mfilename,'_',datestr(now,30));

destdir = './EEGData/EEGExpData/';
if ~exist(destdir,'dir'), mkdir(destdir); end
expinfo.path2save = strcat(destdir,expinfo.id,'_',mfilename,'_',datestr(now,30));


data = [];
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


try
    ioObj = io64;
    status = io64(ioObj);%status=0 then setup is ok
    if status
        fprintf(2,'Failed to initiate io64!');
    end
    address = hex2dec('CFF8');%%EEG port number 378/MEG port number D020  % 需要根据并口地址改
catch
    disp('ERP mark installation failed');
end

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
    oldVisualDebugLevel = Screen('Preference','VisualDebugLevel',3);
    oldSupressAllWarnings = Screen('Preference','SuppressAllWarnings',1);
    
    % Open a screen window and get window information.
    [winPtr, winRect] = Screen('OpenWindow',whichScreen,expinfo.backcolr,winRect,pixelDepth,numBuffer,stereoMode,multiSample,imagingMode);
    Screen('BlendFunction',winPtr,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
    Screen('TextSize',winPtr,35);
    Screen('TextFont',winPtr,'Kaiti');
    [x0,y0] = RectCenter(winRect);
    ifi = Screen('GetFlipInterval',winPtr);
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
    lettlist  = 'ABCDFGHJKMNPQRSTUVWXYZ';%n=22去掉E，O，I，L
    % STI - Single Task Instruction
    % STA - Single Task Answer Instruction
    textstrST1    = '现在进行的是单目标任务:';
    BoundsRectST1 = Screen('TextBounds',winPtr,double(textstrST1));
    textstr2  = ['请在呈现序列中找到两个绿色字母，\n'...
        '序列结束后立刻回答并按回车键确认，\n'...
        '如果不小心输错请按空格键清空答案。\n'...
        '明白要求后请按空格键开始任务。'];
    BoundsRect2 = RectOfMatrix(double(textstr2));
    textstrSTI  = ['请在呈现序列中找到出现的绿色字母，\n'...
        '序列结束后立刻回答并按回车键确认，\n'...
        '如果不小心输错请按空格键清空答案。\n'...
        '明白要求后请按空格键开始任务。'];
    BoundsRectSTI = RectOfMatrix(double(textstrSTI));
    textstr3  = ['本组每个试次开始前会呈现一条线段\n'...
        '提示你本试次两个目标的时间间隔。\n'...
        '线段呈现结束后会出现“+”字注视点\n'...
        '“+”字注视点消失后呈现刺激序列。'];
    BoundsRect3 = RectOfMatrix(double(textstr3));
    textstr4  = '请按顺序输入两个绿色字母:';
    BoundsRect4 = RectOfMatrix(double(textstr4));
    textstrSTA  = '请输入你看到的绿色字母:';
    BoundsRectSTA = RectOfMatrix(double(textstrSTA));
    textstr6    = '请稍作休息,休息结束后，请按空格键自行开始';
    BoundsRect6 = Screen('TextBounds',winPtr,double(textstr6));
    
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
    
    % prepare for the fix figure
    Crossfix = imread(['.\stim\' num2str(1) '.png'],'png');
    for i = 1:size(Crossfix,1)
        for j = 1:size(Crossfix,2)
            if Crossfix(i,j,1:3) ~= expinfo.backcolr
                Crossfix(i,j,1:3) = expinfo.instcolr;
            end
        end
    end
    textCrossfix = Screen('MakeTexture',winPtr,Crossfix);
    % No cue condition  * fix
    fix = imread(['.\stim\' num2str(4) '.png'],'png');
    for i = 1:size(fix,1)
        for j = 1:size(fix,2)
            if fix(i,j,1:3) ~= expinfo.backcolr
                fix(i,j,1:3) = expinfo.instcolr;
            end
        end
    end
    textfix = Screen('MakeTexture',winPtr,fix);
    
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
    %% Single-target TASK SESSION
    % setup trial sequence in a block
    flag   = 0;
    %     ST_T1loc     = repmat([5 6 7],1,1);
    ST_T1loc     = repmat([5 6 7],1,16);  % repmat 函数用于重复数组,它将向量 [5 6 7] 重复X次，形成一个X行3列的矩阵。
                                          % 试次数在这里调
    ST_SS = ST_T1loc(:);
    for blk = 1
        ST_SS       = ST_SS(randperm(size(ST_SS,1)),:);
        % present the instruction  指导语部分不需要打mark
        DrawFormattedText(winPtr,double(textstrST1),x0-150-(BoundsRectST1(3)-BoundsRectST1(1))/2,y0-300-(BoundsRectST1(4)-BoundsRectST1(2))/2,expinfo.instcolr);
        DrawFormattedText(winPtr,double(textstrSTI),x0-350-(BoundsRectSTI(3)-BoundsRectSTI(1))/2,y0-200-(BoundsRectSTI(4)-BoundsRectSTI(2))/2,expinfo.instcolr,[],[],[],2);
        Screen('Flip',winPtr)
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
        
        % start each trial
        ST_trlT          = 0;
        for trl = 1:size(ST_SS,1)
            T1pos = ST_SS(trl,1);
            lettlist_perm  = Shuffle(lettlist);
            lettlist_perm  = lettlist_perm(1:expinfo.seqlength);
            T1lett = Lett{ismember(lettlist,lettlist_perm(T1pos))};
            
            numstim  = expinfo.stimdura;%frame of stim
            numISI   = expinfo.stdura-numstim;
            for i = 1:size(T1lett,1)
                for j = 1:size(T1lett,2)
                    if T1lett(i,j,1:3) ~= expinfo.backcolr
                        T1lett(i,j,1:3) = expinfo.tarcolr;
                    end
                end
            end
            textt1 = Screen('MakeTexture',winPtr,T1lett);
            
            ISIframe = length(lettlist_perm);
            ISIseq   = repmat(numISI,1,ISIframe);
            
            % 这里设置注视点和T1的数值  单目标任务和双目标任务的值应该不同，因为双目标两个条件间不同，是根据mark提前
            ST_data_out_fix    = 50;
            ST_data_out_t1     = 51;
            % 线索及mark
            Screen('FillRect',winPtr,expinfo.backcolr);% 空屏
            Screen('Flip',winPtr);
            WaitSecs(1);
            Screen('DrawTexture',winPtr,textCrossfix,[],[x0-stimsize/2,y0-stimsize/2,x0+stimsize/2,y0+stimsize/2]);
            Screen('Flip', winPtr);
            ERPmark(ioObj,address,ST_data_out_fix);
            WaitSecs(1);
            
            time1 = GetSecs; % 记录整个刺激呈现开始的时间点
            tpoint = []; ISI = [];
            for stim = 1:length(lettlist_perm)
                isi1 = GetSecs;
                for num = 1:ISIseq(stim) % 画椭圆
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
                    ERPmark(ioObj,address,ST_data_out_t1);
                end
                Screen('DrawTexture',winPtr,textoval,[],[x0-ovalsize/2,y0-ovalsize/2,x0+ovalsize/2,y0+ovalsize/2]);
                for num = 1:numstim-1
                    Screen('Flip',winPtr,0,1);%前面几帧呈现完不消失
                end
                Screen('Flip',winPtr);%最后一帧呈现完消失
            end
            
            time3 = GetSecs;  % 记录整个刺激呈现结束的时间点
            
            % wait for a response
            resp = []; resptime = []; xlocation = []; ylocation = []; resphistory = []; textshown = [];
            DrawFormattedText(winPtr,double(textstrSTA),x0-200-(BoundsRectSTA(3)-BoundsRectSTA(1))/2,y0-200-(BoundsRectSTA(4)-BoundsRectSTA(2))/2,expinfo.instcolr);
            
            shownstim = Shuffle(lettlist_perm(T1pos-4:T1pos+4));
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
                    if numel(find(find(keycode) == respKeys1)) == 1
                        target        = find(find(keycode) == respKeys1);
                        resp          = [resp shownstim(target)];
                        resptime      = [resptime secs-time3];
                        resphistory   = [resphistory shownstim(target)];
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
                                    shownlett(i,j,:) = expinfo.tarcolr;
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
                        xlocation = xlocation(1:respmax); ylocation = ylocation(1:respmax); resp = resp(1:respmax); textshown = textshown(1:respmax);
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
            
            % 这里是根据被试的反应正确与否，按照条件以及正确反应和错误反应储存对应EEG数据
            if resp(1)  == lettlist_perm(T1pos)
                ST_data_out = 50 + 100;
                ERPmark(ioObj,address,ST_data_out);%mark T1 response citral correct:150
            else
                ST_data_out = 50 + 200;
                ERPmark(ioObj,address,ST_data_out);%mark T1 response citral wrong:250
            end
            
            % save all the results after each trial
            data.ST_lettseq{blk}{trl,:}      = lettlist_perm;
            data.ST_lett{blk}(trl,:)         = lettlist_perm(T1pos);
            data.ST_T1pos{blk}{trl,:}        = T1pos;
            data.ST_resp{blk}(trl,:)         = resp;
            data.ST_resptime{blk}{trl,:}     = resptime;
            data.ST_resphistory{blk}{trl,:}  = resphistory;
            data.ST_letttime{blk}(trl,:)     = time3-time1; % 当前试次从刺激开始呈现到最后一个刺激消失整体的时间
            data.ST_T1time{blk}(trl,:)       = tpoint; % 这里有改动 data.T1T2point{i,blk}(trl(i,blk),:)   = tpoint;
            % 将T1和T2对应出现的时间点储存在tpoint中
            data.ST_ISI{blk}{trl,:}          = ISI;
            save(expinfo.path2save,'data');            
            
            ST_trlT = ST_trlT + 1 ;
            if ST_trlT == 36
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
                ST_trlT = 0;
            end
            
            Screen('FillRect',winPtr,expinfo.backcolr);
            Screen('Flip',winPtr);
        end
        
        Screen('FillRect',winPtr,expinfo.backcolr);
        vbl = Screen('Flip',winPtr);
        frames4break = floor(expinfo.withnblk);
        if blk < length(expinfo.sequence)
            for m = 1:frames4break
                showTmin1 = floor(floor((expinfo.withnblk-(m-1))/60)/10);
                showTmin2 = rem(floor((expinfo.withnblk-(m-1))/60),10);
                showTsec1 = floor(rem(expinfo.withnblk-(m-1),60)/10);
                showTsec2 = rem(rem(expinfo.withnblk-(m-1),60),10);
                DrawFormattedText(winPtr,double('请休息一会儿'),150,y0-50,expinfo.instcolr);
                Screen('DrawText',winPtr,[num2str(showTmin1) num2str(showTmin2) ':' num2str(showTsec1) num2str(showTsec2)],150,y0+50,expinfo.instcolr);
                vbl = Screen('Flip',winPtr,vbl+(1/ifi-0.5)*ifi);
                [~, ~, keycode] = KbCheck;
                if keycode(quitKey);flag = 1; break;end
            end
        end
        if flag == 1; break; end
    end
    %% Dual-target TASK SESSION
    % setup trial sequence in a block
    flag   = 0;
    % Dual-TASK SESSION
    %     T1loc     = repmat([5 6 7],1,1);   T2loc = [2 5 8];
    T1loc     = repmat([5 6 7],1,8);   T2loc = [2 5 8]; % repmat 函数用于重复数组,它将向量 [5 6 7] 重复12次，形成一个12行3列的矩阵。
    % 试次数在这里调
    [S1,S2]   = ndgrid(T1loc,T2loc);
    SS        = [S1(:) S2(:)];
    for blk = 1:length(expinfo.sequence)  % 4 blk
        SS    = SS(randperm(size(SS,1)),:); % randperm(size(SS,1)) SS中第一维度的所有数据做随机，SS(randperm(size(SS,1)),:)  使用上一步生成的随机排列向量作为行索引，选择 SS 的行
        
        % present the instruction  指导语部分不需要打mark
        textstr1    = ['双目标任务测试第' num2str(blk) '组:'];  % 这里需要修改一下
        BoundsRect1 = Screen('TextBounds',winPtr,double(textstr1));
        DrawFormattedText(winPtr,double(textstr1),x0-150-(BoundsRect1(3)-BoundsRect1(1))/2,y0-300-(BoundsRect1(4)-BoundsRect1(2))/2,expinfo.instcolr);
        DrawFormattedText(winPtr,double(textstr2),x0-350-(BoundsRect2(3)-BoundsRect2(1))/2,y0-200-(BoundsRect2(4)-BoundsRect2(2))/2,expinfo.instcolr,[],[],[],2);
        if expinfo.sequence(blk) == 1
            DrawFormattedText(winPtr,double(textstr3),x0-350-(BoundsRect3(3)-BoundsRect3(1))/2,y0+200-(BoundsRect3(4)-BoundsRect3(2))/2,expinfo.instcolr,[],[],[],2);
        end
        Screen('Flip',winPtr)
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
        
        % start each trial
        trlT          = 0;
        for trl = 1:size(SS,1)
            T1pos = SS(trl,1);
            T2pos = SS(trl,2);
            lettlist_perm  = Shuffle(lettlist);
            lettlist_perm  = lettlist_perm(1:expinfo.seqlength);
            T1lett = Lett{ismember(lettlist,lettlist_perm(T1pos))};
            T2lett = Lett{ismember(lettlist,lettlist_perm(T1pos+T2pos))};
            
            numstim  = expinfo.stimdura;%frame of stim
            numISI   = expinfo.stdura-numstim;
            for i = 1:size(T1lett,1)
                for j = 1:size(T1lett,2)
                    if T1lett(i,j,1:3) ~= expinfo.backcolr
                        T1lett(i,j,1:3) = expinfo.tarcolr;
                    end
                end
            end
            for i = 1:size(T2lett,1)
                for j = 1:size(T2lett,2)
                    if T2lett(i,j,1:3) ~= expinfo.backcolr
                        T2lett(i,j,1:3) = expinfo.tarcolr;
                    end
                end
            end
            textt1 = Screen('MakeTexture',winPtr,T1lett);
            textt2 = Screen('MakeTexture',winPtr,T2lett);
            
            ISIframe = length(lettlist_perm);
            ISIseq   = repmat(numISI,1,ISIframe);
            %             % 这里设置注视点、T1和T2的数值
            if expinfo.sequence(blk) == 1
                data_out_cue    = 1;
                data_out_fix    = 10;
                data_out_t1     = 11; % 分别按照T1和T2的位置生成对应的data_out data_out_t1=11
                data_out_t2     = 10 + T2pos; % T2：258 data_out_t2= 12/15/18
            elseif expinfo.sequence(blk) == 2
                data_out_cue    = 2;
                data_out_fix    = 20;
                data_out_t1     = 21; % 分别按照T1和T2的位置生成对应的data_out data_out_t1=21
                data_out_t2     = 20 + T2pos; % T2：258 data_out_t2= 22/25/28
            end
            %
            % 线索及mark
            Screen('FillRect',winPtr,expinfo.backcolr);
            Screen('Flip',winPtr);
            WaitSecs(1);
            if expinfo.sequence(blk) == 1
                lineLength = T2pos;
                lineWidth = 7;
                singleLineLength = 1 * ppd(1); % single Segment length
                gapLength = 0.2 * ppd(1); % Segment interval length
                totalLengthWithGaps = (singleLineLength * lineLength) + (lineLength - 1) * gapLength;
                for i = 1:lineLength
                    startX = x0 - (totalLengthWithGaps / 2) + ((i - 1) * (singleLineLength + gapLength));
                    endX = startX + singleLineLength;
                    Screen('DrawLine', winPtr, [105,105,105], startX, y0, endX, y0, lineWidth);
                end
            else
                Screen('DrawTexture',winPtr,textfix,[],[x0-stimsize/2,y0-stimsize/2,x0+stimsize/2,y0+stimsize/2]);
            end
            Screen('Flip', winPtr);
            ERPmark(ioObj,address,data_out_cue);
            WaitSecs(1);
            
            Screen('DrawTexture',winPtr,textCrossfix,[],[x0-stimsize/2,y0-stimsize/2,x0+stimsize/2,y0+stimsize/2]);
            Screen('Flip', winPtr);
            ERPmark(ioObj,address,data_out_fix);
            WaitSecs(1);
            %
            time1 = GetSecs; % 记录整个刺激呈现开始的时间点
            tpoint = []; ISI = [];
            for stim = 1:length(lettlist_perm)
                isi1 = GetSecs;
                for num = 1:ISIseq(stim) % 画椭圆
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
                    ERPmark(ioObj,address,data_out_t1);
                    % 在特定条件下（stim == T1pos 或 stim == T1pos+T2pos）获取，记录特定刺激呈现的时间点，并将其与 time1 的差值存储在 tpoint 数组中。
                    % 分别保存T1和T2呈现的时间
                elseif stim == T1pos+T2pos
                    Screen('DrawTexture',winPtr,textt2,[],[x0-stimsize/2,y0-stimsize/2,x0+stimsize/2,y0+stimsize/2]);
                    time2 = GetSecs; tpoint = [tpoint time2-time1];
                    ERPmark(ioObj,address,data_out_t2);
                end
                Screen('DrawTexture',winPtr,textoval,[],[x0-ovalsize/2,y0-ovalsize/2,x0+ovalsize/2,y0+ovalsize/2]);
                for num = 1:numstim-1
                    Screen('Flip',winPtr,0,1);%前面几帧呈现完不消失
                end
                Screen('Flip',winPtr);%最后一帧呈现完消失
            end
            
            time3 = GetSecs;  % 记录整个刺激呈现结束的时间点
            
            
            % wait for a response
            resp = []; resptime = []; xlocation = []; ylocation = []; resphistory = []; textshown = [];
            DrawFormattedText(winPtr,double(textstr4),x0-200-(BoundsRect4(3)-BoundsRect4(1))/2,y0-200-(BoundsRect4(4)-BoundsRect4(2))/2,expinfo.instcolr);
            
            
            if T2pos <= 4
                shownstim = Shuffle(lettlist_perm(T1pos+T2pos-4:T1pos+T2pos+4));
            else
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
                    if numel(find(find(keycode) == respKeys1)) == 1
                        target        = find(find(keycode) == respKeys1);
                        resp          = [resp shownstim(target)];
                        resptime      = [resptime secs-time3];
                        resphistory   = [resphistory shownstim(target)];
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
                                    shownlett(i,j,:) = expinfo.tarcolr;
                                end
                            end
                        end
                        textshown = [textshown Screen('MakeTexture',winPtr,shownlett)];
                    elseif keycode(spaceKey)
                        xlocation = []; ylocation = []; resp = []; textshown =[];
                    end
                    
                    respmax = 2;
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
            
            %             if expinfo.sequence(blk) == 1
            %                 if resp(1)  == lettlist_perm(T1pos)  % T1:567 258
            %                     if resp(2) == lettlist_perm(T1pos + T2pos)
            %                         data_out = 10 + T1pos + T2pos +100; % 117,120,123,118,121,124,119,122,125
            %                         ERPmark(ioObj,address,data_out);% mark T1 correct and T2 correct
            %                     else
            %                         data_out = 10 + T1pos + T2pos +200; % 217,220,223,218,221,224,219,222,225
            %                         ERPmark(ioObj,address,data_out);% mark T1 correct and T2 incorrect
            %                     end
            %                 else
            %                     data_out = 10 + T1pos + T2pos +150; % 167,170,173,168,171,174,169,172,175
            %                     ERPmark(ioObj,address,data_out);% mark T1 incorrect
            %                 end
            %             elseif expinfo.sequence(blk) == 2
            %                 if resp(1)  == lettlist_perm(T1pos)  % T1:567 258
            %                     if resp(2) == lettlist_perm(T1pos + T2pos)
            %                         data_out = 30 + T1pos + T2pos +100; % 137,140,143,138,141,144,139,142,145
            %                         ERPmark(ioObj,address,data_out);% mark T1 correct and T2 correct
            %                     else
            %                         data_out = 30 + T1pos + T2pos +200; % 237,240,243,238,241,244,239,242,245
            %                         ERPmark(ioObj,address,data_out);% mark T1 correct and T2 incorrect
            %                     end
            %                 else
            %                     data_out = 30 + T1pos + T2pos +150; % 187,190,193,188,191,194,189,192,195
            %                     ERPmark(ioObj,address,data_out);% mark T1 incorrect
            %                 end
            %             end
            
            if expinfo.sequence(blk) == 1
                if resp(1)  == lettlist_perm(T1pos)  % T1:567 258
                    if resp(2) == lettlist_perm(T1pos + T2pos)
                        data_out = 10 +100; % 110
                        ERPmark(ioObj,address,data_out);% mark T1 correct and T2 correct
                    else
                        data_out = 20 +200; % 210
                        ERPmark(ioObj,address,data_out);% mark T1 correct and T2 incorrect
                    end
                else
                    data_out = 99; % 99
                    ERPmark(ioObj,address,data_out);% mark T1 incorrect
                end
            elseif expinfo.sequence(blk) == 2
                if resp(1)  == lettlist_perm(T1pos)  % T1:567 258
                    if resp(2) == lettlist_perm(T1pos + T2pos)
                        data_out = 20 + 100; % 120
                        ERPmark(ioObj,address,data_out);% mark T1 correct and T2 correct
                    else
                        data_out = 20 + 200; % 220
                        ERPmark(ioObj,address,data_out);% mark T1 correct and T2 incorrect
                    end
                else
                    data_out = 199; % 199
                    ERPmark(ioObj,address,data_out);% mark T1 incorrect
                end
            end
            
            % save all the results after each trial
            data.lettseq{blk}{trl,:}      = lettlist_perm;
            data.lett{blk}(trl,:)         = [lettlist_perm(T1pos) lettlist_perm(T1pos+T2pos)];
            data.T1T2pos{blk}{trl,:}      = [T1pos T2pos];
            data.resp{blk}(trl,:)         = resp;
            data.resptime{blk}{trl,:}     = resptime;
            data.resphistory{blk}{trl,:}  = resphistory;
            data.letttime{blk}(trl,:)     = time3-time1; % 当前试次从刺激开始呈现到最后一个刺激消失整体的时间
            data.T1T2time{blk}(trl,:)     = tpoint; % 这里有改动 data.T1T2point{i,blk}(trl(i,blk),:)   = tpoint;
            % 将T1和T2对应出现的时间点储存在tpoint中
            data.ISI{blk}{trl,:}          = ISI;
            save(expinfo.path2save,'data');
            
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
            
            Screen('FillRect',winPtr,expinfo.backcolr);
            Screen('Flip',winPtr);
        end
        
        Screen('FillRect',winPtr,expinfo.backcolr);
        vbl = Screen('Flip',winPtr);
        frames4break = floor(expinfo.withnblk);
        if blk < length(expinfo.sequence)
            for m = 1:frames4break
                showTmin1 = floor(floor((expinfo.withnblk-(m-1))/60)/10);
                showTmin2 = rem(floor((expinfo.withnblk-(m-1))/60),10);
                showTsec1 = floor(rem(expinfo.withnblk-(m-1),60)/10);
                showTsec2 = rem(rem(expinfo.withnblk-(m-1),60),10);
                DrawFormattedText(winPtr,double('请休息一会儿'),150,y0-50,expinfo.instcolr);
                Screen('DrawText',winPtr,[num2str(showTmin1) num2str(showTmin2) ':' num2str(showTsec1) num2str(showTsec2)],150,y0+50,expinfo.instcolr);
                vbl = Screen('Flip',winPtr,vbl+(1/ifi-0.5)*ifi);
                [~, ~, keycode] = KbCheck;
                if keycode(quitKey);flag = 1; break;end
            end
        end
        if flag == 1; break; end
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
    Screen('Preference', 'SuppressAllWarnings', oldSupressAllWarnings);
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
    Screen('Preference', 'SuppressAllWarnings', oldSupressAllWarnings);
    ListenChar(0);
    psychrethrow(psychlasterror);
end % try ... catch %