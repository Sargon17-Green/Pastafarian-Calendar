#!/usr/bin/env raku

my $proc = run $*EXECUTABLE, '-Ilib', '-It/lib', 't/01-stage01.t', :out, :err;
my $out = $proc.out.slurp-rest;
my $err = $proc.err.slurp-rest;
print $out;
note $err if $err.chars;
exit $proc.exitcode;
