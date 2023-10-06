function s = link2folder( folder, pre_text, link_text, post_text )
% LINK2FOLDER( FOLDER ) - Return a hyperlink that opens an Explorer window in the folder
% 
% Syntax:
%   s = LINK2FOLDER( FOLDER, PRE_TEXT, LINK_TEXT, POST_TEXT )
%
% Inputs:   
%   folder   - actual link
%   pre_text - before link
%   link_text - text with link
%   post_text - text after link
%
% Update: Max Murphy 2023-06-16 (add arguments block, formatting)

arguments
    folder {mustBeTextScalar, mustBeFolder}
    pre_text {mustBeTextScalar} = ''
    link_text {mustBeTextScalar} = ''
    post_text {mustBeTextScalar} = ''
end

if strlength(link_text) == 0
    link_text = folder;
end

s = sprintf('%s <a href = "matlab:winopen(''%s'');">%s</a> %s\n', pre_text, folder, link_text, post_text);
if nargout < 1
    disp(s);
end
end