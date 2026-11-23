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
# Stage22 post-acceptance QA-only proposal; NOT an accepted Native test.
# SOURCE_COMMIT_LOCK: bb49201411b6397819c97e5fc2b40238251e48ce
# Contract: raw bytes, exactly one CSV record; only ASCII [1-9][0-9]* labels;
# 2,2 profile; every malformed input must return nonzero, stdout empty,
# and a diagnostic of the specified class. No production algorithm is used
# to construct the cases. Invoke under <=90 s and <=393216 KiB virtual memory.

my $oracle = "$FindBin::Bin/stage22_max_arena_forward_oracle.pl";
local $ENV{STAGE22_ORACLE_PROFILE} = '2,2';
local $ENV{STAGE22_ORACLE_QUIET} = 1;
alarm 80;

my @cases = (
    ['UTF-8 BOM',             pack('H*', 'efbbbf') . "1,1,2,2\n", qr/invalid CSV format/],
    ['embedded NUL',         "1,\x001,2,2\n",              qr/invalid CSV format/],
    ['trailing NUL',         "1,1,2,2\x00\n",              qr/invalid CSV format/],
    ['bare CR terminator',   "1,1,2,2\r",                 qr/invalid CSV format/],
    ['double CR before LF',  "1,1,2,2\r\r\n",             qr/invalid CSV format/],
    ['Arabic-Indic digit 1', pack('H*', 'd9a1') . ",1,2,2\n", qr/invalid CSV format/],
    ['fullwidth digit 1',    pack('H*', 'efbc91') . ",1,2,2\n", qr/invalid CSV format/],
    ['DEL byte',             "1,1,2,2\x7f\n",              qr/invalid CSV format/],
    ['64-digit label',       ('9' x 64) . ",1,2,2\n",      qr/word violates event order/],
);

for my $case (@cases) {
    my ($label, $bytes, $expected_error) = @$case;
    my ($fh, $path) = tempfile(UNLINK => 0);
    binmode $fh, ':raw';
    print {$fh} $bytes or die "fixture write failed: $!";
    close $fh or die "fixture close failed: $!";
    my $error = gensym();
    my $pid = open3(my $in, my $out, $error, $^X, $oracle, 'lex', $path);
    close $in;
    local $/;
    my $stdout = <$out> // '';
    my $stderr = <$error> // '';
    waitpid($pid, 0) == $pid or die "cannot wait for oracle";
    my $exit = $? >> 8;
    unlink $path or die "fixture cleanup failed: $!";
    isnt($exit, 0, "$label: nonzero exit");
    is($stdout, '', "$label: no misleading success output");
    like($stderr, $expected_error, "$label: error classification");
}

alarm 0;
done_testing(27);
