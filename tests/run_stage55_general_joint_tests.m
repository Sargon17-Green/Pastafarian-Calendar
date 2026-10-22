function run_stage55_general_joint_tests()
% Native end-to-end general arbitrary-frontier chunk rank comparison.
% Compare the new joint next-letter DP to BOTH the legacy production DAG
% and the previously native-validated separate-children reference route.
here=fileparts(mfilename('fullpath'));
root=fileparts(here);
addpath(fullfile(root,'src'));
cleanup=onCleanup(@() rmpath(fullfile(root,'src'))); %#ok<NASGU>

families={[2 2],[2 2 2],[2 3 2],[3 2 3], ...
    [3 3 3],[4 4 4],[2 2 2 2],[3 2 2 2]};
compared=0;
transitions=0;
for k=1:numel(families)
    L=families{k};
    family=pastafari.WholeMonthWeavingFamily(L);
    last=family.count().toDoubleExact();
    if last<=100
        ranks=1:last;
    else
        ranks=unique([1 2 3 ceil(last/4) ceil(last/2) ...
            ceil(3*last/4) last-2 last-1 last]);
    end
    for rankNo=ranks
        expected=family.itemAt1(pastafari.BigInt(rankNo));
        for maxSteps=[1 2 4]
            R=L;
            opened=0;
            closed=0;
            rank=pastafari.BigInt(rankNo);
            out=[];
            while true
                [jointPiece,jointState]= ...
                    pastafari.unrankGeneralWeaveSuffixChunk( ...
                        L,R,opened,closed,rank,maxSteps,'joint');
                [oldPiece,oldState]= ...
                    pastafari.unrankGeneralWeaveSuffixChunk( ...
                        L,R,opened,closed,rank,maxSteps,'reference');
                assert(isequal(jointPiece,oldPiece) && ...
                    isequal(jointState.remaining,oldState.remaining) && ...
                    jointState.openedUpTo==oldState.openedUpTo && ...
                    jointState.closedUpTo==oldState.closedUpTo && ...
                    jointState.rank==oldState.rank && ...
                    jointState.count==oldState.count && ...
                    jointState.done==oldState.done, ...
                    'Joint and reference exact chunk cursors differ.');
                out=[out jointPiece]; %#ok<AGROW>
                transitions=transitions+1;
                if jointState.done
                    break
                end
                R=jointState.remaining;
                opened=jointState.openedUpTo;
                closed=jointState.closedUpTo;
                rank=jointState.rank;
            end
            assert(isequal(out,expected), ...
                'Joint full lexical weaving differs from production DAG.');
            compared=compared+1;
        end
    end
end
fprintf(['STAGE_55_GENERAL_JOINT_LEXICAL_PASS ', ...
    'FAMILIES=%d RANK_PARTITIONS=%d SEGMENTS=%d\n'], ...
    numel(families),compared,transitions);

expectMethodError([2 2],'approximate');
fprintf('STAGE_55_GENERAL_JOINT_VALIDATION_PASS\n');

% Medium-size, still bounded, arbitrary-frontier performance.
L=repmat(10,1,8);
parent=pastafari.countWholeWeavingSuffixByFirstEndpoint(L,0,0);
ranks={pastafari.BigInt(1), ...
    parent.floorDiv(pastafari.BigInt(2))+pastafari.BigInt(1),parent};
for j=1:numel(ranks)
    rank=ranks{j};
    timer=tic;
    [a,c]=pastafari.unrankGeneralWeaveSuffixChunk( ...
        L,L,0,0,rank,3,'joint');
    duration=toc(timer);
    [b,d]=pastafari.unrankGeneralWeaveSuffixChunk( ...
        L,L,0,0,rank,3,'reference');
    assert(isequal(a,b) && isequal(c.remaining,d.remaining) && ...
        c.rank==d.rank && c.count==d.count, ...
        'Medium joint reference differential disagrees.');
    fprintf(['STAGE_55_GENERAL_JOINT_BENCH DAYS=80 MONTHS=8 ', ...
        'STEPS=3 RANK_CASE=%d SECONDS=%.3f\n'],j,duration);
end
fprintf('STAGE_55_GENERAL_JOINT_EXPERIMENTAL_PASS\n');
end

function expectMethodError(L,method)
failed=false;
try
    pastafari.unrankGeneralWeaveSuffixChunk( ...
        L,L,0,0,1,1,method);
catch err
    failed=strcmp(err.identifier,'Pastafari:GeneralChunk:Method');
end
assert(failed,'Expected strict unsupported-method rejection.');
end
