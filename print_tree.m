function print_tree(options)
%PRINT_TREE Create a tree-like directory structure printout.
%
% Options:
%   'Start': The starting folder for parsing tree path.
%   'OutputFile': Output file. Default: prints to Command Window.
%   'Root': Path for relative indentation. Default: same as Start.
%   'MaxDepth': Max recursion depth. Default: inf.
%   'FileFilter': Wildcard pattern for files. Default: '*.*'
%   'FolderFilter': Slash-delimited per-level wildcard (e.g. '*/Data')
%   'PrintFolderSize': Logical, if true appends folder size to printout
%   'FolderSizeLim': [minBytes maxBytes], size filter on folders (in GB)

arguments
    options.Start {mustBeTextScalar} = pwd;
    options.OutputFile {mustBeTextScalar} = "";
    options.Root {mustBeTextScalar} = "";
    options.MaxDepth {mustBePositive} = inf;
    options.FileFilter {mustBeTextScalar} = "*.*";
    options.FolderFilter {mustBeTextScalar} = "*";
    options.PrintFolderSize (1,1) logical = true;
    options.PrintFiles (1,1) logical = true;
    options.FolderSizeLim (1,2) double = [-inf, inf];
    options.FolderFileCountLim (1,2) double = [-inf, inf];
    options.SortBy {mustBeMember(options.SortBy, {'FolderSize', 'FileCount', 'None'})} = 'FolderSize';
end

outfile = options.OutputFile;
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

clear get_folder_size
write_tree(startpath, fid, numel(relative_parts), options.MaxDepth, ...
    options.FileFilter, folderFilterParts, options.PrintFolderSize, ...
    options.SortBy, options.PrintFiles,  ...
    folderSizeLimInBytes, options.FolderFileCountLim);


if printFile
    fclose(fid);
    fprintf('Pretty tree written to %s\n', outfile);
end

    function write_tree(path, fid, base_level, max_levels, fileFilter, ...
        folderFilterParts, showSize, sizeLimits, countLimits, sortBy, ...
        printFiles, progBase, progWidth)

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