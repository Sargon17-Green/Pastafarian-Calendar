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
use lib 'lib','t/lib';
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::WeavingUnrank qw(unrankWeavingPolynomial);
use Pastafari::WeavingRank qw(rankWeavingPolynomial);

# 單一 47 月份／252 日案例的雙向字典序排名稽核。
# 耗時或資源封頂時明確輸出 BLOCKED，不能稱作 PASS。
my ($seconds,$rss_kib)=(120,262144);
GetOptions('seconds=i'=>\$seconds,'rss-kib=i'=>\$rss_kib)
    or die "參數格式錯誤\n";
die "秒數必須在 1..180\n" if $seconds<1 || $seconds>180;
die "RSS 必須在 32768..1048576 KiB\n"
    if $rss_kib<32768 || $rss_kib>1048576;
die "需要 Linux /proc\n" if !-r '/proc/self/status';
$|=1;

sub read_rss ($pid) {
    open my $fh,'<',"/proc/$pid/status" or return 0;
    while (my $line=<$fh>) {
        return 0+$1 if $line =~ /^VmRSS:\s*(\d+)\s+kB/;
    }
    return 0;
}
sub peak_kib () {
    open my $fh,'<','/proc/self/status' or die "無法讀取 VmHWM\n";
    while (my $line=<$fh>) {
        return 0+$1 if $line =~ /^VmHWM:\s*(\d+)\s+kB/;
    }
    die "缺少 VmHWM\n";
}
my $pid=fork();
die "無法 fork：$!\n" if !defined $pid;
if ($pid==0) {
    my $ok=eval {
        my @lengths=((6)x17,(5)x30);
        my $start=time();
        my $total=countWeavingsPolynomial(\@lengths);
        my $rank=$total->copy->bdiv(2)->badd(1);
        die "不是中間排名\n" if $rank<=1 || $rank>=$total;
        my %unrank_stats;
        my $word=unrankWeavingPolynomial(\@lengths,$rank,\%unrank_stats);
        my $decode_time=time()-$start;
        my %rank_stats;
        my $reconstructed=rankWeavingPolynomial(\@lengths,$word,\%rank_stats);
        die "字典序反向排名無法還原原始 270 位排名\n"
            if $reconstructed!=$rank;
        die "總月份數或日數不符\n" if @lengths!=47 || @$word!=252;
        die "原始排名受到了可變性污染\n"
            if $rank!=$total->copy->bdiv(2)->badd(1);
        printf "ROUNDTRIP status=PASS months=47 days=252 rank_digits=%d total_sec=%.3f decode_sec=%.3f VmHWM_KiB=%d decoder_suffix_calls=%d decoder_reverse_builds=%d rank_smaller_candidates=%d rank_reverse_builds=%d\n",
            length("$rank"),time()-$start,$decode_time,peak_kib(),
            $unrank_stats{suffix_calls},$unrank_stats{reverse_histogram_builds},
            $rank_stats{candidates},$rank_stats{reverse_histogram_builds};
        1;
    };
    if (!$ok) {
        print STDERR "ROUNDTRIP status=FAIL reason=$@\n";
        exit 2;
    }
    exit 0;
}
my $start=time();
my $peak=0;
while (1) {
    my $done=waitpid($pid,WNOHANG);
    if ($done==$pid) {
        die "ROUNDTRIP status=FAIL exit=$?\n" if $?;
        print "ROUNDTRIP_CHECK_COMPLETE passed=1 blocked=0 failed=0\n";
        last;
    }
    die "waitpid 失敗\n" if $done<0;
    my $rss=read_rss($pid);
    $peak=$rss if $rss>$peak;
    if ($rss>$rss_kib || time()-$start>$seconds) {
        my $cause=$rss>$rss_kib?'RSS_LIMIT':'TIME_LIMIT';
        kill 'KILL',$pid;
        waitpid($pid,0);
        printf "ROUNDTRIP status=BLOCKED reason=%s elapsed=%.3fs observed_RSS_KiB=%d\n",
            $cause,time()-$start,$peak;
        print "ROUNDTRIP_CHECK_COMPLETE passed=0 blocked=1 failed=0\n";
        last;
    }
    sleep(0.025);
}
