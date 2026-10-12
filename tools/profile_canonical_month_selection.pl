#!/usr/bin/env perl
use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Math::BigInt;
use Time::HiRes qw(time sleep);
use POSIX qw(WNOHANG);
use Getopt::Long qw(GetOptions);
use Digest::SHA qw(sha256_hex);
use lib 'lib', 't/lib';
use Pastafari::NormativeScroll qw(
    FOUNDATION_DAY resetGateCache year5000
    countWeavings
);
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::WeavingPolynomialStream qw(countWeavingsPolynomialStream);
use Pastafari::WeavingProfileDisk qw(buildWeavingProfileDisk);
use Pastafari::WeavingSuffix qw(countWeavingSuffixPolynomial);
use Pastafari::WeavingSuffixFactor qw(countWeavingSuffixFactored);

# 只驗證真實年份選出的月長及相鄰兩月的精確交織。
# 不呼叫昂貴的整年度反排名，不將局部證據稱為全年度 PASS。
my ($seconds,$rss_kib)=(180,393216);
GetOptions('seconds=i'=>\$seconds,'rss-kib=i'=>\$rss_kib)
    or die "命令列參數無效\n";
die "時間限制必須在 1..240 秒\n"
    if !defined($seconds) || $seconds < 1 || $seconds > 240;
die "RSS 限制必須在 32768..1048576 KiB\n"
    if !defined($rss_kib) || $rss_kib < 32768 || $rss_kib > 1048576;
die "需要 Linux /proc 提供原生資源觀測\n"
    if !-r '/proc/self/status';
$|=1;

sub read_rss ($pid) {
    open my $fh, '<', "/proc/$pid/status" or return 0;
    while (my $line=<$fh>) {
        return 0+$1 if $line =~ /^VmRSS:\s*(\d+)\s+kB/;
    }
    return 0;
}

sub peak_kib () {
    open my $fh, '<', '/proc/self/status'
        or die "無法開啟 VmHWM\n";
    while (my $line=<$fh>) {
        return 0+$1 if $line =~ /^VmHWM:\s*(\d+)\s+kB/;
    }
    die "無法取得 VmHWM\n";
}

sub choose_two_months ($a,$b) {
    # 首個月首次出現早於第二月；其末次出現亦須較早。
    # 因而第一個符號必為 1，最後一個必為 2，
    # 中間 a+b-2 格中選出 a-1 個第一月份符號。
    my $n=$a+$b-2;
    my $k=$a-1;
    $k=$n-$k if $k>$n-$k;
    my $result=Math::BigInt->bone;
    for my $i (1 .. $k) {
        $result->bmul($n-$k+$i)->bdiv($i);
    }
    return $result;
}

sub verify_pair ($pair,$label) {
    my ($a,$b)=@$pair;
    my $expected=choose_two_months($a,$b);
    my $norm=countWeavings($pair);
    die "獨立規範計數與兩月閉式公式不符：$label\n"
        if $norm != $expected;
    my $resident=countWeavingsPolynomial($pair);
    die "常駐多項式與閉式公式不符：$label\n"
        if $resident != $expected;
    my %stream_stats;
    my $stream=countWeavingsPolynomialStream(
        $pair,\%stream_stats,undef,{max_temp_file_bytes=>8*1024*1024});
    die "逐列串流與閉式公式不符：$label\n"
        if $stream != $expected;
    my $indexed=buildWeavingProfileDisk($pair,8*1024*1024);
    die "磁碟索引總數與閉式公式不符：$label\n"
        if $indexed->total != $expected;
    my $hist=$indexed->histogram(2);
    my $sum=Math::BigInt->bzero;
    $sum->badd($_) for grep {defined($_)} @$hist;
    die "第二階段位置直方圖總數不符：$label\n"
        if $sum != $expected;

    my $prefix=[1];
    my $oracle=countWeavingSuffixPolynomial($pair,$prefix);
    for my $engine ('resident','stream','stream-indexed') {
        my $options={profile_engine=>$engine};
        $options->{max_temp_file_bytes}=8*1024*1024
            if $engine ne 'resident';
        my $actual=countWeavingSuffixFactored(
            $pair,$prefix,undef,undef,$options
        );
        die "引擎 $engine 的指定前綴與獨立規範不符：$label\n"
            if $actual != $oracle;
    }
    printf "CANONICAL_MONTH_PAIR status=PASS label=%s lengths=%d,%d count_digits=%d stream_rows=%d index_bytes=%d\n",
        $label,$a,$b,length("$expected"),
        $stream_stats{rows_serialized}//0,
        $indexed->diagnostics->{spool_bytes};
}

