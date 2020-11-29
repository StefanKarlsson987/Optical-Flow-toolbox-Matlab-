% Copyright: Stefan  M. Karlsson, Josef Bigun 2014
function updateGraphicsScript(in,myHandles,curIm,varargin)
% Update the graphics, depending on the "method" used
global g;
%only update if user has NOT killed figure:
if ~ishandle(myHandles.figH) || strcmpi(get(myHandles.figH,'BeingDeleted'),'on')
    return;
end
switch lower(in.method)
    case 'nothing'
        set(myHandles.hImObj ,'cdata',curIm);    
    case 'edge'
        set(myHandles.hImObj ,'cdata',curIm);
        edgeIm = varargin{1};
        set(myHandles.hImObjEdge ,'cdata',edgeIm);
%         set the threshold g.edgeUpper, for histogram normalization
%         let it adapt to the signal:
        maxVal = max(edgeIm(:));
        maxVal = min(maxVal,0.7*max(edgeIm(:)) + std(edgeIm(:)));        
        alpha = 0.55*exp(-((g.edgeUpper - maxVal)^2)/1000)+0.4;
        g.edgeUpper = alpha*g.edgeUpper + (1-alpha)*maxVal;
        set(myHandles.hEdgeAxesObj,'CLim',[0 g.edgeUpper]);
    case 'gradient'
        dx=varargin{1};dy=varargin{2};dt=varargin{3};
        set(myHandles.hImObjDx,'cdata',dx);
        set(myHandles.hImObjDy,'cdata',dy);
        set(myHandles.hImObjDt,'cdata',dt);
        set(myHandles.hImObj  ,'cdata',curIm);
    otherwise %flow methods:
        U = varargin{1};V = varargin{2};
        if g.bColorFlowDisp %then do color coding of flow, full resolution
            an  = (atan2(V,U)+ pi+0.000001)/(2*pi+0.00001);
            mag = min(0.99999999,sqrt(U.^2 + V.^2)*in.sc/10);
            set(myHandles.hImObj ,'cdata', hsv2rgb(an,  mag,   max(mag,curIm/256)));
            if in.bDisplayGT            
                U_GT   = varargin{3};V_GT = varargin{4};
                an_GT  = (atan2(V_GT,U_GT)+ pi+0.000001)/(2*pi+0.00001);
                mag_GT = min(0.99999999,sqrt(U_GT.^2 + V_GT.^2)*in.sc/10);
%                 save
                set(myHandles.hImObjGT ,'cdata', hsv2rgb(an_GT,mag_GT,max(mag_GT,curIm/256)));
            end
%             if in.bRecordFlow
%                 U = (U+in.rm)*(127/in.rm);
%                 V = (V+in.rm)*(127/in.rm);
%                 writeVideo(g.writeVidFlow,...
%                    reshape(uint8([U, V, curIm]),...
%                    [size(an,1) size(an,2) 3]));
%                 if in.bDisplayGT
%                     fwrite(g.writeFlowGT,U,'single');
%                     fwrite(g.writeFlowGT,V,'single');               
%                 end            
%             end
        else % if ~g.bColorFlowDisp
            set(myHandles.hImObj ,'cdata',curIm);
            set(myHandles.hQvObjPoints,'UData', in.sc*U, 'VData', in.sc*V);
            if in.bDisplayGT            
                U_GT   = varargin{3};V_GT = varargin{4};
                set(myHandles.hQvObjLines,'UData', in.sc*U_GT, 'VData', in.sc*V_GT);
            end

%             if in.bRecordFlow
%                  writeVideo(g.writeVidFlow,uint8(curIm));
%                  fwrite(g.writeFlow,U,'single');
%                  fwrite(g.writeFlow,V,'single');
%                 if in.bDisplayGT
%                     fwrite(g.writeFlowGT,U,'single');
%                     fwrite(g.writeFlowGT,V,'single');               
%                 end            
%             end
        end
end

if in.bRecordFlow
    if g.bColorFlowDisp
        if strcmpi(in.method,'user') || strcmpi(in.method,'synthetic')
            U = (U+in.rm)*(127/in.rm);
            V = (V+in.rm)*(127/in.rm);
            writeVideo(g.writeVidFlow,...
               reshape(uint8([U, V, curIm]),...
               [size(an,1) size(an,2) 3]));
            if in.bDisplayGT
                fwrite(g.writeFlowGT,U_GT,'single');
                fwrite(g.writeFlowGT,V_GT,'single');               
            end
        else %saving non-flow method (only video)
            writeVideo(g.writeVidFlow,uint8(curIm));
        end
    else %if ~g.bColorFlowDisp
        writeVideo(g.writeVidFlow,uint8(curIm));
        fwrite(g.writeFlow,U,'single');
        fwrite(g.writeFlow,V,'single');
        if in.bDisplayGT
            fwrite(g.writeFlowGT,U_GT,'single');
            fwrite(g.writeFlowGT,V_GT,'single');               
        end      
    end
end


     if g.bUpdateText
        if g.bPause
            PausString = 'PAUSED(HIT "P")   ';
        else
            PausString = '';
        end
         
         if strcmpi(g.kindOfMovie, 'synthetic')
             set(g.figH, 'Name',[PausString '[q,a]Lag:' num2str(g.lagTime,'%1.2f') ',  [w,s]Speed:' num2str(g.spdFactor(1),'%2.1f')  ',  [e,d]Rotation:' num2str(g.spdFactor(2),'%2.1f') ',  [r,f]Gamma:'  num2str(g.gamma,'%2.2f') ]);
         else 
             set(g.figH, 'Name',[PausString '[q,a]Lag:' num2str(g.lagTime,'%1.2f') ',  [r,f]Gamma:'  num2str(g.gamma,'%2.2f') ]);
         end
     end


%  if g.bUpdateText
% %     g.bUpdateText = 0;
% g.figTopText = num2str(randi(10000));
%      set(g.figH, 'Name',g.figTopText );
%  end

