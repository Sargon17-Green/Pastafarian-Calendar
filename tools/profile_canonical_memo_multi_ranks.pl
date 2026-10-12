#!/usr/bin/env perl
use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Math::BigInt;
use Digest::SHA qw(sha256_hex);
use Time::HiRes qw(time sleep);
use POSIX qw(WNOHANG);
use Getopt::Long qw(GetOptions);
use lib 'lib','t/lib';
use Pastafari::WeavingMemoOracle;
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::WeavingUnrank qw(unrankWeavingPolynomial);
use Pastafari::WeavingRank qw(rankWeavingPolynomial);

# 真正年份固定四個相鄰月份 240 日，精確多個大整數一基排名。
# 使用一份與受測排名器完全分離的記憶式狀態計數快取，並
# 每次以新索引計數實際跑正反向排名；且有父進程資源守衛。
my ($seconds,$rss_limit)=(185,393216);
GetOptions('seconds=i'=>\$seconds,'rss-kib=i'=>\$rss_limit)
    or die "參數格式錯誤\n";
die "second 必須在 1..230\n" if $seconds<1 || $seconds>230;
die "rss-kib 必須在 32768..1048576\n"
    if $rss_limit<32768 || $rss_limit>1048576;
die "需要 Linux /proc\n" if !-r '/proc/self/status';
$|=1;

