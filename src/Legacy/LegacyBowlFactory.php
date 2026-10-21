<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Legacy;

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Patches\SavePatch01;

/**
 * Kilang mangkuk asal, mengekalkan identiti mangkuk 1..6.
 * Bacaan posisi yang salah tidak dipulihkan dalam kelas ini.
 */
final class LegacyBowlFactory
{
    public function __construct(private readonly SavePatch01 $save)
    {
    }

    /**
     * @param array{action:BigInt,target:BigInt,distance:BigInt,connection:BigInt,direction:int} $counts
     * @return array<int,BigInt>
     */
    public function initialBowls(array $counts): array
    {
        $primes = [1 => 17, 2 => 19, 3 => 23, 4 => 29, 5 => 31, 6 => 37];
        $bowls = [];
        for ($id = 1; $id <= 6; $id++) {
            $value = $counts['action']
                ->add($counts['target']->mulSmall($id))
                ->add($counts['distance'])
                ->add($counts['connection'])
                ->add(BigInt::fromInt($counts['direction'] + $primes[$id] * $primes[$id]));
            $bowls[$id] = $this->save->savePatch(
                $value->square()->add(BigInt::fromInt($id))
            );
        }
        return $bowls;
    }
}
