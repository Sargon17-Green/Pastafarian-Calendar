function run_stage55_adjoint_next_letter_tests()
% Brute-force independent suffix enumeration at every reachable frontier.
% The adjoint counter must return exactly every lexical next-letter block
% and sum to the independently verified scalar first-endpoint count.
here=fileparts(mfilename('fullpath'));
root=fileparts(here);
addpath(fullfile(root,'src'));
cleanup=onCleanup(@() rmpath(fullfile(root,'src'))); %#ok<NASGU>
families={[1 2 2],[2 3 2],[3 2 3],[2 2 2 2], ...
    [4 4 4],[3 2 2 3]};
one=pastafari.BigInt(1);
frontiers=0; blocks=0; inversions=0;
for f=1:numel(families)
    L=families{f};
    states=allStates(L);
    for s=1:numel(states)
        st=states{s};
        R=st.R; o=st.o; c=st.c; N=sum(R);
        words=allWords(L,R,o,c);
        ways=size(words,1);
        [parts,total]=pastafari.countWholeWeavingNextLetterBlocksAdjoint( ...
            R,o,c);
        assert(total==pastafari.BigInt(ways), ...
            'Adjoint total disagrees with independent enumeration.');
        if N==0
            assert(all(cellfun(@isempty,parts)), ...
                'Terminal frontier has no first-letter blocks.');
        else
            for j=1:numel(L)
                expected=sum(words(:,1)==j);
                if expected==0
                    assert(isempty(parts{j}), ...
                        'Adjoint counts an impossible first month.');
                else
                    assert(~isempty(parts{j}) && ...
                        parts{j}==pastafari.BigInt(expected), ...
                        'Adjoint first-letter block disagrees with enumeration.');
                end
                blocks=blocks+1;
            end
        end
        frontiers=frontiers+1;
        if f>4 && ways>25
            % Exhaustive block coverage still runs; select a few
            % inversion ranks to bound native MATLAB job duration.
            ranks=unique([1,ceil(ways/2),ways]);
        else
            ranks=1:ways;
        end
        for rank=ranks
            [word,cursor]=pastafari.unrankGeneralWeaveSuffixChunkAdjoint( ...
                L,R,o,c,pastafari.BigInt(rank),N);
            assert(isequal(word,words(rank,:)) && cursor.done && ...
                cursor.rank==one && cursor.count==one && ...
                cursor.initialCount==pastafari.BigInt(ways), ...
                'Adjoint exact unrank does not invert lexical rank.');
            inversions=inversions+1;
        end
    end
end
assert(frontiers>100 && blocks>200 && inversions>220, ...
    'Adjoint test did not cover expected exhaustive frontiers.');
fprintf(['STAGE_55_ADJOINT_BRUTE_PASS FAMILIES=%d ', ...
    'FRONTIERS=%d LABEL_BLOCKS=%d INVERSIONS=%d\n'], ...
    numel(families),frontiers,blocks,inversions);
fprintf('STAGE_55_ADJOINT_EXPERIMENTAL_PASS\n');
end

function states=allStates(L)
states={}; seen=containers.Map('KeyType','char','ValueType','logical');
visit(L,0,0);
    function visit(R,o,c)
        key=[sprintf('%d,',R) sprintf('|%d|%d',o,c)];
        if isKey(seen,key), return; end
        seen(key)=true;
        states{end+1}=struct('R',R,'o',o,'c',c); %#ok<AGROW>
        for j=1:numel(L)
            m=R(j);
            if m==0 || (m==L(j) && j~=o+1) || ...
                    (m==1 && j~=c+1)
                continue
            end
            next=R; next(j)=m-1;
            visit(next,o+double(m==L(j)),c+double(m==1));
        end
    end
end

function words=allWords(L,R,o,c)
N=sum(R); K=numel(L);
if N==0
    words=zeros(1,0); return
end
words=zeros(0,N); current=zeros(1,N);
visit(R,o,c,1);
    function visit(left,opened,closed,position)
        if position>N
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
            next=left; next(j)=n-1; current(position)=j;
            visit(next,opened+double(n==L(j)), ...
                closed+double(n==1),position+1);
        end
    end
end
