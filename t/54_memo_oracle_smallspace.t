use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib','t/lib';
use Pastafari::WeavingMemoOracle;
use Pastafari::WeavingFrontierOracle qw(countWeavingsFrontier);
use Pastafari::NormativeScroll qw(countWeavings);
use Pastafari::WeavingSuffix qw(countWeavingSuffixPolynomial);

my $vectors=0;
for my $m (0..4) {
    my $walk;
    $walk=sub ($v) {
        if (@$v==$m) {
            my $memo=Pastafari::WeavingMemoOracle->new($v);
            my $ref=countWeavings($v);
            is(''.$memo->count_prefix([]),"$ref",
                '獨立記憶式全局計數與規範深度優先結果一致：'.join(',',@$v));
            my $prefix=[];
            my @remaining=@$v;
            my ($opened,$closed)=(0,0);
            for my $step (1..(do {my $days=0;$days+=$_ for @$v;$days})) {
                my $next;
                for my $j (1..($opened<$m ? $opened+1 : $m)) {
                    next if !$remaining[$j-1];
                    next if $remaining[$j-1]==1 && $j!=$closed+1;
                    $next=$j;
                    last;
                }
                die "不能生成合法字典序首名\n" if !defined $next;
                push @$prefix,$next;
                $opened=$next if $next>$opened;
                --$remaining[$next-1];
                $closed=$next if !$remaining[$next-1];
                my $answer=$memo->count_prefix($prefix);
                is("$answer","".countWeavingsFrontier($v,undef,$prefix),
                   '指定首名路徑的記憶式與前沿計數一致：'.join(',',@$v));
            }
            my %bad;
            $bad{0}=1;
            my $copy=$memo->count_prefix([]);
            $copy->badd(27);
            is(''.$memo->count_prefix([]),"$ref",
               '更改回傳 BigInt 不會污染記憶式內部快取');
            ok($memo->diagnostics->{cache_hits}>0,
               '重複 prefix 查詢確實重用獨立狀態快取');
            $vectors++;
            return;
        }
        for my $x (1..3) {$walk->([@$v,$x]);}
    };
    $walk->([]);
}
is($vectors,121,'0..4 個月份、長 1..3 日全部 121 組均已核對');

my @lengths=(Math::BigInt->new(4),Math::BigInt->new(3),
             Math::BigInt->new(2),Math::BigInt->new(2));
my $counter=Pastafari::WeavingMemoOracle->new(\@lengths);
my @snapshot=map {"$_"} @lengths;
my @selected=(1,2);
is(''.$counter->count_prefix(\@selected),
   ''.countWeavingSuffixPolynomial(\@lengths,\@selected),
   '非首名且尚未全開前綴吻合獨立多項式後綴計數');
is_deeply(\@selected,[1,2],'不會改動前綴');
is_deeply([map {"$_"} @lengths],\@snapshot,'不會改動原始 BigInt 月長');
for my $bad ([2],[1,2,3,4,4],[1,1,1,1,1],[0],[-1],[1.5],[1,2,5]) {
    my $ok=eval {$counter->count_prefix($bad);1};
    ok(!$ok,'非法前綴必須拒絕');
}
for my $bad ({},42) {
    my $ok=eval {$counter->count_prefix($bad);1};
    ok(!$ok,'非 ARRAY 前綴必須拒絕');
}
is(''.$counter->count_prefix([1,2]),
   ''.countWeavingSuffixPolynomial(\@lengths,[1,2]),
   '非法輸入不能污染已快取的合法前綴');
done_testing;
