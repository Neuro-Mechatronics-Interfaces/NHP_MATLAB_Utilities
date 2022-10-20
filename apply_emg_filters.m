function [z, fs, filtering] = apply_emg_filters(x, filtering, fs, trigs, stops)
%APPLY_EMG_FILTERS Apply filtering to EMG signal in data struct x.
%
% Syntax:
%   [z, fs, filtering] = apply_emg_filters(x, filtering);
%   [z, fs, filtering] = apply_emg_filters(x, filtering, fs);
%   [z, fs, filtering] = apply_emg_filters(x, filtering, fs, trigs, stops);
%
% Inputs:
%   x - Data struct with field: `samples` and `sample_rate`, or data array. 
%           If the filtering.Type is "Array", then one of the input 
%           dimensions for data array must be exactly 64 (for the EMG grid)
%   filtering - Data struct with filtering parameters. See also:
%              get_default_filtering_pars() for what that should look
%              like.
%   fs - Sampling rate. If x is struct with field 'fs' then this is not
%              needed; however, if x is a vector or array, 
%              then this should be included (or else default fs = 4000 
%              is used).
%   trigs - Vector of stimulus onset samples. Needed only if you specify
%           `Apply_Stim_Blanking` as true.
%   stops - Vector of stimulus end samples. Needed only if you specify
%           `Apply_Stim_Blanking` as true.
%
% Output:
%   z - Filtered input data, depends on what parameters are specified.
%        check what dimmensions being returned are
%   fs - Sample rate (convenience)
%   filtering - The parameter struct, with any modifications that are
%               automated by this function.
%
% See also: Contents, plot_emg_averages, get_filtering_label_string,
%           get_default_filtering_pars

if isstruct(x) || isa(x, 'TMSiSAGA.Data')
    fs = x.sample_rate;
    if ismember(filtering.Type, ["Array", "RMS"])
        b = horzcat(x.channels{:});
        x = x.samples(contains({b.alternative_name}, 'UNI'), :)';
        %x = x.samples(1:64, :)';
    else
        c = horzcat(x.channels{:});
        x = x.samples(contains({c.alternative_name}, 'BIP'), :)';
    end
else
    if nargin < 3
        fs = 4000;
    end
    if filtering.Type == "Array"
        if size(x, 2)~=64
            x = x';
        end
        if size(x, 2)~=64
            error('Check dimensions of x (current size of <strong>[%d x %d]</strong> is invalid)', size(x, 1), size(x, 2));
        end
    else
        % Must have more time-samples than channels. If the orientation is
        % nChannels x nSamples, flip it so that it is corrected.
        if size(x, 2) > size(x, 1)
            x = x';
        end
    end
    if nargin < 3
        error('If x is not a struct, must include the sample rate as third argument (<strong>fs</strong>)!'); 
    end
end

if nargin < 3
    n_trigs = max(floor(size(x, 1) ./ fs) - 1, 3); 
end

filtering.Name = fixCase(filtering.Name);

% Get a mask indicating whether to plot a given channel.
%   (For differential, top and bottom rows are not plotted)
filtering.Add_To_Plots = true(64, 1);
if filtering.Apply_Stim_Blanking
    if filtering.Use_Stops_In_Stim_Blanking
        if nargin < 5
            error('You set Apply_Stim_Blanking to true, but did not supply `trigs` and `stops` inputs, which are required in that case.');
        end
        % Check that our stim onset and offset samples make sense:
        if numel(trigs) > numel(stops)
            trigs(1) = [];
            if numel(trigs) ~= numel(stops)
                if numel(stops) == (numel(trigs)+1)
                    stops(end) = [];
                else
                    error('Mismatch: %d trigs and %d stops.', numel(trigs), numel(stops));
                end
            end
        else
            stops(1) = [];
            if numel(trigs) ~= numel(stops)
                if numel(trigs) == (numel(stops)+1)
                    trigs(end) = [];
                else
                    error('Mismatch: %d trigs and %d stops.', numel(trigs), numel(stops));
                end
            end
        end
        if stops(1) < trigs(1)
            trigs(end) = [];
            stops(1) = [];
        end
    end
     
     % Set of samples to interpolate linearly between
     e_start = trigs + filtering.Stim_Blanking_Epoch(1);
     if filtering.Use_Stops_In_Stim_Blanking
        e_stop = stops + filtering.Stim_Blanking_Epoch(2);
     else
        e_stop = trigs + filtering.Stim_Blanking_Epoch(2);
     end
     
     % Linear interpolation between the two points
     nx = size(x,1);
     for ii = 1:numel(e_start)
         istop = min(e_stop(ii),nx);
         istart = max(e_start(ii),1);
         k = istop - istart;
         x(istart:istop, :) = interp1([0, k], x([istart; istop], :), 0:k, 'linear');
     end
