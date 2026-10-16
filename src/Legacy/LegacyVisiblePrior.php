<?php
declare(strict_types=1);
namespace Pastafari\Stage01\Legacy;
use Pastafari\Stage01\BigInt;
/** Pembaca sejarah tidak mengenali indeks negatif atau sifar. */
final class LegacyVisiblePrior {
    /** @param array<int,BigInt> $dropStore */
    public function legacyPrior(array $dropStore, int $i, int $back): ?BigInt {
        return $dropStore[$i - $back] ?? null;
    }
}
