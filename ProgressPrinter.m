classdef ProgressPrinter < handle
%UTILS.PROGRESSPRINTER  A tqdm-like %-complete indicator for long loops.
%
%   Encapsulates the repo's standard in-place "%03d%%" progress convention (the
%   `fprintf(1,'\b\b\b\b\b%03d%%\n', round(100*k/N))` idiom used throughout
%   batch_decomp_export_*, batch_covariance, add_trial_axis_metrics, ...), so a loop
%   that may run for more than a minute or so can tell the user how far along it is
%   -- and therefore whether a long pause is progress or a hang.
%
%   MATLAB has no iterator protocol, so this cannot wrap the loop the way Python's
%   tqdm wraps an iterable.  It is instead a tiny stateful handle you tick once per
%   iteration:
%
%       p = utils.progress(N, "Decomposing blocks");   % prints "Decomposing blocks... 000%"
%       for k = 1:N
%           ... work ...
%           p.update(k);                                % overwrites in place -> 017%, 034%, ...
%       end
%       p.done();                                       % clamps to 100% and newlines
%
%   `update` reprints only when the integer percent changes, so it is cheap to call
%   every iteration even when N is large.
%
%   Convenience:
%       p = utils.progress(N);            % no label
%       p.update();                       % auto-increment (k = previous + 1)
%       p.done("saved 42 units");         % optional closing message
%
%   Design notes / conventions (see AGENTS.md "Progress indicators"):
%     * Add an indicator to ANY loop expected to take more than ~1 minute, or whose
%       per-iteration cost is unpredictable (per-block decomposition, per-file HDF5
%       reads, bootstrap resampling).  A short, fast loop does not need one.
%     * Prints to fid 1 (stdout) and honours a Verbose/Quiet flag via the `Enabled`
%       property, so a function can pass its own `opts.Verbose` straight through.
%     * It writes control characters (\b) that only render in an interactive Command
%       Window.  In a diary/log or -batch run set Enabled=false, or accept that the
%       backspaces appear literally (harmless, just noisy) -- matching how the
%       existing scripts behave.
%
%   See also: utils.progress, batch_covariance, decompose_gesture_units.

    properties
        N       (1,1) double = 1     % total iterations
        Label   (1,1) string = ""    % text printed once before the counter
        Enabled (1,1) logical = true % false -> a no-op (for -batch / Quiet callers)
        Fid     (1,1) double = 1     % output stream
    end

    properties (Access = private)
        lastPct   (1,1) double = -1  % last integer percent printed (-1 = not started)
        counter   (1,1) double = 0   % auto-increment position for update() with no arg
        started   (1,1) logical = false
        seedWidth (1,1) double = 5   % backspaces to erase "NNN%" plus one (repo idiom)
    end

    methods
        function obj = ProgressPrinter(N, label, opts)
            arguments
                N (1,1) double {mustBePositive, mustBeInteger}
                label (1,1) string = ""
                opts.Enabled (1,1) logical = true
                opts.Fid (1,1) double = 1
            end
            obj.N = N;
            obj.Label = label;
            obj.Enabled = opts.Enabled;
            obj.Fid = opts.Fid;
        end

        function update(obj, k)
            %UPDATE  Tick the counter to iteration k (or auto-increment if omitted).
            if nargin < 2
                obj.counter = obj.counter + 1;
                k = obj.counter;
            else
                obj.counter = k;
            end
            if ~obj.Enabled, return; end
            if ~obj.started, obj.start(); end
            pct = min(100, max(0, round(100 * k / obj.N)));
            if pct == obj.lastPct, return; end     % only redraw on a change
            obj.lastPct = pct;
            fprintf(obj.Fid, '\b\b\b\b\b%03d%%\n', pct);
        end

        function done(obj, msg)
            %DONE  Clamp to 100% and (optionally) print a closing message.
            arguments
                obj
                msg (1,1) string = ""
            end
            if ~obj.Enabled, return; end
            if ~obj.started, obj.start(); end
            if obj.lastPct ~= 100
                fprintf(obj.Fid, '\b\b\b\b\b%03d%%\n', 100);
                obj.lastPct = 100;
            end
            if strlength(msg) > 0
                fprintf(obj.Fid, '  %s\n', msg);
            end
        end
    end

    methods (Access = private)
        function start(obj)
            %START  Seed the display: "<label>... 000%" so the first \b's land right.
            obj.started = true;
            if strlength(obj.Label) > 0
                fprintf(obj.Fid, '%s... 000%%\n', obj.Label);
            else
                fprintf(obj.Fid, '000%%\n');
            end
            obj.lastPct = 0;
        end
    end
end
