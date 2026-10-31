<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Patches;

use InvalidArgumentException;
use RuntimeException;

/**
 * PATCH21: establish the physical Year5000 anchor's identity through a
 * separately trusted canonical source before PATCH20 gate-day validation.
 * The caller must NOT derive trustedYear5000 from the untrusted anchor or
 * adjacent-year callbacks. No test oracle is used by production code.
 */
final class AnchorIdentityPatch21
{
    /** @param array<string,mixed> $anchor @param callable():array $trustedYear5000 */
    private static function requireAnchorIdentity(array $anchor, callable $trustedYear5000): void
    {
        $canonical = $trustedYear5000();
        if (!is_array($canonical)) {
            throw new RuntimeException('PATCH21_CANONICAL_PROVIDER_TYPE');
        }
        foreach (['number','openGateIndex','closeGateIndex','openGateDay','closeGateDay'] as $field) {
            if (!array_key_exists($field, $canonical) || !is_int($canonical[$field])) {
                throw new InvalidArgumentException('PATCH21_CANONICAL_FIELD_' . $field);
            }
            if (!array_key_exists($field, $anchor) || !is_int($anchor[$field])) {
                throw new InvalidArgumentException('PATCH21_ANCHOR_FIELD_' . $field);
            }
        }
        if ($canonical['number'] !== 5000) {
            throw new InvalidArgumentException('PATCH21_CANONICAL_YEAR_NUMBER');
        }
        foreach (['number','openGateIndex','closeGateIndex','openGateDay','closeGateDay'] as $field) {
            if ($anchor[$field] !== $canonical[$field]) {
                throw new RuntimeException('PATCH21_ANCHOR_IDENTITY_MISMATCH_' . $field);
            }
        }
    }

    /**
     * @param array<string,mixed> $anchor
     * @param callable(array):array $nextYear
     * @param callable(array):array $previousYear
     * @param callable(int):int $gateDayByIndex
     * @param callable():array $trustedYear5000 Independent trusted canonical anchor
     * @param array<string,mixed> $legacyReport
     * @return array<string,mixed>
     */
    public function find(
        array $anchor, int $targetDay, callable $nextYear, callable $previousYear,
        callable $gateDayByIndex, callable $trustedYear5000,
        array $legacyReport, int $maxSteps = 2048
    ): array {
        self::requireAnchorIdentity($anchor, $trustedYear5000);
        return (new GateDayCoherencePatch20())->find(
            $anchor, $targetDay, $nextYear, $previousYear, $gateDayByIndex,
            $legacyReport, $maxSteps
        );
    }
}
