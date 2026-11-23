<?php
declare(strict_types=1);
/**
 * Stage56 regression of the opt-in *integration boundary*, not an
 * independent algorithmic oracle or complete Stage56 acceptance.
 */
require_once __DIR__ . '/bootstrap.php';
foreach (['CanonicalJdnBoundary56', 'YearStructureSlices56',
    'MonthWeavingFrontier56', 'MonthWeavingAdjoint56',
    'MonthWeavingRanker56', 'UnboundedUniformChoice56',
    'ContextualYear5000Anchor56', 'YearStructureProvider56'] as $class) {
    require_once dirname(__DIR__) . '/src/Patches/' . $class . '.php';
}

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Patches\CanonicalJdnBoundary56 as Boundary;
use Pastafari\Stage01\Patches\UnboundedUniformChoice56;
use Pastafari\Stage01\Patches\YearStructureProvider56;

$checks = 0;
$check = static function (bool $good, string $label) use (&$checks): void {
    if (!$good) throw new RuntimeException('STAGE56_PROVIDER_ADAPTER_' . $label);
    ++$checks;
};
$kernel = new BootstrapKernel();
$source = new YearStructureProvider56($kernel, Boundary::SOURCE_COMMIT);
$legacy = new YearStructureProvider56($kernel);
$choice = new ReflectionMethod(YearStructureProvider56::class, 'choice');
$counter = new UnboundedUniformChoice56();
$count = BigInt::fromInt(19);
$c = Boundary::SOURCE_FOUNDATION_JDN;
// Separate, previously pinned regression witnesses. These are NOT a new oracle.
$cases = [
    4999 => [-13340403, '73798764692288874135000024365109114723', 1],
    5000 => [-13336277, '81778901639473882019855462426029763179', 1],
    5001 => [-13332033, '81920530390712611044014623049095354507', 1],
];
foreach ($cases as $year => [$t, $first, $step]) {
    $events = [];
    $profile = static function (string $event, string $stage, array $data)
        use (&$events): void {
        if ($event === 'end' && $stage === 'source_choice') $events[] = $data;
    };
    $rank = $choice->invoke($source, $c, $t, 3, 30, $count, $profile,
        'source_choice');
    $check($rank instanceof BigInt && count($events) === 1,
        'SOURCE_TRACE_' . $year);
    $trace = $events[0];
    $check(($trace['stream_first'] ?? null) === $first &&
        ($trace['stream_step'] ?? null) === $step,
        'PINNED_STREAM_' . $year);
    $pair = Boundary::translatedPair($c, $t, Boundary::SOURCE_COMMIT);
    $expected = $counter->chooseFromKernel($kernel, $pair['calculation'],
        $pair['target'], 3, 30, $count);
    $check($rank->toString() === $expected->toString() &&
        $rank->toString() === BigInt::fromString($first)->sub(BigInt::one())
            ->mod($count)->add(BigInt::one())->toString(),
        'TRANSLATED_RANK_' . $year);
    // With no explicit source opt-in, the original PHP coordinate system
    // must stay byte-for-byte semantically unchanged at the choice call.
    $old = $choice->invoke($legacy, $c, $t, 3, 30, $count, null, 'raw');
    $raw = $counter->chooseFromKernel($kernel, $c, $t, 3, 30, $count);
    $check($old instanceof BigInt &&
        $old->toString() === $raw->toString(), 'LEGACY_' . $year);
}
$rejected = false;
try {
    new YearStructureProvider56($kernel, str_repeat('0', 40));
} catch (InvalidArgumentException $error) {
    $rejected = $error->getMessage() === 'STAGE56_COORDINATE_SOURCE_COMMIT';
}
$check($rejected, 'FAIL_CLOSED_SOURCE_COMMIT');
echo "STAGE56_PROVIDER_SOURCE_ADAPTER_QA_ONLY checks={$checks} years=3 stage56_accepted=NO\n";
