function str = get_filtering_label_string(filtering)
%GET_FILTERING_LABEL_STRING  Returns string to indicate what filtering was done.
%
% Syntax:
%   str = get_filtering_label_string(filtering);
%
% Inputs:
%   filtering - Filtering parameters struct
%
% Output:
%   str - char array indicating the filters that were used.
%
% See also: Contents, get_default_filtering_pars

if filtering.Apply_HPF && filtering.Apply_Polynomial_Detrend && filtering.Apply_Virtual_Reference
    if numel(filtering.HPF_Cutoff_Frequency) == 2
        if strcmpi(filtering.Name, 'raw')
            str = char(sprintf('Detrend (poly = %d) + BPF (Ord = %d | Fc = [%.6g %.6g]) + VRef', filtering.Polynomial_Detrend_Order, filtering.HPF_Order, filtering.HPF_Cutoff_Frequency(1), filtering.HPF_Cutoff_Frequency(2)));
        else
            str = char(sprintf('Detrend (poly = %d) + BPF (Ord = %d | Fc = [%.6g %.6g]) + VRef + %s', filtering.Polynomial_Detrend_Order, filtering.HPF_Order, filtering.HPF_Cutoff_Frequency(1), filtering.HPF_Cutoff_Frequency(2), filtering.Name));
        end
    else
        if strcmpi(filtering.Name, 'raw')
            str = char(sprintf('Detrend (poly = %d) + HPF (Ord = %d | Fc = %.6g) + VRef', filtering.Polynomial_Detrend_Order, filtering.HPF_Order, filtering.HPF_Cutoff_Frequency));
        else
            str = char(sprintf('Detrend (poly = %d) + HPF (Ord = %d | Fc = %.6g) + VRef + %s', filtering.Polynomial_Detrend_Order, filtering.HPF_Order, filtering.HPF_Cutoff_Frequency, filtering.Name));
        end
    end
elseif filtering.Apply_HPF && filtering.Apply_Polynomial_Detrend
    if numel(filtering.HPF_Cutoff_Frequency) == 2
        if strcmpi(filtering.Name, 'raw')
            str = char(sprintf('Detrend (poly = %d) + BPF (Ord = %d | Fc = [%.6g %.6g])', filtering.Polynomial_Detrend_Order, filtering.HPF_Order, filtering.HPF_Cutoff_Frequency(1), filtering.HPF_Cutoff_Frequency(2)));
        else
            str = char(sprintf('Detrend (poly = %d) + BPF (Ord = %d | Fc = [%.6g %.6g]) + %s', filtering.Polynomial_Detrend_Order, filtering.HPF_Order, filtering.HPF_Cutoff_Frequency(1), filtering.HPF_Cutoff_Frequency(2), filtering.Name));
        end
    else
        if strcmpi(filtering.Name, 'raw')
            str = char(sprintf('Detrend (poly = %d) + HPF (Ord = %d | Fc = %.6g)', filtering.Polynomial_Detrend_Order, filtering.HPF_Order, filtering.HPF_Cutoff_Frequency));
        else
            str = char(sprintf('Detrend (poly = %d) + HPF (Ord = %d | Fc = %.6g) + %s', filtering.Polynomial_Detrend_Order, filtering.HPF_Order, filtering.HPF_Cutoff_Frequency, filtering.Name));
        end
    end
elseif filtering.Apply_HPF && filtering.Apply_Virtual_Reference
    if numel(filtering.HPF_Cutoff_Frequency) == 2
        if strcmpi(filtering.Name, 'raw')
            str = char(sprintf('BPF (Ord = %d | Fc = [%.6g %.6g]) + VRef', filtering.HPF_Order, filtering.HPF_Cutoff_Frequency(1), filtering.HPF_Cutoff_Frequency(2)));
        else
            str = char(sprintf('BPF (Ord = %d | Fc = [%.6g %.6g]) + VRef + %s', filtering.HPF_Order, filtering.HPF_Cutoff_Frequency(1), filtering.HPF_Cutoff_Frequency(2), filtering.Name));
        end
    else
        if strcmpi(filtering.Name, 'raw')
            str = char(sprintf('HPF (Ord = %d | Fc = %.6g) + VRef', filtering.HPF_Order, filtering.HPF_Cutoff_Frequency));
        else
            str = char(sprintf('HPF (Ord = %d | Fc = %.6g) + VRef + %s', filtering.HPF_Order, filtering.HPF_Cutoff_Frequency, filtering.Name));
        end
    end
