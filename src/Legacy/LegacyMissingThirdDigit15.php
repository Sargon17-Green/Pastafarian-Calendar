<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Legacy;

use InvalidArgumentException;
use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Patches\SavePatch01;

/**
 * DISCOVERY15: untuk M^2<n<=M^3, sebuah digit ketiga wajib dibaca,
 * tetapi pengiraan sejarah berhenti setelah dua digit pertama.
 * Pembetulan sebenar hanya dibenarkan pada PATCH15 (Stage31).
 */
final class LegacyMissingThirdDigit15
{
    private readonly BigInt $modulus;
    private readonly BigInt $space;

    public function __construct(private readonly SavePatch01 $save)
    {
        $this->modulus = BigInt::fromString('170141183460469231731687303715884105727');
        $this->space = $this->modulus->square()->mul($this->modulus);
    }

    /**
     * @param array{first:BigInt,step:int} $stream
     * @return BigInt pangkat sejarah, dengan digit ketiga tercicir
     */
    public function chooseWrong(array $stream, BigInt $n): BigInt
    {
        $first = $stream['first'] ?? null;
        $step = $stream['step'] ?? null;
        if (!$first instanceof BigInt || !is_int($step) || ($step !== 1 && $step !== -1)) {
            throw new InvalidArgumentException('THIRD_DIGIT_STREAM');
        }
        if ($n->compare($this->modulus->square()) <= 0
            || $n->compare($this->space) > 0) {
            throw new InvalidArgumentException('THIRD_DIGIT_SPACE');
        }
        if ($first->compare(BigInt::one()) < 0
            || $first->compare($this->modulus) > 0) {
            throw new InvalidArgumentException('THIRD_DIGIT_FIRST');
        }

        // Jejak asal: baki awal dihitung dengan dua panggilan SAVE yang
        // benar, namun tidak pernah membaca digit ketiga pada berat M^2.
        $wide = BigInt::one();
        $weight = BigInt::one();
        for ($j = 0; $j < 2; $j++) {
            $digit = $this->save->savePatch(
                $first->add(BigInt::fromInt($j * $step))
            );
            $wide = $wide->add($digit->sub(BigInt::one())->mul($weight));
            $weight = $weight->mul($this->modulus);
        }
        // Pengiraan rejection kekal menggunakan domain tiga digit yang sah.
        $cutoff = $this->space->floorDiv($n)->mul($n);
        $delta = BigInt::fromInt($step);
        while ($wide->compare($cutoff) > 0) {
            $wide = $wide->sub(BigInt::one())
                ->add($delta)->mod($this->space)->add(BigInt::one());
        }
        return $wide->sub(BigInt::one())->mod($n)->add(BigInt::one());
    }
}
