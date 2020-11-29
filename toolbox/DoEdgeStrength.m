% Authors: Stefan Karlsson and Josef Bigun, copyright 2015
function edgeIm = DoEdgeStrength(in, imNew, imPrev, gam, edgeIm)
persistent dx dy
if isempty(dx)
    dx = zeros(size(imNew),'single');
    dy = zeros(size(imNew),'single');
end
%INPUTS:
%in - structure containing settings for session (see runMe.m for an example)
%imNew, imPrev - new and previous images of the video
%gam - normalization constant
%edgeIm - previously estimated Edge Strength, same size as imNew (zero matrix on first run)
%OUTPUTS:
% edgeIm - estimated edge strength at each position

%temporal integration constant, for using previous edgeIm:
tInt = in.tIntegration;

%calculate the gradient. Note that we will only need dx and dy (not dt)
% [dx, dy, ~] = grad3D(imNew,imPrev);
% m = 440;%

[dx, dy] = grad2D(imNew,dx, dy,tInt);
m = 220; %contains the maximum magnitude value attainable of the gradient

%% version 1, gradient magnitude:
% edgeIm = sqrt(dx.^2+dy.^2);

%% version 2, normalized magnitude:
% edgeIm = (dx.^2+dy.^2).^(gam/2+eps);
edgeIm = m*((dx.^2+dy.^2)./(dx.^2+dy.^2 + m*(gam)^2+eps));

%% version 3, recursive temporal integration:
edgeIm = tInt*edgeIm + (1-tInt)*m*((dx.^2+dy.^2)./(dx.^2+dy.^2 + m*(gam)^2+eps));

%% version 4, alternatives
% edgeIm =  tInt*edgeIm + (1-tInt)*m*(dx.^2+dy.^2)./(dx.^2+dy.^2 + m*gam^2+eps);
% tInt = 0.1;
% edgeIm =  tInt*edgeIm + (1-tInt)*m*((dx.^2+dy.^2)./(dx.^2+dy.^2 + m*(6*gam)^2+eps));

% % [Ex, Ey] = grad2D(edgeIm);
% edgeIm = (0.3+(1-edgeIm./m )).*(10*round(imNew/10));
% edgeIm = edgeIm.*(Ex.^2+Ey.^2+1).^(-0.1);
% edgeIm = (m-edgeIm +600).*imNew/(m+300);

