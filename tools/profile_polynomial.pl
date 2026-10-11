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
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);

# 每個 47 月份案例是獨立子程序。所有輸入長度符合 4..123
# 的正式月份界限者另行標示；兩日月份只用於獨立 Catalan 數核對。
my $seconds = 90;
my $rss_limit_kib = 262144;
my $profile = 'baseline';
GetOptions('seconds=i' => \$seconds, 'rss-kib=i' => \$rss_limit_kib,
           'profile=s' => \$profile)
    or die "效能量測參數不正確\n";
die "秒數限額必須在 1..180\n" if $seconds < 1 || $seconds > 180;
die "RSS 必須在 32768..1048576 KiB\n"
    if $rss_limit_kib < 32768 || $rss_limit_kib > 1048576;
die "需要 Linux /proc\n" if !-r '/proc/self/status';
die "只支援 baseline 或 year-min\n"
    if $profile ne 'baseline' && $profile ne 'year-min';
$| = 1;

sub rss_kib ($pid) {
    open my $fh, '<', "/proc/$pid/status" or return 0;
    while (my $line = <$fh>) {
        return 0+$1 if $line =~ /^VmRSS:\s*(\d+)\s+kB/;
    }
    return 0;
}
sub peak_kib () {
    open my $fh, '<', '/proc/self/status' or die "無法取得 VmHWM\n";
    while (my $line = <$fh>) {
        return 0+$1 if $line =~ /^VmHWM:\s*(\d+)\s+kB/;
    }
    die "找不到 VmHWM\n";
}
sub independent_catalan ($n) {
    my $answer = Math::BigInt->bone;
    for my $i (1 .. $n) {
        $answer->bmul($n+$i)->bdiv($i);
    }
    return $answer->bdiv($n+1);
}
my @cases;
if ($profile eq 'baseline') {
    @cases = (
        { label=>'47x2-Catalan-非規範', lengths=>[(2)x47], catalan=>1 },
        { label=>'47x4-合法月份長度', lengths=>[(4)x47], catalan=>0 },
    );
} else {
    @cases = (
        { label=>'47-months-252-first-long', lengths=>[68,(4)x46], catalan=>0 },
        { label=>'47-months-252-last-long', lengths=>[(4)x46,68], catalan=>0 },
        { label=>'47-months-252-balanced', lengths=>[(6)x17,(5)x30], catalan=>0 },
    );
    die "年度下限案例總日數錯誤\n"
        if grep {
            my $sum=0; $sum += $_ for @{$_->{lengths}};
            $sum != 252 || @{$_->{lengths}} != 47;
        } @cases;
}
for my $case (@cases) {
    my $pid=fork();
    die "無法啟動量測子程序: $!\n" if !defined $pid;
    if ($pid==0) {
        my $ok=eval {
            my $t0=time();
            my %stats;
            my $answer=countWeavingsPolynomial($case->{lengths},\%stats);
            die "交織數量不是正整數\n" if $answer < 1;
            die "月份階段數不正確\n" if $stats{stages} != 46;
            if ($case->{catalan}) {
                die "Catalan 獨立公式不符\n"
                    if $answer != independent_catalan(47);
            }
            my $N=$stats{total_days};
            die "前緣狀態數超過二維範圍\n"
                if $stats{max_frontier} > ($N+1)*($N+1);
            printf "RESULT label=%s days=%d digits=%d sec=%.3f VmHWM_KiB=%d max_frontier=%d stages=%d PASS\n",
                $case->{label},$N,length("$answer"),time()-$t0,
                peak_kib(),$stats{max_frontier},$stats{stages};
            1;
        };
        if (!$ok) {
            print STDERR "CASE_ERROR $case->{label}: $@\n";
            exit 2;
        }
        exit 0;
    }
    my $t0=time();
    my ($observed,$status)=(0,undef);
    while (1) {
        my $done=waitpid($pid,WNOHANG);
        if($done==$pid){$status=$?;last}
        die "waitpid 失敗\n" if $done<0;
        my $rss=rss_kib($pid);
        $observed=$rss if $rss>$observed;
        if(time()-$t0>$seconds || $rss>$rss_limit_kib){
            my $reason=$rss>$rss_limit_kib?'RSS':'時間';
            kill 'KILL',$pid;waitpid($pid,0);
            die "LIMIT label=$case->{label} reason=$reason RSS_KiB=$observed\n";
        }
        sleep(0.025);
    }
    die "FAILED label=$case->{label} exit=$status\n" if $status!=0;
    print "OBSERVED label=$case->{label} RSS_KiB=$observed\n";
}
print "PASS: 兩組獨立 47 月份多項式計數量測完成；未驗證反排名。\n";
