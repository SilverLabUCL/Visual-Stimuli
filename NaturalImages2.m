function NaturalImages2

%this script presents natural images with this protocol:

%repeted a number of times defined in repetitions:
%trigger
%for the time in the variable "gray_delay" gray screen
%for the time in the variable "movie_delay" one image
%goes through all the images, then goes back to wait for the trigger

%the order of image presentation can be randomized and the order is saved
%square for photodiode recordings possible


try
    % This script calls Psychtoolbox commands available only in OpenGL-based
    % versions of the Psychtoolbox. (So far, the OS X Psychtoolbox is the
    % only OpenGL-base Psychtoolbox.)  The Psychtoolbox command AssertPsychOpenGL will issue
    % an error message if someone tries to execute this script on a computer without
    % an OpenGL Psychtoolbox
    AssertOpenGL;
    
    %photodiode settings
    use_pd=1;                        % 0 disables photodiode square
    diodesz=100;                    %size of photodiode detection square in pixels
    
    %Parameters
    filename='C:\Users\Chiara\Documents\MATLAB\visual stimuli\natural images\NatImag.mat'; %where to take the natural images
    load(filename)
    n_pictures=length(Images);
    frames=[1:n_pictures];
    repetitions=2; %number of trials 
    set_trigger=0  ;                      % 0 disables external trigger, 1 activates external trigger
    test = 1  ;                       % set to 1 if you wan    t to test without external triggering
    
    gray_delayStart=2.2; % First delay in the trial of gray screen before image presentation in seconds
    gray_delay=2.6; % delay of gray screen before image presentation in seconds
    movie_delay=0.4; % movie duration in seconds
    rand_fr=1;      % select 1 to randomize frames
    
    % window configuration
    clear mex;
    timestampmode=1;
    Screen('Preference', 'VBLTimestampingMode', timestampmode);
    tic
    [window,screenRect,ifi,whichScreen]=initScreen;
    init_delay=toc;
    HideCursor;
    priorityLevel=MaxPriority(window);
    Priority(priorityLevel);
   
   
    
    % images loading
  
    for i=1:n_pictures;
        imgtex(i)=Screen('MakeTexture', window, Images{i});
    end
 
    % parameters:
    hz=1/ifi;
    
    %set the trigger
    if test == 0
        dio = digitalio('nidaq','Dev1');
        %dio2 = digitalio('nidaq',1);
        addline(dio,0,'in');
        %addline(dio2,1,'out');
    end
    
    %where to save the order of image presentation
    dirname=['C:\Users\Chiara\Documents\MATLAB\visual stimuli\natural images' '\' datestr(now, 'yyyy_mm_dd') '\' datestr(now, 'yyyy_mm_dd_HH_MM_SS') ];
    mkdir(dirname);
    save([dirname '\imagesPresented.mat'],'Images')
    
    Screen('FillRect', window,127);
    Screen('Flip',window);
    tic
    
    
    for rep=1:repetitions;
        
        %randomize image order if required
        if rand_fr
        rand_frames=randperm(n_pictures);
        else
        rand_frames=frames;
        end
        
        %wait for the trigger
            if set_trigger
                if getvalue(dio),
                    while getvalue(dio),end
                end
                while ~getvalue(dio),
                    if KbCheck Screen('Close');    clear mex,clear imgstack,clear imgtex Images ans i prioritylevel rand_frames rep w
                        ,return,end;
                end
            else
                while ~KbCheck;end
                pause(0.5);
            end

        
        for i=1:n_pictures
            frame_order(rep,i)=rand_frames(i);  %save order of images presented
            toclist(i,rep)=toc;
            
            
            % delay of gray screen
            
            if i==1
                Gray_delay=gray_delayStart;
            else
                Gray_delay=gray_delay;
            end
            
            
            for w=1:Gray_delay*hz;
                Screen('FillRect', window,120);
                if use_pd % photodiode
                    Screen('FillRect', window,0,[screenRect(1) screenRect(4)-diodesz diodesz screenRect(4)] );
                end
                
                Screen('Flip',window);
                if KbCheck Screen('Close');    clear mex,clear imgstack i ii,clear imgtex Images ans i prioritylevel rand_frames rep w
                    ,
                    save([dirname '\image_sequence.mat'],'frame_order'),return,end;
            end
            
            
            
            % image presentation
            for delay=1:movie_delay*hz;
                Screen('DrawTexture', window, imgtex(rand_frames(i)),[],screenRect);
                if use_pd %photodiode
                    Screen('FillRect', window,255,[screenRect(1) screenRect(4)-diodesz diodesz screenRect(4)] );
                end
                
                Screen('Flip',window);
                if KbCheck Screen('Close');    clear mex,clear imgstack i ii,clear imgtex Images ans i prioritylevel rand_frames rep w
                    
                    save([dirname '\image_sequence.mat'],'frame_order'),return,end;
            end
            Screen('FillRect', window,120);
            
            if use_pd
                Screen('FillRect', window,0,[screenRect(1) screenRect(4)-diodesz diodesz screenRect(4)] );
            end
            Screen('Flip',window);
        end
        
        
    end
    
    Screen('FillRect', window,120);
    if use_pd
        Screen('FillRect', window,0,[screenRect(1) screenRect(4)-diodesz diodesz screenRect(4)] );
    end
    Screen('Flip',window);
    KbWait;
    Screen('Close')
    clear mex,clear imgstack i ii,clear imgtex Images ans i prioritylevel rand_frames rep w 
    save([dirname '\image_sequence.mat'],'frame_order')
    ShowCursor;
    
    
    
catch
    %this "catch" section executes in case of an error in the "try" section
    %above.  Importantly, it closes the onscreen window if its open.
    Screen('CloseAll');
    Priority(0);
    psychrethrow(psychlasterror);
    
end %try..catch..




end