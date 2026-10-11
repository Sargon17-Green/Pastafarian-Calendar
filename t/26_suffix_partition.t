use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib','t/lib';
use Pastafari::WeavingSuffix qw(countWeavingSuffixPolynomial);
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::NormativeScroll qw(unrankWeaving);

# 一個有效前綴的所有完成序列，恰好可以依下一個月份的
# 標籤分割為互不重疊的區塊。這是獨立的數學恆等式，
# 不依賴新的字典序反排名實作。
sub verify_partition ($lengths, $prefix, $label) {
    my $base=countWeavingSuffixPolynomial($lengths,$prefix);
    my $sum=Math::BigInt->bzero;
    my $available=0;
    for my $month (1 .. scalar @$lengths) {
        my @candidate=(@$prefix,$month);
        my $part=eval { countWeavingSuffixPolynomial($lengths,\@candidate) };
        if ($@) {
            like($@, qr/月份前綴/, "$label：拒絕不合法的下一月");
            next;
        }
        $sum->badd($part);
        $available++;
    }
    is("$sum","$base","$label：候選完工數相加與母前綴完全相同");
    ok($available>=1, "$label：未完成前綴至少有一個可行候選");
}

for my $lengths ([2,2,2],[4,4,4],[4,4,4,4]) {
    my $total=countWeavingsPolynomial($lengths);
    my $middle=$total->copy->bdiv(2)->badd(1);
    my $days=0;$days+=$_ for @$lengths;
    for my $rank (Math::BigInt->bone,$middle,$total) {
        my $word=unrankWeaving($lengths,$rank);
        for my $n (0,1,2,int($days/2),$days-1) {
            my @prefix = $n>0 ? @$word[0 .. $n-1] : ();
            verify_partition($lengths,\@prefix,
                '月份 '.join('-',@$lengths).'、排名 '.$rank.'、前綴長 '.$n);
        }
    }
}
my @maximum_months=(4)x47;
verify_partition(\@maximum_months,[1],
    '47 個合法月份，第一日唯一為 1');
my $full=countWeavingsPolynomial(\@maximum_months);
my $after_one=countWeavingSuffixPolynomial(\@maximum_months,[1]);
is("$after_one","$full",'47 月份固定第一日後的計數與全域計數相同');

# 不同呼叫互不共享可變排名值或前綴內容。
my @prefix=(1,2);
my $clone=countWeavingSuffixPolynomial([4,4,4],\@prefix);
$clone->badd(12345);
is_deeply(\@prefix,[1,2],'修改結果大整數不更改來源前綴');
is(''.countWeavingSuffixPolynomial([4,4,4],\@prefix),
    ''.countWeavingSuffixPolynomial([4,4,4],\@prefix),
    '相同前綴的多次計數具有確定性');
done_testing;
