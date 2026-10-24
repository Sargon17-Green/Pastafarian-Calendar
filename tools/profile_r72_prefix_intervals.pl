#!/usr/bin/env perl
use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use POSIX qw(WNOHANG);
use Time::HiRes qw(time sleep);
use Getopt::Long qw(GetOptions);
my ($shard,$seconds,$rss_limit)=(0,185,393216);
GetOptions('shard=i'=>\$shard,'seconds=i'=>\$seconds,
           'rss-kib=i'=>\$rss_limit)
    or die "R72 監督參數無效\n";
die "R72 shard 必須 1..4\n" unless $shard>=1 && $shard<=4;
die "R72 資源限制不可放寬\n"
 if $seconds<1 || $seconds>185 || $rss_limit<32768 || $rss_limit>393216;
die "R72 必須 Linux /proc\n" unless -r '/proc/self/status';
$|=1;
sub rss_kib ($pid) {
    open my $fh,'<',"/proc/$pid/status" or return undef;
    while(my $line=<$fh>) {
        return 0+$1 if $line=~/^VmRSS:\s*(\d+)\s+kB/;
    }
    return undef;
}
my $pid=fork();
die "R72 無法 fork\n" if !defined $pid;
if (!$pid) {
    exec $^X,'-Ilib','-It/lib','tools/audit_r72_prefix_intervals.pl',
        '--shard',$shard;
    die "R72 無法 exec 原生測試\n";
}
my $start=time();my $peak=0;
while(1) {
    my $done=waitpid($pid,WNOHANG);
    if ($done==$pid) {
        if ($?) {
            print "R72_WATCH_COMPLETE passed=0 blocked=0 failed=1 shard=$shard\n";
            exit 2;
        }
        printf "R72_WATCH_COMPLETE passed=1 blocked=0 failed=0 shard=%d seconds=%.3f max_RSS_KiB=%d\n",
            $shard,time()-$start,$peak;
        exit 0;
    }
    die "R72 waitpid 子程序失去監督\n" if $done<0;
    my $rss=rss_kib($pid);
    my $elapsed=time()-$start;
    my $reason=!defined($rss)?'RSS_UNAVAILABLE'
        : $rss>$rss_limit?'RSS_LIMIT'
        : $elapsed>$seconds?'TIME_LIMIT':undef;
    $peak=$rss if defined $rss && $rss>$peak;
    if (defined $reason) {
        kill 'KILL',$pid;waitpid($pid,0);
        printf "R72_WATCH_COMPLETE passed=0 blocked=1 failed=0 shard=%d reason=%s seconds=%.3f max_RSS_KiB=%d\n",
            $shard,$reason,$elapsed,$peak;
        exit 3;
    }
    sleep(0.05);
}
