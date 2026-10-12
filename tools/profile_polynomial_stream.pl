#!/usr/bin/env perl
use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use POSIX qw(WNOHANG);
use Time::HiRes qw(time sleep);
use Math::BigInt;
use Digest::SHA qw(sha256_hex);
use Getopt::Long qw(GetOptions);
use lib 'lib','t/lib';
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::WeavingPolynomialStream qw(countWeavingsPolynomialStream);

# 第 1 階段選用的同機資源比較。各模型在自己的子程序中
# 重新執行；經完整 SHA-256 十六進位摘要核對精確 BigInt。
# 沒有完成的案例只報 BLOCKED，不得冒稱通過。
my ($seconds,$rss_limit,$disk_limit)=(40,262144,268435456);
GetOptions('seconds=i'=>\$seconds,'rss-kib=i'=>\$rss_limit,
           'temp-file-bytes=i'=>\$disk_limit)
    or die "命令列參數錯誤\n";
die "秒數須介於 1..90\n" if $seconds<1 || $seconds>90;
die "RSS 限額須介於 32768..1048576 KiB\n"
    if $rss_limit<32768 || $rss_limit>1048576;
die "暫存檔限額須介於 1024..1073741824 位元組\n"
    if $disk_limit<1024 || $disk_limit>1_073_741_824;
die "需有 Linux /proc\n" if !-r '/proc/self/status';
$|=1;

sub read_rss ($pid) {
    open my $fh,'<',"/proc/$pid/status" or return 0;
    while (my $line=<$fh>) {
        return 0+$1 if $line =~ /^VmRSS:\s*(\d+)\s+kB/;
    }
    return 0;
}
sub read_hwm () {
    open my $fh,'<','/proc/self/status' or die "無法讀取 VmHWM\n";
    while (my $line=<$fh>) {
        return 0+$1 if $line =~ /^VmHWM:\s*(\d+)\s+kB/;
    }
    die "缺少 VmHWM\n";
}
sub run_case ($label,$sizes,$mode) {
    pipe(my $reader,my $writer) or die "無法建立子程序摘要管道\n";
    my $pid=fork();
    die "fork 失敗：$!\n" if !defined $pid;
    if ($pid==0) {
        close $reader;
        my $success=eval {
            my $start=time();
            my %metrics;
            my $result=$mode eq 'disk'
               ? countWeavingsPolynomialStream(
                    $sizes,\%metrics,undef,
                    {max_temp_file_bytes=>$disk_limit})
               : countWeavingsPolynomial($sizes,\%metrics);
            my $digits=length("$result");
            my $digest=sha256_hex("$result");
            printf $writer "%d|%s|%.3f|%d|%d|%d\n",
                $digits,$digest,time()-$start,read_hwm(),
                ($metrics{max_temp_file_bytes}//0),
                ($metrics{rows_serialized}//0);
            close $writer;
            1;
        };
        if (!$success) {
            print STDERR "COMPARE label=$label mode=$mode status=FAIL reason=$@\n";
            exit 2;
        }
        exit 0;
    }
    close $writer;
    my ($start,$peak,$status)=(time(),0,undef);
    while (1) {
        my $done=waitpid($pid,WNOHANG);
        if ($done==$pid) { $status=$?;last; }
        die "waitpid 失敗\n" if $done<0;
        my $rss=read_rss($pid);
        $peak=$rss if $rss>$peak;
        if ($rss>$rss_limit || time()-$start>$seconds) {
            my $cause=$rss>$rss_limit ? 'RSS_LIMIT' : 'TIME_LIMIT';
            kill 'KILL',$pid;
            waitpid($pid,0);
            close $reader;
            printf "COMPARE label=%s mode=%s status=BLOCKED reason=%s elapsed=%.3fs observed_RSS_KiB=%d\n",
                $label,$mode,$cause,time()-$start,$peak;
            return undef;
        }
        sleep(0.025);
    }
    my $payload=<$reader>;
    close $reader;
    die "COMPARE label=$label mode=$mode status=FAIL exit=$status\n"
        if $status!=0 || !defined $payload;
    chomp $payload;
    my ($digits,$digest,$seconds,$peak_hwm,$temp_bytes,$rows)=split /\|/,$payload;
    die "子程序摘要格式錯誤\n"
        if !defined($digest) || $digest!~/\A[0-9a-f]{64}\z/;
    printf "COMPARE label=%s mode=%s status=PASS digits=%d digest=%s wall=%ss VmHWM_KiB=%d temp_file_bytes=%d rows_serialized=%d\n",
        $label,$mode,$digits,$digest,$seconds,$peak_hwm,$temp_bytes,$rows;
    return "$digits|$digest";
}
my @cases=(
    ['47x4',[(4)x47]],
    ['47x252',[(6)x17,(5)x30]],
);
my ($paired,$blocked)=(0,0);
for my $case (@cases) {
    my ($label,$sizes)=@$case;
    my $resident=run_case($label,$sizes,'resident');
    my $stream=run_case($label,$sizes,'disk');
    if (defined($resident) && defined($stream)) {
        die "PAIR label=$label status=FAIL digest_mismatch\n"
            if $resident ne $stream;
        print "PAIR label=$label status=PASS exact_bigint_sha256_equal=1\n";
        $paired++;
    } else {
        print "PAIR label=$label status=BLOCKED exact_bigint_not_comparable=1\n";
        $blocked++;
    }
}
print "STREAM_MEASUREMENT_COMPLETE paired=$paired blocked=$blocked failed=0\n";
