function [Z2, labels2, meta] = pca_project_top2(t, X, featLabels, outMetaFile, opts)
%PCA_PROJECT_TOP2  Compute top-2 PCA projection time-series from multichannel data.
%
%   Z2:        T x 2 projected time series [PC1 PC2]
%   labels2:   1 x 2 labels ["PC1","PC2"]
%   meta:      struct with PCA metadata (coeff, explained, mu, sigma, etc.)
%
% Notes
% - Uses z-scoring by default so channels with different units don't dominate PCA.
% - Saves meta to outMetaFile (optional). If outMetaFile == "", no save.

arguments
    t
    X double
    featLabels string = string.empty
    outMetaFile {mustBeTextScalar} = ""
    opts.ZScore logical = true
    opts.NumComponents (1,1) double {mustBeInteger,mustBePositive} = 2
    opts.HandleNaN string {mustBeMember(opts.HandleNaN,["omitrows","fill"])} = "fill"
end

% Ensure T x C
if size(X,1) ~= numel(t)
    X = X';
end

% Handle NaNs
X0 = X;
switch opts.HandleNaN
    case "omitrows"
        good = all(isfinite(X0),2);
        X0 = X0(good,:);
        t0 = t(good);
    case "fill"
        % simple forward-fill then backward-fill per column
        t0 = t;
        for c = 1:size(X0,2)
            xc = X0(:,c);
            if any(~isfinite(xc))
                xc = fillmissing(xc,'previous');
                xc = fillmissing(xc,'next');
            end
            X0(:,c) = xc;
        end
end

% Z-score (recommended when mixing units)
if opts.ZScore
    mu = mean(X0,1,'omitnan');
    sig = std(X0,0,1,'omitnan');
    sig(sig==0) = 1;
    Xn = (X0 - mu) ./ sig;
else
    mu = mean(X0,1,'omitnan');
    sig = ones(1,size(X0,2));
    Xn = X0 - mu;
end

% PCA
[coeff, score, latent, ~, explained] = pca(Xn, ...
    'Algorithm','svd', ...
    'NumComponents', opts.NumComponents);

% score is N x 2 corresponding to t0 rows.
Z2 = score(:,1:2);
labels2 = ["PC1","PC2"];

meta = struct();
meta.coeff = coeff;
meta.latent = latent;
meta.explained = explained;
meta.mu = mu;
meta.sigma = sig;
meta.feature_labels = featLabels;
meta.zscore = opts.ZScore;

% If we used omitrows, we return shortened Z2; caller should keep this in mind.
meta.time_numel_in = numel(t);
meta.time_numel_used = size(Z2,1);
meta.omitrows = (opts.HandleNaN == "omitrows");

if strlength(outMetaFile) > 0
    outDir = fileparts(outMetaFile);
    if ~isempty(outDir) && ~isfolder(outDir)
        mkdir(outDir);
    end
    save(outMetaFile, "meta");
end
end