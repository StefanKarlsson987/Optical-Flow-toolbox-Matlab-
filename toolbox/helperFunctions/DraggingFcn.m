function DraggingFcn(~,~,ptPrev,oldLimL)
    pt = get(gcf,'CurrentPoint');
    ptCur = pt(1,[2,1]);
    mot = ptCur - ptPrev;
        
    set(gca,'Units','pixels');
    axPos = get(gca,'Position');
    axSize = axPos(3:4);
    set(gca,'Units','Normalized');

    motL = zoomLevels(activeZoom).*mot*max(sizLeft./axSize);

    newXlim = oldLimL(1:2) - motL(2);
    newXlim = newXlim - min(newXlim(1),0);
    newXlim = newXlim + min(sizLeft(2)-newXlim(2),0);
    newYlim = oldLimL(3:4) + motL(1);
    newYlim = newYlim - min(newYlim(1),0);
    newYlim = newYlim + min(sizLeft(1)-newYlim(2),0);
    set(gca,'Xlim',newXlim+0.5,'Ylim',newYlim+0.5);

  