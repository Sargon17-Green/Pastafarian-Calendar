<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Patches;

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Legacy\LegacyMissingFifthDigit17;

/**
 * PATCH17: pulihkan sampel kelima pada pemberat M^4.
 * Kelas Legacy Stage34 kekal tidak berubah.
 */
final class FifthDigitPatch17
{
    private readonly BigInt $modulus;
    private readonly BigInt $space;

    public function __construct(
        private readonly LegacyMissingFifthDigit17 $legacy,
        private readonly SavePatch01 $save
    ) {
        $this->modulus = BigInt::fromString('170141183460469231731687303715884105727');
        $this->space = $this->modulus->square()->square()->mul($this->modulus);
    }

    /** @param array{first:BigInt,step:int} $stream */
    public function choosePatched(array $stream, BigInt $n): BigInt
    {
        // Jalankan Legacy sebenar bagi validasi dan mengekalkan jejak salah.
        $old = $this->legacy->chooseWrong($stream, $n);
        $wide = BigInt::one();
        $weight = BigInt::one();
        for ($j = 0; $j < 5; $j++) {
            $digit = $this->save->savePatch(
                $stream['first']->add(BigInt::fromInt($j * $stream['step']))
            );
            $wide = $wide->add($digit->sub(BigInt::one())->mul($weight));
            $weight = $weight->mul($this->modulus);
        }

        $cutoff = $this->space->floorDiv($n)->mul($n);
        $step = BigInt::fromInt($stream['step']);
        while ($wide->compare($cutoff) > 0) {
            $wide = $wide->sub(BigInt::one())
                ->add($step)->mod($this->space)->add(BigInt::one());
        }
        if ($old->compare(BigInt::one()) < 0 || $old->compare($n) > 0) {
            throw new \LogicException('FIFTH_DIGIT_LEGACY_RANGE');
        }
        return $wide->sub(BigInt::one())->mod($n)->add(BigInt::one());
    }
}
