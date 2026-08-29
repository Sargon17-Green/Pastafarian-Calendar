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

Integer oldGateQuestionDay(const Integer& n) {
    return FOUNDATION_DAY_OLD + n;
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

LegacyFixedPourComputation legacyPoursToFixedBowlIds(const Integer& drop,
                                                     int index,
                                                     const BowlState& oldBowls,
                                                     const Stone& stoneRow) {
    if (index < 1 || index > 46) {
        throw BaseValidationError("index guttae visibilis inter unum et quadraginta sex requiritur");
    }

    const Integer oneBasedInteger = regularMod(drop - 1, Integer{720}) + 1;
    const int oneBased = oneBasedInteger.convert_to<int>();
    const PermutationOrder order = oldPermutationUnrank0(oneBased - 1);

    const Integer dropSquare = drop * drop;
    PourTriplet pours{};
    pours[0] = savePatch(dropSquare + stoneRow[0] * oldBowls[0] + 3 * index);
    pours[1] = savePatch(dropSquare + stoneRow[1] * oldBowls[1] + 5 * index);
    pours[2] = savePatch(dropSquare + stoneRow[2] * oldBowls[2] + 7 * index);

    return LegacyFixedPourComputation{order, {{1, 2, 3}}, pours};
}

BowlAlias installBowlAlias(const PermutationOrder& order) {
    BowlAlias alias{};
    for (std::size_t position = 0; position < alias.size(); ++position) {
        alias[position] = order[position];
    }
    return alias;
}

Integer bowlAtAliasedPosition(const BowlState& oldBowls,
                              const BowlAlias& bowlAlias,
                              int position) {
    if (position < 1 || position > 6) {
        throw BaseValidationError("positio crateris inter unum et sex requiritur");
    }
    const int bowlId = bowlAlias[static_cast<std::size_t>(position - 1)];
    if (bowlId < 1 || bowlId > 6) {
        throw BaseValidationError("bowlAlias ID crateris validum non continet");
    }
    return oldBowls[static_cast<std::size_t>(bowlId - 1)];
}

// Vitium legacy consulto manet: helper vetus crateres 1,2,3 directe legit.
// Patch 09 non callerem simplicificat; translationem permanentem positionis ad bowl ID addit.
// Quia order ipsa permutatio normativae craterarum est, bowlAlias[position]=order[position]
// eandem craterem eligit quam definitio fusionis pro illa positione.
BowlAliasPourComputation poursThroughBowlAlias(const Integer& drop,
                                               int index,
                                               const BowlState& oldBowls,
                                               const Stone& stoneRow,
                                               const PermutationOrder& order) {
    if (index < 1 || index > 46) {
        throw BaseValidationError("index guttae visibilis inter unum et quadraginta sex requiritur");
    }

    const BowlAlias alias = installBowlAlias(order);
    const std::array<int, 3> aliasedIds{{alias[0], alias[1], alias[2]}};
    const Integer dropSquare = drop * drop;
    PourTriplet pours{};
    pours[0] = savePatch(dropSquare + stoneRow[0] * bowlAtAliasedPosition(oldBowls, alias, 1) + 3 * index);
    pours[1] = savePatch(dropSquare + stoneRow[1] * bowlAtAliasedPosition(oldBowls, alias, 2) + 5 * index);
    pours[2] = savePatch(dropSquare + stoneRow[2] * bowlAtAliasedPosition(oldBowls, alias, 3) + 7 * index);
    return BowlAliasPourComputation{alias, aliasedIds, pours};
}

// Vitium legacy consulto exponitur: sex crateres eodem obiecto leguntur et statim scribuntur.
// Post primam scripturam positiones posteriores valores iam mutatos legere possunt; nullum snapshot separatum hic adest.
void legacyStirBowlsInPlace(BowlState& bowls,
                            int index,
                            const Integer& drop,
                            const Stone& stoneRow,
                            const PermutationOrder& order,
                            const PourTriplet& firstThreePours) {
    if (index < 1 || index > 46) {
        throw BaseValidationError("index commotionis craterum inter unum et quadraginta sex requiritur");
    }

    std::array<bool, 7> seen{};
    for (const int bowlId : order) {
        if (bowlId < 1 || bowlId > 6 || seen[static_cast<std::size_t>(bowlId)]) {
            throw BaseValidationError("ordo craterum pro commotione legacy permutatio valida non est");
        }
        seen[static_cast<std::size_t>(bowlId)] = true;
    }

    const std::array<std::size_t, 6> stoneByPosition{{0, 1, 2, 3, 4, 0}};
    for (std::size_t position = 0; position < order.size(); ++position) {
        const std::size_t prevPosition = (position + order.size() - 1) % order.size();
        const std::size_t nextPosition = (position + 1) % order.size();
        const int id = order[position];
        const int prev = order[prevPosition];
        const int next = order[nextPosition];
        const Integer pour = position < firstThreePours.size() ? firstThreePours[position] : Integer{0};

        const Integer s = bowls[static_cast<std::size_t>(id - 1)]
            + 2 * bowls[static_cast<std::size_t>(prev - 1)]
            + 3 * bowls[static_cast<std::size_t>(next - 1)]
            + pour
            + drop
            + stoneRow[stoneByPosition[position]];

        bowls[static_cast<std::size_t>(id - 1)] = savePatch(
            s * s
            + 5 * bowls[static_cast<std::size_t>(prev - 1)] * bowls[static_cast<std::size_t>(next - 1)]
            + index * static_cast<int>(position + 1));
    }
}


// Emendatio PATCH 10 cicatricem legacy non delet: omnes lectiones ex vaultOld fiunt,
// omnes sex exitus primum in pending conduntur, deinde tantum ut status novus exponuntur.
Patch10DeferredBowlComputation stirBowlsThroughVaultOld(const BowlState& bowls,
                                                        int index,
                                                        const Integer& drop,
                                                        const Stone& stoneRow,
                                                        const PermutationOrder& order,
                                                        const PourTriplet& firstThreePours) {
    if (index < 1 || index > 46) {
        throw BaseValidationError("index commotionis craterum inter unum et quadraginta sex requiritur");
    }

    std::array<bool, 7> seen{};
    for (const int bowlId : order) {
        if (bowlId < 1 || bowlId > 6 || seen[static_cast<std::size_t>(bowlId)]) {
            throw BaseValidationError("ordo craterum pro commotione patch decima permutatio valida non est");
        }
        seen[static_cast<std::size_t>(bowlId)] = true;
    }

    const BowlState vaultOld = bowls;
    BowlState pending = bowls;
    const std::array<std::size_t, 6> stoneByPosition{{0, 1, 2, 3, 4, 0}};

    for (std::size_t position = 0; position < order.size(); ++position) {
        const std::size_t prevPosition = (position + order.size() - 1) % order.size();
        const std::size_t nextPosition = (position + 1) % order.size();
        const int id = order[position];
        const int prev = order[prevPosition];
        const int next = order[nextPosition];
        const Integer pour = position < firstThreePours.size() ? firstThreePours[position] : Integer{0};

        const Integer s = vaultOld[static_cast<std::size_t>(id - 1)]
            + 2 * vaultOld[static_cast<std::size_t>(prev - 1)]
            + 3 * vaultOld[static_cast<std::size_t>(next - 1)]
            + pour
            + drop
            + stoneRow[stoneByPosition[position]];

        pending[static_cast<std::size_t>(id - 1)] = savePatch(
            s * s
            + 5 * vaultOld[static_cast<std::size_t>(prev - 1)] * vaultOld[static_cast<std::size_t>(next - 1)]
            + index * static_cast<int>(position + 1));
    }

    return Patch10DeferredBowlComputation{vaultOld, pending, pending};
}

LegacySauceCounts sauceCountsThroughScars(const Integer& calculationDay,
                                          const Integer& targetDay) {
    const Integer action = dayTagWithFoundationScar(calculationDay);
    const Integer target = dayTagWithFoundationScar(targetDay);
    const Integer legacyDistantia = oldDistance(calculationDay, targetDay);
    const Integer distance = distanceWithChronologicalPatch(
        calculationDay, targetDay, legacyDistantia);
    const Integer connection = action + target;
    const int direction = targetDay < calculationDay ? 1
                        : targetDay == calculationDay ? 2
                                                      : 3;
    return LegacySauceCounts{action, target, distance, connection, direction};
}

VisibleDropStore buildVisibleDropsThroughPatchedHistory(const LegacySauceCounts& counts,
                                                        const StoneTable& stones,
                                                        const HiddenDrops& backwardStorage) {
    VisibleDropStore visible;
    visible.reserve(46);

    for (int i = 1; i <= 46; ++i) {
        const Integer p1 = priorPatch(visible, backwardStorage, i, 1);
        const Integer p3 = priorPatch(visible, backwardStorage, i, 3);
        const Integer p7 = priorPatch(visible, backwardStorage, i, 7);

        Integer x = savePatch(
            stones[static_cast<std::size_t>(i)][0] * counts.action
            + stones[static_cast<std::size_t>(i)][1] * counts.target
            + stones[static_cast<std::size_t>(i)][2] * counts.distance
            + stones[static_cast<std::size_t>(i)][3] * counts.connection
            + stones[static_cast<std::size_t>(i)][4] * counts.direction
            + p1 + 3 * p3 + 5 * p7 + i);

        for (int grind = 1; grind <= 11; ++grind) {
            // Lectio legacy fit vere, sed index directus eius iam cicatrix diagnostica est.
            (void)legacyGrindRow(grind);
            const LegacyGrindLookup lookup = grindRowWithSentinel(grind);
            if (!lookup.found) {
                throw BaseValidationError("ordo molitionis post sentinellam abest");
            }
            const int kind = static_cast<int>(lookup.row.kind);
            if (kind < 0 || kind > 4) {
                throw BaseValidationError("genus lapidis molitionis visibilis invalidum est");
            }
            const Integer oldX = x;
            x = savePatch(
                oldX * oldX
                + lookup.row.a * oldX
                + lookup.row.b * p1
                + lookup.row.c * p3
                + lookup.row.d * p7
                + stones[static_cast<std::size_t>(i)][static_cast<std::size_t>(kind)]);
        }
        visible.push_back(x);
    }
    return visible;
}

BowlState initialBowlsThroughCounts(const LegacySauceCounts& counts) {
    static constexpr std::array<int, 6> primes{{17, 19, 23, 29, 31, 37}};
    BowlState bowls{};
    for (int bowlId = 1; bowlId <= 6; ++bowlId) {
        const Integer s = counts.action
                        + counts.target * bowlId
                        + counts.distance
                        + counts.connection
                        + counts.direction
                        + Integer{primes[static_cast<std::size_t>(bowlId - 1)]}
                            * primes[static_cast<std::size_t>(bowlId - 1)];
        bowls[static_cast<std::size_t>(bowlId - 1)] = savePatch(s * s + bowlId);
    }
    return bowls;
}

LegacyOrderMemorySauceResult legacySauceWithOverwritableOrderMemory(
    const Integer& calculationDay,
    const Integer& targetDay) {
    const LegacySauceCounts counts = sauceCountsThroughScars(calculationDay, targetDay);
    const StoneTable stones = buildStonesThroughLegacyBuilder();
    const HiddenDrops hiddenBackward = buildHiddenWithBackwardStorage(
        calculationDay, targetDay, stones);
    const VisibleDropStore visible = buildVisibleDropsThroughPatchedHistory(
        counts, stones, hiddenBackward);

    BowlState bowls = initialBowlsThroughCounts(counts);
    PermutationOrder legacyOrderMemory{};
    PermutationOrder orderAtDrop46Diagnostic{};
    PermutationOrder finalPostStirOrder{};
    std::size_t writes = 0;
    std::string finalSource;

    for (int i = 1; i <= 46; ++i) {
        const Integer& drop = visible[static_cast<std::size_t>(i - 1)];
        const int oneBased = (regularMod(drop - 1, Integer{720}) + 1).convert_to<int>();

        // Cicatrix rank0 vocatur reapse ante pontem one-based; error 720 tantum diagnosticus est.
        try {
            (void)oldPermutationUnrank0(oneBased);
        } catch (const BaseValidationError&) {
        }
        const PermutationOrder order = oldPermutationUnrank0(oneBased - 1);

        // Cicatrix fusionum ad IDs fixos etiam currit, sed bowlAlias dat exitum semanticum.
        (void)legacyPoursToFixedBowlIds(
            drop, i, bowls, stones[static_cast<std::size_t>(i)]);
        const BowlAliasPourComputation pours = poursThroughBowlAlias(
            drop, i, bowls, stones[static_cast<std::size_t>(i)], order);

        // Cicatrix contaminationis in-place currit in clone separato; vaultOld/pending reparant viam semanticam.
        BowlState garbage = bowls;
        legacyStirBowlsInPlace(
            garbage, i, drop, stones[static_cast<std::size_t>(i)], order, pours.pours);
        const Patch10DeferredBowlComputation repaired = stirBowlsThroughVaultOld(
            bowls, i, drop, stones[static_cast<std::size_t>(i)], order, pours.pours);
        bowls = repaired.output;

        legacyOrderMemory = order;
        ++writes;
        finalSource = "gutta visibilis " + std::to_string(i);
        if (i == 46) {
            orderAtDrop46Diagnostic = order;
        }
    }

    for (int stir = 1; stir <= 12; ++stir) {
        const BowlState old = bowls;
        Integer savedBowlSum = 0;
        for (const Integer& bowl : old) {
            savedBowlSum += bowl;
        }
        savedBowlSum = savePatch(savedBowlSum + 149 * stir);
        const int oneBased = (regularMod(savedBowlSum - 1, Integer{720}) + 1).convert_to<int>();
        const PermutationOrder order = oldPermutationUnrank0(oneBased - 1);

        BowlState pending = old;
        for (int position = 1; position <= 6; ++position) {
            const std::size_t pos = static_cast<std::size_t>(position - 1);
            const std::size_t prevPos = static_cast<std::size_t>((position + 4) % 6);
            const std::size_t nextPos = static_cast<std::size_t>(position % 6);
            const int id = order[pos];
            const int prev = order[prevPos];
            const int next = order[nextPos];
            const Integer s = old[static_cast<std::size_t>(id - 1)]
                            + 3 * old[static_cast<std::size_t>(prev - 1)]
                            + 5 * old[static_cast<std::size_t>(next - 1)]
                            + savedBowlSum
                            + stir
                            + position * position;
            pending[static_cast<std::size_t>(id - 1)] = savePatch(
                s * s
                + 7 * old[static_cast<std::size_t>(prev - 1)]
                    * old[static_cast<std::size_t>(next - 1)]);
        }
        bowls = pending;

        legacyOrderMemory = order;
        finalPostStirOrder = order;
        ++writes;
        finalSource = "post-commotio " + std::to_string(stir);
    }

    return LegacyOrderMemorySauceResult{
        bowls,
        legacyOrderMemory,
        orderAtDrop46Diagnostic,
        finalPostStirOrder,
        writes,
        finalSource
    };
}

Patch11LatchedOrderSauceResult sauceWithOrderAt46Latch(
    const Integer& calculationDay,
    const Integer& targetDay) {
    const LegacySauceCounts counts = sauceCountsThroughScars(calculationDay, targetDay);
    const StoneTable stones = buildStonesThroughLegacyBuilder();
    const HiddenDrops hiddenBackward = buildHiddenWithBackwardStorage(
        calculationDay, targetDay, stones);
    const VisibleDropStore visible = buildVisibleDropsThroughPatchedHistory(
        counts, stones, hiddenBackward);

    BowlState bowls = initialBowlsThroughCounts(counts);
    PermutationOrder legacyOrderMemory{};
    PermutationOrder orderAt46Latch{};
    PermutationOrder finalPostStirOrder{};
    std::size_t legacyWrites = 0;
    std::size_t latchWrites = 0;
    std::string finalLegacySource;

    for (int i = 1; i <= 46; ++i) {
        const Integer& drop = visible[static_cast<std::size_t>(i - 1)];
        const int oneBased = (regularMod(drop - 1, Integer{720}) + 1).convert_to<int>();

        // Cicatrix rank0 manet activa ante pontem semanticum.
        try {
            (void)oldPermutationUnrank0(oneBased);
        } catch (const BaseValidationError&) {
        }
        const PermutationOrder order = oldPermutationUnrank0(oneBased - 1);

        // Cicatrix fusionum ad crateres fixos vocatur, deinde bowlAlias viam semanticam reparat.
        (void)legacyPoursToFixedBowlIds(
            drop, i, bowls, stones[static_cast<std::size_t>(i)]);
        const BowlAliasPourComputation pours = poursThroughBowlAlias(
            drop, i, bowls, stones[static_cast<std::size_t>(i)], order);

        // Cicatrix mutationis in-place currit in clone; vaultOld/pending custodiunt exitum semanticum.
        BowlState garbage = bowls;
        legacyStirBowlsInPlace(
            garbage, i, drop, stones[static_cast<std::size_t>(i)], order, pours.pours);
        const Patch10DeferredBowlComputation repaired = stirBowlsThroughVaultOld(
            bowls, i, drop, stones[static_cast<std::size_t>(i)], order, pours.pours);
        bowls = repaired.output;

        legacyOrderMemory = order;
        ++legacyWrites;
        finalLegacySource = "gutta visibilis " + std::to_string(i);

        if (i == 46) {
            if (latchWrites != 0) {
                throw BaseValidationError("orderAt46Latch iterum scribi non licet");
            }
            orderAt46Latch = order;
            ++latchWrites;
        }
    }

    if (latchWrites != 1) {
        throw BaseValidationError("orderAt46Latch semel ante post-commotiones scribendus est");
    }

    for (int stir = 1; stir <= 12; ++stir) {
        const BowlState old = bowls;
        Integer savedBowlSum = 0;
        for (const Integer& bowl : old) {
            savedBowlSum += bowl;
        }
        savedBowlSum = savePatch(savedBowlSum + 149 * stir);
        const int oneBased = (regularMod(savedBowlSum - 1, Integer{720}) + 1).convert_to<int>();
        const PermutationOrder order = oldPermutationUnrank0(oneBased - 1);

        BowlState pending = old;
        for (int position = 1; position <= 6; ++position) {
            const std::size_t pos = static_cast<std::size_t>(position - 1);
            const std::size_t prevPos = static_cast<std::size_t>((position + 4) % 6);
            const std::size_t nextPos = static_cast<std::size_t>(position % 6);
            const int id = order[pos];
            const int prev = order[prevPos];
            const int next = order[nextPos];
            const Integer s = old[static_cast<std::size_t>(id - 1)]
                            + 3 * old[static_cast<std::size_t>(prev - 1)]
                            + 5 * old[static_cast<std::size_t>(next - 1)]
                            + savedBowlSum
                            + stir
                            + position * position;
            pending[static_cast<std::size_t>(id - 1)] = savePatch(
                s * s
                + 7 * old[static_cast<std::size_t>(prev - 1)]
                    * old[static_cast<std::size_t>(next - 1)]);
        }
        bowls = pending;

        // Post-commotiones adhuc memoriam legacy superscribunt, sed latch separatum numquam tangunt.
        legacyOrderMemory = order;
        finalPostStirOrder = order;
        ++legacyWrites;
        finalLegacySource = "post-commotio " + std::to_string(stir);
    }

    return Patch11LatchedOrderSauceResult{
        bowls,
        orderAt46Latch,
        orderAt46Latch,
        legacyOrderMemory,
        finalPostStirOrder,
        legacyWrites,
        latchWrites,
        finalLegacySource
    };
}

int oldNextBowlFixedName(int id) {
    if (id < 1 || id > 6) {
        throw BaseValidationError("ID crateris inter unum et sex requiritur");
    }
    return id == 6 ? 1 : id + 1;
}

int nextBowlThroughOrderAt46Latch(const PermutationOrder& orderAt46Latch,
                                  int queriedBowlId) {
    if (queriedBowlId < 1 || queriedBowlId > 6) {
        throw BaseValidationError("ID crateris inter unum et sex requiritur");
    }
    for (std::size_t i = 0; i < orderAt46Latch.size(); ++i) {
        if (orderAt46Latch[i] == queriedBowlId) {
            return orderAt46Latch[(i + 1) % orderAt46Latch.size()];
        }
    }
    throw BaseValidationError("ID crateris in orderAt46Latch non inventus est");
}

LegacyAnswerRing answerRingThroughPatchedNextBowl(const BowlState& finalBowls,
                                                   int queriedBowlId,
                                                   int nextBowlId,
                                                   int seal) {
    if (queriedBowlId < 1 || queriedBowlId > 6 || nextBowlId < 1 || nextBowlId > 6) {
        throw BaseValidationError("ID crateris pro annulo responsorum invalidus est");
    }
    const Integer queried = finalBowls[static_cast<std::size_t>(queriedBowlId - 1)];
    const Integer next = finalBowls[static_cast<std::size_t>(nextBowlId - 1)];
    const Integer firstBase = queried + seal + 181;
    const Integer first = savePatch(firstBase * firstBase + 179 * next + seal);
    const Integer directionBase = first + seal + 1 + 193;
    const Integer directionNumber = savePatch(
        directionBase * directionBase
        + 193 * first
        + 197 * finalBowls[5]);
    const int directionStep = regularMod(directionNumber, Integer{2}) == 1 ? 1 : -1;
    return LegacyAnswerRing{first, directionStep};
}

Integer ringAnswer(const LegacyAnswerRing& stream, const Integer& offset) {
    if (stream.directionStep != -1 && stream.directionStep != 1) {
        throw BaseValidationError("gradus annuli responsorum debet esse -1 aut +1");
    }
    return 1 + regularMod(
        stream.first - 1 + Integer{stream.directionStep} * offset,
        M_OLD);
}

Integer biasedLegacyPick(const Integer& x, const Integer& N) {
    if (N < 1) {
        throw BaseValidationError("magnitudo familiae positiva requiritur");
    }
    return regularMod(x - 1, N) + 1;
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

void BaseValidationManager::requirePatch08Ready(const BaseMonsterContext& ctx) const {
    requireLegacyPermutationReady(ctx);
    if (!ctx.patch08Applied || !ctx.patchedPermutationFound) {
        throw BaseValidationError("emendatio octava permutationis nondum applicata est");
    }

    const Integer oneBasedInteger = regularMod(ctx.patch08PermutationDrop - 1, Integer{720}) + 1;
    const int oneBased = oneBasedInteger.convert_to<int>();
    const int legacyRank0 = oneBased - 1;
    if (ctx.patchedPermutationOneBased != oneBased ||
        ctx.patchedPermutationLegacyRank0 != legacyRank0) {
        throw BaseValidationError("pons one-based ad rank0 permutationis non servatus est");
    }
    if (ctx.patchedPermutationOutput != oldPermutationUnrank0(legacyRank0)) {
        throw BaseValidationError("ordo permutationis post pontem rank0 normam non servat");
    }
}

void BaseValidationManager::requireLegacyFixedPourReady(const BaseMonsterContext& ctx) const {
    if (!ctx.legacyFixedPourReady) {
        throw BaseValidationError("tres fusiones legacy nondum paratae sunt");
    }
    if (ctx.legacyFixedPourIndex < 1 || ctx.legacyFixedPourIndex > 46) {
        throw BaseValidationError("index fusionis legacy extra fines est");
    }
    if (ctx.legacyFixedPourBowlIds != std::array<int, 3>{{1, 2, 3}}) {
        throw BaseValidationError("legacy IDs craterarum fixos unum duo tria non servavit");
    }

    std::array<bool, 7> seen{};
    for (const int bowlId : ctx.legacyFixedPourOrder) {
        if (bowlId < 1 || bowlId > 6 || seen[static_cast<std::size_t>(bowlId)]) {
            throw BaseValidationError("ordo craterarum fusionis legacy permutatio valida non est");
        }
        seen[static_cast<std::size_t>(bowlId)] = true;
    }
}

void BaseValidationManager::requirePatch09Ready(const BaseMonsterContext& ctx) const {
    requireLegacyFixedPourReady(ctx);
    if (!ctx.patch09Applied) {
        throw BaseValidationError("emendatio nona bowlAlias nondum applicata est");
    }
    if (ctx.bowlAlias != ctx.legacyFixedPourOrder) {
        throw BaseValidationError("bowlAlias ordinem permutationis non servat");
    }

    std::array<bool, 7> seen{};
    for (const int bowlId : ctx.bowlAlias) {
        if (bowlId < 1 || bowlId > 6 || seen[static_cast<std::size_t>(bowlId)]) {
            throw BaseValidationError("bowlAlias permutatio valida craterarum non est");
        }
        seen[static_cast<std::size_t>(bowlId)] = true;
    }

    const std::array<int, 3> expectatiIds{{ctx.bowlAlias[0], ctx.bowlAlias[1], ctx.bowlAlias[2]}};
    if (ctx.aliasedFixedPourBowlIds != expectatiIds) {
        throw BaseValidationError("IDs craterarum per bowlAlias non respondent primis tribus positionibus");
    }

    const Integer quadratum = ctx.legacyFixedPourDrop * ctx.legacyFixedPourDrop;
    PourTriplet expectatae{};
    expectatae[0] = savePatch(
        quadratum + ctx.legacyFixedPourStoneRow[0] *
            ctx.legacyFixedPourOldBowls[static_cast<std::size_t>(ctx.bowlAlias[0] - 1)] +
        3 * ctx.legacyFixedPourIndex);
    expectatae[1] = savePatch(
        quadratum + ctx.legacyFixedPourStoneRow[1] *
            ctx.legacyFixedPourOldBowls[static_cast<std::size_t>(ctx.bowlAlias[1] - 1)] +
        5 * ctx.legacyFixedPourIndex);
    expectatae[2] = savePatch(
        quadratum + ctx.legacyFixedPourStoneRow[2] *
            ctx.legacyFixedPourOldBowls[static_cast<std::size_t>(ctx.bowlAlias[2] - 1)] +
        7 * ctx.legacyFixedPourIndex);
    if (ctx.patchedFixedPourOutput != expectatae) {
        throw BaseValidationError("fusiones post bowlAlias normam positionum non servant");
    }
}

void BaseValidationManager::requireLegacyInPlaceBowlReady(const BaseMonsterContext& ctx) const {
    if (!ctx.legacyInPlaceBowlReady) {
        throw BaseValidationError("commotio craterum in-place legacy nondum parata est");
    }
    if (ctx.legacyInPlaceBowlIndex < 1 || ctx.legacyInPlaceBowlIndex > 46) {
        throw BaseValidationError("index commotionis craterum legacy extra fines est");
    }

    BowlState copy = ctx.legacyInPlaceBowlInput;
    legacyStirBowlsInPlace(copy,
                           ctx.legacyInPlaceBowlIndex,
                           ctx.legacyInPlaceBowlDrop,
                           ctx.legacyInPlaceBowlStoneRow,
                           ctx.legacyInPlaceBowlOrder,
                           ctx.legacyInPlaceBowlPours);
    if (copy != ctx.legacyInPlaceBowlOutput) {
        throw BaseValidationError("commotio legacy repetita exitum alium dedit");
    }
}


void BaseValidationManager::requirePatch10Ready(const BaseMonsterContext& ctx) const {
    requireLegacyInPlaceBowlReady(ctx);
    if (!ctx.patch10Applied) {
        throw BaseValidationError("emendatio decima nondum applicata est");
    }
    if (ctx.bowlVaultOld != ctx.legacyInPlaceBowlInput) {
        throw BaseValidationError("vaultOld statum craterum initialem integre servare debet");
    }

    BowlState expectata = ctx.legacyInPlaceBowlInput;
    const BowlState antiqua = ctx.legacyInPlaceBowlInput;
    const std::array<std::size_t, 6> stoneByPosition{{0, 1, 2, 3, 4, 0}};
    std::array<bool, 7> seen{};
    for (const int bowlId : ctx.legacyInPlaceBowlOrder) {
        if (bowlId < 1 || bowlId > 6 || seen[static_cast<std::size_t>(bowlId)]) {
            throw BaseValidationError("ordo craterum patch decima permutatio valida non est");
        }
        seen[static_cast<std::size_t>(bowlId)] = true;
    }

    for (std::size_t position = 0; position < ctx.legacyInPlaceBowlOrder.size(); ++position) {
        const std::size_t prevPosition = (position + ctx.legacyInPlaceBowlOrder.size() - 1)
            % ctx.legacyInPlaceBowlOrder.size();
        const std::size_t nextPosition = (position + 1) % ctx.legacyInPlaceBowlOrder.size();
        const int id = ctx.legacyInPlaceBowlOrder[position];
        const int prev = ctx.legacyInPlaceBowlOrder[prevPosition];
        const int next = ctx.legacyInPlaceBowlOrder[nextPosition];
        const Integer pour = position < ctx.legacyInPlaceBowlPours.size()
            ? ctx.legacyInPlaceBowlPours[position]
            : Integer{0};
        const Integer s = antiqua[static_cast<std::size_t>(id - 1)]
            + 2 * antiqua[static_cast<std::size_t>(prev - 1)]
            + 3 * antiqua[static_cast<std::size_t>(next - 1)]
            + pour
            + ctx.legacyInPlaceBowlDrop
            + ctx.legacyInPlaceBowlStoneRow[stoneByPosition[position]];
        expectata[static_cast<std::size_t>(id - 1)] = savePatch(
            s * s
            + 5 * antiqua[static_cast<std::size_t>(prev - 1)] * antiqua[static_cast<std::size_t>(next - 1)]
            + ctx.legacyInPlaceBowlIndex * static_cast<int>(position + 1));
    }

    if (ctx.bowlPending != expectata || ctx.patchedInPlaceBowlOutput != expectata) {
        throw BaseValidationError("pending et exitus patch decimae non respondent calculationi ex vaultOld");
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

LegacyFixedPourComputation LegacyFixedPourAdapter::compute(const Integer& drop,
                                                           int index,
                                                           const BowlState& oldBowls,
                                                           const Stone& stoneRow) const {
    return legacyPoursToFixedBowlIds(drop, index, oldBowls, stoneRow);
}

BowlAliasPourComputation Patch09BowlAliasWrapper::repair(const Integer& drop,
                                                         int index,
                                                         const BowlState& oldBowls,
                                                         const Stone& stoneRow,
                                                         const PermutationOrder& order) const {
    return poursThroughBowlAlias(drop, index, oldBowls, stoneRow, order);
}

BowlState LegacyInPlaceBowlAdapter::stir(const BowlState& bowls,
                                         int index,
                                         const Integer& drop,
                                         const Stone& stoneRow,
                                         const PermutationOrder& order,
                                         const PourTriplet& firstThreePours) const {
    BowlState altered = bowls;
    legacyStirBowlsInPlace(altered, index, drop, stoneRow, order, firstThreePours);
    return altered;
}


Patch10DeferredBowlComputation Patch10DeferredBowlWrapper::repair(
    const BowlState& bowls,
    int index,
    const Integer& drop,
    const Stone& stoneRow,
    const PermutationOrder& order,
    const PourTriplet& firstThreePours) const {
    return stirBowlsThroughVaultOld(bowls, index, drop, stoneRow, order, firstThreePours);
}
LegacyGrindLookup Patch07SentinelGrindWrapper::read(int grind) const {
    return grindRowWithSentinel(grind);
}

PermutationOrder LegacyPermutationAdapter::unrank0(int rank0) const {
    return oldPermutationUnrank0(rank0);
}

// Vitium legacy consulto manet: helper rank0 non mutatur; pons one-based tantum ante eum additur, quia oneBased-1 eundem ordinem normativum eligit.
Patch08PermutationResolution Patch08PermutationRankWrapper::resolve(
    const Integer& drop, const LegacyPermutationAdapter& adapter) const {
    const Integer oneBasedInteger = regularMod(drop - 1, Integer{720}) + 1;
    const int oneBased = oneBasedInteger.convert_to<int>();
    const int legacyRank0 = oneBased - 1;
    return Patch08PermutationResolution{oneBased, legacyRank0, adapter.unrank0(legacyRank0)};
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

void Patch08PermutationRankHandler::handle(BaseMonsterContext& ctx,
                                            const LegacyPermutationAdapter& adapter,
                                            const Patch08PermutationRankWrapper& wrapper,
                                            const BaseValidationManager& validator,
                                            const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Patch08PermutationRankHandler";
    ctx.phase = "PATCH_08_LEGACY_PERMUTATION_CALL";
    ctx.status = "LEGACY_PERMUTATION_CALLED_BEFORE_PATCH";
    ctx.branchTrace.push_back("PATCH_08_LEGACY_PERMUTATION_CALL");
    metrics.bump(ctx, "patch08.permutation.legacy.calls");

    const Integer normalizedOneBasedInteger = regularMod(ctx.patch08PermutationDrop - 1, Integer{720}) + 1;
    ctx.legacyPermutationCallerRank1 = normalizedOneBasedInteger.convert_to<int>();
    ctx.legacyPermutationRank0Input = ctx.legacyPermutationCallerRank1;
    try {
        ctx.legacyPermutationOutput = adapter.unrank0(ctx.legacyPermutationRank0Input);
        ctx.legacyPermutationFound = true;
    } catch (const BaseValidationError&) {
        ctx.legacyPermutationOutput = PermutationOrder{};
        ctx.legacyPermutationFound = false;
    }
    ctx.legacyPermutationReady = true;

    ctx.phase = "PATCH_08_ONE_BASED_TO_ZERO_BASED_BRIDGE";
    ctx.branchTrace.push_back("PATCH_08_ONE_BASED_TO_ZERO_BASED_BRIDGE");
    const Patch08PermutationResolution repaired = wrapper.resolve(ctx.patch08PermutationDrop, adapter);
    ctx.patchedPermutationOneBased = repaired.oneBased;
    ctx.patchedPermutationLegacyRank0 = repaired.legacyRank0;
    ctx.patchedPermutationOutput = repaired.order;
    ctx.patchedPermutationFound = true;
    ctx.patch08Applied = true;
    metrics.bump(ctx, "patch08.permutation.bridge.calls");

    ctx.phase = "PATCH_08_VALIDATE";
    ctx.branchTrace.push_back("PATCH_08_VALIDATE");
    validator.requirePatch08Ready(ctx);

    ctx.phase = "PATCH_08_PERMUTATION_READY";
    ctx.status = "PATCHED_PERMUTATION_ORDER_EXPOSED";
    ctx.branchTrace.push_back("PATCH_08_PERMUTATION_READY");
    metrics.bump(ctx, "patch08.permutation.ready");
}

void Discovery09FixedPourHandler::handle(BaseMonsterContext& ctx,
                                         const LegacyFixedPourAdapter& adapter,
                                         const BaseValidationManager& validator,
                                         const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Discovery09FixedPourHandler";
    ctx.phase = "DISCOVERY_09_FIXED_BOWL_POURS_CALL";
    ctx.status = "LEGACY_FIXED_BOWL_POURS_ACTIVE";
    ctx.branchTrace.push_back("DISCOVERY_09_FIXED_BOWL_POURS_CALL");
    metrics.bump(ctx, "discovery09.pours.calls");

    const LegacyFixedPourComputation legacy = adapter.compute(
        ctx.legacyFixedPourDrop,
        ctx.legacyFixedPourIndex,
        ctx.legacyFixedPourOldBowls,
        ctx.legacyFixedPourStoneRow);
    ctx.legacyFixedPourOrder = legacy.order;
    ctx.legacyFixedPourBowlIds = legacy.fixedBowlIds;
    ctx.legacyFixedPourOutput = legacy.pours;
    ctx.legacyFixedPourReady = true;

    ctx.phase = "DISCOVERY_09_FIXED_BOWL_POURS_VALIDATE";
    ctx.branchTrace.push_back("DISCOVERY_09_FIXED_BOWL_POURS_VALIDATE");
    validator.requireLegacyFixedPourReady(ctx);

    ctx.phase = "DISCOVERY_09_FIXED_BOWL_POURS_EXPOSED";
    ctx.status = "LEGACY_FIXED_BOWL_POURS_EXPOSED";
    ctx.branchTrace.push_back("DISCOVERY_09_FIXED_BOWL_POURS_EXPOSED");
    metrics.bump(ctx, "discovery09.pours.exposed");
}

 void Patch09BowlAliasHandler::handle(BaseMonsterContext& ctx,
                                     const LegacyFixedPourAdapter& adapter,
                                     const Patch09BowlAliasWrapper& wrapper,
                                     const BaseValidationManager& validator,
                                     const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Patch09BowlAliasHandler";
    ctx.phase = "PATCH_09_LEGACY_FIXED_BOWL_POURS_CALL";
    ctx.status = "LEGACY_FIXED_BOWL_POURS_CALLED_BEFORE_ALIAS";
    ctx.branchTrace.push_back("PATCH_09_LEGACY_FIXED_BOWL_POURS_CALL");
    metrics.bump(ctx, "patch09.legacy.pours.calls");

    const LegacyFixedPourComputation legacy = adapter.compute(
        ctx.legacyFixedPourDrop,
        ctx.legacyFixedPourIndex,
        ctx.legacyFixedPourOldBowls,
        ctx.legacyFixedPourStoneRow);
    ctx.legacyFixedPourOrder = legacy.order;
    ctx.legacyFixedPourBowlIds = legacy.fixedBowlIds;
    ctx.legacyFixedPourOutput = legacy.pours;
    ctx.legacyFixedPourReady = true;

    ctx.phase = "PATCH_09_BOWL_ALIAS_INSTALL";
    ctx.branchTrace.push_back("PATCH_09_BOWL_ALIAS_INSTALL");
    const BowlAliasPourComputation repaired = wrapper.repair(
        ctx.legacyFixedPourDrop,
        ctx.legacyFixedPourIndex,
        ctx.legacyFixedPourOldBowls,
        ctx.legacyFixedPourStoneRow,
        ctx.legacyFixedPourOrder);
    ctx.bowlAlias = repaired.bowlAlias;
    ctx.aliasedFixedPourBowlIds = repaired.aliasedBowlIds;
    ctx.patchedFixedPourOutput = repaired.pours;
    ctx.patch09Applied = true;
    metrics.bump(ctx, "patch09.bowlAlias.calls");

    ctx.phase = "PATCH_09_VALIDATE";
    ctx.branchTrace.push_back("PATCH_09_VALIDATE");
    validator.requirePatch09Ready(ctx);

    ctx.phase = "PATCH_09_ALIAS_POURS_READY";
    ctx.status = "PATCHED_ALIAS_POURS_EXPOSED";
    ctx.branchTrace.push_back("PATCH_09_ALIAS_POURS_READY");
    metrics.bump(ctx, "patch09.pours.ready");
}

void Discovery10InPlaceBowlHandler::handle(BaseMonsterContext& ctx,
                                            const LegacyInPlaceBowlAdapter& adapter,
                                            const BaseValidationManager& validator,
                                            const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Discovery10InPlaceBowlHandler";
    ctx.phase = "DISCOVERY_10_IN_PLACE_BOWL_STIR_CALL";
    ctx.status = "LEGACY_IN_PLACE_BOWL_STIR_ACTIVE";
    ctx.branchTrace.push_back("DISCOVERY_10_IN_PLACE_BOWL_STIR_CALL");
    metrics.bump(ctx, "discovery10.inPlaceBowl.calls");

    ctx.legacyInPlaceBowlOutput = adapter.stir(
        ctx.legacyInPlaceBowlInput,
        ctx.legacyInPlaceBowlIndex,
        ctx.legacyInPlaceBowlDrop,
        ctx.legacyInPlaceBowlStoneRow,
        ctx.legacyInPlaceBowlOrder,
        ctx.legacyInPlaceBowlPours);
    ctx.legacyInPlaceBowlReady = true;

    ctx.phase = "DISCOVERY_10_IN_PLACE_BOWL_STIR_VALIDATE";
    ctx.branchTrace.push_back("DISCOVERY_10_IN_PLACE_BOWL_STIR_VALIDATE");
    validator.requireLegacyInPlaceBowlReady(ctx);

    ctx.phase = "DISCOVERY_10_IN_PLACE_BOWL_STIR_EXPOSED";
    ctx.status = "LEGACY_IN_PLACE_BOWL_STIR_EXPOSED";
    ctx.branchTrace.push_back("DISCOVERY_10_IN_PLACE_BOWL_STIR_EXPOSED");
    metrics.bump(ctx, "discovery10.inPlaceBowl.exposed");
}


void Patch10InPlaceBowlHandler::handle(BaseMonsterContext& ctx,
                                       const LegacyInPlaceBowlAdapter& adapter,
                                       const Patch10DeferredBowlWrapper& wrapper,
                                       const BaseValidationManager& validator,
                                       const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Patch10InPlaceBowlHandler";
    ctx.phase = "PATCH_10_LEGACY_IN_PLACE_CALL";
    ctx.status = "LEGACY_IN_PLACE_CALLED_BEFORE_PATCH";
    ctx.branchTrace.push_back("PATCH_10_LEGACY_IN_PLACE_CALL");
    metrics.bump(ctx, "patch10.legacyInPlace.calls");

    ctx.legacyInPlaceBowlOutput = adapter.stir(
        ctx.legacyInPlaceBowlInput,
        ctx.legacyInPlaceBowlIndex,
        ctx.legacyInPlaceBowlDrop,
        ctx.legacyInPlaceBowlStoneRow,
        ctx.legacyInPlaceBowlOrder,
        ctx.legacyInPlaceBowlPours);
    ctx.legacyInPlaceBowlReady = true;

    ctx.phase = "PATCH_10_VAULT_OLD_AND_PENDING";
    ctx.branchTrace.push_back("PATCH_10_VAULT_OLD_AND_PENDING");
    const Patch10DeferredBowlComputation repaired = wrapper.repair(
        ctx.legacyInPlaceBowlInput,
        ctx.legacyInPlaceBowlIndex,
        ctx.legacyInPlaceBowlDrop,
        ctx.legacyInPlaceBowlStoneRow,
        ctx.legacyInPlaceBowlOrder,
        ctx.legacyInPlaceBowlPours);
    ctx.bowlVaultOld = repaired.vaultOld;
    ctx.bowlPending = repaired.pending;
    ctx.patchedInPlaceBowlOutput = repaired.output;
    ctx.patch10Applied = true;
    metrics.bump(ctx, "patch10.deferredWrite.calls");

    ctx.phase = "PATCH_10_VALIDATE";
    ctx.branchTrace.push_back("PATCH_10_VALIDATE");
    validator.requirePatch10Ready(ctx);

    ctx.phase = "PATCH_10_BOWL_STIR_READY";
    ctx.status = "PATCHED_DEFERRED_BOWL_STIR_EXPOSED";
    ctx.branchTrace.push_back("PATCH_10_BOWL_STIR_READY");
    metrics.bump(ctx, "patch10.bowlStir.ready");
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

void BaseDispatcher::dispatchPatchedPermutationRank(BaseMonsterContext& ctx,
                                                       const Patch08PermutationRankHandler& handler,
                                                       const LegacyPermutationAdapter& adapter,
                                                       const Patch08PermutationRankWrapper& wrapper,
                                                       const BaseValidationManager& validator,
                                                       const BaseMetricsShell& metrics) const {
    ctx.phase = "PATCH_08_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("PATCH_08_DISPATCH");
    metrics.bump(ctx, "patch08.dispatch.calls");
    handler.handle(ctx, adapter, wrapper, validator, metrics);
}

void BaseDispatcher::dispatchLegacyFixedPours(BaseMonsterContext& ctx,
                                              const Discovery09FixedPourHandler& handler,
                                              const LegacyFixedPourAdapter& adapter,
                                              const BaseValidationManager& validator,
                                              const BaseMetricsShell& metrics) const {
    ctx.phase = "DISCOVERY_09_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("DISCOVERY_09_DISPATCH");
    metrics.bump(ctx, "discovery09.dispatch.calls");
    handler.handle(ctx, adapter, validator, metrics);
}

void BaseDispatcher::dispatchPatchedFixedPours(BaseMonsterContext& ctx,
                                               const Patch09BowlAliasHandler& handler,
                                               const LegacyFixedPourAdapter& adapter,
                                               const Patch09BowlAliasWrapper& wrapper,
                                               const BaseValidationManager& validator,
                                               const BaseMetricsShell& metrics) const {
    ctx.phase = "PATCH_09_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("PATCH_09_DISPATCH");
    metrics.bump(ctx, "patch09.dispatch.calls");
    handler.handle(ctx, adapter, wrapper, validator, metrics);
}

void BaseDispatcher::dispatchLegacyInPlaceBowlStir(BaseMonsterContext& ctx,
                                                    const Discovery10InPlaceBowlHandler& handler,
                                                    const LegacyInPlaceBowlAdapter& adapter,
                                                    const BaseValidationManager& validator,
                                                    const BaseMetricsShell& metrics) const {
    ctx.phase = "DISCOVERY_10_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("DISCOVERY_10_DISPATCH");
    metrics.bump(ctx, "discovery10.dispatch.calls");
    handler.handle(ctx, adapter, validator, metrics);
}


void BaseDispatcher::dispatchPatchedInPlaceBowlStir(BaseMonsterContext& ctx,
                                                     const Patch10InPlaceBowlHandler& handler,
                                                     const LegacyInPlaceBowlAdapter& adapter,
                                                     const Patch10DeferredBowlWrapper& wrapper,
                                                     const BaseValidationManager& validator,
                                                     const BaseMetricsShell& metrics) const {
    ctx.phase = "PATCH_10_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("PATCH_10_DISPATCH");
    metrics.bump(ctx, "patch10.dispatch.calls");
    handler.handle(ctx, adapter, wrapper, validator, metrics);
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
    return executePermutationFromDrop(Integer{oneBasedRank});
}

PermutationRankReport BaseMonsterManager::executePermutationFromDrop(const Integer& drop) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = 0;
    ctx.targetDay = 0;
    ctx.phase = "PATCH_08_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";
    ctx.patch08PermutationDrop = drop;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyPermutationAdapter adapter;
    const Patch08PermutationRankWrapper wrapper;
    const Patch08PermutationRankHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchPatchedPermutationRank(ctx, handler, adapter, wrapper, validator, metrics);

    return PermutationRankReport{
        ctx.patchedPermutationOneBased,
        ctx.patchedPermutationOutput,
        ctx.patchedPermutationFound,
        ctx.legacyPermutationRank0Input,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size(),
        ctx.patch08PermutationDrop,
        ctx.patchedPermutationOneBased,
        ctx.patchedPermutationLegacyRank0,
        ctx.legacyPermutationOutput,
        ctx.legacyPermutationFound,
        ctx.patch08Applied,
    };
}

PermutationRankReport BaseMonsterManager::executeUnpatchedPermutationDiagnostic(int oneBasedRank) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = 0;
    ctx.targetDay = 0;
    ctx.phase = "DISCOVERY_08_DIAGNOSTIC_NEW";
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
        Integer{oneBasedRank},
        0,
        -1,
        ctx.legacyPermutationOutput,
        ctx.legacyPermutationFound,
        false,
    };
}

LegacyFixedPourReport BaseMonsterManager::executeFixedPours(const Integer& drop,
                                                            int index,
                                                            const BowlState& oldBowls,
                                                            const Stone& stoneRow) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = 0;
    ctx.targetDay = 0;
    ctx.phase = "PATCH_09_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";
    ctx.legacyFixedPourDrop = drop;
    ctx.legacyFixedPourIndex = index;
    ctx.legacyFixedPourOldBowls = oldBowls;
    ctx.legacyFixedPourStoneRow = stoneRow;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyFixedPourAdapter adapter;
    const Patch09BowlAliasWrapper wrapper;
    const Patch09BowlAliasHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchPatchedFixedPours(ctx, handler, adapter, wrapper, validator, metrics);

    return LegacyFixedPourReport{
        ctx.legacyFixedPourDrop,
        ctx.legacyFixedPourIndex,
        ctx.legacyFixedPourOldBowls,
        ctx.legacyFixedPourStoneRow,
        ctx.legacyFixedPourOrder,
        ctx.legacyFixedPourBowlIds,
        ctx.patchedFixedPourOutput,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size(),
        ctx.legacyFixedPourOutput,
        ctx.legacyFixedPourBowlIds,
        ctx.bowlAlias,
        ctx.aliasedFixedPourBowlIds,
        ctx.patch09Applied,
    };
}

LegacyFixedPourReport BaseMonsterManager::executeUnpatchedFixedPoursDiagnostic(
    const Integer& drop,
    int index,
    const BowlState& oldBowls,
    const Stone& stoneRow) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = 0;
    ctx.targetDay = 0;
    ctx.phase = "DISCOVERY_09_DIAGNOSTIC_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";
    ctx.legacyFixedPourDrop = drop;
    ctx.legacyFixedPourIndex = index;
    ctx.legacyFixedPourOldBowls = oldBowls;
    ctx.legacyFixedPourStoneRow = stoneRow;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyFixedPourAdapter adapter;
    const Discovery09FixedPourHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchLegacyFixedPours(ctx, handler, adapter, validator, metrics);

    return LegacyFixedPourReport{
        ctx.legacyFixedPourDrop,
        ctx.legacyFixedPourIndex,
        ctx.legacyFixedPourOldBowls,
        ctx.legacyFixedPourStoneRow,
        ctx.legacyFixedPourOrder,
        ctx.legacyFixedPourBowlIds,
        ctx.legacyFixedPourOutput,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size(),
        ctx.legacyFixedPourOutput,
        ctx.legacyFixedPourBowlIds,
        BowlAlias{},
        std::array<int, 3>{{1, 2, 3}},
        false,
    };
}

LegacyInPlaceBowlReport BaseMonsterManager::executeInPlaceBowlStir(
    const BowlState& bowls,
    int index,
    const Integer& drop,
    const Stone& stoneRow,
    const PermutationOrder& order,
    const PourTriplet& firstThreePours) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = 0;
    ctx.targetDay = 0;
    ctx.phase = "PATCH_10_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";
    ctx.legacyInPlaceBowlInput = bowls;
    ctx.legacyInPlaceBowlIndex = index;
    ctx.legacyInPlaceBowlDrop = drop;
    ctx.legacyInPlaceBowlStoneRow = stoneRow;
    ctx.legacyInPlaceBowlOrder = order;
    ctx.legacyInPlaceBowlPours = firstThreePours;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyInPlaceBowlAdapter adapter;
    const Patch10DeferredBowlWrapper wrapper;
    const Patch10InPlaceBowlHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchPatchedInPlaceBowlStir(ctx, handler, adapter, wrapper, validator, metrics);

    return LegacyInPlaceBowlReport{
        ctx.legacyInPlaceBowlInput,
        ctx.legacyInPlaceBowlDrop,
        ctx.legacyInPlaceBowlIndex,
        ctx.legacyInPlaceBowlStoneRow,
        ctx.legacyInPlaceBowlOrder,
        ctx.legacyInPlaceBowlPours,
        ctx.patchedInPlaceBowlOutput,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size(),
        ctx.legacyInPlaceBowlOutput,
        ctx.bowlVaultOld,
        ctx.bowlPending,
        ctx.patch10Applied,
    };
}

