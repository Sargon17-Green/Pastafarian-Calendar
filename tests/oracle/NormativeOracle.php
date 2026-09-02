<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Oracle;

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\SourceLanguageCatalog;
use RuntimeException;

final class NormativeOracle
{
    private NormativeSauce $sauce;
    /** @var array<int,int> */
    private array $gate = [0 => NormativeMath::FOUNDATION_DAY];
    private int $minGateIndex = 0;
    private int $maxGateIndex = 0;

    public function __construct()
    {
        $this->sauce = new NormativeSauce();
    }

    public function sauceEngine(): NormativeSauce
    {
        return $this->sauce;
    }

    public function positiveGateGap(int $n): int
    {
        if ($n < 1) {
            throw new RuntimeException('POSITIVE_GATE_INDEX');
        }
        $r = $this->sauce->sauce(NormativeMath::FOUNDATION_DAY, NormativeMath::FOUNDATION_DAY + $n);
        $stream = $this->sauce->askBowl($r, 1, 1);
        return 41 + $this->sauce->chooseRank($stream, BigInt::fromInt(922))->toIntExact();
    }

    public function negativeGateGap(int $n): int
    {
        if ($n < 1) {
            throw new RuntimeException('NEGATIVE_GATE_INDEX');
        }
        $r = $this->sauce->sauce(NormativeMath::FOUNDATION_DAY, NormativeMath::FOUNDATION_DAY - $n);
        $stream = $this->sauce->askBowl($r, 1, 1);
        return 41 + $this->sauce->chooseRank($stream, BigInt::fromInt(922))->toIntExact();
    }

    public function ensureGateIndex(int $k): int
    {
        if ($k > $this->maxGateIndex) {
            for ($n = $this->maxGateIndex + 1; $n <= $k; $n++) {
                $this->gate[$n] = $this->gate[$n - 1] + $this->positiveGateGap($n);
                $this->maxGateIndex = $n;
            }
        }
        if ($k < $this->minGateIndex) {
            for ($n = $this->minGateIndex - 1; $n >= $k; $n--) {
                $this->gate[$n] = $this->gate[$n + 1] - $this->negativeGateGap(abs($n));
                $this->minGateIndex = $n;
            }
        }
        return $this->gate[$k];
    }

    public function ensureGatesCover(int $lowDay, int $highDay): void
    {
        if ($lowDay > $highDay) {
            throw new RuntimeException('GATE_COVER_RANGE');
        }
        while ($this->gate[$this->minGateIndex] > $lowDay) {
            $this->ensureGateIndex($this->minGateIndex - 1);
        }
        while ($this->gate[$this->maxGateIndex] < $highDay) {
            $this->ensureGateIndex($this->maxGateIndex + 1);
        }
    }

    public function gateIndexAtOrBefore(int $day): int
    {
        $this->ensureGatesCover($day, $day);
        $lo = $this->minGateIndex;
        $hi = $this->maxGateIndex;
        while ($lo < $hi) {
            $mid = $lo + intdiv($hi - $lo + 1, 2);
            if ($this->gate[$mid] <= $day) {
                $lo = $mid;
            } else {
                $hi = $mid - 1;
            }
        }
        return $lo;
    }

    public function exactGateIndex(int $day): ?int
    {
        $i = $this->gateIndexAtOrBefore($day);
        return $this->gate[$i] === $day ? $i : null;
    }

    /** @return array{number:int,openGateIndex:int,closeGateIndex:int,openGateDay:int,closeGateDay:int} */
    public function year5000(int $calculationDay): array
    {
        $this->ensureGatesCover(
            $calculationDay - NormativeMath::YEAR_MAX_DAYS,
            $calculationDay + NormativeMath::YEAR_MAX_DAYS
        );
        $candidates = [];
        for ($i = $this->minGateIndex; $i < $this->maxGateIndex; $i++) {
            for ($j = $i + 1; $j <= $this->maxGateIndex; $j++) {
                $gaps = $j - $i;
                $length = $this->gate[$j] - $this->gate[$i];
                if ($gaps < 6 || $length < 252 || $length > NormativeMath::YEAR_MAX_DAYS) {
                    continue;
                }
                if (!($this->gate[$i] < $calculationDay && $calculationDay <= $this->gate[$j])) {
                    continue;
                }
                $candidates[] = ['i'=>$i,'j'=>$j,'length'=>$length,'open'=>$this->gate[$i]];
            }
        }
        usort($candidates, static function(array $a, array $b): int {
            $c = $a['length'] <=> $b['length'];
            return $c !== 0 ? $c : ($a['open'] <=> $b['open']);
        });
        if ($candidates === []) {
            throw new RuntimeException('YEAR5000_CANDIDATES');
        }
        $r = $this->sauce->sauce($calculationDay, $calculationDay);
        $stream = $this->sauce->askBowl($r, 1, 10);
        $rank = $this->sauce->chooseRank($stream, BigInt::fromInt(count($candidates)))->toIntExact();
        $chosen = $candidates[$rank - 1];
        return $this->makeYear(5000, $chosen['i'], $chosen['j']);
    }

