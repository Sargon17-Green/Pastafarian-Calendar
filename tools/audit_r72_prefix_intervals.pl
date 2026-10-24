#!/usr/bin/env perl
use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use Math::BigInt;
use Digest::SHA qw(sha256_hex);
use lib 'lib','t/lib';
use Pastafari::WeavingMemoOracle;
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::WeavingRank qw(rankWeavingPolynomial);
use Pastafari::WeavingUnrank qw(unrankWeavingPolynomial);

# R72：非枚舉全部詞，而以獨立 DFS 求每個前綴所代表的
# 真正詞典序區間 [start,start+ways-1]，並由最小/最大合法
# 尾詞確認受測 rank/unrank 沒有暗中改動一基 BigInt 次序。
my $shard=0;
GetOptions('shard=i'=>\$shard) or die "R72 shard 參數不合法\n";
die "R72 只允許四個第一月份長度分片 1..4\n"
    unless $shard>=1 && $shard<=4;

my %expected_countsum=(1=>4056,2=>27697,3=>116768,4=>380893);
my %expected_hash=(
 1=>'23e29a89c0b0ae4d769d121bd1109e1d21752114227236c810390b7c6bd33da2',
 2=>'9831bee46cbf9d49a203ac3b530064d41c6ad074fe325c25f039a4a3da170e93',
 3=>'9c703bd25c34f7512945c2ffb80cb648b2722b1b7c0bdc33c3e862736594f224',
 4=>'aee9969ee80e407efccb96ea36e1ff68c07a1fa3d568e0bd93a7f0e032f7078c',
);

sub independent_count ($lengths) {
    my %memo;
    my $walk;
    $walk=sub ($rem,$opened,$closed) {
        my $key=join(',',@$rem).":$opened:$closed";
        return $memo{$key}->copy if exists $memo{$key};
        my $left=0; $left+=$_ for @$rem;
        return $memo{$key}=Math::BigInt->bone if $left==0;
        my $answer=Math::BigInt->bzero;
        for my $j (1..($opened<4?$opened+1:4)) {
            next unless $rem->[$j-1];
            next if $rem->[$j-1]==1 && $j!=$closed+1;
            my @next=@$rem;
            --$next[$j-1];
            $answer->badd($walk->(\@next,$j>$opened?$j:$opened,
                                   $next[$j-1]==0?$j:$closed));
        }
        $memo{$key}=$answer->copy;
        return $answer;
    };
    return ($walk,\%memo);
}
sub options ($rem,$opened,$closed,$count) {
    my @out;
    for my $j (1..($opened<4?$opened+1:4)) {
        next unless $rem->[$j-1];
        next if $rem->[$j-1]==1 && $j!=$closed+1;
        my @next=@$rem;
        --$next[$j-1];
        my $new_open=$j>$opened?$j:$opened;
        my $new_closed=$next[$j-1]==0?$j:$closed;
        my $ways=$count->(\@next,$new_open,$new_closed);
        next if $ways->is_zero;
        push @out,[$j,\@next,$new_open,$new_closed,$ways];
    }
    return @out;
}
sub independent_unrank ($lengths,$count,$global_rank) {
    my @rem=@$lengths;
    my ($opened,$closed)=(0,0);
    my $local=Math::BigInt->new("$global_rank");
    my $days=0;$days+=$_ for @$lengths;
    my @word;
    for my $day (1..$days) {
        my $parent=$count->(\@rem,$opened,$closed);
        my @choices=options(\@rem,$opened,$closed,$count);
        my $whole=Math::BigInt->bzero;
        $whole->badd($_->[4]) for @choices;
        die "R72 每步候選子樹不能分割母前綴\n"
            if $whole!=$parent;
        my $selected;
        for my $item (@choices) {
            if ($local<=$item->[4]) {$selected=$item;last}
            $local->bsub($item->[4]);
        }
        die "R72 無法由獨立 DFS 還原排名\n" unless $selected;
        push @word,$selected->[0];
        @rem=@{$selected->[1]};
        ($opened,$closed)=($selected->[2],$selected->[3]);
    }
    die "R72 獨立詞的葉節點非局部第一名\n" if $local!=1;
    die "R72 獨立詞未耗盡全部月份\n" if grep {$_} @rem;
    return \@word;
}
sub interval_and_tails ($lengths,$count,$prefix) {
    my @rem=@$lengths;
    my ($opened,$closed)=(0,0);
    my $start=Math::BigInt->bone;
    my @initial=@$prefix;
    for my $value (@$prefix) {
        my @choices=options(\@rem,$opened,$closed,$count);
        my $selected;
        for my $item (@choices) {
            if ($item->[0]==$value) {$selected=$item;last;}
            $start->badd($item->[4]);
        }
        die "R72 前綴沒有合法延伸\n" unless $selected;
        @rem=@{$selected->[1]};
        ($opened,$closed)=($selected->[2],$selected->[3]);
    }
    my $ways=$count->(\@rem,$opened,$closed);
    die "R72 prefix 對應空的完工字序集合\n" if $ways<1;
    my $finish=$start->copy->badd($ways)->bsub(1);
    my @extreme;
    for my $last (0,1) {
        my @remaining=@rem;
        my ($op,$cl)=($opened,$closed);
        my @word=@initial;
        while (grep {$_>0} @remaining) {
            my @choices=options(\@remaining,$op,$cl,$count);
            die "R72 prefix 後綴沒有合法可達選擇\n" unless @choices;
            my $item=$last?$choices[-1]:$choices[0];
            push @word,$item->[0];
            @remaining=@{$item->[1]};
            ($op,$cl)=($item->[2],$item->[3]);
        }
        die "R72 合法後綴未關完四個月份\n" if $cl!=4;
        push @extreme,\@word;
    }
    return ($start,$finish,$ways,@extreme);
}
sub key ($p) {return join(',',@$p);}

