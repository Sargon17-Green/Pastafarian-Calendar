<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Legacy;

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Patches\FoundationScarPatch02;

/**
 * Andaian lama yang salah: jarak dua tag hari disamakan dengan jarak hari.
 * Kekalkan pengiraan tag ini sebagai parut sejarah; jangan betulkan di sini.
 */
final class LegacyDistance
{
    private FoundationScarPatch02 $tag;

    public function __construct(?FoundationScarPatch02 $tag = null)
    {
        $this->tag = $tag ?? new FoundationScarPatch02(new LegacyDayTag());
    }

    public function oldDistance(int $calculationDay, int $targetDay): BigInt
    {
        $actionTag = $this->tag->dayTagWithFoundationScar($calculationDay);
        $targetTag = $this->tag->dayTagWithFoundationScar($targetDay);
        return $actionTag->sub($targetTag)->abs();
    }

    public function calculateWithoutPatch(int $calculationDay, int $targetDay): BigInt
    {
        return $this->oldDistance($calculationDay, $targetDay);
    }
}
