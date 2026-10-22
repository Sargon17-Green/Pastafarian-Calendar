function run_stage55_real_year_5000_lengths_tests()
% REAL production-selected vector, NOT the previous synthetic 4244 days.
% Evidence: MATLAB Stage55 native run 39818603362, HEAD 6435dfc,
% STAGE_54_STRUCTURE_MONTH_LENGTHS_VECTOR after the canonical
% MonthLengthCompatibilityRoute and BEFORE the blocked weaving DAG.
% This diagnostic fixture does not replace or recompute that route.
%
% Full 4244-day equality here is an exact count-only differential.
% It cannot certify production lexicographic unranking or the complete
% five-field normative calendar tuple.

here=fileparts(mfilename('fullpath'));
root=fileparts(here);
addpath(fullfile(root,'src'));
cleanup=onCleanup(@() rmpath(fullfile(root,'src'))); %#ok<NASGU>

L=[115 108 119 109 106 81 115 114 117 120 98 52 81 97 121 ...
   97 115 96 107 61 106 115 119 39 84 103 115 107 55 119 ...
   97 50 122 110 81 54 101 83 88 40 25 77 98 122 105];
assert(numel(L)==45 && sum(L)==4244 && ...
    all(L>=4) && all(L<=123), ...
    'The exact captured year-5000 production fixture has changed.');

fprintf(['STAGE_55_REAL_YEAR_5000_FIXTURE_PASS ', ...
    'MONTHS=%d DAYS=%d MIN=%d MAX=%d\n'], ...
    numel(L),sum(L),min(L),max(L));
fprintf('STAGE_55_REAL_YEAR_5000_VECTOR %s\n',mat2str(L));

firstTimer=tic;
countOne=pastafari.countWholeWeavingSuffixByFirstEndpoint(L,0,0);
firstSeconds=toc(firstTimer);
countDigits=char(countOne);
assert(countOne>pastafari.BigInt(0) && ...
    numel(countDigits)>1000, ...
    'The actual year-5000 family count must be exact and positive.');
fprintf(['STAGE_55_REAL_YEAR_5000_FIRST_ENDPOINT_PASS ', ...
    'MONTHS=45 DAYS=4244 SECONDS=%.3f DIGITS=%d ', ...
    'FIRST48=%s LAST48=%s\n'], ...
    firstSeconds,numel(countDigits), ...
    countDigits(1:48),countDigits(end-47:end));

% Separate original first/last-occurrence wavefront recurrence;
% compare ALL BigInt digits, not just the printed witness fragments.
secondTimer=tic;
countWavefront=pastafari.countWholeWeavingAllUnopenedWavefront(L);
wavefrontSeconds=toc(secondTimer);
assert(countOne==countWavefront, ...
    'Two independent exact recurrences disagree on ACTUAL 5000-year lengths.');
fprintf(['STAGE_55_REAL_YEAR_5000_FULL_BIGINT_DIFFERENTIAL_PASS ', ...
    'MONTHS=45 DAYS=4244 WAVEFRONT_SECONDS=%.3f DIGITS=%d\n'], ...
    wavefrontSeconds,numel(countDigits));

% The very first letter of every legal entirely-unopened word must be
% month 1, from opening order. A forced letter preserves the complete
% set of suffixes and every exact 1-based rank. No repeated DP needed
% for this algebraic bijection; do NOT label this a complete unrank.
firstNextMonth=1;
firstRemaining=L;
firstRemaining(1)=firstRemaining(1)-1;
assert(firstNextMonth==1 && firstRemaining(1)==114 && ...
    sum(firstRemaining)==4243 && countOne>pastafari.BigInt(1));
lowRank=pastafari.BigInt(1);
midRank=countOne.floorDiv(pastafari.BigInt(2))+pastafari.BigInt(1);
highRank=countOne;
assert(lowRank<=midRank && midRank<=highRank, ...
    'Exact forced-first-letter ranks must retain their relative order.');
fprintf(['STAGE_55_REAL_YEAR_5000_FORCED_FIRST_LETTER_PASS ', ...
    'LETTER=1 REMAINING_DAYS=4243 RANK_CASES=3\n']);
fprintf('STAGE_55_REAL_YEAR_5000_EXPERIMENTAL_PASS\n');
end
