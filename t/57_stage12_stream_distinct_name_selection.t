use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib';
use Pastafari::Monster::StreamDistinctNameSelection qw(select_distinct_name_indices);

my $M = Math::BigInt->new(2)->bpow(127)->bdec;

# Oracle A: enumerate sequences directly by depth-first traversal. No rank
# unranking routine from either production dependency is used for expectations.
sub enumerate ($n, $k) {
    my (@items, @path, %taken);
    my $descend;
    $descend = sub {
        if (@path == $k) {
            push @items, [@path];
            return;
        }
        for my $candidate (1 .. $n) {
            next if $taken{$candidate};
            $taken{$candidate} = 1;
            push @path, $candidate;
            $descend->();
            pop @path;
            delete $taken{$candidate};
        }
    };
    $descend->();
    return \@items;
}

# Oracle B: rank a completed sequence by counting the lexicographically
# preceding unused choices; this is reverse validation, not unranking.
sub inverse_rank ($n, $k, $values) {
    my @unused = 1 .. $n;
    my $rank = Math::BigInt->bone;
    for my $i (0 .. $k - 1) {
        my $target = $values->[$i];
        my $prior = grep { $_ < $target } @unused;
        my $suffix_count = Math::BigInt->bone;
        for my $j (0 .. $k - $i - 2) {
            $suffix_count->bmul($n - $i - 1 - $j);
        }
        $rank->badd($suffix_count->bmul($prior));
        @unused = grep { $_ != $target } @unused;
    }
    return $rank;
}

# Oracle C: direct independent stream calculation, never invoking Stage11
# producer helpers. For the permitted 47! maximum, at most two M digits suffice.
sub stream_rank_expected ($first, $dir, $total) {
    my $f = Math::BigInt->new("$first");
    my $size = Math::BigInt->new("$total");
    my $space = $M->copy;
    my $sample = Math::BigInt->bone;
    my $power = Math::BigInt->bone;
    my $step_no = 0;
    while (1) {
        my $digit = $f->copy->bsub(1)->badd($dir * $step_no)->bmod($M);
        $sample->badd($digit->bmul($power));
        last if $space >= $size;
        $space->bmul($M);
        $power->bmul($M);
        ++$step_no;
    }
    my $accept = $space->copy->bdiv($size)->bmul($size);
    # Direct closed boundary deduction: the accepted interval is [1, accept].
    if ($sample > $accept) {
        $sample = $dir > 0 ? Math::BigInt->bone : $accept->copy;
    }
    my $remainder = $sample->copy->bsub(1);
    $remainder->bsub($remainder->copy->bdiv($size)->bmul($size));
    return $remainder->binc;
}

sub product_count ($n,$k) {
    my $total = Math::BigInt->bone;
    $total->bmul($_) for ($n - $k + 1 .. $n);
    return $total;
}

my ($enumerated, $families) = (0,0);
for my $n (1 .. 6) {
    for my $k (1 .. $n) {
        my $expected = enumerate($n,$k);
        is(scalar(@$expected), ''.product_count($n,$k), '獨立枚舉數量');
        for my $i (0 .. $#$expected) {
            # first=i+1 falls inside the acceptance interval: no rejection.
            for my $direction (-1,1) {
                is_deeply(select_distinct_name_indices($i+1,$direction,$n,$k),$expected->[$i],
                    '逐一列舉的低位串流→排名→名稱整合');
                ++$enumerated;
            }
        }
        ++$families;
    }
}

my $boundary_cases = 0;
for my $case ([2,1],[4,2],[7,3],[17,17],[47,3],[47,47]) {
    my ($n,$k) = @$case;
    my $total = product_count($n,$k);
    for my $first (1,2,$M->copy->bdec,$M->copy) {
        for my $direction (-1,1) {
            my $original_first = "$first";
            my $original_total = "$total";
            my $out = select_distinct_name_indices($first,$direction,$n,$k);
            is(scalar(@$out),$k,'輸出長度');
            my %seen;
            ok(!grep({ $_ < 1 || $_ > $n || $seen{$_}++ } @$out),'索引合法且互異');
            my $expected_rank = stream_rank_expected($first,$direction,$total);
            is(''.inverse_rank($n,$k,$out),"$expected_rank",'獨立反向排名與串流對照');
            is("$first",$original_first,'輸入首值不變');
            is("$total",$original_total,'獨立計數不變');
            ++$boundary_cases;
        }
    }
}

is_deeply(select_distinct_name_indices($M,1,2,1),[1],'+1 溢出後環繞到第一名');
is_deeply(select_distinct_name_indices($M,-1,2,1),[2],'-1 溢出後落在最後接受值');
my $original = select_distinct_name_indices(3,1,7,3);
my $expected_again = select_distinct_name_indices(3,1,7,3);
$original->[0] = -99;
is_deeply(select_distinct_name_indices(3,1,7,3),$expected_again,'輸出陣列非共享快取');

my $bf = Math::BigInt->new(5);
my $bn = Math::BigInt->new(47);
my $bk = Math::BigInt->new(47);
my $out = select_distinct_name_indices($bf,Math::BigInt->new(-1),$bn,$bk);
is(scalar(@$out),47,'BigInt 引數被接受');
is("$bf",'5','首值 BigInt 不變');
is("$bn",'47','目錄 BigInt 不變');
is("$bk",'47','選取數 BigInt 不變');

my $bad_cases = 0;
for my $case ([undef,1,3,2],[0,1,3,2],['01',1,3,2],[$M->copy->binc,1,3,2],
              [1,0,3,2],[1,2,3,2],[1,'01',3,2],[1,1,0,1],
              [1,1,48,1],[1,1,3,0],[1,1,2,3],
              [1,1,[],2],[1,1,3,{}],[1,1,3,'1.0']) {
    ok(!eval { select_distinct_name_indices(@$case); 1 },'拒絕無效輸入');
    ++$bad_cases;
}

note("STAGE12_INDEPENDENT_ENUMERATED=$enumerated");
note("STAGE12_INDEPENDENT_FAMILIES=$families");
note("STAGE12_INDEPENDENT_BOUNDARIES=$boundary_cases");
note("STAGE12_INVALID_CASES=$bad_cases");
note('STAGE12_FULL_GENERATOR_NOT_VERIFIED');
done_testing;
