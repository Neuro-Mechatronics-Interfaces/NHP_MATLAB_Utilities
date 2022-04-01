function interpsmooth(ax, x, y, tag)
%INTERPSMOOTH This function interpolates and smoothes a curve onto data points
if nargin < 4
    tag = 'Data'; 
end

[x, idx] = unique(x);
y = y(idx);

xx = linspace(x(1), x(end), numel(x)*10);
yy = interp1(x, y, xx, 'spline');

set(ax, 'NextPlot', 'add');
h = line(ax, x, y, 'Marker', 'o', 'LineStyle', 'none', 'Color', 'k');

h.Annotation.LegendInformation.IconDisplayStyle = 'off';
plot(ax, xx, yy, 'LineWidth', 1.5, 'DisplayName', tag);

legend(ax, 'Location', 'best');
end