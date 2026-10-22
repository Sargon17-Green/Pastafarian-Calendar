function run_stage55_all_open_common_denominator_tests()
% Independent differential vs both existing exact all-open formulas.
here=fileparts(mfilename('fullpath'));
root=fileparts(here);
addpath(fullfile(root,'src'));
cleanup=onCleanup(@() rmpath(fullfile(root,'src'))); %#ok<NASGU>

frontiers=0;
children=0;
for m=1:5
    for encoded=0:(3^m-1)
        r=zeros(1,m);
        code=encoded;
        for j=1:m
            r(j)=mod(code,3)+1;
            code=floor(code/3);
        end
        for closed=0:2
            v=[zeros(1,closed) r];
            K=numel(v);
            F=pastafari.countWholeWeavingSuffixByEndpoints(v,K,closed);
            got=pastafari.allOpenedWholeWeaveChildCountsCommonDenominator( ...
                v,closed,F);
            verified=pastafari.allOpenedWholeWeaveChildCounts(v,closed,F);
            factors=pastafari.allOpenedWholeWeaveChildCountsByFactors( ...
                v,closed,F);
            assert(numel(got)==numel(v),'Child-block vector width mismatch.');
            for monthId=1:K
                assert(isequal(got{monthId},verified{monthId}), ...
                    'Common-denominator / rational differential mismatch.');
                assert(isequal(got{monthId},factors{monthId}), ...
                    'Common-denominator / binomial factor mismatch.');
                if ~isempty(got{monthId})
                    child=v;
                    child(monthId)=child(monthId)-1;
                    nextClosed=closed+double(v(monthId)==1);
                    independent=pastafari.countWholeWeavingSuffixByEndpoints( ...
                        child,K,nextClosed);
                    assert(got{monthId}==independent, ...
                        'Common denominator differs from exact suffix oracle.');
                    children=children+1;
                end
            end
            frontiers=frontiers+1;
        end
    end
end
fprintf(['STAGE_55_ALL_OPEN_COMMON_DIFFERENTIAL_PASS ', ...
    'FRONTIERS=%d CHILDREN=%d\n'],frontiers,children);

caught=false;
try
    pastafari.allOpenedWholeWeaveChildCountsCommonDenominator( ...
        [2 3],0,pastafari.BigInt(1));
catch err
    caught=strcmp(err.identifier,'Pastafari:AllOpenCommon:NonIntegral') || ...
        strcmp(err.identifier,'Pastafari:AllOpenCommon:Partition');
end
assert(caught,'Incorrect parent count must not pass exact checks.');
fprintf('STAGE_55_ALL_OPEN_COMMON_VALIDATION_PASS\n');

r=repmat(94,1,45);
F=pastafari.countWholeWeavingSuffixByEndpoints(r,45,0);
a=tic;
old=pastafari.allOpenedWholeWeaveChildCounts(r,0,F);
oldSeconds=toc(a);
b=tic;
factor=pastafari.allOpenedWholeWeaveChildCountsByFactors(r,0,F);
factorSeconds=toc(b);
c=tic;
fresh=pastafari.allOpenedWholeWeaveChildCountsCommonDenominator( ...
    r,0,F);
commonSeconds=toc(c);
for i=1:numel(r)
    assert(isequal(fresh{i},old{i}) && isequal(fresh{i},factor{i}), ...
        '4230-day exact common-denominator block mismatch.');
end
fprintf(['STAGE_55_ALL_OPEN_COMMON_BENCH MONTHS=45 DAYS=4230 ', ...
    'OLD_SECONDS=%.3f FACTOR_SECONDS=%.3f ', ...
    'COMMON_SECONDS=%.3f DIGITS=%d\n'], ...
    oldSeconds,factorSeconds,commonSeconds,numel(char(F)));
fprintf('STAGE_55_ALL_OPEN_COMMON_EXPERIMENTAL_PASS\n');
end