LegacyInPlaceBowlReport BaseMonsterManager::executeUnpatchedInPlaceBowlStirDiagnostic(
    const BowlState& bowls,
    int index,
    const Integer& drop,
    const Stone& stoneRow,
    const PermutationOrder& order,
    const PourTriplet& firstThreePours) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = 0;
    ctx.targetDay = 0;
    ctx.phase = "DISCOVERY_10_DIAGNOSTIC_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";
    ctx.legacyInPlaceBowlInput = bowls;
    ctx.legacyInPlaceBowlIndex = index;
    ctx.legacyInPlaceBowlDrop = drop;
    ctx.legacyInPlaceBowlStoneRow = stoneRow;
    ctx.legacyInPlaceBowlOrder = order;
    ctx.legacyInPlaceBowlPours = firstThreePours;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyInPlaceBowlAdapter adapter;
    const Discovery10InPlaceBowlHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchLegacyInPlaceBowlStir(ctx, handler, adapter, validator, metrics);

    return LegacyInPlaceBowlReport{
        ctx.legacyInPlaceBowlInput,
        ctx.legacyInPlaceBowlDrop,
        ctx.legacyInPlaceBowlIndex,
        ctx.legacyInPlaceBowlStoneRow,
        ctx.legacyInPlaceBowlOrder,
        ctx.legacyInPlaceBowlPours,
        ctx.legacyInPlaceBowlOutput,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size(),
        ctx.legacyInPlaceBowlOutput,
        BowlState{},
        BowlState{},
        false,
    };
}


