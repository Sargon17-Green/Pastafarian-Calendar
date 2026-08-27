function run_stage01_tests()
% Główny zestaw szybkich testów rozruchu etapu 1.

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
addpath(fullfile(here, 'oracle'));
cleanup = onCleanup(@() cleanupPaths(root, here)); %#ok<NASGU>

f = stage01_fixtures();

M = pastafari.BigInt(f.M);
assert(strcmp(char(M), f.M), 'Nie udało się odtworzyć stałej M.');
assert(strcmp(char(pastafari.BigInt(2).powNonnegative(127) - pastafari.BigInt(1)), f.M), ...
    'Stała M nie jest równa 2^127-1.');

[a, r] = pastafari.BigInt(-7).floorDivMod(pastafari.BigInt(3));
assert(a == pastafari.BigInt(-3) && r == pastafari.BigInt(2), ...
    'Dzielenie podłogowe liczb ujemnych jest niepoprawne.');
assert((pastafari.BigInt('999999999999999999') * pastafari.BigInt('888888888888888888')) == ...
    pastafari.BigInt('888888888888888887111111111111111112'), ...
    'Mnożenie dowolnej precyzji jest niepoprawne.');

assert(strcmp(char(normative_oracle('SAVE', 0)), f.saveZero), 'SAVE(0) jest niepoprawne.');
assert(strcmp(char(normative_oracle('SAVE', M)), f.saveM), 'SAVE(M) jest niepoprawne.');
assert(strcmp(char(normative_oracle('SAVE', M + 1)), f.saveMPlusOne), 'SAVE(M+1) jest niepoprawne.');
assert(strcmp(char(normative_oracle('SAVE', M * 2)), f.saveTwoM), 'SAVE(2M) jest niepoprawne.');

foundation = pastafari.BigInt(f.foundationDay);
assert(strcmp(char(normative_oracle('dayCount', foundation - 1)), f.dayBeforeFoundation), ...
    'Mianowanie dnia przed Dniem Założenia jest niepoprawne.');
assert(strcmp(char(normative_oracle('dayCount', foundation)), f.dayAtFoundation), ...
    'Mianowanie Dnia Założenia jest niepoprawne.');
assert(strcmp(char(normative_oracle('dayCount', foundation + 1)), f.dayAfterFoundation), ...
    'Mianowanie dnia po Dniu Założenia jest niepoprawne.');
counts = normative_oracle('workCounts', foundation, foundation);
assert(strcmp(char(counts.distance), f.equalDayDistance) && counts.direction == f.equalDayDirection, ...
    'Mianowanie pracy dla dwóch równych dni jest niepoprawne.');

stones = normative_oracle('stones');
for k = 1:5
    assert(strcmp(char(stones{2, k}), f.stone2{k}), 'Drugi wiersz kamieni jest niepoprawny.');
end
assert(isequal(normative_oracle('permutation', 1), f.firstPermutation), ...
    'Pierwsza permutacja mis jest niepoprawna.');
assert(isequal(normative_oracle('permutation', 720), f.lastPermutation), ...
    'Ostatnia permutacja mis jest niepoprawna.');

catalog = pastafari.sourceLanguageCatalog();
assert(numel(catalog.cutlets) == 17, 'Katalog musi zawierać 17 nazw kotletów.');
assert(numel(catalog.months) == 47, 'Katalog musi zawierać 47 nazw miesięcy.');
assert(isequal([catalog.cutlets.canonicalIndex], 1:17), 'Indeksy kotletów muszą być ciągłe i kanoniczne.');
assert(isequal([catalog.months.canonicalIndex], 1:47), 'Indeksy miesięcy muszą być ciągłe i kanoniczne.');
assert(strcmp(catalog.cutlets(12).text, 'pszenica'), 'Znaczenie nazwy „pszenica” zostało odwzorowane błędnie.');
assert(strcmp(catalog.months(6).text, 'pasta do zębów'), 'Znaczenie nazwy „pasta do zębów” zostało odwzorowane błędnie.');
assert(strcmp(catalog.months(41).text, 'Babilon'), 'Nazwa własna „Babilon” została odwzorowana błędnie.');
modified = catalog;
modified.cutlets(1).text = 'zmienione';
fresh = pastafari.sourceLanguageCatalog();
assert(strcmp(fresh.cutlets(1).text, 'brąz'), 'Zewnętrzna modyfikacja naruszyła zamrożony katalog.');

s1 = normative_oracle('sauce', foundation, foundation);
s2 = normative_oracle('sauce', foundation, foundation);
assert(numel(s1.bowls) == 6 && numel(s1.orderAtDrop46) == 6, 'Sos testowy ma niepełną strukturę.');
for k = 1:6
    assert(s1.bowls{k} == s2.bowls{k}, 'Powtórzenie sosu dało inny wynik.');
end
assert(isequal(s1.orderAtDrop46, s2.orderAtDrop46), 'Porządek kropli 46 nie jest deterministyczny.');

caught = false;
try
    calendarDateSpaghetti(foundation, foundation);
catch err
    caught = strcmp(err.identifier, 'Pastafari:Bootstrap:NotImplementedYet');
end
assert(caught, 'Neutralny szkielet produkcyjny nie zatrzymał się na granicy etapu 1.');

fprintf('STAGE_01_TESTS_PASS\n');
end

function cleanupPaths(root, here)
rmpath(fullfile(root, 'src'));
rmpath(fullfile(here, 'oracle'));
end
