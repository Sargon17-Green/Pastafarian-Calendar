function run_stage55_all_open_factor_tests()
% Experimental independent cross-checks against already native-approved
% exact rational block implementation and brute suffix recurrence.
here=fileparts(mfilename('fullpath'));
root=fileparts(here);
addpath(fullfile(root,'src'));
cleanup=onCleanup(@() rmpath(fullfile(root,'src'))); %#ok<NASGU>

families=0;
children=0;
for m=1:5
    for encoded=0:(3^m-1)
        r=zeros(1,m);
        cursor=encoded;
        for j=1:m
            r(j)=mod(cursor,3)+1;
            cursor=floor(cursor/3);
        end
        for closed=0:2
            remainder=[zeros(1,closed),r];
            parent=pastafari.countWholeWeavingSuffixByEndpoints( ...
                remainder,numel(remainder),closed);
            actual=pastafari.allOpenedWholeWeaveChildCountsByFactors( ...
                remainder,closed,parent);
            reference=pastafari.allOpenedWholeWeaveChildCounts( ...
                remainder,closed,parent);
            assert(numel(actual)==numel(reference), ...
                'Fast and approved child-block vectors differ in width.');
            for id=1:numel(actual)
                assert(isequal(actual{id},reference{id}), ...
                    'Factorized child block does not equal approved count.');
                if ~isempty(actual{id})
                    child=remainder;
                    child(id)=child(id)-1;
                    nextClosed=closed+double(remainder(id)==1);
                    oracle=pastafari.countWholeWeavingSuffixByEndpoints( ...
                        child,numel(child),nextClosed);
                    assert(actual{id}==oracle, ...
                        'Child block disagrees with exact suffix oracle.');
                    children=children+1;
                end
            end
            families=families+1;
        end
    end
end
fprintf(['STAGE_55_ALL_OPEN_FACTOR_DIFFERENTIAL_PASS ', ...
    'FRONTIERS=%d CHILDREN=%d\n'],families,children);

% Strict count validation on nontrivial frontier.
caught=false;
try
    pastafari.allOpenedWholeWeaveChildCountsByFactors( ...
        [2 2],0,pastafari.BigInt(1));
catch err
    caught=strcmp(err.identifier,'Pastafari:AllOpenFactors:Count');
end
assert(caught,'Bad parent count must be rejected exactly.');
fprintf('STAGE_55_ALL_OPEN_FACTOR_VALIDATION_PASS\n');

% Compare full exact 45-month 4230-day child-weight partitions.
r=repmat(94,1,45);
F=pastafari.countWholeWeavingSuffixByEndpoints(r,45,0);
oldStart=tic;
old=pastafari.allOpenedWholeWeaveChildCounts(r,0,F);
oldSeconds=toc(oldStart);
newStart=tic;
fresh=pastafari.allOpenedWholeWeaveChildCountsByFactors(r,0,F);
newSeconds=toc(newStart);
for j=1:numel(r)
    assert(isequal(fresh{j},old{j}), ...
        'Large factor block mismatch.');
end
fprintf(['STAGE_55_ALL_OPEN_FACTOR_BENCH MONTHS=45 DAYS=4230 ', ...
    'OLD_SECONDS=%.3f FACTOR_SECONDS=%.3f DIGITS=%d\n'], ...
    oldSeconds,newSeconds,numel(char(F)));
fprintf('STAGE_55_ALL_OPEN_FACTOR_EXPERIMENTAL_PASS\n');
end
