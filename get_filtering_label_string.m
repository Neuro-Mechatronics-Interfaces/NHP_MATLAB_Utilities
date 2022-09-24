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
    if numel(HPF_Cutoff_Frequency) == 2
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

if filtering.Apply_Max_Rescale
    str = ['(Rescaled) ', str]; 
end

end