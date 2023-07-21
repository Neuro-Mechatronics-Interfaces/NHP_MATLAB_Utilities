function transfer_plexon_files(options)
%TRANSFER_PLEXON_FILES Transfer files from local location to remote data share
%
% Syntax:
%   utils.transfer_plexon_files('Name',value,...);
%
% Options:
%   LocalFolder - 'logs' folder in current folder is the default.
%   EventExtension - '.uevt'
arguments
    options.LocalEventFolder {mustBeTextScalar, mustBeFolder} = fullfile(pwd, 'logs')
    options.LocalPlexonFolder {mustBeTextScalar, mustBeFolder} = "D:/PlexonData";
    options.EventExtension {mustBeTextScalar} = '.uevt'
end

F = dir(fullfile(options.LocalEventFolder, strcat("*", options.EventExtension)));
for iF = 1:numel(F)
    % 1. Get the file metadata from the filename
    [~,finfo,~] = fileparts(F(iF).name);
    finfo = strsplit(finfo, '_');
    subj = lower(char(finfo{1}));
    subj(1) = upper(subj(1)); % Fix capitalization
    yyyy = finfo{2};
    mm = finfo{3};
    dd = finfo{4};
    ornt = finfo{5};
    tank = sprintf('%s_%s_%s_%s', subj, yyyy, mm, dd);
    outfolder_root = fullfile("R:\NMLShare\raw_data\primate", subj, tank);
    if exist(outfolder_root, 'dir')==0
        mkdir(outfolder_root);
    end
    % 2. Make a space where the PLEXON (.pl2, .plx, .txt) data files will go
    %       on the raptor data share. If there are local plexon data files 
    %       for this subject, then copy them over one at a time and delete 
    %       the local copies when finished copying.
    P = dir(fullfile(options.LocalPlexonFolder, subj, sprintf('%s_PLEX_*%s%s%s*.*', upper(subj), mm, dd, yyyy)));
    if numel(P) > 0
        outfolder_plex = fullfile(outfolder_root, sprintf('%s_PLEX', tank));
        if exist(outfolder_plex, 'dir')==0
            mkdir(outfolder_plex);
        end
        for iP = 1:numel(P)
            fprintf(1,'Moving PLEX FILE: <strong>%s</strong>...', P(iP).name);
            copyfile(fullfile(P(iP).folder, P(iP).name), fullfile(outfolder_plex, P(iP).name));
            delete(fullfile(P(iP).folder, P(iP).name));
            fprintf(1,'complete.\n');
        end
    end
    % 3. Make a space where the EVENT data files (.uevt)
    outfolder_events = fullfile(outfolder_root, sprintf('%s_EVENTS', tank));
    if exist(outfolder_events, 'dir')==0
        mkdir(outfolder_events);
    end
    fprintf(1,'Moving EVENT FILE: <strong>%s</strong>...', F(iF).name);
    copyfile(fullfile(F(iF).folder, F(iF).name), fullfile(outfolder_events, sprintf('%s_%s_%s_%s_%s.uevt', subj, yyyy, mm, dd, ornt)));
    delete(fullfile(F(iF).folder, F(iF).name));
    fprintf(1,'complete.\n');
end

end