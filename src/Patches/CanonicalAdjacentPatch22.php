<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Patches;

use InvalidArgumentException;
use RuntimeException;

/**
 * PATCH22 opt-in: compare each proposed adjacent year with a separately
 * trusted canonical successor/predecessor. The trusted providers must be
 * independently implemented/configured by the caller; this class does not
 * manufacture a normative calendar or use the test-only oracle.
 */
final class CanonicalAdjacentPatch22
{
    /** @var list<string> */
    private const FIELDS = [
        'number', 'openGateIndex', 'closeGateIndex', 'openGateDay', 'closeGateDay'
    ];

    /**
     * @param array<string,mixed> $from
     * @param callable(array):array $proposed
     * @param callable(array):array $canonical
     * @return array<string,mixed>
     */
    private static function checkedAdjacent(
        array $from, callable $proposed, callable $canonical, string $direction
    ): array {
        $actual = $proposed($from);
        if (!is_array($actual)) {
            throw new RuntimeException('PATCH22_PROPOSED_TYPE_' . $direction);
        }
        $expected = $canonical($from);
        if (!is_array($expected)) {
            throw new RuntimeException('PATCH22_CANONICAL_TYPE_' . $direction);
        }
        foreach (self::FIELDS as $key) {
            if (!array_key_exists($key, $expected) || !is_int($expected[$key])) {
                throw new InvalidArgumentException('PATCH22_CANONICAL_FIELD_' . $direction . '_' . $key);
            }
            if (!array_key_exists($key, $actual) || !is_int($actual[$key])) {
                throw new InvalidArgumentException('PATCH22_PROPOSED_FIELD_' . $direction . '_' . $key);
            }
            if ($actual[$key] !== $expected[$key]) {
                throw new RuntimeException('PATCH22_CANONICAL_MISMATCH_' . $direction . '_' . $key);
            }
        }
        return $actual;
    }

    /**
     * Every upstream PATCH18-21 invariant is retained by delegation.
     *
     * @param array<string,mixed> $anchor
     * @param callable(array):array $nextYear
     * @param callable(array):array $previousYear
     * @param callable(int):int $gateDayByIndex
     * @param callable():array $trustedYear5000
     * @param callable(array):array $canonicalNextYear Independent trusted source
     * @param callable(array):array $canonicalPreviousYear Independent trusted source
     * @param array<string,mixed> $legacyReport
     * @return array<string,mixed>
     */
    public function find(
        array $anchor, int $targetDay, callable $nextYear, callable $previousYear,
        callable $gateDayByIndex, callable $trustedYear5000,
        callable $canonicalNextYear, callable $canonicalPreviousYear,
        array $legacyReport, int $maxSteps = 2048
    ): array {
        $guardedNext = static fn(array $old):array =>
            self::checkedAdjacent($old, $nextYear, $canonicalNextYear, 'forward');
        $guardedPrevious = static fn(array $old):array =>
            self::checkedAdjacent($old, $previousYear, $canonicalPreviousYear, 'backward');
        return (new AnchorIdentityPatch21())->find(
            $anchor, $targetDay, $guardedNext, $guardedPrevious,
            $gateDayByIndex, $trustedYear5000, $legacyReport, $maxSteps
        );
    }
}
