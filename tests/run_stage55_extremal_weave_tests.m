function run_stage55_extremal_weave_tests()
% Native exhaustive independent recursion on 363 small families,
% differential against old exact-DAG ranks, and ACTUAL 5000-year full
% 4244-day extremal words. Not an arbitrary-rank Stage55 solution.
here=fileparts(mfilename('fullpath'));
root=fileparts(here);
addpath(fullfile(root,'src'));
cleanup=onCleanup(@() rmpath(fullfile(root,'src'))); %#ok<NASGU>

families=0;
for K=1:5
    for encoded=0:3^K-1
        code=encoded;
        L=zeros(1,K);
        for j=1:K
            L(j)=mod(code,3)+1;
            code=floor(code/3);
        end
        [lowest,highest]=pastafari.extremalWholeMonthWeavings(L);
        independent=independentRecursiveExtremes(L);
        assert(isequal(lowest,independent.first) && ...
            isequal(highest,independent.last), ...
            'Greedy extrema disagree with independent recursive oracle.');
        validateWholeWeave(lowest,L);
        validateWholeWeave(highest,L);
        families=families+1;
    end
end
assert(families==363, ...
    'Did not examine all 363 small length families.');
fprintf('STAGE_55_EXTREMAL_BRUTE_PASS FAMILIES=%d\n',families);

% Independent legacy production DAG, for representative exact ranks.
cases={[1],[4],[1 1],[2 2],[2 3 2],[3 3 3], ...
    [4 4 4],[2 2 2 2],[3 2 3 2],[2 2 2 2 2]};
for n=1:numel(cases)
    L=cases{n};
    family=pastafari.WholeMonthWeavingFamily(L);
    count=family.count();
    [first,last]=pastafari.extremalWholeMonthWeavings(L);
    assert(isequal(first,family.itemAt1(pastafari.BigInt(1))) && ...
        isequal(last,family.itemAt1(count)), ...
        'Greedy extremes disagree with canonical exact DAG ranks.');
end
fprintf('STAGE_55_EXTREMAL_DAG_DIFFERENTIAL_PASS CASES=%d\n', ...
    numel(cases));

% Actual year-5000 fixture read from production diagnostic run
% 39818603362; not synthetic 108+44*94 length vector.
L=[115 108 119 109 106 81 115 114 117 120 98 52 81 97 121 ...
   97 115 96 107 61 106 115 119 39 84 103 115 107 55 119 ...
   97 50 122 110 81 54 101 83 88 40 25 77 98 122 105];
assert(numel(L)==45 && sum(L)==4244);
timer=tic;
[first,last]=pastafari.extremalWholeMonthWeavings(L);
elapsed=toc(timer);
validateWholeWeave(first,L);
validateWholeWeave(last,L);
assert(numel(first)==4244 && numel(last)==4244 && ...
    isequal(first,repelem(1:numel(L),L)) && ...
    last(1)==1 && last(end)==numel(L), ...
    'Production-sized extrema lost valid opening/closure order.');
% A small deterministic diagnostic, NOT a cryptographic hash.
weights=1:numel(last);
fingerprint=sum(last.*weights);
assert(fingerprint==fix(fingerprint) && fingerprint<=flintmax);
fprintf(['STAGE_55_REAL_YEAR_EXTREMAL_FULL_WORDS_PASS ', ...
    'MONTHS=45 DAYS=4244 SECONDS=%.3f ', ...
    'MAX_WEIGHTED_SUM=%.0f\n'],elapsed,fingerprint);
fprintf('STAGE_55_REAL_YEAR_EXTREMAL_FIRST48=%s\n', ...
    mat2str(first(1:48)));
fprintf('STAGE_55_REAL_YEAR_EXTREMAL_LAST48=%s\n', ...
    mat2str(last(1:48)));
fprintf('STAGE_55_EXTREMAL_EXPERIMENTAL_PASS\n');
end

function reference=independentRecursiveExtremes(L)
% Independently explores ALL legal next choices recursively, with memo
% for repeated exact remaining/opened/closed states.
K=numel(L);
memo=containers.Map('KeyType','char','ValueType','any');
reference=visit(L,0,0);
    function extrema=visit(R,o,c)
        if all(R==0)
            assert(o==K && c==K);
            extrema=struct('first',zeros(1,0),'last',zeros(1,0));
            return
        end
        key=sprintf('%d,',[R,o,c]);
        if isKey(memo,key)
            extrema=memo(key);
            return
        end
        collectedFirst={};
        collectedLast={};
        for j=1:K
            count=R(j);
            if count<1 || (count==L(j) && j~=o+1) || ...
                    (count==1 && j~=c+1)
                continue
            end
            child=R;
            child(j)=count-1;
            result=visit(child,o+double(count==L(j)), ...
                c+double(count==1));
            collectedFirst{end+1}=[j result.first]; %#ok<AGROW>
            collectedLast{end+1}=[j result.last]; %#ok<AGROW>
        end
        assert(~isempty(collectedFirst));
        % Distinct child first symbols in ascending order guarantee
        % every word of earlier child precedes every word of later child.
        extrema=struct('first',collectedFirst{1}, ...
            'last',collectedLast{end});
        memo(key)=extrema;
    end
end

function validateWholeWeave(word,L)
assert(numel(word)==sum(L) && ...
    all(word==fix(word)) && ...
    all(word>=1) && all(word<=numel(L)));
K=numel(L);
f=zeros(1,K);
l=zeros(1,K);
for j=1:K
    positions=find(word==j);
    assert(numel(positions)==L(j), ...
        'A month is missing or appears the wrong number of times.');
    f(j)=positions(1);
    l(j)=positions(end);
end
assert(all(diff(f)>0) && all(diff(l)>0), ...
    'First/last occurrence order is not canonical.');
end
