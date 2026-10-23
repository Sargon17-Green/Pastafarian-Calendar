function run_stage55_general_prefix_rank_tests()
% Exact rank intervals for OPENING and CLOSING frontiers, checked against
% an independent enumeration of all complete canonical legal words.
here=fileparts(mfilename('fullpath'));
root=fileparts(here);
addpath(fullfile(root,'src'));
cleanup=onCleanup(@() rmpath(fullfile(root,'src'))); %#ok<NASGU>

families={[1],[2],[2 2],[2 2 2],[2 3 2], ...
    [3 2 3],[3 3 3],[4 4 4],[2 2 2 2]};
checked=0;
for f=1:numel(families)
    L=families{f};
    words=independentWords(L);
    legacy=pastafari.WholeMonthWeavingFamily(L);
    count=legacy.count();
    assert(count==pastafari.BigInt(size(words,1)), ...
        'Independent complete-word enumeration contradicts old DAG.');
    if size(words,1)<=100
        ranks=1:size(words,1);
    else
        ranks=unique([1 2 3 ceil(size(words,1)/4), ...
            ceil(size(words,1)/2),ceil(3*size(words,1)/4), ...
            size(words,1)-2 size(words,1)-1 size(words,1)]);
    end
    N=sum(L);
    positions=unique([0 1 2 3 floor(N/2) N]);
    for r=ranks
        assert(isequal(words(r,:),legacy.itemAt1(pastafari.BigInt(r))), ...
            'Independent lexicographic order and DAG rank disagree.');
        for depth=positions
            p=words(r,1:depth);
            if depth==0
                hits=1:size(words,1);
            else
                hits=find(all(words(:,1:depth)== ...
                    repmat(p,size(words,1),1),2));
            end
            assert(~isempty(hits) && ...
                isequal(hits(:).',hits(1):hits(end)), ...
                'A fixed legal prefix must occupy contiguous ranks.');
            for method={'joint','reference'}
                [lo,hi,c]=pastafari.rankGeneralWeavePrefix( ...
                    L,L,0,0,p,method{1});
                assert(lo==pastafari.BigInt(hits(1)) && ...
                    hi==pastafari.BigInt(hits(end)) && ...
                    hi-lo+pastafari.BigInt(1)==c.count && ...
                    c.totalCount==count && ...
                    c.stepsComputed==depth && ...
                    sum(c.remaining)==N-depth && ...
                    c.done==(depth==N), ...
                    'Exact general prefix rank interval differs from oracle.');
                checked=checked+1;
            end
        end
    end
end
assert(checked>600 && numel(families)==9, ...
    'Small independent rank-interval regression is too short.');
fprintf(['STAGE_55_GENERAL_PREFIX_RANK_BRUTE_PASS ', ...
    'FAMILIES=%d INTERVAL_CHECKS=%d\n'],numel(families),checked);

reject([2 2],[2 2],0,0,[2], ...
    'Pastafari:GeneralPrefixRank:IllegalLetter');
reject([2 2],[2 2],0,0,[1 2 2], ...
    'Pastafari:GeneralPrefixRank:IllegalLetter');
reject([2 2],[2 2],0,0,[1 2 2 1 1], ...
    'Pastafari:GeneralPrefixRank:Days');
reject([2 2],[2 2],0,0,[1.5], ...
    'Pastafari:GeneralPrefixRank:Prefix');
reject([2 2],[1 2],0,0,[], ...
    'Pastafari:GeneralPrefixRank:Frontier');
[lo,hi,c]=pastafari.rankGeneralWeavePrefix( ...
    [2 2],[0 0],2,2,[]);
assert(lo==pastafari.BigInt(1) && hi==pastafari.BigInt(1) && ...
    c.done && c.count==pastafari.BigInt(1));
fprintf('STAGE_55_GENERAL_PREFIX_RANK_VALIDATION_PASS\n');

% Arbitrary reachable mid-frontier, NOT only from full unopened state:
L=[4 4 4];
R=[3 3 4]; opened=2; closed=0;
joint=pastafari.countWholeWeavingSuffixByFirstEndpoint( ...
    R,opened,closed);
[lo,hi,c]=pastafari.rankGeneralWeavePrefix( ...
    L,R,opened,closed,[1 3],'joint');
[lo2,hi2,d]=pastafari.rankGeneralWeavePrefix( ...
    L,R,opened,closed,[1 3],'reference');
assert(lo==lo2 && hi==hi2 && c.count==d.count && ...
    c.totalCount==joint && d.totalCount==joint && ...
    c.openedUpTo==d.openedUpTo && ...
    isequal(c.remaining,d.remaining), ...
    'Mid-frontier exact general prefix methods disagree.');
fprintf('STAGE_55_GENERAL_PREFIX_RANK_MID_FRONTIER_PASS\n');
fprintf('STAGE_55_GENERAL_PREFIX_RANK_EXPERIMENTAL_PASS\n');
end

function ways=independentWords(L)
K=numel(L); N=sum(L); current=zeros(1,N); ways=zeros(0,N);
visit(L,0,0,1);
    function visit(R,o,c,pos)
        if pos>N
            assert(all(R==0) && o==K && c==K);
            ways(end+1,:)=current; %#ok<AGROW>
            return
        end
        for i=1:K
            n=R(i);
            if n==0 || (n==L(i) && i~=o+1) || ...
                    (n==1 && i~=c+1)
                continue
            end
            rest=R; rest(i)=rest(i)-1;
            current(pos)=i;
            visit(rest,o+double(n==L(i)), ...
                c+double(n==1),pos+1);
        end
    end
end

function reject(L,R,o,c,p,id)
found=false;
try
    pastafari.rankGeneralWeavePrefix(L,R,o,c,p);
catch err
    found=strcmp(err.identifier,id);
end
assert(found,'Expected input rejection %s',id);
end
