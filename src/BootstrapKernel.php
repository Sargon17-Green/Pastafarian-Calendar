<?php
declare(strict_types=1);

namespace Pastafari\Stage01;

final class BootstrapKernel
{
    private BootstrapDispatcher $dispatcher;
    private BootstrapValidator $validator;
    private BootstrapErrorBoundary $boundary;
    private MetricsShell $metrics;

    public function __construct()
    {
        $this->dispatcher = new BootstrapDispatcher();
        $this->validator = new BootstrapValidator();
        $this->boundary = new BootstrapErrorBoundary();
        $this->metrics = new MetricsShell();

        $this->dispatcher->register('BOOTSTRAP_VALIDATE', function(BootstrapContext $context): array {
            $this->metrics->bump($context, 'bootstrap.validation.calls');
            $this->validator->requireCatalogFrozen();
            $context->status = 'READY';
            return [
                'status' => $context->status,
                'catalogVersion' => SourceLanguageCatalog::VERSION,
                'cutletCount' => count(SourceLanguageCatalog::cutlets()),
                'monthCount' => count(SourceLanguageCatalog::months()),
            ];
        });
        $this->dispatcher->register('SAVE_LEGACY', function(BootstrapContext $context): BigInt {
            $operand = $context->semanticState['operand'] ?? null;
            if (!$operand instanceof BigInt) {
                throw new \RuntimeException('LEGACY_SAVE_OPERAND');
            }
            $legacy = new \Pastafari\Stage01\Legacy\LegacyRemainder();
            $result = $legacy->calculateWithoutPatch($operand);
            $context->semanticState['legacyResult'] = $result;
            $context->status = 'LEGACY_RETURNED';
            $this->metrics->bump($context, 'legacy.save.calls');
            return $result;
        });
        $this->dispatcher->register('SAVE_PATCH_01', function(BootstrapContext $context): BigInt {
            $operand = $context->semanticState['operand'] ?? null;
            if (!$operand instanceof BigInt) {
                throw new \RuntimeException('SAVE_PATCH_01_OPERAND');
            }
            $legacy = new \Pastafari\Stage01\Legacy\LegacyRemainder();
            $patch = new \Pastafari\Stage01\Patches\SavePatch01($legacy);
            $result = $patch->savePatch($operand);
            $context->semanticState['savePatchResult'] = $result;
            $context->status = 'PATCH_01_RETURNED';
            $this->metrics->bump($context, 'save.patch01.calls');
            return $result;
        });
        $this->dispatcher->register('DAY_TAG_LEGACY', function(BootstrapContext $context): BigInt {
            $legacy = new \Pastafari\Stage01\Legacy\LegacyDayTag();
            $result = $legacy->calculateWithoutPatch($context->targetDay);
            $context->semanticState['legacyDayTagResult'] = $result;
            $context->status = 'DAY_TAG_LEGACY_RETURNED';
            $this->metrics->bump($context, 'legacy.day_tag.calls');
            return $result;
        });
        $this->dispatcher->register('DAY_TAG_PATCH_02', function(BootstrapContext $context): BigInt {
            $legacy = new \Pastafari\Stage01\Legacy\LegacyDayTag();
            $patch = new \Pastafari\Stage01\Patches\FoundationScarPatch02($legacy);
            $result = $patch->dayTagWithFoundationScar($context->targetDay);
            $context->semanticState['correctedDayTagResult'] = $result;
            $context->status = 'DAY_TAG_PATCH_02_RETURNED';
            $this->metrics->bump($context, 'day.tag.patch02.calls');
            return $result;
        });
        $this->dispatcher->register('DISTANCE_LEGACY', function(BootstrapContext $context): BigInt {
            $legacy = new \Pastafari\Stage01\Legacy\LegacyDistance();
            $result = $legacy->calculateWithoutPatch($context->calculationDay, $context->targetDay);
            $context->semanticState['legacyDistanceResult'] = $result;
            $context->status = 'DISTANCE_LEGACY_RETURNED';
            $this->metrics->bump($context, 'legacy.distance.calls');
            return $result;
        });
        $this->dispatcher->register('DISTANCE_PATCH_03', function(BootstrapContext $context): BigInt {
            $legacy = new \Pastafari\Stage01\Legacy\LegacyDistance();
            $patch = new \Pastafari\Stage01\Patches\DistanceCountPatch03($legacy);
            $result = $patch->distanceCountPatch03($context->calculationDay, $context->targetDay);
            $context->semanticState['correctedDistanceResult'] = $result;
            $context->status = 'DISTANCE_PATCH_03_RETURNED';
            $this->metrics->bump($context, 'distance.patch03.calls');
            return $result;
        });
        $this->dispatcher->register('STONE_MUTATION_LEGACY', function(BootstrapContext $context): array {
            $legacy = new \Pastafari\Stage01\Legacy\LegacyStoneMutation(
                new \Pastafari\Stage01\Patches\SavePatch01(
                    new \Pastafari\Stage01\Legacy\LegacyRemainder()
                )
            );
            $table = $legacy->buildStonesWrong();
            $context->semanticState['legacyStoneTable'] = $table;
            $context->status = 'STONE_MUTATION_LEGACY_RETURNED';
            $this->metrics->bump($context, 'legacy.stones.builds');
            return $table;
        });
        $this->dispatcher->register('STONE_PATCH_04', function(BootstrapContext $context): array {
            $save = new \Pastafari\Stage01\Patches\SavePatch01(
                new \Pastafari\Stage01\Legacy\LegacyRemainder()
            );
            $legacy = new \Pastafari\Stage01\Legacy\LegacyStoneMutation($save);
            $patch = new \Pastafari\Stage01\Patches\StonePatch04($legacy, $save);
            $table = $patch->buildStones();
            $context->semanticState['correctedStoneTable'] = $table;
            $context->status = 'STONE_PATCH_04_RETURNED';
            $this->metrics->bump($context, 'stone.patch04.builds');
            return $table;
        });
    }

