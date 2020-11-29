% Copyright: Stefan  M. Karlsson 2016
% version 1.05
function [fr,macroDat,im,u,v] = FancyFlowPlayer(pathToSave)
% Function to play-back a sequence of recorded optical flow(or just plain video file). 
% This function produces a small video player
%
% MOUSE INTERFACE
% * scroll-wheel: zooms relative to mouse cursor position in video
% * click and drag video windows(if zoomed): pans video around. 
% * click and drag seekbar: sets video progression
% * right-click video windows: add a small marker in the video and the
% flow illustration (helps to keep track of positions of interest)
%
% KEYBOARD INTERFACE
% * Q/A - increase/decrease lag-time
% * P or "space" - toggle pause
% * Left/Right arrow key - move video progress backward/forward one frame
%
% ARGS:
% IN:  pathToSave - directory where data is stored
% OUT: 
%     macroDat-  structure containing description of data
%     fr - frame index at the time of closing the player
%
% EXAMPLE
%%% Assume saved data is located in folder "Test"
%%% first, find a frame you are interested in interactively,  
%%% and then close down the FancyFlowPlayer...
% [fr,macroDat,im] = FancyFlowPlayer('Test');
%%% ... then access the data of the frame:
%%% im is the video frame
% figure;imagesc(im);

%keep track of previous selected folder:
persistent PathName; 

bPause  = 0;
bSeeking= 0;
bKillAll= 0;
reqFr   = 1;
draggingMode = -1;
ptPrev = [0 0];
oldLimL = [0 1 0 1];
oldLimR = [0 1 0 1];

% delaylist = -0.001*ones(1,1000);
if nargin == 0, %then open a dialog asking for a video file:
    if PathName == 0, PathName = [];end
    [FileName,PathName] = uigetfile('*','Select a video for playback',PathName);
    if FileName == 0,
        fr = [];macroDat = [];im = [];u = [];v = [];
        return;
    end
    pathToSave = fullfile(PathName,FileName);
end
% recorded flow will be in loaded matrices "u" and "v"
% load the first frame, sets up "getSavedData" for consecutive calls
[im, u, v, macroDat] = getSavedData(1, pathToSave);
pathToDisp = macroDat.path;

sizLeft  = size(im);
sizLeft = sizLeft(1:2);
sizRight = size(u);

nofLevels = floor(log(max(max(sizLeft),max(sizRight)))*1.7);
zoomLevels = 0.8.^linspace(0,nofLevels-1,nofLevels);
activeZoom = 1; 

if length(pathToDisp)>25
     pathToDisp =  [pathToDisp(1:3) '...' pathToDisp((end-20):end)];
end

hFig = figure('MenuBar', 'none','ToolBar', 'none',...
              'BusyAction','cancel',...
              'WindowKeyPressFcn',@locKeypress,...
              'CloseRequestFcn', @locClosefcn,...
              'WindowButtonUpFcn',@myMouseButtonUpFcn,...
              'WindowScrollWheelFcn',@locMouseScroll,...
              'NumberTitle','off','Name',['The FANCY FLOW PLAYER!!    Location: ' pathToDisp]);
if ~isempty(u)
    axPosL = [0.002 0.15 0.48 0.75];
    axPosR = [0.5199  0.15 0.48 0.75];    
else % isempty(u)
    axPosL = [0.002   0.15 0.96 0.75];
    axPosR = [];
end

hAxLeft  = subplot('Position',axPosL);
hIm = imagesc(im,[0 255]);colormap gray; axis image; 
set(hIm,'hitTest','off'); hold on

title(['Source of video input: ' macroDat.movieType]);
hCrossL = plot(0,0,'rx', 'Visible','off','MarkerSize',7,'hittest','off');
listOfAxes = hAxLeft;

if ~isempty(u)
    hAxRight = subplot('Position',axPosR);
    hFlow = imagesc(flow2colIm(u,v)); axis image; set(hFlow,'hitTest','off'); hold on
    hCrossR = plot(0,0,'wx','Visible','off','MarkerSize',7,'hittest','off');
    if strcmpi(macroDat.method, 'user')
        title(['Method: ' func2str(macroDat.userDefMethod)]);
    else
        if strcmpi(macroDat.method,'synthetic')
            title(['Method: Ground Truth (' macroDat.method ')']);
        else
            title(['Method: ' macroDat.method]);
        end
    end
    listOfAxes = [hAxRight, hAxLeft];
