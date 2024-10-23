function edges = parse_edges(logic_signal)
%PARSE_EDGES  Returns struct with fields 'rising' and 'falling', containing sample indices immediately after a logic transition has occurred. 
edges = struct('rising', strfind(logic_signal,[0,1])+1, ...
               'falling', strfind(logic_signal,[1,0])+1);

end