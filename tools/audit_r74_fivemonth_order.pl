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

# R74：真正跨入五個月份，而非重複以前的四月證據。
# 獨立 DFS 用局部合法選擇生成實際 1-based 字序與後綴數，
# 對 1..3 的 3^5=243 個向量同時核對原生 rank/unrank、
# 有界記憶式 Oracle、位置分布多項式，以及五個月反轉雙射。
my $shard=0;
GetOptions('shard=i'=>\$shard) or die "R74 shard 參數無效\n";
die "R74 shard 僅可取 1..3\n" if $shard<1 || $shard>3;
my %fixed_sum=(1=>'3703',2=>'18719',3=>'64121');
my %fixed_sha=(
 1=>'7081ddef2b4f08c855979a86c0eaf8323491dce1e669d7fc0885ffd2a97faf14',
 2=>'1bbf1195a27f99d60e9ce004b7385ff379eec6f115a59927abf446c695f2d126',
 3=>'252cc5821cb54d747c57ae131cd33b7dc0bf7ec50126e3ce01e35aacc9693f6f',
);
sub independently_count ($lengths) {
    my $m=@$lengths;
    my %memo;
    my $walk;
    $walk=sub ($remaining,$opened,$closed) {
        my $key=join(',',@$remaining).":$opened:$closed";
        return $memo{$key}->copy if exists $memo{$key};
        my $left=0;$left+=$_ for @$remaining;
        return $memo{$key}=Math::BigInt->bone if $left==0;
        my $ways=Math::BigInt->bzero;
        for my $j (1..($opened<$m?$opened+1:$m)) {
            next unless $remaining->[$j-1];
            next if $remaining->[$j-1]==1 && $j!=$closed+1;
            my @next=@$remaining;
            --$next[$j-1];
            $ways->badd($walk->(\@next,$j>$opened?$j:$opened,
                        !$next[$j-1]?$j:$closed));
        }
        $memo{$key}=$ways->copy;
        return $ways;
    };
    return ($walk,\%memo);
}
sub next_options ($lengths,$remaining,$opened,$closed,$counter) {
    my @choices;
    my $m=@$lengths;
    for my $j (1..($opened<$m?$opened+1:$m)) {
        next unless $remaining->[$j-1];
        next if $remaining->[$j-1]==1 && $j!=$closed+1;
        my @after=@$remaining;
        --$after[$j-1];
        my $op=$j>$opened?$j:$opened;
        my $cl=!$after[$j-1]?$j:$closed;
        my $ways=$counter->(\@after,$op,$cl);
        next if $ways->is_zero;
        push @choices,[$j,\@after,$op,$cl,$ways];
    }
    return @choices;
}
sub independent_unrank ($lengths,$counter,$global_rank) {
    my @remaining=@$lengths;
    my ($opened,$closed)=(0,0);
    my $local=Math::BigInt->new("$global_rank");
    my $days=0;$days+=$_ for @$lengths;
    my @word;
    for my $day (1..$days) {
        my @choices=next_options($lengths,\@remaining,$opened,$closed,$counter);
        my $total=$counter->(\@remaining,$opened,$closed);
        my $sum=Math::BigInt->bzero;
        $sum->badd($_->[4]) for @choices;
        die "R74 第 $day 日合法子樹未構成無遺漏分割\n" if $total!=$sum;
        my $selected;
        for my $opt (@choices) {
            if ($local<=$opt->[4]) {$selected=$opt;last;}
            $local->bsub($opt->[4]);
        }
        die "R74 自行解碼無法找到合法完整後綴\n" unless $selected;
        push @word,$selected->[0];
        @remaining=@{$selected->[1]};
        ($opened,$closed)=($selected->[2],$selected->[3]);
    }
    die "R74 最終局部排名不為一\n" if $local!=1;
    die "R74 尚有未用完月份\n" if grep {$_} @remaining;
    return \@word;
}
sub independent_rank ($lengths,$counter,$word) {
    my @remaining=@$lengths;
    my ($opened,$closed)=(0,0);
    my $rank=Math::BigInt->bone;
    for my $value (@$word) {
        my @choices=next_options($lengths,\@remaining,$opened,$closed,$counter);
        my $chosen;
        for my $opt (@choices) {
            if ($opt->[0]==$value) {$chosen=$opt;last;}
            $rank->badd($opt->[4]);
        }
        die "R74 字詞不符合真正五個月首末次序\n" unless $chosen;
        @remaining=@{$chosen->[1]};
        ($opened,$closed)=($chosen->[2],$chosen->[3]);
    }
    die "R74 排名時沒有使用全部月份\n" if grep {$_} @remaining;
    return $rank;
}
sub independent_prefix ($lengths,$counter,$prefix) {
    my @remaining=@$lengths;
    my ($opened,$closed)=(0,0);
    for my $value (@$prefix) {
        my $selected;
        for my $opt (next_options($lengths,\@remaining,$opened,$closed,$counter)) {
            if ($opt->[0]==$value) {$selected=$opt;last;}
        }
        die "R74 被測前綴不合法\n" unless $selected;
        @remaining=@{$selected->[1]};
        ($opened,$closed)=($selected->[2],$selected->[3]);
    }
    return $counter->(\@remaining,$opened,$closed);
}
sub key ($word) {return join(',',@$word);}

