package Pastafari::Monster::DistinctNameAssignment;
use v5.40;
use utf8;
use strict;
use warnings;
use Exporter 'import';
use Math::BigInt;
use Scalar::Util qw(blessed);

our @EXPORT_OK = qw(distinct_name_family);

# 名稱索引只接受無前導零的正整數；不可修改呼叫端的 BigInt。
sub _positive ($value, $limit, $message) {
    die "$message\n" if !defined($value)
        || (ref($value) && !(blessed($value) && $value->isa('Math::BigInt')));
    my $digits = "$value";
    die "$message\n" if $digits !~ /\A[1-9][0-9]*\z/
        || length($digits) > length("$limit")
        || (length($digits) == length("$limit") && $digits gt "$limit");
    return 0 + $digits;
}

sub distinct_name_family ($catalog_size, $selected_count) {
    my $n = _positive($catalog_size, 47, '名稱目錄大小無效');
    my $k = _positive($selected_count, 47, '選取名稱數無效');
    die "選取名稱數超過目錄大小\n" if $k > $n;

    # P(n,k) = n (n-1) ... (n-k+1)，無外部快取或規範 oracle。
    my $total = Math::BigInt->bone;
    for my $offset (0 .. $k - 1) {
        $total->bmul($n - $offset);
    }

    my $unrank1 = sub ($rank_value) {
        die "名稱序列排名無效\n" if !defined($rank_value)
            || (ref($rank_value) && !(blessed($rank_value) && $rank_value->isa('Math::BigInt')));
        my $digits = "$rank_value";
        die "名稱序列排名無效\n" if $digits !~ /\A[1-9][0-9]*\z/;
        my $q = Math::BigInt->new($digits);
        die "名稱序列排名超出範圍\n" if $q->bcmp($total) > 0;
        $q->bdec;

        my @available = (1 .. $n);
        my @chosen;
        # B_0 = P(n-1,k-1); each later block divides by remaining candidates.
        my $block = $total->copy->bdiv($n);
        for my $i (0 .. $k - 1) {
            my $index = $q->copy->bdiv($block)->numify;
            die "名稱序列內部索引錯誤\n" if $index >= @available;
            push @chosen, splice(@available, $index, 1);
            $q = $q->copy->bmod($block);
            $block->bdiv($n - $i - 1) if $i < $k - 1;
        }
        return \@chosen;
    };
    return { count => sub { $total->copy }, unrank1 => $unrank1 };
}

1;
