<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Legacy;

use InvalidArgumentException;
use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Patches\SavePatch01;

/**
 * Pengiraan lama mencemarkan setiap pengganti dengan nilai baru diubah.
 * Ia dikekalkan sebagai bukti sejarah; pembetulan menunggu Stage 9.
 */
final class LegacyStoneMutation
{
    public function __construct(private readonly SavePatch01 $save)
    {
    }

    /**
     * @param array{w:BigInt,b:BigInt,s:BigInt,m:BigInt,r:BigInt} $state
     * @return array{w:BigInt,b:BigInt,s:BigInt,m:BigInt,r:BigInt}
     */
    public function mutateStonesWrong(int $index, array &$state): array
    {
        if ($index < 2 || $index > 46) {
            throw new InvalidArgumentException('STONE_INDEX_RANGE');
        }
        if (count($state) !== 5) {
            throw new InvalidArgumentException('STONE_STATE_SHAPE');
        }
        foreach (['w', 'b', 's', 'm', 'r'] as $key) {
            if (!isset($state[$key]) || !$state[$key] instanceof BigInt) {
                throw new InvalidArgumentException('STONE_STATE_TYPE');
            }
        }

        // Kebergantungan salah adalah sengaja: setiap langkah membaca hasil baru.
        $state['w'] = $this->save->savePatch(
            $state['w']->square()->add($state['b']->mulSmall(3))->add(BigInt::fromInt($index))
        );
        $state['b'] = $this->save->savePatch(
            $state['b']->square()->add($state['s']->mulSmall(5))->add($state['w'])
        );
        $state['s'] = $this->save->savePatch(
            $state['s']->square()->add($state['m']->mulSmall(7))->add($state['b'])
        );
        $state['m'] = $this->save->savePatch(
            $state['m']->square()->add($state['r']->mulSmall(11))->add($state['s'])
        );
        $state['r'] = $this->save->savePatch(
            $state['r']->square()->add($state['w']->mulSmall(13))->add($state['m'])
        );
        return $state;
    }

    /** @return array<int,array{w:BigInt,b:BigInt,s:BigInt,m:BigInt,r:BigInt}> */
    public function buildStonesWrong(): array
    {
        $state = [
            'w' => BigInt::fromInt(17),
            'b' => BigInt::fromInt(29),
            's' => BigInt::fromInt(43),
            'm' => BigInt::fromInt(71),
            'r' => BigInt::fromInt(101),
        ];
        $table = [1 => $state];
        for ($index = 2; $index <= 46; $index++) {
            $this->mutateStonesWrong($index, $state);
            $table[$index] = $state;
        }
        return $table;
    }
}
