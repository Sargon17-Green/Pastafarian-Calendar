<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Oracle;

use Pastafari\Stage01\BigInt;

use RuntimeException;

final class NormativeSauce
{
    private const W = 'w';
    private const B = 'b';
    private const S = 's';
    private const M = 'm';
    private const R = 'r';

    /** @var array<int,array{w:BigInt,b:BigInt,s:BigInt,m:BigInt,r:BigInt}>|null */
    private ?array $stones = null;

    /** @return array<int,array{w:BigInt,b:BigInt,s:BigInt,m:BigInt,r:BigInt}> */
    public function buildStones(): array
    {
        if ($this->stones !== null) {
            return $this->stones;
        }
        $table = [];
        $table[1] = [
            self::W => BigInt::fromInt(17),
            self::B => BigInt::fromInt(29),
            self::S => BigInt::fromInt(43),
            self::M => BigInt::fromInt(71),
            self::R => BigInt::fromInt(101),
        ];
        for ($i = 2; $i <= 46; $i++) {
            $old = $table[$i - 1];
            $table[$i] = [
                self::W => NormativeMath::save($old[self::W]->square()->add($old[self::B]->mulSmall(3))->add(BigInt::fromInt($i))),
                self::B => NormativeMath::save($old[self::B]->square()->add($old[self::S]->mulSmall(5))->add($old[self::W])),
                self::S => NormativeMath::save($old[self::S]->square()->add($old[self::M]->mulSmall(7))->add($old[self::B])),
                self::M => NormativeMath::save($old[self::M]->square()->add($old[self::R]->mulSmall(11))->add($old[self::S])),
                self::R => NormativeMath::save($old[self::R]->square()->add($old[self::W]->mulSmall(13))->add($old[self::M])),
            ];
        }
        $this->stones = $table;
        return $table;
    }

    /** @param array{action:BigInt,target:BigInt,distance:BigInt,connection:BigInt,direction:int} $counts @param array<int,array{w:BigInt,b:BigInt,s:BigInt,m:BigInt,r:BigInt}> $stones @return array<int,BigInt> */
    public function buildHiddenDrops(array $counts, array $stones): array
    {
        $coeff = [
            1 => [3,4,6,8], 2 => [5,7,10,12], 3 => [7,10,14,16], 4 => [9,13,18,20],
            5 => [11,16,22,24], 6 => [13,19,26,28], 7 => [15,22,30,32],
        ];
        $grindKinds = [1=>self::W,2=>self::B,3=>self::S,4=>self::M,5=>self::R,6=>self::W,7=>self::B];
        $hidden = [];
        for ($k = 1; $k <= 7; $k++) {
            [$a,$b,$c,$d] = $coeff[$k];
            $x = $counts['action']
                ->add($counts['target']->mulSmall($a))
                ->add($counts['distance']->mulSmall($b))
                ->add($counts['connection']->mulSmall($c))
                ->add(BigInt::fromInt($counts['direction'] * $d));
            foreach ([self::W,self::B,self::S,self::M,self::R] as $kind) {
                $x = $x->add($stones[$k][$kind]);
            }
            $x = NormativeMath::save($x);
            for ($grind = 1; $grind <= 7; $grind++) {
                $old = $x;
                $x = NormativeMath::save(
                    $old->square()
                        ->add($old->mulSmall(3))
                        ->add($stones[$k][$grindKinds[$grind]])
                        ->add(BigInt::fromInt($grind))
                );
            }
            $hidden[$k] = $x;
        }
        return $hidden;
    }

    /** @param array{action:BigInt,target:BigInt,distance:BigInt,connection:BigInt,direction:int} $counts @param array<int,array{w:BigInt,b:BigInt,s:BigInt,m:BigInt,r:BigInt}> $stones @param array<int,BigInt> $hidden @return array<int,BigInt> */
    public function buildVisibleDrops(array $counts, array $stones, array $hidden): array
    {
        $timeline = [];
        for ($k = 1; $k <= 7; $k++) {
            $timeline[1 - $k] = $hidden[$k];
        }
        $grinds = [
            1=>[3,5,7,11,self::W], 2=>[5,7,11,13,self::B], 3=>[7,11,13,17,self::S],
            4=>[11,13,17,19,self::M], 5=>[13,17,19,23,self::R], 6=>[17,19,23,29,self::W],
            7=>[19,23,29,31,self::B], 8=>[23,29,31,37,self::S], 9=>[29,31,37,41,self::M],
            10=>[31,37,41,43,self::R], 11=>[37,41,43,47,self::W],
        ];
        for ($i = 1; $i <= 46; $i++) {
            $p1 = $timeline[$i - 1];
            $p3 = $timeline[$i - 3];
            $p7 = $timeline[$i - 7];
            $x = $stones[$i][self::W]->mul($counts['action'])
                ->add($stones[$i][self::B]->mul($counts['target']))
                ->add($stones[$i][self::S]->mul($counts['distance']))
                ->add($stones[$i][self::M]->mul($counts['connection']))
                ->add($stones[$i][self::R]->mulSmall($counts['direction']))
                ->add($p1)
                ->add($p3->mulSmall(3))
                ->add($p7->mulSmall(5))
                ->add(BigInt::fromInt($i));
            $x = NormativeMath::save($x);
            for ($g = 1; $g <= 11; $g++) {
                [$a,$b,$c,$d,$kind] = $grinds[$g];
                $old = $x;
                $x = NormativeMath::save(
                    $old->square()
                        ->add($old->mulSmall($a))
                        ->add($p1->mulSmall($b))
                        ->add($p3->mulSmall($c))
                        ->add($p7->mulSmall($d))
                        ->add($stones[$i][$kind])
                );
            }
            $timeline[$i] = $x;
        }
        $visible = [];
        for ($i = 1; $i <= 46; $i++) {
            $visible[$i] = $timeline[$i];
        }
        return $visible;
    }

