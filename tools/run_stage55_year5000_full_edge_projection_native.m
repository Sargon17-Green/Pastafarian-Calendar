function run_stage55_year5000_full_edge_projection_native()
% Full 4244-day native PATCH25 projection for the two exact edge words.
% Does NOT establish the canonical middle-rank weave or final Stage55 pass.
root = fileparts(fileparts(mfilename('fullpath')));
src = fullfile(root,'src');
addpath(src);
pathGuard = onCleanup(@()rmpath(src)); %#ok<NASGU>
logs = fullfile(root,'logs');
if exist(logs,'dir')~=7, mkdir(logs); end
diary(fullfile(logs,'STAGE55_FULL_EDGE_PROJECTION_NATIVE.log'));
diaryGuard = onCleanup(@()diary('off')); %#ok<NASGU>
fixture = jsondecode(fileread(fullfile(root,'tests','fixtures', ...
    'stage55_year5000_appendix_a_metadata.json')));
L = double(fixture.month_lengths(:).');
C = double(fixture.cutlet_day_lengths(:).');
cutletNames = double(fixture.cutlet_name_indices(:).');
monthNames = double(fixture.month_name_indices(:).');
assert(fixture.year==5000 && fixture.first_day==-15057702 && ...
    fixture.last_day==-15053459 && numel(L)==45 && sum(L)==4244 && ...
    numel(C)==6 && sum(C)==4244 && numel(cutletNames)==6 && ...
    numel(monthNames)==45, 'Stage55:FullEdgeFixture');
K = numel(L);
% Separate closed-form extremal construction. Python uses legal-move greed.
first = repelem(1:K,L);
middle = zeros(1,0);
for j=K:-1:1
    middle = [middle,repmat(j,1,L(j)-2)]; %#ok<AGROW>
end
last = [1:K,middle,1:K];
words = {first,last};
labels = {'FIRST','LAST'};
ends = cumsum(C);
starts = [1,ends(1:end-1)+1];
origin = pastafari.BigInt(fixture.first_day-1);
calculation = pastafari.BigInt(fixture.calculation_day);
catalog = pastafari.sourceLanguageCatalog();
assert(all(cutletNames>=1 & cutletNames<=numel(catalog.cutlets)) && ...
    all(monthNames>=1 & monthNames<=numel(catalog.months)), ...
    'Stage55:FullEdgeCatalog');
for mode=1:2
    word = words{mode};
    assert(numel(word)==4244 && ...
        isequal(accumarray(word(:),1,[K 1]),L(:)), ...
        'Stage55:FullEdgeMultiplicity');
    firstPositions = zeros(1,K);
    lastPositions = zeros(1,K);
    for j=1:K
        p=find(word==j);
        firstPositions(j)=p(1);
        lastPositions(j)=p(end);
    end
    assert(all(diff(firstPositions)>0) && all(diff(lastPositions)>0), ...
        'Stage55:FullEdgeLegality');
    for trial=1:2
        path = fullfile(logs,sprintf('STAGE55_YEAR5000_%s_RUN%d.csv', ...
            labels{mode},trial));
        [fid,msg] = fopen(path,'w','n','US-ASCII');
        assert(fid>=0,'Stage55:FullEdgeOpen',msg);
        guard = onCleanup(@()fclose(fid));
        fprintf(fid,'POSITION,YEAR,CUTLET_INDEX,CUTLET_DAY,MONTH_INDEX,MONTH_DAY\n');
        seen = zeros(1,K);
        t = tic;
        for position=1:4244
            symbol=word(position);
            seen(symbol)=seen(symbol)+1;
            part=find(position<=ends,1,'first');
            assert(~isempty(part),'Stage55:FullEdgeCutlet');
            ordinal=position-starts(part)+1;
            day=pastafari.BigInt(fixture.first_day+position-1);
            ctx=pastafari.MonsterContext(calculation,day);
            [ctx,actualSymbol,actualDay]= ...
                pastafari.MonthDayCompatibilityRoute.call(ctx,word,origin,day);
            assert(actualSymbol==symbol && ...
                actualDay==pastafari.BigInt(seen(symbol)) && ...
                any(strcmp(ctx.branchTrace,'PATCH_25_OCCURRENCE_COUNT')), ...
                'Stage55:FullEdgeMonthRoute');
            tuple={pastafari.BigInt(5000), ...
                catalog.cutlets(cutletNames(part)).text, ...
                pastafari.BigInt(ordinal), ...
                catalog.months(monthNames(symbol)).text,actualDay};
            assert(numel(tuple)==5 && ...
                strcmp(tuple{2},catalog.cutlets(cutletNames(part)).text) && ...
                strcmp(tuple{4},catalog.months(monthNames(symbol)).text) && ...
                tuple{1}==pastafari.BigInt(5000) && ...
                tuple{3}==pastafari.BigInt(ordinal) && ...
                tuple{5}==pastafari.BigInt(seen(symbol)), ...
                'Stage55:FullEdgeFiveFields');
            fprintf(fid,'%d,%d,%d,%d,%d,%d\n',position,5000, ...
                cutletNames(part),ordinal,monthNames(symbol), ...
                str2double(char(actualDay)));
        end
        assert(isequal(seen,L),'Stage55:FullEdgeFinalCounts');
        clear guard
        assert(exist(path,'file')==2,'Stage55:FullEdgeOutput');
        fprintf('STAGE55_FULL_EDGE_NATIVE_CASE_PASS WORD=%s RUN=%d ROWS=4244 SEC=%.3f\n', ...
            labels{mode},trial,toc(t));
    end
    for badPosition=[0,4245]
        target=pastafari.BigInt(fixture.first_day+badPosition-1);
        invalid=pastafari.MonsterContext(calculation,target);
        rejected=false;
        try
            pastafari.MonthDayCompatibilityRoute.call(invalid,word,origin,target);
        catch err
            rejected=strcmp(err.identifier,'Pastafari:MonthDay:TargetOutsideYear');
        end
        assert(rejected,'Stage55:FullEdgeNegativeBoundary');
    end
end
fprintf('STAGE55_FULL_EDGE_NATIVE_PROJECTION_PASS CASES=2 RUNS=2 ROWS=4244 NEGATIVE=4\n');
fprintf('STAGE55_CANONICAL_MIDDLE_RANK_NOT_VERIFIED\n');
fprintf('STAGE55_FINAL_STAGE_PASS_NOT_VERIFIED\n');
end
