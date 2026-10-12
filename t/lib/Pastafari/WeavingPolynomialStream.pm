package Pastafari::WeavingPolynomialStream;
use v5.40;
use utf8;
use strict;
use warnings;
use Math::BigInt;
use Scalar::Util qw(blessed);
use File::Temp;
use Storable qw(store_fd fd_retrieve);
use Exporter 'import';

our @EXPORT_OK = qw(countWeavingsPolynomialStream);

# 第一階段參考演算法：與 WeavingPolynomial 相同的精確 D[u,v]
# 轉移，但每個階段的舊列只從臨時檔順序讀入一次，新列隨算
# 隨寫。RAM 只保存 O(N) 的欄累計、前綴和、二項係數與單列。
#
# 無邊際直方圖輸出時核心 RAM 為 O(N) 個 BigInt；若要求
# 每個階段的首次出現直方圖，另需 O(Σ T_stage) 個 BigInt。
# 暫存磁碟空間可能為 O(N²)，且僅限制「每一檔」的最大位元組數。
# 改用持有生命週期的 File::Temp->new(UNLINK=>1) 物件：
# 舊 tempfile(UNLINK=>1) 僅在程序結束時清理，不足以保證
# 大型多階段計算在釋放上個階段時即回收磁碟。
sub countWeavingsPolynomialStream ($lengths, $stats = undef,
                                  $first_histories = undef, $options = undef,
                                  $histogram_sink = undef) {
    # 回呼僅持有當前階段的邊際位置直方圖；後續階段不保留參照。
    # 可讓呼叫者寫到持久的暫存索引，避免存下所有階段的 BigInt。
    die "位置直方圖接收器必須是程式參照\n"
        if defined($histogram_sink) && ref($histogram_sink) ne 'CODE';
    die "月份長度必須是陣列參照\n" if ref($lengths) ne 'ARRAY';
    die "診斷記錄必須是雜湊參照\n"
        if defined($stats) && ref($stats) ne 'HASH';
    die "每階段首次位置分布必須是陣列參照\n"
        if defined($first_histories) && ref($first_histories) ne 'ARRAY';
    die "磁碟預算選項必須是雜湊參照\n"
        if defined($options) && ref($options) ne 'HASH';
    $options //= {};
    die "只支援 max_temp_file_bytes 選項\n"
        if grep {$_ ne 'max_temp_file_bytes'} keys %$options;
    my $limit = $options->{max_temp_file_bytes} // (128 * 1024 * 1024);
    die "單一暫存檔容量限制須為 1..1073741824 的整數位元組\n"
        if !defined($limit) || ref($limit)
        || "$limit" !~ /\A[1-9][0-9]*\z/
        || length("$limit") > 10 || $limit > 1_073_741_824;

    my @sizes;
    my $days = 0;
    for my $item (@$lengths) {
        die "月份長度必須是正整數\n"
            if !defined($item)
            || (ref($item) && !(blessed($item) && $item->isa('Math::BigInt')))
            || "$item" !~ /\A[0-9]+\z/;
        my $value=Math::BigInt->new("$item");
        die "月份日數不在稽核模型的 1..5778 範圍\n"
            if $value < 1 || $value > 5778;
        $days += 0+"$value";
        die "稽核模型的總日數上限為 5778\n" if $days > 5778;
        push @sizes,0+"$value";
    }
    @$first_histories=() if defined $first_histories;
    if (defined $stats) {
        %$stats=(stages=>0,total_days=>$days,
                 last_frontier=>0,max_frontier=>0,
                 max_temp_file_bytes=>0,rows_serialized=>0,
                 histogram_sink_calls=>0);
    }
    return Math::BigInt->bone if !@sizes;
    if (@sizes == 1) {
        my $one=[undef,Math::BigInt->bone];
        $first_histories->[1]=$one if defined $first_histories;
        if (defined $histogram_sink) {
            $histogram_sink->(1,$one);
            $stats->{histogram_sink_calls}++ if defined $stats;
        }
        return Math::BigInt->bone;
    }

    my $old_fh=File::Temp->new(UNLINK=>1);
    binmode($old_fh) or die "無法將暫存檔切換成二進位模式\n";
    my $T=$sizes[0];
    for my $u (1 .. $T) {
        my @row;
        $row[$T]=Math::BigInt->bone if $u==1;
        store_fd(\@row,$old_fh);
        my $bytes=tell($old_fh);
        die "暫存檔無法取得寫入位置\n" if !defined($bytes) || $bytes<0;
        die "暫存檔超過容量限制\n" if $bytes>$limit;
        if (defined $stats) {
            $stats->{rows_serialized}++;
            $stats->{max_temp_file_bytes}=$bytes
                if $bytes>$stats->{max_temp_file_bytes};
        }
    }
    seek($old_fh,0,0) or die "暫存檔無法重新讀取\n";
    my $initial_histogram=[undef,Math::BigInt->bone];
    $first_histories->[1]=$initial_histogram if defined $first_histories;
    if (defined $histogram_sink) {
        $histogram_sink->(1,$initial_histogram);
        $stats->{histogram_sink_calls}++ if defined $stats;
    }

    my $answer=Math::BigInt->bone;
    for my $index (1 .. $#sizes) {
        my $k=$sizes[$index];
        my $newT=$T+$k;
        my $last_stage=($index==$#sizes);
        my $new_fh;
        if (!$last_stage) {
            $new_fh=File::Temp->new(UNLINK=>1);
            binmode($new_fh) or die "無法將暫存檔切換成二進位模式\n";
        }
        my @weights;
        if ($k>1) {
            my $order=$k-2;
            my $w=Math::BigInt->bone;
            for my $gap ($order .. $newT-2) {
                $weights[$gap]=$w->copy;
                if ($gap<$newT-2) {
                    $w->bmul($gap+1)->bdiv($gap+1-$order);
                }
            }
        }
        my @columns=map {Math::BigInt->bzero} 0 .. $T;
        my @histogram;
        my $stage_total=Math::BigInt->bzero;
        my $frontier=0;

        for my $u (1 .. $newT) {
            my $incoming=$u-1;
            if ($incoming>=1 && $incoming<=$T) {
                my $previous=fd_retrieve($old_fh);
                die "暫存列格式錯誤\n" if ref($previous) ne 'ARRAY';
                for my $b (1 .. $T) {
                    $columns[$b]->badd($previous->[$b])
                        if defined $previous->[$b];
                }
            }
            my @prefix=(Math::BigInt->bzero);
            for my $b (1 .. $T) {
                $prefix[$b]=$prefix[$b-1]->copy->badd($columns[$b]);
            }
            my @row;
            if ($k==1) {
                my $bmax=$u-1;
                $bmax=$T if $bmax>$T;
                if ($bmax>=1 && !$prefix[$bmax]->is_zero) {
                    $row[$u]=$prefix[$bmax]->copy;
                    $frontier++;
                }
            } else {
                my $first_v=$u+$k-1;
                $first_v=$k+1 if $first_v<$k+1;
                for my $v ($first_v .. $newT) {
                    my $bmax=$v-$k;
                    $bmax=$T if $bmax>$T;
                    next if $bmax<1 || $prefix[$bmax]->is_zero;
                    my $w=$weights[$v-$u-1];
                    next if !defined($w) || $w->is_zero;
                    $row[$v]=$prefix[$bmax]->copy->bmul($w);
                    $frontier++;
                }
            }
            my $row_total=Math::BigInt->bzero;
            $row_total->badd($_) for grep {defined $_} @row;
            $stage_total->badd($row_total);
            $histogram[$u]=$row_total
                if (defined($first_histories) || defined($histogram_sink))
                   && !$row_total->is_zero;
            if (!$last_stage) {
                store_fd(\@row,$new_fh);
                my $bytes=tell($new_fh);
                die "暫存檔無法取得寫入位置\n"
                    if !defined($bytes) || $bytes<0;
                die "暫存檔超過容量限制\n" if $bytes>$limit;
                if (defined $stats) {
                    $stats->{rows_serialized}++;
                    $stats->{max_temp_file_bytes}=$bytes
                        if $bytes>$stats->{max_temp_file_bytes};
                }
            }
        }
        $first_histories->[$index+1]=\@histogram
            if defined $first_histories;
        if (defined $histogram_sink) {
            $histogram_sink->($index+1,\@histogram);
            $stats->{histogram_sink_calls}++ if defined $stats;
        }
        $answer=$stage_total;
        if (defined $stats) {
            $stats->{stages}++;
            $stats->{last_frontier}=$frontier;
            $stats->{max_frontier}=$frontier
                if $frontier>$stats->{max_frontier};
        }
        close($old_fh) or die "無法關閉暫存檔\n";
        if (!$last_stage) {
            seek($new_fh,0,0) or die "暫存檔無法重新讀取\n";
            $old_fh=$new_fh;
        }
        $T=$newT;
    }
    return $answer;
}
1;
