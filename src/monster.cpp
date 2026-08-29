#include "pastafari/monster.hpp"

namespace pastafari {

Integer regularMod(const Integer& x, const Integer& d) {
    if (d <= 0) {
        throw BaseValidationError("divisor positivus requiritur");
    }
    Integer r = x % d;
    if (r < 0) {
        r += d;
    }
    return r;
}

Integer oldRemainder(const Integer& x) {
    return regularMod(x, M_OLD);
}

Integer savePatch(const Integer& x) {
    Integer r = oldRemainder(x);
    if (r == 0) {
        r = M_OLD;
    }
    return r;
}

Integer oldDayTag(const Integer& day) {
    Integer distantia = day - FOUNDATION_DAY_OLD;
    if (distantia < 0) {
        distantia = -distantia;
    }
    return 2 * distantia;
}

Integer dayTagWithFoundationScar(const Integer& day) {
    Integer n = oldDayTag(day);
    if (day >= FOUNDATION_DAY_OLD) {
        n += 1;
    }
    if (day == FOUNDATION_DAY_OLD && n != 1) {
        n = 1;
    }
    return n;
}

Integer oldDistance(const Integer& calculationDay, const Integer& targetDay) {
    Integer d = dayTagWithFoundationScar(calculationDay) - dayTagWithFoundationScar(targetDay);
    if (d < 0) {
        d = -d;
    }
    return d;
}

Integer distanceWithChronologicalPatch(const Integer& calculationDay,
                                       const Integer& targetDay,
                                       const Integer& legacyDistance) {
    Integer d = legacyDistance;
    Integer chronological = targetDay - calculationDay;
    if (chronological < 0) {
        chronological = -chronological;
    }
    if (d != chronological) {
        d = chronological;
    }
    return d + 1;
}

Stone mutateStonesWrong(int i, Stone state) {
    state[0] = savePatch(state[0] * state[0] + 3 * state[1] + i);
    state[1] = savePatch(state[1] * state[1] + 5 * state[2] + state[0]);
    state[2] = savePatch(state[2] * state[2] + 7 * state[3] + state[1]);
    state[3] = savePatch(state[3] * state[3] + 11 * state[4] + state[2]);
    state[4] = savePatch(state[4] * state[4] + 13 * state[0] + state[3]);
    return state;
}

StoneTable buildStonesThroughWrongLegacyMutation() {
    StoneTable table{};
    Stone state{Integer{17}, Integer{29}, Integer{43}, Integer{71}, Integer{101}};
    table[1] = state;
    for (int i = 2; i <= 46; ++i) {
        state = mutateStonesWrong(i, state);
        table[i] = state;
    }
    return table;
}

Stone stonePatch(int i, Stone state) {
    const Stone old = state;

    // Vocatio legacy consulto manet. Exitus eius est receptaculum "garbage",
    // non fons semanticus postquam quinque partes ex uno snapshot veteri
    // denuo scribuntur.
    Stone garbage = mutateStonesWrong(i, state);

    garbage[0] = savePatch(old[0] * old[0] + 3 * old[1] + i);
    garbage[1] = savePatch(old[1] * old[1] + 5 * old[2] + old[0]);
    garbage[2] = savePatch(old[2] * old[2] + 7 * old[3] + old[1]);
    garbage[3] = savePatch(old[3] * old[3] + 11 * old[4] + old[2]);
    garbage[4] = savePatch(old[4] * old[4] + 13 * old[0] + old[3]);
    return garbage;
}

StoneTable buildStonesThroughLegacyBuilder() {
    StoneTable table{};
    Stone state{Integer{17}, Integer{29}, Integer{43}, Integer{71}, Integer{101}};
    table[1] = state;
    for (int i = 2; i <= 46; ++i) {
        state = stonePatch(i, state);
        table[i] = state;
    }
    return table;
}

Integer makeHiddenLegacyValue(int k,
                              const Integer& calculationDay,
                              const Integer& targetDay,
                              const StoneTable& stones) {
    static constexpr std::array<std::array<int, 4>, 7> coeff{{
        {{3, 4, 6, 8}},
        {{5, 7, 10, 12}},
        {{7, 10, 14, 16}},
        {{9, 13, 18, 20}},
        {{11, 16, 22, 24}},
        {{13, 19, 26, 28}},
        {{15, 22, 30, 32}},
    }};
    static constexpr std::array<int, 7> grindStone{{0, 1, 2, 3, 4, 0, 1}};

    if (k < 1 || k > 7) {
        throw BaseValidationError("index guttae occultae inter unum et septem requiritur");
    }

    const Integer action = dayTagWithFoundationScar(calculationDay);
    const Integer target = dayTagWithFoundationScar(targetDay);
    const Integer distance = distanceWithChronologicalPatch(
        calculationDay, targetDay, oldDistance(calculationDay, targetDay));
    const Integer connection = action + target;
    const Integer direction = targetDay < calculationDay ? Integer{1}
                            : targetDay == calculationDay ? Integer{2}
                                                          : Integer{3};

    const auto c = coeff[static_cast<std::size_t>(k - 1)];
    Integer x = action
              + c[0] * target
              + c[1] * distance
              + c[2] * connection
              + c[3] * direction;
    for (int part = 0; part < 5; ++part) {
        x += stones[static_cast<std::size_t>(k)][static_cast<std::size_t>(part)];
    }
    x = savePatch(x);

    for (int grind = 1; grind <= 7; ++grind) {
        const Integer oldX = x;
        x = savePatch(oldX * oldX
                    + 3 * oldX
                    + stones[static_cast<std::size_t>(k)]
                            [static_cast<std::size_t>(grindStone[static_cast<std::size_t>(grind - 1)])]
                    + grind);
    }
    return x;
}

HiddenDrops buildHiddenWithBackwardStorage(const Integer& calculationDay,
                                           const Integer& targetDay,
                                           const StoneTable& stones) {
    HiddenDrops legacyHidden{};
    for (int k = 1; k <= 7; ++k) {
        const Integer value = makeHiddenLegacyValue(k, calculationDay, targetDay, stones);
        legacyHidden[static_cast<std::size_t>(7 - k)] = value;
    }
    return legacyHidden;
}

Integer hiddenByNearness(const HiddenDrops& backwardStorage, int k) {
    if (k < 1 || k > 7) {
        throw BaseValidationError("index guttae occultae inter unum et septem requiritur");
    }
    const int oneBasedSlot = 8 - k;
    return backwardStorage[static_cast<std::size_t>(oneBasedSlot - 1)];
}

HiddenDrops buildHiddenNearnessView(const HiddenDrops& backwardStorage) {
    HiddenDrops view{};
    for (int k = 1; k <= 7; ++k) {
        view[static_cast<std::size_t>(k - 1)] = hiddenByNearness(backwardStorage, k);
    }
    return view;
}

Integer legacyPrior(const VisibleDropStore& dropStore, int i, int back) {
    if (i < 1) {
        throw BaseValidationError("index guttae visibilis positivus requiritur");
    }
    if (back < 1) {
        throw BaseValidationError("distantia retro positiva requiritur");
    }
    const int indexPrior = i - back;
    if (indexPrior < 1 || indexPrior >= i) {
        throw BaseValidationError("helper legacy tantum historiam visibilem iam scriptam legit");
    }
    const auto slot = static_cast<std::size_t>(indexPrior - 1);
    if (slot >= dropStore.size()) {
        throw BaseValidationError("historia visibilis ad indicem petitum nondum adest");
    }
    return dropStore[slot];
}

Integer priorPatch(const VisibleDropStore& dropStore,
                   const HiddenDrops& backwardStorage,
                   int i,
                   int back) {
    if (i < 1) {
        throw BaseValidationError("index guttae visibilis positivus requiritur");
    }
    if (back < 1) {
        throw BaseValidationError("distantia retro positiva requiritur");
    }

    const int slot = i - back;
    if (slot >= 1) {
        return legacyPrior(dropStore, i, back);
    }

    const int hiddenK = 1 - slot;
    return hiddenByNearness(backwardStorage, hiddenK);
}

const std::array<VisibleGrindRow, 11>& legacyVisibleGrindTableZeroBased() {
    static const std::array<VisibleGrindRow, 11> table{{
        {GrindStoneKind::WHEAT, 3, 5, 7, 11},
        {GrindStoneKind::BARLEY, 5, 7, 11, 13},
        {GrindStoneKind::SALT, 7, 11, 13, 17},
        {GrindStoneKind::BITTER, 11, 13, 17, 19},
        {GrindStoneKind::RED, 13, 17, 19, 23},
        {GrindStoneKind::WHEAT, 17, 19, 23, 29},
        {GrindStoneKind::BARLEY, 19, 23, 29, 31},
        {GrindStoneKind::SALT, 23, 29, 31, 37},
        {GrindStoneKind::BITTER, 29, 31, 37, 41},
        {GrindStoneKind::RED, 31, 37, 41, 43},
        {GrindStoneKind::WHEAT, 37, 41, 43, 47},
    }};
    return table;
}

LegacyGrindLookup legacyGrindRow(int grind) {
    if (grind < 1 || grind > 11) {
        throw BaseValidationError("numerus molitionis inter unum et undecim requiritur");
    }

    const auto& table = legacyVisibleGrindTableZeroBased();
    const int physicalIndex = grind;
    if (physicalIndex < 0 || physicalIndex >= static_cast<int>(table.size())) {
        return LegacyGrindLookup{VisibleGrindRow{}, physicalIndex, false};
    }
    return LegacyGrindLookup{
        table[static_cast<std::size_t>(physicalIndex)],
        physicalIndex,
        true,
    };
}

const std::array<VisibleGrindRow, 12>& grindTableWithSentinel() {
    static const std::array<VisibleGrindRow, 12> table{{
        {GrindStoneKind::NONE, 0, 0, 0, 0},
        {GrindStoneKind::WHEAT, 3, 5, 7, 11},
        {GrindStoneKind::BARLEY, 5, 7, 11, 13},
        {GrindStoneKind::SALT, 7, 11, 13, 17},
        {GrindStoneKind::BITTER, 11, 13, 17, 19},
        {GrindStoneKind::RED, 13, 17, 19, 23},
        {GrindStoneKind::WHEAT, 17, 19, 23, 29},
        {GrindStoneKind::BARLEY, 19, 23, 29, 31},
        {GrindStoneKind::SALT, 23, 29, 31, 37},
        {GrindStoneKind::BITTER, 29, 31, 37, 41},
        {GrindStoneKind::RED, 31, 37, 41, 43},
        {GrindStoneKind::WHEAT, 37, 41, 43, 47},
    }};
    return table;
}

LegacyGrindLookup grindRowWithSentinel(int grind) {
    if (grind < 1 || grind > 11) {
        throw BaseValidationError("numerus molitionis inter unum et undecim requiritur");
    }
    const auto& table = grindTableWithSentinel();
    const int physicalIndex = grind;
    return LegacyGrindLookup{table[static_cast<std::size_t>(physicalIndex)], physicalIndex, true};
}

PermutationOrder oldPermutationUnrank0(int rank0) {
    if (rank0 < 0 || rank0 >= 720) {
        throw BaseValidationError("gradus permutationis legacy inter nullum et DCCXIX requiritur");
    }

    std::vector<int> available{1, 2, 3, 4, 5, 6};
    PermutationOrder order{};
    const std::array<int, 6> divisors{{120, 24, 6, 2, 1, 1}};
    int remnant = rank0;

    for (std::size_t pos = 0; pos < order.size(); ++pos) {
        const int divisor = divisors[pos];
        const int choice = remnant / divisor;
        remnant %= divisor;
        if (choice < 0 || choice >= static_cast<int>(available.size())) {
            throw BaseValidationError("digitus factoradicus legacy extra fines est");
        }
        order[pos] = available[static_cast<std::size_t>(choice)];
        available.erase(available.begin() + choice);
    }

    return order;
}

void BaseValidationManager::requireNeutralBootstrapState(const BaseMonsterContext& ctx) const {
    if (ctx.phase.empty() || ctx.status.empty()) {
        throw BaseValidationError("status initialis invalidus");
    }
}

void BaseValidationManager::requireLegacyArithmeticReady(const BaseMonsterContext& ctx) const {
    if (!ctx.legacyArithmeticReady) {
        throw BaseValidationError("res arithmetica legacy nondum parata est");
    }
}

void BaseValidationManager::requirePatch01Ready(const BaseMonsterContext& ctx) const {
    requireLegacyArithmeticReady(ctx);
    if (!ctx.patch01Applied) {
        throw BaseValidationError("emendatio prima nondum applicata est");
    }
    if (ctx.legacyArithmeticOutput == 0) {
        if (ctx.patchedArithmeticOutput != M_OLD) {
            throw BaseValidationError("emendatio prima multiplum M non servavit");
        }
    } else if (ctx.patchedArithmeticOutput != ctx.legacyArithmeticOutput) {
        throw BaseValidationError("emendatio prima residuum non-nullum mutavit");
    }
}

void BaseValidationManager::requireLegacyDayTagReady(const BaseMonsterContext& ctx) const {
    if (!ctx.legacyDayTagReady) {
        throw BaseValidationError("nota diei legacy nondum parata est");
    }
}

void BaseValidationManager::requirePatch02Ready(const BaseMonsterContext& ctx) const {
    requireLegacyDayTagReady(ctx);
    if (!ctx.patch02Applied) {
        throw BaseValidationError("emendatio secunda nondum applicata est");
    }

    Integer expectatus = ctx.legacyDayTagOutput;
    if (ctx.legacyDayTagInput >= FOUNDATION_DAY_OLD) {
        expectatus += 1;
    }
    if (ctx.legacyDayTagInput == FOUNDATION_DAY_OLD && expectatus != 1) {
        expectatus = 1;
    }

    if (ctx.patchedDayTagOutput != expectatus) {
        throw BaseValidationError("emendatio secunda cicatricem diei non servavit");
    }
}

void BaseValidationManager::requireLegacyDistanceReady(const BaseMonsterContext& ctx) const {
    if (!ctx.legacyDistanceReady) {
        throw BaseValidationError("distantia legacy nondum parata est");
    }
}

void BaseValidationManager::requirePatch03Ready(const BaseMonsterContext& ctx) const {
    requireLegacyDistanceReady(ctx);
    if (!ctx.patch03Applied) {
        throw BaseValidationError("emendatio tertia nondum applicata est");
    }

    Integer chronological = ctx.legacyDistanceTargetDay - ctx.legacyDistanceCalculationDay;
    if (chronological < 0) {
        chronological = -chronological;
    }
    const Integer expectatus = chronological + 1;
    if (ctx.patchedDistanceOutput != expectatus) {
        throw BaseValidationError("emendatio tertia distantiam chronologicam inclusivam non servavit");
    }
}

void BaseValidationManager::requireLegacyStoneTableReady(const BaseMonsterContext& ctx) const {
    if (!ctx.legacyStoneTableReady) {
        throw BaseValidationError("tabula lapidum legacy nondum parata est");
    }
    const Stone initium{Integer{17}, Integer{29}, Integer{43}, Integer{71}, Integer{101}};
    if (ctx.legacyStoneTable[1] != initium) {
        throw BaseValidationError("primus lapis legacy mutatus est");
    }
}

void BaseValidationManager::requirePatch04Ready(const BaseMonsterContext& ctx) const {
    requireLegacyStoneTableReady(ctx);
    if (!ctx.patch04Applied) {
        throw BaseValidationError("emendatio quarta nondum applicata est");
    }

    const Stone initium{Integer{17}, Integer{29}, Integer{43}, Integer{71}, Integer{101}};
    if (ctx.patchedStoneTable[1] != initium) {
        throw BaseValidationError("primus lapis post emendationem quartam mutatus est");
    }

    Stone state = initium;
    for (int i = 2; i <= 46; ++i) {
        const Stone old = state;
        Stone expectatus{};
        expectatus[0] = savePatch(old[0] * old[0] + 3 * old[1] + i);
        expectatus[1] = savePatch(old[1] * old[1] + 5 * old[2] + old[0]);
        expectatus[2] = savePatch(old[2] * old[2] + 7 * old[3] + old[1]);
        expectatus[3] = savePatch(old[3] * old[3] + 11 * old[4] + old[2]);
        expectatus[4] = savePatch(old[4] * old[4] + 13 * old[0] + old[3]);
        if (ctx.patchedStoneTable[i] != expectatus) {
            throw BaseValidationError("emendatio quarta omnes partes ex eodem snapshot veteri non derivavit");
        }
        state = expectatus;
    }
}

void BaseValidationManager::requireLegacyHiddenBackwardReady(const BaseMonsterContext& ctx) const {
    if (!ctx.legacyHiddenBackwardReady) {
        throw BaseValidationError("guttae occultae ordine retrogrado nondum paratae sunt");
    }
}

void BaseValidationManager::requirePatch05Ready(const BaseMonsterContext& ctx) const {
    requireLegacyHiddenBackwardReady(ctx);
    if (!ctx.patch05Applied) {
        throw BaseValidationError("emendatio quinta nondum applicata est");
    }
    for (int k = 1; k <= 7; ++k) {
        const Integer expectatus = hiddenByNearness(ctx.legacyHiddenBackward, k);
        if (ctx.patchedHiddenNearness[static_cast<std::size_t>(k - 1)] != expectatus) {
            throw BaseValidationError("emendatio quinta mapping octo-minus-k non servavit");
        }
    }
}

void BaseValidationManager::requireLegacyPriorReady(const BaseMonsterContext& ctx) const {
    if (!ctx.legacyPriorReady) {
        throw BaseValidationError("valor prior legacy nondum paratus est");
    }
}

void BaseValidationManager::requirePatch06Ready(const BaseMonsterContext& ctx) const {
    if (!ctx.patch06Applied) {
        throw BaseValidationError("emendatio sexta nondum applicata est");
    }
    if (ctx.patch06LegacyPathUsed == ctx.patch06HiddenPathUsed) {
        throw BaseValidationError("emendatio sexta unam tantum viam prioris eligere debet");
    }

    const int slot = ctx.legacyPriorI - ctx.legacyPriorBack;
    Integer expectatus{};
    if (slot >= 1) {
        expectatus = legacyPrior(ctx.legacyPriorDropStore, ctx.legacyPriorI, ctx.legacyPriorBack);
        if (!ctx.patch06LegacyPathUsed) {
            throw BaseValidationError("emendatio sexta historiam visibilem sine helper legacy legit");
        }
    } else {
        const int hiddenK = 1 - slot;
        expectatus = hiddenByNearness(ctx.patch06HiddenBackward, hiddenK);
        if (!ctx.patch06HiddenPathUsed) {
            throw BaseValidationError("emendatio sexta historiam occultam non elegit");
        }
    }

    if (ctx.patchedPriorOutput != expectatus) {
        throw BaseValidationError("emendatio sexta valorem prioris normativum non servavit");
    }
}

void BaseValidationManager::requireLegacyGrindReady(const BaseMonsterContext& ctx) const {
    if (!ctx.legacyGrindReady) {
        throw BaseValidationError("lectio tabulae molitionis legacy nondum perfecta est");
    }
    if (ctx.legacyGrindOrdinal < 1 || ctx.legacyGrindOrdinal > 11) {
        throw BaseValidationError("numerus molitionis legacy extra fines est");
    }
    if (ctx.legacyGrindPhysicalIndex != ctx.legacyGrindOrdinal) {
        throw BaseValidationError("caller legacy numerum molitionis ut indicem directum non servavit");
    }
}

void BaseValidationManager::requirePatch07Ready(const BaseMonsterContext& ctx) const {
    requireLegacyGrindReady(ctx);
    if (!ctx.patch07Applied || !ctx.patchedGrindFound) {
        throw BaseValidationError("emendatio septima nondum applicata est");
    }
    const auto expected = grindRowWithSentinel(ctx.legacyGrindOrdinal);
    if (!expected.found || ctx.patchedGrindOutput.kind != expected.row.kind ||
        ctx.patchedGrindOutput.a != expected.row.a || ctx.patchedGrindOutput.b != expected.row.b ||
        ctx.patchedGrindOutput.c != expected.row.c || ctx.patchedGrindOutput.d != expected.row.d) {
        throw BaseValidationError("sentinella molitionis ordinem normativum non restituit");
    }
}

void BaseValidationManager::requireLegacyPermutationReady(const BaseMonsterContext& ctx) const {
    if (!ctx.legacyPermutationReady) {
        throw BaseValidationError("permutatio legacy nondum perfecta est");
    }
    if (ctx.legacyPermutationCallerRank1 < 1 || ctx.legacyPermutationCallerRank1 > 720) {
        throw BaseValidationError("ordinalis permutationis caller inter unum et DCCXX requiritur");
    }
    if (ctx.legacyPermutationRank0Input != ctx.legacyPermutationCallerRank1) {
        throw BaseValidationError("caller legacy ordinalem one-based directe ut rank0 non servavit");
    }
    if (!ctx.legacyPermutationFound) {
        if (ctx.legacyPermutationRank0Input != 720) {
            throw BaseValidationError("rank0 legacy intra fines permutationem non reddidit");
        }
        return;
    }

    std::array<bool, 7> seen{};
    for (const int value : ctx.legacyPermutationOutput) {
        if (value < 1 || value > 6 || seen[static_cast<std::size_t>(value)]) {
            throw BaseValidationError("permutatio legacy structuram sex elementorum non servavit");
        }
        seen[static_cast<std::size_t>(value)] = true;
    }
}

void BaseMetricsShell::bump(BaseMonsterContext& ctx, const std::string& key) const {
    auto it = ctx.metrics.find(key);
    if (it == ctx.metrics.end()) {
        ctx.metrics.emplace(key, Integer{1});
    } else {
        it->second += 1;
    }
}

Integer LegacyArithmeticAdapter::callOldRemainder(const Integer& x) const {
    return oldRemainder(x);
}

Integer LegacyDayTagAdapter::callOldDayTag(const Integer& day) const {
    return oldDayTag(day);
}

Integer LegacyDistanceAdapter::callOldDistance(const Integer& calculationDay, const Integer& targetDay) const {
    return oldDistance(calculationDay, targetDay);
}

StoneTable LegacyStoneMutationAdapter::buildWrongStoneTable() const {
    return buildStonesThroughWrongLegacyMutation();
}

HiddenDrops LegacyHiddenStorageAdapter::buildBackward(const Integer& calculationDay,
                                                      const Integer& targetDay,
                                                      const StoneTable& stones) const {
    return buildHiddenWithBackwardStorage(calculationDay, targetDay, stones);
}

Integer LegacyPriorAdapter::read(const VisibleDropStore& dropStore, int i, int back) const {
    return legacyPrior(dropStore, i, back);
}

Integer Patch06PriorWrapper::read(const VisibleDropStore& dropStore,
                                  const HiddenDrops& backwardStorage,
                                  int i,
                                  int back) const {
    return priorPatch(dropStore, backwardStorage, i, back);
}

LegacyGrindLookup LegacyGrindTableAdapter::read(int grind) const {
    return legacyGrindRow(grind);
}

LegacyGrindLookup Patch07SentinelGrindWrapper::read(int grind) const {
    return grindRowWithSentinel(grind);
}

PermutationOrder LegacyPermutationAdapter::unrank0(int rank0) const {
    return oldPermutationUnrank0(rank0);
}

void Discovery01RemainderHandler::handle(BaseMonsterContext& ctx,
                                         const LegacyArithmeticAdapter& adapter,
                                         const BaseValidationManager& validator,
                                         const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Discovery01RemainderHandler";
    ctx.phase = "DISCOVERY_01_REMAINDER_CALL";
    ctx.status = "LEGACY_ACTIVE";
    ctx.branchTrace.push_back("DISCOVERY_01_REMAINDER_CALL");
    metrics.bump(ctx, "discovery01.remainder.calls");

    ctx.legacyArithmeticOutput = adapter.callOldRemainder(ctx.legacyArithmeticInput);
    ctx.legacyArithmeticReady = true;

    ctx.phase = "DISCOVERY_01_REMAINDER_VALIDATE";
    ctx.branchTrace.push_back("DISCOVERY_01_REMAINDER_VALIDATE");
    validator.requireLegacyArithmeticReady(ctx);

    ctx.phase = "DISCOVERY_01_REMAINDER_EXPOSED";
    ctx.status = "LEGACY_RESULT_EXPOSED";
    ctx.branchTrace.push_back("DISCOVERY_01_REMAINDER_EXPOSED");
    metrics.bump(ctx, "discovery01.remainder.exposed");
}

Integer Patch01SaveWrapper::repair(const Integer& x) const {
    return savePatch(x);
}

void Patch01RemainderHandler::handle(BaseMonsterContext& ctx,
                                     const LegacyArithmeticAdapter& adapter,
                                     const Patch01SaveWrapper& wrapper,
                                     const BaseValidationManager& validator,
                                     const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Patch01RemainderHandler";
    ctx.phase = "PATCH_01_LEGACY_CALL";
    ctx.status = "LEGACY_CALLED_BEFORE_PATCH";
    ctx.branchTrace.push_back("PATCH_01_LEGACY_CALL");
    metrics.bump(ctx, "patch01.legacy.calls");

    ctx.legacyArithmeticOutput = adapter.callOldRemainder(ctx.legacyArithmeticInput);
    ctx.legacyArithmeticReady = true;

    ctx.phase = "PATCH_01_SAVE_WRAPPER";
    ctx.branchTrace.push_back("PATCH_01_SAVE_WRAPPER");
    ctx.patchedArithmeticOutput = wrapper.repair(ctx.legacyArithmeticInput);
    ctx.patch01Applied = true;
    metrics.bump(ctx, "patch01.wrapper.calls");

    ctx.phase = "PATCH_01_VALIDATE";
    ctx.branchTrace.push_back("PATCH_01_VALIDATE");
    validator.requirePatch01Ready(ctx);

    ctx.phase = "PATCH_01_REMAINDER_READY";
    ctx.status = "PATCHED_RESULT_EXPOSED";
    ctx.branchTrace.push_back("PATCH_01_REMAINDER_READY");
    metrics.bump(ctx, "patch01.remainder.ready");
}

void Discovery02DayTagHandler::handle(BaseMonsterContext& ctx,
                                      const LegacyDayTagAdapter& adapter,
                                      const BaseValidationManager& validator,
                                      const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Discovery02DayTagHandler";
    ctx.phase = "DISCOVERY_02_DAY_TAG_CALL";
    ctx.status = "LEGACY_DAY_TAG_ACTIVE";
    ctx.branchTrace.push_back("DISCOVERY_02_DAY_TAG_CALL");
    metrics.bump(ctx, "discovery02.dayTag.calls");

    ctx.legacyDayTagOutput = adapter.callOldDayTag(ctx.legacyDayTagInput);
    ctx.legacyDayTagReady = true;

    ctx.phase = "DISCOVERY_02_DAY_TAG_VALIDATE";
    ctx.branchTrace.push_back("DISCOVERY_02_DAY_TAG_VALIDATE");
    validator.requireLegacyDayTagReady(ctx);

    ctx.phase = "DISCOVERY_02_DAY_TAG_EXPOSED";
    ctx.status = "LEGACY_DAY_TAG_RESULT_EXPOSED";
    ctx.branchTrace.push_back("DISCOVERY_02_DAY_TAG_EXPOSED");
    metrics.bump(ctx, "discovery02.dayTag.exposed");
}

Integer Patch02DayTagWrapper::repair(const Integer& day) const {
    return dayTagWithFoundationScar(day);
}

void Patch02DayTagHandler::handle(BaseMonsterContext& ctx,
                                  const LegacyDayTagAdapter& adapter,
                                  const Patch02DayTagWrapper& wrapper,
                                  const BaseValidationManager& validator,
                                  const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Patch02DayTagHandler";
    ctx.phase = "PATCH_02_LEGACY_DAY_TAG_CALL";
    ctx.status = "LEGACY_DAY_TAG_CALLED_BEFORE_PATCH";
    ctx.branchTrace.push_back("PATCH_02_LEGACY_DAY_TAG_CALL");
    metrics.bump(ctx, "patch02.legacyDayTag.calls");

    ctx.legacyDayTagOutput = adapter.callOldDayTag(ctx.legacyDayTagInput);
    ctx.legacyDayTagReady = true;

    ctx.phase = "PATCH_02_FOUNDATION_SCAR";
    ctx.branchTrace.push_back("PATCH_02_FOUNDATION_SCAR");
    ctx.patchedDayTagOutput = wrapper.repair(ctx.legacyDayTagInput);
    ctx.patch02Applied = true;
    metrics.bump(ctx, "patch02.wrapper.calls");

    ctx.phase = "PATCH_02_VALIDATE";
    ctx.branchTrace.push_back("PATCH_02_VALIDATE");
    validator.requirePatch02Ready(ctx);

    ctx.phase = "PATCH_02_DAY_TAG_READY";
    ctx.status = "PATCHED_DAY_TAG_RESULT_EXPOSED";
    ctx.branchTrace.push_back("PATCH_02_DAY_TAG_READY");
    metrics.bump(ctx, "patch02.dayTag.ready");
}

void Discovery03DistanceHandler::handle(BaseMonsterContext& ctx,
                                        const LegacyDistanceAdapter& adapter,
                                        const BaseValidationManager& validator,
                                        const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Discovery03DistanceHandler";
    ctx.phase = "DISCOVERY_03_DISTANCE_CALL";
    ctx.status = "LEGACY_DISTANCE_ACTIVE";
    ctx.branchTrace.push_back("DISCOVERY_03_DISTANCE_CALL");
    metrics.bump(ctx, "discovery03.distance.calls");

    ctx.legacyDistanceOutput = adapter.callOldDistance(
        ctx.legacyDistanceCalculationDay, ctx.legacyDistanceTargetDay);
    ctx.legacyDistanceReady = true;

    ctx.phase = "DISCOVERY_03_DISTANCE_VALIDATE";
    ctx.branchTrace.push_back("DISCOVERY_03_DISTANCE_VALIDATE");
    validator.requireLegacyDistanceReady(ctx);

    ctx.phase = "DISCOVERY_03_DISTANCE_EXPOSED";
    ctx.status = "LEGACY_DISTANCE_RESULT_EXPOSED";
    ctx.branchTrace.push_back("DISCOVERY_03_DISTANCE_EXPOSED");
    metrics.bump(ctx, "discovery03.distance.exposed");
}

Integer Patch03DistanceWrapper::repair(const Integer& calculationDay,
                                       const Integer& targetDay,
                                       const Integer& legacyDistance) const {
    return distanceWithChronologicalPatch(calculationDay, targetDay, legacyDistance);
}

void Patch03DistanceHandler::handle(BaseMonsterContext& ctx,
                                    const LegacyDistanceAdapter& adapter,
                                    const Patch03DistanceWrapper& wrapper,
                                    const BaseValidationManager& validator,
                                    const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Patch03DistanceHandler";
    ctx.phase = "PATCH_03_LEGACY_DISTANCE_CALL";
    ctx.status = "LEGACY_DISTANCE_CALLED_BEFORE_PATCH";
    ctx.branchTrace.push_back("PATCH_03_LEGACY_DISTANCE_CALL");
    metrics.bump(ctx, "patch03.legacyDistance.calls");

    ctx.legacyDistanceOutput = adapter.callOldDistance(
        ctx.legacyDistanceCalculationDay, ctx.legacyDistanceTargetDay);
    ctx.legacyDistanceReady = true;

    ctx.phase = "PATCH_03_CHRONOLOGICAL_DETOUR";
    ctx.branchTrace.push_back("PATCH_03_CHRONOLOGICAL_DETOUR");
    ctx.patchedDistanceOutput = wrapper.repair(
        ctx.legacyDistanceCalculationDay,
        ctx.legacyDistanceTargetDay,
        ctx.legacyDistanceOutput);
    ctx.patch03Applied = true;
    metrics.bump(ctx, "patch03.wrapper.calls");

    ctx.phase = "PATCH_03_VALIDATE";
    ctx.branchTrace.push_back("PATCH_03_VALIDATE");
    validator.requirePatch03Ready(ctx);

    ctx.phase = "PATCH_03_DISTANCE_READY";
    ctx.status = "PATCHED_DISTANCE_RESULT_EXPOSED";
    ctx.branchTrace.push_back("PATCH_03_DISTANCE_READY");
    metrics.bump(ctx, "patch03.distance.ready");
}

void Discovery04StoneMutationHandler::handle(BaseMonsterContext& ctx,
                                             const LegacyStoneMutationAdapter& adapter,
                                             const BaseValidationManager& validator,
                                             const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Discovery04StoneMutationHandler";
    ctx.phase = "DISCOVERY_04_STONE_MUTATION_CALL";
    ctx.status = "LEGACY_STONE_MUTATION_ACTIVE";
    ctx.branchTrace.push_back("DISCOVERY_04_STONE_MUTATION_CALL");
    metrics.bump(ctx, "discovery04.stoneMutation.calls");

    ctx.legacyStoneTable = adapter.buildWrongStoneTable();
    ctx.legacyStoneTableReady = true;

    ctx.phase = "DISCOVERY_04_STONE_MUTATION_VALIDATE";
    ctx.branchTrace.push_back("DISCOVERY_04_STONE_MUTATION_VALIDATE");
    validator.requireLegacyStoneTableReady(ctx);

    ctx.phase = "DISCOVERY_04_STONE_MUTATION_EXPOSED";
    ctx.status = "LEGACY_STONE_TABLE_EXPOSED";
    ctx.branchTrace.push_back("DISCOVERY_04_STONE_MUTATION_EXPOSED");
    metrics.bump(ctx, "discovery04.stoneMutation.exposed");
}

StoneTable Patch04StoneSnapshotWrapper::repair() const {
    return buildStonesThroughLegacyBuilder();
}

void Patch04StoneMutationHandler::handle(BaseMonsterContext& ctx,
                                         const LegacyStoneMutationAdapter& adapter,
                                         const Patch04StoneSnapshotWrapper& wrapper,
                                         const BaseValidationManager& validator,
                                         const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Patch04StoneMutationHandler";
    ctx.phase = "PATCH_04_LEGACY_STONE_TABLE_CALL";
    ctx.status = "LEGACY_STONE_TABLE_CALLED_BEFORE_PATCH";
    ctx.branchTrace.push_back("PATCH_04_LEGACY_STONE_TABLE_CALL");
    metrics.bump(ctx, "patch04.legacyStoneTable.calls");

    // Haec tabula vitiosa servatur ut cicatrix observabilis; praeterea
    // stonePatch ipse mutateStonesWrong in singulis gradibus revera vocat.
    ctx.legacyStoneTable = adapter.buildWrongStoneTable();
    ctx.legacyStoneTableReady = true;

    ctx.phase = "PATCH_04_SNAPSHOT_OVERWRITE";
    ctx.branchTrace.push_back("PATCH_04_SNAPSHOT_OVERWRITE");
    ctx.patchedStoneTable = wrapper.repair();
    ctx.patch04Applied = true;
    metrics.bump(ctx, "patch04.snapshotOverwrite.calls");

    ctx.phase = "PATCH_04_VALIDATE";
    ctx.branchTrace.push_back("PATCH_04_VALIDATE");
    validator.requirePatch04Ready(ctx);

    ctx.phase = "PATCH_04_STONE_TABLE_READY";
    ctx.status = "PATCHED_STONE_TABLE_EXPOSED";
    ctx.branchTrace.push_back("PATCH_04_STONE_TABLE_READY");
    metrics.bump(ctx, "patch04.stoneTable.ready");
}

void Discovery05HiddenStorageHandler::handle(BaseMonsterContext& ctx,
                                             const LegacyHiddenStorageAdapter& adapter,
                                             const BaseValidationManager& validator,
                                             const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Discovery05HiddenStorageHandler";
    ctx.phase = "DISCOVERY_05_HIDDEN_BACKWARD_BUILD";
    ctx.status = "LEGACY_HIDDEN_BACKWARD_ACTIVE";
    ctx.branchTrace.push_back("DISCOVERY_05_HIDDEN_BACKWARD_BUILD");
    metrics.bump(ctx, "discovery05.hiddenBackward.calls");

    const StoneTable stones = buildStonesThroughLegacyBuilder();
    ctx.legacyHiddenBackward = adapter.buildBackward(
        ctx.calculationDay, ctx.targetDay, stones);
    ctx.legacyHiddenBackwardReady = true;

    ctx.phase = "DISCOVERY_05_HIDDEN_BACKWARD_VALIDATE";
    ctx.branchTrace.push_back("DISCOVERY_05_HIDDEN_BACKWARD_VALIDATE");
    validator.requireLegacyHiddenBackwardReady(ctx);

    ctx.phase = "DISCOVERY_05_HIDDEN_BACKWARD_EXPOSED";
    ctx.status = "LEGACY_HIDDEN_BACKWARD_EXPOSED_AS_NEARNESS";
    ctx.branchTrace.push_back("DISCOVERY_05_HIDDEN_BACKWARD_EXPOSED");
    metrics.bump(ctx, "discovery05.hiddenBackward.exposed");
}

Integer Patch05HiddenNearnessWrapper::read(const HiddenDrops& backwardStorage, int k) const {
    return hiddenByNearness(backwardStorage, k);
}

void Patch05HiddenStorageHandler::handle(BaseMonsterContext& ctx,
                                         const LegacyHiddenStorageAdapter& adapter,
                                         const Patch05HiddenNearnessWrapper& wrapper,
                                         const BaseValidationManager& validator,
                                         const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Patch05HiddenStorageHandler";
    ctx.phase = "PATCH_05_LEGACY_HIDDEN_BACKWARD_BUILD";
    ctx.status = "LEGACY_HIDDEN_BACKWARD_CALLED_BEFORE_PATCH";
    ctx.branchTrace.push_back("PATCH_05_LEGACY_HIDDEN_BACKWARD_BUILD");
    metrics.bump(ctx, "patch05.legacyHiddenBackward.calls");

    const StoneTable stones = buildStonesThroughLegacyBuilder();
    ctx.legacyHiddenBackward = adapter.buildBackward(
        ctx.calculationDay, ctx.targetDay, stones);
    ctx.legacyHiddenBackwardReady = true;

    ctx.phase = "PATCH_05_NEARNESS_ACCESS";
    ctx.branchTrace.push_back("PATCH_05_NEARNESS_ACCESS");
    for (int k = 1; k <= 7; ++k) {
        ctx.patchedHiddenNearness[static_cast<std::size_t>(k - 1)] =
            wrapper.read(ctx.legacyHiddenBackward, k);
    }
    ctx.patch05Applied = true;
    metrics.bump(ctx, "patch05.nearnessAccess.calls");

    ctx.phase = "PATCH_05_VALIDATE";
    ctx.branchTrace.push_back("PATCH_05_VALIDATE");
    validator.requirePatch05Ready(ctx);

    ctx.phase = "PATCH_05_HIDDEN_READY";
    ctx.status = "PATCHED_HIDDEN_NEARNESS_EXPOSED";
    ctx.branchTrace.push_back("PATCH_05_HIDDEN_READY");
    metrics.bump(ctx, "patch05.hidden.ready");
}

void Discovery06PriorHandler::handle(BaseMonsterContext& ctx,
                                     const LegacyPriorAdapter& adapter,
                                     const BaseValidationManager& validator,
                                     const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Discovery06PriorHandler";
    ctx.phase = "DISCOVERY_06_PRIOR_READ";
    ctx.status = "LEGACY_PRIOR_VISIBLE_ONLY_ACTIVE";
    ctx.branchTrace.push_back("DISCOVERY_06_PRIOR_READ");
    metrics.bump(ctx, "discovery06.prior.calls");

    ctx.legacyPriorOutput = adapter.read(
        ctx.legacyPriorDropStore, ctx.legacyPriorI, ctx.legacyPriorBack);
    ctx.legacyPriorReady = true;

    ctx.phase = "DISCOVERY_06_PRIOR_VALIDATE";
    ctx.branchTrace.push_back("DISCOVERY_06_PRIOR_VALIDATE");
    validator.requireLegacyPriorReady(ctx);

    ctx.phase = "DISCOVERY_06_PRIOR_EXPOSED";
    ctx.status = "LEGACY_PRIOR_VISIBLE_RESULT_EXPOSED";
    ctx.branchTrace.push_back("DISCOVERY_06_PRIOR_EXPOSED");
    metrics.bump(ctx, "discovery06.prior.exposed");
}

void Patch06PriorHandler::handle(BaseMonsterContext& ctx,
                                 const LegacyPriorAdapter& adapter,
                                 const Patch06PriorWrapper& wrapper,
                                 const BaseValidationManager& validator,
                                 const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Patch06PriorHandler";
    ctx.phase = "PATCH_06_PREPARE_HIDDEN";
    ctx.status = "PATCH_06_PRIOR_ACTIVE";
    ctx.branchTrace.push_back("PATCH_06_PREPARE_HIDDEN");
    metrics.bump(ctx, "patch06.prior.calls");

    const StoneTable stones = buildStonesThroughLegacyBuilder();
    ctx.patch06HiddenBackward = buildHiddenWithBackwardStorage(
        ctx.calculationDay, ctx.targetDay, stones);

    const int slot = ctx.legacyPriorI - ctx.legacyPriorBack;
    ctx.phase = "PATCH_06_ROUTE_PRIOR";
    ctx.branchTrace.push_back("PATCH_06_ROUTE_PRIOR");
    if (slot >= 1) {
        ctx.legacyPriorOutput = adapter.read(
            ctx.legacyPriorDropStore, ctx.legacyPriorI, ctx.legacyPriorBack);
        ctx.legacyPriorReady = true;
        ctx.patch06LegacyPathUsed = true;
        ctx.patchedPriorOutput = ctx.legacyPriorOutput;
        metrics.bump(ctx, "patch06.prior.legacyPath");
    } else {
        ctx.patch06HiddenPathUsed = true;
        ctx.patchedPriorOutput = wrapper.read(
            ctx.legacyPriorDropStore,
            ctx.patch06HiddenBackward,
            ctx.legacyPriorI,
            ctx.legacyPriorBack);
        metrics.bump(ctx, "patch06.prior.hiddenPath");
    }
    ctx.patch06Applied = true;

    ctx.phase = "PATCH_06_VALIDATE";
    ctx.branchTrace.push_back("PATCH_06_VALIDATE");
    validator.requirePatch06Ready(ctx);

    ctx.phase = "PATCH_06_PRIOR_READY";
    ctx.status = "PATCHED_PRIOR_RESULT_EXPOSED";
    ctx.branchTrace.push_back("PATCH_06_PRIOR_READY");
    metrics.bump(ctx, "patch06.prior.ready");
}

void Discovery07GrindIndexHandler::handle(BaseMonsterContext& ctx,
                                           const LegacyGrindTableAdapter& adapter,
                                           const BaseValidationManager& validator,
                                           const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Discovery07GrindIndexHandler";
    ctx.phase = "DISCOVERY_07_GRIND_INDEX_READ";
    ctx.status = "LEGACY_GRIND_ZERO_BASED_TABLE_ACTIVE";
    ctx.branchTrace.push_back("DISCOVERY_07_GRIND_INDEX_READ");
    metrics.bump(ctx, "discovery07.grind.calls");

    const LegacyGrindLookup lookup = adapter.read(ctx.legacyGrindOrdinal);
    ctx.legacyGrindPhysicalIndex = lookup.physicalIndex;
    ctx.legacyGrindOutput = lookup.row;
    ctx.legacyGrindFound = lookup.found;
    ctx.legacyGrindReady = true;

    ctx.phase = "DISCOVERY_07_GRIND_INDEX_VALIDATE";
    ctx.branchTrace.push_back("DISCOVERY_07_GRIND_INDEX_VALIDATE");
    validator.requireLegacyGrindReady(ctx);

    ctx.phase = "DISCOVERY_07_GRIND_INDEX_EXPOSED";
    ctx.status = lookup.found ? "LEGACY_GRIND_SHIFTED_ROW_EXPOSED" : "LEGACY_GRIND_ROW_ABSENT";
    ctx.branchTrace.push_back("DISCOVERY_07_GRIND_INDEX_EXPOSED");
    metrics.bump(ctx, lookup.found ? "discovery07.grind.shifted" : "discovery07.grind.absent");
}

void Patch07GrindIndexHandler::handle(BaseMonsterContext& ctx,
                                      const LegacyGrindTableAdapter& adapter,
                                      const Patch07SentinelGrindWrapper& wrapper,
                                      const BaseValidationManager& validator,
                                      const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Patch07GrindIndexHandler";
    ctx.phase = "PATCH_07_LEGACY_GRIND_READ";
    ctx.status = "LEGACY_GRIND_READ_BEFORE_SENTINEL";
    ctx.branchTrace.push_back("PATCH_07_LEGACY_GRIND_READ");
    metrics.bump(ctx, "patch07.grind.legacy.calls");

    const LegacyGrindLookup legacy = adapter.read(ctx.legacyGrindOrdinal);
    ctx.legacyGrindPhysicalIndex = legacy.physicalIndex;
    ctx.legacyGrindOutput = legacy.row;
    ctx.legacyGrindFound = legacy.found;
    ctx.legacyGrindReady = true;

    ctx.phase = "PATCH_07_SENTINEL_TABLE_READ";
    ctx.branchTrace.push_back("PATCH_07_SENTINEL_TABLE_READ");
    const LegacyGrindLookup patched = wrapper.read(ctx.legacyGrindOrdinal);
    ctx.patchedGrindOutput = patched.row;
    ctx.patchedGrindFound = patched.found;
    ctx.patch07Applied = true;
    metrics.bump(ctx, "patch07.grind.sentinel.calls");

    ctx.phase = "PATCH_07_VALIDATE";
    ctx.branchTrace.push_back("PATCH_07_VALIDATE");
    validator.requirePatch07Ready(ctx);

    ctx.phase = "PATCH_07_GRIND_READY";
    ctx.status = "PATCHED_GRIND_ROW_EXPOSED";
    ctx.branchTrace.push_back("PATCH_07_GRIND_READY");
    metrics.bump(ctx, "patch07.grind.ready");
}

void Discovery08PermutationRankHandler::handle(BaseMonsterContext& ctx,
                                                const LegacyPermutationAdapter& adapter,
                                                const BaseValidationManager& validator,
                                                const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Discovery08PermutationRankHandler";
    ctx.phase = "DISCOVERY_08_PERMUTATION_ZERO_BASED_CALL";
    ctx.status = "LEGACY_PERMUTATION_ZERO_BASED_ACTIVE";
    ctx.branchTrace.push_back("DISCOVERY_08_PERMUTATION_ZERO_BASED_CALL");
    metrics.bump(ctx, "discovery08.permutation.calls");

    ctx.legacyPermutationRank0Input = ctx.legacyPermutationCallerRank1;
    try {
        ctx.legacyPermutationOutput = adapter.unrank0(ctx.legacyPermutationRank0Input);
        ctx.legacyPermutationFound = true;
    } catch (const BaseValidationError&) {
        ctx.legacyPermutationOutput = PermutationOrder{};
        ctx.legacyPermutationFound = false;
    }
    ctx.legacyPermutationReady = true;

    ctx.phase = "DISCOVERY_08_PERMUTATION_ZERO_BASED_VALIDATE";
    ctx.branchTrace.push_back("DISCOVERY_08_PERMUTATION_ZERO_BASED_VALIDATE");
    validator.requireLegacyPermutationReady(ctx);

    ctx.phase = "DISCOVERY_08_PERMUTATION_ZERO_BASED_EXPOSED";
    ctx.status = ctx.legacyPermutationFound
        ? "LEGACY_PERMUTATION_SHIFTED_ORDER_EXPOSED"
        : "LEGACY_PERMUTATION_RANK_REJECTED";
    ctx.branchTrace.push_back("DISCOVERY_08_PERMUTATION_ZERO_BASED_EXPOSED");
    metrics.bump(ctx, ctx.legacyPermutationFound
        ? "discovery08.permutation.shifted"
        : "discovery08.permutation.rejected");
}

void BaseDispatcher::dispatch(BaseMonsterContext& ctx,
                              const BaseValidationManager& validator,
                              const BaseMetricsShell& metrics) const {
    ctx.phase = "BOOTSTRAP_ENTRY";
    ctx.status = "ENTERED";
    ctx.branchTrace.push_back("BOOTSTRAP_ENTRY");
    metrics.bump(ctx, "bootstrap.calls");
    validator.requireNeutralBootstrapState(ctx);

    ctx.phase = "BOOTSTRAP_VALIDATE";
    ctx.branchTrace.push_back("BOOTSTRAP_VALIDATE");
    validator.requireNeutralBootstrapState(ctx);

    ctx.phase = "BOOTSTRAP_DONE";
    ctx.status = "OK";
    ctx.branchTrace.push_back("BOOTSTRAP_DONE");
    metrics.bump(ctx, "bootstrap.success");
}

void BaseDispatcher::dispatchLegacyRemainder(BaseMonsterContext& ctx,
                                             const Discovery01RemainderHandler& handler,
                                             const LegacyArithmeticAdapter& adapter,
                                             const BaseValidationManager& validator,
                                             const BaseMetricsShell& metrics) const {
    ctx.phase = "DISCOVERY_01_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("DISCOVERY_01_DISPATCH");
    metrics.bump(ctx, "discovery01.dispatch.calls");

    handler.handle(ctx, adapter, validator, metrics);
}

void BaseDispatcher::dispatchPatchedRemainder(BaseMonsterContext& ctx,
                                              const Patch01RemainderHandler& handler,
                                              const LegacyArithmeticAdapter& adapter,
                                              const Patch01SaveWrapper& wrapper,
                                              const BaseValidationManager& validator,
                                              const BaseMetricsShell& metrics) const {
    ctx.phase = "PATCH_01_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("PATCH_01_DISPATCH");
    metrics.bump(ctx, "patch01.dispatch.calls");

    handler.handle(ctx, adapter, wrapper, validator, metrics);
}

void BaseDispatcher::dispatchLegacyDayTag(BaseMonsterContext& ctx,
                                          const Discovery02DayTagHandler& handler,
                                          const LegacyDayTagAdapter& adapter,
                                          const BaseValidationManager& validator,
                                          const BaseMetricsShell& metrics) const {
    ctx.phase = "DISCOVERY_02_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("DISCOVERY_02_DISPATCH");
    metrics.bump(ctx, "discovery02.dispatch.calls");

    handler.handle(ctx, adapter, validator, metrics);
}

void BaseDispatcher::dispatchPatchedDayTag(BaseMonsterContext& ctx,
                                           const Patch02DayTagHandler& handler,
                                           const LegacyDayTagAdapter& adapter,
                                           const Patch02DayTagWrapper& wrapper,
                                           const BaseValidationManager& validator,
                                           const BaseMetricsShell& metrics) const {
    ctx.phase = "PATCH_02_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("PATCH_02_DISPATCH");
    metrics.bump(ctx, "patch02.dispatch.calls");

    handler.handle(ctx, adapter, wrapper, validator, metrics);
}

void BaseDispatcher::dispatchLegacyDistance(BaseMonsterContext& ctx,
                                            const Discovery03DistanceHandler& handler,
                                            const LegacyDistanceAdapter& adapter,
                                            const BaseValidationManager& validator,
                                            const BaseMetricsShell& metrics) const {
    ctx.phase = "DISCOVERY_03_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("DISCOVERY_03_DISPATCH");
    metrics.bump(ctx, "discovery03.dispatch.calls");

    handler.handle(ctx, adapter, validator, metrics);
}

void BaseDispatcher::dispatchPatchedDistance(BaseMonsterContext& ctx,
                                             const Patch03DistanceHandler& handler,
                                             const LegacyDistanceAdapter& adapter,
                                             const Patch03DistanceWrapper& wrapper,
                                             const BaseValidationManager& validator,
                                             const BaseMetricsShell& metrics) const {
    ctx.phase = "PATCH_03_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("PATCH_03_DISPATCH");
    metrics.bump(ctx, "patch03.dispatch.calls");

    handler.handle(ctx, adapter, wrapper, validator, metrics);
}

void BaseDispatcher::dispatchLegacyStoneMutation(BaseMonsterContext& ctx,
                                                 const Discovery04StoneMutationHandler& handler,
                                                 const LegacyStoneMutationAdapter& adapter,
                                                 const BaseValidationManager& validator,
                                                 const BaseMetricsShell& metrics) const {
    ctx.phase = "DISCOVERY_04_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("DISCOVERY_04_DISPATCH");
    metrics.bump(ctx, "discovery04.dispatch.calls");

    handler.handle(ctx, adapter, validator, metrics);
}

void BaseDispatcher::dispatchPatchedStoneMutation(BaseMonsterContext& ctx,
                                                  const Patch04StoneMutationHandler& handler,
                                                  const LegacyStoneMutationAdapter& adapter,
                                                  const Patch04StoneSnapshotWrapper& wrapper,
                                                  const BaseValidationManager& validator,
                                                  const BaseMetricsShell& metrics) const {
    ctx.phase = "PATCH_04_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("PATCH_04_DISPATCH");
    metrics.bump(ctx, "patch04.dispatch.calls");

    handler.handle(ctx, adapter, wrapper, validator, metrics);
}

void BaseDispatcher::dispatchLegacyHiddenStorage(BaseMonsterContext& ctx,
                                                 const Discovery05HiddenStorageHandler& handler,
                                                 const LegacyHiddenStorageAdapter& adapter,
                                                 const BaseValidationManager& validator,
                                                 const BaseMetricsShell& metrics) const {
    ctx.phase = "DISCOVERY_05_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("DISCOVERY_05_DISPATCH");
    metrics.bump(ctx, "discovery05.dispatch.calls");

    handler.handle(ctx, adapter, validator, metrics);
}

void BaseDispatcher::dispatchPatchedHiddenStorage(BaseMonsterContext& ctx,
                                                  const Patch05HiddenStorageHandler& handler,
                                                  const LegacyHiddenStorageAdapter& adapter,
                                                  const Patch05HiddenNearnessWrapper& wrapper,
                                                  const BaseValidationManager& validator,
                                                  const BaseMetricsShell& metrics) const {
    ctx.phase = "PATCH_05_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("PATCH_05_DISPATCH");
    metrics.bump(ctx, "patch05.dispatch.calls");

    handler.handle(ctx, adapter, wrapper, validator, metrics);
}

void BaseDispatcher::dispatchLegacyPrior(BaseMonsterContext& ctx,
                                         const Discovery06PriorHandler& handler,
                                         const LegacyPriorAdapter& adapter,
                                         const BaseValidationManager& validator,
                                         const BaseMetricsShell& metrics) const {
    ctx.phase = "DISCOVERY_06_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("DISCOVERY_06_DISPATCH");
    metrics.bump(ctx, "discovery06.dispatch.calls");

    handler.handle(ctx, adapter, validator, metrics);
}

void BaseDispatcher::dispatchPatchedPrior(BaseMonsterContext& ctx,
                                          const Patch06PriorHandler& handler,
                                          const LegacyPriorAdapter& adapter,
                                          const Patch06PriorWrapper& wrapper,
                                          const BaseValidationManager& validator,
                                          const BaseMetricsShell& metrics) const {
    ctx.phase = "PATCH_06_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("PATCH_06_DISPATCH");
    metrics.bump(ctx, "patch06.dispatch.calls");

    handler.handle(ctx, adapter, wrapper, validator, metrics);
}

void BaseDispatcher::dispatchLegacyGrindIndex(BaseMonsterContext& ctx,
                                                 const Discovery07GrindIndexHandler& handler,
                                                 const LegacyGrindTableAdapter& adapter,
                                                 const BaseValidationManager& validator,
                                                 const BaseMetricsShell& metrics) const {
    ctx.phase = "DISCOVERY_07_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("DISCOVERY_07_DISPATCH");
    metrics.bump(ctx, "discovery07.dispatch.calls");

    handler.handle(ctx, adapter, validator, metrics);
}

void BaseDispatcher::dispatchPatchedGrindIndex(BaseMonsterContext& ctx,
                                               const Patch07GrindIndexHandler& handler,
                                               const LegacyGrindTableAdapter& adapter,
                                               const Patch07SentinelGrindWrapper& wrapper,
                                               const BaseValidationManager& validator,
                                               const BaseMetricsShell& metrics) const {
    ctx.phase = "PATCH_07_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("PATCH_07_DISPATCH");
    metrics.bump(ctx, "patch07.dispatch.calls");
    handler.handle(ctx, adapter, wrapper, validator, metrics);
}

void BaseDispatcher::dispatchLegacyPermutationRank(BaseMonsterContext& ctx,
                                                   const Discovery08PermutationRankHandler& handler,
                                                   const LegacyPermutationAdapter& adapter,
                                                   const BaseValidationManager& validator,
                                                   const BaseMetricsShell& metrics) const {
    ctx.phase = "DISCOVERY_08_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("DISCOVERY_08_DISPATCH");
    metrics.bump(ctx, "discovery08.dispatch.calls");
    handler.handle(ctx, adapter, validator, metrics);
}

BaseRunReport BaseMonsterManager::execute(const Integer& calculationDay, const Integer& targetDay) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = calculationDay;
    ctx.targetDay = targetDay;
    ctx.phase = "BOOTSTRAP_NEW";
    ctx.status = "NEW";

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const BaseDispatcher dispatcher;
    dispatcher.dispatch(ctx, validator, metrics);

