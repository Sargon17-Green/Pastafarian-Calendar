use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib';
use Pastafari::SourceLanguageCatalog qw(
    cutlet_entries month_entries cutlet_name_by_index month_name_by_index
);

my @families = (
    {
        label => '肉排',
        entries => cutlet_entries(),
        lookup => \&cutlet_name_by_index,
        count => 17,
        error => qr/肉排名稱索引超出範圍/,
    },
    {
        label => '月份',
        entries => month_entries(),
        lookup => \&month_name_by_index,
        count => 47,
        error => qr/月份名稱索引超出範圍/,
    },
);

for my $group (@families) {
    my ($label, $entries, $lookup, $count, $error) =
        @$group{qw(label entries lookup count error)};
    is(scalar @$entries, $count, "$label 的索引數量固定");
    for my $index (1 .. $count) {
        is($entries->[$index - 1]{canonicalIndex}, $index,
           "$label 索引 $index 的規範次序不變");
        is($lookup->($index), $entries->[$index - 1]{source},
           "$label 索引 $index 與顯示值一致");
    }
    for my $index ("0001", "0$count", Math::BigInt->new($count)) {
        my $expected = "$index";
        $expected =~ s/\A0+//;
        $expected = 0 + $expected;
        is($lookup->($index), $entries->[$expected - 1]{source},
            "$label 支援前導零與合法的大整數物件");
    }

    my @invalid = (
        undef, '', ' ', 0, '0000', '-1', "+1", '1.0', '1e0',
        ' 1', "1\n", 'NaN', 'Infinity', '１', [], {}, 
        $count + 1, '0'.($count+1),
        Math::BigInt->new(-1),
        Math::BigInt->new($count+1),
        Math::BigInt->new('9' x 320),
        '9' x 320
    );
    for my $case (@invalid) {
        my $ok = eval { $lookup->($case); 1 };
        my $err = $@;
        ok(!$ok, "$label 無效索引會被拒絕");
        like($err, $error, "$label 無效索引有一致的診斷");
    }

    my $copy1 = $label eq '肉排' ? cutlet_entries() : month_entries();
    my $copy2 = $label eq '肉排' ? cutlet_entries() : month_entries();
    $copy1->[0]{source} = '內容被修改';
    $copy1->[0]{canonicalIndex} = -5;
    is($copy2->[0]{source}, $entries->[0]{source}, "$label 回傳的名稱不共用可變雜湊");
    is($copy2->[0]{canonicalIndex}, 1, "$label 回傳的規範索引不共用可變雜湊");
    is($lookup->(1), $entries->[0]{source}, "$label 外部修改不會汙染權威目錄");
}

done_testing;
