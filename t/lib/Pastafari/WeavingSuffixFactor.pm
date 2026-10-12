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
use Pastafari::WeavingPolynomialStream qw(countWeavingsPolynomialStream);

our @EXPORT_OK = qw(countWeavingSuffixFactored);

# 所有入口均先驗證引擎與磁碟預算；不允許使用相同共享快取
# 時，以其它預算先算好的結果繞過較嚴格的限制。
sub _normalize_profile_options ($options = undef) {
    die "交織計數選項必須是雜湊參照\n"
        if defined($options) && ref($options) ne 'HASH';
    $options //= {};
    die "未知的交織計數選項\n"
        if grep {$_ ne 'profile_engine' && $_ ne 'max_temp_file_bytes'}
                keys %$options;
    my $engine=$options->{profile_engine} // 'resident';
    die "交織計數引擎必須是 resident 或 stream\n"
        if ref($engine) || ($engine ne 'resident' && $engine ne 'stream');
    die "常駐矩陣引擎不能指定磁碟容量\n"
        if $engine eq 'resident' && exists $options->{max_temp_file_bytes};
    my $max_bytes;
    if ($engine eq 'stream') {
        $max_bytes=$options->{max_temp_file_bytes} // (128*1024*1024);
        die "單一暫存檔容量限制須為 1..1073741824 的整數位元組\n"
            if ref($max_bytes) || "$max_bytes" !~ /\A[1-9][0-9]*\z/
            || length("$max_bytes") > 10 || $max_bytes > 1_073_741_824;
        $max_bytes=0+"$max_bytes";
    }
    return {profile_engine=>$engine,
            ($engine eq 'stream' ? (max_temp_file_bytes=>$max_bytes) : ())};
}


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
                               $shared_cache = undef, $diagnostics = undef,
                               $options = undef) {
    my $normalized=_normalize_profile_options($options);
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

    return _countWeavingSuffixFactoredState(
        \@sizes,\@remaining,$opened,$closed,$shared_cache,$diagnostics,
        $normalized
    );
}
# 僅限反排名內部使用。呼叫者已驗證月長和整個前綴，
# 並擁有「剩餘向量／opened／closed」狀態；此捷徑不可
# 用作未經驗證的公開輸入界面。
sub _countWeavingSuffixFactoredState ($lengths, $remaining,
                                     $opened, $closed,
                                     $shared_cache = undef,
                                     $diagnostics = undef,
                                     $options = undef) {
    my $normalized=_normalize_profile_options($options);
    my $engine=$normalized->{profile_engine};
    my $budget=$normalized->{max_temp_file_bytes} // '-';
    my @sizes=map { 0+"$_" } @$lengths;
    my @remaining=@$remaining;
    my $m=scalar @sizes;
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
    my $signature=join(',',@sizes);
    my $namespace=join('|','profile-v1',$engine,$budget,$signature);
    my $key=$namespace.'|'.$opened.'|'.$T;
    my $future;
    if (exists $cache->{$key}) {
        $future=$cache->{$key}->copy;
        $diagnostics->{future_cache_hits}++ if defined $diagnostics;
    } else {
        # 對所有未開啟的月份反轉日期及月份標籤，可把
        # 「正序第 1 未開啟月份的末次位置 z」轉為
        # 「反序最後月份的首次位置 u」，並有 z=U+1-u。
        # 在一個反序全域多項式 DP 中，一次取得所有
        # 未開啟後綴長度的首次位置直方圖，再共享於各 p。
        my $profile_key='reversed-first-hist|'.$namespace;
        if (!exists $cache->{$profile_key}) {
            my @reversed=reverse @sizes;
            my @histories;
            if ($engine eq 'stream') {
                my %stream_stats;
                countWeavingsPolynomialStream(\@reversed,\%stream_stats,
                    \@histories,{max_temp_file_bytes=>$budget});
                if (defined $diagnostics) {
                    $diagnostics->{profile_disk_builds}++;
                    my $previous=$diagnostics->{profile_max_temp_file_bytes}//0;
                    my $now=$stream_stats{max_temp_file_bytes}//0;
                    $diagnostics->{profile_max_temp_file_bytes}=
                        $now>$previous ? $now : $previous;
                    $diagnostics->{profile_rows_serialized}+=
                        $stream_stats{rows_serialized}//0;
                }
            } else {
                countWeavingsPolynomial(\@reversed,undef,\@histories);
            }
            # 建表成功後才發表快取：失敗、超限時不能暴露半成品。
            $cache->{$profile_key}=\@histories;
            $diagnostics->{profile_builds}++ if defined $diagnostics;
        }
        my $future_months=$m-$opened;
        my $histogram=$cache->{$profile_key}[$future_months];
        die "缺少未開啟後綴的精確首次位置直方圖\n"
            if !defined($histogram);
        my $U=0;
        $U+=$_ for @sizes[$opened .. $m-1];

        # 固定任何一個合法的已開啟 A 序列與未開啟 B
        # 序列。若 B 第一個月份最後出現於 z，
        # 恰有 C(T+z-1,T) 種插入 A 的方法，
        # 且 A 的最後一日必早於該個 B 符號。
        # 相鄰 u 的組合數以精確整數遞推，而非重建 DP。
        my $n=$T+$U-1;
        my $r=$T;
        $r=$n-$r if $r>$n-$r;
        my $weight=Math::BigInt->bone;
        for my $i (1 .. $r) {
            $weight->bmul($n-$r+$i)->bdiv($i);
        }
        $future=Math::BigInt->bzero;
        for my $u (1 .. $U) {
            if (defined $histogram->[$u]) {
                $future->badd($histogram->[$u]->copy->bmul($weight));
            }
            if ($u<$U) {
                my $current_n=$T+$U-$u;
                $weight->bmul($current_n-$T)->bdiv($current_n);
            }
        }
        $cache->{$key}=$future->copy;
        $diagnostics->{future_cache_misses}++ if defined $diagnostics;
    }
    return $factor->bmul($future);
}
1;
