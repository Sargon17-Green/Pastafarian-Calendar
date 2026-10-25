function run_stage55_polynomial_family_equivalence_tests()
% Exact old-production versus new-polynomial family equivalence for
% EVERY legal one-based rank of independent small families.
% No production wrapper or independent normative_oracle is changed.
here=fileparts(mfilename('fullpath'));
root=fileparts(here);
addpath(fullfile(root,'src'));
cleanup=onCleanup(@() rmpath(fullfile(root,'src'))); %#ok<NASGU>
families={[1],[2],[1 2 2],[2 3 2],[3 2 3],[2 2 2 2], ...
    [3 3 2],[4 4 4],[3 2 2 3]};
one=pastafari.BigInt(1);
instances=0; ranks=0; prefixes=0;
for f=1:numel(families)
    L=families{f};
    original=pastafari.WholeMonthWeavingFamily(L);
    replacement=pastafari.WholeMonthWeavingFamilyPolynomial(L(:));
    exact=original.count();
    assert(exact==replacement.count(), ...
        'Polynomial family count differs from original production DAG.');
    total=exact.toDoubleExact();
    assert(total>=1 && total<10000, ...
        'Reference family must remain small and exhaustive.');
    for k=1:total
        rank=pastafari.BigInt(k);
        oldWord=original.itemAt1(rank);
        newWord=replacement.itemAt1(rank);
        assert(isequal(oldWord,newWord) && ...
            numel(newWord)==sum(L), ...
            'Production-DAG and polynomial lexicographic words differ.');
        for chunk=[0 1 floor(sum(L)/2) sum(L)]
            [prefix,c]=replacement.prefixAt1(rank,chunk);
            assert(isequal(prefix,newWord(1:numel(prefix))) && ...
                c.initialCount==exact && ...
                c.rank>=one && c.rank<=c.count && ...
                sum(c.remaining)==sum(L)-numel(prefix), ...
                'Partial exact polynomial-family rank was corrupted.');
            prefixes=prefixes+1;
        end
        ranks=ranks+1;
    end
    instances=instances+1;
end
assert(instances==numel(families) && ranks>100 && prefixes>400, ...
    'Insufficient all-rank equivalence coverage.');
fprintf(['STAGE_55_POLYNOMIAL_FAMILY_EQUIVALENCE_PASS ', ...
    'FAMILIES=%d ALL_RANKS=%d PREFIX_CASES=%d\n'], ...
    instances,ranks,prefixes);
reject(@() pastafari.WholeMonthWeavingFamilyPolynomial( ...
    [2 NaN]),'Pastafari:PolynomialFamily:Lengths');
f=pastafari.WholeMonthWeavingFamilyPolynomial([2 3 2]);
reject(@() f.itemAt1(pastafari.BigInt(0)), ...
    'Pastafari:PolynomialFamily:Rank');
reject(@() f.itemAt1(f.count()+one), ...
    'Pastafari:PolynomialFamily:Rank');
fprintf('STAGE_55_POLYNOMIAL_FAMILY_VALIDATION_PASS\n');
fprintf('STAGE_55_POLYNOMIAL_FAMILY_EXPERIMENTAL_PASS\n');
end

function reject(fn,id)
matched=false;
try
    fn();
catch err
    matched=strcmp(err.identifier,id);
end
assert(matched,'Expected error identifier: %s',id);
end
