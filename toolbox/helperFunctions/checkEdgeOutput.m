% Authors: Stefan M. Karlsson, Josef Bigun 2014
%%
% checks for sanity in the DoEdgeStrength output
function bOK = checkEdgeOutput(edgeIm)
      bOK = 1;
      if (ndims(edgeIm) ~=2 ||  length(edgeIm) < 3 || ~isreal(edgeIm))
          msgbox('function "DoEdgeStrength" returned invalid image. edgeIm should be 2D, real valued (did you use a dx^2 instead of dx.^2?)');
          bOK = 0;
      end      
      if ~bOK
          error('Bad Flow output');end

