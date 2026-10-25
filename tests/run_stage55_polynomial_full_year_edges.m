function run_stage55_polynomial_full_year_edges()
% Complete real 45-month / 4244-day whole-word rank witnesses for the
% experimental polynomial family. No production or normative-oracle edit.
% These are exactly the four extremal and adjacent-to-extremal ranks:
% 1, 2, F-1, F. Arbitrary interior ranks are deliberately not certified.
here=fileparts(mfilename('fullpath'));
root=fileparts(here);
addpath(fullfile(root,'src'));
cleanup=onCleanup(@() rmpath(fullfile(root,'src'))); %#ok<NASGU>
L=[115 108 119 109 106 81 115 114 117 120 98 52 81 97 121 ...
   97 115 96 107 61 106 115 119 39 84 103 115 107 55 119 ...
   97 50 122 110 81 54 101 83 88 40 25 77 98 122 105];
assert(numel(L)==45 && sum(L)==4244);
initialRank=pastafari.BigInt(['1' repmat('0',1,6764)]);
ticTotal=tic;
family=pastafari.WholeMonthWeavingFamilyPolynomial(L(:));
F=family.count();
assert(F>initialRank && numel(char(F))==6765, ...
    'Year-5000 true whole-month count must contain all interior ranks.');
fprintf(['STAGE_55_POLYNOMIAL_REAL_YEAR_COUNT_PASS ', ...
    'MONTHS=%d DAYS=%d DIGITS=%d SECONDS=%.3f\n'], ...
    family.monthCount,family.totalDays,numel(char(F)),toc(ticTotal));
one=pastafari.BigInt(1);
ranks={one,one+one,F-one,F};
% The weights are complete-word, cross-implementation regression
% witnesses from the native-verified near-edge test, not hash security.
weighted=[264303486 264303485 131812553 131812552];
squared=[8847605690 8847605601 2927435647 2927435644];
words=cell(1,4);
momentIndex=1:4244;
for i=1:4
    t=tic;
    word=family.itemAt1(ranks{i});
    verifyLegal(word,L);
    assert(sum(word.*momentIndex)==weighted(i) && ...
        sum((word.*word).*momentIndex)==squared(i), ...
        '4244-day complete word differs from independently signed moments.');
    words{i}=word;
    fprintf(['STAGE_55_POLYNOMIAL_REAL_YEAR_EDGE_PASS ', ...
        'CASE=%d MONTHS=%d DAYS=%d SECONDS=%.3f\n'], ...
        i,numel(L),numel(word),toc(t));
end
assert(~isequal(words{1},words{2}) && ...
    ~isequal(words{3},words{4}), ...
    'Nontrivial lexical family must have distinct neighboring ranks.');
assert(lexLess(words{1},words{2}) && ...
    lexLess(words{2},words{3}) && ...
    lexLess(words{3},words{4}), ...
    'Complete lexical rank order is incorrect.');
[second,hasSecond]=pastafari.adjacentWholeMonthWeaving( ...
    words{1},L,'next');
[penultimate,hasPenultimate]=pastafari.adjacentWholeMonthWeaving( ...
    words{4},L,'previous');
assert(hasSecond && hasPenultimate && ...
    isequal(second,words{2}) && ...
    isequal(penultimate,words{3}), ...
    'Independent exact adjacent-word operator contradicts edge ranks.');
fprintf(['STAGE_55_POLYNOMIAL_REAL_YEAR_FOUR_FULL_WORDS_PASS ', ...
    'MONTHS=45 DAYS=4244 RANKS=4 SECONDS=%.3f\n'],toc(ticTotal));
fprintf('STAGE_55_POLYNOMIAL_REAL_YEAR_EDGE_EXPERIMENTAL_PASS\n');
end

function verifyLegal(word,L)
assert(isrow(word) && numel(word)==sum(L) && ...
    all(word==fix(word)) && ...
    all(word>=1) && all(word<=numel(L)));
f=zeros(1,numel(L)); e=zeros(1,numel(L));
for j=1:numel(L)
    p=find(word==j);
    assert(numel(p)==L(j),'Wrong full-word month multiplicity.');
    f(j)=p(1); e(j)=p(end);
end
assert(all(diff(f)>0) && all(diff(e)>0), ...
    'Noncanonical month opening/closure order.');
end

function tf=lexLess(a,b)
at=find(a~=b,1,'first');
tf=~isempty(at) && a(at)<b(at);
end
