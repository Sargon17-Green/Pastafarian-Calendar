#!/usr/bin/env perl
use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use Math::BigInt;
use Digest::SHA qw(sha512_hex);
use lib 'lib','t/lib';
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::WeavingRank qw(rankWeavingPolynomial);
use Pastafari::WeavingUnrank qw(unrankWeavingPolynomial);

# R68 Stage 1：僅四月份。獨立逐步合法後繼 DFS 再做
# BigInt 1-based unrank；不調用受測後綴多項式、rank/unrank。
my $profile='';
GetOptions('profile=s'=>\$profile) or die "R68 無效參數\n";
my %profiles=(
    a=>[[10,10,10,11],'34837538497713607370'],
    b=>[[11,11,11,11],'2134397833143177403516'],
);
die "R68 必須明確指定 a 或 b\n" if !exists $profiles{$profile};
my ($lengths,$expected)=@{$profiles{$profile}};
my @before=@$lengths;
my $m=@$lengths;
my $days=0; $days+=$_ for @$lengths;
my %memo;
my ($decisions,$partition_checks,$nontrivial)=(0,0,0);
my $count;
$count=sub ($rem,$opened,$closed) {
    my $key=join(',',@$rem).":$opened:$closed";
    return $memo{$key}->copy if exists $memo{$key};
    my $left=0; $left+=$_ for @$rem;
    return $memo{$key}=Math::BigInt->bone if $left==0;
    my $sum=Math::BigInt->bzero;
    my $upper=$opened<$m?$opened+1:$m;
    for my $j (1..$upper) {
        next unless $rem->[$j-1];
        next if $rem->[$j-1]==1 && $j!=$closed+1;
        my @next=@$rem;
        --$next[$j-1];
        $sum->badd($count->(\@next,$j>$opened?$j:$opened,
                            $next[$j-1]==0?$j:$closed));
    }
    $memo{$key}=$sum->copy;
    return $sum;
};
sub candidates ($rem,$opened,$closed) {
    my @found;
    for my $j (1..($opened<$m?$opened+1:$m)) {
        next unless $rem->[$j-1];
        next if $rem->[$j-1]==1 && $j!=$closed+1;
        my @after=@$rem;
        --$after[$j-1];
        my $new_open=$j>$opened?$j:$opened;
        my $new_closed=$after[$j-1]==0?$j:$closed;
        my $ways=$count->(\@after,$new_open,$new_closed);
        push @found,[$j,\@after,$new_open,$new_closed,$ways];
    }
    return @found;
}
sub independent_unrank ($rank1) {
    my @rem=@$lengths;
    my ($opened,$closed)=(0,0);
    my $position=Math::BigInt->new("$rank1");
    my @word;
    for my $day (1..$days) {
        my $parent=$count->(\@rem,$opened,$closed);
        my @opts=candidates(\@rem,$opened,$closed);
        my $sum=Math::BigInt->bzero;
        $sum->badd($_->[4]) for @opts;
        die "R68 候選枝數之和不等於母前綴 day=$day\n"
            if $sum!=$parent;
        $partition_checks++;
        die "R68 子樹局部名次超過父前綴\n"
            if $position<1 || $position>$parent;
        my $chosen;
        for my $opt (@opts) {
            $decisions++;
            if ($position<=$opt->[4]) {
                $chosen=$opt;
                last;
            }
            $position->bsub($opt->[4]);
        }
        die "R68 非完整候選分割\n" unless defined $chosen;
        $nontrivial++ if @opts>1;
        push @word,$chosen->[0];
        @rem=@{$chosen->[1]};
        ($opened,$closed)=($chosen->[2],$chosen->[3]);
    }
    die "R68 還有月份未結束\n" if grep {$_} @rem;
    die "R68 葉節點局部排名不為一\n" if $position!=1;
    return \@word;
}
sub independent_rank ($word) {
    my @rem=@$lengths;
    my ($opened,$closed)=(0,0);
    my $rank=Math::BigInt->bone;
    for my $chosen (@$word) {
        my @opts=candidates(\@rem,$opened,$closed);
        my $selected;
        for my $opt (@opts) {
            if ($opt->[0]==$chosen) {
                $selected=$opt; last;
            }
            $rank->badd($opt->[4]);
        }
        die "R68 完整詞包含非法標籤\n" if !defined $selected;
        @rem=@{$selected->[1]};
        ($opened,$closed)=($selected->[2],$selected->[3]);
    }
    die "R68 排名結束時月份未耗盡\n" if grep {$_} @rem;
    return $rank;
}

my $total=$count->([@$lengths],0,0);
die "R68 獨立 BigInt 固定真值不符\n" if "$total" ne $expected;
die "R68 不同插入多項式總數不符\n"
    if countWeavingsPolynomial($lengths)!=$total;
my @samples=(
    Math::BigInt->bone,
    Math::BigInt->new(2),
    Math::BigInt->new('9223372036854775807'),
    Math::BigInt->new('9223372036854775808'),
    Math::BigInt->new('9223372036854775809'),
    $total->copy->bdiv(2)->badd(1),
    $total->copy->bsub(1),
    $total->copy,
);
my $hash=sha512_hex("PASTAFARIAN-FOURMONTH-R68:$profile");
push @samples,Math::BigInt->from_hex("0x$hash")->bmod($total)->badd(1);
my %seen;
my $verified=0;
for my $rank (@samples) {
    die "R68 名次超過完整 BigInt 有效範圍\n"
        if $rank<1 || $rank>$total;
    die "R68 不允許重複排名樣本\n" if $seen{"$rank"}++;
    my $original="$rank";
    my $word=independent_unrank($rank);
    die "R68 獨立解碼非完整詞\n" if @$word!=$days;
    die "R68 解析器更改原始排名\n" if "$rank" ne $original;
    my $independent=independent_rank($word);
    die "R68 獨立逆排名非原始一基 BigInt\n"
        if "$independent" ne $original;
    my $decoded=unrankWeavingPolynomial($lengths,$rank);
    die "R68 既有 unrank 與獨立完整字序不同\n"
        if join(',',@$word) ne join(',',@$decoded);
    my @untouched=@$decoded;
    my $back=rankWeavingPolynomial($lengths,$decoded);
    die "R68 既有 rank 與獨立完整名次不同\n"
        if "$back" ne $original;
    die "R68 被測排名器修改了完整詞\n"
        if join(',',@$decoded) ne join(',',@untouched);
    die "R68 任務修改了樣本 BigInt\n" if "$rank" ne $original;
    printf "R68_RANK_SAMPLE status=PASS profile=%s rank=%s days=%d candidate_checks=%d\n",
        $profile,$original,$days,$decisions;
    $verified++;
}
die "R68 不是完整九個互異名次\n" if $verified!=9;
die "R68 沒有實際分支選擇\n" if !$nontrivial;
die "R68 沒有逐日核對所有父候選和\n"
    if $partition_checks!=$days*$verified;
die "R68 修改輸入長度\n" if join(',',@$lengths) ne join(',',@before);
printf "R68_RANK_COMPLETE status=PASS profile=%s ranks=%d decisions=%d partitions=%d memo_states=%d days=%d\n",
    $profile,$verified,$decisions,$partition_checks,scalar(keys %memo),$days;