    return BaseRunReport{ctx.phase, ctx.status, ctx.branchTrace.size()};
}

LegacyRemainderReport BaseMonsterManager::executeLegacyRemainder(const Integer& x) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = 0;
    ctx.targetDay = 0;
    ctx.phase = "PATCH_01_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";
    ctx.legacyArithmeticInput = x;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyArithmeticAdapter adapter;
    const Patch01SaveWrapper wrapper;
    const Patch01RemainderHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchPatchedRemainder(ctx, handler, adapter, wrapper, validator, metrics);

    return LegacyRemainderReport{
        ctx.legacyArithmeticInput,
        ctx.patchedArithmeticOutput,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size(),
        ctx.legacyArithmeticOutput,
        ctx.patch01Applied
    };
}

LegacyRemainderReport BaseMonsterManager::executeUnpatchedRemainderDiagnostic(const Integer& x) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = 0;
    ctx.targetDay = 0;
    ctx.phase = "DISCOVERY_01_DIAGNOSTIC_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";
    ctx.legacyArithmeticInput = x;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyArithmeticAdapter adapter;
    const Discovery01RemainderHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchLegacyRemainder(ctx, handler, adapter, validator, metrics);

    return LegacyRemainderReport{
        ctx.legacyArithmeticInput,
        ctx.legacyArithmeticOutput,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size(),
        ctx.legacyArithmeticOutput,
        false
    };
}

