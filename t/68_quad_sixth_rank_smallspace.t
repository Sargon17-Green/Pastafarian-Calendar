use v5.40;
use utf8;
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib','t/lib';
use Pastafari::WeavingUnrank qw(unrankWeavingPolynomial);
use Pastafari::WeavingRank qw(rankWeavingPolynomial);

# 原理不同的有限枚舉：以真實合法「首次按順序、末次按順序」
# 的狀態遞迴，完全不呼叫任何位置多項式/前沿 Oracle。
# 四個月 4,4,3,2，共 13 日，字序足夠多讓第五日選第三月。
my @lengths=(4,4,3,2);
my %memo;
sub brute ($remaining,$opened,$closed) {
    my $key=join(',',@$remaining)."|$opened|$closed";
    return $memo{$key} if exists $memo{$key};
    my $left=0;$left+=$_ for @$remaining;
    return $memo{$key}=1 if $left==0;
    my $max=$opened<@lengths ? $opened+1 : scalar(@lengths);
    my $ways=0;
    for my $j (1..$max) {
        next if !$remaining->[$j-1];
        next if $remaining->[$j-1]==1 && $j!=$closed+1;
        my @new=@$remaining;
        $new[$j-1]--;
        my $next_closed=$new[$j-1] ? $closed : $j;
        $ways+=brute(\@new,$j>$opened ? $j : $opened,$next_closed);
    }
    return $memo{$key}=$ways;
}
sub prefix_count ($prefix) {
    my @remaining=@lengths;
    my ($opened,$closed)=(0,0);
    for my $j (@$prefix) {
        return 0 if $j<1 || $j>@lengths;
        return 0 if $j>$opened+1 || !$remaining[$j-1];
        return 0 if $remaining[$j-1]==1 && $j!=$closed+1;
        $remaining[$j-1]--;
        $opened=$j if $j>$opened;
        $closed=$j if !$remaining[$j-1];
    }
    return brute(\@remaining,$opened,$closed);
}
my $n=prefix_count([]);
is($n,3063,'13 日 4,4,3,2 的直接合法字序總數');
my $mid=int($n/2)+1;
is($mid,1532,'直接算出的中位一基排名');
my @parent=(1,2,1,2,3);
my $p12=prefix_count([1,2]);
my $p1211=prefix_count([1,2,1,1]);
my $p12121=prefix_count([1,2,1,2,1]);
my $p12122=prefix_count([1,2,1,2,2]);
my $p=prefix_count(\@parent);
my $local=$mid-($n-$p12)-$p1211-$p12121-$p12122;
is($p,105,'第六日四候選的共同完整母前綴');
is($local,24,'先扣除各日較小分支後的一基排名');
my @counts=map {prefix_count([@parent,$_])} 1..4;
is_deeply(\@counts,[48,24,18,15],
          '不用多項式的四個第六日完工數');
my $sum=0;$sum+=$_ for @counts;
is($sum,$p,'第六日四候選合計恰等於父前綴');
my $independent;
for my $j (1..4) {
    if ($local<=$counts[$j-1]) {
        $independent=$j;
        last;
    }
    $local-=$counts[$j-1];
}
is($independent,1,'獨立有限枚舉在第六日選 1');
my $word=unrankWeavingPolynomial(
    \@lengths,Math::BigInt->new($mid),
    undef,{profile_engine=>'stream-indexed',max_temp_file_bytes=>1048576}
);
is_deeply([@$word[0..4]],\@parent,
          '13 日實例的前五字也符合獨立數學排名');
is($word->[5],$independent,
   '正式索引式第六字和獨立枚舉 BigInt 分支選擇相同');
is(scalar(@$word),13,'所有 13 天完整輸出');
my @actual=(0)x4;
$actual[$_-1]++ for @$word;
is_deeply(\@actual,\@lengths,'詞中各月份天數保持原值');
my $back=rankWeavingPolynomial(
    \@lengths,$word,undef,
    {profile_engine=>'stream-indexed',max_temp_file_bytes=>1048576}
);
is("$back","$mid",'有限枚舉中位排名能由索引雙向精確還原');
done_testing;
