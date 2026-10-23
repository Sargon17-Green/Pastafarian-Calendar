#!/usr/bin/env perl
use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use POSIX qw(WNOHANG);
use Time::HiRes qw(time sleep);
use Getopt::Long qw(GetOptions);
my ($profile,$seconds,$rss_limit)=('',185,393216);
GetOptions('profile=s'=>\$profile,'seconds=i'=>\$seconds,
           'rss-kib=i'=>\$rss_limit) or die "R69 參數無效\n";
die "R69 profile 只能 a/b/c\n"
    if $profile ne 'a' && $profile ne 'b' && $profile ne 'c';
die "R69 不得放寬資源上限\n"
    if $seconds<1 || $seconds>185 || $rss_limit<32768 || $rss_limit>393216;
die "R69 必須 Linux /proc\n" if !-r '/proc/self/status';
$|=1;
sub resident_kib ($pid) {
    open my $fh,'<',"/proc/$pid/status" or return undef;
    while(my $line=<$fh>) {
        return 0+$1 if $line =~ /^VmRSS:\s*(\d+)\s+kB/;
    }
    return undef;
}
my $pid=fork();
die "R69 無法 fork\n" if !defined $pid;
if (!$pid) {
    exec $^X,'-Ilib','-It/lib','tools/audit_r69_bigint_neighbors.pl','--profile',$profile;
    die "R69 無法 exec\n";
}
my $begin=time();my $peak=0;
while (1) {
    my $done=waitpid($pid,WNOHANG);
    if ($done==$pid) {
        if ($?) {
            print "R69_WATCH passed=0 blocked=0 failed=1\n";
            exit 2;
        }
        printf "R69_WATCH passed=1 blocked=0 failed=0 seconds=%.3f rss_peak_kib=%d\n",
            time()-$begin,$peak;
        exit 0;
    }
    die "R69 子程序監控失效\n" if $done<0;
    my $rss=resident_kib($pid);
    my $elapsed=time()-$begin;
    my $reason=!defined($rss)?'RSS_UNAVAILABLE'
             : $rss>$rss_limit?'RSS_LIMIT'
             : $elapsed>$seconds?'TIME_LIMIT':undef;
    $peak=$rss if defined($rss) && $rss>$peak;
    if (defined $reason) {
        kill 'KILL',$pid;waitpid($pid,0);
        printf "R69_WATCH passed=0 blocked=1 failed=0 reason=%s seconds=%.3f rss_peak_kib=%d\n",
            $reason,$elapsed,$peak;
        exit 3;
    }
    sleep(0.05);
}
