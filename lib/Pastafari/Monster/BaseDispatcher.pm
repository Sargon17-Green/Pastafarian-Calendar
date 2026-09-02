package Pastafari::Monster::BaseDispatcher;
use v5.40;
use strict;
use warnings;

sub new ($class) { return bless { handlers => {} }, $class }

sub register ($self, $phase, $handler) {
    die "處理階段已註冊\n" if exists $self->{handlers}{$phase};
    $self->{handlers}{$phase} = $handler;
    return 1;
}

sub dispatch ($self, $phase, $ctx) {
    die "找不到處理階段\n" if !exists $self->{handlers}{$phase};
    return $self->{handlers}{$phase}->($ctx);
}

1;
