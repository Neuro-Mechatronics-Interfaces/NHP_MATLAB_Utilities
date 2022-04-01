function pars = parse_parameters(pars, varargin)
%PARSE_PARAMETERS Parses input parameters given a default struct.
%
% Syntax:
%   pars = parse_parameters(pars, 'Field1', value1, 'Field2', value2, ...)
%
% See also: Contents

if numel(varargin) > 0
    % In case `pars` was given directly:
    if isstruct(varargin{1})
        pars = varargin{1};
        varargin(1) = [];
    end
    % Handle <'Name', value> varargin pairs.
    f = fieldnames(pars);
    for iV = 1:2:numel(varargin)
        idx = strcmpi(f, varargin{iV});
        if sum(idx) == 1 % If only one unique field matches, then make assignment of subsequent value.
            pars.(f{idx}) = varargin{iV+1}; 
        end
    end
end
pars.ts = default.now();  % Timestamp when parameters were generated.

end