#!/usr/bin/env perl
use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Math::BigInt;
use Digest::SHA qw(sha256_hex sha512_hex);
use Time::HiRes qw(time sleep);
use POSIX qw(WNOHANG);
use Getopt::Long qw(GetOptions);
use lib 'lib','t/lib';
use Pastafari::WeavingMemoOracle;
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::WeavingUnrank qw(unrankWeavingPolynomial);
use Pastafari::WeavingRank qw(rankWeavingPolynomial);

# 第 5000 年兩種真實相鄰四月份樣本，各自精確驗證完整 BigInt 排名。
# 使用一份與受測排名器完全分離的記憶式狀態計數快取，並
# 每次以新索引計數實際跑正反向排名；且有父進程資源守衛。
my ($seconds,$rss_limit,$offset,$case_filter)=(185,393216,39,'all');
GetOptions('seconds=i'=>\$seconds,'rss-kib=i'=>\$rss_limit,
           'window-offset=i'=>\$offset,
           'case-filter=s'=>\$case_filter)
    or die "參數格式錯誤\n";
die "second 必須在 1..230\n" if $seconds<1 || $seconds>230;
die "rss-kib 必須在 32768..1048576\n"
    if $rss_limit<32768 || $rss_limit>1048576;
die "window-offset 只支援 37、38、39 或 40\n"
    if $offset!=37 && $offset!=38 && $offset!=39 && $offset!=40;
die "case-filter 只支援 all、middle、first-half、last-half、hash-a、hash-b\n"
    if $case_filter ne 'all' && $case_filter ne 'middle'
    && $case_filter ne 'first-half' && $case_filter ne 'last-half'
    && $case_filter ne 'hash-a' && $case_filter ne 'hash-b';
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
        my @L=@year[$offset .. $offset+3];
        my $expected=$offset==37 ? '83,88,40,25'
                    : $offset==38 ? '88,40,25,77'
                    : $offset==39 ? '40,25,77,98'
                    : '25,77,98,122';
        die "固定真正月份向量不符\n"
            if join(',',@L) ne $expected;
        my $days=0;
        $days+=$_ for @L;
        die "真實視窗合計日數不符\n"
            unless $days==($offset==37 ? 236 : $offset==38 ? 230 : $offset==39 ? 240 : 322);
        printf "CANONICAL_MULTI_RANK phase=WINDOW offset=%d days=%d lengths=%s\n",
            $offset,$days,join(',',@L);
        # 37 窗口可能超過 200000 個「累積」狀態；仍只保留
        # 至多 200000 個即時 BigInt 快取項，超額時 FIFO 淘汰。
        # 其餘 38..40 窗口完全使用原本的嚴格 hard-fail 上限。
        my $counter=Pastafari::WeavingMemoOracle->new(
            \@L,$offset==37 ? {bounded_cache=>1,cache_limit=>200000} : undef
        );
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
        @named=grep {$_->[0] eq 'middle'} @named
            if $case_filter eq 'middle';
        @named=@named[0..6] if $case_filter eq 'first-half';
        @named=@named[7..13] if $case_filter eq 'last-half';
        my $expected_labels=$case_filter eq 'first-half'
            ? 'first,second,third,fourth,p10,p25,pre_middle'
            : $case_filter eq 'last-half'
            ? 'middle,p75,p90,near_last3,near_last2,near_last1,last'
            : undef;
        die "分片樣本並非七個完整、互不重複的固定排名\n"
            if defined($expected_labels)
            && join(',',map {$_->[0]} @named) ne $expected_labels;
        # R55：SHA-512 的 512 位十六進位作獨立確定性檢測名次，
        # modulo 完整 BigInt N，均勻跨越 N 的 125 位十進位範圍。
        # 先完全固定 12 個名次再分組，每次測試仍是完整 236 日。
        if ($case_filter eq 'hash-a' || $case_filter eq 'hash-b') {
            die "SHA-512 補充名次僅可套用已核對的真實 37 窗口\n"
                if $offset!=37;
            my @hash_samples;
            my %observed;
            for my $index (0..11) {
                my $seed="PASTAFARIAN-5000-FOURMONTH-37-R55:$index";
                my $digest=sha512_hex($seed);
                my $rank=Math::BigInt->from_hex("0x$digest")
                    ->bmod($total)->badd(1);
                die "SHA-512 固定名次必須在 1..N 之內\n"
                    if $rank<1 || $rank>$total;
                die "SHA-512 固定名次發生重複，不能悄悄少驗\n"
                    if $observed{"$rank"}++;
                push @hash_samples,[
                    sprintf('hash%02d',$index),$rank
                ];
            }
            @named=$case_filter eq 'hash-a'
                ? @hash_samples[0..5] : @hash_samples[6..11];
            die "SHA-512 六名次分組失敗\n" if @named!=6;
        }
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
            die "$label 字序長度不等於目前真實四月日數\n" if @$word!=$days;
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
            for my $day (1..$days) {
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
            die "$label 完成所有月份日後局部排名不是 1\n" if $local!=1;
            die "$label 輸入 BigInt 排名被污染\n"
                if "$rank" ne $rank_text;
            $test_count++;
            my $diag=$counter->diagnostics;
            printf "CANONICAL_MULTI_RANK status=PASS window=%d case=%s index=%d digits=%d checked_days=%d memo_entries=%d memo_hits=%d elapsed_sec=%.3f\n",
                $offset,$label,$test_count,length($rank_text),$days,
                $diag->{entries},$diag->{cache_hits},time()-$start;
        }
        my $expected_count=$case_filter eq 'all' ? 14
                          : $case_filter eq 'middle' ? 1
                          : ($case_filter eq 'hash-a' || $case_filter eq 'hash-b') ? 6 : 7;
        die "字典序重要排名樣本未全部執行\n"
            if $test_count!=$expected_count;
        my $diag=$counter->diagnostics;
        printf "CANONICAL_MULTI_RANK phase=BOUNDED_MEMO entries=%d evictions=%d cache_limit=%d\n",$diag->{entries},$diag->{evictions},$diag->{cache_limit} if $offset==37;
        printf "CANONICAL_MULTI_RANK status=PASS scope=FOUR_MONTH_WINDOW_LEXICOGRAPHIC_BRANCHES filter=%s window=%d cases=%d days_per_rank=%d total_digits=%d memo_entries=%d memo_hits=%d elapsed_sec=%.3f VmHWM_KiB=%d\n",
            $case_filter,$offset,$test_count,$days,length("$total"),$diag->{entries},
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
