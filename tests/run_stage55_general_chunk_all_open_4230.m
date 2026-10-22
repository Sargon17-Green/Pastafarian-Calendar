function run_stage55_general_chunk_all_open_4230()
% FULL-SIZE already-opened suffix cross-implementation chunk test.
% The untested production 4244-day all-unopened problem remains open.
here=fileparts(mfilename('fullpath'));
root=fileparts(here);
addpath(fullfile(root,'src'));
cleanup=onCleanup(@() rmpath(fullfile(root,'src'))); %#ok<NASGU>

L=repmat(95,1,45);
R=repmat(94,1,45);
% Every month already opened once, none closed: a reachable frontier.
assert(numel(L)==45 && sum(R)==4230);
count=pastafari.countWholeWeavingSuffixByEndpoints(R,45,0);
ranks={pastafari.BigInt(1), ...
    count.floorDiv(pastafari.BigInt(2))+pastafari.BigInt(1),count};
for k=1:numel(ranks)
    rank=ranks{k};
    started=tic;
    [a,c]=pastafari.unrankGeneralWeaveSuffixChunk( ...
        L,R,45,0,rank,12);
    seconds=toc(started);
    [b,w]=pastafari.unrankAllOpenedWeaveSuffixChunk( ...
        R,0,rank,12,'common');
    assert(isequal(a,b) && isequal(c.remaining,w.remaining) && ...
        c.closedUpTo==w.closedUpTo && c.rank==w.rank && ...
        c.count==w.count && c.stepsComputed==12 && ...
        c.openedUpTo==45 && ~c.done, ...
        '4230-day all-open chunk mismatch with separate native method.');
    fprintf(['STAGE_55_GENERAL_CHUNK_4230_ALL_OPEN_PASS ', ...
        'RANK_CASE=%d STEPS=12 SECONDS=%.3f DIGITS=%d\n'], ...
        k,seconds,numel(char(c.count)));
end
fprintf('STAGE_55_GENERAL_CHUNK_4230_DIFFERENTIAL_PASS\n');
end
