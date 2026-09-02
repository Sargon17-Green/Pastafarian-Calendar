use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use lib 'lib', 't/lib';
use Pastafari::NormativeScroll qw(
    FOUNDATION_DAY makeBoundedCompositionFamily makeCutletPartitionFamily
    countWeavings unrankWeaving positiveGateGap negativeGateGap resetGateCache year5000
);

my $bounded = makeBoundedCompositionFamily(8,2,3,5);
is("".$bounded->{count}->(),'3','有界組成的精確計數為三');
is_deeply($bounded->{unrank1}->(1),[3,5],'有界組成第一列按字典序');
is_deeply($bounded->{unrank1}->(2),[4,4],'有界組成第二列按字典序');
is_deeply($bounded->{unrank1}->(3),[5,3],'有界組成第三列按字典序');

sub brute_partitions ($G,$K,$required) {
    my @out;
    my $walk;
    $walk = sub ($rem,$slots,$row) {
        if ($slots == 0) {
            return if $rem != 0;
            my $sum = 0;
            my $hit = 0;
            for my $x (@$row) { $sum += $x; $hit = 1 if defined($required) && $sum == $required }
            return if defined($required) && !$hit;
            push @out, [@$row];
            return;
        }
        my $max = $rem - ($slots - 1);
        for my $x (1..$max) { $walk->($rem-$x,$slots-1,[@$row,$x]) }
    };
    $walk->($G,$K,[]);
    return \@out;
}

my $family = makeCutletPartitionFamily(7,3,3);
my $brute = brute_partitions(7,3,3);
is("".$family->{count}->(),"".scalar(@$brute),'肉排分割 DP 與小型完整列舉的計數一致');
for my $rank (1..scalar @$brute) {
    is_deeply($family->{unrank1}->($rank),$brute->[$rank-1],"肉排分割第 $rank 列與字典序完整列舉一致");
}

is("".countWeavings([2,2]),'2','兩個各兩日月份共有兩種合法交織');
is_deeply(unrankWeaving([2,2],1),[1,1,2,2],'交織第一列為一一二二');
is_deeply(unrankWeaving([2,2],2),[1,2,1,2],'交織第二列為一二一二');

resetGateCache();
is(positiveGateGap(1),345,'第一個正向閘門間距固定');
is(negativeGateGap(1),503,'第一個負向閘門間距固定');
is(positiveGateGap(2),818,'第二個正向閘門間距固定');
is(negativeGateGap(2),441,'第二個負向閘門間距固定');

resetGateCache();
my $y = year5000(FOUNDATION_DAY());
is("".$y->{number},'5000','奠基日所用錨定年份編號為五千');
is($y->{openGateIndex},-4,'奠基日錨定年份開閘索引固定');
is($y->{closeGateIndex},4,'奠基日錨定年份閉閘索引固定');
is("".$y->{openGateDay},'-15057703','奠基日錨定年份開閘日固定');
is("".$y->{closeGateDay},'-15053459','奠基日錨定年份閉閘日固定');
is("".$y->{closeGateDay}->copy->bsub($y->{openGateDay}),'4244','錨定年份長度落在規範上限內');

done_testing;
