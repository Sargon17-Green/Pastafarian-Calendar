<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Patches;

use InvalidArgumentException;
use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Legacy\LegacyVisiblePrior;

/**
 * Tampalan 06: pembaca history kekal untuk slot positif.
 * Slot sifar dan negatif dialihkan ke titisan hidden menurut jarak.
 */
final class PriorAccessPatch06
{
    public function __construct(
        private readonly LegacyVisiblePrior $legacy,
        private readonly HiddenNearnessPatch05 $hidden
    ) {
    }

    /**
     * @param array<int,BigInt> $dropStore
     * @param array<int,BigInt> $legacyHidden susunan asal hidden7..hidden1
     */
    public function priorPatch(array $dropStore, array $legacyHidden, int $i, int $back): BigInt
    {
        if ($i < 1 || $i > 46) {
            throw new InvalidArgumentException('PRIOR_INDEX_RANGE');
        }
        if ($back < 1) {
            throw new InvalidArgumentException('PRIOR_BACK_RANGE');
        }
        $slot = $i - $back;
        if ($slot >= 1) {
            // Panggilan sejarah yang sebenar; tiada salinan formula.
            $historical = $this->legacy->legacyPrior($dropStore, $i, $back);
            if (!$historical instanceof BigInt) {
                throw new InvalidArgumentException('PRIOR_VISIBLE_MISSING');
            }
            return $historical;
        }

        // slot=0 -> hidden1, slot=-1 -> hidden2, ... slot=-6 -> hidden7.
        // Guna PATCH05 untuk memetakan susunan stor legacy yang terbalik.
        $k = 1 - $slot;
        return $this->hidden->hiddenByNearness($legacyHidden, $k);
    }
}
