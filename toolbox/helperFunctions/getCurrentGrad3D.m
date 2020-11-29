function [dx, dy, dt] = getCurrentGrad3D()

% get the internal variables of "VidProcessing" in 'g'
global g
% get the derivatives using current and previous frames
[dx, dy, dt] = grad3D(g.imNew,g.imPrev);

subplot(1,2,1); imagesc(dt);title('dt');
colormap gray;axis image;

phi = pi/4; subplot(1,2,2); 
imagesc(-(cos(phi)*dx+(sin(phi)*dy))); title('-(cos(phi)*dx+(sin(phi)*dy))');
colormap gray;axis image;