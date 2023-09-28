function save_figure(fig, output_folder, name_stem, options)
%SAVE_FIGURE  Exports figure in desired file formats, creating output folder if needed.
%
% Syntax:
%   utils.save_figure(fig, output_folder, name_stem, 'Name', value, ...);
%
% Inputs:
%   fig - Figure handle to save
%   output_folder - Folder in which to generate saved figure files.
%   name_stem - The filename stem to use in combination with extension
%                   related to different export types.
%  
% Options:
%     'AddAnnotation' (1,1) logical = true - Set to false to prevent annotation parsing from output folder name.
%     'CloseFigure' (1,1) logical = true - Set to false to prevent auto-delete of figure handle after successful saves.
%     'ExportAs' cell = {'.png'} - Can be an arbitrary cell array of '.*' extensions for valid filetypes. See also: saveas
%     'Tag' {mustBeTextScalar} = '' - Can be used to append some differentiating filename tag for multiple iterations of similar file saved in same sub-folder.
%     'SaveFigure' (1,1) logical = true - Set false to prevent saving .fig file.
%     'SubFolders' cell = {} - Each cell element (in-order) is used to generate sub-folders after "output_folder."
%
% Output:
%   Saves contents of `fig` into different figure filetypes and potentially
%   closes the figure handle when done saving. 
%
% See also: Contents, saveas, savefig

arguments
    fig (1,1) matlab.ui.Figure
    output_folder {mustBeTextScalar}
    name_stem {mustBeTextScalar}
    options.AddAnnotation (1,1) logical = true;
    options.CloseFigure (1,1) logical = true;
    options.ExportAs cell = {'.png'}; 
    options.Tag {mustBeTextScalar} = ''
    options.SaveFigure (1,1) logical = true;
    options.SubFolders cell = {};
end

if exist(output_folder,'dir')==0
    mkdir(fullfile(output_folder, options.SubFolders{:}));
end

if options.AddAnnotation
    pinfo = strsplit(output_folder,filesep);
    if startsWith(pinfo{end},'v') && ~isnan(str2double(strrep(pinfo{end},'v','')))
        v_num = pinfo{end};
        c_name = pinfo{end-1};
        c_date = pinfo{end-2};
        annotation(fig,'textbox',[0.01 0.01 .5 .04],'String',sprintf('%s.m',strrep(c_name,'_','\_')), ...
            'FitBoxToText','off','EdgeColor','none','Margin',0,...
            'FontName','Tahoma','HorizontalAlignment','left');
        annotation(fig,'textbox',[.49 0.95 .5 .04],'String',sprintf('%s: %s',c_date,v_num), ...
            'FitBoxToText','off','EdgeColor','none','Margin',0,...
            'FontName','Tahoma','HorizontalAlignment','right');
    end
end

if strlength(options.Tag) > 0
    if startsWith(options.Tag, '_')
        name_stem = sprintf('%s%s',name_stem,options.Tag);
    else
        name_stem = sprintf('%s_%s',name_stem,options.Tag);
    end
end

for ii = 1:numel(options.ExportAs)
    saveas(fig, fullfile(output_folder, options.SubFolders{:}, sprintf('%s%s', name_stem, options.ExportAs{ii})));
end

if options.SaveFigure
    savefig(fig, fullfile(output_folder, options.SubFolders{:}, sprintf('%s.fig', name_stem)));
end

if options.CloseFigure
    delete(fig);
end

end