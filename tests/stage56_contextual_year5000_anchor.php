<?php
declare(strict_types=1);

require_once dirname(__DIR__) . '/src/Patches/ContextualYear5000Anchor56.php';

use Pastafari\Stage01\Patches\ContextualYear5000Anchor56;

$provider = new ContextualYear5000Anchor56();
$calculation = 50;
$base = [
    'calculation_jdn' => $calculation,
    'source_commit' => str_repeat('a', 40),
    'year' => [
        'number' => 5000,
        'openGateIndex' => 10,
        'closeGateIndex' => 20,
        'openGateDay' => -100,
        'closeGateDay' => 300,
    ],
];
// Source metadata is an explicitly synthetic boundary fixture, NOT a
// reconstructed canonical year or evidence of a source-authenticated provider.
$checks = 0;
$trustedCalls = 0;
$trusted = static function (int $day) use ($base, &$trustedCalls): array {
    ++$trustedCalls;
    if ($day !== $base['calculation_jdn']) {
        throw new RuntimeException('UNEXPECTED_CONTEXT');
    }
    return $base;
};
$year = $provider->bind($calculation, $base, $trusted);
if ($year !== $base['year'] || $trustedCalls !== 1) {
    throw new RuntimeException('STAGE56_CONTEXT_POSITIVE');
}
++$checks;

$reject = static function (string $name, array $bad, callable $callback,
    string $expected) use ($provider, $calculation, &$checks): void {
    try {
        $provider->bind($calculation, $bad, $callback);
        throw new RuntimeException('FAILED_TO_REJECT:' . $name);
    } catch (InvalidArgumentException|RuntimeException $e) {
        if ($e->getMessage() !== $expected) {
            throw new RuntimeException('WRONG_REJECTION:' . $name . ':' . $e->getMessage());
        }
    }
    ++$checks;
};

$bad = $base;
$bad['calculation_jdn'] = $calculation + 1;
$reject('wrong context', $bad, $trusted, 'STAGE56_ANCHOR_CANDIDATE_CONTEXT');
$bad = $base;
$bad['source_commit'] = 'G' . substr($base['source_commit'], 1);
$reject('bad hash', $bad, $trusted, 'STAGE56_ANCHOR_CANDIDATE_SOURCE');
$bad = $base;
$bad['source_commit'] = str_repeat('0', 40);
$reject('source mismatch', $bad, $trusted, 'STAGE56_ANCHOR_SOURCE_MISMATCH');
$bad = $base;
$bad['year']['openGateDay'] -= 1;
$reject('identity differs', $bad, $trusted, 'STAGE56_ANCHOR_IDENTITY_MISMATCH_openGateDay');
$bad = $base;
$bad['year']['number'] = 4999;
$reject('wrong year', $bad, $trusted, 'STAGE56_ANCHOR_CANDIDATE_INTERVAL');
$bad = $base;
$bad['year']['openGateDay'] = $calculation;
$reject('open endpoint', $bad, $trusted, 'STAGE56_ANCHOR_CANDIDATE_INTERVAL');
$bad = $base;
$bad['year']['closeGateDay'] = $calculation - 1;
$reject('close endpoint', $bad, $trusted, 'STAGE56_ANCHOR_CANDIDATE_INTERVAL');
$bad = $base;
$bad['year']['openGateIndex'] = 20;
$reject('invalid gate interval', $bad, $trusted, 'STAGE56_ANCHOR_CANDIDATE_INTERVAL');
$bad = $base;
$bad['year']['closeGateIndex'] = 11;
$reject('few gates', $bad, $trusted, 'STAGE56_ANCHOR_CANDIDATE_INTERVAL');
$bad = $base;
unset($bad['year']['closeGateDay']);
$reject('missing field', $bad, $trusted, 'STAGE56_ANCHOR_CANDIDATE_YEAR_closeGateDay');
$bad = $base;
$bad['year']['closeGateDay'] = '123';
$reject('wrong type', $bad, $trusted, 'STAGE56_ANCHOR_CANDIDATE_YEAR_closeGateDay');
$reject('trusted wrong type', $base, static fn(int $d): string => 'bad', 'STAGE56_ANCHOR_TRUSTED_TYPE');
$badTrusted = $base;
$badTrusted['calculation_jdn'] = $calculation + 1;
$reject('trusted wrong context', $base, static fn(int $d): array => $badTrusted,
    'STAGE56_ANCHOR_TRUSTED_CONTEXT');
$badTrusted = $base;
$badTrusted['year']['closeGateDay'] += 1;
$reject('trusted distinct', $base, static fn(int $d): array => $badTrusted,
    'STAGE56_ANCHOR_IDENTITY_MISMATCH_closeGateDay');
$reject('exception preserved', $base, static function (int $d): array {
    throw new RuntimeException('SOURCE_UNAVAILABLE');
}, 'SOURCE_UNAVAILABLE');

if ($base['year']['openGateDay'] !== -100 || $trustedCalls < 1) {
    throw new RuntimeException('STAGE56_CONTEXT_MUTATION');
}
++$checks;
echo "STAGE56_CONTEXTUAL_ANCHOR_BOUNDARY_LOCAL_PASS checks={$checks}; TRUSTED_SOURCE_ATTESTATION=NO; PROVIDER=NOT_IMPLEMENTED\n";
