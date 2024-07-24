function [subset_1, subset_2] = find_overlapping_indices(sample_times_1, sample_times_2, tolerance)
%FIND_OVERLAPPING_INDICES Finds overlapping indices in two time-series.
%
%   [subset_1, subset_2] = utils.find_overlapping_indices(sample_times_1, sample_times_2, tolerance)
%   returns the indices of overlapping timestamps from two datetime arrays.
%
%   Inputs:
%       sample_times_1 - A column vector of datetime values representing the timestamps of the first time-series.
%       sample_times_2 - A column vector of datetime values representing the timestamps of the second time-series.
%       tolerance - A scalar double representing the tolerance for matching samples in seconds.
%
%   Outputs:
%       subset_1 - Indices of overlapping timestamps in the first time-series.
%       subset_2 - Indices of overlapping timestamps in the second time-series.
%
%   Example:
%       sample_times_1 = datetime({'2023-07-26 12:19:54.6923', '2023-07-26 12:19:54.9423', '2023-07-26 12:19:55.1923'});
%       sample_times_2 = datetime({'2023-07-26 12:19:54.7923', '2023-07-26 12:19:55.0423', '2023-07-26 12:19:55.2923'});
%       tolerance = 0.001; % 1 millisecond tolerance
%
%       [subset_1, subset_2] = find_overlapping_indices(sample_times_1, sample_times_2, tolerance);
%       disp('Indices in time series 1:');
%       disp(subset_1);
%
%       disp('Indices in time series 2:');
%       disp(subset_2);
%
%   Note:
%       This function assumes that the input datetime arrays are sampled uniformly at 4 kHz.
%
%   See also DATETIME, FIND

arguments
    sample_times_1 (1,:) datetime
    sample_times_2 (1,:) datetime
    tolerance (1,1) double = 0.001 % Tolerance for matching samples (seconds)
end

% Define the tolerance as duration
tolerance = seconds(tolerance);

% Find the overlapping range
start_time = max(sample_times_1(1), sample_times_2(1));
end_time = min(sample_times_1(end), sample_times_2(end));

% Find indices in the first time series that fall within the overlap range
subset_1 = find(sample_times_1 >= (start_time - tolerance) & sample_times_1 <= (end_time + tolerance));

% Find indices in the second time series that fall within the overlap range
subset_2 = find(sample_times_2 >= (start_time - tolerance) & sample_times_2 <= (end_time + tolerance));

% Ensure the subsets have the same number of elements
while length(subset_1) ~= length(subset_2)
    if length(subset_1) > length(subset_2)
        % Remove the element in subset_1 that is furthest from its corresponding element in subset_2
        distances_start = abs(sample_times_1(subset_1(1)) - sample_times_2(subset_2(1)));
        distances_end = abs(sample_times_1(subset_1(end)) - sample_times_2(subset_2(end)));
        
        if distances_start > distances_end
            subset_1(1) = [];
        else
            subset_1(end) = [];
        end
    else
        % Remove the element in subset_2 that is furthest from its corresponding element in subset_1
        distances_start = abs(sample_times_2(subset_2(1)) - sample_times_1(subset_1(1)));
        distances_end = abs(sample_times_2(subset_2(end)) - sample_times_1(subset_1(end)));
        
        if distances_start > distances_end
            subset_2(1) = [];
        else
            subset_2(end) = [];
        end
    end
end

end
