unit module Pastafari::Bootstrap;

use Pastafari::Bootstrap::Infrastructure;

sub prepare-monster-context(Int:D $calculation-day, Int:D $target-day --> MonsterContext:D) is export {
    MonsterManager.new.prepare($calculation-day, $target-day)
}
