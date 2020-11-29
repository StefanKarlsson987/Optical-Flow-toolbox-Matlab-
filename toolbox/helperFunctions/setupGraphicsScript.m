% Copyright: Stefan  M. Karlsson, Josef Bigun 2014
function [myHandles, pathToSave] = setupGraphicsScript(in,imNew, varargin)
global g;
pathToSave = in.pathToSave;
myHandles.figH = figure('NumberTitle','off');
g.bColorFlowDisp =1;
switch in.method
    case 'nothing'
      set(myHandles.figH, 'Name',in.method);
      myHandles.hImObj= imagesc( imNew,[0,250]);
      colormap gray;axis off;axis manual;axis image;
      hold on;
    case 'edge'
    %setup graphics based on edgeIm
      set(myHandles.figH, 'Name',in.method);
      subplot(1,2,1); myHandles.hImObjEdge = imagesc(varargin{1},[0 max(max(varargin{1}))*0.96  ]);
      set(myHandles.hImObjEdge,'CData',zeros(size(varargin{1})));
%       subplot(1,2,1); hImObjEdge = imagesc(edgeIm);
      axis off;axis image;colormap gray(256); title(gca,'Edge Image');
      myHandles.hEdgeAxesObj = gca;       
      subplot(1,2,2); myHandles.hImObj = imagesc( imNew,[0,255]); 
      axis off;axis image;colormap gray(256);title(gca,'original sequence');
    case 'gradient'
      % setup graphics based on dx, dy and dt
      dx = varargin{1};dy = varargin{2};dt = varargin{3}; 
      set(myHandles.figH,'Name','3D gradient');
      plotRange = max(max(sqrt(dx.^2+dy.^2)))+0.001;
    
      subplot(2,2,1); myHandles.hImObjDx = imagesc(dx,[-plotRange,plotRange]); 
      axis off;axis image;colormap gray(256);title(gca,'dx');

      subplot(2,2,2); myHandles.hImObjDy = imagesc(dy,[-plotRange,plotRange]); 
      axis off;axis image;colormap gray(256);title(gca,'dy');

      subplot(2,2,3); myHandles.hImObjDt = imagesc(dt,[-plotRange,plotRange]); 
      axis off;axis image;colormap gray(256);title(gca,'dt');

	  subplot(2,2,4); myHandles.hImObj = imagesc( imNew,[0,255]); 
      axis off;axis image;colormap gray(256);title(gca,'original sequence');       
    otherwise %flow methods
      set(myHandles.figH, 'Name', func2str(in.userDefMethod));
      U = varargin{1};
      if all(size(imNew) == size(U)) %then display as color coding
          g.bColorFlowDisp = 1;
          if in.bDisplayGT
              subplot(1,2,1);
          end
          myHandles.hImObj = image(zeros([size(imNew), 3]));
          axis off;axis image; title(gca, ... 
              [func2str(in.userDefMethod) ', color-coded flow image']);
          if in.bDisplayGT
              subplot(1,2,2);
              myHandles.hImObjGT = image(zeros([size(imNew), 3]));          
              axis off;axis image; title(gca, 'Ground Truth Flow');
          end
      else %if flow field not the size of image, display as vectors
          g.bColorFlowDisp = 0;
          myHandles.hImObj= imagesc( imNew,[0,250]);
          colormap gray;axis off;axis manual;axis image;
          hold on;

        oldSize = size(imNew);  
        newSize = size(U);
        scale = newSize./oldSize;    
        iY = min(round(((1:newSize(1))-0.5)./scale(1)+0.5),oldSize(1));
        iX = min(round(((1:newSize(2))-0.5)./scale(2)+0.5),oldSize(2));

          if in.bDisplayGT
              myHandles.hQvObjLines  = quiver(iX,iY, zeros(size(U)),  zeros(size(U)),0 ,'m','MaxHeadSize',5,'Color',[.9 .2 .1]);%, 'LineWidth', 1);
              title(gca,[func2str(in.userDefMethod) ', scaled by ' num2str(in.sc) ':1, blue: estimation, red: ground truth' ]);              
          else
              title(gca,[func2str(in.userDefMethod) ', scaled by ' num2str(in.sc) ':1' ]);              
          end
          myHandles.hQvObjPoints = quiver(iX,iY, zeros(size(U)),  zeros(size(U)),0 ,'m','MaxHeadSize',0.1,'Color',[0 1 .1]);%, 'LineWidth', 1);
          axis image;axis manual;

      end
