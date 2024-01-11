function transfer_uevt_files(options)
%TRANSFER_UEVT_FILES Transfer *.uevt files (only) from local location to remote data share
%
% Syntax:
%   utils.transfer_uevt_files('Name',value,...);
%
% Options:
%     options.LocalEventFolder {mustBeTextScalar, mustBeFolder} = fullfile(pwd, 'logs');
%     options.EventExtension {mustBeTextScalar} = '.uevt';
%     options.RemoteFolderRoot {mustBeTextScalar,mustBeFolder} = "R:/NMLShare/raw_data/primate";
%
% See also: Contents, utils.transfer_plexon_files, TASK_CreateUDPClient (Plexon_Tools/Online)
arguments
    options.LocalEventFolder {mustBeTextScalar, mustBeFolder} = fullfile(pwd, 'logs');
    options.EventExtension {mustBeTextScalar} = '.uevt';
    options.RemoteFolderRoot {mustBeTextScalar,mustBeFolder} = "R:/NMLShare/raw_data/primate"; % (Because .uevt files are small, this is fine since it is easy to transfer directly to the remote datashare despite slow Wi-Fi connection on Plexon rig computer) 
    options.RemoteFolderSubfolder cell = {};
end

fclose("all");
F = dir(fullfile(options.LocalEventFolder, strcat("*", options.EventExtension)));
for iF = 1:numel(F)
    % 1. Get the file metadata from the filename
    [~,finfo,~] = fileparts(F(iF).name);
    f_parts = strsplit(finfo, '_');
    subj = lower(char(f_parts{1}));
    subj(1) = upper(subj(1)); % Fix capitalization
    yyyy = f_parts{2};
    mm = f_parts{3};
    dd = f_parts{4};
    ornt = f_parts{5};
    tank = sprintf('%s_%s_%s_%s', subj, yyyy, mm, dd);
    outfolder_root = fullfile(options.RemoteFolderRoot, subj, options.RemoteFolderSubfolder{:}, tank);
    if exist(outfolder_root, 'dir')==0
        mkdir(outfolder_root);
    end

    % 2. Make a space where the EVENT data files (.uevt)
    outfolder_events = fullfile(outfolder_root, sprintf('%s_EVENTS', tank));
    if exist(outfolder_events, 'dir')==0
        mkdir(outfolder_events);
    end
    fprintf(1,'Moving EVENT FILE: %s...', F(iF).name);
    copyfile(fullfile(F(iF).folder, F(iF).name), fullfile(outfolder_events, sprintf('%s_%s_%s_%s_%s.uevt', subj, yyyy, mm, dd, ornt)));
    delete(fullfile(F(iF).folder, F(iF).name));
    fprintf(1,'complete.\n');
end

end