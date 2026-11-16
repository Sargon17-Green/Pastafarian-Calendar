#!/usr/bin/env perl
use v5.40;
use strict;
use warnings;
use utf8;
use Pastafari::Monster::WeavingPrimitive qw(count_weavings rank_weaving unrank_weaving);
use Time::HiRes qw(time);

my $k = shift @ARGV;
die "Usage: PERL5LIB=<sandbox-lib> perl stage18_resource_probe.pl {2|3|4}\n"
    unless defined($k) && $k =~ /\A[234]\z/ && !@ARGV;
my @profile = ($k) x 9;
my $start = time;
my $count = count_weavings(\@profile);
my $count_s = "$count";
my $after_count = time;
my $middle = $count->copy->badd(1)->bdiv(2);
for my $rank (1, "$middle", "$count") {
    my $word = unrank_weaving(\@profile, $rank);
    die "Wrong word length at rank $rank\n" if @$word != $k * 9;
    my $actual = rank_weaving(\@profile, $word);
    die "Roundtrip mismatch at rank $rank\n" if "$actual" ne "$rank";
}
die "Catalan(9) oracle mismatch\n" if $k == 2 && $count_s ne '4862';
my $finish = time;
printf "k=%d days=%d count=%s count_sec=%.6f roundtrip_three_sec=%.6f total_sec=%.6f\n",
    $k, 9 * $k, $count_s, $after_count - $start, $finish - $after_count, $finish - $start;
