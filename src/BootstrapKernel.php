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
        $this->dispatcher->register('HIDDEN_BACKWARD_LEGACY', function(BootstrapContext $context): array {
            $c = $context->calculationDay;
            $t = $context->targetDay;
            $action = $this->dayCount($c);
            $target = $this->dayCount($t);
            $distance = $this->distance($c, $t);
            $counts = [
                'action' => $action,
                'target' => $target,
                'distance' => $distance,
                'connection' => $action->add($target),
                'direction' => $t < $c ? 1 : ($t === $c ? 2 : 3),
            ];
            $save = new \Pastafari\Stage01\Patches\SavePatch01(
                new \Pastafari\Stage01\Legacy\LegacyRemainder()
            );
            $legacy = new \Pastafari\Stage01\Legacy\LegacyHiddenBackward($save);
            $stored = $legacy->buildStoredBackward($counts, $this->stones());
            $context->semanticState['hiddenBackward'] = $stored;
            $revealed = $legacy->revealWrong($stored);
            $context->status = 'HIDDEN_BACKWARD_LEGACY_RETURNED';
            $this->metrics->bump($context, 'legacy.hidden.reveals');
            return $revealed;
        });
        $this->dispatcher->register('HIDDEN_PATCH_05', function(BootstrapContext $context): array {
            $c = $context->calculationDay;
            $t = $context->targetDay;
            $action = $this->dayCount($c);
            $target = $this->dayCount($t);
            $distance = $this->distance($c, $t);
            $counts = [
                'action' => $action,
                'target' => $target,
                'distance' => $distance,
                'connection' => $action->add($target),
                'direction' => $t < $c ? 1 : ($t === $c ? 2 : 3),
            ];
            $save = new \Pastafari\Stage01\Patches\SavePatch01(
                new \Pastafari\Stage01\Legacy\LegacyRemainder()
            );
            $legacy = new \Pastafari\Stage01\Legacy\LegacyHiddenBackward($save);
            $patch = new \Pastafari\Stage01\Patches\HiddenNearnessPatch05($legacy);
            $stored = $legacy->buildStoredBackward($counts, $this->stones());
            $context->semanticState['hiddenBackward'] = $stored;
            $revealed = $patch->revealByNearness($stored);
            $context->semanticState['hiddenNearness'] = $revealed;
            $context->status = 'HIDDEN_PATCH_05_RETURNED';
            $this->metrics->bump($context, 'hidden.patch05.reveals');
            return $revealed;
        });
        $this->dispatcher->register('VISIBLE_PRIOR_LEGACY', function(BootstrapContext $context): ?BigInt {
            $visible = $context->semanticState['visibleDropStore'] ?? null;
            $i = $context->semanticState['dropIndex'] ?? null;
            $back = $context->semanticState['lookback'] ?? null;
            if (!is_array($visible) || !is_int($i) || !is_int($back)) {
                throw new \InvalidArgumentException('LEGACY_PRIOR_ARGUMENTS');
            }
            $legacy = new \Pastafari\Stage01\Legacy\LegacyVisiblePrior();
            $value = $legacy->legacyPrior($visible, $i, $back);
            $context->semanticState['legacyPriorResult'] = $value;
            $context->status = $value === null ? 'VISIBLE_PRIOR_MISSING' : 'VISIBLE_PRIOR_RETURNED';
            $this->metrics->bump($context, $value === null ? 'visible.prior.missing' : 'visible.prior.found');
            return $value;
        });
        $this->dispatcher->register('PRIOR_PATCH_06', function(BootstrapContext $context): BigInt {
            $visible = $context->semanticState['visibleDropStore'] ?? null;
            $hidden = $context->semanticState['legacyHidden'] ?? null;
            $i = $context->semanticState['dropIndex'] ?? null;
            $back = $context->semanticState['lookback'] ?? null;
            if (!is_array($visible) || !is_array($hidden) || !is_int($i) || !is_int($back)) {
                throw new \InvalidArgumentException('PRIOR_PATCH_ARGUMENTS');
            }
            $save = new \Pastafari\Stage01\Patches\SavePatch01(
                new \Pastafari\Stage01\Legacy\LegacyRemainder()
            );
            $hiddenLegacy = new \Pastafari\Stage01\Legacy\LegacyHiddenBackward($save);
            $patch05 = new \Pastafari\Stage01\Patches\HiddenNearnessPatch05($hiddenLegacy);
            $patch06 = new \Pastafari\Stage01\Patches\PriorAccessPatch06(
                new \Pastafari\Stage01\Legacy\LegacyVisiblePrior(), $patch05
            );
            $value = $patch06->priorPatch($visible, $hidden, $i, $back);
            $context->semanticState['patchedPriorResult'] = $value;
            $context->status = 'PRIOR_PATCH_06_RETURNED';
            $this->metrics->bump($context, 'prior.patch06.calls');
            return $value;
        });
        $this->dispatcher->register('VISIBLE_GRIND_LEGACY', function(BootstrapContext $context): array {
            $c = $context->calculationDay;
            $t = $context->targetDay;
            $action = $this->dayCount($c);
            $target = $this->dayCount($t);
            $counts = [
                'action' => $action,
                'target' => $target,
                'distance' => $this->distance($c, $t),
                'connection' => $action->add($target),
                'direction' => $t < $c ? 1 : ($t === $c ? 2 : 3),
            ];
            $save = new \Pastafari\Stage01\Patches\SavePatch01(
                new \Pastafari\Stage01\Legacy\LegacyRemainder()
            );
            $hiddenOld = new \Pastafari\Stage01\Legacy\LegacyHiddenBackward($save);
            $prior = new \Pastafari\Stage01\Patches\PriorAccessPatch06(
                new \Pastafari\Stage01\Legacy\LegacyVisiblePrior(),
                new \Pastafari\Stage01\Patches\HiddenNearnessPatch05($hiddenOld)
            );
            $stones = $this->stones();
            $stored = $hiddenOld->buildStoredBackward($counts, $stones);
            $legacy = new \Pastafari\Stage01\Legacy\LegacyVisibleGrind($save, $prior);
            $visible = $legacy->buildVisibleWrong($counts, $stones, $stored);
            $context->semanticState['legacyVisibleTable'] = $visible;
            $context->status = 'VISIBLE_GRIND_LEGACY_RETURNED';
            $this->metrics->bump($context, 'legacy.visible.grinds');
            return $visible;
        });
        $this->dispatcher->register('VISIBLE_GRIND_PATCH_07', function(BootstrapContext $context): array {
            $c = $context->calculationDay;
            $t = $context->targetDay;
            $action = $this->dayCount($c);
            $target = $this->dayCount($t);
            $counts = [
                'action' => $action,
                'target' => $target,
                'distance' => $this->distance($c, $t),
                'connection' => $action->add($target),
                'direction' => $t < $c ? 1 : ($t === $c ? 2 : 3),
            ];
            $save = new \Pastafari\Stage01\Patches\SavePatch01(
                new \Pastafari\Stage01\Legacy\LegacyRemainder()
            );
            $hiddenOld = new \Pastafari\Stage01\Legacy\LegacyHiddenBackward($save);
            $prior = new \Pastafari\Stage01\Patches\PriorAccessPatch06(
                new \Pastafari\Stage01\Legacy\LegacyVisiblePrior(),
                new \Pastafari\Stage01\Patches\HiddenNearnessPatch05($hiddenOld)
            );
            $stones = $this->stones();
            $stored = $hiddenOld->buildStoredBackward($counts, $stones);
            $patch = new \Pastafari\Stage01\Patches\GrindTablePatch07($save, $prior);
            $visible = $patch->buildVisible($counts, $stones, $stored);
            $context->semanticState['patchedVisibleTable'] = $visible;
            $context->status = 'VISIBLE_GRIND_PATCH_07_RETURNED';
            $this->metrics->bump($context, 'visible.grind.patch07');
            return $visible;
        });
        $this->dispatcher->register('BOWL_PERMUTATION_LEGACY', function(BootstrapContext $context): array {
            $drop = $context->semanticState['dropValue'] ?? null;
            if (!$drop instanceof BigInt) {
                throw new \InvalidArgumentException('BOWL_PERMUTATION_DROP');
            }
            $legacy = new \Pastafari\Stage01\Legacy\LegacyBowlPermutation(
                new \Pastafari\Stage01\Legacy\LegacyPermutationUnrank0()
            );
            $rank1 = $legacy->oneBasedRank($drop);
            $context->semanticState['legacyPermutationRank1'] = $rank1;
            $result = $legacy->legacyBowlOrderFromDrop($drop);
            $context->semanticState['legacyBowlOrder'] = $result;
            $context->status = 'BOWL_PERMUTATION_LEGACY_RETURNED';
            $this->metrics->bump($context, 'legacy.bowl.permutation.calls');
            return $result;
        });
        $this->dispatcher->register('BOWL_PERMUTATION_PATCH_08', function(BootstrapContext $context): array {
            $drop = $context->semanticState['dropValue'] ?? null;
            if (!$drop instanceof BigInt) {
                throw new \InvalidArgumentException('BOWL_PERMUTATION_DROP');
            }
            $unrank = new \Pastafari\Stage01\Legacy\LegacyPermutationUnrank0();
            $legacy = new \Pastafari\Stage01\Legacy\LegacyBowlPermutation($unrank);
            $patch = new \Pastafari\Stage01\Patches\PermutationPatch08($legacy, $unrank);
            $order = $patch->permutationPatch($drop);
            $context->semanticState['patchedBowlOrder'] = $order;
            $context->status = 'BOWL_PERMUTATION_PATCH_08_RETURNED';
            $this->metrics->bump($context, 'bowl.permutation.patch08');
            return $order;
        });
        $this->dispatcher->register('FIXED_POSITION_POURS_LEGACY', function(BootstrapContext $context): array {
            $c = $context->calculationDay;
            $t = $context->targetDay;
            $i = $context->semanticState['visibleIndex'] ?? null;
            if (!is_int($i) || $i < 1 || $i > 46) {
                throw new \InvalidArgumentException('LEGACY_POUR_INDEX_RANGE');
            }
            $visible = $this->visibleDrops($c, $t);
            $drop = $visible[$i];
            $order = $this->bowlOrder($drop);
            $action = $this->dayCount($c);
            $target = $this->dayCount($t);
            $counts = [
                'action' => $action,
                'target' => $target,
                'distance' => $this->distance($c, $t),
                'connection' => $action->add($target),
                'direction' => $t < $c ? 1 : ($t === $c ? 2 : 3),
            ];
            $save = new \Pastafari\Stage01\Patches\SavePatch01(
                new \Pastafari\Stage01\Legacy\LegacyRemainder()
            );
            $factory = new \Pastafari\Stage01\Legacy\LegacyBowlFactory($save);
            $bowls = $factory->initialBowls($counts);
            $legacy = new \Pastafari\Stage01\Legacy\LegacyFixedPositionPours($save);
            $pours = $legacy->legacyPours($i, $drop, $this->stones()[$i], $bowls, $order);
            $context->semanticState['legacyPours'] = $pours;
            $context->status = 'FIXED_POSITION_POURS_LEGACY_RETURNED';
            $this->metrics->bump($context, 'legacy.fixed.pours');
            return ['drop' => $drop, 'order' => $order, 'oldBowls' => $bowls, 'pours' => $pours];
        });
        $this->dispatcher->register('POURS_ALIAS_PATCH_09', function(BootstrapContext $context): array {
            $c = $context->calculationDay;
            $t = $context->targetDay;
            $i = $context->semanticState['visibleIndex'] ?? null;
            if (!is_int($i) || $i < 1 || $i > 46) {
                throw new \InvalidArgumentException('PATCHED_POUR_INDEX_RANGE');
            }
            $visible = $this->visibleDrops($c, $t);
            $drop = $visible[$i];
            $order = $this->bowlOrder($drop);
            $action = $this->dayCount($c);
            $target = $this->dayCount($t);
            $counts = [
                'action' => $action,
                'target' => $target,
                'distance' => $this->distance($c, $t),
                'connection' => $action->add($target),
                'direction' => $t < $c ? 1 : ($t === $c ? 2 : 3),
            ];
            $save = new \Pastafari\Stage01\Patches\SavePatch01(
                new \Pastafari\Stage01\Legacy\LegacyRemainder()
            );
            $factory = new \Pastafari\Stage01\Legacy\LegacyBowlFactory($save);
            $oldBowls = $factory->initialBowls($counts);
            $patch = new \Pastafari\Stage01\Patches\PoursAliasPatch09(
                new \Pastafari\Stage01\Legacy\LegacyFixedPositionPours($save)
            );
            $aliases = $patch->installOrderAliases($order);
            $pours = $patch->patchedPours($i, $drop, $this->stones()[$i], $oldBowls, $order);
            $context->semanticState['positionAliases'] = $aliases;
            $context->semanticState['patchedPours'] = $pours;
            $context->status = 'POURS_ALIAS_PATCH_09_RETURNED';
            $this->metrics->bump($context, 'pours.alias.patch09');
            return ['drop' => $drop, 'order' => $order, 'oldBowls' => $oldBowls,
                'aliases' => $aliases, 'pours' => $pours];
        });
        $this->dispatcher->register('IN_PLACE_BOWL_STIR_LEGACY', function(BootstrapContext $context): array {
            $i = $context->semanticState['visibleIndex'] ?? null;
            if (!is_int($i) || $i < 1 || $i > 46) {
                throw new \InvalidArgumentException('LEGACY_STIR_INDEX_RANGE');
            }
            $trace = $this->poursAt($context->calculationDay, $context->targetDay, $i);
            $save = new \Pastafari\Stage01\Patches\SavePatch01(
                new \Pastafari\Stage01\Legacy\LegacyRemainder()
            );
            $legacy = new \Pastafari\Stage01\Legacy\LegacyInPlaceBowlStir($save);
            $oldBowls = $trace['oldBowls'];
            $workingBowls = $oldBowls;
            $wrong = $legacy->stirOneDropWrong(
                $workingBowls, $i, $trace['drop'], $this->stones()[$i],
                $trace['order'], $trace['pours']
            );
            $context->semanticState['legacyStirBefore'] = $oldBowls;
            $context->semanticState['legacyStirAfter'] = $wrong;
            $context->status = 'IN_PLACE_BOWL_STIR_LEGACY_RETURNED';
            $this->metrics->bump($context, 'legacy.bowls.in_place_stirs');
            return [
                'drop' => $trace['drop'], 'order' => $trace['order'],
                'oldBowls' => $oldBowls, 'pours' => $trace['pours'],
                'wrongBowls' => $wrong,
            ];
        });
        $this->dispatcher->register('BOWL_SHADOW_PATCH_10', function(BootstrapContext $context): array {
            $i = $context->semanticState['visibleIndex'] ?? null;
            if (!is_int($i) || $i < 1 || $i > 46) {
                throw new \InvalidArgumentException('SHADOW_STIR_INDEX_RANGE');
            }
            $trace = $this->poursAt($context->calculationDay, $context->targetDay, $i);
            $save = new \Pastafari\Stage01\Patches\SavePatch01(
                new \Pastafari\Stage01\Legacy\LegacyRemainder()
            );
            $legacy = new \Pastafari\Stage01\Legacy\LegacyInPlaceBowlStir($save);
            $patch = new \Pastafari\Stage01\Patches\BowlShadowPatch10($legacy, $save);
            $before = $trace['oldBowls'];
            $working = $before;
            $fixed = $patch->stirOneDropViaShadow(
                $working, $i, $trace['drop'], $this->stones()[$i],
                $trace['order'], $trace['pours']
            );
            $context->semanticState['shadowBowlsBefore'] = $before;
            $context->semanticState['shadowBowlsAfter'] = $fixed;
            $context->status = 'BOWL_SHADOW_PATCH_10_RETURNED';
            $this->metrics->bump($context, 'bowls.shadow.patch10.stirs');
            return [
                'drop' => $trace['drop'], 'order' => $trace['order'],
                'oldBowls' => $before, 'pours' => $trace['pours'],
                'bowls' => $fixed,
            ];
        });
        $this->dispatcher->register('OVERWRITTEN_ORDER_46_LEGACY', function(BootstrapContext $context): array {
            $c = $context->calculationDay;
            $t = $context->targetDay;
            $action = $this->dayCount($c);
            $target = $this->dayCount($t);
            $counts = [
                'action' => $action,
                'target' => $target,
                'distance' => $this->distance($c, $t),
                'connection' => $action->add($target),
                'direction' => $t < $c ? 1 : ($t === $c ? 2 : 3),
            ];
            $save = new \Pastafari\Stage01\Patches\SavePatch01(
                new \Pastafari\Stage01\Legacy\LegacyRemainder()
            );
            $unrank = new \Pastafari\Stage01\Legacy\LegacyPermutationUnrank0();
            $permutation = new \Pastafari\Stage01\Patches\PermutationPatch08(
                new \Pastafari\Stage01\Legacy\LegacyBowlPermutation($unrank), $unrank
            );
            $pours = new \Pastafari\Stage01\Patches\PoursAliasPatch09(
                new \Pastafari\Stage01\Legacy\LegacyFixedPositionPours($save)
            );
            $shadow = new \Pastafari\Stage01\Patches\BowlShadowPatch10(
                new \Pastafari\Stage01\Legacy\LegacyInPlaceBowlStir($save), $save
            );
            $legacy = new \Pastafari\Stage01\Legacy\LegacyOverwrittenOrder11(
                $save,
                new \Pastafari\Stage01\Legacy\LegacyBowlFactory($save),
                $permutation, $pours, $shadow
            );
            $result = $legacy->sauceWrong($counts, $this->stones(), $this->visibleDrops($c, $t));
            $context->semanticState['overwrittenOrder'] = $result['orderAtDrop46'];
            $context->semanticState['postStirsCompleted'] = $result['postStirs'];
            $context->status = 'OVERWRITTEN_ORDER_46_LEGACY_RETURNED';
            $this->metrics->bump($context, 'legacy.order46.overwritten');
            return $result;
        });
        $this->dispatcher->register('ORDER_LATCH_PATCH_11', function(BootstrapContext $context): array {
            $c = $context->calculationDay;
            $t = $context->targetDay;
            $action = $this->dayCount($c);
            $target = $this->dayCount($t);
            $counts = [
                'action' => $action,
                'target' => $target,
                'distance' => $this->distance($c, $t),
                'connection' => $action->add($target),
                'direction' => $t < $c ? 1 : ($t === $c ? 2 : 3),
            ];
            $save = new \Pastafari\Stage01\Patches\SavePatch01(
                new \Pastafari\Stage01\Legacy\LegacyRemainder()
            );
            $unrank = new \Pastafari\Stage01\Legacy\LegacyPermutationUnrank0();
            $permutation = new \Pastafari\Stage01\Patches\PermutationPatch08(
                new \Pastafari\Stage01\Legacy\LegacyBowlPermutation($unrank), $unrank
            );
            $legacy = new \Pastafari\Stage01\Legacy\LegacyOverwrittenOrder11(
                $save,
                new \Pastafari\Stage01\Legacy\LegacyBowlFactory($save),
                $permutation,
                new \Pastafari\Stage01\Patches\PoursAliasPatch09(
                    new \Pastafari\Stage01\Legacy\LegacyFixedPositionPours($save)
                ),
                new \Pastafari\Stage01\Patches\BowlShadowPatch10(
                    new \Pastafari\Stage01\Legacy\LegacyInPlaceBowlStir($save), $save
                )
            );
            $patch = new \Pastafari\Stage01\Patches\OrderLatchPatch11(
                $legacy, $permutation
            );
            $result = $patch->sauceWithOrderLatch(
                $counts, $this->stones(), $this->visibleDrops($c, $t)
            );
            $context->semanticState['orderAtDrop46Latch'] = $result['orderAtDrop46'];
            $context->semanticState['postStirsCompleted'] = $result['postStirs'];
            $context->status = 'ORDER_LATCH_PATCH_11_RETURNED';
            $this->metrics->bump($context, 'order46.patch11.calls');
            return $result;
        });

        $this->dispatcher->register('ORDER_NEIGHBOR_PATCH_12', function(BootstrapContext $context): array {
            $id = $context->semanticState['queriedBowlId'] ?? null;
            $seal = $context->semanticState['seal'] ?? null;
            if (!is_int($id) || !is_int($seal)) {
                throw new \InvalidArgumentException('ORDER_NEIGHBOR_PATCH_12_ARGS');
            }
            $save = new \Pastafari\Stage01\Patches\SavePatch01(
                new \Pastafari\Stage01\Legacy\LegacyRemainder()
            );
            $legacy = new \Pastafari\Stage01\Legacy\LegacyNumericSuccessor12($save);
            $patch = new \Pastafari\Stage01\Patches\NextBowlOrderPatch12($legacy, $save);
            $sauce = $this->sauceOrder($context->calculationDay, $context->targetDay);
            $stream = $patch->askPatched($sauce, $id, $seal);
            $context->semanticState['correctOrderNeighbor'] = $stream['nextBowlId'];
            $context->status = 'ORDER_NEIGHBOR_PATCH_12_RETURNED';
            $this->metrics->bump($context, 'order.neighbor.patch12.requests');
            return $stream;
        });
        $this->dispatcher->register('NUMERIC_NEXT_BOWL_LEGACY', function(BootstrapContext $context): array {
            $id = $context->semanticState['queriedBowlId'] ?? null;
            $seal = $context->semanticState['seal'] ?? null;
            if (!is_int($id) || !is_int($seal)) {
                throw new \InvalidArgumentException('NUMERIC_NEXT_BOWL_ARGS');
            }
            $save = new \Pastafari\Stage01\Patches\SavePatch01(
                new \Pastafari\Stage01\Legacy\LegacyRemainder()
            );
            $legacy = new \Pastafari\Stage01\Legacy\LegacyNumericSuccessor12($save);
            $sauce = $this->sauceOrder($context->calculationDay, $context->targetDay);
            $stream = $legacy->askWrong($sauce, $id, $seal);
            $context->semanticState['numericNeighbor'] = $stream['nextBowlId'];
            $context->status = 'NUMERIC_NEXT_BOWL_LEGACY_RETURNED';
            $this->metrics->bump($context, 'legacy.numeric_neighbor.requests');
            return $stream;
        });
    }

    /**
     * Laluan sejarah yang memilih jiran nombor, bukan jiran permutasi.
     * @return array{first:BigInt,step:int,nextBowlId:int}
     */
    /**
     * Laluan produksi: jiran diambil daripada permutasi titisan 46.
     * @return array{first:BigInt,step:int,nextBowlId:int}
     */
    public function askBowl(
        int $calculationDay, int $targetDay, int $queriedBowlId, int $seal
    ): array {
        $context = new BootstrapContext($calculationDay, $targetDay);
        $context->phase = 'ORDER_NEIGHBOR_PATCH_12';
        $context->semanticState['queriedBowlId'] = $queriedBowlId;
        $context->semanticState['seal'] = $seal;
        return $this->boundary->run(
            $context,
            fn(): array => $this->dispatcher->dispatch('ORDER_NEIGHBOR_PATCH_12', $context)
        );
    }

    public function legacyAskBowl(
        int $calculationDay, int $targetDay, int $queriedBowlId, int $seal
    ): array {
        $context = new BootstrapContext($calculationDay, $targetDay);
        $context->phase = 'NUMERIC_NEXT_BOWL_LEGACY';
        $context->semanticState['queriedBowlId'] = $queriedBowlId;
        $context->semanticState['seal'] = $seal;
        return $this->boundary->run(
            $context,
            fn(): array => $this->dispatcher->dispatch('NUMERIC_NEXT_BOWL_LEGACY', $context)
        );
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

    /**
     * Akses sah menggunakan tampalan indeks 8-k ke atas stor legacy songsang.
     * Pembaca legacy yang salah kekal dapat diuji terus.
     *
     * @return array<int,BigInt>
     */
    public function hiddenDrops(int $calculationDay, int $targetDay): array
    {
        $context = new BootstrapContext($calculationDay, $targetDay);
        $context->phase = 'HIDDEN_PATCH_05';
        return $this->boundary->run(
            $context,
            fn(): array => $this->dispatcher->dispatch('HIDDEN_PATCH_05', $context)
        );
    }

    /** Pembaca sejarah; pembetulan slot hidden hanya pada Stage 13.
     * @param array<int,BigInt> $dropStore
     */
    public function priorLegacy(array $dropStore, int $i, int $back): ?BigInt
    {
        $context = new BootstrapContext(0, 0);
        $context->phase = 'VISIBLE_PRIOR_LEGACY';
        $context->semanticState['visibleDropStore'] = $dropStore;
        $context->semanticState['dropIndex'] = $i;
        $context->semanticState['lookback'] = $back;
        return $this->boundary->run(
            $context,
            fn(): ?BigInt => $this->dispatcher->dispatch('VISIBLE_PRIOR_LEGACY', $context)
        );
    }

    /**
     * Pintu masuk sah membalut pembaca sejarah dan pembetul hidden tahap 05.
     * Stor terlihat dan hidden ialah parameter per-panggilan, bukan global.
     *
     * @param array<int,BigInt> $dropStore
     * @param array<int,BigInt> $legacyHidden
     */
    public function prior(array $dropStore, array $legacyHidden, int $i, int $back): BigInt
    {
        $context = new BootstrapContext(0, 0);
        $context->phase = 'PRIOR_PATCH_06';
        $context->semanticState['visibleDropStore'] = $dropStore;
        $context->semanticState['legacyHidden'] = $legacyHidden;
        $context->semanticState['dropIndex'] = $i;
        $context->semanticState['lookback'] = $back;
        return $this->boundary->run(
            $context,
            fn(): BigInt => $this->dispatcher->dispatch('PRIOR_PATCH_06', $context)
        );
    }

    /**
     * Jalan sejarah mengekalkan cacat baris g=1..11 pada array 0..10.
     *
     * @return array<int,BigInt>
     */
    public function visibleDropsLegacy(int $calculationDay, int $targetDay): array
    {
        $context = new BootstrapContext($calculationDay, $targetDay);
        $context->phase = 'VISIBLE_GRIND_LEGACY';
        return $this->boundary->run(
            $context,
            fn(): array => $this->dispatcher->dispatch('VISIBLE_GRIND_LEGACY', $context)
        );
    }

    /**
     * Pengeluaran sah: sentinel pada indeks 0, baris benar pada 1..11.
     * Laluan sejarah masih diakses melalui visibleDropsLegacy.
     *
     * @return array<int,BigInt>
     */
    public function visibleDrops(int $calculationDay, int $targetDay): array
    {
        $context = new BootstrapContext($calculationDay, $targetDay);
        $context->phase = 'VISIBLE_GRIND_PATCH_07';
        return $this->boundary->run(
            $context,
            fn(): array => $this->dispatcher->dispatch('VISIBLE_GRIND_PATCH_07', $context)
        );
    }

    /**
     * Pintu masuk sejarah bagi pembacaan permutasi mangkuk yang salah.
     * Pembetulan pangkat satu kepada pangkat sifar hanya pada Stage 17.
     *
     * @return list<int>
     */
    public function legacyBowlOrder(BigInt $drop): array
    {
        $context = new BootstrapContext(0, 0);
        $context->phase = 'BOWL_PERMUTATION_LEGACY';
        $context->semanticState['dropValue'] = $drop;
        return $this->boundary->run(
            $context,
            fn(): array => $this->dispatcher->dispatch('BOWL_PERMUTATION_LEGACY', $context)
        );
    }

    /**
     * Susunan mangkuk yang sah dengan pemetaan ordinal 1..720 ke 0..719.
     * Laluan legacy masih wujud bagi bukti Stage 16.
     *
     * @return list<int>
     */
    public function bowlOrder(BigInt $drop): array
    {
        $context = new BootstrapContext(0, 0);
        $context->phase = 'BOWL_PERMUTATION_PATCH_08';
        $context->semanticState['dropValue'] = $drop;
        return $this->boundary->run(
            $context,
            fn(): array => $this->dispatcher->dispatch('BOWL_PERMUTATION_PATCH_08', $context)
        );
    }

    /**
     * Mendedahkan tiga tuangan sejarah yang salah untuk titisan terlihat.
     * Pembaca kekal mengenali ID tetap 1, 2 dan 3, bukan posisi dalam order.
     *
     * @return array{drop:BigInt,order:list<int>,oldBowls:array<int,BigInt>,pours:array<int,BigInt>}
     */
    public function legacyPoursAt(int $calculationDay, int $targetDay, int $i): array
    {
        $context = new BootstrapContext($calculationDay, $targetDay);
        $context->phase = 'FIXED_POSITION_POURS_LEGACY';
        $context->semanticState['visibleIndex'] = $i;
        return $this->boundary->run(
            $context,
            fn(): array => $this->dispatcher->dispatch('FIXED_POSITION_POURS_LEGACY', $context)
        );
    }

    /**
     * Tuangan tiga posisi yang benar melalui alias, sementara pembaca
     * fixed-ID asal kekal tersedia sebagai legacyPoursAt.
     *
     * @return array{drop:BigInt,order:list<int>,oldBowls:array<int,BigInt>,aliases:array<int,int>,pours:array<int,BigInt>}
     */
    public function poursAt(int $calculationDay, int $targetDay, int $i): array
    {
        $context = new BootstrapContext($calculationDay, $targetDay);
        $context->phase = 'POURS_ALIAS_PATCH_09';
        $context->semanticState['visibleIndex'] = $i;
        return $this->boundary->run(
            $context,
            fn(): array => $this->dispatcher->dispatch('POURS_ALIAS_PATCH_09', $context)
        );
    }

    /**
     * Jejak sejarah satu titisan: penulisan mangkuk dibuat sejurus selepas
     * kiraan setiap posisi. Pemisahan salinan dibenarkan hanya pada Stage21.
     *
     * @return array{drop:BigInt,order:list<int>,oldBowls:array<int,BigInt>,pours:array<int,BigInt>,wrongBowls:array<int,BigInt>}
     */
    public function legacyStirAt(int $calculationDay, int $targetDay, int $i): array
    {
        $context = new BootstrapContext($calculationDay, $targetDay);
        $context->phase = 'IN_PLACE_BOWL_STIR_LEGACY';
        $context->semanticState['visibleIndex'] = $i;
        return $this->boundary->run(
            $context,
            fn(): array => $this->dispatcher->dispatch('IN_PLACE_BOWL_STIR_LEGACY', $context)
        );
    }

    /**
     * Enam mangkuk diperbetulkan daripada snapshot satu titisan.
     * Laluan pencemaran legacy masih tersedia sebagai legacyStirAt.
     *
     * @return array{drop:BigInt,order:list<int>,oldBowls:array<int,BigInt>,pours:array<int,BigInt>,bowls:array<int,BigInt>}
     */
    public function stirAt(int $calculationDay, int $targetDay, int $i): array
    {
        $context = new BootstrapContext($calculationDay, $targetDay);
        $context->phase = 'BOWL_SHADOW_PATCH_10';
        $context->semanticState['visibleIndex'] = $i;
        return $this->boundary->run(
            $context,
            fn(): array => $this->dispatcher->dispatch('BOWL_SHADOW_PATCH_10', $context)
        );
    }

    /**
     * Laluan sejarah mengira semua mangkuk dengan betul, tetapi susunan
     * pada titisan 46 ditindih dua belas kali ketika kacauan terakhir.
     *
     * @return array{bowls:array<int,BigInt>,orderAtDrop46:list<int>,postStirs:int,dropCount:int}
     */
    public function legacySauceOrder(int $calculationDay, int $targetDay): array
    {
        $context = new BootstrapContext($calculationDay, $targetDay);
        $context->phase = 'OVERWRITTEN_ORDER_46_LEGACY';
        return $this->boundary->run(
            $context,
            fn(): array => $this->dispatcher->dispatch('OVERWRITTEN_ORDER_46_LEGACY', $context)
        );
    }

    /** @return array{bowls:array<int,BigInt>,orderAtDrop46:list<int>,postStirs:int,dropCount:int} */
    public function sauceOrder(int $calculationDay, int $targetDay): array
    {
        $context = new BootstrapContext($calculationDay, $targetDay);
        $context->phase = 'ORDER_LATCH_PATCH_11';
        return $this->boundary->run(
            $context,
            fn(): array => $this->dispatcher->dispatch('ORDER_LATCH_PATCH_11', $context)
        );
    }

}
