function meta = pattern_name_to_metadata(name)
%PATTERN_NAME_TO_METADATA  Helper function to convert pattern files to metadata struct
%
% Example:
%   name = 'Run24_J_5_-13EMU_Biphasic-Anodal';
%   meta = utils.pattern_name_to_metadata(name);
%
%   This returns meta struct with:
%       -> meta.loc.x = 0; meta.loc.y = 0; meta.loc.units = 'mm';
%       -> meta.run = 24; meta.optimizer = "J_5";
%       -> meta.stim.amplitude = -13; meta.stim.units = "EMU";
%       -> meta.stim.shape = "Biphasic-Anodal";
%
% Inputs:
%   name - char array or string, the name of "Tag" folder to parse.
%   
% Output:
%   meta - Metadata struct about this pattern.
%
% See also: Contents

meta = struct('loc', struct('x', [], 'y', [], 'units', ''), ...
    'run', "RunX", ...
    'optimizer', "Jx", ...
    'stim', struct('amplitude', 0, 'units', "EMU", 'shape', 'Biphasic-Anodal'));
info = strsplit(name, '_');
meta.run = info{1};
meta.optimizer = strjoin(info(2:3), '_');
meta.stim.shape = info{end};
tmp = char(info{end-1});
meta.stim.amplitude = str2double(tmp(1:(end-3)));
switch info{2}
    case 'J'
        meta.loc.units = 'mm';
        switch numel(info)
            case 5
                meta.loc.x = 0.0;
                meta.loc.y = 0.0;
            case 6
                tmp = char(info{4});
                meta.loc.(tmp(1)) = str2double(strrep(tmp(2:end), 'mm', ''));
            case 7
                tmp = char(info{4});
                meta.loc.(tmp(1)) = str2double(strrep(tmp(2:end), 'mm', ''));
                tmp = char(info{5});
                meta.loc.(tmp(1)) = str2double(strrep(tmp(2:end), 'mm', ''));
            otherwise
                error("Unexpected number of name parts (%d) for <strong>'%s'</strong>", numel(info), name);

        end
    case 'Jsafety'
        meta.loc.units = 'μm';
        switch numel(info)
            case 5
                meta.loc.x = 0.0;
                meta.loc.y = 0.0;
            case 6
                tmp = char(info{4});
                meta.loc.(tmp(1)) = str2double(strrep(tmp(2:end), 'um', ''));
            case 7
                tmp = char(info{4});
                meta.loc.(tmp(1)) = str2double(strrep(tmp(2:end), 'um', ''));
                tmp = char(info{5});
                meta.loc.(tmp(1)) = str2double(strrep(tmp(2:end), 'um', ''));
            otherwise
                error("Unexpected number of name parts (%d) for <strong>'%s'</strong>", numel(info), name);

        end

    otherwise
        error("Unexpected optimizer: <strong>%s</strong>", info{2});
end
end