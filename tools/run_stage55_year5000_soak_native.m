function run_stage55_year5000_soak_native(session)
% Two fresh MATLAB processes, mixed-order warm runs of six new words.
% This gate is projection-only, not independent full rank or final Stage55.
root = fileparts(fileparts(mfilename('fullpath')));
src = fullfile(root,'src');
addpath(src);
pathGuard = onCleanup(@()rmpath(src)); %#ok<NASGU>
assert(ismember(session,[1 2]),'Stage55:SoakSession');
logs = fullfile(root,'logs','stage55_soak');
if exist(logs,'dir')~=7, mkdir(logs); end
diary(fullfile(logs,sprintf('native_S%d.log',session)));
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
    numel(monthNames)==45, 'Stage55:MiddleFixture');
K = numel(L);
labels = {'LOW_NEIGHBOR','HIGH_NEIGHBOR','CUTLET_SWAPS','SEED17','SEED2718','SEED65537'};
if session==1, schedule=[1 2 3 4 5 6 4 6 2 5 1 3];
else, schedule=[6 3 1 5 2 4 2 4 6 1 3 5]; end
visits=zeros(1,6);
ends = cumsum(C);
starts = [1,ends(1:end-1)+1];
origin = pastafari.BigInt(fixture.first_day-1);
calculation = pastafari.BigInt(fixture.calculation_day);
catalog = pastafari.sourceLanguageCatalog();
assert(all(cutletNames>=1 & cutletNames<=numel(catalog.cutlets)) && ...
    all(monthNames>=1 & monthNames<=numel(catalog.months)), ...
    'Stage55:MiddleCatalog');
for mode=schedule
    word = double(jsondecode(fileread(fullfile(logs,[labels{mode},'.json']))));
    word=word(:).';
    assert(all(isfinite(word)) && all(word==fix(word)) && all(word>=1 & word<=K),'Stage55:SoakDomain');
    visits(mode)=visits(mode)+1;
    trial=visits(mode);
    assert(numel(word)==4244 && ...
        isequal(accumarray(word(:),1,[K 1]),L(:)), ...
        'Stage55:MiddleMultiplicity');
    firstPositions = zeros(1,K);
    lastPositions = zeros(1,K);
    for j=1:K
        p=find(word==j);
        firstPositions(j)=p(1);
        lastPositions(j)=p(end);
    end
    assert(all(diff(firstPositions)>0) && all(diff(lastPositions)>0), ...
        'Stage55:MiddleLegality');
        path = fullfile(logs,sprintf('%s_S%d_R%d.csv', ...
            labels{mode},session,trial));
        [fid,msg] = fopen(path,'w','n','US-ASCII');
        assert(fid>=0,'Stage55:MiddleOpen',msg);
        guard = onCleanup(@()fclose(fid));
        fprintf(fid,'POSITION,YEAR,CUTLET_INDEX,CUTLET_DAY,MONTH_INDEX,MONTH_DAY\n');
        seen = zeros(1,K);
        t = tic;
        for position=1:4244
            symbol=word(position);
            seen(symbol)=seen(symbol)+1;
            part=find(position<=ends,1,'first');
            assert(~isempty(part),'Stage55:MiddleCutlet');
            ordinal=position-starts(part)+1;
            day=pastafari.BigInt(fixture.first_day+position-1);
            ctx=pastafari.MonsterContext(calculation,day);
            [ctx,actualSymbol,actualDay]= ...
                pastafari.MonthDayCompatibilityRoute.call(ctx,word,origin,day);
            assert(actualSymbol==symbol && ...
                actualDay==pastafari.BigInt(seen(symbol)) && ...
                any(strcmp(ctx.branchTrace,'PATCH_25_OCCURRENCE_COUNT')), ...
                'Stage55:MiddleMonthRoute');
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
                'Stage55:MiddleFiveFields');
            fprintf(fid,'%d,%d,%d,%d,%d,%d\n',position,5000, ...
                cutletNames(part),ordinal,monthNames(symbol), ...
                str2double(char(actualDay)));
        end
        assert(isequal(seen,L),'Stage55:MiddleFinalCounts');
        clear guard
        assert(exist(path,'file')==2,'Stage55:MiddleOutput');
        elapsed=toc(t);
        assert(elapsed<=60,'Stage55:SoakCaseTime');
        fprintf('SOAK_NATIVE_CASE_PASS WORD=%s SESSION=%d RUN=%d ROWS=4244 SEC=%.3f\n', ...
            labels{mode},session,trial,elapsed);
    for badPosition=[0,4245]
        target=pastafari.BigInt(fixture.first_day+badPosition-1);
        invalid=pastafari.MonsterContext(calculation,target);
        rejected=false;
        try
            pastafari.MonthDayCompatibilityRoute.call(invalid,word,origin,target);
        catch err
            rejected=strcmp(err.identifier,'Pastafari:MonthDay:TargetOutsideYear');
        end
        assert(rejected,'Stage55:MiddleNegativeBoundary');
    end
end
assert(all(visits==2),'Stage55:SoakVisits');
fprintf('SOAK_NATIVE_SESSION_PASS SESSION=%d CASES=12 NEGATIVE=24\n',session);
fprintf('STAGE55_NATIVE_RANK_NOT_VERIFIED\n');
fprintf('STAGE55_FINAL_STAGE_PASS_NOT_VERIFIED\n');
end