void BaseValidationManager::requireLegacyOrderMemorySauceReady(const BaseMonsterContext& ctx) const {
    if (!ctx.legacyOrderMemorySauceReady) {
        throw BaseValidationError("memoria ordinis legacy nondum parata est");
    }
    const LegacyOrderMemorySauceResult& result = ctx.legacyOrderMemorySauce;
    if (result.orderWriteCount != 58) {
        throw BaseValidationError("memoria ordinis legacy quinquaginta octo scripturas requirit");
    }
    if (result.finalOrderSource != "post-commotio 12") {
        throw BaseValidationError("memoria ordinis legacy fonte post-commotionis duodecimae terminare debet");
    }
    if (result.queryOrder != result.finalPostStirOrder) {
        throw BaseValidationError("query ordinis legacy memoriam ultimam non legit");
    }

    auto requirePermutation = [](const PermutationOrder& order) {
        std::array<bool, 7> seen{};
        for (const int id : order) {
            if (id < 1 || id > 6 || seen[static_cast<std::size_t>(id)]) {
                throw BaseValidationError("ordo craterum in memoria legacy permutatio valida non est");
            }
            seen[static_cast<std::size_t>(id)] = true;
        }
    };
    requirePermutation(result.orderAtDrop46Diagnostic);
    requirePermutation(result.queryOrder);
}

