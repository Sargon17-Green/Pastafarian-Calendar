#!/usr/bin/env perl
use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Time::HiRes qw(time sleep);
use POSIX qw(WNOHANG);
use Getopt::Long qw(GetOptions);
my ($shard,$seconds,$rss_limit)=(0,185,393216);
GetOptions('shard=i'=>\$shard,'seconds=i'=>\$seconds,
           'rss-kib=i'=>\$rss_limit) or die "R73 監督參數不合法\n";
die "R73 只支援分片 1..5\n" if $shard<1 || $shard>5;
die "R73 不可放寬原先資源上限\n"
    if $seconds<1 || $seconds>185
    || $rss_limit<32768 || $rss_limit>393216;
die "R73 需要 Linux /proc\n" unless -r '/proc/self/status';
$|=1;
sub resident_kib ($pid) {
 open my $fh,'<',"/proc/$pid/status" or return undef;
 while (my $line=<$fh>) {
  return 0+$1 if $line=~/^VmRSS:\s*(\d+)\s+kB/;
 }
 return undef;
}
my $pid=fork();
die "R73 無法 fork 原生驗證\n" unless defined($pid);
if (!$pid) {
 exec $^X,'-Ilib','-It/lib','tools/audit_r73_prefix_partition.pl','--shard',$shard;
 die "R73 無法 exec 真正驗證器\n";
}
my $start=time();
my $peak=0;
while (1) {
 my $done=waitpid($pid,WNOHANG);
 if ($done==$pid) {
  if ($?!=0) {
   print "R73_WATCH passed=0 blocked=0 failed=1 shard=$shard\n";
   exit 2;
  }
  printf "R73_WATCH passed=1 blocked=0 failed=0 shard=%d elapsed_sec=%.3f max_RSS_KiB=%d\n",
         $shard,time()-$start,$peak;
  exit 0;
 }
 die "R73 失去 waitpid 監督\n" if $done<0;
 my $rss=resident_kib($pid);
 my $elapsed=time()-$start;
 my $reason=!defined($rss)?'RSS_UNAVAILABLE'
     : $rss>$rss_limit?'RSS_LIMIT'
     : $elapsed>$seconds?'TIME_LIMIT':undef;
 $peak=$rss if defined($rss) && $rss>$peak;
 if (defined $reason) {
  kill 'KILL',$pid;
  waitpid($pid,0);
  printf "R73_WATCH passed=0 blocked=1 failed=0 shard=%d reason=%s elapsed_sec=%.3f max_RSS_KiB=%d\n",
      $shard,$reason,$elapsed,$peak;
  exit 3;
 }
 sleep(0.05);
}
