#!/usr/bin/env perl
use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Time::HiRes qw(time sleep);
use POSIX qw(WNOHANG);
use Getopt::Long qw(GetOptions);
my ($shard,$seconds,$rss_limit)=(-1,185,393216);
GetOptions('shard=i'=>\$shard,'seconds=i'=>\$seconds,'rss-kib=i'=>\$rss_limit)
    or die "R70 監督參數格式不合法\n";
die "R70 只支援四個分片 0..3\n" if $shard<0 || $shard>3;
die "R70 不可放寬資源界線\n"
 if $seconds<1 || $seconds>185 || $rss_limit<32768 || $rss_limit>393216;
die "R70 必須 Linux /proc\n" if !-r '/proc/self/status';
$|=1;
sub rss_kib ($pid) {
 open my $fh,'<',"/proc/$pid/status" or return undef;
 while(my $line=<$fh>) {
  return 0+$1 if $line=~/^VmRSS:\s*(\d+)\s+kB/;
 }
 return undef;
}
my $pid=fork();
die "R70 無法 fork 驗證子程序\n" if !defined $pid;
if (!$pid) {
 exec $^X,'-Ilib','-It/lib','tools/audit_r70_permutation_mirror.pl',
      '--shard',$shard;
 die "R70 無法 exec 原生測試\n";
}
my $begin=time();
my $peak=0;
while(1) {
 my $done=waitpid($pid,WNOHANG);
 if ($done==$pid) {
  if ($?) {
   print "R70_WATCH_COMPLETE passed=0 blocked=0 failed=1 shard=$shard\n";
   exit 2;
  }
  printf "R70_WATCH_COMPLETE passed=1 blocked=0 failed=0 shard=%d seconds=%.3f max_RSS_KiB=%d\n",
   $shard,time()-$begin,$peak;
  exit 0;
 }
 die "R70 waitpid 失敗\n" if $done<0;
 my $rss=rss_kib($pid);
 my $elapsed=time()-$begin;
 my $reason=!defined($rss)?'RSS_UNAVAILABLE'
          : $rss>$rss_limit?'RSS_LIMIT'
          : $elapsed>$seconds?'TIME_LIMIT':undef;
 $peak=$rss if defined($rss) && $rss>$peak;
 if (defined $reason) {
  kill 'KILL',$pid;
  waitpid($pid,0);
  printf "R70_WATCH_COMPLETE passed=0 blocked=1 failed=0 shard=%d reason=%s seconds=%.3f max_RSS_KiB=%d\n",
   $shard,$reason,$elapsed,$peak;
  exit 3;
 }
 sleep(0.05);
}
