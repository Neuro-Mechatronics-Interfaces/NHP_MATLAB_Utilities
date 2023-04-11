function [xg, yg, grid_index, xi, yi] = parse_xy_grid_vec(xv, yv, dx, dy, xe, ye)
%PARSE_XY_GRID_VEC  Parses xy grid to encapsulate values in x and values in y
%
% Use half-minimum absolute difference between sorted unique values from a
% vector of x-values (and repeat for vector of y-values) to generate "edge"
% vectors, which are used to form a grid for discretizing pairs of <xv, yv>
% coordinate locations into a corresponding grid location.
%
% The "edge" vector dx and dy can be manually-specified by providing the dx
% and dy arguments. Otherwise dx or dy can be left as nan and they are then
% computed.
%
% The first and last edges use the minimum and maximum value of xv or yv,
% minus or plus dx or dy respectively, unless `xe` and `ye` are
% specified manually (by default they are [nan nan]). If the values are
% manually specified, then the edge vector is computed so that it always
% includes the first element, but will only contain the second element if
% the difference between the two elements is divisible by the corresponding
% dx or dy value.
%
% Syntax:
%   [xg, yg, grid_index] = utils.parse_xy_grid_vec(xv, yv)
%   [__, xi, yi] = utils.parse_xy_grid_vec(xv, yv, dx, dy, xe, ye)
%
% Inputs:
%   xv - X-values (nSamples x 1 vector)
%   yv - Y-values (nSamples x 1 vector)
%   dx - (Default is nan) the edge-vector-spacing for x-grid.
%   dy - (Default is nan) the edge-vector spacing for y-grid.
%   xe - (Default is [nan nan]) the x-edge min and max values. 
%   ye - (Default is [nan nan]) the y-edge min and max values.
%
% Output:
%   xg - Grid edges used for discretizing values in xv.
%   yg - Grid edges used for discretizing values in yv.
%   grid_index - The index into meshgrid formed by xg and yg, for each pair
%                   of <xv,yv> coordinate values.
%   xi - X-grid indices
%   yi - Y-grid indices
% 
% See also: Contents, utils, discretize, meshgrid
arguments
    xv (:,1) double
    yv (:,1) double
    dx (1,1) double = nan
    dy (1,1) double = nan
    xe (1,2) double = [nan nan]
    ye (1,2) double = [nan nan]
end

xg = compute_grid(xv, dx, xe);
yg = compute_grid(yv, dy, ye);

xi = discretize(xv, xg);
yi = discretize(yv, yg);

grid_index = sub2ind([numel(yg)-1, numel(xg)-1], yi, xi);

    function g = compute_grid(v, d, e)
        %COMPUTE_GRID  Sub-function to apply to xg and yg calculation
        if isnan(d)
            d = 0.5 * min(abs(diff(unique(v))));
        end
        if isnan(e(1))
            e(1) = min(v) - d;
        end
        if isnan(e(2))
            e(2) = max(v) + d;
        end
        g = e(1):d:e(2);
    end

end