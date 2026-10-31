package Pastafari::Monster::FiveFieldProjection;
use v5.40;
use utf8;
use strict;
use warnings;
use Exporter 'import';
use Scalar::Util qw(blessed);
use Math::BigInt;
use Pastafari::Monster::YearOccurrence qw(year_occurrence);
use Pastafari::Monster::CutletOccurrence qw(cutlet_occurrence);
use Pastafari::SourceLanguageCatalog qw(month_name_by_index);

our @EXPORT_OK = qw(five_field_projection);

# A fully materialized, externally built year; never produces gates, a year,
# a month weaving, a rank, or the normative calendarDate itself.
sub _bounded ($value, $maximum, $error) {
    die "$error\n" if !defined($value)
        || (ref($value) && !(blessed($value) && $value->isa('Math::BigInt')));
    my $digits = "$value";
    die "$error\n" if $digits !~ /\A[1-9][0-9]*\z/
        || length($digits) > length("$maximum")
        || (length($digits) == length("$maximum") && $digits gt "$maximum");
    return 0 + $digits;
}

sub five_field_projection ($year, $structure, $target_day) {
    die "年份記錄須為雜湊\n" if ref($year) ne 'HASH';
    die "年份結構須為雜湊\n" if ref($structure) ne 'HASH';

    # Stage 6 checks complete year bounds and closed-right gate membership.
    my $number = year_occurrence([$year], $target_day);
    my $open = Math::BigInt->new("$year->{openGateDay}");
    my $close = Math::BigInt->new("$year->{closeGateDay}");
    my $span = $close->copy->bsub($open)->numify;
    my $position = Math::BigInt->new("$target_day")->bsub($open)->numify;

    for my $key (qw(cutletPartition cutletNames monthLengths monthNames monthWeaving)) {
        die "年份結構缺少陣列：$key\n" if ref($structure->{$key}) ne 'ARRAY';
    }
    my $cutlet_lengths = $structure->{cutletPartition};
    my $cutlet_names = $structure->{cutletNames};
    my $total_cutlets = 0;
    $total_cutlets += _bounded($_, 5778, '肉排日長無效') for @$cutlet_lengths;
    die "肉排分段總日數與年份不符\n" if $total_cutlets != $span;
    # Stage 5 checks cutlet-count, unique catalogue indices and day membership.
    my $cutlet = cutlet_occurrence($cutlet_lengths, $cutlet_names, $position);

    my $lengths = $structure->{monthLengths};
    my $names = $structure->{monthNames};
    my $word = $structure->{monthWeaving};
    my $m = scalar @$lengths;
    die "月份數量超出界限\n" if $m < 3 || $m > 47 || @$names != $m;
    die "月份交織長度與年份不符\n" if @$word != $span;
    my (@counts, %used_names);
    my $total_months = 0;
    for my $i (0 .. $m - 1) {
        my $n = _bounded($lengths->[$i], 123, '月份日長無效');
        die "月份日長須至少四日\n" if $n < 4;
        $total_months += $n;
        push @counts, $n;
        my $name_idx = _bounded($names->[$i], 47, '月份名稱索引無效');
        die "月份名稱索引不得重複\n" if $used_names{$name_idx}++;
    }
    die "月份日長總數與年份不符\n" if $total_months != $span;

    my @seen = (0) x $m;
    my @first = (-1) x $m;
    my @last = (-1) x $m;
    my ($chosen_month, $day_in_month);
    for my $i (0 .. $#$word) {
        my $month = _bounded($word->[$i], $m, '交織月份索引無效');
        my $j = $month - 1;
        $first[$j] = $i if $first[$j] == -1;
        $last[$j] = $i;
        ++$seen[$j];
        if ($i == $position - 1) {
            $chosen_month = $j;
            $day_in_month = $seen[$j];
        }
    }
    for my $i (0 .. $m - 1) {
        die "月份出現次數不符\n" if $seen[$i] != $counts[$i];
        if ($i > 0) {
            die "月份首次或末次出現順序無效\n"
                if $first[$i - 1] >= $first[$i] || $last[$i - 1] >= $last[$i];
        }
    }
    return [
        $number,
        $cutlet->{cutletName},
        $cutlet->{dayInCutlet},
        month_name_by_index($names->[$chosen_month]),
        Math::BigInt->new($day_in_month),
    ];
}

1;
