package Pastafari::Monster::BaseValidator;
use v5.40;
use strict;
use warnings;
use Scalar::Util qw(looks_like_number);

sub new ($class) { return bless {}, $class }

sub require_integer_day ($self, $value) {
    die "日期必須是整數\n" if !defined($value) || !looks_like_number($value) || $value !~ /\A[+-]?\d+\z/;
    return 1;
}

sub require_semantic_state_owned ($self, $ctx) {
    die "語意狀態缺少單次呼叫擁有者\n" if ref($ctx) ne 'Pastafari::Monster::BaseContext';
    return 1;
}

1;