void BaseValidationManager::requirePatch11Ready(const BaseMonsterContext& ctx) const {
    requireLegacyOrderMemorySauceReady(ctx);
    if (!ctx.patch11Applied) {
        throw BaseValidationError("emendatio undecima nondum applicata est");
    }

    const Patch11LatchedOrderSauceResult& patched = ctx.patch11LatchedOrderSauce;
    if (patched.legacyOrderWriteCount != 58) {
        throw BaseValidationError("memoria legacy etiam post patch undecimum quinquaginta octo scripturas requirit");
    }
    if (patched.latchWriteCount != 1) {
        throw BaseValidationError("orderAt46Latch exactissime semel scribendus est");
    }
    if (patched.finalLegacyOrderSource != "post-commotio 12") {
        throw BaseValidationError("memoria legacy post patch undecimum fonte post-commotionis duodecimae terminare debet");
    }
    if (patched.legacyQueryOrderBeforePatch != patched.finalPostStirOrder) {
        throw BaseValidationError("cicatrix memoriae legacy post patch undecimum non servata est");
    }
    if (patched.queryOrder != patched.orderAt46Latch) {
        throw BaseValidationError("query ordinis per latch guttae 46 tantum legere debet");
    }
    if (patched.orderAt46Latch != ctx.legacyOrderMemorySauce.orderAtDrop46Diagnostic) {
        throw BaseValidationError("latch guttae 46 ordinem diagnosticum exactum non clonat");
    }
    if (patched.finalBowls != ctx.legacyOrderMemorySauce.finalBowls) {
        throw BaseValidationError("patch undecimum crateres finales mutare non debet");
    }
}

