function print_tree(options)
%PRINT_TREE Recursively prints a visual directory tree with file and folder stats.
%
% Syntax:
%   print_tree(options)
%
% Description:
%   Recursively traverses a folder structure starting at the given root,
%   printing a tree-like hierarchy of folders and (optionally) files.
%   Allows filtering, sorting, and size reporting. Output can be printed
%   to the Command Window or written to a text file.
%
% Options (Name-Value Pairs in `options` struct):
%   Start                - (string) Starting path for tree traversal. Default: `pwd`
%   OutputFile           - (string) If non-empty, saves output to a UTF-8 .txt file.
%   Root                 - (string) Path to define relative indentation. Default: same as Start.
%   MaxDepth             - (positive scalar) Max folder depth. Default: `inf`
%   FileFilter           - (string) Wildcard pattern for files. Default: `'*.*'`
%   FolderFilter         - (string) Slash-delimited wildcard for folders by level (e.g., '*/Data')
%   PrintFolderSize      - (logical) If true, appends size and file count for folders.
%   PrintFiles           - (logical) If true, includes file names in tree output.
%   FolderSizeLim        - ([min max] double) Min/max size in **gigabytes** to show folders.
%   FolderFileCountLim   - ([min max] double) Min/max total file counts for shown folders.
%   SortBy               - (string) One of `'FolderSize'`, `'FileCount'`, or `'None'`. Sort order for subfolders.
%   ClearCache           - (logical) If true, clears internal size cache for fresh computation.
%
% Notes:
%   - Sizes are displayed in human-readable units (B, KB, MB, GB).
%   - Relative folder indentation is computed from Root, if specified.
%   - Uses persistent caching of folder sizes unless 'ClearCache' is true.
%
% Example:
%   print_tree(struct( ...
%       'Start', 'C:\MyProject', ...
%       'OutputFile', 'tree_output.txt', ...
%       'MaxDepth', 3, ...
%       'PrintFolderSize', true, ...
%       'SortBy', 'FileCount' ...
%   ));
%
% See also: dir, fullfile, containers.Map

arguments
    options.ClearCache (1,1) logical = false;
    options.Start {mustBeTextScalar} = pwd;
    options.OutputFile {mustBeTextScalar} = "";
    options.Root {mustBeTextScalar} = "";
    options.MaxDepth {mustBePositive} = inf;
    options.FileFilter {mustBeTextScalar} = "*.*";
    options.FileExcluder (1,:) = strings(1,0);
    options.FolderFilter {mustBeTextScalar} = "*";
    options.FolderExcluder (1,:) string = strings(1,0);
    options.PrintFolderSize (1,1) logical = true;
    options.PrintFiles (1,1) logical = true;
    options.FolderSizeLim (1,2) double = [-inf, inf];
    options.FolderFileCountLim (1,2) double = [-inf, inf];
    options.SortBy {mustBeMember(options.SortBy, {'FolderSize', 'FileCount', 'None'})} = 'FolderSize';
end

outfile = options.OutputFile;
[p,f,~] = fileparts(outfile);
outfile = fullfile(p, sprintf('%s.txt', f));

startpath = options.Start;

printFile = strlength(outfile) > 0;
if ~printFile
    clc;
end
if strlength(options.Root) < 1
    root = startpath;
else
    root = options.Root;
end

startpath = char(java.io.File(startpath).getCanonicalPath());
root = char(java.io.File(root).getCanonicalPath());

if ~startsWith(startpath, root)
    error('Path %s is not inside root %s.', startpath, root);
end

if printFile
    fid = fopen(outfile, 'w', 'n', 'UTF-8');
    if fid == -1
        error('Failed to open file for writing: %s', outfile);
    end
else
    fid = 1;
end

[~, project_name] = fileparts(root);
fprintf(fid, '%s/\n', project_name);

relative_parts = split(strip(replace(startpath, root, ''), filesep), filesep);
if all(cellfun(@isempty, relative_parts))
    relative_parts = {};
end

folderFilterParts = split(regexprep(options.FolderFilter, '\\', '/'), '/');
folderSizeLimInBytes = options.FolderSizeLim * (1024^3);

if options.ClearCache
    clear get_folder_size
end
write_tree(startpath, fid, numel(relative_parts), options.MaxDepth, ...
    options.FileFilter, folderFilterParts, options.PrintFolderSize, ...
    folderSizeLimInBytes, options.FolderFileCountLim, ...
    options.SortBy, options.PrintFiles);

if printFile
    fclose(fid);
    fprintf('Pretty tree written to %s\n', outfile);
