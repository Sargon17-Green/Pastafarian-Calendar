package Pastafari::Monster::WeavingPrimitive;
use v5.40;
use utf8;
use strict;
use warnings;
use Exporter 'import';
use Math::BigInt;
use Scalar::Util qw(blessed);

our @EXPORT_OK = qw(count_weavings rank_weaving unrank_weaving);

# 第一個生產排名原語：先首次出現、再依序末次出現。
# 限定小型設定檔；不得將其宣稱為完整曆法或大型年份的實作。
sub _counts ($profile) {
    die "月份長度須為陣列參照\n" if ref($profile) ne 'ARRAY';
    my $m = scalar @$profile;
    die "月份數超出本階段範圍\n" if $m < 1 || $m > 4;
    my @lengths;
    my $days = 0;
    for my $v (@$profile) {
        die "月份長度須為正整數\n" if !defined($v) || ref($v) || "$v" !~ /\A[1-9][0-9]*\z/;
        die "總日數超出本階段範圍\n" if length("$v") > 2;
        my $length = int($v);
        $days += $length;
        die "總日數超出本階段範圍\n" if $days > 12;
        push @lengths, $length;
    }
    return (\@lengths, $days);
}

sub _choices ($remaining, $opened, $closed) {
    my $m = scalar @$remaining;
    my $upper = $opened + 1 <= $m ? $opened + 1 : $m;
    return grep { $remaining->[$_ - 1] > 0
        && ($remaining->[$_ - 1] != 1 || $_ == $closed + 1) } (1 .. $upper);
}

sub _step ($remaining, $opened, $closed, $symbol) {
    my @next = @$remaining;
    --$next[$symbol - 1];
    $opened = $symbol if $symbol > $opened;
    $closed = $symbol if $next[$symbol - 1] == 0;
    return (\@next, $opened, $closed);
}

sub _suffix_count ($remaining, $opened, $closed, $memo) {
    my $key = join(',', $opened, $closed, @$remaining);
    return $memo->{$key}->copy if exists $memo->{$key};
    if (!grep { $_ } @$remaining) {
        return $memo->{$key} = Math::BigInt->bone;
    }
    my $sum = Math::BigInt->bzero;
    for my $j (_choices($remaining, $opened, $closed)) {
        my ($next, $o, $c) = _step($remaining, $opened, $closed, $j);
        $sum->badd(_suffix_count($next, $o, $c, $memo));
    }
    $memo->{$key} = $sum->copy;
    return $sum;
}

sub _rank_input ($rank, $max) {
    die "排名須為正整數\n" if !defined($rank)
        || (ref($rank) && !(blessed($rank) && $rank->isa('Math::BigInt')))
        || "$rank" !~ /\A[0-9]+\z/;
    my $r = Math::BigInt->new("$rank");
    die "排名超出範圍\n" if $r < 1 || $r > $max;
    return $r;
}

sub count_weavings ($profile) {
    my ($lengths) = _counts($profile);
    my %memo;
    return _suffix_count($lengths, 0, 0, \%memo)->copy;
}

sub rank_weaving ($profile, $word) {
    my ($lengths, $days) = _counts($profile);
    die "完整月份序列須為陣列參照\n" if ref($word) ne 'ARRAY';
    die "完整月份序列長度不正確\n" if @$word != $days;
    my @remaining = @$lengths;
    my ($opened, $closed) = (0, 0);
    my $rank = Math::BigInt->bone;
    my %memo;
    for my $value (@$word) {
        die "月份序列標籤無效\n" if !defined($value)
            || (ref($value) && !(blessed($value) && $value->isa('Math::BigInt')))
            || "$value" !~ /\A[1-9][0-9]*\z/
            || length("$value") > 2 || $value > @$lengths;
        my $j = int("$value");
        my @choices = _choices(\@remaining, $opened, $closed);
        my $valid = 0;
        for my $candidate (@choices) {
            my ($next, $o, $c) = _step(\@remaining, $opened, $closed, $candidate);
            if ($candidate == $j) {
                @remaining = @$next;
                ($opened, $closed) = ($o, $c);
                $valid = 1;
                last;
            }
            $rank->badd(_suffix_count($next, $o, $c, \%memo));
        }
        die "月份序列違反交織次序或數量\n" if !$valid;
    }
    return $rank;
}

sub unrank_weaving ($profile, $rank) {
    my ($lengths, $days) = _counts($profile);
    my %memo;
    my $max = _suffix_count($lengths, 0, 0, \%memo);
    my $remaining_rank = _rank_input($rank, $max);
    my @remaining = @$lengths;
    my ($opened, $closed) = (0, 0);
    my @word;
    for (1 .. $days) {
        my $chosen = 0;
        for my $candidate (_choices(\@remaining, $opened, $closed)) {
            my ($next, $o, $c) = _step(\@remaining, $opened, $closed, $candidate);
            my $ways = _suffix_count($next, $o, $c, \%memo);
            if ($remaining_rank <= $ways) {
                push @word, $candidate;
                @remaining = @$next;
                ($opened, $closed) = ($o, $c);
                $chosen = 1;
                last;
            }
            $remaining_rank->bsub($ways);
        }
        die "排名回推失敗\n" if !$chosen;
    }
    return \@word;
}

1;
