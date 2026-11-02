package Pastafari::Monster::StreamRankSelection;
use v5.40;
use utf8;
use strict;
use warnings;
use Exporter 'import';
use Math::BigInt;
use Scalar::Util qw(blessed);

our @EXPORT_OK = qw(choose_rank_from_stream);
my $M = Math::BigInt->new(2)->bpow(127)->bdec;
my $MAX_N = Math::BigInt->bone;
$MAX_N->bmul($_) for 2 .. 47;

sub _decimal ($value, $label) {
    die "$label 無效\n" if !defined($value)
        || (ref($value) && !(blessed($value) && $value->isa('Math::BigInt')));
    my $text = "$value";
    die "$label 無效\n" if $text !~ /\A(?:0|[1-9][0-9]*)\z/;
    return Math::BigInt->new($text);
}

# Private, modulus-parametric implementation for an independently enumerated small oracle.
# Production entry point fixes the modulus at 2^127-1 and caps N at 47!.
sub _choose_with_modulus ($first, $direction_step, $n, $modulus) {
    my $m = _decimal($modulus, '模數');
    die "模數必須大於一\n" if $m <= 1;
    my $f = _decimal($first, '首值');
    die "首值超出模數\n" if $f < 1 || $f > $m;
    die "方向必須為 +1 或 -1\n" if !defined($direction_step)
        || (ref($direction_step) && !(blessed($direction_step) && $direction_step->isa('Math::BigInt')))
        || "$direction_step" !~ /\A(?:\+?1|-1)\z/;
    my $step = "$direction_step" eq '-1' ? -1 : 1;
    my $N = _decimal($n, '選擇空間');
    die "選擇空間必須為正\n" if $N < 1;

    my $space = $m->copy;
    my $digits = 1;
    while ($space < $N) {
        $space->bmul($m);
        ++$digits;
    }
    my $word = Math::BigInt->bone;
    my $weight = Math::BigInt->bone;
    for my $j (0 .. $digits - 1) {
        my $digit = $f->copy->bdec->badd($step * $j)->bmod($m);
        $word->badd($digit->bmul($weight));
        $weight->bmul($m);
    }

    my $limit = $space->copy->bdiv($N)->bmul($N);
    # Skip the entire rejected suffix in O(1) BigInt operations.
    if ($word > $limit) {
        $word = $step == 1 ? Math::BigInt->bone : $limit->copy;
    }
    return $word->bdec->bmod($N)->binc;
}

sub choose_rank_from_stream ($first, $direction_step, $n) {
    my $f = _decimal($first, '首值');
    my $N = _decimal($n, '選擇空間');
    die "首值超出有效範圍\n" if $f < 1 || $f > $M;
    die "選擇空間超出有效範圍\n" if $N < 1 || $N > $MAX_N;
    return _choose_with_modulus($f, $direction_step, $N, $M);
}

1;
