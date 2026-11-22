<?php
declare(strict_types=1);

/** Stage56 QA-only snapshot of the genuine PHP production sauce; no year construction. */
require_once __DIR__ . '/bootstrap.php';

use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\BigInt;

const STAGE56_SAUCE_PROJECT = 'PC-BRANCH-PHP-MALAY';
const STAGE56_SAUCE_SOURCE = 'cc2cf0b422757a5e7c33218ce30cffa8f99c6786';
const STAGE56_SAUCE_CALCULATION_JDN = -13334246;
// QA-only coordinate transform, not a change to production semantics.
const STAGE56_SAUCE_LOCAL_FOUNDATION = -15055671;
const STAGE56_SAUCE_REFERENCE_FOUNDATION = -13334246;
const STAGE56_SAUCE_SHIFT = STAGE56_SAUCE_LOCAL_FOUNDATION - STAGE56_SAUCE_REFERENCE_FOUNDATION;

try {
    $kernel = new BootstrapKernel();
    $collect = static function (int $shift) use ($kernel): array {
    $records = [];
    foreach ([4999 => -13340403, 5000 => -13336277, 5001 => -13332033] as $year => $targetJdn) {
        $sauce = $kernel->sauceOrder((STAGE56_SAUCE_CALCULATION_JDN + $shift), ($targetJdn + $shift));
        $order = $sauce['orderAtDrop46'] ?? null;
        $bowls = $sauce['bowls'] ?? null;
        if (!is_array($order) || !is_array($bowls) || count($order) !== 6 ||
            array_values(array_unique($order)) !== array_values($order) ||
            array_diff($order, range(1, 6)) !== [] ||
            array_diff(range(1, 6), $order) !== []) {
            throw new RuntimeException('STAGE56_SAUCE_SHAPE');
        }
        $values = [];
        foreach (range(1, 6) as $bowlId) {
            if (!($bowls[$bowlId] ?? null) instanceof BigInt) {
                throw new RuntimeException('STAGE56_SAUCE_BOWL_TYPE');
            }
            $values[] = $bowls[$bowlId]->toString();
        }
        $stream = $kernel->askBowl((STAGE56_SAUCE_CALCULATION_JDN + $shift), ($targetJdn + $shift), 3, 30);
        if (!($stream['first'] ?? null) instanceof BigInt ||
            !in_array($stream['step'] ?? null, [-1, 1], true) ||
            !is_int($stream['nextBowlId'] ?? null)) {
            throw new RuntimeException('STAGE56_SAUCE_STREAM_TYPE');
        }
        $records[] = [
            'year' => $year,
            'target_jdn' => $targetJdn,
            'bowls' => $values,
            'drop46_order' => $order,
            'response_first' => $stream['first']->toString(),
            'response_step' => $stream['step'],
            'next_bowl_id' => $stream['nextBowlId'],
        ];
    }
        return $records;
    };
    $records = $collect(0);
    $translatedRecords = $collect(STAGE56_SAUCE_SHIFT);
    echo json_encode([
        'project_id' => STAGE56_SAUCE_PROJECT,
        'branch_sha' => getenv('GITHUB_SHA') ?: null,
        'reference_source_commit' => STAGE56_SAUCE_SOURCE,
        'calculation_jdn' => STAGE56_SAUCE_CALCULATION_JDN,
        'php_bowl_indexing' => '1..6',
        'records' => $records,
        'foundation_coordinate_diagnostic' => [
            'php_origin_jdn' => STAGE56_SAUCE_LOCAL_FOUNDATION,
            'reference_origin_jdn' => STAGE56_SAUCE_REFERENCE_FOUNDATION,
            'shift_jdn' => STAGE56_SAUCE_SHIFT,
            'translated_calculation_jdn' => STAGE56_SAUCE_CALCULATION_JDN + STAGE56_SAUCE_SHIFT,
            'translated_records' => $translatedRecords,
        ],
        'stage56_accepted' => false,
    ], JSON_THROW_ON_ERROR | JSON_UNESCAPED_SLASHES), "\n";
} catch (Throwable $e) {
    fwrite(STDERR, 'STAGE56_SAUCE_PROBE_ERROR: ' . $e->getMessage() . "\n");
    exit(2);
}
