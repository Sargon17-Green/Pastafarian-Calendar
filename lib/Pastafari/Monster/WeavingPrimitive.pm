package Pastafari::Monster::WeavingPrimitive;
use v5.40;
use utf8;
use strict;
use warnings;
use Exporter 'import';
use Math::BigInt;
use Scalar::Util qw(blessed);
our @EXPORT_OK = qw(count_weavings rank_weaving unrank_weaving);

# Stage21 accepted primitive: twelve months / forty-eight days. No date semantics.
sub _counts ($profile) {
    die "月份長度須為陣列參照\n" if ref($profile) ne 'ARRAY';
    my $m = scalar @$profile;
    die "月份數超出本階段範圍\n" if $m < 1 || $m > 12;
    my (@lengths, $days);
    $days = 0;
    for my $v (@$profile) {
        die "月份長度須為正整數\n" if !defined($v) || ref($v) || "$v" !~ /\A[1-9][0-9]*\z/;
        die "總日數超出本階段範圍\n" if length("$v") > 2;
        my $length = int($v);
        $days += $length;
        die "總日數超出本階段範圍\n" if $days > 48;
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

# Active labels form an interval (closed,opened]. Digit zero means the first
# occurrence has happened; digit (length-2) means only the last is left.
# Distinct mixed-radix indices are assigned to all possible active intervals.
sub _solver ($lengths) {
    my $m = scalar @$lengths;
    my (@offset, @weight);
    my $capacity = 0;
    for my $opened (0 .. $m) {
        for my $closed (0 .. $opened) {
            $offset[$opened][$closed] = $capacity;
            my $size = 1;
            for my $j ($closed + 1 .. $opened) {
                $weight[$opened][$closed][$j] = $size;
                $size *= $lengths->[$j-1] - 1;
            }
            $capacity += $size;
        }
    }
    my @memo;
    my $one = pack('Q<4',1,0,0,0);
    my $base = 1_000_000_000_000;
    my $solve;
    $solve = sub ($self, $opened, $closed, $code) {
        my $index = $offset[$opened][$closed] + $code;
        return $memo[$index] if defined $memo[$index];
        return $memo[$index] = $one if $closed == $m;
        my ($a,$b,$c,$d) = (0,0,0,0);
        my $add = sub ($packed) {
            my ($x,$y,$z,$w) = unpack('Q<4',$packed);
            $a += $x; if ($a >= $base) { $a -= $base; ++$b; }
            $b += $y; if ($b >= $base) { $b -= $base; ++$c; }
            $c += $z; if ($c >= $base) { $c -= $base; ++$d; }
            $d += $w;
        };
        if ($opened < $m) {
            my $length = $lengths->[$opened];
            if ($length > 1) {
                $add->($self->($self,$opened+1,$closed,$code));
            } elsif ($opened == $closed) {
                $add->($self->($self,$opened+1,$closed+1,0));
            }
        }
        for my $j ($closed+1 .. $opened) {
            my $radix = $lengths->[$j-1]-1;
            my $weight = $weight[$opened][$closed][$j];
            my $digit = int($code/$weight) % $radix;
            if ($digit < $radix-1) {
                $add->($self->($self,$opened,$closed,$code+$weight));
            } elsif ($j == $closed+1) {
                $add->($self->($self,$opened,$closed+1,int($code/$radix)));
            }
        }
        die "計數超出精確位數\n" if $d >= $base;
        return $memo[$index] = pack('Q<4',$a,$b,$c,$d);
    };
    return ($solve, \@weight);
}

sub _as_bigint ($packed) {
    my @limbs = unpack('Q<4',$packed);
    my $decimal = $limbs[3];
    $decimal .= sprintf('%012d',$limbs[$_]) for reverse 0..2;
    $decimal =~ s/\A0+(?=\d)//;
    return Math::BigInt->new($decimal);
}

sub _rank_input ($rank, $max) {
    die "排名須為正整數\n" if !defined($rank)
        || (ref($rank) && !(blessed($rank) && $rank->isa('Math::BigInt')))
        || "$rank" !~ /\A[0-9]+\z/;
    my $r = Math::BigInt->new("$rank");
    die "排名超出範圍\n" if $r < 1 || $r > $max;
    return $r;
}

sub _next_state ($lengths, $weights, $opened, $closed, $code, $j) {
    if ($j == $opened + 1) {
        return $lengths->[$j-1] == 1
            ? ($opened+1,$closed+1,0)
            : ($opened+1,$closed,$code);
    }
    my $radix = $lengths->[$j-1] - 1;
    my $weight = $weights->[$opened][$closed][$j];
    my $digit = int($code/$weight) % $radix;
    return $digit == $radix-1
        ? ($opened,$closed+1,int($code/$radix))
        : ($opened,$closed,$code+$weight);
}

sub count_weavings ($profile) {
    my ($lengths) = _counts($profile);
    my ($solve) = _solver($lengths);
    return _as_bigint($solve->($solve,0,0,0));
}

sub rank_weaving ($profile, $word) {
    my ($lengths, $days) = _counts($profile);
    die "完整月份序列須為陣列參照\n" if ref($word) ne 'ARRAY';
    die "完整月份序列長度不正確\n" if @$word != $days;
    my ($solve, $weights) = _solver($lengths);
    my @remaining = @$lengths;
    my ($opened,$closed,$code) = (0,0,0);
    my $rank = Math::BigInt->bone;
    for my $value (@$word) {
        die "月份序列標籤無效\n" if !defined($value)
            || (ref($value) && !(blessed($value) && $value->isa('Math::BigInt')))
            || "$value" !~ /\A[1-9][0-9]*\z/
            || length("$value") > 2 || $value > @$lengths;
        my $j = int("$value");
        my $valid = 0;
        for my $candidate (_choices(\@remaining,$opened,$closed)) {
            my ($no,$nc,$code2) = _next_state($lengths,$weights,$opened,$closed,$code,$candidate);
            if ($candidate == $j) {
                --$remaining[$j-1];
                ($opened,$closed,$code) = ($no,$nc,$code2);
                $valid = 1;
                last;
            }
            $rank->badd(_as_bigint($solve->($solve,$no,$nc,$code2)));
        }
        die "月份序列違反交織次序或數量\n" if !$valid;
    }
    return $rank;
}

sub unrank_weaving ($profile, $rank) {
    my ($lengths, $days) = _counts($profile);
    my ($solve, $weights) = _solver($lengths);
    my $remaining_rank = _rank_input($rank,_as_bigint($solve->($solve,0,0,0)));
    my @remaining = @$lengths;
    my ($opened,$closed,$code) = (0,0,0);
    my @word;
    for (1 .. $days) {
        my $chosen = 0;
        for my $j (_choices(\@remaining,$opened,$closed)) {
            my ($no,$nc,$code2) = _next_state($lengths,$weights,$opened,$closed,$code,$j);
            my $ways = _as_bigint($solve->($solve,$no,$nc,$code2));
            if ($remaining_rank <= $ways) {
                push @word, $j;
                --$remaining[$j-1];
                ($opened,$closed,$code) = ($no,$nc,$code2);
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
