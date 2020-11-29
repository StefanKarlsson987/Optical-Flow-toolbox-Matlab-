%Authors: Stefan Karlsson and Josef Bigun, 2015
function [dx, dy, dt] = grad3D(imNew,imPrev)
%calculates the 3D gradient from two images.
% filters predefined:
dg =  [1     0    -1];
gg = [0.2163,   0.5674,   0.2163]; %normalized to sum 1

% spatial derivatives, use conv2
 dx    = zeros(size(imNew)); %L1
 dy    = zeros(size(imNew)); %L2
 
 % temporal derivative can be implemented as a difference of frames. 
 dt    = zeros(size(imNew)); %L3
