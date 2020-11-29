%Authors: Stefan Karlsson and Josef Bigun, 2015
function [dx, dy] = grad2D(f,dx, dy,tInt)
%calculates the 2D gradient from an image.
gg = [0.2163,   0.5674,   0.2163]; %normalized to sum 1

if nargin >1
    dx = tInt*dx + ...
    (1-tInt)*conv2(f(  :    ,[2:end end ]) - f(:,[1 1:(end-1)]),gg','same');

    dy = tInt*dy + ...
    (1-tInt)*conv2(f([2:end end],  :     ) - f([1 1:(end-1)],:),gg ,'same');
else
    dx = conv2(f(  :    ,[2:end end ]) - f(:,[1 1:(end-1)]),gg','same');
    dy = conv2(f([2:end end],  :     ) - f([1 1:(end-1)],:),gg ,'same');
end    
 
