use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib','t/lib';
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::WeavingPolynomialStream qw(countWeavingsPolynomialStream);
use Pastafari::WeavingSuffixFactor qw(countWeavingSuffixFactored);

my $comparisons=0;
for my $m (0 .. 5) {
    my $build;
    $build=sub ($lengths) {
        if (@$lengths==$m) {
            my (@h1,@h2,%stats);
            my $a=countWeavingsPolynomial($lengths,undef,\@h1);
            my $b=countWeavingsPolynomialStream($lengths,\%stats,\@h2);
            is("$b","$a",'硬碟逐列計數與記憶體模型相同：'.join('-',@$lengths));
            is(scalar(@h2),scalar(@h1),'邊際直方圖階段數相同');
            for my $j (1 .. $#$lengths+1) {
                my $left=$h1[$j];
                my $right=$h2[$j];
                my $U=0;$U+=$_ for @$lengths[0 .. $j-1];
                for my $u (1 .. $U) {
                    is(''.($right->[$u]//0),''.($left->[$u]//0),
                        '每階段首日精確 BigInt 邊際相同');
                }
            }
            my $sum=0;$sum+=$_ for @$lengths;
            is($stats{total_days},$sum,'傳回統計日數正確');
            $comparisons++;
            return;
        }
        $build->([@$lengths,$_]) for 1 .. 3;
    };
    $build->([]);
}
cmp_ok($comparisons,'>=',300,'核對至少三百組小型月份向量');

# 用 47 月份實際檢查較大 BigInt，亦核對反序計數。
for my $lengths ([(4)x47],[(6)x17,(5)x30]) {
    my %stats;
    my $stream=countWeavingsPolynomialStream($lengths,\%stats);
    my $reference=countWeavingsPolynomial($lengths);
    is("$stream","$reference",'47 月份的完整精確計數保持不變');
    is($stats{stages},46,'47 月份共需 46 次新增月份');
    cmp_ok($stats{max_temp_file_bytes},'>',0,
        '確實使用逐列二進位暫存檔');
    cmp_ok($stats{rows_serialized},'>',46,
        '逐列序列化記錄已啟用');
}

# 任何超出磁碟預算的案例必須失敗，而不是截斷 BigInt 造成假 PASS。
my $ok=eval {
    countWeavingsPolynomialStream([4,4,4],undef,undef,
                                  {max_temp_file_bytes=>50});
    1
};
ok(!$ok,'低暫存檔預算會產生可識別失敗');
like($@,qr/暫存檔超過容量限制/,'超限錯誤訊息包含資源原因');

for my $bad (
    {max_temp_file_bytes=>0},
    {max_temp_file_bytes=>'12KB'},
    {max_temp_file_bytes=>1_073_741_825},
    {unknown=>2}
) {
    my $ok=eval {countWeavingsPolynomialStream([2,2],undef,undef,$bad);1};
    ok(!$ok,'拒絕無效的暫存檔設定');
}

my @original=(Math::BigInt->new(2),Math::BigInt->new(3),
              Math::BigInt->new(2));
my @before=map {"$_"} @original;
my $r=countWeavingsPolynomialStream(\@original);
is("$r",''.countWeavingsPolynomial([2,3,2]),
    '支援 BigInt 月份長度作為輸入');
is_deeply([map {"$_"} @original],\@before,'不改動輸入 BigInt');
done_testing;
