function [h_str, t_str, p_str, f]  = get_block_pattern(SUBJ, YYYY, MM, DD, ARRAY, BLOCK, n, tag, varargin)
%GET_BLOCK_PATTERN  Return the string corresponding to a given block
%
% Syntax:
%   h_str = get_block_pattern(SUBJ, YYYY, MM, DD, ARRAY, BLOCK);
%   [h_str, t_str] = get_block_pattern(SUBJ, YYYY, MM, DD, ARRAY, BLOCK, n);
%   [h_str, t_str, p_str] = get_block_pattern(SUBJ, YYYY, MM, DD, ARRAY, BLOCK, n, tag);
%   [_, f] = get_block_pattern(___, 'Name', value, ...);
%
% Inputs:
%   SUBJ  - Subject name (e.g. 'Frank' or "Frank")
%   YYYY  - Year (numeric or string, e.g. 2021 or "2021" or '2021')
%   MM    - Month (numeric or string, e.g. 11 or "11" or '11')
%   DD    - Day   (numeric or string, e.g. 18 or "18" or '18')
%   ARRAY - "A" or "B" (or 'A' or 'B') or ["A", "B"] or {'A', 'B'}
%   BLOCK - Recording parameter key (block; numeric or string, e.g. 0 or "0")
%   n - (Optional) -- Arbitrary "number" integer for showing (N = %d) part
%   tag - (Optional) -- Tag to append to header string
%   varargin - (Optional) -- 'Name', value pairs
%
% Output:
%   h_str - String title "header" for a given block.
%   t_str - String title "header" for axes title.
%   p_str - String title "header" for powerpoint slide.
%   f     - Filename struct with fields for 'Tank', 'Block' etc.
%
% See also: Contents, plot_emg_averages, plot_emg_rms

pars = struct;
pars.Amplitude_Parameter = 'Current';
pars.Amplitude_Units = 'mA';
pars = parse_parameters(pars, varargin{:});

if nargin < 7
    n = []; 
end

if nargin < 8
    if ischar(n) || isstring(n)
        tag = n;
        n = [];
    else
        tag = '';
    end
else
    tag = char(tag);
end

[YYYY, MM, DD] = parse_date_args(YYYY, MM, DD);

tank = sprintf('%s_%04d_%02d_%02d', SUBJ, YYYY, MM, DD);
block = char(sprintf('%s_%s_%d', tank, ARRAY, BLOCK));
[meta, Stim] = getMetadata(fullfile('R:/NMLShare/raw_data/primate', SUBJ, tank, [block '.Poly5']));

if ~isempty(tag)
    if ~isempty(n)
        str = [strrep(block, '_', '\_'), ': ' strrep(Stim.site, '_', '\_') newline ...
                sprintf('(Max %s: ', pars.Amplitude_Parameter) num2str(Stim.pulseAmp, '%.2f')   sprintf(' %s | ', pars.Amplitude_Units) tag ' | N = ' char(num2str(n))  ')'];
    else
        str = [strrep(block, '_', '\_'), ': ' strrep(Stim.site, '_', '\_') newline ...
                sprintf('(Max %s: ', pars.Amplitude_Parameter) num2str(Stim.pulseAmp, '%.2f')   sprintf(' %s | ', pars.Amplitude_Units) tag ')'];
    end
else
    if ~isempty(n)
        str = [strrep(block, '_', '\_'), ': ' strrep(Stim.site, '_', '\_') newline ...
                sprintf('(Max %s: ', pars.Amplitude_Parameter) num2str(Stim.pulseAmp, '%.2f')   sprintf(' %s | N = ', pars.Amplitude_Units) char(num2str(n))  ')'];
    else
        str = [strrep(block, '_', '\_'), ': ' strrep(Stim.site, '_', '\_') newline ...
                sprintf('(Max %s: ', pars.Amplitude_Parameter) num2str(Stim.pulseAmp, '%.2f')   sprintf(' %s)', pars.Amplitude_Units)];
    end
end

h_str = string(strrep(str, '\', ''));
t_str = str;
base = char(h_str);

f = struct;
f.Date = sprintf('%04d_%02d_%02d', YYYY, MM, DD);
f.Tank = tank;
f.Block = block;

k = regexp(base, sprintf('%04d_%02d_%02d', YYYY, MM, DD)) + 11; % Find first index for "shortening" the string.
str_base_short = string(base(k:end));
str_base_short = strsplit(str_base_short, ':');
bn = strsplit(str_base_short{1}, '_');
p_str = char(strjoin([bn(2), strip(meta.raw.Notes, '.')], ' :: '));
p_str = string([p_str, ' :: ', char(strjoin(str_base_short(2:end), ':'))]);
clipboard('copy', p_str);
end