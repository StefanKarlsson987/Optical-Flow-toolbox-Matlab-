% Copyright: Stefan  M. Karlsson, Josef Bigun 2014
function [vid,width,height, nofFrames] =  myVidSetup(kindOfMovie,movieType,width, height,camID,startingTime,frameRatePref)
% myVidSetup- setups the video feed. 3 types are handled different,
% depending on the 'kindOfMovie' input arg. Can be 'file'(file on disk),
% 'synthetic'(manufactured test sequence) or 'camera' (setups the default 
% video input device for capturing video for this application)
if nargin < 6
    startingTime = 1;
end
if nargin < 5
    camID = 1;
end
nofFrames = Inf; % will change below if specified movie source is saved data ('folder' or 'file')
vid.camID = camID;
vid.bUseCam = 0; %if camera used, will be 1(toolbox) or 2(windows stand-alone lib)

if strcmpi(kindOfMovie, 'file') 
  if startingTime == 1
        %we open the file for reading
    try  %first try to get the computer vision toolbox videoreader:
        vid = vision.VideoFileReader(movieType,...
            'ImageColorSpace','Intensity',...
            'VideoOutputDataType','single');
      	vidtmp = VideoReader(movieType); %only the built in VideoReader gives nofFrames
        nofFrames = vidtmp.numberOfFrames;
        clear vidtmp;

    catch %if that didnt work, we go with the built in Videoreader:
%         disp('computer vision avi reading not available')
        vid = VideoReader(movieType);
        nofFrames = vid.numberOfFrames;

    end
  else %if startingTime ~= 1
      vid = VideoReader(movieType); %only the built in VideoReader can handle seeking
      nofFrames = vid.numberOfFrames;
  end
  
    info = mmfileinfo(movieType);
    height = info.Video.Height;
    width = info.Video.Width;
    
elseif strcmpi(kindOfMovie, 'folder')
      clear getSavedFlow;
      [~, ~, ~,vid] = getSavedFlow(startingTime-1, movieType);
      height = vid.vidRes(1);
      width  = vid.vidRes(2);
      nofFrames = vid.nofFrames;
elseif strcmpi(kindOfMovie, 'synthetic') 
    vid.Height = height;   vid.Width  = width;
elseif strcmpi(kindOfMovie, 'camera')
    vid.bUseCam = 1; %matlab built in
    vid.Height = height;   vid.Width  = width;
%         first, reset image aqcuisition devices. This also tests if the
%         toolbox is available. 
    try
       imaqreset;
       imaqhwinfo('winvideo',camID);
    catch %#ok<CTCH>
        fprintf('\nImage Aquisition toolbox not available(or you need to configure it for webcam support)! \n Looking for videoinput library instead(this is a windows ONLY library)... ');
        vid.bUseCam = 2; %videoInput
        try
            addpath(fullfile('helperFunctions', 'VideoinputLib'));
            VI = vi_create();
            vi_delete(VI);
            fprintf('FOUND IT!\n');
        catch %#ok<CTCH>
            rmpath(fullfile('helperFunctions', 'VideoinputLib'));
            error('no library available for camera input. You can download it from my webpage: http://islab.hh.se/mediawiki/Stefan_Karlsson/PersonalPage');
        end
    end
    if(vid.bUseCam==1) %matlab built-in

    dev_info = imaqhwinfo('winvideo',camID);
    strVid = dev_info.SupportedFormats;

    splitStr = regexpi(strVid,'x|_','split');
    pickedFormat = 0;          %integer, indicating which format chosen
    resolutionFormat = [Inf, Inf];
    % goodFormats  = {'RGB','YUY'};
    goodFormats  = {'YUY','RGB'};
    nastyFormats = {'MJP'};

    ValueOfPic = 0; %format pref, negative:nasty, 0:unknown, positive:good
    for ik = 1:length(strVid)
    %     fprintf([splitStr{ik}{1} ' ' splitStr{ik}{2} ' ' splitStr{ik}{3} ', '])
        resW = str2double(splitStr{ik}{2}); %width  of this format
        resH = str2double(splitStr{ik}{3}); %height of this format

        %we will pick this format, if it supports the requested height
        %and width, AND if its resolution (resW*resH) is smaller than
        %previously found formats
        thisValue = 1;
        if (resW > (width-1) )&&(resH > (height-1) )&& (resW*resH)<=(resolutionFormat(1)*resolutionFormat(2))
            for kk = 1:length(goodFormats)
                if ~isempty(strfind(splitStr{ik}{1},goodFormats{kk}))
                    thisValue = kk;
                end
            end
            for kk = 1:length(nastyFormats)
                if ~isempty(strfind(splitStr{ik}{1},nastyFormats{kk}))
                    thisValue = -kk;
                end
            end
            if thisValue >= ValueOfPic
                ValueOfPic = thisValue;
                resolutionFormat = [resW,resH];
                pickedFormat = ik;
            end
        end
    end
    % pick the selected format, color format and a region of interest:
    vid.camIn = videoinput('winvideo',camID,strVid{pickedFormat});

