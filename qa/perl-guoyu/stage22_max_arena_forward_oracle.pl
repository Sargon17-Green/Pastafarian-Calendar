#!/usr/bin/env perl
use v5.40;
use strict;
use warnings;
use Math::BigInt;

# PROJECT_ID: PC-BRANCH-PERL-GUOYU
# Independent Stage22 oracle: forward event-transfer dynamic programming.
# It never loads, includes, or invokes the production WeavingPrimitive.pm.
# Labels occur in increasing first-appearance order and increasing last-
# appearance order; a label's intermediate appearances can interleave.
# Counts are four unsigned little-endian base-2**32 limbs, not the production
# decimal-limb packed memoized recursive suffix engine.
my @length = (3,4,4,5,5,5,5,5,5,4,4,3);
if (exists $ENV{STAGE22_ORACLE_PROFILE}) {
    my $value = $ENV{STAGE22_ORACLE_PROFILE};
    die "bad profile syntax\n" unless $value =~ /\A[1-9][0-9]*(?:,[1-9][0-9]*)*\z/;
    @length = map { int($_) } split /,/, $value;
}
die "profile is out of the 13/52 contract\n"
    if @length < 1 || @length > 13 || grep { $_ < 1 || $_ > 52 } @length;
my $months = scalar @length;
my $days = 0; $days += $_ for @length;
die "profile has too many days\n" if $days > 52;
my $mode = shift(@ARGV) // 'count';
die "usage: $0 count | lex WORD_CSV\n" unless $mode eq 'count' || $mode eq 'lex';
my $file = $mode eq 'lex' ? shift(@ARGV) : undef;
die "lex requires a word-file path\n" if $mode eq 'lex' && (!defined($file) || @ARGV);
die "count takes no arguments\n" if $mode eq 'count' && @ARGV;

my (@offset, @ranges, @layers);
my $owners = '';
my $capacity = 0;
for my $opened (0 .. $months) {
    for my $closed (0 .. $opened) {
        my (@weight, @radix);
        my $size = 1;
        for my $j ($closed + 1 .. $opened) {
            $weight[$j] = $size;
            $radix[$j] = $length[$j - 1] - 1;
            $size *= $radix[$j];
        }
        $offset[$opened][$closed] = $capacity;
        push @ranges, [$opened, $closed, $capacity, $size, \@weight, \@radix];
        my $rid = $#ranges;
        $owners .= pack('S<', $rid) x $size;
        my $completed = 0;
        $completed += $length[$_ - 1] for 1 .. $closed;
        for my $code (0 .. $size - 1) {
            my $used = $completed;
            my $remaining = $code;
            for my $j ($closed + 1 .. $opened) {
                $used += 1 + $remaining % $radix[$j];
                $remaining = int($remaining / $radix[$j]);
            }
            die "state depth out of bounds\n" if $used > $days;
            $layers[$used] .= pack('L<', $capacity + $code);
        }
        $capacity += $size;
    }
}
die "arena count unexpectedly changed\n" if !exists($ENV{STAGE22_ORACLE_PROFILE}) && $capacity != 4_021_367;
my $zero = "\0" x ($capacity * 16);
my $mask = 0xffffffff;

# Add four base-2**32 words into a packed counter. Every limb sum fits a
# native 64-bit integer; the high carry is checked, never silently wrapped.
sub add_words ($buf, $index, $a, $b, $c, $d) {
    my $position = 16 * $index;
    my ($v0, $v1, $v2, $v3) = unpack('L<4', substr($$buf, $position, 16));
    my $n = $v0 + $a;
    $v0 = $n & $mask;
    $n = $v1 + $b + ($n >> 32);
    $v1 = $n & $mask;
    $n = $v2 + $c + ($n >> 32);
    $v2 = $n & $mask;
    $n = $v3 + $d + ($n >> 32);
    die "count exceeds 128 bits\n" if $n > $mask;
    substr($$buf, $position, 16, pack('L<4', $v0, $v1, $v2, $n));
}

sub decimal ($bytes) {
    my @words = unpack('L<4', $bytes);
    my $value = Math::BigInt->bzero;
    for my $w (reverse @words) {
        $value->blsft(32)->badd($w);
    }
    return $value->bstr;
}

# The event transition is derived from the chronological event language.
# Opening label j grows the active interval; finishing the lowest active
# label shrinks it; intermediate appearances advance that label's progress.
# Invalid events are represented by undef.
sub step ($opened, $closed, $code, $j) {
    return undef if $j <= $closed || $j > $opened + 1 || $j > $months;
    if ($j == $opened + 1) {
        return undef if $length[$j - 1] == 1 && $opened != $closed;
        return $length[$j - 1] == 1
            ? [$opened + 1, $closed + 1, 0]
            : [$opened + 1, $closed, $code];
    }
    my $radix = $length[$j - 1] - 1;
    my $weight = 1;
    for my $k ($closed + 1 .. $j - 1) { $weight *= $length[$k - 1] - 1; }
    my $progress = int($code / $weight) % $radix;
    if ($progress + 1 < $radix) {
        return [$opened, $closed, $code + $weight];
    }
    return undef if $j != $closed + 1;
    return [$opened, $closed + 1, int($code / $radix)];
}

