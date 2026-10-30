<?php
declare(strict_types=1);
require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Legacy\LegacyYearJumpGuess18;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeOracle;

function semak36(bool $condition, string $name): void
{
    if (!$condition) {
        throw new RuntimeException('STAGE36_UNEXPECTED_' . $name);
    }
}

// A verified Year5000 comes from an independent TEST-ONLY normative oracle.
// No normative year calculation is imported by production src/.
$oracle = new NormativeOracle();
$calculationDay = NormativeMath::FOUNDATION_DAY;
$authentic = $oracle->year5000($calculationDay);
$length = $authentic['closeGateDay'] - $authentic['openGateDay'];
semak36($authentic['number'] === 5000, 'FOUNDATION_YEAR_NUMBER');
semak36($length > 365 && $length <= NormativeMath::YEAR_MAX_DAYS, 'LONG_REAL_YEAR');

$anchor = [
    'number' => $authentic['number'],
    'openGateDay' => $authentic['openGateDay'],
    'closeGateDay' => $authentic['closeGateDay'],
];
$kernel = new BootstrapKernel();
$other = new BootstrapKernel();
$legacy = new LegacyYearJumpGuess18();
$beforeAnchor = serialize($anchor);

// All three targets truly belong to the SAME year 5000, by authoritative
// (openGateDay, closeGateDay] membership; two must be wrong in historical /365.
$cases = [
    'kawalan' => $anchor['openGateDay'] + 1,
    'selepas_365' => $anchor['openGateDay'] + 365,
    'akhir_tahun' => $anchor['closeGateDay'],
];
$reds = 0;
$matches = 0;
foreach ($cases as $name => $target) {
    semak36($anchor['openGateDay'] < $target && $target <= $anchor['closeGateDay'],
        'REAL_MEMBERSHIP_' . $name);
    $output = $kernel->legacyGuessTargetYear365($calculationDay, $target, $anchor);
    $independentKernel = $other->legacyGuessTargetYear365($calculationDay, $target, $anchor);
    $direct = $legacy->guess($anchor, $target);
    semak36($output === $direct && $output === $independentKernel,
        'REAL_ROUTE_' . $name);
    semak36($output['anchorNumber'] === 5000 &&
        $output['anchorOpenGateDay'] === $anchor['openGateDay'] &&
        $output['anchorCloseGateDay'] === $anchor['closeGateDay'] &&
        $output['targetDay'] === $target &&
        $output['usedLegacyOutput'] === true, 'REPORT_' . $name);
    if ($output['guessedYearNumber'] !== 5000) {
        // The first day control must not be a red. The only authorized red
        // signatures are exactly these two named observations.
        semak36($name !== 'kawalan', 'CONTROL_MUST_MATCH');
        $reds++;
        echo "GAGAL_DIJANGKA witness={$name} lama={$output['guessedYearNumber']} sah=5000\n";
    } else {
        semak36($name === 'kawalan', 'RED_WITNESS_MISSING_' . $name);
        $matches++;
    }
}
semak36($reds === 2 && $matches === 1, 'REAL_EXPECTED_RED_COUNTS');
semak36(serialize($anchor) === $beforeAnchor, 'ANCHOR_PRESERVED');

// Independent deterministic signed FLOOR arithmetic control, including
// negative exact multiples, and large signed offsets (no native subtraction).
$synthetic = ['number'=>5000, 'openGateDay'=>0, 'closeGateDay'=>4244];
foreach ([
    [-731, 4997], [-730, 4998], [-366, 4998],
    [-365, 4999], [-1, 4999], [0, 5000],
    [1, 5000], [364, 5000], [365, 5001], [730, 5002]
] as [$day, $year]) {
    $a = $kernel->legacyGuessTargetYear365($calculationDay, $day, $synthetic);
    semak36($a['guessedYearNumber'] === $year, 'SIGNED_FLOOR_' . $day);
}
semak36(
    $legacy->guess($synthetic, PHP_INT_MAX)['guessedYearNumber'] > 5000 &&
    $legacy->guess($synthetic, PHP_INT_MIN)['guessedYearNumber'] < 5000,
    'BIGINT_BOUNDARY_NO_OVERFLOW'
);

// Exactly these malformed anchor cases must be rejected by the real route.
$invalid = 0;
foreach ([
    [],
    ['number'=>5001,'openGateDay'=>0,'closeGateDay'=>4244],
    ['number'=>5000,'openGateDay'=>'0','closeGateDay'=>4244],
    ['number'=>5000,'openGateDay'=>0,'closeGateDay'=>251],
    ['number'=>5000,'openGateDay'=>0,'closeGateDay'=>5779],
    ['number'=>5000,'openGateDay'=>20,'closeGateDay'=>10],
] as $badAnchor) {
    try {
        $kernel->legacyGuessTargetYear365($calculationDay, 3, $badAnchor);
        throw new RuntimeException('STAGE36_UNEXPECTED_BAD_ANCHOR_ACCEPTED');
    } catch (InvalidArgumentException $e) {
        $invalid++;
    }
}
semak36($invalid === 6, 'INVALID_ANCHORS');

// Check that the source actually takes the dispatcher production route and
// does not use a test oracle as a hidden implementation substitute.
$sourceRoot = dirname(__DIR__) . '/src';
$kernelCode = (string)file_get_contents($sourceRoot . '/BootstrapKernel.php');
$legacyCode = (string)file_get_contents($sourceRoot . '/Legacy/LegacyYearJumpGuess18.php');
semak36(str_contains($kernelCode, "register('YEAR_JUMP_365_LEGACY'") &&
    str_contains($kernelCode, "dispatch('YEAR_JUMP_365_LEGACY', ".'$context)') &&
    str_contains($legacyCode, 'floorDiv(BigInt::fromInt(365))'),
    'PHYSICAL_PRODUCTION_DISPATCH');
foreach (new RecursiveIteratorIterator(
    new RecursiveDirectoryIterator($sourceRoot, FilesystemIterator::SKIP_DOTS)
) as $file) {
    if (strtolower($file->getExtension()) !== 'php') continue;
    $source = (string)file_get_contents($file->getPathname());
    semak36(!str_contains($source,'NormativeMath') &&
        !str_contains($source,'NormativeSauce') &&
        !str_contains($source,'NormativeOracle'),
        'NO_TEST_ORACLE_IN_PRODUCTION_' . $file->getFilename());
}
echo "LULUS Stage36 DISCOVERY18 kawalan={$matches} merah={$reds} real=3 invalid={$invalid} floor=10 lain=0\n";
// Deliberate historical exit status: zero means the old wrong route
// was accidentally corrected or the red witnesses disappeared.
exit(1);
