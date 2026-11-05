package Pastafari::Monster::CanonicalNameSelection;
use v5.40;
use utf8;
use strict;
use warnings;
use Exporter 'import';
use Scalar::Util qw(blessed);
use Pastafari::SourceLanguageCatalog qw(source_language catalog_version cutlet_entries month_entries);
use Pastafari::Monster::StreamDistinctNameMaterialization qw(select_distinct_names);

our @EXPORT_OK = qw(select_canonical_names);

# Catalog names are solely from the accepted source-language Stage01 freeze.
# This adapter does not create sauce, a bowl stream, dates, or canonical events.
sub select_canonical_names ($kind, $first, $direction_step, $selected_count) {
    die "目錄類型無效\n" if !defined($kind) || ref($kind)
        || ($kind ne 'cutlet' && $kind ne 'month');
    die "正式目錄版本無效\n"
        if source_language() ne '繁體中文（國語）'
        || catalog_version() ne '1.0.0-stage1-frozen';

    my $minimum = $kind eq 'cutlet' ? 6 : 3;
    my $maximum = $kind eq 'cutlet' ? 17 : 47;
    die "選取數量無效\n" if !defined($selected_count)
        || (ref($selected_count) && !(blessed($selected_count)
                && $selected_count->isa('Math::BigInt')));
    my $digits = "$selected_count";
    die "選取數量無效\n" if $digits !~ /\A[1-9][0-9]*\z/
        || length($digits) > 2 || $digits < $minimum || $digits > $maximum;

    my $entries = $kind eq 'cutlet' ? cutlet_entries() : month_entries();
    die "正式目錄長度無效\n" if ref($entries) ne 'ARRAY'
        || @$entries != $maximum;
    my (@catalog, %used);
    for my $i (0 .. $#$entries) {
        my $entry = $entries->[$i];
        die "正式目錄條目無效\n" if ref($entry) ne 'HASH';
        my $index = $entry->{canonicalIndex};
        my $name = $entry->{source};
        die "正式目錄順序無效\n" if !defined($index) || ref($index)
            || "$index" ne '' . ($i + 1);
        die "正式目錄名稱無效\n" if !defined($name) || ref($name)
            || $name !~ /\S/u || $used{$name}++;
        push @catalog, "$name";
    }
    return select_distinct_names($first, $direction_step, \@catalog, $selected_count);
}

1;
