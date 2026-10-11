use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib', 't/lib';
use Pastafari::NormativeScroll qw(
    M answerAt chooseRankShort chooseRankWide chooseRank
);

my $M = M();
my $m2 = $M->copy->bmul($M);
my $m3 = $m2->copy->bmul($M);
my $M_minus_1 = $M->copy->bsub(1);
my $N_reject = $m2->copy->bsub(2);

# 以獨立多精度整數運算建立小型直接模型，不呼叫受測選擇器。
sub independent_answer ($first, $direction, $offset, $modulus) {
    return Math::BigInt->new("$first")
        ->bsub(1)->badd(Math::BigInt->new($direction)->bmul($offset))
        ->bmod($modulus)->badd(1);
}

sub independent_short ($first, $direction, $N, $modulus) {
    my $limit = $modulus->copy->bdiv($N)->bmul($N);
    for my $offset (0 .. 5) {
        my $value = independent_answer($first, $direction, $offset, $modulus);
        if ($value <= $limit) {
            return $value->bsub(1)->bmod($N)->badd(1);
        }
    }
    die "短選擇直接模型超過測試步數\n";
}

sub independent_wide ($first, $direction, $N, $modulus) {
    my $digits = 1;
    my $space = $modulus->copy;
    while ($space < $N) {
        $space->bmul($modulus);
        $digits++;
    }
    my $value = Math::BigInt->bone;
    my $weight = Math::BigInt->bone;
    for my $offset (0 .. $digits - 1) {
        my $digit = independent_answer($first,$direction,$offset,$modulus);
        $value->badd($digit->bsub(1)->bmul($weight));
        $weight->bmul($modulus);
    }
    my $limit = $space->copy->bdiv($N)->bmul($N);
    for my $tries (0 .. 5) {
        last if $value <= $limit;
        $value = $value->bsub(1)->badd($direction)->bmod($space)->badd(1);
    }
    die "寬選擇直接模型超過測試步數\n" if $value > $limit;
    return $value->bsub(1)->bmod($N)->badd(1);
}

my @short_spaces = (
    Math::BigInt->bone,
    Math::BigInt->new(2),
    Math::BigInt->new(3),
    $M_minus_1,
    $M,
);
for my $start (Math::BigInt->bone, $M_minus_1, $M) {
    for my $direction (-1,1) {
        my $stream = { first => $start, directionStep => $direction };
        for my $N (@short_spaces) {
            my $expected = independent_short($start,$direction,$N,$M);
            my $actual = chooseRankShort($stream,$N);
            is(''.$actual, ''.$expected, '短選擇的獨立模型：一基排名、拒絕區與方向');
            is(''.chooseRank($stream,$N), ''.$expected, '統一入口在短空間使用同一數學答案');
        }
    }
}

my @wide_spaces = (
    $M->copy->badd(1),
    $N_reject,
    $m2->copy->bsub(1),
    $m2->copy,
    $m3->copy->badd(1),
);
for my $start (Math::BigInt->bone, $M_minus_1, $M) {
    for my $direction (-1,1) {
        my $stream = { first => $start, directionStep => $direction };
        for my $N (@wide_spaces) {
            my $expected = independent_wide($start,$direction,$N,$M);
            my $actual = chooseRankWide($stream,$N);
            is(''.$actual, ''.$expected, '寬選擇的獨立多精度模型（超過 256 位元）');
            is(''.chooseRank($stream,$N), ''.$expected, '統一入口在寬空間與數學模型一致');
            ok($actual >= 1 && $actual <= $N, '寬選擇永遠位於一至 N 的閉區間');
        }
    }
}
my $overflow_stream = { first => $M_minus_1, directionStep => 1 };
is(''.chooseRankWide($overflow_stream,$N_reject), '1',
    '寬選擇確實拒絕 M²-1、M²，並循環回到一');
is(''.chooseRankWide($overflow_stream,$m2->copy->bsub(1)),
    ''. $m2->copy->bsub(1), '相同合成數在相鄰合法界限內仍被接受');

my $huge_period = $M->copy->badd($m3);
for my $direction (-1,1) {
    my $stream = { first => $M_minus_1, directionStep => $direction };
    is(''.answerAt($stream,$huge_period), ''.answerAt($stream,$m3),
        '詢問序列的長週期與同餘性成立');
    is(''.answerAt($stream,0), ''.$M_minus_1, '第零詢問保留原始一基值');
}

my $before_n = '' . $m3;
my $before_first = '' . $M_minus_1;
my $rank = chooseRankWide({first => $M_minus_1, directionStep => 1},$m3);
is(''.$m3,$before_n,'寬選擇不修改傳入的總數大整數');
is(''.$M_minus_1,$before_first,'寬選擇不修改傳入的初值大整數');
ok($rank >= 1 && $rank <= $m3, '立方尺度輸入返回合法排名');

done_testing;
