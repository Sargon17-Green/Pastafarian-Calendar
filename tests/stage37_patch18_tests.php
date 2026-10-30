<?php
declare(strict_types=1);
require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Oracle\NormativeMath;
use Pastafari\Stage01\Oracle\NormativeOracle;

$checks37 = 0;
function periksa37(bool $ok, string $label): void
{
    global $checks37;
    $checks37++;
    if (!$ok) throw new RuntimeException('STAGE37_FAILED_' . $label);
}
function mestiTolak37(callable $operation, string $label): void
{
    try {
        $operation();
    } catch (InvalidArgumentException|RuntimeException $e) {
        periksa37(true, $label);
        return;
    }
    periksa37(false, $label);
}

$calculationDay = NormativeMath::FOUNDATION_DAY;
$oracle = new NormativeOracle();
$anchor = $oracle->year5000($calculationDay);
$nextReal = static fn(array $y): array => $oracle->nextYear($calculationDay, $y);
$previousReal = static fn(array $y): array => $oracle->previousYear($calculationDay, $y);
$next = $nextReal($anchor);
$previous = $previousReal($anchor);
$kernel = new BootstrapKernel();
$baseline = serialize($anchor);
periksa37($anchor['number'] === 5000, 'ANCHOR');
periksa37($anchor['closeGateDay'] - $anchor['openGateDay'] > 365, 'RED_WITNESS');

$cases = [
    ['same_first', $anchor['openGateDay'] + 1, $anchor, 0, 'stay'],
    ['same_red365', $anchor['openGateDay'] + 365, $anchor, 0, 'stay'],
    ['same_last', $anchor['closeGateDay'], $anchor, 0, 'stay'],
    ['forward_first', $anchor['closeGateDay'] + 1, $next, 1, 'forward'],
    ['forward_last', $next['closeGateDay'], $next, 1, 'forward'],
    ['backward_last', $anchor['openGateDay'], $previous, 1, 'backward'],
    ['backward_first', $previous['openGateDay'] + 1, $previous, 1, 'backward'],
];
foreach ($cases as [$label,$target,$expected,$steps,$direction]) {
    $raw = $kernel->legacyGuessTargetYear365($calculationDay, $target, $anchor);
    $fixed = $kernel->targetYearSequentialPatch18(
        $calculationDay, $target, $anchor, $nextReal, $previousReal, 4
    );
    periksa37($fixed['targetYearCandidate'] === $expected, 'TRUE_YEAR_' . $label);
    periksa37($fixed['legacyReport'] === $raw, 'LEGACY_PHYSICALLY_PRESERVED_' . $label);
    periksa37($fixed['steps'] === $steps && $fixed['direction'] === $direction,
        'STEP_AND_DIRECTION_' . $label);
    periksa37($fixed['usedLegacyOutput'] === false, 'RAW_NOT_AUTHORITY_' . $label);
}
foreach (['same_red365'=>$anchor['openGateDay'] + 365,
          'same_last'=>$anchor['closeGateDay']] as $label=>$day) {
    $raw = $kernel->legacyGuessTargetYear365($calculationDay, $day, $anchor);
    periksa37($raw['guessedYearNumber'] !== 5000, 'ARCHIVE_RED_' . $label);
}
periksa37(serialize($anchor) === $baseline, 'INPUT_NOT_MUTATED');

$synthetic = ['number'=>5000,'openGateDay'=>0,'closeGateDay'=>4244];
$goodNext = static fn(array $y): array =>
    ['number'=>5001,'openGateDay'=>4244,'closeGateDay'=>4700];
$goodPrevious = static fn(array $y): array =>
    ['number'=>4999,'openGateDay'=>-400,'closeGateDay'=>0];
$badNumber = static fn(array $y): array =>
    ['number'=>5002,'openGateDay'=>4244,'closeGateDay'=>4700];
$badGate = static fn(array $y): array =>
    ['number'=>5001,'openGateDay'=>4245,'closeGateDay'=>4700];
$badPrevious = static fn(array $y): array =>
    ['number'=>4999,'openGateDay'=>-400,'closeGateDay'=>-1];
$do = static fn(int $target, callable $n, callable $p, int $budget=4): array =>
    (new BootstrapKernel())->targetYearSequentialPatch18(
        $calculationDay, $target, $synthetic, $n, $p, $budget
    );
mestiTolak37(static fn() => $do(4245,$badNumber,$goodPrevious), 'WRONG_NEXT_NUMBER');
mestiTolak37(static fn() => $do(4245,$badGate,$goodPrevious), 'NEXT_GATE_GAP');
mestiTolak37(static fn() => $do(0,$goodNext,$badPrevious), 'PREVIOUS_GATE_GAP');
mestiTolak37(static fn() => $do(4245,$goodNext,$goodPrevious,0), 'ZERO_BUDGET');
mestiTolak37(static fn() => $do(4245,$goodNext,$goodPrevious,-1), 'NEGATIVE_BUDGET');
mestiTolak37(static fn() => $do(4245,static fn(array $y)=>null,$goodPrevious), 'INVALID_PROVIDER');

$sourceRoot = dirname(__DIR__) . '/src';
$kernelCode = (string)file_get_contents($sourceRoot . '/BootstrapKernel.php');
$patchCode = (string)file_get_contents($sourceRoot . '/Patches/SequentialYearWalkPatch18.php');
periksa37(str_contains($kernelCode, "register('TARGET_YEAR_PATCH_18'") &&
    str_contains($kernelCode, "dispatch('TARGET_YEAR_PATCH_18', ".'$context)') &&
    str_contains($kernelCode, '$this->legacyGuessTargetYear365(') &&
    str_contains($patchCode, '$nextYear($old)') &&
    str_contains($patchCode, '$previousYear($old)'), 'REAL_PRODUCTION_ROUTE');
foreach (new RecursiveIteratorIterator(
    new RecursiveDirectoryIterator($sourceRoot, FilesystemIterator::SKIP_DOTS)
) as $file) {
    if (strtolower($file->getExtension()) !== 'php') continue;
    $source = (string)file_get_contents($file->getPathname());
    periksa37(!str_contains($source, 'NormativeOracle') &&
        !str_contains($source, 'NormativeMath') &&
        !str_contains($source, 'NormativeSauce'), 'NO_TEST_ORACLE_' . $file->getFilename());
}
echo "LULUS Stage37 PATCH18 checks={$checks37} genuine_years=3 real_targets=7 archive_red=2 invalid=6 stderr=0\n";
