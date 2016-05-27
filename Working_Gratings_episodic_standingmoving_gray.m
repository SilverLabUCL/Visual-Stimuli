 function classic_ori_trig_20090129
try
clear mex;
clear all;
%Screen('Preference','SkipSyncTests', 1);
%Screen('Preference','VisualDebugLevel', 0);
%Screen('Preference', 'SuppressAllWarnings', 1);
%{
The behaviour of PTB can be controlled by the command:
  Screen('Preference', 'VBLTimestampingMode', mode); where mode can be one of the
  following:

  -1 = Disable all cleverness, take noisy timestamps. This is the behaviour
       you'd get from any other psychophysics toolkit, as far as we know.
   0 = Disable kernel-level fallback method (on OS-X), use either beamposition
       or noisy stamps if beamposition is unavailable.
   1 = Use beamposition. Should it fail, switch to use of kernel-level interrupt
       timestamps. If that fails as well or is unavailable, use noisy stamps.
   2 = Use beamposition, but cross-check with kernel-level timestamps.
       Use noisy stamps if beamposition mode fails. This is for the paranoid
       to check proper functioning.
   3 = Always use kernel-level timestamping, fall back to noisy stamps if it fails.
%}
timestampmode=1;
Screen('Preference', 'VBLTimestampingMode', timestampmode);
tic
[window,screenRect,ifi,whichScreen]=initScreen;
init_delay=toc



HideCursor;
% ---------------:configuration variables:----------------

% Screen parameters:
screenSize = 58;              % x screen size in centimeters
mouseDistancecm = 20;           % mouse distance from the screen im cm
mouseCenter = [(screenRect(3)-screenRect(1)) (screenRect(4)-screenRect(2))]/2; % in pixel coordinates (position the mouse pointer on the screen an use GetMouse in MatLab)
% [(screenRect(3)-screenRect(1)) (screenRect(4)-screenRect(2))]/2 is screen center


% Grating parameters:
grating_type = 1;               % 0 creates sine grating, 1 creates square wave grating
temp_freq = 2;                % temporal frequency in 1/seconds
space_freq_deg = 0.035 ;              % spatial frequency in 1/pixels
background_color = [0 0 0];   % background color in R G B
grating_high_color = [255 255 255]; % grating color in R G B
grating_low_color = [0 0 0];  % grating color in R G B
contrast=100 %% percentage difference between grating high and low bars

% Parameters of patches and orientations:
n_patches = [1, 1];             % number of patches in x and y
field_of_view = [120,90];        % size of the field of view in degree
view_offset =[0,0];        % offset of the field of view
rel_patch_size = 2;            % patch size: 1: touching  - 0.5: size an distance is equal
%patch_time = 2;               % 1time in seconds one patch is shown
ori_delay = 1          ; %6               % time in seconds after trigger grating starts drifting
orientation_time = 2; %2           % time in seconds after the orientation changes
orientations = 2;               % number of orientations for randomisation
angle_increment=225;   

