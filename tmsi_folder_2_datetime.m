function dt = tmsi_folder_2_datetime(SUBJ, YYYY, MM, DD, ARRAY, BLOCK, rootdir)
%TMSI_FOLDER_2_DATETIME  Convert TMSi folder timestring to datetime
%
% Syntax:
%   dt = utils.tmsi_folder_2_datetime(SUBJ, YYYY, MM, DD, ARRAY, BLOCK);
%
% Inputs:
%   SUBJ - String: should be name of subject (e.g. "Rupert" or "Frank")
%   YYYY - year (numeric scalar)
%   MM - month (numeric scalar)
%   DD - day (numeric scalar)
%   ARRAY - String: "A" or "B" or "*" for array identifier
%   BLOCK - Recording block index (numeric scalar)
%
% Output:
%   dt - Formatted datetime that is TMSi recorded start of session.
%
% See also: Contents

if nargin < 7
    rootdir = parameters('raw_data_folder'); 
end

if (numel(ARRAY) > 1) || (numel(BLOCK) > 1)
    dt = repmat(datetime('now'), numel(BLOCK), numel(ARRAY));
    dt.Format = 'yyyy-MM-dd HH:mm:ss.SSS';
    dt.TimeZone = 'America/New_York';
    for iB = 1:numel(BLOCK)
        for iA = 1:numel(ARRAY)
            dt(iB, iA) = utils.tmsi_folder_2_datetime(SUBJ, YYYY, MM, DD, ARRAY(iA), BLOCK(iB), rootdir);
        end
    end
    return;
end

f = utils.get_block_name(SUBJ, YYYY, MM, DD, ARRAY, BLOCK, 'rootdir_raw', rootdir);
f_expr = sprintf('%s*', strrep(f.Raw.Block, '\', '/'));
F = dir(f_expr);
if isempty(F)
    error("No folder found using expression: <strong>%s</strong>\n", f_expr);
end
f_info = strsplit(F(1).name, '-');
ts = strip(f_info{2});
dt = datetime(ts, ...
    'Format', 'yyyy-MM-dd HH:mm:ss.SSS', ...
    'TimeZone', 'America/New_York');

end