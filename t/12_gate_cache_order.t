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
);

sub collect_gate_days () {
    my %days;
    for my $i (-8 .. 8) {
        $days{$i} = '' . ensureGateIndex($i);
    }
    return \%days;
}

resetGateCache();
ensureGateIndex(-8);
ensureGateIndex(8);
my $reference = collect_gate_days();
is($reference->{0}, '' . FOUNDATION_DAY(), '閘門零始終位於奠基日');

for my $index (-8 .. 7) {
    my $step = Math::BigInt->new($reference->{$index+1})
        ->bsub($reference->{$index});
    ok($step >= 42 && $step <= 963, "連續閘門 $index 的間距符合規範");
}
my $borrowed = ensureGateIndex(5);
$borrowed->badd('999999999999999999999999999999999999999');
is('' . ensureGateIndex(5), $reference->{5}, '修改閘門函式的回傳值不改變內部快取');
my $reversed = ensureGateIndex(-5);
$reversed->bsub('999999999999999999999999999999999999999');
is('' . ensureGateIndex(-5), $reference->{-5}, '反向閘門的回傳值亦為獨立物件');

resetGateCache();
for my $idx (8, -8, 6, -3, -7, 3, 0) {
    ensureGateIndex($idx);
}
my $mixed = collect_gate_days();
is_deeply($mixed, $reference, '交錯建構正負閘門與單向建構得到相同結果');

for my $index (-7 .. 7) {
    my $low = Math::BigInt->new($reference->{$index});
    my $high = Math::BigInt->new($reference->{$index+1});
    is(exactGateIndex($low), $index, "閘門 $index 的精確反查不受建立次序影響");
    is(exactGateIndex($low->copy->badd(1)), undef,
        "閘門 $index 後一日不是閘門");
    is(exactGateIndex($high->copy->bsub(1)), undef,
        "閘門 $index 下一閘門之前一日不是閘門");
}
is(exactGateIndex(Math::BigInt->new($reference->{8})),8,
    '正向最後一個已知閘門仍可精確反查');

resetGateCache();
ensureGateIndex(8);
ensureGateIndex(-8);
is_deeply(collect_gate_days(), $reference,
    '重置後採用相反擴張次序也能重建完全相同的閘門座標');
done_testing;
