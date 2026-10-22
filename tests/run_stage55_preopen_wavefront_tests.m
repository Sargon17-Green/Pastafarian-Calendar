function run_stage55_preopen_wavefront_tests()
% Native differential of linear-memory exact wavefront against the
% previously verified endpoint DP and an INDEPENDENT legal-state oracle.
here=fileparts(mfilename('fullpath'));
root=fileparts(here);
addpath(fullfile(root,'src'));
cleanup=onCleanup(@() rmpath(fullfile(root,'src'))); %#ok<NASGU>

cases=0;
for K=1:5
    for encoded=0:(3^K-1)
        lengths=zeros(1,K);
        v=encoded;
        for j=1:K
            lengths(j)=mod(v,3)+1;
            v=floor(v/3);
        end
        fromWavefront=pastafari.countWholeWeavingAllUnopenedWavefront(lengths);
        fromEndpoints=pastafari.countWholeWeavingSuffixByEndpoints( ...
            lengths,0,0);
        memo=containers.Map('KeyType','char','ValueType','double');
        fromOracle=independentBrute(lengths,lengths,0,0,memo);
        assert(fromWavefront==fromEndpoints && ...
            fromWavefront==pastafari.BigInt(fromOracle), ...
            'Fully unopened wavefront differs from exact reference.');
        cases=cases+1;
    end
end
fprintf('STAGE_55_PREOPEN_WAVEFRONT_EXHAUSTIVE_PASS CASES=%d\n',cases);

% Compare complete counts on larger initial frontiers. Keep the
% benchmark bounded so the separate pre-open scaling workflow can
% measure 160/240/320 days independently, without test cancellation.
vectors={repmat(5,1,6),repmat(10,1,8),repmat(10,1,12)};
for i=1:numel(vectors)
    lengths=vectors{i};
    start=tic;
    got=pastafari.countWholeWeavingAllUnopenedWavefront(lengths);
    elapsed=toc(start);
    exact=pastafari.countWholeWeavingSuffixByEndpoints(lengths,0,0);
    assert(got==exact,'Wavefront / existing endpoint mismatch.');
    fprintf(['STAGE_55_PREOPEN_WAVEFRONT_BENCH MONTHS=%d DAYS=%d ', ...
        'SECONDS=%.3f DIGITS=%d\n'], ...
        numel(lengths),sum(lengths),elapsed,numel(char(got)));
end
fprintf('STAGE_55_PREOPEN_WAVEFRONT_EXPERIMENTAL_PASS\n');
end

function count=independentBrute(remaining,lengths,opened,closed,memo)
% Independent legal-transition oracle with memoized STATE counts.
% Memoization merges identical subtrees without skipping any legal word.
if all(remaining==0)
    assert(opened==numel(lengths) && closed==numel(lengths));
    count=1;
    return
end
key=sprintf('%d,',[remaining opened closed]);
if isKey(memo,key)
    count=memo(key);
    return
end
count=0;
for month=1:numel(lengths)
    copies=remaining(month);
    if copies==0 || (copies==lengths(month) && month~=opened+1) || ...
            (copies==1 && month~=closed+1)
        continue
    end
    child=remaining;
    child(month)=copies-1;
    count=count+independentBrute(child,lengths, ...
        opened+double(copies==lengths(month)), ...
        closed+double(copies==1),memo);
end
assert(count<=flintmax, ...
    'Independent small-case counter exceeded exact double capacity.');
memo(key)=count;
end
