function d = datetime_2_date(dt)
%DATETIME_2_DATE Convert datetime to just date, keeping as a datetime value-type.
%
% Syntax:
%   d = utils.datetime_2_date(dt);
%
% Inputs:
%   dt - Array of datetime that has hours, minutes, seconds values etc.
%   
% Output:
%   d - Array of datetime with same timezone as dt, but only the date part.
d = datetime(year(dt),month(dt),day(dt));
d.TimeZone = dt.TimeZone; % To make sure it is compatible
end