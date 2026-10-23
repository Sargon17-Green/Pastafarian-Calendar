use v5.40;
use utf8;
use strict;
use warnings;
use Test::More;
use Math::BigInt;

# 完全獨立的有限詞遞迴。不引入 Pastafari 的生產或測試 Oracle。
# 前次出現的月標籤必須依 1..4 順序關閉，首次亦如此。
sub independent_count ($L) {
    my %memo;
    my $walk;
    $walk=sub ($remaining,$opened,$closed) {
        my $key=join(',',@$remaining).":$opened:$closed";
        return $memo{$key} if exists $memo{$key};
        my $left=0;$left+=$_ for @$remaining;
        return $memo{$key}=Math::BigInt->bone if $left==0;
        my $sum=Math::BigInt->bzero;
        for my $j (1..($opened<4 ? $opened+1 : 4)) {
            next if !$remaining->[$j-1];
            next if $remaining->[$j-1]==1 && $j!=$closed+1;
            my @next=@$remaining;
            $next[$j-1]--;
            $sum->badd($walk->(
                \@next,$j>$opened ? $j : $opened,
                $next[$j-1]==0 ? $j : $closed
            ));
        }
        return $memo{$key}=$sum;
    };
    return $walk->([@$L],0,0)->copy;
}
is(''.independent_count([9,9,9,9]),'45407181480430770',
   '9 月四向量的獨立精確計數兼容 R65');
is(''.independent_count([10,10,10,9]),'2533511719279382270',
   '只有三個 10 日的四向量仍未跨越 int64');
my $highest=independent_count([10,10,10,10]);
is("$highest",'9754478684858928020',
   '全部 10 日向量需要超過 int64 的 BigInt');
ok($highest>Math::BigInt->new('9223372036854775807'),
   '精確計數嚴格超出有號 int64');
done_testing;
