package Pastafari::Monster::YearOccurrence;
use v5.40;
use utf8;
use strict;
use warnings;
use Exporter 'import';
use Scalar::Util qw(blessed);
use Math::BigInt;

our @EXPORT_OK = qw(year_occurrence);

# 第六階段只投影已建立的相鄰年份區間之年份編號。
# 不生成 gate、不選擇年份，也不計算完整五欄日期。
sub _integer_copy ($value, $error) {
    die "$error\n" if !defined($value);
    die "$error\n" if ref($value)
        && !(blessed($value) && $value->isa('Math::BigInt'));
    my $digits = "$value";
    die "$error\n" if $digits !~ /\A-?(?:0|[1-9][0-9]*)\z/;
    return Math::BigInt->new($digits);
}

sub _validated_years ($years) {
    die "年份區間須為陣列\n" if ref($years) ne 'ARRAY';
    my $count = scalar @$years;
    die "年份區間數量須在一至一百零一之間\n"
        if $count < 1 || $count > 101;

    my @validated;
    for my $i (0 .. $#$years) {
        my $record = $years->[$i];
        die "年份區間記錄須為雜湊\n" if ref($record) ne 'HASH';
        my $number = _integer_copy($record->{number}, '年份編號無效');
        my $open = _integer_copy($record->{openGateDay}, '開閘日無效');
        my $close = _integer_copy($record->{closeGateDay}, '閉閘日無效');
        die "年份區間方向無效\n" if $open >= $close;
        my $span = $close->copy->bsub($open);
        die "年份日數超出規範界限\n" if $span < 252 || $span > 5778;

        if (@validated) {
            my $previous = $validated[-1];
            my $expected_number = $previous->{number}->copy->badd(1);
            die "年份編號必須連續遞增\n"
                if $number->bcmp($expected_number) != 0;
            die "相鄰年份閘日必須連續銜接\n"
                if $open->bcmp($previous->{close}) != 0;
        }

        push @validated, {
            number => $number,
            open => $open,
            close => $close,
        };
    }
    return \@validated;
}

sub year_occurrence ($years, $target_day) {
    my $intervals = _validated_years($years);
    my $target = _integer_copy($target_day, '目標日無效');

    # 以閉閘日尋找第一個 closeGateDay >= target 的區間。
    # 共用閘日因此歸屬前一年，符合 openGateDay < target <= closeGateDay。
    my ($low, $high) = (0, $#$intervals);
    while ($low <= $high) {
        my $middle = int(($low + $high) / 2);
        if ($intervals->[$middle]{close}->bcmp($target) >= 0) {
            $high = $middle - 1;
        } else {
            $low = $middle + 1;
        }
    }

    die "目標日不在提供的年份區間內\n" if $low > $#$intervals;
    my $chosen = $intervals->[$low];
    die "目標日不在提供的年份區間內\n"
        if $target->bcmp($chosen->{open}) <= 0
        || $target->bcmp($chosen->{close}) > 0;

    return $chosen->{number}->copy;
}

1;
