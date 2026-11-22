#!/usr/bin/env perl
use v5.40;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use FindBin;

# Independent brute-force reference: form every multiset permutation, then
# keep words whose first and last occurrence positions are both strictly
# increasing by label. Do not reuse the oracle's state machine.
my $oracle = "$FindBin::Bin/stage22_max_arena_forward_oracle.pl";
sub all_valid ($sizes) {
    my @valid;
    my @remaining = @$sizes;
    my @prefix;
    my $build;
    $build = sub {
        if (@prefix == do { my $n=0; $n += $_ for @$sizes; $n }) {
            my (@first, @last);
            for my $i (0 .. $#prefix) {
                my $label = $prefix[$i] - 1;
                $first[$label] //= $i;
                $last[$label] = $i;
            }
            for my $j (1 .. $#$sizes) {
                return if $first[$j] <= $first[$j-1] || $last[$j] <= $last[$j-1];
            }
            push @valid, [@prefix];
            return;
        }
        for my $j (0 .. $#remaining) {
            next unless $remaining[$j];
            --$remaining[$j]; push @prefix, $j+1;
            $build->();
            pop @prefix; ++$remaining[$j];
        }
    };
    $build->();
    return \@valid;
}
sub invoke ($profile, $mode, $path) {
    local $ENV{STAGE22_ORACLE_PROFILE} = $profile;
    local $ENV{STAGE22_ORACLE_QUIET} = 1;
    my @args = ($^X, $oracle, $mode);
    push @args, $path if defined $path;
    open my $pipe, '-|', @args or die "cannot start oracle: $!";
    local $/;
    my $text = <$pipe> // '';
    close $pipe or die "oracle unexpectedly failed in $profile/$mode";
    return $text;
}

my @cases = (
    [[2,2], 2],
    [[2,2,2], 5],
    [[3,2,3], 19],
    [[1,2,1], 1],
    [[1,1], 1],
    [[3,1,2], 1],
    [[2,3,1], undef],
);
for my $case (@cases) {
    my ($sizes,$expected) = @$case;
    my $profile = join ',', @$sizes;
    my $valid = all_valid($sizes);
    my $count = scalar @$valid;
    if (defined $expected) {
        is($count, $expected, "independent brute-force count: $profile");
    }
    my $got = invoke($profile, 'count', undef);
    is($got, "$count\n", "forward count matches brute-force: $profile");
    for my $i (0 .. $#$valid) {
        my ($fh,$path) = tempfile();
        print {$fh} join(',', @{$valid->[$i]}), "\n";
        close $fh;
        my $lex = invoke($profile, 'lex', $path);
        unlink $path;
        is($lex, "$count\nlexical_ordinal=" . ($i+1) . "\n", "lexical ordinal matches brute-force $profile/$i");
    }
}
print "STAGE22_PERL_ORACLE_BRUTE_FORCE_CONTRACT=PASS\n";
done_testing;
