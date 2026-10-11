<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Patches;

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Legacy\LegacyDistance;

/**
 * Tampalan sejarah ketiga: baca jarak antara tag lama dahulu, semak arah
 * kronologi sebenar, lencongkan hanya apabila nilainya tidak sama.
 * Cabang penggantian wajib kekal sebagai parut walaupun hasil akhirnya betul.
 */
final class DistanceCountPatch03
{
    public function __construct(private readonly LegacyDistance $legacy)
    {
    }

    public function distanceCountPatch03(int $calculationDay, int $targetDay): BigInt
    {
        $distanceByTags = $this->legacy->oldDistance($calculationDay, $targetDay);
        $chronological = BigInt::fromInt($targetDay)->sub(BigInt::fromInt($calculationDay))->abs();

        if (!$distanceByTags->equals($chronological)) {
            $distanceByTags = $chronological;
        }

        return $distanceByTags->add(BigInt::one());
    }
}
