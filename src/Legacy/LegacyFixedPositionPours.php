<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Legacy;

use InvalidArgumentException;
use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Patches\SavePatch01;

/**
 * Posisi pertama, kedua dan ketiga tersalah dibaca sebagai ID mangkuk tetap.
 * Kesilapan ini mesti kekal hingga PATCH 09 memperkenalkan alias posisi.
 */
final class LegacyFixedPositionPours
{
    public function __construct(private readonly SavePatch01 $save)
    {
    }

    /**
     * @param array<int,BigInt> $oldBowls
     * @param array<int,int> $order
     * @param array{w:BigInt,b:BigInt,s:BigInt,m:BigInt,r:BigInt} $stone
     * @return array<int,BigInt>
     */
    public function legacyPours(
        int $i,
        BigInt $drop,
        array $stone,
        array $oldBowls,
        array $order
    ): array {
        if ($i < 1 || $i > 46 || count($order) !== 6
            || array_values(array_unique($order)) === []
            || array_diff([1,2,3,4,5,6], $order) !== []
            || array_diff($order, [1,2,3,4,5,6]) !== []) {
            throw new InvalidArgumentException('LEGACY_POUR_ARGUMENTS');
        }
        foreach ([1,2,3,4,5,6] as $id) {
            if (!isset($oldBowls[$id]) || !$oldBowls[$id] instanceof BigInt) {
                throw new InvalidArgumentException('LEGACY_BOWL_MISSING');
            }
        }

        $pours = [];
        $pours[1] = $this->save->savePatch(
            $drop->square()->add($stone['w']->mul($oldBowls[1]))
                ->add(BigInt::fromInt(3 * $i))
        );
        $pours[2] = $this->save->savePatch(
            $drop->square()->add($stone['b']->mul($oldBowls[2]))
                ->add(BigInt::fromInt(5 * $i))
        );
        $pours[3] = $this->save->savePatch(
            $drop->square()->add($stone['s']->mul($oldBowls[3]))
                ->add(BigInt::fromInt(7 * $i))
        );
        for ($position = 4; $position <= 6; $position++) {
            $pours[$position] = BigInt::zero();
        }
        return $pours;
    }
}
