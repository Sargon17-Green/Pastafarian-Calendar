function run_stage55_all_frontier_inverse_tests()
% Independent exhaustive suffix oracle at EVERY reachable opening/closing
% frontier for small families. Checks both exact rank/unrank directions.
% This test does not modify production code or normative_oracle.
here=fileparts(mfilename('fullpath'));
root=fileparts(here);
addpath(fullfile(root,'src'));
cleanup=onCleanup(@() rmpath(fullfile(root,'src'))); %#ok<NASGU>

families={[1 2 2],[2 3 2],[3 2 3],[2 2 2 2]};
frontiers=0;
inversions=0;
intervals=0;
columnChecks=0;
partialCheckpoint=false;
one=pastafari.BigInt(1);
for f=1:numel(families)
    L=families{f};
    states=reachableFrontiers(L);
    for s=1:numel(states)
        state=states{s};
        R=state.remaining;
        o=state.openedUpTo;
        c=state.closedUpTo;
        N=sum(R);
        words=independentSuffixes(L,R,o,c);
        ways=size(words,1);
        assert(ways>=1,'Reachable frontier has no legal completions.');
        expectedTotal=pastafari.BigInt(ways);
        frontiers=frontiers+1;

        for r=1:ways
            rank=pastafari.BigInt(r);
            expected=words(r,:);
            [wordA,a]=pastafari.unrankGeneralWeaveSuffixChunk( ...
                L,R,o,c,rank,N,'reference');
            [wordB,b]=pastafari.unrankGeneralWeaveSuffixChunk( ...
                L,R,o,c,rank,N,'joint');
            [wordC,d]=pastafari.unrankGeneralWeaveSuffixChunkLazyJoint( ...
                L,R,o,c,rank,N);
            assert(isequal(wordA,expected) && isequal(wordB,expected) && ...
                isequal(wordC,expected), ...
                'Unrank engines disagree with independently enumerated suffix.');
            assert(a.done && b.done && d.done && ...
                a.rank==one && b.rank==one && d.rank==one && ...
                a.count==one && b.count==one && d.count==one && ...
                d.initialCount==expectedTotal && ...
                a.openedUpTo==numel(L) && a.closedUpTo==numel(L) && ...
                all(a.remaining==0) && all(b.remaining==0) && ...
                all(d.remaining==0), ...
                'Complete unrank did not reach the unique terminal cursor.');
            inversions=inversions+1;

            % Exhaustively verify distinct lexical ranks, but sample
            % prefix depths to bound native execution time.
            depths=unique([0 min(1,N) floor(N/2) N]);
            for depth=depths
                prefix=expected(1:depth);
                if depth==0
                    hits=1:ways;
                else
                    hits=find(all(words(:,1:depth)== ...
                        repmat(prefix,ways,1),2)).';
                end
                assert(~isempty(hits) && ...
                    isequal(hits,hits(1):hits(end)), ...
                    'Independent suffix oracle is not lexicographically grouped.');
                for method={'joint','reference'}
                    [lo,hi,inv]=pastafari.rankGeneralWeavePrefix( ...
                        L,R,o,c,prefix,method{1});
                    assert(lo==pastafari.BigInt(hits(1)) && ...
                        hi==pastafari.BigInt(hits(end)) && ...
                        inv.totalCount==expectedTotal && ...
                        inv.count==pastafari.BigInt(numel(hits)) && ...
                        inv.stepsComputed==depth && ...
                        sum(inv.remaining)==N-depth, ...
                        'Prefix interval differs from independent suffix oracle.');
                    intervals=intervals+1;
                end
            end

            % Same legal state must accept either column or row vectors.
            % MATLAB implicit expansion is not a valid vector comparison.
            if r==1
                [colWord,colCursor]=pastafari.unrankGeneralWeaveSuffixChunk( ...
                    L(:),R(:),o,c,rank,N,'reference');
                assert(isequal(colWord,expected) && colCursor.done && ...
                    colCursor.count==one, ...
                    'Column-oriented month vector changes exact unrank.');
                columnChecks=columnChecks+1;
            end
        end

        % JSON restore must independently verify a genuine partly opened
        % state, not merely the all-open suffix.
        if ~partialCheckpoint && o>0 && o<numel(L) && N>1 && ways>1
            [~,partial]=pastafari.unrankGeneralWeaveSuffixChunkLazyJoint( ...
                L,R,o,c,one,0);
            partial.stepsComputed=0;
            json=pastafari.serializeExactWeaveCursorJson(L,partial);
            [restoredLengths,restored]= ...
                pastafari.restoreExactWeaveCursorJson(json);
            assert(isequal(restoredLengths,L) && ...
                isequal(restored.remaining,R) && ...
                restored.openedUpTo==o && restored.closedUpTo==c && ...
                restored.count==expectedTotal && restored.rank==one, ...
                'Partial-frontier JSON restore altered an exact cursor.');
            partialCheckpoint=true;
        end
    end
end
assert(frontiers>=40 && inversions>=150 && intervals>=500 && ...
    columnChecks==frontiers && partialCheckpoint, ...
    'Independent frontier regression did not cover its required scope.');
fprintf(['STAGE_55_ALL_FRONTIER_INVERSE_BRUTE_PASS ', ...
    'FAMILIES=%d FRONTIERS=%d COMPLETE_INVERSIONS=%d ', ...
    'PREFIX_INTERVALS=%d COLUMN_CHECKS=%d\n'], ...
    numel(families),frontiers,inversions,intervals,columnChecks);
fprintf('STAGE_55_ALL_FRONTIER_PARTIAL_JSON_PASS\n');
fprintf('STAGE_55_ALL_FRONTIER_INVERSE_EXPERIMENTAL_PASS\n');
end

function states=reachableFrontiers(L)
% Derive each unique state by a separate direct legal-move DFS.
K=numel(L);
states=cell(0,1);
seen=containers.Map('KeyType','char','ValueType','logical');
visit(L,0,0);
    function visit(R,o,c)
        key=sprintf('%d,',R);
        key=sprintf('%s|%d|%d',key,o,c);
        if isKey(seen,key)
            return
        end
        seen(key)=true;
        states{end+1,1}=struct('remaining',R, ...
            'openedUpTo',o,'closedUpTo',c); %#ok<AGROW>
        if ~any(R)
            return
        end
        for i=1:K
            n=R(i);
            if n==0 || (n==L(i) && i~=o+1) || ...
                    (n==1 && i~=c+1)
                continue
            end
            child=R;
            child(i)=n-1;
            visit(child,o+double(n==L(i)),c+double(n==1));
        end
    end
end

function words=independentSuffixes(L,R,o,c)
% Exhaustively enumerate each complete suffix without any production
% counter or ranked algorithm; loop order gives lexical order.
K=numel(L);
N=sum(R);
if N==0
    assert(o==K && c==K);
    words=zeros(1,0);
    return
end
words=zeros(0,N);
current=zeros(1,N);
visit(R,o,c,1);
    function visit(left,opened,closed,pos)
        if pos>N
            assert(all(left==0) && opened==K && closed==K);
            words(end+1,:)=current; %#ok<AGROW>
            return
        end
        for j=1:K
            n=left(j);
            if n==0 || (n==L(j) && j~=opened+1) || ...
                    (n==1 && j~=closed+1)
                continue
            end
            child=left;
            child(j)=n-1;
            current(pos)=j;
            visit(child,opened+double(n==L(j)), ...
                closed+double(n==1),pos+1);
        end
    end
end
