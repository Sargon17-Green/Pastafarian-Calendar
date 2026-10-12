use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib','t/lib';
use Pastafari::WeavingSuffixFactor qw(countWeavingSuffixFactored);
use Pastafari::WeavingUnrank qw(unrankWeavingPolynomial);
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::NormativeScroll qw(unrankWeaving);

my $checked=0;
for my $lengths ([1,1,1],[2,2,2],[3,2,2],[4,4,4],
                 [2,2,2,2],[3,3,3,3],[4,4,4,4]) {
    my $total=countWeavingsPolynomial($lengths);
    my @ranks=(1,2,$total->copy->bdiv(2)->badd(1),$total);
    my %seen;
    for my $rank (@ranks) {
        next if $rank<1 || $rank>$total || $seen{"$rank"}++;
        my $word=unrankWeaving($lengths,$rank);
        my @remaining=@$lengths;
        my ($opened,$closed)=(0,0);
        my @prefix;
        for my $step (0 .. @$word) {
            my %stats;
            my $before=join(',',@remaining);
            my $raw=Pastafari::WeavingSuffixFactor::_countWeavingSuffixFactoredState(
                    $lengths,\@remaining,$opened,$closed,{},\%stats
                );
            my $full=countWeavingSuffixFactored($lengths,\@prefix);
            is("$raw","$full",
                '已驗證狀態捷徑與公開完整前綴的精確計數一致：'
                  .join('-',@$lengths)."/$rank/$step");
            is(join(',',@remaining),$before,
                '狀態介面不得改動呼叫者提供的剩餘日數向量');
            is($stats{factor_calls},1,'狀態介面每次只執行一次因式分解');
            $checked++;
            last if $step == @$word;
            my $j=$word->[$step];
            $opened=$j if $j>$opened;
            $remaining[$j-1]--;
            $closed=$j if !$remaining[$j-1];
            push @prefix,$j;
        }
    }
}
cmp_ok($checked,'>=',150,'超過一百五十個合法內部狀態逐一比對');

for my $lengths ([2,2,2],[4,4,4,4],[4,4,4,4,4]) {
    my $total=countWeavingsPolynomial($lengths);
    for my $rank (Math::BigInt->new(2),$total->copy->bdiv(2)->badd(1),
                  $total->copy->bsub(1)) {
        next if $rank<=1 || $rank>=$total;
        my @copy=@$lengths;
        my $answer=unrankWeavingPolynomial($lengths,$rank);
        is_deeply($answer,unrankWeaving($lengths,$rank),
            '狀態捷徑整合後仍保持獨立規範字典序');
        is_deeply($lengths,\@copy,'完整反排名不更改月份長度輸入');
    }
}
done_testing;
