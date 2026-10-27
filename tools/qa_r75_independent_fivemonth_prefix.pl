#!/usr/bin/env perl
use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use Encode qw(encode decode FB_CROAK);
use Getopt::Long qw(GetOptions);
my ($first,$second)=(0,0);
GetOptions('first=i'=>\$first,'second=i'=>\$second) or die "args\n";
die "shard must be 1..3\n" unless $first>=1 && $first<=3 && $second>=1 && $second<=3;
my $shard="$first,$second";
my %totals=('1,1'=>215,'1,2'=>892,'1,3'=>2596,'2,1'=>215,'2,2'=>3488,'2,3'=>15016,'3,1'=>215,'3,2'=>9698,'3,3'=>54208);
my %digests=(
 '1,1'=>'06e2c1f648cb139a0d5b59151efc366fbf2f6b96ef815ea875f030af197a45e1',
 '1,2'=>'2d7fe0bbddfe3cd8966ad4f8ea12d54444f1074c2125d1020d00197e22a611f1',
 '1,3'=>'93039a0b1d5b00cf0438e2170240bee4631a0e4615494ff939540b1bec092761',
 '2,1'=>'f531a02d6ee02f472db23502bec3e21b83b3fe7e0f09055ba6ddc18d77f468cf',
 '2,2'=>'2a8bfff1d65378526c348c492ecb361abd07b6cf0c9a7c5b8f3dfc818e3998ff',
 '2,3'=>'140eb44287900c69b71f19a9b1bfef789f3ff9c2e1c57641e2177399cab1a7e8',
 '3,1'=>'c834da8df6b478810fe393ea4ea2eafd75dab3fb001977ef241629526fe796cf',
 '3,2'=>'ee23c98e54a853343740ccbcdcd2b2f0bfc33724440182ab3dd86fc946f639da',
 '3,3'=>'f577b9edfe3ddbf0f1bdff1ec06e57eb204c85a2f95d245cd64b43558c5f9a32');
my %expected_outside=('1,1'=>24,'1,2'=>114,'1,3'=>150,'2,1'=>0,'2,2'=>348,'2,3'=>528,'3,1'=>0,'3,2'=>456,'3,3'=>744);
my %expected_nodes=('1,1'=>[27,27,27,27,39],'1,2'=>[27,27,27,45,66],'1,3'=>[27,27,27,45,84],'2,1'=>[27,27,27,27,27],'2,2'=>[27,27,54,72,129],'2,3'=>[27,27,54,99,192],'3,1'=>[27,27,27,27,27],'3,2'=>[27,27,54,99,156],'3,3'=>[27,27,54,126,273]);
my @nodes=(0,0,0,0,0);
my ($all,$partition,$outside,$endpoint)=(0,0,0,0);
my @rows;
for my $third (1..3) {
 for my $fourth (1..3) {
  for my $fifth (1..3) {
   my @L=($first,$second,$third,$fourth,$fifth);
   my @words;
   my $walk;
   $walk=sub ($rem,$opened,$closed,$word) {
    my $sum=0; $sum+=$_ for @$rem;
    if(!$sum) {
     die "terminal closed month !=5\n" if $closed!=5;
     push @words,join('',@$word);
     return;
    }
    for my $j (1..($opened<5?$opened+1:5)) {
     next unless $rem->[$j-1];
     next if $rem->[$j-1]==1 && $j!=$closed+1;
     my @next=@$rem; --$next[$j-1];
     $walk->(\@next,$j>$opened?$j:$opened,$next[$j-1]==0?$j:$closed,[@$word,$j]);
    }
   };
   $walk->(\@L,0,0,[]);
   my %rank; for my $i (0..$#words) {
    die "duplicate word\n" if exists $rank{$words[$i]};
    die "out of order\n" if $i && $words[$i-1] ge $words[$i];
    $rank{$words[$i]}=$i+1;
   }
   my @levels;
   for my $i (0..$#words) {
    my $word=$words[$i];
    for my $d (0..4) {
     my $p=substr($word,0,$d);
     $levels[$d]{$p}{start}//=$i;
     $levels[$d]{$p}{end}=$i;
     $levels[$d]{$p}{count}++;
    }
   }
   for my $d (0..4) {
    for my $p (sort keys %{$levels[$d]}) {
     my $r=$levels[$d]{$p};
     my ($start,$end,$size)=($r->{start},$r->{end},$r->{count});
     die "non-contiguous prefix\n" if $end-$start+1!=$size;
     die "first endpoint wrong\n" if $rank{$words[$start]}!=$start+1 || substr($words[$start],0,$d) ne $p;
     die "last endpoint wrong\n" if $rank{$words[$end]}!=$end+1 || substr($words[$end],0,$d) ne $p;
     $endpoint+=4; $nodes[$d]++;
     if($d<4) {
      my $children=0;
      for my $next (1..5) { $children += exists($levels[$d+1]{$p.$next}) ? $levels[$d+1]{$p.$next}{count} : 0; }
      die "children do not partition\n" if $children!=$size;
      $partition++;
     }
     if($d>=2) {
      for my $i ($start-1,$end+1) {
       next if $i<0 || $i>@words-1;
       die "outside neighbour shares prefix\n" if substr($words[$i],0,$d) eq $p;
       $outside++;
      }
     }
    }
   }
   $all+=scalar @words;
   push @rows,join(',',@L).'='.scalar(@words);
  }
 }
}
my $digest=sha256_hex(join(';',@rows));
die "count mismatch: $all vs $totals{$shard}\n" if $all!=$totals{$shard};
die "sha mismatch: $digest vs $digests{$shard}\n" if $digest ne $digests{$shard};
die "nodes mismatch: @nodes vs @{$expected_nodes{$shard}}\n" if join(',',@nodes) ne join(',',@{$expected_nodes{$shard}});
die "outside mismatch: $outside vs $expected_outside{$shard}\n" if $outside!=$expected_outside{$shard};
my $expected_parts=0; $expected_parts+=$nodes[$_] for 0..3;
die "partition mismatch\n" if $partition!=$expected_parts;
my $expected_endpoints=0;$expected_endpoints+=$_*4 for @nodes;
die "endpoint mismatch\n" if $endpoint!=$expected_endpoints;
my $unicode="第七十五輪：五個月份檢查 國語 ✅";
my $bytes=encode('UTF-8',$unicode);
die "unicode mismatch\n" if decode('UTF-8',$bytes) ne $unicode;
print "R75_INDEPENDENT_PERL passed=1 first=$first second=$second vectors=27 words=$all nodes=",join(',',@nodes)," endpoints=$endpoint partitions=$partition outside=$outside sha256=$digest unicode=ok\n";