LegacyDayTagReport BaseMonsterManager::executeLegacyDayTag(const Integer& day) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = day;
    ctx.targetDay = day;
    ctx.phase = "PATCH_02_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";
    ctx.legacyDayTagInput = day;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyDayTagAdapter adapter;
    const Patch02DayTagWrapper wrapper;
    const Patch02DayTagHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchPatchedDayTag(ctx, handler, adapter, wrapper, validator, metrics);

    return LegacyDayTagReport{
        ctx.legacyDayTagInput,
        ctx.patchedDayTagOutput,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size(),
        ctx.legacyDayTagOutput,
        ctx.patch02Applied
    };
}

LegacyDayTagReport BaseMonsterManager::executeUnpatchedDayTagDiagnostic(const Integer& day) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = day;
    ctx.targetDay = day;
    ctx.phase = "DISCOVERY_02_DIAGNOSTIC_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";
    ctx.legacyDayTagInput = day;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyDayTagAdapter adapter;
    const Discovery02DayTagHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchLegacyDayTag(ctx, handler, adapter, validator, metrics);

    return LegacyDayTagReport{
        ctx.legacyDayTagInput,
        ctx.legacyDayTagOutput,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size(),
        ctx.legacyDayTagOutput,
        false
    };
}

LegacyDistanceReport BaseMonsterManager::executeDistance(const Integer& calculationDay, const Integer& targetDay) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = calculationDay;
    ctx.targetDay = targetDay;
    ctx.phase = "PATCH_03_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";
    ctx.legacyDistanceCalculationDay = calculationDay;
    ctx.legacyDistanceTargetDay = targetDay;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyDistanceAdapter adapter;
    const Patch03DistanceWrapper wrapper;
    const Patch03DistanceHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchPatchedDistance(ctx, handler, adapter, wrapper, validator, metrics);

    return LegacyDistanceReport{
        ctx.legacyDistanceCalculationDay,
        ctx.legacyDistanceTargetDay,
        ctx.patchedDistanceOutput,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size(),
        ctx.legacyDistanceOutput,
        ctx.patch03Applied,
    };
}

