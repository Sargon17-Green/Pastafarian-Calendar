use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib';
use Pastafari::Monster::WeavingPrimitive qw(count_weavings rank_weaving unrank_weaving);

# Oracle A: enumerate complete multiset permutations without production
# transition pruning, then independently check first/last-occurrence order.
sub brute_words ($profile) {
    my @left = @$profile;
    my @work;
    my @accepted;
    my $m = scalar @$profile;
    my $visit;
    $visit = sub {
        if (!grep { $_ } @left) {
            my (@first, @last);
            for my $at (0 .. $#work) {
                my $idx = $work[$at] - 1;
                $first[$idx] //= $at;
                $last[$idx] = $at;
            }
            for my $idx (1 .. $m - 1) {
                return if $first[$idx - 1] >= $first[$idx];
                return if $last[$idx - 1] >= $last[$idx];
            }
            push @accepted, [@work];
            return;
        }
        for my $label (1 .. $m) {
            next unless $left[$label - 1];
            --$left[$label - 1];
            push @work, $label;
            $visit->();
            pop @work;
            ++$left[$label - 1];
        }
    };
    $visit->();
    return \@accepted;
}

my ($profiles, $positions) = (0, 0);
for my $profile (
    [(1) x 9],
    [2, (1) x 8],
    [1,1,2,(1) x 6],
    [1,1,1,2,(1) x 5],
) {
    my $oracle = brute_words($profile);
    ++$profiles;
    is(''.count_weavings($profile), ''.scalar(@$oracle), '九月多重集合全部完成序列的獨立計數');
    for my $idx (0 .. $#$oracle) {
        my $rank = Math::BigInt->new($idx + 1);
        is_deeply(unrank_weaving($profile, $rank), $oracle->[$idx], '字典序對照獨立全排列');
        is(''.rank_weaving($profile, $oracle->[$idx]), "$rank", '每個獨立全排列排名一致');
        ++$positions;
    }
}

# Oracle B: enumerate legal Dyck open/close strings. This constructs
# labels from opening and closing counters, not the production DP.
sub independent_dyck ($m) {
    my @all;
    my @work;
    my $visit;
    $visit = sub ($up, $down) {
        if ($down == $m) {
            push @all, [@work];
            return;
        }
        if ($up < $m) {
            push @work, $up + 1;
            $visit->($up + 1, $down);
            pop @work;
        }
        if ($down < $up) {
            push @work, $down + 1;
            $visit->($up, $down + 1);
            pop @work;
        }
    };
    $visit->(0,0);
    return [sort {
        my $cmp = 0;
        for my $i (0 .. $#$a) {
            $cmp = $a->[$i] <=> $b->[$i];
            last if $cmp;
        }
        $cmp;
    } @all];
}
my $catalan = Math::BigInt->new(18)->bfac;
$catalan->bdiv(Math::BigInt->new(9)->bfac);
$catalan->bdiv(Math::BigInt->new(10)->bfac);
is("$catalan", '4862', 'Catalan(9) = 18!/(9! 10!)');
my $dyck = independent_dyck(9);
is(scalar(@$dyck), 4862, '獨立九對 Dyck 路徑數');
my $pairs = [(2) x 9];
is(''.count_weavings($pairs), '4862', '生產九月份總數吻合閉式');
for my $rank (1 .. 4862) {
    my $word = unrank_weaving($pairs, $rank);
    is_deeply($word, $dyck->[$rank - 1], '全部 Dyck 字典序比對');
    is(''.rank_weaving($pairs, $word), "$rank", '全部 Catalan(9) 雙向排名');
}

my $large = 0;
for my $profile ([(4)x9], [28,(1)x8], [36]) {
    my $sum = 0; $sum += $_ for @$profile;
    is($sum, 36, '36-day boundary profile');
    my $count = count_weavings($profile);
    isa_ok($count, 'Math::BigInt');
    cmp_ok($count, '>=', 1, 'exact nonzero count');
    my $middle = $count->copy->badd(1)->bdiv(2);
    my $snapshot = join(',', @$profile);
    for my $rank (Math::BigInt->bone, $middle, $count->copy) {
        my $saved = "$rank";
        my $word = unrank_weaving($profile, $rank);
        is(scalar(@$word), 36, '36-day output length');
        is(''.rank_weaving($profile, $word), $saved, 'BigInt rank/unrank roundtrip');
        is("$rank", $saved, 'BigInt input unchanged');
        is(join(',', @$profile), $snapshot, 'profile unchanged');
    }
    ++$large;
}

my $invalid_profiles = 0;
for my $bad (
    undef, [], [(1)x11], [41], [32,(1)x9],
    [1,1,1,1,1,1,1,1,1,32], [0], [-1], [1.5],
    ['02'], ['2x'], [undef], {}, [Math::BigInt->bone]
) {
    ok(!eval {count_weavings($bad);1}, 'reject invalid profile');
    ++$invalid_profiles;
}
my $invalid_ranks = 0;
for my $rank (undef, 0, -1, 'abc', 'NaN', '1.5', '0x10',
    Math::BigInt->new(4863), Math::BigInt->new('9'x45), [], {}) {
    ok(!eval {unrank_weaving($pairs,$rank);1}, 'reject invalid rank');
    ++$invalid_ranks;
}
my $invalid_words = 0;
for my $word (
    undef, [], [1,2], [(1)x18],
    [2,1,1,2,(3)x2,(4)x2,(5)x2,(6)x2,(7)x2,(8)x2,(9)x2],
    [1,2,2,1,(3)x2,(4)x2,(5)x2,(6)x2,(7)x2,(8)x2,(9)x2],
    [1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,'x'],
    [1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,10]
) {
    ok(!eval {rank_weaving($pairs,$word);1}, 'reject invalid word');
    ++$invalid_words;
}

my $rank = Math::BigInt->new(2);
my $word = unrank_weaving([(4)x9], $rank);
my $copy = [@$word];
$word->[0] = 999;
is_deeply(unrank_weaving([(4)x9], $rank), $copy, 'returned word has no shared mutable state');
is("$rank",'2','input rank unchanged');

note("STAGE18_EXHAUSTIVE_PROFILES=$profiles");
note("STAGE18_EXHAUSTIVE_POSITIONS=$positions");
note('STAGE18_CATALAN9_DYCK_WORDS=4862');
note('STAGE18_CATALAN9_RANKS=4862');
note("STAGE18_LARGE_36DAY_PROFILES=$large");
note("STAGE18_INVALID_PROFILES=$invalid_profiles");
note("STAGE18_INVALID_RANKS=$invalid_ranks");
note("STAGE18_INVALID_WORDS=$invalid_words");
note('STAGE18_FULL_YEAR_GENERATOR_NOT_VERIFIED');
done_testing;
