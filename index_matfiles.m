function index_matfiles(folderPath, options)
%INDEX_MATFILES Create a structured index of all .mat files in a folder
%   index_matfiles('path/to/folder', options) writes matfile-index.txt with
%   the contents (variable structure) of each .mat file in the folder.
%   - options.ExpandStruct = true/false, whether to load and expand structs

arguments
    folderPath (1,1) string {mustBeFolder}
    options.ExpandStruct (1,1) logical = true
end

matFiles = dir(fullfile(folderPath, '*.mat'));
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
            isLastVar = (i == numel(vars));
            print_variable_tree(fid, fullPath, vars(i), 1, isLastVar, options);
        end
    catch ME
        fprintf(fid, '   [!] Failed to read %s: %s\n', fileName, ME.message);
    end
end

fclose(fid);
fprintf('Index written to: %s\n', outFile);
end

function print_variable_tree(fid, matFilePath, varInfo, indentLevel, isLast, options)
branch = ternary(isLast, '└── ', '├── ');
prefix = repmat('   ', 1, indentLevel);
fprintf(fid, '|%s%s%s [%s %s]\n', prefix, branch, varInfo.name, ...
    size2str(varInfo.size), varInfo.class);

if options.ExpandStruct && strcmp(varInfo.class, 'struct') && (prod(varInfo.size)==1)
    % Try to load only that variable to inspect fields
    try
        s = load(matFilePath, varInfo.name);
        val = s.(varInfo.name);
        info = structfun(@(x) struct('size', size(x), 'class', class(x)), val, 'UniformOutput', false);
        fnames = fieldnames(val);
        
        for j = 1:numel(fnames)
            isLastField = (j == numel(info));

            subBranch = ternary(isLastField, '└── ', '├── ');
            subPrefix = repmat('   ', 1, indentLevel+1);
            fval = val.(fnames{j});
            fsize = size2str(size(fval));
            fclass = class2str(class(fval));
            fprintf(fid, '|%s%s%s [%s %s]\n', subPrefix, subBranch, fnames{j}, fsize, fclass);
            if isstruct(fval)
                fnames_s = fieldnames(fval);
                for k = 1:numel(fnames_s)
                    subBranch2 = ternary(isLastField, '└── ', '├── ');
                    fval2 = fval.(fnames_s{k});
                    fsize2 = size2str(size(fval2));
                    fclass2 = class2str(class(fval2));
                    fprintf(fid, '|%s|   %s%s [%s %s]\n',subPrefix, subBranch2, fnames_s{k}, fsize2, fclass2);
                end
            end
        end
    catch
        subPrefix = repmat('   ', 1, indentLevel);
        fprintf(fid, '%|s└── [Could not load struct fields]\n', subPrefix);
    end
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

function out = ternary(cond, a, b)
if cond, out = a; else, out = b; end
end