LegacyDistanceReport BaseMonsterManager::executeUnpatchedDistanceDiagnostic(
    const Integer& calculationDay, const Integer& targetDay) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = calculationDay;
    ctx.targetDay = targetDay;
    ctx.phase = "DISCOVERY_03_DIAGNOSTIC_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";
    ctx.legacyDistanceCalculationDay = calculationDay;
    ctx.legacyDistanceTargetDay = targetDay;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyDistanceAdapter adapter;
    const Discovery03DistanceHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchLegacyDistance(ctx, handler, adapter, validator, metrics);

    return LegacyDistanceReport{
        ctx.legacyDistanceCalculationDay,
        ctx.legacyDistanceTargetDay,
        ctx.legacyDistanceOutput,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size(),
        ctx.legacyDistanceOutput,
        false,
    };
}

LegacyStoneTableReport BaseMonsterManager::executeStoneTable() const {
    BaseMonsterContext ctx;
    ctx.calculationDay = 0;
    ctx.targetDay = 0;
    ctx.phase = "PATCH_04_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyStoneMutationAdapter adapter;
    const Patch04StoneSnapshotWrapper wrapper;
    const Patch04StoneMutationHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchPatchedStoneMutation(ctx, handler, adapter, wrapper, validator, metrics);

    return LegacyStoneTableReport{
        ctx.patchedStoneTable,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size(),
        ctx.legacyStoneTable,
        ctx.patch04Applied,
    };
}

