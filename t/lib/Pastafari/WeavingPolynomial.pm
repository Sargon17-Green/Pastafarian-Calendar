package Pastafari::WeavingPolynomial;
use v5.40;
use utf8;
use strict;
use warnings;
use Math::BigInt;
use Scalar::Util qw(blessed);
use Exporter 'import';

our @EXPORT_OK = qw(countWeavingsPolynomial);

# 此為獨立稽核模型，不引入 Pastafari::NormativeScroll。
# 前 m-1 個月已經有合法序列時，只保留最後一個月份
# 首次出現位置 a、末次出現位置 b 的分布 D[a,b]。
#
# 新月份長 k，插入於長 T 的舊序列。若它最初及最後出現於新序列
# 的 u,v（u<v，k>=2），其餘 k-2 個位置有 C(v-u-1,k-2) 種。
# 「新首日比舊最後月份的首日更晚」恰是 a<u；
# 「新末日比舊最後月份的末日更晚」恰是 b<=v-k。
# 因此 D'[u,v]=C(v-u-1,k-2)*Σ_{a<u,b<=v-k}D[a,b]。
# k=1 時 u=v，D'[u,u]=Σ_{a<u,b<=u-1}D[a,b]。
#
# 使用掃描 u 時的欄累積和與當列的 b 前綴和，可在每一新增月份
# O((T+k)^2) 個精確 BigInt 運算內完成，工作記憶體為 O((T+k)^2)。

sub countWeavingsPolynomial ($lengths, $stats = undef,
                            $first_histories = undef) {
    die "月份長度必須是陣列參照\n" if ref($lengths) ne 'ARRAY';
    die "診斷記錄必須是雜湊參照\n"
        if defined($stats) && ref($stats) ne 'HASH';
    die "每階段首次位置分布必須是陣列參照\n"
        if defined($first_histories) && ref($first_histories) ne 'ARRAY';
    @$first_histories=() if defined $first_histories;
    my @sizes;
    my $total = 0;
    for my $item (@$lengths) {
        die "月份長度必須是正整數\n"
            if !defined($item)
            || (ref($item) && !(blessed($item) && $item->isa('Math::BigInt')))
            || "$item" !~ /\A[0-9]+\z/;
        my $integer = Math::BigInt->new("$item");
        die "月份日數不在稽核模型的 1..5778 範圍\n"
            if $integer < 1 || $integer > 5778;
        my $n = 0 + "$integer";
        $total += $n;
        die "稽核模型的總日數上限為 5778\n" if $total > 5778;
        push @sizes,$n;
    }
    if (defined $stats) {
        %$stats = (stages => 0, max_frontier => 0, last_frontier => 0,
                   total_days => $total);
    }

    return Math::BigInt->bone if !@sizes;
    if (@sizes == 1) {
        $first_histories->[1] = [undef, Math::BigInt->bone]
            if defined $first_histories;
        return Math::BigInt->bone;
    }

    # 計數 D[u,v] 時，額外保留每個階段「最後一月
    # 首次出現於 u」的精確邊際分布。只在明確需要
    # 共用未開啟後綴時建立；一般全域計數路徑不受影響。
    my $record_histogram = sub ($stage, $matrix) {
        return if !defined $first_histories;
        my @histogram;
        for my $u (1 .. $#$matrix) {
            next if !defined $matrix->[$u];
            my $sum=Math::BigInt->bzero;
            $sum->badd($_) for grep { defined $_ } @{$matrix->[$u]};
            $histogram[$u]=$sum if !$sum->is_zero;
        }
        $first_histories->[$stage]=\@histogram;
    };

    my $T = $sizes[0];
    my @distribution;
    $distribution[1][$T] = Math::BigInt->bone;
    $record_histogram->(1,\@distribution);
    my $stage=1;

    for my $k (@sizes[1 .. $#sizes]) {
        my $nextT = $T+$k;
        my @weights;
        if ($k > 1) {
            my $order = $k-2;
            my $weight = Math::BigInt->bone;
            for my $gap ($order .. $nextT-2) {
                $weights[$gap] = $weight->copy;
                if ($gap < $nextT-2) {
                    # C(g+1,order) = C(g,order)*(g+1)/(g+1-order)
                    $weight->bmul($gap+1)->bdiv($gap+1-$order);
                }
            }
        }

        my @columns = map { Math::BigInt->bzero } 0 .. $T;
        my @next_distribution;
        my $frontier = 0;

        for my $u (1 .. $nextT) {
            # 累加所有舊月份首次出現位置 a < u 的整列。
            my $incoming = $u-1;
            if ($incoming >= 1 && $incoming <= $T) {
                my $row = $distribution[$incoming];
                if (defined $row) {
                    for my $b (1 .. $T) {
                        $columns[$b]->badd($row->[$b])
                            if defined $row->[$b];
                    }
                }
            }

            # 計算 Σ_{a<u,b<=v-k}D[a,b] 的一維前綴和。
            my @prefix = (Math::BigInt->bzero);
            for my $b (1 .. $T) {
                $prefix[$b] = $prefix[$b-1]->copy->badd($columns[$b]);
            }

            if ($k == 1) {
                my $bmax = $u-1;
                $bmax = $T if $bmax > $T;
                if ($bmax >= 1 && !$prefix[$bmax]->is_zero) {
                    $next_distribution[$u][$u] = $prefix[$bmax]->copy;
                    $frontier++;
                }
                next;
            }

            my $first_v = $u+$k-1;
            $first_v = $k+1 if $first_v < $k+1;
            for my $v ($first_v .. $nextT) {
                my $bmax = $v-$k;
                $bmax = $T if $bmax > $T;
                next if $bmax < 1 || $prefix[$bmax]->is_zero;
                my $weight = $weights[$v-$u-1];
                next if !defined($weight) || $weight->is_zero;
                $next_distribution[$u][$v] =
                    $prefix[$bmax]->copy->bmul($weight);
                $frontier++;
            }
        }

        @distribution = @next_distribution;
        $T = $nextT;
        $stage++;
        $record_histogram->($stage,\@distribution);
        if (defined $stats) {
            $stats->{stages}++;
            $stats->{last_frontier} = $frontier;
            $stats->{max_frontier} = $frontier
                if $frontier > $stats->{max_frontier};
        }
    }

    my $answer = Math::BigInt->bzero;
    for my $row (@distribution) {
        next if !defined $row;
        $answer->badd($_) for grep { defined $_ } @$row;
    }
    return $answer;
}

1;