% randomization settings (0 creates sequential order, 1 creates random order:
randset_eye=0;
randset_patch=0;
randset_ori=0 ;

mouseDistance = fix((screenRect(3) / screenSize) * mouseDistancecm);           % in pixel
space_freq = 1 / ( 2 * mouseDistancecm * tan( ( ( 1 / space_freq_deg ) * pi / 180 ) / 2 ) * 1024 / screenSize );   % edit jleong 050718


set_trigger=0               ;                      % 0 disables external trigger, 1 activates external trigger
test =1                    ;                       % set to 1 if you wan    t to test without external triggering
showPatches = test; 

 
ext_patch_nr = 0;                    % 1 means external generated pach number (OI)
n_repetitions =  10             ;              % number of stim cycles
binoc_stim = 0;                    % 1 means use binocular stimulation with shutters
%putvalue(dio.Line(2),1); shutter right eye (ipsi) closed
%putvalue(dio.Line(3),0); shutter left eye (contra) opened         
% => eye1=1 in outputfile
%---------------------------------------------------------
patch_time=orientation_time;
patch_delay=ori_delay;
xoffset=0;

if test == 0
    dio = digitalio('nidaq','Dev1');
    addline(dio,0,1,'in');
     dio2 = digitalio('nidaq','Dev1');
      addline(dio2,[0 1],'out');
end

hz=1/ifi


mkdir(['C:\MAT_DATA' '\' datestr(now, 'yyyy_mm_dd')]);
starttimestr=['C:\MAT_DATA' '\' datestr(now, 'yyyy_mm_dd') '\' datestr(now, 'yyyy_mm_dd_HH_MM_SS')];

HideCursor;


p1=ceil(1/(space_freq/2));
shiftperframe= p1 * ifi * temp_freq;

%%% sets the transparency of the RGBA planes. The black/white grating is
%%% overlayed with an inverse of itself. By changing the transparency of
%%% the overlay you can control the contrast. 0=fully transparent,
%%% 255=fully opaque. Contrast is high at either extreme but lowest when
%%% overlay is mid tranparent (127.5). Shuold be able to get given percent
%%% contrast with 127 + desidered percentage*(127.5/100)
transparency=127.5+(contrast*(127.5/100));
o=1;  

g=transparency*gratingBruno(grating_type,(screenRect(1)+1:screenRect(3)*2), (screenRect(2)+1:screenRect(4)*2), (o-1) * 360/orientations, space_freq/2)/1;
gratingtex=Screen('MakeTexture', window, g);
BW=zeros(prod(n_patches),screenRect(4),screenRect(3)-screenRect(1),2);


%orientationFrames = round(orientation_time * hz);

priorityLevel=MaxPriority(window);


Priority(priorityLevel);

Screen('FillRect', window,127);
Screen('Flip',window);
%{
    if set_trigger
                 while ~getvalue(dio.Line(1)), if KbCheck clear mex,return,end,end
    end
%}
if set_trigger
            
    %         toc
    if getvalue(dio.Line(1)),
        while getvalue(dio.Line(1)),end
    end
    while ~getvalue(dio.Line(1)),
        if KbCheck Screen('Close');clear mex,return,end;
    end
else
    while ~KbCheck;end
    pause(0.5);
end

tic
for j=1:n_repetitions
    repet=j;
    n = 1 + binoc_stim;
    if randset_eye
        rand_eye=randperm(n);
    else
        rand_eye=1:n;
    end
    
    for eye=1:n
        eye1=rand_eye(eye);
        rand_log.repetition(j).eye(eye).eyedentity=eye1;
        diovalue=logical(eye1-1);
%         putvalue(dio2.Line(2),~diovalue);
%         putvalue(dio2.Line(3),diovalue);
        stim_ids = 1:prod(n_patches);

        rand_oriidx = 0;
        if randset_ori
            rand_ori=randperm(orientations);
        else
            rand_ori=0:(orientations-1);
        end



        for s=1: orientations;
            toclist(s,j,1)=toc;
            orien=s;


            i2=0;

            % rand_log.repetition(j).eye(eye).patches(s).patchxy(1)=floor((s1-1)/n_patches(2))+1;
            %rand_log.repetition(j).eye(eye).patches(s).patchxy(2)=mod(s1-1,n_patches(2))+1;
            %rand_log.repetition(j).eye(eye).patches(s).patchidx=s1;
            rand_oriidx = rand_oriidx + 1;
            rand_log.repetition(j).eye(eye).ori(s)=rand_ori(rand_oriidx)*angle_increment;
            angle=90+rand_ori(rand_oriidx)*angle_increment;
            srcRect=[xoffset 0 (xoffset + screenRect(3)*2) screenRect(4)*2];

            Screen('DrawTexture', window, gratingtex, srcRect, [], angle);
            Screen('Flip',window);



    

            if       j*eye*s>1;
                

                if set_trigger
                    getvalue(dio.Line(1))
                    if getvalue(dio.Line(1)),
                        j*eye*s;
                        while getvalue(dio.Line(1)),end
                    end
                    while ~getvalue(dio.Line(1)),
                         j*eye*s;
                        if KbCheck Screen('Close');clear mex,save([starttimestr '_classic_ori']);
                            return,end;
                    end
                else
                     while ~KbCheck;
                     Screen('FillRect', window,127);
Screen('Flip',window);
end
                    pause(0.5);
                end
            end

toclist(s,j,2)=toc;
            for w=1:patch_delay*hz;
             if toc-toclist(s,j,2)<(patch_delay)   
                       
                Screen('DrawTexture', window, gratingtex, srcRect, [], angle);
                Screen('Flip',window);
             else
                 break
             end
                if KbCheck clear mex,
                    clear Warte angle ans clutCounter clut_cycles ext_patch_nr eye i i2 j la lo ...
                        masktex n o p p1 priorityLevel rand_ori rand_oriidx rand_patches s s1 ...
                        srcRect stim_ids window x xx y yy;

                    save([starttimestr '_classic_ori']);
                    ShowCursor;
                    return
                end
            end
            for i=1:patch_time * hz
               % tic

                if KbCheck clear mex,
                    clear Warte angle ans clutCounter clut_cycles ext_patch_nr eye i i2 j la lo ...
                        masktex n o p p1 priorityLevel rand_ori rand_oriidx rand_patches s s1 ...
                        srcRect stim_ids window x xx y yy;

                    save([starttimestr '_classic_ori']);
                    ShowCursor;
                    return
                end
if toc-toclist(s,j,2)<(patch_delay+patch_time)
                xoffset = mod(i2*shiftperframe,p1);
                i2=i2+1;

                % Define shifted srcRect that cuts out the properly shifted rectangular
                % area from the texture:
                srcRect=[xoffset 0 (xoffset + screenRect(3)*2) screenRect(4)*2];

                % Draw grating texture, rotated by "angle":
                Screen('DrawTexture', window, gratingtex, srcRect, [], angle);
                %Screen('DrawTexture', window, masktex(1),[],screenRect);

                Screen('Flip',window);
%                 rand_log.repetition(j).eye(eye).patches(s).timing(i)=toc;
else
    break
end

end
toclist(s,j,3)=toc;
Screen('FillRect', window,127);
Screen('Flip',window);

        end
    end

end
Screen('FillRect', window,127);
Screen('Flip',window);
KbWait
clear mex,
clear Warte angle ans clutCounter clut_cycles ext_patch_nr eye i i2 j la lo ...
    masktex n o p p1 priorityLevel rand_ori rand_oriidx rand_patches s s1 ...
    srcRect stim_ids window x xx y yy;

save([starttimestr '_classic_ori']);
ShowCursor;
Screen('CloseAll');
catch
    %this "catch" section executes in case of an error in the "try" section
    %above.  Importantly, it closes the onscreen window if its open.
    Screen('CloseAll');
    Priority(0);
    %psychrethrow(psychlasterror);
end %try..catch..
