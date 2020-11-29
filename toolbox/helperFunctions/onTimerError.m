function onTimerError(~,~)
global g;
if ~g.bQuittingRequested
    return;
end

disp('Error during timer execution. Something wasnt turned off the way it was supposed. ');