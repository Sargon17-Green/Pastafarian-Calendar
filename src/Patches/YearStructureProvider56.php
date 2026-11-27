<?php
declare(strict_types=1);
namespace Pastafari\Stage01\Patches;
use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\BootstrapKernel;
use InvalidArgumentException;
use RuntimeException;
use LogicException;

/** Opt-in production PHP construction; external witness origin is not attested here. */
final class YearStructureProvider56
{
    private YearStructureSlices56 $slices;
    private MonthWeavingRanker56 $ranker;
    private UnboundedUniformChoice56 $chooser;
    private ContextualYear5000Anchor56 $binder;
    private const FIELDS=['number','openGateIndex','closeGateIndex','openGateDay','closeGateDay'];

    public function __construct(
        private readonly BootstrapKernel $kernel,
        private readonly ?string $sourceCommit = null,
        bool $fusedExperiment = false
    ) {
        // Explicit opt-in only. Reject unpinned source identity at construction.
        if ($sourceCommit !== null) {
            CanonicalJdnBoundary56::toPhpJdn(0, $sourceCommit);
        }
        $this->slices=new YearStructureSlices56();
        $this->ranker=new MonthWeavingRanker56(null, $fusedExperiment);
        $this->chooser=new UnboundedUniformChoice56();
        $this->binder=new ContextualYear5000Anchor56();
    }

    /**
     * @param callable(int):array<string,mixed> $trustedAnchor
     * @param callable(int,int):array<string,mixed> $trustedYear
     * @param callable(int):int $gateDay
     * @return array<string,mixed>
     */
    public function buildVerified(int $c,array $anchorCandidate,callable $trustedAnchor,
        array $year,callable $trustedYear,callable $gateDay,?callable $profile=null):array
    {
        $anchor=$this->binder->bind($c,$anchorCandidate,$trustedAnchor);
        if ($this->sourceCommit !== null &&
            $anchorCandidate['source_commit'] !== $this->sourceCommit) {
            throw new RuntimeException('STAGE56_PROVIDER_SOURCE_CONTEXT');
        }
        $this->validateYear($year);
        $trusted=$trustedYear($c,$year['number']);
        if (!is_array($trusted) || ($trusted['calculation_jdn']??null)!==$c ||
            ($trusted['source_commit']??null)!==$anchorCandidate['source_commit'] ||
            !is_array($trusted['year']??null)) {
            throw new RuntimeException('STAGE56_YEAR_WITNESS_ENVELOPE');
        }
        $this->validateYear($trusted['year']);
        foreach (self::FIELDS as $key) {
            if ($year[$key]!==$trusted['year'][$key]) {
                throw new RuntimeException('STAGE56_YEAR_WITNESS_MISMATCH_'.$key);
            }
            if ($year['number']===5000 && $year[$key]!==$anchor[$key]) {
                throw new RuntimeException('STAGE56_YEAR5000_MISMATCH_'.$key);
            }
        }
        if ($year['number']===4999 &&
            ($year['closeGateIndex']!==$anchor['openGateIndex'] ||
             $year['closeGateDay']!==$anchor['openGateDay'])) {
            throw new RuntimeException('STAGE56_ADJACENT_4999_MISMATCH');
        }
        if ($year['number']===5001 &&
            ($year['openGateIndex']!==$anchor['closeGateIndex'] ||
             $year['openGateDay']!==$anchor['closeGateDay'])) {
            throw new RuntimeException('STAGE56_ADJACENT_5001_MISMATCH');
        }
        return $this->build($c,$year,$gateDay,$profile);
    }

    private function validateYear(array $y):void
    {
        foreach (self::FIELDS as $key) {
            if (!isset($y[$key]) || !is_int($y[$key])) {
                throw new InvalidArgumentException('STAGE56_YEAR_FIELD_'.$key);
            }
        }
        $g=$y['closeGateIndex']-$y['openGateIndex'];
        $d=$y['closeGateDay']-$y['openGateDay'];
        if (!is_int($g)||!is_int($d)||$g<6||$g>137||$d<252||$d>5778) {
            throw new InvalidArgumentException('STAGE56_YEAR_INTERVAL');
        }
    }

