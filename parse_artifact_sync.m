function [onset, offset, sync_data] = parse_artifact_sync(SUBJ, YYYY, MM, DD, ARRAY, BLOCK, data_vector, varargin)
%PARSE_ARTIFACT_SYNC  Outputs a vector of trigger events that match up with logic parsed from a threshold set under the assumption that the input is a vector with large stimulus-related artifacts in it.
%
% Syntax:
%   [onset, offset, sync_data] = parse_artifact_sync(SUBJ, YYYY, MM, DD, ARRAY, BLOCK); % Use the mean of array channels to parse artifacts.
%   [onset, offset, sync_data, data_vector] = parse_artifact_sync(SUBJ, YYYY, MM, DD, ARRAY, BLOCK, data_vector, 'Name', value, ...); % Use a specific data vector to parse artifacts.
%
% Inputs:
%   SUBJ  - Subject name (e.g. 'Frank' or "Frank")
%   YYYY  - Year (numeric or string, e.g. 2021 or "2021" or '2021')
%   MM    - Month (numeric or string, e.g. 11 or "11" or '11')
%   DD    - Day   (numeric or string, e.g. 18 or "18" or '18')
%   ARRAY - "A" or "B" (or 'A' or 'B') or ["A", "B"] or {'A', 'B'}
%   BLOCK - Recording parameter key (block; numeric or string, e.g. 0 or "0")
%   data_vector     - Data to get sync signal from
%   varargin        - Optional input parameter name,value pairs.
%
% Outputs:
%   onset - The sample indices of detected LOW-to-HIGH TTL sync transitions.
%   offset - The sample indices of detected HIGH-to-LOW TTL sync transitions.
%   sync_data - The logic data used to generate `onset` and `offset` vectors.
%   data_vector - If you didn't specify it for input then you can also
%                   return the actual data used as output (which can be
%                   helpful for example diagnosing why it's not working).
%
% See also: Contents, parse_bit_sync
if (numel(varargin) == 1) && isstruct(varargin{1})
    pars = varargin{1};
else
    pars = struct;
    pars.Invert_Logic = false;      % This switches "onset" and "offset" so that they match the TMSi syntax
    pars.N_Samples_Edge_Discard = 2000; % Number of samples at each "edge" of the recording to "discard" (set to zero) to avoid artifacts from recording start/stop.
    pars.N_Samples_Debounce_Triggers = 50; % Minimum number of samples between each trigger for it to "count".
    pars.Outlier_Threshold = 0.98; % Threshold for considering samples to be outliers.
    pars.Output_Folder = parameters('generated_data_folder'); % Root location where data will be saved.
    pars.Remove_Outliers = false;  % Set true to remove the samples that are outside of range set by Outlier_Threshold
    pars.Rectify_Data = true;      % Rectify data vector before zscore?
    pars.Save_Output = true;       % Save output sync signal?
    pars.Sync_Z_Threshold = 2.5;   % Threshold for converting to logic HIGH signal
    pars = utils.parse_parameters(pars, varargin{:});
    pars.Artifact_Sync_Rule = 'max_rms';
    pars.Zscore = false;
    pars.Halfmax = true;

    % Handle parsing of `pars`
    pars = utils.parse_parameters(pars, varargin{:});
end

if isstring(SUBJ)
    % If we did not specify a data vector
    if (nargin < 7) || isempty(data_vector)
        x = load_tmsi_raw(SUBJ, YYYY, MM, DD, ARRAY, BLOCK);
        data_vector = mean(x.samples(1:64, :), 1);
        clear x;
    end
elseif isstruct(SUBJ)
    x = SUBJ;
    pars.Artifact_Sync_Rule = YYYY;
    gen_data_folder = MM;
    pars.Inverted_Logic = DD;
    if isstruct(x)
        switch(pars.Artifact_Sync_Rule)
            case isnumeric(pars.Artifact_Sync_Rule) % Any channel number
                data_vector = x.samples(pars.Artifact_Sync_Rule, :);
            case 'Mean'
                data_vector = mean(x.samples(1:64, :), 1);
        end
    else
        data_vector = x;
    end
else
    beep;
    error('Unknown data type passed to "parse_artifact_sync"');
end


N = numel(data_vector);
data_vector([1:pars.N_Samples_Edge_Discard, (N - pars.N_Samples_Edge_Discard + 1) : N]) = median(data_vector);

if pars.Rectify_Data
    data_vector = data_vector - mean(data_vector, 2);
    data_vector = abs(data_vector);
end

if pars.Remove_Outliers
    [~, idx] = sort(data_vector, 'ascend');
    i_remove = floor(N * pars.Outlier_Threshold);
    vec_remove = idx(i_remove:N);
    data_vector(vec_remove) = ones(size(vec_remove)) * median(data_vector);
end

if pars.Zscore == true
    data_vector_zscore = zscore(data_vector);
    sync_data = data_vector_zscore >= pars.Sync_Z_Threshold;
elseif pars.Halfmax == true
    sync_data = data_vector > max(data_vector)/2;
end

if pars.Invert_Logic
    sync_data = ~sync_data;
end

onset = utils.apply_debounce(find([false, diff(sync_data) > 0]), pars.N_Samples_Debounce_Triggers);
offset = utils.apply_debounce(find([diff(sync_data) < 0, false]), pars.N_Samples_Debounce_Triggers);

if isstruct(SUBJ)
    out_path = gen_data_folder;
    save_output = true && (isa(x, 'TMSiSAGA.Data') || isa(x, 'struct'));
else
    out_path = varargin{3};
    save_output = true && (isa(x, 'TMSiSAGA.Data') || isa(x, 'struct'));
end

if save_output
    if (numel(offset) < 10) && (exist(fullfile(out_path, sprintf('%s_sync.mat', data.name)), 'file')~=0)
        warning('Only %d triggers parsed from bit sync signal for %s! Skipped saving empty vector.', numel(offset), data.name);
        return;
    else
        if exist(out_path, 'dir') == 0
            try
                mkdir(out_path);
            catch me
                warning(me.message);
            end
        end
        out_f = fullfile(out_path, sprintf('%s_sync.mat', x.name));
        save(out_f, 'onset', 'offset', 'sync_data', '-v7.3');
    end
end

%if ~pars.Save_Output
%     resp = questdlg({'Save result?'; ...
%         sprintf('(N = %d sync triggers parsed)', numel(onset))}, ...
%         'Save Triggers?', ...
%         'Yes', 'No', 'Cancel', 'Yes');
%     switch resp
%         case 'Yes'
%             fprintf(1, 'Saving...\n');
%         case 'No'
%             return;
%         case 'Cancel'
%             assignin('base', 'onset', onset);
%             assignin('base', 'offset', offset);
%             assignin('base', 'sync_data', sync_data);
%             throw(MException('Sync:parsingCanceled', 'User canceled sync parsing. See variables assigned in base workspace.'));
%     end
% end
%
% [YYYY, MM, DD] = parse_date_args(YYYY, MM, DD);
% name = sprintf('%s_%04d_%02d_%02d_%s_%d', SUBJ, YYYY, MM, DD, ARRAY, BLOCK);
% out_folder = fullfile(pars.Output_Folder, SUBJ, sprintf('%s_%04d_%02d_%02d', SUBJ, YYYY, MM, DD), num2str(BLOCK));
% if exist(out_folder, 'dir') == 0
%     try
%         mkdir(out_folder);
%     catch me
%         warning(me.message);
%     end
% end
%
% out_f = fullfile(out_folder, sprintf('%s_sync.mat', name));
% try
%     save(out_f, 'onset', 'offset', 'sync_data', '-v7.3');
% catch me
%     warning(me.message);
%     disp(me);
% end

end