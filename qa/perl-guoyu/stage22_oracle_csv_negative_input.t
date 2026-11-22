#!/usr/bin/env perl
use v5.40;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use IPC::Open3;
use Symbol qw(gensym);
use FindBin;

# PROJECT_ID: PC-BRANCH-PERL-GUOYU
# Stage22 post-acceptance QA: CSV parser negative-input contract only.
# Deliberately use a tiny 2,2 profile; do not recompute 12/52 or 13x4.
my $oracle = "$FindBin::Bin/stage22_max_arena_forward_oracle.pl";
local $ENV{STAGE22_ORACLE_PROFILE} = '2,2';
local $ENV{STAGE22_ORACLE_QUIET} = 1;

sub invoke (@args) {
    my $err = gensym();
    my $pid = open3(my $in, my $out, $err, $^X, $oracle, @args);
    close $in;
    local $/;
    my $stdout = <$out> // '';
    my $stderr = <$err> // '';
    waitpid($pid, 0) == $pid or die "failed to wait for oracle";
    return ($? >> 8, $stdout, $stderr);
}

sub file_case ($text, @args) {
    my ($fh, $path) = tempfile();
    binmode $fh, ':raw';
    print {$fh} $text or die "cannot write fixture: $!";
    close $fh or die "cannot close fixture: $!";
    my @result = invoke('lex', $path, @args);
    unlink $path or die "cannot remove fixture: $!";
    return @result;
}

sub accepted ($label, $text, $expected) {
    my ($rc, $out, $err) = file_case($text);
    is($rc, 0, "$label: exit 0");
    is($out, $expected, "$label: exact output");
    is($err, '', "$label: no stderr");
}

sub rejected ($label, $text, $reason) {
    my ($rc, $out, $err) = file_case($text);
    isnt($rc, 0, "$label: nonzero exit");
    is($out, '', "$label: no misleading success output");
    like($err, $reason, "$label: explicit diagnostic");
}

accepted('single LF line', "1,1,2,2\n", "2\nlexical_ordinal=1\n");
accepted('single CRLF line', "1,2,1,2\r\n", "2\nlexical_ordinal=2\n");
accepted('single line without terminator', "1,1,2,2", "2\nlexical_ordinal=1\n");

my @invalid = (
    ['second CSV line', "1,1,2,2\n1,2,1,2\n", qr/extra CSV lines/],
    ['blank trailing line', "1,1,2,2\n\n", qr/extra CSV lines/],
    ['trailing nonnewline data', "1,1,2,2\nextra", qr/extra CSV lines/],
    ['second CRLF line', "1,1,2,2\r\n1,2,1,2\r\n", qr/extra CSV lines/],
    ['empty file', '', qr/empty word file/],
    ['zero label', "0,1,2,2\n", qr/invalid CSV format/],
    ['leading zero', "01,1,2,2\n", qr/invalid CSV format/],
    ['embedded whitespace', "1, 1,2,2\n", qr/invalid CSV format/],
    ['negative label', "-1,1,2,2\n", qr/invalid CSV format/],
    ['alphabetical label', "1,x,2,2\n", qr/invalid CSV format/],
    ['short word', "1,1,2\n", qr/wrong word length/],
    ['long word', "1,1,2,2,2\n", qr/wrong word length/],
    ['out-of-range label', "1,1,2,3\n", qr/word violates event order/],
    ['wrong opening order', "2,1,1,2\n", qr/word violates event order/],
    ['wrong closing order', "1,2,2,1\n", qr/word violates event order/],
);
rejected(@$_) for @invalid;

my @cli_invalid = (
    [['count', 'unexpected'], qr/count takes no arguments/],
    [['lex'], qr/lex requires a word-file path/],
    [['unknown'], qr/usage:/],
);
for my $c (@cli_invalid) {
    my ($rc, $out, $err) = invoke(@{$c->[0]});
    isnt($rc, 0, 'invalid CLI: nonzero exit');
    is($out, '', 'invalid CLI: no success output');
    like($err, $c->[1], 'invalid CLI: diagnostic');
}
my ($count_rc, $count_out, $count_err) = invoke('count');
is($count_rc, 0, 'count without args: exit 0');
is($count_out, "2\n", 'count without args: exact count');
is($count_err, '', 'count without args: no stderr');

print "STAGE22_ORACLE_CSV_NEGATIVE_CONTRACT=PASS\n" unless !Test::More->builder->is_passing;
done_testing;
