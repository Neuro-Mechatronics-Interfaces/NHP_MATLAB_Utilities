function s = sba_patch_2_struct(p)
%SBA_PATCH_2_STRUCT  Convenience function to convert patch handle to struct
%
% Syntax:
%   s = sba_patch_2_struct(p);
%
% Inputs:
%   p - Patch returned by `plot_SBA`
%   
% Output:
%   s - "Patch-like" struct with relevant data from `p` so that `s` can be
%           used as a smaller non-handle object to pass data to functions
%           like `export_specific_pattern` (which then calls `plot_SBA`)
%
% See also: Contents, plot_SBA, export_specific_pattern, example_SBA

s = struct('Faces', p.Faces, ...
           'Vertices', p.Vertices, ...
           'FaceVertexCData', p.FaceVertexCData, ...
           'UserData', p.UserData);

end