use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use Digest::SHA qw(sha256_hex);
use File::Temp qw(tempdir);
use lib 'lib','t/lib';
use Pastafari::NormativeScroll qw(countWeavings);
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::WeavingPolynomialStream qw(countWeavingsPolynomialStream);
use Pastafari::WeavingProfileDisk qw(buildWeavingProfileDisk);
use Pastafari::WeavingSuffix qw(countWeavingSuffixPolynomial);
use Pastafari::WeavingSuffixFactor qw(countWeavingSuffixFactored);

# 由原生 year5000 -> sauce -> 月份數/長度選擇器取得的固定快照。
# 其 SHA-256 在 opt-in 原生重算中確認；快照不是外部權威 Oracle。
my @L = (
    115,108,119,109,106,81,115,114,117,120,98,52,81,97,121,
    97,115,96,107,61,106,115,119,39,84,103,115,107,55,119,
    97,50,122,110,81,54,101,83,88,40,25,77,98,122,105
);
is(scalar(@L),45,'第 5000 年固定實測月長共有 45 月');
my $sum=0; $sum += $_ for @L;
is($sum,4244,'固定快照恰好覆蓋錨定年全部 4,244 日');
is(sha256_hex(join(',',@L)),
   '6d64022344c04935e6423aa6f96b285098d35b9b5ecb4b8c57a4c7149773a134',
   '月長快照保持可獨立重算的固定雜湊');

sub choose_two_months ($a,$b) {
    # 兩月份首次及末次順序強制首符號為 1、末符號為 2；
    # 其餘 a+b-2 個位置選 a-1 個第一月份符號。
    my $n=$a+$b-2;
    my $k=$a-1;
    $k=$n-$k if $k>$n-$k;
    my $v=Math::BigInt->bone;
    for my $i (1 .. $k) {
        $v->bmul($n-$k+$i)->bdiv($i);
    }
    return $v;
}

# 全部 44 個相鄰月對；與只抽樣首尾月對不同，這裡不排除
# 年份中間的非常短月份和其他不均勻長度。
my $pairs=0;
my $scratch=tempdir(CLEANUP=>1);
{
    local $ENV{TMPDIR}=$scratch;
    for my $i (0 .. $#L-1) {
        my @pair=@L[$i,$i+1];
        my $label=sprintf('第%02d/%02d月', $i+1,$i+2);
        my $expected=choose_two_months(@pair);
        my $norm=countWeavings(\@pair);
        is("$norm","$expected","$label: 規範 DP 符合獨立二項式閉式");
        my $resident=countWeavingsPolynomial(\@pair);
        is("$resident","$expected","$label: 常駐多項式符合獨立二項式閉式");
        my %stats;
        my $stream=countWeavingsPolynomialStream(
            \@pair,\%stats,undef,{max_temp_file_bytes=>8*1024*1024}
        );
        is("$stream","$expected","$label: 磁碟串流符合獨立二項式閉式");
        is($stats{rows_serialized},$pair[0],
           "$label: 真正序列化首月的每一個矩陣列");
        $stream->badd(777);
        is("$norm","$expected","$label: 更改回傳串流 BigInt 不污染規範值");
        is("$resident","$expected","$label: 更改串流值不污染常駐模型");
        $pairs++;
    }

    # 八處分布於整年的位置使用獨立磁碟索引與三種後綴引擎，
    # 覆蓋長月、短月及尾端，無須對所有 44 對重複昂貴建表。
    my @check_index=(0,7,14,21,28,35,39,43);
    my $indexed=0;
    for my $i (@check_index) {
        my @pair=@L[$i,$i+1];
        my $expected=choose_two_months(@pair);
        my $store=buildWeavingProfileDisk(\@pair,8*1024*1024);
        is(''.$store->total,"$expected",'實際相鄰月對的索引式總數精確');
        my $hist=$store->histogram(2);
        my $total=Math::BigInt->bzero;
        $total->badd($_) for grep {defined($_)} @$hist;
        is("$total","$expected",'索引式位置直方圖加總保持完整計數');
        my $oracle=countWeavingSuffixPolynomial(\@pair,[1]);
        for my $engine ('resident','stream','stream-indexed') {
            my $opts={profile_engine=>$engine};
            $opts->{max_temp_file_bytes}=8*1024*1024
                if $engine ne 'resident';
            my $value=countWeavingSuffixFactored(
                \@pair,[1],undef,undef,$opts);
            is("$value","$oracle",'指定首月前綴的三引擎後綴計數精確');
            $value->badd(10_000);
            my $again=countWeavingSuffixFactored(
                \@pair,[1],undef,undef,$opts);
            is("$again","$oracle",'對外 BigInt 變更不污染下一次後綴計數');
        }
        $indexed++;
    }
    is($indexed,8,'八處實際月份位置各完成索引及三引擎核對');
    opendir my $dh,$scratch or die "無法開啟專用暫存目錄：$!\n";
    my @left=grep {$_ ne '.' && $_ ne '..'} readdir($dh);
    closedir $dh;
    # store 持有物件可能仍在最後一次迭代的詞法作用域內？
    # for 的區域已結束，沒有其他應該持續存在的索引物件。
    is_deeply(\@left,[],'全部索引與串流檔案均即時回收');
}
is($pairs,44,'覆蓋真實錨定年份的全部 44 個相鄰月對');
done_testing;
