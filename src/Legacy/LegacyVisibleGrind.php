<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Legacy;

use InvalidArgumentException;
use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Patches\PriorAccessPatch06;
use Pastafari\Stage01\Patches\SavePatch01;

/**
 * Jadual lama berkunci 0..10, sedangkan pembaca sejarah meminta 1..11.
 * Baris sebelas yang tiada kembali ke baris sifar: cacat lama disengajakan.
 * Pembetulan Stage 15 mesti menambah sentinel tanpa menulis semula pembaca.
 */
final class LegacyVisibleGrind
{
    /** @var array<int,array{0:int,1:int,2:int,3:int,4:string}> */
    private array $rows;

    public function __construct(
        private readonly SavePatch01 $save,
        private readonly PriorAccessPatch06 $prior,
        ?array $rows = null
    ) {
        $this->rows = $rows ?? self::legacyGrindRows();
    }

    /** @return array<int,array{0:int,1:int,2:int,3:int,4:string}> */
    public static function legacyGrindRows(): array
    {
        return [
            [3, 5, 7, 11, 'w'], [5, 7, 11, 13, 'b'],
            [7, 11, 13, 17, 's'], [11, 13, 17, 19, 'm'],
            [13, 17, 19, 23, 'r'], [17, 19, 23, 29, 'w'],
            [19, 23, 29, 31, 'b'], [23, 29, 31, 37, 's'],
            [29, 31, 37, 41, 'm'], [31, 37, 41, 43, 'r'],
            [37, 41, 43, 47, 'w'],
        ];
    }

    /** @return array{0:int,1:int,2:int,3:int,4:string} */
    public function legacyRowAt(int $grind): array
    {
        if ($grind < 1 || $grind > 11) {
            throw new InvalidArgumentException('VISIBLE_GRIND_RANGE');
        }
        // Indeks salah ini mesti kekal; Stage 15 memasukkan sentinel di 0.
        return $this->rows[$grind] ?? $this->rows[0];
    }

    /**
     * @param array{action:BigInt,target:BigInt,distance:BigInt,connection:BigInt,direction:int} $counts
     * @param array<int,array{w:BigInt,b:BigInt,s:BigInt,m:BigInt,r:BigInt}> $stones
     * @param array<int,BigInt> $backwardHidden
     * @return array<int,BigInt>
     */
    public function buildVisibleWrong(array $counts, array $stones, array $backwardHidden): array
    {
        $visible = [];
        for ($i = 1; $i <= 46; $i++) {
            $p1 = $this->prior->priorPatch($visible, $backwardHidden, $i, 1);
            $p3 = $this->prior->priorPatch($visible, $backwardHidden, $i, 3);
            $p7 = $this->prior->priorPatch($visible, $backwardHidden, $i, 7);
            $state = $stones[$i];
            $x = $state['w']->mul($counts['action'])
                ->add($state['b']->mul($counts['target']))
                ->add($state['s']->mul($counts['distance']))
                ->add($state['m']->mul($counts['connection']))
                ->add($state['r']->mulSmall($counts['direction']))
                ->add($p1)
                ->add($p3->mulSmall(3))
                ->add($p7->mulSmall(5))
                ->add(BigInt::fromInt($i));
            $x = $this->save->savePatch($x);
            for ($g = 1; $g <= 11; $g++) {
                [$a, $b, $c, $d, $kind] = $this->legacyRowAt($g);
                $old = $x;
                $x = $this->save->savePatch(
                    $old->square()
                        ->add($old->mulSmall($a))
                        ->add($p1->mulSmall($b))
                        ->add($p3->mulSmall($c))
                        ->add($p7->mulSmall($d))
                        ->add($state[$kind])
                );
            }
            $visible[$i] = $x;
        }
        return $visible;
    }
}
