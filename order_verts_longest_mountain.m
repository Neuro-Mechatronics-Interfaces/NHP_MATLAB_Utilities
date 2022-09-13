function [ind,n] = order_verts_longest_mountain(U, ind)
%ORDER_VERTS_LONGEST_MOUNTAIN  Order vertices to achieve longest "mountain" sequence of points.
%
% THIS DOES NOT WORK SORRY
%
% Syntax:
%   V = utils.order_verts_longest_mountain(U);
%
% Inputs:
%   U - Unordered vertices; columns should be [X, Y] or [X, Y, Z] for patch
%           vertex data points.
%
% Output:
%   ind - Ordering such that U(ind) = V, the best-mountain-sorted.
%
% See also: Contents, utils.longest_mountain

N = size(U,1);

if nargin < 2
    [ind,n] = utils.order_verts_longest_mountain(U - min(U,[],1), []);
    return;
else
    D = vecnorm(U, 2, 2);
    vec = (1:size(U,1))';
    if size(ind,1) == N
        [n, ~] = utils.longest_mountain(U(vec,:));
        return;
    end
end

if isempty(ind)
    [~, idx] = utils.longest_mountain(U);
else
    vec(ind(:,2)) = vec(ind(:,1));
    [~, idx] = utils.longest_mountain(U(vec,:));
end

switch idx
    case 1
        k = [N, 2];
    case N
        k = [N-1, 1];
    otherwise
        k = [idx-1, idx+1];
end
A = abs(D(idx)-D(k(1)));
B = abs(D(k(2))-D(idx));
tmp = D;
tmp(ind) = inf;
if A >= B
    tmp([k(1),idx]) = inf;
    [~,iBestCur] = min(abs(tmp-D(idx)));
    tmp(iBestCur) = inf;
    [~,iBestOther] = min(abs(tmp-D(k(1))));

else
    tmp([k(2),cur.idx]) = inf;
    [~,iBestCur] = min(abs(tmp-D(idx)));
    tmp(iBestCur) = inf;
    [~,iBestOther] = min(abs(tmp-D(k(2))));
end
ind_new = [ind; [vec(iBestCur),vec(iBestOther); vec(iBestOther), vec(iBestCur)]];
% fprintf(1,'<strong>ind_new</strong>:\n');
% disp(ind_new);
% fprintf(1,'vec:\n');
% disp(vec);
fprintf(1,'iBestCur: %d\t\tiBestOther: %d\n',iBestCur,iBestOther);

[ind,n] = utils.order_verts_longest_mountain(U,ind_new);


end