<?php
declare(strict_types=1);

/** Stage56 native regression: explicit coordinate boundary, not full acceptance. */
require_once __DIR__ . '/bootstrap.php';
require_once dirname(__DIR__) . '/src/Patches/CanonicalJdnBoundary56.php';

use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Patches\CanonicalJdnBoundary56 as Bridge;

const STAGE56_COORDINATE_SOURCE = Bridge::SOURCE_COMMIT;
const STAGE56_COORDINATE_CALCULATION = -13334246;

$checks = 0;
$check = static function (bool $condition, string $name) use (&$checks): void {
    if (!$condition) {
        throw new RuntimeException('STAGE56_COORDINATE_REGRESSION_' . $name);
    }
    ++$checks;
};
$reject = static function (callable $operation, string $error)
    use ($check): void {
    try {
        $operation();
    } catch (InvalidArgumentException|OutOfRangeException $e) {
        $check($e->getMessage() === $error, 'REJECTION_' . $error);
        return;
    }
    throw new RuntimeException('STAGE56_COORDINATE_NOT_REJECTED_' . $error);
};

$check(Bridge::SHIFT_TO_PHP === -1721425, 'SHIFT');
$kernel = new BootstrapKernel();
$bridge = new Bridge($kernel);
// Historical PHP-native JDNs must not be silently remapped.
$check($kernel->dayCount(-15055671)->toString() === '1', 'LEGACY_FOUNDATION');
$check($kernel->dayCount(-13334246)->toString() === '3442851', 'LEGACY_UNCHANGED');

$cases = [
    4999 => [-13340403, -15061828, '14374117473731844947696598361063346125',
        [6,4,3,2,1,5], '73798764692288874135000024365109114723', 1, 2],
    5000 => [-13336277, -15057702, '104801149399974323964160455528163370769',
        [2,5,6,4,3,1], '81778901639473882019855462426029763179', 1, 1],
    5001 => [-13332033, -15053458, '70585863274639670479561974357830767407',
        [2,6,5,1,3,4], '81920530390712611044014623049095354507', 1, 4],
];
// Independent pinned-Python expected values were verified in completed Actions
// #45068985923 artifact #14772417703; they are regression witnesses,
// NOT an independent algorithm or substitute for a live source-bound oracle.
foreach ($cases as $year => [$sourceTarget, $phpTarget, $firstBowl, $order,
                             $firstResponse, $direction, $nextBowl]) {
    $pair = Bridge::translatedPair(STAGE56_COORDINATE_CALCULATION,
        $sourceTarget, STAGE56_COORDINATE_SOURCE);
    $check($pair === ['calculation' => -15055671, 'target' => $phpTarget],
        'PAIR_' . $year);
    $check($pair['target'] - $pair['calculation'] ===
        $sourceTarget - STAGE56_COORDINATE_CALCULATION,
        'DISTANCE_' . $year);
    $sauce = $bridge->sauceOrder(STAGE56_COORDINATE_CALCULATION,
        $sourceTarget, STAGE56_COORDINATE_SOURCE);
    $check($sauce['bowls'][1]->toString() === $firstBowl, 'BOWL_' . $year);
    $check($sauce['orderAtDrop46'] === $order, 'ORDER_' . $year);
    $response = $bridge->askBowl(STAGE56_COORDINATE_CALCULATION,
        $sourceTarget, 3, 30, STAGE56_COORDINATE_SOURCE);
    $check($response['first']->toString() === $firstResponse &&
        $response['step'] === $direction && $response['nextBowlId'] === $nextBowl,
        'RESPONSE_' . $year);
    $check(Bridge::toSourceJdn($phpTarget, STAGE56_COORDINATE_SOURCE) ===
        $sourceTarget, 'ROUNDTRIP_' . $year);
}
$check(Bridge::toPhpJdn(PHP_INT_MIN + 1721425, STAGE56_COORDINATE_SOURCE) ===
    PHP_INT_MIN, 'LOWEST_SAFE');
$check(Bridge::toSourceJdn(PHP_INT_MAX - 1721425, STAGE56_COORDINATE_SOURCE) ===
    PHP_INT_MAX, 'HIGHEST_SAFE');
$reject(static fn() => Bridge::toPhpJdn(PHP_INT_MIN, STAGE56_COORDINATE_SOURCE),
    'STAGE56_COORDINATE_PHP_UNDERFLOW');
$reject(static fn() => Bridge::toSourceJdn(PHP_INT_MAX, STAGE56_COORDINATE_SOURCE),
    'STAGE56_COORDINATE_SOURCE_OVERFLOW');
foreach (['', str_repeat('0', 40), strtoupper(STAGE56_COORDINATE_SOURCE)] as $wrong) {
    $reject(static fn() => Bridge::toPhpJdn(0, $wrong),
        'STAGE56_COORDINATE_SOURCE_COMMIT');
}
$reject(static fn() => $bridge->sauceOrder(
    STAGE56_COORDINATE_CALCULATION, -13340403, str_repeat('0', 40)),
    'STAGE56_COORDINATE_SOURCE_COMMIT');
$reject(static fn() => $bridge->askBowl(
    STAGE56_COORDINATE_CALCULATION, -13340403, 3, 30, str_repeat('0', 40)),
    'STAGE56_COORDINATE_SOURCE_COMMIT');
echo "STAGE56_COORDINATE_NATIVE_BOUNDARY_PASS checks={$checks}; RAW_PHP_PARITY=FAIL; STAGE56_ACCEPTED=NO\n";
