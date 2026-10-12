#!/usr/bin/env perl
use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Math::BigInt;
use Time::HiRes qw(time sleep);
use POSIX qw(WNOHANG);
use Getopt::Long qw(GetOptions);
use lib 'lib','t/lib';
use Pastafari::WeavingUnrank qw(unrankWeavingPolynomial);
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::NormativeScroll qw(unrankWeaving);

# 受限、前台、獨立子程序的「非極端排名」研究工具。
# BLOCKED 是資源限制下未完成，不能混同於 PASS。
my ($seconds,$rss_limit_kib)=(20,196608);
GetOptions('seconds=i'=>\$seconds,'rss-kib=i'=>\$rss_limit_kib)
    or die "稽核工具參數錯誤\n";
die "時間限額須在 1..90 秒\n" if $seconds < 1 || $seconds > 90;
die "RSS 限額須在 32768..1048576 KiB\n"
    if $rss_limit_kib < 32768 || $rss_limit_kib > 1048576;
die "需要 Linux /proc\n" if !-r '/proc/self/status';
$|=1;

sub rss_kib ($pid) {
    open my $fh,'<',"/proc/$pid/status" or return 0;
    while (my $line=<$fh>) {
        return 0+$1 if $line =~ /^VmRSS:\s*(\d+)\s+kB/;
    }
    return 0;
}
sub highwater_kib () {
    open my $fh,'<','/proc/self/status' or die "無法讀取 VmHWM\n";
    while (my $line=<$fh>) {
        return 0+$1 if $line =~ /^VmHWM:\s*(\d+)\s+kB/;
    }
    die "缺少 VmHWM\n";
}
sub verify_word ($lengths, $word) {
    my $m=scalar @$lengths;
    my $days=0;$days+=$_ for @$lengths;
    die "反排名日數錯誤\n" if @$word != $days;
    my (@count,@first,@last);
    for my $pos (0 .. $#$word) {
        my $j=$word->[$pos];
        die "月份標籤非法\n" if $j<1 || $j>$m;
        $count[$j]++;$first[$j] //= $pos;$last[$j]=$pos;
    }
    for my $j (1 .. $m) {
        die "月份日數錯誤\n" if ($count[$j] // 0)!=$lengths->[$j-1];
        if ($j>1) {
            die "月份首次順序錯誤\n" if $first[$j-1]>=$first[$j];
            die "月份末次順序錯誤\n" if $last[$j-1]>=$last[$j];
        }
    }
}
my @cases=(
    { label=>'4x4-baseline',lengths=>[(4)x4],required=>1,oracle=>1 },
    { label=>'6x4-growth',lengths=>[(4)x6],required=>0,oracle=>1 },
    { label=>'8x4-growth',lengths=>[(4)x8],required=>0,oracle=>0 },
    { label=>'47x4-middle',lengths=>[(4)x47],required=>0,oracle=>0 },
    { label=>'47x252-middle',lengths=>[(6)x17,(5)x30],required=>0,oracle=>0 },
);
my ($finished,$blocked)=(0,0);
for my $case (@cases) {
    my $pid=fork();
    die "無法 fork：$!\n" if !defined($pid);
    if ($pid==0) {
        my $ok=eval {
            my $start=time();
            my $total=countWeavingsPolynomial($case->{lengths});
            my $rank=$total->copy->bdiv(2)->badd(1);
            die "預期為中間排名\n" if $rank<=1 || $rank>=$total;
            my %stats;
            my $word=unrankWeavingPolynomial($case->{lengths},$rank,\%stats);
            verify_word($case->{lengths},$word);
            if ($case->{oracle}) {
                my $expected=unrankWeaving($case->{lengths},$rank);
                die "原始規範 Oracle 的字典序結果不一致\n"
                    if "@$expected" ne "@$word";
            }
            printf "CASE label=%s status=PASS days=%d rank_digits=%d wall=%.3fs VmHWM_KiB=%d suffix_calls=%d considered=%d shortcut_steps=%d tail_days=%d tail_kind=%d future_hits=%d future_misses=%d reverse_profile_builds=%d\n",
                $case->{label},scalar(@$word),length("$rank"),time()-$start,
                highwater_kib(),@stats{qw(suffix_calls considered shortcut_steps tail_shortcut_days tail_shortcut_kind future_cache_hits future_cache_misses reverse_histogram_builds)};
            1;
        };
        if (!$ok) {
            print STDERR "CASE label=$case->{label} status=FAIL reason=$@\n";
            exit 2;
        }
        exit 0;
    }
    my ($begin,$peak,$status)=(time(),0,undef);
    while (1) {
        my $done=waitpid($pid,WNOHANG);
        if ($done==$pid) {$status=$?;last}
        die "waitpid 失敗\n" if $done<0;
        my $rss=rss_kib($pid);
        $peak=$rss if $rss>$peak;
        if ($rss>$rss_limit_kib || time()-$begin>$seconds) {
            my $reason=$rss>$rss_limit_kib?'RSS_LIMIT':'TIME_LIMIT';
            kill 'KILL',$pid;
            waitpid($pid,0);
            printf "CASE label=%s status=BLOCKED reason=%s elapsed=%.3fs observed_RSS_KiB=%d\n",
                $case->{label},$reason,time()-$begin,$peak;
            die "必須通過的基準案例超限\n" if $case->{required};
            $blocked++;
            $status=-1;
            last;
        }
        sleep(0.025);
    }
    next if $status==-1;
    die "子程序失敗：$case->{label} code=$status\n" if $status!=0;
    $finished++;
}
print "MEASUREMENT_COMPLETE passed=$finished blocked=$blocked failed=0 (BLOCKED 不代表演算法正確性已驗證)\n";
