use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use lib 'lib';
use Pastafari::SourceLanguageCatalog qw(
    source_language catalog_version cutlet_entries month_entries
    cutlet_name_by_index month_name_by_index
);

my $cutlets = cutlet_entries();
my $months = month_entries();

is(source_language(), '繁體中文（國語）', '來源語言固定為繁體中文國語');
is(catalog_version(), '1.0.0-stage1-frozen', '來源語言目錄版本已凍結');
is(scalar @$cutlets, 17, '共有十七個肉排名稱');
is(scalar @$months, 47, '共有四十七個月份名稱');
is_deeply([map { $_->{canonicalIndex} } @$cutlets], [1..17], '肉排名稱索引完整且連續');
is_deeply([map { $_->{canonicalIndex} } @$months], [1..47], '月份名稱索引完整且連續');

my %cutlet_seen;
$cutlet_seen{$_->{source}}++ for @$cutlets;
is(scalar(keys %cutlet_seen),17,'肉排名稱沒有重複顯示字串');
my %month_seen;
$month_seen{$_->{source}}++ for @$months;
is(scalar(keys %month_seen),47,'月份名稱沒有重複顯示字串');

is(cutlet_name_by_index(6),'九分之四','完整分數肉排名稱按語意翻譯');
is(cutlet_name_by_index(12),'小麥','小麥名稱使用語意翻譯');
is(cutlet_name_by_index(15),'阿卡德','阿卡德使用固定地名轉寫');
is(month_name_by_index(7),'五分之三','完整分數月份名稱按語意翻譯');
is(month_name_by_index(41),'巴比倫','巴比倫使用固定地名名稱');
is(month_name_by_index(47),'沙','最後一個月份名稱保留固定規範索引');

my $copy = cutlet_entries();
$copy->[0]{source} = '已修改';
is(cutlet_name_by_index(1),'青銅','外部修改副本不會改變凍結目錄');

done_testing;
