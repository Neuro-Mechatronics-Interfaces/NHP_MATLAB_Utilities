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

ts = h.start_time([1:3, 5:7])';
dt = datetime(ts, ...
    'Format', 'uuuu-MM-dd HH:mm:ss.SSSS', ...
    'TimeZone', 'America/New_York');

end