end

axHandle = subplot('Position',[0  0.005 1 0.06]); 
set(axHandle,'XLim',[0 1],'YLim',[0 1], 'XTickMode','manual','YTickMode','manual',...
     'XTick',[],'YTick',[],'XTickLabelMode','manual','XTickLabel',[],...
     'XLimMode','manual','YLimMode','manual','ZLimMode','manual','YTickLabelMode','manual',...
     'YTickLabel',[],'ButtonDownFcn',@locMouseButtonDownFcnSearchBar);

hSearchBar = patch([0 0 0 0],[0 0 1 1],'r', 'Parent', axHandle, 'EdgeColor','k','tag','-2','ButtonDownFcn',@locMouseButtonDownFcnSearchBar);

hText = title(axHandle,['frame '  num2str(macroDat.fileReadPointer-1) '/' num2str(macroDat.nofFrames) '  target FPS: ' num2str(macroDat.targetFramerate)]);

set(listOfAxes , 'ButtonDownFcn',@locMouseButtonDownFcnIm,...
    'XTickMode','manual','YTickMode','manual',...
     'XTick',[],'YTick',[],'XTickLabelMode','manual','XTickLabel',[],...
     'XLimMode','manual','YLimMode','manual','ZLimMode','manual','YTickLabelMode','manual',...
     'YTickLabel',[]);

tic;
adaptiveDelay = (1/(macroDat.targetFramerate*1.05));
curTime = 0;
prevTime = -adaptiveDelay;
curTargetFrameRate = macroDat.targetFramerate;
fr = 1;
while ishandle(hFig) && ~bKillAll
	set(hText,'String',['frame '  num2str(fr) '/' num2str(macroDat.nofFrames) '  target FPS: ' num2str(curTargetFrameRate)]);
    if bSeeking % seeking mode is initialized when seekbar is dragged, or arrow keys used
        if prevFr == reqFr %if requested frame same as previous, do nothing
            pause(1/30); % pausing (or drawnow)important for event callbacks to execute
            continue;
        end
       [im, u, v, macroDat] = getSavedData(reqFr); 
    else % if not seeking mode, then regular play-back
        if macroDat.bEOF %if we reach the end of recording ...
            [im, u, v, macroDat] = getSavedData(1); %... then start over...
        else
            [im, u, v, macroDat] = getSavedData(); %otherwise continue to the next frame
        end
    end

    %     update graphics:
    set(hIm,  'CData' ,im);
    if ~isempty(u)
        set(hFlow,'CData' ,flow2colIm(u,v));
    end        
    fr = macroDat.fileReadPointer-1;

    seekProgress = fr/macroDat.nofFrames;
    set(hSearchBar, 'XData',[0 seekProgress seekProgress 0]);
    
    prevFr = fr;

    %timing:
    if bSeeking
        pause(1/30);
    else %regular playback
        er = 1/curTargetFrameRate - (curTime - prevTime);
        er = sign(er)*(sqrt(min(abs(er),0.6)));
        adaptiveDelay = max(min(adaptiveDelay + (adaptiveDelay/50+0.001)*er,1),0);
%         delaylist(mod(fr-2,1000)+1) =adaptiveDelay ;
        %pause to maintain target frame-rate.
        if adaptiveDelay < 1/55
            drawnow
        else
            pause(adaptiveDelay); 
        end
        prevTime = curTime;
        curTime  = toc; 
    end
    
    while bPause && ~bKillAll
        pause(0.3);
        set(hText,'String',['frame '  num2str(fr) '/' num2str(macroDat.nofFrames) '  target FPS: ' num2str(curTargetFrameRate)]);
    end 
end

if ishandle(hFig)
    delete(hFig);
end
clear getSavedData;
% disp(' ');
% save('delaylist','delaylist');

% local helper to convert flow components to color coding:
function colIm = flow2colIm(u,v)
H  = (atan2(v,u)+ pi+0.000001)/(2*pi+0.00001);   
V = min(0.99999999,sqrt(u.^2 + v.^2)*8/10);
colIm = hsv2rgb(H,  ones(size(H),'single'),V);
end

