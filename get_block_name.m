function [f, args]  = get_block_name(SUBJ, YYYY, MM, DD, ARRAY, BLOCK, varargin)
%GET_BLOCK_NAME  Return the string info corresponding to a given block
%
% Syntax:
%   f = utils.get_block_name(SUBJ, YYYY, MM, DD, ARRAY, BLOCK);
%   [f, args] = utils.get_block_name(__, 'Name', value, ...);
%
% Inputs:
%   SUBJ  - Subject name (e.g. 'Frank' or "Frank")
%   YYYY  - Year (numeric or string, e.g. 2021 or "2021" or '2021')
%   MM    - Month (numeric or string, e.g. 11 or "11" or '11')
%   DD    - Day   (numeric or string, e.g. 18 or "18" or '18')
%   ARRAY - "A" or "B" (or 'A' or 'B') or ["A", "B"] or {'A', 'B'}
%   BLOCK - Recording parameter key (block; numeric or string, e.g. 0 or "0")
%   varargin - (Optional) -- 'Name', value pairs
%
% Output:
%   f     - Filename struct with fields for 'Tank', 'Block' etc.
%   args  - Cell format of input args (SUBJ - BLOCK) to make it convenient
%           to pass them to other functions.
%
% See also: Contents, utils, utils.get_subj_query

if (numel(varargin)==1) && isstruct(varargin{1})
    pars = varargin{1};
else
    pars = struct;
    [pars.rootdir_raw, pars.rootdir_gen, ...
        pars.raw_matfiles_folder, pars.meta_file_expr, pars.events_file_expr, ...
        pars.alignment_parent_folder, pars.alignment_folder] = ...
        utils.parameters('raw_data_folder', 'generated_data_folder', ...
            'raw_matfiles_folder', 'meta_file_expr', 'events_file_expr', ...
            'alignment_parent_folder', 'alignment_folder');
    pars = utils.parse_parameters(pars, varargin{:});
end
if (numel(BLOCK) > 1) || (numel(ARRAY) > 1)
    nB = numel(BLOCK);
    nA = numel(ARRAY);
    f = struct('Date', cell(nB, nA), ...
               'DateValue', cell(nB, nA), ...
               'Animal', cell(nB, nA), ...
               'Tank', cell(nB, nA), ...
               'Block', cell(nB, nA), ...
               'Raw', cell(nB, nA), ...
               'Generated', cell(nB, nA));
    args = cell(nB, nA);
    for iB = 1:nB
        for iA = 1:nA
             if nargout > 1
                 [f(iB, iA), args{iB, iA}] = utils.get_block_name(SUBJ, YYYY, MM, DD, ARRAY(iA), BLOCK(iB), pars); 
             else
                 f(iB, iA) = utils.get_block_name(SUBJ, YYYY, MM, DD, ARRAY(iA), BLOCK(iB), pars); 
             end
        end
    end
    return;
end

[YYYY, MM, DD] = utils.parse_date_args(YYYY, MM, DD);

tank = string(sprintf('%s_%04d_%02d_%02d', SUBJ, YYYY, MM, DD));
block = string(sprintf('%s_%s_%d', tank, ARRAY, BLOCK));

f = struct;
f.Date = string(sprintf('%04d_%02d_%02d', YYYY, MM, DD));
f.DateValue = datetime(YYYY, MM, DD);
f.Animal = SUBJ;
f.Tank = tank;
f.Block = block;
f.Raw.Subj = fullfile(pars.rootdir_raw, SUBJ);
f.Raw.Tank = fullfile(pars.rootdir_raw, SUBJ, tank);
f.Raw.Block = fullfile(pars.rootdir_raw, SUBJ, tank, block);
f.Generated.Subj = fullfile(pars.rootdir_gen, SUBJ);
f.Generated.Tank = fullfile(pars.rootdir_gen, SUBJ, tank);
f.Generated.Block = fullfile(pars.rootdir_gen, SUBJ, tank, num2str(BLOCK));
f.Generated.Channels = fullfile(f.Generated.Block, pars.raw_matfiles_folder);
f.Generated.Config = fullfile(f.Generated.Block, "config.json");
f.Generated.Aligned = struct;
F = fieldnames(pars.alignment_folder);
for iF = 1:numel(F)
    f.Generated.Aligned.(F{iF}) = fullfile(f.Generated.Block, pars.alignment_parent_folder, pars.alignment_folder.(F{iF})); 
end
f.Generated.Events = fullfile(f.Generated.Block, sprintf(pars.events_file_expr, f.Block));
f.Generated.Meta = fullfile(f.Generated.Block, sprintf(pars.meta_file_expr, f.Block));

if nargout > 1
    args = {SUBJ, YYYY, MM, DD, ARRAY, BLOCK}; 
end
end