    /** @param array{number:int,openGateIndex:int,closeGateIndex:int,openGateDay:int,closeGateDay:int} $known @return array{number:int,openGateIndex:int,closeGateIndex:int,openGateDay:int,closeGateDay:int} */
    public function nextYear(int $calculationDay, array $known): array
    {
        $open = $known['closeGateIndex'];
        $this->ensureGatesCover($this->gate[$open], $this->gate[$open] + NormativeMath::YEAR_MAX_DAYS);
        $rows = [];
        $seq = 0;
        for ($j = $open + 1; ; $j++) {
            $this->ensureGateIndex($j);
            $length = $this->gate[$j] - $this->gate[$open];
            if ($length > NormativeMath::YEAR_MAX_DAYS) {
                break;
            }
            if ($j - $open >= 6 && $length >= 252) {
                $rows[] = ['idx'=>$j,'length'=>$length,'seq'=>$seq++];
            }
        }
        usort($rows, static function(array $a, array $b): int {
            $c = $a['length'] <=> $b['length'];
            return $c !== 0 ? $c : ($a['seq'] <=> $b['seq']);
        });
        $r = $this->sauce->sauce($calculationDay, $this->gate[$open]);
        $stream = $this->sauce->askBowl($r, 1, 11);
        $rank = $this->sauce->chooseRank($stream, BigInt::fromInt(count($rows)))->toIntExact();
        return $this->makeYear($known['number'] + 1, $open, $rows[$rank - 1]['idx']);
    }

    /** @param array{number:int,openGateIndex:int,closeGateIndex:int,openGateDay:int,closeGateDay:int} $known @return array{number:int,openGateIndex:int,closeGateIndex:int,openGateDay:int,closeGateDay:int} */
    public function previousYear(int $calculationDay, array $known): array
    {
        $close = $known['openGateIndex'];
        $this->ensureGatesCover($this->gate[$close] - NormativeMath::YEAR_MAX_DAYS, $this->gate[$close]);
        $rows = [];
        $seq = 0;
        for ($i = $close - 1; ; $i--) {
            $this->ensureGateIndex($i);
            $length = $this->gate[$close] - $this->gate[$i];
            if ($length > NormativeMath::YEAR_MAX_DAYS) {
                break;
            }
            if ($close - $i >= 6 && $length >= 252) {
                $rows[] = ['idx'=>$i,'length'=>$length,'seq'=>$seq++];
            }
        }
        usort($rows, static function(array $a, array $b): int {
            $c = $a['length'] <=> $b['length'];
            return $c !== 0 ? $c : ($a['seq'] <=> $b['seq']);
        });
        $r = $this->sauce->sauce($calculationDay, $this->gate[$close]);
        $stream = $this->sauce->askBowl($r, 1, 12);
        $rank = $this->sauce->chooseRank($stream, BigInt::fromInt(count($rows)))->toIntExact();
        return $this->makeYear($known['number'] - 1, $rows[$rank - 1]['idx'], $close);
    }

    /** @return array{number:int,openGateIndex:int,closeGateIndex:int,openGateDay:int,closeGateDay:int} */
    private function makeYear(int $number, int $open, int $close): array
    {
        return [
            'number'=>$number,
            'openGateIndex'=>$open,
            'closeGateIndex'=>$close,
            'openGateDay'=>$this->gate[$open],
            'closeGateDay'=>$this->gate[$close],
        ];
    }

    /** @return array{number:int,openGateIndex:int,closeGateIndex:int,openGateDay:int,closeGateDay:int} */
    public function findTargetYear(int $calculationDay, int $targetDay): array
    {
        $y = $this->year5000($calculationDay);
        while ($targetDay > $y['closeGateDay']) {
            $y = $this->nextYear($calculationDay, $y);
        }
        while ($targetDay <= $y['openGateDay']) {
            $y = $this->previousYear($calculationDay, $y);
        }
        if (!($y['openGateDay'] < $targetDay && $targetDay <= $y['closeGateDay'])) {
            throw new RuntimeException('TARGET_YEAR_INTERVAL');
        }
        return $y;
    }

