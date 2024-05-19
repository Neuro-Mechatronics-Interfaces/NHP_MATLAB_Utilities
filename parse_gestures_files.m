function T = parse_gestures_files(gestures_folder, options)
%PARSE_GESTURES_FILES  Parses folder containing Gestures GUI poly5 files
%
% Example
%   GESTURES_FOLDER = "D:\Data\Shared\MCP04_2024_05_16\TMSi Data\Gestures GUI";
%   T = utils.parse_gestures_files(GESTURES_FOLDER);

arguments
    gestures_folder {mustBeTextScalar, mustBeFolder}
    options.TrialOrder = [];
    options.TrialOrderFileExpr = 'trial_order*.csv';
    options.OutputPrefix = "Gestures GUI";
end

if isempty(options.TrialOrder)
    F = dir(fullfile(gestures_folder,options.TrialOrderFileExpr));
    if isempty(F)
        error("No files in %s met expression (%s)", gestures_folder, options.TrialOrderFileExpr);
    end
    fid = fopen(fullfile(F(1).folder, F(1).name),'r');
    s = textscan(fid,'%s','Delimiter','\r\n');
    s = string(s{1});
else
    s = options.TrialOrder;
end
u = unique(s);
n = zeros(size(u));
FlexorFile = strings(size(s));
ExtensorFile = strings(size(s));
for iS = 1:numel(s)
    iCounter = u==s(iS);
    n(iCounter) = n(iCounter) + 1;
    F = dir(fullfile(gestures_folder, s(iS), '*dev1*.poly5'));
    time_number = nan(numel(F),1);
    for ii = 1:numel(F)
        [~,f,~] = fileparts(F(ii).name);
        finfo = strsplit(f,'_');
        time_number(ii) = str2double(finfo{end});
    end
    [~, i_orig] = sort(time_number,'ascend');
    FlexorFile(iS) = sprintf('%s/%s/%s', options.OutputPrefix, s(iS), F(i_orig(n(iCounter))).name);
    E = dir(fullfile(gestures_folder, s(iS), '*dev2*.poly5'));
    time_number = nan(numel(E),1);
    for ii = 1:numel(E)
        [~,f,~] = fileparts(E(ii).name);
        finfo = strsplit(f,'_');
        time_number(ii) = str2double(finfo{end});
    end
    [~, i_orig] = sort(time_number,'ascend');
    ExtensorFile(iS) = sprintf('%s/%s/%s', options.OutputPrefix, s(iS), E(i_orig(n(iCounter))).name);
end
T = table(FlexorFile, ExtensorFile);
end