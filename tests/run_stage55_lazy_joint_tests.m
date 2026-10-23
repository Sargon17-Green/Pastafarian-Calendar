function run_stage55_lazy_joint_tests()
% Porównanie całych słów i kursorów z niezależnym dawnym DAG oraz
% referencyjną ścieżką joint. Wszystkie wartości pozostają dokładne.
here=fileparts(mfilename('fullpath'));
root=fileparts(here);
addpath(fullfile(root,'src'));
cleanup=onCleanup(@() rmpath(fullfile(root,'src'))); %#ok<NASGU>
vectors={[1],[2],[2 2],[2 2 2],[2 3 2], ...
    [3 2 3],[3 3 3],[4 4 4],[2 2 2 2]};
checked=0;
segments=0;
for f=1:numel(vectors)
    L=vectors{f};
    legacy=pastafari.WholeMonthWeavingFamily(L);
    last=legacy.count().toDoubleExact();
    if last<=100
        ranks=1:last;
    else
        ranks=unique([1 2 3 ceil(last/4) ceil(last/2) ...
            ceil(3*last/4) last-2 last-1 last]);
    end
    for n=ranks
        expected=legacy.itemAt1(pastafari.BigInt(n));
        for chunkSize=[1 2 4 7]
            R=L; opened=0; closed=0;
            rank=pastafari.BigInt(n);
            assembled=[];
            while true
                [a,c]=pastafari.unrankGeneralWeaveSuffixChunkLazyJoint( ...
                    L,R,opened,closed,rank,chunkSize);
                [b,d]=pastafari.unrankGeneralWeaveSuffixChunk( ...
                    L,R,opened,closed,rank,chunkSize,'joint');
                assert(isequal(a,b) && ...
                    isequal(c.remaining,d.remaining) && ...
                    c.openedUpTo==d.openedUpTo && ...
                    c.closedUpTo==d.closedUpTo && ...
                    c.rank==d.rank && c.count==d.count && ...
                    c.initialCount== ...
                        pastafari.countWholeWeavingSuffixByFirstEndpoint( ...
                            R,opened,closed) && ...
                    c.done==d.done, ...
                    'Dokładne kursory dwóch tras nie są równoważne.');
                assembled=[assembled a]; %#ok<AGROW>
                segments=segments+1;
                if c.done
                    break
                end
                R=c.remaining;
                opened=c.openedUpTo;
                closed=c.closedUpTo;
                rank=c.rank;
            end
            assert(isequal(assembled,expected), ...
                'Całe słowo nie zgadza się z historycznym DAG.');
            checked=checked+1;
        end
    end
end
fprintf(['STAGE_55_LAZY_JOINT_BRUTE_PASS FAMILIES=%d ', ...
    'RANK_CHECKS=%d SEGMENTS=%d\n'],numel(vectors),checked,segments);

[empty,c]=pastafari.unrankGeneralWeaveSuffixChunkLazyJoint( ...
    [2 2],[2 2],0,0,1,0);
assert(isempty(empty) && ~c.done && c.count==pastafari.BigInt(2), ...
    'Zerowy krok musi zwrócić zweryfikowaną liczność.');
[empty,c]=pastafari.unrankGeneralWeaveSuffixChunkLazyJoint( ...
    [2 2],[0 0],2,2,1,5);
assert(isempty(empty) && c.done && c.count==pastafari.BigInt(1), ...
    'Stan końcowy musi być zwrócony dokładnie.');
assertReject([2 2],[2 2],0,0,3,1, ...
    'Pastafari:LazyJoint:Rank');
assertReject([2 2],[1 2],0,0,1,1, ...
    'Pastafari:LazyJoint:Reachability');
assertReject([2 2],[2 2],0,0,1,-1, ...
    'Pastafari:LazyJoint:StepLimit');
fprintf('STAGE_55_LAZY_JOINT_VALIDATION_PASS\n');

L=repmat(10,1,8);
total=pastafari.countWholeWeavingSuffixByFirstEndpoint(L,0,0);
for idx=1:3
    if idx==1
        rank=pastafari.BigInt(1);
    elseif idx==2
        rank=total.floorDiv(pastafari.BigInt(2))+pastafari.BigInt(1);
    else
        rank=total;
    end
    timer=tic;
    [a,c]=pastafari.unrankGeneralWeaveSuffixChunkLazyJoint( ...
        L,L,0,0,rank,3);
    elapsed=toc(timer);
    [b,d]=pastafari.unrankGeneralWeaveSuffixChunk( ...
        L,L,0,0,rank,3,'joint');
    assert(isequal(a,b) && isequal(c.remaining,d.remaining) && ...
        c.rank==d.rank && c.count==d.count, ...
        '80 dni: rozbieżność dokładnej rangi.');
    fprintf(['STAGE_55_LAZY_JOINT_BENCH DAYS=80 MONTHS=8 ', ...
        'STEPS=3 RANK_CASE=%d SECONDS=%.3f\n'],idx,elapsed);
end
fprintf('STAGE_55_LAZY_JOINT_EXPERIMENTAL_PASS\n');
end

function assertReject(L,R,opened,closed,rank,steps,expected)
matched=false;
try
    pastafari.unrankGeneralWeaveSuffixChunkLazyJoint( ...
        L,R,opened,closed,rank,steps);
catch err
    matched=strcmp(err.identifier,expected);
end
assert(matched,'Brak spodziewanego odrzucenia: %s.',expected);
end
