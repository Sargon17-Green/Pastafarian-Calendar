<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Patches;

use InvalidArgumentException;
use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Legacy\LegacyBowlPermutation;
use Pastafari\Stage01\Legacy\LegacyPermutationUnrank0;

/**
 * Tampalan kelapan mengekalkan panggilan legacy yang benar-benar salah,
 * kemudian mengguna pangkat sifar yang sah bagi susunan enam mangkuk.
 */
final class PermutationPatch08
{
    public function __construct(
        private readonly LegacyBowlPermutation $legacy,
        private readonly LegacyPermutationUnrank0 $unrank
    ) {
    }

    /** @return list<int> */
    public function permutationPatch(BigInt $drop): array
    {
        $rank1 = $this->legacy->oneBasedRank($drop);

        // Panggilan legacy diwajibkan walaupun hasilnya tersasar.
        // Pada rank1=720, pengecualian sejarah turut dicerap.
        try {
            $legacyResult = $this->legacy->legacyBowlOrderFromDrop($drop);
            if ($rank1 === 720) {
                throw new \LogicException('LEGACY_PERMUTATION_720_NOT_REJECTED');
            }
        } catch (InvalidArgumentException $error) {
            if ($rank1 !== 720
                || $error->getMessage() !== 'PERMUTATION_RANK_ZERO_RANGE') {
                throw $error;
            }
            $legacyResult = null;
        }

        // Pemetaan sah: ordinal 1..720 menjadi indeks 0..719.
        $rank0 = $rank1 - 1;
        $correct = $this->unrank->oldPermutationUnrank0($rank0);
        if ($legacyResult !== null && $legacyResult === $correct) {
            throw new \LogicException('LEGACY_PERMUTATION_UNEXPECTED_MATCH');
        }
        return $correct;
    }
}
