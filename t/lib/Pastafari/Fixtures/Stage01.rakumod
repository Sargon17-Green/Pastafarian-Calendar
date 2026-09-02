unit module Pastafari::Fixtures::Stage01;

use Pastafari::Normative::Oracle;

our @DAY_COUNT_CASES is export = (
    [FOUNDATION_DAY,     1],
    [FOUNDATION_DAY + 1, 3],
    [FOUNDATION_DAY - 1, 2],
    [FOUNDATION_DAY + 2, 5],
    [FOUNDATION_DAY - 2, 4],
);

our @WORK_COUNT_CASES is export = (
    [FOUNDATION_DAY, FOUNDATION_DAY,     [1,1,1,2,2]],
    [FOUNDATION_DAY, FOUNDATION_DAY + 1, [1,3,2,4,3]],
    [FOUNDATION_DAY + 1, FOUNDATION_DAY, [3,1,2,4,1]],
);

our @STONE_ROW_2 is export = [Nil,378,1073,2375,6195,10493];
our @INITIAL_BOWL_PREFIX_FOUNDATION is export = [Nil,87617,136163];
