function onStop(~,~)
global g;
g.bQuittingRequested = g.bQuittingRequested+1;
if g.bPause
    g.bPause = 0;
    start(g.timer1);
end
if g.bQuittingRequested > 2
    delete(g.figH);
    warning('VidProcessing terminated improperly. Data was  not saved.')
    fclose all;
    imaqreset;
    clear functions;
end
if isvalid(g.timer1)
    pause(0.1);
    if isvalid(g.timer1)
    stop(g.timer1);
    end
end