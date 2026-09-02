unit module Pastafari::Calendar;

use Pastafari::Bootstrap;

class X::Pastafari::StageNotReached is Exception is export {
    has Int $.stage;
    method message() {
        "Kalendri autoriteetne tootmistee ei ole etapis $!stage veel ajalooliselt lubatud"
    }
}

sub calendar-date-spaghetti(Int:D $calculation-day, Int:D $target-day) is export {
    my $ctx = prepare-monster-context($calculation-day, $target-day);
    $ctx.status = 'WAITING_FOR_HISTORICAL_GROWTH';
    die X::Pastafari::StageNotReached.new(stage => 1);
}
