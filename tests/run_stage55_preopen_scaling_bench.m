function run_stage55_preopen_scaling_bench()
% Measure the original hard frontier: NO months have been opened.
% Unlike the already-opened factorization, every first/last occurrence
% constraint is active. These are complete exact counts, not partial
% state-space truncations and not substitutes for the 4244-day gate.
here=fileparts(mfilename('fullpath'));
root=fileparts(here);
addpath(fullfile(root,'src'));
cleanup=onCleanup(@() rmpath(fullfile(root,'src'))); %#ok<NASGU>

sizes=[8 12 16];
previous=[];
for k=1:numel(sizes)
    months=sizes(k);
    lengths=repmat(20,1,months);
    days=sum(lengths);
    fprintf('STAGE_55_PREOPEN_BENCH_BEGIN MONTHS=%d DAYS=%d\n', ...
        months,days);
    mark=tic;
    actual=pastafari.countWholeWeavingSuffixByEndpoints( ...
        lengths,0,0);
    elapsed=toc(mark);
    assert(actual>=pastafari.BigInt(1), ...
        'Fully unopened exact family must be nonempty.');
    % Verify that the exact count admits positive rank 1, without
    % invoking the exponential production full-year DAG.
    assert(actual==pastafari.countWholeWeavingSuffixByEndpoints( ...
        lengths,0,0),'Deterministic exact initial count changed.');
    if ~isempty(previous)
        assert(actual>previous, ...
            'Adding a positive new month should increase count.');
    end
    previous=actual;
    fprintf('STAGE_55_PREOPEN_BENCH_PASS MONTHS=%d DAYS=%d SECONDS=%.3f DIGITS=%d\n', ...
        months,days,elapsed,numel(char(actual)));
end
fprintf('STAGE_55_PREOPEN_SCALING_PASS SIZES=3\n');
end
