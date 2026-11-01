use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib';
use Pastafari::Monster::MonthLengthGeneration qw(month_length_family);

# 獨立 oracle A：巢狀迴圈逐一列舉 252 日、三月份的全部合法有序組成。
my @oracle;
for my $a (4 .. 123) {
    for my $b (4 .. 123) {
        my $c = 252 - $a - $b;
        push @oracle, [$a, $b, $c] if $c >= 4 && $c <= 123;
    }
}
my $family = month_length_family(252, 3);
is(''.$family->{count}->(), ''.scalar(@oracle), '獨立枚舉總數');
for my $idx (0 .. $#oracle) {
    my $actual = $family->{unrank1}->($idx + 1);
    is_deeply($actual, $oracle[$idx], '逐一比對字典序排名 '.($idx + 1));
}

# 獨立 oracle B：容斥公式，將 4..123 平移為 0..119。
sub choose ($n, $k) {
    return Math::BigInt->bzero if $n < 0 || $k < 0 || $k > $n;
    my $r = Math::BigInt->bone;
    for my $i (1 .. $k) {
        $r->bmul($n - $k + $i);
        $r->bdiv($i);
    }
    return $r;
}
sub independent_count ($span, $months) {
    my $target = $span - 4 * $months;
    my $sum = Math::BigInt->bzero;
    for my $j (0 .. $months) {
        my $ways = choose($months, $j)->bmul(
            choose($target - 120 * $j + $months - 1, $months - 1));
        $j % 2 ? $sum->bsub($ways) : $sum->badd($ways);
    }
    return $sum;
}
my $checked = 0;
for my $fixture ([252,3], [963,8], [5778,47], [492,4], [252,47]) {
    my ($span,$months) = @$fixture;
    my $f = month_length_family($span, $months);
    my $expected = independent_count($span, $months);
    is(''.$f->{count}->(), "$expected", "容斥總數 $span/$months");
    for my $rank (Math::BigInt->bone, $expected->copy->bdiv(2)->badd(1), $expected->copy) {
        my $saved = "$rank";
        my $lengths = $f->{unrank1}->($rank);
        is(scalar(@$lengths), $months, '月份個數');
        is(0 + (join '', map { $_ < 4 || $_ > 123 ? 1 : 0 } @$lengths), 0, '每月日長合法');
        my $sum = 0; $sum += $_ for @$lengths;
        is($sum, $span, '全部月長加總為年長');
        is("$rank",$saved,'輸入 BigInt 不受修改');
        ++$checked;
    }
    ok(!eval { $f->{unrank1}->($expected->copy->badd(1)); 1 }, '拒絕超出最大排名');
    ok(!eval { $f->{unrank1}->(0); 1 }, '拒絕零排名');
    my $copied = $f->{count}->(); $copied->badd(123);
    is(''.$f->{count}->(), "$expected", '計數 BigInt 防止別名修改');
}
for my $invalid ([251,3], [5779,47], [252,2], [252,48], [5778,3],
                 ['0252',3], [252,'03'], [undef,3], [252,undef], [[],3], [252,{}], [-252,3]) {
    my ($s,$m) = @$invalid;
    ok(!eval { month_length_family($s,$m); 1 }, '拒絕無效年長／月數');
}
for my $bad (undef, [], {}, '01', '-1', '1.0', 'abc', Math::BigInt->bzero) {
    ok(!eval { $family->{unrank1}->($bad); 1 }, '拒絕無效排名');
}
my $s = Math::BigInt->new(252);
my $m = Math::BigInt->new(3);
my $big = month_length_family($s, $m);
is(''.$big->{count}->(), ''.scalar(@oracle), '接受 BigInt 作為年長／月數');
is("$s",'252','年長 BigInt 未改');
is("$m",'3','月數 BigInt 未改');
note('STAGE08_INDEPENDENT_ENUMERATED='.scalar(@oracle));
note("STAGE08_INDEPENDENT_BIGINT_CASES=$checked");
note('STAGE08_FULL_GENERATOR_NOT_VERIFIED');
done_testing;
