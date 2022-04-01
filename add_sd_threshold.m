function [h, th] = add_sd_threshold(ax, n_sd, xdata, ydata, varargin)
%ADD_SD_THRESHOLD  Adds yline threshold to plot using pre-stimulus data
%
% Syntax:
%   h = add_sd_threshold(ax, n_sd);
%   [h, th] = add_sd_threshold(ax, n_sd, xdata, ydata);
%   [h, th] = add_sd_threshold(__, 'Name', value, ...);
%
% Inputs:
%   ax - Axes handle to axes you want to put this on, or array of axes. If
%           given as an array then optional `xdata` and `ydata` arguments 
%           must be cell arrays with one cell per `ax` object.
%   xdata - (Optional) Time or sample vector. If not given, then this is 
%               detected using any object with the Tag "STA" found on the
%               axes object.
%               NOTE: THE STIMULUS IS ASSUMED TO OCCUR AT T == 0;
%                     THEREFORE, THRESHOLD IS COMPUTED USING ANY SAMPLE
%                     INDICES THAT ARE < 0 USING THIS AS AN INDEXING VECTOR
%                     INTO COLUMNS OF YDATA.
%   ydata - (Optional) 1 x nSamples vector of stimulus or event-aligned
%               data samples. If not given, then this is  detected using 
%               any object with the Tag "STA" found on the axes object.
%   n_sd  - Number of standard deviations to multiply the pre-stimulus
%           noise by for generating the threshold line. 
%
% Output:
%   h     - Handle to the yline object
%   th    - The value of the actual threshold
%
% See also: Contents, handleAxesClick, handleCommonWindowKeyPresses

if nargin < 2
    n_sd = 6.5; 
end

if numel(ax) > 1
    h = gobjects(size(ax));
    th = nan(size(ax));
    for ii = 1:numel(ax)
        if nargin < 3
            [h(ii), th(ii)] = add_sd_threshold(ax(ii), n_sd);
        else
            [h(ii), th(ii)] = add_sd_threshold(ax(ii), n_sd, xdata{ii}, ydata{ii}, varargin{:});
        end
    end
    return;
end

if nargin < 3 % Check for a line with 'Tag' property of "STA"
    l = findobj(ax, 'Tag', "STA");
    if isempty(l)
        if isempty(l)
            disp('No object found with TAG property set to STA.');
            h = [];
            th = nan;
            return;
        end
    elseif numel(l) > 1
        warning('Found multiple objects tagged using STA. Only using first element in array.');
        l = l(1);
    end
    % Then, using the XData and YData properties, do the same thing as
    % supplying the inputs manually:
    xdata = l.XData;
    ydata = l.YData;
end

h = findobj(ax.Children, 'Tag', 'threshold');
th = n_sd*std(ydata(xdata < 0)) + mean(ydata(xdata < 0));
if isnan(th)
    th = 0;
end
if isempty(h)
    h = yline(ax, th, ...
        'Color', 'b', 'LineStyle', '--',  ...
        'Label', sprintf('DC + %g SD', n_sd), ...
        'LineWidth', 1.25, ...
        'Tag', 'threshold', ...
        'FontName', 'Tahoma', ...
        'FontWeight', 'bold', ...
        'LabelHorizontalAlignment', 'left', ...
        varargin{:});
else
    delete(h); 
end
        
end