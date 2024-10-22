function onPath = isOnPath(Folder)
%ISONPATH Checks if folder is on current MATLAB path. Returns true if yes.
%
% Syntax:
%   onPath = utils.isOnPath(Folder);
%
% Inputs:
%   Folder - Folder to check
%   
% Output:
%   onPath (1,1) logical - true if on path, false otherwise.
%
% See also: Contents
arguments
    Folder {mustBeTextScalar}
end

s       = pathsep;
pathStr = [s, path, s];
onPath  = contains(pathStr, [s, strrep(Folder,'/',filesep), s], 'IgnoreCase', ispc);

end

