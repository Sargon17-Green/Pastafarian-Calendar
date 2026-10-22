function run_stage55_first_endpoint_tests()
% Exhaustive all-reachable suffix state differential vs independent
% legal-next-step oracle AND existing two-dimensional exact endpoint DP.
here=fileparts(mfilename('fullpath'));
root=fileparts(here);
addpath(fullfile(root,'src'));
cleanup=onCleanup(@() rmpath(fullfile(root,'src'))); %#ok<NASGU>

families=0;
states=0;
for K=1:5
    for encoding=0:3^K-1
        lengths=zeros(1,K);
        code=encoding;
        for j=1:K
            lengths(j)=mod(code,3)+1;
            code=floor(code/3);
        end
        work={{lengths,0,0}};
        seen=containers.Map('KeyType','char','ValueType','logical');
        counts=containers.Map('KeyType','char','ValueType','double');
        while ~isempty(work)
            entry=work{end};
            work(end)=[];
            r=entry{1}; opened=entry{2}; closed=entry{3};
            key=sprintf('%d,',[r,opened,closed]);
            if isKey(seen,key)
                continue
            end
            seen(key)=true;
            got=pastafari.countWholeWeavingSuffixByFirstEndpoint( ...
                r,opened,closed);
            previous=pastafari.countWholeWeavingSuffixByEndpoints( ...
                r,opened,closed);
            brute=independentLegalCount(r,lengths,opened,closed,counts);
            assert(got==previous && got==pastafari.BigInt(brute), ...
                'First-endpoint exact count disagrees with independent oracle.');
            states=states+1;
            for month=1:K
                n=r(month);
                if n==0 || (n==lengths(month) && month~=opened+1) || ...
                        (n==1 && month~=closed+1)
                    continue
                end
                next=r;
                next(month)=n-1;
                work{end+1}={next,opened+double(n==lengths(month)), ...
                    closed+double(n==1)}; %#ok<AGROW>
            end
        end
        families=families+1;
    end
end
assert(families==363 && states>=6651, ...
    'The exhaustive reachable-state matrix was incomplete.');
fprintf(['STAGE_55_FIRST_ENDPOINT_EXHAUSTIVE_PASS ', ...
    'FAMILIES=%d STATES=%d\n'],families,states);

% Three increasing FULLY unopened input families; count every valid word.
% A separate full-size test covers 45 months / 4244 days.
vectors={repmat(10,1,8),repmat(20,1,12),repmat(20,1,16)};
for k=1:numel(vectors)
    L=vectors{k};
    ticStart=tic;
    actual=pastafari.countWholeWeavingSuffixByFirstEndpoint(L,0,0);
    seconds=toc(ticStart);
    reference=pastafari.countWholeWeavingSuffixByEndpoints(L,0,0);
    assert(actual==reference,'Large exact full-unopened count mismatch.');
    fprintf(['STAGE_55_FIRST_ENDPOINT_BENCH MONTHS=%d DAYS=%d ', ...
        'SECONDS=%.3f DIGITS=%d\n'], ...
        numel(L),sum(L),seconds,numel(char(actual)));
end

% Real-sized synthetically specified 45-month workload. The actual
% calendar 5000-year month vector is not yet known in this benchmark.
L=[108 repmat(94,1,44)];
assert(sum(L)==4244 && numel(L)==45);
previous=getenv('PASTAFARI_FIRST_ENDPOINT_TRACE');
setenv('PASTAFARI_FIRST_ENDPOINT_TRACE','1');
cleanupTrace=onCleanup(@() setenv('PASTAFARI_FIRST_ENDPOINT_TRACE',previous)); %#ok<NASGU>
started=tic;
actual=pastafari.countWholeWeavingSuffixByFirstEndpoint(L,0,0);
seconds=toc(started);
digits=char(actual);
assert(actual>pastafari.BigInt(0) && numel(digits)>1000, ...
    'Full-sized all-unopened count invalid.');
fprintf(['STAGE_55_FIRST_ENDPOINT_4244_EXACT_PASS ', ...
    'MONTHS=45 DAYS=4244 SECONDS=%.3f DIGITS=%d ', ...
    'FIRST48=%s LAST48=%s\n'], ...
    seconds,numel(digits),digits(1:48),digits(end-47:end));

% Full-size exact differential against the independently structured
% (first,last)-prefix wavefront algorithm, not merely matching a
% few printed decimal digits. No probability or sampling.
differentialStart=tic;
wavefront=pastafari.countWholeWeavingAllUnopenedWavefront(L);
compareSeconds=toc(differentialStart);
assert(actual==wavefront, ...
    'Complete 4244-day BigInt mismatch between independent counters.');
fprintf(['STAGE_55_FIRST_ENDPOINT_4244_WAVEFRONT_DIFFERENTIAL_PASS ', ...
    'MONTHS=45 DAYS=4244 WAVEFRONT_SECONDS=%.3f DIGITS=%d\n'], ...
    compareSeconds,numel(digits));
fprintf('STAGE_55_FIRST_ENDPOINT_EXPERIMENTAL_PASS\n');
end

function count=independentLegalCount(r,lengths,opened,closed,memo)
if all(r==0)
    assert(opened==numel(lengths) && closed==numel(lengths));
    count=1;
    return
end
key=sprintf('%d,',[r opened closed]);
if isKey(memo,key)
    count=memo(key);
    return
end
count=0;
for i=1:numel(r)
    n=r(i);
    if n==0 || (n==lengths(i) && i~=opened+1) || ...
            (n==1 && i~=closed+1)
        continue
    end
    child=r;
    child(i)=n-1;
    count=count+independentLegalCount(child,lengths, ...
        opened+double(n==lengths(i)), ...
        closed+double(n==1),memo);
end
assert(count<=flintmax, ...
    'Independent brute test must remain exactly representable.');
memo(key)=count;
end
