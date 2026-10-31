<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Patches;

use InvalidArgumentException;
use RuntimeException;

/**
 * PATCH20: reject a year whose gate-index endpoints are not the actual days
 * of those gates. A trusted independent gate-day mapping is mandatory and
 * supplied by the caller. It MUST NOT be reconstructed from the year record.
 * PATCH19 and PATCH18 remain the production traversal and seam validators.
 */
final class GateDayCoherencePatch20
{
    /** @param array<string,mixed> $year @param callable(int):int $gateDayByIndex */
    private static function requireMappedYear(array $year, callable $gateDayByIndex): void
    {
        foreach (['open', 'close'] as $edge) {
            $indexField = $edge . 'GateIndex';
            $dayField = $edge . 'GateDay';
            if (!array_key_exists($indexField, $year) || !is_int($year[$indexField]) ||
                !array_key_exists($dayField, $year) || !is_int($year[$dayField])) {
                throw new InvalidArgumentException('PATCH20_YEAR_FIELD_' . $edge);
            }
            $day = $gateDayByIndex($year[$indexField]);
            if (!is_int($day)) {
                throw new RuntimeException('PATCH20_GATE_LOOKUP_TYPE_' . $edge);
            }
            if ($day !== $year[$dayField]) {
                throw new RuntimeException('PATCH20_GATE_DAY_MISMATCH_' . $edge);
            }
        }
        if ($year['openGateIndex'] >= $year['closeGateIndex'] ||
            $year['openGateDay'] >= $year['closeGateDay']) {
            throw new InvalidArgumentException('PATCH20_GATE_ORDER');
        }
    }

    /**
     * @param array<string,mixed> $anchor
     * @param callable(array):array $nextYear
     * @param callable(array):array $previousYear
     * @param callable(int):int $gateDayByIndex Trusted independent day-by-index source.
     * @param array<string,mixed> $legacyReport
     * @return array<string,mixed>
     */
    public function find(
        array $anchor, int $targetDay, callable $nextYear, callable $previousYear,
        callable $gateDayByIndex, array $legacyReport, int $maxSteps = 2048
    ): array {
        self::requireMappedYear($anchor, $gateDayByIndex);
        $guardedNext = static function (array $old) use ($nextYear, $gateDayByIndex): array {
            $candidate = $nextYear($old);
            if (!is_array($candidate)) {
                throw new RuntimeException('PATCH20_NEXT_PROVIDER_RESULT');
            }
            self::requireMappedYear($candidate, $gateDayByIndex);
            return $candidate;
        };
        $guardedPrevious = static function (array $old) use ($previousYear, $gateDayByIndex): array {
            $candidate = $previousYear($old);
            if (!is_array($candidate)) {
                throw new RuntimeException('PATCH20_PREVIOUS_PROVIDER_RESULT');
            }
            self::requireMappedYear($candidate, $gateDayByIndex);
            return $candidate;
        };
        return (new GateIndexContinuityPatch19())->find(
            $anchor, $targetDay, $guardedNext, $guardedPrevious, $legacyReport, $maxSteps
        );
    }
}
