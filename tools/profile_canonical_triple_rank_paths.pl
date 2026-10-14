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
use Pastafari::WeavingUnrank qw(unrankWeavingPolynomial);
use Pastafari::WeavingRank qw(rankWeavingPolynomial);

# 取實測第 5000 年三個真正連續月份，獨立核對首／中／末
# 三個字典序 BigInt 排名的「每一天、所有合法分支」。
# 不以被測多項式排序流程的內部快取計數作為獨立預言機。
my ($offset,$seconds,$rss_limit)=(0,185,393216);
GetOptions('window-offset=i'=>\$offset,
           'seconds=i'=>\$seconds,
           'rss-kib=i'=>\$rss_limit)
    or die "參數無效\n";
die "三月窗口起點必須在 0..42\n"
    if $offset<0 || $offset>42;
die "時間預算須在 1..230 秒\n"
    if $seconds<1 || $seconds>230;
die "RSS 上限須在 32768..1048576 KiB\n"
    if $rss_limit<32768 || $rss_limit>1048576;
die "需要 Linux /proc 作為資源監督\n"
    if !-r '/proc/self/status';
$|=1;

sub child_rss ($pid) {
    open my $fh,'<',"/proc/$pid/status" or return 0;
    while (my $line=<$fh>) {
        return 0+$1 if $line =~ /^VmRSS:\s*(\d+)\s+kB/;
    }
    return 0;
}
sub child_peak () {
    open my $fh,'<','/proc/self/status' or die "不能讀取 VmHWM\n";
    while (my $line=<$fh>) {
        return 0+$1 if $line =~ /^VmHWM:\s*(\d+)\s+kB/;
    }
    die "不能找到 VmHWM\n";
}
my $pid=fork();
die "無法建立獨立驗證子程序\n" if !defined $pid;
if (!$pid) {
    my $ok=eval {
        my $start=time();
        my @year=(
            115,108,119,109,106,81,115,114,117,120,98,52,81,97,121,
            97,115,96,107,61,106,115,119,39,84,103,115,107,55,119,
            97,50,122,110,81,54,101,83,88,40,25,77,98,122,105
        );
        die "原生 5000 年 45 個月份的固定 SHA-256 已變\n"
            if sha256_hex(join(',',@year)) ne
               '6d64022344c04935e6423aa6f96b285098d35b9b5ecb4b8c57a4c7149773a134';
        my $year_days=0;
        $year_days+=$_ for @year;
        die "固定年份並非 45 月、4244 日\n"
            if @year!=45 || $year_days!=4244;
        my @L=@year[$offset..$offset+2];
        my $days=0;
        $days+=$_ for @L;
        printf "CANONICAL_TRIPLE_RANKS phase=INPUT offset=%d months=%s days=%d\n",
            $offset,join(',',@L),$days;

        my $oracle=Pastafari::WeavingMemoOracle->new(\@L);
        my $total=$oracle->count_prefix([]);
        my $poly=countWeavingsPolynomial(\@L);
        die "三月局部記憶式和多項式總數不符\n"
            if $total!=$poly;
        die "三月局部有不合理的空計數\n" if $total<3;
        my @samples=(
            ['first',Math::BigInt->bone],
            ['middle',$total->copy->bdiv(2)->badd(1)],
            ['last',$total->copy],
        );
        my $passed=0;
        for my $sample (@samples) {
            my ($name,$rank)=@$sample;
            my $rank_text="$rank";
            my %unrank_stats;
            my $word=unrankWeavingPolynomial(
                \@L,$rank,\%unrank_stats,
                {profile_engine=>'stream-indexed',
                 max_temp_file_bytes=>16*1024*1024}
            );
            die "$name 解碼長度不等於全部月份天數\n"
                if @$word!=$days;
            die "$name 反排名沒有實際建立磁碟索引\n"
                if ($unrank_stats{indexed_profile_builds}//0)!=1;

            my $remaining=[@L];
            my ($opened,$closed)=(0,0);
            my @prefix;
            my $local=$rank->copy;
            for my $day (1..$days) {
                my $parent=$oracle->count_prefix(\@prefix);
                die "$name/$day 局部一基 BigInt 不在母前綴範圍\n"
                    if $local<1 || $local>$parent;
                my $max=$opened<@L ? $opened+1 : scalar(@L);
                my @legal=grep {
                    $remaining->[$_-1]>0
                    && ($remaining->[$_-1]!=1 || $_==$closed+1)
                } 1..$max;
                die "$name/$day 沒有合法候選月份\n" if !@legal;
                my $partition=Math::BigInt->bzero;
                my $selected;
                for my $j (@legal) {
                    my @possible=(@prefix,$j);
                    my $ways=$oracle->count_prefix(\@possible);
                    $partition->badd($ways);
                    if (!defined $selected) {
                        if ($local<=$ways) {
                            $selected=$j;
                        } else {
                            $local->bsub($ways);
                        }
                    }
                }
                die "$name/$day 所有候選沒有形成完整不相交分割\n"
                    if $partition!=$parent;
                die "$name/$day 多項式排名字元和獨立前綴 Oracle 不符\n"
                    if !defined($selected) || $selected!=$word->[$day-1];
                push @prefix,$selected;
                $opened=$selected if $selected>$opened;
                --$remaining->[$selected-1];
                $closed=$selected if !$remaining->[$selected-1];
            }
            die "$name 完整後仍有月份剩餘天數\n"
                if grep {$_!=0} @$remaining;
            die "$name 完成後局部排名不等於 1\n"
                if $local!=1;
            my %rank_stats;
            my $back=rankWeavingPolynomial(
                \@L,$word,\%rank_stats,
                {profile_engine=>'stream-indexed',
                 max_temp_file_bytes=>16*1024*1024}
            );
            die "$name 正向排名不能精確還原原 BigInt\n"
                if "$back" ne $rank_text;
            die "$name 正向排名沒有建立私人索引\n"
                if ($rank_stats{indexed_profile_builds}//0)!=1;
            die "$name 原始可變 BigInt 排名被污染\n"
                if "$rank" ne $rank_text;
            $passed++;
            my $diag=$oracle->diagnostics;
            printf "CANONICAL_TRIPLE_RANK status=PASS offset=%d case=%s rank_digits=%d days=%d memo_entries=%d hits=%d elapsed_sec=%.3f\n",
                $offset,$name,length($rank_text),$days,
                $diag->{entries},$diag->{cache_hits},time()-$start;
        }
        die "三個必選排名未全數核對\n" if $passed!=3;
        my $diag=$oracle->diagnostics;
        printf "CANONICAL_TRIPLE_RANKS status=PASS scope=THREE_COMPLETE_INDEPENDENT_RANK_PATHS offset=%d cases=%d days_per_case=%d total_digits=%d memo_states=%d cache_hits=%d elapsed_sec=%.3f VmHWM_KiB=%d\n",
            $offset,$passed,$days,length("$total"),$diag->{entries},
            $diag->{cache_hits},time()-$start,child_peak();
        1;
    };
    if (!$ok) {
        print STDERR "CANONICAL_TRIPLE_RANKS status=FAIL reason=$@\n";
        exit 2;
    }
    exit 0;
}
my $begin=time();
my $max_seen=0;
while (1) {
    my $done=waitpid($pid,WNOHANG);
    if ($done==$pid) {
        if ($?) {
            print "CANONICAL_TRIPLE_RANKS_CHECK_COMPLETE passed=0 blocked=0 failed=1 exit=$?\n";
            exit 2;
        }
        print "CANONICAL_TRIPLE_RANKS_CHECK_COMPLETE passed=1 blocked=0 failed=0\n";
        exit 0;
    }
    die "父程序 waitpid 失敗\n" if $done<0;
    my $rss=child_rss($pid);
    $max_seen=$rss if $rss>$max_seen;
    if ($rss>$rss_limit || time()-$begin>$seconds) {
        my $reason=$rss>$rss_limit ? 'RSS_LIMIT' : 'TIME_LIMIT';
        kill 'KILL',$pid;
        waitpid($pid,0);
        printf "CANONICAL_TRIPLE_RANKS status=BLOCKED reason=%s elapsed_sec=%.3f observed_peak_RSS_KiB=%d\n",
            $reason,time()-$begin,$max_seen;
        print "CANONICAL_TRIPLE_RANKS_CHECK_COMPLETE passed=0 blocked=1 failed=0\n";
        exit 3;
    }
    sleep(0.05);
}