LegacyStoneTableReport BaseMonsterManager::executeUnpatchedStoneTableDiagnostic() const {
    BaseMonsterContext ctx;
    ctx.calculationDay = 0;
    ctx.targetDay = 0;
    ctx.phase = "DISCOVERY_04_DIAGNOSTIC_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyStoneMutationAdapter adapter;
    const Discovery04StoneMutationHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchLegacyStoneMutation(ctx, handler, adapter, validator, metrics);

    return LegacyStoneTableReport{
        ctx.legacyStoneTable,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size(),
        ctx.legacyStoneTable,
        false,
    };
}

LegacyHiddenReport BaseMonsterManager::executeHiddenDrops(const Integer& calculationDay,
                                                          const Integer& targetDay) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = calculationDay;
    ctx.targetDay = targetDay;
    ctx.phase = "PATCH_05_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyHiddenStorageAdapter adapter;
    const Patch05HiddenNearnessWrapper wrapper;
    const Patch05HiddenStorageHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchPatchedHiddenStorage(ctx, handler, adapter, wrapper, validator, metrics);

    return LegacyHiddenReport{
        ctx.calculationDay,
        ctx.targetDay,
        ctx.patchedHiddenNearness,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size(),
        ctx.legacyHiddenBackward,
        ctx.patch05Applied,
    };
}

