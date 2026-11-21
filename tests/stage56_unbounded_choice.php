<?php
declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';
require_once dirname(__DIR__) . '/src/Patches/UnboundedUniformChoice56.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeSauce;
use Pastafari\Stage01\Patches\UnboundedUniformChoice56;

$subject = new UnboundedUniformChoice56();
$oracle = new NormativeSauce();
$m = NormativeMath::m();
$m2 = $m->square();
$m5 = $m2->square()->mul($m);
$m6 = $m5->mul($m);
$checks = 0;

function checkChoice56(bool $ok, string $tag): void
{
    global $checks;
    ++$checks;
    if (!$ok) {
        throw new RuntimeException('STAGE56_CHOICE_TEST_' . $tag);
    }
}

$spaces = [
    BigInt::one(), BigInt::fromInt(2), $m->sub(BigInt::one()), $m,
    $m->add(BigInt::one()), $m2->add(BigInt::fromInt(7)), $m5,
    $m5->add(BigInt::one()), $m6->add(BigInt::fromInt(123)),
];
$firsts = [BigInt::one(), BigInt::fromInt(2),
    $m->sub(BigInt::one()), $m];
foreach ($spaces as $ni => $count) {
    foreach ($firsts as $fi => $first) {
        foreach ([-1, 1] as $step) {
            $stream = ['first' => $first, 'step' => $step];
            $expected = $oracle->chooseRank($stream, $count);
            $got = $subject->chooseFromStream($stream, $count);
            checkChoice56($got->equals($expected), 'ORACLE_' . $ni . '_' . $fi . '_' . $step);
            checkChoice56($got->compare(BigInt::one()) >= 0 &&
                $got->compare($count) <= 0, 'RANGE_' . $ni . '_' . $fi . '_' . $step);
        }
    }
}

// Explicit huge-rejection witnesses avoid making the independent oracle
// walk an astronomically long rejected tail. Here M^6/2 < n < M^6,
// so cutoff=n. The forward stream must wrap to one; backward hits n.
$weight = BigInt::one();
$plusWide = BigInt::one();
$minusWide = BigInt::one();
for ($i = 0; $i < 6; ++$i) {
    $plusWide = $plusWide->add(
        $m->sub(BigInt::fromInt(6 - $i))->mul($weight)
    );
    $minusWide = $minusWide->add(
        $m->sub(BigInt::fromInt($i + 1))->mul($weight)
    );
    $weight = $weight->mul($m);
}
$plusN = $plusWide->sub(BigInt::one());
$minusN = $minusWide->sub(BigInt::one());
checkChoice56($weight->equals($m6), 'SIX_PLACE_BASE');
checkChoice56($plusN->compare($m5) > 0 &&
    $plusN->compare($m6->floorDiv(BigInt::fromInt(2))) > 0, 'PLUS_DOMAIN');
checkChoice56($minusN->compare($m5) > 0 &&
    $minusN->compare($m6->floorDiv(BigInt::fromInt(2))) > 0, 'MINUS_DOMAIN');
checkChoice56($subject->chooseFromStream([
    'first' => $m->sub(BigInt::fromInt(5)), 'step' => 1
], $plusN)->equals(BigInt::one()), 'PLUS_WRAP_REJECTION');
checkChoice56($subject->chooseFromStream([
    'first' => $m, 'step' => -1
], $minusN)->equals($minusN), 'MINUS_DECREMENT_REJECTION');
checkChoice56($oracle->chooseRank([
    'first' => $m, 'step' => -1
], $minusN)->equals($minusN), 'MINUS_ORACLE_REJECTION');

// Production end-to-end source of bowl response (never a test fixture).
$kernel = new BootstrapKernel();
$real = 0;
foreach ([[10000000, -10000000], [2500000, 2500017]] as [$calculation, $target]) {
    $referenceSauce = $oracle->sauce($calculation, $target);
    foreach ([1, 3, 6] as $bowl) {
        $referenceStream = $oracle->askBowl($referenceSauce, $bowl, 32);
        foreach ([BigInt::fromInt(7), $m2->add(BigInt::fromInt(19)),
                  $m6->add(BigInt::fromInt(123))] as $count) {
            $got = $subject->chooseFromKernel(
                $kernel, $calculation, $target, $bowl, 32, $count
            );
            $want = $oracle->chooseRank($referenceStream, $count);
            checkChoice56($got->equals($want),
                'NATIVE_KERNEL_' . $calculation . '_' . $target . '_' . $bowl);
            ++$real;
        }
    }
}
checkChoice56($real === 18, 'KERNEL_COVERAGE');

$invalid = 0;
$badCases = [
    [['first' => BigInt::zero(), 'step' => 1], BigInt::one()],
    [['first' => $m->add(BigInt::one()), 'step' => 1], BigInt::one()],
    [['first' => BigInt::one(), 'step' => 0], BigInt::one()],
    [['first' => BigInt::one(), 'step' => 2], BigInt::one()],
    [['first' => BigInt::one()], BigInt::one()],
    [['first' => BigInt::one(), 'step' => 1], BigInt::zero()],
    [['first' => BigInt::one(), 'step' => 1], BigInt::fromInt(-1)],
];
foreach ($badCases as [$stream, $count]) {
    try {
        $subject->chooseFromStream($stream, $count);
        throw new RuntimeException('STAGE56_INVALID_ACCEPTED');
    } catch (InvalidArgumentException $e) {
        ++$invalid;
    }
}
checkChoice56($invalid === 7, 'INVALID_COVERAGE');

echo "STAGE56_UNBOUNDED_CHOICE checks={$checks} real={$real} invalid={$invalid} status=PASS; YEAR_PROVIDER=NOT_IMPLEMENTED\n";
