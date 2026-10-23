#!/usr/bin/env perl
use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Time::HiRes qw(time sleep);
use POSIX qw(WNOHANG);
use Getopt::Long qw(GetOptions);

# Stage 1 R67：以獨立父程序監督真正執行 Perl t/87 的子程序。
# 只有子程序正常結束且 RSS、時間均未逾限才輸出 PASS。
my ($seconds,$rss_limit)=(185,393216);
GetOptions('seconds=i'=>\$seconds,'rss-kib=i'=>\$rss_limit)
    or die "R67 監督參數無效\n";
die "R67 限時不得超過 185 秒\n" if $seconds<1 || $seconds>185;
die "R67 RSS 限額不可放寬\n"
    if $rss_limit<32768 || $rss_limit>393216;
die "R67 需要 Linux /proc\n" unless -r '/proc/self/status';
$|=1;

sub resident_kib ($pid) {
    open my $fh,'<',"/proc/$pid/status" or return 0;
    while (my $line=<$fh>) {
        return 0+$1 if $line =~ /^VmRSS:\s*(\d+)\s+kB/;
    }
    return 0;
}
my $child=fork();
die "R67 無法 fork 原生 Perl 測試\n" unless defined($child);
if (!$child) {
    exec $^X,'-Ilib','-It/lib','t/87_r67_wide_bigint_prefix.t';
    die "R67 無法 exec 測試\n";
}
my $start=time();
my $peak=0;
while (1) {
    my $done=waitpid($child,WNOHANG);
    if ($done==$child) {
        if ($?!=0) {
            print "R67_WIDE_COMPLETE passed=0 blocked=0 failed=1 child_status=$?\n";
            exit 2;
        }
        printf "R67_WIDE_COMPLETE passed=1 blocked=0 failed=0 elapsed_sec=%.3f max_RSS_KiB=%d\n",
            time()-$start,$peak;
        exit 0;
    }
    die "R67 waitpid 失敗\n" if $done<0;
    my $rss=resident_kib($child);
    $peak=$rss if $rss>$peak;
    my $elapsed=time()-$start;
    if ($rss>$rss_limit || $elapsed>$seconds) {
        my $reason=$rss>$rss_limit?'RSS_LIMIT':'TIME_LIMIT';
        kill 'KILL',$child;
        waitpid($child,0);
        printf "R67_WIDE_COMPLETE passed=0 blocked=1 failed=0 reason=%s elapsed_sec=%.3f max_RSS_KiB=%d\n",
            $reason,$elapsed,$peak;
        exit 3;
    }
    sleep(0.05);
}