    /** @return list<int> */
    public function permutationUnrank1(int $rank1): array
    {
        if ($rank1 < 1 || $rank1 > 720) {
            throw new RuntimeException('PERMUTATION_RANK');
        }
        $factorial = [0=>1,1=>1,2=>2,3=>6,4=>24,5=>120,6=>720];
        $rank0 = $rank1 - 1;
        $remaining = [1,2,3,4,5,6];
        $result = [];
        for ($slots = 6; $slots >= 1; $slots--) {
            $block = $factorial[$slots - 1];
            $q = intdiv($rank0, $block);
            $rank0 %= $block;
            $result[] = $remaining[$q];
            array_splice($remaining, $q, 1);
        }
        return $result;
    }

    /** @return list<int> */
    public function bowlOrderFromDrop(BigInt $drop): array
    {
        return $this->permutationUnrank1($drop->sub(BigInt::one())->modSmall(720) + 1);
    }

    /** @param array{action:BigInt,target:BigInt,distance:BigInt,connection:BigInt,direction:int} $counts @return array<int,BigInt> */
    public function initialBowls(array $counts): array
    {
        $prime = [1=>17,2=>19,3=>23,4=>29,5=>31,6=>37];
        $bowls = [];
        for ($id = 1; $id <= 6; $id++) {
            $s = $counts['action']
                ->add($counts['target']->mulSmall($id))
                ->add($counts['distance'])
                ->add($counts['connection'])
                ->add(BigInt::fromInt($counts['direction'] + $prime[$id] * $prime[$id]));
            $bowls[$id] = NormativeMath::save($s->square()->add(BigInt::fromInt($id)));
        }
        return $bowls;
    }

    /** @param array<int,BigInt> $bowls @param array<int,BigInt> $visible @param array<int,array{w:BigInt,b:BigInt,s:BigInt,m:BigInt,r:BigInt}> $stones @return array{0:array<int,BigInt>,1:list<int>} */
    public function applyVisibleDropsToBowls(array $bowls, array $visible, array $stones): array
    {
        $stoneByPos = [1=>self::W,2=>self::B,3=>self::S,4=>self::M,5=>self::R,6=>self::W];
        $orderAt46 = [];
        for ($i = 1; $i <= 46; $i++) {
            $drop = $visible[$i];
            $order = $this->bowlOrderFromDrop($drop);
            $old = $bowls;
            $pour = array_fill(1, 6, BigInt::zero());
            $pour[1] = NormativeMath::save($drop->square()->add($stones[$i][self::W]->mul($old[$order[0]]))->add(BigInt::fromInt(3*$i)));
            $pour[2] = NormativeMath::save($drop->square()->add($stones[$i][self::B]->mul($old[$order[1]]))->add(BigInt::fromInt(5*$i)));
            $pour[3] = NormativeMath::save($drop->square()->add($stones[$i][self::S]->mul($old[$order[2]]))->add(BigInt::fromInt(7*$i)));
            $nextBowls = [];
            for ($position = 1; $position <= 6; $position++) {
                $id = $order[$position - 1];
                $prev = $order[NormativeMath::wrap1($position - 1, 6) - 1];
                $next = $order[NormativeMath::wrap1($position + 1, 6) - 1];
                $s = $old[$id]
                    ->add($old[$prev]->mulSmall(2))
                    ->add($old[$next]->mulSmall(3))
                    ->add($pour[$position])
                    ->add($drop)
                    ->add($stones[$i][$stoneByPos[$position]]);
                $nextBowls[$id] = NormativeMath::save(
                    $s->square()->add($old[$prev]->mul($old[$next])->mulSmall(5))->add(BigInt::fromInt($i*$position))
                );
            }
            $bowls = $nextBowls;
            if ($i === 46) {
                $orderAt46 = $order;
            }
        }
        return [$bowls, $orderAt46];
    }

