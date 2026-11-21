<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Patches;

use InvalidArgumentException;
use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;

/**
 * Stage56, opt-in: exact normative selection from a production bowl stream
 * for an arbitrary positive BigInt choice count (including counts > M^5).
 *
 * This is a production arithmetic component, NOT a year-structure provider
 * or an authentication of an external source/Year5000 anchor.
 * The source-backed entrypoint uses BootstrapKernel::askBowl, so the sauce
 * and drop-46 neighbor come from the existing production implementation.
 */
final class UnboundedUniformChoice56
{
    private readonly BigInt $modulus;

    public function __construct()
    {
        $this->modulus = BigInt::fromString('170141183460469231731687303715884105727');
    }

    public function chooseFromKernel(
        BootstrapKernel $kernel,
        int $calculationJdn,
        int $targetJdn,
        int $bowlId,
        int $seal,
        BigInt $count
    ): BigInt {
        if ($bowlId < 1 || $bowlId > 6 || $seal < 0) {
            throw new InvalidArgumentException('STAGE56_CHOICE_BOWL_OR_SEAL');
        }
        return $this->chooseFromStream(
            $kernel->askBowl($calculationJdn, $targetJdn, $bowlId, $seal),
            $count
        );
    }

    /**
     * @param array{first:BigInt,step:int} $stream
     * @return BigInt An exact one-based rank in 1..$count.
     */
    public function chooseFromStream(array $stream, BigInt $count): BigInt
    {
        $first = $stream['first'] ?? null;
        $step = $stream['step'] ?? null;
        if (!$first instanceof BigInt ||
            !is_int($step) || ($step !== 1 && $step !== -1) ||
            $first->compare(BigInt::one()) < 0 ||
            $first->compare($this->modulus) > 0) {
            throw new InvalidArgumentException('STAGE56_CHOICE_STREAM');
        }
        if ($count->sign() < 1) {
            throw new InvalidArgumentException('STAGE56_CHOICE_COUNT');
        }

        $space = $this->modulus;
        if ($count->compare($space) <= 0) {
            $candidate = $first;
        } else {
            // Each place uses the next response of the SAME canonical stream.
            // The first place is the least significant place, as the Scroll
            // requires; no upper digit count is presumed.
            $places = 1;
            while ($space->compare($count) < 0) {
                $space = $space->mul($this->modulus);
                ++$places;
            }
            $candidate = BigInt::one();
            $weight = BigInt::one();
            $firstMinusOne = $first->sub(BigInt::one());
            for ($i = 0; $i < $places; ++$i) {
                $digit = $firstMinusOne
                    ->add(BigInt::fromInt($i * $step))
                    ->mod($this->modulus);
                $candidate = $candidate->add($digit->mul($weight));
                $weight = $weight->mul($this->modulus);
            }
        }

        $limit = $space->floorDiv($count)->mul($count);
        if ($candidate->compare($limit) > 0) {
            // Exact O(1) rejection traversal, not a biased modulo shortcut:
            // the wide stream walks by +/-1 around the full 1..space cycle.
            // Above the acceptance limit, forward must wrap to 1; backward
            // reaches 'limit' first. No valid response is skipped.
            $candidate = $step === 1 ? BigInt::one() : $limit;
        }
        return $candidate->sub(BigInt::one())->mod($count)->add(BigInt::one());
    }
}
