function run_stage55_joint_next_blocks_tests()
% Independently enumerate every legal reachable frontier and next letter.
here=fileparts(mfilename('fullpath'));
root=fileparts(here);
addpath(fullfile(root,'src'));
cleanup=onCleanup(@() rmpath(fullfile(root,'src'))); %#ok<NASGU>

families=0;
states=0;
children=0;
for K=1:5
    for encoded=0:3^K-1
        L=zeros(1,K);
        q=encoded;
        for j=1:K
            L(j)=mod(q,3)+1;
            q=floor(q/3);
        end
        pending={{L,0,0}};
        seen=containers.Map('KeyType','char','ValueType','logical');
        memo=containers.Map('KeyType','char','ValueType','double');
        while ~isempty(pending)
            item=pending{end};
            pending(end)=[];
            R=item{1};
            opened=item{2};
            closed=item{3};
            key=sprintf('%d,',[R,opened,closed]);
            if isKey(seen,key)
                continue
            end
            seen(key)=true;
            [blocks,total]=pastafari.countWholeWeavingNextLetterBlocksOnePass( ...
                R,opened,closed);
            expected=pastafari.countWholeWeavingSuffixByFirstEndpoint( ...
                R,opened,closed);
            assert(total==expected, ...
                'Joint first-letter count disagrees with independent DP.');
            aggregate=pastafari.BigInt(0);
            for i=1:K
                n=R(i);
                allowed=n>0 && ...
                    ~(n==L(i) && i~=opened+1) && ...
                    ~(n==1 && i~=closed+1);
                if ~allowed
                    assert(isempty(blocks{i}), ...
                        'Illegal next month has a nonzero lexical block.');
                    continue
                end
                child=R;
                child(i)=n-1;
                nextOpened=opened+double(n==L(i));
                nextClosed=closed+double(n==1);
                exact=brute(child,L,nextOpened,nextClosed,memo);
                assert(~isempty(blocks{i}) && ...
                    blocks{i}==pastafari.BigInt(exact), ...
                    'Joint next-month lexical block mismatches brute oracle.');
                aggregate=aggregate+blocks{i};
                pending{end+1}={child,nextOpened,nextClosed}; %#ok<AGROW>
                children=children+1;
            end
            if all(R==0)
                assert(total==pastafari.BigInt(1) && ...
                    all(cellfun(@isempty,blocks)), ...
                    'Terminal suffix must have exactly one empty word.');
            else
                assert(aggregate==total, ...
                    'Disjoint lexical next-child blocks do not partition parent.');
            end
            states=states+1;
        end
        families=families+1;
    end
end
assert(families==363 && states>=6651 && children>6000, ...
    'Expected full small-case reachable-state matrix.');
fprintf(['STAGE_55_JOINT_NEXT_EXHAUSTIVE_PASS ', ...
    'FAMILIES=%d STATES=%d CHILDREN=%d\n'], ...
    families,states,children);

% Modest performance measurements; no unverified extrapolation to 4244.
sizes={repmat(10,1,8),repmat(20,1,12)};
for caseNo=1:numel(sizes)
    L=sizes{caseNo};
    % First symbol is forced for a fully unopened family.
    started=tic;
    [blocks,total]=pastafari.countWholeWeavingNextLetterBlocksOnePass( ...
        L,0,0);
    seconds=toc(started);
    reference=pastafari.countWholeWeavingSuffixByFirstEndpoint(L,0,0);
    assert(total==reference && blocks{1}==total, ...
        'Full-unopened first-letter distribution is incorrect.');
    assert(all(cellfun(@isempty,blocks(2:end))), ...
        'Unopened month beyond first must have zero next-letter block.');
    fprintf(['STAGE_55_JOINT_NEXT_BENCH MONTHS=%d DAYS=%d ', ...
        'SECONDS=%.3f DIGITS=%d\n'], ...
        numel(L),sum(L),seconds,numel(char(total)));
end
fprintf('STAGE_55_JOINT_NEXT_EXPERIMENTAL_PASS\n');
end

function count=brute(R,L,opened,closed,memo)
if all(R==0)
    assert(opened==numel(L) && closed==numel(L));
    count=1;
    return
end
key=sprintf('%d,',[R,opened,closed]);
if isKey(memo,key)
    count=memo(key);
    return
end
count=0;
for i=1:numel(L)
    n=R(i);
    if n==0 || (n==L(i) && i~=opened+1) || ...
            (n==1 && i~=closed+1)
        continue
    end
    next=R;
    next(i)=n-1;
    count=count+brute(next,L, ...
        opened+double(n==L(i)),closed+double(n==1),memo);
end
assert(count<=flintmax,'Brute oracle must remain exactly representable.');
memo(key)=count;
end
