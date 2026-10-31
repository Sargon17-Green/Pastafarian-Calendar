use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib';
use Pastafari::Monster::CutletOccurrence qw(cutlet_occurrence);
use Pastafari::SourceLanguageCatalog qw(cutlet_entries);

# 獨立逐日展開 oracle：不用生產的累積界限/區段查找演算法。
my $entries = cutlet_entries();
my @names = map { $_->{source} } @$entries;
my $positions_checked = 0;
for my $case (
    [[(42) x 6], [1,17,3,4,5,6]],
    [[(963) x 6], [17,16,15,14,13,12]],
    [[(15) x 17], [reverse 1..17]],
) {
    my ($lengths, $indexes) = @$case;
    my @expanded;
    for my $i (0 .. $#$lengths) {
        push @expanded, map { [$i + 1, $indexes->[$i], $_] } 1 .. $lengths->[$i];
    }
    for my $day (1 .. @expanded) {
        my ($index, $name_index, $ordinal) = @{ $expanded[$day - 1] };
        my $actual = cutlet_occurrence($lengths, $indexes, $day);
        is($actual->{cutletIndex}, $index, '肉排序號');
        is($actual->{cutletName}, $names[$name_index - 1], '名稱目錄映射');
        is("$actual->{dayInCutlet}", "$ordinal", '肉排內日數');
        ++$positions_checked;
    }
}
ok($positions_checked >= 6000, '獨立逐日展開涵蓋最小及最大年長');
my $anchor = cutlet_occurrence([(42) x 6], [1,17,3,4,5,6], 43);
is($anchor->{cutletName}, '空陶罐', '固定第十七名稱錨點');
is("$anchor->{dayInCutlet}", '1', '區段交界後第一日');
is(cutlet_occurrence([(42) x 6], [1,17,3,4,5,6], 1)->{cutletName}, '青銅', '固定第一名稱錨點');

my @lengths = ((42) x 6);
my @indices = (1,17,3,4,5,6);
my $big_position = Math::BigInt->new(252);
my $result = cutlet_occurrence(\@lengths, \@indices, $big_position);
is("$result->{dayInCutlet}", '42', 'BigInt 日期位置邊界');
$result->{dayInCutlet}->badd(99);
is("$big_position", '252', '輸出不共享輸入的 BigInt');
is(join(',', @lengths), join(',', (42) x 6), '日長輸入未改變');
is(join(',', @indices), '1,17,3,4,5,6', '名稱輸入未改變');

for my $bad (0, -1, 'x', '01', undef, [], Math::BigInt->new('9' x 80), 253) {
    ok(!eval { cutlet_occurrence([(42) x 6], [1,17,3,4,5,6], $bad); 1 }, '拒絕無效日期位置');
}
for my $bad_lengths (
    [], [(42) x 5], [(42) x 18], [(41) x 6], [(963) x 6, 1],
    [0, (42) x 5], [-1, (42) x 5], ['042', (42) x 5],
    ['x', (42) x 5], [Math::BigInt->new('9' x 80), (42) x 5],
) {
    my $n = scalar @$bad_lengths;
    my @ids = (1..$n);
    ok(!eval { cutlet_occurrence($bad_lengths, \@ids, 1); 1 }, '拒絕無效肉排界限');
}
for my $bad_names (
    [], [1,2,3], [1,2,3,4,5,5], [0,2,3,4,5,6],
    [18,2,3,4,5,6], ['01',2,3,4,5,6], [undef,2,3,4,5,6],
) {
    ok(!eval { cutlet_occurrence([(42) x 6], $bad_names, 1); 1 }, '拒絕無效名稱配置');
}
for my $bad_input (undef, {}, 'abc') {
    ok(!eval { cutlet_occurrence($bad_input, [1..6], 1); 1 }, '拒絕非陣列日長');
}
note("STAGE05_INDEPENDENT_DAY_POSITIONS=$positions_checked");
note('STAGE05_FULL_CANONICAL_FIVE_FIELDS_NOT_VERIFIED');
done_testing;
