package Pastafari::SpaghettiMonster;
use v5.40;
use utf8;
use strict;
use warnings;
use Exporter 'import';
use Pastafari::Monster::BaseContext;
use Pastafari::Monster::BaseDispatcher;
use Pastafari::Monster::BaseValidator;
use Pastafari::Monster::BaseErrorBoundary;
use Pastafari::Monster::BaseMetrics;

our @EXPORT_OK = qw(calendarDateSpaghetti bootstrap_components);

sub bootstrap_components {
    return {
        dispatcher => Pastafari::Monster::BaseDispatcher->new,
        validator  => Pastafari::Monster::BaseValidator->new,
        errors     => Pastafari::Monster::BaseErrorBoundary->new,
        metrics    => Pastafari::Monster::BaseMetrics->new,
    };
}

sub calendarDateSpaghetti ($calculationDay, $targetDay) {
    my $ctx = Pastafari::Monster::BaseContext->new(
        calculationDay => $calculationDay,
        targetDay      => $targetDay,
    );
    my $parts = bootstrap_components();
    $parts->{validator}->require_integer_day($calculationDay);
    $parts->{validator}->require_integer_day($targetDay);
    $parts->{validator}->require_semantic_state_owned($ctx);
    die "第 1 階段只建立生產骨架；規範生產路徑會依歷史階段逐步形成。\n";
}

1;