    /** @param array<int,BigInt> $bowls @return array<int,BigInt> */
    public function postStir12(array $bowls): array
    {
        for ($stir = 1; $stir <= 12; $stir++) {
            $old = $bowls;
            $sum = BigInt::zero();
            for ($id = 1; $id <= 6; $id++) {
                $sum = $sum->add($old[$id]);
            }
            $saved = NormativeMath::save($sum->add(BigInt::fromInt(149*$stir)));
            $order = $this->permutationUnrank1($saved->sub(BigInt::one())->modSmall(720) + 1);
            $nextBowls = [];
            for ($position = 1; $position <= 6; $position++) {
                $id = $order[$position - 1];
                $prev = $order[NormativeMath::wrap1($position - 1, 6) - 1];
                $next = $order[NormativeMath::wrap1($position + 1, 6) - 1];
                $s = $old[$id]
                    ->add($old[$prev]->mulSmall(3))
                    ->add($old[$next]->mulSmall(5))
                    ->add($saved)
                    ->add(BigInt::fromInt($stir + $position*$position));
                $nextBowls[$id] = NormativeMath::save($s->square()->add($old[$prev]->mul($old[$next])->mulSmall(7)));
            }
            $bowls = $nextBowls;
        }
        return $bowls;
    }

    /** @return array{bowls:array<int,BigInt>,orderAtDrop46:list<int>,hidden:array<int,BigInt>,visible:array<int,BigInt>} */
    public function sauce(int $calculationDay, int $targetDay): array
    {
        $counts = NormativeMath::workCounts($calculationDay, $targetDay);
        $stones = $this->buildStones();
        $hidden = $this->buildHiddenDrops($counts, $stones);
        $visible = $this->buildVisibleDrops($counts, $stones, $hidden);
        $bowls = $this->initialBowls($counts);
        [$afterDrops, $orderAt46] = $this->applyVisibleDropsToBowls($bowls, $visible, $stones);
        return [
            'bowls' => $this->postStir12($afterDrops),
            'orderAtDrop46' => $orderAt46,
            'hidden' => $hidden,
            'visible' => $visible,
        ];
    }

    /** @param array{bowls:array<int,BigInt>,orderAtDrop46:list<int>} $sauceResult @return array{first:BigInt,step:int} */
    public function askBowl(array $sauceResult, int $queriedBowlId, int $seal): array
    {
        $order = $sauceResult['orderAtDrop46'];
        $pos = array_search($queriedBowlId, $order, true);
        if ($pos === false) {
            throw new RuntimeException('QUERY_BOWL');
        }
        $nextId = $order[($pos + 1) % 6];
        $firstBase = $sauceResult['bowls'][$queriedBowlId]->add(BigInt::fromInt($seal + 181));
        $first = NormativeMath::save(
            $firstBase->square()->add($sauceResult['bowls'][$nextId]->mulSmall(179))->add(BigInt::fromInt($seal))
        );
        $dirBase = $first->add(BigInt::fromInt($seal + 194));
        $directionNumber = NormativeMath::save(
            $dirBase->square()->add($first->mulSmall(193))->add($sauceResult['bowls'][6]->mulSmall(197))
        );
        $step = $directionNumber->modSmall(2) === 1 ? 1 : -1;
        return ['first'=>$first, 'step'=>$step];
    }

    /** @param array{first:BigInt,step:int} $stream */
    public function answerAt(array $stream, int $k): BigInt
    {
        return NormativeMath::save($stream['first']->add(BigInt::fromInt($stream['step'] * $k)));
    }

    /** @param array{first:BigInt,step:int} $stream */
    public function chooseRank(array $stream, BigInt $n): BigInt
    {
        if ($n->compare(BigInt::one()) < 0) {
            throw new RuntimeException('CHOICE_SPACE');
        }
        $m = NormativeMath::m();
        if ($n->compare($m) <= 0) {
            $limit = $m->floorDiv($n)->mul($n);
            $k = 0;
            while (true) {
                $x = $this->answerAt($stream, $k);
                if ($x->compare($limit) <= 0) {
                    return $x->sub(BigInt::one())->mod($n)->add(BigInt::one());
                }
                $k++;
            }
        }

        $places = 1;
        $space = $m;
        while ($space->compare($n) < 0) {
            $places++;
            $space = $space->mul($m);
        }
        $wide = BigInt::one();
        $weight = BigInt::one();
        for ($j = 0; $j < $places; $j++) {
            $wide = $wide->add($this->answerAt($stream, $j)->sub(BigInt::one())->mul($weight));
            $weight = $weight->mul($m);
        }
        $limit = $space->floorDiv($n)->mul($n);
        while ($wide->compare($limit) > 0) {
            $wide = $wide->sub(BigInt::one())->add(BigInt::fromInt($stream['step']))->mod($space)->add(BigInt::one());
        }
        return $wide->sub(BigInt::one())->mod($n)->add(BigInt::one());
    }
}