my $terminal = $offset[$months][$months];
my $bits = $zero;
my $active_states = 0;
my $edges = 0;
if ($mode eq 'count') {
    substr($bits, 0, 16, pack('L<4', 1, 0, 0, 0));
    for my $depth (0 .. $days - 1) {
        for my $index (unpack('L<*', $layers[$depth] // '')) {
            my ($a, $b, $c, $d) = unpack('L<4', substr($bits, 16*$index, 16));
            next if !($a | $b | $c | $d);
            ++$active_states;
            my $r = $ranges[unpack('S<', substr($owners, 2*$index, 2))];
            my ($opened, $closed, $base, $size, $weight, $radix) = @$r;
            my $code = $index - $base;
            if ($opened < $months) {
                if ($length[$opened] > 1) {
                    add_words(\$bits, $offset[$opened+1][$closed] + $code, $a,$b,$c,$d); ++$edges;
                } elsif ($opened == $closed) {
                    add_words(\$bits, $offset[$opened+1][$closed+1], $a,$b,$c,$d); ++$edges;
                }
            }
            for my $j ($closed+1 .. $opened) {
                my $digit = int($code/$weight->[$j]) % $radix->[$j];
                if ($digit + 1 < $radix->[$j]) {
                    add_words(\$bits, $index + $weight->[$j], $a,$b,$c,$d); ++$edges;
                } elsif ($j == $closed+1) {
                    add_words(\$bits, $offset[$opened][$closed+1] + int($code/$radix->[$j]), $a,$b,$c,$d); ++$edges;
                }
            }
        }
    }
    print decimal(substr($bits, 16*$terminal, 16)), "\n";
} else {
    substr($bits, 16*$terminal, 16, pack('L<4', 1, 0, 0, 0));
    for (my $depth = $days - 1; $depth >= 0; --$depth) {
        for my $index (unpack('L<*', $layers[$depth] // '')) {
            my $r = $ranges[unpack('S<', substr($owners, 2*$index, 2))];
            my ($opened, $closed, $base, $size, $weight, $radix) = @$r;
            my $code = $index - $base;
            my ($a, $b, $c, $d) = (0,0,0,0);
            my @children;
            if ($opened < $months) {
                if ($length[$opened] > 1) {
                    push @children, $offset[$opened+1][$closed] + $code;
                } elsif ($opened == $closed) {
                    push @children, $offset[$opened+1][$closed+1];
                }
            }
            for my $j ($closed+1 .. $opened) {
                my $digit = int($code/$weight->[$j]) % $radix->[$j];
                if ($digit + 1 < $radix->[$j]) {
                    push @children, $index + $weight->[$j];
                } elsif ($j == $closed+1) {
                    push @children, $offset[$opened][$closed+1] + int($code/$radix->[$j]);
                }
            }
            for my $child (@children) {
                my ($v0,$v1,$v2,$v3) = unpack('L<4', substr($bits, 16*$child, 16));
                my $n=$a+$v0; $a=$n&$mask;
                $n=$b+$v1+($n>>32); $b=$n&$mask;
                $n=$c+$v2+($n>>32); $c=$n&$mask;
                $n=$d+$v3+($n>>32);
                die "reverse count exceeds 128 bits\n" if $n > $mask;
                $d=$n;
                ++$edges;
            }
            substr($bits, 16*$index, 16, pack('L<4', $a,$b,$c,$d));
            ++$active_states if $a | $b | $c | $d;
        }
    }
    my $total = decimal(substr($bits, 0, 16));
    open my $fh, '<:raw', $file or die "cannot open word file: $!\n";
    my $line = <$fh>;
    close $fh;
    die "empty word file\n" unless defined $line;
    $line =~ s/\r?\n\z//;
    die "invalid CSV format\n" unless $line =~ /\A[1-9][0-9]*(?:,[1-9][0-9]*)*\z/;
    my @word = split /,/, $line;
    die "wrong word length\n" unless @word == $days;
    my ($opened,$closed,$code)=(0,0,0);
    my $ordinal = Math::BigInt->bone;
    for my $value (@word) {
        my $selected;
        for my $j ($closed+1 .. $opened+1) {
            my $next = step($opened,$closed,$code,$j) // next;
            my ($no,$nc,$ncode)=@$next;
            my $next_index = $offset[$no][$nc] + $ncode;
            if ($j < $value) {
                $ordinal->badd(decimal(substr($bits, 16*$next_index,16)));
                next;
            }
            if ($j == $value) {
                ($opened,$closed,$code)=($no,$nc,$ncode);
                $selected=1;
            }
            last;
        }
        die "word violates event order\n" unless $selected;
    }
    die "incomplete word\n" unless $opened==$months && $closed==$months && $code==0;
    print "$total\nlexical_ordinal=", $ordinal->bstr, "\n";
}
print STDERR "profile_months=$months days=$days capacity=$capacity nonzero_states=$active_states transitions=$edges\n" unless $ENV{STAGE22_ORACLE_QUIET};
