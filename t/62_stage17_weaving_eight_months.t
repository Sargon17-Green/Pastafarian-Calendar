use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib';
use Pastafari::Monster::WeavingPrimitive qw(count_weavings rank_weaving unrank_weaving);

# Independent oracle: enumerate ALL distinct multiset permutations. Only
# completed words are filtered by increasing first and last occurrences.
# Neither the production transitions nor its memoization are used.
sub multiset_oracle ($profile) {
    my @left = @$profile;
    my @prefix;
    my @accepted;
    my $m = @$profile;
    my $walk;
    $walk = sub {
        if (!grep { $_ } @left) {
            my (@first, @last);
            for my $i (0 .. $#prefix) {
                my $j = $prefix[$i] - 1;
                $first[$j] //= $i;
                $last[$j] = $i;
            }
            for my $j (1 .. $m-1) {
                return if $first[$j-1] >= $first[$j];
                return if $last[$j-1] >= $last[$j];
            }
            push @accepted, [@prefix];
            return;
        }
        for my $label (1 .. $m) {
            next unless $left[$label-1];
            --$left[$label-1];
            push @prefix, $label;
            $walk->();
            pop @prefix;
            ++$left[$label-1];
        }
    };
    $walk->();
    return \@accepted;
}

my ($exhaustive_profiles, $exhaustive_positions) = (0, 0);
for my $profile ([(1) x 8], [2,(1) x 7], [3,(1) x 7], [2,2,(1) x 6]) {
    my $expected = multiset_oracle($profile);
    ++$exhaustive_profiles;
    is(''.count_weavings($profile), ''.scalar(@$expected), '全排列後過濾的獨立總數');
    for my $i (0 .. $#$expected) {
        my $rank = Math::BigInt->new($i+1);
        is_deeply(unrank_weaving($profile,$rank), $expected->[$i], '反排名符合全排列 oracle');
        is(''.rank_weaving($profile,$expected->[$i]), "$rank", '排名符合全排列 oracle');
        ++$exhaustive_positions;
    }
}

# Independent Dyck-path bijection for two copies of every label.
# U = first occurrence (next opening label), D = last occurrence
# (next closing label). Every Dyck word produces one admissible weaving.
sub dyck_oracle ($m) {
    my @words;
    my @prefix;
    my $enumerate;
    $enumerate = sub ($opens, $closes) {
        if ($closes == $m) {
            push @words, [@prefix];
            return;
        }
        if ($opens < $m) {
            push @prefix, $opens + 1;
            $enumerate->($opens+1, $closes);
            pop @prefix;
        }
        if ($closes < $opens) {
            push @prefix, $closes + 1;
            $enumerate->($opens, $closes+1);
            pop @prefix;
        }
    };
    $enumerate->(0,0);
    return [ sort {
        for my $i (0 .. $#$a) {
            my $cmp = $a->[$i] <=> $b->[$i];
            return $cmp if $cmp;
        }
        return 0;
    } @words ];
}
my $cat8 = Math::BigInt->new(16)->bfac;
$cat8->bdiv(Math::BigInt->new(8)->bfac);
$cat8->bdiv(Math::BigInt->new(9)->bfac);
is("$cat8", '1430', '獨立 Catalan(8) = 16! / 8! / 9!');
my $dyck = dyck_oracle(8);
is(scalar(@$dyck), 1430, '獨立 Dyck 路徑計數');
my $pairs = [(2) x 8];
is(''.count_weavings($pairs), "$cat8", '生產計數符合 Catalan 閉式');
for my $rank (1 .. 1430) {
    my $word = unrank_weaving($pairs,$rank);
    is_deeply($word, $dyck->[$rank-1], '反排名符合獨立 Dyck 字典序');
    is(''.rank_weaving($pairs,$word), "$rank", '全部 1430 個排名精確往返');
}

my $large_profiles = 0;
for my $profile ([(4) x 8], [10,4,3,3,3,3,3,3], [25,(1) x 7], [32]) {
    my $days = 0; $days += $_ for @$profile;
    is($days,32,'三十二日輸入');
    my $total = count_weavings($profile);
    isa_ok($total,'Math::BigInt');
    cmp_ok($total,'>=',1,'計數是正值');
    my $mid = $total->copy->badd(1)->bdiv(2);
    my $saved = join(',',@$profile);
    for my $rank (Math::BigInt->bone, $mid, $total->copy) {
        my $rank_before = "$rank";
        my $word = unrank_weaving($profile,$rank);
        is(scalar(@$word),32,'完整三十二日輸出');
        is(''.rank_weaving($profile,$word),$rank_before,'三十二日首中末 BigInt 往返');
        is("$rank",$rank_before,'傳入 BigInt 不變');
        is(join(',',@$profile),$saved,'傳入月份不變');
    }
    ++$large_profiles;
}

my $invalid_profiles = 0;
for my $profile (
    undef, [], [(1)x13], [49], [40,(1)x9], [1,1,1,1,1,1,1,1,1,40],
    [0], [-1], [1.5], ['2x'], ['03'], [undef], {}, [Math::BigInt->bone]
) {
    ok(!eval {count_weavings($profile);1}, '拒絕九月／三十三日／非法資料型態');
    ++$invalid_profiles;
}
my $invalid_ranks = 0;
for my $rank (undef, 0, -1, 'abc', 'NaN', '1.5', '0x10',
    Math::BigInt->new(1431), Math::BigInt->new('9'x45), [], {}) {
    ok(!eval {unrank_weaving($pairs,$rank);1}, '拒絕無效排名或超限');
    ++$invalid_ranks;
}
my $invalid_words = 0;
for my $word (
    undef, [], [1,2], [(1)x16],
    [2,1,1,2,(3)x2,(4)x2,(5)x2,(6)x2,(7)x2,(8)x2],
    [1,2,2,1,(3)x2,(4)x2,(5)x2,(6)x2,(7)x2,(8)x2],
    [1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,'x'],
    [1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,9]
) {
    ok(!eval {rank_weaving($pairs,$word);1}, '拒絕非法標籤／次數／次序');
    ++$invalid_words;
}

my $profile = [(4)x8];
my $rank = Math::BigInt->new(2);
my $word = unrank_weaving($profile,$rank);
my $copy = [@$word];
$word->[0] = 999;
is_deeply(unrank_weaving($profile,$rank),$copy,'輸出不共享可變狀態');
is("$rank", '2','輸出變異後傳入排名仍不變');

note("STAGE17_EXHAUSTIVE_PROFILES=$exhaustive_profiles");
note("STAGE17_EXHAUSTIVE_POSITIONS=$exhaustive_positions");
note('STAGE17_CATALAN8_DYCK_WORDS=1430');
note('STAGE17_CATALAN8_RANKS=1430');
note("STAGE17_LARGE_32DAY_PROFILES=$large_profiles");
note("STAGE17_INVALID_PROFILES=$invalid_profiles");
note("STAGE17_INVALID_RANKS=$invalid_ranks");
note("STAGE17_INVALID_WORDS=$invalid_words");
note('STAGE17_FULL_YEAR_GENERATOR_NOT_VERIFIED');
done_testing;
