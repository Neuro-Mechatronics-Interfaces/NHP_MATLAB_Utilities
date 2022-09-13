function filtering = get_default_filtering_pars(acquisition_system, data_type, filter_type, varargin)
%GET_DEFAULT_FILTERING_PARS Return default filtering parameters struct.
%
% Syntax:
%   filtering = get_default_filtering_pars(acquisition_system, data_type, filter_type, varargin);
%
% Inputs:
%   acquisition_system - "TMSi" (default; not set up for others yet 12/10/21)
%   data_type - "Array" (default) | "Bipolar"
%   filter_type - "Rectified" (default) | "Raw" | "Differential2" | "Differential2rectified"
%   varargin - (Optional) 'Name', value input pairs. See fields of `Array`
%                   or `Bipolar` for options.
%
% Output:
%   filtering - Struct to be used with `apply_emg_filtering`
%
% See also: Contents, apply_emg_filtering, plot_emg_averages

opts = struct;
opts.TMSi.Array = struct;
opts.TMSi.Array.Name = "Raw";                               % Can be: "Raw" | "Rectified" | "Vref" | "Differential2" | "Differential2rectified"
opts.TMSi.Array.Add_To_Plots = true(64, 1);                 % Add channel to plot?
opts.TMSi.Array.Apply_HPF = true;                          % Apply high-pass filter to the data?
opts.TMSi.Array.Apply_Max_Rescale = false;                   % Apply rescaling using maximum value on per-channel basis?
opts.TMSi.Array.Apply_Polynomial_Detrend = false;            % Apply polynomial detrending to the data?
opts.TMSi.Array.Apply_Stim_Blanking = false;                % Apply stimulation artifact blanking to the data?
opts.TMSi.Array.Stim_Blanking_Epoch = [-4 8];               % Samples to blank around stim onset and offset sample, respectively.
opts.TMSi.Array.Pre_Blanking_HPF_Order = 1;                 % Order of pre-blanking DC bias removal filter order
opts.TMSi.Array.Pre_Blanking_HPF_Cutoff_Frequency = 15;     % Pre-blanking DC bias removal filter cutoff
opts.TMSi.Array.Apply_Virtual_Reference = true;             % Apply virtual common average subtraction?
opts.TMSi.Array.HPF_Order = 2;                              % Butterworth filter order for High-pass filter
opts.TMSi.Array.HPF_Cutoff_Frequency = 1;                   % Cutoff frequency for High-pass filter
opts.TMSi.Array.Polynomial_Detrend_Order = 3;               % If this is NaN, auto-compute polynomial detrend order from number of triggers. Otherwise, use a specified polynomial fit to detrend data.

opts.TMSi.Bipolar = struct;
opts.TMSi.Bipolar.Name = "Rectified";                       % Can be: "Raw" | "Rectified" | "Vref"
opts.TMSi.Bipolar.Add_To_Plots = true;                      % Add to plot?
opts.TMSi.Bipolar.Apply_HPF = true;                         % Apply high-pass filter to the data?
opts.TMSi.Bipolar.Apply_Max_Rescale = false;                % Apply rescaling using maximum value on per-channel basis?
opts.TMSi.Bipolar.Apply_Polynomial_Detrend = true;          % Apply polynomial detrending to the data?
opts.TMSi.Bipolar.Apply_Stim_Blanking = false;              % Apply stimulation artifact blanking to the data?
opts.TMSi.Bipolar.Stim_Blanking_Epoch = [-4 8];             % Samples to blank around stim onset and offset sample, respectively.
opts.TMSi.Bipolar.Pre_Blanking_HPF_Order = 1;               % Order of pre-blanking DC bias removal filter order
opts.TMSi.Bipolar.Pre_Blanking_HPF_Cutoff_Frequency = 15;   % Pre-blanking DC bias removal filter cutoff
opts.TMSi.Bipolar.Apply_Virtual_Reference = false;          % Apply virtual common average subtraction?
opts.TMSi.Bipolar.HPF_Order = 4;                            % Butterworth filter order for High-pass filter
opts.TMSi.Bipolar.HPF_Cutoff_Frequency = 30;                % Cutoff frequency for High-pass filter
opts.TMSi.Bipolar.Polynomial_Detrend_Order = 7;             % If this is NaN, auto-compute polynomial detrend order from number of triggers. Otherwise, use a specified polynomial fit to detrend data.

opts.TMSi.RMS = struct;
opts.TMSi.RMS.Name = "Rectified";                       % Can be: "Raw" | "Rectified" | "Vref"
opts.TMSi.RMS.Add_To_Plots = true;                      % Add to plot?
opts.TMSi.RMS.Apply_HPF = true;                         % Apply high-pass filter to the data?
opts.TMSi.RMS.Apply_Max_Rescale = false;                % Apply rescaling using maximum value on per-channel basis?
opts.TMSi.RMS.Apply_Polynomial_Detrend = false;         % Apply polynomial detrending to the data?
opts.TMSi.RMS.Apply_Stim_Blanking = false;              % Apply stimulation artifact blanking to the data?
opts.TMSi.RMS.Stim_Blanking_Epoch = [-4 8];             % Samples to blank around stim onset and offset sample, respectively.
opts.TMSi.RMS.Pre_Blanking_HPF_Order = 1;               % Order of pre-blanking DC bias removal filter order
opts.TMSi.RMS.Pre_Blanking_HPF_Cutoff_Frequency = 15;   % Pre-blanking DC bias removal filter cutoff
opts.TMSi.RMS.Apply_Virtual_Reference = true;           % Apply virtual common average subtraction?
opts.TMSi.RMS.HPF_Order = 2;                            % Butterworth filter order for High-pass filter
opts.TMSi.RMS.HPF_Cutoff_Frequency = 2;                 % Cutoff frequency for High-pass filter
opts.TMSi.RMS.Polynomial_Detrend_Order = 7;             % If this is NaN, auto-compute polynomial detrend order from number of triggers. Otherwise, use a specified polynomial fit to detrend data.


if nargin < 3
    filter_type = "Rectified"; 
end

if nargin < 2
    data_type = 'Array';
end

if nargin < 1
    acquisition_system = 'TMSi'; 
end

if ~ismember(acquisition_system, fieldnames(opts))
    error('Not set up with default filters for acquisition system == <strong>%s</strong>\n', acquisition_system); 
end
opts = opts.(acquisition_system);

if ~ismember(data_type, fieldnames(opts))
    error('Not set up with default filters for combination: <strong>%s.%s</strong>\n', acquisition_system, data_type); 
end
filtering = opts.(data_type);

filtering.Name = filter_type;
filtering.System = acquisition_system;
filtering.Type = data_type;

filtering = utils.parse_parameters(filtering, varargin{:});

end
