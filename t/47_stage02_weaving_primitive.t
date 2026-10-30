use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib', 't/lib';
use Pastafari::Monster::WeavingPrimitive qw(count_weavings rank_weaving unrank_weaving);
use Pastafari::NormativeScroll qw(countWeavings unrankWeaving);

# 與生產演算法不同：直接窮舉多重集合的全部排列，再過濾首次及末次順序。
sub exhaustive_oracle ($profile) {
    my @words;
    my @remaining = @$profile;
    my @prefix;
    my $m = @$profile;
    my $enumerate;
    $enumerate = sub {
        if (!grep { $_ } @remaining) {
            my (%first, %last);
            for my $i (0 .. $#prefix) {
                $first{$prefix[$i]} //= $i;
                $last{$prefix[$i]} = $i;
            }
            for my $j (2 .. $m) {
                return if $first{$j-1} >= $first{$j} || $last{$j-1} >= $last{$j};
            }
            push @words, [@prefix];
            return;
        }
        for my $j (1 .. $m) {
            next if !$remaining[$j-1];
            --$remaining[$j-1];
            push @prefix, $j;
            $enumerate->();
            pop @prefix;
            ++$remaining[$j-1];
        }
    };
    $enumerate->();
    return \@words;
}

my $cases = 0;
for my $profile ([1],[1,1,1],[2,2],[2,3,2],[3,3,3],[2,2,2,2]) {
    my $oracle = exhaustive_oracle($profile);
    is(''.count_weavings($profile), ''.scalar(@$oracle), '窮舉與生產計數一致');
    for my $i (0 .. $#$oracle) {
        my $rank = Math::BigInt->new($i+1);
        my $word = unrank_weaving($profile, $rank);
        is_deeply($word, $oracle->[$i], '反排名與獨立窮舉一致');
        is(''.rank_weaving($profile, $oracle->[$i]), "$rank", '排名與獨立窮舉一致');
        ++$cases;
    }
}
cmp_ok($cases,'>=',100,'已核對至少一百個獨立窮舉案例');

is_deeply(unrank_weaving([2,2],2),[1,2,1,2],'明確的規範二日示例');
is(''.rank_weaving([2,2],[1,1,2,2]),'1','第一個序列排名為一');

for my $invalid ([],[0],[13],[1,1,1,1,1],[1,'2x'],undef) {
    my $ok = eval { count_weavings($invalid); 1 };
    ok(!$ok,'不合法月份長度遭拒');
}
for my $rank (0,-1,3,Math::BigInt->new('9'x50),'abc',undef) {
    my $ok = eval { unrank_weaving([2,2],$rank); 1 };
    ok(!$ok,'超出範圍排名遭拒');
}
for my $word ([1,2,2,1],[2,1,1,2],[1,1,1,2],[1,2,2],[1,1,2,'x'],undef) {
    my $ok = eval { rank_weaving([2,2],$word); 1 };
    ok(!$ok,'不合法交織序列遭拒');
}
my $profile = [2,3,2];
my $original_profile = join(',',@$profile);
my $big_rank = Math::BigInt->new(4);
my $word = unrank_weaving($profile,$big_rank);
$word->[0]=99;
is(join(',',@$profile),$original_profile,'輸入設定檔未被修改');
is("$big_rank",'4','外部 Math::BigInt 排名未被修改');

# 規範 Oracle 限定測試端；生產模組絕不可載入 t/lib。
for my $p ([1],[2,2],[2,3,2],[2,2,2,2]) {
    my $n = count_weavings($p);
    is("$n",''.countWeavings($p), '測試專用規範計數吻合');
    for my $rank (1 .. $n) {
        is_deeply(unrank_weaving($p,$rank),
            unrankWeaving($p,$rank),
            '規範測試庫的反排名差分吻合');
    }
}

done_testing;
