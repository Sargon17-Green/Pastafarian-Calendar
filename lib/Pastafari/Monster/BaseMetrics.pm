package Pastafari::Monster::BaseMetrics;
use v5.40;
use strict;
use warnings;

sub new ($class) { return bless { counters => {} }, $class }

sub bump ($self, $name) {
    $self->{counters}{$name} //= 0;
    $self->{counters}{$name}++;
    return $self->{counters}{$name};
}

sub snapshot ($self) { return { %{ $self->{counters} } } }

1;
