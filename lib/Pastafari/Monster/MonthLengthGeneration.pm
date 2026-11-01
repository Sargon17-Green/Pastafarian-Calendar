package Pastafari::Monster::MonthLengthGeneration;
use v5.40;
use utf8;
use strict;
use warnings;
use Exporter 'import';
use Math::BigInt;
use Scalar::Util qw(blessed);

our @EXPORT_OK = qw(month_length_family);

sub _bounded ($value, $maximum, $message) {
    die "$message\n" if !defined($value)
        || (ref($value) && !(blessed($value) && $value->isa('Math::BigInt')));
    my $digits = "$value";
    die "$message\n" if $digits !~ /\A[1-9][0-9]*\z/
        || length($digits) > length("$maximum")
        || (length($digits) == length("$maximum") && $digits gt "$maximum");
    return 0 + $digits;
}

sub month_length_family ($year_span, $month_count) {
    my $span = _bounded($year_span, 5778, '年份日數無效');
    die "年份日數須介於 252 至 5778\n" if $span < 252;
    my $months = _bounded($month_count, 47, '月份數量無效');
    die "月份數量須介於 3 至 47\n" if $months < 3;
    die "月份數量與年長不相容\n"
        if $span < 4 * $months || $span > 123 * $months;

    # 按剩餘月份個數、剩餘日數計數。滑動窗口與規範的遞迴分支不同。
    my @counts;
    $counts[0] = [Math::BigInt->bone];
    for my $k (1 .. $months) {
        my @row;
        my $window = Math::BigInt->bzero;
        my $previous = $counts[$k - 1];
        for my $sum (4 * $k .. ($span < 123 * $k ? $span : 123 * $k)) {
            $window->badd($previous->[$sum - 4])
                if defined $previous->[$sum - 4];
            $window->bsub($previous->[$sum - 124])
                if $sum >= 124 && defined $previous->[$sum - 124];
            $row[$sum] = $window->copy;
        }
        $counts[$k] = \@row;
    }
    my $total = $counts[$months][$span]->copy;
    die "月份配置不存在\n" if $total->is_zero;
    my $unrank1 = sub ($rank1) {
        die "月份配置排名無效\n" if !defined($rank1)
            || (ref($rank1) && !(blessed($rank1) && $rank1->isa('Math::BigInt')));
        my $digits = "$rank1";
        die "月份配置排名無效\n" if $digits !~ /\A[1-9][0-9]*\z/;
        my $rank = Math::BigInt->new($digits);
        die "月份配置排名超出範圍\n" if $rank->bcmp($total) > 0;
        my ($remaining, @lengths) = ($span);
        for my $k (reverse 1 .. $months) {
            my $selected;
            for my $x (4 .. 123) {
                next if $x > $remaining;
                my $block = $counts[$k - 1][$remaining - $x];
                next if !defined $block || $block->is_zero;
                if ($rank->bcmp($block) > 0) {
                    $rank->bsub($block);
                } else {
                    $selected = $x;
                    last;
                }
            }
            die "月份配置排名內部錯誤\n" if !defined $selected;
            push @lengths, $selected;
            $remaining -= $selected;
        }
        die "月份配置剩餘日數非零\n" if $remaining != 0;
        return \@lengths;
    };
    return { count => sub { $total->copy }, unrank1 => $unrank1 };
}

1;
