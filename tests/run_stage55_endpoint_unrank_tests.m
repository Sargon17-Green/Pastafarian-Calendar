function run_stage55_endpoint_unrank_tests()
% Independent lexicographic brute enumeration vs proposed endpoint unrank.
here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
cleanup = onCleanup(@() rmpath(fullfile(root, 'src'))); %#ok<NASGU>

cases = {[1], [4], [1 1], [2 2], [2 2 2], ...
    [2 3 2], [3 2 3], [3 3 3], [4 4 4], ...
    [2 2 2 2], [3 2 3 2], [2 2 2 2 2]};
checked = 0;
for c = 1:numel(cases)
    lengths = cases{c};
    reference = enumerateBrute(lengths);
    count = size(reference, 1);
    % Check EVERY lexicographic rank for each small family, including
    % all 1301 legal rows of [4 4 4], never sampling its ranks.
    ranks = 1:count;
    for rank = ranks
        got = pastafari.unrankWholeWeavingByEndpoints( ...
            lengths, pastafari.BigInt(rank));
        assert(isequal(got, reference(rank, :)), ...
            'Endpoint unrank mismatch: case %d, rank %d.', c, rank);
        checked = checked + 1;
    end
end
fprintf('STAGE_55_ENDPOINT_UNRANK_BRUTE_PASS CASES=%d RANKS=%d\n', ...
    numel(cases), checked);

% Differential with the existing production exact-DAG implementation for
% small inputs only. No production algorithm is replaced.
for c = 1:numel(cases)
    lengths = cases{c};
    family = pastafari.WholeMonthWeavingFamily(lengths);
    last = family.count().toDoubleExact();
    ranks = 1:last; % exhaustive native cross-implementation comparison
    for rank = ranks
        actual = pastafari.unrankWholeWeavingByEndpoints( ...
            lengths, pastafari.BigInt(rank));
        expected = family.itemAt1(pastafari.BigInt(rank));
        assert(isequal(actual, expected), ...
            'Legacy exact-DAG / endpoint rank mismatch.');
    end
end
fprintf('STAGE_55_ENDPOINT_UNRANK_OLD_DAG_DIFFERENTIAL_PASS\n');

assertRejected([2 2], 0, 'Pastafari:EndpointUnrank:Rank');
assertRejected([2 2], -1, 'Pastafari:EndpointUnrank:Rank');
assertRejected([2 2], 3, 'Pastafari:EndpointUnrank:Rank');
assertRejected([0 2], 1, 'Pastafari:EndpointUnrank:Lengths');
assertRejected([2.5 2], 1, 'Pastafari:EndpointUnrank:Lengths');
assertRejected([2 2], NaN, 'Pastafari:Validation:IntegerInput');
% Validate the exact all-open rational child blocks for all small
% positive vectors, including already-closed prefixes, against the
% INDEPENDENT endpoint suffix counter for every legal next letter.
allOpenCases = 0;
allOpenChildren = 0;
for m = 1:4
    for encoding = 0:3^m-1
        r = zeros(1,m);
        tmp = encoding;
        for pos = 1:m
            r(pos) = mod(tmp,3)+1;
            tmp = floor(tmp/3);
        end
        for closed = 0:2
            fullRemaining = [zeros(1,closed) r];
            parent = pastafari.countWholeWeavingSuffixByEndpoints( ...
                fullRemaining, numel(fullRemaining), closed);
            blocks = pastafari.allOpenedWholeWeaveChildCounts( ...
                fullRemaining, closed, parent);
            assert(numel(blocks) == numel(fullRemaining), ...
                'All-open block width lost closed month IDs.');
            for id = 1:numel(fullRemaining)
                if id <= closed || (id > closed+1 && fullRemaining(id) == 1)
                    assert(isempty(blocks{id}), ...
                        'Illegal all-open child should not have a block.');
                    continue
                end
                suffix = fullRemaining;
                suffix(id) = suffix(id)-1;
                nextClosed = closed+double(fullRemaining(id)==1);
                expected = pastafari.countWholeWeavingSuffixByEndpoints( ...
                    suffix,numel(suffix),nextClosed);
                assert(blocks{id} == expected, ...
                    'All-open algebraic block disagrees with exact suffix counter.');
                allOpenChildren = allOpenChildren+1;
            end
            allOpenCases = allOpenCases+1;
        end
    end