function locKeypress(~,evnt)
    switch evnt.Key,
      case 'q'
          curTargetFrameRate = min(curTargetFrameRate + 1,60);
          adaptiveDelay = 1/(curTargetFrameRate*1.05);       
      case'a'
          curTargetFrameRate = max(1,curTargetFrameRate -1);
          adaptiveDelay = 1/(curTargetFrameRate*1.05);       
      case {'p','space'}
          if bSeeking
              bSeeking = 0;
              bPause = 0;
          else
              bPause = ~bPause;
          end
          if bPause == 0
              tic;
              curTime = 0;
              prevTime = -adaptiveDelay;
          end
      case 'rightarrow'
          reqFr = min(fr +1,macroDat.nofFrames);
          bSeeking = 1;
          bPause = 0;            
      case 'leftarrow'
          reqFr = max(fr -1,1);
          bSeeking = 1;
          bPause = 0;
%       otherwise
%           disp(['currently no binding for ' evnt.Key]);
    end
end

function locMouseButtonDownFcnIm(src,~)
    if strcmp(get(gcf,'Selectiontype'),'alt')
        mousePos = get(src,'CurrentPoint');
        pt   = mousePos(1,[2,1]);
        if ~isempty(u)
        if src == hAxRight
            set(hCrossR,'visible','on','Xdata',pt(2),'Ydata',pt(1));
            pt = ceil(pt.*(sizLeft)./(sizRight) -0.5);
            set(hCrossL,'visible','on','Xdata',pt(2),'Ydata',pt(1));
        else
            set(hCrossL,'visible','on','Xdata',pt(2),'Ydata',pt(1));
            pt = ceil(pt.*sizRight./sizLeft -0.5);
            set(hCrossR,'visible','on','Xdata',pt(2),'Ydata',pt(1));
        end
    else
        pt   = mousePos(1,[2,1]);
            set(hCrossL,'visible','on','Xdata',pt(2),'Ydata',pt(1));
        end        
    end
    draggingMode = 1; %indicates panning 
    mousePos = get(gcf,'CurrentPoint');
    ptPrev   = mousePos(1,[2,1]);
    oldLimL = [get(hAxLeft,'XLim')  get(hAxLeft,'YLim')];
    if ~isempty(u)
        oldLimR = [get(hAxRight,'XLim') get(hAxRight,'YLim')];
    end
    set(hFig, 'WindowButtonMotionFcn', @locDraggingFcn);

end

function locDraggingFcn(~,~)
    if draggingMode == 0 %if searchbar dragging...
        bPause = 0;
        pt = get(gca,'CurrentPoint');
        reqFr = ceil(macroDat.nofFrames*pt(1,1));
        reqFr = min(max(reqFr,1),macroDat.nofFrames);
        bSeeking = 1;
    else %if image dragging
        % if we are all zoomed out or if right mouse button down, do nothing
        if activeZoom == 1 || strcmp(get(gcf,'Selectiontype'),'alt')
            return        
        end                % if not zoomed out, then do panning
        pt = get(gcf,'CurrentPoint');
        ptCur = pt(1,[2,1]);
        mot = ptCur - ptPrev;
        
        %left:
        set(hAxLeft,'Units','pixels');
        axPos = get(hAxLeft,'Position');
        axSize = axPos(3:4);
        set(hAxLeft,'Units','Normalized');
       
        motL = zoomLevels(activeZoom).*mot*max(sizLeft./axSize);
        
        newXlim = oldLimL(1:2) - motL(2);
        newXlim = newXlim - min(newXlim(1),0);
        newXlim = newXlim + min(sizLeft(2)-newXlim(2),0);
        newYlim = oldLimL(3:4) + motL(1);
        newYlim = newYlim - min(newYlim(1),0);
        newYlim = newYlim + min(sizLeft(1)-newYlim(2),0);
        set(hAxLeft,'Xlim',newXlim+0.5,'Ylim',newYlim+0.5);

        if ~isempty(u)
            %right:
            set(hAxRight,'Units','pixels');
            axPos = get(hAxRight,'Position');
            axSize = axPos(3:4);
            set(hAxRight,'Units','Normalized');

            motL = zoomLevels(activeZoom)*mot*max(sizRight./axSize);

            newXlim = oldLimR(1:2) - motL(2);
            newXlim = newXlim - min(newXlim(1),0);
            newXlim = newXlim + min(sizRight(2)-newXlim(2),0);
            newYlim = oldLimR(3:4) + motL(1);
            newYlim = newYlim - min(newYlim(1),0);
            newYlim = newYlim + min(sizRight(1)-newYlim(2),0);
            set(hAxRight,'Xlim',newXlim+0.5,'Ylim',newYlim+0.5);
        end
    end