my $pid=fork();
die "無法建立受控子程序：$!\n" if !defined $pid;
if (!$pid) {
    my $ok=eval {
        my $start=time();
        resetGateCache();
        my $calculation_day=FOUNDATION_DAY();
        my $year=year5000($calculation_day);
        my $L=$year->{closeGateDay}->copy
            ->bsub($year->{openGateDay})->numify;
        die "起始錨定年份不是既有可驗證的 4244 日\n"
            unless "$year->{number}" eq '5000' && $L == 4244;
        print "CANONICAL_MONTHS phase=YEAR_RESOLVED days=$L\n";
        my $first_day=$year->{openGateDay}->copy->badd(1);
        my $sauce=Pastafari::NormativeScroll::sauce(
            $calculation_day,$first_day
        );
        my $count=Pastafari::NormativeScroll::_choose_month_count(
            $sauce,$year
        );
        die "實際月份數超出 3..47\n" if $count<3 || $count>47;
        print "CANONICAL_MONTHS phase=COUNT_SELECTED months=$count\n";
        my $lengths=Pastafari::NormativeScroll::_choose_month_lengths(
            $sauce,$year,$count
        );
        die "未取得完整月份長度陣列\n"
            if ref($lengths) ne 'ARRAY' || @$lengths!=$count;
        my ($total,$min,$max)=(0,124,0);
        for my $v (@$lengths) {
            die "規範月份長度不在 4..123 範圍\n"
                if !defined($v) || ref($v) || "$v" !~ /\A[0-9]+\z/
                || $v<4 || $v>123;
            $total+=$v;
            $min=$v if $v<$min;
            $max=$v if $v>$max;
        }
        die "選出月份的日數總和與原始年份不相等\n"
            if $total!=$L;
        my $digest=sha256_hex(join(',',@$lengths));
        printf "CANONICAL_MONTHS phase=LENGTHS_SELECTED days=%d months=%d min=%d max=%d sha256=%s first=%d,%d last=%d,%d\n",
            $L,$count,$min,$max,$digest,
            @$lengths[0,1],@$lengths[$count-2,$count-1];
        verify_pair([@$lengths[0,1]],'first');
        verify_pair([@$lengths[$count-2,$count-1]],'last');
        printf "CANONICAL_MONTHS status=PASS scope=YEAR5000_MONTH_LENGTHS_AND_TWO_PAIRS elapsed_sec=%.3f VmHWM_KiB=%d\n",
            time()-$start,peak_kib();
        1;
    };
    if (!$ok) {
        print STDERR "CANONICAL_MONTHS status=FAIL reason=$@\n";
        exit 2;
    }
    exit 0;
}
my $start=time();
my $peak=0;
while (1) {
    my $done=waitpid($pid,WNOHANG);
    if ($done==$pid) {
        my $status=$?;
        if ($status) {
            printf STDERR "CANONICAL_MONTHS_CHECK_COMPLETE passed=0 blocked=0 failed=1 child_status=%d\n",$status;
            exit 2;
        }
        print "CANONICAL_MONTHS_CHECK_COMPLETE passed=1 blocked=0 failed=0\n";
        exit 0;
    }
    die "父程序 waitpid 失敗\n" if $done<0;
    my $rss=read_rss($pid);
    $peak=$rss if $rss>$peak;
    if ($rss>$rss_kib || time()-$start>$seconds) {
        my $reason=$rss>$rss_kib ? 'RSS_LIMIT' : 'TIME_LIMIT';
        kill 'KILL',$pid;
        waitpid($pid,0);
        printf "CANONICAL_MONTHS status=BLOCKED reason=%s elapsed_sec=%.3f observed_RSS_KiB=%d\n",
            $reason,time()-$start,$peak;
        print "CANONICAL_MONTHS_CHECK_COMPLETE passed=0 blocked=1 failed=0\n";
        exit 3;
    }
    sleep(0.05);
}
