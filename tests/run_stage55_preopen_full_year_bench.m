function run_stage55_preopen_full_year_bench()
% Real-scale complete count. Not the normative exact 5000-year month
% vector and not a replacement for independent production-oracle PASS.
% The 4244-day workload is *fully unopened*: every first and last month
% occurrence constraint remains active. No limits or sampling of words.
here=fileparts(mfilename('fullpath'));
root=fileparts(here);
addpath(fullfile(root,'src'));
cleanupPath=onCleanup(@() rmpath(fullfile(root,'src'))); %#ok<NASGU>
prior=getenv('PASTAFARI_PREOPEN_WAVEFRONT_TRACE');
setenv('PASTAFARI_PREOPEN_WAVEFRONT_TRACE','1');
cleanupEnv=onCleanup(@() setenv('PASTAFARI_PREOPEN_WAVEFRONT_TRACE',prior)); %#ok<NASGU>

lengths=[108 repmat(94,1,44)];
assert(sum(lengths)==4244 && numel(lengths)==45, ...
    'Benchmark must use exactly 4244 days and 45 unopened months.');
fprintf('STAGE_55_PREOPEN_4244_BEGIN MONTHS=%d DAYS=%d\n', ...
    numel(lengths),sum(lengths));
elapsed=tic;
count=pastafari.countWholeWeavingAllUnopenedWavefront(lengths);
seconds=toc(elapsed);
digits=char(count);
assert(count>pastafari.BigInt(0) && numel(digits)>=1000, ...
    'Exact 4244-day count must be positive and have many digits.');
fprintf(['STAGE_55_PREOPEN_4244_FULL_COUNT_PASS MONTHS=45 DAYS=4244 ', ...
    'SECONDS=%.3f DIGITS=%d FIRST48=%s LAST48=%s\n'], ...
    seconds,numel(digits),digits(1:48),digits(end-47:end));
fprintf('STAGE_55_PREOPEN_4244_EXPERIMENTAL_PASS\n');
end
