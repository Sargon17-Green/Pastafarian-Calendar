#!/usr/bin/env perl
use v5.40;
use utf8;
use strict;
use warnings;
use Math::BigInt;

# Combinatorial independent upper bound; no production DP or packed limbs.
my $nmax = 52;
my $mmax = 13;
my @fact = (Math::BigInt->bone());
for my $n (1 .. $nmax) { push @fact, $fact[-1]->copy()->bmul($n) }
my ($max_count,$arg_max)=(Math::BigInt->bzero(),0);
for my $m (1 .. $mmax) {
    my $q=int($nmax/$m);
    my $r=$nmax % $m;
    my $den=$fact[$m]->copy();
    for (1..$r) {$den->bmul($fact[$q+1])}
    for (1..($m-$r)) {$den->bmul($fact[$q])}
    my $bound=$fact[$nmax]->copy()->bdiv($den);
    if ($bound->bcmp($max_count)>0) { $max_count=$bound; $arg_max=$m; }
}
my @dp;
$dp[0][0] = [1, []];
my ($max_product,$best)=(0,[]);
for my $k (1 .. $mmax) {
    for my $n (2*$k .. $nmax) {
        for my $length (2 .. $n-2*($k-1)) {
            next unless defined $dp[$k-1][$n-$length];
            my $prev=$dp[$k-1][$n-$length];
            my $value=($length-1)*$prev->[0];
            if (!defined($dp[$k][$n]) || $value > $dp[$k][$n][0]) {
                $dp[$k][$n]=[$value,[$length,@{$prev->[1]}]];
            }
        }
        next unless defined $dp[$k][$n];
        if ($dp[$k][$n][0] > $max_product) {
            $max_product=$dp[$k][$n][0];
            $best=$dp[$k][$n][1];
        }
    }
}
my $buckets=($mmax+1)*($mmax+2)/2;
my $exclusive_index_cap=$max_product*$buckets;
die "capacity count exceeds 48 digits\n" unless length($max_count->bstr) < 48;
die "unexpected count bound\n" unless "$max_count" eq '14778213400262135041705388361938994140625';
die "unexpected product\n" unless $max_product == 1769472;
die "unexpected index cap\n" unless $exclusive_index_cap == 185794560;
print "STAGE22_STATIC_CAPACITY_PASS=1\n";
print "MAX_FIRST_ORDERED_COUNT_BOUND=$max_count\n";
print "BOUND_DIGITS=", length($max_count->bstr), "\n";
print "MAX_PRODUCT=$max_product\n";
print "MAX_PRODUCT_PROFILE=", join(',',@$best), "\n";
print "MAX_BUCKETS=$buckets\n";
print "EXCLUSIVE_MEMO_INDEX_BOUND=$exclusive_index_cap\n";
