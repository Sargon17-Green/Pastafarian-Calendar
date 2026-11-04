package Pastafari::Monster::StreamDistinctNameMaterialization;
use v5.40;
use utf8;
use strict;
use warnings;
use Exporter 'import';
use Scalar::Util qw(blessed);
use Pastafari::Monster::StreamDistinctNameSelection qw(select_distinct_name_indices);

our @EXPORT_OK = qw(select_distinct_names);

# The catalog is supplied by the caller. This adapter neither invents
# canonical names nor changes any of the existing stream/index semantics.
sub select_distinct_names ($first, $direction_step, $catalog, $selected_count) {
    die "名稱目錄必須是陣列\n" if ref($catalog) ne 'ARRAY' || blessed($catalog);
    my $size = scalar @$catalog;
    die "名稱目錄長度無效\n" if $size < 1 || $size > 47;
    my %seen;
    for my $name (@$catalog) {
        die "名稱目錄包含無效名稱\n"
            if !defined($name) || ref($name) || $name !~ /\S/u;
        die "名稱目錄包含重複名稱\n" if $seen{$name}++;
    }
    my $indices = select_distinct_name_indices($first, $direction_step, $size, $selected_count);
    return [map { "$catalog->[$_ - 1]" } @$indices];
}

1;
