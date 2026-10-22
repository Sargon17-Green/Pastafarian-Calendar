function run_stage55_general_chunk_tests()
% Reference chunk unrank for EVERY frontier: independent recursive legal
% word enumeration, previous DAG itemAt1, and alternate chunk partitions.
here=fileparts(mfilename('fullpath'));
root=fileparts(here);
addpath(fullfile(root,'src'));
cleanup=onCleanup(@() rmpath(fullfile(root,'src'))); %#ok<NASGU>

families={[1],[2],[2 2],[2 2 2],[2 3 2],[3 2 3], ...
    [3 3 3],[4 4 4],[2 2 2 2],[3 2 2 2]};
checked=0; segments=0; fullyOpened=0; partiallyOpened=0;
for f=1:numel(families)
    L=families{f};
    oracle=bruteAllLegal(L);
    family=pastafari.WholeMonthWeavingFamily(L);
    assert(pastafari.BigInt(size(oracle,1))==family.count(), ...
        'Independent full lexical family count and legacy DAG differ.');
    if size(oracle,1)<=100
        ranks=1:size(oracle,1);
    else
        ranks=unique([1 2 3 23 259 396 1129 size(oracle,1)]);
    end
    for rankNo=ranks
        expected=oracle(rankNo,:);
        for limit=[1 2 4 7]
            R=L; opened=0; closed=0;
            r=pastafari.BigInt(rankNo);
            actual=zeros(1,0);
            while true
                [chunk,c]=pastafari.unrankGeneralWeaveSuffixChunk( ...
                    L,R,opened,closed,r,limit);
                assert(numel(chunk)==min(sum(R),limit), ...
                    'General chunk must not skip any day.');
                actual=[actual chunk]; %#ok<AGROW>
                segments=segments+1;
                if c.openedUpTo==numel(L)
                    fullyOpened=fullyOpened+1;
                elseif c.openedUpTo>0
                    partiallyOpened=partiallyOpened+1;
                end
                assert(c.count== ...
                    pastafari.countWholeWeavingSuffixByFirstEndpoint( ...
                        c.remaining,c.openedUpTo,c.closedUpTo), ...
                    'Chunk cursor has incorrect full legal completion count.');
                assert(c.rank>=pastafari.BigInt(1) && c.rank<=c.count, ...
                    'Exact rank must lie inside the resumed suffix family.');
                if c.done
                    assert(c.rank==pastafari.BigInt(1));
                    break
                end
                R=c.remaining; opened=c.openedUpTo;
                closed=c.closedUpTo; r=c.rank;
            end
            assert(isequal(actual,expected), ...
                'Chunk concatenation lost independent lexical rank.');
            assert(isequal(actual,family.itemAt1(pastafari.BigInt(rankNo))), ...
                'General chunk and old exact-DAG implementation disagree.');
            checked=checked+1;
        end
    end
end
assert(fullyOpened>0 && partiallyOpened>0, ...
    'Chunk test did not exercise opened and partially opened states.');
fprintf(['STAGE_55_GENERAL_CHUNK_BRUTE_PASS FAMILIES=%d ', ...
    'RANK_CHECKS=%d SEGMENTS=%d PARTIAL=%d ALL_OPEN=%d\n'], ...
    numel(families),checked,segments,partiallyOpened,fullyOpened);

[none,s]=pastafari.unrankGeneralWeaveSuffixChunk([2 2],[2 2],0,0,1,0);
assert(isempty(none) && ~s.done && s.stepsComputed==0 && ...
    isequal(s.remaining,[2 2]), ...
    'Zero-step cursor must preserve its initial state.');
[none,s]=pastafari.unrankGeneralWeaveSuffixChunk([2 2],[0 0],2,2,1,10);
assert(isempty(none) && s.done && s.count==pastafari.BigInt(1), ...
    'Finished general cursor must remain terminal.');
mustReject([2 2],[2 2],1,0,1,1, ...
    'Pastafari:GeneralChunk:Reachability');
mustReject([2 2],[1 2],0,0,1,1, ...
    'Pastafari:GeneralChunk:Reachability');
mustReject([2 2],[2 2],0,0,0,1, ...
    'Pastafari:GeneralChunk:Rank');
mustReject([2 2],[2 2],0,0,1,-1, ...
    'Pastafari:GeneralChunk:StepLimit');
mustReject([2 2],[2 2],0,0,NaN,1, ...
    'Pastafari:Validation:IntegerInput');
% One forced opening preserves the ENTIRE exact rank and count:
% every fully-unopened legal family begins with month 1.
L=[4 4 4];
count=pastafari.countWholeWeavingSuffixByFirstEndpoint(L,0,0);
[forced,forcedState]=pastafari.unrankGeneralWeaveSuffixChunk( ...
    L,L,0,0,count,1);
