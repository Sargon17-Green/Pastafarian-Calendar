use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib','t/lib';
use Pastafari::WeavingFrontierOracle qw(countWeavingsFrontier);
use Pastafari::NormativeScroll qw(countWeavings);
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);

# 逐層累計合法轉移，與深度優先規範模型和依位置
# 直方圖轉移的模型互不共用計數器、前綴狀態或任何快取。
my $tested=0;
for my $months (0..4) {
    my $walk;
    $walk=sub ($vec) {
        if (@$vec==$months) {
            my %stats;
            my $actual=countWeavingsFrontier($vec,\%stats);
            my $oracle=countWeavings($vec);
            my $poly=countWeavingsPolynomial($vec);
            my $label=join('-',@$vec);
            is("$actual","$oracle","$label: 波前全狀態算法與深度優先規範一致");
            is("$actual","$poly","$label: 波前全狀態算法與位置矩陣一致");
            ok($stats{frontier_peak}>=0,"$label: 受控前沿記錄有效");
            $tested++;
            return;
        }
        for my $length (1..3) {
            $walk->([@$vec,$length]);
        }
    };
    $walk->([]);
}
is($tested,121,'0..4 月份、每月 1..3 日的完整空間共 121 組');
my @source=(Math::BigInt->new(4),Math::BigInt->new(2),Math::BigInt->new(3),Math::BigInt->new(2));
my @copy=map {"$_"} @source;
my $expected=countWeavings(\@source);
my $actual=countWeavingsFrontier(\@source);
is("$actual","$expected",'一般非對稱 4 月份與規範算法完全一致');
$actual->badd(77);
is_deeply([map {"$_"} @source],\@copy,'回傳可變 BigInt 的變更不影響月份輸入');
is("".countWeavingsFrontier(\@source),"$expected",
   '重複呼叫不會沿用遭修改的回傳 BigInt');
for my $bad ([0], [256], [3,0], [1,1,1,1,1], [1.5]) {
    my $ok=eval {countWeavingsFrontier($bad);1};
    ok(!$ok,'前沿預言機明確拒絕範圍外或錯誤月份長度');
}
done_testing;