void BaseValidationManager::requireLegacyNextBowlReady(const BaseMonsterContext& ctx) const {
    if (!ctx.patch11Applied || ctx.patch11LatchedOrderSauce.latchWriteCount != 1) {
        throw BaseValidationError("orderAt46Latch ante discovery duodecimum paratus esse debet");
    }
    if (!ctx.legacyNextBowlReady) {
        throw BaseValidationError("next-bowl legacy nondum paratus est");
    }
    if (ctx.legacyNextBowlQueriedId < 1 || ctx.legacyNextBowlQueriedId > 6) {
        throw BaseValidationError("queried ID crateris extra fines est");
    }
    if (ctx.legacyNextBowlOrderAt46Latch != ctx.patch11LatchedOrderSauce.orderAt46Latch) {
        throw BaseValidationError("discovery duodecimum latch undecimi patch perdere non debet");
    }
    if (ctx.legacyNextBowlOutput != oldNextBowlFixedName(ctx.legacyNextBowlQueriedId)) {
        throw BaseValidationError("next-bowl legacy successor numericus fixus non servatus est");
    }
}

void BaseValidationManager::requirePatch12Ready(const BaseMonsterContext& ctx) const {
    requireLegacyNextBowlReady(ctx);
    if (!ctx.patch12Applied) {
        throw BaseValidationError("patch duodecimum next-bowl nondum applicatum est");
    }
    std::size_t inventa = 0;
    for (std::size_t i = 0; i < ctx.legacyNextBowlOrderAt46Latch.size(); ++i) {
        if (ctx.legacyNextBowlOrderAt46Latch[i] == ctx.legacyNextBowlQueriedId) {
            inventa = i + 1;
            break;
        }
    }
    if (inventa == 0) {
        throw BaseValidationError("queried ID crateris in latch non inventus est");
    }
    if (ctx.patch12QueriedPosition != inventa) {
        throw BaseValidationError("positio queried crateris a latch non recte servata est");
    }
    const int expectatus = nextBowlThroughOrderAt46Latch(
        ctx.legacyNextBowlOrderAt46Latch,
        ctx.legacyNextBowlQueriedId);
    if (ctx.patchedNextBowlOutput != expectatus) {
        throw BaseValidationError("successor circularis orderAt46Latch non servatus est");
    }
}

void BaseValidationManager::requireLegacyBiasedSelectionReady(const BaseMonsterContext& ctx) const {
    if (!ctx.patch11Applied || !ctx.patch12Applied) {
        throw BaseValidationError("patches undecimus et duodecimus ante discovery tertium decimum parati esse debent");
    }
    if (!ctx.legacyBiasedSelectionReady) {
        throw BaseValidationError("electio legacy modulo directa nondum parata est");
    }
    if (ctx.legacyBiasedSelectionFamilySize < 1) {
        throw BaseValidationError("magnitudo familiae selectionis invalida est");
    }
    if (ctx.legacyBiasedSelectionRing.directionStep != -1 &&
        ctx.legacyBiasedSelectionRing.directionStep != 1) {
        throw BaseValidationError("directio annuli selectionis invalida est");
    }
    const Integer expectatusPrimus = ringAnswer(ctx.legacyBiasedSelectionRing, Integer{0});
    if (ctx.legacyBiasedSelectionFirstAnswer != expectatusPrimus) {
        throw BaseValidationError("primus responsus annuli non servatus est");
    }
    const Integer expectataElectio = biasedLegacyPick(
        expectatusPrimus,
        ctx.legacyBiasedSelectionFamilySize);
    if (ctx.legacyBiasedSelectionOutput != expectataElectio) {
        throw BaseValidationError("selector legacy non est modulo directus");
    }
}

void BaseValidationManager::requireDiscovery14WideAssumptionReady(const BaseMonsterContext& ctx) const {
    if (!ctx.patch11Applied || !ctx.patch12Applied) {
        throw BaseValidationError("patches undecimus et duodecimus ante discovery quartum decimum parati esse debent");
    }
    if (!ctx.legacyWideSelectionReady) {
        throw BaseValidationError("conatus selectionis latae legacy nondum paratus est");
    }
    if (ctx.legacyWideSelectionFamilySize <= M_OLD) {
        throw BaseValidationError("discovery quartum decimum familiam supra M requirit");
    }
    if (ctx.legacyWideSelectionOutputAvailable) {
        throw BaseValidationError("legacy short-only familiam supra M perperam accepit");
    }
    if (!ctx.legacyWideSelectionShortFailure) {
        throw BaseValidationError("assumptio legacy N<=M defectum short-only non exposuit");
    }
    if (ctx.legacyWideSelectionFailure.empty()) {
        throw BaseValidationError("causa defectus short-only vacua est");
    }
}

void BaseValidationManager::requirePatch14WideSelectionReady(const BaseMonsterContext& ctx) const {
    if (!ctx.patch11Applied || !ctx.patch12Applied || !ctx.patch14Applied) {
        throw BaseValidationError("patches undecimus, duodecimus et quartus decimus parati esse debent");
    }
    const Integer N = ctx.legacyWideSelectionFamilySize;
    if (N < 1) {
        throw BaseValidationError("familia selectionis vacua est");
    }
    if (!ctx.legacyWideSelectionOutputAvailable) {
        throw BaseValidationError("patch quartus decimus output selectionis non paravit");
    }
    if (ctx.patch14UsedShortPath == ctx.patch14UsedWideDetour) {
        throw BaseValidationError("dispatcher patch quarti decimi unam tantum viam eligere debet");
    }
    if (N <= M_OLD) {
        if (!ctx.patch14UsedShortPath || ctx.patch14UsedWideDetour) {
            throw BaseValidationError("familia brevis non per viam short missa est");
        }
        if (ctx.patch14WidePlaces != 0 || ctx.patch14WideDigitReadCount != 0 ||
            !ctx.patch14WideDigits.empty()) {
            throw BaseValidationError("via brevis digits wide legere non debet");
        }
        return;
    }
    if (!ctx.patch14UsedWideDetour || ctx.patch14UsedShortPath) {
        throw BaseValidationError("familia lata non per wideDetour missa est");
    }
    if (!ctx.patch14LegacyShortFailureBeforePatch ||
        ctx.patch14LegacyFailureBeforePatch.empty() ||
        ctx.patch14LegacyOutputAvailableBeforePatch) {
        throw BaseValidationError("cicatrix short-only ante wideDetour non servata est");
    }
    if (ctx.patch14WidePlaces < 2 ||
        ctx.patch14WideDigitReadCount != ctx.patch14WidePlaces ||
        static_cast<int>(ctx.patch14WideDigits.size()) != ctx.patch14WidePlaces) {
        throw BaseValidationError("digits wide semel pro omnibus locis legi debent");
    }
    Integer expectatumSpatium = M_OLD;
    for (int i = 1; i < ctx.patch14WidePlaces; ++i) {
        expectatumSpatium *= M_OLD;
    }
    if (ctx.patch14WideSpace != expectatumSpatium || ctx.patch14WideSpace < N) {
        throw BaseValidationError("spatium wide non est M^places minimum");
    }
    if (ctx.patch14WidePlaces > 1 && ctx.patch14WideSpace / M_OLD >= N) {
        throw BaseValidationError("places wide minimum non sunt");
    }
    Integer expectatusWide = 1;
    Integer pondus = 1;
    for (int j = 0; j < ctx.patch14WidePlaces; ++j) {
        const Integer expectataDigit = ringAnswer(ctx.legacyWideSelectionRing, Integer{j});
        if (ctx.patch14WideDigits[static_cast<std::size_t>(j)] != expectataDigit) {
            throw BaseValidationError("digit wide non ex annulo semel lecta est");
        }
        expectatusWide += (expectataDigit - 1) * pondus;
        pondus *= M_OLD;
    }
    if (ctx.patch14WideInitialValue != expectatusWide) {
        throw BaseValidationError("numerus wide initialis ex digits male compositus est");
    }
    const Integer expectatusLimes = (ctx.patch14WideSpace / N) * N;
    if (ctx.patch14WideAcceptanceLimit != expectatusLimes) {
        throw BaseValidationError("limes rejectionis wide non est floor(space/N)*N");
    }
    Integer acceptus = ctx.patch14WideInitialValue;
    Integer gradus = 0;
    while (acceptus > expectatusLimes) {
        acceptus = 1 + regularMod(
            acceptus - 1 + Integer{ctx.legacyWideSelectionRing.directionStep},
            ctx.patch14WideSpace);
        ++gradus;
    }
    if (ctx.patch14WideAcceptedValue != acceptus || ctx.patch14WideRejectionSteps != gradus) {
        throw BaseValidationError("rejectio wide non super eodem numero composito processit");
    }
    const Integer expectatusOutput = biasedLegacyPick(acceptus, N);
    if (ctx.legacyWideSelectionOutput != expectatusOutput) {
        throw BaseValidationError("output wide post rejectionem non per selector legacy reductus est");
    }
}

void BaseValidationManager::requireDiscovery15GateQuestionReady(const BaseMonsterContext& ctx) const {
    if (!ctx.legacyGateQuestionReady) {
        throw BaseValidationError("quaestio portae legacy nondum parata est");
    }
    Integer magnitudo = ctx.legacyGateQuestionSignedStep;
    if (magnitudo < 0) {
        magnitudo = -magnitudo;
    }
    if (ctx.legacyGateQuestionMagnitude != magnitudo) {
        throw BaseValidationError("caller legacy signum gradus non per abs delevit");
    }
    if (ctx.legacyGateQuestionOutput != oldGateQuestionDay(magnitudo)) {
        throw BaseValidationError("oldGateQuestionDay magnitudinem calleris non accepit");
    }
}

void BaseValidationManager::requirePatch13BiasedSelectionReady(const BaseMonsterContext& ctx) const {
    requireLegacyBiasedSelectionReady(ctx);
    if (!ctx.patch13Applied) {
        throw BaseValidationError("emendatio tertia decima nondum applicata est");
    }
    const Integer N = ctx.legacyBiasedSelectionFamilySize;
    if (N < 1 || N > M_OLD) {
        throw BaseValidationError("magnitudo familiae brevis extra fines 1..M est");
    }
    const Integer expectatusLimes = (M_OLD / N) * N;
    if (ctx.patch13AcceptanceLimit != expectatusLimes) {
        throw BaseValidationError("limes rejectionis brevis non est floor(M/N)*N");
    }
    if (ctx.patch13AcceptedOffset < 0) {
        throw BaseValidationError("offset responsi accepti negativus est");
    }
    const Integer expectatusResponsus = ringAnswer(
        ctx.legacyBiasedSelectionRing,
        ctx.patch13AcceptedOffset);
    if (ctx.patch13AcceptedAnswer != expectatusResponsus) {
        throw BaseValidationError("responsus acceptus non ex eodem annulo venit");
    }
    if (ctx.patch13AcceptedAnswer > ctx.patch13AcceptanceLimit) {
        throw BaseValidationError("responsus supra limitem rejectionis acceptus est");
    }
    for (Integer k = 0; k < ctx.patch13AcceptedOffset; ++k) {
        if (ringAnswer(ctx.legacyBiasedSelectionRing, k) <= ctx.patch13AcceptanceLimit) {
            throw BaseValidationError("responsus prior acceptabilis praetermissus est");
        }
    }
    const Integer expectataElectio = biasedLegacyPick(
        ctx.patch13AcceptedAnswer,
        N);
    if (ctx.patchedBiasedSelectionOutput != expectataElectio) {
        throw BaseValidationError("selector legacy post rejectionem non vocatus est");
    }
}

LegacyOrderMemorySauceResult LegacyOrderMemorySauceAdapter::run(
    const Integer& calculationDay,
    const Integer& targetDay) const {
    return legacySauceWithOverwritableOrderMemory(calculationDay, targetDay);
}

Patch11LatchedOrderSauceResult Patch11OrderAt46LatchWrapper::repair(
    const Integer& calculationDay,
    const Integer& targetDay) const {
    return sauceWithOrderAt46Latch(calculationDay, targetDay);
}

int LegacyNextBowlAdapter::nextFixedName(int queriedBowlId) const {
    return oldNextBowlFixedName(queriedBowlId);
}

int Patch12NextBowlWrapper::repair(const PermutationOrder& orderAt46Latch,
                                   int queriedBowlId) const {
    return nextBowlThroughOrderAt46Latch(orderAt46Latch, queriedBowlId);
}

Integer LegacyBiasedSelectionAdapter::selectBeforeRejection(
    const LegacyAnswerRing& stream,
    const Integer& N) const {
    const Integer x = ringAnswer(stream, Integer{0});
    return biasedLegacyPick(x, N);
}

Integer LegacyBiasedSelectionAdapter::selectAcceptedAnswer(
    const Integer& x,
    const Integer& N) const {
    return biasedLegacyPick(x, N);
}

Patch13RejectionSelection Patch13RejectionWrapper::repair(
    const LegacyAnswerRing& stream,
    const Integer& N,
    const LegacyBiasedSelectionAdapter& adapter) const {
    if (N < 1 || N > M_OLD) {
        throw BaseValidationError("magnitudo familiae brevis inter 1 et M requiritur");
    }
    const Integer acceptanceLimit = (M_OLD / N) * N;
    Integer offset = 0;
    for (;;) {
        const Integer x = ringAnswer(stream, offset);
        if (x <= acceptanceLimit) {
            return Patch13RejectionSelection{
                acceptanceLimit,
                x,
                offset,
                adapter.selectAcceptedAnswer(x, N)
            };
        }
        ++offset;
    }
}

Integer LegacyGateQuestionAdapter::ask(const Integer& magnitude) const {
    return oldGateQuestionDay(magnitude);
}

LegacyWideSelectionAttempt LegacyShortOnlyWideSelectionAdapter::attempt(
    const LegacyAnswerRing& stream,
    const Integer& N,
    const LegacyBiasedSelectionAdapter& selectionAdapter,
    const Patch13RejectionWrapper& rejectionWrapper) const {
    try {
        const Patch13RejectionSelection shortResult = rejectionWrapper.repair(
            stream,
            N,
            selectionAdapter);
        return LegacyWideSelectionAttempt{
            true,
            shortResult.outputRank,
            false,
            std::string{}
        };
    } catch (const BaseValidationError& error) {
        return LegacyWideSelectionAttempt{
            false,
            Integer{0},
            true,
            error.what()
        };
    }
}

