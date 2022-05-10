function sample_vector = apply_debounce(sample_vector, min_sample_interval)
%APPLY_DEBOUNCE  Debounce vector of sample times so that each is separated by *at least* `min_sample_interval` samples.
%
% Syntax:
%   sample_vector = apply_debounce(sample_vector, min_sample_interval);
%
% Inputs:
%   sample_vector - Vector of sample indices
%   min_sample_interval - Minimum number of samples that each value
%                           in sample_vector must be separated by.
%                           This helper function ensures that this
%                           value separates them.
% Output:
%   sample_vector - "Debounced" version of input.
iSample = 1;
while iSample < numel(sample_vector)
    if (sample_vector(iSample + 1) - sample_vector(iSample)) < min_sample_interval
        sample_vector(iSample + 1) = []; % Discard
    else
        iSample = iSample + 1; % Continue
    end
end
end