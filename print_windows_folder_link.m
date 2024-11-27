function s = print_windows_folder_link(f, tag)
%UTILS.PRINT_WINDOWS_FOLDER_LINK Print or return a hyperlink to open a Windows folder.
%
% Syntax:
%   utils.print_windows_folder_link(f);               % Print to the Command Window
%   s = utils.print_windows_folder_link(f);           % Return hyperlink string for later use
%   utils.print_windows_folder_link(f, tag);          % Print with custom hyperlink text
%   s = utils.print_windows_folder_link(f, tag);      % Return hyperlink string with custom text
%
% Description:
%   This function generates clickable hyperlinks for Windows folders and prints them in the Command Window.
%   Alternatively, it can return a string or string array of hyperlinks for later use. These hyperlinks use 
%   MATLAB's `winopen` function to open the specified folders directly in Windows Explorer.
%
% Inputs:
%   f   - String or char array, or an array of strings or cell array of char arrays, specifying the full folder 
%         paths. These should be valid paths that can be opened by the MATLAB `winopen` function.
%   tag - (Optional) String or char array, or an array of strings or cell array of char arrays, specifying the 
%         text displayed as the hyperlink. If `f` is an array, `tag` must have the same number of elements or 
%         a scalar value to be repeated (default: "Link").
%
% Output:
%   s   - String or string array of hyperlinks. If no output is requested, the hyperlinks are printed to the 
%         Command Window. Use `disp(s)` to print the hyperlinks later.
%
% Example 1: Print a hyperlink for a single folder
%   folderPath = "C:\Users\YourUserName\Documents";
%   utils.print_windows_folder_link(folderPath);
%
% Example 2: Return a hyperlink for later use
%   folderPath = "C:\Users\YourUserName\Documents";
%   s = utils.print_windows_folder_link(folderPath);
%   disp(s);  % Prints the hyperlink in the Command Window
%
% Example 3: Print hyperlinks for multiple folders with custom tags
%   folderPaths = ["C:\Folder1", "C:\Folder2"];
%   tags = ["Project A", "Project B"];
%   utils.print_windows_folder_link(folderPaths, tags);
%
% Example 4: Return hyperlinks for multiple folders
%   folderPaths = ["C:\Folder1", "C:\Folder2"];
%   tags = ["Project A", "Project B"];
%   s = utils.print_windows_folder_link(folderPaths, tags);
%   disp(s);  % Prints the hyperlinks in the Command Window
%
% Notes:
%   - This function is designed for use on Windows systems where `winopen` is available.
%   - When `f` is an array, the corresponding `tag` array must match in size or be scalar.
%   - If no output variable is specified, the hyperlinks are automatically printed to the Command Window.
%
% See also: winopen


arguments
    f (:,1) string
    tag (:,1) string = "Link";
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