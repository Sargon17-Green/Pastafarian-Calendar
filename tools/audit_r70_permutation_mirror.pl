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
use Pastafari::WeavingMemoOracle;
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::WeavingUnrank qw(unrankWeavingPolynomial);
use Pastafari::WeavingRank qw(rankWeavingPolynomial);

# R70：四個互異月長的全部 24 個順序。序列反轉且月份標籤
# j -> 5-j 後，首次、末次次序互相轉換而依舊合法：
# 這是和位置多項式及 memo 不共享狀態的真正構造性雙射。
my $shard=-1;
GetOptions('shard=i'=>\$shard) or die "R70 shard 不合法\n";
die "R70 shard 必須 0..3\n" if $shard<0 || $shard>3;
my @months=(10,11,12,13);
my @perms;
for my $a (@months) {
 for my $b (@months) {
  next if $a==$b;
  for my $c (@months) {
   next if $c==$a || $c==$b;
   for my $d (@months) {
    next if $d==$a || $d==$b || $d==$c;
    push @perms,[$a,$b,$c,$d];
   }
  }
 }
}
die "R70 不是全部 24 個互異排列\n" unless @perms==24;
my @expected=(
 '25513687727559962223774','26901290660710499652866',
 '25341518874398544245844','28434255912845240954002',
 '26659962630383135412086','28370541622127764989202',
 '23718803306682746887430','25007597426594493080890',
 '23505673077948010810640','28370541622127764989202',
 '24838799101034314803550','28434255912845240954002',
 '22141349322938170320892','24838799101034314803550',
 '22091572533315142223392','26659962630383135412086',
 '25007597426594493080890','26901290660710499652866',
 '22091572533315142223392','23505673077948010810640',
 '22141349322938170320892','25341518874398544245844',
 '23718803306682746887430','25513687727559962223774',
);
my $static=join(';',map {join(',',@{$perms[$_]}).'='.$expected[$_]} 0..23);
die "R70 24 固定真值的 SHA-256 表未通過獨立預先核對\n"
 if sha256_hex($static) ne 'a25ac18f972ade732c44f4e672a22f03f5b98b5bd16d979a58bfddb97c6c26be';
my %unique=map {$_=>1} @expected;
die "R70 對稱群應產生十二種不同總數\n" if keys(%unique)!=12;
for my $i (0..23) {
 my @reversed=reverse @{$perms[$i]};
 my $reversed_index;
 for my $j (0..23) {
  if(join(',',@{$perms[$j]}) eq join(',',@reversed)) {
   $reversed_index=$j;last;
  }
 }
 die "R70 缺少反轉的配對排列\n" unless defined $reversed_index;
 die "R70 反轉配對的固定真值相異\n"
     if $expected[$i] ne $expected[$reversed_index];
}

sub independent_counter ($L) {
 my $m=scalar(@$L);
 my %memo;
 my $walk;
 $walk=sub ($remaining,$opened,$closed) {
  my $key=join(',',@$remaining).":$opened:$closed";
  return $memo{$key}->copy if exists $memo{$key};
  my $left=0;$left+=$_ for @$remaining;
  return $memo{$key}=Math::BigInt->bone if !$left;
  my $sum=Math::BigInt->bzero;
  for my $j (1..($opened<$m?$opened+1:$m)) {
   next if !$remaining->[$j-1];
   next if $remaining->[$j-1]==1 && $j!=$closed+1;
   my @next=@$remaining;
   --$next[$j-1];
   $sum->badd($walk->(\@next,$j>$opened?$j:$opened,
              $next[$j-1]==0?$j:$closed));
  }
  $memo{$key}=$sum->copy;
  return $sum;
 };
 return ($walk,\%memo);
}
sub independently_unrank ($L,$count,$input_rank) {
 my @rem=@$L;
 my ($opened,$closed)=(0,0);
 my $rank=Math::BigInt->new("$input_rank");
 my $days=0;$days+=$_ for @$L;
 my @word;
 for my $day (1..$days) {
  my $parent=$count->(\@rem,$opened,$closed);
  my $sum=Math::BigInt->bzero;
  my @branches;
  for my $j (1..($opened<@$L?$opened+1:scalar(@$L))) {
   next if !$rem[$j-1];
   next if $rem[$j-1]==1 && $j!=$closed+1;
   my @next=@rem;
   --$next[$j-1];
   my $new_open=$j>$opened?$j:$opened;
   my $new_closed=$next[$j-1]==0?$j:$closed;
   my $ways=$count->(\@next,$new_open,$new_closed);
   push @branches,[$j,\@next,$new_open,$new_closed,$ways];
   $sum->badd($ways);
  }
  die "R70 某日的子樹未能分割父前綴\n" if $sum!=$parent;
  my $selected;
  for my $item (@branches) {
   if ($rank<=$item->[4]) {
    $selected=$item;last;
   }
   $rank->bsub($item->[4]);
  }
  die "R70 解碼沒有可選的合法分支\n" unless $selected;
  push @word,$selected->[0];
  @rem=@{$selected->[1]};
  ($opened,$closed)=($selected->[2],$selected->[3]);
 }
 die "R70 字序葉節點非排名一\n" if $rank!=1;
 die "R70 尚有月份未完成\n" if grep {$_} @rem;
 return \@word;
}
sub independently_rank ($L,$count,$word) {
 my @rem=@$L;
 my ($opened,$closed)=(0,0);
 my $rank=Math::BigInt->bone;
 for my $selected (@$word) {
  my $found=0;
  for my $j (1..($opened<@$L?$opened+1:scalar(@$L))) {
   next if !$rem[$j-1];
   next if $rem[$j-1]==1 && $j!=$closed+1;
   my @next=@rem;
   --$next[$j-1];
   my $new_open=$j>$opened?$j:$opened;
   my $new_closed=$next[$j-1]==0?$j:$closed;
   if ($j==$selected) {
    @rem=@next;
    ($opened,$closed)=($new_open,$new_closed);
    $found=1;
    last;
   }
   $rank->badd($count->(\@next,$new_open,$new_closed));
  }
  die "R70 反轉後的詞違反合法首末次序\n" if !$found;
 }
 die "R70 反轉後的詞不是完整合法詞\n" if grep {$_} @rem;
 return $rank;
}

