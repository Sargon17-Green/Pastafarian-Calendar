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
use Pastafari::WeavingMemoOracle;

# Stage 1 R65: 四月份 1..9 全部 6561 個向量，按第一月分成
# 1..2 / 3..4 / 5..6 / 7..8 / 9 五份。各批保留相同限制。
# 用獨立合法後繼枚舉檢驗前三月已開、第四月未開的可達狀態。
# 舊版 DFS、FIFO 提前末次序閉式、CLOCK 提前末次序閉式
# 都必須逐一等於獨立原始合法字序遞迴，不靠被測後綴多項式。
my ($seconds,$rss_limit,$a_min,$a_max)=(185,393216,undef,undef);
my %expected=(
    '1-2'=>[1458,42282,226719],
    '3-4'=>[1458,88938,474579],
    '5-6'=>[1458,135594,722439],
    '7-8'=>[1458,182250,970299],
    '9-9'=>[729,108621,578097],
);
GetOptions('seconds=i'=>\$seconds,'rss-kib=i'=>\$rss_limit,
           'a-min=i'=>\$a_min,'a-max=i'=>\$a_max)
    or die "參數格式錯誤\n";
die "時間上限必須在 1..230 秒\n" if $seconds<1 || $seconds>230;
die "RSS 上限必須在 32768..1048576 KiB\n"
    if $rss_limit<32768 || $rss_limit>1048576;
die "需明確選擇已核對的 a-min/a-max，不能略過向量\n"
    if !defined($a_min) || !defined($a_max)
    || !exists($expected{"$a_min-$a_max"});
die "原生資源監督需要 Linux /proc\n" if !-r '/proc/self/status';
$|=1;

sub rss_kib ($pid) {
    open my $fh,'<',"/proc/$pid/status" or return 0;
    while (my $line=<$fh>) {
        return 0+$1 if $line =~ /^VmRSS:\s*(\d+)\s+kB/;
    }
    return 0;
}
sub peak_kib () {
    open my $fh,'<','/proc/self/status'
        or die "無法取得自身 VmHWM\n";
    while (my $line=<$fh>) {
        return 0+$1 if $line =~ /^VmHWM:\s*(\d+)\s+kB/;
    }
    die "VmHWM 不存在\n";
}

