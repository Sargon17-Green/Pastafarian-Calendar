use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib';
use Pastafari::Monster::YearOccurrence qw(year_occurrence);

# 獨立 Oracle：逐日展開區間，建立日期至年份編號的對照表。
# 不使用生產模組的二分搜尋或區間驗證程序。
my @lengths = (252, 963, 5778);
my @numbers = (-1, 0, 1);
my @years;
my %oracle;
my $open = -10000;
my $positions_checked = 0;
for my $i (0 .. $#lengths) {
    my $close = $open + $lengths[$i];
    push @years, {
        number => Math::BigInt->new($numbers[$i]),
        openGateDay => Math::BigInt->new($open),
        closeGateDay => Math::BigInt->new($close),
    };
    for my $day ($open + 1 .. $close) {
        $oracle{$day} = $numbers[$i];
        ++$positions_checked;
    }
    $open = $close;
}

is($positions_checked, 6993, '獨立展開位置數量固定');
for my $day (sort { $a <=> $b } keys %oracle) {
    my $actual = year_occurrence(\@years, $day);
    is("$actual", "$oracle{$day}", '年份編號符合逐日展開 Oracle');
}

# 年界採開開閉閉：共用閘日屬於前一年，下一日才屬於後一年。
is(''.year_occurrence(\@years, -9999), '-1', '首年開閘後第一日');
is(''.year_occurrence(\@years, -9748), '-1', '共用閘日仍屬前一年');
is(''.year_occurrence(\@years, -9747), '0', '共用閘日後第一日屬後一年');
is(''.year_occurrence(\@years, -8785), '0', '第二個共用閘日仍屬前一年');
is(''.year_occurrence(\@years, -8784), '1', '第二個共用閘日後第一日屬後一年');
is(''.year_occurrence(\@years, -3007), '1', '末年閉閘日包含在內');

ok(!eval { year_occurrence(\@years, -10000); 1 }, '首年開閘日不包含');
ok(!eval { year_occurrence(\@years, -3006); 1 }, '末年閉閘日之後不包含');

# 最多一百零一個連續年份；編號可跨越零並可為負數。
my @maximum;
my $cursor = -50000;
for my $i (0 .. 100) {
    my $close = $cursor + 252;
    push @maximum, {
        number => Math::BigInt->new($i - 50),
        openGateDay => Math::BigInt->new($cursor),
        closeGateDay => Math::BigInt->new($close),
    };
    $cursor = $close;
}
is(''.year_occurrence(\@maximum, -49999), '-50', '一百零一個區間的第一個');
is(''.year_occurrence(\@maximum, -37399), '0', '一百零一個區間的中間');
is(''.year_occurrence(\@maximum, -24749), '50', '一百零一個區間的最後一個');

for my $bad_years (undef, {}, [], 'abc') {
    ok(!eval { year_occurrence($bad_years, -9999); 1 }, '拒絕非陣列或空年份區間');
}
my @too_many = @maximum;
push @too_many, {
    number => 51,
    openGateDay => $cursor,
    closeGateDay => $cursor + 252,
};
ok(!eval { year_occurrence(\@too_many, $cursor + 1); 1 }, '拒絕超過一百零一個區間');

my @not_hash = ({ number => 1, openGateDay => 0, closeGateDay => 252 }, 'bad');
ok(!eval { year_occurrence(\@not_hash, 1); 1 }, '拒絕非雜湊區間記錄');
my @missing = ({ number => 1, openGateDay => 0 });
ok(!eval { year_occurrence(\@missing, 1); 1 }, '拒絕缺少閉閘日');
my @bad_number = ({ number => '1x', openGateDay => 0, closeGateDay => 252 });
ok(!eval { year_occurrence(\@bad_number, 1); 1 }, '拒絕非整數年份編號');
my @bad_day = ({ number => 1, openGateDay => '0.5', closeGateDay => 252 });
ok(!eval { year_occurrence(\@bad_day, 1); 1 }, '拒絕非整數閘日');
my @reverse = ({ number => 1, openGateDay => 252, closeGateDay => 0 });
ok(!eval { year_occurrence(\@reverse, 200); 1 }, '拒絕反向區間');
my @short = ({ number => 1, openGateDay => 0, closeGateDay => 251 });
ok(!eval { year_occurrence(\@short, 1); 1 }, '拒絕少於二百五十二日');
my @long = ({ number => 1, openGateDay => 0, closeGateDay => 5779 });
ok(!eval { year_occurrence(\@long, 1); 1 }, '拒絕超過五千七百七十八日');

my @gap = (
    { number => 1, openGateDay => 0, closeGateDay => 252 },
    { number => 2, openGateDay => 253, closeGateDay => 505 },
);
ok(!eval { year_occurrence(\@gap, 300); 1 }, '拒絕年份區間間隙');
my @overlap = (
    { number => 1, openGateDay => 0, closeGateDay => 252 },
    { number => 2, openGateDay => 251, closeGateDay => 503 },
);
ok(!eval { year_occurrence(\@overlap, 252); 1 }, '拒絕年份區間重疊');
my @number_gap = (
    { number => 1, openGateDay => 0, closeGateDay => 252 },
    { number => 3, openGateDay => 252, closeGateDay => 504 },
);
ok(!eval { year_occurrence(\@number_gap, 300); 1 }, '拒絕不連續年份編號');
my @bad_target = (undef, '1.5', 'x', [], Math::BigInt->new('9' x 80));
for my $bad (@bad_target) {
    ok(!eval { year_occurrence(\@years, $bad); 1 }, '拒絕非法目標日');
}

# BigInt 輸入與輸出不可共享可變狀態。
my $number = Math::BigInt->new(5000);
my $big_open = Math::BigInt->new(-1);
my $big_close = Math::BigInt->new(251);
my $big_target = Math::BigInt->new(0);
my @big_year = ({
    number => $number,
    openGateDay => $big_open,
    closeGateDay => $big_close,
});
my $big_result = year_occurrence(\@big_year, $big_target);
is("$big_result", '5000', 'BigInt 年份編號');
$big_result->badd(100);
is("$number", '5000', '不修改輸入年份 BigInt');
is("$big_open", '-1', '不修改輸入開閘日 BigInt');
is("$big_close", '251', '不修改輸入閉閘日 BigInt');
is("$big_target", '0', '不修改輸入目標日 BigInt');
is("$big_year[0]{number}", '5000', '輸入記錄不被修改');

note("STAGE06_INDEPENDENT_DAY_POSITIONS=$positions_checked");
note('STAGE06_FULL_CANONICAL_FIVE_FIELDS_NOT_VERIFIED');
done_testing;
