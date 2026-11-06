package Pastafari::Monster::CanonicalFiveFieldProjection;
use v5.40;
use utf8;
use strict;
use warnings;
use Exporter 'import';
use Scalar::Util qw(blessed);
use Math::BigInt;
use Pastafari::SourceLanguageCatalog qw(source_language catalog_version cutlet_entries month_entries);
use Pastafari::Monster::CanonicalNameSelection qw(select_canonical_names);
use Pastafari::Monster::FiveFieldProjection qw(five_field_projection);

our @EXPORT_OK = qw(project_with_canonical_names);

# Join accepted Stage07 and Stage14 only. No gates, layout or stream generated here.
sub _catalog_index ($kind, $expected_size) {
    die "正式目錄語言或版本無效\n"
        unless source_language() eq '繁體中文（國語）'
            && catalog_version() eq '1.0.0-stage1-frozen';
    my $entries = $kind eq 'cutlet' ? cutlet_entries() : month_entries();
    die "正式目錄長度無效\n" if ref($entries) ne 'ARRAY' || @$entries != $expected_size;
    my %by_text;
    for my $i (0 .. $#$entries) {
        my $e = $entries->[$i];
        die "正式目錄條目無效\n" if ref($e) ne 'HASH';
        my ($index, $name) = @{$e}{qw(canonicalIndex source)};
        die "正式目錄索引無效\n" if !defined($index) || ref($index)
            || "$index" ne '' . ($i + 1);
        die "正式目錄名稱無效\n" if !defined($name) || ref($name)
            || $name !~ /\S/u || $name =~ /\A\s|\s\z/u
            || exists $by_text{$name};
        $by_text{$name} = $i + 1;
    }
    return \%by_text;
}

sub _copy_scalar ($value) {
    die "年份基底陣列含有不合法參照\n"
        if ref($value) && !(blessed($value) && $value->isa('Math::BigInt'));
    return blessed($value) ? $value->copy : $value;
}

sub _indices_from_names ($kind, $first, $step, $count, $lookup) {
    my $selected = select_canonical_names($kind, $first, $step, $count);
    die "正式名稱選取數量錯誤\n" if ref($selected) ne 'ARRAY' || @$selected != $count;
    my (%used, @indices);
    for my $name (@$selected) {
        die "非正式或重複名稱\n" if !defined($name) || ref($name)
            || !exists $lookup->{$name} || $used{$name}++;
        push @indices, $lookup->{$name};
    }
    return \@indices;
}

sub project_with_canonical_names (
    $year, $base_structure, $target_day,
    $cutlet_first, $cutlet_step, $month_first, $month_step
) {
    die "年份基底結構須為雜湊\n" if ref($base_structure) ne 'HASH';
    my @keys = sort keys %$base_structure;
    die "年份基底結構只能含三個陣列\n"
        if join(',', @keys) ne 'cutletPartition,monthLengths,monthWeaving';
    for my $key (@keys) {
        die "年份基底陣列無效：$key\n" if ref($base_structure->{$key}) ne 'ARRAY';
    }
    my $cutlet_count = @{$base_structure->{cutletPartition}};
    my $month_count = @{$base_structure->{monthLengths}};
    die "肉排數量無效\n" if $cutlet_count < 6 || $cutlet_count > 17;
    die "月份數量無效\n" if $month_count < 3 || $month_count > 47;

    my $cutlet_index = _catalog_index('cutlet', 17);
    my $month_index = _catalog_index('month', 47);
    my $cutlet_names = _indices_from_names('cutlet', $cutlet_first, $cutlet_step,
                                           $cutlet_count, $cutlet_index);
    my $month_names = _indices_from_names('month', $month_first, $month_step,
                                          $month_count, $month_index);
    my %structure = map {
        $_ => [map { _copy_scalar($_) } @{$base_structure->{$_}}]
    } @keys;
    $structure{cutletNames} = $cutlet_names;
    $structure{monthNames} = $month_names;
    my $result = five_field_projection($year, \%structure, $target_day);
    die "五欄投影結果無效\n" if ref($result) ne 'ARRAY' || @$result != 5;
    return [ $result->[0]->copy, "$result->[1]", $result->[2]->copy,
             "$result->[3]", $result->[4]->copy ];
}

1;
