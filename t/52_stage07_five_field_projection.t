use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib';
use Pastafari::Monster::FiveFieldProjection qw(five_field_projection);
use Pastafari::SourceLanguageCatalog qw(cutlet_entries month_entries);

# Independent day expansion, not the production module's prefix scan/search.
my @cutlet_catalogue = map { $_->{source} } @{cutlet_entries()};
my @month_catalogue = map { $_->{source} } @{month_entries()};
my @fixtures = (
    {len => 252, open => -1000, number => -7,
     cutletPartition => [(42) x 6], cutletNames => [1,17,3,4,5,6],
     monthLengths => [84,84,84], monthNames => [1,47,2]},
    {len => 963, open => 0, number => 0,
     cutletPartition => [((160) x 5),163], cutletNames => [6,5,4,3,2,1],
     monthLengths => [((123) x 7),102], monthNames => [10..17]},
    {len => 5778, open => 10000, number => 5000,
     cutletPartition => [((340) x 16),338], cutletNames => [reverse 1..17],
     monthLengths => [((123) x 46),120], monthNames => [1..47]},
);
my $checked = 0;
my $expanded = 0;
for my $f (@fixtures) {
    my $year = {
        number => Math::BigInt->new($f->{number}),
        openGateDay => Math::BigInt->new($f->{open}),
        closeGateDay => Math::BigInt->new($f->{open} + $f->{len}),
    };
    my @word;
    for my $i (0 .. $#{$f->{monthLengths}}) {
        push @word, ($i + 1) x $f->{monthLengths}[$i];
    }
    my $structure = {
        cutletPartition => [@{$f->{cutletPartition}}],
        cutletNames => [@{$f->{cutletNames}}],
        monthLengths => [@{$f->{monthLengths}}],
        monthNames => [@{$f->{monthNames}}],
        monthWeaving => \@word,
    };
    my @cutlet_days;
    for my $i (0 .. $#{$f->{cutletPartition}}) {
        push @cutlet_days,
            map { [$cutlet_catalogue[$f->{cutletNames}[$i] - 1], $_] }
                1 .. $f->{cutletPartition}[$i];
    }
    my @month_days;
    for my $i (0 .. $#{$f->{monthLengths}}) {
        push @month_days,
            map { [$month_catalogue[$f->{monthNames}[$i] - 1], $_] }
                1 .. $f->{monthLengths}[$i];
    }
    is(scalar(@cutlet_days), $f->{len}, '獨立肉排日位置展開');
    is(scalar(@month_days), $f->{len}, '獨立月份日位置展開');
    $expanded += $f->{len};
    my %probe = (1 => 1, $f->{len} => 1);
    if ($f->{len} <= 963) {
        $probe{$_} = 1 for 1 .. $f->{len};
    } else {
        $probe{$_} = 1 for map { 1 + int($_ * ($f->{len} - 1) / 99) } 0 .. 99;
    }
    my $acc = 0;
    for my $l (@{$f->{cutletPartition}}) {
        $acc += $l;
        $probe{$acc} = 1;
        $probe{$acc+1} = 1 if $acc < $f->{len};
    }
    $acc = 0;
    for my $l (@{$f->{monthLengths}}) {
        $acc += $l;
        $probe{$acc} = 1;
        $probe{$acc+1} = 1 if $acc < $f->{len};
    }
    for my $day (sort {$a <=> $b} keys %probe) {
        my $result = five_field_projection($year,$structure,$f->{open}+$day);
        my $a = $cutlet_days[$day-1];
        my $b = $month_days[$day-1];
        is(scalar(@$result),5,'回傳恰五欄');
        is("$result->[0]", "$f->{number}", '年份編號');
        is($result->[1],$a->[0],'肉排名稱');
        is("$result->[2]","$a->[1]",'肉排日數');
        is($result->[3],$b->[0],'月份名稱');
        is("$result->[4]","$b->[1]",'月份日數');
        ++$checked;
    }
    ok(!eval{five_field_projection($year,$structure,$f->{open});1}, '開閘日不屬於年份');
    ok(!eval{five_field_projection($year,$structure,$f->{open}+$f->{len}+1);1}, '閉閘日次日不屬於年份');
    my $one = five_field_projection($year,$structure,$f->{open}+1);
    $one->[0]->badd(23);
    $one->[2]->badd(23);
    $one->[4]->badd(23);
    is("$year->{number}", "$f->{number}", '輸出不別名化輸入年份');
    is("$year->{openGateDay}", "$f->{open}", '開閘日輸入不變');
    is("$year->{closeGateDay}", "".($f->{open}+$f->{len}), '閉閘日輸入不變');
}