end

    function write_tree(path, fid, base_level, max_levels, fileFilter, ...
        folderFilterParts, showSize, sizeLimits, countLimits, sortBy, ...
        printFiles, progBase, progWidth)
        %WRITE_TREE Recursive function to write nested tree structure to Command Window or text file.
        d_all = dir(path);
        d_all = d_all(~startsWith({d_all.name}, '.'));

        dirs = d_all([d_all.isdir]);
        folderNames = {dirs.name};

        level = base_level + 1;
        if level <= numel(folderFilterParts)
            pattern = folderFilterParts{level};
        else
            pattern = '*';
        end

        % Match folder name using wildcard
        keepFolders = cellfun(@(f) ~isempty(regexp(f, wildcard2regexp(pattern), 'once')), folderNames);
        % Exclude folders based on FolderExcluder
        if ~isempty(options.FolderExcluder)
            excludeMatches = false(size(folderNames));
            for jj = 1:numel(options.FolderExcluder)
                pat = wildcard2regexp(options.FolderExcluder(jj));
                excludeMatches = excludeMatches | ~cellfun(@isempty, regexp(folderNames, pat, 'once'));
            end
            keepFolders = keepFolders & ~excludeMatches;
        end

        % Apply folder size bounds
        n = numel(dirs);
        sizes = zeros(1, n);
        counts = zeros(1, n);
        if fid ~= 1 && nargin < 12
            fprintf(1,'Please wait, determining folder file-counts and sizes...000%%\n');
        end
        for ii = 1:n
            [sizes(ii), counts(ii)] = get_folder_size(fullfile(path, dirs(ii).name));
            if fid ~= 1 && nargin < 12
                fprintf(1,'\b\b\b\b\b%03d%%\n', round(ii * 100 / n));
            end
        end

        withinSize = sizes >= sizeLimits(1) & sizes <= sizeLimits(2);
        withinCount = counts >= countLimits(1) & counts <= countLimits(2);
        keepFolders = keepFolders & withinSize & withinCount;

        dirs = dirs(keepFolders);
        folderSizes = sizes(keepFolders);
        folderCounts = counts(keepFolders);

        switch sortBy
            case 'FolderSize'
                [~, order] = sort(folderSizes, 'descend');
            case 'FileCount'
                [~, order] = sort(folderCounts, 'descend');
            case 'None'
                order = 1:numel(dirs);
        end
        dirs = dirs(order);
        folderSizes = folderSizes(order);
        folderCounts = folderCounts(order);

        % Filter files
        files = dir(fullfile(path, fileFilter));
        files = files(~[files.isdir]);

        nDirs = numel(dirs);

        if nargin < 12
            progBase = 0;
            progWidth = 1;
            if fid ~= 1
                fprintf(1,'Please wait, printing tree... 000%%');
            end
        end

        % Print subdirectories
        for ii = 1:nDirs
            sub = dirs(ii);
            sizeStr = '';
            if showSize
                sz = folderSizes(ii);
                sizeStr = sprintf(' [%s (%d Files)]', format_bytes(sz), folderCounts(ii));
            end
            indent = repmat('│   ', 1, base_level + 1);
            fprintf(fid, '%s├── %s/%s\n', indent, sub.name, sizeStr);

            % Calculate new progress range for this subdirectory
            subProgBase = progBase + (ii - 1) / nDirs * progWidth;
            subProgWidth = progWidth / nDirs;

            if base_level + 1 <= max_levels
                write_tree(fullfile(path, sub.name), fid, base_level + 1, max_levels, ...
                    fileFilter, folderFilterParts, showSize, sizeLimits, ...
                    countLimits, sortBy, printFiles, subProgBase, subProgWidth);
            end

            % Print progress after each subdir
            pct = round((subProgBase + subProgWidth) * 100);
            if fid ~= 1
                fprintf(1, '\b\b\b\b\b%03d%%\n', pct);
            end
        end

        % Print files
        if printFiles
            % Apply FileExcluder patterns
            if ~isempty(options.FileExcluder)
                fileNames = {files.name};
                excludeMatches = false(size(fileNames));
                for jj = 1:numel(options.FileExcluder)
                    pat = wildcard2regexp(options.FileExcluder(jj));
                    excludeMatches = excludeMatches | ~cellfun(@isempty, regexp(fileNames, pat, 'once'));
                end
                files = files(~excludeMatches);
            end

            for ii = 1:numel(files)
                is_last = (ii == numel(files));
                connector = '└── ';
                if ~is_last
                    connector = '├── ';
                end
                indent = repmat('│   ', 1, base_level + 1);
                fprintf(fid, '%s%s%s\n', indent, connector, files(ii).name);
            end
        elseif isempty(dirs)
            fprintf(fid, '%s└── [no subfolders]\n', repmat('│   ', 1, base_level + 1));
        end
    end

    function [sz, count] = get_folder_size(p)
        persistent sizeCache

        if isempty(sizeCache)
            sizeCache = containers.Map('KeyType', 'char', 'ValueType', 'any');
        end

        % Normalize path without slow Java call
        p = char(fullfile(p));  % keep platform-native slashes
        if isKey(sizeCache, p)
            result = sizeCache(p);
            sz = result(1);
            count = result(2);
            return;
        end

        d = dir(p);
        files = d(~[d.isdir]);
        sz = sum([files.bytes]);
        count = numel(files);

        subdirs = d([d.isdir] & ~ismember({d.name}, {'.','..'}));
        for ii = 1:numel(subdirs)
            [sub_sz, sub_count] = get_folder_size(fullfile(p, subdirs(ii).name));
            sz = sz + sub_sz;
            count = count + sub_count;
        end

        sizeCache(p) = [sz, count];
    end


    function out = format_bytes(b)
        % Convert bytes to human-readable string
        if b < 1024
            out = sprintf('%d B', b);
        elseif b < 1024^2
            out = sprintf('%.1f KB', b/1024);
        elseif b < 1024^3
            out = sprintf('%.1f MB', b/1024^2);
        else
            out = sprintf('%.2f GB', b/1024^3);
        end
    end

    function rgx = wildcard2regexp(wildcard)
        rgx = regexptranslate('wildcard', wildcard);
    end

end