Patch14WideDetourSelection Patch14WideDetourWrapper::repair(
    const LegacyAnswerRing& stream,
    const Integer& N,
    const LegacyBiasedSelectionAdapter& selectionAdapter) const {
    if (N <= M_OLD) {
        throw BaseValidationError("wideDetour familiam supra M requirit");
    }
    int places = 1;
    Integer space = M_OLD;
    while (space < N) {
        ++places;
        space *= M_OLD;
    }

    std::vector<Integer> digits;
    digits.reserve(static_cast<std::size_t>(places));
    for (int j = 0; j < places; ++j) {
        digits.push_back(ringAnswer(stream, Integer{j}));
    }

    Integer wide = 1;
    Integer weight = 1;
    for (const Integer& digit : digits) {
        wide += (digit - 1) * weight;
        weight *= M_OLD;
    }
    const Integer initialWide = wide;
    const Integer acceptanceLimit = (space / N) * N;
    Integer rejectionSteps = 0;
    while (wide > acceptanceLimit) {
        wide = 1 + regularMod(
            wide - 1 + Integer{stream.directionStep},
            space);
        ++rejectionSteps;
    }

    return Patch14WideDetourSelection{
        places,
        space,
        digits,
        places,
        initialWide,
        acceptanceLimit,
        wide,
        rejectionSteps,
        selectionAdapter.selectAcceptedAnswer(wide, N)
    };
}

void Discovery11OverwrittenOrderHandler::handle(
    BaseMonsterContext& ctx,
    const LegacyOrderMemorySauceAdapter& adapter,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Discovery11OverwrittenOrderHandler";
    ctx.phase = "DISCOVERY_11_ORDER_MEMORY_RUN";
    ctx.status = "LEGACY_ORDER_MEMORY_ACTIVE";
    ctx.branchTrace.push_back("DISCOVERY_11_ORDER_MEMORY_RUN");
    metrics.bump(ctx, "discovery11.orderMemory.calls");

    ctx.legacyOrderMemorySauce = adapter.run(ctx.calculationDay, ctx.targetDay);
    ctx.legacyOrderMemorySauceReady = true;

    ctx.phase = "DISCOVERY_11_ORDER_MEMORY_VALIDATE";
    ctx.branchTrace.push_back("DISCOVERY_11_ORDER_MEMORY_VALIDATE");
    validator.requireLegacyOrderMemorySauceReady(ctx);

    ctx.phase = "DISCOVERY_11_ORDER_MEMORY_EXPOSED";
    ctx.status = "OVERWRITTEN_QUERY_ORDER_EXPOSED";
    ctx.branchTrace.push_back("DISCOVERY_11_ORDER_MEMORY_EXPOSED");
    metrics.bump(ctx, "discovery11.orderMemory.exposed");
}

void Patch11OrderAt46LatchHandler::handle(
    BaseMonsterContext& ctx,
    const LegacyOrderMemorySauceAdapter& adapter,
    const Patch11OrderAt46LatchWrapper& wrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Patch11OrderAt46LatchHandler";
    ctx.phase = "PATCH_11_LEGACY_ORDER_MEMORY_RUN";
    ctx.status = "LEGACY_ORDER_MEMORY_CALLED_BEFORE_LATCH";
    ctx.branchTrace.push_back("PATCH_11_LEGACY_ORDER_MEMORY_RUN");
    metrics.bump(ctx, "patch11.legacyOrderMemory.calls");

    ctx.legacyOrderMemorySauce = adapter.run(ctx.calculationDay, ctx.targetDay);
    ctx.legacyOrderMemorySauceReady = true;

    ctx.phase = "PATCH_11_ORDER_AT_46_LATCH";
    ctx.branchTrace.push_back("PATCH_11_ORDER_AT_46_LATCH");
    ctx.patch11LatchedOrderSauce = wrapper.repair(ctx.calculationDay, ctx.targetDay);
    ctx.patch11Applied = true;
    metrics.bump(ctx, "patch11.latch.calls");

    ctx.phase = "PATCH_11_VALIDATE";
    ctx.branchTrace.push_back("PATCH_11_VALIDATE");
    validator.requirePatch11Ready(ctx);

    ctx.phase = "PATCH_11_LATCHED_QUERY_READY";
    ctx.status = "LATCHED_ORDER_AT_46_EXPOSED";
    ctx.branchTrace.push_back("PATCH_11_LATCHED_QUERY_READY");
    metrics.bump(ctx, "patch11.latchedQuery.ready");
}

void Discovery12NextBowlHandler::handle(
    BaseMonsterContext& ctx,
    const LegacyNextBowlAdapter& adapter,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Discovery12NextBowlHandler";
    ctx.phase = "DISCOVERY_12_NEXT_BOWL_CALL";
    ctx.status = "LEGACY_NEXT_BOWL_ACTIVE";
    ctx.branchTrace.push_back("DISCOVERY_12_NEXT_BOWL_CALL");
    metrics.bump(ctx, "discovery12.nextBowl.calls");

    ctx.legacyNextBowlOrderAt46Latch = ctx.patch11LatchedOrderSauce.orderAt46Latch;
    ctx.legacyNextBowlOutput = adapter.nextFixedName(ctx.legacyNextBowlQueriedId);
    ctx.legacyNextBowlReady = true;

    ctx.phase = "DISCOVERY_12_NEXT_BOWL_VALIDATE";
    ctx.branchTrace.push_back("DISCOVERY_12_NEXT_BOWL_VALIDATE");
    validator.requireLegacyNextBowlReady(ctx);

    ctx.phase = "DISCOVERY_12_NEXT_BOWL_EXPOSED";
    ctx.status = "FIXED_NAME_SUCCESSOR_EXPOSED";
    ctx.branchTrace.push_back("DISCOVERY_12_NEXT_BOWL_EXPOSED");
    metrics.bump(ctx, "discovery12.nextBowl.exposed");
}

void Patch12NextBowlHandler::handle(
    BaseMonsterContext& ctx,
    const LegacyNextBowlAdapter& adapter,
    const Patch12NextBowlWrapper& wrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Patch12NextBowlHandler";
    ctx.phase = "PATCH_12_LEGACY_NEXT_BOWL_CALL";
    ctx.status = "LEGACY_FIXED_NAME_CALLED_BEFORE_POSITIONAL_PATCH";
    ctx.branchTrace.push_back("PATCH_12_LEGACY_NEXT_BOWL_CALL");
    metrics.bump(ctx, "patch12.legacyNextBowl.calls");

    ctx.legacyNextBowlOrderAt46Latch = ctx.patch11LatchedOrderSauce.orderAt46Latch;
    ctx.legacyNextBowlOutput = adapter.nextFixedName(ctx.legacyNextBowlQueriedId);
    ctx.legacyNextBowlReady = true;

    ctx.phase = "PATCH_12_LOCATE_IN_ORDER_AT_46";
    ctx.branchTrace.push_back("PATCH_12_LOCATE_IN_ORDER_AT_46");
    for (std::size_t i = 0; i < ctx.legacyNextBowlOrderAt46Latch.size(); ++i) {
        if (ctx.legacyNextBowlOrderAt46Latch[i] == ctx.legacyNextBowlQueriedId) {
            ctx.patch12QueriedPosition = i + 1;
            break;
        }
    }

    ctx.phase = "PATCH_12_CIRCULAR_SUCCESSOR";
    ctx.branchTrace.push_back("PATCH_12_CIRCULAR_SUCCESSOR");
    ctx.patchedNextBowlOutput = wrapper.repair(
        ctx.legacyNextBowlOrderAt46Latch,
        ctx.legacyNextBowlQueriedId);
    ctx.patch12Applied = true;
    metrics.bump(ctx, "patch12.circularSuccessor.calls");

    ctx.phase = "PATCH_12_VALIDATE";
    ctx.branchTrace.push_back("PATCH_12_VALIDATE");
    validator.requirePatch12Ready(ctx);

    ctx.phase = "PATCH_12_NEXT_BOWL_READY";
    ctx.status = "LATCH_POSITIONAL_SUCCESSOR_EXPOSED";
    ctx.branchTrace.push_back("PATCH_12_NEXT_BOWL_READY");
    metrics.bump(ctx, "patch12.nextBowl.ready");
}

void BaseDispatcher::dispatchLegacyOverwrittenOrder(
    BaseMonsterContext& ctx,
    const Discovery11OverwrittenOrderHandler& handler,
    const LegacyOrderMemorySauceAdapter& adapter,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.phase = "DISCOVERY_11_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("DISCOVERY_11_DISPATCH");
    metrics.bump(ctx, "discovery11.dispatch.calls");
    handler.handle(ctx, adapter, validator, metrics);
}

void BaseDispatcher::dispatchPatchedOrderAt46Latch(
    BaseMonsterContext& ctx,
    const Patch11OrderAt46LatchHandler& handler,
    const LegacyOrderMemorySauceAdapter& adapter,
    const Patch11OrderAt46LatchWrapper& wrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.phase = "PATCH_11_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("PATCH_11_DISPATCH");
    metrics.bump(ctx, "patch11.dispatch.calls");
    handler.handle(ctx, adapter, wrapper, validator, metrics);
}

void BaseDispatcher::dispatchLegacyNextBowl(
    BaseMonsterContext& ctx,
    const Discovery12NextBowlHandler& handler,
    const LegacyNextBowlAdapter& adapter,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.phase = "DISCOVERY_12_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("DISCOVERY_12_DISPATCH");
    metrics.bump(ctx, "discovery12.dispatch.calls");
    handler.handle(ctx, adapter, validator, metrics);
}

void BaseDispatcher::dispatchPatchedNextBowl(
    BaseMonsterContext& ctx,
    const Patch12NextBowlHandler& handler,
    const LegacyNextBowlAdapter& adapter,
    const Patch12NextBowlWrapper& wrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.phase = "PATCH_12_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("PATCH_12_DISPATCH");
    metrics.bump(ctx, "patch12.dispatch.calls");
    handler.handle(ctx, adapter, wrapper, validator, metrics);
}

void Discovery13BiasedSelectionHandler::handle(
    BaseMonsterContext& ctx,
    const LegacyBiasedSelectionAdapter& adapter,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Discovery13BiasedSelectionHandler";
    ctx.phase = "DISCOVERY_13_BUILD_ANSWER_RING";
    ctx.status = "LEGACY_BIASED_MODULO_BEFORE_REJECTION";
    ctx.branchTrace.push_back("DISCOVERY_13_BUILD_ANSWER_RING");
    metrics.bump(ctx, "discovery13.answerRing.calls");

    ctx.legacyBiasedSelectionRing = answerRingThroughPatchedNextBowl(
        ctx.patch11LatchedOrderSauce.finalBowls,
        ctx.legacyBiasedSelectionQueriedBowlId,
        ctx.patchedNextBowlOutput,
        ctx.legacyBiasedSelectionSeal);
    ctx.legacyBiasedSelectionFirstAnswer = ringAnswer(
        ctx.legacyBiasedSelectionRing,
        Integer{0});

    ctx.phase = "DISCOVERY_13_DIRECT_MODULO_SELECTION";
    ctx.branchTrace.push_back("DISCOVERY_13_DIRECT_MODULO_SELECTION");
    ctx.legacyBiasedSelectionOutput = adapter.selectBeforeRejection(
        ctx.legacyBiasedSelectionRing,
        ctx.legacyBiasedSelectionFamilySize);
    ctx.legacyBiasedSelectionReady = true;
    metrics.bump(ctx, "discovery13.biasedModulo.calls");

    ctx.phase = "DISCOVERY_13_VALIDATE";
    ctx.branchTrace.push_back("DISCOVERY_13_VALIDATE");
    validator.requireLegacyBiasedSelectionReady(ctx);

    ctx.phase = "DISCOVERY_13_BIASED_SELECTION_EXPOSED";
    ctx.status = "DIRECT_MODULO_CALLED_WITHOUT_REJECTION";
    ctx.branchTrace.push_back("DISCOVERY_13_BIASED_SELECTION_EXPOSED");
    metrics.bump(ctx, "discovery13.biasedSelection.exposed");
}

void BaseDispatcher::dispatchLegacyBiasedSelection(
    BaseMonsterContext& ctx,
    const Discovery13BiasedSelectionHandler& handler,
    const LegacyBiasedSelectionAdapter& adapter,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.phase = "DISCOVERY_13_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("DISCOVERY_13_DISPATCH");
    metrics.bump(ctx, "discovery13.dispatch.calls");
    handler.handle(ctx, adapter, validator, metrics);
}

void Patch13BiasedSelectionHandler::handle(
    BaseMonsterContext& ctx,
    const LegacyBiasedSelectionAdapter& adapter,
    const Patch13RejectionWrapper& wrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Patch13BiasedSelectionHandler";
    ctx.phase = "PATCH_13_BUILD_ANSWER_RING";
    ctx.status = "LEGACY_BIASED_MODULO_CALLED_BEFORE_REJECTION_PATCH";
    ctx.branchTrace.push_back("PATCH_13_BUILD_ANSWER_RING");
    metrics.bump(ctx, "patch13.answerRing.calls");

    ctx.legacyBiasedSelectionRing = answerRingThroughPatchedNextBowl(
        ctx.patch11LatchedOrderSauce.finalBowls,
        ctx.legacyBiasedSelectionQueriedBowlId,
        ctx.patchedNextBowlOutput,
        ctx.legacyBiasedSelectionSeal);
    ctx.legacyBiasedSelectionFirstAnswer = ringAnswer(
        ctx.legacyBiasedSelectionRing,
        Integer{0});

    ctx.phase = "PATCH_13_LEGACY_DIRECT_MODULO_CALL";
    ctx.branchTrace.push_back("PATCH_13_LEGACY_DIRECT_MODULO_CALL");
    ctx.legacyBiasedSelectionOutput = adapter.selectBeforeRejection(
        ctx.legacyBiasedSelectionRing,
        ctx.legacyBiasedSelectionFamilySize);
    ctx.legacyBiasedSelectionReady = true;
    metrics.bump(ctx, "patch13.legacyBiasedModulo.calls");
    validator.requireLegacyBiasedSelectionReady(ctx);

    ctx.phase = "PATCH_13_REJECTION_RING";
    ctx.branchTrace.push_back("PATCH_13_REJECTION_RING");
    const Patch13RejectionSelection repaired = wrapper.repair(
        ctx.legacyBiasedSelectionRing,
        ctx.legacyBiasedSelectionFamilySize,
        adapter);
    ctx.patch13AcceptanceLimit = repaired.acceptanceLimit;
    ctx.patch13AcceptedAnswer = repaired.acceptedAnswer;
    ctx.patch13AcceptedOffset = repaired.acceptedOffset;
    ctx.patchedBiasedSelectionOutput = repaired.outputRank;
    ctx.patch13Applied = true;
    metrics.bump(ctx, "patch13.rejection.calls");

    ctx.phase = "PATCH_13_VALIDATE";
    ctx.branchTrace.push_back("PATCH_13_VALIDATE");
    validator.requirePatch13BiasedSelectionReady(ctx);

    ctx.phase = "PATCH_13_BIASED_SELECTION_READY";
    ctx.status = "REJECTION_COMPLETED_ON_SAME_ANSWER_RING";
    ctx.branchTrace.push_back("PATCH_13_BIASED_SELECTION_READY");
    metrics.bump(ctx, "patch13.biasedSelection.ready");
}

