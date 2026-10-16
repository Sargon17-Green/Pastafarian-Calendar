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
use Pastafari::WeavingSuffixFactor qw(countWeavingSuffixFactored);

# 原生 5000 年的數個分散四月份窗口（預設末四月 402 日）。
# 前沿獨立狀態 Oracle 只驗證總數；中位排名的雙向還原不是
# 另一個獨立的全字典序預言機。邊界詞另有獨立貪婪構造。
my ($seconds,$rss_kib,$requested_offset,$second_day_partition,$third_day_partition,$third_day_target)=(185,393216,undef,0,0,undef);
GetOptions('seconds=i'=>\$seconds,'rss-kib=i'=>\$rss_kib,
           'window-offset=i'=>\$requested_offset,
           'second-day-partition!'=>\$second_day_partition,
           'third-day-partition!'=>\$third_day_partition,
           'third-day-target=s'=>\$third_day_target)
    or die "參數無效\n";
die "seconds 必須在 1..230 範圍\n"
    if $seconds<1 || $seconds>230;
die "rss-kib 必須在 32768..1048576 範圍\n"
    if $rss_kib<32768 || $rss_kib>1048576;
die "指定位置只允許 10、20、28、36、37、41；其餘窗口不得默默通過\n"
    if defined($requested_offset)
    && !grep { $requested_offset==$_ } (10,20,28,36,37,41);
die "獨立第二日分支工作必須明確選第 37 個窗口\n"
    if $second_day_partition
    && (!defined($requested_offset) || $requested_offset!=37);
die "第三日實驗只能在第 37 個窗口單獨啟用\n"
    if $third_day_partition
    && ($second_day_partition || !defined($requested_offset)
        || $requested_offset!=37);
die "第三日分片只准 parent、1、2、3、assembly\n"
    if defined($third_day_target)
    && $third_day_target !~ /\A(?:parent|[123]|assembly)\z/;
