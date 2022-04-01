function [data, all_data] = parse_xml(filename)
%PARSE_XML Convert XML file to a MATLAB structure.
%
% Syntax:
%   [data, all_data] = parse_xml(filename);
%
% Inputs:
%   filename - Name of XML file. In this case, it's the poly5 annotation.
%
% Output:
%   data - Struct with fields 'Operator' and 'Annotation' (notes they took)
%
% See also: Contents, load_tmsi_raw, parse_polybench_data_manager_notes
try
    tree = xmlread(filename);
catch
    error('Failed to read XML file %s.',filename);
end

% Recurse over child nodes. This could run into problems
% with very deeply nested trees.
try
    all_data = parseChildNodes(tree);
catch
    error('Unable to parse XML file %s.',filename);
end

data = struct('Operator', "", 'Annotation', "");
c = all_data.Children;
name = arrayfun(@(s)string(s.Name), c);
value = arrayfun(@(s)get_value(s.Children), c);
iOp = find(name == "Operator", 1, 'first');
iAnnotate = find(name == "Notes", 1, 'first');
if ~isempty(iOp)
    data.Operator = value(iOp);
else
    data.Operator = "MM";
end
if ~isempty(iAnnotate)
    data.Annotation = value(iAnnotate);
else
    data.Annotation = "";
end

    function val = get_value(s)
        try
            val = string(s.Data);
        catch
            val = "?";
        end
    end

% ----- Local function PARSECHILDNODES -----
    function children = parseChildNodes(theNode)
        % Recurse over node children.
        children = [];
        if theNode.hasChildNodes
            childNodes = theNode.getChildNodes;
            numChildNodes = childNodes.getLength;
            allocCell = cell(1, numChildNodes);
            
            children = struct(             ...
                'Name', allocCell, 'Attributes', allocCell,    ...
                'Data', allocCell, 'Children', allocCell);
            
            for count = 1:numChildNodes
                theChild = childNodes.item(count-1);
                children(count) = makeStructFromNode(theChild);
            end
        end
    end

% ----- Local function MAKESTRUCTFROMNODE -----
    function nodeStruct = makeStructFromNode(theNode)
        % Create structure of node info.
        
        nodeStruct = struct(                        ...
            'Name', char(theNode.getNodeName),       ...
            'Attributes', parseAttributes(theNode),  ...
            'Data', '',                              ...
            'Children', parseChildNodes(theNode));
        
        if any(strcmp(methods(theNode), 'getData'))
            nodeStruct.Data = char(theNode.getData);
        else
            nodeStruct.Data = '';
        end
    end

% ----- Local function PARSEATTRIBUTES -----
    function attributes = parseAttributes(theNode)
        % Create attributes structure.
        
        attributes = [];
        if theNode.hasAttributes
            theAttributes = theNode.getAttributes;
            numAttributes = theAttributes.getLength;
            allocCell = cell(1, numAttributes);
            attributes = struct('Name', allocCell, 'Value', ...
                allocCell);
            
            for count = 1:numAttributes
                attrib = theAttributes.item(count-1);
                attributes(count).Name = char(attrib.getName);
                attributes(count).Value = char(attrib.getValue);
            end
        end
    end

end