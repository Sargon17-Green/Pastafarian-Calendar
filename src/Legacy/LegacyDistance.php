<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Legacy;

use Pastafari\Stage01\BigInt;

/**
 * Pengiraan jarak sejarah mengira langkah di antara dua hari tetapi
 * terlupa bahawa kedua-dua hujung termasuk dalam bilangan normatif.
 * Perbezaan ini sengaja belum ditampal pada Stage 6.
 */
final class LegacyDistance
{
    public function oldDistance(int $calculationDay, int $targetDay): BigInt
    {
        // Jangan menolak int mesin secara terus: hujung julat boleh melimpah.
        $action = BigInt::fromInt($calculationDay);
        $target = BigInt::fromInt($targetDay);
        return $target->sub($action)->abs();
    }

    public function calculateWithoutPatch(int $calculationDay, int $targetDay): BigInt
    {
        return $this->oldDistance($calculationDay, $targetDay);
    }
}
