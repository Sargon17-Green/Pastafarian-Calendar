#!/usr/bin/env perl
use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Math::BigInt;
use Digest::SHA qw(sha256_hex);
use Getopt::Long qw(GetOptions);
use Time::HiRes qw(time sleep);
use POSIX qw(WNOHANG);
use lib 'lib','t/lib';
use Pastafari::WeavingMemoOracle;
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::WeavingPolynomialStream qw(countWeavingsPolynomialStream);

# 真實 5000 年 45 月份的全部 43 個相鄰三月局部計數。
# 分組由同一有界子程序執行，禁止把「三月局部總數」
# 冒稱為完整 45 月／4244 日的全年度字序或時間性能。
my ($batch_start,$batch_count,$seconds,$rss_limit)=(0,11,185,393216);
GetOptions(
    'batch-start=i'=>\$batch_start,
    'batch-count=i'=>\$batch_count,
    'seconds=i'=>\$seconds,
    'rss-kib=i'=>\$rss_limit,
) or die "命令列參數格式無效\n";
die "批次起點必須是 0..42\n" if $batch_start<0 || $batch_start>42;
die "批次最多 11 個且必須在 43 窗內\n"
    if $batch_count<1 || $batch_count>11 || $batch_start+$batch_count>43;
die "時間限制必須是 1..230 秒\n" if $seconds<1 || $seconds>230;
die "RSS 限制必須是 32768..1048576 KiB\n"
    if $rss_limit<32768 || $rss_limit>1048576;
die "需要 Linux /proc 才能驗證資源上限\n"
    if !-r '/proc/self/status';
$|=1;

sub rss_kib ($pid) {
    open my $fh,'<',"/proc/$pid/status" or return 0;
    while (my $line=<$fh>) {
        return 0+$1 if $line =~ /^VmRSS:\s*(\d+)\s+kB/;
    }
    return 0;
}
sub own_hwm () {
    open my $fh,'<','/proc/self/status' or die "無法讀取 VmHWM\n";
    while (my $line=<$fh>) {
        return 0+$1 if $line =~ /^VmHWM:\s*(\d+)\s+kB/;
    }
    die "找不到 VmHWM\n";
}
my $pid=fork();
die "無法啟動獨立資源監督子程序：$!\n"
    if !defined $pid;
if (!$pid) {
    my $ok=eval {
        my $begin=time();
        my @year=(
            115,108,119,109,106,81,115,114,117,120,98,52,81,97,121,
            97,115,96,107,61,106,115,119,39,84,103,115,107,55,119,
            97,50,122,110,81,54,101,83,88,40,25,77,98,122,105
        );
        die "已核對的第 5000 年月份向量雜湊不符\n"
            if sha256_hex(join(',',@year)) ne
               '6d64022344c04935e6423aa6f96b285098d35b9b5ecb4b8c57a4c7149773a134';
        my $total=0;
        $total+=$_ for @year;
        die "來源年份月數或總日數不合 45 / 4244\n"
            if @year!=45 || $total!=4244;
        printf "CANONICAL_TRIPLES phase=INPUT start=%d count=%d whole_year_months=%d whole_year_days=%d\n",
            $batch_start,$batch_count,scalar(@year),$total;
        my $checked=0;
        my $largest_digits=0;
        for my $i ($batch_start .. $batch_start+$batch_count-1) {
            my @lengths=@year[$i .. $i+2];
            my $days=0;
            $days+=$_ for @lengths;
            my $oracle=Pastafari::WeavingMemoOracle->new(\@lengths);
            my $norm=$oracle->count_prefix([]);
            my $resident=countWeavingsPolynomial(\@lengths);
            die "第 $i 個三月份局部：獨立 BigInt 和位置多項式總數不一致\n"
                if $norm!=$resident;
            my %stats;
            my $stream=countWeavingsPolynomialStream(
                \@lengths,\%stats,undef,{max_temp_file_bytes=>16*1024*1024}
            );
            die "第 $i 個三月份局部：磁碟串流總數和獨立 Oracle 不一致\n"
                if $stream!=$norm;
            die "第 $i 個三月份局部：沒有序列化任何矩陣行\n"
                if ($stats{rows_serialized}//0)<1;
            my $text="$norm";
            $stream->badd(1234);
            die "第 $i 個三月份局部：串流輸出污染獨立 BigInt\n"
                if "$norm" ne $text || "$resident" ne $text;
            my $diag=$oracle->diagnostics;
            die "第 $i 個三月份局部：未儲存獨立的遞迴狀態\n"
                if ($diag->{entries}//0)<1;
            my $digits=length($text);
            $largest_digits=$digits if $digits>$largest_digits;
            $checked++;
            printf "CANONICAL_TRIPLE status=PASS index=%d months=%d,%d,%d days=%d digits=%d memo_states=%d stream_rows=%d elapsed_sec=%.3f\n",
                $i,@lengths,$days,$digits,$diag->{entries},
                $stats{rows_serialized},time()-$begin;
        }
        die "實際完成的連續三月窗口數不符\n"
            if $checked!=$batch_count;
        printf "CANONICAL_TRIPLES status=PASS scope=ADJACENT_TRIPLES start=%d count=%d final_exclusive=%d max_digits=%d elapsed_sec=%.3f VmHWM_KiB=%d\n",
            $batch_start,$checked,$batch_start+$checked,
            $largest_digits,time()-$begin,own_hwm();
        1;
    };
    if (!$ok) {
        print STDERR "CANONICAL_TRIPLES status=FAIL reason=$@\n";
        exit 2;
    }
    exit 0;
}
my $started=time();
my $observed_peak=0;
while (1) {
    my $done=waitpid($pid,WNOHANG);
    if ($done==$pid) {
        if ($?) {
            print "CANONICAL_TRIPLES_CHECK_COMPLETE passed=0 blocked=0 failed=1 exit=$?\n";
            exit 2;
        }
        print "CANONICAL_TRIPLES_CHECK_COMPLETE passed=1 blocked=0 failed=0\n";
        exit 0;
    }
    die "資源監督 waitpid 失敗\n" if $done<0;
    my $rss=rss_kib($pid);
    $observed_peak=$rss if $rss>$observed_peak;
    if ($rss>$rss_limit || time()-$started>$seconds) {
        my $reason=$rss>$rss_limit ? 'RSS_LIMIT' : 'TIME_LIMIT';
        kill 'KILL',$pid;
        waitpid($pid,0);
        printf "CANONICAL_TRIPLES status=BLOCKED reason=%s elapsed_sec=%.3f observed_peak_RSS_KiB=%d\n",
            $reason,time()-$started,$observed_peak;
        print "CANONICAL_TRIPLES_CHECK_COMPLETE passed=0 blocked=1 failed=0\n";
        exit 3;
    }
    sleep(0.05);
}
