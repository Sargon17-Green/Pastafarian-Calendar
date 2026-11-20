#!/usr/bin/env perl
use v5.40;
use utf8;
use strict;
use warnings;
use Time::HiRes qw(time);
use Math::BigInt;

# Exploratory independent counting implementation: exactly m columns, four
# occurrences of every symbol; the first and final occurrences are ordered.
# Every active column has remaining 3, 2, or 1. Encoding the active interval
# with ternary digits gives a collision-free dense state index.
my $months = shift(@ARGV) // 12;
die "expected integer 1..12\n" unless $months =~ /\A(?:[1-9]|1[0-2])\z/;
my $B = 1_000_000_000_000; # 10^12: exact 64-bit Perl integer limbs
my @pow = (1);
push @pow, $pow[-1] * 3 for 1 .. $months;
my @offset;
my $capacity = 0;
for my $opened (0 .. $months) {
    for my $closed (0 .. $opened) {
        $offset[$opened][$closed] = $capacity;
        $capacity += $pow[$opened - $closed];
    }
}
my @memo;
my $states = 0;
my $edges = 0;
my $start = time();
my $one = pack('Q<4',1,0,0,0);
my $solve;
$solve = sub ($opened, $closed, $code) {
    my $index = $offset[$opened][$closed] + $code;
    return $memo[$index] if defined $memo[$index];
    ++$states;
    if ($closed == $months) {
        return $memo[$index] = $one;
    }
    my ($a,$b,$c,$d)=(0,0,0,0);
    my $add = sub ($packed) {
        my ($x,$y,$z,$w) = unpack('Q<4', $packed);
        $a += $x; if($a >= $B){$a -= $B; $b++}
        $b += $y; if($b >= $B){$b -= $B; $c++}
        $c += $z; if($c >= $B){$c -= $B; $d++}
        $d += $w;
        ++$edges;
    };
    # The next symbol can be opened in the canonical first-use order.
    if ($opened < $months) {
        $add->($solve->($opened + 1,$closed,$code));
    }
    # Existing active symbols can advance, except their final occurrence
    # must respect the canonical last-use order.
    my $digits = $code;
    for my $i (0 .. $opened-$closed-1) {
        my $digit = $digits % 3;
        $digits = int($digits / 3);
        if ($digit < 2) {
            $add->($solve->($opened,$closed,$code+$pow[$i]));
        } elsif ($i == 0) {
            $add->($solve->($opened,$closed+1,int($code/3)));
        }
    }
    die "limb width exceeded\n" if $d >= $B;
    return $memo[$index] = pack('Q<4',$a,$b,$c,$d);
};
my $count = $solve->(0,0,0);
my @limbs=unpack('Q<4',$count);
my $decimal = $limbs[3];
for my $idx (reverse 0..2) { $decimal .= sprintf('%012d',$limbs[$idx]); }
$decimal =~ s/\A0+(?=\d)//;
# Independent arithmetic cross-check: total must not exceed all unique
# permutations of the 4-of-each multiset; bound built using Math::BigInt.
my $ceiling=Math::BigInt->bone;
$ceiling->bmul($_) for 2 .. ($months*4);
my $factorial4=24;
$ceiling->bdiv($factorial4) for 1 .. $months;
die "upper combinatorial bound violated\n" if Math::BigInt->new($decimal)->bcmp($ceiling) > 0;
printf "months=%d states=%d capacity=%d edges=%d seconds=%.3f count=%s\n", $months,$states,$capacity,$edges,time()-$start,$decimal;
