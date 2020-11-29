% Copyright: Stefan  M. Karlsson, Josef Bigun 2014
function [U, V] = Flow1(in, imNew, imPrev,U,V)
persistent m200 m020 m110 m101 m011 gg dx dy dt;
flowRes = in.flowRes;

if isempty(gg) || nargin <4
    stdTensor = 1.8; 
    gg  = single(gaussgen(stdTensor)); %% filter for tensor smoothing
    m200 = zeros(flowRes,'single');
    m020 = zeros(flowRes,'single');
    m110 = zeros(flowRes,'single');
    m101 = zeros(flowRes,'single');
    m011 = zeros(flowRes,'single');
    dx = zeros(size(imNew),'single');
    dy = zeros(size(imNew),'single');
    dt = zeros(size(imNew),'single');
end
%temporal integration constant:
tInt = in.tIntegration;

[dx, dy, dt] = grad3Drec(imNew,imPrev,sqrt(tInt),dx, dy, dt);

%Tikhinov Constant:
TC = single(5^2); 

m = 550;
gam = 0.2;
nor = (dx.^2+dy.^2 +dt.^2  + m*(6*gam)^2+eps)/m;                


%     MOMENT CALCULATIONS
%     moment m200, calculated in 5 steps explicitly
%     1) make gamma-corrected elementwise product
      momentIm = (dx.^2)./nor;
     
%     2) smooth with large seperable gaussian filter (spatial integration)
      momentIm = conv2(gg,gg,momentIm,'same');

%     3) downsample to specified resolution (imresizeNN function is found in "helperFunctions"):     
      momentIm =  imresizeNN(momentIm ,flowRes);

%     4) ...  add Tikhonov constant if a diagonal element (for m200, m020):
      momentIm =  momentIm + TC;
      
%    5) update the moment output (recursive filtering, temporal integration)
     m200 = tInt*m200 + (1-tInt)*momentIm;

%  L1:  The remaining moments are calculated as one liners (replace with correct):
 m020 = zeros(flowRes,'single')+TC;
 m110 = zeros(flowRes,'single');
 m101 = zeros(flowRes,'single');
 m011 = zeros(flowRes,'single');
 
 %  L2: Implement the vectorized formulation of the solver:
U =(-m101.*m020 + m011.*m110)./(m020.*m200 - m110.^2);%-2*TC^2/3);
V =( m101.*m110 - m011.*m200)./(m020.*m200 - m110.^2);%-2*TC^2/3);

