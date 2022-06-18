function [SUBJ, YYYY, MM, DD, ARRAY, BLOCK] = get_subj_query(f)
%GET_SUBJ_QUERY  Return the subject-info args for most "load" and "plot" queries, given the subject query struct.
%
% Syntax:
%   [SUBJ, YYYY, MM, DD, ARRAY, BLOCK] = utils.get_subj_query(f);
%
% Input:
%   f     - Filename struct with fields for 'Tank', 'Block' etc. From
%           utils.get_block_name
%
% Outputs:
%   SUBJ  - Subject name (string)
%   YYYY  - Year (numeric)
%   MM    - Month (numeric)
%   DD    - Day   (numeric)
%   ARRAY - SAGA array identifier (string; "A" or "B")
%   BLOCK - Recording parameter key (block; numeric)
%
% See also: Contents, utils, utils.get_block_name

SUBJ = string(f.Animal);
YYYY = year(f.DateValue);
MM = month(f.DateValue);
DD = day(f.DateValue);
b_info = strsplit(f.Block, "_");
BLOCK = str2double(b_info{6});
ARRAY = string(b_info{5});

end