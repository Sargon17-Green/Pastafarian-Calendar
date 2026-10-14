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
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::WeavingUnrank qw(unrankWeavingPolynomial);
use Pastafari::WeavingRank qw(rankWeavingPolynomial);

# 兩月份規範約束：「1」必在最初，「2」必在最後。
# 移除這兩個端點後，其餘 (a-1) 個 1 與 (b-1) 個 2
# 任意相間且保持各個符號同一性，精確總數是 C(a+b-2,a-1)。
# 此推導不使用任何被測編織演算法、位置直方圖或快取。
sub direct_two_month_count ($a,$b) {
    my ($n,$k)=($a+$b-2,$a-1);
    $k=$n-$k if $k>$n-$k;
    my $sum=Math::BigInt->bone;
    for my $i (1..$k) {
        $sum->bmul($n-$k+$i)->bdiv($i);
    }
    return $sum;
}

my $first_total;
for my $v ([255,100],[100,255]) {
    my @lengths=map {Math::BigInt->new($_)} @$v;
    my @unchanged=map {"$_"} @lengths;
    my $case=join(',',@$v);
    my $expected=direct_two_month_count(@$v);
    ok(length("$expected")>78,"$case: 真正使用超過 256-bit 的精確整數");

    my $memo=Pastafari::WeavingMemoOracle->new(\@lengths);
    my $got=$memo->count_prefix([]);
    is("$got","$expected","$case: 獨立記憶式後綴計數等於二項係數");
    is(''.countWeavingsFrontier(\@lengths),"$expected",
       "$case: 正向獨立前沿等於二項係數");
    is(''.countWeavingsPolynomial(\@lengths),"$expected",
       "$case: 位置多項式等於二項係數");

    is(''.$memo->count_prefix([1]),"$expected",
       "$case: 所有合法詞均以月份 1 起始");
    my $first=$memo->count_prefix([1,1]);
    my $second=$memo->count_prefix([1,2]);
    my $partition=$first->copy->badd($second);
    is("$partition","$expected",
       "$case: 第二日所有兩個分支的精確 BigInt 和");

    my $middle=$expected->copy->bdiv(2)->badd(1);
    my $original="$middle";
    my %unrank_stats;
    my $word=unrankWeavingPolynomial(
        \@lengths,$middle,\%unrank_stats,
        {profile_engine=>'stream-indexed',
         max_temp_file_bytes=>16*1024*1024}
    );
    is(scalar(@$word),355,"$case: 中間 BigInt 排名有完整 355 日");
    is($word->[0],1,"$case: 第一日必為月份 1");
    is($word->[-1],2,"$case: 最後一日必為月份 2");
    ok(($unrank_stats{indexed_profile_builds}//0)>=1,
       "$case: 非邊界精確 BigInt 排名確實使用磁碟索引");
    my @occur=(0,0);
    $occur[$_-1]++ for @$word;
    is_deeply(\@occur,$v,"$case: 解碼詞完整消耗原始月份長度");
    my $back=rankWeavingPolynomial(
        \@lengths,$word,undef,
        {profile_engine=>'stream-indexed',
         max_temp_file_bytes=>16*1024*1024}
    );
    is("$back",$original,
       "$case: 索引正向排名精確恢復超過 256-bit 的中間排名");
    is("$middle",$original,
       "$case: 排名器沒有修改原始可變 BigInt");
    is_deeply([map {"$_"} @lengths],\@unchanged,
       "$case: 任何計數及排名器都沒有修改原始月份 BigInt");

    $got->badd(123_456_789);
    is(''.$memo->count_prefix([]),"$expected",
       "$case: 修改輸出 BigInt 不污染記憶式計數器");
    my $hit=$memo->diagnostics;
    ok($hit->{cache_hits}>0,"$case: 重複查詢實際命中私有狀態快取");

    if (defined $first_total) {
        is("$expected","$first_total",
           '對調二月天數 (255,100) ↔ (100,255) 不改變合法詞數');
    } else {
        $first_total=$expected->copy;
    }
}
for my $invalid ([256,1],[1,256], [0,255],[-1,255]) {
    my $ok=eval {
        Pastafari::WeavingMemoOracle->new($invalid);
        1;
    };
    ok(!$ok,'獨立位元組鍵後綴 Oracle 必須拒絕超出 1..255 月長');
}
done_testing;
