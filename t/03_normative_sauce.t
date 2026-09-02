use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use lib 'lib', 't/lib';
use Pastafari::NormativeScroll qw(
    FOUNDATION_DAY workCounts buildHiddenDrops buildVisibleDrops sauce nextBowlInDrop46Order postStir12
);

my $f = FOUNDATION_DAY();
my @fixtures = (
    {
        delta => -1,
        hidden1 => '385360696959016217388918434899987398',
        visible1 => '144575801277822383338200354400111546592',
        visible46 => '151204316575656473729694124521071474078',
        bowls => [qw(
            53617910026188644408785518956929829705
            64099662087489283047126777093936773892
            139643152190900062978826723281224579214
            97190645139363776848883295392220726876
            95665604875729659804961905020962896942
            122469125164456629639876300862840789616
        )],
        order => [6,2,4,1,5,3],
    },
    {
        delta => 0,
        hidden1 => '119390830530032782664128530203002080344',
        visible1 => '56644603826892212324764499696091907135',
        visible46 => '141872771689426650819909896585756512282',
        bowls => [qw(
            65286679584284972964194865805379907599
            127720283375330263615328810127751035299
            54364069496183805843611594721403108554
            93072329024469476118876155742008280619
            54867842942953573450868747713087920246
            111207247632761530752404582123499651367
        )],
        order => [4,5,2,3,6,1],
    },
    {
        delta => 1,
        hidden1 => '85810332001725416653016433262819893812',
        visible1 => '83173269902412395672922919805999934831',
        visible46 => '103430891166207829578580984586604139424',
        bowls => [qw(
            70434042897387900551035702298758230041
            151850866568206521277785993322419084200
            46789989601168961860953147090427783906
            59157232574390061342797286434713623158
            58727783453082214425403502323380868121
            90529134939564904389153387230745526261
        )],
        order => [4,6,2,1,5,3],
    },
);

for my $fixture (@fixtures) {
    my $target = $f->copy->badd($fixture->{delta});
    my $counts = workCounts($f,$target);
    my $hidden = buildHiddenDrops($counts);
    my $visible = buildVisibleDrops($counts,undef,$hidden);
    my $result = sauce($f,$target);
    is("".$hidden->[1],$fixture->{hidden1},"偏移 $fixture->{delta} 的第一個隱藏滴固定");
    is("".$visible->[1],$fixture->{visible1},"偏移 $fixture->{delta} 的第一個可見滴固定");
    is("".$visible->[46],$fixture->{visible46},"偏移 $fixture->{delta} 的第四十六滴固定");
    is_deeply([map { "".$result->{bowls}[$_] } 1..6],$fixture->{bowls},"偏移 $fixture->{delta} 的十二次後攪拌結果固定");
    is_deeply($result->{orderAtDrop46},$fixture->{order},"偏移 $fixture->{delta} 保留第四十六滴順序");
    my $last = $fixture->{order}[-1];
    is(nextBowlInDrop46Order($result,$last),$fixture->{order}[0],"偏移 $fixture->{delta} 的循環下一碗正確");
}

my @simple = (undef, map { Math::BigInt->new($_) } 1..6);
my $a1 = postStir12(\@simple);
is_deeply([map { "".$a1->[$_] } 1..6], [qw(
    141132694112953656784802743599690311793
    136632892414948082655633411464102794505
    134404201440819867177248219965286133396
    114290835991731114228285355792902410488
    133747246005993698450862842763676230984
    38641804819033612619357638081595297714
)], "A1 使用加入一百四十九倍攪拌序號後保存的同一總和");

done_testing;
