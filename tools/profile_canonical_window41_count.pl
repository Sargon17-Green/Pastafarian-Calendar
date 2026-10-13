#!/usr/bin/env perl
use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use Math::BigInt;
use Time::HiRes qw(time sleep);
use POSIX qw(WNOHANG);
use Getopt::Long qw(GetOptions);
use lib 'lib','t/lib';
use Pastafari::WeavingFrontierOracle qw(countWeavingsFrontier);
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::WeavingPolynomialStream qw(countWeavingsPolynomialStream);
use Pastafari::WeavingUnrank qw(unrankWeavingPolynomial);
use Pastafari::WeavingRank qw(rankWeavingPolynomial);

# 真實 5000 年第 42..45 月之四個連續月份，四月合計 402 日。
# 前沿獨立狀態 Oracle 只驗證總數；中位排名的雙向還原不是
# 另一個獨立的全字典序預言機。邊界詞另有獨立貪婪構造。
my ($seconds,$rss_kib)=(185,393216);
GetOptions('seconds=i'=>\$seconds,'rss-kib=i'=>\$rss_kib)
    or die "參數無效\n";
die "seconds 必須在 1..230 範圍\n"
    if $seconds<1 || $seconds>230;
die "rss-kib 必須在 32768..1048576 範圍\n"
    if $rss_kib<32768 || $rss_kib>1048576;
die "本工具需 Linux /proc\n" if !-r '/proc/self/status';
$|=1;

