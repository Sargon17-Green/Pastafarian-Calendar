<?php
declare(strict_types=1);

require_once dirname(__DIR__) . '/tests/bootstrap.php';

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Oracle\BoundedCompositionCounter;
use Pastafari\Stage01\Oracle\CutletPartitionCounter;
use Pastafari\Stage01\Oracle\DistinctNameFamily;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeOracle;
use Pastafari\Stage01\Oracle\WeavingCounter;

function strings(array $values): array
{
    $out = [];
    foreach ($values as $k => $v) {
        $out[(string)$k] = $v instanceof BigInt ? $v->toString() : $v;
    }
    return $out;
}

$oracle = new NormativeOracle();
$sauce = $oracle->sauceEngine();
$m = NormativeMath::m();

$fixture = [];
$fixture['m'] = $m->toString();
$fixture['save'] = [
    '1' => NormativeMath::save(1)->toString(),
    'M-1' => NormativeMath::save($m->sub(BigInt::one()))->toString(),
    'M' => NormativeMath::save($m)->toString(),
    'M+1' => NormativeMath::save($m->add(BigInt::one()))->toString(),
    '2M' => NormativeMath::save($m->mulSmall(2))->toString(),
];
$foundation = NormativeMath::FOUNDATION_DAY;
$fixture['dayCount'] = [
    'before' => NormativeMath::dayCount($foundation - 1)->toString(),
    'foundation' => NormativeMath::dayCount($foundation)->toString(),
    'after' => NormativeMath::dayCount($foundation + 1)->toString(),
];
$wc = NormativeMath::workCounts($foundation - 2, $foundation + 3);
$fixture['workCountsCrossFoundation'] = [
    'action'=>$wc['action']->toString(),
    'target'=>$wc['target']->toString(),
    'distance'=>$wc['distance']->toString(),
    'connection'=>$wc['connection']->toString(),
    'direction'=>$wc['direction'],
];
$stones = $sauce->buildStones();
$fixture['stone2'] = strings($stones[2]);
$fixture['stone46'] = strings($stones[46]);

foreach ([
    'foundation'=>[$foundation,$foundation],
    'cross'=>[$foundation-1,$foundation+1],
    'forward'=>[$foundation+7,$foundation+19],
] as $name => [$c,$t]) {
    $r = $sauce->sauce($c,$t);
    $fixture['sauce'][$name] = [
        'bowls'=>strings($r['bowls']),
        'orderAtDrop46'=>$r['orderAtDrop46'],
        'hidden1'=>$r['hidden'][1]->toString(),
        'hidden7'=>$r['hidden'][7]->toString(),
        'visible1'=>$r['visible'][1]->toString(),
        'visible46'=>$r['visible'][46]->toString(),
    ];
}

$fixture['gateGap'] = [
    'positive1'=>$oracle->positiveGateGap(1),
    'negative1'=>$oracle->negativeGateGap(1),
];

$streamShort = ['first'=>BigInt::fromInt(123456789), 'step'=>1];
$fixture['selection']['short10'] = $sauce->chooseRank($streamShort, BigInt::fromInt(10))->toString();
$streamWide = ['first'=>BigInt::fromInt(42), 'step'=>1];
$fixture['selection']['wideMPlus1'] = $sauce->chooseRank($streamWide, $m->add(BigInt::one()))->toString();

$bounded = new BoundedCompositionCounter(12,3,2,6);
$fixture['bounded'] = [
    'count'=>$bounded->countAll()->toString(),
    'rank5'=>$bounded->unrank1(BigInt::fromInt(5)),
];
$cutlet = new CutletPartitionCounter(8,3,4);
$fixture['cutletPartition'] = [
    'count'=>$cutlet->countAll()->toString(),
    'rank3'=>$cutlet->unrank1(BigInt::fromInt(3)),
];
$weave = new WeavingCounter([2,2,1]);
$fixture['weaving'] = [
    'count'=>$weave->countAll()->toString(),
    'rank1'=>$weave->unrank1(BigInt::one()),
    'last'=>$weave->unrank1($weave->countAll()),
];
$fixture['distinctNames'] = DistinctNameFamily::unrankIndices(5,3,BigInt::fromInt(17));

$fixture['year5000Foundation'] = $oracle->year5000($foundation);

file_put_contents(
    dirname(__DIR__) . '/tests/fixtures_stage01.json',
    json_encode($fixture, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE) . PHP_EOL
);
