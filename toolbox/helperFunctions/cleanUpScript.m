% Clears up memory
% persistent variables in functions:

function cleanUpScript(~,~)
global g;
if ~g.bQuittingRequested
    return;
end
delete(g.figH);
g.bQuittingRequested = 1;
in = g.in;
vid = g.vid;

if strcmpi(g.kindOfMovie,'file')
    delete(vid);   
elseif strcmpi(g.kindOfMovie,'camera')
  if vid.bUseCam ==2
      vi_stop_device(vid.camIn, vid.camID-1);
      vi_delete(vid.camIn);
  else
      pause(0.2)
      stop(vid.camIn);
      delete(vid.camIn); 
  end
end 

if in.bRecordFlow
   if g.bColorFlowDisp
	close(g.writeVidFlow);
    %rename the file to "flow.bin", so the user wont think it is an avi that is readily playable.
    movefile(fullfile(g.writeVidFlow.Path, g.writeVidFlow.Filename), fullfile(g.writeVidFlow.Path, 'flow.bin'))
   else
    close(g.writeVidFlow);
    movefile(fullfile(g.writeVidFlow.Path, g.writeVidFlow.Filename), fullfile(g.writeVidFlow.Path, 'flow.avi'))
  try
	close(g.writeVidFlow);
    fclose(g.writeFlow);
  catch
  end
   end
if in.bDisplayGT
  try
    fclose(g.writeFlowGT );
  catch
  end
end
    fidText = fopen(fullfile(g.writeVidFlow.Path,'HOW_TO_ACCESS_THIS_DATA.txt'),'wt');
    fprintf(fidText,[ ... 
        'This folder(originally called ''' g.pathToSave '''), was created to save data\n'...
        'generated with Stefan Karlsson''s and Josef Bigun''s OPTICAL FLOW TOOLBOX. \n \n' ...
        'The toolbox is in Matlab, is free for non-commercial use, and can be downloaded here: \n' ...
        'http://www.mathworks.com/matlabcentral/fileexchange/44400-tutorial-and-toolbox-on-real-time-optical-flow\n\n'...
        'To view the data: in main folder of the toolbox(in Matlab), type "flowPlayBack(nameOfDir)", where nameOfDir\n'... 
        'is the name of the directory you have found these files. If they are in the original location, then type:\n\n'...
        'flowPlayBack(''' g.pathToSave ''');\n\n' ...
        'To access data: the first frame of the saved data:\n\n' ...
        '[im, u, v, macroDat] = getSavedFlow(1, nameOfDir);\n\n'...
        'where "im" is the grayscale image, "u" and "v" are the component images of the flow, and "macroDat" contains a description of the data\n\n'...
        'The n-th frame is thereafter accessed as:\n\n'...
        '[im, u, v] = getSavedFlow(n);\n\n'...
        'you can also quickly access succesive frames without giving frame number:\n\n'...
        '[im, u, v] = getSavedFlow();\n\n\n'...
        '   EXAMPLE 1: display the saved video\n\n'...
        '[im, u, v, macroDat] = getSavedFlow(1, ''' g.pathToSave ''');\n'...
        'hIm = imagesc(im,[0 255]);\n'...
        'colormap gray; axis image; axis off;\n' ...
        'for fr = 2:macroDat.nofFrames \n'...
        '  [im, u, v] = getSavedFlow();\n'...
        '  set(hIm,  ''CData'' ,im);\n'...
        '  pause(1/15);\n'...
        'end\n'...
        'clear getSavedFlow;\n\n\n'...
        '   EXAMPLE 2:  Open the code for function "flowPlayBack.m", it is in the folder "HelperFunctions"'
]);
    fclose(fidText);
end
clear functions;

if (~strcmp(g.pathToSave,'') && g.bAutoPlayWithPlayer)
  disp(['Starting "FancyFlowPlayer" for saved data folder: "' g.pathToSave '"']);
  % MATLAB BUG? I want to just execute the line:
  % flowPlayBack2(pathToSave);
  % however, calling that from here will lock execution until the figure
  % opened from flowPlayBack2 is closed. For some reason, this prevents the
  % mouse and keyboard callbacks for flowPlayBack2 from working (?!?!?).
  % However, only some times... on other times, the callbacks work as they
  % should.
  % a solution that works on my system (it seems) is to create a new timer
  % that has as sole purpose to just exectute the line:
  % flowPlayBack2(pathToSave);
  % and give this new timer a brief starting delay:
  start(timer('StartDelay',1, ...
              'TimerFcn',  @(~,~) FancyFlowPlayer(g.pathToSave), ... 
              'StopFcn' ,  @(obj,~) delete(obj))); 
end
delete(g.timer1);
end
