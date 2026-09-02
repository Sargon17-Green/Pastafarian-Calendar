package Pastafari::SourceLanguageCatalog;
use v5.40;
use utf8;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(
    source_language catalog_version cutlet_entries month_entries
    cutlet_name_by_index month_name_by_index
);

my $SOURCE_LANGUAGE = '繁體中文（國語）';
my $CATALOG_VERSION = '1.0.0-stage1-frozen';

my @CUTLETS = (
    { canonicalIndex => 1,  source => '青銅' },
    { canonicalIndex => 2,  source => '狐狸' },
    { canonicalIndex => 3,  source => '腎臟' },
    { canonicalIndex => 4,  source => '拉加什' },
    { canonicalIndex => 5,  source => '思想' },
    { canonicalIndex => 6,  source => '九分之四' },
    { canonicalIndex => 7,  source => '帕爾古拉什' },
    { canonicalIndex => 8,  source => '紙莎草' },
    { canonicalIndex => 9,  source => '葡萄串' },
    { canonicalIndex => 10, source => '蠍子' },
    { canonicalIndex => 11, source => '灰燼' },
    { canonicalIndex => 12, source => '小麥' },
    { canonicalIndex => 13, source => '河流' },
    { canonicalIndex => 14, source => '笑聲' },
    { canonicalIndex => 15, source => '阿卡德' },
    { canonicalIndex => 16, source => '角' },
    { canonicalIndex => 17, source => '空陶罐' },
);

my @MONTHS = (
    { canonicalIndex => 1,  source => '黏土' },
    { canonicalIndex => 2,  source => '石榴' },
    { canonicalIndex => 3,  source => '手肘' },
    { canonicalIndex => 4,  source => '嫉妒' },
    { canonicalIndex => 5,  source => '埃里都' },
    { canonicalIndex => 6,  source => '牙膏' },
    { canonicalIndex => 7,  source => '五分之三' },
    { canonicalIndex => 8,  source => '卡爾舒馬布' },
    { canonicalIndex => 9,  source => '花豹' },
    { canonicalIndex => 10, source => '錫' },
    { canonicalIndex => 11, source => '霧' },
    { canonicalIndex => 12, source => '乳香' },
    { canonicalIndex => 13, source => '紡錘' },
    { canonicalIndex => 14, source => '肋骨' },
    { canonicalIndex => 15, source => '角豆' },
    { canonicalIndex => 16, source => '烏魯克' },
    { canonicalIndex => 17, source => '羞恥' },
    { canonicalIndex => 18, source => '駱駝' },
    { canonicalIndex => 19, source => '銅' },
    { canonicalIndex => 20, source => '井' },
    { canonicalIndex => 21, source => '蛋黃' },
    { canonicalIndex => 22, source => '星星' },
    { canonicalIndex => 23, source => '蜂蜜' },
    { canonicalIndex => 24, source => '脾臟' },
    { canonicalIndex => 25, source => '石灰岩' },
    { canonicalIndex => 26, source => '喜悅' },
    { canonicalIndex => 27, source => '無花果' },
    { canonicalIndex => 28, source => '尼尼微' },
    { canonicalIndex => 29, source => '青蛙' },
    { canonicalIndex => 30, source => '瀝青' },
    { canonicalIndex => 31, source => '蠟燭' },
    { canonicalIndex => 32, source => '關上的門' },
    { canonicalIndex => 33, source => '芝麻' },
    { canonicalIndex => 34, source => '後頸' },
    { canonicalIndex => 35, source => '銀' },
    { canonicalIndex => 36, source => '百合' },
    { canonicalIndex => 37, source => '暴風雨' },
    { canonicalIndex => 38, source => '驢子' },
    { canonicalIndex => 39, source => '麵粉' },
    { canonicalIndex => 40, source => '後悔' },
    { canonicalIndex => 41, source => '巴比倫' },
    { canonicalIndex => 42, source => '舌頭' },
    { canonicalIndex => 43, source => '亞麻' },
    { canonicalIndex => 44, source => '鹽' },
    { canonicalIndex => 45, source => '梨' },
    { canonicalIndex => 46, source => '弓' },
    { canonicalIndex => 47, source => '沙' },
);

sub source_language { return $SOURCE_LANGUAGE }
sub catalog_version { return $CATALOG_VERSION }

sub _copy_entries ($entries) {
    return [ map { +{ %$_ } } @$entries ];
}

sub cutlet_entries { return _copy_entries(\@CUTLETS) }
sub month_entries  { return _copy_entries(\@MONTHS) }

sub cutlet_name_by_index ($index) {
    die "肉排名稱索引超出範圍\n" if $index < 1 || $index > scalar @CUTLETS;
    return $CUTLETS[$index - 1]{source};
}

sub month_name_by_index ($index) {
    die "月份名稱索引超出範圍\n" if $index < 1 || $index > scalar @MONTHS;
    return $MONTHS[$index - 1]{source};
}

1;
