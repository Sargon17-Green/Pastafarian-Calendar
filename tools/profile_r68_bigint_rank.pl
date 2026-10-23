#!/usr/bin/env perl
use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Time::HiRes qw(time sleep);
use POSIX qw(WNOHANG);
use Getopt::Long qw(GetOptions);
my ($profile,$seconds,$rss_limit)=('',185,393216);
GetOptions('profile=s'=>\$profile,'seconds=i'=>\$seconds,
           'rss-kib=i'=>\$rss_limit) or die "R68 參數不合法\n";
die "R68 profile 只允許 a/b\n" unless $profile eq 'a'||$profile eq 'b';
die "R68 資源上限不得放寬\n"
    if $seconds<1 || $seconds>185
    || $rss_limit<32768 || $rss_limit>393216;
die "R68 需要 Linux /proc\n" unless -r '/proc/self/status';
$|=1;
sub rss_kib ($pid) {
    open my $fh,'<',"/proc/$pid/status" or return undef;
    while(my $line=<$fh>) {
        return 0+$1 if $line =~ /^VmRSS:\s*(\d+)\s+kB/;
    }
    return undef;
}
my $pid=fork();
die "R68 無法建立監督子程序\n" if !defined $pid;
if (!$pid) {
    exec $^X,'-Ilib','-It/lib','tools/audit_r68_bigint_rank.pl',
        '--profile',$profile;
    die "R68 無法 exec 真正檢驗\n";
}
my $start=time();
my $peak=0;
while (1) {
    my $done=waitpid($pid,WNOHANG);
    if ($done==$pid) {
        if ($?) {
            print "R68_WATCH_COMPLETE passed=0 blocked=0 failed=1\n";
            exit 2;
        }
        printf "R68_WATCH_COMPLETE passed=1 blocked=0 failed=0 elapsed_sec=%.3f peak_RSS_KiB=%d\n",
            time()-$start,$peak;
        exit 0;
    }
    die "R68 waitpid 監督錯誤\n" if $done<0;
    my $rss=rss_kib($pid);
    my $elapsed=time()-$start;
    my $reason=!defined($rss)?'RSS_UNAVAILABLE'
              : $rss>$rss_limit?'RSS_LIMIT'
              : $elapsed>$seconds?'TIME_LIMIT':undef;
    $peak=$rss if defined($rss) && $rss>$peak;
    if (defined $reason) {
        kill 'KILL',$pid; waitpid($pid,0);
        printf "R68_WATCH_COMPLETE passed=0 blocked=1 failed=0 reason=%s elapsed_sec=%.3f peak_RSS_KiB=%d\n",
            $reason,$elapsed,$peak;
        exit 3;
    }
    sleep(0.05);
}
