function t = sample_time(data,fs,t_start)
%SAMPLE_TIME  Returns sample timestamp vector from data length and sample rate, with optional offset time.
%
% Syntax:
%   t = utils.sample_time(data, fs);
%   t = utils.sample_time(data, fs, t_start);
%
% Inputs:
%   data - Data vector or array. If array, uses longest dimension for times
%   fs   - Sample rate (samples/second).
%   t_start (optional) - Default is 0; set to non-zero to add this to the
%                           returned time vector.
%
% Output:
%   t - nSamples time vector. Orientation (1 x nSamples or nSamples x 1)
%           depends on which dimension of `data` is longest.
arguments
    data double
    fs (1,1) double
    t_start (1,1) double = 0;
end
dims = size(data);
n = length(data);
t = (0:(1/fs):((n-1)/fs)) + t_start;
d = find(dims == n,1,'first');
dims = ones(size(dims));
dims(d) = n;
t = reshape(t, dims);

end