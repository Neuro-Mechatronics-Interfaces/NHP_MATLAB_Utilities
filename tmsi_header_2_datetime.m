function dt = tmsi_header_2_datetime(h)
%TMSI_HEADER_2_DATETIME  Convert TMSi header start_time field to datetime
%
% Syntax:
%   dt = utils.tmsi_header_2_datetime(h);
%
% Inputs:
%   h - Header struct with field `start_time` that is 7-element numeric
%       array.
%
% Output:
%   dt - Formatted datetime that is TMSi recorded start of session.
%
% See also: Contents

ts = h.start_time(1:6)';
ts(6) = ts(6) + h.start_time(7).*1e-3;
ts(4) = ts(4) + 9; % Account for offset from different timezones.
dt = datetime(ts, ...
    'Format', 'yyyy-MM-dd HH:mm:ss.SSS', ...
    'TimeZone', 'America/New_York');

end