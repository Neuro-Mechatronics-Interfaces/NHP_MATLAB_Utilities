function [rising,falling] = parse_sync(triggers, bit, options)
%PARSE_SYNC  Parses sync from TMSi TRIGGERS
arguments
    triggers (1,:) double
    bit (1,1) {mustBeInteger}
    options.InvertLogic (1,1) logical = true;
    options.DebounceSamples (1,1) double {mustBePositive, mustBeInteger} = 1;
end
if options.InvertLogic
    HIGH = find(bitand(triggers, 2^bit)==0);
else
    HIGH = find(bitand(triggers, 2^bit)==2^bit);
end
if ~isempty(HIGH)
    rising = HIGH([HIGH(1) > 1, diff(HIGH) > options.DebounceSamples]);
else
    rising = [];
end
if nargout < 2
    return;
end
if options.InvertLogic
    LOW = find(bitand(triggers, 2^bit)==2^bit);
else
    LOW = find(bitand(triggers, 2^bit)==0);
end
if ~isempty(LOW)
    falling = LOW([LOW(1) > 1, diff(LOW) > options.DebounceSamples]);
else
    falling = [];
end
end