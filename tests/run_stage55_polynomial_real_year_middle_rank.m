function run_stage55_polynomial_real_year_middle_rank(prefixLimit)
if nargin==0, prefixLimit=0; end
assert(isscalar(prefixLimit) && any(prefixLimit==[0 2 6 12 202 265 4244 5000]), 'Invalid diagnostic prefix limit.');
% QA-only Native MATLAB test for the experimental polynomial whole-weave
% family. It does NOT call the production calendar converter F(c,t).
% The target is the exact 45-month / 4244-day middle-rank word independently
% inverse-ranked by the pinned GMP C++ verifier.
here=fileparts(mfilename('fullpath'));
root=fileparts(here);
addpath(fullfile(root,'src'));
cleanup=onCleanup(@() rmpath(fullfile(root,'src'))); %#ok<NASGU>
if ~exist(fullfile(root,'evidence'),'dir')
    mkdir(fullfile(root,'evidence'));
end

fprintf('STAGE55_POLYNOMIAL_MIDDLE_RANK_BEGIN\n');
fprintf('REFERENCE_CXX_INVERSE_RUN=45686680226\n');
fprintf('SOURCE_RANK_CATALOG_ORACLE_RUN=45691066424\n');
fprintf('PROJECTION_SOAK_RUN=45655790072\n');
assert(strcmp(sha256Ascii('abc'), ...
    'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad'), ...
    'SHA-256 helper self-test failed.');

metadataPath=fullfile(root,'tests','fixtures', ...
    'stage55_year5000_appendix_a_metadata.json');
wordPath=fullfile(root,'tests','fixtures', ...
    'stage55_year5000_middle_word.json');