my @profile_entries;
my ($vectors,$sum,$intervals,$endpoint_checks,$outside_checks)=(0,0,0,0,0);
for my $b (1..4) {
 for my $c (1..4) {
  for my $d (1..4) {
   my @L=($shard,$b,$c,$d);
   my @initial=@L;
   my ($count,$memo)=independent_count(\@L);
   my $N=$count->([@L],0,0);
   my $poly=countWeavingsPolynomial(\@L);
   die "R72 另一插入多項式與獨立 DFS 總數不同\n" if $N!=$poly;
   my $oracle=Pastafari::WeavingMemoOracle->new(
       \@L,{bounded_cache=>1,cache_limit=>16,
            cache_policy=>'clock',early_final_closed_form=>1}
   );
   my $oracle_total=$oracle->count_prefix([]);
   die "R72 有界 oracle 總數不同\n" if "$oracle_total" ne "$N";
   my $days=0;$days+=$_ for @L;
   my @witness=(
       independent_unrank(\@L,$count,Math::BigInt->bone),
       independent_unrank(\@L,$count,$N->copy->bdiv(2)->badd(1)),
       independent_unrank(\@L,$count,$N),
   );
   my %cuts=map {$_=>1} (0,1,2,int($days/2),$days-1,$days);
   my %seen;
   my $local_intervals=0;
   for my $word (@witness) {
    for my $cut (sort {$a<=>$b} keys %cuts) {
     next if $cut>$days;
     my @prefix=$cut?@$word[0..$cut-1]:();
     my $pkey=key(\@prefix);
     next if $seen{$pkey}++;
     my ($start,$end,$ways,$first,$last)=
          interval_and_tails(\@L,$count,\@prefix);
     die "R72 prefix 大於原始總排名\n" if $start<1 || $end>$N;
     die "R72 局部候選數並非精確連續排名區間\n"
          if $end-$start+1!=$ways;
     my $answer=$oracle->count_prefix(\@prefix);
     die "R72 非獨立 clock/memo 的 prefix 計數不同\n"
          if $answer!=$ways;
     my $rank_first=rankWeavingPolynomial(\@L,$first);
     my $rank_last=rankWeavingPolynomial(\@L,$last);
     die "R72 真正字典序首詞的排名不等於區間起點\n"
          if $rank_first!=$start;
     die "R72 真正字典序尾詞的排名不等於區間終點\n"
          if $rank_last!=$end;
     my $decoded_first=unrankWeavingPolynomial(\@L,$start);
     my $decoded_last=unrankWeavingPolynomial(\@L,$end);
     die "R72 解碼區間起點不是首個合法完整詞\n"
          if key($decoded_first) ne key($first);
     die "R72 解碼區間終點不是最後合法完整詞\n"
          if key($decoded_last) ne key($last);
     $endpoint_checks+=4;
     if ($cut==int($days/2) && $cut>0) {
      for my $side (-1,1) {
       my $neighbor=$side<0
           ? $start->copy->bsub(1)
           : $end->copy->badd(1);
       next if $neighbor<1 || $neighbor>$N;
       my $outside=unrankWeavingPolynomial(\@L,$neighbor);
       die "R72 區間外相鄰詞不應共享該指定前綴\n"
           if key([@$outside[0..$cut-1]]) eq $pkey;
       $outside_checks++;
      }
     }
     $intervals++;
     $local_intervals++;
    }
   }
   die "R72 合法前綴區間覆蓋太少\n" if $local_intervals<5;
   my $diag=$oracle->diagnostics;
   die "R72 有界快取越界或提前閉式沒有實際運行\n"
       if $diag->{entries}>16 || !$diag->{early_closed_forms};
   die "R72 在驗證途中修改了輸入月份長度\n"
       if join(',',@L) ne join(',',@initial);
   my $n="$N";
   push @profile_entries,join(',',@L)."=$n";
   $sum+=$N;
   $vectors++;
   printf "R72_PREFIX_PROFILE_PASS lengths=%s total=%s intervals=%d\n",
       join(',',@L),$n,$local_intervals;
  }
 }
}
die "R72 非每片 64 個月份向量\n" if $vectors!=64;
die "R72 整片 64 向量精確總數不符合獨立基線\n"
    if $sum!=$expected_countsum{$shard};
my $digest=sha256_hex(join(';',@profile_entries));
die "R72 64 個獨立總數的 SHA256 清單不符合原始 Python 基線\n"
    if $digest ne $expected_hash{$shard};
die "R72 沒有逐個字序端點真正 rank/unrank\n"
    if $endpoint_checks!=$intervals*4;
die "R72 區間外獨立鄰詞沒有實際比對\n" if !$outside_checks;
printf "R72_COMPLETE passed=1 blocked=0 failed=0 shard=%d vectors=%d total_words=%s intervals=%d endpoint_checks=%d outside_neighbors=%d count_sha256=%s\n",
       $shard,$vectors,$sum,$intervals,$endpoint_checks,$outside_checks,$digest;
