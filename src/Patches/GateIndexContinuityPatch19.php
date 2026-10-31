<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Patches;

use InvalidArgumentException;
use RuntimeException;

/**
 * PATCH19: validate physical gate-index continuity before accepting each
 * adjacent-year callback. PATCH18 remains unchanged and is delegated to.
 * The Year5000 anchor and providers must be supplied by the caller; this
 * patch does not manufacture a canonical year or import test-only oracles.
 */
final class GateIndexContinuityPatch19
{
    /** @param array<string,mixed> $year */
    private static function requireIndex(array $year, string $field): void
    {
        if (!array_key_exists($field, $year) || !is_int($year[$field])) {
            throw new InvalidArgumentException('PATCH19_INDEX_FIELD_' . $field);
        }
    }

    /**
     * @param array<string,mixed> $anchor
     * @param callable(array):array $nextYear
     * @param callable(array):array $previousYear
     * @param array<string,mixed> $legacyReport
     * @return array<string,mixed>
     */
    public function find(
        array $anchor, int $targetDay, callable $nextYear, callable $previousYear,
        array $legacyReport, int $maxSteps = 2048
    ): array {
        self::requireIndex($anchor, 'openGateIndex');
        self::requireIndex($anchor, 'closeGateIndex');

        $guardedNext = static function (array $old) use ($nextYear): array {
            self::requireIndex($old, 'closeGateIndex');
            $candidate = $nextYear($old);
            if (!is_array($candidate)) {
                throw new RuntimeException('PATCH19_NEXT_PROVIDER_RESULT');
            }
            self::requireIndex($candidate, 'openGateIndex');
            self::requireIndex($candidate, 'closeGateIndex');
            if ($candidate['openGateIndex'] !== $old['closeGateIndex']) {
                throw new RuntimeException('PATCH19_NEXT_INDEX_GAP');
            }
            return $candidate;
        };
        $guardedPrevious = static function (array $old) use ($previousYear): array {
            self::requireIndex($old, 'openGateIndex');
            $candidate = $previousYear($old);
            if (!is_array($candidate)) {
                throw new RuntimeException('PATCH19_PREVIOUS_PROVIDER_RESULT');
            }
            self::requireIndex($candidate, 'openGateIndex');
            self::requireIndex($candidate, 'closeGateIndex');
            if ($candidate['closeGateIndex'] !== $old['openGateIndex']) {
                throw new RuntimeException('PATCH19_PREVIOUS_INDEX_GAP');
            }
            return $candidate;
        };
        return (new SequentialYearWalkPatch18())->find(
            $anchor, $targetDay, $guardedNext, $guardedPrevious,
            $legacyReport, $maxSteps
        );
    }
}
