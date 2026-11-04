use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib';
use Pastafari::Monster::StreamDistinctNameMaterialization qw(select_distinct_names);

my $M = Math::BigInt->new(2)->bpow(127)->bdec;

# Oracle A enumerates each ordered, nonrepeating index tuple by DFS.
# It never uses the production name-index selection, rank or unrank methods.
sub enumerate_indices ($size, $length) {
    my (@all, @prefix, %used);
    my $walk;
    $walk = sub {
        if (@prefix == $length) {
            push @all, [@prefix];
            return;
        }
        for my $index (1 .. $size) {
            next if $used{$index};
            $used{$index} = 1;
            push @prefix, $index;
            $walk->();
            pop @prefix;
            delete $used{$index};
        }
    };
    $walk->();
    return \@all;
}

# Oracle B reads the returned labels and independently calculates their
# lexicographic one-based rank from the ordered remaining label pool.
sub labels_to_rank ($catalog, $names) {
    my @pool = @$catalog;
    my $rank = Math::BigInt->bone;
    for my $position (0 .. $#$names) {
        my $place;
        for my $j (0 .. $#pool) {
            if ($pool[$j] eq $names->[$position]) {
                $place = $j;
                last;
            }
        }
        die "獨立反向排名找不到名稱\n" if !defined($place);
        my $suffix = Math::BigInt->bone;
        for my $j (0 .. scalar(@$names) - $position - 2) {
            $suffix->bmul(@pool - 1 - $j);
        }
        $rank->badd($suffix->bmul($place));
        splice @pool, $place, 1;
    }
    return $rank;
}

# Independently interpret the one-based 127-bit stream word, including
# a second word digit when N exceeds the one-digit modulus, and rejection.
sub stream_rank ($first, $direction, $count) {
    my $N = Math::BigInt->new("$count");
    my $base = Math::BigInt->bone;
    my $space = $M->copy;
    my $word = Math::BigInt->bone;
    my $digit_index = 0;
    while (1) {
        my $digit = Math::BigInt->new("$first")->bdec->badd($direction * $digit_index)->bmod($M);
        $word->badd($digit->bmul($base));
        last if $space >= $N;
        $space->bmul($M);
        $base->bmul($M);
        ++$digit_index;
    }
    my $accepted = $space->copy->bdiv($N)->bmul($N);
    $word = $direction == 1 ? Math::BigInt->bone : $accepted->copy if $word > $accepted;
    return $word->bdec->bmod($N)->binc;
}

sub count_sequences ($n,$k) {
    my $count = Math::BigInt->bone;
    $count->bmul($n - $_) for 0 .. $k - 1;
    return $count;
}

my ($enumerated, $families, $boundary_cases, $invalid_cases) = (0,0,0,0);
for my $n (1 .. 6) {
    my @catalog = map { "章節名$_" } 1 .. $n;
    for my $k (1 .. $n) {
        my $expected = enumerate_indices($n,$k);
        is(scalar(@$expected), '' . count_sequences($n,$k), 'DFS 全量數量');
        for my $i (0 .. $#$expected) {
            my @names = map { $catalog[$_ - 1] } @{$expected->[$i]};
            for my $direction (-1,1) {
                is_deeply(select_distinct_names($i+1,$direction,\@catalog,$k),\@names,
                    '獨立 DFS 排名和實際名稱映射一致');
                ++$enumerated;
            }
        }
        ++$families;
    }
}

for my $pair ([1,1],[2,2],[5,3],[17,17],[47,47]) {
    my ($n,$k) = @$pair;
    my @catalog = map { "條目_$_" } 1 .. $n;
    my $count = count_sequences($n,$k);
    for my $first (1,2,$M->copy->bdec,$M->copy) {
        for my $dir (-1,1) {
            my $before_first = "$first";
            my @original = @catalog;
            my $names = select_distinct_names($first,$dir,\@catalog,$k);
            is(scalar(@$names),$k,'輸出長度');
            my %unique;
            ok(!grep({ $unique{$_}++ } @$names),'互異名稱');
            is('' . labels_to_rank(\@catalog,$names),'' . stream_rank($first,$dir,$count),
                'BigInt 獨立串流排名與反向排列排名相等');
            is_deeply(\@catalog,\@original,'目錄未變更');
            is("$first",$before_first,'首值未變更');
            ++$boundary_cases;
        }
    }
}

my @sample = ('甲','乙','丙','丁');
my $first_result = select_distinct_names(3,1,\@sample,2);
my $comparison = select_distinct_names(3,1,\@sample,2);
$first_result->[0] = '被覆寫';
is_deeply(select_distinct_names(3,1,\@sample,2),$comparison,'回傳陣列不共用');
is_deeply(\@sample,['甲','乙','丙','丁'],'修改輸出不改變原始目錄');
my $big_first = Math::BigInt->new(5);
my $big_count = Math::BigInt->new(4);
is_deeply(select_distinct_names($big_first,Math::BigInt->new(-1),\@sample,$big_count),
          select_distinct_names(5,-1,\@sample,4),'BigInt 首值、方向、數量合法');
is("$big_first",'5','BigInt 首值未變更');
is("$big_count",'4','BigInt 數量未變更');

for my $case (
    [1,1,undef,1], [1,1,'名錄',1], [1,1,{},1], [1,1,[],1],
    [1,1,[('甲') x 48],1], [1,1,['甲',undef],1],
    [1,1,['甲','甲'],1], [1,1,['甲',''],1],
    [1,1,['甲','  '],1], [1,1,['甲',[]],1],
    [0,1,['甲'],1], ['01',1,['甲'],1],
    [1,0,['甲'],1], [1,2,['甲'],1],
    [1,1,['甲'],0], [1,1,['甲'],2], [1,1,['甲'],'01'],
) {
    ok(!eval { select_distinct_names(@$case); 1 },'拒絕無效目錄或串流參數');
    ++$invalid_cases;
}

note("STAGE13_INDEPENDENT_ENUMERATED=$enumerated");
note("STAGE13_INDEPENDENT_FAMILIES=$families");
note("STAGE13_INDEPENDENT_BOUNDARIES=$boundary_cases");
note("STAGE13_INVALID_CASES=$invalid_cases");
note('STAGE13_CANONICAL_CATALOG_NOT_VERIFIED');
note('STAGE13_FULL_GENERATOR_NOT_VERIFIED');
done_testing;