metadata=jsondecode(fileread(metadataPath));
expected=double(jsondecode(fileread(wordPath)));
L=double(metadata.month_lengths(:).');
expected=double(expected(:).');
assert(metadata.year==5000 && metadata.months==45 && ...
    numel(L)==45 && sum(L)==4244 && min(L)==25 && max(L)==122, ...
    'Pinned Year-5000 metadata dimensions mismatch.');
assert(numel(expected)==4244 && all(expected>=1) && ...
    all(expected<=45) && all(expected==fix(expected)), ...
    'Pinned middle-word fixture dimensions/symbols mismatch.');

wrapperPath=fullfile(root,'src','+pastafari', ...
    'MonthWeavingCompatibilityRoute.m');
wrapper=fileread(wrapperPath);
assert(contains(wrapper,'pastafari.MonthWeavingDPPatchWrapper.callWithRing(') && ...
    ~contains(wrapper,'WholeMonthWeavingFamilyPolynomial'), ...
    'QA must leave the historic production wrapper untouched.');
fprintf('INPUT_FIXTURES_PASS MONTHS=45 DAYS=4244 MIN=25 MAX=122\n');
fprintf('PRODUCTION_WRAPPER_STILL_HISTORIC=1 FULL_CONVERTER_CALLS=0\n');

if prefixLimit==5000
    % Source-derived rank only, NOT a date conversion or a full weaving.
    overlay=getenv('PASTAFARI_QA_OVERLAY');
    assert(isfolder(overlay)); addpath(overlay,'-begin');
    assert(strcmp(which('pastafari.BigInt'),fullfile(overlay,'+pastafari','BigInt.m')));
    % All source functions except the tested arithmetic overlay remain exact.
    N=pastafari.BigInt(strtrim(fileread(fullfile(root,'evidence','root-count.txt'))));
    assert(strcmp(sha256Ascii(char(N)), ...
        'c0c08ac89c8faaaf589d1b3e076fe1e96405f2ad7172a15efa9d028fb43fb6f8'));
    c=pastafari.BigInt(metadata.calculation_day);
    firstDay=pastafari.BigInt(metadata.first_day);
    sauce=pastafari.sauceWithCurrentScars(c,firstDay);
    assert(sauce.calculationDay==c && sauce.targetDay==firstDay);
    order=double(sauce.orderAt46Latch(:).');
    assert(isequal(sort(order),1:6));
    stream=pastafari.buildMonthWeavingAnswerRing(sauce);
    bowls=cell(1,6);
    for i=1:6, bowls{i}=char(sauce.bowls{i}); end
    one=pastafari.BigInt(1);
    M=pastafari.BigInt('170141183460469231731687303715884105727');
    space=M; places=1;
    while space<N
        space=space*M; places=places+1;
        assert(places<=200);
    end
    assert(places>1);
    wide=one; weight=one; digits=cell(1,places);
    for j=0:places-1
        digit=pastafari.AnswerRingStreamFactory.answerAt(stream,pastafari.BigInt(j))-one;
        assert(digit>=pastafari.BigInt(0) && digit<M);
        digits{j+1}=char(digit);
        wide=wide+digit*weight; weight=weight*M;
    end
    fprintf('QA_SOURCE_WEAVE_RING_PASS PLACES=%d\n',places);
    data=struct('schema','STAGE55_SOURCE_WEAVE_RANK/1', ...
        'calculation_day',metadata.calculation_day,'structure_target_day',metadata.first_day, ...
        'bowls',{bowls},'order',order,'ring_first',char(stream.first), ...
        'direction',stream.directionStep,'digits',{digits},'root_count',char(N), ...
        'wide',char(wide),'places',places,'space',char(space), ...
        'full_converter_calls',0,'stage55_accepted',false);
    file=fullfile(root,'evidence','source-weave-rank.json');
    fid=fopen(file,'w'); assert(fid>=0);
    fwrite(fid,jsonencode(data),'char'); fwrite(fid,newline,'char'); fclose(fid);
    % Exact bounded rejection calculation. The historical selector's loop
    % is called only if it will terminate at the first iteration.
    limit=space.floorDiv(N)*N;
    if wide<=limit
        [rank,nativeWide,accepted,nativePlaces,nativeSpace,nativeLimit,steps]= ...
            pastafari.WideSelectionDetourPatch.apply(stream,N);
        assert(nativeWide==wide && accepted==wide && nativePlaces==places && ...
            nativeSpace==space && nativeLimit==limit && steps.iszero());
        selectorNative=true;
    else
        if stream.directionStep==1
            accepted=one; steps=space-wide+one;
        else
            accepted=limit; steps=wide-limit;
        end
        acceptedOffset=accepted-one;
        rank=acceptedOffset.regularMod(N)+one;
        selectorNative=false;
    end
    assert(rank>=one && rank<=N);
    data.rank=char(rank); data.acceptance_limit=char(limit);
    data.accepted=char(accepted); data.rejection_steps=char(steps);
    data.native_selector_executed=selectorNative;
    fid=fopen([file,'.part'],'w'); assert(fid>=0);
    fwrite(fid,jsonencode(data),'char'); fwrite(fid,newline,'char'); fclose(fid);
    movefile([file,'.part'],file,'f');
    fprintf('QA_SOURCE_WEAVE_RANK_PASS PLACES=%d RANK_DIGITS=%d NATIVE_SELECTOR=%d\n', ...
        places,numel(char(rank)),selectorNative);
    return
end

if prefixLimit==4244
    overlay=getenv('PASTAFARI_QA_OVERLAY');
    assert(isfolder(overlay));
    addpath(overlay,'-begin');
    assert(strcmp(which('pastafari.BigInt'),fullfile(overlay,'+pastafari','BigInt.m')));
    qaFactoredSmallOracle();
    prior=jsondecode(fileread(fullfile(root,'evidence','prior-prefix-result.json')));
    certificate=jsondecode(fileread(fullfile(root,'evidence','interval-hashes.json')));
    assert(numel(certificate)==4244 && prior.prefix_symbols_matched==265 && ...
        prior.full_converter_calls==0 && ~prior.full_word_verified && ~prior.stage55_accepted);
    prefix=zeros(1,4244);
    prefix(1:265)=double(prior.prefix(:).');
    remaining=double(prior.remaining(:).');
    opened=prior.opened_up_to; closed=prior.closed_up_to;
    assert(isequal(prefix(1:265),expected(1:265)) && opened==45 && closed==0);
    expectedRemaining=L;
    for i=1:265, expectedRemaining(prefix(i))=expectedRemaining(prefix(i))-1; end
    assert(isequal(remaining,expectedRemaining));
    rank=pastafari.BigInt(prior.rank_decimal); count=pastafari.BigInt(prior.count_decimal);
    assert(strcmp(sha256Ascii(char(rank)),certificate(265).rank_sha256) && ...
        strcmp(sha256Ascii(char(count)),certificate(265).count_sha256));
    one=pastafari.BigInt(1);
    ledger=fopen(fullfile(root,'evidence','suffix-ledger.jsonl'),'w');
    assert(ledger>=0); ledgerClose=onCleanup(@() fclose(ledger)); %#ok<NASGU>
    totalSeconds=0;
    fprintf('QA_FULL_SUFFIX_BEGIN START=265 TARGET=4244\n');
    for position=266:4244
        stepTimer=tic;
        [piece,cursor]=qaFactoredStep(L,remaining,opened,closed,rank,count);
        elapsed=toc(stepTimer); totalSeconds=totalSeconds+elapsed;
        assert(cursor.initialCount==count && isscalar(piece) && piece==expected(position));
        assert(certificate(position).position==position && certificate(position).symbol==piece);
        prefix(position)=piece;
        oldClosed=closed;
        remaining(piece)=remaining(piece)-1;
        assert(isequal(double(cursor.remaining(:).'),remaining));
        opened=cursor.openedUpTo; closed=cursor.closedUpTo;
        assert(opened==45 && closed>=oldClosed && closed<=oldClosed+1);
        assert(all(remaining(1:closed)==0) && all(remaining(closed+1:end)>0));
        assert(sum(remaining)==4244-position && cursor.done==(position==4244));
        rank=cursor.rank; count=cursor.count;
        rHash=sha256Ascii(char(rank)); cHash=sha256Ascii(char(count));
        assert(rank>=one && rank<=count);
        assert(strcmp(rHash,certificate(position).rank_sha256) && ...
            strcmp(cHash,certificate(position).count_sha256),'Independent exact interval mismatch.');
        row=struct('position',position,'symbol',piece,'opened',opened,'closed',closed, ...
            'rank_sha256',rHash,'count_sha256',cHash,'step_seconds',elapsed);
        fprintf(ledger,'%s\n',jsonencode(row));
        % Compact ledger plus periodically atomically replaced checkpoint.
        if mod(position,25)==0 || closed~=oldClosed || position==4244
            result=struct('schema','STAGE55_POLYNOMIAL_PREFIX_DIAGNOSTIC/1', ...
                'prefix_only',position~=4244,'prefix_symbols_matched',position,'days',4244, ...
                'prefix',prefix(1:position),'remaining',remaining,'opened_up_to',opened, ...
                'closed_up_to',closed,'rank_decimal',char(rank),'count_decimal',char(count), ...
                'rank_sha256',rHash,'count_sha256',cHash, ...
                'initial_count_sha256',prior.initial_count_sha256, ...
                'original_rank_sha256',prior.original_rank_sha256, ...
                'prior_native_run',45948885720,'reference_cxx_inverse_run_id',45686680226, ...
                'step_seconds',elapsed,'qa_arithmetic_overlay',true, ...
                'full_word_verified',position==4244,'full_converter_calls',0,'stage55_accepted',false);
            file=fullfile(root,'evidence','latest-suffix-cursor.json');
            fid=fopen([file,'.part'],'w'); assert(fid>=0);
            fwrite(fid,jsonencode(result),'char'); fwrite(fid,newline,'char'); fclose(fid);
            movefile([file,'.part'],file,'f');
            fprintf('QA_FULL_SUFFIX_PROGRESS PREFIX=%d CLOSED=%d SECONDS=%.3f\n',position,closed,totalSeconds);
        end
    end
    assert(isequal(prefix,expected) && all(remaining==0) && opened==45 && closed==45);
    assert(rank==one && count==one && cursor.done);
    first=zeros(1,45); last=zeros(1,45);
    for k=1:45
        ix=find(prefix==k);
        assert(numel(ix)==L(k));
        first(k)=ix(1); last(k)=ix(end);
    end
    assert(all(diff(first)>0) && all(diff(last)>0));
    result=struct('schema','STAGE55_QA_FACTORED_FULL_WORD/1','full_word_verified',true, ...
        'prefix_previous',265,'new_symbols',3979,'symbols_matched',4244, ...
        'closed_months',45,'final_rank',char(rank),'final_count',char(count), ...
        'suffix_compute_seconds',totalSeconds,'full_converter_calls',0,'stage55_accepted',false);
    fid=fopen(fullfile(root,'evidence','full-word-summary.json'),'w'); assert(fid>=0);
    fwrite(fid,jsonencode(result),'char'); fwrite(fid,newline,'char'); fclose(fid);
    fprintf('QA_FULL_WORD_PASS MATCHED=4244 CLOSED=45 RANK=1 COUNT=1 FULL_CONVERTER_CALLS=0\n');
    return
end

if prefixLimit==265
    overlay=getenv('PASTAFARI_QA_OVERLAY');
    assert(isfolder(overlay));
    addpath(overlay,'-begin');
    assert(strcmp(which('pastafari.BigInt'),fullfile(overlay,'+pastafari','BigInt.m')));
    assert(strcmp(which('pastafari.unrankGeneralWeaveSuffixChunkAdjoint'), ...
        fullfile(overlay,'+pastafari','unrankGeneralWeaveSuffixChunkAdjoint.m')));
    qaFactoredSmallOracle();
    prior=jsondecode(fileread(fullfile(root,'evidence','prior-prefix-result.json')));
    certificate=jsondecode(fileread(fullfile(root,'evidence','interval-hashes.json')));
    assert(numel(certificate)==265 && prior.prefix_symbols_matched==165 && ...
        prior.full_converter_calls==0 && ~prior.full_word_verified && ~prior.stage55_accepted);
    prefix=double(prior.prefix(:).'); remaining=double(prior.remaining(:).');
    opened=prior.opened_up_to; closed=prior.closed_up_to;
    assert(isequal(prefix,expected(1:165)) && opened==43 && closed==0);
    expectedRemaining=L;
    for i=1:165, expectedRemaining(prefix(i))=expectedRemaining(prefix(i))-1; end
    assert(isequal(remaining,expectedRemaining));
    rank=pastafari.BigInt(prior.rank_decimal); count=pastafari.BigInt(prior.count_decimal);
    assert(strcmp(sha256Ascii(char(rank)),certificate(165).rank_sha256) && ...
        strcmp(sha256Ascii(char(count)),certificate(165).count_sha256));
    fprintf('QA_CERTIFIED_CURSOR_RESUME START=165 TARGET=265\n');
    for position=166:265
        stepTimer=tic;
        if opened<44
            [piece,cursor]=pastafari.unrankGeneralWeaveSuffixChunkAdjoint( ...
                L,remaining,opened,closed,rank,1);
            method='native_adjoint';
        else
            [piece,cursor]=qaFactoredStep(L,remaining,opened,closed,rank,count);
            method='qa_factored_last_order';
        end
        elapsed=toc(stepTimer);
        assert(cursor.initialCount==count && isscalar(piece) && piece==expected(position));
        assert(certificate(position).position==position && ...
            certificate(position).symbol==piece);
        prefix=[prefix,piece]; %#ok<AGROW>
        remaining(piece)=remaining(piece)-1;
        assert(isequal(double(cursor.remaining(:).'),remaining));
        opened=cursor.openedUpTo; closed=cursor.closedUpTo;
        assert(opened==max(prefix) && closed==0 && ~cursor.done);
        rank=cursor.rank; count=cursor.count;
        rHash=sha256Ascii(char(rank)); cHash=sha256Ascii(char(count));
        assert(rank>=pastafari.BigInt(1) && rank<=count);
        assert(strcmp(rHash,certificate(position).rank_sha256) && ...
            strcmp(cHash,certificate(position).count_sha256), ...
            'Independent exact interval mismatch.');
        result=struct('schema','STAGE55_POLYNOMIAL_PREFIX_DIAGNOSTIC/1', ...
            'prefix_only',true,'prefix_symbols_matched',position,'days',4244, ...
            'prefix',prefix,'remaining',remaining,'opened_up_to',opened, ...
            'closed_up_to',closed,'rank_decimal',char(rank),'count_decimal',char(count), ...
            'rank_sha256',rHash,'count_sha256',cHash, ...
            'initial_count_sha256',prior.initial_count_sha256, ...
            'original_rank_sha256',prior.original_rank_sha256, ...
            'prior_native_run',45909328891,'reference_cxx_inverse_run_id',45686680226, ...
            'step_seconds',elapsed,'method',method,'qa_arithmetic_overlay',true,'full_word_verified',false, ...
            'full_converter_calls',0,'stage55_accepted',false);
        file=fullfile(root,'evidence',sprintf('prefix-%04d-result.json',position));
        fid=fopen([file,'.part'],'w'); assert(fid>=0);
        fwrite(fid,jsonencode(result),'char'); fwrite(fid,newline,'char'); fclose(fid);
        movefile([file,'.part'],file,'f');
        fprintf('QA_CERTIFIED_STEP_PASS PREFIX=%d SYMBOL=%d OPENED=%d SECONDS=%.3f METHOD=%s\n', ...
            position,piece,opened,elapsed,method);
    end
    assert(opened==45 && closed==0 && sum(remaining)==3979);
    fprintf('QA_CERTIFIED_PREFIX_PASS PREFIX=265 OPENED=45 FULL_WORD_VERIFIED=0\n');
    return
end

if prefixLimit==202
    overlay=getenv('PASTAFARI_QA_OVERLAY');
    assert(isfolder(overlay));
    addpath(overlay,'-begin');
    assert(strcmp(which('pastafari.BigInt'),fullfile(overlay,'+pastafari','BigInt.m')));
    assert(strcmp(which('pastafari.unrankGeneralWeaveSuffixChunkAdjoint'), ...
        fullfile(overlay,'+pastafari','unrankGeneralWeaveSuffixChunkAdjoint.m')));
    qaArithmeticExactness();
    prior=jsondecode(fileread(fullfile(root,'evidence','prior-prefix-result.json')));
    certificate=jsondecode(fileread(fullfile(root,'evidence','interval-hashes.json')));
    assert(numel(certificate)==202 && prior.prefix_symbols_matched==12 && ...
        prior.full_converter_calls==0 && ~prior.full_word_verified && ~prior.stage55_accepted);
    prefix=double(prior.prefix(:).'); remaining=double(prior.remaining(:).');
    opened=prior.opened_up_to; closed=prior.closed_up_to;
    assert(isequal(prefix,expected(1:12)) && opened==10 && closed==0);
    expectedRemaining=L;
    for i=1:12, expectedRemaining(prefix(i))=expectedRemaining(prefix(i))-1; end
    assert(isequal(remaining,expectedRemaining));
    rank=pastafari.BigInt(prior.rank_decimal); count=pastafari.BigInt(prior.count_decimal);
    assert(strcmp(sha256Ascii(char(rank)),certificate(12).rank_sha256) && ...
        strcmp(sha256Ascii(char(count)),certificate(12).count_sha256));
    fprintf('QA_CERTIFIED_CURSOR_RESUME START=12 TARGET=202\n');
    for position=13:202
        stepTimer=tic;
        [piece,cursor]=pastafari.unrankGeneralWeaveSuffixChunkAdjoint( ...
            L,remaining,opened,closed,rank,1);
        elapsed=toc(stepTimer);
        assert(cursor.initialCount==count && isscalar(piece) && piece==expected(position));
        assert(certificate(position).position==position && ...
            certificate(position).symbol==piece);
        prefix=[prefix,piece]; %#ok<AGROW>
        remaining(piece)=remaining(piece)-1;
        assert(isequal(double(cursor.remaining(:).'),remaining));
        opened=cursor.openedUpTo; closed=cursor.closedUpTo;
        assert(opened==max(prefix) && closed==0 && ~cursor.done);
        rank=cursor.rank; count=cursor.count;
        rHash=sha256Ascii(char(rank)); cHash=sha256Ascii(char(count));
        assert(rank>=pastafari.BigInt(1) && rank<=count);
        assert(strcmp(rHash,certificate(position).rank_sha256) && ...
            strcmp(cHash,certificate(position).count_sha256), ...
            'Independent exact interval mismatch.');
        result=struct('schema','STAGE55_POLYNOMIAL_PREFIX_DIAGNOSTIC/1', ...
            'prefix_only',true,'prefix_symbols_matched',position,'days',4244, ...
            'prefix',prefix,'remaining',remaining,'opened_up_to',opened, ...
            'closed_up_to',closed,'rank_decimal',char(rank),'count_decimal',char(count), ...
            'rank_sha256',rHash,'count_sha256',cHash, ...
            'initial_count_sha256',prior.initial_count_sha256, ...
            'original_rank_sha256',prior.original_rank_sha256, ...
            'prior_native_run',45908453935,'reference_cxx_inverse_run_id',45686680226, ...
            'step_seconds',elapsed,'qa_arithmetic_overlay',true,'full_word_verified',false, ...
            'full_converter_calls',0,'stage55_accepted',false);
        file=fullfile(root,'evidence',sprintf('prefix-%04d-result.json',position));
        fid=fopen([file,'.part'],'w'); assert(fid>=0);
        fwrite(fid,jsonencode(result),'char'); fwrite(fid,newline,'char'); fclose(fid);
        movefile([file,'.part'],file,'f');
        fprintf('QA_CERTIFIED_STEP_PASS PREFIX=%d SYMBOL=%d OPENED=%d SECONDS=%.3f\n', ...
            position,piece,opened,elapsed);
    end
    assert(opened==44 && closed==0 && sum(remaining)==4042);
    fprintf('QA_CERTIFIED_PREFIX_PASS PREFIX=202 OPENED=44 FULL_WORD_VERIFIED=0\n');
    return
end

if prefixLimit==12
    overlay=getenv('PASTAFARI_QA_OVERLAY');
    assert(isfolder(overlay),'QA-only arithmetic overlay missing.');
    addpath(overlay,'-begin');
    assert(strcmp(which('pastafari.BigInt'),fullfile(overlay,'+pastafari','BigInt.m')), ...
        'Optimized arithmetic was not selected.');
    assert(strcmp(which('pastafari.unrankGeneralWeaveSuffixChunkAdjoint'), ...
        fullfile(overlay,'+pastafari','unrankGeneralWeaveSuffixChunkAdjoint.m')));
    qaArithmeticExactness();
    prior=jsondecode(fileread(fullfile(root,'evidence','prior-prefix-result.json')));
    assert(prior.prefix_symbols_matched==6 && prior.full_converter_calls==0 && ...
        ~prior.full_word_verified && ~prior.stage55_accepted);
    prefix=double(prior.prefix(:).'); remaining=double(prior.remaining(:).');
    opened=prior.opened_up_to; closed=prior.closed_up_to;
    assert(isequal(prefix,expected(1:6)) && opened==6 && closed==0);
    expectedRemaining=L;
    for i=1:6, expectedRemaining(prefix(i))=expectedRemaining(prefix(i))-1; end
    assert(isequal(remaining,expectedRemaining));
    rank=pastafari.BigInt(prior.rank_decimal); count=pastafari.BigInt(prior.count_decimal);
    assert(strcmp(sha256Ascii(char(rank)),'71223178e09a86889e1c5497cd7ae30e2458cdb58d0e0d11b96ecb3460959443'));
    assert(strcmp(sha256Ascii(char(count)),'c47a58f5b9fb8b9d1bb3c17be5b8573dcf72b08e2a3ad0d429672916c5b9f49e'));
    rankHashes={ ...
        '9bcda2a7da72a077ee51db8debd858b2cdd578ab5b95913212209d9bf2a313fa', ...
        '038e3565af370fbac347033fada61fdfe4830e265d4cf94c40d6f6ceca9acd79', ...
        '6ba97455e7575822d215fe020e7140815d55759f889710f99c23e2281fd3633a', ...
        '39053710e806551b019c8a4b87ef0e2c98afece5efc384a88431dd91a5b33fc8', ...
        'e0c60e5e0b4deb0b169269402d43c420d4fe5c4b2295ba3dc5f7473be9776ac1', ...
        'a39b215363a95ead14111432cd29b779be0e333857d7d7570d217cf0abdada55'};
    countHashes={ ...
        '311b713ba26e926b60243b9a63b0bb8d13132a17d95a346b4841b02e5b5e2eec', ...
        '3adfc02aa07e839ae8477c1852b05a3012b916dad070e3aa24a9834757e138c3', ...
        'd17a7f10a6ed4ff570134adb6e13f0d028118d9985b56ee6a4c28249924ecf0a', ...
        '42433e519055e6f1d25b640264c4ce3b1f72abc5e4a9df66a820209ff4c7d96a', ...
        'fd999f8e3c4cf00910df2956eb7dfff62bc1b891d503ec51d5336ac3e44c4709', ...
        '9cc21ee7a163a496a079b4610124dd7a83e612ae111a07c7bf6f71f23ed69c44'};
    fprintf('QA_OPTIMIZED_CURSOR_START PREFIX=6\n');
    for position=7:12
        stepTimer=tic;
        [piece,cursor]=pastafari.unrankGeneralWeaveSuffixChunkAdjoint( ...
            L,remaining,opened,closed,rank,1);
        elapsed=toc(stepTimer);
        assert(cursor.initialCount==count && isscalar(piece) && piece==expected(position));
        prefix=[prefix,piece]; %#ok<AGROW>
        remaining(piece)=remaining(piece)-1;
        assert(isequal(double(cursor.remaining(:).'),remaining));
        opened=cursor.openedUpTo; closed=cursor.closedUpTo;
        assert(opened==max(prefix) && closed==0 && ~cursor.done);
        rank=cursor.rank; count=cursor.count;
        rHash=sha256Ascii(char(rank)); cHash=sha256Ascii(char(count));
        assert(rank>=pastafari.BigInt(1) && rank<=count);
        assert(strcmp(rHash,rankHashes{position-6}) && strcmp(cHash,countHashes{position-6}), ...
            'Independent exact interval mismatch.');
        result=struct('schema','STAGE55_POLYNOMIAL_PREFIX_DIAGNOSTIC/1', ...
            'prefix_only',true,'prefix_symbols_matched',position,'days',4244, ...
            'prefix',prefix,'remaining',remaining,'opened_up_to',opened, ...
            'closed_up_to',closed,'rank_decimal',char(rank),'count_decimal',char(count), ...
            'rank_sha256',rHash,'count_sha256',cHash, ...
            'initial_count_sha256',prior.initial_count_sha256, ...
            'original_rank_sha256',prior.original_rank_sha256, ...
            'prior_native_run',45905761751,'reference_cxx_inverse_run_id',45686680226, ...
            'step_seconds',elapsed,'qa_arithmetic_overlay',true,'full_word_verified',false, ...
            'full_converter_calls',0,'stage55_accepted',false);
        file=fullfile(root,'evidence',sprintf('prefix-%02d-result.json',position));
        fid=fopen([file,'.part'],'w'); assert(fid>=0);
        fwrite(fid,jsonencode(result),'char'); fwrite(fid,newline,'char'); fclose(fid);
        movefile([file,'.part'],file,'f');
        fprintf('QA_OPTIMIZED_STEP_PASS PREFIX=%d SYMBOL=%d SECONDS=%.3f\n',position,piece,elapsed);
    end
    fprintf('QA_OPTIMIZED_PREFIX_PASS PREFIX=12 FULL_WORD_VERIFIED=0\n');
    return
end

if prefixLimit==6
    % Resume from the actual prior MATLAB cursor, not from oracle rank inputs.
    % Independent C++ interval-derived hashes are used only as postconditions.
    prior=jsondecode(fileread(fullfile(root,'evidence','prior-prefix-result.json')));
    assert(strcmp(prior.schema,'STAGE55_POLYNOMIAL_PREFIX_DIAGNOSTIC/1') && ...
        prior.prefix_only && prior.prefix_symbols_matched==2 && ...
        ~prior.full_word_verified && prior.full_converter_calls==0);
    prefix=double(prior.prefix(:).');
    remaining=double(prior.remaining(:).');
    opened=prior.opened_up_to; closed=prior.closed_up_to;
    assert(isequal(prefix,expected(1:2)) && opened==2 && closed==0);
    expectedRemaining=L;
    for i=1:2
        expectedRemaining(prefix(i))=expectedRemaining(prefix(i))-1;
    end
    assert(isequal(remaining,expectedRemaining));
    rank=pastafari.BigInt(prior.rank_decimal);
    count=pastafari.BigInt(prior.count_decimal);
    assert(rank>=pastafari.BigInt(1) && rank<=count);
    assert(strcmp(sha256Ascii(char(rank)), ...
        '1191f818e77c6dd94d3d2e8e70ee0a419b2a2eb3234ffd60098f8481769c99ac'));
    assert(strcmp(sha256Ascii(char(count)), ...
        'd14117c552025c61ee7f5af7140344e390202cdec045e219f1925e60495a53ce'));
    rankHashes={ ...
        '25b8697dfb238f466a4c2457e168d3c6cdb177fa8f9b4390dd91e844ba4d9d46', ...
        '637ec208a1ddbbd3f5b8d236502146a4eb0c84f732736d891e7f243fa47d8d87', ...
        'f9bace24e466e0a54b8c9438bb024815f6c67185358153e0fbae5a0732e9a32b', ...
        '71223178e09a86889e1c5497cd7ae30e2458cdb58d0e0d11b96ecb3460959443'};
    countHashes={ ...
        'da8d066cf0c7a5d5a613edf7de109301969997102c19794d41a165ec62c30c4a', ...
        '2b8fbcebcd72d7197a6b216c3271cd241cdd6ab81cfbb7da17387ddbf2498cba', ...
        '8c0e6abeeee779f8a89c67f7e12aa0198118fdee4cc76290648ae1d92719211f', ...
        'c47a58f5b9fb8b9d1bb3c17be5b8573dcf72b08e2a3ad0d429672916c5b9f49e'};
    fprintf('RESUME_EXACT_CURSOR_PASS PREFIX=2 REMAINING=%d\n',sum(remaining));
    for position=3:6
        fprintf('RESUME_NATIVE_STEP_BEGIN PREFIX=%d\n',position);
        stepTimer=tic;
        [piece,cursor]=pastafari.unrankGeneralWeaveSuffixChunkAdjoint( ...
            L,remaining,opened,closed,rank,1);
        elapsed=toc(stepTimer);
        assert(cursor.initialCount==count,'Prior count differs from native parent.');
        assert(isscalar(piece) && piece==expected(position),'Independent word mismatch.');
        prefix=[prefix,piece]; %#ok<AGROW>
        remaining(piece)=remaining(piece)-1;
        assert(isequal(double(cursor.remaining(:).'),remaining));
        opened=cursor.openedUpTo; closed=cursor.closedUpTo;
        assert(opened==max(prefix) && closed==0 && ~cursor.done);
        rank=cursor.rank; count=cursor.count;
        assert(rank>=pastafari.BigInt(1) && rank<=count);
        rHash=sha256Ascii(char(rank)); cHash=sha256Ascii(char(count));
        assert(strcmp(rHash,rankHashes{position-2}),'Independent residual rank mismatch.');
        assert(strcmp(cHash,countHashes{position-2}),'Independent suffix count mismatch.');
        result=struct('schema','STAGE55_POLYNOMIAL_PREFIX_DIAGNOSTIC/1', ...
            'prefix_only',true,'prefix_symbols_matched',position,'days',4244, ...
            'prefix',prefix,'remaining',remaining,'opened_up_to',opened, ...
            'closed_up_to',closed,'rank_decimal',char(rank),'count_decimal',char(count), ...
            'rank_sha256',rHash,'count_sha256',cHash, ...
            'initial_count_sha256',prior.initial_count_sha256, ...
            'original_rank_sha256',prior.original_rank_sha256, ...
            'prior_native_run',45900820670,'reference_cxx_inverse_run_id',45686680226, ...
            'step_seconds',elapsed,'full_word_verified',false, ...
            'full_converter_calls',0,'stage55_accepted',false);
        file=fullfile(root,'evidence',sprintf('prefix-%02d-result.json',position));
        fid=fopen([file,'.part'],'w'); assert(fid>=0);
        fwrite(fid,jsonencode(result),'char'); fwrite(fid,newline,'char'); fclose(fid);
        movefile([file,'.part'],file,'f');
        fprintf('RESUME_NATIVE_STEP_PASS PREFIX=%d SYMBOL=%d EXACT_CURSOR_MATCH=1 SECONDS=%.3f\n', ...
            position,piece,elapsed);
    end
    fprintf('POLYNOMIAL_PREFIX_RESUME_PASS PREFIX=6 FULL_WORD_VERIFIED=0\n');
    return
end

countTimer=tic;
family=pastafari.WholeMonthWeavingFamilyPolynomial(L(:));
T=family.count();
countSeconds=toc(countTimer);
Ttext=char(T);
assert(numel(Ttext)==6765 && ...
    strcmp(sha256Ascii(Ttext), ...
    'c0c08ac89c8faaaf589d1b3e076fe1e96405f2ad7172a15efa9d028fb43fb6f8'), ...
    'Polynomial root count differs from independent GMP inverse-rank certificate.');
fprintf('POLYNOMIAL_MIDDLE_COUNT_PASS DIGITS=%d SECONDS=%.3f\n', ...
    numel(Ttext),countSeconds);

[q,remainder]=T.floorDivMod(pastafari.BigInt(2));
assert(remainder>=pastafari.BigInt(0) && ...
    remainder<pastafari.BigInt(2), ...
    'Exact floor division remainder is outside [0,2).');
R=q+pastafari.BigInt(1);
Rtext=char(R);
assert(numel(Rtext)==6764 && ...
    strcmp(sha256Ascii(Rtext), ...
    'cd5ce4036fc8e99355a4bab5d48c3db473422083d035df5e0af25297be1be3b6'), ...
    'Polynomial middle rank differs from independent GMP inverse-rank certificate.');
fprintf('POLYNOMIAL_MIDDLE_RANK_POLICY_PASS DIGITS=%d POLICY=floor(T/2)+1\n', ...
    numel(Rtext));

if prefixLimit==2
    % The first letter is forced; the second tests the first nontrivial
    % branch of the same native adjoint candidate. No production calls.
    fprintf('POLYNOMIAL_FIRST_BRANCH_BEGIN STEPS=2\n');
    prefixTimer=tic;
    [actualPrefix,cursor]=family.prefixAt1(R,prefixLimit);
    prefixSeconds=toc(prefixTimer);
    assert(isequal(double(actualPrefix(:).'),expected(1:prefixLimit)), ...
        'Native prefix differs from independently inverse-ranked fixture.');
    assert(cursor.initialCount==T && cursor.rank>=pastafari.BigInt(1) && ...
        cursor.rank<=cursor.count && ~cursor.done, 'Exact prefix cursor invalid.');
    remaining=L;
    for i=1:numel(actualPrefix)
        remaining(actualPrefix(i))=remaining(actualPrefix(i))-1;
    end
    assert(isequal(double(cursor.remaining(:).'),remaining), ...
        'Prefix cursor remaining multiplicities differ.');
    assert(cursor.openedUpTo==max(actualPrefix) && cursor.closedUpTo==0, ...
        'Prefix frontier inconsistent.');
    result=struct('schema','STAGE55_POLYNOMIAL_PREFIX_DIAGNOSTIC/1', ...
        'prefix_only',true,'prefix_symbols_matched',2,'days',4244, ...
        'prefix',actualPrefix,'remaining',cursor.remaining, ...
        'opened_up_to',cursor.openedUpTo,'closed_up_to',cursor.closedUpTo, ...
        'rank_decimal',char(cursor.rank),'count_decimal',char(cursor.count), ...
        'initial_count_sha256',sha256Ascii(Ttext), ...
        'original_rank_sha256',sha256Ascii(Rtext), ...
        'prefix_seconds',prefixSeconds,'count_seconds',countSeconds, ...
        'full_word_verified',false,'full_converter_calls',0,'stage55_accepted',false);
    fid=fopen(fullfile(root,'evidence','prefix-result.json'),'w');
    assert(fid>=0,'Cannot create prefix diagnostic evidence.');
    closer=onCleanup(@() fclose(fid)); %#ok<NASGU>
    fwrite(fid,jsonencode(result),'char'); fwrite(fid,newline,'char');
    fprintf('POLYNOMIAL_FIRST_BRANCH_PASS MATCHED=2/2 SECONDS=%.3f\n',prefixSeconds);
    return
end

fprintf('POLYNOMIAL_MIDDLE_UNRANK_BEGIN DAYS=4244\n');
unrankTimer=tic;
actual=family.itemAt1(R);
unrankSeconds=toc(unrankTimer);
family.verifyWord(actual);
assert(isequal(double(actual(:).'),expected), ...
    'Polynomial candidate did not return the independently inverse-ranked middle word.');
assert(numel(actual)==4244 && all(actual==fix(actual)), ...
    'Polynomial candidate returned an incomplete/noninteger word.');
fprintf(['POLYNOMIAL_MIDDLE_UNRANK_PASS MONTHS=45 DAYS=4244 ', ...
    'SECONDS=%.3f WORD_MATCH=4244/4244\n'],unrankSeconds);
fprintf('POLYNOMIAL_MIDDLE_CXX_INVERSE_CROSSCHECK_PASS\n');

result=struct( ...
    'schema','STAGE55_POLYNOMIAL_MIDDLE_RANK_NATIVE/1', ...
    'pass',true, ...
    'months',45, ...
    'days',4244, ...
    'count_digits',numel(Ttext), ...
    'count_sha256',sha256Ascii(Ttext), ...
    'rank_digits',numel(Rtext), ...
    'rank_sha256',sha256Ascii(Rtext), ...
    'rank_policy','floor(T/2)+1', ...
    'word_symbols_matched',4244, ...
    'count_seconds',countSeconds, ...
    'unrank_seconds',unrankSeconds, ...
    'reference_cxx_inverse_run_id',45686680226, ...
    'source_rank_catalog_oracle_run_id',45691066424, ...
    'projection_soak_run_id',45655790072, ...
    'production_wrapper_still_historic',true, ...
    'full_converter_calls',0, ...
    'stage55_accepted',false);
fid=fopen(fullfile(root,'evidence','result.json'),'w');
assert(fid>=0,'Cannot create evidence/result.json.');
closer=onCleanup(@() fclose(fid)); %#ok<NASGU>
fwrite(fid,jsonencode(result),'char');
fwrite(fid,newline,'char');
fprintf('STAGE55_POLYNOMIAL_MIDDLE_RANK_EXPERIMENTAL_PASS\n');
end

function hex=sha256Ascii(value)
md=java.security.MessageDigest.getInstance('SHA-256');
md.update(int8(uint8(value)));
raw=md.digest();
bytes=typecast(raw,'uint8');
hex=lower(reshape(dec2hex(bytes,2).',1,[]));
end

function qaArithmeticExactness()
% Java is only a test oracle, never the implementation under test.
rng(551206,'twister');
lengths=[1 7 8 31 224 225 700 6765];
divisors=[1 2 3 97 9999 1000000 9999999];
checks=0;
for n=lengths
    for variant=1:3
        if variant==1
            a=repmat('9',1,n);
        elseif variant==2
            a=['1',repmat('0',1,n-1)];
        else
            a=['7',char(randi([48 57],1,n-1))];
        end
        for sign=[1 -1]
            s=a; if sign<0, s=['-',a]; end
            A=pastafari.BigInt(s); J=javaObject('java.math.BigInteger',s);
            for d=divisors
                B=pastafari.BigInt(d); D=javaObject('java.math.BigInteger',sprintf('%d',d));
                [q,r]=A.floorDivMod(B);
                jr=J.mod(D); jq=J.subtract(jr); jq=jq.divide(D);
                assert(strcmp(char(q),char(jq.toString())) && strcmp(char(r),char(jr.toString())));
                P=A*B; JP=J.multiply(D);
                assert(strcmp(char(P),char(JP.toString())));
                checks=checks+2;
            end
            for m=[7 8 70 217 224 225 231]
                b=repmat('9',1,m);
                P=A*pastafari.BigInt(b);
                JB=javaObject('java.math.BigInteger',b); JP=J.multiply(JB);
                assert(strcmp(char(P),char(JP.toString())));
                checks=checks+1;
            end
        end
    end
end
fprintf('QA_ARITHMETIC_ORACLE_PASS CHECKS=%d\n',checks);
end

function [symbol,cursor]=qaFactoredStep(L,R,opened,closed,rank,F)
% QA only. With at most one unopened month, first-order constraints are
% vacuous. The suffix family equals the all-open last-order family.
assert(opened>=numel(L)-1 && rank>=pastafari.BigInt(1) && rank<=F);
blocks=qaFactoredBlocks(R(closed+1:end),F);
symbol=0;
for i=1:numel(blocks)
    b=blocks{i};
    if b.iszero(), continue; end
    if rank>b
        rank=rank-b;
    else
        symbol=closed+i;
        count=b;
        break
    end
end
assert(symbol>0);
n=R(symbol);
assert(n>0 && (n<L(symbol) || symbol==opened+1) && (n>1 || symbol==closed+1));
R(symbol)=n-1;
opened=opened+double(n==L(symbol));
closed=closed+double(n==1);
cursor=struct('remaining',R,'openedUpTo',opened,'closedUpTo',closed, ...
    'rank',rank,'count',count,'initialCount',F,'done',all(R==0));
end

function blocks=qaFactoredBlocks(r,F)
% Same common denominator identity as the frozen implementation, but
% factor D into small positive integers. Sequential gcd cancellations
% compute F/gcd(F,D) and D/gcd(F,D) without general long division.
r=double(r(:).'); m=numel(r);
assert(m>=1 && all(r>0) && all(fix(r)==r) && sum(r)<1e7);
one=pastafari.BigInt(1); zero=pastafari.BigInt(0);
S=cumsum(r); Q=F; reduced=ones(1,m);
P=cell(1,m); H=cell(1,m+1); P{1}=one; H{m+1}=one;
for j=2:m
    d=S(j)-1;
    P{j}=P{j-1}*pastafari.BigInt(d);
    [q,rem]=Q.floorDivMod(pastafari.BigInt(d));
    g=gcd(d,rem.toDoubleExact());
    assert(g>=1 && mod(d,g)==0);
    if g==d
        Q=q;
    elseif g>1
        [Q,rem]=Q.floorDivMod(pastafari.BigInt(g));
        assert(rem.iszero());
    end
    reduced(j)=d/g;
end
for j=m:-1:2
    H{j}=H{j+1}*pastafari.BigInt(S(j-1));
end
blocks=repmat({zero},1,m); total=zero;
for i=1:m
    if i==1
        N=H{2};
    elseif r(i)>1
        N=pastafari.BigInt(r(i)-1)*P{i-1}*H{i+1};
    else
        continue
    end
    for j=2:m
        if reduced(j)>1
            [N,rem]=N.floorDivMod(pastafari.BigInt(reduced(j)));
            assert(rem.iszero(),'Reduced denominator did not divide numerator.');
        end
    end
    b=Q*N;
    assert(b>=one);
    blocks{i}=b; total=total+b;
end
assert(total==F,'Factored partition differs from exact parent.');
end

function qaFactoredSmallOracle()
% Independent enumerative recurrence on small positive multiplicities.
% A label with one remaining occurrence can be selected only if it is
% the first active label. No binomial/product identity is used here.
memo=containers.Map('KeyType','char','ValueType','double');
families=0; checks=0;
for k=1:4
    for code=0:3^k-1
        r=mod(floor(code./(3.^(0:k-1))),3)+1;
        F=qaBruteLastOrder(r,memo);
        blocks=qaFactoredBlocks(r,pastafari.BigInt(F));
        families=families+1;
        for i=1:k
            if i>1 && r(i)==1
                n=0;
            else
                child=r; child(i)=child(i)-1;
                if child(1)==0, child=child(2:end); end
                n=qaBruteLastOrder(child,memo);
            end
            assert(blocks{i}==pastafari.BigInt(n));
            checks=checks+1;
        end
    end
end
assert(families==120 && checks==426);
fprintf('QA_FACTORED_SMALL_ORACLE_PASS FAMILIES=%d BLOCKS=%d\n',families,checks);
end

function n=qaBruteLastOrder(r,memo)
if isempty(r), n=1; return; end
key=sprintf('%d,',r);
if isKey(memo,key), n=memo(key); return; end
n=0;
for i=1:numel(r)
    if i>1 && r(i)==1, continue; end
    child=r; child(i)=child(i)-1;
    if child(1)==0, child=child(2:end); end
    n=n+qaBruteLastOrder(child,memo);
end
assert(n<=flintmax && n==fix(n));
memo(key)=n;
end