die "第三日分片必須單獨啟用並指定窗口 37\n"
    if defined($third_day_target)
    && (!defined($requested_offset) || $requested_offset!=37
        || $second_day_partition || $third_day_partition);
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
            97,50,122,110,81,54,101,83,88,40,25,77,98,122,105
        );
        die "5000 年原生月長 SHA-256 不符\n"
            if sha256_hex(join(',',@year)) ne
                '6d64022344c04935e6423aa6f96b285098d35b9b5ecb4b8c57a4c7149773a134';
        my $window_offset=41;
        $window_offset=$requested_offset if defined $requested_offset;
        my %expected=(
            10=>'98,52,81,97',
            20=>'106,115,119,39',
            28=>'55,119,97,50',
            36=>'101,83,88,40',
            37=>'83,88,40,25',
            41=>'77,98,122,105',
        );
        my @L=@year[$window_offset .. $window_offset+3];
        die "固定的原生月份窗口與窗口索引不相符\n"
            if join(',',@L) ne $expected{$window_offset};
        my $days=0;
        $days+=$_ for @L;
        my $expected_days=0;
        $expected_days+=$_ for split(',', $expected{$window_offset});
        die "原生月份日數和固定月份窗口不符\n"
            if $days!=$expected_days;
        printf "CANONICAL_WINDOW41 phase=INPUT offset=%d months=4 days=%d lengths=%s\n",
            $window_offset,$days,join(',',@L);
        my %frontier_stats;
        my $oracle=countWeavingsFrontier(\@L,\%frontier_stats);
        printf "CANONICAL_WINDOW41 phase=ORACLE_COUNT status=PASS digits=%d states=%d max_frontier=%d elapsed_sec=%.3f\n",
            length("$oracle"),$frontier_stats{states},
            $frontier_stats{frontier_peak},time()-$start;
        my $resident=countWeavingsPolynomial(\@L);
        die "真實月份位置多項式總數與獨立前沿不符\n"
            if $resident!=$oracle;
        my %stream_stats;
        my $stream=countWeavingsPolynomialStream(
            \@L,\%stream_stats,undef,{max_temp_file_bytes=>16*1024*1024}
        );
        die "真實月份磁碟串流總數與獨立前沿不符\n"
            if $stream!=$oracle;
        printf "CANONICAL_WINDOW41 phase=THREE_COUNTS_PASS stream_rows=%d elapsed_sec=%.3f\n",
            $stream_stats{rows_serialized},time()-$start;

        # 這不是 236 日完整逐天字序的獨立證明：
        # 以另一個不共用多項式排序程式碼的「正向合法狀態」
        # Oracle 獨立核對所有第二日合法分支和，
        # 再根據大整數中位名次決定第二日月份。
        my $independent_second;
        my $independent_third;
        if ($second_day_partition) {
            my %a_stats;
            my %b_stats;
            my $p11=countWeavingsFrontier(\@L,\%a_stats,[1,1]);
            my $p12=countWeavingsFrontier(\@L,\%b_stats,[1,2]);
            die "兩個合法的第二日分支都必須有後續完工詞\n"
                if $p11<1 || $p12<1;
            my $sum=$p11->copy->badd($p12);
            die "第二日兩個獨立前沿後綴的 BigInt 和不等於完整總數\n"
                if $sum!=$oracle;
            my $rank=$oracle->copy->bdiv(2)->badd(1);
            $independent_second=$rank<=$p11 ? 1 : 2;
            my $local=$rank->copy;
            $local->bsub($p11) if $independent_second==2;
            die "第二日選中分支的局部 BigInt 名次無效\n"
                if $local<1 ||
                $local>($independent_second==1 ? $p11 : $p12);
            printf "CANONICAL_WINDOW41 phase=SECOND_DAY_INDEPENDENT_PARTITION_PASS offset=%d second=%d prefix11_digits=%d prefix12_digits=%d prefix11_states=%d prefix12_states=%d elapsed_sec=%.3f\n",
                $window_offset,$independent_second,length("$p11"),
                length("$p12"),$a_stats{states},$b_stats{states},
                time()-$start;
        }

        # 在第 46 輪已證明中位名次第二日選「2」之上，
        # 用三條全新的獨立前沿將該分支的第三日完全分割。
        # 此工作不重算上一輪的 [1,1] 以控制 185 秒限制；
        # N-B 由同一精確全局計數及獨立 B 計算得出。
        if ($third_day_partition) {
            my %p12_stats;
            my $p12=countWeavingsFrontier(\@L,\%p12_stats,[1,2]);
            die "第三日驗證前，[1,2] 分支沒有完工詞\n"
                if $p12<1 || $p12>=$oracle;
            my $smaller=$oracle->copy->bsub($p12);
            my $global=$oracle->copy->bdiv(2)->badd(1);
            die "第 37 窗的中位名次不落在第二日選 2 的區段\n"
                if $global<=$smaller;
            my $local=$global->copy->bsub($smaller);
            die "第二日選 2 的局部名次超出精確計數\n"
                if $local<1 || $local>$p12;
            my $partition=Math::BigInt->bzero;
            my $selected;
            my $highest=0;
            for my $candidate (1,2,3) {
                my @prefix=(1,2,$candidate);
                my %stats;
                my $ways=countWeavingsFrontier(\@L,\%stats,\@prefix);
                die "第三日合法候選竟沒有完整的後續字序\n"
                    if $ways<1;
                $partition->badd($ways);
                if (!defined $selected) {
                    if ($local<=$ways) {
                        $selected=$candidate;
                    } else {
                        $local->bsub($ways);
                    }
                }
                my $peak=$stats{frontier_peak}//0;
                $highest=$peak if $peak>$highest;
            }
            die "第三日三個精確獨立前沿分支和不等於 [1,2] 的完工數\n"
                if $partition!=$p12;
            die "第三日 BigInt 局部名次無法定位分支\n"
                if !defined $selected || $local<1;
            $independent_second=2;
            $independent_third=$selected;
            printf "CANONICAL_WINDOW41 phase=THIRD_DAY_INDEPENDENT_PARTITION_PASS offset=%d second=%d third=%d branch_count=3 parent_digits=%d max_frontier=%d elapsed_sec=%.3f\n",
                $window_offset,$independent_second,$independent_third,
                length("$p12"),$highest,time()-$start;
        }

        # 第 47 輪全在同一子程序執行而 TIME_LIMIT BLOCKED。
        # 分片模式每個子程序僅跑一個合法前綴的獨立前沿；
        # assembly 子程序用另一個已受分片比對的精確後綴模型
        # 驗證三個數的和與全球中間 BigInt 字典序。
        my ($split_second,$split_third);
        if (defined $third_day_target) {
            my $options={
                profile_engine=>'stream-indexed',
                max_temp_file_bytes=>16*1024*1024
            };
            if ($third_day_target ne 'assembly') {
                my @prefix=$third_day_target eq 'parent'
                    ? (1,2) : (1,2,0+$third_day_target);
                my %prefix_stats;
                my $forward=countWeavingsFrontier(
                    \@L,\%prefix_stats,\@prefix
                );
                my $factor=countWeavingSuffixFactored(
                    \@L,\@prefix,undef,undef,$options
                );
                die "指定前綴的正向獨立 Oracle 與多項式後綴不相等\n"
                    if $forward<1 || $forward!=$factor;
                printf "CANONICAL_WINDOW41 phase=THIRD_PIECE_PASS target=%s prefix=%s digits=%d states=%d elapsed_sec=%.3f\n",
                    $third_day_target,join(',',@prefix),length("$forward"),
                    $prefix_stats{states},time()-$start;
            } else {
                my $parent=countWeavingSuffixFactored(
                    \@L,[1,2],undef,undef,$options
                );
                die "第三日父前綴必須非空且小於完整總數\n"
                    if $parent<1 || $parent>=$oracle;
                my $global=$oracle->copy->bdiv(2)->badd(1);
                my $before=$oracle->copy->bsub($parent);
                die "全球中位排名不在第二天選 2 的分支\n"
                    if $global<=$before;
                my $local=$global->copy->bsub($before);
                my $sum=Math::BigInt->bzero;
                my $choice;
                for my $j (1,2,3) {
                    my @prefix=(1,2,$j);
                    my $ways=countWeavingSuffixFactored(
                        \@L,\@prefix,undef,undef,$options
                    );
                    die "合法第三日 BigInt 分支不能為零\n"
                        if $ways<1;
                    $sum->badd($ways);
                    if (!defined $choice) {
                        if ($local<=$ways) {
                            $choice=$j;
                        } else {
                            $local->bsub($ways);
                        }
                    }
                }
                die "三條第三日 BigInt 分支之和不同於第二日父前綴\n"
                    if $sum!=$parent;
                die "中間名次無法從所有合法第三日分支定位\n"
                    if !defined($choice) || $local<1;
                ($split_second,$split_third)=(2,$choice);
                printf "CANONICAL_WINDOW41 phase=THIRD_ASSEMBLY_PASS second=%d third=%d branches=3 parent_digits=%d elapsed_sec=%.3f\n",
                    $split_second,$split_third,length("$parent"),
                    time()-$start;
            }
        }

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
        die "中位排名的第二日與獨立前沿 BigInt 分割不符\n"
            if defined($independent_second) &&
            $word->[1]!=$independent_second;
        die "第三日的獨立前沿 BigInt 分割與索引反排名不相符\n"
            if defined($independent_third)
            && $word->[2]!=$independent_third;
        die "分片中位排名的第二天選擇不相符\n"
            if defined($split_second) && $word->[1]!=$split_second;
        die "分片中位排名的第三天選擇不相符\n"
            if defined($split_third) && $word->[2]!=$split_third;
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
        printf "CANONICAL_WINDOW41 status=PASS scope=INDEPENDENT_TOTAL_BOUNDARY_AND_MIDDLE_ROUNDTRIP offset=%d days=%d months=4 total_digits=%d rank_digits=%d frontier_states=%d max_frontier=%d elapsed_sec=%.3f VmHWM_KiB=%d\n",
            $window_offset,$days,length("$oracle"),length($wanted),$frontier_stats{states},
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
