function s = print_windows_folder_link(f, tag)
%PRINT_WINDOWS_FOLDER_LINK Print or return string to link to windows folder(s)
%
% Syntax:
%   utils.print_windows_folder_link(f);     % Print to Command window
%   s = utils.print_windows_folder_link(f); % Return string to use later
%   [__] = utils.print_windows_folder_link(__, tag); % Tag that is shown as the text part of the href in command window, matched to elements of f if it is an array.
%
% Inputs:
%   f - String or char array, or array of strings or cell array of char
%           arrays. These should be the full folder name to print, such as
%           would be called by `winopen` builtin.
%   tag - String or char array, or array of strings or cell array of char
%           arrays. If this is an array of strings or cell array of char
%           arrays, then it should have the same number of elements as f.
%
% Output:
%   s - String or string array of statements that can be used with
%           `disp` to cause Command Window print if desired at a later
%           time.
%
% See also: Contents

f = string(f);
if nargin < 2
    tag = "Link";
else
    tag = string(tag);
end
if numel(tag) ~= numel(f)
    if numel(tag) > 1
        error("Mismatch on input size for tag and f, check inputs.");
    end
    tag = repmat(tag, size(f));
end

if nargout > 0
    if isscalar(f)
        s = string(sprintf('<a href="matlab:winopen(''%s'');">%s</a>', f, tag));
    else
        s = strings(size(f));
        for ii = 1:numel(f)
            s(ii) = sprintf('\n<a href="matlab:winopen(''%s'');">%d. %s</a>\n', ...
                f(ii), ii, tag(ii));
        end
    end
else
    if isscalar(f)
        fprintf(1, '<a href="matlab:winopen(''%s'');">%s</a>\n', f, tag);
    else
        for ii = 1:numel(f)
            fprintf(1, '<a href="matlab:winopen(''%s'');">%d. %s</a>\n', ...
                f(ii), ii, tag(ii));
        end
    end
    s = []; %#ok<NASGU>
    clear s;
end


end