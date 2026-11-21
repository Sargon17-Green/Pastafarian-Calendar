#!/usr/bin/env perl
use v5.40;
use strict;
use warnings;

# Independent Stage22 static arithmetic oracle. It does not load or execute
# WeavingPrimitive.pm and does not claim a Native or differential PASS.
# For a profile L[1..m], let y[i]=L[i]-1>=0 and sum(y)<=52-m.
# The packed arena has m+1 empty-interval buckets and one bucket per
# nonempty interval, of size product(y[i..j]).

sub arena_states ($lengths) {
    my $m = scalar @$lengths;
    my $total = $m + 1;
    for my $i (0 .. $m-1) {
        my $product = 1;
        for my $j ($i .. $m-1) {
            $product *= $lengths->[$j] - 1;
            $total += $product;
        }
    }
    return $total;
}

# Retain only Pareto-optimal (suffix_sum, interval_sum) states.
# Future choices y>=0 are monotone in both coordinates, so a state
# dominated in both can never win for any remaining month lengths.
sub pareto ($candidates) {
    my @sorted = sort {
        $b->[0] <=> $a->[0] || $b->[1] <=> $a->[1]
    } @$candidates;
    my @keep;
    my $best_interval_sum = -1;
    for my $state (@sorted) {
        next if $state->[1] <= $best_interval_sum;
        push @keep, $state;
        $best_interval_sum = $state->[1];
    }
    return \@keep;
}

sub exact_maximum ($m) {
    my $budget = 52 - $m;
    my %states = (0 => [[0, 0, []]]);
    for my $step (1 .. $m) {
        my %next;
        for my $spent (keys %states) {
            for my $state (@{$states{$spent}}) {
                my ($tail, $sum, $path) = @$state;
                for my $y (0 .. $budget - $spent) {
                    my $new_tail = $y * (1 + $tail);
                    push @{$next{$spent + $y}}, [
                        $new_tail, $sum + $new_tail,
                        [@$path, $y + 1]
                    ];
                }
            }
        }
        %states = map { $_ => pareto($next{$_}) } keys %next;
    }
    my ($best, $profile) = (-1, undef);
    for my $spent (keys %states) {
        for my $state (@{$states{$spent}}) {
            my $value = $m + 1 + $state->[1];
            if ($value > $best) {
                ($best, $profile) = ($value, $state->[2]);
            }
        }
    }
    die "independent interval formula disagrees for m=$m\n"
        if arena_states($profile) != $best;
    return ($best, $profile);
}

my ($global, $global_m, $global_profile) = (-1, 0, undef);
my $m13 = 0;
for my $m (1 .. 13) {
    my ($max, $profile) = exact_maximum($m);
    my $sum = 0;
    $sum += $_ for @$profile;
    die "out-of-contract witness\n" if $sum > 52 || @$profile != $m;
    print "m=$m max_states=$max witness=", join(',', @$profile), "\n";
    $m13 = $max if $m == 13;
    if ($max > $global) {
        ($global, $global_m, $global_profile) = ($max, $m, $profile);
    }
}
my $benchmark = arena_states([(4) x 13]);
my $bytes = $global * 32 + int(($global + 7) / 8);
die "unexpected global max" unless $global == 4_021_367 && $global_m == 12;
die "unexpected 13-month max" unless $m13 == 3_855_027;
die "unexpected 13x4 arena" unless $benchmark == 3_587_219;
die "unexpected packed bytes" unless $bytes == 129_186_415;
print "STATIC_QA_PASS=1\n";
print "GLOBAL_MAX_STATES=$global\n";
print "GLOBAL_MAX_MONTHS=$global_m\n";
print "GLOBAL_MAX_PROFILE=", join(',', @$global_profile), "\n";
print "MAX_13_MONTH_STATES=$m13\n";
print "BENCHMARK_13X4_STATES=$benchmark\n";
print "GLOBAL_MAX_PACKED_BYTES=$bytes\n";
print "PRODUCER_TESTED=0\nNATIVE_PASS_CLAIM=0\nFULL_YEAR_VERIFIED=0\n";
