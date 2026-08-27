function fixtures = stage01_fixtures()
% Wartości oczekiwane wyprowadzone od nowa bez użycia innej implementacji.
fixtures = struct();
fixtures.M = '170141183460469231731687303715884105727';
fixtures.foundationDay = '-15055671';
fixtures.saveZero = fixtures.M;
fixtures.saveM = fixtures.M;
fixtures.saveMPlusOne = '1';
fixtures.saveTwoM = fixtures.M;
fixtures.dayBeforeFoundation = '2';
fixtures.dayAtFoundation = '1';
fixtures.dayAfterFoundation = '3';
fixtures.equalDayDistance = '1';
fixtures.equalDayDirection = 2;
fixtures.firstPermutation = [1 2 3 4 5 6];
fixtures.lastPermutation = [6 5 4 3 2 1];
fixtures.stone2 = {'378', '1073', '2375', '6195', '10493'};
end
