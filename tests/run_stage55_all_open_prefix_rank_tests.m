function run_stage55_all_open_prefix_rank_tests()
% Exact forward-prefix interval ranks vs independent lexical word
% enumeration; inverse of separate rank->letters algorithms.
here=fileparts(mfilename('fullpath'));
root=fileparts(here);
addpath(fullfile(root,'src'));
cleanup=onCleanup(@() rmpath(fullfile(root,'src'))); %#ok<NASGU>

families={[1],[2 1],[2 2],[2 2 2], ...
    [3 2 2],[2 3 2],[2 2 2 2],[1 2 1 2],[4 2 1]};
cases=0; intervals=0;
for f=1:numel(families)
    L=families{f};
    words=bruteAllOpen(L);
    total=pastafari.countWholeWeavingSuffixByEndpoints( ...
        L,numel(L),0);
    assert(total==pastafari.BigInt(size(words,1)));
    for row=1:size(words,1)
        for prefixSize=0:sum(L)
            prefix=words(row,1:prefixSize);
            if prefixSize==0
                hits=1:size(words,1);
            else
                hits=find(all(words(:,1:prefixSize)== ...
                    repmat(prefix,size(words,1),1),2));
            end
            assert(~isempty(hits) && ...
                isequal(hits(:).',(hits(1):hits(end))), ...
                'Independent prefixes must be one contiguous interval.');
            for method={'common','rational'}
                [lo,hi,c]=pastafari.rankAllOpenedWeavePrefix( ...
                    L,0,prefix,method{1});
                assert(lo==pastafari.BigInt(hits(1)) && ...
                    hi==pastafari.BigInt(hits(end)) && ...
                    hi-lo+pastafari.BigInt(1)==c.count && ...
                    c.totalCount==total && ...
                    sum(c.remaining)==sum(L)-prefixSize && ...
                    c.stepsComputed==prefixSize && ...
                    c.done==(prefixSize==sum(L)), ...
                    'Prefix rank interval disagrees with independent words.');
                intervals=intervals+1;
            end
        end
    end
    cases=cases+1;
end
assert(cases==9 && intervals>3000, ...
    'Full independent prefix-rank matrix unexpectedly small.');
fprintf(['STAGE_55_ALL_OPEN_PREFIX_RANK_BRUTE_PASS ', ...
    'FAMILIES=%d INTERVAL_CHECKS=%d\n'],cases,intervals);

assertReject([2 2],0,[2 2], ...
    'Pastafari:AllOpenPrefixRank:IllegalLetter');
assertReject([2 2],0,[1 1 2 2 1], ...
    'Pastafari:AllOpenPrefixRank:Days');
assertReject([2 2],0,[2.5], ...
    'Pastafari:AllOpenPrefixRank:Prefix');
assertReject([2 2],0,[0], ...
    'Pastafari:AllOpenPrefixRank:Prefix');
assertReject([2 2],0,[3], ...
    'Pastafari:AllOpenPrefixRank:Prefix');
assertReject([2 0],0,[], ...
    'Pastafari:AllOpenPrefixRank:Frontier');
[lo,hi,terminal]=pastafari.rankAllOpenedWeavePrefix([0 0],2,[]);
assert(lo==pastafari.BigInt(1) && ...
    hi==pastafari.BigInt(1) && terminal.done);
fprintf('STAGE_55_ALL_OPEN_PREFIX_RANK_VALIDATION_PASS\n');

% Exactly the REAL year-5000 production vector after ALL months have
% opened once; this is a 4199-day remaining suffix, not the 4244-day
% unopened full year. Check exact arbitrary middle-rank interval.
L=[115 108 119 109 106 81 115 114 117 120 98 52 81 97 121 ...
   97 115 96 107 61 106 115 119 39 84 103 115 107 55 119 ...
   97 50 122 110 81 54 101 83 88 40 25 77 98 122 105];
R=L-1;
assert(numel(R)==45 && sum(R)==4199);
total=pastafari.countWholeWeavingSuffixByEndpoints(R,45,0);
rank=total.floorDiv(pastafari.BigInt(2))+pastafari.BigInt(1);
start=tic;
[part,state]=pastafari.unrankAllOpenedWeaveSuffixChunk( ...
    R,0,rank,96,'common');
unrankSeconds=toc(start);
started=tic;
[lo,hi,c]=pastafari.rankAllOpenedWeavePrefix(R,0,part,'rational');
rankSeconds=toc(started);
assert(numel(part)==96 && ...
    isequal(c.remaining,state.remaining) && ...
    c.closedUpTo==state.closedUpTo && ...
    c.count==state.count && ...
    c.totalCount==total && c.firstRank==lo && ...
    c.lastRank==hi && ...
    rank>=lo && rank<=hi && ...
    rank-lo+pastafari.BigInt(1)==state.rank && ...
    hi-lo+pastafari.BigInt(1)==state.count, ...
    'Independent 4199-day rank/unrank exact cursor mismatch.');
fprintf(['STAGE_55_REAL_YEAR_ALL_OPEN_PREFIX_INVERSE_PASS ', ...
    'MONTHS=45 DAYS=4199 STEPS=96 DIGITS=%d ', ...
    'UNRANK_SECONDS=%.3f INVERSE_SECONDS=%.3f\n'], ...
    numel(char(total)),unrankSeconds,rankSeconds);
fprintf('STAGE_55_ALL_OPEN_PREFIX_RANK_EXPERIMENTAL_PASS\n');
end

function words=bruteAllOpen(L)
K=numel(L); N=sum(L); word=zeros(1,N);words=zeros(0,N);
walk(L,0,1);
    function walk(R,c,p)
        if p>N
            assert(all(R==0) && c==K);
            words(end+1,:)=word; %#ok<AGROW>
            return
        end
        for i=1:K
            n=R(i);
            if n==0 || (n==1 && i~=c+1)
                continue
            end
            next=R;
            next(i)=n-1;
            word(p)=i;
            walk(next,c+double(n==1),p+1);
        end
    end
end

function assertReject(R,c,p,id)
caught=false;
try
    pastafari.rankAllOpenedWeavePrefix(R,c,p);
catch err
    caught=strcmp(err.identifier,id);
end
assert(caught,'Expected strict prefix rank rejection %s',id);
end