sub current_rss ($pid) {
    open my $fh,'<',"/proc/$pid/status" or return 0;
    while (my $line=<$fh>) {
        return 0+$1 if $line =~ /^VmRSS:\s*(\d+)\s+kB/;
    }
    return 0;
}
sub peak_kib () {
    open my $fh,'<','/proc/self/status' or die "不能讀取 VmHWM\n";
    while (my $line=<$fh>) {
        return 0+$1 if $line =~ /^VmHWM:\s*(\d+)\s+kB/;
    }
    die "找不到 VmHWM\n";
}
sub verify_word ($L,$word) {
    my @counts=(0)x@$L;
    my (%first,%last);
    for my $i (0..$#$word) {
        my $j=$word->[$i];
        die "解碼標籤不在四月的合法集合\n" if $j<1 || $j>@$L;
        $counts[$j-1]++;
        $first{$j}//=$i;
        $last{$j}=$i;
    }
    for my $i (0..$#$L) {
        die "解碼月長與規範選擇器不符\n" if $counts[$i]!=$L->[$i];
    }
    for my $j (2..@$L) {
        die "首次與末次出現的順序違反規範\n"
            if $first{$j}<=$first{$j-1} || $last{$j}<=$last{$j-1};
    }
}
my $pid=fork();
die "無法 fork 受控子程序：$!\n" if !defined $pid;
if (!$pid) {
    my $ok=eval {
        my $start=time();
        my @year=(
            115,108,119,109,106,81,115,114,117,120,98,52,81,97,121,
            97,115,96,107,61,106,115,119,39,84,103,115,107,55,119,
            97,50,122,110,81,54,101,83,88,40,77,98,122,105,105
        );
        die "5000 年原生月長 SHA-256 不符\n"
            if sha256_hex(join(',',@year)) ne
                '6d64022344c04935e6423aa6f96b285098d35b9b5ecb4b8c57a4c7149773a134';
        my @L=@year[41..44];
        die "原生四月序列不是 77,98,122,105\n"
            if join(',',@L) ne '77,98,122,105';
        my $days=0;
        $days+=$_ for @L;
        die "四個真實月份並非 402 日\n" if $days!=402;
        print "CANONICAL_WINDOW41 phase=INPUT offset=40 months=4 days=402 lengths=77,98,122,105\n";
        my %frontier_stats;
        my $oracle=countWeavingsFrontier(\@L,\%frontier_stats);
        printf "CANONICAL_WINDOW41 phase=ORACLE_COUNT status=PASS digits=%d states=%d max_frontier=%d elapsed_sec=%.3f\n",
            length("$oracle"),$frontier_stats{states},
            $frontier_stats{frontier_peak},time()-$start;
        my $resident=countWeavingsPolynomial(\@L);
        die "402 日位置多項式總數與獨立前沿不符\n"
            if $resident!=$oracle;
        my %stream_stats;
        my $stream=countWeavingsPolynomialStream(
            \@L,\%stream_stats,undef,{max_temp_file_bytes=>16*1024*1024}
        );
        die "402 日磁碟串流總數與獨立前沿不符\n"
            if $stream!=$oracle;
        printf "CANONICAL_WINDOW41 phase=THREE_COUNTS_PASS stream_rows=%d elapsed_sec=%.3f\n",
            $stream_stats{rows_serialized},time()-$start;

        my @direct_first;
        for my $m (1..@L) {
            push @direct_first,(($m)x$L[$m-1]);
        }
        my @rem=@L;
        my ($opened,$closed)=(0,0);
        my @direct_last;
        for my $step (1..$days) {
            my $max=$opened<@L ? $opened+1 : scalar(@L);
            my $j;
            for (my $candidate=$max;$candidate>=1;$candidate--) {
                next if !$rem[$candidate-1];
                next if $rem[$candidate-1]==1 && $candidate!=$closed+1;
                $j=$candidate;
                last;
            }
            die "無法建構獨立最大合法字序\n" if !defined $j;
            push @direct_last,$j;
            $opened=$j if $j>$opened;
            --$rem[$j-1];
            $closed=$j if !$rem[$j-1];
        }
        my $first=unrankWeavingPolynomial(\@L,1);
        my $last=unrankWeavingPolynomial(\@L,$oracle);
        die "最初字序與無 DP 連續區塊不同\n"
            if join(',',@$first) ne join(',',@direct_first);
        die "最後字序與無 DP 貪婪結果不同\n"
            if join(',',@$last) ne join(',',@direct_last);
        verify_word(\@L,$first);
        verify_word(\@L,$last);
        printf "CANONICAL_WINDOW41 phase=BOUNDARY_ORDERS_PASS elapsed_sec=%.3f\n",time()-$start;

        my $middle=$oracle->copy->bdiv(2)->badd(1);
        die "中間一基 BigInt 排名不是內部排名\n"
            if $middle<=1 || $middle>=$oracle;
        my $wanted="$middle";
        my %unrank_stats;
        my $word=unrankWeavingPolynomial(
            \@L,$middle,\%unrank_stats,
            {profile_engine=>'stream-indexed',max_temp_file_bytes=>16*1024*1024}
        );
        verify_word(\@L,$word);
        die "索引式解碼未建立實際私人索引\n"
            if ($unrank_stats{indexed_profile_builds}//0)!=1;
        my %rank_stats;
        my $back=rankWeavingPolynomial(
            \@L,$word,\%rank_stats,
            {profile_engine=>'stream-indexed',max_temp_file_bytes=>16*1024*1024}
        );
        die "中間一基 BigInt 排名不能完整還原\n" if "$back" ne $wanted;
        die "索引式正向排名未建立自己的索引\n"
            if ($rank_stats{indexed_profile_builds}//0)!=1;
        die "原始中間 BigInt 被不當修改\n" if "$middle" ne $wanted;
        printf "CANONICAL_WINDOW41 status=PASS scope=INDEPENDENT_TOTAL_BOUNDARY_AND_MIDDLE_ROUNDTRIP days=402 months=4 total_digits=%d rank_digits=%d frontier_states=%d max_frontier=%d elapsed_sec=%.3f VmHWM_KiB=%d\n",
            length("$oracle"),length($wanted),$frontier_stats{states},
            $frontier_stats{frontier_peak},time()-$start,peak_kib();
        1;
    };
    if (!$ok) {
        print STDERR "CANONICAL_WINDOW41 status=FAIL reason=$@\n";
        exit 2;
    }
    exit 0;
}
my $start=time();
my $peak=0;
while (1) {
    my $done=waitpid($pid,WNOHANG);
    if ($done==$pid) {
        if ($?) {
            print "CANONICAL_WINDOW41_CHECK_COMPLETE passed=0 blocked=0 failed=1 status=$?\n";
            exit 2;
        }
        print "CANONICAL_WINDOW41_CHECK_COMPLETE passed=1 blocked=0 failed=0\n";
        exit 0;
    }
    die "waitpid 失敗\n" if $done<0;
    my $rss=current_rss($pid);
    $peak=$rss if $rss>$peak;
    if ($rss>$rss_kib || time()-$start>$seconds) {
        my $why=$rss>$rss_kib ? 'RSS_LIMIT' : 'TIME_LIMIT';
        kill 'KILL',$pid;
        waitpid($pid,0);
        printf "CANONICAL_WINDOW41 status=BLOCKED reason=%s elapsed_sec=%.3f peak_RSS_KiB=%d\n",
            $why,time()-$start,$peak;
        print "CANONICAL_WINDOW41_CHECK_COMPLETE passed=0 blocked=1 failed=0\n";
        exit 3;
    }
    sleep(0.05);
}
