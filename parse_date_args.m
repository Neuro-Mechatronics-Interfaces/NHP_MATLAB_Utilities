function [yyyy, mm, dd] = parse_date_args(YYYY, MM, DD, to_string)
%PARSE_DATE_ARGS  Parse date input arguments
%
% Syntax:
%   [yyyy, mm, dd] = parse_date_args(YYYY, MM, DD);
%   [yyyy, mm, dd] = parse_date_args(YYYY, MM, DD, to_string);
%
% Inputs:
%   YYYY  --  Numeric or string/char year (2-digit or 4-digit)
%   MM    --  Numeric or string/char month
%   DD    --  Numeric or string/char day
%   to_string -- Default is false; if set to true, converts to string
%                   instead of to numeric (integer) values.
%
% Output:
%   yyyy  --  Integer (4-digit) version of year
%   mm    --  Integer version of month
%   dd    --  Integer version of day
%
% See also: Contents, load_tmsi_raw, load_block_hd_emg

if nargin < 4
    to_string = false; 
end

if ~isnumeric(YYYY)
    if to_string
        yyyy = string(YYYY);
    else
        yyyy = str2double(YYYY);
    end
else
    if to_string
        yyyy = string(sprintf('%04d', YYYY));
    else
        yyyy = YYYY;
    end
end
if ~isnumeric(DD)
    if to_string
        dd = string(DD);
    else
        dd = str2double(DD);
    end
else
    if to_string
        dd = string(sprintf('%02d', DD));
    else
        dd = DD;
    end
end
if ~isnumeric(MM)
    if to_string
        mm = string(MM); 
    else
        mm = str2double(MM);
    end
else
    if to_string
        mm = string(sprintf('%02d', MM));
    else
        mm = MM;
    end
end

end