use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib', 't/lib';
use Pastafari::NormativeScroll qw(countWeavings weavingPreopenStateCount);

# 獨立地直接枚舉每個已開啟前綴 p 及關閉前綴 c 的組合，
# 不使用受測的線性遞推式，也不呼叫 DP 計數器。
sub independent_product_sum ($lengths) {
    my $m = @$lengths;
    return Math::BigInt->bzero if !$m;
    my $answer = Math::BigInt->bone;
    for my $p (1 .. $m-1) {
        $answer->badd(1); # 前 p 個月份都已結束
        for my $c (0 .. $p-1) {
            my $product = Math::BigInt->bone;
            for my $j ($c .. $p-1) {
                $product->bmul(Math::BigInt->new($lengths->[$j])->bsub(1));
            }
            $answer->badd($product);
        }
    }
    return $answer;
}

my @tests;
for my $m (1 .. 4) {
    my $generate;
    $generate = sub ($prefix) {
        if (@$prefix == $m) {
            push @tests, [@$prefix];
            return;
        }
        for my $length (1 .. 4) {
            $generate->([@$prefix,$length]);
        }
    };
    $generate->([]);
}
for my $lengths (@tests) {
    my %stats;
    countWeavings($lengths,\%stats);
    my $formula = weavingPreopenStateCount($lengths);
    is("$formula",''.$stats{preopen_states},
        "DP 各階段狀態計數與解析式吻合：".join('-',@$lengths));
    is("$formula",''.independent_product_sum($lengths),
        "獨立直接乘積求和相符：".join('-',@$lengths));
}
for my $case (
    [[4,4,4], '18'],
    [[4,123,4], '494'],
    [[4,4,4,4,4,4], '543'],
    [[(4)x8], '4916'],
    [[(4)x10], '44281'],
    [[(4)x47], '19941610769218127465816'],
) {
    my ($lengths,$expected) = @$case;
    is(''.weavingPreopenStateCount($lengths),$expected,
        '固定向量的確切前期狀態數：'.scalar(@$lengths));
}
my $huge = weavingPreopenStateCount([(123)x47]);
cmp_ok(length("$huge"),'>=',90,'47 個 123 日月份的預測狀態數為超大精確整數');
is("$huge",''.independent_product_sum([(123)x47]),
    '47 個月的巨量解析結果經另一個公式獨立核對');
is(''.weavingPreopenStateCount([]),'0','空向量並無未全數開啟狀態');
for my $bad (undef, -1, 0, '3.5', [], {}) {
    my $value = eval { weavingPreopenStateCount([$bad,4]); 1 };
    ok(!$value,'不合法月份長度會被拒絕');
    like($@,qr/月份長度必須是正整數/,'不合法月份長度有確定診斷');
}
done_testing;
