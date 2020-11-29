% Copyright: Stefan  M. Karlsson, Josef Bigun 2014
function [U, V] = FlowLK(in, imNew, imPrev,U,V)
% function DoFlow inputs images, dx, dy, dt, corresponding to the
% 3D gradients of a video feed
flowRes = in.flowRes;

stdTensor = 1.8; 
gg  = single(gaussgen(stdTensor)); %% filter for tensor smoothing

U = zeros(flowRes,'single');
V = zeros(flowRes,'single');

[dx, dy, dt] = grad3D(imNew,imPrev);

%     MOMENT CALCULATIONS
% moment m200, calculated in 3 steps explicitly
% 1) make elementwise product
momentIm = dx.^2;
     
% 2) smooth with large seperable gaussian filter (spatial integration)
momentIm = conv2(gg,gg,momentIm,'same');

% 3) downsample to specified resolution (imresizeNN function is found in "helperFunctions"):     
m200 =  imresizeNN(momentIm ,flowRes);
      
% The remaining moments are calculated in EXACTLY the same way as above, condensed to one liners:
m020=imresizeNN(conv2(gg,gg, sum(dy.^2 ,3),'same'),flowRes);
m110=imresizeNN(conv2(gg,gg, sum(dx.*dy,3),'same'),flowRes);
m101=imresizeNN(conv2(gg,gg, sum(dx.*dt,3),'same'),flowRes);
m011=imresizeNN(conv2(gg,gg, sum(dy.*dt,3),'same'),flowRes);

%TODO: fill in the missing moments(should not be zero):
% m002 = zeros(flowRes,'single');
% m110 = zeros(flowRes,'single');
% m101 = zeros(flowRes,'single');
% m011 = zeros(flowRes,'single');
 
 % Threshold:
EPSILONLK = 0.4;  

for x=1:size(m011,1)
for y=1:size(m011,2)
    %%%TODO: build the 2D structure tensor, call it S2D!
    %%% (here you can assume that m20 = m200, m02 = m020)
    %%% you have access to the elements as m200(x,y), m020(x,y) and m110(x,y)
    %%% (it should NOT be the identity matrix, enter the correct)
    S2D  = [m200(x,y), m110(x,y);...
            m110(x,y), m020(x,y)];
%         S2D  = [1, 0;...
%                 0, 1];
    if(rcond(S2D)>EPSILONLK) %"L1"
        %%%%%TODO form the vector 'DTd')
        %%%%% (it should NOT be the zero vector)
        b = [m101(x,y);...
             m011(x,y)];
%             b = [0;...
%                  0];
        %%%% TODO finally, calculate the velocity vector by the relation 
        %%%% between vector b, and matrix S2D (2D structure tensor)
        %%%% (it should NOT be the zero vector)
         v = -S2D\b;
%             v = -pinv(S2D,1.5)*b; %this also works, but never do this
%             v = [0;...
%                  0];
        U(x,y) = v(1);
        V(x,y) = v(2);
    end
end
end