end
fprintf('STAGE_55_ALL_OPEN_CHILD_BLOCKS_EXACT_PASS CASES=%d CHILDREN=%d\n', ...
    allOpenCases,allOpenChildren);

% Benchmark the actual branch weights at 45 opened months and 4230
% remaining days. This is not a full-calendar production measurement.
largeR = repmat(94,1,45);
largeTotal = pastafari.countWholeWeavingSuffixByEndpoints(largeR,45,0);
elapsed = tic;
largeBlocks = pastafari.allOpenedWholeWeaveChildCounts( ...
    largeR,0,largeTotal);
duration = toc(elapsed);
aggregate = pastafari.BigInt(0);
for id = 1:numel(largeBlocks)
    if ~isempty(largeBlocks{id})
        aggregate = aggregate+largeBlocks{id};
    end
end
assert(aggregate == largeTotal, ...
    'Huge all-open child blocks must sum to exact parent count.');
fprintf(['STAGE_55_ALL_OPEN_CHILD_BLOCKS_BENCH MONTHS=45 ', ...
    'DAYS=4230 SECONDS=%.3f DIGITS=%d\n'], ...
    duration, numel(char(largeTotal)));
fprintf('STAGE_55_ALL_OPEN_CHILD_BLOCKS_PASS\n');

fprintf('STAGE_55_ENDPOINT_UNRANK_VALIDATION_PASS\n');

% Bounded native performance samples: exact counts, not elapsed-time
% claims about the untested 4244-day production case.
sizes = {[10 10 10 10 10 10], ...
    [20 20 20 20 20 20 20 20]};
for k = 1:numel(sizes)
    lengths = sizes{k};
    elapsed = tic;
    total = pastafari.countWholeWeavingSuffixByEndpoints( ...
        lengths, 0, 0);
    assert(total > pastafari.BigInt(0), ...
        'Positive lengths must admit at least one whole weaving.');
    fprintf('STAGE_55_ENDPOINT_COUNT_BENCH DAYS=%d MONTHS=%d SECONDS=%.3f DIGITS=%d\n', ...
        sum(lengths), numel(lengths), toc(elapsed), numel(char(total)));
end
fprintf('STAGE_55_ENDPOINT_UNRANK_EXPERIMENTAL_PASS\n');
end

function rows = enumerateBrute(lengths)
% Entirely independent recursive reference, emitted in lexical order.
N = sum(lengths);
row = zeros(1, N);
rows = zeros(0, N);
visit(lengths, 0, 0, 1);

    function visit(remaining, opened, closed, position)
        if position > N
            assert(all(remaining == 0) && opened == numel(lengths) && ...
                closed == numel(lengths));
            rows(end+1, :) = row; %#ok<AGROW>
            return
        end
        for month = 1:numel(lengths)
            if remaining(month) == 0 || ...
                    (remaining(month) == lengths(month) && ...
                        month ~= opened+1) || ...
                    (remaining(month) == 1 && month ~= closed+1)
                continue
            end
            child = remaining;
            child(month) = child(month) - 1;
            row(position) = month;
            visit(child, opened + ...
                double(remaining(month) == lengths(month)), ...
                closed + double(remaining(month) == 1), position+1);
        end
    end
end

function assertRejected(lengths, rank, identifier)
matched = false;
try
    pastafari.unrankWholeWeavingByEndpoints(lengths, rank);
catch err
    matched = strcmp(err.identifier, identifier);
end
assert(matched, 'Expected %s rejection.', identifier);
end
