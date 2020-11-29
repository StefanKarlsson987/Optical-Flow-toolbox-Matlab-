% Copyright: Stefan  M. Karlsson, Josef Bigun 2014
function [U, V] = Flow2Full(in, imNew, imPrev,U,V)
persistent m200 m020 m110 m101 m011;% dx dy dt;
global g;
%%initialization:
if isempty(m200) || nargin <4
    m200 = zeros(size(imNew),'single');
    m020 = zeros(size(imNew),'single');
    m110 = zeros(size(imNew),'single');
    m101 = zeros(size(imNew),'single');
    m011 = zeros(size(imNew),'single');
%     dx = zeros(size(imNew),'single'); 
%     dy = zeros(size(imNew),'single'); 
%     dt = zeros(size(imNew),'single'); 
end

[dx, dy, dt] = grad3D(imNew,imPrev);

% gam = 0.5;
% gradScaling = (dx.^2 + dy.^2).^((1-gam)/2);
% dx = dx.*gradScaling;
% dy = dy.*gradScaling;
% dt = dt.*(dt.^2).^((1-gam)/2);

%Tikhonov Constant:
TC = single((110-10*g.gamma)^g.gamma); 

%temporal integration constant:
tInt = in.tIntegration;
r = 2;

%generate moments 
m200= tInt*m200 + (1-tInt)*(convTri(dx.^2 ,r)+TC);
m020= tInt*m020 + (1-tInt)*(convTri(dy.^2 ,r)+TC);
m110= tInt*m110 + (1-tInt)* convTri(dx.*dy,r);
m101= tInt*m101 + (1-tInt)* convTri(dx.*dt,r);
m011= tInt*m011 + (1-tInt)* convTri(dy.*dt,r);

% m200= tInt*m200 + (1-tInt)*(conv2(gg,gg, dx.^2 ,'same')+TC);
% m020= tInt*m020 + (1-tInt)*(conv2(gg,gg, dy.^2 ,'same')+TC);
% m110= tInt*m110 + (1-tInt)* conv2(gg,gg, dx.*dy,'same');
% m101= tInt*m101 + (1-tInt)* conv2(gg,gg, dx.*dt,'same');
% m011= tInt*m011 + (1-tInt)* conv2(gg,gg, dy.*dt,'same');
 
%flow calculations:
U =(-m101.*m020 + m011.*m110)./(m020.*m200 - m110.^2);
V =( m101.*m110 - m011.*m200)./(m020.*m200 - m110.^2);