    private function readGates(array $y,callable $gateDay):array
    {
        $p=$y['openGateIndex']; $q=$y['closeGateIndex']; $positions=[];
        for ($i=$p;$i<=$q;++$i) {
            $day=$gateDay($i);
            if (!is_int($day)) throw new InvalidArgumentException('STAGE56_GATE_TYPE');
            if ($i>$p) {
                $delta=$day-$positions[$i-1];
                if (!is_int($delta)||$delta<42||$delta>963) {
                    throw new InvalidArgumentException('STAGE56_GATE_DISTANCE');
                }
            }
            $positions[$i]=$day;
        }
        if ($positions[$p]!==$y['openGateDay']||$positions[$q]!==$y['closeGateDay']) {
            throw new RuntimeException('STAGE56_GATE_ENDPOINTS');
        }
        return $positions;
    }

    /**
     * Execute a provider substage and persist timing only when a QA observer is supplied.
     */
    private function profileStage(?callable $profile,string $stage,callable $operation,
        array $metadata=[]):mixed
    {
        if ($profile===null) return $operation();
        $started=hrtime(true);
        $profile('start',$stage,$metadata);
        $status='ok';
        try {
            return $operation();
        } catch (\Throwable $e) {
            $status='error';
            throw $e;
        } finally {
            $profile('end',$stage,$metadata+[
                'seconds'=>(hrtime(true)-$started)/1e9,
                'status'=>$status
            ]);
        }
    }

    private function choice(int $c,int $t,int $bowl,int $seal,BigInt $count,
        ?callable $profile=null,string $stage='choice'):BigInt
    {
        if ($count->sign()<1) throw new LogicException('STAGE56_EMPTY_FAMILY');
        // Year/gate arithmetic remains in canonical source coordinates.
        // Only the legacy PHP bowl kernel receives translated JDNs.
        if ($this->sourceCommit !== null) {
            $pair = CanonicalJdnBoundary56::translatedPair($c, $t, $this->sourceCommit);
            $kernelC = $pair['calculation'];
            $kernelT = $pair['target'];
        } else {
            $kernelC = $c;
            $kernelT = $t;
        }
        if ($profile===null) {
            return $this->chooser->chooseFromKernel(
                $this->kernel,$kernelC,$kernelT,$bowl,$seal,$count
            );
        }
        $metadata=['bowl'=>$bowl,'seal'=>$seal,'count'=>$count->toString()];
        $started=hrtime(true);
        $profile('start',$stage,$metadata);
        try {
            $trace=$this->chooser->chooseFromKernelWithTrace(
                $this->kernel,$kernelC,$kernelT,$bowl,$seal,$count
            );
            $rank=$trace['choice'];
            $stream=$trace['stream'];
            $profile('end',$stage,$metadata+[
                'seconds'=>(hrtime(true)-$started)/1e9,
                'stream_first'=>$stream['first']->toString(),
                'stream_step'=>$stream['step'],
                'rank'=>$rank->toString(),
                'status'=>'ok'
            ]);
            return $rank;
        } catch (\Throwable $e) {
            $profile('end',$stage,$metadata+[
                'seconds'=>(hrtime(true)-$started)/1e9,
                'status'=>'error',
                'error'=>$e->getMessage()
            ]);
            throw $e;
        }
    }

