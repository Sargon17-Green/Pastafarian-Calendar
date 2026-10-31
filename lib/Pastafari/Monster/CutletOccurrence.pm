package Pastafari::Monster::CutletOccurrence;
use v5.40;
use utf8;
use strict;
use warnings;
use Exporter 'import';
use Scalar::Util qw(blessed);
use Math::BigInt;
use Pastafari::SourceLanguageCatalog qw(cutlet_name_by_index);

our @EXPORT_OK = qw(cutlet_occurrence);

# 第五階段的局部語意：已給定的相鄰肉排日長和規範名稱索引。
# 年界、年數、月份交織和完整五欄日期均不在本原語內計算。
sub _bounded_positive ($x, $limit, $error) {
    die "$error\n" if !defined($x)
        || (ref($x) && !(blessed($x) && $x->isa('Math::BigInt')));
    my $digits = "$x";
    die "$error\n" if $digits !~ /\A[1-9][0-9]*\z/
        || length($digits) > length("$limit")
        || (length($digits) == length("$limit") && $digits gt "$limit");
    return 0 + $digits;
}

sub cutlet_occurrence ($lengths, $name_indices, $position) {
    die "肉排日長與名稱索引須為陣列\n"
        if ref($lengths) ne 'ARRAY' || ref($name_indices) ne 'ARRAY';
    my $n = scalar @$lengths;
    die "肉排數量須在六至十七之間\n"
        if $n < 6 || $n > 17 || @$name_indices != $n;

    my (@days, @names, %seen);
    my $total = 0;
    for my $i (0 .. $n - 1) {
        my $span = _bounded_positive($lengths->[$i], 5778, '肉排日長無效');
        my $name = _bounded_positive($name_indices->[$i], 17, '肉排名稱索引無效');
        die "肉排名稱索引不得重複\n" if $seen{$name}++;
        $total += $span;
        die "年份長度超出界限\n" if $total > 5778;
        push @days, $span;
        push @names, $name;
    }
    die "年份長度不足\n" if $total < 252;
    my $p = _bounded_positive($position, 5778, '日期位置無效');
    die "日期位置超出年份\n" if $p > $total;

    my $start = 0;
    for my $i (0 .. $n - 1) {
        my $last = $start + $days[$i];
        if ($p <= $last) {
            return {
                cutletIndex => $i + 1,
                cutletName => cutlet_name_by_index($names[$i]),
                dayInCutlet => Math::BigInt->new($p - $start),
            };
        }
        $start = $last;
    }
    die "找不到日期位置\n";
}

1;
