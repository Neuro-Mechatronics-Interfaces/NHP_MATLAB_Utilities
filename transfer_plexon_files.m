function transfer_plexon_files(options)
%TRANSFER_PLEXON_FILES Transfer files from local location to remote data share
%
% Syntax:
%   utils.transfer_plexon_files('Name',value,...);
%
% Options:
%     options.LocalEventFolder {mustBeTextScalar, mustBeFolder} = fullfile(pwd, 'logs')
%     options.LocalPlexonFolder {mustBeTextScalar, mustBeFolder} = "D:/PlexonData"
%     options.LocalTMSiFolder {mustBeTextScalar, mustBeFolder} = "D:/TMSi/MATLAB"
%     options.EventExtension {mustBeTextScalar} = '.uevt'
%     options.RemoteFolderRoot {mustBeTextScalar,mustBeFolder} = "R:/NMLShare/raw_data/primate";
%
% See also: Contents, TASK_CreateUDPClient (Plexon_Tools/Online)
arguments
    options.LocalEventFolder {mustBeTextScalar, mustBeFolder} = fullfile(pwd, 'logs')
    options.LocalPlexonFolder {mustBeTextScalar, mustBeFolder} = "D:/PlexonData"
    options.LocalTMSiFolder {mustBeTextScalar, mustBeFolder} = "D:/TMSi/MATLAB/raw_data"
    options.LocalTRecFolder {mustBeTextScalar, mustBeFolder} = "D:/TREC/Logs/Position"
    options.EventExtension {mustBeTextScalar} = '.uevt'
    options.RemoteFolderRoot {mustBeTextScalar,mustBeFolder} = "R:/NMLShare/raw_data/primate";
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
    outfolder_root = fullfile(options.RemoteFolderRoot, subj, tank);
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
            copyfile(fullfile(P(iP).folder, P(iP).name), fullfile(outfolder_plex, strrep(P(iP).name, upper(subj), subj)));
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
    % 4. Copy the SAGA data files over to remote (.mat)
    S = dir(fullfile(options.LocalTMSiFolder, subj, sprintf('%s_%s_%s_%s_%s_*.mat',subj,yyyy,mm,dd,ornt)));
    if numel(S) > 0
        for iS = 1:numel(S)
            fprintf(1,'Moving TMSI FILE: <strong>%s</strong>...', S(iS).name);
            copyfile(fullfile(S(iS).folder,S(iS).name), fullfile(outfolder_root, S(iS).name));
            delete(fullfile(S(iS).folder,S(iS).name));
            fprintf(1,'complete.\n');
        end
    end
    % 5. Copy the TREC files over to remote (.csv)
    T = dir(fullfile(options.LocalTRecFolder, '*Position.csv'));
    if numel(T) > 0
        outfolder_trec = fullfile(outfolder_root, sprintf('%s_TREC', tank));
        if exist(outfolder_trec, 'dir')==0
            mkdir(outfolder_trec);
        end
        for iT = 1:numel(T)
            fprintf(1,'Moving TREC FILE: <strong>%s</strong>...', T(iT).name);
            copyfile(fullfile(T(iT).folder,T(iT).name), fullfile(outfolder_trec, T(iT).name));
            delete(fullfile(T(iT).folder,T(iT).name));
            fprintf(1,'complete.\n');
        end
    end
end

end