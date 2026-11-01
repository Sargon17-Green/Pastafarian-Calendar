package Pastafari::Monster::CutletPartitionGeneration;
use v5.40;
use utf8;
use strict;
use warnings;
use Exporter 'import';
use Math::BigInt;
use Scalar::Util qw(blessed);

our @EXPORT_OK = qw(cutlet_partition_family);

# 只採用切點組合的乘除及字典序 unranking，不呼叫規範遞迴分割計數器。
sub _bounded ($value, $maximum, $error) {
    die "$error\n" if !defined($value)
        || (ref($value) && !(blessed($value) && $value->isa('Math::BigInt')));
    my $digits = "$value";
    die "$error\n" if $digits !~ /\A[1-9][0-9]*\z/
        || length($digits) > length("$maximum")
        || (length($digits) == length("$maximum") && $digits gt "$maximum");
    return 0 + $digits;
}

sub cutlet_partition_family ($gate_count, $cutlet_count, $required = undef) {
    my $g = _bounded($gate_count, 137, '肉排區間閘數無效');
    die "肉排區間閘數須介於六至一百三十七\n" if $g < 6;
    my $k = _bounded($cutlet_count, 17, '肉排數量無效');
    die "肉排數量須介於六至十七\n" if $k < 6;
    die "肉排數量超出閘區間\n" if $k > $g;
    my $r = defined($required)
        ? _bounded($required, $g - 1, '指定內部分界無效')
        : undef;

    # 只使用局部快取，複製 BigInt 以避免結果或呼叫者改動計數。
    my %choose_cache;
    my $choose = sub ($n, $m) {
        return Math::BigInt->bzero if $n < 0 || $m < 0 || $m > $n;
        $m = $n - $m if $m > $n - $m;
        my $key = "$n:$m";
        return $choose_cache{$key}->copy if exists $choose_cache{$key};
        my $answer = Math::BigInt->bone;
        for my $j (1 .. $m) {
            $answer->bmul($n - $m + $j)->bdiv($j);
        }
        $choose_cache{$key} = $answer->copy;
        return $answer;
    };

    # 無必選切點時選 K-1 個內部閘；有必選切點則只選其餘 K-2 個。
    my $total = defined($r) ? $choose->($g - 2, $k - 2)
                            : $choose->($g - 1, $k - 1);
    my $unrank1 = sub ($rank1) {
        die "肉排分割排名無效\n" if !defined($rank1)
            || (ref($rank1) && !(blessed($rank1) && $rank1->isa('Math::BigInt')));
        my $digits = "$rank1";
        die "肉排分割排名無效\n" if $digits !~ /\A[1-9][0-9]*\z/;
        my $rank = Math::BigInt->new($digits);
        die "肉排分割排名超出範圍\n" if $rank->bcmp($total) > 0;

        my ($previous, $must_choose) = (0, defined($r) ? 1 : 0);
        my @cuts;
        for my $index (0 .. $k - 2) {
            my $after = $k - 2 - $index;
            my $last_candidate = $g - 1 - $after;
            my $selected;
            for my $candidate ($previous + 1 .. $last_candidate) {
                my $block;
                if (!$must_choose || $candidate == $r) {
                    $block = $choose->($g - 1 - $candidate, $after);
                } elsif ($candidate < $r) {
                    # 必選 r 仍在後綴：r 以外另挑 after-1 個。
                    $block = $choose->($g - 2 - $candidate, $after - 1);
                } else {
                    next; # 不可跨越尚未選取的必要切點。
                }
                next if $block->is_zero;
                if ($rank->bcmp($block) > 0) {
                    $rank->bsub($block);
                } else {
                    $selected = $candidate;
                    last;
                }
            }
            die "肉排分割排名內部錯誤\n" if !defined($selected);
            push @cuts, $selected;
            $previous = $selected;
            $must_choose = 0 if defined($r) && $selected == $r;
        }
        die "缺少指定內部分界\n" if $must_choose;
        my @lengths;
        $previous = 0;
        for my $cut (@cuts, $g) {
            push @lengths, $cut - $previous;
            $previous = $cut;
        }
        return \@lengths;
    };
    return { count => sub { $total->copy }, unrank1 => $unrank1 };
}

1;
