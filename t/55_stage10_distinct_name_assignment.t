use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib';
use Pastafari::Monster::DistinctNameAssignment qw(distinct_name_family);

# Oracle A: recursive ordered enumeration without factorials or producer calls.
sub enumerate ($n, $k) {
    my (@out, @path, %used);
    my $walk;
    $walk = sub {
        if (@path == $k) {
            push @out, [@path];
            return;
        }
        for my $value (1 .. $n) {
            next if $used{$value};
            $used{$value} = 1;
            push @path, $value;
            $walk->();
            pop @path;
            delete $used{$value};
        }
    };
    $walk->();
    return \@out;
}

# Oracle B: reconstruct rank by counting earlier available choices * trailing permutations.
# Uses a direct product of remaining slots, not the producer's quotient blocks.
sub oracle_rank ($n, $k, $sequence) {
    my @available = 1 .. $n;
    my $rank = Math::BigInt->bone;
    for my $i (0 .. $k - 1) {
        my $value = $sequence->[$i];
        my $smaller = scalar grep { $_ < $value } @available;
        my $tail = Math::BigInt->bone;
        for my $j (0 .. ($k - $i - 2)) {
            $tail->bmul($n - $i - 1 - $j);
        }
        $rank->badd($tail->bmul($smaller));
        @available = grep { $_ != $value } @available;
    }
    return $rank;
}
sub oracle_count ($n, $k) {
    my $value = Math::BigInt->bone;
    $value->bmul($_) for reverse($n - $k + 1 .. $n);
    return $value;
}

my ($enumerated, $families) = (0, 0);
for my $n (1 .. 7) {
    for my $k (1 .. $n) {
        my $reference = enumerate($n,$k);
        my $family = distinct_name_family($n,$k);
        is(''.$family->{count}->(), ''.scalar(@$reference), "遞迴枚舉計數 n=$n k=$k");
        is(''.$family->{count}->(), ''.oracle_count($n,$k), '獨立連乘計數');
        for my $i (0 .. $#$reference) {
            is_deeply($family->{unrank1}->($i + 1), $reference->[$i], '逐排名詞典序比較');
            ++$enumerated;
        }
        ++$families;
    }
}

my $large_cases = 0;
for my $case ([17,6], [17,17], [47,3], [47,47]) {
    my ($n,$k) = @$case;
    my $family = distinct_name_family($n,$k);
    my $total = oracle_count($n,$k);
    is(''.$family->{count}->(), "$total", '大型排列計數直接連乘');
    my @ranks = (Math::BigInt->bone, Math::BigInt->new(2),
                 $total->copy->bdiv(2)->badd(1),
                 $total->copy->bdec, $total->copy);
    for my $rank (@ranks) {
        my $before = "$rank";
        my $sequence = $family->{unrank1}->($rank);
        is(scalar(@$sequence),$k,'序列長度精確');
        my %uniq;
        ok(!grep({ $_ < 1 || $_ > $n || $uniq{$_}++ } @$sequence), '所有名稱索引合法且互異');
        is(''.oracle_rank($n,$k,$sequence), $before, '獨立逆向排名驗證');
        is("$rank",$before,'輸入排名 BigInt 未更改');
        ++$large_cases;
    }
    ok(!eval { $family->{unrank1}->($total->copy->badd(1)); 1 },'超出排列總數即拒絕');
    my $copy = $family->{count}->();
    $copy->badd(1000);
    is(''.$family->{count}->(), "$total",'count 每次新建 BigInt');
    my $first = $family->{unrank1}->(1);
    $first->[0] = -1;
    is_deeply($family->{unrank1}->(1),[1 .. $k],'輸出陣列跨呼叫獨立');
}

for my $bad ([undef,1], [1,undef], [0,1], [1,0], [48,1], [1,2],
             ['01',1], [1,'01'], ['1.0',1], [1,'1.0'], [-1,1], [1,-1],
             ['NaN',1], ['abc',1], [[],1], [{},1], [1,[]], [1,{}],
             ['',1], [1,''], [' 1',1], [1,'1 ']) {
    ok(!eval { distinct_name_family(@$bad); 1 },'拒絕無效輸入');
}
my $stable = distinct_name_family(7,3);
for my $bad (undef, 0, '00', '01', '-1', '1.0', 'NaN', '', ' 1', '1 ', [], {},
             Math::BigInt->bzero, Math::BigInt->new(211)) {
    ok(!eval { $stable->{unrank1}->($bad); 1 },'拒絕無效排名');
}
my $n_b = Math::BigInt->new(47);
my $k_b = Math::BigInt->new(17);
my $f = distinct_name_family($n_b,$k_b);
is(''.$f->{count}->(), ''.oracle_count(47,17),'接受 BigInt 家族參數');
is("$n_b",'47','未變更目錄大小 BigInt');
is("$k_b",'17','未變更選取數 BigInt');
ok(ref($f) eq 'HASH' && join(',', sort keys %$f) eq 'count,unrank1', 'API 僅包含兩個操作');
note("STAGE10_INDEPENDENT_ENUMERATED=$enumerated");
note("STAGE10_INDEPENDENT_FAMILIES=$families");
note("STAGE10_LARGE_RANK_CASES=$large_cases");
note('STAGE10_FULL_GENERATOR_NOT_VERIFIED');
done_testing;
