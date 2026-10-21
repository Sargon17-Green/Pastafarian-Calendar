function run_stage55_endpoint_unrank_tests()
% Independent lexicographic brute enumeration vs proposed endpoint unrank.
here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
cleanup = onCleanup(@() rmpath(fullfile(root, 'src'))); %#ok<NASGU>

cases = {[1], [4], [1 1], [2 2], [2 2 2], ...
    [2 3 2], [3 2 3], [3 3 3], [4 4 4]};
checked = 0;
for c = 1:numel(cases)
    lengths = cases{c};
    reference = enumerateBrute(lengths);
    count = size(reference, 1);
    % Every rank for families with at most 71 rows; edge/mid/witness
    % ranks for [4 4 4], which has exactly 1301 rows.
    if count <= 100
        ranks = 1:count;
    else
        ranks = unique([1 2 3 23 259 396 1129 count-1 count]);
    end
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
    ranks = unique([1 ceil(last / 2) last]);
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