end


% Detrend data.
if filtering.Apply_Polynomial_Detrend
    % Note that we have to flip the data here so that `detrend` operates
    % along the correct dimension. Since `filter` operates along columns as
    % well, we can maintain that orientation and then flip it back after.
    if isnan(filtering.Polynomial_Detrend_Order)
        filtering.Polynomial_Detrend_Order = max(n_trigs - 1, 3);
        if rem(filtering.Polynomial_Detrend_Order, 2)==0
            filtering.Polynomial_Detrend_Order = filtering.Polynomial_Detrend_Order - 1;
        end
    end
    data_in = detrend(x, filtering.Polynomial_Detrend_Order);
else
    % So that if we do HPF without detrend, data is still oriented
    % correctly:
    data_in = x;
end

% Apply rescaling
if filtering.Apply_Max_Rescale
    data_in = double(data_in);
    max_values = max(abs(data_in), [], 1);
    iValid = max_values > eps;
    data_in(:, iValid) = double(data_in(:, iValid)./max_values(iValid));
else
    data_in = double(data_in); 
end

% Apply HPF
if filtering.Apply_HPF
    if numel(filtering.HPF_Cutoff_Frequency) == 2
        [b, a] = butter(filtering.HPF_Order, filtering.HPF_Cutoff_Frequency / (fs / 2), 'bandpass');
    else
        [b, a] = butter(filtering.HPF_Order, filtering.HPF_Cutoff_Frequency / (fs / 2), 'high');
    end
    data_in = filter(b, a, data_in)'; % Flip back to nChannels x nSamples.
else
    data_in = data_in'; % Flip back to nChannels x nSamples. 
end

% Apply virtual common-average subtraction.
if filtering.Apply_Virtual_Reference
    % Only use common-average subtraction for array type
    if filtering.Type == "Array"
        data_in = data_in - mean(data_in, 1); 
    end
end

% Apply specific filtering:
switch filtering.Name
    case "Raw"
        % Remove DC offset.
        z = data_in;
        
    case "Rectified"               
        % Do rectification
        z = abs(data_in);
    case "Differential2rectified"               
        % Do rectification
        y = abs(data_in);
        
        G = grid.array_to_grid(y);
        G = diff(G, 2, 1); % Take double-differential along each column.
        G = cat(1, nan(1, 8, size(y, 2)), G, nan(1, 8, size(y, 2)));
        %G = cat(1, nan(1, 8, size(y1, 2)), G, nan(1, 8, size(y1, 2)));
        z = grid.grid_to_array(G);
        filtering.Add_To_Plots = grid.vec_to_grid(filtering.Add_To_Plots);
        filtering.Add_To_Plots(1, :) = false;
        filtering.Add_To_Plots(8, :) = false;
        filtering.Add_To_Plots = grid.grid_to_vec(filtering.Add_To_Plots);
    case "Differential2"
        G = grid.array_to_grid(data_in);
        G = diff(G, 2, 1); % Take double-differential along each column.
        G = cat(1, nan(1, 8, size(data_in, 2)), G, nan(1, 8, size(data_in, 2)));
        z = grid.grid_to_array(G);
        filtering.Add_To_Plots = grid.vec_to_grid(filtering.Add_To_Plots);
        filtering.Add_To_Plots(1, :) = false;
        filtering.Add_To_Plots(8, :) = false;
        filtering.Add_To_Plots = grid.grid_to_vec(filtering.Add_To_Plots);
    otherwise
        error("I have not set up this code to handle <strong>%s</strong> for `filtering.Name`", filtering.Name);
end

end