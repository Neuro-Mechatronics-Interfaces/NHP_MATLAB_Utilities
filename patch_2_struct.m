function s = patch_2_struct(p)
%PATCH_2_STRUCT  Convenience function to convert patch handle to struct
%
% Syntax:
%   s = utils.patch_2_struct(p);
%
% Inputs:
%   p - Any MATLAB patch graphic handle or array of such handles.
%   
% Output:
%   s - "Patch-like" struct with relevant data from `p` so that `s` can be
%           used as a smaller non-handle object to pass data to functions
%           like `export_specific_pattern` (which then calls `plot_SBA`)
%
% See also: Contents, plot_SBA, export_specific_pattern, example_SBA

if numel(p) > 1
    s = struct('Faces', cell(numel(p), 1), ...
           'Vertices', cell(numel(p), 1), ...
           'FaceVertexCData', cell(numel(p), 1), ...
           'UserData',cell(numel(p), 1));
    for ii = 1:numel(p)
        s(ii) = utils.patch_2_struct(p(ii));
    end
    return;
end

s = struct('Faces', p.Faces, ...
           'Vertices', p.Vertices, ...
           'FaceVertexCData', p.FaceVertexCData, ...
           'UserData', p.UserData);

end