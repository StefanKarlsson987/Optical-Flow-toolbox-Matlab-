%Authors: Stefan Karlsson and Josef Bigun, 2015
function [dx, dy, dt] = grad3Drec(imNew,imPrev,tInt,dx, dy,dt)
% global g;
gg = [0.2163,   0.5674,   0.2163];
% tInt(in interval [0,1]) indicates temporal integration

tInt=0.5;
f = imNew + imPrev;
dx = tInt*dx + (1-tInt)*conv2(f(:,[2:end end ]) - f(:,[1 1:(end-1)]),gg','same');
dy = tInt*dy + (1-tInt)*conv2(f([2:end end],: ) - f([1 1:(end-1)],:),gg ,'same');
dt = tInt*dt + (1-tInt)*2*conv2(gg,gg,imNew - imPrev,'same'); 
