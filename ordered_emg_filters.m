function [data_out, fs, filtering] = ordered_emg_filters(x, filtering, processes, fs, trigs, stops)
%ORDERED_EMG_FILTERS Apply filtering to EMG signal in data struct x according to a specific order of operations.
% This is a modified version of the apply_emg_filters() function in the
% +utils package.
%
% Accepted processes include: 'Virtual_Reference' | 'Bandpass' | 'Highpass' | 'Stim_Blanking' | 'Rectify' | 'Detrend'
%
% Syntax:
%     [z, fs, filtering] = ordered_emg_filters(x, filtering, processes);
%     [z, fs, filtering] = ordered_emg_filters(x, filtering, processes, fs);
%     [z, fs, filtering, trigs, stops] = ordered_emg_filters(x, filtering, processes, fs, trigs, stops);
%
% Inputs:
%     x         - (struct) A data struct with field: `samples` and `sample_rate`, or data array.
%                 If the filtering.Type is "Array", then one of the input
%                 dimensions for data array must be exactly 64 (for the EMG grid)
%     filtering - (struct) Data struct with filtering parameters. See also:
%                 get_default_filtering_pars() for what that should look like.
%     processes   - (cell) A cell array with each element containing a filtering step. Data will be
%                 processed in the order of the filtering steps read
%     fs        - Sampling rate. If x is struct with field 'fs' then this is not
%                 needed; however, if x is a vector or array,
%                 then this should be included (or else default fs = 4000
%                 is used).
%     trigs     - Vector of stimulus onset samples. Needed only if you specify
%                 `Apply_Stim_Blanking` as true.
%     stops     - Vector of stimulus end samples. Needed only if you specify
%                 `Apply_Stim_Blanking` as true.
%
% Output:
%     z         - (double array) Filtered input data, depends on what parameters are specified.
%                 check what dimmensions being returned are
%     fs        - (num) Sample rate (convenience)
%     filtering - (struct) The parameter struct, with any modifications that are
%                 automated by this function.
%
% See also: Contents, plot_emg_averages, get_filtering_label_string,
%           get_default_filtering_pars

if isstruct(x) || isa(x, 'TMSiSAGA.Data')
    fs = x.sample_rate;
    if ismember(filtering.Type, ["Array", "RMS"])
        b = horzcat(x.channels{:});
        data_in = x.samples(contains({b.alternative_name}, 'UNI'), :)';
    else
        c = horzcat(x.channels{:});
        data_in = x.samples(contains({c.alternative_name}, 'BIP'), :)';
    end
else
    if nargin < 4
        error('If x is not a struct, must include the sample rate as third argument (<strong>fs</strong>)!');
    end
    if filtering.Type == "Array"
        if size(x, 2)~=64
            data_in = x';
        end
        if size(x, 2)~=64
            error('Check dimensions of x (current size of <strong>[%d x %d]</strong> is invalid)', size(x, 1), size(x, 2));
        end
    else
        % Must have more time-samples than channels. If the orientation is
        % nChannels x nSamples, flip it so that it is corrected.
        if size(x, 2) > size(x, 1)
            data_in = x';
        end
    end
end
if nargin < 5
    n_trigs = max(floor(size(x, 1) ./ fs) - 1, 3);
end
if (ischar(processes) || isstring(processes))
    processes=cellstr(processes);
end
filtering.Name = utils.fixCase(filtering.Name);

data_out = data_in;

