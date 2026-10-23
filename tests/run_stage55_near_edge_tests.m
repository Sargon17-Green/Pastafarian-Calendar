function run_stage55_near_edge_tests()
% Small full exact-rank oracle, bounded 1301-word family and actual
% production-selected 4244-day year-5000 vector.
here=fileparts(mfilename('fullpath'));
root=fileparts(here);
addpath(fullfile(root,'src'));
cleanup=onCleanup(@() rmpath(fullfile(root,'src'))); %#ok<NASGU>

cases=0; checks=0;
for K=1:4
    for encoded=0:3^K-1
        L=zeros(1,K); code=encoded;
        for j=1:K
            L(j)=mod(code,3)+1;
            code=floor(code/3);
        end
        fam=pastafari.WholeMonthWeavingFamily(L);
        count=fam.count().toDoubleExact();
        distances=0:min(count-1,3);
        for d=distances
            [a,receipt]=pastafari.unrankWholeWeavingNearEdge(L,d,'first');
            [b,backReceipt]=pastafari.unrankWholeWeavingNearEdge( ...
                L,d,'last');
            assert(isequal(a,fam.itemAt1(pastafari.BigInt(1+d))) && ...
                isequal(b,fam.itemAt1(pastafari.BigInt(count-d))) && ...
                receipt.distance==d && backReceipt.distance==d && ...
                receipt.days==sum(L) && receipt.months==K && ...
                receipt.allStepsCompleted && ...
                backReceipt.allStepsCompleted, ...
                'Near-edge exact rank diverges from historical DAG.');
            checks=checks+2;
        end
        if count<=3
            rejectRange(L,count,'first');
            rejectRange(L,count,'last');
        end
        cases=cases+1;
    end
end
assert(cases==120 && checks>300);
fprintf(['STAGE_55_NEAR_EDGE_SMALL_DAG_PASS ', ...
    'FAMILIES=%d RANK_CHECKS=%d\n'],cases,checks);

L=[4 4 4];
fam=pastafari.WholeMonthWeavingFamily(L);
assert(fam.count()==pastafari.BigInt(1301));
positions=[0 1 2 10 100 400 650 1000 1299 1300];
for d=positions
    [f,~]=pastafari.unrankWholeWeavingNearEdge(L,d,'first');
    [l,~]=pastafari.unrankWholeWeavingNearEdge(L,d,'last');
    assert(isequal(f,fam.itemAt1(pastafari.BigInt(d+1))) && ...
        isequal(l,fam.itemAt1(pastafari.BigInt(1301-d))), ...
        '1301-family rank mismatch at a selected exact distance.');
end
rejectRange(L,1301,'first');
rejectRange(L,1301,'last');
fprintf('STAGE_55_NEAR_EDGE_1301_DAG_DIFFERENTIAL_PASS CHECKS=%d\n', ...
    2*numel(positions));

% Actual production-selected 45 months/4244 days of year 5000.
L=[115 108 119 109 106 81 115 114 117 120 98 52 81 97 121 ...
   97 115 96 107 61 106 115 119 39 84 103 115 107 55 119 ...
   97 50 122 110 81 54 101 83 88 40 25 77 98 122 105];
assert(numel(L)==45 && sum(L)==4244);
offsets=[0 1 2 7 31 127];
timer=tic;
for d=offsets
    [a,ra]=pastafari.unrankWholeWeavingNearEdge(L,d,'first');
    [b,rb]=pastafari.unrankWholeWeavingNearEdge(L,d,'last');
    assert(numel(a)==4244 && numel(b)==4244 && ...
        ra.distance==d && rb.distance==d && ...
        ra.allStepsCompleted && rb.allStepsCompleted);
    checkLegal(a,L);
    checkLegal(b,L);
    if d>0
        [prev,existsPrev]=pastafari.adjacentWholeMonthWeaving( ...
            a,L,'previous');
        [next,existsNext]=pastafari.adjacentWholeMonthWeaving( ...
            b,L,'next');
        [expectedA,~]=pastafari.unrankWholeWeavingNearEdge( ...
            L,d-1,'first');
        [expectedB,~]=pastafari.unrankWholeWeavingNearEdge( ...
            L,d-1,'last');
        assert(existsPrev && existsNext && ...
            isequal(prev,expectedA) && isequal(next,expectedB), ...
            'Nonextreme exact edge offset must invert one step.');
    end
end
fprintf(['STAGE_55_REAL_YEAR_NEAR_EDGE_4244_PASS ', ...
    'MONTHS=45 DAYS=4244 OFFSETS=%s ', ...
    'WORDS=%d SECONDS=%.3f\n'], ...
    mat2str(offsets),2*numel(offsets),toc(timer));
fprintf('STAGE_55_NEAR_EDGE_EXPERIMENTAL_PASS\n');

rejectDistance(L,-1);
rejectDistance(L,0.5);
rejectEdge(L,'middle');
end

function checkLegal(word,L)
K=numel(L); f=zeros(1,K); e=zeros(1,K);
for j=1:K
    p=find(word==j);
    assert(numel(p)==L(j));
    f(j)=p(1); e(j)=p(end);
end
assert(all(diff(f)>0) && all(diff(e)>0));
end

function rejectRange(L,d,edge)
ok=false;
try
    pastafari.unrankWholeWeavingNearEdge(L,d,edge);
catch err
    ok=strcmp(err.identifier,'Pastafari:NearEdge:OutOfRange');
end
assert(ok,'Expected out-of-range rejection.');
end

function rejectDistance(L,d)
ok=false;
try
    pastafari.unrankWholeWeavingNearEdge(L,d,'first');
catch err
    ok=strcmp(err.identifier,'Pastafari:NearEdge:Distance');
end
assert(ok,'Expected exact-integer distance rejection.');
end

function rejectEdge(L,edge)
ok=false;
try
    pastafari.unrankWholeWeavingNearEdge(L,0,edge);
catch err
    ok=strcmp(err.identifier,'Pastafari:NearEdge:Edge');
end
assert(ok,'Expected unsupported edge rejection.');
end
