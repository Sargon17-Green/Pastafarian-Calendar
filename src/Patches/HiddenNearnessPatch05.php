<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Patches;

use InvalidArgumentException;
use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Legacy\LegacyHiddenBackward;

/**
 * Tampalan kelima membetulkan akses jarak tanpa menyusun semula stor sejarah.
 * Pembaca legacy sebenar kekal dipanggil dengan indeks 8-k.
 */
final class HiddenNearnessPatch05
{
    public function __construct(private readonly LegacyHiddenBackward $legacy)
    {
    }

    /** @param array<int,BigInt> $backward */
    public function hiddenByNearness(array $backward, int $k): BigInt
    {
        if ($k < 1 || $k > 7) {
            throw new InvalidArgumentException('HIDDEN_NEARNESS_RANGE');
        }
        // Ini pembetulan pemetaan, bukan pembalikan array atau rumus titisan.
        return $this->legacy->wrongNearness($backward, 8 - $k);
    }

    /**
     * @param array<int,BigInt> $backward
     * @return array<int,BigInt>
     */
    public function revealByNearness(array $backward): array
    {
        $near = [];
        for ($k = 1; $k <= 7; $k++) {
            $near[$k] = $this->hiddenByNearness($backward, $k);
        }
        return $near;
    }
}
