function print_model_info(mdl, options)
%PRINT_MODEL_INFO  Prints sfit object model coefficients in Command Window, or to a text file ID (if specified).
%
% Syntax:
%   utils.print_model_info(mdl);
%   utils.print_model_info(mdl, 'fid', fid, ...);
%
% Example:
%   planar_offset = "z_0";
%   gauss_A = "A./(2.*pi.*sigma_xa.*sigma_ya.*sqrt(1-rho_a.^2)).*exp(-(1./(2.*(1 - rho_a.^2))).*(((x - mu_xa)./sigma_xa).^2 + ((y - mu_ya)./sigma_ya).^2 - 2.*rho_a.*(x - mu_xa).*(y - mu_ya)./(sigma_xa.*sigma_ya)))";
%   gauss_B = "B./(2.*pi.*sigma_xb.*sigma_yb.*sqrt(1-rho_b.^2)).*exp(-(1./(2.*(1 - rho_b.^2))).*(((x - mu_xb)./sigma_xb).^2 + ((y - mu_yb)./sigma_yb).^2 - 2.*rho_b.*(x - mu_xb).*(y - mu_yb)./(sigma_xb.*sigma_yb)))";
%   gauss_C = "C./(2.*pi.*sigma_xc.*sigma_yc.*sqrt(1-rho_c.^2)).*exp(-(1./(2.*(1 - rho_c.^2))).*(((x - mu_xc)./sigma_xc).^2 + ((y - mu_yc)./sigma_yc).^2 - 2.*rho_c.*(x - mu_xc).*(y - mu_yc)./(sigma_xc.*sigma_yc)))";
%   full_model = strjoin([planar_offset, gauss_A, gauss_B, gauss_C], " + ");
%   ft = fittype(full_model, ...
%     'dependent', {'z'}, 'independent', {'x', 'y'}, ...
%     'coefficients', {'z_0', 'A', 'sigma_xa', 'sigma_ya', 'rho_a', 'mu_xa', 'mu_ya', 'B', 'sigma_xb', 'sigma_yb', 'rho_b', 'mu_xb', 'mu_yb', 'C', 'sigma_xc', 'sigma_yc', 'rho_c', 'mu_xc', 'mu_yc'});
%   % % Note that "Database" for example could be a struct or Table, % % %
%   % basically anything where the rows of column vectors `x/y/z`  % % % %
%   % are matched up in a meaningful way related to the experiment % % % %  
%   [xData, yData, zData] prepareSurfaceData(Database.x, Database.y, Database.z);
%   % You could also define `opt` using fitoptions and supply the  % %
%   % 'Name',value arguments that way, e.g.                        % %
%   % >> opt = fitoptions(ft, 'Name', value, ...);
%   % >> mdl = fit([xData,yData],zData,ft,opt);
%   mdl = fit([xData,yData], zData, ft, 'Normalize', 'on');
%   utils.print_model_info(mdl);   
%   % % % OR % % %
%   fid = fopen('model_coeffs.txt', 'w');
%   utils.print_model_info(mdl, 'fid', fid);
%
% Inputs:
%   mdl - `sfit` object returned by `fit` MATLAB builtin.
%   'Name',value pairs:
%       * 'fid' - File ID, as returned by e.g. `fopen` built-in (def: 1 -- Command Window)
%       * 'numspec' - Format specifier for numeric values in coefficient print statements (def: "%11.4f")
%       * 'width' - Width (character symbols) for columns with names/coefficient values (def: 14)
%
% Output:
%   Prints to the command window or the file specified by `fid` option.
%
% See also: Contents, fit, fittype, fitoptions, fopen, fprintf

arguments
    mdl (1,1) sfit
    options.fid (1,1) double = 1;
    options.numspec (1,1) string = "%11.4f";
    options.width (1,1) double = 14;
end 

% % Get the relevant data from model % %
cname = coeffnames(mdl);
eqn = formula(mdl);
dt = datetime('now');

% % Run print statements to Command Window or text output file % %
fprintf(options.fid, 'Exported at %s\n', string(dt));
fprintf(options.fid, '\tEQUATION\n\t\t%s\n\n', eqn);
w = num2str(options.width);
fprintf(options.fid, ['\t%-' w 's  :   %+' w 's\n'], 'COEFFICIENT', 'VALUE');
fspec = sprintf(['\\t  %%-' w 's:%+' w 's\\n'], options.numspec);
for iC = 1:numel(cname)
    fprintf(options.fid, fspec, cname{iC}, mdl.(cname{iC}));
end

end