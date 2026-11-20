<?php
declare(strict_types=1);

require_once __DIR__ . '/stage56_actual_year_profile.php';

function stage56B5Fixture(): array
{
    $years = [];
    for ($i = 0; $i < 3; ++$i) {
        $years[] = [
            'number' => 4999 + $i,
            'open_gate_day' => $i * 252,
            'close_gate_day' => ($i + 1) * 252,
            'month_lengths' => [84, 84, 84],
            'month_weaving' => array_merge(...array_fill(0, 84, [1, 2, 3])),
        ];
    }
    return [
        'project_id' => 'PC-BRANCH-PHP-MALAY',
        'source' => [
            'kind' => 'production_export', // Claims structurally checked, NOT authenticated.
            'provider_path' => 'src/ProductionProvider.php',
            'source_commit' => str_repeat('a', 40),
            'provider_sha256' => str_repeat('b', 64),
            'anchor_sha256' => str_repeat('c', 64),
        ],
        'year5000_anchor' => ['number' => 5000, 'open_gate_day' => 252],
        'years' => $years,
    ];
}

function stage56B5MustReject(array $input, string $expected): void
{
    try {
        stage56B5Validate($input);
    } catch (InvalidArgumentException $e) {
        if ($e->getMessage() === 'STAGE56_B5_' . $expected) {
            return;
        }
        throw $e;
    }
    throw new RuntimeException('STAGE56_B5_EXPECTED_REJECT_' . $expected);
}

$good = stage56B5Fixture();
if (count(stage56B5Validate($good)) !== 3) {
    throw new RuntimeException('STAGE56_B5_VALID_SAMPLE');
}
$checks = 1;
$mutate = static function (callable $fn, string $expected) use ($good, &$checks): void {
    $v = $good;
    $fn($v);
    stage56B5MustReject($v, $expected);
    ++$checks;
};
$mutate(static function (&$v) {$v['project_id'] = 'WRONG';}, 'PROJECT');
$mutate(static function (&$v) {$v['source']['kind'] = 'fixture';}, 'SOURCE_CLAIM');
$mutate(static function (&$v) {$v['source']['provider_path'] = 'tests/oracle/Provider.php';}, 'SOURCE_CLAIM');
$mutate(static function (&$v) {$v['source']['provider_path'] = 'src/../Provider.php';}, 'SOURCE_CLAIM');
$mutate(static function (&$v) {$v['source']['provider_path'] = 'src/./Provider.php';}, 'SOURCE_CLAIM');
$mutate(static function (&$v) {$v['source']['provider_path'] = 'src//Provider.php';}, 'SOURCE_CLAIM');
$mutate(static function (&$v) {$v['source']['provider_path'] = '/tmp/Provider.php';}, 'SOURCE_CLAIM');
$mutate(static function (&$v) {$v['source']['provider_path'] = 'lib/Provider.php';}, 'SOURCE_CLAIM');
$mutate(static function (&$v) {$v['source']['provider_path'] = 'src\Provider.php';}, 'SOURCE_CLAIM');
$mutate(static function (&$v) {$v['source']['provider_path'] = 'src/Provider.txt';}, 'SOURCE_CLAIM');
$mutate(static function (&$v) {$v['source']['provider_path'] = 'src/MiXeD/FiXtUrEs/Provider.php';}, 'SOURCE_CLAIM');
$mutate(static function (&$v) {$v['source']['provider_path'] = "src/Provider.php\0";}, 'SOURCE_CLAIM');
$mutate(static function (&$v) {$v['source']['provider_sha256'] = 'bad';}, 'SOURCE_CLAIM');
$mutate(static function (&$v) {$v['year5000_anchor']['number'] = 4999;}, 'ANCHOR');
$mutate(static function (&$v) {$v['year5000_anchor']['open_gate_day']++;}, 'ANCHOR_MISMATCH');
$mutate(static function (&$v) {array_pop($v['years']);}, 'YEARS_SHAPE');
$mutate(static function (&$v) {$v['years'][1]['number'] = 5001;}, 'YEAR_RECORD');
$mutate(static function (&$v) {$v['years'][2]['open_gate_day']++;}, 'YEAR_BOUNDARY');
$mutate(static function (&$v) {array_pop($v['years'][0]['month_weaving']);}, 'MONTH_SHAPE');
$mutate(static function (&$v) {$v['years'][0]['month_lengths'][0] = 3;}, 'MONTH_LENGTH');
$mutate(static function (&$v) {$v['years'][0]['month_lengths'][0] = 85;}, 'MONTH_TOTAL');
$mutate(static function (&$v) {$v['years'][0]['month_weaving'][0] = 4;}, 'MONTH_ID');
$mutate(static function (&$v) {$v['years'][0]['month_weaving'][0] = 2;}, 'MONTH_COUNTS');
$mutate(static function (&$v) {
    $v['years'][0]['month_weaving'][0] = 2;
    $v['years'][0]['month_weaving'][1] = 1;
}, 'MONTH_ORDER');
if ($checks !== 25) {
    throw new RuntimeException('STAGE56_B5_CHECK_COUNT');
}
echo "STAGE56_B5_PREFLIGHT checks=$checks synthetic_structure_only=YES provenance=NOT_VERIFIED status=PASS\n";
