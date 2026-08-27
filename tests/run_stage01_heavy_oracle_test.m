function run_stage01_heavy_oracle_test()
% Opcjonalny test pełnej ścieżki kalendarza; może być kosztowny czasowo i pamięciowo.
here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
addpath(fullfile(here, 'oracle'));
cleanup = onCleanup(@() cleanupPaths(root, here)); %#ok<NASGU>
normative_oracle('resetGates');
foundation = pastafari.BigInt('-15055671');
result = normative_oracle('calendar', foundation, foundation);
assert(iscell(result) && numel(result) == 5, 'Pełne źródło odniesienia nie zwróciło dokładnie pięciu pól.');
assert(isa(result{1}, 'pastafari.BigInt') && isa(result{3}, 'pastafari.BigInt') && isa(result{5}, 'pastafari.BigInt'), ...
    'Pola liczbowe pełnego wyniku nie są dokładnymi liczbami całkowitymi.');
assert(ischar(result{2}) && ischar(result{4}), 'Nazwy w pełnym wyniku nie pochodzą z polskiego katalogu źródłowego.');
fprintf('STAGE_01_HEAVY_ORACLE_TEST_PASS\n');
end

function cleanupPaths(root, here)
rmpath(fullfile(root, 'src'));
rmpath(fullfile(here, 'oracle'));
end
