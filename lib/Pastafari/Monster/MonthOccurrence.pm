package Pastafari::Monster::MonthOccurrence;
use v5.40;
use utf8;
use strict;
use warnings;
use Exporter 'import';
use Scalar::Util qw(blessed);
use Math::BigInt;
use Pastafari::Monster::WeavingPrimitive qw(unrank_weaving);

our @EXPORT_OK = qw(month_occurrence);

# 第四階段只投影規範第四、第五欄的月份索引和月內日數。
# 日期年份、肉排邊界、月份名稱及完整年曆不由此原語計算。
sub month_occurrence ($lengths, $rank, $position) {
    # 先由已驗收的有界交織原語檢查配置及排名，不共用可變快取。
    my $word = unrank_weaving($lengths, $rank);
    die "日期位置須為一基正整數\n" if !defined($position)
        || (ref($position) && !(blessed($position) && $position->isa('Math::BigInt')))
        || "$position" !~ /\A[1-9][0-9]*\z/;
    my $p = Math::BigInt->new("$position");
    die "日期位置超出交織序列\n" if $p > scalar(@$word);
    my $i = $p->numify - 1;
    my $month = $word->[$i];
    my $occurrence = 0;
    for my $j (0 .. $i) {
        ++$occurrence if $word->[$j] == $month;
    }
    return {
        monthIndex => $month,
        dayInMonth => Math::BigInt->new($occurrence),
    };
}

1;
