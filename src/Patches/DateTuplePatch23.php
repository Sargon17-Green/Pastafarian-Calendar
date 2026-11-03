<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Patches;

use InvalidArgumentException;
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\SourceLanguageCatalog;

/**
 * Stage55: opt-in five-component adapter.
 * Year resolution is PATCH22; structure is supplied by an independent provider.
 * This does not claim that the normative year-structure generator is implemented in production.
 */
final class DateTuplePatch23
{
    /**
     * @return array{0:int,1:string,2:int,3:string,4:int}
     */
    public function calendarDate(
        BootstrapKernel $kernel,
        int $calculationDay,
        int $targetDay,
        array $year5000Anchor,
        callable $proposedNext,
        callable $proposedPrevious,
        callable $gateDay,
        callable $trustedAnchor,
        callable $canonicalNext,
        callable $canonicalPrevious,
        callable $yearStructureProvider,
        int $maxSteps = 2048
    ): array {
        $walk = $kernel->targetYearSequentialPatch22(
            $calculationDay, $targetDay, $year5000Anchor,
            $proposedNext, $proposedPrevious, $gateDay,
            $trustedAnchor, $canonicalNext, $canonicalPrevious, $maxSteps
        );
        $year = $walk['targetYearCandidate'] ?? null;
        if (!is_array($year)) {
            throw new InvalidArgumentException('PATCH23_YEAR_RESULT');
        }
        $structure = $yearStructureProvider($year);
        if (!is_array($structure)) {
            throw new InvalidArgumentException('PATCH23_STRUCTURE_TYPE');
        }
        return $this->assemble($targetDay, $year, $structure);
    }

    /**
     * @return array{0:int,1:string,2:int,3:string,4:int}
     */
    public function assemble(int $targetDay, array $year, array $structure): array
    {
        $number = $year['number'] ?? null;
        $open = $year['openGateDay'] ?? null;
        $close = $year['closeGateDay'] ?? null;
        if (!is_int($number) || !is_int($open) || !is_int($close) ||
            $close <= $open || $close - $open < 252 ||
            $close - $open > 5778 || $targetDay <= $open || $targetDay > $close) {
            throw new InvalidArgumentException('PATCH23_YEAR_INTERVAL');
        }

        $cutlets = $structure['cutlets'] ?? null;
        $months = $structure['monthCount'] ?? null;
        $lengths = $structure['monthLengths'] ?? null;
        $weaving = $structure['monthWeaving'] ?? null;
        $names = $structure['monthNameIndices'] ?? null;
        if (!is_array($cutlets) || !array_is_list($cutlets) ||
            count($cutlets) < 6 || count($cutlets) > 17 ||
            !is_int($months) || $months < 3 || $months > 47 ||
            !is_array($lengths) || !array_is_list($lengths) ||
            !is_array($weaving) || !array_is_list($weaving) ||
            !is_array($names) || !array_is_list($names) ||
            count($lengths) !== $months || count($names) !== $months ||
            count($weaving) !== $close - $open) {
            throw new InvalidArgumentException('PATCH23_STRUCTURE_SHAPE');
        }

        $knownCutlets = SourceLanguageCatalog::cutlets();
        $knownMonths = SourceLanguageCatalog::months();
        $cursor = $open + 1;
        $cutletIds = [];
        foreach ($cutlets as $row) {
            if (!is_array($row)) {
                throw new InvalidArgumentException('PATCH23_CUTLET_ROW');
            }
            $first = $row['firstDay'] ?? null;
            $last = $row['lastDay'] ?? null;
            $id = $row['canonicalIndex'] ?? null;
            if (!is_int($first) || !is_int($last) || !is_int($id) ||
                !isset($knownCutlets[$id]) || isset($cutletIds[$id]) ||
                $first !== $cursor || $last < $first || $last > $close) {
                throw new InvalidArgumentException('PATCH23_CUTLET_PARTITION');
            }
            $cutletIds[$id] = true;
            $cursor = $last + 1;
        }
        if ($cursor !== $close + 1) {
            throw new InvalidArgumentException('PATCH23_CUTLET_COVERAGE');
        }

        $monthIds = [];
        $tallies = array_fill(1, $months, 0);
        for ($i = 0; $i < $months; ++$i) {
            $id = $names[$i];
            $length = $lengths[$i];
            if (!is_int($id) || !isset($knownMonths[$id]) ||
                isset($monthIds[$id]) || !is_int($length) ||
                $length < 4 || $length > 123) {
                throw new InvalidArgumentException('PATCH23_MONTH_METADATA');
            }
            $monthIds[$id] = true;
        }
        foreach ($weaving as $monthId) {
            if (!is_int($monthId) || $monthId < 1 || $monthId > $months) {
                throw new InvalidArgumentException('PATCH23_MONTH_WEAVING');
            }
            ++$tallies[$monthId];
        }
        for ($m = 1; $m <= $months; ++$m) {
            if ($tallies[$m] !== $lengths[$m - 1]) {
                throw new InvalidArgumentException('PATCH23_MONTH_COUNTS');
            }
        }

        // Binary search over validated disjoint cutlets, rather than oracle's scan.
        $left = 0;
        $right = count($cutlets) - 1;
        while ($left < $right) {
            $mid = intdiv($left + $right, 2);
            if ($cutlets[$mid]['lastDay'] < $targetDay) {
                $left = $mid + 1;
            } else {
                $right = $mid;
            }
        }
        $chosen = $cutlets[$left];
        if ($targetDay < $chosen['firstDay']) {
            throw new InvalidArgumentException('PATCH23_CUTLET_LOOKUP');
        }

        $offset = $targetDay - $open - 1;
        $monthId = $weaving[$offset];
        $prefix = array_count_values(array_slice($weaving, 0, $offset + 1));
        return [
            $number,
            $knownCutlets[$chosen['canonicalIndex']],
            $targetDay - $chosen['firstDay'] + 1,
            $knownMonths[$names[$monthId - 1]],
            $prefix[$monthId],
        ];
    }
}
