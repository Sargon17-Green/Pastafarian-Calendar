#!/usr/bin/env perl
use v5.40;
use utf8;
use strict;
use warnings;
use Digest::SHA ();

# Stage22 discovery oracle: Dyck paths, NOT the production rank/unrank DP.
# Every open receives the next first-appearance label; every close receives
# the next last-appearance label. Close-before-open yields numeric lexical order.
my $months = 13;
my $expected = 742900; # C_13 = binomial(26,13)/14
my $sha = Digest::SHA->new(256);
my @path;
my ($count, $first, $middle, $last) = (0, undef, undef, undef);
my $visit;
$visit = sub ($opened, $closed) {
    if ($closed == $months) {
        my $line = join(',', @path) . "\n";
        $sha->add($line);
        ++$count;
        $first //= $line;
        $middle = $line if $count == 371450;
        $last = $line;
        return;
    }
    if ($closed < $opened) {
        push @path, $closed + 1;
        $visit->($opened, $closed + 1);
        pop @path;
    }
    if ($opened < $months) {
        push @path, $opened + 1;
        $visit->($opened + 1, $closed);
        pop @path;
    }
};
$visit->(0, 0);
die "wrong Catalan13 ordinal count $count\n" unless $count == $expected;
print "STAGE22_DISCOVERY_ORACLE_PASS=1\n";
print "COUNT=$count\n";
print "CSV_NUMERIC_LEXICAL_LF_SHA256=", $sha->hexdigest, "\n";
print "FIRST=", $first;
print "MIDDLE_371450=", $middle;
print "LAST=", $last;
