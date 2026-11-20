#!/usr/bin/env perl
use v5.40;
use strict;
use warnings;
use bytes;
use Digest::SHA;
use Math::BigInt;

# Independent enumeration of two-occurrence words with strictly increasing
# first- and last-occurrence label order. Does not call production modules.
my $months = 12;
my @words;
my $visit;
$visit = sub ($opened, $closed, $encoded) {
    if ($opened == $months && $closed == $months) {
        push @words, $encoded;
        return;
    }
    # Opening and closing ranks are independent occurrence-order counters.
    $visit->($opened + 1, $closed, $encoded . chr($opened + 1))
        if $opened < $months;
    $visit->($opened, $closed + 1, $encoded . chr($closed + 1))
        if $closed < $opened;
};
$visit->(0, 0, '');

my $expected = Math::BigInt->new(1);
for my $k (13 .. 24) { $expected->bmul($k) }
for my $k (2 .. 12) { $expected->bdiv($k) }
$expected->bdiv(13);  # C(24,12) / 13
my $count = scalar @words;
die "Catalan12 count mismatch: $count != $expected\n"
    unless $count == $expected && $count == 208_012;

@words = sort @words;  # byte value 1..12 is numeric lexicographic order
my $sha = Digest::SHA->new(256);
my $previous;
for my $encoded (@words) {
    die "word length mismatch\n" unless length($encoded) == 24;
    die "lexicographic monotonicity mismatch\n"
        if defined($previous) && $previous ge $encoded;
    $previous = $encoded;
    my @labels = unpack('C*', $encoded);
    my (@count, @first, @last);
    for my $pos (0 .. $#labels) {
        my $label = $labels[$pos];
        die "label out of range\n" unless $label >= 1 && $label <= 12;
        $count[$label]++;
        $first[$label] //= $pos;
        $last[$label] = $pos;
    }
    for my $label (1 .. 12) {
        die "multiplicity mismatch\n" unless $count[$label] == 2;
        if ($label > 1) {
            die "first-occurrence ordering mismatch\n" unless $first[$label - 1] < $first[$label];
            die "last-occurrence ordering mismatch\n" unless $last[$label - 1] < $last[$label];
        }
    }
    $sha->add(join(',', @labels), "\n");
}

print "PROJECT_ID=PC-BRANCH-PERL-GUOYU\n";
print "STAGE21_CATALAN12_WORDS=$count\n";
print "STAGE21_ORACLE_HASH=", $sha->hexdigest, "\n";
print "STAGE21_MAX_MONTHS=12\n";
print "STAGE21_MAX_DAYS=48\n";
print "STAGE21_INDEPENDENT_ENUMERATION_PASS=1\n";
print "STAGE21_PRODUCTION_NOT_EXTENDED=1\n";
print "STAGE21_NATIVE_CI_NOT_RUN=1\n";
