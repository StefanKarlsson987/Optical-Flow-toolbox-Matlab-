function MouseButtonDownFcnIm(~,~)

    mousePos = get(gcf,'CurrentPoint');
    ptPrev   = mousePos(1,[2,1]);
    oldLimL = [get(gca,'XLim')  get(gca,'YLim')];
    set(hFig, 'WindowButtonMotionFcn', {@DraggingFcn,ptPrev,oldLimL});