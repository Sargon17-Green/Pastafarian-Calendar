use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib';
use Pastafari::Monster::StreamRankSelection qw(choose_rank_from_stream);

# Oracle A: bounded native-integer simulation, with direct sampling and repeated rejection.
# It never calls production modulus, sampling, skip or residue helpers.
sub brute ($m, $first, $step, $n) {
    my ($capacity, $width) = ($m, 1);
    while ($capacity < $n) { $capacity *= $m; ++$width; }
    my ($word, $place) = (1, 1);
    for my $j (0 .. $width - 1) {
        my $current = ($first - 1 + $step * $j) % $m;
        $current += $m if $current < 0;
        $word += $current * $place;
        $place *= $m;
    }
    my $limit = int($capacity / $n) * $n;
    my $turns = 0;
    while ($word > $limit) {
        $word += $step;
        $word = 1 if $word > $capacity;
        $word = $capacity if $word < 1;
        die 'oracle did not terminate' if ++$turns > $capacity;
    }
    return 1 + (($word - 1) % $n);
}

my $small_cases = 0;
for my $m (2, 3, 5, 7) {
    for my $first (1 .. $m) {
        for my $step (-1, 1) {
            for my $n (1 .. $m**3) {
                my $expected = brute($m, $first, $step, $n);
                my $actual = Pastafari::Monster::StreamRankSelection::_choose_with_modulus($first,$step,$n,$m);
                is("$actual", "$expected", "small exhaustive m=$m first=$first step=$step n=$n");
                ++$small_cases;
            }
        }
    }
}

my $M = Math::BigInt->new(2)->bpow(127)->bsub(1);
my $fac = Math::BigInt->bone;
$fac->bmul($_) for 2 .. 47;

# Oracle B: BigInt scalar version that recomputes every sampled term directly and
# derives the residue independently. Exhaustive A above covers iterative rejection.
sub big_oracle ($f0,$dir,$n0) {
    my $f = Math::BigInt->new("$f0");
    my $n = Math::BigInt->new("$n0");
    my $span = $M->copy;
    my $count = 1;
    while ($span->bcmp($n) < 0) { $span->bmul($M); ++$count; }
    my $v = Math::BigInt->bone;
    for my $j (0 .. $count - 1) {
        my $sample = $f->copy->badd($dir * $j)->bdec;
        $sample->bmod($M);
        my $factor = $M->copy->bpow($j);
        $v->badd($sample->bmul($factor));
    }
    my $q = $span->copy->bdiv($n);
    my $end = $q->bmul($n);
    if ($v->bcmp($end) > 0) {
        $v = $dir == 1 ? Math::BigInt->bone : $end->copy;
    }
    my $quotient = $v->copy->bdec->bdiv($n);
    my $remainder = $v->copy->bdec->bsub($quotient->bmul($n));
    return $remainder->binc;
}

my $large_cases = 0;
my @sizes = (Math::BigInt->bone, Math::BigInt->new(2), Math::BigInt->new(3),
             $M->copy->bdec, $M->copy, $M->copy->binc, $fac->copy);
my @firsts = (Math::BigInt->bone, Math::BigInt->new(2), $M->copy->bdec, $M->copy);
for my $size (@sizes) {
    for my $first (@firsts) {
        for my $step (-1, 1) {
            my ($old_first, $old_size) = ("$first", "$size");
            my $actual = choose_rank_from_stream($first,Math::BigInt->new($step),$size);
            my $expected = big_oracle($first,$step,$size);
            is("$actual","$expected",'independent real-modulus rank');
            ok($actual >= 1 && $actual <= $size,'rank in range');
            is("$first",$old_first,'input first remains intact');
            is("$size",$old_size,'input N remains intact');
            ++$large_cases;
        }
    }
}

# Concrete accepted/rejected boundaries for one-digit / two-digit arithmetic.
is(''.choose_rank_from_stream($M,1,2), '1', 'short rejected + direction wraps to 1');
is(''.choose_rank_from_stream($M,-1,2), '2', 'short rejected - direction walks to limit');
is(''.choose_rank_from_stream($M->copy->bdec,1,$M->copy->binc), ''.big_oracle($M->copy->bdec,1,$M->copy->binc),'wide W equals L accepted');
is(''.choose_rank_from_stream($M->copy->bdec,1,$M->copy->badd(2)), ''.big_oracle($M->copy->bdec,1,$M->copy->badd(2)),'wide W above L wraps');
is(''.choose_rank_from_stream(1,-1,$M->copy->bmul(2)), ''.($M->copy->bmul(2)), 'wide W=L+1 negative step lands on L');

my $bfirst = Math::BigInt->new(123);
my $bn = Math::BigInt->new(17);
my $before_first = "$bfirst";
my $before_n = "$bn";
my $out = choose_rank_from_stream($bfirst,Math::BigInt->new(-1),$bn);
$out->badd(100000);
is(''.choose_rank_from_stream($bfirst,-1,$bn),''.big_oracle($bfirst,-1,$bn),'new output BigInt is not aliased to inputs');
is("$bfirst",$before_first,'first BigInt unchanged after return modification');
is("$bn",$before_n,'N BigInt unchanged after return modification');

my @bad_first = (undef, 0, '00', '01', -1, '1.0', 'NaN', '', ' 1', '1 ', [], {}, $M->copy->binc);
for my $bad (@bad_first) {
    ok(!eval { choose_rank_from_stream($bad,1,3); 1 }, 'reject invalid first');
}
my @bad_n = (undef, 0, '00', '03', -1, '1.0', 'NaN', '', ' 1', '1 ', [], {}, $fac->copy->binc);
for my $bad (@bad_n) {
    ok(!eval { choose_rank_from_stream(1,1,$bad); 1 }, 'reject invalid N');
}
for my $bad (undef,0,2,-2,'01','-01','1.0','NaN','',[],{},' 1', '1 ') {
    ok(!eval { choose_rank_from_stream(1,$bad,3); 1 }, 'reject invalid direction');
}

note("STAGE11_SMALL_MODULUS_CASES=$small_cases");
note("STAGE11_REAL_MODULUS_CASES=$large_cases");
note('STAGE11_INDEPENDENT_BIGINT_ORACLE=1');
note('STAGE11_FULL_GENERATOR_NOT_VERIFIED');
done_testing;
