use v5.40;
use strict;
use warnings;
use Math::BigInt;
my @f=(Math::BigInt->bone);
push @f,$f[-1]->copy->bmul($_) for 1..56;
my ($bound,@arg)=(Math::BigInt->bone);
my $triples=0;
for my $n (1..56) { for my $k (1..14) { for my $s (0..14-$k) {
    my $t=$n-2*$k-$s; next if $t<0; ++$triples;
    my ($q,$r)=(int($t/$k),$t%$k);
    my $den=$f[$k]->copy->bmul($f[$k+1])->bmul($f[$s])->bmul($f[$q]->copy->bpow($k-$r))->bmul($f[$q+1]->copy->bpow($r));
    my $b=$f[$n]->copy->bdiv($den);
    if ($b>$bound) { $bound=$b; @arg=($n,$k,$s,$q,$r) }
}}}
say "BOUND=$bound DIGITS=".length("$bound")." TRIPLES=$triples ARG=@arg";
# Exact capacity Pareto DP. E=sum products of nonempty intervals ending at the last label; C=sum over all nonempty intervals.
my %dp=(0=>[[0,0,[]]]); my ($max,$profile)=(0,[]);
for my $m (1..14) {
    my %next;
    for my $n (sort {$a<=>$b} keys %dp) { for my $l (1..56-$n) {
        for my $p (@{$dp{$n}}) {
            my $e=($l-1)*(1+$p->[0]);
            push @{$next{$n+$l}},[$e,$p->[1]+$e,[@{$p->[2]},$l]];
        }
    }}
    %dp=();
    for my $n (sort {$a<=>$b} keys %next) {
        my $top=-1;
        for my $p (sort {$b->[0]<=>$a->[0] || $b->[1]<=>$a->[1]} @{$next{$n}}) {
            next if $p->[1]<=$top; $top=$p->[1]; push @{$dp{$n}},$p;
            my $cap=$p->[1]+$m+1;
            if ($cap>$max) { ($max,$profile)=($cap,$p->[2]) }
        }
    }
}
say "ARENA=$max PROFILE=@$profile RAW32=".($max*32+int(($max+7)/8))." RAW40=".($max*40+int(($max+7)/8));
# Independent two-occurrence oracle: ballot suffix counts, numeric lexical closing before opening.
my %memo;
sub ways ($o,$c) {
    return 1 if $c==14;
    return $memo{"$o,$c"} //= ($c<$o ? ways($o,$c+1):0)+($o<14 ? ways($o+1,$c):0);
}
my $total=ways(0,0); say "CATALAN14=$total";
for my $rank (1,2,int($total/2),$total-1,$total) {
    my ($o,$c,$r)=(0,0,$rank); my @word;
    while ($c<14) { my $w=$c<$o ? ways($o,$c+1):0;
        if ($r<=$w) { push @word,++$c } else { $r-=$w; die 'invalid opening' if $o==14; push @word,++$o }
    }
    die 'residual rank' if $r!=1;
    my ($oo,$cc,$back)=(0,0,1);
    for my $j (@word) {
        if ($cc<$oo && $j==$cc+1) { ++$cc }
        elsif ($oo<14 && $j==$oo+1) { $back+=ways($oo,$cc+1) if $cc<$oo; ++$oo }
        else { die 'invalid label' }
    }
    die 'rank mismatch' if $back!=$rank || $cc!=14 || $oo!=14;
    say "RANK=$rank WORD=".join(',',@word)." INVERSE=$back";
}
die 'preflight mismatch' unless "$bound" eq '211400621135291847714750594140071941494784000000000' && $max==12106881 && $total==2674440;
say 'DISCOVERY_PREFLIGHT_PASS';
