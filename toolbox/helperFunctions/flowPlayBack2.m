% Copyright: Stefan  M. Karlsson, Josef Bigun 2014
function macroDat = flowPlayBack2(pathToSave)
% Function to play-back a sequence of recorded optical flow. This function
% produces a small video player
%
% MOUSE INTERFACE
% * scroll-wheel: zooms relative to mouse cursor position in video
% * click and drag video windows(if zoomed): pans video around. 
% * click and drag searchbar: sets video progression
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
% OUT: structure containing description of data

lagTime = 0;
bPause  = 0;
bSeeking= 0;
bKillAll= 0;
reqFr   = 1;
draggingMode = -1;
ptPrev = [0 0];
oldLimL = [0 1 0 1];
oldLimR = [0 1 0 1];

%% recorded flow will be in loaded matrices "u" and "v"
% load the first frame, sets up "getSavedFlow" for consecutive calls
[im, u, v, macroDat] = getSavedFlow(1, pathToSave);
sizLeft  = size(im);
sizRight = size(u);

nofLevels = floor(log(max(max(sizLeft),max(sizRight)))*1.7);
% zoomLevels = linspace(1,(0.2)^(1/50), nofLevels ).^50;
zoomLevels = 0.8.^linspace(0,nofLevels-1,nofLevels);
activeZoom = 1; 

hFig = figure('WindowKeyPressFcn',@locKeypress,...
              'CloseRequestFcn', @locClosefcn,...
              'WindowButtonUpFcn',@myMouseButtonUpFcn,...
              'WindowScrollWheelFcn',@locMouseScroll,...
              'NumberTitle','off','Name',['Playing: ' macroDat.path]);
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
        title(['Method: ' macroDat.method]);
    end
    listOfAxes = [hAxRight, hAxLeft];
end

axHandle = subplot('Position',[0  0.005 1 0.06]); 
set(axHandle,'XLim',[0 1],'YLim',[0 1], 'XTickMode','manual','YTickMode','manual',...
     'XTick',[],'YTick',[],'XTickLabelMode','manual','XTickLabel',[],...
     'XLimMode','manual','YLimMode','manual','ZLimMode','manual','YTickLabelMode','manual',...
     'YTickLabel',[],'ButtonDownFcn',@locMouseButtonDownFcnSearchBar);
     
hSearchBar = patch([0 0 0 0],[0 0 1 1],'r', 'Parent', axHandle, 'EdgeColor','k','tag','-2','ButtonDownFcn',@locMouseButtonDownFcnSearchBar);

hText = title(['frame '  num2str(macroDat.fileReadPointer-1) '/' num2str(macroDat.nofFrames)]);

set(listOfAxes , 'ButtonDownFcn',@locMouseButtonDownFcnIm,...
    'XTickMode','manual','YTickMode','manual',...
     'XTick',[],'YTick',[],'XTickLabelMode','manual','XTickLabel',[],...
     'XLimMode','manual','YLimMode','manual','ZLimMode','manual','YTickLabelMode','manual',...
     'YTickLabel',[]);

while ishandle(hFig) && ~bKillAll
    tic; %we time each loop iteration to maintain frame-rate
    
    if bSeeking % seeking mode is initialized when seekbar is dragged, or arrow keys used
        targetFrameInterval = 1/25;
        if prevFr == reqFr %if requested frame same as previous, do nothing
            pause(targetFrameInterval); % pausing (or drawnow)important for
%             drawnow                   % event callbacks to execute
            continue;
        end
        [im, u, v, macroDat] = getSavedFlow(reqFr); 
    else % if not seeking mode, then regular play-back
        targetFrameInterval = (1/macroDat.targetFramerate) + lagTime; 
        if macroDat.bEOF %if we reach the end of recording ...
            [im, u, v, macroDat] = getSavedFlow(1); %... then start over...
        else
            [im, u, v, macroDat] = getSavedFlow(); %otherwise continue to the next frame
        end
    end
    
    set(hIm,  'CData' ,im);
    if ~isempty(u)
        set(hFlow,'CData' ,flow2colIm(u,v));
    end        

    fr = macroDat.fileReadPointer-1;
    
%     update graphics:
    set(hText,'String',['frame '  num2str(fr) '/' num2str(macroDat.nofFrames)]);
    seekProgress = fr/macroDat.nofFrames;
    set(hSearchBar, 'XData',[0 seekProgress seekProgress 0]);
    
    %pause to maintain target frame-rate:
    pause(  max(targetFrameInterval - toc, 0.01)  ); 
    while bPause && ~bKillAll
        pause(0.3);
    end 
    prevFr = fr;
end

if ishandle(hFig)
    delete(hFig);
end
clear getSavedFlow;

% local helper to convert flow components to color coding:
function colIm = flow2colIm(u,v)
H  = (atan2(v,u)+ pi+0.000001)/(2*pi+0.00001);   
V = min(0.99999999,sqrt(u.^2 + v.^2)*8/10);
colIm = hsv2rgb(H,  ones(size(H),'single'),V);
end

function locKeypress(~,evnt)
    switch evnt.Key,
      case 'q'
          lagTime = lagTime + 0.02;
      case'a'
          lagTime = max(0,lagTime - 0.02);
      case {'p','space'}
          if bSeeking
              bSeeking = 0;
              bPause = 0;
          else
              bPause = ~bPause;
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
        if ~isempty(u)
        mousePos = get(src,'CurrentPoint');
        pt   = mousePos(1,[2,1]);
        if src == hAxRight
            set(hCrossR,'visible','on','Xdata',pt(2),'Ydata',pt(1));
            pt = ceil(pt.*(sizLeft)./(sizRight));
            set(hCrossL,'visible','on','Xdata',pt(2),'Ydata',pt(1));
        else
            set(hCrossL,'visible','on','Xdata',pt(2),'Ydata',pt(1));
            pt = ceil(pt.*(sizRight)./(sizLeft));
            set(hCrossR,'visible','on','Xdata',pt(2),'Ydata',pt(1));
        end
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
        if activeZoom == 1 % if we are all zoomed out do nothing
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

function locMouseButtonDownFcnSearchBar(src,~)

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

function locClosefcn(src,evnt)
    if bKillAll
        clear getSavedFlow;
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