assert(isequal(forced,1) && forcedState.openedUpTo==1 && ...
    forcedState.closedUpTo==0 && ...
    isequal(forcedState.remaining,[3 4 4]) && ...
    forcedState.rank==count && forcedState.count==count, ...
    'The forced first month must preserve exact all-words rank/count.');
fprintf('STAGE_55_GENERAL_CHUNK_FORCED_PREFIX_PASS\n');
% For a genuine branching pre-open frontier, the final child is
% computed by the exact parent-minus-prior-block identity.
L=[4 4 4];
R=[3 4 4]; % month 1 opened; month 2 still unopened
p=pastafari.countWholeWeavingSuffixByFirstEndpoint(R,1,0);
firstR=[2 4 4];
firstBlock=pastafari.countWholeWeavingSuffixByFirstEndpoint(firstR,1,0);
lastR=[3 3 4];
lastBlock=pastafari.countWholeWeavingSuffixByFirstEndpoint(lastR,2,0);
assert(firstBlock+lastBlock==p, ...
    'Two legal lexicographic child languages must exactly partition parent.');
[choice,lastState]=pastafari.unrankGeneralWeaveSuffixChunk( ...
    L,R,1,0,firstBlock+pastafari.BigInt(1),1);
assert(isequal(choice,2) && isequal(lastState.remaining,lastR) && ...
    lastState.rank==pastafari.BigInt(1) && lastState.count==lastBlock, ...
    'Last-child subtraction must preserve exact rank and count.');
fprintf('STAGE_55_GENERAL_CHUNK_LAST_CHILD_PARTITION_PASS\n');

% A 4-month frontier with precisely one month unopened uses exact
% binomial factorization and must match the independent DP.
L=[3 3 3 3];
R=[2 2 2 3];
fast=pastafari.countWholeWeavingSuffixByEndpoints(R,3,0);
reference=pastafari.countWholeWeavingSuffixByFirstEndpoint(R,3,0);
assert(fast==reference, ...
    'One unopened month exact factorization disagrees with DP.');
[choice,c]=pastafari.unrankGeneralWeaveSuffixChunk( ...
    L,R,3,0,fast,1);
assert(choice>=1 && choice<=4 && ...
    c.rank>=pastafari.BigInt(1) && c.rank<=c.count, ...
    'One-unopened factorized branch lost its exact lexicographic rank.');
fprintf('STAGE_55_GENERAL_CHUNK_ONE_UNOPENED_FACTOR_PASS\n');


fprintf('STAGE_55_GENERAL_CHUNK_VALIDATION_PASS\n');

% Bounded pre-open performance; NOT a 4244-day unrank claim.
L=repmat(10,1,8);
count=pastafari.countWholeWeavingSuffixByFirstEndpoint(L,0,0);
rank=count.floorDiv(pastafari.BigInt(2))+pastafari.BigInt(1);
started=tic;
[chunk,c]=pastafari.unrankGeneralWeaveSuffixChunk(L,L,0,0,rank,3);
seconds=toc(started);
assert(numel(chunk)==3 && sum(L)-sum(c.remaining)==3 && ...
    c.rank>=pastafari.BigInt(1) && c.rank<=c.count, ...
    'Reference initial-frontier chunk lost its exact rank/count.');
fprintf(['STAGE_55_GENERAL_CHUNK_PREOPEN_BENCH DAYS=80 MONTHS=8 ', ...
    'STEPS=3 SECONDS=%.3f RESULT=%s\n'], ...
    seconds,mat2str(chunk));
fprintf('STAGE_55_GENERAL_CHUNK_EXPERIMENTAL_PASS\n');
end

function rows=bruteAllLegal(L)
% Independent enumeration in increasing month-ID choice order.
K=numel(L); N=sum(L); row=zeros(1,N); rows=zeros(0,N);
visit(L,0,0,1);
    function visit(R,opened,closed,position)
        if position>N
            assert(all(R==0) && opened==K && closed==K);
            rows(end+1,:)=row; %#ok<AGROW>
            return
        end
        for i=1:K
            n=R(i);
            if n==0 || (n==L(i) && i~=opened+1) || ...
                    (n==1 && i~=closed+1)
                continue
            end
            next=R;
            next(i)=n-1;
            row(position)=i;
            visit(next,opened+double(n==L(i)), ...
                closed+double(n==1),position+1);
        end
    end
end

function mustReject(L,R,opened,closed,rank,steps,id)
matched=false;
try
    pastafari.unrankGeneralWeaveSuffixChunk( ...
        L,R,opened,closed,rank,steps);
catch err
    matched=strcmp(err.identifier,id);
end
assert(matched,'Expected strict rejection with identifier %s.',id);
end