void BaseDispatcher::dispatchPatchedBiasedSelection(
    BaseMonsterContext& ctx,
    const Patch13BiasedSelectionHandler& handler,
    const LegacyBiasedSelectionAdapter& adapter,
    const Patch13RejectionWrapper& wrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.phase = "PATCH_13_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("PATCH_13_DISPATCH");
    metrics.bump(ctx, "patch13.dispatch.calls");
    handler.handle(ctx, adapter, wrapper, validator, metrics);
}

void Discovery14WideAssumptionHandler::handle(
    BaseMonsterContext& ctx,
    const LegacyShortOnlyWideSelectionAdapter& adapter,
    const LegacyBiasedSelectionAdapter& selectionAdapter,
    const Patch13RejectionWrapper& rejectionWrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Discovery14WideAssumptionHandler";
    ctx.phase = "DISCOVERY_14_SHORT_ONLY_ATTEMPT";
    ctx.status = "LEGACY_ASSUMES_N_NOT_ABOVE_M";
    ctx.branchTrace.push_back("DISCOVERY_14_SHORT_ONLY_ATTEMPT");
    metrics.bump(ctx, "discovery14.shortOnly.calls");

    ctx.legacyWideSelectionRing = answerRingThroughPatchedNextBowl(
        ctx.patch11LatchedOrderSauce.finalBowls,
        ctx.legacyBiasedSelectionQueriedBowlId,
        ctx.patchedNextBowlOutput,
        ctx.legacyBiasedSelectionSeal);
    ctx.legacyWideSelectionFamilySize = ctx.legacyBiasedSelectionFamilySize;

    const LegacyWideSelectionAttempt attempt = adapter.attempt(
        ctx.legacyWideSelectionRing,
        ctx.legacyWideSelectionFamilySize,
        selectionAdapter,
        rejectionWrapper);
    ctx.legacyWideSelectionOutputAvailable = attempt.outputAvailable;
    ctx.legacyWideSelectionOutput = attempt.outputRank;
    ctx.legacyWideSelectionShortFailure = attempt.legacyShortFailure;
    ctx.legacyWideSelectionFailure = attempt.legacyFailure;
    ctx.legacyWideSelectionReady = true;

    ctx.phase = "DISCOVERY_14_VALIDATE";
    ctx.branchTrace.push_back("DISCOVERY_14_VALIDATE");
    validator.requireDiscovery14WideAssumptionReady(ctx);

    ctx.phase = "DISCOVERY_14_WIDE_ASSUMPTION_EXPOSED";
    ctx.status = "SHORT_ONLY_PATH_CANNOT_SELECT_N_ABOVE_M";
    ctx.branchTrace.push_back("DISCOVERY_14_WIDE_ASSUMPTION_EXPOSED");
    metrics.bump(ctx, "discovery14.wideAssumption.exposed");
}

void BaseDispatcher::dispatchLegacyWideSelectionAssumption(
    BaseMonsterContext& ctx,
    const Discovery14WideAssumptionHandler& handler,
    const LegacyShortOnlyWideSelectionAdapter& adapter,
    const LegacyBiasedSelectionAdapter& selectionAdapter,
    const Patch13RejectionWrapper& rejectionWrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.phase = "DISCOVERY_14_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("DISCOVERY_14_DISPATCH");
    metrics.bump(ctx, "discovery14.dispatch.calls");
    handler.handle(ctx, adapter, selectionAdapter, rejectionWrapper, validator, metrics);
}

void Patch14WideSelectionHandler::handle(
    BaseMonsterContext& ctx,
    const LegacyShortOnlyWideSelectionAdapter& legacyAdapter,
    const LegacyBiasedSelectionAdapter& selectionAdapter,
    const Patch13RejectionWrapper& rejectionWrapper,
    const Patch14WideDetourWrapper& wideWrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Patch14WideSelectionHandler";
    ctx.phase = "PATCH_14_BUILD_ANSWER_RING";
    ctx.status = "LEGACY_SHORT_ONLY_ATTEMPT_PRESERVED_BEFORE_DISPATCH";
    ctx.branchTrace.push_back("PATCH_14_BUILD_ANSWER_RING");
    metrics.bump(ctx, "patch14.answerRing.calls");

    ctx.legacyWideSelectionRing = answerRingThroughPatchedNextBowl(
        ctx.patch11LatchedOrderSauce.finalBowls,
        ctx.legacyBiasedSelectionQueriedBowlId,
        ctx.patchedNextBowlOutput,
        ctx.legacyBiasedSelectionSeal);
    ctx.legacyWideSelectionFamilySize = ctx.legacyBiasedSelectionFamilySize;

    ctx.phase = "PATCH_14_LEGACY_SHORT_ONLY_ATTEMPT";
    ctx.branchTrace.push_back("PATCH_14_LEGACY_SHORT_ONLY_ATTEMPT");
    const LegacyWideSelectionAttempt legacyAttempt = legacyAdapter.attempt(
        ctx.legacyWideSelectionRing,
        ctx.legacyWideSelectionFamilySize,
        selectionAdapter,
        rejectionWrapper);
    ctx.patch14LegacyOutputAvailableBeforePatch = legacyAttempt.outputAvailable;
    ctx.patch14LegacyOutputBeforePatch = legacyAttempt.outputRank;
    ctx.patch14LegacyShortFailureBeforePatch = legacyAttempt.legacyShortFailure;
    ctx.patch14LegacyFailureBeforePatch = legacyAttempt.legacyFailure;
    metrics.bump(ctx, "patch14.legacyShortOnly.calls");

    if (ctx.legacyWideSelectionFamilySize <= M_OLD) {
        ctx.phase = "PATCH_14_SHORT_DISPATCH";
        ctx.branchTrace.push_back("PATCH_14_SHORT_DISPATCH");
        if (!legacyAttempt.outputAvailable || legacyAttempt.legacyShortFailure) {
            throw BaseValidationError("via brevis legacy-compatible output non dedit");
        }
        ctx.legacyWideSelectionOutputAvailable = true;
        ctx.legacyWideSelectionOutput = legacyAttempt.outputRank;
        ctx.legacyWideSelectionShortFailure = false;
        ctx.legacyWideSelectionFailure.clear();
        ctx.patch14UsedShortPath = true;
        ctx.patch14UsedWideDetour = false;
        metrics.bump(ctx, "patch14.shortPath.calls");
    } else {
        ctx.phase = "PATCH_14_WIDE_DETOUR";
        ctx.branchTrace.push_back("PATCH_14_WIDE_DETOUR");
        const Patch14WideDetourSelection wide = wideWrapper.repair(
            ctx.legacyWideSelectionRing,
            ctx.legacyWideSelectionFamilySize,
            selectionAdapter);
        ctx.legacyWideSelectionOutputAvailable = true;
        ctx.legacyWideSelectionOutput = wide.outputRank;
        ctx.legacyWideSelectionShortFailure = false;
        ctx.legacyWideSelectionFailure.clear();
        ctx.patch14UsedShortPath = false;
        ctx.patch14UsedWideDetour = true;
        ctx.patch14WidePlaces = wide.places;
        ctx.patch14WideSpace = wide.space;
        ctx.patch14WideDigits = wide.digits;
        ctx.patch14WideDigitReadCount = wide.digitReadCount;
        ctx.patch14WideInitialValue = wide.initialWide;
        ctx.patch14WideAcceptanceLimit = wide.acceptanceLimit;
        ctx.patch14WideAcceptedValue = wide.acceptedWide;
        ctx.patch14WideRejectionSteps = wide.rejectionSteps;
        metrics.bump(ctx, "patch14.wideDetour.calls");
    }

    ctx.patch14Applied = true;
    ctx.legacyWideSelectionReady = true;
    ctx.phase = "PATCH_14_VALIDATE";
    ctx.branchTrace.push_back("PATCH_14_VALIDATE");
    validator.requirePatch14WideSelectionReady(ctx);

    ctx.phase = "PATCH_14_WIDE_SELECTION_READY";
    ctx.status = ctx.patch14UsedWideDetour
        ? "WIDE_DETOUR_REUSES_SINGLE_DIGIT_VECTOR"
        : "SHORT_PATH_REMAINS_LEGACY_COMPATIBLE";
    ctx.branchTrace.push_back("PATCH_14_WIDE_SELECTION_READY");
    metrics.bump(ctx, "patch14.wideSelection.ready");
}

void Discovery15GateQuestionHandler::handle(
    BaseMonsterContext& ctx,
    const LegacyGateQuestionAdapter& adapter,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Discovery15GateQuestionHandler";
    ctx.phase = "DISCOVERY_15_GATE_QUESTION";
    ctx.branchTrace.push_back("DISCOVERY_15_GATE_QUESTION");
    ctx.legacyGateQuestionMagnitude = ctx.legacyGateQuestionSignedStep;
    if (ctx.legacyGateQuestionMagnitude < 0) {
        ctx.legacyGateQuestionMagnitude = -ctx.legacyGateQuestionMagnitude;
    }
    ctx.legacyGateQuestionOutput = adapter.ask(ctx.legacyGateQuestionMagnitude);
    ctx.legacyGateQuestionReady = true;
    ctx.status = ctx.legacyGateQuestionSignedStep < 0
        ? "SIGNUM_NEGATIVUM_AB_CALLER_DELETUM"
        : "VIA_POSITIVA_LEGACY_CONCORDAT";
    metrics.bump(ctx, "discovery15.gateQuestion.calls");
    validator.requireDiscovery15GateQuestionReady(ctx);
}

void BaseDispatcher::dispatchLegacyGateQuestion(
    BaseMonsterContext& ctx,
    const Discovery15GateQuestionHandler& handler,
    const LegacyGateQuestionAdapter& adapter,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.phase = "DISCOVERY_15_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("DISCOVERY_15_DISPATCH");
    metrics.bump(ctx, "discovery15.dispatch.calls");
    handler.handle(ctx, adapter, validator, metrics);
}

void BaseDispatcher::dispatchPatchedWideSelection(
    BaseMonsterContext& ctx,
    const Patch14WideSelectionHandler& handler,
    const LegacyShortOnlyWideSelectionAdapter& legacyAdapter,
    const LegacyBiasedSelectionAdapter& selectionAdapter,
    const Patch13RejectionWrapper& rejectionWrapper,
    const Patch14WideDetourWrapper& wideWrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.phase = "PATCH_14_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("PATCH_14_DISPATCH");
    metrics.bump(ctx, "patch14.dispatch.calls");
    handler.handle(
        ctx,
        legacyAdapter,
        selectionAdapter,
        rejectionWrapper,
        wideWrapper,
        validator,
        metrics);
}

LegacyOrderMemoryReport BaseMonsterManager::executeOverwritableOrderMemorySauce(
    const Integer& calculationDay,
    const Integer& targetDay) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = calculationDay;
    ctx.targetDay = targetDay;
    ctx.phase = "PATCH_11_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyOrderMemorySauceAdapter adapter;
    const Patch11OrderAt46LatchWrapper wrapper;
    const Patch11OrderAt46LatchHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchPatchedOrderAt46Latch(ctx, handler, adapter, wrapper, validator, metrics);

    const LegacyOrderMemorySauceResult& legacy = ctx.legacyOrderMemorySauce;
    const Patch11LatchedOrderSauceResult& result = ctx.patch11LatchedOrderSauce;
    return LegacyOrderMemoryReport{
        calculationDay,
        targetDay,
        result.finalBowls,
        result.queryOrder,
        result.orderAt46Latch,
        result.finalPostStirOrder,
        result.legacyOrderWriteCount,
        result.finalLegacyOrderSource,
        legacy.queryOrder,
        result.orderAt46Latch,
        result.latchWriteCount,
        ctx.patch11Applied,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size()
    };
}

LegacyOrderMemoryReport BaseMonsterManager::executeUnpatchedOverwritableOrderMemoryDiagnostic(
    const Integer& calculationDay,
    const Integer& targetDay) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = calculationDay;
    ctx.targetDay = targetDay;
    ctx.phase = "DISCOVERY_11_DIAGNOSTIC_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyOrderMemorySauceAdapter adapter;
    const Discovery11OverwrittenOrderHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchLegacyOverwrittenOrder(ctx, handler, adapter, validator, metrics);

    const LegacyOrderMemorySauceResult& result = ctx.legacyOrderMemorySauce;
    return LegacyOrderMemoryReport{
        calculationDay,
        targetDay,
        result.finalBowls,
        result.queryOrder,
        result.orderAtDrop46Diagnostic,
        result.finalPostStirOrder,
        result.orderWriteCount,
        result.finalOrderSource,
        result.queryOrder,
        PermutationOrder{},
        0,
        false,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size()
    };
}

