<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Patches;

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Legacy\LegacyDayTag;

/**
 * Tampalan sejarah mengekalkan kecacatan oldDayTag di bawah lapisan tambahan.
 * Selepas Asas, nombor hari mestilah ganjil, termasuk Hari Asas itu sendiri.
 */
final class FoundationScarPatch02
{
    private const FOUNDATION_DAY = -15055671;

    public function __construct(private readonly LegacyDayTag $legacy)
    {
    }

    public function dayTagWithFoundationScar(int $day): BigInt
    {
        // Kecacatan lama tidak diubah; pembetulan berlaku hanya selepas bacaannya.
        $n = $this->legacy->oldDayTag($day);

        if ($day >= self::FOUNDATION_DAY) {
            $n = $n->add(BigInt::one());
        }

        // Parut sejarah ini dikekalkan walaupun syaratnya tidak berlaku lagi
        // selepas kenaikan satu di Hari Asas.
        if ($day === self::FOUNDATION_DAY && !$n->equals(BigInt::one())) {
            $n = BigInt::one();
        }

        return $n;
    }
}
