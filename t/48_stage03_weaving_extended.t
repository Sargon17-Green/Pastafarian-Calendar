use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib';
use Pastafari::Monster::WeavingPrimitive qw(count_weavings rank_weaving unrank_weaving);

# 獨立 Oracle：全部不重複多重集合排列，完成後才過濾首見和末見。
# 不使用生產程式的剩餘狀態動態規劃或下一步剪枝。
sub exhaustive_oracle ($profile) {
    my @remaining = @$profile;
    my @prefix;
    my @valid;
    my $m = scalar @$profile;
    my $visit;
    $visit = sub {
        if (!grep { $_ } @remaining) {
            my (@first,@last);
            for my $i (0 .. $#prefix) {
                my $symbol = $prefix[$i] - 1;
                $first[$symbol] //= $i;
                $last[$symbol] = $i;
            }
            for my $j (1 .. $m - 1) {
                return if $first[$j-1] >= $first[$j] || $last[$j-1] >= $last[$j];
            }
            push @valid, [@prefix];
            return;
        }
        for my $j (1 .. $m) {
            next unless $remaining[$j-1];
            --$remaining[$j-1];
            push @prefix, $j;
            $visit->();
            pop @prefix;
            ++$remaining[$j-1];
        }
    };
    $visit->();
    return \@valid;
}

for my $p ([2,2,2,2,2],[2,2,2,1,1,1],[3,2,2,1,1,1]) {
    my $oracle = exhaustive_oracle($p);
    is(''.count_weavings($p), ''.scalar(@$oracle), '完整多重集合窮舉計數一致');
    for my $i (0 .. $#$oracle) {
        is_deeply(unrank_weaving($p,$i+1),$oracle->[$i],'獨立窮舉反排名一致');
        is(''.rank_weaving($p,$oracle->[$i]),''.($i+1),'獨立窮舉排名一致');
    }
}
# 對兩次出現的 m 個標籤，合法完整序列數是 Catalan(m)。
# 閉式與排列窮舉不同；此處驗證六個月的新邊界。
my $catalan6 = Math::BigInt->new(1);
for my $i (1 .. 12) { $catalan6->bmul($i); }
for my $i (1 .. 6) { $catalan6->bdiv($i); }
for my $i (1 .. 7) { $catalan6->bdiv($i); }
is("$catalan6",'132','Catalan 閉式獨立算術檢查');
my $six = [(2) x 6];
is(''.count_weavings($six),"$catalan6",'六月份二日總數');
for my $i (1 .. 132) {
    my $w = unrank_weaving($six,$i);
    is(''.rank_weaving($six,$w),"$i",'六月份所有 132 個排名往返');
}
for my $p ([(4) x 6],[24]) {
    my $total = count_weavings($p);
    isa_ok($total,'Math::BigInt');
    ok($total >= 1, '二十四日計數正值');
    my @ranks = (Math::BigInt->bone,
                 $total->copy->badd(1)->bdiv(2),
                 $total->copy);
    for my $rank (@ranks) {
        my $unchanged = "$rank";
        my $word = unrank_weaving($p,$rank);
        is(scalar(@$word),24,'完整二十四日輸出');
        is(''.rank_weaving($p,$word),$unchanged,'邊界排名與反排名可逆');
        is("$rank",$unchanged,'呼叫不修改 BigInt 排名');
    }
}
for my $invalid ([],[0],[25],[(1) x 7],[12,13],[2,'3x'],undef) {
    ok(!eval { count_weavings($invalid); 1 },'拒絕超界與非數字月份設定');
}
for my $invalid_rank (0,-1,'abc',Math::BigInt->new('9'x60),undef) {
    ok(!eval { unrank_weaving([(4) x 6],$invalid_rank); 1 },'拒絕非法排名');
}
ok(!eval { rank_weaving([2,2],[1,2,2,1]); 1 },'拒絕末次出現倒置');
ok(!eval { rank_weaving([2,2],[2,1,1,2]); 1 },'拒絕首次出現倒置');
ok(!eval { rank_weaving([2,2],[1,1,2]); 1 },'拒絕序列長度不符');
my $profile = [(4) x 6];
my $snapshot = join ',',@$profile;
my $r = Math::BigInt->new(132);
my $w = unrank_weaving($profile,$r);
$w->[0] = 99;
is(join(',',@$profile),$snapshot,'設定檔不可被修改');
is("$r",'132','傳入的 BigInt 不可被修改');

done_testing;