LegacyNextBowlReport BaseMonsterManager::executeLegacyNextBowl(
    const Integer& calculationDay,
    const Integer& targetDay,
    int queriedBowlId) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = calculationDay;
    ctx.targetDay = targetDay;
    ctx.phase = "PATCH_12_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";
    ctx.legacyNextBowlQueriedId = queriedBowlId;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyOrderMemorySauceAdapter orderMemoryAdapter;
    const Patch11OrderAt46LatchWrapper latchWrapper;
    const Patch11OrderAt46LatchHandler latchHandler;
    const LegacyNextBowlAdapter nextBowlAdapter;
    const Patch12NextBowlWrapper nextBowlWrapper;
    const Patch12NextBowlHandler nextBowlHandler;
    const BaseDispatcher dispatcher;

    dispatcher.dispatchPatchedOrderAt46Latch(
        ctx,
        latchHandler,
        orderMemoryAdapter,
        latchWrapper,
        validator,
        metrics);
    dispatcher.dispatchPatchedNextBowl(
        ctx,
        nextBowlHandler,
        nextBowlAdapter,
        nextBowlWrapper,
        validator,
        metrics);

    return LegacyNextBowlReport{
        calculationDay,
        targetDay,
        queriedBowlId,
        ctx.patchedNextBowlOutput,
        ctx.legacyNextBowlOrderAt46Latch,
        ctx.patch11LatchedOrderSauce.latchWriteCount,
        ctx.patch11Applied,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size(),
        ctx.legacyNextBowlOutput,
        ctx.patch12QueriedPosition,
        ctx.patch12Applied
    };
}

LegacyNextBowlReport BaseMonsterManager::executeUnpatchedNextBowlDiagnostic(
    const Integer& calculationDay,
    const Integer& targetDay,
    int queriedBowlId) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = calculationDay;
    ctx.targetDay = targetDay;
    ctx.phase = "DISCOVERY_12_DIAGNOSTIC_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";
    ctx.legacyNextBowlQueriedId = queriedBowlId;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyOrderMemorySauceAdapter orderMemoryAdapter;
    const Patch11OrderAt46LatchWrapper latchWrapper;
    const Patch11OrderAt46LatchHandler latchHandler;
    const LegacyNextBowlAdapter nextBowlAdapter;
    const Discovery12NextBowlHandler nextBowlHandler;
    const BaseDispatcher dispatcher;

    dispatcher.dispatchPatchedOrderAt46Latch(
        ctx,
        latchHandler,
        orderMemoryAdapter,
        latchWrapper,
        validator,
        metrics);
    dispatcher.dispatchLegacyNextBowl(
        ctx,
        nextBowlHandler,
        nextBowlAdapter,
        validator,
        metrics);

    return LegacyNextBowlReport{
        calculationDay,
        targetDay,
        queriedBowlId,
        ctx.legacyNextBowlOutput,
        ctx.legacyNextBowlOrderAt46Latch,
        ctx.patch11LatchedOrderSauce.latchWriteCount,
        ctx.patch11Applied,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size(),
        ctx.legacyNextBowlOutput,
        0,
        false
    };
}

LegacyBiasedSelectionReport BaseMonsterManager::executeLegacyBiasedSelection(
    const Integer& calculationDay,
    const Integer& targetDay,
    int queriedBowlId,
    int seal,
    const Integer& familySize) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = calculationDay;
    ctx.targetDay = targetDay;
    ctx.phase = "PATCH_13_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";
    ctx.legacyNextBowlQueriedId = queriedBowlId;
    ctx.legacyBiasedSelectionQueriedBowlId = queriedBowlId;
    ctx.legacyBiasedSelectionSeal = seal;
    ctx.legacyBiasedSelectionFamilySize = familySize;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyOrderMemorySauceAdapter orderMemoryAdapter;
    const Patch11OrderAt46LatchWrapper latchWrapper;
    const Patch11OrderAt46LatchHandler latchHandler;
    const LegacyNextBowlAdapter nextBowlAdapter;
    const Patch12NextBowlWrapper nextBowlWrapper;
    const Patch12NextBowlHandler nextBowlHandler;
    const LegacyBiasedSelectionAdapter selectionAdapter;
    const Patch13RejectionWrapper rejectionWrapper;
    const Patch13BiasedSelectionHandler selectionHandler;
    const BaseDispatcher dispatcher;

    dispatcher.dispatchPatchedOrderAt46Latch(
        ctx,
        latchHandler,
        orderMemoryAdapter,
        latchWrapper,
        validator,
        metrics);
    dispatcher.dispatchPatchedNextBowl(
        ctx,
        nextBowlHandler,
        nextBowlAdapter,
        nextBowlWrapper,
        validator,
        metrics);
    dispatcher.dispatchPatchedBiasedSelection(
        ctx,
        selectionHandler,
        selectionAdapter,
        rejectionWrapper,
        validator,
        metrics);

    return LegacyBiasedSelectionReport{
        calculationDay,
        targetDay,
        queriedBowlId,
        seal,
        familySize,
        ctx.legacyBiasedSelectionRing,
        ctx.legacyBiasedSelectionFirstAnswer,
        ctx.patchedBiasedSelectionOutput,
        ctx.patch11LatchedOrderSauce.finalBowls,
        ctx.patch11LatchedOrderSauce.orderAt46Latch,
        ctx.patchedNextBowlOutput,
        ctx.patch11Applied,
        ctx.patch12Applied,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size(),
        ctx.legacyBiasedSelectionOutput,
        ctx.patch13AcceptanceLimit,
        ctx.patch13AcceptedAnswer,
        ctx.patch13AcceptedOffset,
        ctx.patch13Applied
    };
}

LegacyBiasedSelectionReport BaseMonsterManager::executeUnpatchedBiasedSelectionDiagnostic(
    const Integer& calculationDay,
    const Integer& targetDay,
    int queriedBowlId,
    int seal,
    const Integer& familySize) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = calculationDay;
    ctx.targetDay = targetDay;
    ctx.phase = "DISCOVERY_13_DIAGNOSTIC_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";
    ctx.legacyNextBowlQueriedId = queriedBowlId;
    ctx.legacyBiasedSelectionQueriedBowlId = queriedBowlId;
    ctx.legacyBiasedSelectionSeal = seal;
    ctx.legacyBiasedSelectionFamilySize = familySize;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyOrderMemorySauceAdapter orderMemoryAdapter;
    const Patch11OrderAt46LatchWrapper latchWrapper;
    const Patch11OrderAt46LatchHandler latchHandler;
    const LegacyNextBowlAdapter nextBowlAdapter;
    const Patch12NextBowlWrapper nextBowlWrapper;
    const Patch12NextBowlHandler nextBowlHandler;
    const LegacyBiasedSelectionAdapter selectionAdapter;
    const Discovery13BiasedSelectionHandler selectionHandler;
    const BaseDispatcher dispatcher;

    dispatcher.dispatchPatchedOrderAt46Latch(
        ctx,
        latchHandler,
        orderMemoryAdapter,
        latchWrapper,
        validator,
        metrics);
    dispatcher.dispatchPatchedNextBowl(
        ctx,
        nextBowlHandler,
        nextBowlAdapter,
        nextBowlWrapper,
        validator,
        metrics);
    dispatcher.dispatchLegacyBiasedSelection(
        ctx,
        selectionHandler,
        selectionAdapter,
        validator,
        metrics);

    return LegacyBiasedSelectionReport{
        calculationDay,
        targetDay,
        queriedBowlId,
        seal,
        familySize,
        ctx.legacyBiasedSelectionRing,
        ctx.legacyBiasedSelectionFirstAnswer,
        ctx.legacyBiasedSelectionOutput,
        ctx.patch11LatchedOrderSauce.finalBowls,
        ctx.patch11LatchedOrderSauce.orderAt46Latch,
        ctx.patchedNextBowlOutput,
        ctx.patch11Applied,
        ctx.patch12Applied,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size(),
        ctx.legacyBiasedSelectionOutput,
        Integer{0},
        Integer{0},
        Integer{0},
        false
    };
}

LegacyWideSelectionReport BaseMonsterManager::executeLegacyWideSelectionAssumption(
    const Integer& calculationDay,
    const Integer& targetDay,
    int queriedBowlId,
    int seal,
    const Integer& familySize) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = calculationDay;
    ctx.targetDay = targetDay;
    ctx.phase = "PATCH_14_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";
    ctx.legacyNextBowlQueriedId = queriedBowlId;
    ctx.legacyBiasedSelectionQueriedBowlId = queriedBowlId;
    ctx.legacyBiasedSelectionSeal = seal;
    ctx.legacyBiasedSelectionFamilySize = familySize;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyOrderMemorySauceAdapter orderMemoryAdapter;
    const Patch11OrderAt46LatchWrapper latchWrapper;
    const Patch11OrderAt46LatchHandler latchHandler;
    const LegacyNextBowlAdapter nextBowlAdapter;
    const Patch12NextBowlWrapper nextBowlWrapper;
    const Patch12NextBowlHandler nextBowlHandler;
    const LegacyBiasedSelectionAdapter selectionAdapter;
    const Patch13RejectionWrapper rejectionWrapper;
    const LegacyShortOnlyWideSelectionAdapter wideLegacyAdapter;
    const Patch14WideDetourWrapper wideWrapper;
    const Patch14WideSelectionHandler wideHandler;
    const BaseDispatcher dispatcher;

    dispatcher.dispatchPatchedOrderAt46Latch(
        ctx,
        latchHandler,
        orderMemoryAdapter,
        latchWrapper,
        validator,
        metrics);
    dispatcher.dispatchPatchedNextBowl(
        ctx,
        nextBowlHandler,
        nextBowlAdapter,
        nextBowlWrapper,
        validator,
        metrics);
    dispatcher.dispatchPatchedWideSelection(
        ctx,
        wideHandler,
        wideLegacyAdapter,
        selectionAdapter,
        rejectionWrapper,
        wideWrapper,
        validator,
        metrics);

    return LegacyWideSelectionReport{
        calculationDay,
        targetDay,
        queriedBowlId,
        seal,
        familySize,
        ctx.legacyWideSelectionRing,
        ctx.legacyWideSelectionOutputAvailable,
        ctx.legacyWideSelectionOutput,
        ctx.legacyWideSelectionShortFailure,
        ctx.legacyWideSelectionFailure,
        ctx.patch11LatchedOrderSauce.finalBowls,
        ctx.patch11LatchedOrderSauce.orderAt46Latch,
        ctx.patchedNextBowlOutput,
        ctx.patch11Applied,
        ctx.patch12Applied,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size(),
        ctx.patch14LegacyOutputAvailableBeforePatch,
        ctx.patch14LegacyOutputBeforePatch,
        ctx.patch14LegacyShortFailureBeforePatch,
        ctx.patch14LegacyFailureBeforePatch,
        ctx.patch14Applied,
        ctx.patch14UsedShortPath,
        ctx.patch14UsedWideDetour,
        ctx.patch14WidePlaces,
        ctx.patch14WideSpace,
        ctx.patch14WideDigits,
        ctx.patch14WideDigitReadCount,
        ctx.patch14WideInitialValue,
        ctx.patch14WideAcceptanceLimit,
        ctx.patch14WideAcceptedValue,
        ctx.patch14WideRejectionSteps
    };
}

LegacyWideSelectionReport BaseMonsterManager::executeUnpatchedWideSelectionDiagnostic(
    const Integer& calculationDay,
    const Integer& targetDay,
    int queriedBowlId,
    int seal,
    const Integer& familySize) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = calculationDay;
    ctx.targetDay = targetDay;
    ctx.phase = "DISCOVERY_14_DIAGNOSTIC_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";
    ctx.legacyNextBowlQueriedId = queriedBowlId;
    ctx.legacyBiasedSelectionQueriedBowlId = queriedBowlId;
    ctx.legacyBiasedSelectionSeal = seal;
    ctx.legacyBiasedSelectionFamilySize = familySize;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyOrderMemorySauceAdapter orderMemoryAdapter;
    const Patch11OrderAt46LatchWrapper latchWrapper;
    const Patch11OrderAt46LatchHandler latchHandler;
    const LegacyNextBowlAdapter nextBowlAdapter;
    const Patch12NextBowlWrapper nextBowlWrapper;
    const Patch12NextBowlHandler nextBowlHandler;
    const LegacyBiasedSelectionAdapter selectionAdapter;
    const Patch13RejectionWrapper rejectionWrapper;
    const LegacyShortOnlyWideSelectionAdapter wideLegacyAdapter;
    const Discovery14WideAssumptionHandler wideHandler;
    const BaseDispatcher dispatcher;

    dispatcher.dispatchPatchedOrderAt46Latch(
        ctx,
        latchHandler,
        orderMemoryAdapter,
        latchWrapper,
        validator,
        metrics);
    dispatcher.dispatchPatchedNextBowl(
        ctx,
        nextBowlHandler,
        nextBowlAdapter,
        nextBowlWrapper,
        validator,
        metrics);
    dispatcher.dispatchLegacyWideSelectionAssumption(
        ctx,
        wideHandler,
        wideLegacyAdapter,
        selectionAdapter,
        rejectionWrapper,
        validator,
        metrics);

    return LegacyWideSelectionReport{
        calculationDay,
        targetDay,
        queriedBowlId,
        seal,
        familySize,
        ctx.legacyWideSelectionRing,
        ctx.legacyWideSelectionOutputAvailable,
        ctx.legacyWideSelectionOutput,
        ctx.legacyWideSelectionShortFailure,
        ctx.legacyWideSelectionFailure,
        ctx.patch11LatchedOrderSauce.finalBowls,
        ctx.patch11LatchedOrderSauce.orderAt46Latch,
        ctx.patchedNextBowlOutput,
        ctx.patch11Applied,
        ctx.patch12Applied,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size()
    };
}

LegacyGateQuestionReport BaseMonsterManager::executeLegacyGateQuestionDay(
    const Integer& signedStep) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = FOUNDATION_DAY_OLD;
    ctx.targetDay = FOUNDATION_DAY_OLD;
    ctx.phase = "DISCOVERY_15_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";
    ctx.legacyGateQuestionSignedStep = signedStep;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyGateQuestionAdapter adapter;
    const Discovery15GateQuestionHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchLegacyGateQuestion(ctx, handler, adapter, validator, metrics);

    return LegacyGateQuestionReport{
        signedStep,
        ctx.legacyGateQuestionMagnitude,
        ctx.legacyGateQuestionOutput,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size()
    };
}

} // namespace pastafari
