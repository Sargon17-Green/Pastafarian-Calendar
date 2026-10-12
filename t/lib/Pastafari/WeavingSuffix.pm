package Pastafari::WeavingSuffix;
use v5.40;
use utf8;
use strict;
use warnings;
use Math::BigInt;
use Scalar::Util qw(blessed);
use Exporter 'import';
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);

our @EXPORT_OK = qw(countWeavingSuffixPolynomial);

# 僅供第一階段稽核：精確計算一個「已實際選定前綴」的完工數。
# 不呼叫 NormativeScroll 的剩餘向量 DP。
#
# 前綴中已開啟的月份，首次出現順序已經固定；剩餘部分只需
# 遵守最後出現順序。尚未開啟的第一個月份同樣無需再檢查
# 與其前一月份的首次出現順序，因為前一月份在前綴已出現。
# 更後面的未開啟月份仍須同時遵守首次和末次順序。

sub _weights ($k, $next_total) {
    my @weights;
    return \@weights if $k == 1;
    my $order = $k-2;
    my $value = Math::BigInt->bone;
    for my $gap ($order .. $next_total-2) {
        $weights[$gap] = $value->copy;
        if ($gap < $next_total-2) {
            $value->bmul($gap+1)->bdiv($gap+1-$order);
        }
    }
    return \@weights;
}

sub _last_prefix ($distribution, $T) {
    my @sum = (Math::BigInt->bzero);
    for my $b (1 .. $T) {
        $sum[$b] = $sum[$b-1]->copy;
        $sum[$b]->badd($distribution->[$b])
            if defined $distribution->[$b];
    }
    return \@sum;
}

sub _sum_distribution ($distribution) {
    my $sum = Math::BigInt->bzero;
    for my $row (@$distribution) {
        next if !defined $row;
        $sum->badd($_) for grep { defined $_ } @$row;
    }
    return $sum;
}

# 所有月份皆已首次出現時，剩餘序列只保留末次順序的
# 約束。最末月份必須在最末日出現，其前 k-1 次出現位置
# 可從前 N-1 日中選擇。移除此月份後再次應用相同定理。
# 乘積的每一項都是精確 Math::BigInt 組合數，無需展開
# 一維 E 或二維 D 分布。
sub _full_open_last_order_count ($remaining, $closed) {
    my $total=0;
    $total += $_ for @$remaining;
    my $answer=Math::BigInt->bone;
    for (my $j=$#$remaining; $j>$closed; $j--) {
        my $k=$remaining->[$j];
        die "所有月份已開啟時，未結束月份必須有剩餘日數\n"
            if $k < 1;
        my $choose=Math::BigInt->bone;
        my $n=$total-1;
        my $r=$k-1;
        $r=$n-$r if $r>$n-$r;
        for my $i (1 .. $r) {
            $choose->bmul($n-$r+$i)->bdiv($i);
        }
        $answer->bmul($choose);
        $total -= $k;
    }
    return $answer;
}

