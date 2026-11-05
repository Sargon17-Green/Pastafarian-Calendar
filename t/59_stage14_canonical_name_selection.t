use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib';
use Pastafari::SourceLanguageCatalog qw(source_language catalog_version);
use Pastafari::Monster::CanonicalNameSelection qw(select_canonical_names);

# Two complete frozen-language anchors; expected names never come from
# the production catalog accessor.
my @cutlet_names = qw(青銅 狐狸 腎臟 拉加什 思想 九份中的四份 帕爾古拉什 莎草 簇 蠍子 灰燼 小麥 河流 笑聲 阿卡德 角 空陶罐);
my @month_names = qw(黏土 石榴 手肘 嫉妒 埃里都 牙膏 五份中的三份 卡爾舒馬夫 花豹 錫 霧 乳香 紡錘 肋骨 角豆 烏魯克 羞恥 駱駝 銅 井 蛋黃 星星 蜂蜜 脾臟 石灰岩 喜悅 無花果 尼尼微 青蛙 瀝青 燈 關上的門 芝麻 後頸 銀 蘇薩 暴風雨 驢子 麵粉 後悔 巴比倫 舌頭 亞麻 鹽 梨 弓 沙);
my @cutlet_frozen = @cutlet_names;
my @month_frozen  = @month_names;
my $M = Math::BigInt->new(2)->bpow(127)->bdec;

sub count_choices ($n, $k) {
    my $v = Math::BigInt->bone;
    $v->bmul($n - $_) for 0 .. $k - 1;
    return $v;
}

# Compute the stream rank independently using its zero-based radix digits.
sub oracle_rank_from_stream ($first, $step, $count) {
    my $word0 = Math::BigInt->bzero;
    my $radix = Math::BigInt->bone;
    my $space = Math::BigInt->bone;
    for (my $j = 0; $space < $count; ++$j) {
        my $digit = Math::BigInt->new("$first")->bdec->badd($step * $j)->bmod($M);
        $word0->badd($digit->bmul($radix));
        $radix->bmul($M);
        $space->bmul($M);
    }
    my $accepted = $space->copy->bdiv($count)->bmul($count);
    if ($word0 >= $accepted) {
        $word0 = $step == 1 ? Math::BigInt->bzero : $accepted->copy->bdec;
    }
    return $word0->bmod($count)->binc;
}

# Recover lexicographic rank from the *text* returned, not production indices.
sub oracle_rank_from_names ($catalog, $observed) {
    my @pool = @$catalog;
    my $rank = Math::BigInt->bone;
    for my $position (0 .. $#$observed) {
        my $location;
        for my $candidate (0 .. $#pool) {
            if ($pool[$candidate] eq $observed->[$position]) {
                $location = $candidate;
                last;
            }
        }
        die "獨立名稱排名失敗\n" if !defined($location);
        my $block = Math::BigInt->bone;
        $block->bmul(@pool - $_) for 1 .. (@$observed - $position - 1);
        $rank->badd($block->bmul($location));
        splice @pool, $location, 1;
    }
    return $rank;
}

is(source_language(), '繁體中文（國語）', '來源語言鎖定');
is(catalog_version(), '1.0.0-stage1-frozen', '目錄版本鎖定');
is_deeply(select_canonical_names('cutlet', 1, 1, 17), \@cutlet_names, '肉排全目錄固定錨點');
is_deeply(select_canonical_names('month', 1, 1, 3), [@month_names[0 .. 2]], '月份第一排名固定錨點');
my @second_cutlets = @cutlet_names;
@second_cutlets[15,16] = @second_cutlets[16,15];
is_deeply(select_canonical_names('cutlet', 2, 1, 17), \@second_cutlets, '肉排第二排名固定錨點');
is_deeply(select_canonical_names('month', 2, 1, 3), [@month_names[0,1,3]], '月份第二排名固定錨點');

my $boundaries = 0;
for my $spec (
    ['cutlet', 6], ['cutlet', 7], ['cutlet', 11], ['cutlet', 17],
    ['month', 3], ['month', 6], ['month', 17], ['month', 47],
) {
    my ($kind, $k) = @$spec;
    my $catalog = $kind eq 'cutlet' ? \@cutlet_names : \@month_names;
    my %allowed = map { $_ => 1 } @$catalog;
    my $count = count_choices(scalar(@$catalog), $k);
    for my $first (1, 2, $M->copy->bdec, $M->copy) {
        for my $step (-1, 1) {
            my $observed = select_canonical_names($kind, $first, $step, $k);
            is(scalar(@$observed), $k, '精確輸出長度');
            is(scalar(grep { $allowed{$_} } @$observed), $k, '僅正式目錄名稱');
            my %seen;
            is(scalar(grep { !$seen{$_}++ } @$observed), $k, '無重複名稱');
            is('' . oracle_rank_from_names($catalog, $observed),
               '' . oracle_rank_from_stream($first, $step, $count),
               '獨立大整數流排名等於文字逆排名');
            ++$boundaries;
        }
    }
}

my $first_result = select_canonical_names('month', 1, 1, 3);
my $other_result = select_canonical_names('month', 1, 1, 3);
$first_result->[0] = '覆寫';
is_deeply($other_result, [@month_names[0..2]], '跨呼叫輸出獨立');
is_deeply(select_canonical_names('month', 1, 1, 3), [@month_names[0..2]], '結果與封存目錄不共用');
my $first_big = Math::BigInt->new(2);
my $size_big = Math::BigInt->new(6);
select_canonical_names('cutlet', $first_big, Math::BigInt->new(-1), $size_big);
is("$first_big", '2', '第一取樣值不變');
is("$size_big", '6', '選取數量不變');
is_deeply(\@cutlet_names, \@cutlet_frozen, '肉排期望資料未變');
is_deeply(\@month_names, \@month_frozen, '月份期望資料未變');

my @invalid = (
    [undef,1,1,6], ['Cutlet',1,1,6], ['month ',1,1,3], [[],1,1,6], ['day',1,1,6],
    ['cutlet',1,1,5], ['cutlet',1,1,18], ['month',1,1,2], ['month',1,1,48],
    ['month',0,1,3], ['month','01',1,3], ['month',1,0,3], ['month',1,2,3],
    ['cutlet',1,1,'06'], ['month',1,1,'3.0'], ['month',1,1,undef], ['month',1,1,[]],
);
my $invalid_cases = 0;
for my $input (@invalid) {
    ok(!eval { select_canonical_names(@$input); 1 }, '非法輸入確定拒絕');
    ++$invalid_cases;
}

note("STAGE14_FROZEN_CUTLET_NAMES=17");
note("STAGE14_FROZEN_MONTH_NAMES=47");
note("STAGE14_INDEPENDENT_BOUNDARIES=$boundaries");
note("STAGE14_INVALID_CASES=$invalid_cases");
note('STAGE14_FULL_GENERATOR_NOT_VERIFIED');
done_testing;
