function S = parse_uevt_trials(T, options)
%PARSE_UEVT_TRIALS  Parse table from io.load_uevt, identifying trial metadata
%
% Syntax:
%   S = utils.parse_uevt_trials(T, 'Name', value, ...);
%
% Inputs

arguments
    T
%     options.Keyword {mustBeTextScalar} = "STOP";
    options.KeyEvent {mustBeTextScalar} = "State";
    options.BlockEvent {mustBeTextScalar} = "SUCCESS";
    options.KeyData (1,1) enum.TaskState = enum.TaskState.COMPLETE;
    options.StartData (1,1) enum.TaskState = enum.TaskState.SETUP;
    options.MaxStateIntervalWithinTrial (1,1) double = 15.0; % Seconds, maximum allowable time between states. Exclude state(1) where interval state(2)-state(1) exceeds this value.
    options.Verbose (1,1) logical = true;
end


% i_last = find(T.Event == options.Keyword, 1, 'last');
i_state_word = find(T.Event == options.KeyEvent);
i_last = i_state_word(find(enum.TaskState(T.Data(i_state_word))==options.KeyData, 1, 'last'));
if isempty(i_last)
    if options.Verbose
        if isfield(T.Properties.UserData, 'Experiment')
            expName = T.Properties.UserData.Experiment;
        else
            expName = 'Unknown';
        end
        fprintf(1,"No logs with key-event: %s -- check keyword or uevt file (%s).\n", options.KeyEvent, expName);
    end
    S = [];
    return;
end
% Time = T.Time(T.Event == options.Keyword);
i_start = i_state_word(enum.TaskState(T.Data(i_state_word))==options.StartData);
Time = T.Time(i_start);
n = numel(Time);
% n = numel(Time)+1;
% Time(end+1) = Time(end) + seconds(2);
% Plexon_Block = (1:n)';
Plexon_Block = nan(n,1);
SAGA_Block = nan(n,1); 
Target = enum.TaskTarget(-1.*ones(n,1));
Direction = enum.TaskDirection(-1.*ones(n,1));
Outcome = enum.TaskOutcome(-1.*ones(n,1));
% Orientation = enum.TaskOrientation(-1.*ones(n,1));
tmp = strsplit(T.Properties.UserData.Experiment, '_');
Orientation = repmat(enum.TaskOrientation(tmp{end}),n,1);
State = cell(n,1);
State_Time = cell(n,1);

% i_next = find(T.Event == options.Keyword, 1, 'first');
% i_next = i_state_word(find(enum.TaskState(T.Data(i_state_word))==options.KeyData, 1, 'first'));

% i_orientation = find(T.Event(1:i_next) == "Orientation", 1, 'last');
% i_target = find(T.Event(1:i_next) == "Target", 1, 'last');
% % i_direction = find(T.Event(1:i_next) == "Direction", 1, 'last');
% i_outcome = find(T.Event(1:i_next) =="Outcome", 1, 'last');
% i_state = find(T.Event(1:i_next) == "State");
% if ~isempty(i_state)
%     State{1} = enum.TaskState(T.Data(i_state));
%     State_Time{1} = seconds(T.Time(i_state) - T.Time(i_state(1)));
% end

% if ~isempty(i_orientation)
%     Orientation(1) = enum.TaskOrientation(T.Data(i_orientation));
% end
% if ~isempty(i_target)
%     Target(1) = enum.TaskTarget(T.Data(i_target));
% end
% if ~isempty(i_direction)
%     Direction(1) = enum.TaskDirection(T.Data(i_direction));
% end
% Direction(1) = enum.TaskDirection(1); % Always starts in-to-out
% if ~isempty(i_outcome)
%     Outcome(1) = enum.TaskOutcome(T.Data(i_outcome));
% end
% i_block = find(T.Event == options.BlockEvent, 1, 'first');
% if ~isempty(i_block)
%     SAGA_Block(1) = T.Data(i_block);
%     Plexon_Block(1) = T.Data(i_block);
% end
% T(1:i_next,:) = [];

for ii = 1:n
%     i_next = find(T.Event == options.Keyword, 1, 'first');
    i_state_word = find(T.Event == options.KeyEvent);
    i_next = i_state_word(find(enum.TaskState(T.Data(i_state_word))==options.KeyData, 1, 'first'));
    if isempty(i_next)
        i_next = size(T,1);
    end
