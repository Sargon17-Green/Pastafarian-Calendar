#!/usr/bin/env perl
use v5.40;
use strict;
use warnings;
use Time::HiRes qw(time);
my $m = shift(@ARGV) // 12;
die "expected 1..12\n" if $m !~ /\A(?:[1-9]|1[0-2])\z/;
my @powers = (1);
push @powers, $powers[-1]*5 for 1..$m;
my $base = 1_000_000_000_000;
my %layer = (0 => pack('Q<4',1,0,0,0));
my $expanded=0;
my $start=time;
for my $step (1 .. 4*$m) {
    my %next;
    for my $key (keys %layer) {
        $expanded++;
        my @digits = map { int($key/$powers[$_]) % 5 } 0..$m-1;
        my $unopened = 0;
        $unopened++ while $unopened < $m && $digits[$unopened] > 0;
        my $unclosed = 0;
        $unclosed++ while $unclosed < $m && $digits[$unclosed] == 4;
        for my $j (0..$m-1) {
            next if $digits[$j] == 4;
            next if $digits[$j] == 0 && $j != $unopened;
            next if $digits[$j] == 3 && $j != $unclosed;
            my $new_key = $key + $powers[$j];
            if (!exists $next{$new_key}) {
                $next{$new_key} = $layer{$key};
            } else {
                my ($a,$b,$c,$d) = unpack('Q<4',$next{$new_key});
                my ($w,$x,$y,$z) = unpack('Q<4',$layer{$key});
                $a+=$w; if($a >= $base){$a-=$base;$b++}
                $b+=$x; if($b >= $base){$b-=$base;$c++}
                $c+=$y; if($c >= $base){$c-=$base;$d++}
                $d+=$z;
                die "limb overflow\n" if $d >= $base;
                $next{$new_key} = pack('Q<4',$a,$b,$c,$d);
            }
        }
    }
    %layer = %next;
}
my $terminal = $powers[$m]-1;
die "terminal mismatch\n" if keys(%layer)!=1 || !exists $layer{$terminal};
my @blocks = unpack('Q<4',$layer{$terminal});
my $result = $blocks[3];
$result .= sprintf('%012d',$blocks[$_]) for reverse 0..2;
$result =~ s/\A0+(?=\d)//;
printf "months=%d expanded=%d seconds=%.3f count=%s\n",$m,$expanded,time-$start,$result;
