package Pastafari::WeavingSuffixFactor;
use v5.40;
use utf8;
use strict;
use warnings;
use Math::BigInt;
use Scalar::Util qw(blessed);
use Exporter 'import';
use Pastafari::WeavingSuffix qw(countWeavingSuffixPolynomial);
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);

our @EXPORT_OK = qw(countWeavingSuffixFactored);

# 第 1 階段實驗：依「已開啟月份的最後次序」與
# 「未開啟月份的首次及最後次序」拆開後綴。
#
# A：已開啟而尚未結束的月份 c+1..p，長度 r_i，
#    其內部序列只受各月最後出現的次序約束。
# B：尚未開啟的月份 p+1..m，長度仍為 L_i，
#    其內部序列必須同時遵守首次與最後出現次序。
# 每個合法 A 序列的最後一個符號必屬月份 p。
# A 與 B 交織時，只須保證 A 的最後一個符號
# 早於 B 中第 p+1 月的最後一個符號，與 A 的內部
# 字母排列無關。故 F(prefix)=F(A)*H(p,T)，
# 其中 T=Σr_i，H 為一個「已在前綴開啟」的虛擬月份
# 長度 T+1（先固定其首日）和 B 之多項式完工數。
# 對同一完整月份長度及相同 (p,T) 的候選只算一次 H。
#
# 共用快取僅由呼叫者擁有，應在單次反排名內建立；
# 鍵包含全部月份長度，不跨不同日曆輸入互相污染。
sub countWeavingSuffixFactored ($lengths, $prefix,
                               $shared_cache = undef, $diagnostics = undef) {
    die "月份長度必須是陣列參照\n" if ref($lengths) ne 'ARRAY';
    die "月份前綴必須是陣列參照\n" if ref($prefix) ne 'ARRAY';
    die "共用後綴快取必須是雜湊參照\n"
        if defined($shared_cache) && ref($shared_cache) ne 'HASH';
    die "診斷記錄必須是雜湊參照\n"
        if defined($diagnostics) && ref($diagnostics) ne 'HASH';

    my (@sizes,$total);
    $total=0;
    for my $item (@$lengths) {
        die "月份長度必須是正整數\n"
            if !defined($item)
            || (ref($item) && !(blessed($item) && $item->isa('Math::BigInt')))
            || "$item" !~ /\A[0-9]+\z/;
        my $v=Math::BigInt->new("$item");
        die "月份日數不在稽核模型的 1..5778 範圍\n"
            if $v < 1 || $v > 5778;
        my $n=0+"$v";
        $total+=$n;
        die "稽核模型的總日數上限為 5778\n" if $total > 5778;
        push @sizes,$n;
    }

    my $m=scalar @sizes;
    my @remaining=@sizes;
    my ($opened,$closed)=(0,0);
    die "月份前綴不得超過總日數\n" if @$prefix > $total;
    for my $item (@$prefix) {
        die "月份前綴編號必須是正整數\n"
            if !defined($item)
            || (ref($item) && !(blessed($item) && $item->isa('Math::BigInt')))
            || "$item" !~ /\A[0-9]+\z/;
        my $v=Math::BigInt->new("$item");
        die "月份前綴編號超出範圍\n" if $v < 1 || $v > $m;
        my $j=0+"$v";
        die "月份前綴重複使用已完成月份\n"
            if !$remaining[$j-1];
        if ($remaining[$j-1] == $sizes[$j-1]) {
            die "月份前綴違反首次出現次序\n" if $j!=$opened+1;
            $opened=$j;
        }
        $remaining[$j-1]--;
        if (!$remaining[$j-1]) {
            die "月份前綴違反末次出現次序\n" if $j!=$closed+1;
            $closed=$j;
        }
    }

    $diagnostics->{factor_calls}++ if defined $diagnostics;

    my @active = $opened ? @remaining[0 .. $opened-1] : ();
    my $T=0; $T+=$_ for @active;
    my $factor=Math::BigInt->bone;
    # 對已開啟月份直接用獨立的一維二項式乘積公式。
    if ($T) {
        $factor=Pastafari::WeavingSuffix::_full_open_last_order_count(
            \@active,$closed
        );
    }

    # 沒有尚未開啟的月份：剩餘交織只計一次 F(A)。
    return $factor if $opened==$m;

    my %private_cache;
    my $cache = defined($shared_cache) ? $shared_cache : \%private_cache;
    my $key=join(',',@sizes).'|'.$opened.'|'.$T;
    my $future;
    if (exists $cache->{$key}) {
        $future=$cache->{$key}->copy;
        $diagnostics->{future_cache_hits}++ if defined $diagnostics;
    } else {
        if (!$T) {
            # 已開啟月份均已結束，餘下完全等於新的獨立月份序列。
            my @rest=@sizes[$opened .. $m-1];
            $future=countWeavingsPolynomial(\@rest);
        } else {
            # 首次出現順序已在真實前綴固定的虛擬月份。
            # 因為前綴至少使用一天，虛擬總日數不超過原始總日數。
            my @virtual=($T+1,@sizes[$opened .. $m-1]);
            $future=countWeavingSuffixPolynomial(\@virtual,[1]);
        }
        $cache->{$key}=$future->copy;
        $diagnostics->{future_cache_misses}++ if defined $diagnostics;
    }
    return $factor->bmul($future);
}
1;
