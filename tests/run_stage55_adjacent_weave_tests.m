function run_stage55_adjacent_weave_tests()
% Differential proof on short families, complete 1301-rank traverse,
% and ALL DAYS of the actual production year-5000 length vector.
here=fileparts(mfilename('fullpath'));
root=fileparts(here);
addpath(fullfile(root,'src'));
cleanup=onCleanup(@() rmpath(fullfile(root,'src'))); %#ok<NASGU>

cases=0;
for K=1:4
    for encoded=0:3^K-1
        q=encoded;
        L=zeros(1,K);
        for j=1:K
            L(j)=mod(q,3)+1;
            q=floor(q/3);
        end
        legacy=pastafari.WholeMonthWeavingFamily(L);
        count=legacy.count();
        [first,last]=pastafari.extremalWholeMonthWeavings(L);
        [none,hasPrev]=pastafari.adjacentWholeMonthWeaving( ...
            first,L,'previous');
        [noneNext,hasNext]=pastafari.adjacentWholeMonthWeaving( ...
            last,L,'next');
        assert(~hasPrev && isempty(none) && ...
            ~hasNext && isempty(noneNext), ...
            'Lexical minimum/maximum must have no outside neighbors.');
        if count>pastafari.BigInt(1)
            [afterMin,ok]=pastafari.adjacentWholeMonthWeaving( ...
                first,L,'next');
            [beforeMax,ok2]=pastafari.adjacentWholeMonthWeaving( ...
                last,L,'previous');
            assert(ok && ok2 && ...
                isequal(afterMin,legacy.itemAt1(pastafari.BigInt(2))) && ...
                isequal(beforeMax,legacy.itemAt1(count-pastafari.BigInt(1))), ...
                'Exact adjacent rank differs from production DAG.');
            [back,ok3]=pastafari.adjacentWholeMonthWeaving( ...
                afterMin,L,'previous');
            assert(ok3 && isequal(back,first), ...
                'Previous must invert next at the lexical boundary.');
        else
            [missing,exists]=pastafari.adjacentWholeMonthWeaving( ...
                first,L,'next');
            assert(~exists && isempty(missing));
        end
        cases=cases+1;
    end
end
assert(cases==120);
fprintf('STAGE_55_ADJACENT_SMALL_DAG_PASS FAMILIES=%d\n',cases);

% Count [4,4,4] has 1301 exact lexicographic words. Walk ALL
% consecutive ranks forward and backward; compare sampled ranks to
% historical production without rebuilding its entire DAG each step.
L=[4 4 4];
legacy=pastafari.WholeMonthWeavingFamily(L);
assert(legacy.count()==pastafari.BigInt(1301));
[first,last]=pastafari.extremalWholeMonthWeavings(L);
current=first;
for rank=1:1300
    [next,ok]=pastafari.adjacentWholeMonthWeaving( ...
        current,L,'next');
    assert(ok && lexLess(current,next), ...
        'Successor must exist and increase exactly one rank.');
    [previous,ok2]=pastafari.adjacentWholeMonthWeaving( ...
        next,L,'previous');
    assert(ok2 && isequal(previous,current), ...
        'Successor/predecessor must be mutual inverses.');
    current=next;
    if any(rank+1==[2 3 10 100 651 1300 1301])
        assert(isequal(current,legacy.itemAt1(pastafari.BigInt(rank+1))), ...
            'Traversed rank disagrees with production DAG.');
    end
end
assert(isequal(current,last), ...
    'The final rank after 1300 successors must be maximum.');
fprintf('STAGE_55_ADJACENT_ALL_1301_RANKS_PASS TRANSITIONS=1300\n');

% True year-5000 month-length vector: 45 months, 4244 days.
L=[115 108 119 109 106 81 115 114 117 120 98 52 81 97 121 ...
   97 115 96 107 61 106 115 119 39 84 103 115 107 55 119 ...
   97 50 122 110 81 54 101 83 88 40 25 77 98 122 105];
assert(numel(L)==45 && sum(L)==4244);
timer=tic;
[first,last]=pastafari.extremalWholeMonthWeavings(L);
[second,exists2]=pastafari.adjacentWholeMonthWeaving( ...
    first,L,'next');
[third,exists3]=pastafari.adjacentWholeMonthWeaving( ...
    second,L,'next');
[penultimate,exists4]=pastafari.adjacentWholeMonthWeaving( ...
    last,L,'previous');
[antepenultimate,exists5]=pastafari.adjacentWholeMonthWeaving( ...
    penultimate,L,'previous');
[back,inv]=pastafari.adjacentWholeMonthWeaving( ...
    second,L,'previous');
[up,inv2]=pastafari.adjacentWholeMonthWeaving( ...
    penultimate,L,'next');
elapsed=toc(timer);
assert(exists2 && exists3 && exists4 && exists5 && inv && inv2 && ...
    isequal(back,first) && isequal(up,last) && ...
    lexLess(first,second) && lexLess(second,third) && ...
    lexLess(antepenultimate,penultimate) && ...
    lexLess(penultimate,last), ...
    'Full-year lexical nearest-neighbor invariant lost.');
for word={first,second,third,antepenultimate,penultimate,last}
    verifyWholeWord(word{1},L);
end
fprintf(['STAGE_55_REAL_YEAR_5000_ADJACENT_FULL_WORDS_PASS ', ...
    'MONTHS=45 DAYS=4244 EXACT_EDGE_RANKS=6 ', ...
    'SECONDS=%.3f\n'],elapsed);
fprintf('STAGE_55_REAL_YEAR_ADJACENT_MIN3_FIRST48=%s\n', ...
    mat2str(third(1:48)));
fprintf('STAGE_55_REAL_YEAR_ADJACENT_MAX3_FIRST48=%s\n', ...
    mat2str(antepenultimate(1:48)));

% Input-validation regression.
bad=[1 2 2 1]; % multiplicities legal, last-occurrence order reversed
assertReject(bad,[2 2],'Pastafari:AdjacentWeave:Ordering');
assertReject([1 2 2 2],[2 2], ...
    'Pastafari:AdjacentWeave:Multiplicity');
fprintf('STAGE_55_ADJACENT_EXPERIMENTAL_PASS\n');
end

function flag=lexLess(a,b)
p=find(a~=b,1,'first');
flag=~isempty(p) && a(p)<b(p);
end

function verifyWholeWord(word,L)
K=numel(L);
assert(numel(word)==sum(L));
first=zeros(1,K);
last=zeros(1,K);
for k=1:K
    indices=find(word==k);
    assert(numel(indices)==L(k));
    first(k)=indices(1);
    last(k)=indices(end);
end
assert(all(diff(first)>0) && all(diff(last)>0));
end

function assertReject(word,L,id)
matched=false;
try
    pastafari.adjacentWholeMonthWeaving(word,L,'next');
catch err
    matched=strcmp(err.identifier,id);
end
assert(matched,'Expected strict error identifier %s',id);
end
