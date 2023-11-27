function Y = check_values_with_tol(X, options)
%CHECK_VALUES_WITH_TOL Checks values in each individual cell of X against all other cells in X to identify the other cells with values within tolerance of each element of the checked cell. 
%
% Syntax:
%   Y = utils.check_values_with_tol(X, 'Name', value, ..);
%
% Example:
%   rng("default"); % Set random seed for reproducibility
%   X = cell(1,16);
%   for iX = 1:numel(X)
%       X{iX} = randi(randi(1000,1),randi(250,1),1);
%   end
%   Y = utils.check_values_with_tol(X);
%   disp(Y{1}(1:3,:)); % Should give [1 2 1; 1 2 11; 1 2 18];
%   disp(X{1}(1)); % Should give 104
%   disp(X{2}([1, 11, 18])); % Should give [108 108 98]   
%
% Inputs:
%     X cell {mustBeVector} - Cell vector where each cell contains a vector
%                               of values to compare against all other cells in X.
%
% Options:
%     'LeftTolerance' (1,1) double = 10; % a.u. depends on data units in X
%     'RightTolerance' (1,1) double = 10; % a.u. depends on data units in X
%     'Verbose' (1,1) logical = true;
%
% Output:
%   Y cell - Same size as X but cell elements are arrays of [nMatch x 3], 
%               such that Y{i}(j,1) indicates the index of the original 
%               element from X{i} to match to the other cells for row j; 
%               Y{i}(j,2) indicates which cell in X that the indexed
%               template value was matched against; and 
%               Y{i}(j,3) is the corresponding element index within that
%               cell of X which was specifically matched.
%
% See also: Contents

arguments
    X cell {mustBeVector}
    options.LeftTolerance (1,1) double = 10; % a.u. depends on data units in X
    options.RightTolerance (1,1) double = 10; % a.u. depends on data units in X
    options.Verbose (1,1) logical = true;
end

x_valid_indices = find(~cellfun(@isempty, X));
x_valid_indices = reshape(x_valid_indices, 1, numel(x_valid_indices));
all_data = [];
for iX = x_valid_indices
    nx = numel(X{iX});
    all_data = [all_data; [ones(nx,1).*iX, (1:nx)', reshape(X{iX}, nx, 1)]]; %#ok<*AGROW> 
end
Y = cell(size(X));
if options.Verbose
    n = 0;
    N = numel(x_valid_indices);
    fprintf(1,'Please wait, checking values with tolerance of [-%6.3f,+%6.3f)...000%%\n', options.LeftTolerance, options.RightTolerance);
end
for iX = x_valid_indices
    for ii = 1:numel(X{iX})
        val = [X{iX}(ii)-options.LeftTolerance, X{iX}(ii)+options.RightTolerance];
        mask = (all_data(:,1)~=iX) & (all_data(:,3)>=val(1)) & (all_data(:,3)<val(2));
        Y{iX} = [Y{iX}; [ones(sum(mask),1).*ii, all_data(mask, 1:2)]];
    end
    if options.Verbose
        n = n + 1;
        fprintf(1,'\b\b\b\b\b%03d%%\n', round(100*n/N));
    end
end

end