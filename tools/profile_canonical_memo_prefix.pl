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

# 四個真正月份、240 日的獨立 BigInt 逐日前綴核查。執行時限與
# RSS 界限均由父程序強制。父程序不把 BLOCKED 當成 PASS。
my ($days,$seconds,$rss_limit)=(240,185,393216);
GetOptions('days=i'=>\$days,'seconds=i'=>\$seconds,
           'rss-kib=i'=>\$rss_limit)
    or die "參數無效\n";
die "days 必須在 1..240\n" if $days<1 || $days>240;
die "seconds 必須在 1..230\n" if $seconds<1 || $seconds>230;
die "rss-kib 必須在 32768..1048576\n"
    if $rss_limit<32768 || $rss_limit>1048576;
die "需具備 Linux /proc 行程觀測\n" if !-r '/proc/self/status';
$|=1;

sub rss_of ($pid) {
    open my $fh,'<',"/proc/$pid/status" or return 0;
    while(my $ln=<$fh>) {
        return 0+$1 if $ln =~ /^VmRSS:\s*(\d+)\s+kB/;
    }
    return 0;
}
sub peak_self () {
    open my $fh,'<','/proc/self/status' or die "無法讀取 VmHWM\n";
    while(my $ln=<$fh>) {
        return 0+$1 if $ln =~ /^VmHWM:\s*(\d+)\s+kB/;
    }
    die "缺少 VmHWM\n";
}
my $pid=fork();
die "無法建立受控子程序\n" if !defined $pid;
if (!$pid) {
    my $ok=eval {
        my $start=time();
        my @year=(
            115,108,119,109,106,81,115,114,117,120,98,52,81,97,121,
            97,115,96,107,61,106,115,119,39,84,103,115,107,55,119,
            97,50,122,110,81,54,101,83,88,40,25,77,98,122,105
        );
        die "原生月份快照 SHA-256 不符\n"
            if sha256_hex(join(',',@year)) ne
                '6d64022344c04935e6423aa6f96b285098d35b9b5ecb4b8c57a4c7149773a134';
        my @L=@year[39..42];
        die "四個實際月份不符\n" if join(',',@L) ne '40,25,77,98';
        print "CANONICAL_MEMO phase=INPUT months=4 days=240 lengths=40,25,77,98 requested_prefix_days=$days\n";
        my $counter=Pastafari::WeavingMemoOracle->new(\@L);
        my $original=$counter->count_prefix([]);
        my %info=%{$counter->diagnostics};
        printf "CANONICAL_MEMO phase=MEMO_TOTAL digits=%d entries=%d visits=%d hits=%d elapsed_sec=%.3f\n",
            length("$original"),$info{entries},$info{visits},
            $info{cache_hits},time()-$start;
        my $poly=countWeavingsPolynomial(\@L);
        die "記憶式前沿獨立計數和全域位置多項式計數不符\n"
            if $original!=$poly;
        my $middle=$original->copy->bdiv(2)->badd(1);
        my $middle_text="$middle";
        die "中位排名不在有效 BigInt 範圍\n"
            if $middle<=1 || $middle>=$original;
        my %unrank_stats;
        my $word=unrankWeavingPolynomial(\@L,$middle,\%unrank_stats,
             {profile_engine=>'stream-indexed',
              max_temp_file_bytes=>16*1024*1024});
        die "索引反排名沒有完整 240 日\n" if @$word!=240;
        die "索引反排名沒有建立私人索引\n"
            if ($unrank_stats{indexed_profile_builds}//0)!=1;
        my $local=$middle->copy;
        my @prefix;
        my @remaining=@L;
        my ($opened,$closed)=(0,0);
        for my $step (1..$days) {
            my $parent=$counter->count_prefix(\@prefix);
            die "第 $step 天的局部 BigInt 排名失去合法範圍\n"
                if $local<1 || $local>$parent;
            my $max=$opened<@L ? $opened+1 : scalar(@L);
            my @options=grep {
                $remaining[$_-1]>0
                && ($remaining[$_-1]!=1 || $_==$closed+1)
            } 1..$max;
            die "第 $step 天沒有合法候選\n" if !@options;
            my $sum=Math::BigInt->bzero;
            my $selected;
            for my $j (@options) {
                my @candidate=(@prefix,$j);
                my $ways=$counter->count_prefix(\@candidate);
                $sum->badd($ways);
                if (!defined $selected) {
                    if ($local<=$ways) {
                        $selected=$j;
                    } else {
                        $local->bsub($ways);
                    }
                }
            }
            die "第 $step 天各候選計數不構成母前綴精確分割\n"
                if $sum!=$parent;
            die "第 $step 天沒有按 BigInt 字典序找到所需分支\n"
                if !defined $selected;
            die "第 $step 天與索引反排名的字典序選擇不符\n"
                if $selected!=$word->[$step-1];
            push @prefix,$selected;
            $opened=$selected if $selected>$opened;
            --$remaining[$selected-1];
            $closed=$selected if !$remaining[$selected-1];
            if ($step==1 || $step==4 || $step==8
                || $step==12 || $step==24 || $step==$days) {
                my $diag=$counter->diagnostics;
                printf "CANONICAL_MEMO phase=PREFIX_PASS checked_days=%d entries=%d cache_hits=%d next_rank_digits=%d elapsed_sec=%.3f\n",
                    $step,$diag->{entries},$diag->{cache_hits},
                    length("$local"),time()-$start;
            }
        }
        die "中位 BigInt 排名被任何驗證過程修改\n"
            if "$middle" ne $middle_text;
        die "240 日完整核查後仍有尚未用完的月份\n"
            if $days==240 && grep {$_!=0} @remaining;
        die "240 日全部核查後局部排名不等於 1\n"
            if $days==240 && $local!=1;
        my $diag=$counter->diagnostics;
        die "沒有任何獨立記憶式狀態快取命中\n"
            if $diag->{cache_hits}<1;
        printf "CANONICAL_MEMO status=PASS scope=%s checked_days=%d months=4 total_days=240 rank_digits=%d entries=%d hits=%d peak_depth=%d binomial_cache=%d elapsed_sec=%.3f VmHWM_KiB=%d\n",
            $days==240?'FULL_240_DAY_LEXICOGRAPHIC_BRANCHES':'PREFIX_ONLY',
            $days,length($middle_text),
            $diag->{entries},$diag->{cache_hits},
            $diag->{peak_depth},$diag->{binomial_entries},
            time()-$start,peak_self();
        1;
    };
    if (!$ok) {
        print STDERR "CANONICAL_MEMO status=FAIL reason=$@\n";
        exit 2;
    }
    exit 0;
}
my $start=time();
my $max_rss=0;
while (1) {
    my $done=waitpid($pid,WNOHANG);
    if ($done==$pid) {
        if ($?) {
            print "CANONICAL_MEMO_CHECK_COMPLETE passed=0 blocked=0 failed=1 exit=$?\n";
            exit 2;
        }
        print "CANONICAL_MEMO_CHECK_COMPLETE passed=1 blocked=0 failed=0\n";
        exit 0;
    }
    die "waitpid 失敗\n" if $done<0;
    my $rss=rss_of($pid);
    $max_rss=$rss if $rss>$max_rss;
    if ($rss>$rss_limit || time()-$start>$seconds) {
        my $reason=$rss>$rss_limit ? 'RSS_LIMIT' : 'TIME_LIMIT';
        kill 'KILL',$pid;
        waitpid($pid,0);
        printf "CANONICAL_MEMO status=BLOCKED reason=%s observed_peak_RSS_KiB=%d elapsed_sec=%.3f\n",
            $reason,$max_rss,time()-$start;
        print "CANONICAL_MEMO_CHECK_COMPLETE passed=0 blocked=1 failed=0\n";
        exit 3;
    }
    sleep(0.05);
}
