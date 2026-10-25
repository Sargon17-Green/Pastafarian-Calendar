#!/usr/bin/env perl
use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Math::BigInt;
use Digest::SHA qw(sha256_hex);
use Getopt::Long qw(GetOptions);
use lib 'lib','t/lib';
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::WeavingRank qw(rankWeavingPolynomial);
use Pastafari::WeavingUnrank qw(unrankWeavingPolynomial);

# 逐一展開五個月份的全部合法前綴，深度為 0..4。
my ($first,$second)=(0,0);
GetOptions('first=i'=>\$first,'second=i'=>\$second)
 or die "R75 分片參數無效\n";
die "R75 第一、二月份長度只允許 1..3\n"
 if $first<1 || $first>3 || $second<1 || $second>3;
my $shard="$first,$second";
my %totals=(
 '1,1'=>215,'1,2'=>892,'1,3'=>2596,
 '2,1'=>215,'2,2'=>3488,'2,3'=>15016,
 '3,1'=>215,'3,2'=>9698,'3,3'=>54208
);
my %digests=(
 '1,1'=>'06e2c1f648cb139a0d5b59151efc366fbf2f6b96ef815ea875f030af197a45e1',
 '1,2'=>'2d7fe0bbddfe3cd8966ad4f8ea12d54444f1074c2125d1020d00197e22a611f1',
 '1,3'=>'93039a0b1d5b00cf0438e2170240bee4631a0e4615494ff939540b1bec092761',
 '2,1'=>'f531a02d6ee02f472db23502bec3e21b83b3fe7e0f09055ba6ddc18d77f468cf',
 '2,2'=>'2a8bfff1d65378526c348c492ecb361abd07b6cf0c9a7c5b8f3dfc818e3998ff',
 '2,3'=>'140eb44287900c69b71f19a9b1bfef789f3ff9c2e1c57641e2177399cab1a7e8',
 '3,1'=>'c834da8df6b478810fe393ea4ea2eafd75dab3fb001977ef241629526fe796cf',
 '3,2'=>'ee23c98e54a853343740ccbcdcd2b2f0bfc33724440182ab3dd86fc946f639da',
 '3,3'=>'f577b9edfe3ddbf0f1bdff1ec06e57eb204c85a2f95d245cd64b43558c5f9a32'
);
my %nodes=(
 '1,1'=>[27,27,27,27,39],'1,2'=>[27,27,27,45,66],
 '1,3'=>[27,27,27,45,84],'2,1'=>[27,27,27,27,27],
 '2,2'=>[27,27,54,72,129],'2,3'=>[27,27,54,99,192],
 '3,1'=>[27,27,27,27,27],'3,2'=>[27,27,54,99,156],
 '3,3'=>[27,27,54,126,273]
);
sub counter ($L) {
 my %memo;my $walk;
 $walk=sub ($rem,$open,$closed) {
  my $key=join(',',@$rem).":$open:$closed";
  return $memo{$key}->copy if exists $memo{$key};
  my $left=0;$left+=$_ for @$rem;
  return $memo{$key}=Math::BigInt->bone if !$left;
  my $sum=Math::BigInt->bzero;
  for my $j (1..($open<5?$open+1:5)) {
   next unless $rem->[$j-1];
   next if $rem->[$j-1]==1 && $j!=$closed+1;
   my @next=@$rem;--$next[$j-1];
   $sum->badd($walk->(\@next,$j>$open?$j:$open,!$next[$j-1]?$j:$closed));
  }
  $memo{$key}=$sum->copy;return $sum;
 };
 return $walk;
}
sub children ($rem,$open,$closed,$walk) {
 my @out;
 for my $j (1..($open<5?$open+1:5)) {
  next unless $rem->[$j-1];
  next if $rem->[$j-1]==1 && $j!=$closed+1;
  my @next=@$rem;--$next[$j-1];
  my $op=$j>$open?$j:$open;
  my $cl=!$next[$j-1]?$j:$closed;
  my $ways=$walk->(\@next,$op,$cl);
  push @out,[$j,\@next,$op,$cl,$ways] if $ways>0;
 }
 return @out;
}
sub key ($w) {join(',',@$w)}
sub complete ($rem,$open,$closed,$prefix,$walk,$right) {
 my @remaining=@$rem;my ($o,$c)=($open,$closed);my @word=@$prefix;
 while (grep {$_} @remaining) {
  my @opts=children(\@remaining,$o,$c,$walk);
  die "R75 合法前綴無合法後綴\n" unless @opts;
  my $chosen=$right?$opts[-1]:$opts[0];
  push @word,$chosen->[0];@remaining=@{$chosen->[1]};
  ($o,$c)=($chosen->[2],$chosen->[3]);
 }
 die "R75 完工後月份末次順序錯誤\n" if $c!=5;
 return \@word;
}
my @counts=(0,0,0,0,0);
my ($checks,$partitions,$outside)=(0,0,0);
sub walk_prefix ($L,$f,$rem,$open,$closed,$prefix,$start,$depth,$N) {
 my $ways=$f->($rem,$open,$closed);
 die "R75 前綴完工數不合理\n" if $ways<1;
 my $end=$start->copy->badd($ways)->bsub(1);
 die "R75 區間超出總體合法排名\n" if $start<1 || $end>$N;
 $counts[$depth]++;
 my $low=complete($rem,$open,$closed,$prefix,$f,0);
 my $high=complete($rem,$open,$closed,$prefix,$f,1);
 die "R75 起點 rank 不正確\n" if rankWeavingPolynomial($L,$low)!=$start;
 die "R75 終點 rank 不正確\n" if rankWeavingPolynomial($L,$high)!=$end;
 die "R75 起點 unrank 不正確\n" if key(unrankWeavingPolynomial($L,$start)) ne key($low);
 die "R75 終點 unrank 不正確\n" if key(unrankWeavingPolynomial($L,$end)) ne key($high);
 $checks+=4;
 if($depth>=2) {
  for my $n ($start->copy->bsub(1),$end->copy->badd(1)) {
   next if $n<1 || $n>$N;
   my $w=unrankWeavingPolynomial($L,$n);
   my @p=@$w[0..$depth-1];
   die "R75 區間外相鄰詞包含相同前綴\n" if key(\@p) eq key($prefix);
   $outside++;
  }
 }
 return if $depth==4;
 my @opts=children($rem,$open,$closed,$f);
 die "R75 沒有合法孩子\n" unless @opts;
 my $sum=Math::BigInt->bzero;$sum->badd($_->[4]) for @opts;
 die "R75 子樹完工數和不等於父節點\n" if $sum!=$ways;
 my $cursor=$start->copy;
 for my $o (@opts) {
  my @p=(@$prefix,$o->[0]);
  walk_prefix($L,$f,$o->[1],$o->[2],$o->[3],\@p,$cursor,$depth+1,$N);
  $cursor->badd($o->[4]);
 }
 die "R75 孩子排名區間不連續或有重疊\n" if $cursor!=$end->copy->badd(1);
 $partitions++;
}
my $all=Math::BigInt->bzero;my @rows;
for my $third (1..3) {
 for my $fourth (1..3) {
  for my $fifth (1..3) {
   my @L=($first,$second,$third,$fourth,$fifth);
   my $f=counter(\@L);
   my $N=$f->([@L],0,0);
   die "R75 獨立 DFS 與位置多項式不一致\n" if $N!=countWeavingsPolynomial(\@L);
   walk_prefix(\@L,$f,[@L],0,0,[],Math::BigInt->bone,0,$N);
   push @rows,key(\@L)."=$N";$all->badd($N);
  }
 }
}
die "R75 27 個向量總計數不符合獨立基線\n" if $all!=$totals{$shard};
my $sha=sha256_hex(join(';',@rows));
die "R75 27 個向量 SHA-256 不符合獨立基線\n" if $sha ne $digests{$shard};
for my $i (0..4) {
 die "R75 全部深度前綴數與外部基線不同\n" if $counts[$i]!=$nodes{$shard}->[$i];
}
my $n=0;$n+=$_ for @counts;
die "R75 未全部執行原生排名檢查\n" if $checks!=$n*4;
die "R75 未完全核對各內部前綴分割\n" if $partitions!=$n-$counts[4];
die "R75 缺少區間外相鄰詞核對\n" if $outside==0;
printf "R75_COMPLETE passed=1 blocked=0 failed=0 first=%d second=%d vectors=27 words=%s nodes=%s endpoints=%d partitions=%d outside=%d sha256=%s\n",
 $first,$second,$all,join(',',@counts),$checks,$partitions,$outside,$sha;