    private function build(int $c,array $y,callable $gateDay,?callable $profile=null):array
    {
        $gate=$this->profileStage($profile,'read_gates',
            fn():array=>$this->readGates($y,$gateDay),['year'=>$y['number']]);
        $p=$y['openGateIndex'];$q=$y['closeGateIndex'];
        $g=$q-$p;$days=$y['closeGateDay']-$y['openGateDay'];
        $t=$y['openGateDay']+1;
        $forced=$this->profileStage($profile,'forced_cut_detection',function() use($c,$y,$gate,$p,$q):?int {
            if ($c>$y['openGateDay']&&$c<=$y['closeGateDay']) {
                for ($i=$p+1;$i<$q;++$i) {
                    if ($gate[$i]===$c) return $i-$p;
                }
            }
            return null;
        },['year'=>$y['number']]);

        $cutletCountRank=$this->choice($c,$t,2,20,
            BigInt::fromInt(min(17,$g)-5),$profile,'cutlet_count_choice');
        $k=5+$cutletCountRank->toIntExact();

        $partitionCount=$this->profileStage($profile,'cutlet_partition_count',
            fn():BigInt=>$this->slices->countCutletPartitions($g,$k,$forced),
            ['gaps'=>$g,'parts'=>$k,'required_cut'=>$forced]);
        $partitionRank=$this->choice($c,$t,2,21,$partitionCount,
            $profile,'cutlet_partition_choice');
        $partition=$this->profileStage($profile,'cutlet_partition_unrank',
            fn():array=>$this->slices->unrankCutletPartitions($g,$k,$forced,$partitionRank),
            ['gaps'=>$g,'parts'=>$k,'required_cut'=>$forced,'rank'=>$partitionRank->toString()]);

        $cutletNameCount=$this->profileStage($profile,'cutlet_name_count',
            fn():BigInt=>$this->slices->countOrderedNames(17,$k),
            ['pool'=>17,'selected'=>$k]);
        $cutletNameRank=$this->choice($c,$t,5,22,$cutletNameCount,
            $profile,'cutlet_names_choice');
        $cutletNames=$this->profileStage($profile,'cutlet_names_unrank',
            fn():array=>$this->slices->unrankOrderedNames(17,$k,$cutletNameRank),
            ['pool'=>17,'selected'=>$k,'rank'=>$cutletNameRank->toString()]);

        $cutlets=[];$cursor=$p;
        foreach ($partition as $j=>$count) {
            $old=$cursor; $cursor+=$count;
            $cutlets[]=['canonicalIndex'=>$cutletNames[$j],
                'openGateIndex'=>$old,'closeGateIndex'=>$cursor,
                'firstDay'=>$gate[$old]+1,'lastDay'=>$gate[$cursor]];
        }
        if ($cursor!==$q) throw new LogicException('STAGE56_CUTLET_COVERAGE');

        $min=intdiv($days+122,123);$max=min(47,intdiv($days,4));
        if ($min<3||$min>$max) throw new LogicException('STAGE56_MONTH_RANGE');
        $monthCountRank=$this->choice($c,$t,3,30,
            BigInt::fromInt($max-$min+1),$profile,'month_count_choice');
        $m=$min-1+$monthCountRank->toIntExact();

        $monthLengthCount=$this->profileStage($profile,'month_length_count',
            fn():BigInt=>$this->slices->countMonthLengths($days,$m),
            ['days'=>$days,'months'=>$m]);
        $monthLengthRank=$this->choice($c,$t,3,31,$monthLengthCount,
            $profile,'month_lengths_choice');
        $lengths=$this->profileStage($profile,'month_length_unrank',
            fn():array=>$this->slices->unrankMonthLengths($days,$m,$monthLengthRank),
            ['days'=>$days,'months'=>$m,'rank'=>$monthLengthRank->toString()]);

        $weaveCount=$this->profileStage($profile,'month_weaving_count',
            fn():BigInt=>$this->ranker->count($lengths),
            ['days'=>$days,'months'=>$m]);
        $weaveRank=$this->choice($c,$t,4,32,$weaveCount,
            $profile,'month_weaving_choice');
        $weave=$this->profileStage($profile,'month_weaving_unrank',
            fn():array=>$this->ranker->unrank($lengths,$weaveRank),
            ['days'=>$days,'months'=>$m,'rank'=>$weaveRank->toString()]);

        $monthNameCount=$this->profileStage($profile,'month_name_count',
            fn():BigInt=>$this->slices->countOrderedNames(47,$m),
            ['pool'=>47,'selected'=>$m]);
        $monthNameRank=$this->choice($c,$t,5,33,$monthNameCount,
            $profile,'month_names_choice');
        $monthNames=$this->profileStage($profile,'month_names_unrank',
            fn():array=>$this->slices->unrankOrderedNames(47,$m,$monthNameRank),
            ['pool'=>47,'selected'=>$m,'rank'=>$monthNameRank->toString()]);

        if (count($weave)!==$days||array_sum($lengths)!==$days) {
            throw new LogicException('STAGE56_MONTH_COVERAGE');
        }
        return ['cutletCount'=>$k,'cutletPartition'=>$partition,
            'cutletNameIndices'=>$cutletNames,'cutlets'=>$cutlets,
            'monthCount'=>$m,'monthLengths'=>$lengths,
            'monthWeaving'=>$weave,'monthNameIndices'=>$monthNames];
    }
}
