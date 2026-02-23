function [nRows, nCols, idxKeep] = get_limited_layout(nCh, maxRows, maxCols)

if nargin < 2
    maxRows = 4;
end
if nargin < 3
    maxCols = 2;
end

maxPanels = maxRows * maxCols;

if nCh <= maxPanels
    idxKeep = 1:nCh;
else
    % Stratified subsampling across full index range
    idxKeep = round(linspace(1, nCh, maxPanels));
    idxKeep = unique(idxKeep); % safety
end

nKeep = numel(idxKeep);

% Compute layout respecting max rows/cols
nCols = min(maxCols, ceil(nKeep / maxRows));
nRows = ceil(nKeep / nCols);

end