%     i_orientation = find(T.Event(1:i_next) == "Orientation", 1, 'last');
    i_target = find(T.Event(1:i_next) == "Target", 1, 'last');
    i_direction = find(T.Event(1:i_next) == "Direction", 1, 'last');
    i_outcome = find(T.Event(1:i_next) =="Outcome", 1, 'last');
    i_state = find(T.Event(1:i_next)=="State");
    if ~isempty(i_state)
        State{ii} = enum.TaskState(T.Data(i_state));
        State_Time{ii} = seconds(T.Time(i_state) - T.Time(i_state(1)));
        if numel(State_Time{ii}) > 1
            checkStateTime = true;
            while checkStateTime
                i_state_diff = diff(State_Time{ii}) > options.MaxStateIntervalWithinTrial;
                if any(i_state_diff)
                    k = find(i_state_diff,1,'last');
                    State_Time{ii}(1:k) = [];
                    State{ii}(1:k) = [];
                    i_state(1:k) = [];
                    Time(ii) = T.Time(i_state(1));
                    State_Time{ii} = State_Time{ii} - State_Time{ii}(1);
                    checkStateTime = numel(State_Time{ii}) > 1;
                else
                    checkStateTime = false;
                end
            end
        end
    end
%     if ~isempty(i_orientation)
%         Orientation(ii+1) = enum.TaskOrientation(T.Data(i_orientation));
%     else
%         Orientation(ii+1) = Orientation(ii);
%     end
    if ~isempty(i_target)
        Target(ii) = enum.TaskTarget(T.Data(i_target));
    elseif ii > 1
        Target(ii) = Target(ii-1);
    end
    if ~isempty(i_direction)
        Direction(ii) = enum.TaskDirection(T.Data(i_direction));
    elseif ii > 1
        Direction(ii) = Direction(ii-1);
    end
    
    if ~isempty(i_outcome)
        Outcome(ii) = enum.TaskOutcome(T.Data(i_outcome));
    elseif ii > 1
        Outcome(ii) = Outcome(ii-1);
    end
%     if Direction(ii+1)~=Direction(ii)
%         Outcome(ii) = enum.TaskOutcome.SUCCESSFUL;
%     else
%         Outcome(ii) = enum.TaskOutcome.UNSUCCESSFUL;
%     end

%     SAGA_Block(ii) = sum(Orientation == Orientation(ii))-1;
    i_block = find(T.Event == options.BlockEvent, 1, 'first');
    if ~isempty(i_block)
        SAGA_Block(ii) = T.Data(i_block);
        Plexon_Block(ii) = T.Data(i_block);
    end
    T(1:i_next,:) = [];
end

S = timetable(Time, Orientation, Target, Direction, Outcome, Plexon_Block, SAGA_Block, State, State_Time);
% S(end,:) = [];

i_missed = find(S.Outcome == enum.TaskOutcome.UNDEFINED);
if ~isempty(i_missed)
    i_edge = i_missed([diff(i_missed)>1; true]);
    for ii = 1:numel(i_edge)
        if (i_edge(ii)+1) <= size(S, 1)
            if S.Target(i_edge(ii)+1) ~= S.Target(i_edge(ii))
                S.Outcome(i_edge(ii)) = enum.TaskOutcome.SUCCESSFUL;
                S.Direction(i_edge(ii)) = enum.TaskDirection(1 - double(S.Direction(i_edge(ii)+1)));
                S.Plexon_Block(i_edge(ii)) = S.Plexon_Block(i_edge(ii)+1)-1;
                S.SAGA_Block(i_edge(ii)) = S.SAGA_Block(i_edge(ii)+1)-1;
            else
                S.Outcome(i_edge(ii)) = enum.TaskOutcome.UNSUCCESSFUL;
                S.Direction(i_edge(ii)) = S.Direction(i_edge(ii)+1);
            end
            i_prev = i_missed(i_missed < i_edge(ii));
            for ik = 1:numel(i_prev)
                S.Outcome(i_prev(ik)) = enum.TaskOutcome.UNSUCCESSFUL;
                S.Direction(i_prev(ik)) = S.Direction(i_edge(ii));
                S.Plexon_Block(i_prev(ik)) = S.Plexon_Block(i_edge(ii));
                S.SAGA_Block(i_prev(ik)) = S.SAGA_Block(i_edge(ii));
            end
            i_missed = setdiff(i_missed, i_prev);
        else
            S.Outcome(i_edge(ii)) = enum.TaskOutcome.UNSUCCESSFUL;
        end
    end
end


end