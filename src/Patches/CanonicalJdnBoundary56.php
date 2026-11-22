<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Patches;

use InvalidArgumentException;
use OutOfRangeException;
use Pastafari\Stage01\BootstrapKernel;

/**
 * Stage56 opt-in boundary between SHA-pinned external source JDNs and
 * the historical PHP coordinate system. The kernel and legacy patches retain
 * their original JDN semantics. This class DOES NOT attest source bytes:
 * callers must independently verify the external checkout and provenance.
 */
final class CanonicalJdnBoundary56
{
    public const SOURCE_COMMIT = 'cc2cf0b422757a5e7c33218ce30cffa8f99c6786';
    public const SOURCE_FOUNDATION_JDN = -13334246;
    public const PHP_FOUNDATION_JDN = -15055671;
    public const SHIFT_TO_PHP = self::PHP_FOUNDATION_JDN - self::SOURCE_FOUNDATION_JDN;

    public function __construct(private readonly BootstrapKernel $kernel)
    {
    }

    private static function requireSource(string $sourceCommit): void
    {
        if (!hash_equals(self::SOURCE_COMMIT, $sourceCommit)) {
            throw new InvalidArgumentException('STAGE56_COORDINATE_SOURCE_COMMIT');
        }
    }

    public static function toPhpJdn(int $sourceJdn, string $sourceCommit): int
    {
        self::requireSource($sourceCommit);
        // The shift is negative; reject instead of allowing int -> float overflow.
        if ($sourceJdn < PHP_INT_MIN - self::SHIFT_TO_PHP) {
            throw new OutOfRangeException('STAGE56_COORDINATE_PHP_UNDERFLOW');
        }
        return $sourceJdn + self::SHIFT_TO_PHP;
    }

    public static function toSourceJdn(int $phpJdn, string $sourceCommit): int
    {
        self::requireSource($sourceCommit);
        if ($phpJdn > PHP_INT_MAX + self::SHIFT_TO_PHP) {
            throw new OutOfRangeException('STAGE56_COORDINATE_SOURCE_OVERFLOW');
        }
        return $phpJdn - self::SHIFT_TO_PHP;
    }

    /** @return array{calculation:int,target:int} */
    public static function translatedPair(
        int $sourceCalculationJdn, int $sourceTargetJdn, string $sourceCommit
    ): array {
        return [
            'calculation' => self::toPhpJdn($sourceCalculationJdn, $sourceCommit),
            'target' => self::toPhpJdn($sourceTargetJdn, $sourceCommit),
        ];
    }

    /** Explicit external-source entrypoint; unmodified kernel remains PHP-native. */
    public function sauceOrder(
        int $sourceCalculationJdn, int $sourceTargetJdn, string $sourceCommit
    ): array {
        $pair = self::translatedPair($sourceCalculationJdn, $sourceTargetJdn, $sourceCommit);
        return $this->kernel->sauceOrder($pair['calculation'], $pair['target']);
    }

    /** Explicit external-source entrypoint; bowl IDs remain 1..6. */
    public function askBowl(
        int $sourceCalculationJdn, int $sourceTargetJdn,
        int $bowlId, int $seal, string $sourceCommit
    ): array {
        $pair = self::translatedPair($sourceCalculationJdn, $sourceTargetJdn, $sourceCommit);
        return $this->kernel->askBowl(
            $pair['calculation'], $pair['target'], $bowlId, $seal
        );
    }
}