fprintf('Applying EMG filters in order:\n');
for p=1:length(processes)

    switch processes{p}

        case 'Virtual_Reference'
            fprintf("   - Applying Virtual Common Reference\n");
            % Only use common-average subtraction for array type
            if filtering.Type == "Array"
                data_out = data_out - mean(data_out, 1);
            end

        case 'Bandpass'
            fprintf("   - Applying Bandpass Filter\n");
            if numel(filtering.HPF_Cutoff_Frequency) == 2
                data_out = data_out';
                [b, a] = butter(filtering.HPF_Order, filtering.HPF_Cutoff_Frequency / (fs / 2), 'bandpass');
                data_out = filter(b, a, data_out)'; % Flip back to nChannels x nSamples.
            else
                error('Need 2 elements for calculating bandpass cutoff frequency');
            end

        case 'Highpass'
            fprintf("   - Applying Highpass Filter\n");
            data_out = data_out';
            [b, a] = butter(filtering.HPF_Order, filtering.HPF_Cutoff_Frequency / (fs / 2), 'high');
            data_out = filter(b, a, data_out)'; % Flip back to nChannels x nSamples.

        case 'Stim_Blanking_PCA'
            fprintf("   - Applying Stimulus Blanking (PCA method)\n");
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

            if (numel(trigs) >= 5)
                % Reconstruct centered mean without first two PCs.
                if filtering.Use_Stops_In_Stim_Blanking
                    if numel(stops) >= numel(trigs)
                        e_extend = round(median(trigs - stops(1:numel(trigs))));
                    else
                        e_extend = 0;
                    end
                else
                    e_extend = 0;
                end
                vec = ((filtering.Stim_Blanking_Epoch(1)+1):(filtering.Stim_Blanking_Epoch(2) + e_extend))';
                art_sample_indices = vec + reshape(trigs,1,numel(trigs));
                art_sample_indices(any((art_sample_indices < 0) | (art_sample_indices > size(x,1)),2),:) = [];
                % Use median subtraction and small filter to remove DC-bias:
                data_out = data_out - median(data_out, 1);
                [b,a] = butter(1,0.02,'high'); % ~40-Hz @ 4kHz fs (nyquist = 2kHz)
                data_out = filter(b,a,data_out')';
                for ii = 1:size(data_out,2)
                    tmp = data_out(:,ii);
                    art_data = tmp(art_sample_indices);
                    [coeff,score,~,~,explained,mu] = pca(art_data);
                    cs = cumsum(explained);
                    i_recon = min(find(cs > filtering.Stim_Artifact_Variance_Removed,1,'first')+1,size(score,2));
                    recon_data = score(:,i_recon:end)*coeff(:,i_recon:end)' + mu;
                    data_out(art_sample_indices(:), ii) = recon_data(:);
                end
            end

        case 'Stim_Blanking_Interp'
            fprintf("   - Applying Stimulus Blanking (Linear Interpolation method)\n");
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
            % Otherwise, use linear interpolation between the two points
            % -> Set (relative) samples for defining artifact blanking epoch.
            e_start = trigs + filtering.Stim_Blanking_Epoch(1);
            if filtering.Use_Stops_In_Stim_Blanking
                e_stop = stops + filtering.Stim_Blanking_Epoch(2);
            else
                e_stop = trigs + filtering.Stim_Blanking_Epoch(2);
            end
            % -> Interpolate on a trial-by-trial basis.
            nx = size(data_out,1);
            for ii = 1:numel(e_start)
                istop = min(e_stop(ii),nx);
                istart = max(e_start(ii),1);
                k = istop - istart;
                %temp = interp1([0, k], data_out([istart; istop], :), 0:k, 'linear');
                %noise = awgn(temp, 100, 'measured'); % Signal:Noise ratio 100:1
                %data_out(istart:istop, :) = noise;
                data_out(istart:istop, :) = interp1([0, k], data_out([istart; istop], :), 0:k, 'linear');
            end

        case 'Rectify'
            fprintf("   - Applying Rectification\n");
            data_out = abs(data_out);

        case 'Detrend'
            if isnan(filtering.Polynomial_Detrend_Order)
                filtering.Polynomial_Detrend_Order = max(n_trigs - 1, 3);
                if rem(filtering.Polynomial_Detrend_Order, 2)==0
                    filtering.Polynomial_Detrend_Order = filtering.Polynomial_Detrend_Order - 1;
                end
            end
            fprintf("   - Applying Polynomial Detrend (Order=%d)\n", filtering.Polynomial_Detrend_Order);
            data_out = detrend(data_out, filtering.Polynomial_Detrend_Order);

    end
end
fprintf("Done\n");

end


