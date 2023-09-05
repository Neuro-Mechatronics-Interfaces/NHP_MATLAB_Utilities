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

n = T.Data(i_last)+1;

Plexon_Block = (1:n)';
SAGA_Block = nan(n,1); 
Target = enum.TaskTarget(-1.*ones(n,1));
Direction = enum.TaskDirection(-1.*ones(n,1));
Outcome = enum.TaskOutcome(-1.*ones(n,1));
Orientation = enum.TaskOrientation(-1.*ones(n,1));
Time = T.Time(T.Event == "STOP");

for ii = 1:n
    i_next = find(T.Event == options.Keyword, 1, 'first');
    i_orientation = find(T.Event(1:(i_next-1)) == "Orientation", 1, 'first');
    i_target = find(T.Event(1:(i_next-1)) == "Target", 1, 'first');
    i_outcome = find(T.Event(1:(i_next-1)) == "Outcome", 1, 'first');
    i_direction = find(T.Event(1:(i_next-1)) == "Direction", 1, 'first');
    if ~isempty(i_orientation)
        Orientation(ii) = enum.TaskOrientation(T.Data(i_orientation));
    else
        if ii > 1
            Orientation(ii) = Orientation(ii-1);
        end
    end
    if ~isempty(i_target)
        Target(ii) = enum.TaskTarget(T.Data(i_target));
    else
        if ii > 1
            Target(ii) = Target(ii-1);
        end
    end
    if ~isempty(i_direction)
        Direction(ii) = enum.TaskDirection(T.Data(i_direction));
    else
        if ii > 1
            Direction(ii) = Direction(ii-1);
        end
    end
    if ~isempty(i_outcome)
        Outcome(ii) = enum.TaskOutcome(T.Data(i_outcome));
    else
        if ii > 1
            Outcome(ii) = Outcome(ii-1);
        end
    end
    SAGA_Block(ii) = sum(Orientation == Orientation(ii))-1;
    T(1:i_next,:) = [];
end

S = timetable(Time, Orientation, Target, Direction, Outcome, Plexon_Block, SAGA_Block);

end