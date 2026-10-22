<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Legacy;

use InvalidArgumentException;
use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Patches\BowlShadowPatch10;
use Pastafari\Stage01\Patches\PermutationPatch08;
use Pastafari\Stage01\Patches\PoursAliasPatch09;
use Pastafari\Stage01\Patches\SavePatch01;

/**
 * Peringkat sejarah: susunan pada titisan ke-46 tidak dikunci.
 * Dua belas kacauan akhir menulis semula pemboleh ubah susunan yang sama.
 * Kunci berasingan hanya dibenarkan dalam Stage 23 PATCH 11.
 */
final class LegacyOverwrittenOrder11
{
    public function __construct(
        private readonly SavePatch01 $save,
        private readonly LegacyBowlFactory $factory,
        private readonly PermutationPatch08 $permutation,
        private readonly PoursAliasPatch09 $pours,
        private readonly BowlShadowPatch10 $shadow
    ) {
    }

    /**
     * @param array{action:BigInt,target:BigInt,distance:BigInt,connection:BigInt,direction:int} $counts
     * @param array<int,array{w:BigInt,b:BigInt,s:BigInt,m:BigInt,r:BigInt}> $stones
     * @param array<int,BigInt> $visible
     * @return array{bowls:array<int,BigInt>,orderAtDrop46:list<int>,postStirs:int,dropCount:int}
     */
    public function sauceWrong(array $counts, array $stones, array $visible): array
    {
        if (array_keys($visible) !== range(1, 46)
            || array_keys($stones) !== range(1, 46)) {
            throw new InvalidArgumentException('OVERWRITTEN_ORDER_SHAPE');
        }
        $bowls = $this->factory->initialBowls($counts);
        $order = [];
        for ($i = 1; $i <= 46; $i++) {
            $drop = $visible[$i];
            if (!$drop instanceof BigInt) {
                throw new InvalidArgumentException('OVERWRITTEN_ORDER_DROP');
            }
            $order = $this->permutation->permutationPatch($drop);
            $oldBowls = $bowls;
            $pour = $this->pours->patchedPours(
                $i, $drop, $stones[$i], $oldBowls, $order
            );
            $this->shadow->stirOneDropViaShadow(
                $bowls, $i, $drop, $stones[$i], $order, $pour
            );
        }

        // Di sini "order" memegang susunan titisan 46 dengan betul.
        // Tiada salinan latch: setiap kacauan selepas ini menimpanya.
        $overwritten = 0;
        for ($stir = 1; $stir <= 12; $stir++) {
            $old = $bowls;
            $sum = BigInt::zero();
            foreach (range(1, 6) as $id) {
                $sum = $sum->add($old[$id]);
            }
            $saved = $this->save->savePatch(
                $sum->add(BigInt::fromInt(149 * $stir))
            );
            $order = $this->permutation->permutationPatch($saved);
            $pending = $bowls;
            for ($position = 1; $position <= 6; $position++) {
                $id = $order[$position - 1];
                $prev = $order[($position + 4) % 6];
                $next = $order[$position % 6];
                $z = $old[$id]
                    ->add($old[$prev]->mulSmall(3))
                    ->add($old[$next]->mulSmall(5))
                    ->add($saved)
                    ->add(BigInt::fromInt($stir + $position * $position));
                $pending[$id] = $this->save->savePatch(
                    $z->square()
                        ->add($old[$prev]->mul($old[$next])->mulSmall(7))
                );
            }
            $bowls = $pending;
            $overwritten++;
        }
        // Salah: "orderAtDrop46" kini sebenarnya susunan post-stir 12.
        return [
            'bowls' => $bowls,
            'orderAtDrop46' => $order,
            'postStirs' => $overwritten,
            'dropCount' => 46,
        ];
    }
}
