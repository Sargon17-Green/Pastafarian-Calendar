function run_stage55_all_open_chunk_tests()
% Native exact chunked lexicographic unrank vs independent brute oracle.
here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
cleanup = onCleanup(@() rmpath(fullfile(root, 'src'))); %#ok<NASGU>

families = {[1], [2 1], [2 2], [2 2 2], ...
    [3 2 2], [2 3 2], [2 2 2 2], [1 2 1 2], [4 2 1]};
checked = 0;
segments = 0;
for f = 1:numel(families)
    lengths = families{f};
    oracle = independentAllOpenWords(lengths);
    exact = pastafari.countWholeWeavingSuffixByEndpoints( ...
        lengths, numel(lengths), 0);
    assert(exact == pastafari.BigInt(size(oracle,1)), ...
        'Brute all-open count does not agree with exact algebraic family.');
    for r = 1:size(oracle,1)
        for chunkLength = [1 2 3 7]
          for mode = {'rational','common'}
            rest = lengths;
            closed = 0;
            rank = pastafari.BigInt(r);
            built = zeros(1,0);
            while true
                [part,state] = pastafari.unrankAllOpenedWeaveSuffixChunk( ...
                    rest,closed,rank,chunkLength,mode{1});
                assert(numel(part) == min(chunkLength,sum(rest)), ...
                    'A chunk skipped or invented days.');
                built = [built part]; %#ok<AGROW>
                segments = segments+1;
                assert(state.count == ...
                    pastafari.countWholeWeavingSuffixByEndpoints( ...
                        state.remaining,numel(rest),state.closedUpTo), ...
                    'Cursor parent count is not exact.');
                if state.done
                    assert(state.rank == pastafari.BigInt(1) && ...
                        state.count == pastafari.BigInt(1), ...
                        'Terminal rank/count invariant failed.');
                    break
                end
                assert(state.stepsComputed > 0, ...
                    'Nonterminal chunk must make progress.');
                rest = state.remaining;
                closed = state.closedUpTo;
                rank = state.rank;
            end
            assert(isequal(built,oracle(r,:)), ...
                'Chunked lexicographic rank output does not match brute.');
            checked = checked+1;
          end
        end
    end
end
fprintf('STAGE_55_ALL_OPEN_CHUNK_BRUTE_PASS FAMILIES=%d RANK_CHECKS=%d SEGMENTS=%d\n', ...
    numel(families),checked,segments);

% Partial cursor and boundary controls, including a zero-step checkpoint.
[empty, s] = pastafari.unrankAllOpenedWeaveSuffixChunk([2 2],0,1,0);
assert(isempty(empty) && ~s.done && s.stepsComputed == 0 && ...
    isequal(s.remaining,[2 2]), ...
    'Zero-step cursor must not make false progress.');
[empty, s] = pastafari.unrankAllOpenedWeaveSuffixChunk([0 0],2,1,50);
assert(isempty(empty) && s.done && s.count == pastafari.BigInt(1), ...
    'Terminal cursor should remain safely terminal.');
expectReject([2 2],0,1,0.5,'Pastafari:AllOpenChunk:StepLimit');
expectReject([2 2],0,1,-1,'Pastafari:AllOpenChunk:StepLimit');
expectReject([2 2],0,0,1,'Pastafari:AllOpenChunk:Rank');
expectReject([2 2],0,0.5,1,'Pastafari:Validation:IntegerInput');
expectReject([2 0],0,1,1,'Pastafari:AllOpenChunk:Frontier');
expectReject([2 2],0,1,NaN,'Pastafari:AllOpenChunk:StepLimit');
expectRejectMethod([2 2],0,1,1,'approximate');
fprintf('STAGE_55_ALL_OPEN_CHUNK_VALIDATION_PASS\n');

% Native *real* large partial progress, not a claim of full 4230-day
% unranking or full-year P(c,t) computation. Choose the middle rank to
% avoid merely following lexicographically first all-month blocks.
lengths = repmat(94,1,45);
whole = pastafari.countWholeWeavingSuffixByEndpoints(lengths,45,0);
rank = whole.floorDiv(pastafari.BigInt(2))+pastafari.BigInt(1);
elapsed = tic;
[part,state] = pastafari.unrankAllOpenedWeaveSuffixChunk( ...
    lengths,0,rank,12,'rational');
seconds = toc(elapsed);
fastStart=tic;
[fastPart,fastState] = pastafari.unrankAllOpenedWeaveSuffixChunk( ...
    lengths,0,rank,12,'common');
fastSeconds=toc(fastStart);
assert(isequal(fastPart,part) && ...
    isequal(fastState.remaining,state.remaining) && ...
    fastState.closedUpTo==state.closedUpTo && ...
    fastState.rank==state.rank && fastState.count==state.count && ...
    fastState.done==state.done && ...
    fastState.stepsComputed==state.stepsComputed, ...
    '4230-day 12-step common mode must match rational state exactly.');
fprintf(['STAGE_55_ALL_OPEN_CHUNK_COMMON_BENCH MONTHS=45 DAYS=4230 ', ...
    'STEPS=12 RATIONAL_SECONDS=%.3f COMMON_SECONDS=%.3f ', ...
    'COUNT_DIGITS=%d\n'],seconds,fastSeconds,numel(char(state.count)));
fprintf('STAGE_55_ALL_OPEN_CHUNK_COMMON_DIFFERENTIAL_PASS\n');
assert(numel(part)==12 && state.stepsComputed==12 && ...
    sum(lengths)-sum(state.remaining)==12 && ...
    state.count >= state.rank && state.rank >= pastafari.BigInt(1), ...
    'Large chunk must preserve day, exact rank and count invariants.');
fprintf(['STAGE_55_ALL_OPEN_CHUNK_BENCH MONTHS=45 DAYS=4230 ', ...
    'STEPS=12 SECONDS=%.3f COUNT_DIGITS=%d DONE=%d\n'], ...
    seconds,numel(char(state.count)),state.done);
fprintf('STAGE_55_ALL_OPEN_CHUNK_EXPERIMENTAL_PASS\n');
end

function ways = independentAllOpenWords(lengths)
% Reference enumerates every legal completion with only closure order,
% explicitly independent of the optimized binomial child formula.
days = sum(lengths);
buffer = zeros(1,days);
ways = zeros(0,days);
visit(lengths,0,1);

    function visit(remaining,closed,pos)
        if pos > days
            assert(all(remaining==0) && closed==numel(lengths));
            ways(end+1,:) = buffer; %#ok<AGROW>
            return
        end
        for month=1:numel(lengths)
            if remaining(month)==0 || ...
                    (remaining(month)==1 && month~=closed+1)
                continue
            end
            next=remaining;
            next(month)=next(month)-1;
            buffer(pos)=month;
            visit(next,closed+double(remaining(month)==1),pos+1);
        end
    end
end

function expectReject(remaining,closed,rank,steps,id)
matched=false;
try
    pastafari.unrankAllOpenedWeaveSuffixChunk(remaining,closed,rank,steps);
catch err
    matched=strcmp(err.identifier,id);
end
assert(matched,'Expected strict input rejection: %s.',id);
end

function expectRejectMethod(remaining,closed,rank,steps,method)
caught=false;
try
    pastafari.unrankAllOpenedWeaveSuffixChunk( ...
        remaining,closed,rank,steps,method);
catch err
    caught=strcmp(err.identifier,'Pastafari:AllOpenChunk:Method');
end
assert(caught,'An unrecognized child counter must be rejected.');
end
