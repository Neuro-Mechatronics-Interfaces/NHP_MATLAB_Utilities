function s = print_timing_info(maintic, function_name)
%PRINT_TIMING_INFO Prints total time for a given function to run.
%
% Syntax:
%   s = utils.print_timing_info(maintic, function_name);
%
% Example:
%   maintic = tic;
%   ...
%   [~, function_name, ~] = fileparts(mfilename);
%   utils.print_timing_info(maintic, function_name);
%
% Inputs:
%   maintic - Output from a `tic` assignment.
%   function_name - (Optional) name of function that was timed.
%
% Output:
%   s - (Optional) formatted output string.
%
%   Prints to the command window the total time to run a particular
%   function.
%
% See also: Contents, tic, mfilename

total = seconds(toc(maintic));

H = floor(hours(total));
M = floor(minutes(total - hours(H)));
S = round(seconds(total - (hours(H) + minutes(M))), 2);

if nargin > 1
    s = sprintf('\t->\t<strong>%3d h :: %2d m :: %4.2f s</strong> elapsed (<strong>%s</strong>)\n', H, M, S, function_name); 
else
    s = sprintf('\t->\t<strong>%3d h :: %2d m :: %4.2f s</strong> elapsed\n', H, M, S); 
end
fprintf(1, s);
if nargout < 1  % Suppress output if no `;` and no LHS assignment
    clear s;
end
end