use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib';
use Pastafari::Monster::CutletPartitionGeneration qw(cutlet_partition_family);

# Oracle A: 獨立遞迴枚舉所有正整數有序組成，再由前綴和過濾必要分界。
sub exhaustive ($g, $k, $required) {
    my @out;
    my $walk;
    $walk = sub ($left, $slots, $prefix, $values, $hit) {
        if ($slots == 1) {
            my $last = $left;
            push @out, [@$values, $last] if !defined($required) || $hit;
            return;
        }
        for my $length (1 .. $left - $slots + 1) {
            my $next = $prefix + $length;
            $walk->($left - $length, $slots - 1, $next,
                     [@$values, $length], $hit || (defined($required) && $next == $required));
        }
    };
    $walk->($g, $k, 0, [], 0);
    return \@out;
}

# Oracle B: Pascal 三角形，只使用加法，而非生產端的二項乘除計算。
my @pascal = ([Math::BigInt->bone]);
for my $n (1 .. 136) {
    my @row = (Math::BigInt->bone);
    for my $j (1 .. $n - 1) {
        push @row, $pascal[$n - 1][$j - 1]->copy->badd($pascal[$n - 1][$j]);
    }
    push @row, Math::BigInt->bone;
    $pascal[$n] = \@row;
}
sub pascal_choose ($n, $k) {
    return $pascal[$n][$k]->copy;
}

my ($cases, $families) = (0, 0);
for my $g (6 .. 12) {
    for my $k (6 .. ($g < 8 ? $g : 8)) {
        for my $required (undef, 1 .. $g - 1) {
            my $expected = exhaustive($g, $k, $required);
            my $family = cutlet_partition_family($g, $k, $required);
            my $count = defined($required) ? pascal_choose($g - 2, $k - 2)
                                            : pascal_choose($g - 1, $k - 1);
            is(''.$family->{count}->(), "$count", "獨立 Pascal 計數 G=$g K=$k");
            is(''.$family->{count}->(), ''.scalar(@$expected), '遞迴枚舉數目相符');
            for my $idx (0 .. $#$expected) {
                is_deeply($family->{unrank1}->($idx + 1), $expected->[$idx],
                          '逐一核對字典序切分');
                ++$cases;
            }
            ++$families;
        }
    }
}

my $large_checked = 0;
for my $fixture ([137,17,undef], [137,17,1], [137,17,68], [137,17,136],
                 [137,6,undef], [137,6,60], [6,6,undef], [6,6,4]) {
    my ($g,$k,$required) = @$fixture;
    my $f = cutlet_partition_family($g,$k,$required);
    my $n = defined($required) ? pascal_choose($g-2,$k-2) : pascal_choose($g-1,$k-1);
    is(''.$f->{count}->(), "$n", '大範圍 Pascal 精確計數');
    for my $rank (Math::BigInt->bone, $n->copy->bdiv(2)->badd(1), $n->copy) {
        my $snapshot = "$rank";
        my $partition = $f->{unrank1}->($rank);
        is(scalar @$partition, $k, '肉排數目');
        my $sum = 0;
        my $valid = 1;
        my $hit = 0;
        for my $i (0 .. $#$partition) {
            my $length = $partition->[$i];
            $valid &&= $length >= 1 && $length <= $g;
            $sum += $length;
            $hit ||= defined($required) && $sum == $required && $i < $#$partition;
        }
        ok($valid, '全部肉排日長為正整數');
        is($sum,$g,'長度總和等於閘區間');
        ok(!defined($required) || $hit,'必要切點存在於內部邊界');
        is("$rank",$snapshot,'傳入排名 BigInt 未被修改');
        ++$large_checked;
    }
    ok(!eval { $f->{unrank1}->($n->copy->badd(1)); 1 }, '拒絕超界排名');
    my $copy = $f->{count}->(); $copy->badd(123);
    is(''.$f->{count}->(), "$n", 'BigInt 計數無別名洩漏');
    my $a = $f->{unrank1}->(1);
    $a->[0] = -999;
    is_deeply($f->{unrank1}->(1),$f->{unrank1}->(1),'返回分割陣列無跨呼叫別名');
}

my $stable = cutlet_partition_family(9,6,3);
for my $bad ([5,6,undef], [138,6,undef], [6,5,undef], [17,18,undef],
             [6,7,undef], [137,0,undef], [undef,6,undef], [6,undef,undef],
             ['06',6,undef], [6,'06',undef], [6,6,0], [6,6,6], [6,6,'01'],
             [6,6,-1], [6,6,'1.0'], [6,6,[]], [[],6,undef],
             [6,{},undef], [6,6,{}]) {
    ok(!eval { cutlet_partition_family(@$bad); 1 }, '拒絕無效閘數／肉排數／必要切點');
}
for my $bad (undef, 0, '00', '01', '-1', '1.0', 'abc', [], {}, Math::BigInt->bzero) {
    ok(!eval { $stable->{unrank1}->($bad); 1 }, '拒絕無效排名');
}
my $g = Math::BigInt->new(12);
my $k = Math::BigInt->new(6);
my $r = Math::BigInt->new(4);
my $f = cutlet_partition_family($g,$k,$r);
is(''.$f->{count}->(), ''.pascal_choose(10,4), '接受 BigInt 輸入');
is("$g",'12','未改動閘區間 BigInt');
is("$k",'6','未改動肉排數 BigInt');
is("$r",'4','未改動必要切點 BigInt');
note("STAGE09_INDEPENDENT_ENUMERATED=$cases");
note("STAGE09_INDEPENDENT_FAMILIES=$families");
note("STAGE09_LARGE_RANK_CASES=$large_checked");
note('STAGE09_FULL_GENERATOR_NOT_VERIFIED');
done_testing;