end

function locMouseButtonDownFcnSearchBar(~,~)

    bPause = 0;
    pt = get(gca,'CurrentPoint');
    reqFr = ceil(macroDat.nofFrames*pt(1,1));
    reqFr = min(max(reqFr,1),macroDat.nofFrames);
    bSeeking = 1;
    draggingMode = 0; %indicates search bar drag
    set(hFig, 'WindowButtonMotionFcn', @locDraggingFcn);
end

function myMouseButtonUpFcn(~,~)
    set(hFig, 'WindowButtonMotionFcn', '');
    draggingMode = -1;
end

function locClosefcn(~,~)
    if bKillAll
        clear getSavedData;
        delete(gcf);
    else
        bKillAll = 1;
    end
end

function locMouseScroll(~,evnt)

    if isempty(u)
        bInLeft = 1;
    else
        set(gcf,'Units','Normalized');
        pt = get(gcf,'CurrentPoint');
        set(gcf,'Units','Pixels');
        pt = pt(1,[1,2]);
        DaxCL = norm(pt - [axPosL(1)+axPosL(3)/2,  axPosL(2)+axPosL(4)/2]);
        DaxCR = norm(pt - [axPosR(1)+axPosR(3)/2,  axPosR(2)+axPosR(4)/2]);
        if DaxCL < DaxCR
            bInLeft = 1;
        else
            bInLeft = 0;
        end
    end

    if bInLeft
        axH = hAxLeft;
        siz = sizLeft;
    else
        axH = hAxRight;
        siz = sizRight;
    end    
    %get mouse position
    mousePos  = get(axH,'CurrentPoint');
    mousePos  = mousePos(1,[2,1])./siz;
    %tuner for the zooming, especially affects near border zooming
    red = 1.01;  
    posN  = (mousePos-0.5)*red +0.5;
    
%     limit how far off the axis we consider scroll positions:
    if abs(posN(1))>1.1
        posN(1) = 1.1*sign(posN(1));
    end
    if abs(posN(2))>1.1
        posN(2) = 1.1*sign(posN(2));
    end
    
%     Get the relative position to the zoom factor
    %get the new zoom level from vertical scroll count:
	scrlCnt = -evnt.VerticalScrollCount;
    activeZoom = max(min(activeZoom + scrlCnt, nofLevels),1);
    newFactor = zoomLevels(activeZoom);
    
    %set the axis limits (ie. zooming)
    posL = posN.*sizLeft+0.5;
    posLc= (posN-0.5).*sizLeft;
    
    axis(hAxLeft,  ([-sizLeft(2)/2 sizLeft(2)/2  -sizLeft(1)/2 sizLeft(1)/2 ] -...
                    [posLc(2) posLc(2) posLc(1) posLc(1)])*newFactor +...
                    [posL(2) posL(2) posL(1) posL(1)]);
    if ~isempty(u)
        posR = posN.*sizRight+0.5;
        posRc= (posN-0.5).*sizRight;

        axis(hAxRight,  ([-sizRight(2)/2 sizRight(2)/2  -sizRight(1)/2 sizRight(1)/2 ] -...
                        [posRc(2) posRc(2) posRc(1) posRc(1)])*newFactor +...
                        [posR(2) posR(2) posR(1) posR(1)]);
    end
end

   

end

function [im, u, v,macroDatOut] = getSavedData(frameNr, session)
% reads one frame of saved optical flow data(or just regular video)
% im - the gray scale image of the video where the flow was calculated
% (u, v) - the optical flow, x and y component images
% macroDatOut - structure with macro data containing all the fields of the
% input argument to vidProcessing for when this data was generated.
% Additional fields:
% macroDatOut.path - path to where data is stored
% macroDatOut.fileReadPointer - the current frame that was read
% macroDatOut.bEOF - flags end of file for the stored data

