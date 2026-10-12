package Pastafari::WeavingRank;
use v5.40;
use utf8;
use strict;
use warnings;
use Exporter 'import';
use Math::BigInt;
use Scalar::Util qw(blessed);
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::WeavingSuffixFactor ();

our @EXPORT_OK = qw(rankWeavingPolynomial);

# 第 1 階段驗證用的反向字典序排名器，不呼叫 WeavingUnrank。
# 每一步把比實際下一個標籤小的合法選項所能形成的全部
# 完工序列數相加，最後再加一取得一基排名。
# 與反排名器使用相同已獨立驗證的精確計數公式，
# 但候選順序及排名累加由另一個獨立控制流程實作。
sub rankWeavingPolynomial ($lengths, $word, $stats=undef,
                          $options=undef) {
    my $normalized=Pastafari::WeavingSuffixFactor::_normalize_profile_options($options);
    die "月份長度必須是陣列參照\n" if ref($lengths) ne 'ARRAY';
    die "完整月份序列必須是陣列參照\n" if ref($word) ne 'ARRAY';
    die "診斷記錄必須是雜湊參照\n"
        if defined($stats) && ref($stats) ne 'HASH';
    countWeavingsPolynomial($lengths); # 驗證所有長度與總日數的限制
    my @remaining=map {0+"$_"} @$lengths;
    my $m=scalar @remaining;
    my $expected_days=0;
    $expected_days+=$_ for @remaining;
    die "完整月份序列長度不正確\n" if @$word!=$expected_days;

    my ($opened,$closed)=(0,0);
    my $rank=Math::BigInt->bone;
    my (%cache,%diagnostics);
    my $candidates=0;
    for my $value (@$word) {
        die "月份序列標籤必須是正整數\n"
            if !defined($value)
            || (ref($value) && !(blessed($value)
                                 && $value->isa('Math::BigInt')))
            || "$value" !~ /\A[0-9]+\z/;
        my $big=Math::BigInt->new("$value");
        die "月份序列標籤超出範圍\n"
            if $big<1 || $big>$m;
        my $chosen=0+"$big";
        my $upper=$opened<$m ? $opened+1 : $m;
        die "月份序列違反首次出現次序\n" if $chosen>$upper;
        die "月份序列使用已耗盡的月份\n" if !$remaining[$chosen-1];
        die "月份序列違反末次出現次序\n"
            if $remaining[$chosen-1]==1 && $chosen!=$closed+1;

        # 只計算字典序中位於真實下一個標籤之前的候選分支。
        for my $j (1 .. $chosen-1) {
            next if !$remaining[$j-1];
            next if $remaining[$j-1]==1 && $j!=$closed+1;
            my $next_opened=$j>$opened ? $j : $opened;
            my $next_closed=$remaining[$j-1]==1 ? $j : $closed;
            $remaining[$j-1]--;
            my $ways=
                Pastafari::WeavingSuffixFactor::_countWeavingSuffixFactoredState(
                    $lengths,\@remaining,$next_opened,$next_closed,
                    \%cache,\%diagnostics,$normalized
                );
            $remaining[$j-1]++;
            $rank->badd($ways);
            $candidates++;
        }
        $opened=$chosen if $chosen>$opened;
        $remaining[$chosen-1]--;
        $closed=$chosen if !$remaining[$chosen-1];
    }
    die "完整月份序列仍有未結束月份\n"
        if $closed!=$m || grep {$_} @remaining;
    if(defined $stats) {
        %$stats=(days=>$expected_days,candidates=>$candidates,
                 future_cache_hits=>($diagnostics{future_cache_hits}//0),
                 future_cache_misses=>($diagnostics{future_cache_misses}//0),
                 reverse_histogram_builds=>($diagnostics{profile_builds}//0),
                 stream_profile_builds=>($diagnostics{profile_disk_builds}//0),
                 stream_max_temp_file_bytes=>($diagnostics{profile_max_temp_file_bytes}//0));
    }
    return $rank;
}
1;
