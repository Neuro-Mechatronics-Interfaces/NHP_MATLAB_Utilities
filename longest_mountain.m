function [n, idx] = longest_mountain(A)
%LONGEST_MOUNTAIN Returns the longest "mountain" in the array. Columns of A are treated as variables e.g. P = [X, Y, Z] for 3D-points.
%
% Syntax:
%   [n, idx] = utils.longest_mountain(A);
%
% Inputs:
%   A - Array of points. A good way to pre-process is 
%       >> P = [X, Y, Z]; % Patch vertex XYZ data.
%       >> A = P - min(A,[],1); % Make it so everything is offset by
%                               % minimum value of each column.
%
% Output:
%   n - Number of elements in longest "mountain." A "mountain" is a stretch
%       that is monotonically increasing (or staying the same), then only
%       monotonically decreasing (or staying the same). 
%   idx - Index of where the "mountain" starts. If there are n elements, 
%           then the index where "mountain" ends is idx + n - 1.
%
% Note: This is basically used for ordering Vertices on the Faces property
%       of patch data.
%
% See also: Contents

N = size(A,1);
D = vecnorm(A,2,2);

n = 0;
idx = 1;  
while (idx < N)
    stop = idx;
    if (stop+1<N)&&(D(stop+1)>=D(stop))
        while (stop+1<N)&&(D(stop+1)>=D(stop))
            stop = stop+1; 
        end
        if (stop+1<N)&&(D(stop+1)<=D(stop))
            while (stop+1<N)&&(D(stop+1)<=D(stop))
                stop = stop+1;
                n = max(n, stop-idx+2);
            end
        end
    end
    if (stop+1<N)
        idx = max(idx+1, stop);
    else
        break;
    end
end

end