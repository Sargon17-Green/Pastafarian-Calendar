function run_stage55_binary_first_letter_tests()
% Completely independent exhaustive lexical suffix oracle for all
% reachable small opening/closing frontiers. Checks exact cumulative
% first-label count and the binary rank->word->rank interval identity.
here=fileparts(mfilename('fullpath'));
root=fileparts(here);
addpath(fullfile(root,'src'));
cleanup=onCleanup(@() rmpath(fullfile(root,'src'))); %#ok<NASGU>
families={[1 2 2],[2 3 2],[3 2 3],[2 2 2 2]};
frontiers=0; thresholds=0; inversions=0; chunks=0;
one=pastafari.BigInt(1);
for f=1:numel(families)
    L=families{f};
    states=allStates(L);
    K=numel(L);
    for s=1:numel(states)
        st=states{s};
        R=st.R; o=st.o; c=st.c; N=sum(R);
        words=allWords(L,R,o,c);
        ways=size(words,1);
        assert(ways>=1);
        frontiers=frontiers+1;
        if N>0
            prev=0;
            for t=0:K
                observed=pastafari.countWholeWeavingFirstLetterUpTo( ...
                    R,o,c,t);
                expected=sum(words(:,1)<=t);
                assert(observed==pastafari.BigInt(expected) && ...
                    observed>=pastafari.BigInt(prev), ...
                    'First-letter threshold count contradicts enumeration.');
                prev=expected;
                thresholds=thresholds+1;
            end
            assert(prev==ways,'Last threshold must cover all completions.');
        end
        for rank=1:ways
            expected=words(rank,:);
            [whole,a]=pastafari.unrankGeneralWeaveSuffixChunkBinary( ...
                L,R,o,c,pastafari.BigInt(rank),N);
            assert(isequal(whole,expected) && a.done && ...
                a.rank==one && a.count==one && ...
                a.initialCount==pastafari.BigInt(ways), ...
                'Binary exact unrank contradicts brute-force lexical rank.');
            inversions=inversions+1;
            if N>0
                firstSteps=floor(N/2);
                [first,partial]=pastafari.unrankGeneralWeaveSuffixChunkBinary( ...
                    L(:),R(:),o,c,pastafari.BigInt(rank),firstSteps);
                [last,endCursor]=pastafari.unrankGeneralWeaveSuffixChunkBinary( ...
                    L,partial.remaining,partial.openedUpTo, ...
                    partial.closedUpTo,partial.rank,N-firstSteps);
                assert(isequal([first,last],expected) && endCursor.done && ...
                    partial.count==endCursor.initialCount && ...
                    endCursor.count==one, ...
                    'Binary exact rank was corrupted when chunked/resumed.');
                [lo,hi,inverse]=pastafari.rankGeneralWeavePrefix( ...
                    L,R,o,c,first,'reference');
                assert(lo<=pastafari.BigInt(rank) && ...
                    hi>=pastafari.BigInt(rank) && ...
                    hi-lo+one==partial.count && ...
                    pastafari.BigInt(rank)-lo+one==partial.rank && ...
                    inverse.totalCount==pastafari.BigInt(ways), ...
                    'Partial binary rank contradicts independent inverse.');
                chunks=chunks+1;
            end
        end
    end
end
assert(frontiers==53 && inversions==208 && thresholds>150 && ...
    chunks>150, 'Unexpected amount of exact coverage.');
fprintf(['STAGE_55_BINARY_FIRST_LETTER_BRUTE_PASS ', ...
    'FAMILIES=%d FRONTIERS=%d THRESHOLDS=%d ', ...
    'INVERSIONS=%d CHUNKS=%d\n'], ...
    numel(families),frontiers,thresholds,inversions,chunks);
reject(@() pastafari.countWholeWeavingFirstLetterUpTo( ...
    [2 2],0,0,1.5),'Pastafari:FirstLetterUpTo:Threshold');
reject(@() pastafari.countWholeWeavingFirstLetterUpTo( ...
    [0 0],2,2,1),'Pastafari:FirstLetterUpTo:Terminal');
reject(@() pastafari.unrankGeneralWeaveSuffixChunkBinary( ...
    [2 2],[2 2],0,0,pastafari.BigInt(999),2), ...
    'Pastafari:BinaryUnrank:Rank');
fprintf('STAGE_55_BINARY_FIRST_LETTER_VALIDATION_PASS\n');
fprintf('STAGE_55_BINARY_FIRST_LETTER_EXPERIMENTAL_PASS\n');
end

function reject(fn,id)
matched=false;
try
    fn();
catch err
    matched=strcmp(err.identifier,id);
end
assert(matched,'Expected error identifier %s',id);
end

function states=allStates(L)
states={}; seen=containers.Map('KeyType','char','ValueType','logical');
visit(L,0,0);
    function visit(R,o,c)
        key=[sprintf('%d,',R) sprintf('|%d|%d',o,c)];
        if isKey(seen,key), return; end
        seen(key)=true;
        states{end+1}=struct('R',R,'o',o,'c',c); %#ok<AGROW>
        for i=1:numel(L)
            n=R(i);
            if n==0 || (n==L(i) && i~=o+1) || ...
                    (n==1 && i~=c+1)
                continue
            end
            child=R; child(i)=n-1;
            visit(child,o+double(n==L(i)),c+double(n==1));
        end
    end
end

function words=allWords(L,R,o,c)
N=sum(R); K=numel(L);
if N==0
    assert(o==K && c==K);
    words=zeros(1,0); return
end
words=zeros(0,N); current=zeros(1,N);
visit(R,o,c,1);
    function visit(left,opened,closed,p)
        if p>N
            assert(all(left==0) && opened==K && closed==K);
            words(end+1,:)=current; %#ok<AGROW>
            return
        end
        for i=1:K
            n=left(i);
            if n==0 || (n==L(i) && i~=opened+1) || ...
                    (n==1 && i~=closed+1)
                continue
            end
            child=left; child(i)=n-1; current(p)=i;
            visit(child,opened+double(n==L(i)), ...
                closed+double(n==1),p+1);
        end
    end
end
