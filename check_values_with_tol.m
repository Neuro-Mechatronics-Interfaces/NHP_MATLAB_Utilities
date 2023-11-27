function Y = check_values_with_tol(X, options)
%CHECK_VALUES_WITH_TOL Checks values in each individual cell of X against all other cells in X to identify the other cells with values within tolerance of each element of the checked cell. 
%
% Syntax:
%   Y = utils.check_values_with_tol(X, 'Name', value, ..);
%
% Example 1:
%   rng("default"); % Set random seed for reproducibility
%   X = cell(1,16);
%   for iX = 1:numel(X)
%       X{iX} = randi(randi(1000,1),randi(250,1),1);
%   end
%   Y = utils.check_values_with_tol(X);
%   disp(Y{1}(1:3,:));       % Should give [1 2 1; 1 2 11; 1 2 18];
%   disp(X{1}(1));           % Should give 104
%   disp(X{2}([1, 11, 18])); % Should give [108 108 98]   
%
% Example 2:
%   rng("default"); % Set random seed for reproducibility
%   X = cell(1,16);
%   for iX = 1:numel(X)
%       X{iX} = randi(randi(10000,1),randi(1000,1),1);
%   end
%   tic;
%   Y = utils.check_values_with_tol(X, ...
%           'LeftValueTolerance', 50,  ...
%           'RightValueTolerance', 50, ...
%           'ChannelTolerance', 4);
%   toc; % Runs in ~0.4 seconds
%   disp(Y{1}(1:3,:));         % Should give [1 2 60; 1 2 70; 1 2 109];
%   disp(X{1}(1));             % Should give 1035
%   disp(X{2}([60, 70, 109])); % Should give [1028, 1037, 1068] 
%   Z = utils.check_values_with_tol(X, ...
%           'LeftValueTolerance', 5,  ... % Reduce value tolerances
%           'RightValueTolerance', 5, ...
%           'ChannelTolerance', 4);
%   disp(Z{1}(1:3,:));         % Should give [1 2 70; 1 2 314; 1 2 595];
%   disp(X{1}(1));             % Should give 1035
%   disp(X{2}([70, 314, 595]); % Should give [1037, 1038, 1035]
%
% Inputs:
%     X cell {mustBeVector} - Cell vector where each cell contains a vector
%                               of values to compare against all other cells in X.
%
% Options:
%     'ChannelTolerance' (1,1) double = inf; % Can set this to limit the number of "channels away" for a match to be found.     
%     'LeftValueTolerance' (1,1) double = 10; % a.u. depends on data units in X
%     'RightValueTolerance' (1,1) double = 10; % a.u. depends on data units in X
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
    options.ChannelTolerance (1,1) double {mustBePositive} = inf; % Can set this to limit the number of "channels away" for a match to be found.     
    options.LeftValueTolerance (1,1) double = 10; % a.u. depends on data units in X
    options.RightValueTolerance (1,1) double = 10; % a.u. depends on data units in X
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
    if isinf(options.ChannelTolerance)
        fprintf(1,'Please wait, checking values matched on all channels with tolerance of [-%6.3f,+%6.3f)...000%%\n', options.LeftValueTolerance, options.RightValueTolerance);
    else
        fprintf(1,'Please wait, checking values matched within channel-groups of %d with tolerance of [-%6.3f,+%6.3f)...000%%\n', options.ChannelTolerance, options.LeftValueTolerance, options.RightValueTolerance);
    end
end
for iX = x_valid_indices
    for ii = 1:numel(X{iX})
        val = [X{iX}(ii)-options.LeftValueTolerance, X{iX}(ii)+options.RightValueTolerance];
        mask = (all_data(:,1) > iX) & (all_data(:,1) <= (iX + options.ChannelTolerance)) & (all_data(:,3)>=val(1)) & (all_data(:,3)<val(2));
        Y{iX} = [Y{iX}; [ones(sum(mask),1).*ii, all_data(mask, 1:2)]];
    end
    if options.Verbose
        n = n + 1;
        fprintf(1,'\b\b\b\b\b%03d%%\n', round(100*n/N));
    end
end

end