persistent macroDat vidStream fileStream dataSourceType

%dataSourceType, 0: folder with flow-data,
%                1: video file, as in "input.avi"

if nargin >0
    if ~isnumeric(frameNr) || frameNr < 0
        error('only positive values for frameNr');
    end
    frameNr = round(frameNr);
end

if nargin >2 
    error('max 2 input arguments');
end

if nargin < 2 && isempty(vidStream)
    error('no saved session initialized');
end

if nargin == 2 %then we initialize
    %if session is a number...
    if isnumeric(session) && isscalar(session)
        %... then it indicates one of the savedOutputX folders
        session = ['savedOutput' num2str(session)];
    end
    if (~exist(session,'dir')) && (~exist(session,'file') ==2)
        error('directory or file missing');
    end
    
    %%% load regular video?
    if exist(session,'file') ==2
        dataSourceType = 1;
         vidStream  = VideoReader(session);  
%         im = read(vidStream,1);
%         pathToDisp = pathToSave;    
        macroDat.movieType = 'file';
        macroDat.nofFrames = vidStream.NumberOfFrames;
        macroDat.targetFramerate = vidStream.FrameRate;
        macroDat.fileReadPointer = 1;
        macroDat.bEOF = false;
        macroDat.bQuiver = false;
        macroDat.path =  session; %session is a file
    else %setting up for flow data in folder, OR there is a list png/jpeg files:
        if exist(fullfile(session,'flow.mat'),'file') || exist(fullfile(session,'flow.bin'),'file')
            dataSourceType = 0;
            load(fullfile(session,'flow.mat')); %loads "in"
            macroDat = in;

            if in.bColorFlowDisp
                macroDat.bQuiver = false;
                vidStream = VideoReader(fullfile(session,'flow.bin'));
            else
                macroDat.bQuiver = true;
                vidStream  = VideoReader(fullfile(session,'flow.avi'));  
                fileStream = fopen(fullfile(session,'flow.bin'),'r');
            end
            macroDat.nofFrames = vidStream.NumberOfFrames;
            tmp = what(session);
            macroDat.path = tmp.path;
            macroDat.fileReadPointer = frameNr;
            macroDat.bEOF = false;
            if frameNr == 0 %then initialize only, return no data
                    macroDat.fileReadPointer = 1;
                im = [];
                u  = [];
                v  = [];
                macroDatOut = macroDat;
                return
            end              
        else
            error('invalid directory!');
        end      
    end
end

%all inputs are ok and we are sure to have initialized, then:
if nargin == 0 
    frameNr = macroDat.fileReadPointer;
elseif nargin > 0
    if macroDat.bQuiver && frameNr ~= macroDat.fileReadPointer
        fseek(fileStream,(frameNr-1)*macroDat.flowRes(1)*macroDat.flowRes(2)*4*2, 'bof');
    end
    macroDat.fileReadPointer = frameNr;
end

if frameNr > macroDat.nofFrames
     macroDat.bEOF = true;
else
    macroDat.bEOF = false;
end

if  macroDat.bEOF
    im = -1;
    u = -1;
    v = -1;
    macroDatOut = macroDat;
    return;
end

if ~dataSourceType
imCoded = single(read(vidStream,frameNr));
if macroDat.bQuiver
    im  = imCoded; 
    u = fread(fileStream,[macroDat.flowRes(1),macroDat.flowRes(2)],'*single');
	v = fread(fileStream,[macroDat.flowRes(1),macroDat.flowRes(2)],'*single');
%     im = single(imTmp(:,:,1));
else % if full flow or only video
    if strcmpi(macroDat.method,'user') || strcmpi(macroDat.method,'synthetic') %if flow
        im  = imCoded(:,:,3); 
        u = (imCoded(:,:,1)*(macroDat.rm/127))-macroDat.rm;
        v = (imCoded(:,:,2)*(macroDat.rm/127))-macroDat.rm;
    else %only video
        im  = imCoded; 
        u = [];
        v = [];
    end
end
else
    im = read(vidStream,frameNr);
    u  = [];
    v  = [];
end

macroDat.fileReadPointer = macroDat.fileReadPointer +1;
if macroDat.fileReadPointer > macroDat.nofFrames
     macroDat.bEOF = true;
end
macroDatOut = macroDat;
end


