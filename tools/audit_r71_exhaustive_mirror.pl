#!/usr/bin/env perl
use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Math::BigInt;
use Getopt::Long qw(GetOptions);
use lib 'lib','t/lib';
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::WeavingMemoOracle;
use Pastafari::WeavingRank qw(rankWeavingPolynomial);
use Pastafari::WeavingUnrank qw(unrankWeavingPolynomial);

# R71: 枚舉四月份 1..3 的 81 個長度向量，原生重建全部合法詞。
# 不用受測 rank/unrank 生成期望詞，也不用鏡射算法枚舉原始詞。
my $shard=0;
GetOptions('shard=i'=>\$shard) or die "R71 不合法 shard\n";
die "R71 分片必須是第一月份長度 1..3\n"
    unless $shard>=1 && $shard<=3;

sub enumerate_legal_words ($sizes) {
    my @remaining=@$sizes;
    my $total=0;$total+=$_ for @remaining;
    my @words;
    my $visit;
    $visit=sub ($opened,$closed,$word) {
        if (@$word==$total) {
            die "R71 非完整合法詞進入葉節點\n"
                if grep {$_!=0} @remaining;
            push @words,[@$word];
            return;
        }
        my $upper=$opened<4?$opened+1:4;
        for my $j (1..$upper) {
            next unless $remaining[$j-1];
            next if $remaining[$j-1]==1 && $j!=$closed+1;
            --$remaining[$j-1];
            push @$word,$j;
            $visit->(
                $j>$opened?$j:$opened,
                !$remaining[$j-1]?$j:$closed,
                $word
            );
            pop @$word;
            ++$remaining[$j-1];
        }
    };
    $visit->(0,0,[]);
    return \@words;
}

sub key ($word) { return join(',',@$word); }
sub equal_word ($a,$b) { return key($a) eq key($b); }

my %expected_shard_words=(1=>215,2=>892,3=>2596);
my ($vectors,$source_words,$mirrors,$roundtrip_checks)=(0,0,0,0);
my %all_profile_counts;
for my $b (1..3) {
    for my $c (1..3) {
        for my $d (1..3) {
            my @L=($shard,$b,$c,$d);
            my @rev=reverse @L;
            my $src=enumerate_legal_words(\@L);
            my $target=enumerate_legal_words(\@rev);
            die "R71 非獨立枚舉的來源／目標長度不相等\n"
                unless @$src==@$target;
            die "R71 字典序原始枚舉為空\n" unless @$src;
            my $n=@$src;
            my $poly=countWeavingsPolynomial(\@L);
            die "R71 原生枚舉與位置多項式結果不同\n"
                if "$poly" ne "$n";
            my $memo=Pastafari::WeavingMemoOracle->new(\@L);
            die "R71 原生枚舉與不同狀態 Memo Oracle 不同\n"
                if ''.$memo->count_prefix([]) ne "$n";
            my %target_indices;
            for my $j (0..$#$target) {
                my $k=key($target->[$j]);
                die "R71 目標詞有重複\n" if exists $target_indices{$k};
                $target_indices{$k}=$j+1;
            }
            die "R71 鏡射的合法目標詞表不完整\n"
                if keys(%target_indices)!=$n;
            my %hit;
            my $last_key='';
            for my $i (0..$#$src) {
                my $word=$src->[$i];
                my $source_key=key($word);
                die "R71 原始完整合法詞未嚴格遞增\n"
                    if $i && $source_key eq $last_key;
                $last_key=$source_key;
                my $rank=Math::BigInt->new($i+1);
                die "R71 原生 rank 與真正詞典序索引不同\n"
                    if rankWeavingPolynomial(\@L,$word)!=$rank;
                my $decoded=unrankWeavingPolynomial(\@L,$rank);
                die "R71 原生 unrank 與獨立枚舉不同\n"
                    unless equal_word($decoded,$word);
                my @mirror=map {5-$_} reverse @$word;
                my $mkey=key(\@mirror);
                die "R71 反轉補標籤不屬於目標合法完整詞\n"
                    unless exists $target_indices{$mkey};
                die "R71 不同來源詞映成相同目標詞\n"
                    if $hit{$mkey}++;
                my $target_rank=Math::BigInt->new($target_indices{$mkey});
                die "R71 反轉詞的 rank 與獨立枚舉不一致\n"
                    if rankWeavingPolynomial(\@rev,\@mirror)!=$target_rank;
                my $target_decoded=unrankWeavingPolynomial(\@rev,$target_rank);
                die "R71 反轉詞的 unrank 與獨立枚舉不一致\n"
                    unless equal_word($target_decoded,\@mirror);
                my @restored=map {5-$_} reverse @mirror;
                die "R71 反轉補標籤兩次未恢復原詞\n"
                    unless equal_word(\@restored,$word);
                $mirrors++;
                $roundtrip_checks+=4;
            }
            die "R71 反轉映射並未覆蓋全部合法目標詞\n"
                if keys(%hit)!=$n;
            my $pkey=join(',',@L);
            die "R71 長度向量重複\n"
                if exists $all_profile_counts{$pkey};
            $all_profile_counts{$pkey}=$n;
            $vectors++;
            $source_words+=$n;
            printf "R71_PROFILE_PASS lengths=%s legal_words=%d verified_mirrors=%d\n",
                $pkey,$n,$n;
        }
    }
}
die "R71 每個 shard 必須恰有 27 向量\n" if $vectors!=27;
die "R71 各片全部字序固定基數與獨立基線不同\n"
    if $source_words!=$expected_shard_words{$shard};
die "R71 鏡射或雙向 native 檢驗不完整\n"
    if $mirrors!=$source_words || $roundtrip_checks!=$source_words*4;
printf "R71_COMPLETE passed=1 blocked=0 failed=0 shard=%d profiles=%d words=%d mirrors=%d rank_unrank_checks=%d\n",
    $shard,$vectors,$source_words,$mirrors,$roundtrip_checks;
