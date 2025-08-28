function outPath = concat_mfiles(inFile, options)
%CONCAT_MFILES Concatenate the text of a target MATLAB file and
% other files from specified folders/extensions into a single output .m file.
%
% outPath = utils.concat_mfiless(inFile, Name=Value, ...)
%
% Required
%   inFile    - Full filepath to a MATLAB function/script, OR a bare filename.
%               If no path is included, the file is assumed to reside in pwd.
%
% Name-Value options (parsed into `options` via arguments block):
%   OutputFile                 string    = "_m_.concatenated"
%   ExtraFolders               string    = string.empty(1,0)  % additional folders to search
%   Extensions                 string    = ".m"               % which file extensions to include
%   ExplicitIncludeFiles       string   (default is empty; set as (1,:) list of explicit files to include; if set, ignores other folder contents)
%   IncludeFilesInInputRoot    logical   = true               % include files from inFile's folder
%   Verbose                    logical   = true
%
% Behavior
%   (1) Writes the text from the indicated file to OutputFile (overwrites).
%   (2) Discovers other files from (input root if enabled) and ExtraFolders
%       whose extensions match Extensions.
%   (3) Appends their text to the end of OutputFile (skipping the primary file).
%
% Returns
%   outPath   - Full path to the generated output file.
%
% Example
%   % Minimal (writes to <input-folder>/mFileContents.m):
%   concat_mfile_contents("myfun.m");
%
%   % Custom name placed in the same folder as input file (no path in OutputFile):
%   concat_mfile_contents("C:\proj\utils\myfun.m", OutputFile="bundle.m");
%
%   % Add more folders and extensions:
%   concat_mfile_contents("myfun.m", ...
%       ExtraFolders=["src","include"], ...
%       Extensions=[".m",".mlx",".md"], ...
%       IncludeFilesInInputRoot=true, ...
%       Verbose=true);
%
% Notes
%   - Search is non-recursive within each folder.
%   - If OutputFile includes a path, it’s honored; otherwise it’s placed in
%     the input file’s folder.
%   - Duplicate files (same fullpath) are de-duplicated; the primary file is
%     always written first and not re-appended later.

arguments
    inFile (1,1) string
    options.OutputFile (1,1) string = "_m_.concatenated"
    options.ExtraFolders (1,:) string = string.empty(1,0)
    options.Extensions (1,:) string = ".m"
    options.ExplicitIncludeFiles (1,:) string = strings(1,0);
    options.IncludeFilesInInputRoot (1,1) logical = true
    options.Verbose (1,1) logical = true
end

vprint = @(varargin) (options.Verbose && fprintf(varargin{:}));

% ---- Resolve input path ----
[inPath, inName, inExt] = fileparts(inFile);
if strlength(inPath) == 0
    % Bare filename: assume in pwd
    inPath = string(pwd);
    inFull = fullfile(inPath, inFile);
else
    inFull = inFile;
end
inFull = string(inFull);

if ~isfile(inFull)
    error('concat_mfile_contents:InputNotFound', ...
        'Input file not found: %s', inFull);
end

% ---- Normalize extensions (ensure they start with ".") ----
exts = options.Extensions(:);
exts = unique( arrayfun(@(e) ensureDotPrefix(e), exts, 'UniformOutput', true) );

% ---- Build folder list ----
folders = string.empty(0,1);
if isempty(options.ExplicitIncludeFiles)
    if options.IncludeFilesInInputRoot
        folders(end+1,1) = inPath;
    end
    if ~isempty(options.ExtraFolders)
        folders = [folders; options.ExtraFolders(:)];
    end
    % Make absolute paths where possible (relative paths are resolved from pwd)
    folders = unique( arrayfun(@(f) string(fullfile(f)), folders, 'UniformOutput', true) );
end

% ---- Determine output path ----
[outDir, outName, outExt] = fileparts(options.OutputFile);
if strlength(outDir) == 0
    % No path provided for OutputFile → place in input root
    outDir = inPath;
elseif ~isfolder(outDir)
    % If a path was provided but doesn't exist, attempt to create it
    vprint('Creating output directory: %s\n', outDir);
    mkdir(outDir);
end
if strlength(outExt) == 0
    % Ensure .m extension if none given
    outExt = ".m";
end
outPath = fullfile(outDir, outName + outExt);

% ---- Step 1: write the primary file (overwrite) ----
primaryHdr = separatorHeader(inFull);
vprint('Writing primary file → %s\n', outPath);
writeText(outPath, sprintf("%s%s",primaryHdr, filereadNative(inFull))); 

% ---- Step 2: discover other files to append ----
% Collect files matching any of the extensions from the chosen folders
toAppend = string.empty(0,1);
if isempty(options.ExplicitIncludeFiles)
    for f = folders.'
        if ~isfolder(f); continue; end
        for ex = exts.'
            listing = dir(fullfile(f, sprintf("*%s",ex)));
            if ~isempty(listing)
                toAppend = [toAppend; string(fullfile({listing.folder}.', {listing.name}.'))]; %#ok<AGROW>
            end
        end
    end
    % De-duplicate and remove the primary file
    toAppend = unique(toAppend);
    toAppend = toAppend(~strcmpi(toAppend, inFull));
else
    toAppend = options.ExplicitIncludeFiles(:);
end

% ---- Step 3: append each discovered file ----
if isempty(toAppend)
    vprint('No additional files found to append.\n');
else
    vprint('Appending %d additional file(s)...\n', numel(toAppend));
    for k = 1:numel(toAppend)
        fp = toAppend(k);
        try
            hdr = separatorHeader(fp);
            appendText(outPath, sprintf("%s%s",hdr,filereadNative(fp)));
            vprint('  + %s\n', fp);
        catch ME
            vprint('  ! Skipping %s (%s)\n', fp, ME.message);
        end
    end
end

vprint('Done. Output written to: %s\n', outPath);

% =====================================================================
% Helpers
% =====================================================================
    function t = filereadNative(fp)
        % fileread with ensured trailing newline
        t = fileread(fp);
        if ~endsWith(t, newline)
            t = [t,newline];
        end
    end

    function writeText(fp, txt)
        fid = fopen(fp, 'w', 'n', 'UTF-8');
        if fid < 0
            error('concat_mfile_contents:OpenFailed', 'Cannot open for writing: %s', fp);
        end
        c = onCleanup(@() fclose(fid));
        fwrite(fid, txt, 'char');
    end

    function appendText(fp, txt)
        fid = fopen(fp, 'a', 'n', 'UTF-8');
        if fid < 0
            error('concat_mfile_contents:OpenFailed', 'Cannot open for appending: %s', fp);
        end
        c = onCleanup(@() fclose(fid));
        fwrite(fid, txt, 'char');
    end

    function s = separatorHeader(fp)
        [p,n,e] = fileparts(fp);
        s = sprintf([ ...
            '%% =====================================================================\n' ...
            '%% File: %s%s\n' ...
            '%% Path: %s\n' ...
            '%% =====================================================================\n\n'], n,e,p);
    end

    function e = ensureDotPrefix(eIn)
        e = string(eIn);
        if e == ""
            e = ".m";
        elseif ~startsWith(e, ".")
            e = sprintf('.%s',e);
        end
    end
end
