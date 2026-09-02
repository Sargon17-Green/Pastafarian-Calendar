package Pastafari::Monster::BaseErrorBoundary;
use v5.40;
use strict;
use warnings;

sub new ($class) { return bless {}, $class }

sub run ($self, $ctx, $code) {
    my $result;
    my $ok = eval {
        $result = $code->();
        1;
    };
    if (!$ok) {
        my $error = $@ || "未知錯誤\n";
        $ctx->{lastError} = $error;
        $ctx->{status} = 'FAILED';
        die $error;
    }
    return $result;
}

1;
