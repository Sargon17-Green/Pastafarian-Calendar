function tests = test_stage55_bigint_difference
% Native MATLAB regression for Stage55 BigInt subtraction method calls.
% Run from the repository root:
% matlab -batch "addpath('src'); r=runtests('tests/test_stage55_bigint_difference.m'); assert(~isempty(r) && all([r.Passed]));"
tests = functiontests(localfunctions);
end

function testBothBigIntDifferenceBranches(testCase)
repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(repoRoot, 'src'));

% Seven two-day months have 429 admissible lexical words. The count
% exceeds 256, so the two <=128-distance paths cannot overlap.
monthLengths = 2 * ones(1, 7);
family = pastafari.WholeMonthWeavingFamilyPolynomial(monthLengths);
total = family.count();
one = pastafari.BigInt(1);
testCase.verifyEqual(char(total), '429');

[firstWord, lastWord] = pastafari.extremalWholeMonthWeavings(monthLengths);
testCase.verifyEqual(family.itemAt1(one), firstWord);
testCase.verifyEqual(family.itemAt1(total), lastWord);

[nextWord, hasNext] = pastafari.adjacentWholeMonthWeaving( ...
    firstWord, monthLengths, 'next');
[previousWord, hasPrevious] = pastafari.adjacentWholeMonthWeaving( ...
    lastWord, monthLengths, 'previous');
testCase.verifyTrue(hasNext);
testCase.verifyTrue(hasPrevious);
testCase.verifyEqual(family.itemAt1(one + one), nextWord);
testCase.verifyEqual(family.itemAt1(total - one), previousWord);
end

function testNearEdgeDistance127(testCase)
repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(repoRoot, 'src'));

monthLengths = 2 * ones(1, 7);
family = pastafari.WholeMonthWeavingFamilyPolynomial(monthLengths);
total = family.count();
offset = pastafari.BigInt(127);
firstWindow = family.edgeWindowAt1(127, 'first');
lastWindow = family.edgeWindowAt1(127, 'last');

% Rank 128 executes distanceBig=rank-one; F-127 executes
% distanceBig=obj.exactCount-rank, then toDoubleExact() on the bound object.
testCase.verifyEqual(family.itemAt1(offset + pastafari.BigInt(1)), ...
    firstWindow(end, :));
testCase.verifyEqual(family.itemAt1(total - offset), ...
    lastWindow(end, :));
end
