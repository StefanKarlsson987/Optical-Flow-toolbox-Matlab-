function onFrameUpdate(varargin)
global g;
in = g.in;
myHandles = g.myHandles;
g.t=g.t+1;
t = g.t;

% strcmpi(get(myHandles.figH,'BeingDeleted'),'on')

%first check if we should quit or pause:
if      g.bQuittingRequested || ...
        t > in.endingTime ||...
        ~ishandle(myHandles.figH) || ...
        strcmpi(get(myHandles.figH,'BeingDeleted'),'on')         
    if ishandle(myHandles.figH), 
        close(myHandles.figH); 
    end
    if t > in.endingTime
        fprintf(['endingTime=' num2str(in.endingTime) ' is reached. ']);
    end
    pause(0.05);
    return;
elseif g.bPause
    stop(g.timer1);
end

%% Timer updating
% if different lag was requested, we have to handle it here:
period =  round(1000*g.lagTime + 1000/g.in.targetFramerate)/1000;
if period ~= get(g.timer1,'Period')
    stop(g.timer1);
    set(g.timer1,'Period',period, 'StartDelay', period);
    start(g.timer1);
end
    %define previous image:
	g.imPrev = g.imNew;    
    %get new image:
    if strcmpi(in.method,'syntheticfull') ||strcmpi(in.method,'synthetic')
        %for the special case of method = synthetic, then we retrieve both
        %images and flow output during synthesis:
        [g.imNew,g.U,g.V] = generateFrame(g.vid, t,g.kindOfMovie,g.spdFactor,g.arrowKey);
        updateGraphicsScript(in,myHandles,g.imNew,g.U,g.V);
    elseif in.bDisplayGT
        [g.imNew,g.U_GT,g.V_GT,in.supIm] = generateFrame(g.vid, t,g.kindOfMovie,g.spdFactor,g.arrowKey);
    else
        g.imNew= generateFrame(g.vid, t,g.kindOfMovie,g.spdFactor,g.arrowKey);
    end
    
    %perform analysis and update graphics:
    switch in.method
        case 'gradient'
            [dx, dy, dt] = grad3D(g.imNew,g.imPrev);
            updateGraphicsScript(in,myHandles,g.imNew,dx,dy,dt);
        case 'edge'
            g.edgeIm = DoEdgeStrength(g.in, g.imNew, g.imPrev,g.gamma,g.edgeIm);
            updateGraphicsScript(in,myHandles,g.imNew,g.edgeIm);
        case 'nothing'
            updateGraphicsScript(in,myHandles,g.imNew); 
        case 'user'
            [g.U, g.V] = in.userDefMethod(in,g.imNew,g.imPrev,g.U, g.V);
            updateGraphicsScript(in,myHandles,g.imNew,g.U,g.V,g.U_GT,g.V_GT);
    end
drawnow %expose
% pause(0.01);
end