sub get_rss ($pid) {
    open my $fh,'<',"/proc/$pid/status" or return 0;
    while(my $line=<$fh>) {
        return 0+$1 if $line =~ /^VmRSS:\s*(\d+)\s+kB/;
    }
    return 0;
}
sub peak_self () {
    open my $fh,'<','/proc/self/status' or die "不能讀取 /proc/self/status\n";
    while(my $line=<$fh>) {
        return 0+$1 if $line =~ /^VmHWM:\s*(\d+)\s+kB/;
    }
    die "不能取得 VmHWM\n";
}
my $pid=fork();
die "無法啟動驗證子程序\n" if !defined $pid;
if (!$pid) {
    my $ok=eval {
        my $start=time();
        my @year=(
            115,108,119,109,106,81,115,114,117,120,98,52,81,97,121,
            97,115,96,107,61,106,115,119,39,84,103,115,107,55,119,
            97,50,122,110,81,54,101,83,88,40,25,77,98,122,105
        );
        die "原生年份月份快照雜湊不符\n"
            if sha256_hex(join(',',@year)) ne
                '6d64022344c04935e6423aa6f96b285098d35b9b5ecb4b8c57a4c7149773a134';
        my @L=@year[39..42];
        die "固定真正月份向量不符\n"
            if join(',',@L) ne '40,25,77,98';
        my $counter=Pastafari::WeavingMemoOracle->new(\@L);
        my $total=$counter->count_prefix([]);
        my $poly=countWeavingsPolynomial(\@L);
        die "記憶式和不同位置多項式算法的總數不符\n"
            if $total!=$poly;

        my @named=(
            ['first',Math::BigInt->bone],
            ['second',Math::BigInt->new(2)],
            ['third',Math::BigInt->new(3)],
            ['fourth',Math::BigInt->new(4)],
            ['p10',$total->copy->bdiv(10)],
            ['p25',$total->copy->bdiv(4)],
            ['pre_middle',$total->copy->bdiv(2)],
            ['middle',$total->copy->bdiv(2)->badd(1)],
            ['p75',$total->copy->bmul(3)->bdiv(4)],
            ['p90',$total->copy->bmul(9)->bdiv(10)],
            ['near_last3',$total->copy->bsub(3)],
            ['near_last2',$total->copy->bsub(2)],
            ['near_last1',$total->copy->bsub(1)],
            ['last',$total->copy],
        );
        my $test_count=0;
        for my $case (@named) {
            my ($label,$rank)=@$case;
            my $rank_text="$rank";
            die "樣本 $label 的 BigInt 排名無效\n"
                if $rank<1 || $rank>$total;
            my %decoded_stats;
            my $word=unrankWeavingPolynomial(
                \@L,$rank,\%decoded_stats,
                {profile_engine=>'stream-indexed',
                 max_temp_file_bytes=>16*1024*1024}
            );
            die "$label 字序不是完整 240 日\n" if @$word!=240;
            my %rank_stats;
            my $back=rankWeavingPolynomial(
                \@L,$word,\%rank_stats,
                {profile_engine=>'stream-indexed',
                 max_temp_file_bytes=>16*1024*1024}
            );
            die "$label 反向 BigInt 排名與輸入不符\n"
                if "$back" ne $rank_text;
            my @prefix;
            my @remaining=@L;
            my ($opened,$closed)=(0,0);
            my $local=$rank->copy;
            for my $day (1..240) {
                my $parent=$counter->count_prefix(\@prefix);
                die "$label/$day 局部 BigInt 名次超出母區段\n"
                    if $local<1 || $local>$parent;
                my $upper=$opened<@L ? $opened+1 : scalar(@L);
                my @valid=grep {
                    $remaining[$_-1]>0
                    && ($remaining[$_-1]!=1 || $_==$closed+1)
                } 1..$upper;
                die "$label/$day 沒有合法下一符號\n"
                    if !@valid;
                my $sum=Math::BigInt->bzero;
                my $chosen;
                for my $j (@valid) {
                    my @candidate=(@prefix,$j);
                    my $size=$counter->count_prefix(\@candidate);
                    $sum->badd($size);
                    if (!defined $chosen) {
                        if ($local<=$size) {
                            $chosen=$j;
                        } else {
                            $local->bsub($size);
                        }
                    }
                }
                die "$label/$day 所有合法分支不構成精確分割\n"
                    if $sum!=$parent;
                die "$label/$day 的獨立 BigInt 字典序與索引排名器矛盾\n"
                    if !defined($chosen) || $chosen!=$word->[$day-1];
                push @prefix,$chosen;
                $opened=$chosen if $chosen>$opened;
                --$remaining[$chosen-1];
                $closed=$chosen if !$remaining[$chosen-1];
            }
            die "$label 完整字序後月長仍未歸零\n"
                if grep {$_!=0} @remaining;
            die "$label 完成 240 日後局部排名不是 1\n" if $local!=1;
            die "$label 輸入 BigInt 排名被污染\n"
                if "$rank" ne $rank_text;
            $test_count++;
            my $diag=$counter->diagnostics;
            printf "CANONICAL_MULTI_RANK status=PASS case=%s index=%d digits=%d checked_days=240 memo_entries=%d memo_hits=%d elapsed_sec=%.3f\n",
                $label,$test_count,length($rank_text),
                $diag->{entries},$diag->{cache_hits},time()-$start;
        }
        die "14 種固定且重要的字典序邊界排名未全部執行\n"
            if $test_count!=14;
        my $diag=$counter->diagnostics;
        printf "CANONICAL_MULTI_RANK status=PASS scope=14_DISTINCT_REAL_240_DAY_RANKS cases=%d days_per_rank=240 total_digits=%d memo_entries=%d memo_hits=%d elapsed_sec=%.3f VmHWM_KiB=%d\n",
            $test_count,length("$total"),$diag->{entries},
            $diag->{cache_hits},time()-$start,peak_self();
        1;
    };
    if (!$ok) {
        print STDERR "CANONICAL_MULTI_RANK status=FAIL reason=$@\n";
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
            print "CANONICAL_MULTI_RANK_CHECK_COMPLETE passed=0 blocked=0 failed=1 exit=$?\n";
            exit 2;
        }
        print "CANONICAL_MULTI_RANK_CHECK_COMPLETE passed=1 blocked=0 failed=0\n";
        exit 0;
    }
    die "waitpid 失敗\n" if $done<0;
    my $rss=get_rss($pid);
    $max_rss=$rss if $rss>$max_rss;
    if ($rss>$rss_limit || time()-$start>$seconds) {
        my $reason=$rss>$rss_limit ? 'RSS_LIMIT' : 'TIME_LIMIT';
        kill 'KILL',$pid;
        waitpid($pid,0);
        printf "CANONICAL_MULTI_RANK status=BLOCKED reason=%s elapsed_sec=%.3f observed_peak_RSS_KiB=%d\n",
            $reason,time()-$start,$max_rss;
        print "CANONICAL_MULTI_RANK_CHECK_COMPLETE passed=0 blocked=1 failed=0\n";
        exit 3;
    }
    sleep(0.05);
}