my $pid=fork();
die "無法建立獨立 QA 子程序\n" if !defined($pid);
if (!$pid) {
    my $ok=eval {
        my $start=time();
        my ($vectors,$states,$reference_states,$evicted,$second_chances,$reachable_states)
            =(0,0,0,0,0,0);
        for my $a ($a_min..$a_max) {
            for my $b (1..9) {
                for my $c (1..9) {
                    for my $d (1..9) {
                        my @L=($a,$b,$c,$d);
                        my $label=join(',',@L);
                        my $old=Pastafari::WeavingMemoOracle->new(\@L);
                        my $fifo=Pastafari::WeavingMemoOracle->new(
                            \@L,{
                                bounded_cache=>1,cache_limit=>16,
                                cache_policy=>'fifo',
                                early_final_closed_form=>1
                            }
                        );
                        my $clock=Pastafari::WeavingMemoOracle->new(
                            \@L,{
                                bounded_cache=>1,cache_limit=>16,
                                cache_policy=>'clock',
                                early_final_closed_form=>1
                            }
                        );
                        # 直接列舉合法下一標籤；只有同一個
                        # 純遞迴函式自己的參考答案共用 memo。
                        my %reference_memo;
                        my $reference;
                        $reference=sub ($rem,$opened,$closed) {
                            my $key=join(',',@$rem)."|$opened|$closed";
                            return $reference_memo{$key}
                                if exists($reference_memo{$key});
                            my $left=0;
                            $left+=$_ for @$rem;
                            return $reference_memo{$key}=1 if !$left;
                            my $ways=0;
                            my $max=$opened<4 ? $opened+1 : 4;
                            for my $j (1..$max) {
                                next unless $rem->[$j-1];
                                next if $rem->[$j-1]==1 && $j!=$closed+1;
                                my @next=@$rem;
                                $next[$j-1]--;
                                my $newclosed=$next[$j-1]==0 ? $j : $closed;
                                $ways+=$reference->(
                                    \@next,$j>$opened?$j:$opened,$newclosed
                                );
                            }
                            return $reference_memo{$key}=$ways;
                        };
                        my $full=$reference->(\@L,0,0);
                        die "$label：8,8,8,8 精確總數不符合獨立直接計數\n"
                            if $a==8 && $b==8 && $c==8 && $d==8
                            && $full!=216355766851224;
                        die "$label：9,9,9,9 完工詞與獨立精確計數不同\n"
                            if $a==9 && $b==9 && $c==9 && $d==9
                            && $full!=45407181480430770;
                        die "$label：參考數量可能溢出 64 位整數\n"
                            if $full>=9223372036854775807;
                        die "$label：完整合法詞總數不是正整數\n"
                            if $full<1;
                        for my $oracle ($old,$fifo,$clock) {
                            die "$label：完整總數不符合獨立有限列舉\n"
                                if $oracle->count_prefix([])!=$full;
                        }
                        my @todo=([[],[@L],0,0]);
                        my %seen;
                        my $local=0;
                        while (@todo) {
                            my ($prefix,$remaining,$opened,$closed)
                                =@{pop @todo};
                            my $key=join(',',@$remaining)."|$opened|$closed";
                            next if $seen{$key}++;
                            if ($opened==3) {
                                my $answer=$reference->(
                                    $remaining,$opened,$closed
                                );
                                die "$label：合法提前閉式狀態不得空集合\n"
                                    if $answer<1;
                                for my $oracle ($old,$fifo,$clock) {
                                    my $actual=$oracle->count_prefix($prefix);
                                    die "$label：獨立 DFS 和提前末次序 BigInt 不同：".
                                        join(',',@$prefix)."\n"
                                        if "$actual" ne "$answer";
                                }
                                $local++;
                                $states++;
                            }
                            my $max=$opened<4 ? $opened+1 : 4;
                            for my $j (1..$max) {
                                next unless $remaining->[$j-1];
                                next if $remaining->[$j-1]==1
                                     && $j!=$closed+1;
                                my @next=@$remaining;
                                $next[$j-1]--;
                                push @todo,[
                                    [@$prefix,$j],\@next,
                                    $j>$opened?$j:$opened,
                                    $next[$j-1]==0?$j:$closed
                                ];
                            }
                        }
                        die "$label：實際沒有覆蓋提前閉式狀態\n"
                            if !$local;
                        $reachable_states+=scalar(keys %seen);
                        $reference_states+=scalar(keys %reference_memo);
                        for my $oracle ($fifo,$clock) {
                            my $diag=$oracle->diagnostics;
                            die "$label：任何時刻超出 16 個 BigInt 項\n"
                                if $diag->{entries}>16;
                            die "$label：提前閉式實際未被調用\n"
                                if $diag->{early_closed_forms}<$local;
                            $evicted+=$diag->{evictions};
                            $second_chances+=$diag->{second_chances};
                            my $returned=$oracle->count_prefix([]);
                            $returned->badd(3);
                            die "$label：可變答案污染內部 BigInt 快取\n"
                                if $oracle->count_prefix([])!=$full;
                        }
                        $vectors++;
                    }
                }
            }
        }
        my $check=$expected{"$a_min-$a_max"};
        die "本批向量數與預先獨立計算的固定值不同\n"
            if $vectors!=$check->[0];
        die "本批提前末次序狀態數與固定精確值不同\n"
            if $states!=$check->[1];
        die "本批全部可達狀態數與固定精確值不同\n"
            if $reachable_states!=$check->[2];
        die "純參考遞迴必須覆蓋全部可達狀態\n"
            if $reference_states!=$reachable_states;
        die "沒有獨立合法詞後綴參考狀態\n"
            if !$reference_states;
        printf "R65_EARLY_LAST_SHARD status=PASS a_min=%d a_max=%d vectors=%d opened3_states=%d reachable_states=%d independent_ref_states=%d evictions=%d second_chances=%d elapsed_sec=%.3f VmHWM_KiB=%d\n",
            $a_min,$a_max,$vectors,$states,$reachable_states,
            $reference_states,$evicted,$second_chances,time()-$start,peak_kib();
        1;
    };
    if (!$ok) {
        print STDERR "R65_EARLY_LAST_SHARD status=FAIL reason=$@\n";
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
            print "R65_EARLY_LAST_SHARD_COMPLETE passed=0 blocked=0 failed=1\n";
            exit 2;
        }
        print "R65_EARLY_LAST_SHARD_COMPLETE passed=1 blocked=0 failed=0\n";
        exit 0;
    }
    die "waitpid 失敗\n" if $done<0;
    my $rss=rss_kib($pid);
    $max_seen=$rss if $rss>$max_seen;
    if ($rss>$rss_limit || time()-$begin>$seconds) {
        my $reason=$rss>$rss_limit?'RSS_LIMIT':'TIME_LIMIT';
        kill 'KILL',$pid;
        waitpid($pid,0);
        printf "R65_EARLY_LAST_SHARD status=BLOCKED reason=%s elapsed_sec=%.3f observed_RSS_KiB=%d\n",
            $reason,time()-$begin,$max_seen;
        print "R65_EARLY_LAST_SHARD_COMPLETE passed=0 blocked=1 failed=0\n";
        exit 3;
    }
    sleep(0.05);
}
