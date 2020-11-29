% Copyright: Stefan  M. Karlsson, Josef Bigun 2014
function macroDat = flowPlayBack(pathToSave)
% Function to play-back a sequence of recorded optical flow. This functions
% main purpose is to illustrate how to use the "getSavedFlow" function.

lagTime = 0;
bPause  = 0;

%% recorded flow will be in loaded matrices "u" and "v"
% load the first frame, sets up "getSavedFlow" for consecutive calls
[im, u, v, macroDat] = getSavedFlow(1, pathToSave);
% macroDat
%figure for the plotting
hFig = figure('Name',['Save Files in ' macroDat.path],'WindowKeyPressFcn',@localKeypress);

%original input video for the flow displayed to the left:
subplot(1,2,1);
hIm = imagesc(im,[0 255]);colormap gray; axis image; axis off;
title(['Source of video input: ' macroDat.movieType]);

%loaded flow shown to the right, in color coding:
subplot(1,2,2); 
hFlow = imagesc(flow2colIm(u,v)); axis image; axis off;

if strcmpi(macroDat.method, 'user')
    methodText = func2str(macroDat.userDefMethod);
else
    methodText = macroDat.method;
end

hText = title(['Method: ' methodText]);


while ishandle(hFig)
    tic; %we time each loop iteration to maintain frame-rate
    set(hIm,  'CData' ,im);
    set(hFlow,'CData' ,flow2colIm(u,v));
    T = macroDat.nofFrames       + macroDat.startingTime -1;
    t = macroDat.fileReadPointer + macroDat.startingTime -1;
    
    set(hText,'String',['Method: ' methodText ', frame = ' num2str(t) '/' num2str(T)]);
    
    if macroDat.bEOF %if we reach the end of recording ...
        [im, u, v, macroDat] = getSavedFlow(1); %... then start over...
    else
        [im, u, v, macroDat] = getSavedFlow(); %otherwise continue to the next frame
    end
    % we pause just long enough to achieve the target frame rate:
    timeToSpare = (1/macroDat.targetFramerate) + lagTime - toc; 
    pause(  max(timeToSpare  , 0.01)  ); 
    while bPause
        pause(0.3);
    end 
end

% clear the persistent variables in getSavedFlow (ugly solution? yes, feel free to improve)
clear getSavedFlow;

% local helper to conver flow components to color coding:
function colIm = flow2colIm(u,v)
H  = (atan2(v,u)+ pi+0.000001)/(2*pi+0.00001);   
V = min(0.99999999,sqrt(u.^2 + v.^2)*8/10);
colIm = hsv2rgb(H,  ones(size(H),'single'),V);
end

function localKeypress(~,evnt)
    switch evnt.Key,
      case 'q'
          lagTime = lagTime + 0.02;
      case'a'
          lagTime = max(0,lagTime - 0.02);
      case 'p'
          bPause = ~bPause;
    end
  
end
end