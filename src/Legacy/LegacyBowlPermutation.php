<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Legacy;

use Pastafari\Stage01\BigInt;

/**
 * Kesilapan sejarah: pangkat satu 1..720 terus dihantar ke penyahpangkat
 * sifar 0..719. Jangan tolak satu di sini sebelum PATCH 08 Stage 17.
 */
final class LegacyBowlPermutation
{
    public function __construct(private readonly LegacyPermutationUnrank0 $unrank)
    {
    }

    public function oneBasedRank(BigInt $drop): int
    {
        // mod biasa sah untuk nilai negatif dan integer yang sangat besar.
        return $drop->sub(BigInt::one())->modSmall(720) + 1;
    }

    /** @return list<int> */
    public function legacyBowlOrderFromDrop(BigInt $drop): array
    {
        $oneBased = $this->oneBasedRank($drop);
        // Salah secara sengaja: rank0 sepatutnya oneBased-1.
        return $this->unrank->oldPermutationUnrank0($oneBased);
    }
}
