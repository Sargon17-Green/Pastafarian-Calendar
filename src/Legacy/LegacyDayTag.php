<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Legacy;

use Pastafari\Stage01\BigInt;

/**
 * Andaian sejarah ini terlupa bahawa hari pada atau selepas Asas memerlukan
 * nombor ganjil. Kecacatan masih sengaja hidup pada peringkat penemuan.
 */
final class LegacyDayTag
{
    private const FOUNDATION_DAY = -15055671;

    public function oldDayTag(int $day): BigInt
    {
        // Gunakan integer tepat supaya perbezaan hari tidak melimpahi int mesin.
        $distance = BigInt::fromInt($day)->sub(BigInt::fromInt(self::FOUNDATION_DAY));
        return $distance->abs()->mulSmall(2);
    }

    public function calculateWithoutPatch(int $day): BigInt
    {
        return $this->oldDayTag($day);
    }
}
