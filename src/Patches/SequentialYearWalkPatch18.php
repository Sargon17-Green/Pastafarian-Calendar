<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Patches;

use InvalidArgumentException;
use RuntimeException;
use Pastafari\Stage01\BigInt;

/**
 * PATCH18: actual consecutive-year navigation, never a /365 jump.
 * The caller supplies a verified Year5000 and real next/previous-year
 * operations. This class does NOT manufacture those years or use an oracle.
 */
final class SequentialYearWalkPatch18
{
    /** @param array<string,mixed> $year */
    private function requireYear(array $year): void
    {
        foreach (['number','openGateDay','closeGateDay'] as $key) {
            if (!isset($year[$key]) || !is_int($year[$key])) {
                throw new InvalidArgumentException('PATCH18_YEAR_FIELD_' . $key);
            }
        }
        $span = BigInt::fromInt($year['closeGateDay'])->sub(BigInt::fromInt($year['openGateDay']));
        if ($span->compare(BigInt::fromInt(252)) < 0 ||
            $span->compare(BigInt::fromInt(5778)) > 0) {
            throw new InvalidArgumentException('PATCH18_YEAR_INTERVAL');
        }
    }

    /**
     * @param array<string,mixed> $anchor A genuinely verified Year5000 record.
     * @param callable(array):array $nextYear Real adjacent-year provider.
     * @param callable(array):array $previousYear Real adjacent-year provider.
     * @param array<string,mixed> $legacyReport Raw Stage36 production result.
     * @return array{targetYearCandidate:array,legacyReport:array,steps:int,direction:string,usedLegacyOutput:bool}
     */
    public function find(
        array $anchor, int $targetDay, callable $nextYear, callable $previousYear,
        array $legacyReport, int $maxSteps = 2048
    ): array {
        $this->requireYear($anchor);
        if ($anchor['number'] !== 5000) {
            throw new InvalidArgumentException('PATCH18_ANCHOR_NUMBER');
        }
        if ($maxSteps < 0 || $maxSteps > 100000) {
            throw new InvalidArgumentException('PATCH18_STEP_BUDGET');
        }
        if (($legacyReport['anchorNumber'] ?? null) !== 5000 ||
            ($legacyReport['anchorOpenGateDay'] ?? null) !== $anchor['openGateDay'] ||
            ($legacyReport['anchorCloseGateDay'] ?? null) !== $anchor['closeGateDay'] ||
            ($legacyReport['targetDay'] ?? null) !== $targetDay ||
            ($legacyReport['usedLegacyOutput'] ?? null) !== true ||
            !isset($legacyReport['guessedYearNumber'])) {
            throw new InvalidArgumentException('PATCH18_LEGACY_PROVENANCE');
        }

        $current = $anchor;
        $steps = 0;
        $direction = 'stay';
        while (!($current['openGateDay'] < $targetDay &&
                 $targetDay <= $current['closeGateDay'])) {
            if ($steps >= $maxSteps) {
                throw new RuntimeException('PATCH18_STEP_BUDGET_EXHAUSTED');
            }
            $forward = $targetDay > $current['closeGateDay'];
            $direction = $forward ? 'forward' : 'backward';
            $old = $current;
            if (($forward && $old['number'] === PHP_INT_MAX) ||
                (!$forward && $old['number'] === PHP_INT_MIN)) {
                throw new RuntimeException('PATCH18_YEAR_NUMBER_OVERFLOW');
            }
            $candidate = $forward ? $nextYear($old) : $previousYear($old);
            if (!is_array($candidate)) {
                throw new RuntimeException('PATCH18_PROVIDER_RESULT');
            }
            $this->requireYear($candidate);
            if ($forward) {
                if ($candidate['number'] !== $old['number'] + 1 ||
                    $candidate['openGateDay'] !== $old['closeGateDay']) {
                    throw new RuntimeException('PATCH18_NEXT_NOT_ADJACENT');
                }
            } else {
                if ($candidate['number'] !== $old['number'] - 1 ||
                    $candidate['closeGateDay'] !== $old['openGateDay']) {
                    throw new RuntimeException('PATCH18_PREVIOUS_NOT_ADJACENT');
                }
            }
            $current = $candidate;
            $steps++;
        }
        return [
            'targetYearCandidate' => $current,
            'legacyReport' => $legacyReport,
            'steps' => $steps,
            'direction' => $direction,
            'usedLegacyOutput' => false,
        ];
    }
}
