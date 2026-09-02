package Pastafari::Monster::BaseContext;
use v5.40;
use strict;
use warnings;

sub new ($class, %args) {
    my $self = {
        calculationDay => $args{calculationDay},
        targetDay      => $args{targetDay},
        phase          => 'BOOTSTRAP',
        status         => 'NEW',
        semanticState  => {},
        logs           => [],
        metrics        => {},
        diagnostics    => [],
        lastError      => undef,
    };
    return bless $self, $class;
}

sub semantic_snapshot ($self) {
    return { %{ $self->{semanticState} } };
}

1;
