%resize an image using bi-linear interpolation.
%author: Stefan Karlsson
%
% functions "contributions" and "triangle" are taken from the function:
% imresize, part of the image processing toolbox.

function imOut = imresizeBL(imIn, newSize)
    kernel = @gauss;
    kernel_width = 20;

    oldSize = size(imIn);  
    scale   = newSize./oldSize(1:2);    

    % Determine which dimension to resize first.
    [~, order] = sort(scale);

    % Calculate interpolation weights and indices for each dimension.
    	%%%% beware that in-place computations dont work for mex calls!
    
    k = order(1);
    [weights, indices] = contributions(oldSize(k), ...
        newSize(k), scale(k), kernel, kernel_width, 1);
%     note! if you dont have imresizemex in your matlab path, then find
%     it in the image processing toolbox. Its in a private folder,
%     accessible from "imresize.m"
    imOut = imresizemex(imIn, weights', indices', k);
% save; error
    k = order(2);
    [weights, indices] = contributions(oldSize(k), ...
        newSize(k), scale(k), kernel, kernel_width, 1);
    imOut = imresizemex(imOut, weights', indices', k);
	
end

function [weights, indices] = contributions(in_length, out_length, ...
                                            scale, kernel, ...
                                            kernel_width, antialiasing)

if (scale < 1) && (antialiasing)
    % Use a modified kernel to simultaneously interpolate and
    % antialias.
    h = @(x) scale * kernel(scale * x);
    kernel_width = kernel_width / scale;
else
    % No antialiasing; use unmodified kernel.
    h = kernel;
end

% Output-space coordinates.
x = (1:out_length)';

% Input-space coordinates. Calculate the inverse mapping such that 0.5
% in output space maps to 0.5 in input space, and 0.5+scale in output
% space maps to 1.5 in input space.
u = x/scale + 0.5 * (1 - 1/scale);

% What is the left-most pixel that can be involved in the computation?
left = floor(u - kernel_width/2);

% What is the maximum number of pixels that can be involved in the
% computation?  Note: it's OK to use an extra pixel here; if the
% corresponding weights are all zero, it will be eliminated at the end
% of this function.
P = ceil(kernel_width) + 2;

% The indices of the input pixels involved in computing the k-th output
% pixel are in row k of the indices matrix.
indices = bsxfun(@plus, left, 0:P-1);

% The weights used to compute the k-th output pixel are in row k of the
% weights matrix.
weights = h(bsxfun(@minus, u, indices));

% Normalize the weights matrix so that each row sums to 1.
weights = bsxfun(@rdivide, weights, sum(weights, 2));

% Clamp out-of-range indices; has the effect of replicating end-points.
indices = min(max(1, indices), in_length);

% If a column in weights is all zero, get rid of it.
kill = find(~any(weights, 1));
if ~isempty(kill)
    weights(:,kill) = [];
    indices(:,kill) = [];
end
end

function f = triangle(x)
f = (x+1) .* ((-1 <= x) & (x < 0)) + (1-x) .* ((0 <= x) & (x <= 1));
end

function f = gauss(x)
f = exp(-(2.7/50)*x.^2);
end