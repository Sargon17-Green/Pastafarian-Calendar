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
use Pastafari::WeavingRank qw(rankWeavingPolynomial);
use Pastafari::WeavingUnrank qw(unrankWeavingPolynomial);

# R73: 全部 625 個四月份 1..5 向量的完整深度 0..4
# 合法前綴樹逐個節點證明 [start,end] 及合法子區間分割。
# 其獨立參考只由剩餘日數、開/關月份狀態 DFS 建造。
my $shard=0;
GetOptions('shard=i'=>\$shard) or die "R73 shard 參數無效\n";
die "R73 shard 只准 1..5\n" if $shard<1 || $shard>5;
my %expected_sum=(
 1=>'84493',2=>'816161',3=>'4556227',
 4=>'18985221',5=>'65276665'
);
my %expected_sha=(
 1=>'aa475e200df43fae9f912003cd5799a08d756b14a8652947d4e64a106442b2b3',
 2=>'62524d0c43078bdc5836406ebdb71646ea617cc02615287a2949d2c0844942dd',
 3=>'9081e5cf00e2249317f71a07574bb5d9fb5f8bd40f0ebd53b70ab9c1746a903c',
 4=>'e94f0ea563a1489db7cbf13bd9ea79a92f79dbf9f0f8fcad590ed897f1ac1c39',
 5=>'79112d59ca0e0f25cfe6ca7eb7d63e79ed42ba61a9ce8d8ebc346cad6d809d04'
);
my %expected_nodes=(
 1=>[125,125,125,205,405],
 2=>[125,125,225,380,834],
 3=>[125,125,225,480,1084],
 4=>[125,125,225,480,1184],
 5=>[125,125,225,480,1184],
);
my ($profiles,$root_sum,$endpoint_checks,$memo_checks,$partitions)=(0,Math::BigInt->bzero,0,0,0);
my @nodes=(0,0,0,0,0);
my @entries;
sub reference_counter ($lengths) {
 my %memo;
 my $walk;
 $walk=sub ($remaining,$opened,$closed) {
  my $key=join(',',@$remaining).":$opened:$closed";
  return $memo{$key}->copy if exists $memo{$key};
  my $left=0;$left+=$_ for @$remaining;
  return $memo{$key}=Math::BigInt->bone if !$left;
  my $ways=Math::BigInt->bzero;
  for my $j (1..($opened<4?$opened+1:4)) {
   next if !$remaining->[$j-1];
   next if $remaining->[$j-1]==1 && $j!=$closed+1;
   my @after=@$remaining;
   --$after[$j-1];
   $ways->badd($walk->(\@after,$j>$opened?$j:$opened,
                 $after[$j-1]==0?$j:$closed));
  }
  $memo{$key}=$ways->copy;
  return $ways;
 };
 return ($walk,\%memo);
}
sub candidates ($remaining,$opened,$closed,$count) {
 my @out;
 for my $j (1..($opened<4?$opened+1:4)) {
  next if !$remaining->[$j-1];
  next if $remaining->[$j-1]==1 && $j!=$closed+1;
  my @after=@$remaining;
  --$after[$j-1];
  my $new_open=$j>$opened?$j:$opened;
  my $new_closed=$after[$j-1]==0?$j:$closed;
  my $ways=$count->(\@after,$new_open,$new_closed);
  next if $ways->is_zero;
  push @out,[$j,\@after,$new_open,$new_closed,$ways];
 }
 return @out;
}
sub extreme_word ($remaining,$opened,$closed,$prefix,$count,$largest) {
 my @rem=@$remaining;
 my ($op,$cl)=($opened,$closed);
 my @word=@$prefix;
 while (grep {$_} @rem) {
  my @opts=candidates(\@rem,$op,$cl,$count);
  die "R73 子樹未能接出合法極端詞\n" if !@opts;
  my $choice=$largest?$opts[-1]:$opts[0];
  push @word,$choice->[0];
  @rem=@{$choice->[1]};
  ($op,$cl)=($choice->[2],$choice->[3]);
 }
 die "R73 極端詞未按照 1..4 結束月份\n" if $cl!=4;
 return \@word;
}
sub wordkey ($word) { return join(',',@$word); }
sub verify_tree ($lengths,$count,$oracle,$rem,$opened,$closed,$prefix,$start,$depth) {
 my $ways=$count->($rem,$opened,$closed);
 die "R73 有前綴無法完工\n" if $ways<1;
 my $end=$start->copy->badd($ways)->bsub(1);
 $nodes[$depth]++;
 my $first=extreme_word($rem,$opened,$closed,$prefix,$count,0);
 my $last=extreme_word($rem,$opened,$closed,$prefix,$count,1);
 my $rf=rankWeavingPolynomial($lengths,$first);
 my $rl=rankWeavingPolynomial($lengths,$last);
 die "R73 左端真正完整詞排名錯誤\n" if $rf!=$start;
 die "R73 右端真正完整詞排名錯誤\n" if $rl!=$end;
 my $uf=unrankWeavingPolynomial($lengths,$start);
 my $ul=unrankWeavingPolynomial($lengths,$end);
 die "R73 原生解碼前綴左端不等於獨立最小延伸\n"
     if wordkey($uf) ne wordkey($first);
 die "R73 原生解碼前綴右端不等於獨立最大延伸\n"
     if wordkey($ul) ne wordkey($last);
 $endpoint_checks+=4;
 if ($depth==0 || $depth==4) {
  my $memo_answer=$oracle->count_prefix($prefix);
  die "R73 獨立 Oracle 完工數不等於 DFS\n" if $memo_answer!=$ways;
  $memo_checks++;
 }
 return if $depth==4;
 my @opts=candidates($rem,$opened,$closed,$count);
 die "R73 內部節點無任何合法後繼\n" if !@opts;
 my $sum=Math::BigInt->bzero;
 $sum->badd($_->[4]) for @opts;
 die "R73 各候選子樹和不等於父前綴完工數\n"
     if $sum!=$ways;
 my $cursor=$start->copy;
 for my $opt (@opts) {
  my $next_end=$cursor->copy->badd($opt->[4])->bsub(1);
  my @next_prefix=(@$prefix,$opt->[0]);
  verify_tree($lengths,$count,$oracle,$opt->[1],$opt->[2],$opt->[3],
              \@next_prefix,$cursor,$depth+1);
  $cursor=$next_end->copy->badd(1);
 }
 die "R73 依字典序排列後的子區間未緊密且完整拼接\n"
     if $cursor!=$end->copy->badd(1);
 $partitions++;
}
for my $b (1..5) {
 for my $c (1..5) {
  for my $d (1..5) {
   my @lengths=($shard,$b,$c,$d);
   my @snapshot=@lengths;
   my ($count,$memo)=reference_counter(\@lengths);
   my $total=$count->([@lengths],0,0);
   my $poly=countWeavingsPolynomial(\@lengths);
   die "R73 不同位置分布多項式與參考計數不一致\n"
       if $total!=$poly;
   my $oracle=Pastafari::WeavingMemoOracle->new(
       \@lengths,{bounded_cache=>1,cache_limit=>16,
                  cache_policy=>'clock',early_final_closed_form=>1});
   verify_tree(\@lengths,$count,$oracle,[@lengths],0,0,[],
               Math::BigInt->bone,0);
   my $diag=$oracle->diagnostics;
   die "R73 有界 cache 超限或閉式沒有啟用\n"
       if $diag->{entries}>16 || !$diag->{early_closed_forms};
   die "R73 驗證程序修改原始月長\n"
       if join(',',@lengths) ne join(',',@snapshot);
   push @entries,join(',',@lengths).'='.$total;
   $root_sum->badd($total);
   $profiles++;
  }
 }
}
die "R73 分片未覆蓋所有 125 個月份向量\n" if $profiles!=125;
die "R73 分片原生精確總數與外部預先固定的真值不一致\n"
    if "$root_sum" ne $expected_sum{$shard};
my $hash=sha256_hex(join(';',@entries));
die "R73 全 125 向量外部 SHA-256 基線不一致\n"
    if $hash ne $expected_sha{$shard};
my $expected=$expected_nodes{$shard};
for my $depth (0..4) {
 die "R73 原生可達前綴節點數不等於外部固定基線\n"
    if $nodes[$depth]!=$expected->[$depth];
}
my $total_nodes=0;$total_nodes+=$_ for @nodes;
die "R73 未對每個前綴比較四次原生 rank/unrank\n"
    if $endpoint_checks!=$total_nodes*4;
die "R73 並未對每個根節點及第四層葉前綴與 memo 交叉核對\n"
    if $memo_checks!=$nodes[0]+$nodes[4];
die "R73 所有深度 0..3 節點未逐條核對子區間分割\n"
    if $partitions!=$total_nodes-$nodes[4];
printf "R73_COMPLETE passed=1 blocked=0 failed=0 shard=%d vectors=%d total_words=%s prefix_nodes=%d nodes_by_depth=%s endpoints=%d memo_cross_checks=%d partitions=%d count_sha256=%s\n",
    $shard,$profiles,$root_sum,$total_nodes,join(',',@nodes),
    $endpoint_checks,$memo_checks,$partitions,$hash;