LegacyHiddenReport BaseMonsterManager::executeUnpatchedHiddenStorageDiagnostic(
    const Integer& calculationDay, const Integer& targetDay) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = calculationDay;
    ctx.targetDay = targetDay;
    ctx.phase = "DISCOVERY_05_DIAGNOSTIC_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyHiddenStorageAdapter adapter;
    const Discovery05HiddenStorageHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchLegacyHiddenStorage(ctx, handler, adapter, validator, metrics);

    return LegacyHiddenReport{
        ctx.calculationDay,
        ctx.targetDay,
        ctx.legacyHiddenBackward,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size(),
        ctx.legacyHiddenBackward,
        false,
    };
}

LegacyPriorReport BaseMonsterManager::executePrior(const Integer& calculationDay,
                                                   const Integer& targetDay,
                                                   const VisibleDropStore& dropStore,
                                                   int i,
                                                   int back) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = calculationDay;
    ctx.targetDay = targetDay;
    ctx.phase = "PATCH_06_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";
    ctx.legacyPriorDropStore = dropStore;
    ctx.legacyPriorI = i;
    ctx.legacyPriorBack = back;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyPriorAdapter adapter;
    const Patch06PriorWrapper wrapper;
    const Patch06PriorHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchPatchedPrior(ctx, handler, adapter, wrapper, validator, metrics);

    return LegacyPriorReport{
        ctx.calculationDay,
        ctx.targetDay,
        ctx.legacyPriorI,
        ctx.legacyPriorBack,
        ctx.patchedPriorOutput,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size(),
        ctx.legacyPriorOutput,
        ctx.patch06LegacyPathUsed,
        ctx.patch06HiddenPathUsed,
        ctx.patch06Applied,
    };
}

