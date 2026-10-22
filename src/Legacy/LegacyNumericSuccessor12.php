<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Legacy;

use InvalidArgumentException;
use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Patches\SavePatch01;

/** DISCOVERY12: jiran mangkuk disalah anggap sebagai ID angka berturutan. */
final class LegacyNumericSuccessor12
{
    public function __construct(private readonly SavePatch01 $save)
    {
    }

    /**
     * @param array{bowls:array<int,BigInt>,orderAtDrop46:list<int>} $sauce
     * @return array{first:BigInt,step:int,nextBowlId:int}
     */
    public function askWrong(array $sauce, int $queriedBowlId, int $seal): array
    {
        $order = $sauce['orderAtDrop46'] ?? null;
        $bowls = $sauce['bowls'] ?? null;
        if (!is_array($order) || !is_array($bowls)
            || array_values($order) !== $order || count($order) !== 6) {
            throw new InvalidArgumentException('NUMERIC_SUCCESSOR_SHAPE');
        }
        $sorted = $order;
        sort($sorted, SORT_NUMERIC);
        if ($sorted !== [1, 2, 3, 4, 5, 6]
            || !in_array($queriedBowlId, $order, true)) {
            throw new InvalidArgumentException('NUMERIC_SUCCESSOR_ORDER');
        }
        foreach (range(1, 6) as $id) {
            if (!isset($bowls[$id]) || !$bowls[$id] instanceof BigInt) {
                throw new InvalidArgumentException('NUMERIC_SUCCESSOR_BOWL');
            }
        }

        // Parut lama: abaikan orderAtDrop46 semasa mencari jiran.
        $nextId = ($queriedBowlId % 6) + 1;
        $base = $bowls[$queriedBowlId]->add(BigInt::fromInt($seal + 181));
        $first = $this->save->savePatch(
            $base->square()
                ->add($bowls[$nextId]->mulSmall(179))
                ->add(BigInt::fromInt($seal))
        );
        $directionBase = $first->add(BigInt::fromInt($seal + 194));
        $direction = $this->save->savePatch(
            $directionBase->square()
                ->add($first->mulSmall(193))
                ->add($bowls[6]->mulSmall(197))
        );
        return [
            'first' => $first,
            'step' => $direction->modSmall(2) === 1 ? 1 : -1,
            'nextBowlId' => $nextId,
        ];
    }
}