# A genuinely interleaved word respecting ordered first and last positions.
my $f=$fixtures[0];
my $year={number=>1,openGateDay=>0,closeGateDay=>252};
my @interleaved=((1)x40,(2)x40,(1)x44,(3)x40,(2)x44,(3)x44);
my $base={cutletPartition=>[(42)x6],cutletNames=>[1..6],
          monthLengths=>[84,84,84],monthNames=>[1,2,3],monthWeaving=>\@interleaved};
# Word actually contains 84 of each month and ordered last occurrences 1,2,3.
is(scalar(@interleaved),252,'交錯月份字串長度');
is("".five_field_projection($year,$base,41)->[4], '1', '月二首次出現');
is("".five_field_projection($year,$base,81)->[4], '41', '月一後續出現');

sub bad ($changes, $label) {
    my %copy=%$base;
    $copy{$_}=$changes->{$_} for keys %$changes;
    ok(!eval{five_field_projection($year,\%copy,41);1}, $label);
}
bad({monthLengths=>[84,84]},'拒絕月份名稱數量不匹配');
bad({monthLengths=>[84,84,83]},'拒絕月份長度總和不匹配');
bad({monthLengths=>[84,84,124]},'拒絕月份長度上界');
bad({monthNames=>[1,1,2]},'拒絕重複月份名稱');
bad({monthNames=>[1,48,2]},'拒絕非法月份名稱索引');
bad({monthNames=>['01',2,3]},'拒絕前導零名稱索引');
bad({cutletPartition=>[(41)x6]},'拒絕肉排總長不符');
bad({cutletNames=>[1,1,2,3,4,5]},'拒絕重複肉排名稱');
bad({cutletNames=>[1,2,3,4,5,18]},'拒絕超界肉排名稱');
bad({monthWeaving=>[@interleaved[0..250]]},'拒絕月份交織日數不符');
my @bad_counts=@interleaved; $bad_counts[0]=2;
bad({monthWeaving=>\@bad_counts},'拒絕月份交織計數不符');
my @bad_order=((2)x84,(1)x84,(3)x84);
bad({monthWeaving=>\@bad_order},'拒絕月份首次次序不符');
my @bad_last=((1)x40,(2)x44,(1)x44,(3)x84,(2)x40);
bad({monthWeaving=>\@bad_last},'拒絕月份末次次序不符');
my @bad_zero=@interleaved; $bad_zero[0]='01';
bad({monthWeaving=>\@bad_zero},'拒絕前導零月份索引');
my @bad_type=@interleaved; $bad_type[0]=[];
bad({monthWeaving=>\@bad_type},'拒絕非整數月份索引');
for my $missing (qw(cutletPartition cutletNames monthLengths monthNames monthWeaving)) {
    bad({$missing=>undef},"拒絕缺少欄位 $missing");
}
for my $day (0,-1,253,'01','x',undef,[],{}) {
    ok(!eval{five_field_projection($year,$base,$day);1},'拒絕非法日期');
}
for my $invalid (undef,[],17) {
    ok(!eval{five_field_projection($invalid,$base,41);1},'拒絕非法年份記錄');
    ok(!eval{five_field_projection($year,$invalid,41);1},'拒絕非法年份結構');
}
# Catalog anchors are explicit fixed literals, not derived from a producer result.
is(five_field_projection($year,$base,1)->[1], '青銅', '固定肉排名稱錨點');
is(five_field_projection($year,$base,1)->[3], '黏土', '固定月份名稱錨點');
note("STAGE07_INDEPENDENT_EXPANDED_POSITIONS=$expanded");
note("STAGE07_INDEPENDENT_COMPARED_POSITIONS=$checked");
note('STAGE07_FULL_GENERATOR_NOT_VERIFIED');
ok($checked >= 1300,'至少 1300 個五欄位置比較');
done_testing;
