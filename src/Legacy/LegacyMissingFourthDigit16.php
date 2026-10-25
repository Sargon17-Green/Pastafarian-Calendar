<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Legacy;

use InvalidArgumentException;
use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Patches\SavePatch01;

/**
 * DISCOVERY16: semasa ruang M^3 < n <= M^4, digit keempat
 * diabaikan. Kod pembetulan tidak dibenarkan sehingga Stage33.
 */
final class LegacyMissingFourthDigit16
{
    private readonly BigInt $modulus;
    private readonly BigInt $space;

    public function __construct(private readonly SavePatch01 $save)
    {
        $this->modulus = BigInt::fromString('170141183460469231731687303715884105727');
        $this->space = $this->modulus->square()->square();
    }

    /** @param array{first:BigInt,step:int} $stream */
    public function chooseWrong(array $stream, BigInt $n): BigInt
    {
        $first = $stream['first'] ?? null;
        $step = $stream['step'] ?? null;
        if (!$first instanceof BigInt || !is_int($step)
            || ($step !== -1 && $step !== 1)) {
            throw new InvalidArgumentException('FOURTH_DIGIT_STREAM');
        }
        if ($n->compare($this->modulus->mul($this->modulus)->mul($this->modulus)) <= 0
            || $n->compare($this->space) > 0) {
            throw new InvalidArgumentException('FOURTH_DIGIT_SPACE');
        }
        if ($first->compare(BigInt::one()) < 0
            || $first->compare($this->modulus) > 0) {
            throw new InvalidArgumentException('FOURTH_DIGIT_FIRST');
        }

        // Tiga digit diperoleh daripada SAVE yang betul, tetapi
        // digit keempat (pemberat M^3) tidak pernah dibaca.
        $wide = BigInt::one();
        $weight = BigInt::one();
        for ($j = 0; $j < 3; $j++) {
            $digit = $this->save->savePatch(
                $first->add(BigInt::fromInt($j * $step))
            );
            $wide = $wide->add($digit->sub(BigInt::one())->mul($weight));
            $weight = $weight->mul($this->modulus);
        }
        $cutoff = $this->space->floorDiv($n)->mul($n);
        $delta = BigInt::fromInt($step);
        while ($wide->compare($cutoff) > 0) {
            $wide = $wide->sub(BigInt::one())->add($delta)
                ->mod($this->space)->add(BigInt::one());
        }
        return $wide->sub(BigInt::one())->mod($n)->add(BigInt::one());
    }
}