    public function probe(int $calculationDay, int $targetDay): array
    {
        $context = new BootstrapContext($calculationDay, $targetDay);
        $context->phase = 'BOOTSTRAP_VALIDATE';
        return $this->boundary->run(
            $context,
            fn(): array => $this->dispatcher->dispatch('BOOTSTRAP_VALIDATE', $context)
        );
    }
    /**
     * Laluan sah menggunakan pembetul di atas baki legacy yang masih tersedia.
     * Medan hari sifar dalam konteks tidak dibaca oleh operasi aritmetik ini.
     */
    public function save(BigInt $value): BigInt
    {
        $context = new BootstrapContext(0, 0);
        $context->phase = 'SAVE_PATCH_01';
        $context->semanticState['operand'] = $value;
        return $this->boundary->run(
            $context,
            fn(): BigInt => $this->dispatcher->dispatch('SAVE_PATCH_01', $context)
        );
    }

    /**
     * Laluan sah membalut pengiraan hari lama tanpa mengubah kecacatan asal.
     * Keadaan semantik dimiliki oleh konteks panggilan sahaja.
     */
    public function dayCount(int $day): BigInt
    {
        $context = new BootstrapContext($day, $day);
        $context->phase = 'DAY_TAG_PATCH_02';
        return $this->boundary->run(
            $context,
            fn(): BigInt => $this->dispatcher->dispatch('DAY_TAG_PATCH_02', $context)
        );
    }

    /**
     * Laluan jarak sah membalut operasi sejarah tanpa membuang kesilapan lama.
     * Konteks baharu memastikan pemilikan keadaan tidak merentas panggilan.
     */
    public function distance(int $calculationDay, int $targetDay): BigInt
    {
        $context = new BootstrapContext($calculationDay, $targetDay);
        $context->phase = 'DISTANCE_PATCH_03';
        return $this->boundary->run(
            $context,
            fn(): BigInt => $this->dispatcher->dispatch('DISTANCE_PATCH_03', $context)
        );
    }
    /**
     * Laluan batu produksi memakai snapshot di atas mutasi legacy yang kekal.
     * Setiap panggilan membina jadual dan konteks semantiknya sendiri.
     *
     * @return array<int,array{w:BigInt,b:BigInt,s:BigInt,m:BigInt,r:BigInt}>
     */
    public function stones(): array
    {
        $context = new BootstrapContext(0, 0);
        $context->phase = 'STONE_PATCH_04';
        return $this->boundary->run(
            $context,
            fn(): array => $this->dispatcher->dispatch('STONE_PATCH_04', $context)
        );
    }

}
