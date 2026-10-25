<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Legacy;

use InvalidArgumentException;
use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Patches\SavePatch01;

/**
 * DISCOVERY17: untuk M^4 < n <= M^5, pemilih lama membaca empat
 * digit sahaja dan terlupa sampel kelima pada pemberat M^4.
 * Pembaikan hanya dibenarkan pada Stage35 PATCH17.
 */
final class LegacyMissingFifthDigit17
{
    private readonly BigInt $modulus;
    private readonly BigInt $floorFour;
    private readonly BigInt $space;

    public function __construct(private readonly SavePatch01 $save)
    {
        $this->modulus = BigInt::fromString('170141183460469231731687303715884105727');
        $this->floorFour = $this->modulus->square()->square();
        $this->space = $this->floorFour->mul($this->modulus);
    }

    /** @param array{first:BigInt,step:int} $stream */
    public function chooseWrong(array $stream, BigInt $n): BigInt
    {
        $first = $stream['first'] ?? null;
        $step = $stream['step'] ?? null;
        if (!$first instanceof BigInt || !is_int($step)
            || ($step !== -1 && $step !== 1)) {
            throw new InvalidArgumentException('FIFTH_DIGIT_STREAM');
        }
        if ($n->compare($this->floorFour) <= 0
            || $n->compare($this->space) > 0) {
            throw new InvalidArgumentException('FIFTH_DIGIT_SPACE');
        }
        if ($first->compare(BigInt::one()) < 0
            || $first->compare($this->modulus) > 0) {
            throw new InvalidArgumentException('FIFTH_DIGIT_FIRST');
        }

        // Empat sampel SAVE dihasilkan dengan betul. Sampel kelima
        // pada pemberat M^4 sengaja tidak dibaca oleh laluan sejarah.
        $wide = BigInt::one();
        $weight = BigInt::one();
        for ($j = 0; $j < 4; $j++) {
            $digit = $this->save->savePatch(
                $first->add(BigInt::fromInt($j * $step))
            );
            $wide = $wide->add($digit->sub(BigInt::one())->mul($weight));
            $weight = $weight->mul($this->modulus);
        }

        // Had penerimaan dan rejection masih dalam ruang lima digit.
        $cutoff = $this->space->floorDiv($n)->mul($n);
        $delta = BigInt::fromInt($step);
        while ($wide->compare($cutoff) > 0) {
            $wide = $wide->sub(BigInt::one())->add($delta)
                ->mod($this->space)->add(BigInt::one());
        }
        return $wide->sub(BigInt::one())->mod($n)->add(BigInt::one());
    }
}