    /** @param array{number:int,openGateIndex:int,closeGateIndex:int,openGateDay:int,closeGateDay:int} $year */
    public function buildYearStructure(int $calculationDay, array $year): array
    {
        $r = $this->sauce->sauce($calculationDay, $year['openGateDay'] + 1);
        $gapCount = $year['closeGateIndex'] - $year['openGateIndex'];
        $cutletCandidates = [];
        for ($k = 6; $k <= 17; $k++) {
            if ($k <= $gapCount) {
                $cutletCandidates[] = $k;
            }
        }
        $stream20 = $this->sauce->askBowl($r, 2, 20);
        $cutletCountRank = $this->sauce->chooseRank($stream20, BigInt::fromInt(count($cutletCandidates)))->toIntExact();
        $cutletCount = $cutletCandidates[$cutletCountRank - 1];

        $exact = $this->exactGateIndex($calculationDay);
        $required = null;
        if ($exact !== null && $year['openGateIndex'] < $exact && $exact < $year['closeGateIndex']) {
            $required = $exact - $year['openGateIndex'];
        }
        $partitionFamily = new CutletPartitionCounter($gapCount, $cutletCount, $required);
        $stream21 = $this->sauce->askBowl($r, 2, 21);
        $partitionRank = $this->sauce->chooseRank($stream21, $partitionFamily->countAll());
        $partition = $partitionFamily->unrank1($partitionRank);

        $stream22 = $this->sauce->askBowl($r, 5, 22);
        $cutletNameSpace = NormativeMath::fallingFactorial(17, $cutletCount);
        $cutletNameRank = $this->sauce->chooseRank($stream22, $cutletNameSpace);
        $cutletNameIndices = DistinctNameFamily::unrankIndices(17, $cutletCount, $cutletNameRank);

        $cutlets = [];
        $cursor = $year['openGateIndex'];
        foreach ($partition as $idx => $part) {
            $open = $cursor;
            $close = $cursor + $part;
            $this->ensureGateIndex($open);
            $this->ensureGateIndex($close);
            $cutlets[] = [
                'canonicalIndex'=>$cutletNameIndices[$idx],
                'openGateIndex'=>$open,
                'closeGateIndex'=>$close,
                'firstDay'=>$this->gate[$open] + 1,
                'lastDay'=>$this->gate[$close],
            ];
            $cursor = $close;
        }

        $length = $year['closeGateDay'] - $year['openGateDay'];
        $minMonths = NormativeMath::ceilDivInt($length, 123);
        $maxMonths = min(47, intdiv($length, 4));
        if ($minMonths < 3 || $minMonths > $maxMonths) {
            throw new RuntimeException('MONTH_COUNT_RANGE');
        }
        $stream30 = $this->sauce->askBowl($r, 3, 30);
        $monthCountRank = $this->sauce->chooseRank($stream30, BigInt::fromInt($maxMonths - $minMonths + 1))->toIntExact();
        $monthCount = $minMonths + $monthCountRank - 1;

        $monthLengthFamily = new BoundedCompositionCounter($length, $monthCount, 4, 123);
        $stream31 = $this->sauce->askBowl($r, 3, 31);
        $monthLengthRank = $this->sauce->chooseRank($stream31, $monthLengthFamily->countAll());
        $monthLengths = $monthLengthFamily->unrank1($monthLengthRank);

        $weavingFamily = new WeavingCounter($monthLengths);
        $stream32 = $this->sauce->askBowl($r, 4, 32);
        $weaveRank = $this->sauce->chooseRank($stream32, $weavingFamily->countAll());
        $monthWeaving = $weavingFamily->unrank1($weaveRank);

        $stream33 = $this->sauce->askBowl($r, 5, 33);
        $monthNameSpace = NormativeMath::fallingFactorial(47, $monthCount);
        $monthNameRank = $this->sauce->chooseRank($stream33, $monthNameSpace);
        $monthNameIndices = DistinctNameFamily::unrankIndices(47, $monthCount, $monthNameRank);

        return [
            'cutletCount'=>$cutletCount,
            'cutletPartition'=>$partition,
            'cutletNameIndices'=>$cutletNameIndices,
            'cutlets'=>$cutlets,
            'monthCount'=>$monthCount,
            'monthLengths'=>$monthLengths,
            'monthWeaving'=>$monthWeaving,
            'monthNameIndices'=>$monthNameIndices,
        ];
    }

    /** @return array{0:int,1:string,2:int,3:string,4:int} */
    public function calendarDate(int $calculationDay, int $targetDay): array
    {
        $year = $this->findTargetYear($calculationDay, $targetDay);
        $structure = $this->buildYearStructure($calculationDay, $year);
        $chosenCutlet = null;
        foreach ($structure['cutlets'] as $cutlet) {
            if ($cutlet['firstDay'] <= $targetDay && $targetDay <= $cutlet['lastDay']) {
                $chosenCutlet = $cutlet;
                break;
            }
        }
        if ($chosenCutlet === null) {
            throw new RuntimeException('CUTLET_CONTAINMENT');
        }
        $dayInCutlet = $targetDay - $chosenCutlet['firstDay'] + 1;
        $offset = $targetDay - ($year['openGateDay'] + 1);
        $monthId = $structure['monthWeaving'][$offset];
        $dayInMonth = 0;
        for ($p = 0; $p <= $offset; $p++) {
            if ($structure['monthWeaving'][$p] === $monthId) {
                $dayInMonth++;
            }
        }
        return [
            $year['number'],
            SourceLanguageCatalog::cutletName($chosenCutlet['canonicalIndex']),
            $dayInCutlet,
            SourceLanguageCatalog::monthName($structure['monthNameIndices'][$monthId - 1]),
            $dayInMonth,
        ];
    }
}
