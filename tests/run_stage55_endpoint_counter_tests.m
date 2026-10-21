function run_stage55_endpoint_counter_tests()
% Experimental: native exact suffix count versus independent brute oracle.
here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
cleanup = onCleanup(@() rmpath(fullfile(root, 'src'))); %#ok<NASGU>

cases = { ...
    [1 1], [2 2], [2 2 2], [3 3 3], [4 4 4], [2 3 2], [3 2 3]};
expected = [1 2 5 71 1301 11 19];
for k = 1:numel(cases)
    lengths = cases{k};
    actual = pastafari.countWholeWeavingSuffixByEndpoints( ...
        lengths, 0, 0);
    assert(actual == pastafari.BigInt(expected(k)), ...
        'Endpoint total mismatch in case %d.', k);
    assert(actual == pastafari.BigInt(bruteSuffix( ...
        lengths, lengths, 0, 0)), ...
        'Exhaustive brute total mismatch in case %d.', k);
end
fprintf('STAGE_55_ENDPOINT_TOTALS_PASS CASES=%d\n', numel(cases));

% Exercise ALL reachable legal suffix frontiers, not only the empty prefix.
families = {[2 3 2], [3 2 3], [2 2 2]};
checked = 0;
for family = 1:numel(families)
    lengths = families{family};
    work = {{lengths, 0, 0}};
    visited = containers.Map('KeyType', 'char', 'ValueType', 'logical');
    while ~isempty(work)
        entry = work{end};
        work(end) = [];
        remaining = entry{1};
        opened = entry{2};
        closed = entry{3};
        key = sprintf('%d,', [remaining, opened, closed]);
        if isKey(visited, key)
            continue
        end
        visited(key) = true;
        expectedCount = bruteSuffix(remaining, lengths, opened, closed);
        actualCount = pastafari.countWholeWeavingSuffixByEndpoints( ...
            remaining, opened, closed);
        assert(actualCount == pastafari.BigInt(expectedCount), ...
            ['Wrong exact suffix completion count for state ', key]);
        checked = checked + 1;
        for i = 1:numel(lengths)
            if remaining(i) == 0 || ...
                    (remaining(i) == lengths(i) && i ~= opened + 1) || ...
                    (remaining(i) == 1 && i ~= closed + 1)
                continue
            end
            next = remaining;
            next(i) = next(i) - 1;
            nextOpened = opened + double(remaining(i) == lengths(i));
            nextClosed = closed + double(remaining(i) == 1);
            work{end+1} = {next, nextOpened, nextClosed}; %#ok<AGROW>
        end
    end
end
assert(checked >= 25, 'Too few distinct suffix states checked.');
fprintf('STAGE_55_ENDPOINT_SUFFIX_EXHAUSTIVE_PASS STATES=%d\n', checked);

% A closed suffix has exactly one empty completion.
assert(pastafari.countWholeWeavingSuffixByEndpoints( ...
    [0 0 0], 3, 3) == pastafari.BigInt(1), ...
    'Empty suffix must have one completion.');

% Malformed counters/frontiers must be rejected, not silently counted.
assertRejected([-1 1], 0, 0, 'Pastafari:EndpointCount:Remaining');
assertRejected([2 0], 1, 0, 'Pastafari:EndpointCount:SuffixShape');
assertRejected([0 2], 0, 1, 'Pastafari:EndpointCount:Frontier');
fprintf('STAGE_55_ENDPOINT_VALIDATION_PASS\n');
fprintf('STAGE_55_ENDPOINT_EXPERIMENTAL_PASS\n');
end

function count = bruteSuffix(remaining, lengths, opened, closed)
if all(remaining == 0)
    assert(opened == numel(lengths) && closed == numel(lengths), ...
        'Brute terminal state has an incorrect frontier.');
    count = 1;
    return
end
count = 0;
for i = 1:numel(lengths)
    if remaining(i) == 0
        continue
    end
    if remaining(i) == lengths(i) && i ~= opened + 1
        continue
    end
    if remaining(i) == 1 && i ~= closed + 1
        continue
    end
    child = remaining;
    child(i) = child(i) - 1;
    nextOpened = opened + double(remaining(i) == lengths(i));
    nextClosed = closed + double(remaining(i) == 1);
    count = count + bruteSuffix(child, lengths, nextOpened, nextClosed);
end
end

function assertRejected(remaining, opened, closed, identifier)
caught = false;
try
    pastafari.countWholeWeavingSuffixByEndpoints( ...
        remaining, opened, closed);
catch err
    caught = strcmp(err.identifier, identifier);
end
assert(caught, 'Expected strict rejection for %s.', identifier);
end
