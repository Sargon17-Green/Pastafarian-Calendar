#!/usr/bin/env perl
use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Time::HiRes qw(time sleep);
use POSIX qw(WNOHANG);
use Getopt::Long qw(GetOptions);
my ($first,$second,$seconds,$limit)=(0,0,185,393216);
GetOptions('first=i'=>\$first,'second=i'=>\$second,
 'seconds=i'=>\$seconds,'rss-kib=i'=>\$limit)
 or die "R75 監督參數格式無效\n";
die "R75 第一與第二月長只允許 1..3\n"
 if $first<1 || $first>3 || $second<1 || $second>3;
die "R75 不可放寬 185 秒及 393216 KiB 上限\n"
 if $seconds<1 || $seconds>185 || $limit<32768 || $limit>393216;
die "R75 需要 Linux /proc\n" unless -r '/proc/self/status';
$|=1;
sub rss_kib ($pid) {
 open my $f,'<',"/proc/$pid/status" or return undef;
 while(my $line=<$f>) {
  return 0+$1 if $line=~/^VmRSS:\s*(\d+)\s+kB/;
 }
 return undef;
}
my $pid=fork();
die "R75 無法 fork 真正原生子程序\n" unless defined($pid);
if(!$pid) {
 exec $^X,'-Ilib','-It/lib','tools/audit_r75_fivemonth_prefix_tree.pl',
  '--first',$first,'--second',$second;
 die "R75 無法 exec 真正驗證器\n";
}
my $begin=time();my $peak=0;
while(1) {
 my $done=waitpid($pid,WNOHANG);
 if($done==$pid) {
  if($?) {
   print "R75_WATCH passed=0 blocked=0 failed=1 first=$first second=$second\n";
   exit 2;
  }
  printf "R75_WATCH passed=1 blocked=0 failed=0 first=%d second=%d elapsed_sec=%.3f max_RSS_KiB=%d\n",
   $first,$second,time()-$begin,$peak;
  exit 0;
 }
 die "R75 waitpid 失去監督\n" if $done<0;
 my $rss=rss_kib($pid);
 my $elapsed=time()-$begin;
 my $why=!defined($rss)?'RSS_UNAVAILABLE':$rss>$limit?'RSS_LIMIT'
      :$elapsed>$seconds?'TIME_LIMIT':undef;
 $peak=$rss if defined($rss) && $rss>$peak;
 if(defined($why)) {
  kill 'KILL',$pid;waitpid($pid,0);
  printf "R75_WATCH passed=0 blocked=1 failed=0 first=%d second=%d reason=%s elapsed_sec=%.3f max_RSS_KiB=%d\n",
   $first,$second,$why,$elapsed,$peak;
  exit 3;
 }
 sleep(0.05);
}