elseif filtering.Apply_Polynomial_Detrend && filtering.Apply_Virtual_Reference
    if strcmpi(filtering.Name, 'raw')
        str = char(sprintf('Detrend (poly = %d) + VRef', filtering.Polynomial_Detrend_Order));
    else
        str = char(sprintf('Detrend (poly = %d) + VRef + %s', filtering.Polynomial_Detrend_Order, filtering.Name));
    end
elseif filtering.Apply_HPF
    if numel(filtering.HPF_Cutoff_Frequency) == 2
        if strcmpi(filtering.Name, 'raw')
            str = char(sprintf('BPF (Ord = %d | Fc = [%.6g %.6g])', filtering.HPF_Order, filtering.HPF_Cutoff_Frequency(1), filtering.HPF_Cutoff_Frequency(2)));
        else
            str = char(sprintf('BPF (Ord = %d | Fc = [%.6g %.6g]) + %s', filtering.HPF_Order, filtering.HPF_Cutoff_Frequency(1), filtering.HPF_Cutoff_Frequency(2), filtering.Name));
        end
    else
        if strcmpi(filtering.Name, 'raw')
            str = char(sprintf('HPF (Ord = %d | Fc = %.6g)', filtering.HPF_Order, filtering.HPF_Cutoff_Frequency));
        else
            str = char(sprintf('HPF (Ord = %d | Fc = %.6g) + %s', filtering.HPF_Order, filtering.HPF_Cutoff_Frequency, filtering.Name));
        end
    end
elseif filtering.Apply_Polynomial_Detrend
    if strcmpi(filtering.Name, 'raw')
        str = char(sprintf('Detrend (poly = %d)', filtering.Polynomial_Detrend_Order));
    else
        str = char(sprintf('Detrend (poly = %d) + %s', filtering.Polynomial_Detrend_Order, filtering.Name));
    end
elseif filtering.Apply_Virtual_Reference
    if strcmpi(filtering.Name, 'raw')
        str = 'VRef';
    else
        str = char(sprintf('VRef + %s', filtering.Name));
    end
else
    str = char(filtering.Name);
end

if filtering.Use_PCA_Stim_Blanking
    art_str = sprintf('PCA-Art-Blank=%3.1f%%', filtering.Stim_Artifact_Variance_Removed);
else
    art_str = sprintf('Art. Lin. Interp [%d %d]', filtering.Stim_Blanking_Epoch);
end
if filtering.Apply_Max_Rescale
    if filtering.Apply_Stim_Blanking && filtering.Apply_Pre_Stimulus_Normalization
        str = [sprintf('(%s + Pre-Stim Z-score) ', art_str), str];        
    elseif filtering.Apply_Stim_Blanking
        str = [sprintf('(%s + Max-Rescaled) ', art_str), str];        
    elseif filtering.Apply_Pre_Stimulus_Normalization
        str = ['(Pre-Stim Z-score) ', str];
    else
        str = ['(Max-Rescaled) ', str]; 
    end
else
    if filtering.Apply_Stim_Blanking && filtering.Apply_Pre_Stimulus_Normalization
        str = [sprintf('(%s + Pre-Stim Z-score) ', art_str), str]; 
    elseif filtering.Apply_Stim_Blanking
        str = [sprintf('(%s) ', art_str), str];
    elseif filtering.Apply_Pre_Stimulus_Normalization
        str = ['(Pre-Stim Z-score) ', str];
    end
end

if filtering.Subtract_Cross_Trial_Mean
    if strcmpi(str(end), ')')
        str = [str(1:(end-1)), ' | S.D.)'];
    else
        str = [str, ' | S.D.'];
    end
end

end