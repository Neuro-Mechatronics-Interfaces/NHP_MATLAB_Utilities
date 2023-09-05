function S = parse_uevt_trials(T, options)
%PARSE_UEVT_TRIALS  Parse table from io.load_uevt, identifying trial metadata
%
% Syntax:
%   S = utils.parse_uevt_trials(T, 'Name', value, ...);
%
% Inputs

arguments
    T
    options.Keyword {mustBeTextScalar} = "STOP";
end

i_last = find(T.Event == options.Keyword, 1, 'last');
if isempty(i_last)
    error("No logs with keyword: %s -- check keyword or uevt file.", options.Keyword);
end

Time = T.Time(T.Event == options.Keyword);
n = numel(Time);
Plexon_Block = (0:(n-1))';
SAGA_Block = nan(n,1); 
Target = enum.TaskTarget(-1.*ones(n,1));
Direction = enum.TaskDirection(-1.*ones(n,1));
Outcome = enum.TaskOutcome(-1.*ones(n,1));
Orientation = enum.TaskOrientation(-1.*ones(n,1));

i_orientation = find(T.Event == "Orientation", 1, 'first');
i_target = find(T.Event == "Target", 1, 'first');
i_direction = find(T.Event == "Direction", 1, 'first');
i_outcome = find(T.Event =="Outcome", 1, 'first');
i_next = find(T.Event == options.Keyword, 1, 'first');

if ~isempty(i_orientation)
    Orientation(1) = enum.TaskOrientation(T.Data(i_orientation));
end
if ~isempty(i_target)
    Target(1) = enum.TaskTarget(T.Data(i_target));
end
if ~isempty(i_direction)
    Direction(1) = enum.TaskDirection(T.Data(i_direction));
end
if ~isempty(i_outcome)
    Outcome(1) = enum.TaskOutcome(T.Data(i_outcome));
end
T(1:i_next,:) = [];

for ii = 1:(n-1)
    i_next = find(T.Event == options.Keyword, 1, 'first');
    i_orientation = find(T.Event(1:(i_next-1)) == "Orientation", 1, 'first');
    i_target = find(T.Event(1:(i_next-1)) == "Target", 1, 'first');
    i_direction = find(T.Event(1:(i_next-1)) == "Direction", 1, 'first');
    if ~isempty(i_orientation)
        Orientation(ii+1) = enum.TaskOrientation(T.Data(i_orientation));
    else
        Orientation(ii+1) = Orientation(ii);
    end
    if ~isempty(i_target)
        Target(ii+1) = enum.TaskTarget(T.Data(i_target));
    else
        Target(ii+1) = Target(ii);
    end
    if ~isempty(i_direction)
        Direction(ii+1) = enum.TaskDirection(T.Data(i_direction));
    else
        Direction(ii+1) = Direction(ii);
    end

    if Direction(ii+1)~=Direction(ii)
        Outcome(ii) = enum.TaskOutcome.SUCCESSFUL;
    else
        Outcome(ii) = enum.TaskOutcome.UNSUCCESSFUL;
    end

    SAGA_Block(ii) = sum(Orientation == Orientation(ii))-1;
    T(1:i_next,:) = [];
end

S = timetable(Time, Orientation, Target, Direction, Outcome, Plexon_Block, SAGA_Block);
S(end,:) = [];

end