LegacyPriorReport BaseMonsterManager::executeUnpatchedPriorDiagnostic(
    const Integer& calculationDay,
    const Integer& targetDay,
    const VisibleDropStore& dropStore,
    int i,
    int back) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = calculationDay;
    ctx.targetDay = targetDay;
    ctx.phase = "DISCOVERY_06_DIAGNOSTIC_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";
    ctx.legacyPriorDropStore = dropStore;
    ctx.legacyPriorI = i;
    ctx.legacyPriorBack = back;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyPriorAdapter adapter;
    const Discovery06PriorHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchLegacyPrior(ctx, handler, adapter, validator, metrics);

    return LegacyPriorReport{
        ctx.calculationDay,
        ctx.targetDay,
        ctx.legacyPriorI,
        ctx.legacyPriorBack,
        ctx.legacyPriorOutput,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size(),
        ctx.legacyPriorOutput,
        true,
        false,
        false,
    };
}

GrindLookupReport BaseMonsterManager::executeGrindRow(int grind) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = 0;
    ctx.targetDay = 0;
    ctx.phase = "PATCH_07_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";
    ctx.legacyGrindOrdinal = grind;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyGrindTableAdapter adapter;
    const Patch07SentinelGrindWrapper wrapper;
    const Patch07GrindIndexHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchPatchedGrindIndex(ctx, handler, adapter, wrapper, validator, metrics);

    return GrindLookupReport{ctx.legacyGrindOrdinal, ctx.patchedGrindOutput, ctx.patchedGrindFound,
        ctx.legacyGrindOrdinal, ctx.phase, ctx.status, ctx.currentHandler, ctx.branchTrace.size(),
        ctx.legacyGrindOutput, ctx.legacyGrindFound, ctx.patch07Applied};
}

