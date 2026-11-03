package Pastafari::Monster::StreamDistinctNameSelection;
use v5.40;
use utf8;
use strict;
use warnings;
use Exporter 'import';
use Pastafari::Monster::StreamRankSelection qw(choose_rank_from_stream);
use Pastafari::Monster::DistinctNameAssignment qw(distinct_name_family);

our @EXPORT_OK = qw(select_distinct_name_indices);

# This module joins two already bounded producers; it does not calculate
# calendar dates, names, bowl values or any other seal semantics.
sub select_distinct_name_indices ($first, $direction_step, $catalog_size, $selected_count) {
    my $family = distinct_name_family($catalog_size, $selected_count);
    my $rank = choose_rank_from_stream($first, $direction_step, $family->{count}->());
    return $family->{unrank1}->($rank);
}

1;