sub countWeavingSuffixPolynomial ($lengths, $prefix, $stats = undef) {
    die "月份長度必須是陣列參照\n" if ref($lengths) ne 'ARRAY';
    die "月份前綴必須是陣列參照\n" if ref($prefix) ne 'ARRAY';
    die "診斷記錄必須是雜湊參照\n"
        if defined($stats) && ref($stats) ne 'HASH';

    my @sizes;
    my $total = 0;
    for my $value (@$lengths) {
        die "月份長度必須是正整數\n"
            if !defined($value)
            || (ref($value) && !(blessed($value) && $value->isa('Math::BigInt')))
            || "$value" !~ /\A[0-9]+\z/;
        my $integer = Math::BigInt->new("$value");
        die "月份日數不在稽核模型的 1..5778 範圍\n"
            if $integer < 1 || $integer > 5778;
        $total += 0+"$integer";
        die "稽核模型的總日數上限為 5778\n" if $total > 5778;
        push @sizes,0+"$integer";
    }

    my $m = scalar @sizes;
    my @remaining = @sizes;
    my ($opened,$closed)=(0,0);
    die "月份前綴不得超過總日數\n" if @$prefix > $total;
    for my $value (@$prefix) {
        die "月份前綴編號必須是正整數\n"
            if !defined($value)
            || (ref($value) && !(blessed($value) && $value->isa('Math::BigInt')))
            || "$value" !~ /\A[0-9]+\z/;
        my $number = Math::BigInt->new("$value");
        die "月份前綴編號超出範圍\n" if $number < 1 || $number > $m;
        my $j = 0+"$number";
        die "月份前綴重複使用已完成月份\n" if $remaining[$j-1] == 0;
        if ($remaining[$j-1] == $sizes[$j-1]) {
            die "月份前綴違反首次出現次序\n" if $j != $opened+1;
            $opened = $j;
        }
        $remaining[$j-1]--;
        if ($remaining[$j-1] == 0) {
            die "月份前綴違反末次出現次序\n" if $j != $closed+1;
            $closed = $j;
        }
    }

    if (defined $stats) {
        %$stats = (opened => $opened, closed => $closed,
                   days_remaining => $total-@$prefix,
                   stages => 0, max_frontier => 0);
    }

    if ($opened >= $m-1 && $opened > $closed) {
        # 若所有月份都已開啟，首次出現次序已固定。
        # 若僅有最後月份尚未開啟，它的首次出現自然晚於
        # 所有已開啟月份，且沒有更後面的月份須加以限制。
        # 因此兩種情形的後綴都只需保持末次出現次序。
        if (defined $stats) {
            if ($opened == $m) {
                $stats->{full_open_closed_form} = 1;
            } else {
                $stats->{one_unopened_closed_form} = 1;
            }
        }
        return _full_open_last_order_count(\@remaining,$closed);
    }

    if ($opened == $closed) {
        # 前綴中的月份皆已結束；其餘月份從零開始正常開啟。
        my @future = @remaining[$opened .. $#remaining];
        my $answer = countWeavingsPolynomial(\@future);
        return $answer;
    }

    # 此時 c+1..opened 是首次出現已滿足、但尚未全部結束的月份。
    # E[v] 計算其末月最後出現於 v 的剩餘序列數。
    my $T = $remaining[$closed];
    my @E;
    $E[$T] = Math::BigInt->bone;

    for my $j ($closed+1 .. $opened-1) {
        my $k = $remaining[$j];
        my $prefixE = _last_prefix(\@E,$T);
        my @next;
        my $weight = Math::BigInt->bone;
        for my $v ($k .. $T+$k) {
            my $bmax = $v-$k;
            if ($bmax >= 1 && !$prefixE->[$bmax]->is_zero) {
                $next[$v] = $prefixE->[$bmax]->copy->bmul($weight);
            }
            if ($v < $T+$k) {
                # C(v,k-1) = C(v-1,k-1) * v/(v-k+1)
                $weight->bmul($v)->bdiv($v-$k+1);
            }
        }
        @E = @next;
        $T += $k;
        $stats->{stages}++ if defined $stats;
    }

    if ($opened == $m) {
        my $total_count = Math::BigInt->bzero;
        $total_count->badd($_) for grep { defined $_ } @E;
        return $total_count;
    }

    # 第一個尚未開啟的月份，不必與已在前綴出現過的前一月份
    # 比較首日；只要末日順序正確。
    my $k = $remaining[$opened];
    my $nextT = $T+$k;
    my $prefixE = _last_prefix(\@E,$T);
    my $weights = _weights($k,$nextT);
    my @D;
    my $frontier = 0;
    for my $u (1 .. $nextT) {
        if ($k == 1) {
            my $bmax = $u-1;
            $bmax = $T if $bmax > $T;
            if ($bmax >= 1 && !$prefixE->[$bmax]->is_zero) {
                $D[$u][$u] = $prefixE->[$bmax]->copy;
                $frontier++;
            }
            next;
        }
        my $first_v = $u+$k-1;
        $first_v = $k+1 if $first_v < $k+1;
        for my $v ($first_v .. $nextT) {
            my $bmax = $v-$k;
            $bmax = $T if $bmax > $T;
            next if $bmax < 1 || $prefixE->[$bmax]->is_zero;
            my $weight = $weights->[$v-$u-1];
            next if !defined($weight) || $weight->is_zero;
            $D[$u][$v] = $prefixE->[$bmax]->copy->bmul($weight);
            $frontier++;
        }
    }
    $T = $nextT;
    if (defined $stats) {
        $stats->{stages}++;
        $stats->{max_frontier} = $frontier;
    }

    # 後續未開啟月份間的首次出現與末次出現次序都須保持。
    for my $j ($opened+1 .. $m-1) {
        $k = $remaining[$j];
        $nextT = $T+$k;
        $weights = _weights($k,$nextT);
        my @columns = map { Math::BigInt->bzero } 0 .. $T;
        my @next_D;
        $frontier = 0;
        for my $u (1 .. $nextT) {
            my $incoming = $u-1;
            if ($incoming >= 1 && $incoming <= $T && defined($D[$incoming])) {
                for my $b (1 .. $T) {
                    $columns[$b]->badd($D[$incoming][$b])
                        if defined $D[$incoming][$b];
                }
            }
            my @prefixB = (Math::BigInt->bzero);
            for my $b (1 .. $T) {
                $prefixB[$b] = $prefixB[$b-1]->copy->badd($columns[$b]);
            }
            if ($k == 1) {
                my $bmax = $u-1;
                $bmax = $T if $bmax > $T;
                if ($bmax >= 1 && !$prefixB[$bmax]->is_zero) {
                    $next_D[$u][$u] = $prefixB[$bmax]->copy;
                    $frontier++;
                }
                next;
            }
            my $first_v = $u+$k-1;
            $first_v = $k+1 if $first_v < $k+1;
            for my $v ($first_v .. $nextT) {
                my $bmax = $v-$k;
                $bmax = $T if $bmax > $T;
                next if $bmax < 1 || $prefixB[$bmax]->is_zero;
                my $weight = $weights->[$v-$u-1];
                next if !defined($weight) || $weight->is_zero;
                $next_D[$u][$v] = $prefixB[$bmax]->copy->bmul($weight);
                $frontier++;
            }
        }
        @D = @next_D;
        $T = $nextT;
        if (defined $stats) {
            $stats->{stages}++;
            $stats->{max_frontier} = $frontier
                if $frontier > $stats->{max_frontier};
        }
    }

    return _sum_distribution(\@D);
}

1;