GrindLookupReport BaseMonsterManager::executeUnpatchedGrindDiagnostic(int grind) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = 0;
    ctx.targetDay = 0;
    ctx.phase = "DISCOVERY_07_DIAGNOSTIC_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";
    ctx.legacyGrindOrdinal = grind;
    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyGrindTableAdapter adapter;
    const Discovery07GrindIndexHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchLegacyGrindIndex(ctx, handler, adapter, validator, metrics);
    return GrindLookupReport{ctx.legacyGrindOrdinal, ctx.legacyGrindOutput, ctx.legacyGrindFound,
        ctx.legacyGrindPhysicalIndex, ctx.phase, ctx.status, ctx.currentHandler, ctx.branchTrace.size(),
        ctx.legacyGrindOutput, ctx.legacyGrindFound, false};
}

PermutationRankReport BaseMonsterManager::executePermutationOrder(int oneBasedRank) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = 0;
    ctx.targetDay = 0;
    ctx.phase = "DISCOVERY_08_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";
    ctx.legacyPermutationCallerRank1 = oneBasedRank;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyPermutationAdapter adapter;
    const Discovery08PermutationRankHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchLegacyPermutationRank(ctx, handler, adapter, validator, metrics);

    return PermutationRankReport{
        ctx.legacyPermutationCallerRank1,
        ctx.legacyPermutationOutput,
        ctx.legacyPermutationFound,
        ctx.legacyPermutationRank0Input,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size(),
    };
}

} // namespace pastafari