my $checked=0;
my $sampled=0;
my $over64=Math::BigInt->new('9223372036854775807');
for my $idx ($shard*6 .. $shard*6+5) {
 my $lengths=$perms[$idx];
 my @reverse=reverse @$lengths;
 my ($f,$states)=independent_counter($lengths);
 my ($rev,$rev_states)=independent_counter(\@reverse);
 my $total=$f->([@$lengths],0,0);
 my $backward=$rev->([@reverse],0,0);
 die "R70 permutation $idx 固定 BigInt 參考值不一致\n"
     if "$total" ne $expected[$idx];
 die "R70 permutation $idx 的反轉雙射沒有等數量\n"
     if $total!=$backward;
 die "R70 permutation $idx 不在 int64 溢位空間\n" if $total<=$over64;
 die "R70 permutation $idx 插入多項式與 DFS 不一致\n"
     if countWeavingsPolynomial($lengths)!=$total;
 my $oracle=Pastafari::WeavingMemoOracle->new($lengths,{
     bounded_cache=>1,cache_limit=>16,cache_policy=>'clock',
     early_final_closed_form=>1
 });
 die "R70 permutation $idx bounded clock Oracle 不相等\n"
     if $oracle->count_prefix([])!=$total;
 my $diag=$oracle->diagnostics;
 die "R70 permutation $idx 未使用早期末次序閉式\n"
     if $diag->{early_closed_forms}<1 || $diag->{entries}>16;
 my @ranks=(Math::BigInt->bone,$total->copy->bdiv(2)->badd(1),$total->copy);
 for my $rank (@ranks) {
  my $word=independently_unrank($lengths,$f,$rank);
  my @mirror=map {5-$_} reverse @$word;
  my $mirror_rank=independently_rank(\@reverse,$rev,\@mirror);
  die "R70 permutation $idx 鏡射後排名超出範圍\n"
      if $mirror_rank<1 || $mirror_rank>$total;
  my $native_word=unrankWeavingPolynomial($lengths,$rank);
  die "R70 permutation $idx 真正詞與原生反排名不同\n"
      if join(',',@$native_word) ne join(',',@$word);
  die "R70 permutation $idx 原生正向排名不同\n"
      if rankWeavingPolynomial($lengths,$word)!=$rank;
  die "R70 permutation $idx 反轉詞的原生正向排名不同\n"
      if rankWeavingPolynomial(\@reverse,\@mirror)!=$mirror_rank;
  my $native_mirror=unrankWeavingPolynomial(\@reverse,$mirror_rank);
  die "R70 permutation $idx 反轉詞的原生反排名不同\n"
      if join(',',@$native_mirror) ne join(',',@mirror);
  my @restored=map {5-$_} reverse @mirror;
  die "R70 permutation $idx 鏡射兩次不是恆等\n"
      if join(',',@restored) ne join(',',@$word);
  $sampled++;
 }
 die "R70 permutation $idx 實際訪問狀態太少\n"
     if keys(%$states)<1000 || keys(%$rev_states)<1000;
 printf "R70_PERMUTATION_PASS index=%d lengths=%s total=%s samples=3 states=%d mirror_states=%d\n",
     $idx,join(',',@$lengths),"$total",scalar(keys %$states),
     scalar(keys %$rev_states);
 $checked++;
}
die "R70 每份必須六種順序、十八個完整詞鏡射\n"
    if $checked!=6 || $sampled!=18;
printf "R70_COMPLETE passed=1 blocked=0 failed=0 shard=%d permutations=%d mirror_words=%d\n",
    $shard,$checked,$sampled;
