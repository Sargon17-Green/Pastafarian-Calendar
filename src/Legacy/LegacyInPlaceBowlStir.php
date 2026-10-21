<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Legacy;

use InvalidArgumentException;
use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Patches\SavePatch01;

/**
 * Pembacaan sejarah: mangkuk ditulis serta-merta semasa satu titisan dikacau.
 * Kedudukan berikutnya tersilap membaca mangkuk yang sudah berubah.
 * Pembetulan vault/salinan dan pending hanya dibenarkan pada Stage 21.
 */
final class LegacyInPlaceBowlStir
{
    public function __construct(private readonly SavePatch01 $save)
    {
    }

    /**
     * @param array<int,BigInt> $bowls Enam mangkuk asal; diubah terus.
     * @param array{w:BigInt,b:BigInt,s:BigInt,m:BigInt,r:BigInt} $stone
     * @param list<int> $order
     * @param array<int,BigInt> $pour
     * @return array<int,BigInt>
     */
    public function stirOneDropWrong(
        array &$bowls,
        int $i,
        BigInt $drop,
        array $stone,
        array $order,
        array $pour
    ): array {
        $sorted = $order;
        sort($sorted);
        if ($i < 1 || $i > 46 || array_keys($order) !== range(0, 5)
            || $sorted !== [1,2,3,4,5,6]) {
            throw new InvalidArgumentException('LEGACY_STIR_ARGUMENTS');
        }
        foreach (range(1, 6) as $id) {
            if (!isset($bowls[$id]) || !$bowls[$id] instanceof BigInt
                || !isset($pour[$id]) || !$pour[$id] instanceof BigInt) {
                throw new InvalidArgumentException('LEGACY_STIR_BOWL_SHAPE');
            }
        }
        foreach (['w','b','s','m','r'] as $kind) {
            if (!isset($stone[$kind]) || !$stone[$kind] instanceof BigInt) {
                throw new InvalidArgumentException('LEGACY_STIR_STONE_SHAPE');
            }
        }

        $stoneByPosition = [1=>'w',2=>'b',3=>'s',4=>'m',5=>'r',6=>'w'];
        for ($position = 1; $position <= 6; $position++) {
            $id = $order[$position - 1];
            $prev = $order[($position + 4) % 6];
            $next = $order[$position % 6];

            // Cacat sejarah: setiap bacaan datang daripada mangkuk hidup.
            // Kedudukan terdahulu mungkin sudah menukarnya dalam gelung ini.
            $s = $bowls[$id]
                ->add($bowls[$prev]->mulSmall(2))
                ->add($bowls[$next]->mulSmall(3))
                ->add($pour[$position])
                ->add($drop)
                ->add($stone[$stoneByPosition[$position]]);

            $bowls[$id] = $this->save->savePatch(
                $s->square()
                    ->add($bowls[$prev]->mul($bowls[$next])->mulSmall(5))
                    ->add(BigInt::fromInt($i * $position))
            );
        }
        return $bowls;
    }
}