end

      in.bColorFlowDisp = g.bColorFlowDisp;
if in.bRecordFlow
        if strcmp(in.pathToSave,'')
          saveNum =1;
          while exist(['savedOutput' num2str(saveNum)],'dir')
            saveNum = saveNum+1;
          end
          pathToSave = ['savedOutput' num2str(saveNum)];
        else
            pathToSave = in.pathToSave;
        end
        if ~exist(pathToSave,'dir'), mkdir(pathToSave);end 
        
        if g.bColorFlowDisp %then save as color video file (also true for non-flow methods, such as "gradient") 
%         if in.bRecordFlow == 1 %do lossless compression
         g.writeVidFlow = VideoWriter(fullfile(pathToSave, 'tmp.avi'),'Archival');
%         else %in.bRecordFlow > 1: do lossy compression
%             g.writeVidFlow = VideoWriter(fullfile(pathToSave, 'tmp.avi'),'Motion JPEG AVI');
%             if in.bRecordFlow == 2
%                 g.writeVidFlow.Quality = 100;
%             else
%                 g.writeVidFlow.Quality = 90;
%             end
%         end
        g.writeVidFlow.FrameRate = min(in.targetFramerate,30);
        open(g.writeVidFlow);
    	save(fullfile(pathToSave, 'flow.mat'),'in');

        else %if ~g.bColorFlowDisp %then save as avi plus a bin file
%             if in.bRecordFlow == 1 %do lossless compression
%                 g.writeVidFlow = VideoWriter(fullfile(pathToSave, 'flow.avi'),'Archival');
%                 disp('Archival')
%             else %in.bRecordFlow > 1: do lossy compression
%                  g.writeVidFlow = VideoWriter(fullfile(pathToSave, 'flow.avi'),'Motion JPEG AVI');
%                 if in.bRecordFlow == 2
%                     g.writeVidFlow.Quality = 100;
%                 else
%                     g.writeVidFlow.Quality = 90;
%                 end
%             end
            g.writeVidFlow = VideoWriter(fullfile(pathToSave, 'flow'),'Archival');
            g.writeVidFlow.FrameRate = min(in.targetFramerate,30);
            open(g.writeVidFlow);
            save(fullfile(pathToSave, 'flow.mat'),'in', 'iX','iY');
            g.writeFlow = fopen(fullfile(pathToSave, 'flow.bin'),'w');
        end
       if in.bDisplayGT
        g.writeFlowGT = fopen(fullfile(pathToSave, 'flowGT.bin'),'w');
       end        
end


g.figH = myHandles.figH;
%setup keyboard callback
set(myHandles.figH, 'WindowKeyPressFcn',@myKeypress,...
    'WindowKeyReleaseFcn', @myKeyrelease,'CloseRequestFcn',@onStop,...
    'Interruptible','off', 'busyAction','cancel',...
    'handlevisibility','off');
% g.figTopText = get(myHandles.figH,'Name');
% set(hImObj , 'ButtonDownFcn',@MouseButtonDownFcnIm);


if strcmpi(in.movieType, 'synthetic')
    set(myHandles.figH, 'Name',[get(myHandles.figH, 'Name') ' -- (shut down figure to stop), keys (q,a,w,s,e,d,p) for lag time and pattern speed --' ]);
else
    set(myHandles.figH, 'Name',[get(myHandles.figH, 'Name') ' -- shut down figure to stop']);
end
