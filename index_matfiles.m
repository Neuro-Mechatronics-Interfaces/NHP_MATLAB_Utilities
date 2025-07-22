function index_matfiles(folderPath)
%INDEX_MATFILES Create a structured index of all .mat files in a folder
%   index_matfiles('path/to/folder') writes matfile-index.txt with the
%   contents (variable structure) of each .mat file in the folder.

arguments
    folderPath (1,1) string {mustBeFolder}
end

% Get list of .mat files in folder
matFiles = dir(fullfile(folderPath, '*.mat'));

% Open output file
outFile = fullfile(folderPath, 'matfile-index.txt');
fid = fopen(outFile, 'w');
if fid == -1
    error('Failed to open output file for writing: %s', outFile);
end

fprintf(fid, 'MAT File Index for folder:\n%s\n\n', folderPath);

for k = 1:numel(matFiles)
    fileName = matFiles(k).name;
    fullPath = fullfile(folderPath, fileName);
    fprintf(fid, '├── %s\n', fileName);
    try
        m = matfile(fullPath);
        vars = whos(m);
        for i = 1:numel(vars)
            print_variable_tree(fid, vars(i), 1, i==numel(vars));
        end
    catch ME
        fprintf(fid, '   [!] Failed to read %s: %s\n', fileName, ME.message);
    end
end

fclose(fid);
fprintf('Index written to: %s\n', outFile);
end

function print_variable_tree(fid, varInfo, indentLevel, isLast)
prefix = repmat('    ', 1, indentLevel);
if isLast
    fprintf(fid, '│%s└── %s [%s %s]\n', prefix, varInfo.name, ...
        size2str(varInfo.size), class2str(varInfo.class));
else
    fprintf(fid, '│%s├── %s [%s %s]\n', prefix, varInfo.name, ...
        size2str(varInfo.size), class2str(varInfo.class));
end
end

function str = size2str(sz)
str = sprintf('%dx', sz);
str = str(1:end-1);
end

function str = class2str(cl)
if ischar(cl)
    str = cl;
else
    str = class(cl);
end
end

function mustBeFolder(f)
if ~isfolder(f)
    error('Input must be a valid folder path.');
end
end
