function stim = get_tmsi_stim_data(SUBJ, YYYY, MM, DD, ARRAY, BLOCK, raw_data_folder)
%GET_TMSI_STIM_DATA  Return stim data specifically for TMSi blocks
%
% Syntax:
%   stim = utils.get_tmsi_stim_data(SUBJ, YYYY, MM, DD, ARRAY, BLOCK, raw_data_folder);
%
% Inputs:
%   SUBJ - Name of subject
%   YYYY - Year of recording
%   MM - Month of recording
%   DD - Date of recording
%   ARRAY - "A" | "B" (recording array)
%   BLOCK - Block index ("parameter key") for recording
%   raw_data_folder - (Optional) raw data folder 
%           -> Default: 'R:/NMLShare/raw_data/primate'
%
% Output:
%   stim - Struct containing stimulation info

if nargin < 7
    raw_data_folder = 'R:/NMLShare/raw_data/primate'; 
end

tank = sprintf('%s_%04d_%02d_%02d', SUBJ, YYYY, MM, DD); % data "tank"
block = sprintf('%s_%s_%d', tank, ARRAY, BLOCK); % experimental "block" (recording within tank)
out_block = fullfile(raw_data_folder, SUBJ, tank, sprintf('%s.Poly5', block));
[~, stim] = getMetadata(out_block);
end