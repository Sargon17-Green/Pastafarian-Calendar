<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Legacy;

use InvalidArgumentException;
use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Patches\SavePatch01;

/**
 * Stor sejarah menyimpan tujuh titisan dari yang paling jauh ke terdekat.
 * Pembaca lama menganggap slot 1 yang terdekat; salah tafsir ini sengaja
 * ditinggalkan bagi penemuan kelima.
 */
final class LegacyHiddenBackward
{
    public function __construct(private readonly SavePatch01 $save)
    {
    }

    /**
     * @param array{action:BigInt,target:BigInt,distance:BigInt,connection:BigInt,direction:int} $counts
     * @param array<int,array{w:BigInt,b:BigInt,s:BigInt,m:BigInt,r:BigInt}> $stones
     * @return array<int,BigInt>
     */
    public function buildStoredBackward(array $counts, array $stones): array
    {
        $coefficient = [
            1 => [3, 4, 6, 8],
            2 => [5, 7, 10, 12],
            3 => [7, 10, 14, 16],
            4 => [9, 13, 18, 20],
            5 => [11, 16, 22, 24],
            6 => [13, 19, 26, 28],
            7 => [15, 22, 30, 32],
        ];
        $kindForGrind = [
            1 => 'w', 2 => 'b', 3 => 's', 4 => 'm',
            5 => 'r', 6 => 'w', 7 => 'b',
        ];
        $backward = array_fill(1, 7, null);
        for ($k = 1; $k <= 7; $k++) {
            [$a, $b, $c, $d] = $coefficient[$k];
            $x = $counts['action']
                ->add($counts['target']->mulSmall($a))
                ->add($counts['distance']->mulSmall($b))
                ->add($counts['connection']->mulSmall($c))
                ->add(BigInt::fromInt($counts['direction'] * $d));
            foreach (['w', 'b', 's', 'm', 'r'] as $kind) {
                $x = $x->add($stones[$k][$kind]);
            }
            $x = $this->save->savePatch($x);
            for ($grind = 1; $grind <= 7; $grind++) {
                $old = $x;
                $x = $this->save->savePatch(
                    $old->square()
                        ->add($old->mulSmall(3))
                        ->add($stones[$k][$kindForGrind[$grind]])
                        ->add(BigInt::fromInt($grind))
                );
            }
            // Kesilapan sejarah ialah stor terbalik, bukan rumus titisan.
            $backward[8 - $k] = $x;
        }
        return $backward;
    }

    /** @param array<int,BigInt> $backward */
    public function wrongNearness(array $backward, int $k): BigInt
    {
        if ($k < 1 || $k > 7) {
            throw new InvalidArgumentException('HIDDEN_SLOT_RANGE');
        }
        if (!isset($backward[$k]) || !$backward[$k] instanceof BigInt) {
            throw new InvalidArgumentException('HIDDEN_SLOT_MISSING');
        }
        // Pembaca lama menganggap susunan terbalik itu susunan semula jadi.
        return $backward[$k];
    }

    /**
     * @param array<int,BigInt> $backward
     * @return array<int,BigInt>
     */
    public function revealWrong(array $backward): array
    {
        $revealed = [];
        for ($k = 1; $k <= 7; $k++) {
            $revealed[$k] = $this->wrongNearness($backward, $k);
        }
        return $revealed;
    }
}
