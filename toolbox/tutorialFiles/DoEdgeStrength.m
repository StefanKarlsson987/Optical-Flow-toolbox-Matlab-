% Authors: Stefan Karlsson and Josef Bigun, copyright 2015
function edgeIm = DoEdgeStrength(in, imNew, imPrev, gam, edgeIm)

%calculate the gradient. Note that we will only need dx and dy (not dt)
[dx, dy, ~] = grad3D(imNew,imPrev);

% TODO: set edgeIm to be gradient magnitude:
edgeIm = zeros(size(imNew));    %this aint right...
