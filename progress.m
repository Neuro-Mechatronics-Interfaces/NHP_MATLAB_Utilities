function p = progress(N, label, opts)
%UTILS.PROGRESS  Make a tqdm-like %-complete indicator for a long loop.
%
%   p = utils.progress(N)
%   p = utils.progress(N, "Decomposing blocks")
%   p = utils.progress(N, "Decomposing blocks", 'Enabled', opts.Verbose)
%
%   A thin factory around utils.ProgressPrinter, so a loop that may run for more than
%   a minute or so can show how far along it is -- the repo's standard "%03d%%"
%   convention, encapsulated.  MATLAB has no iterator protocol, so this cannot wrap
%   the loop; tick it once per iteration instead:
%
%       p = utils.progress(numel(files), "Reading HDF5");
%       for k = 1:numel(files)
%           ... slow work ...
%           p.update(k);
%       end
%       p.done();
%
%   Inputs:
%     N       total number of iterations (positive integer)
%     label   optional text printed once before the counter (default "")
%
%   Name-value:
%     Enabled true (default) to print; pass a function's own opts.Verbose to make the
%             indicator follow the caller's verbosity.  In a -batch / diary run where
%             the backspaces would render literally, pass false.
%     Fid     output stream (default 1 = stdout)
%
%   Returns a handle object with .update(k) and .done(msg) -- see
%   utils.ProgressPrinter for the full contract and the convention note.
%
%   WHEN TO USE ONE (AGENTS.md "Progress indicators"): add an indicator to any loop
%   expected to exceed ~1 minute, or whose per-iteration time is unpredictable
%   (per-block decomposition, per-file reads, bootstrap resampling), so the user can
%   tell a long pause from a hang.  Short, fast loops do not need one.
%
%   See also: utils.ProgressPrinter.

arguments
    N (1,1) double {mustBePositive, mustBeInteger}
    label (1,1) string = ""
    opts.Enabled (1,1) logical = true
    opts.Fid (1,1) double = 1
end

p = utils.ProgressPrinter(N, label, 'Enabled', opts.Enabled, 'Fid', opts.Fid);
end