%      set(vid.camIn,'FramesPerTrigger', Inf);
%      set(vid.camIn,'FramesAcquiredFcnCount', 1);
%      set(vid.camIn,'FramesAcquiredFcn',  {@onFrameUpdate});
%      set(vid.camIn,'ReturnedColorSpace','grayscale');
% %     triggerconfig(vid.camIn, 'manual');
%   	triggerconfig(vid.camIn, 'immediate');
%     set(vid.camIn,'TriggerRepeat',1);

%      set(vid.camIn,'TimerFcn',  {@onFrameUpdate});
% set(vid.camIn,'TimerPeriod',  1/30);
    set(vid.camIn,'ReturnedColorSpace','grayscale');
%      set(vid.camIn,'FramesPerTrigger', 1);
     triggerconfig(vid.camIn, 'manual');
%      set(vid.camIn,'TriggerRepeat',Inf);     
    
    ratio = width/height;
    ratioRaw = resolutionFormat(1)/resolutionFormat(2);
    fprintf(['Picked format ' strVid{pickedFormat}])

    %     calculate the center point roiC:
    if ratio > ratioRaw %then I need to find a new height
        newHeight = floor(resolutionFormat(1)/ratio);
        newWidth  = resolutionFormat(1);
        roiC = [0, floor((resolutionFormat(2)-newHeight+1)/2)];
    else%if ratio >= ratioRaw %then I need to find a new width
        newHeight = resolutionFormat(2);
        newWidth  = floor(resolutionFormat(2)*ratio);
        roiC = [floor((resolutionFormat(1)-newWidth+1)/2),0];
    end    
    set(vid.camIn, 'ROIPosition', [roiC(1),roiC(2),newWidth, newHeight]);

    %let the video go on forever, grab one frame every update time, maximum framerate:
    src = getselectedsource(vid.camIn);
    if isfield(get(src), 'FrameRate')
        frameRates = set(src, 'FrameRate'); %get the possible options for framerates
    %     set(src, 'FrameRate',frameRates{2});      %pick the first one, presumably the highest

        bestInd= 1;
        bestFR = str2double(frameRates{bestInd});

    % src = getselectedsource(vid.camIn);
         %pick the lowest framerate, higher than frameRatePref
        for pp = 1:length(frameRates)
            fr  = frameRates{pp};
            if ~isnumeric(fr)
                fr = str2double(fr);
            end
            if (bestFR < frameRatePref) % still have no valid pick, go higher
                if (fr > bestFR)
                    bestFR = fr;
                    bestInd= pp;
                end
            else% if (bestFR > frameRatePref)
                if ((fr < bestFR) && (fr >=frameRatePref))% have valid pick, go lower
                    bestFR = fr;
                    bestInd= pp;
                end            
            end

        end
        set(src,'FrameRate',frameRates{bestInd})
        fprintf([',with frame rate: ' get(getselectedsource(vid.camIn), 'FrameRate') '\n']);
    else
    fprintf(',with default frame rate(information not available) \n');
    end
    %other things you may want to play around with on your system(if settings exist):
    %         set(getselectedsource(vid.camIn), 'Sharpness', 1);
    %         set(getselectedsource(vid.camIn), 'BacklightCompensation','off');
    %         set(getselectedsource(vid.camIn), 'WhiteBalanceMode','manual');    
    % if running with the camera, now we start it:
     start(vid.camIn);
     pause(0.001);
    else %if vid.bUseCam == 2 
    % using videoinput library. This is an external windows library for 
    % grabbing from the connected camera. You may need to get compiled
    % binaries, see instructions in "helperFunctions" folder.
        vid.camIn = vi_create();
        numDevices = vi_list_devices(vid.camIn);
        if numDevices<1,    error('video input found no cameras');end
        vi_setup_deviceProper(vid.camIn, camID-1, vid.Height, vid.Width, 30);
    end 
end
