use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib', 't/lib';
use Pastafari::NormativeScroll qw(
    FOUNDATION_DAY resetGateCache ensureGateIndex exactGateIndex
    positiveGateGap negativeGateGap year5000 nextYear previousYear findTargetYear
);

my $origin = FOUNDATION_DAY();
resetGateCache();
my %gates;
for my $i (-4 .. 4) {
    $gates{$i} = ensureGateIndex($i);
}
is('' . $gates{0}, '' . $origin, '第零閘門等於奠基日');

for my $i (-4 .. 3) {
    my $delta = $gates{$i+1}->copy->bsub($gates{$i});
    ok($delta >= 42 && $delta <= 963, "閘門間距 $i 屬於閉區間 42..963");
    my $expected = $i < 0 ? negativeGateGap(-$i) : positiveGateGap($i+1);
    is('' . $delta, '' . $expected, "閘門間距 $i 與獨立方向公式相符");
    is(exactGateIndex($gates{$i}), $i, "閘門 $i 的反查精確");
    ok(!defined exactGateIndex($gates{$i}->copy->badd(1)),
       "閘門 $i 之後一日不是閘門");
}
is(exactGateIndex($gates{4}),4,'最高已核對閘門可精確反查');

my @original = map { '' . $gates{$_} } -4 .. 4;
resetGateCache();
my @recomputed = map { '' . ensureGateIndex($_) } -4 .. 4;
is_deeply(\@recomputed,\@original, '重置快取後正負閘門位置完全相同');

my $base = year5000($origin);
is('' . $base->{number}, '5000', '奠基日所用年份編號仍為五千');
ok($base->{openGateDay} < $origin && $origin <= $base->{closeGateDay},
    '五千年的區間採用左開右閉並涵蓋奠基日');
my $length = $base->{closeGateDay}->copy->bsub($base->{openGateDay});
ok($length >= 252 && $length <= 5778, '錨定年長度符合規範範圍');
ok($base->{closeGateIndex}-$base->{openGateIndex} >= 6,
    '錨定年包含至少六段閘門間距');

my $prev = previousYear($origin, $base);
my $next = nextYear($origin, $base);
is('' . $prev->{number}, '4999', '上一年編號為 4999');
is('' . $next->{number}, '5001', '下一年編號為 5001');
is('' . $prev->{closeGateDay}, '' . $base->{openGateDay},
    '前一年的右端點恰好等於五千年的左端點');
is('' . $next->{openGateDay}, '' . $base->{closeGateDay},
    '五千年的右端點恰好等於下一年的左端點');

for my $year ($prev, $base, $next) {
    my $span = $year->{closeGateDay}->copy->bsub($year->{openGateDay});
    ok($span >= 252 && $span <= 5778,
        "年份 $year->{number} 的長度落於閉區間 252..5778");
    ok($year->{closeGateIndex}-$year->{openGateIndex} >= 6,
        "年份 $year->{number} 跨越至少六段閘門間距");
}

my @cases = (
    ['五千年第一日', $base->{openGateDay}->copy->badd(1), 5000],
    ['五千年最後日', $base->{closeGateDay}->copy, 5000],
    ['上一年最後日', $base->{openGateDay}->copy, 4999],
    ['下一年第一日', $base->{closeGateDay}->copy->badd(1), 5001],
);
for my $case (@cases) {
    my ($label,$target,$year_num) = @$case;
    my $actual = findTargetYear($origin,$target);
    is('' . $actual->{number}, "$year_num", "$label 的年份歸屬正確");
    ok($actual->{openGateDay} < $target && $target <= $actual->{closeGateDay},
       "$label 被左開右閉邊界涵蓋");
}
done_testing;
