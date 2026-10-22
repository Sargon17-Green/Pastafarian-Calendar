<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Patches;

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Legacy\LegacyInPlaceBowlStir;

/**
 * Tampalan 10 mengekalkan panggilan mutasi sejarah yang salah.
 * Semua enam bacaan pembetulan datang daripada snapshot awal.
 */
final class BowlShadowPatch10
{
    public function __construct(
        private readonly LegacyInPlaceBowlStir $legacy,
        private readonly SavePatch01 $save
    ) {
    }

    /**
     * @param array<int,BigInt> $bowls
     * @param array{w:BigInt,b:BigInt,s:BigInt,m:BigInt,r:BigInt} $stone
     * @param list<int> $order
     * @param array<int,BigInt> $pour
     * @return array<int,BigInt>
     */
    public function stirOneDropViaShadow(
        array &$bowls, int $i, BigInt $drop,
        array $stone, array $order, array $pour
    ): array {
        // Mutasi sejarah berlaku pada salinan sebenar, bukan pemanggil.
        // Ia juga mengesahkan semua input sebelum commit pembetulan.
        $garbage = $bowls;
        $this->legacy->stirOneDropWrong(
            $garbage, $i, $drop, $stone, $order, $pour
        );

        // BigInt tidak boleh ubah, array PHP bersifat copy-on-write.
        $vaultOld = $bowls;
        $pending = $bowls;
        $stoneByPosition = [1=>'w',2=>'b',3=>'s',4=>'m',5=>'r',6=>'w'];
        for ($position = 1; $position <= 6; $position++) {
            $id = $order[$position - 1];
            $prev = $order[($position + 4) % 6];
            $next = $order[$position % 6];
            $s = $vaultOld[$id]
                ->add($vaultOld[$prev]->mulSmall(2))
                ->add($vaultOld[$next]->mulSmall(3))
                ->add($pour[$position])
                ->add($drop)
                ->add($stone[$stoneByPosition[$position]]);
            $pending[$id] = $this->save->savePatch(
                $s->square()
                    ->add($vaultOld[$prev]->mul($vaultOld[$next])->mulSmall(5))
                    ->add(BigInt::fromInt($i * $position))
            );
        }

        // Commit enam nilai sekaligus, selepas semua bacaan lama.
        $bowls = $pending;
        return $bowls;
    }
}
