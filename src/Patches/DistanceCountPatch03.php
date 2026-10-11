<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Patches;

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Legacy\LegacyDistance;

/**
 * Tampalan ketiga tidak mengubah fungsi lama: ia hanya menambah hari hujung
 * yang dahulu tertinggal daripada pengiraan jarak langkah.
 * Tiada rujukan kepada oracle, metrik atau pembolehubah keadaan global.
 */
final class DistanceCountPatch03
{
    public function __construct(private readonly LegacyDistance $legacy)
    {
    }

    public function distanceCountPatch03(int $calculationDay, int $targetDay): BigInt
    {
        $steps = $this->legacy->oldDistance($calculationDay, $targetDay);
        return $steps->add(BigInt::one());
    }
}
