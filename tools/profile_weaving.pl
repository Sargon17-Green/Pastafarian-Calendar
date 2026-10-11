#!/usr/bin/env perl
use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Time::HiRes qw(time sleep);
use POSIX qw(WNOHANG);
use Getopt::Long qw(GetOptions);
use lib 'lib', 't/lib';
use Pastafari::NormativeScroll qw(countWeavings unrankWeaving);

# Linux 資源量測器：每個案例在獨立子程序執行。
# RSS 採樣並非硬性記憶體限制；必須另加作業系統層級的上限。
my $profile = 'smoke';
my $seconds = 15;
my $rss_limit_kib = 262144;
GetOptions(
    'profile=s' => \$profile,
    'seconds=i' => \$seconds,
    'rss-kib=i' => \$rss_limit_kib,
) or die "量測參數不正確\n";
die "只支援 smoke 或 extended\n" if $profile ne 'smoke' && $profile ne 'extended';
die "秒數必須在 1..120\n" if $seconds < 1 || $seconds > 120;
die "RSS 限額必須在 32768..1048576 KiB\n"
    if $rss_limit_kib < 32768 || $rss_limit_kib > 1048576;
die "此量測器需使用 Linux /proc\n" if !-r '/proc/self/status';
$| = 1;

my @cases = ([4,4,4], [8,8,8], [4,123,4], [4,4,4,4]);
push @cases, [12,12,12], [24,24,24], [123,123,4]
    if $profile eq 'extended';

sub rss_kib ($pid) {
    open my $fh, '<', "/proc/$pid/status" or return 0;
    while (my $line = <$fh>) {
        return 0+$1 if $line =~ /^VmRSS:\s*(\d+)\s+kB/;
    }
    return 0;
}
sub peak_kib () {
    open my $fh, '<', '/proc/self/status' or die "無法讀取 VmHWM\n";
    while (my $line = <$fh>) {
        return 0+$1 if $line =~ /^VmHWM:\s*(\d+)\s+kB/;
    }
    die "無法取得記憶體高水位\n";
}
sub verify_word ($word, $lengths) {
    my $n = scalar @$lengths;
    my @occurs = (0) x $n;
    my (@first, @last);
    for my $i (0 .. $#$word) {
        my $id = $word->[$i];
        die "月份編號超出範圍\n" if $id < 1 || $id > $n;
        $first[$id] //= $i;
        $last[$id] = $i;
        $occurs[$id-1]++;
    }
    for my $id (1 .. $n) {
        die "月份日數不符\n" if $occurs[$id-1] != $lengths->[$id-1];
        if ($id > 1) {
            die "月份首次出現次序錯誤\n" if $first[$id-1] >= $first[$id];
            die "月份最後出現次序錯誤\n" if $last[$id-1] >= $last[$id];
        }
    }
    return 1;
}
sub run_child ($lengths) {
    my $label = join('-', @$lengths);
    my $start = time();
    my $count = countWeavings($lengths);
    die "交織計數不得為零\n" if $count < 1;
    my $first = unrankWeaving($lengths, 1);
    my $last = unrankWeaving($lengths, $count);
    verify_word($first, $lengths);
    verify_word($last, $lengths);
    my $total = 0;
    $total += $_ for @$lengths;
    die "交織日數不符\n" if @$first != $total || @$last != $total;
    my @lex_first;
    for my $j (0 .. $#$lengths) {
        push @lex_first, (($j+1) x $lengths->[$j]);
    }
    die "第一名不是最小字典序列\n"
        if join(',', @$first) ne join(',', @lex_first);
    printf "案例=%s 日數=%d 計數位數=%d 用時=%.3f秒 VmHWM=%dKiB 結果=PASS\n",
        $label, $total, length("$count"), time()-$start, peak_kib();
    return 1;
}

print "量測模式=$profile / 每例限時=$seconds 秒 / RSS觀測限額=$rss_limit_kib KiB\n";
for my $lengths (@cases) {
    my $label = join('-', @$lengths);
    my $pid = fork();
    die "無法啟動子程序：$!\n" if !defined $pid;
    if ($pid == 0) {
        my $ok = eval { run_child($lengths); 1 };
        if (!$ok) {
            print STDERR "案例 $label 失敗：$@\n";
            exit 2;
        }
        exit 0;
    }
    my $began = time();
    my ($max_observed, $status) = (0, undef);
    while (1) {
        my $done = waitpid($pid, WNOHANG);
        if ($done == $pid) { $status = $?; last }
        die "無法等待子程序\n" if $done < 0;
        my $rss = rss_kib($pid);
        $max_observed = $rss if $rss > $max_observed;
        if (time()-$began > $seconds || $rss > $rss_limit_kib) {
            my $reason = $rss > $rss_limit_kib ? 'RSS' : '時間';
            kill 'KILL', $pid;
            waitpid($pid, 0);
            die "案例 $label 超過 $reason 限額；子程序已停止。RSS觀測峰值=$max_observed KiB\n";
        }
        sleep(0.025);
    }
    die "案例 $label 子程序狀態=$status\n" if $status != 0;
    print "案例=$label 父程序觀測RSS峰值=$max_observed KiB\n";
}
print "案例通過。這不證明 47 個月份的極限需求可行。\n";
