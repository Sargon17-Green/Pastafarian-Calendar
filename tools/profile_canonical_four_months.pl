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
use Pastafari::NormativeScroll qw(countWeavings unrankWeaving);
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::WeavingPolynomialStream qw(countWeavingsPolynomialStream);
use Pastafari::WeavingUnrank qw(unrankWeavingPolynomial);
use Pastafari::WeavingRank qw(rankWeavingPolynomial);

# 只檢驗真實年份相鄰四個月的局部精確排名；並非整年度排名。
# 相鄰 40、25、77、98 日位於實測 5000 年末段。
my ($seconds,$rss_kib)=(185,393216);
GetOptions('seconds=i'=>\$seconds,'rss-kib=i'=>\$rss_kib)
    or die "參數格式無效\n";
die "秒數必須在 1..230 範圍內\n"
    if $seconds<1 || $seconds>230;
die "RSS 必須在 32768..1048576 KiB\n"
    if $rss_kib<32768 || $rss_kib>1048576;
die "需要 Linux /proc 原生行程觀測\n"
    if !-r '/proc/self/status';
$|=1;

sub rss_kib ($pid) {
    open my $fh,'<',"/proc/$pid/status" or return 0;
    while(my $line=<$fh>) {
        return 0+$1 if $line =~ /^VmRSS:\s*(\d+)\s+kB/;
    }
    return 0;
}
sub own_highwater () {
    open my $fh,'<','/proc/self/status' or die "不能讀取 VmHWM\n";
    while(my $line=<$fh>) {
        return 0+$1 if $line =~ /^VmHWM:\s*(\d+)\s+kB/;
    }
    die "不能取得 VmHWM\n";
}
sub verify_word ($lengths,$word) {
    my @count=(0)x@$lengths;
    my (%first,%last);
    for my $i (0..$#$word) {
        my $j=$word->[$i];
        die "解碼標籤超出範圍\n" if $j<1 || $j>@$lengths;
        $count[$j-1]++;
        $first{$j}//=$i;
        $last{$j}=$i;
    }
    for my $i (0..$#$lengths) {
        die "解碼月份長度不符\n" if $count[$i]!=$lengths->[$i];
    }
    for my $j (2..@$lengths) {
        die "首次／末次順序不符\n"
            if $first{$j}<=$first{$j-1} || $last{$j}<=$last{$j-1};
    }
}
my $child=fork();
die "不能啟動受控子程序：$!\n" if !defined($child);
if ($child==0) {
    my $ok=eval {
        my $start=time();
        my @year=(
            115,108,119,109,106,81,115,114,117,120,98,52,81,97,121,
            97,115,96,107,61,106,115,119,39,84,103,115,107,55,119,
            97,50,122,110,81,54,101,83,88,40,25,77,98,122,105
        );
        die "規範年份長度快照摘要已變\n"
            unless sha256_hex(join(',',@year)) eq
                '6d64022344c04935e6423aa6f96b285098d35b9b5ecb4b8c57a4c7149773a134';
        my @L=@year[39..42];
        die "真實四月份快照不符\n"
            unless join(',',@L) eq '40,25,77,98';
        printf "CANONICAL_FOUR phase=INPUT months=4 days=%d lengths=%s\n",
            0+do{my $x=0;$x+=$_ for @L;$x},join(',',@L);
        my %oracle_stats;
        my $oracle_total=countWeavings(\@L,\%oracle_stats);
        printf "CANONICAL_FOUR phase=ORACLE_COUNT total_digits=%d states=%d peak_stack=%d elapsed_sec=%.3f\n",
            length("$oracle_total"),$oracle_stats{states}//0,
            $oracle_stats{max_stack}//0,time()-$start;
        my $poly_total=countWeavingsPolynomial(\@L);
        die "四月份多項式總數和獨立規範計數不相等\n"
            if $poly_total!=$oracle_total;
        my %stream_stats;
        my $stream_total=countWeavingsPolynomialStream(
            \@L,\%stream_stats,undef,{max_temp_file_bytes=>16*1024*1024}
        );
        die "四月份磁碟串流總數和獨立規範計數不相等\n"
            if $stream_total!=$oracle_total;
        printf "CANONICAL_FOUR phase=THREE_COUNTS_PASS stream_rows=%d elapsed_sec=%.3f\n",
            $stream_stats{rows_serialized}//0,time()-$start;
        my $middle=$oracle_total->copy->bdiv(2)->badd(1);
        die "四月份中間一基排名不是有效內部排名\n"
            if $middle<=1 || $middle>=$oracle_total;
        my $wanted="$middle";
        my $norm_word=unrankWeaving(\@L,$middle);
        verify_word(\@L,$norm_word);
        printf "CANONICAL_FOUR phase=ORACLE_UNRANK_PASS rank_digits=%d elapsed_sec=%.3f\n",
            length($wanted),time()-$start;
        my %decode;
        my $actual=unrankWeavingPolynomial(\@L,$middle,\%decode,
            {profile_engine=>'stream-indexed',
             max_temp_file_bytes=>16*1024*1024});
        die "四月份索引反排名和獨立規範字典序不符\n"
            if join(',',@$actual) ne join(',',@$norm_word);
        verify_word(\@L,$actual);
        die "四月份未啟動索引式反排名引擎\n"
            if ($decode{indexed_profile_builds}//0)!=1;
        printf "CANONICAL_FOUR phase=INDEXED_UNRANK_PASS suffix_calls=%d elapsed_sec=%.3f\n",
            $decode{suffix_calls}//0,time()-$start;
        my %rank_stats;
        my $reconstructed=rankWeavingPolynomial(\@L,$actual,\%rank_stats,
            {profile_engine=>'stream-indexed',
             max_temp_file_bytes=>16*1024*1024});
        die "四月份索引式正向排名無法還原原始 BigInt\n"
            if "$reconstructed" ne $wanted;
        die "四月份未啟動獨立的索引式正向排名\n"
            if ($rank_stats{indexed_profile_builds}//0)!=1;
        die "輸入中間排名已受可變性污染\n"
            if "$middle" ne $wanted;
        printf "CANONICAL_FOUR status=PASS months=4 days=240 rank_digits=%d rank_smaller_candidates=%d elapsed_sec=%.3f VmHWM_KiB=%d\n",
            length($wanted),$rank_stats{candidates}//0,time()-$start,
            own_highwater();
        1;
    };
    if(!$ok) {
        print STDERR "CANONICAL_FOUR status=FAIL reason=$@\n";
        exit 2;
    }
    exit 0;
}
my $start=time();
my $peak=0;
while (1) {
    my $done=waitpid($child,WNOHANG);
    if ($done==$child) {
        if($?) {
            printf STDERR "CANONICAL_FOUR_CHECK_COMPLETE passed=0 blocked=0 failed=1 child_status=%d\n",$?;
            exit 2;
        }
        print "CANONICAL_FOUR_CHECK_COMPLETE passed=1 blocked=0 failed=0\n";
        exit 0;
    }
    die "父程序 waitpid 失敗\n" if $done<0;
    my $rss=rss_kib($child);
    $peak=$rss if $rss>$peak;
    if ($rss>$rss_kib || time()-$start>$seconds) {
        my $reason=$rss>$rss_kib ? 'RSS_LIMIT' : 'TIME_LIMIT';
        kill 'KILL',$child;
        waitpid($child,0);
        printf "CANONICAL_FOUR status=BLOCKED reason=%s elapsed_sec=%.3f observed_peak_RSS_KiB=%d\n",
            $reason,time()-$start,$peak;
        print "CANONICAL_FOUR_CHECK_COMPLETE passed=0 blocked=1 failed=0\n";
        exit 3;
    }
    sleep(0.05);
}