my ($profiles,$ranks,$prefixes,$mirrors)=(0,0,0,0);
my $total_all=Math::BigInt->bzero;
my @entries;
for my $b (1..3) {
 for my $c (1..3) {
  for my $d (1..3) {
   for my $e (1..3) {
    my @L=($shard,$b,$c,$d,$e);
    my @original=@L;
    my @rev=reverse @L;
    my ($count,$memo)=independently_count(\@L);
    my ($counter_reversed,$memo_reversed)=independently_count(\@rev);
    my $N=$count->([@L],0,0);
    my $N_reversed=$counter_reversed->([@rev],0,0);
    die "R74 五個月字序反轉雙射總數不同\n" if $N!=$N_reversed;
    die "R74 五個月位置多項式總數不同\n"
        if countWeavingsPolynomial(\@L)!=$N;
    my $clock=Pastafari::WeavingMemoOracle->new(
        \@L,{bounded_cache=>1,cache_limit=>16,cache_policy=>'clock',
             early_final_closed_form=>1});
    die "R74 有界 clock 總數和獨立 DFS 不同\n"
        if $clock->count_prefix([])!=$N;
    my $days=0;$days+=$_ for @L;
    my @samples=(
       Math::BigInt->bone,Math::BigInt->new(2),
       $N->copy->bdiv(2)->badd(1),
       $N->copy->bsub(1),$N->copy
    );
    my %unique;
    for my $r (@samples) {
        next if $r<1 || $r>$N || $unique{"$r"}++;
        my $rank_original="$r";
        my $word=independent_unrank(\@L,$count,$r);
        die "R74 五個月獨立正向排名無法復原\n"
            if independent_rank(\@L,$count,$word)!=$r;
        die "R74 五個月受測正向排名不一致\n"
            if rankWeavingPolynomial(\@L,$word)!=$r;
        my $native=unrankWeavingPolynomial(\@L,$r);
        die "R74 五個月受測反排名不一致\n"
            if key($native) ne key($word);
        my @mirror=map {6-$_} reverse @$word;
        my $mirror_rank=independent_rank(\@rev,$counter_reversed,\@mirror);
        die "R74 倒序補標籤的五個月原生排名不一致\n"
            if rankWeavingPolynomial(\@rev,\@mirror)!=$mirror_rank;
        my $mirror_native=unrankWeavingPolynomial(\@rev,$mirror_rank);
        die "R74 倒序補標籤的五個月原生反排名不一致\n"
            if key($mirror_native) ne key(\@mirror);
        my @restored=map {6-$_} reverse @mirror;
        die "R74 五個月雙重倒序不還原完整詞\n"
            if key(\@restored) ne key($word);
        die "R74 測試更改了原始 BigInt 排名\n" if "$r" ne $rank_original;
        my %cuts=map {$_=>1} (0,1,2,int($days/2),$days-1,$days);
        for my $cut (sort {$a<=>$b} keys %cuts) {
            my @prefix=$cut?@$word[0..$cut-1]:();
            my $correct=independent_prefix(\@L,$count,\@prefix);
            die "R74 五個月 prefix 時計數失真\n"
                if $clock->count_prefix(\@prefix)!=$correct;
            $prefixes++;
        }
        $ranks++;
        $mirrors++;
    }
    my $diag=$clock->diagnostics;
    die "R74 clock 16 BigInt 項上限被突破\n" if $diag->{entries}>16;
    die "R74 修改了原始月份長度\n"
        if join(',',@L) ne join(',',@original);
    my $full="$N";
    push @entries,join(',',@L)."=$full";
    $total_all->badd($N);
    $profiles++;
    printf "R74_PROFILE_PASS lengths=%s total=%s native_ranks=%d\n",
           join(',',@L),$full,scalar(keys %unique);
   }
  }
 }
}
die "R74 每份必須處理恰好 81 個五個月向量\n" if $profiles!=81;
die "R74 分片總數與兩種外部獨立模型的真值不同\n"
    if "$total_all" ne $fixed_sum{$shard};
my $hash=sha256_hex(join(';',@entries));
die "R74 81 個五個月精確總數的 SHA-256 基線錯誤\n"
    if $hash ne $fixed_sha{$shard};
die "R74 每條排名必須檢查合法鏡射\n"
    if $ranks!=$mirrors || $ranks<81;
die "R74 沒有檢查實際五個月前綴完工數\n" if $prefixes<$ranks*4;
printf "R74_COMPLETE passed=1 blocked=0 failed=0 shard=%d profiles=%d total_words=%s rank_and_mirrors=%d prefixes=%d fixture_sha256=%s\n",
       $shard,$profiles,$total_all,$ranks,$prefixes,$hash;
