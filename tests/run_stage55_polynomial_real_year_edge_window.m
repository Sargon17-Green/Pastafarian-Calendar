function run_stage55_polynomial_real_year_edge_window()
% Native 256 complete real-year legal words: first 128, last 128.
% Verify full 4244-day multiplicity / ordering and exact adjacency.
% Golden full-word weighted witnesses at distances 0,1,2,7,31,127
% are independent of the experimental polynomial candidate.
here=fileparts(mfilename('fullpath'));
root=fileparts(here);
addpath(fullfile(root,'src'));
cleanup=onCleanup(@() rmpath(fullfile(root,'src'))); %#ok<NASGU>
L=[115 108 119 109 106 81 115 114 117 120 98 52 81 97 121 ...
   97 115 96 107 61 106 115 119 39 84 103 115 107 55 119 ...
   97 50 122 110 81 54 101 83 88 40 25 77 98 122 105];
assert(numel(L)==45 && sum(L)==4244);
timer=tic;
family=pastafari.WholeMonthWeavingFamilyPolynomial(L);
F=family.count();
assert(numel(char(F))==6765);
first=family.edgeWindowAt1(127,'first');
fprintf(['STAGE_55_POLYNOMIAL_FIRST_128_PASS ', ...
    'WORDS=%d DAYS=%d SECONDS=%.3f\n'],size(first,1), ...
    size(first,2),toc(timer));
last=family.edgeWindowAt1(127,'last');
fprintf(['STAGE_55_POLYNOMIAL_LAST_128_PASS ', ...
    'WORDS=%d DAYS=%d SECONDS=%.3f\n'],size(last,1), ...
    size(last,2),toc(timer));
assert(isequal(size(first),[128 4244]) && ...
    isequal(size(last),[128 4244]));
weights=1:4244;
offsets=[0 1 2 7 31 127];
goldenFirstWeighted=[264303486 264303485 264303484 ...
    264303479 264303455 264303462];
goldenLastWeighted=[131812552 131812553 131812554 ...
    131812559 131812583 131812566];
goldenFirstSquares=[8847605690 8847605601 8847605512 ...
    8847605067 8847602931 8847603554];
goldenLastSquares=[2927435644 2927435647 2927435650 ...
    2927435665 2927435737 2927435686];
for i=1:128
    validateComplete(first(i,:),L);
    validateComplete(last(i,:),L);
    if i>1
        assert(lexLess(first(i-1,:),first(i,:)) && ...
            lexLess(last(i,:),last(i-1,:)), ...
            'Adjacent window violates exact lexical ordering.');
    end
end
for k=1:numel(offsets)
    d=offsets(k);
    a=first(d+1,:); b=last(d+1,:);
    assert(sum(a.*weights)==goldenFirstWeighted(k) && ...
        sum(b.*weights)==goldenLastWeighted(k) && ...
        sum((a.*a).*weights)==goldenFirstSquares(k) && ...
        sum((b.*b).*weights)==goldenLastSquares(k), ...
        'Whole-word independent full-length weighted witness mismatch.');
    ra=pastafari.BigInt(d+1);
    rb=F-pastafari.BigInt(d);
    assert(isequal(family.itemAt1(ra),a) && ...
        isequal(family.itemAt1(rb),b), ...
        'One-shot ranked polynomial path disagrees with window.');
end
fprintf(['STAGE_55_POLYNOMIAL_YEAR_256_WORDS_PASS ', ...
    'MONTHS=45 DAYS=4244 WORDS=256 MOMENT_WITNESSES=12 ', ...
    'SECONDS=%.3f\n'],toc(timer));
reject(@() family.edgeWindowAt1(128,'first'), ...
    'Pastafari:PolynomialFamily:EdgeWindowLimit');
reject(@() family.edgeWindowAt1(0.5,'last'), ...
    'Pastafari:PolynomialFamily:EdgeWindowLimit');
reject(@() family.edgeWindowAt1(1,'middle'), ...
    'Pastafari:PolynomialFamily:EdgeWindowSide');
small=pastafari.WholeMonthWeavingFamilyPolynomial([1]);
reject(@() small.edgeWindowAt1(1,'first'), ...
    'Pastafari:PolynomialFamily:EdgeWindowRange');
assert(isequal(small.edgeWindowAt1(0,'first'),1) && ...
    isequal(small.edgeWindowAt1(0,'last'),1));
fprintf('STAGE_55_POLYNOMIAL_YEAR_EDGE_WINDOW_VALIDATION_PASS\n');
fprintf('STAGE_55_POLYNOMIAL_YEAR_EDGE_WINDOW_EXPERIMENTAL_PASS\n');
end

function validateComplete(word,L)
assert(isrow(word) && numel(word)==sum(L) && ...
    all(word>=1) && all(word<=numel(L)) && ...
    all(word==fix(word)));
first=zeros(1,numel(L));last=zeros(1,numel(L));
for j=1:numel(L)
    ix=find(word==j);
    assert(numel(ix)==L(j),'Month multiplicities do not match.');
    first(j)=ix(1);last(j)=ix(end);
end
assert(all(diff(first)>0) && all(diff(last)>0), ...
    'Opening and closure orders must be strictly increasing.');
end

function less=lexLess(a,b)
j=find(a~=b,1,'first');
less=~isempty(j) && a(j)<b(j);
end

function reject(f,expected)
failed=false;
try
    f();
catch err
    failed=strcmp(err.identifier,expected);
end
assert(failed,'Expected exact validation error %s',expected);
end
