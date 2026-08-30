#include "pastafari/monster.hpp"
#include "pastafari/source_language_catalog.hpp"

#include <algorithm>
#include <limits>
#include <mutex>
#include <numeric>
#include <set>
#include <tuple>

namespace pastafari {

namespace {

// PATCHES 27-39: memoria externa non managerem immortalem facit.
// Manager adhuc nascitur et moritur; tantum sepulcra, ossuaria et testamenta
// semantice probata extra vitam eius manent.
constexpr std::uint64_t PERSISTENT_SCAR_GENERATION = 39;
constexpr std::size_t FINAL_RESULT_BURIAL_LIMIT = 4096;
constexpr std::size_t ANCESTRAL_STRUCTURE_LIMIT = 128;
constexpr std::size_t YEAR_CHECKPOINT_LIMIT = 8192;
constexpr std::size_t GATE_GRAVEYARD_LIMIT = 32768;
constexpr std::size_t SAUCE_TOMB_LIMIT = 512;
constexpr std::size_t STAGE56_SAUCE_TOMB_LIMIT = 256;
constexpr std::size_t AUTOPSY_LIMIT = 128;
constexpr std::size_t REJECTION_SCAR_LIMIT = 16384;
constexpr std::size_t VIRTUAL_MEMO_GRAVEYARD_LIMIT = 4096;
constexpr std::size_t LEGAL_WEAVING_SKELETON_LIMIT = 512;
constexpr std::size_t WORKSPACE_WILL_LIMIT = 512;

bool accelerationScarsEnabledInternal = true;
bool fullHistoricalAccelerationValidationInternal = false;
std::mutex accelerationModeMutex;

PersistentScarMetrics persistentScarMetricsState{};
std::mutex persistentScarMetricsMutex;

void scarBump(std::uint64_t PersistentScarMetrics::*member,
              std::uint64_t amount = 1) {
    std::lock_guard<std::mutex> guard(persistentScarMetricsMutex);
    persistentScarMetricsState.*member += amount;
}

const std::string& persistentCatalogFossilFingerprint() {
    // PATCH39 CICATRIX: catalogus non fit hash nitidus nec dependency nova.
    // Nomina ipsa, cum longitudinibus et indicibus, quasi dentes in sarcophago
    // concatenantur.  Mutatio unius tituli corpus cache vetus reddit.
    static const std::string fossil = [] {
        std::string out = "CATALOG_FOSSIL";
        for (const CatalogEntry& entry : CUTLET_SOURCE_CATALOG) {
            out += "|C" + std::to_string(entry.canonicalIndex) + ":" +
                   std::to_string(entry.text.size()) + ":" + std::string(entry.text);
        }
        for (const CatalogEntry& entry : MONTH_SOURCE_CATALOG) {
            out += "|M" + std::to_string(entry.canonicalIndex) + ":" +
                   std::to_string(entry.text.size()) + ":" + std::string(entry.text);
        }
        return out;
    }();
    return fossil;
}

const std::string& persistentSemanticFingerprint() {
    static const std::string fingerprint =
        std::string("PATCH39|") +
        "M_OLD=" + M_OLD.str() +
        "|FOUNDATION_DAY_OLD=" + FOUNDATION_DAY_OLD.str() +
        "|LEGACY_YEAR_MAX=" + std::to_string(LEGACY_YEAR_MAX) +
        "|REAL_YEAR_MAX_PATCH=" + std::to_string(REAL_YEAR_MAX_PATCH) +
        "|LEGACY_MONTH_LENGTH_MIN=" + std::to_string(LEGACY_MONTH_LENGTH_MIN) +
        "|LEGACY_MONTH_LENGTH_MAX=" + std::to_string(LEGACY_MONTH_LENGTH_MAX) +
        "|PATCH_GENERATION=" + std::to_string(PERSISTENT_SCAR_GENERATION) +
        "|SAUCE_GENERATION=STAGE56_RAW_BOWL_SUM" +
        "|" + persistentCatalogFossilFingerprint();
    return fingerprint;
}

template <class Map>
void boundedEraseFirst(Map& map, std::size_t limit) {
    while (map.size() >= limit && !map.empty()) {
        map.erase(map.begin());
    }
}

struct GateGraveyardKey {
    bool stage56 = false;
    Integer index{};
    bool operator<(const GateGraveyardKey& other) const {
        return std::tie(stage56, index) < std::tie(other.stage56, other.index);
    }
};

struct BuriedGate {
    Integer index{};
    Integer day{};
    std::uint64_t scarGeneration = 28;
    bool verifiedThroughLegacyGapPath = false;
    bool poisoned = false;
    std::string semanticFingerprint{};
};

std::map<GateGraveyardKey, BuriedGate> gateGraveyard;
std::mutex gateGraveyardMutex;

struct YearCheckpointKey {
    bool stage56 = false;
    Integer calculationDay{};
    Integer yearNumber{};
    bool operator<(const YearCheckpointKey& other) const {
        return std::tie(stage56, calculationDay, yearNumber) <
               std::tie(other.stage56, other.calculationDay, other.yearNumber);
    }
};

struct BuriedYearCheckpoint {
    Integer calculationDayFingerprint{};
    Patch18YearRecord year{};
    std::uint64_t scarGeneration = 30;
    bool stage56 = false;
    bool poisoned = false;
    std::string semanticFingerprint{};
};

std::map<YearCheckpointKey, BuriedYearCheckpoint> yearCheckpointVault;
std::mutex yearCheckpointVaultMutex;

struct WorkspaceWillKey {
    bool stage56 = false;
    Integer calculationDay{};
    bool operator<(const WorkspaceWillKey& other) const {
        return std::tie(stage56, calculationDay) <
               std::tie(other.stage56, other.calculationDay);
    }
};

struct DeadWorkspaceWill {
    Integer minGateIndex{};
    Integer maxGateIndex{};
    std::uint64_t scarGeneration = 31;
    std::string semanticFingerprint{};
    bool poisoned = false;
};

std::map<WorkspaceWillKey, DeadWorkspaceWill> workspaceWillVault;
std::mutex workspaceWillVaultMutex;

struct SauceKey {
    Integer calculationDay{};
    Integer targetDay{};
    bool operator<(const SauceKey& other) const {
        return std::tie(calculationDay, targetDay) <
               std::tie(other.calculationDay, other.targetDay);
    }
};

struct BuriedSauce {
    Patch11LatchedOrderSauceResult value{};
    std::uint64_t scarGeneration = 32;
    bool poisoned = false;
    std::string semanticFingerprint{};
};

struct BuriedStage56Sauce {
    Stage56RawBowlSumSauceResult value{};
    std::uint64_t scarGeneration = 32;
    bool poisoned = false;
    std::string semanticFingerprint{};
};

std::map<SauceKey, BuriedSauce> sauceTomb;
std::mutex sauceTombMutex;
std::map<SauceKey, BuriedStage56Sauce> stage56SauceTomb;
std::mutex stage56SauceTombMutex;

struct SauceAutopsyRecord {
    LegacySauceCounts counts{};
    StoneTable stones{};
    HiddenDrops hidden{};
    VisibleDropStore visible{};
    bool diagnosticBodyBuilt = false;
    bool authoritativeBodyResurrected = false;
    bool legacyDoubleComputationShapePreserved = false;
    bool poisoned = false;
    std::uint64_t scarGeneration = 33;
    std::string semanticFingerprint{};
};

std::map<SauceKey, SauceAutopsyRecord> sauceAutopsyVault;
std::mutex sauceAutopsyVaultMutex;

struct StoneTableFossil {
    StoneTable value{};
    bool present = false;
    bool poisoned = false;
    std::uint64_t scarGeneration = 35;
    std::string semanticFingerprint{};
};

StoneTableFossil stoneTableFossil;
std::mutex stoneTableFossilMutex;

struct RejectionScarKey {
    Integer ringFirst{};
    int directionStep = 0;
    Integer familySize{};
    Integer acceptanceLimit{};
    bool operator<(const RejectionScarKey& other) const {
        return std::tie(ringFirst, directionStep, familySize, acceptanceLimit) <
               std::tie(other.ringFirst, other.directionStep,
                        other.familySize, other.acceptanceLimit);
    }
};

struct RejectionCertificate {
    Integer firstRejectedOffset{};
    Integer acceptedOffset{};
    Integer acceptedAnswer{};
    bool poisoned = false;
    std::uint64_t scarGeneration = 36;
    std::string semanticFingerprint{};
};

std::map<RejectionScarKey, RejectionCertificate> rejectionScarVault;
std::mutex rejectionScarVaultMutex;

struct WideRejectionScarKey {
    Integer ringFirst{};
    int directionStep = 0;
    Integer familySize{};
    Integer space{};
    Integer acceptanceLimit{};
    Integer initialWide{};
    bool operator<(const WideRejectionScarKey& other) const {
        return std::tie(ringFirst, directionStep, familySize, space,
                        acceptanceLimit, initialWide) <
               std::tie(other.ringFirst, other.directionStep, other.familySize,
                        other.space, other.acceptanceLimit, other.initialWide);
    }
};

struct WideRejectionCertificate {
    Integer acceptedWide{};
    Integer rejectionSteps{};
    bool poisoned = false;
    std::uint64_t scarGeneration = 36;
    std::string semanticFingerprint{};
};

std::map<WideRejectionScarKey, WideRejectionCertificate> wideRejectionScarVault;
std::mutex wideRejectionScarVaultMutex;

struct VirtualMemoBoneKey {
    int yearLength = 0;
    int monthCount = 0;
    int remaining = 0;
    int slots = 0;
    bool operator<(const VirtualMemoBoneKey& other) const {
        return std::tie(yearLength, monthCount, remaining, slots) <
               std::tie(other.yearLength, other.monthCount,
                        other.remaining, other.slots);
    }
};

struct VirtualMemoBone {
    Integer count{};
    bool poisoned = false;
    std::uint64_t scarGeneration = 37;
    std::string semanticFingerprint{};
};

std::map<VirtualMemoBoneKey, VirtualMemoBone> virtualMemoGraveyard;
std::mutex virtualMemoGraveyardMutex;

struct LegalWeavingSkeletonBones {
    std::vector<int> maxActive{};
    std::vector<std::vector<Integer>> suffixPerFixedActive{};
    bool poisoned = false;
    std::uint64_t scarGeneration = 38;
    std::string semanticFingerprint{};
};

std::map<std::vector<int>, LegalWeavingSkeletonBones> legalWeavingSkeletonVault;
std::mutex legalWeavingSkeletonVaultMutex;

struct StructureVaultKey {
    bool stage56 = false;
    Integer calculationDay{};
    Integer yearNumber{};
    Integer openGate{};
    Integer closeGate{};
    bool operator<(const StructureVaultKey& other) const {
        return std::tie(stage56, calculationDay, yearNumber, openGate, closeGate) <
               std::tie(other.stage56, other.calculationDay, other.yearNumber,
                        other.openGate, other.closeGate);
    }
};

struct BuriedFinalStructure {
    Integer calculationDayFingerprint{};
    Integer yearNumber{};
    Integer openGate{};
    Integer closeGate{};
    SpaghettiYearStructure value{};
    std::size_t resurrectionCount = 0;
    std::size_t burialGeneration = 27;
    bool stage56 = false;
    bool poisoned = false;
    std::string semanticFingerprint{};
};

std::map<StructureVaultKey, BuriedFinalStructure> ancestralMemoryVault;
std::mutex ancestralMemoryVaultMutex;

struct FinalResultKey {
    Integer calculationDay{};
    Integer targetDay{};
    std::uint64_t semanticGeneration = PERSISTENT_SCAR_GENERATION;
    bool operator<(const FinalResultKey& other) const {
        return std::tie(calculationDay, targetDay, semanticGeneration) <
               std::tie(other.calculationDay, other.targetDay,
                        other.semanticGeneration);
    }
};

struct BuriedFinalResult {
    SpaghettiDateFive value{};
    bool poisoned = false;
    std::uint64_t scarGeneration = 39;
    std::string semanticFingerprint{};
};

std::map<FinalResultKey, BuriedFinalResult> finalResultBurialVault;
std::mutex finalResultBurialVaultMutex;

bool accelerationsOn() {
    std::lock_guard<std::mutex> guard(accelerationModeMutex);
    return accelerationScarsEnabledInternal;
}

bool fullHistoricalValidationOn() {
    std::lock_guard<std::mutex> guard(accelerationModeMutex);
    return fullHistoricalAccelerationValidationInternal;
}

bool fingerprintAcceptable(const std::string& fingerprint,
                           std::uint64_t generation,
                           std::uint64_t minimumGeneration) {
    return generation >= minimumGeneration &&
           fingerprint == persistentSemanticFingerprint();
}

} // namespace

void setAccelerationScarsEnabled(bool enabled) {
    std::lock_guard<std::mutex> guard(accelerationModeMutex);
    accelerationScarsEnabledInternal = enabled;
}

bool accelerationScarsEnabled() {
    return accelerationsOn();
}

void setFullHistoricalAccelerationValidation(bool enabled) {
    std::lock_guard<std::mutex> guard(accelerationModeMutex);
    fullHistoricalAccelerationValidationInternal = enabled;
}

bool fullHistoricalAccelerationValidation() {
    return fullHistoricalValidationOn();
}

PersistentScarMetrics persistentScarMetricsDiagnostic() {
    std::lock_guard<std::mutex> guard(persistentScarMetricsMutex);
    return persistentScarMetricsState;
}

void resetPersistentScarVaultsDiagnostic() {
    {
        std::lock_guard<std::mutex> guard(gateGraveyardMutex);
        gateGraveyard.clear();
    }
    {
        std::lock_guard<std::mutex> guard(yearCheckpointVaultMutex);
        yearCheckpointVault.clear();
    }
    {
        std::lock_guard<std::mutex> guard(workspaceWillVaultMutex);
        workspaceWillVault.clear();
    }
    {
        std::lock_guard<std::mutex> guard(sauceTombMutex);
        sauceTomb.clear();
    }
    {
        std::lock_guard<std::mutex> guard(stage56SauceTombMutex);
        stage56SauceTomb.clear();
    }
    {
        std::lock_guard<std::mutex> guard(sauceAutopsyVaultMutex);
        sauceAutopsyVault.clear();
    }
    {
        std::lock_guard<std::mutex> guard(stoneTableFossilMutex);
        stoneTableFossil = StoneTableFossil{};
    }
    {
        std::lock_guard<std::mutex> guard(rejectionScarVaultMutex);
        rejectionScarVault.clear();
    }
    {
        std::lock_guard<std::mutex> guard(wideRejectionScarVaultMutex);
        wideRejectionScarVault.clear();
    }
    {
        std::lock_guard<std::mutex> guard(virtualMemoGraveyardMutex);
        virtualMemoGraveyard.clear();
    }
    {
        std::lock_guard<std::mutex> guard(legalWeavingSkeletonVaultMutex);
        legalWeavingSkeletonVault.clear();
    }
    {
        std::lock_guard<std::mutex> guard(ancestralMemoryVaultMutex);
        ancestralMemoryVault.clear();
    }
    {
        std::lock_guard<std::mutex> guard(finalResultBurialVaultMutex);
        finalResultBurialVault.clear();
    }
    {
        std::lock_guard<std::mutex> guard(persistentScarMetricsMutex);
        persistentScarMetricsState = PersistentScarMetrics{};
    }
}

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

Integer oldJumpGuess(const LegacyYearAnchor& anchor, const Integer& targetDay) {
    const Integer delta = targetDay - anchor.firstDay;
    Integer q = delta / 365;
    const Integer r = delta % 365;
    if (r < 0) {
        --q;
    }
    return anchor.number + q;
}

bool legacyYearCandidateAllowed(const std::vector<Integer>& gates,
                                std::size_t openIndex,
                                std::size_t closeIndex) {
    if (openIndex >= gates.size() || closeIndex >= gates.size() || closeIndex <= openIndex) {
        return false;
    }
    const std::size_t gapCount = closeIndex - openIndex;
    const Integer candidateLength = gates[closeIndex] - gates[openIndex];
    return gapCount >= 6 &&
           candidateLength >= 252 &&
           candidateLength <= LEGACY_YEAR_MAX;
}

LegacyYearCandidateList legacyYearCandidatesBeforeSort(
    const std::vector<Integer>& gates,
    const std::vector<LegacyYearCandidatePair>& pairs) {
    LegacyYearCandidateList out;
    for (const LegacyYearCandidatePair& pair : pairs) {
        if (!legacyYearCandidateAllowed(gates, pair.openIndex, pair.closeIndex)) {
            continue;
        }
        out.push_back(LegacyYearCandidate{
            pair.openIndex,
            pair.closeIndex,
            gates[pair.closeIndex] - gates[pair.openIndex]
        });
    }
    return out;
}

LegacyYearCandidateList legacyStableLengthOnlyYearCandidates(
    const LegacyYearCandidateList& candidates) {
    LegacyYearCandidateList out = candidates;
    std::stable_sort(out.begin(), out.end(), [](const LegacyYearCandidate& a,
                                                const LegacyYearCandidate& b) {
        return a.length < b.length;
    });
    return out;
}

Patch16YearCandidateDecision yearCandidateAfterFootnotePatch(
    const std::vector<Integer>& gates,
    std::size_t openIndex,
    std::size_t closeIndex) {
    const bool legacyAccepted = legacyYearCandidateAllowed(gates, openIndex, closeIndex);
    if (!legacyAccepted) {
        return Patch16YearCandidateDecision{};
    }
    const LegacyYearCandidate candidate{
        openIndex,
        closeIndex,
        gates[closeIndex] - gates[openIndex]
    };
    return Patch16YearCandidateDecision{
        true,
        candidate.length <= REAL_YEAR_MAX_PATCH,
        candidate
    };
}

LegacyYear5000TiePreparation legacyYear5000TiePreparation(
    const std::vector<Integer>& gates,
    const std::vector<LegacyYearCandidatePair>& pairs,
    const Integer& calculationDay) {
    LegacyYear5000TiePreparation out;
    for (const LegacyYearCandidatePair& pair : pairs) {
        const Patch16YearCandidateDecision decision = yearCandidateAfterFootnotePatch(
            gates,
            pair.openIndex,
            pair.closeIndex);
        if (!decision.semanticAccepted) {
            continue;
        }
        if (!(gates[pair.openIndex] < calculationDay &&
              calculationDay <= gates[pair.closeIndex])) {
            continue;
        }
        out.preSort.push_back(decision.candidate);
    }
    out.sorted = legacyStableLengthOnlyYearCandidates(out.preSort);
    return out;
}

LegacyYearCandidateList sortEqualLengthRunsByOpeningGate(
    const std::vector<Integer>& gates,
    const LegacyYearCandidateList& lengthSorted) {
    LegacyYearCandidateList out = lengthSorted;
    std::size_t begin = 0;
    while (begin < out.size()) {
        std::size_t end = begin + 1;
        while (end < out.size() && out[end].length == out[begin].length) {
            ++end;
        }
        if (end - begin > 1) {
            std::stable_sort(
                out.begin() + static_cast<std::ptrdiff_t>(begin),
                out.begin() + static_cast<std::ptrdiff_t>(end),
                [&](const LegacyYearCandidate& a, const LegacyYearCandidate& b) {
                    return gates[a.openIndex] < gates[b.openIndex];
                });
        }
        begin = end;
    }
    return out;
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

namespace {

StoneTable buildStonesThroughLegacyBuilderUnfossilized() {
    StoneTable table{};
    Stone state{Integer{17}, Integer{29}, Integer{43}, Integer{71}, Integer{101}};
    table[1] = state;
    for (int i = 2; i <= 46; ++i) {
        state = stonePatch(i, state);
        table[i] = state;
    }
    return table;
}

bool cheapStoneFossilIntegrity(const StoneTable& table) {
    return table[1][0] == Integer{17} &&
           table[1][1] == Integer{29} &&
           table[1][2] == Integer{43} &&
           table[1][3] == Integer{71} &&
           table[1][4] == Integer{101};
}

} // namespace

StoneTable buildStonesThroughLegacyBuilder() {
    if (!accelerationsOn()) {
        scarBump(&PersistentScarMetrics::patch35StoneFullRebuild);
        return buildStonesThroughLegacyBuilderUnfossilized();
    }

    StoneTable fossilCopy{};
    bool fossilFound = false;
    {
        std::lock_guard<std::mutex> guard(stoneTableFossilMutex);
        if (stoneTableFossil.present &&
            !stoneTableFossil.poisoned &&
            fingerprintAcceptable(
                stoneTableFossil.semanticFingerprint,
                stoneTableFossil.scarGeneration,
                35)) {
            fossilCopy = stoneTableFossil.value;
            fossilFound = true;
        } else if (stoneTableFossil.present) {
            stoneTableFossil.poisoned = true;
            scarBump(&PersistentScarMetrics::staleOrPoisonedRejected);
        }
    }

    if (fossilFound && cheapStoneFossilIntegrity(fossilCopy)) {
        scarBump(&PersistentScarMetrics::patch35StoneFossilHit);
        if (fullHistoricalValidationOn()) {
            scarBump(&PersistentScarMetrics::patch35StoneFullRebuild);
            const StoneTable rebuilt = buildStonesThroughLegacyBuilderUnfossilized();
            if (rebuilt != fossilCopy) {
                std::lock_guard<std::mutex> guard(stoneTableFossilMutex);
                stoneTableFossil.poisoned = true;
                scarBump(&PersistentScarMetrics::staleOrPoisonedRejected);
                return rebuilt;
            }
        }
        return fossilCopy;
    }

    scarBump(&PersistentScarMetrics::patch35StoneFossilMiss);
    scarBump(&PersistentScarMetrics::patch35StoneFullRebuild);
    const StoneTable rebuilt = buildStonesThroughLegacyBuilderUnfossilized();

    {
        std::lock_guard<std::mutex> guard(stoneTableFossilMutex);
        if (!stoneTableFossil.present || stoneTableFossil.poisoned ||
            !fingerprintAcceptable(
                stoneTableFossil.semanticFingerprint,
                stoneTableFossil.scarGeneration,
                35)) {
            stoneTableFossil = StoneTableFossil{
                rebuilt, true, false, 35, persistentSemanticFingerprint()};
        }
    }
    return rebuilt;
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

namespace {

bool sameLatchedSauce(const Patch11LatchedOrderSauceResult& a,
                      const Patch11LatchedOrderSauceResult& b) {
    return a.finalBowls == b.finalBowls &&
           a.orderAt46Latch == b.orderAt46Latch &&
           a.queryOrder == b.queryOrder &&
           a.legacyQueryOrderBeforePatch == b.legacyQueryOrderBeforePatch &&
           a.finalPostStirOrder == b.finalPostStirOrder &&
           a.legacyOrderWriteCount == b.legacyOrderWriteCount &&
           a.latchWriteCount == b.latchWriteCount;
}

namespace patch32_legacy_body {

Patch11LatchedOrderSauceResult sauceWithOrderAt46Latch(
    const Integer& calculationDay,
    const Integer& targetDay) {
    LegacySauceCounts counts{};
    StoneTable stones{};
    HiddenDrops hiddenBackward{};
    VisibleDropStore visible{};
    bool autopsyResurrected = false;

    if (accelerationsOn() && !fullHistoricalValidationOn()) {
        const SauceKey key{calculationDay, targetDay};
        std::lock_guard<std::mutex> guard(sauceAutopsyVaultMutex);
        const auto found = sauceAutopsyVault.find(key);
        if (found != sauceAutopsyVault.end()) {
            if (!found->second.poisoned &&
                found->second.diagnosticBodyBuilt &&
                fingerprintAcceptable(
                    found->second.semanticFingerprint,
                    found->second.scarGeneration,
                    33)) {
                counts = found->second.counts;
                stones = found->second.stones;
                hiddenBackward = found->second.hidden;
                visible = found->second.visible;
                autopsyResurrected = true;
            } else if (!found->second.poisoned) {
                found->second.poisoned = true;
                scarBump(&PersistentScarMetrics::staleOrPoisonedRejected);
            }
        }
    }

    if (!autopsyResurrected) {
        counts = sauceCountsThroughScars(calculationDay, targetDay);
        stones = buildStonesThroughLegacyBuilder();
        hiddenBackward = buildHiddenWithBackwardStorage(
            calculationDay, targetDay, stones);
        visible = buildVisibleDropsThroughPatchedHistory(
            counts, stones, hiddenBackward);
    } else {
        scarBump(&PersistentScarMetrics::patch33AuthoritativeBodyResurrected);
        scarBump(&PersistentScarMetrics::patch33LegacyDoubleComputationShapePreserved);
    }

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

} // namespace patch32_legacy_body
} // namespace

Patch11LatchedOrderSauceResult sauceWithOrderAt46Latch(
    const Integer& calculationDay,
    const Integer& targetDay) {
    if (!accelerationsOn()) {
        scarBump(&PersistentScarMetrics::patch32SauceRecomputed);
        return patch32_legacy_body::sauceWithOrderAt46Latch(calculationDay, targetDay);
    }

    const SauceKey key{calculationDay, targetDay};
    BuriedSauce corpse{};
    bool foundCorpse = false;
    {
        std::lock_guard<std::mutex> guard(sauceTombMutex);
        const auto found = sauceTomb.find(key);
        if (found != sauceTomb.end()) {
            scarBump(&PersistentScarMetrics::patch32SauceCorpseFound);
            if (!found->second.poisoned &&
                fingerprintAcceptable(
                    found->second.semanticFingerprint,
                    found->second.scarGeneration,
                    32)) {
                corpse = found->second;
                foundCorpse = true;
            } else {
                found->second.poisoned = true;
                scarBump(&PersistentScarMetrics::patch32SauceGenerationMismatch);
                scarBump(&PersistentScarMetrics::staleOrPoisonedRejected);
            }
        }
    }

    if (foundCorpse) {
        scarBump(&PersistentScarMetrics::patch32SauceResurrected);
        if (fullHistoricalValidationOn()) {
            const Patch11LatchedOrderSauceResult rebuilt =
                patch32_legacy_body::sauceWithOrderAt46Latch(calculationDay, targetDay);
            scarBump(&PersistentScarMetrics::patch32SauceRecomputed);
            if (!sameLatchedSauce(rebuilt, corpse.value)) {
                std::lock_guard<std::mutex> guard(sauceTombMutex);
                const auto found = sauceTomb.find(key);
                if (found != sauceTomb.end()) found->second.poisoned = true;
                scarBump(&PersistentScarMetrics::staleOrPoisonedRejected);
                return rebuilt;
            }
        }
        return corpse.value;
    }

    const Patch11LatchedOrderSauceResult rebuilt =
        patch32_legacy_body::sauceWithOrderAt46Latch(calculationDay, targetDay);
    scarBump(&PersistentScarMetrics::patch32SauceRecomputed);
    {
        std::lock_guard<std::mutex> guard(sauceTombMutex);
        const auto existing = sauceTomb.find(key);
        if (existing == sauceTomb.end() || existing->second.poisoned) {
            boundedEraseFirst(sauceTomb, SAUCE_TOMB_LIMIT);
            sauceTomb[key] = BuriedSauce{
                rebuilt, 32, false, persistentSemanticFingerprint()};
        }
    }
    return rebuilt;
}

Patch11LatchedOrderSauceResult sauceWithScars(
    const Integer& calculationDay,
    const Integer& targetDay) {
    LegacySauceCounts diagnosticCounts{};
    StoneTable diagnosticStones{};
    HiddenDrops diagnosticHidden{};
    VisibleDropStore diagnosticVisible{};
    Patch11LatchedOrderSauceResult authoritative{};
    int state = 0;
    int recoveryBudget = 2;

    goto SAUCE_WITH_SCARS_DISPATCH;

SAUCE_WITH_SCARS_DISPATCH:
    if (state == 0) {
        goto SAUCE_WITH_SCARS_COUNTS;
    }
    if (state == 10) {
        goto SAUCE_WITH_SCARS_STONES;
    }
    if (state == 20) {
        goto SAUCE_WITH_SCARS_HIDDEN;
    }
    if (state == 30) {
        goto SAUCE_WITH_SCARS_VISIBLE;
    }
    if (state == 40) {
        goto SAUCE_WITH_SCARS_DROP_AND_POST_STIR_MACHINE;
    }
    if (state == 50) {
        goto SAUCE_WITH_SCARS_VALIDATE;
    }
    throw BaseValidationError("status sauceWithScars ignotus est");

SAUCE_WITH_SCARS_COUNTS:
    diagnosticCounts = sauceCountsThroughScars(calculationDay, targetDay);
    state = 10;
    goto SAUCE_WITH_SCARS_DISPATCH;

SAUCE_WITH_SCARS_STONES:
    diagnosticStones = buildStonesThroughLegacyBuilder();
    state = 20;
    goto SAUCE_WITH_SCARS_DISPATCH;

SAUCE_WITH_SCARS_HIDDEN:
    diagnosticHidden = buildHiddenWithBackwardStorage(
        calculationDay,
        targetDay,
        diagnosticStones);
    state = 30;
    goto SAUCE_WITH_SCARS_DISPATCH;

SAUCE_WITH_SCARS_VISIBLE:
    diagnosticVisible = buildVisibleDropsThroughPatchedHistory(
        diagnosticCounts,
        diagnosticStones,
        diagnosticHidden);
    if (diagnosticVisible.size() != 46) {
        if (recoveryBudget <= 0) {
            throw BaseValidationError("sauceWithScars quadraginta sex guttas requirit");
        }
        --recoveryBudget;
        diagnosticVisible.clear();
        state = 0;
        goto SAUCE_WITH_SCARS_DISPATCH;
    }
    if (accelerationsOn()) {
        const SauceKey key{calculationDay, targetDay};
        SauceAutopsyRecord autopsy{
            diagnosticCounts,
            diagnosticStones,
            diagnosticHidden,
            diagnosticVisible,
            true,
            false,
            true,
            false,
            33,
            persistentSemanticFingerprint()
        };
        {
            std::lock_guard<std::mutex> guard(sauceAutopsyVaultMutex);
            boundedEraseFirst(sauceAutopsyVault, AUTOPSY_LIMIT);
            sauceAutopsyVault[key] = std::move(autopsy);
        }
        scarBump(&PersistentScarMetrics::patch33DiagnosticBodyBuilt);
        scarBump(&PersistentScarMetrics::patch33LegacyDoubleComputationShapePreserved);
    }
    state = 40;
    goto SAUCE_WITH_SCARS_DISPATCH;

SAUCE_WITH_SCARS_DROP_AND_POST_STIR_MACHINE:
    // Haec via auctoritatem veterem per omnes 46 guttas, aliases, vaultOld,
    // latch unicum atque duodecim post-commotiones vere exsequitur.
    authoritative = sauceWithOrderAt46Latch(calculationDay, targetDay);
    state = 50;
    goto SAUCE_WITH_SCARS_DISPATCH;

SAUCE_WITH_SCARS_VALIDATE:
    if (authoritative.latchWriteCount != 1 ||
        authoritative.legacyOrderWriteCount != 58) {
        throw BaseValidationError("sauceWithScars cicatrices ordinis integras requirit");
    }
    for (const int bowlId : authoritative.orderAt46Latch) {
        if (bowlId < 1 || bowlId > 6) {
            throw BaseValidationError("sauceWithScars latch craterum invalidum habet");
        }
    }
    return authoritative;
}

namespace {

BowlState stage56LegacySavedOrderOperandScar(
    const BowlState& old,
    int stir,
    Integer& rawBowlSumOut,
    Integer& savedOrderNumberOut,
    PermutationOrder& orderOut) {
    if (stir < 1 || stir > 12) {
        throw BaseValidationError("Gradus 56 post-commotionem inter 1 et 12 requirit");
    }

    Integer rawBowlSum = 0;
    for (const Integer& bowl : old) {
        rawBowlSum += bowl;
    }
    const Integer savedOrderNumber = savePatch(rawBowlSum + 149 * stir);
    const int oneBased =
        (regularMod(savedOrderNumber - 1, Integer{720}) + 1).convert_to<int>();
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
                        + savedOrderNumber
                        + stir
                        + position * position;
        pending[static_cast<std::size_t>(id - 1)] = savePatch(
            s * s
            + 7 * old[static_cast<std::size_t>(prev - 1)]
                * old[static_cast<std::size_t>(next - 1)]);
    }

    rawBowlSumOut = rawBowlSum;
    savedOrderNumberOut = savedOrderNumber;
    orderOut = order;
    return pending;
}

} // namespace

Stage56PostStirDetourWitness stage56RawBowlSumPostStirDetour(
    const BowlState& oldBowls,
    int stirIndex) {
    Integer legacyRawBowlSum = 0;
    Integer legacySavedOrderNumber = 0;
    PermutationOrder legacyOrder{};
    const BowlState oldResult = stage56LegacySavedOrderOperandScar(
        oldBowls,
        stirIndex,
        legacyRawBowlSum,
        legacySavedOrderNumber,
        legacyOrder);

    Integer rawBowlSum = 0;
    for (const Integer& bowl : oldBowls) {
        rawBowlSum += bowl;
    }
    const Integer savedOrderNumber = savePatch(rawBowlSum + 149 * stirIndex);
    const int oneBased =
        (regularMod(savedOrderNumber - 1, Integer{720}) + 1).convert_to<int>();
    const PermutationOrder correctedOrder = oldPermutationUnrank0(oneBased - 1);

    if (legacyRawBowlSum != rawBowlSum ||
        legacySavedOrderNumber != savedOrderNumber ||
        legacyOrder != correctedOrder) {
        throw BaseValidationError(
            "Gradus 56 guard: orderNumber vel permutatio a cicatrice legacy discrepat");
    }

    BowlState corrected = oldBowls;
    for (int position = 1; position <= 6; ++position) {
        const std::size_t pos = static_cast<std::size_t>(position - 1);
        const std::size_t prevPos = static_cast<std::size_t>((position + 4) % 6);
        const std::size_t nextPos = static_cast<std::size_t>(position % 6);
        const int id = correctedOrder[pos];
        const int prev = correctedOrder[prevPos];
        const int next = correctedOrder[nextPos];
        const Integer u = oldBowls[static_cast<std::size_t>(id - 1)]
                        + 3 * oldBowls[static_cast<std::size_t>(prev - 1)]
                        + 5 * oldBowls[static_cast<std::size_t>(next - 1)]
                        + rawBowlSum
                        + stirIndex
                        + position * position;
        corrected[static_cast<std::size_t>(id - 1)] = savePatch(
            u * u
            + 7 * oldBowls[static_cast<std::size_t>(prev - 1)]
                * oldBowls[static_cast<std::size_t>(next - 1)]);
    }

    return Stage56PostStirDetourWitness{
        oldResult,
        corrected,
        rawBowlSum,
        savedOrderNumber,
        legacyOrder,
        correctedOrder,
        stirIndex,
        true
    };
}

namespace {

Stage56RawBowlSumSauceResult sauceWithStage56RawBowlSumDetourUnburied(
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
        const int oneBased =
            (regularMod(drop - 1, Integer{720}) + 1).convert_to<int>();

        try {
            (void)oldPermutationUnrank0(oneBased);
        } catch (const BaseValidationError&) {
        }
        const PermutationOrder order = oldPermutationUnrank0(oneBased - 1);

        (void)legacyPoursToFixedBowlIds(
            drop, i, bowls, stones[static_cast<std::size_t>(i)]);
        const BowlAliasPourComputation pours = poursThroughBowlAlias(
            drop, i, bowls, stones[static_cast<std::size_t>(i)], order);

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
            orderAt46Latch = order;
            ++latchWrites;
        }
    }

    if (latchWrites != 1) {
        throw BaseValidationError("Gradus 56 orderAt46Latch semel scribendus est");
    }

    Stage56RawBowlSumSauceResult out;
    for (int stir = 1; stir <= 12; ++stir) {
        const Stage56PostStirDetourWitness witness =
            stage56RawBowlSumPostStirDetour(bowls, stir);
        out.stirWitnesses[static_cast<std::size_t>(stir - 1)] = witness;
        ++out.legacyScarCallCount;
        ++out.appliedCount;
        bowls = witness.correctedResult;

        legacyOrderMemory = witness.legacyOrder;
        finalPostStirOrder = witness.correctedOrder;
        ++legacyWrites;
        finalLegacySource = "post-commotio " + std::to_string(stir);
    }

    out.semanticSauce = Patch11LatchedOrderSauceResult{
        bowls,
        orderAt46Latch,
        orderAt46Latch,
        legacyOrderMemory,
        finalPostStirOrder,
        legacyWrites,
        latchWrites,
        finalLegacySource
    };
    out.applied = out.legacyScarCallCount == 12 && out.appliedCount == 12;
    if (!out.applied) {
        throw BaseValidationError("Gradus 56 duodecim cicatrices et detours requirit");
    }
    return out;
}

bool sameStage56Sauce(const Stage56RawBowlSumSauceResult& a,
                      const Stage56RawBowlSumSauceResult& b) {
    if (!sameLatchedSauce(a.semanticSauce, b.semanticSauce) ||
        a.legacyScarCallCount != b.legacyScarCallCount ||
        a.appliedCount != b.appliedCount ||
        a.applied != b.applied) {
        return false;
    }
    for (std::size_t i = 0; i < a.stirWitnesses.size(); ++i) {
        const auto& x = a.stirWitnesses[i];
        const auto& y = b.stirWitnesses[i];
        if (x.oldResult != y.oldResult ||
            x.correctedResult != y.correctedResult ||
            x.rawBowlSum != y.rawBowlSum ||
            x.savedOrderNumber != y.savedOrderNumber ||
            x.legacyOrder != y.legacyOrder ||
            x.correctedOrder != y.correctedOrder ||
            x.stirIndex != y.stirIndex ||
            x.applied != y.applied) {
            return false;
        }
    }
    return true;
}

} // namespace

Stage56RawBowlSumSauceResult sauceWithStage56RawBowlSumDetour(
    const Integer& calculationDay,
    const Integer& targetDay) {
    if (!accelerationsOn()) {
        scarBump(&PersistentScarMetrics::patch32SauceRecomputed);
        return sauceWithStage56RawBowlSumDetourUnburied(calculationDay, targetDay);
    }

    const SauceKey key{calculationDay, targetDay};
    BuriedStage56Sauce corpse{};
    bool foundCorpse = false;
    {
        std::lock_guard<std::mutex> guard(stage56SauceTombMutex);
        const auto found = stage56SauceTomb.find(key);
        if (found != stage56SauceTomb.end()) {
            scarBump(&PersistentScarMetrics::patch32SauceCorpseFound);
            if (!found->second.poisoned &&
                fingerprintAcceptable(
                    found->second.semanticFingerprint,
                    found->second.scarGeneration,
                    32)) {
                corpse = found->second;
                foundCorpse = true;
            } else {
                found->second.poisoned = true;
                scarBump(&PersistentScarMetrics::patch32SauceGenerationMismatch);
                scarBump(&PersistentScarMetrics::staleOrPoisonedRejected);
            }
        }
    }

    if (foundCorpse) {
        scarBump(&PersistentScarMetrics::patch32SauceResurrected);
        if (fullHistoricalValidationOn()) {
            const Stage56RawBowlSumSauceResult rebuilt =
                sauceWithStage56RawBowlSumDetourUnburied(calculationDay, targetDay);
            scarBump(&PersistentScarMetrics::patch32SauceRecomputed);
            if (!sameStage56Sauce(rebuilt, corpse.value)) {
                std::lock_guard<std::mutex> guard(stage56SauceTombMutex);
                const auto found = stage56SauceTomb.find(key);
                if (found != stage56SauceTomb.end()) found->second.poisoned = true;
                scarBump(&PersistentScarMetrics::staleOrPoisonedRejected);
                return rebuilt;
            }
        }
        return corpse.value;
    }

    const Stage56RawBowlSumSauceResult rebuilt =
        sauceWithStage56RawBowlSumDetourUnburied(calculationDay, targetDay);
    scarBump(&PersistentScarMetrics::patch32SauceRecomputed);
    {
        std::lock_guard<std::mutex> guard(stage56SauceTombMutex);
        const auto existing = stage56SauceTomb.find(key);
        if (existing == stage56SauceTomb.end() || existing->second.poisoned) {
            boundedEraseFirst(stage56SauceTomb, STAGE56_SAUCE_TOMB_LIMIT);
            stage56SauceTomb[key] = BuriedStage56Sauce{
                rebuilt, 32, false, persistentSemanticFingerprint()};
        }
    }
    return rebuilt;
}

Patch11LatchedOrderSauceResult oldStructureSauce(
    const Integer& calculationDay,
    const Integer& originalTargetDay) {
    return sauceWithOrderAt46Latch(calculationDay, originalTargetDay);
}

Patch20StructureSauceResult structureSaucePatch(
    const Integer& calculationDay,
    const Integer& originalTargetDay,
    const Patch18YearRecord& year) {
    Patch20StructureSauceResult result;
    result.ghost = oldStructureSauce(calculationDay, originalTargetDay);
    result.ghostExecuted = true;
    result.mustUse = year.openGateDay + 1;
    if (originalTargetDay != result.mustUse) {
        result.semanticSauce = sauceWithOrderAt46Latch(calculationDay, result.mustUse);
        result.semanticRecomputed = true;
    } else {
        result.semanticSauce = result.ghost;
        result.semanticRecomputed = false;
    }
    return result;
}

static Integer exactCombinationForLegacyPositiveCompositions(int n, int k) {
    if (n < 0 || k < 0 || k > n) {
        return Integer{0};
    }
    int kk = std::min(k, n - k);
    Integer out = 1;
    for (int i = 1; i <= kk; ++i) {
        out *= (n - kk + i);
        out /= i;
    }
    return out;
}

LegacyPositiveCompositionFamily legacyPositiveCompositions(int gapCount,
                                                            int cutletCount) {
    if (gapCount < 1) {
        throw BaseValidationError("numerus intervallorum positivus requiritur");
    }
    if (cutletCount < 1 || cutletCount > gapCount) {
        throw BaseValidationError("numerus segmentorum inter unum et intervalla requiritur");
    }
    return LegacyPositiveCompositionFamily{
        gapCount,
        cutletCount,
        exactCombinationForLegacyPositiveCompositions(gapCount - 1, cutletCount - 1)
    };
}

std::vector<int> legacyPositiveCompositionUnrank(
    const LegacyPositiveCompositionFamily& family,
    const Integer& rank1) {
    if (family.count < 1 || rank1 < 1 || rank1 > family.count) {
        throw BaseValidationError("gradus compositionis legacy extra familiam est");
    }
    Integer rank = rank1;
    int remaining = family.gapCount;
    int slots = family.cutletCount;
    std::vector<int> out;
    out.reserve(static_cast<std::size_t>(family.cutletCount));
    while (slots > 0) {
        if (slots == 1) {
            out.push_back(remaining);
            remaining = 0;
            slots = 0;
            continue;
        }
        const int maxFirst = remaining - (slots - 1);
        bool chosen = false;
        for (int first = 1; first <= maxFirst; ++first) {
            const int rest = remaining - first;
            const Integer block = exactCombinationForLegacyPositiveCompositions(
                rest - 1,
                slots - 2);
            if (rank > block) {
                rank -= block;
                continue;
            }
            out.push_back(first);
            remaining = rest;
            --slots;
            chosen = true;
            break;
        }
        if (!chosen) {
            throw BaseValidationError("compositionis legacy apertio defecit");
        }
    }
    return out;
}

static Integer exactPositiveCompositionCount(int total, int parts) {
    if (total < 1 || parts < 1 || parts > total) {
        return Integer{0};
    }
    return exactCombinationForLegacyPositiveCompositions(total - 1, parts - 1);
}

static Integer filteredPositiveCompletionCount(
    int remaining,
    int slots,
    int cumulative,
    int internalGateOffset,
    bool internalGateRequired,
    bool hitBoundary) {
    if (slots == 0) {
        if (remaining != 0) {
            return Integer{0};
        }
        return (!internalGateRequired || hitBoundary) ? Integer{1} : Integer{0};
    }
    if (remaining < slots) {
        return Integer{0};
    }
    if (!internalGateRequired || hitBoundary) {
        return exactPositiveCompositionCount(remaining, slots);
    }
    if (cumulative >= internalGateOffset) {
        return cumulative == internalGateOffset
            ? exactPositiveCompositionCount(remaining, slots)
            : Integer{0};
    }

    const int distanceToBoundary = internalGateOffset - cumulative;
    if (distanceToBoundary < 1 || distanceToBoundary >= remaining) {
        return Integer{0};
    }
    const int tailTotal = remaining - distanceToBoundary;
    Integer total = 0;
    for (int prefixParts = 1; prefixParts < slots; ++prefixParts) {
        const int tailParts = slots - prefixParts;
        const Integer prefixWays = exactPositiveCompositionCount(
            distanceToBoundary,
            prefixParts);
        if (prefixWays == 0) {
            continue;
        }
        const Integer tailWays = exactPositiveCompositionCount(
            tailTotal,
            tailParts);
        if (tailWays == 0) {
            continue;
        }
        total += prefixWays * tailWays;
    }
    return total;
}

FilteredPositiveCompositionFamily filteredLegacyPositiveCompositions(
    int gapCount,
    int cutletCount,
    int internalGateOffset,
    bool internalGateRequired) {
    const LegacyPositiveCompositionFamily legacy = legacyPositiveCompositions(
        gapCount,
        cutletCount);
    if (internalGateRequired &&
        (internalGateOffset < 1 || internalGateOffset >= gapCount)) {
        throw BaseValidationError("offset portae internae intra intervalla requiritur");
    }
    const Integer count = internalGateRequired
        ? filteredPositiveCompletionCount(
              gapCount,
              cutletCount,
              0,
              internalGateOffset,
              true,
              false)
        : legacy.count;
    if (count < 1) {
        throw BaseValidationError("familia partitionis filtratae vacua est");
    }
    return FilteredPositiveCompositionFamily{
        gapCount,
        cutletCount,
        internalGateOffset,
        internalGateRequired,
        count
    };
}

std::vector<int> filteredLegacyPositiveCompositionUnrank(
    const FilteredPositiveCompositionFamily& family,
    const Integer& rank1) {
    if (rank1 < 1 || rank1 > family.count) {
        throw BaseValidationError("gradus compositionis filtratae extra familiam est");
    }
    if (!family.internalGateRequired) {
        const LegacyPositiveCompositionFamily legacy{
            family.gapCount,
            family.cutletCount,
            family.count
        };
        return legacyPositiveCompositionUnrank(legacy, rank1);
    }

    Integer rank = rank1;
    int remaining = family.gapCount;
    int slots = family.cutletCount;
    int cumulative = 0;
    bool hitBoundary = false;
    std::vector<int> out;
    out.reserve(static_cast<std::size_t>(family.cutletCount));

    while (slots > 0) {
        const int maxFirst = remaining - (slots - 1);
        bool chosen = false;
        for (int first = 1; first <= maxFirst; ++first) {
            const int nextCumulative = cumulative + first;
            bool nextHit = hitBoundary;
            if (!hitBoundary) {
                if (nextCumulative > family.internalGateOffset) {
                    continue;
                }
                if (nextCumulative == family.internalGateOffset) {
                    nextHit = true;
                }
            }
            const Integer block = filteredPositiveCompletionCount(
                remaining - first,
                slots - 1,
                nextCumulative,
                family.internalGateOffset,
                true,
                nextHit);
            if (block == 0) {
                continue;
            }
            if (rank > block) {
                rank -= block;
                continue;
            }
            out.push_back(first);
            remaining -= first;
            --slots;
            cumulative = nextCumulative;
            hitBoundary = nextHit;
            chosen = true;
            break;
        }
        if (!chosen) {
            throw BaseValidationError("compositionis filtratae apertio defecit");
        }
    }
    if (!hitBoundary) {
        throw BaseValidationError("compositio filtrata portam internam non attingit");
    }
    return out;
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

Integer legacyCutletNameSelectionSpaceCount(int masterCount, int itemCount) {
    if (masterCount < 1) {
        throw BaseValidationError("numerus nominum magistrorum positivus requiritur");
    }
    if (itemCount < 0 || itemCount > masterCount) {
        throw BaseValidationError("numerus nominum selectorum extra fines est");
    }
    Integer count = 1;
    for (int i = 0; i < itemCount; ++i) {
        count *= (masterCount - i);
    }
    return count;
}

std::vector<int> legacyNameRowWithRepeats(const std::vector<int>& masterList,
                                          const Integer& rank1,
                                          int itemCount) {
    if (masterList.empty()) {
        throw BaseValidationError("lista nominum magistrorum vacua esse non potest");
    }
    if (rank1 < 1) {
        throw BaseValidationError("gradus legacy nominum debet esse saltem unus");
    }
    if (itemCount < 0) {
        throw BaseValidationError("numerus nominum negativus esse non potest");
    }
    const Integer n = Integer{masterList.size()};
    Integer q = rank1 - 1;
    std::vector<int> row;
    row.reserve(static_cast<std::size_t>(itemCount));
    for (int p = 1; p <= itemCount; ++p) {
        const Integer digit = regularMod(q, n);
        const std::size_t index = digit.convert_to<std::size_t>();
        row.push_back(masterList.at(index));
        q /= n;
    }
    return row;
}

bool legacyNameRowContainsRepeat(const std::vector<int>& row) {
    for (std::size_t i = 0; i < row.size(); ++i) {
        for (std::size_t j = i + 1; j < row.size(); ++j) {
            if (row[i] == row[j]) {
                return true;
            }
        }
    }
    return false;
}

std::vector<int> partialPermutationNameRowUnrank(const std::vector<int>& masterList,
                                                  const Integer& rank1,
                                                  int itemCount) {
    if (masterList.empty()) {
        throw BaseValidationError("lista nominum magistrorum vacua esse non potest");
    }
    if (itemCount < 0 || itemCount > static_cast<int>(masterList.size())) {
        throw BaseValidationError("numerus nominum partialis permutationis extra fines est");
    }
    for (std::size_t i = 0; i < masterList.size(); ++i) {
        for (std::size_t j = i + 1; j < masterList.size(); ++j) {
            if (masterList[i] == masterList[j]) {
                throw BaseValidationError("lista nominum magistrorum canonicalIndex duplicatum continet");
            }
        }
    }
    const Integer total = legacyCutletNameSelectionSpaceCount(
        static_cast<int>(masterList.size()),
        itemCount);
    if (rank1 < 1 || rank1 > total) {
        throw BaseValidationError("gradus partialis permutationis nominum extra fines est");
    }

    std::vector<int> remaining = masterList;
    std::vector<int> out;
    out.reserve(static_cast<std::size_t>(itemCount));
    Integer r = rank1;
    for (int position = 0; position < itemCount; ++position) {
        const int suffixLength = itemCount - position - 1;
        Integer block = 1;
        for (int j = 0; j < suffixLength; ++j) {
            block *= static_cast<int>(remaining.size()) - 1 - j;
        }
        bool chosen = false;
        for (std::size_t candidateIndex = 0; candidateIndex < remaining.size(); ++candidateIndex) {
            if (r > block) {
                r -= block;
                continue;
            }
            out.push_back(remaining[candidateIndex]);
            remaining.erase(remaining.begin() + static_cast<std::ptrdiff_t>(candidateIndex));
            chosen = true;
            break;
        }
        if (!chosen) {
            throw BaseValidationError("partial-permutation unrank nomen eligere non potuit");
        }
    }
    return out;
}

Integer legacyMonthLengthConcreteFamilyCountProof(int yearLength,
                                                  int monthCount) {
    if (yearLength < 1) {
        throw BaseValidationError("longitudo anni positiva requiritur");
    }
    if (monthCount < 1) {
        throw BaseValidationError("numerus mensium positivus requiritur");
    }
    if (yearLength < monthCount * LEGACY_MONTH_LENGTH_MIN ||
        yearLength > monthCount * LEGACY_MONTH_LENGTH_MAX) {
        return Integer{0};
    }

    const int shiftedTotal = yearLength - monthCount * LEGACY_MONTH_LENGTH_MIN;
    const int shiftedUpper = LEGACY_MONTH_LENGTH_MAX - LEGACY_MONTH_LENGTH_MIN;
    Integer total = 0;
    const int maxViolations = shiftedTotal / (shiftedUpper + 1);
    for (int j = 0; j <= maxViolations && j <= monthCount; ++j) {
        const int remaining = shiftedTotal - j * (shiftedUpper + 1);
        const Integer chooseSlots = exactCombinationForLegacyPositiveCompositions(
            monthCount,
            j);
        const Integer chooseRemainder = exactCombinationForLegacyPositiveCompositions(
            remaining + monthCount - 1,
            monthCount - 1);
        const Integer term = chooseSlots * chooseRemainder;
        if ((j % 2) == 0) {
            total += term;
        } else {
            total -= term;
        }
    }
    return total;
}

static void legacyMaterializeAllMonthLengthWaysRec(
    int remaining,
    int slots,
    std::vector<int>& prefix,
    LegacyMonthLengthWays& out) {
    if (slots == 0) {
        if (remaining == 0) {
            out.push_back(prefix);
        }
        return;
    }
    if (remaining < slots * LEGACY_MONTH_LENGTH_MIN ||
        remaining > slots * LEGACY_MONTH_LENGTH_MAX) {
        return;
    }
    for (int length = LEGACY_MONTH_LENGTH_MIN;
         length <= LEGACY_MONTH_LENGTH_MAX;
         ++length) {
        const int nextRemaining = remaining - length;
        if (nextRemaining < (slots - 1) * LEGACY_MONTH_LENGTH_MIN ||
            nextRemaining > (slots - 1) * LEGACY_MONTH_LENGTH_MAX) {
            continue;
        }
        prefix.push_back(length);
        legacyMaterializeAllMonthLengthWaysRec(
            nextRemaining,
            slots - 1,
            prefix,
            out);
        prefix.pop_back();
    }
}

LegacyMonthLengthWays legacyMaterializeAllMonthLengthWays(int yearLength,
                                                          int monthCount) {
    if (yearLength < 1 || monthCount < 1) {
        throw BaseValidationError("fines materializationis mensium invalidi sunt");
    }
    LegacyMonthLengthWays out;
    std::vector<int> prefix;
    prefix.reserve(static_cast<std::size_t>(monthCount));
    legacyMaterializeAllMonthLengthWaysRec(yearLength, monthCount, prefix, out);
    return out;
}

int wrapMonth(int j, int monthCount) {
    if (monthCount < 1) {
        throw BaseValidationError("numerus mensium ad circulationem positivus requiritur");
    }
    int reduced = (j - 1) % monthCount;
    if (reduced < 0) {
        reduced += monthCount;
    }
    return reduced + 1;
}

std::vector<int> legacyChooseEachDaySeparately(
    const std::vector<int>& lengths,
    const LegacyAnswerRing& answerStream) {
    if (lengths.empty()) {
        throw BaseValidationError("textura legacy saltem unum mensem requirit");
    }
    if (answerStream.directionStep != -1 && answerStream.directionStep != 1) {
        throw BaseValidationError("annulus responsorum texturae legacy gradum invalidum habet");
    }

    int totalLength = 0;
    for (const int length : lengths) {
        if (length < 1) {
            throw BaseValidationError("longitudo mensis texturae legacy positiva requiritur");
        }
        if (totalLength > std::numeric_limits<int>::max() - length) {
            throw BaseValidationError("summa longitudinum texturae legacy nimis magna est");
        }
        totalLength += length;
    }

    const int monthCount = static_cast<int>(lengths.size());
    std::vector<int> remaining = lengths;
    std::vector<int> ghost;
    ghost.reserve(static_cast<std::size_t>(totalLength));
    for (int dayPosition = 1; dayPosition <= totalLength; ++dayPosition) {
        const Integer answer = ringAnswer(answerStream, Integer{dayPosition - 1});
        int j = regularMod(answer - 1, Integer{monthCount}).convert_to<int>() + 1;
        int rotations = 0;
        while (remaining[static_cast<std::size_t>(j - 1)] == 0) {
            j = wrapMonth(j + 1, monthCount);
            ++rotations;
            if (rotations > monthCount) {
                throw BaseValidationError("textura legacy mensem cum capacitate residua invenire non potuit");
            }
        }
        ghost.push_back(j);
        --remaining[static_cast<std::size_t>(j - 1)];
    }
    return ghost;
}

int oldContiguousMonthDayGuess(const std::vector<int>& weaving,
                               std::size_t targetPosition1) {
    if (weaving.empty()) {
        throw BaseValidationError("oldContiguousMonthDayGuess texturam vacuam recusat");
    }
    if (targetPosition1 < 1 || targetPosition1 > weaving.size()) {
        throw BaseValidationError("oldContiguousMonthDayGuess positionem target extra fines recusat");
    }
    const int targetMonthId = weaving[targetPosition1 - 1];
    const auto found = std::find(weaving.begin(), weaving.end(), targetMonthId);
    if (found == weaving.end()) {
        throw BaseValidationError("oldContiguousMonthDayGuess mensem target invenire non potuit");
    }
    const std::size_t firstPosition1 =
        static_cast<std::size_t>(std::distance(weaving.begin(), found)) + 1;
    return static_cast<int>(targetPosition1 - firstPosition1 + 1);
}

int countMonthOccurrencesThroughTarget(const std::vector<int>& weaving,
                                       std::size_t targetPosition1) {
    if (weaving.empty()) {
        throw BaseValidationError("countMonthOccurrencesThroughTarget texturam vacuam recusat");
    }
    if (targetPosition1 < 1 || targetPosition1 > weaving.size()) {
        throw BaseValidationError("countMonthOccurrencesThroughTarget positionem target extra fines recusat");
    }
    const int targetMonthId = weaving[targetPosition1 - 1];
    int count = 0;
    for (std::size_t i = 0; i < targetPosition1; ++i) {
        if (weaving[i] == targetMonthId) {
            ++count;
        }
    }
    return count;
}

namespace {

struct LegalMonthWeavingStateInternal {
    std::vector<int> remaining{};
    int openedUpTo = 0;
    int closedUpTo = 0;

    bool operator<(const LegalMonthWeavingStateInternal& other) const {
        if (openedUpTo != other.openedUpTo) {
            return openedUpTo < other.openedUpTo;
        }
        if (closedUpTo != other.closedUpTo) {
            return closedUpTo < other.closedUpTo;
        }
        return remaining < other.remaining;
    }
};

class LegalMonthWeavingCounterInternal {
public:
    explicit LegalMonthWeavingCounterInternal(const std::vector<int>& lengths)
        : lengths_(lengths) {
        if (lengths_.empty()) {
            throw BaseValidationError("DP texturae mensium saltem unum mensem requirit");
        }
        for (const int length : lengths_) {
            if (length < 1) {
                throw BaseValidationError("DP texturae mensium longitudines positivas requirit");
            }
        }
    }

    Integer countAll() {
        return countState(LegalMonthWeavingStateInternal{lengths_, 0, 0});
    }

    std::vector<int> unrank1(const Integer& rank1) {
        LegalMonthWeavingStateInternal state{lengths_, 0, 0};
        const Integer total = countState(state);
        if (rank1 < 1 || rank1 > total) {
            throw BaseValidationError("rank texturae mensium extra familiam legalem est");
        }

        Integer rank = rank1;
        const int totalLength = std::accumulate(lengths_.begin(), lengths_.end(), 0);
        std::vector<int> out;
        out.reserve(static_cast<std::size_t>(totalLength));
        while (static_cast<int>(out.size()) < totalLength) {
            bool chosen = false;
            for (int monthId = 1;
                 monthId <= static_cast<int>(lengths_.size());
                 ++monthId) {
                if (!legalMove(state, monthId)) {
                    continue;
                }
                const LegalMonthWeavingStateInternal next = applyMove(state, monthId);
                const Integer block = countState(next);
                if (rank > block) {
                    rank -= block;
                    continue;
                }
                out.push_back(monthId);
                state = next;
                chosen = true;
                break;
            }
            if (!chosen) {
                throw BaseValidationError("DP texturae mensium rank aperire non potuit");
            }
        }
        return out;
    }

private:
    std::vector<int> lengths_{};
    std::map<LegalMonthWeavingStateInternal, Integer> memo_{};

    bool legalMove(const LegalMonthWeavingStateInternal& state,
                   int monthId) const {
        const std::size_t index = static_cast<std::size_t>(monthId - 1);
        if (state.remaining[index] == 0) {
            return false;
        }
        const bool alreadyOpened = state.remaining[index] < lengths_[index];
        if (!alreadyOpened && monthId != state.openedUpTo + 1) {
            return false;
        }
        const bool willClose = state.remaining[index] == 1;
        if (willClose && monthId != state.closedUpTo + 1) {
            return false;
        }
        return true;
    }

    LegalMonthWeavingStateInternal applyMove(
        const LegalMonthWeavingStateInternal& state,
        int monthId) const {
        LegalMonthWeavingStateInternal next = state;
        const std::size_t index = static_cast<std::size_t>(monthId - 1);
        if (next.remaining[index] == lengths_[index]) {
            next.openedUpTo = monthId;
        }
        --next.remaining[index];
        if (next.remaining[index] == 0) {
            next.closedUpTo = monthId;
        }
        return next;
    }

    Integer countState(const LegalMonthWeavingStateInternal& state) {
        bool empty = true;
        for (const int remaining : state.remaining) {
            if (remaining != 0) {
                empty = false;
                break;
            }
        }
        if (empty) {
            return Integer{1};
        }

        const auto hit = memo_.find(state);
        if (hit != memo_.end()) {
            return hit->second;
        }

        Integer total = 0;
        for (int monthId = 1;
             monthId <= static_cast<int>(lengths_.size());
             ++monthId) {
            if (legalMove(state, monthId)) {
                total += countState(applyMove(state, monthId));
            }
        }
        memo_.emplace(state, total);
        return total;
    }
};

class FastLegalMonthWeavingCounterInternal {
public:
    explicit FastLegalMonthWeavingCounterInternal(const std::vector<int>& lengths)
        : lengths_(lengths), monthCount_(static_cast<int>(lengths.size())) {
        if (lengths_.empty()) {
            throw BaseValidationError("DP celer texturae mensium saltem unum mensem requirit");
        }
        for (const int length : lengths_) {
            if (length < 1) {
                throw BaseValidationError("DP celer texturae mensium longitudines positivas requirit");
            }
        }

        LegalWeavingSkeletonBones inherited{};
        bool inheritedSkeleton = false;
        if (accelerationsOn() && !fullHistoricalValidationOn()) {
            std::lock_guard<std::mutex> guard(legalWeavingSkeletonVaultMutex);
            const auto found = legalWeavingSkeletonVault.find(lengths_);
            if (found != legalWeavingSkeletonVault.end()) {
                if (!found->second.poisoned &&
                    fingerprintAcceptable(
                        found->second.semanticFingerprint,
                        found->second.scarGeneration,
                        38)) {
                    inherited = found->second;
                    inheritedSkeleton = true;
                } else if (!found->second.poisoned) {
                    found->second.poisoned = true;
                    scarBump(&PersistentScarMetrics::staleOrPoisonedRejected);
                }
            }
        }

        if (inheritedSkeleton) {
            maxActive_ = inherited.maxActive;
            suffixPerFixedActive_ = inherited.suffixPerFixedActive;
            scarBump(&PersistentScarMetrics::patch38SharedSkeletonUsed);
            return;
        }

        if (accelerationsOn()) {
            scarBump(&PersistentScarMetrics::patch38SkeletonMiss);
        }
        maxActive_.assign(static_cast<std::size_t>(monthCount_ + 1), 0);
        for (int a = 1; a <= monthCount_; ++a) {
            const int length = lengths_.at(static_cast<std::size_t>(a - 1));
            maxActive_[static_cast<std::size_t>(a)] =
                maxActive_[static_cast<std::size_t>(a - 1)] + length - 1;
        }
        suffixPerFixedActive_.resize(static_cast<std::size_t>(monthCount_ + 1));
        suffixPerFixedActive_[static_cast<std::size_t>(monthCount_)].assign(
            static_cast<std::size_t>(maxActive_.back() + 1),
            Integer{1});
        for (int a = monthCount_ - 1; a >= 0; --a) {
            const int n = lengths_.at(static_cast<std::size_t>(a));
            const int maxS = maxActive_.at(static_cast<std::size_t>(a));
            auto& row = suffixPerFixedActive_.at(static_cast<std::size_t>(a));
            row.resize(static_cast<std::size_t>(maxS + 1));
            Integer insertionWays = 1;
            for (int s = 0; s <= maxS; ++s) {
                if (s > 0) {
                    insertionWays *= (s + n - 2);
                    insertionWays /= s;
                }
                const Integer openNow = insertionWays *
                    suffixPerFixedActive_.at(static_cast<std::size_t>(a + 1)).at(
                        static_cast<std::size_t>(s + n - 1));
                row[static_cast<std::size_t>(s)] = openNow;
                if (s > 0) {
                    row[static_cast<std::size_t>(s)] += row[static_cast<std::size_t>(s - 1)];
                }
            }
        }

        if (accelerationsOn()) {
            LegalWeavingSkeletonBones born{
                maxActive_,
                suffixPerFixedActive_,
                false,
                38,
                persistentSemanticFingerprint()
            };
            std::lock_guard<std::mutex> guard(legalWeavingSkeletonVaultMutex);
            const auto existing = legalWeavingSkeletonVault.find(lengths_);
            if (existing == legalWeavingSkeletonVault.end() || existing->second.poisoned) {
                boundedEraseFirst(
                    legalWeavingSkeletonVault,
                    LEGAL_WEAVING_SKELETON_LIMIT);
                legalWeavingSkeletonVault[lengths_] = std::move(born);
            }
        }
    }

    Integer countAll() {
        LegalMonthWeavingStateInternal initial{lengths_, 0, 0};
        return countState(initial);
    }

    std::vector<int> unrank1(const Integer& rank1) {
        LegalMonthWeavingStateInternal state{lengths_, 0, 0};
        const Integer total = countState(state);
        if (rank1 < 1 || rank1 > total) {
            throw BaseValidationError("rank texturae mensium celeris extra familiam est");
        }
        Integer rank = rank1;
        const int totalLength = std::accumulate(lengths_.begin(), lengths_.end(), 0);
        std::vector<int> out;
        out.reserve(static_cast<std::size_t>(totalLength));
        while (static_cast<int>(out.size()) < totalLength) {
            bool chosen = false;
            for (int monthId = 1; monthId <= monthCount_; ++monthId) {
                if (!legalMove(state, monthId)) {
                    continue;
                }
                const LegalMonthWeavingStateInternal next = applyMove(state, monthId);
                const Integer block = countState(next);
                if (rank > block) {
                    rank -= block;
                    continue;
                }
                out.push_back(monthId);
                state = next;
                chosen = true;
                break;
            }
            if (!chosen) {
                throw BaseValidationError("DP celer texturae mensium rank aperire non potuit");
            }
        }
        return out;
    }

private:
    std::vector<int> lengths_{};
    int monthCount_ = 0;
    std::vector<int> maxActive_{};
    std::vector<std::vector<Integer>> suffixPerFixedActive_{};
    std::map<std::pair<int, int>, Integer> binomialMemo_{};

    Integer binomial(int n, int k) {
        if (k < 0 || k > n) {
            return Integer{0};
        }
        k = std::min(k, n - k);
        const std::pair<int, int> key{n, k};
        const auto hit = binomialMemo_.find(key);
        if (hit != binomialMemo_.end()) {
            return hit->second;
        }
        Integer out = 1;
        for (int i = 1; i <= k; ++i) {
            out *= (n - k + i);
            out /= i;
        }
        binomialMemo_.emplace(key, out);
        return out;
    }

    bool legalMove(const LegalMonthWeavingStateInternal& state,
                   int monthId) const {
        const std::size_t index = static_cast<std::size_t>(monthId - 1);
        if (state.remaining[index] == 0) {
            return false;
        }
        const bool alreadyOpened = state.remaining[index] < lengths_[index];
        if (!alreadyOpened && monthId != state.openedUpTo + 1) {
            return false;
        }
        const bool willClose = state.remaining[index] == 1;
        return !willClose || monthId == state.closedUpTo + 1;
    }

    LegalMonthWeavingStateInternal applyMove(
        const LegalMonthWeavingStateInternal& state,
        int monthId) const {
        LegalMonthWeavingStateInternal next = state;
        const std::size_t index = static_cast<std::size_t>(monthId - 1);
        if (next.remaining[index] == lengths_[index]) {
            next.openedUpTo = monthId;
        }
        --next.remaining[index];
        if (next.remaining[index] == 0) {
            next.closedUpTo = monthId;
        }
        return next;
    }

    Integer countState(const LegalMonthWeavingStateInternal& state) {
        if (state.openedUpTo == monthCount_ && state.closedUpTo == monthCount_) {
            return Integer{1};
        }
        int activeLength = 0;
        int prefixLength = 0;
        Integer activeExtensions = 1;
        for (int monthId = state.closedUpTo + 1;
             monthId <= state.openedUpTo;
             ++monthId) {
            const int remaining = state.remaining.at(
                static_cast<std::size_t>(monthId - 1));
            if (remaining <= 0) {
                throw BaseValidationError("DP celer statum activum corruptum invenit");
            }
            activeExtensions *= binomial(
                prefixLength + remaining - 1,
                remaining - 1);
            prefixLength += remaining;
            activeLength += remaining;
        }
        const int a = state.openedUpTo;
        if (activeLength < 0 ||
            activeLength > maxActive_.at(static_cast<std::size_t>(a))) {
            throw BaseValidationError("DP celer longitudinem activam extra fines invenit");
        }
        return activeExtensions *
            suffixPerFixedActive_.at(static_cast<std::size_t>(a)).at(
                static_cast<std::size_t>(activeLength));
    }
};

bool legalMonthWeavingRowInternal(const std::vector<int>& lengths,
                                  const std::vector<int>& row) {
    const int totalLength = std::accumulate(lengths.begin(), lengths.end(), 0);
    if (row.size() != static_cast<std::size_t>(totalLength)) {
        return false;
    }
    LegalMonthWeavingStateInternal state{lengths, 0, 0};
    for (const int monthId : row) {
        if (monthId < 1 || monthId > static_cast<int>(lengths.size())) {
            return false;
        }
        const std::size_t index = static_cast<std::size_t>(monthId - 1);
        if (state.remaining[index] == 0) {
            return false;
        }
        const bool alreadyOpened = state.remaining[index] < lengths[index];
        if (!alreadyOpened && monthId != state.openedUpTo + 1) {
            return false;
        }
        const bool willClose = state.remaining[index] == 1;
        if (willClose && monthId != state.closedUpTo + 1) {
            return false;
        }
        if (state.remaining[index] == lengths[index]) {
            state.openedUpTo = monthId;
        }
        --state.remaining[index];
        if (state.remaining[index] == 0) {
            state.closedUpTo = monthId;
        }
    }
    return state.openedUpTo == static_cast<int>(lengths.size()) &&
           state.closedUpTo == static_cast<int>(lengths.size());
}

} // spatium nominum

Integer exactLegalMonthWeavingCount(const std::vector<int>& lengths) {
    scarBump(&PersistentScarMetrics::patch38CountBackendBorn);
    const int totalLength = std::accumulate(lengths.begin(), lengths.end(), 0);
    if (totalLength <= 40) {
        LegalMonthWeavingCounterInternal family(lengths);
        return family.countAll();
    }
    FastLegalMonthWeavingCounterInternal family(lengths);
    return family.countAll();
}

std::vector<int> DPUnrankLegalWeaving(const std::vector<int>& lengths,
                                      const Integer& rank1) {
    scarBump(&PersistentScarMetrics::patch38UnrankBackendBorn);
    const int totalLength = std::accumulate(lengths.begin(), lengths.end(), 0);
    if (totalLength <= 40) {
        LegalMonthWeavingCounterInternal family(lengths);
        return family.unrank1(rank1);
    }
    FastLegalMonthWeavingCounterInternal family(lengths);
    return family.unrank1(rank1);
}

Integer compatibleMonthWeavingRank(const LegacyAnswerRing& stream,
                                   const Integer& familySize) {
    if (familySize < 1) {
        throw BaseValidationError("familia texturae mensium vacua est");
    }
    const LegacyBiasedSelectionAdapter selectionAdapter;
    const Patch13RejectionWrapper rejectionWrapper;
    if (familySize <= M_OLD) {
        return rejectionWrapper.repair(stream, familySize, selectionAdapter).outputRank;
    }
    const Patch14WideDetourWrapper wideWrapper;
    return wideWrapper.repair(stream, familySize, selectionAdapter).outputRank;
}

VirtualLegacyList::VirtualLegacyList(int yearLength, int monthCount)
    : yearLength_(yearLength), monthCount_(monthCount) {
    if (yearLength_ < 1) {
        throw BaseValidationError("VirtualLegacyList longitudinem anni positivam requirit");
    }
    if (monthCount_ < 1) {
        throw BaseValidationError("VirtualLegacyList numerum mensium positivum requirit");
    }
}

Integer VirtualLegacyList::countSuffix(int remaining, int slots) const {
    if (slots == 0) {
        return remaining == 0 ? Integer{1} : Integer{0};
    }
    if (remaining < slots * LEGACY_MONTH_LENGTH_MIN ||
        remaining > slots * LEGACY_MONTH_LENGTH_MAX) {
        return Integer{0};
    }
    const std::pair<int, int> key{remaining, slots};
    const auto found = memo_.find(key);
    if (found != memo_.end()) {
        return found->second;
    }

    const VirtualMemoBoneKey boneKey{
        yearLength_, monthCount_, remaining, slots};
    if (accelerationsOn() && !fullHistoricalValidationOn()) {
        std::lock_guard<std::mutex> guard(virtualMemoGraveyardMutex);
        const auto bone = virtualMemoGraveyard.find(boneKey);
        if (bone != virtualMemoGraveyard.end()) {
            if (!bone->second.poisoned &&
                fingerprintAcceptable(
                    bone->second.semanticFingerprint,
                    bone->second.scarGeneration,
                    37)) {
                memo_[key] = bone->second.count;
                scarBump(&PersistentScarMetrics::patch37VirtualMemoBoneHit);
                return bone->second.count;
            }
            if (!bone->second.poisoned) {
                bone->second.poisoned = true;
                scarBump(&PersistentScarMetrics::staleOrPoisonedRejected);
            }
        }
    }
    if (accelerationsOn()) {
        scarBump(&PersistentScarMetrics::patch37VirtualMemoBoneMiss);
    }

    Integer total = 0;
    for (int length = LEGACY_MONTH_LENGTH_MIN;
         length <= LEGACY_MONTH_LENGTH_MAX;
         ++length) {
        total += countSuffix(remaining - length, slots - 1);
    }
    memo_[key] = total;
    if (accelerationsOn()) {
        std::lock_guard<std::mutex> guard(virtualMemoGraveyardMutex);
        const auto existing = virtualMemoGraveyard.find(boneKey);
        if (existing == virtualMemoGraveyard.end() || existing->second.poisoned) {
            boundedEraseFirst(virtualMemoGraveyard, VIRTUAL_MEMO_GRAVEYARD_LIMIT);
            virtualMemoGraveyard[boneKey] = VirtualMemoBone{
                total, false, 37, persistentSemanticFingerprint()};
        }
    }
    return total;
}

Integer VirtualLegacyList::count() const {
    return countSuffix(yearLength_, monthCount_);
}

std::vector<int> VirtualLegacyList::itemAt1(const Integer& rank1) const {
    const Integer familyCount = count();
    if (rank1 < 1 || rank1 > familyCount) {
        throw BaseValidationError("VirtualLegacyList itemAt1 gradum extra fines accepit");
    }

    Integer remainingRank = rank1;
    int remainingTotal = yearLength_;
    std::vector<int> out;
    out.reserve(static_cast<std::size_t>(monthCount_));

    for (int position = 0; position < monthCount_; ++position) {
        bool chosen = false;
        const int slotsAfter = monthCount_ - position - 1;
        for (int length = LEGACY_MONTH_LENGTH_MIN;
             length <= LEGACY_MONTH_LENGTH_MAX;
             ++length) {
            const Integer blockCount = countSuffix(
                remainingTotal - length,
                slotsAfter);
            if (remainingRank > blockCount) {
                remainingRank -= blockCount;
                continue;
            }
            out.push_back(length);
            remainingTotal -= length;
            chosen = true;
            break;
        }
        if (!chosen) {
            throw BaseValidationError("VirtualLegacyList itemAt1 membrum lexicographicum invenire non potuit");
        }
    }
    if (remainingTotal != 0) {
        throw BaseValidationError("VirtualLegacyList itemAt1 summam finalem non servavit");
    }
    return out;
}

int VirtualLegacyList::yearLength() const {
    return yearLength_;
}

int VirtualLegacyList::monthCount() const {
    return monthCount_;
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

void BaseValidationManager::requirePatch15GateQuestionReady(const BaseMonsterContext& ctx) const {
    requireDiscovery15GateQuestionReady(ctx);
    if (!ctx.patch15Applied) {
        throw BaseValidationError("emendatio quinta decima nondum applicata est");
    }
    if (ctx.patch15LegacyOutputBeforePatch != ctx.legacyGateQuestionOutput) {
        throw BaseValidationError("output legacy ante PATCH 15 non servatus est");
    }
    Integer expectatus = ctx.patch15LegacyOutputBeforePatch;
    if (ctx.legacyGateQuestionSignedStep < 0) {
        expectatus = FOUNDATION_DAY_OLD - ctx.legacyGateQuestionMagnitude;
    }
    if (ctx.patch15GateQuestionOutput != expectatus) {
        throw BaseValidationError("quaestio portae PATCH 15 latus signatum non servat");
    }
}

void BaseValidationManager::requireDiscovery16LegacyYearCandidatesReady(
    const BaseMonsterContext& ctx) const {
    if (!ctx.legacyYearCandidateReady) {
        throw BaseValidationError("familia candidatorum annorum legacy nondum parata est");
    }
    if (LEGACY_YEAR_MAX != 5781) {
        throw BaseValidationError("LEGACY_YEAR_MAX cicatricem 5781 non servat");
    }
    const LegacyYearCandidateList expectataPre = legacyYearCandidatesBeforeSort(
        ctx.legacyYearGates,
        ctx.legacyYearCandidatePairs);
    if (expectataPre.size() != ctx.legacyYearCandidatesPreSort.size()) {
        throw BaseValidationError("familia candidatorum ante sortem legacy discrepat");
    }
    for (std::size_t i = 0; i < expectataPre.size(); ++i) {
        const auto& a = expectataPre[i];
        const auto& b = ctx.legacyYearCandidatesPreSort[i];
        if (a.openIndex != b.openIndex || a.closeIndex != b.closeIndex || a.length != b.length) {
            throw BaseValidationError("candidatus legacy ante sortem mutatus est");
        }
    }
    const LegacyYearCandidateList expectataSort = legacyStableLengthOnlyYearCandidates(expectataPre);
    if (expectataSort.size() != ctx.legacyYearCandidatesSorted.size()) {
        throw BaseValidationError("familia candidatorum post sortem legacy discrepat");
    }
    for (std::size_t i = 0; i < expectataSort.size(); ++i) {
        const auto& a = expectataSort[i];
        const auto& b = ctx.legacyYearCandidatesSorted[i];
        if (a.openIndex != b.openIndex || a.closeIndex != b.closeIndex || a.length != b.length) {
            throw BaseValidationError("stable sort per longitudinem solam non servata est");
        }
    }
    if (!ctx.legacyYearSelectionCalled) {
        throw BaseValidationError("familia legacy ad selectionem non pervenit");
    }
    if (ctx.legacyYearSelectionFamilySize != Integer{ctx.legacyYearCandidatesSorted.size()}) {
        throw BaseValidationError("magnitudo familiae selectionis legacy falsa est");
    }
    if (ctx.legacyYearCandidatesSorted.empty()) {
        throw BaseValidationError("familia selectionis legacy vacua est");
    }
    if (ctx.legacyYearSelectedOrdinal < 1 ||
        ctx.legacyYearSelectedOrdinal > ctx.legacyYearSelectionFamilySize) {
        throw BaseValidationError("ordinalis selectionis legacy extra fines est");
    }
    const std::size_t index = (ctx.legacyYearSelectedOrdinal - 1).convert_to<std::size_t>();
    const auto& expectatus = ctx.legacyYearCandidatesSorted[index];
    if (ctx.legacyYearSelectedCandidate.openIndex != expectatus.openIndex ||
        ctx.legacyYearSelectedCandidate.closeIndex != expectatus.closeIndex ||
        ctx.legacyYearSelectedCandidate.length != expectatus.length) {
        throw BaseValidationError("candidatus electus non ex familia sortata venit");
    }
}

void BaseValidationManager::requirePatch16YearCandidateCeilingReady(
    const BaseMonsterContext& ctx) const {
    if (!ctx.patch16Applied) {
        throw BaseValidationError("emendatio sexta decima nondum applicata est");
    }
    if (LEGACY_YEAR_MAX != 5781) {
        throw BaseValidationError("LEGACY_YEAR_MAX cicatricem 5781 non servat");
    }
    if (REAL_YEAR_MAX_PATCH != 5778) {
        throw BaseValidationError("REAL_YEAR_MAX_PATCH non est 5778");
    }

    LegacyYearCandidateList expectataLegacy;
    LegacyYearCandidateList expectataRejecta;
    LegacyYearCandidateList expectataPre;
    for (const LegacyYearCandidatePair& pair : ctx.legacyYearCandidatePairs) {
        if (!legacyYearCandidateAllowed(ctx.legacyYearGates, pair.openIndex, pair.closeIndex)) {
            continue;
        }
        const LegacyYearCandidate candidate{
            pair.openIndex,
            pair.closeIndex,
            ctx.legacyYearGates[pair.closeIndex] - ctx.legacyYearGates[pair.openIndex]
        };
        expectataLegacy.push_back(candidate);
        if (candidate.length > REAL_YEAR_MAX_PATCH) {
            expectataRejecta.push_back(candidate);
        } else {
            expectataPre.push_back(candidate);
        }
    }
    const LegacyYearCandidateList expectataSort = legacyStableLengthOnlyYearCandidates(expectataPre);

    const auto requireList = [](const LegacyYearCandidateList& a,
                                const LegacyYearCandidateList& b,
                                const char* nuntius) {
        if (a.size() != b.size()) {
            throw BaseValidationError(nuntius);
        }
        for (std::size_t i = 0; i < a.size(); ++i) {
            if (a[i].openIndex != b[i].openIndex ||
                a[i].closeIndex != b[i].closeIndex ||
                a[i].length != b[i].length) {
                throw BaseValidationError(nuntius);
            }
        }
    };

    requireList(expectataLegacy, ctx.patch16LegacyYearCandidatesPreSort,
                "familia legacy ante PATCH 16 non servata est");
    requireList(expectataRejecta, ctx.patch16RejectedBeforeSort,
                "candidati supra 5778 ante sortem non recte rejecti sunt");
    requireList(expectataPre, ctx.patch16YearCandidatesPreSort,
                "familia PATCH 16 ante sortem discrepat");
    requireList(expectataSort, ctx.patch16YearCandidatesSorted,
                "stable sort PATCH 16 per longitudinem solam discrepat");

    for (const LegacyYearCandidate& candidate : ctx.patch16YearCandidatesPreSort) {
        if (candidate.length > REAL_YEAR_MAX_PATCH) {
            throw BaseValidationError("candidatus supra 5778 ad familiam semanticam pervenit");
        }
    }
    for (const LegacyYearCandidate& candidate : ctx.patch16YearCandidatesSorted) {
        if (candidate.length > REAL_YEAR_MAX_PATCH) {
            throw BaseValidationError("candidatus supra 5778 ad sortem semanticam pervenit");
        }
    }
    if (!ctx.patch16YearSelectionCalled) {
        throw BaseValidationError("selectio PATCH 16 non vocata est");
    }
    if (ctx.patch16YearSelectionFamilySize != Integer{ctx.patch16YearCandidatesSorted.size()}) {
        throw BaseValidationError("magnitudo familiae selectionis PATCH 16 falsa est");
    }
    if (ctx.patch16YearCandidatesSorted.empty()) {
        throw BaseValidationError("familia selectionis PATCH 16 vacua est");
    }
    if (ctx.patch16YearSelectedOrdinal < 1 ||
        ctx.patch16YearSelectedOrdinal > ctx.patch16YearSelectionFamilySize) {
        throw BaseValidationError("ordinalis selectionis PATCH 16 extra fines est");
    }
    const std::size_t index = (ctx.patch16YearSelectedOrdinal - 1).convert_to<std::size_t>();
    const LegacyYearCandidate& expectatus = ctx.patch16YearCandidatesSorted[index];
    if (ctx.patch16YearSelectedCandidate.openIndex != expectatus.openIndex ||
        ctx.patch16YearSelectedCandidate.closeIndex != expectatus.closeIndex ||
        ctx.patch16YearSelectedCandidate.length != expectatus.length) {
        throw BaseValidationError("candidatus electus PATCH 16 non ex familia filtrata venit");
    }
}

void BaseValidationManager::requireDiscovery17Year5000TieReady(
    const BaseMonsterContext& ctx) const {
    if (!ctx.discovery17Year5000Ready) {
        throw BaseValidationError("DISCOVERY 17 nondum paratus est");
    }
    const LegacyYear5000TiePreparation expectata = legacyYear5000TiePreparation(
        ctx.legacyYearGates,
        ctx.legacyYearCandidatePairs,
        ctx.calculationDay);
    const auto requireList = [](const LegacyYearCandidateList& a,
                                const LegacyYearCandidateList& b,
                                const char* nuntius) {
        if (a.size() != b.size()) {
            throw BaseValidationError(nuntius);
        }
        for (std::size_t i = 0; i < a.size(); ++i) {
            if (a[i].openIndex != b[i].openIndex ||
                a[i].closeIndex != b[i].closeIndex ||
                a[i].length != b[i].length) {
                throw BaseValidationError(nuntius);
            }
        }
    };
    requireList(expectata.preSort, ctx.discovery17Year5000PreSort,
                "familia year 5000 ante sortem discrepat");
    requireList(expectata.sorted, ctx.discovery17Year5000Sorted,
                "stable sort year 5000 per longitudinem solam discrepat");
    if (ctx.discovery17Year5000Sorted.size() < 2) {
        throw BaseValidationError("DISCOVERY 17 run aequalis longitudinis non habet");
    }
    bool aequalisRun = false;
    for (std::size_t i = 1; i < ctx.discovery17Year5000Sorted.size(); ++i) {
        if (ctx.discovery17Year5000Sorted[i - 1].length ==
            ctx.discovery17Year5000Sorted[i].length) {
            aequalisRun = true;
            break;
        }
    }
    if (!aequalisRun) {
        throw BaseValidationError("DISCOVERY 17 nullum tie longitudinis observat");
    }
    if (!ctx.discovery17Year5000SelectionCalled) {
        throw BaseValidationError("selectio year 5000 legacy non vocata est");
    }
    if (ctx.discovery17Year5000SelectionFamilySize !=
        Integer{ctx.discovery17Year5000Sorted.size()}) {
        throw BaseValidationError("magnitudo familiae selectionis year 5000 falsa est");
    }
    if (ctx.discovery17Year5000SelectedOrdinal < 1 ||
        ctx.discovery17Year5000SelectedOrdinal > ctx.discovery17Year5000SelectionFamilySize) {
        throw BaseValidationError("ordinalis year 5000 extra fines est");
    }
    const std::size_t index =
        (ctx.discovery17Year5000SelectedOrdinal - 1).convert_to<std::size_t>();
    const LegacyYearCandidate& expectatus = ctx.discovery17Year5000Sorted[index];
    if (ctx.discovery17Year5000SelectedCandidate.openIndex != expectatus.openIndex ||
        ctx.discovery17Year5000SelectedCandidate.closeIndex != expectatus.closeIndex ||
        ctx.discovery17Year5000SelectedCandidate.length != expectatus.length) {
        throw BaseValidationError("candidatus year 5000 non ex stable sort legacy venit");
    }
}

void BaseValidationManager::requireDiscovery18LegacyYearJumpReady(
    const BaseMonsterContext& ctx) const {
    if (!ctx.discovery18JumpReady) {
        throw BaseValidationError("saltus anni legacy nondum paratus est");
    }
    if (ctx.discovery18JumpAnchor.firstDay > ctx.discovery18JumpAnchor.lastDay) {
        throw BaseValidationError("fines anni anchoris inversi sunt");
    }
    const Integer expectatus = oldJumpGuess(
        ctx.discovery18JumpAnchor,
        ctx.discovery18JumpTargetDay);
    if (ctx.discovery18OldJumpGuess != expectatus ||
        ctx.discovery18JumpOutputYearNumber != expectatus ||
        !ctx.discovery18GuessUsedAsOutput) {
        throw BaseValidationError("oldJumpGuess non est output activus legacy");
    }
}

void BaseValidationManager::requirePatch18YearWalkReady(
    const BaseMonsterContext& ctx) const {
    if (!ctx.patch18Applied || !ctx.patch18GuessTelemetryOnly) {
        throw BaseValidationError("PATCH 18 nondum applicatus est");
    }
    if (!ctx.discovery18JumpReady) {
        throw BaseValidationError("cicatrix oldJumpGuess ante PATCH 18 non cucurrit");
    }
    const Integer expectatusGuess = oldJumpGuess(
        ctx.discovery18JumpAnchor,
        ctx.discovery18JumpTargetDay);
    if (ctx.discovery18OldJumpGuess != expectatusGuess) {
        throw BaseValidationError("telemetria oldJumpGuess mutata est");
    }
    if (ctx.discovery18GuessUsedAsOutput) {
        throw BaseValidationError("oldJumpGuess adhuc output semanticum gubernat");
    }
    if (ctx.patch18OutputYear.number != ctx.discovery18JumpOutputYearNumber) {
        throw BaseValidationError("numerus anni semanticus cum recordo PATCH 18 non congruit");
    }
    if (!(ctx.patch18OutputYear.openGateDay < ctx.discovery18JumpTargetDay &&
          ctx.discovery18JumpTargetDay <= ctx.patch18OutputYear.closeGateDay)) {
        throw BaseValidationError("target dies intra annum PATCH 18 non continetur");
    }
    if (ctx.patch18AnchorYear.number != ctx.discovery18JumpAnchor.number ||
        ctx.patch18AnchorYear.openGateDay + 1 != ctx.discovery18JumpAnchor.firstDay ||
        ctx.patch18AnchorYear.closeGateDay != ctx.discovery18JumpAnchor.lastDay) {
        throw BaseValidationError("anchor PATCH 18 a LegacyYearAnchor differt");
    }
    const Integer expectedNumber = ctx.patch18AnchorYear.number
        + Integer{ctx.patch18ForwardSteps}
        - Integer{ctx.patch18BackwardSteps};
    if (ctx.patch18OutputYear.number != expectedNumber) {
        throw BaseValidationError("numerus anni non congruit cum gradibus sequentialibus");
    }
}
void BaseValidationManager::requireDiscovery19YearCacheReady(const BaseMonsterContext& ctx) const {
    if (!ctx.discovery19CacheReady) throw BaseValidationError("cache anni legacy nondum paratus est");
    if (ctx.discovery19CacheKeyYearNumber != ctx.discovery19CacheRequest.value.number) throw BaseValidationError("clavis cache anni a numero request differt");
    if (ctx.discovery19CacheOutput.number != ctx.discovery19CachedEntry.value.number) throw BaseValidationError("output cache anni a value servato differt");
}
void BaseValidationManager::requirePatch19YearCacheReady(const BaseMonsterContext& ctx) const {
    if (!ctx.patch19Applied) throw BaseValidationError("PATCH 19 nondum applicatus est");
    if (!ctx.discovery19CacheReady) throw BaseValidationError("cache anni PATCH 19 nondum paratus est");
    if (ctx.patch19LegacyCacheHitBeforePatch) {
        const bool allMatched = ctx.patch19FingerprintMatched && ctx.patch19OpenGateMatched && ctx.patch19CloseGateMatched;
        if (allMatched != ctx.discovery19CacheHit) throw BaseValidationError("HIT semanticus a tribus guardis differt");
        if (!allMatched && !ctx.patch19EntryOverwritten) throw BaseValidationError("mismatch guardiae sine overwrite sub clave legacy");
        if (allMatched && ctx.patch19EntryOverwritten) throw BaseValidationError("entry congruens frustra overwrite facta est");
    } else if (ctx.discovery19CacheHit || ctx.patch19EntryOverwritten) {
        throw BaseValidationError("prima MISS legacy in HIT vel overwrite conversa est");
    }
    if (ctx.discovery19CachedEntry.calculationDayFingerprint != ctx.discovery19CacheRequest.calculationDayFingerprint ||
        ctx.discovery19CachedEntry.openGate != ctx.discovery19CacheRequest.openGate ||
        ctx.discovery19CachedEntry.closeGate != ctx.discovery19CacheRequest.closeGate) {
        if (!ctx.discovery19CacheHit) throw BaseValidationError("entry semanticus post MISS guardato a request differt");
    }
    if (ctx.discovery19CacheOutput.number != ctx.discovery19CachedEntry.value.number) throw BaseValidationError("output PATCH 19 a value semantico differt");
}
void BaseValidationManager::requireDiscovery20StructureSauceReady(const BaseMonsterContext& ctx) const {
    if (!ctx.discovery20StructureSauceReady) throw BaseValidationError("structure sauce legacy nondum paratus est");
    if (!ctx.discovery20SelectorConsumedLegacySauce) throw BaseValidationError("selector structure sauce legacy non consumpsit");
    if (ctx.discovery20YearFirstDay != ctx.discovery20ResolvedYear.openGateDay + 1) throw BaseValidationError("primus dies anni ex open gate male derivatus est");
    if (!(ctx.discovery20ResolvedYear.openGateDay < ctx.discovery20OriginalTargetDay && ctx.discovery20OriginalTargetDay <= ctx.discovery20ResolvedYear.closeGateDay)) throw BaseValidationError("target originalis extra annum resolutum est");
    if (ctx.discovery20SelectorToken.bowl2 != ctx.discovery20LegacyStructureSauce.finalBowls.at(1)) throw BaseValidationError("selector bowl2 non ex oldStructureSauce venit");
    if (ctx.discovery20SelectorToken.orderAt46Latch != ctx.discovery20LegacyStructureSauce.orderAt46Latch) throw BaseValidationError("selector order non ex oldStructureSauce venit");
}
void BaseValidationManager::requirePatch20StructureSauceReady(const BaseMonsterContext& ctx) const {
    if (!ctx.discovery20StructureSauceReady) throw BaseValidationError("structure sauce PATCH 20 nondum paratus est");
    if (!ctx.patch20Applied) throw BaseValidationError("PATCH 20 nondum applicatus est");
    if (!ctx.patch20GhostExecuted) throw BaseValidationError("oldStructureSauce ut ghost non cucurrit");
    if (ctx.patch20GhostReachedSelector) throw BaseValidationError("ghost oldStructureSauce ad selector pervenit");
    if (ctx.discovery20SelectorConsumedLegacySauce) throw BaseValidationError("selector semanticus legacy sauce consumpsit");
    if (ctx.discovery20YearFirstDay != ctx.discovery20ResolvedYear.openGateDay + 1) throw BaseValidationError("primus dies anni PATCH 20 male derivatus est");
    if (!(ctx.discovery20ResolvedYear.openGateDay < ctx.discovery20OriginalTargetDay && ctx.discovery20OriginalTargetDay <= ctx.discovery20ResolvedYear.closeGateDay)) throw BaseValidationError("target originalis PATCH 20 extra annum resolutum est");
    if (ctx.discovery20SelectorToken.bowl2 != ctx.patch20SemanticStructureSauce.finalBowls.at(1)) throw BaseValidationError("selector bowl2 non ex sauce semantica PATCH 20 venit");
    if (ctx.discovery20SelectorToken.orderAt46Latch != ctx.patch20SemanticStructureSauce.orderAt46Latch) throw BaseValidationError("selector order non ex sauce semantica PATCH 20 venit");
    const bool differunt = ctx.discovery20OriginalTargetDay != ctx.discovery20YearFirstDay;
    if (differunt != ctx.patch20SemanticRecomputed) throw BaseValidationError("recomputatio PATCH 20 a differentia target/firstDay differt");
}
void BaseValidationManager::requireDiscovery21CutletPartitionReady(const BaseMonsterContext& ctx) const {
    if (!ctx.discovery21CutletPartitionReady) {
        throw BaseValidationError("partitio segmentorum legacy nondum parata est");
    }
    if (ctx.discovery21GapCount < 1 ||
        ctx.discovery21CutletCount < 1 ||
        ctx.discovery21CutletCount > ctx.discovery21GapCount) {
        throw BaseValidationError("fines familiae compositionum legacy invalidi sunt");
    }
    if (ctx.discovery21LegacyFamily.gapCount != ctx.discovery21GapCount ||
        ctx.discovery21LegacyFamily.cutletCount != ctx.discovery21CutletCount ||
        ctx.discovery21LegacyFamily.count < 1) {
        throw BaseValidationError("familia compositionum legacy cum contextu non congruit");
    }
    if (ctx.discovery21SelectionRank < 1 ||
        ctx.discovery21SelectionRank > ctx.discovery21LegacyFamily.count) {
        throw BaseValidationError("gradus selectionis partitionis legacy extra fines est");
    }
    if (ctx.discovery21LegacyPartition.size() !=
        static_cast<std::size_t>(ctx.discovery21CutletCount)) {
        throw BaseValidationError("numerus partium partitionis legacy falsus est");
    }
    int summa = 0;
    int cumulata = 0;
    bool boundaryHit = false;
    if (ctx.discovery21LegacyPrefixSums.size() != ctx.discovery21LegacyPartition.size()) {
        throw BaseValidationError("prefixa partitionis legacy incompleta sunt");
    }
    for (std::size_t i = 0; i < ctx.discovery21LegacyPartition.size(); ++i) {
        const int part = ctx.discovery21LegacyPartition[i];
        if (part < 1) {
            throw BaseValidationError("pars compositionis legacy non positiva est");
        }
        summa += part;
        cumulata += part;
        if (ctx.discovery21LegacyPrefixSums[i] != cumulata) {
            throw BaseValidationError("prefixum compositionis legacy male servatum est");
        }
        if (ctx.discovery21CalculationDayIsInternalGate &&
            cumulata == ctx.discovery21InternalGateOffset) {
            boundaryHit = true;
        }
    }
    if (summa != ctx.discovery21GapCount) {
        throw BaseValidationError("summa partitionis legacy a gapCount differt");
    }
    if (boundaryHit != ctx.discovery21LegacyHitInternalGateBoundary) {
        throw BaseValidationError("diagnosticum limes portae internae a prefixis differt");
    }
    if (ctx.discovery21CalculationDayIsInternalGate &&
        !ctx.discovery21LegacyIgnoredInternalGate) {
        throw BaseValidationError("DISCOVERY 21 portam internam non ignoravit");
    }
}

void BaseValidationManager::requirePatch21CutletPartitionReady(const BaseMonsterContext& ctx) const {
    requireDiscovery21CutletPartitionReady(ctx);
    if (!ctx.patch21Applied) {
        throw BaseValidationError("PATCH 21 nondum applicatus est");
    }
    if (!ctx.patch21LegacyExecuted) {
        throw BaseValidationError("familia legacy ante PATCH 21 non exsecuta est");
    }
    if (ctx.patch21SemanticFamily.gapCount != ctx.discovery21GapCount ||
        ctx.patch21SemanticFamily.cutletCount != ctx.discovery21CutletCount ||
        ctx.patch21SemanticFamily.count < 1) {
        throw BaseValidationError("familia semantica PATCH 21 cum contextu non congruit");
    }
    if (ctx.patch21SemanticSelectionRank < 1 ||
        ctx.patch21SemanticSelectionRank > ctx.patch21SemanticFamily.count) {
        throw BaseValidationError("gradus selectionis PATCH 21 extra fines est");
    }
    if (ctx.patch21SemanticPartition.size() !=
        static_cast<std::size_t>(ctx.discovery21CutletCount) ||
        ctx.patch21SemanticPrefixSums.size() != ctx.patch21SemanticPartition.size()) {
        throw BaseValidationError("partitio semantica PATCH 21 magnitudine falsa est");
    }

    int summa = 0;
    int cumulata = 0;
    bool boundaryHit = false;
    for (std::size_t i = 0; i < ctx.patch21SemanticPartition.size(); ++i) {
        const int part = ctx.patch21SemanticPartition[i];
        if (part < 1) {
            throw BaseValidationError("pars semantica PATCH 21 non positiva est");
        }
        summa += part;
        cumulata += part;
        if (ctx.patch21SemanticPrefixSums[i] != cumulata) {
            throw BaseValidationError("prefixum semanticum PATCH 21 male servatum est");
        }
        if (ctx.discovery21CalculationDayIsInternalGate &&
            cumulata == ctx.discovery21InternalGateOffset) {
            boundaryHit = true;
        }
    }
    if (summa != ctx.discovery21GapCount) {
        throw BaseValidationError("summa partitionis PATCH 21 a gapCount differt");
    }
    if (boundaryHit != ctx.patch21SemanticHitInternalGateBoundary) {
        throw BaseValidationError("diagnosticum limes semanticae PATCH 21 discrepat");
    }

    if (ctx.discovery21CalculationDayIsInternalGate) {
        if (!ctx.patch21FilterApplied ||
            !ctx.patch21SemanticFamily.internalGateRequired ||
            ctx.patch21SemanticFamily.internalGateOffset != ctx.discovery21InternalGateOffset ||
            !ctx.patch21SemanticHitInternalGateBoundary ||
            ctx.patch21LegacyPartitionReused) {
            throw BaseValidationError("filter portae internae PATCH 21 non completus est");
        }
    } else {
        if (ctx.patch21FilterApplied ||
            ctx.patch21SemanticFamily.internalGateRequired ||
            !ctx.patch21LegacyPartitionReused ||
            ctx.patch21SemanticSelectionRank != ctx.discovery21SelectionRank ||
            ctx.patch21SemanticPartition != ctx.discovery21LegacyPartition) {
            throw BaseValidationError("casus sine porta interna legacy transire debet");
        }
    }
}

void BaseValidationManager::requireDiscovery22RepeatedNamesReady(
    const BaseMonsterContext& ctx) const {
    if (!ctx.discovery22RepeatedNamesReady) {
        throw BaseValidationError("DISCOVERY 22 nondum paratus est");
    }
    if (!ctx.discovery22Patch20Prepared || !ctx.discovery22Patch21Prepared) {
        throw BaseValidationError("DISCOVERY 22 gradus anteriores paratos requirit");
    }
    if (ctx.discovery22MasterNameCount != 17) {
        throw BaseValidationError("DISCOVERY 22 catalogum XVII nominum requirit");
    }
    if (ctx.discovery22CutletCount < 1 ||
        ctx.discovery22CutletCount > ctx.discovery22MasterNameCount) {
        throw BaseValidationError("numerus nominum segmentorum DISCOVERY 22 invalidus est");
    }
    const Integer expectedSpace = legacyCutletNameSelectionSpaceCount(
        ctx.discovery22MasterNameCount,
        ctx.discovery22CutletCount);
    if (ctx.discovery22SelectionSpaceCount != expectedSpace) {
        throw BaseValidationError("spatium selectionis nominum DISCOVERY 22 discrepat");
    }
    if (ctx.discovery22SelectionRank < 1 ||
        ctx.discovery22SelectionRank > ctx.discovery22SelectionSpaceCount) {
        throw BaseValidationError("gradus nominum DISCOVERY 22 extra fines est");
    }
    if (ctx.discovery22LegacyNameIndices.size() !=
        static_cast<std::size_t>(ctx.discovery22CutletCount)) {
        throw BaseValidationError("ordo nominum legacy DISCOVERY 22 magnitudine falsa est");
    }
    std::vector<int> masterList;
    masterList.reserve(static_cast<std::size_t>(ctx.discovery22MasterNameCount));
    for (int canonicalIndex = 1;
         canonicalIndex <= ctx.discovery22MasterNameCount;
         ++canonicalIndex) {
        masterList.push_back(canonicalIndex);
    }
    const std::vector<int> replay = legacyNameRowWithRepeats(
        masterList,
        ctx.discovery22SelectionRank,
        ctx.discovery22CutletCount);
    if (replay != ctx.discovery22LegacyNameIndices) {
        throw BaseValidationError("generator legacy nominum DISCOVERY 22 non reproducitur");
    }
    for (const int canonicalIndex : ctx.discovery22LegacyNameIndices) {
        if (canonicalIndex < 1 || canonicalIndex > ctx.discovery22MasterNameCount) {
            throw BaseValidationError("canonicalIndex legacy DISCOVERY 22 extra catalogum est");
        }
    }
    if (legacyNameRowContainsRepeat(ctx.discovery22LegacyNameIndices) !=
        ctx.discovery22LegacyContainsRepeat) {
        throw BaseValidationError("diagnosticum repetitionis DISCOVERY 22 discrepat");
    }
}

void BaseValidationManager::requirePatch22RepeatedNamesReady(
    const BaseMonsterContext& ctx) const {
    requireDiscovery22RepeatedNamesReady(ctx);
    if (!ctx.patch22RepeatedNamesReady || !ctx.patch22Applied) {
        throw BaseValidationError("PATCH 22 nondum applicatus est");
    }
    if (!ctx.patch22LegacyExecuted || !ctx.patch22CorrectComputed) {
        throw BaseValidationError("PATCH 22 bad et correct ambos computare debet");
    }
    std::vector<int> masterList;
    masterList.reserve(static_cast<std::size_t>(ctx.discovery22MasterNameCount));
    for (int canonicalIndex = 1;
         canonicalIndex <= ctx.discovery22MasterNameCount;
         ++canonicalIndex) {
        masterList.push_back(canonicalIndex);
    }
    const std::vector<int> expectedCorrect = partialPermutationNameRowUnrank(
        masterList,
        ctx.discovery22SelectionRank,
        ctx.discovery22CutletCount);
    if (ctx.patch22CorrectNameIndices != expectedCorrect) {
        throw BaseValidationError("correct partial-permutation PATCH 22 discrepat");
    }
    if (legacyNameRowContainsRepeat(ctx.patch22CorrectNameIndices)) {
        throw BaseValidationError("correct partial-permutation PATCH 22 repetitionem continet");
    }
    const bool equal = ctx.discovery22LegacyNameIndices == ctx.patch22CorrectNameIndices;
    if (ctx.patch22BadEqualsCorrect != equal) {
        throw BaseValidationError("comparatio bad==correct PATCH 22 discrepat");
    }
    if (equal) {
        if (!ctx.patch22LegacyReturned ||
            ctx.patch22SemanticNameIndices != ctx.discovery22LegacyNameIndices) {
            throw BaseValidationError("PATCH 22 bad solum cum bad==correct reddere debet");
        }
    } else {
        if (ctx.patch22LegacyReturned ||
            ctx.patch22SemanticNameIndices != ctx.patch22CorrectNameIndices) {
            throw BaseValidationError("PATCH 22 correct cum bad!=correct reddere debet");
        }
    }
    if (legacyNameRowContainsRepeat(ctx.patch22SemanticNameIndices)) {
        throw BaseValidationError("output semanticus PATCH 22 repetitionem continet");
    }
}

void BaseValidationManager::requireDiscovery23MonthLengthMaterializationReady(
    const BaseMonsterContext& ctx) const {
    if (!ctx.discovery23MonthLengthMaterializationReady) {
        throw BaseValidationError("DISCOVERY 23 nondum paratus est");
    }
    if (!ctx.discovery23Patch22Prepared) {
        throw BaseValidationError("DISCOVERY 23 PATCH 22 paratum requirit");
    }
    if (ctx.discovery23YearLength < 1 ||
        ctx.discovery23YearLength > REAL_YEAR_MAX_PATCH) {
        throw BaseValidationError("longitudo anni DISCOVERY 23 extra fines est");
    }
    if (ctx.discovery23MonthCount < 3 || ctx.discovery23MonthCount > 47) {
        throw BaseValidationError("numerus mensium DISCOVERY 23 extra fines est");
    }
    const Integer replayCount = legacyMonthLengthConcreteFamilyCountProof(
        ctx.discovery23YearLength,
        ctx.discovery23MonthCount);
    if (replayCount < 1 || replayCount != ctx.discovery23ExactFamilyCount) {
        throw BaseValidationError("numerus familiaris concreti DISCOVERY 23 discrepat");
    }
    const Integer platformCapacity{
        std::numeric_limits<std::size_t>::max()};
    if (ctx.discovery23ConcreteListIndexCapacity != platformCapacity) {
        throw BaseValidationError("capacitas listae concretae DISCOVERY 23 discrepat");
    }
    if (!ctx.discovery23LegacyConcreteListContractReached) {
        throw BaseValidationError("API listae concretae legacy DISCOVERY 23 attingi debet");
    }
    if (ctx.discovery23ExactFamilyCount > platformCapacity) {
        if (!ctx.discovery23BlockedBeforeAllocation ||
            ctx.discovery23LegacyConcreteEnumerationEntered ||
            ctx.discovery23LegacyConcreteMaterializationCompleted ||
            ctx.discovery23MaterializedItemCount != 0) {
            throw BaseValidationError(
                "familia enormis DISCOVERY 23 ante allocationem tuto sistere debet");
        }
    } else {
        if (ctx.discovery23BlockedBeforeAllocation ||
            !ctx.discovery23LegacyConcreteEnumerationEntered ||
            !ctx.discovery23LegacyConcreteMaterializationCompleted ||
            Integer{ctx.discovery23MaterializedItemCount} !=
                ctx.discovery23ExactFamilyCount) {
            throw BaseValidationError(
                "familia parva DISCOVERY 23 materializationem concretam complere debet");
        }
    }
}

void BaseValidationManager::requirePatch23MonthLengthMaterializationReady(
    const BaseMonsterContext& ctx) const {
    requireDiscovery23MonthLengthMaterializationReady(ctx);
    if (!ctx.patch23MonthLengthMaterializationReady || !ctx.patch23Applied) {
        throw BaseValidationError("PATCH 23 nondum applicatus est");
    }
    if (!ctx.patch23LegacyExecuted) {
        throw BaseValidationError("PATCH 23 cicatricem materializationis legacy vere exsequi debet");
    }
    if (!ctx.patch23VirtualBackendUsed) {
        throw BaseValidationError("PATCH 23 backend VirtualLegacyList uti debet");
    }
    if (!ctx.patch23CountMatchesLegacyProof) {
        throw BaseValidationError("count DP PATCH 23 probationi exactae legacy congruere debet");
    }
    if (ctx.patch23VirtualCount != ctx.discovery23ExactFamilyCount) {
        throw BaseValidationError("count VirtualLegacyList PATCH 23 a familia exacta differt");
    }
    if (ctx.patch23VirtualProbeRank < 1 ||
        ctx.patch23VirtualProbeRank > ctx.patch23VirtualCount) {
        throw BaseValidationError("probe rank VirtualLegacyList PATCH 23 extra fines est");
    }
    if (ctx.patch23VirtualProbeItem.size() !=
        static_cast<std::size_t>(ctx.discovery23MonthCount)) {
        throw BaseValidationError("probe item VirtualLegacyList PATCH 23 magnitudine falsa est");
    }
    int sum = 0;
    for (const int length : ctx.patch23VirtualProbeItem) {
        if (length < LEGACY_MONTH_LENGTH_MIN || length > LEGACY_MONTH_LENGTH_MAX) {
            throw BaseValidationError("probe item VirtualLegacyList PATCH 23 longitudinem extra fines continet");
        }
        sum += length;
    }
    if (sum != ctx.discovery23YearLength) {
        throw BaseValidationError("probe item VirtualLegacyList PATCH 23 summam anni non servat");
    }
    VirtualLegacyList replay(
        ctx.discovery23YearLength,
        ctx.discovery23MonthCount);
    if (replay.count() != ctx.patch23VirtualCount ||
        replay.itemAt1(ctx.patch23VirtualProbeRank) != ctx.patch23VirtualProbeItem) {
        throw BaseValidationError("VirtualLegacyList PATCH 23 invocationem non reproducit");
    }
}

void BaseValidationManager::requireDiscovery24MonthWeavingReady(
    const BaseMonsterContext& ctx) const {
    if (!ctx.discovery24MonthWeavingReady) {
        throw BaseValidationError("DISCOVERY 24 nondum paratus est");
    }
    if (!ctx.discovery24Patch20Prepared) {
        throw BaseValidationError("DISCOVERY 24 sauce structuralem PATCH 20 paratam requirit");
    }
    if (!ctx.discovery24Patch23Prepared) {
        throw BaseValidationError("DISCOVERY 24 backend mensium PATCH 23 paratum requirit");
    }
    if (ctx.discovery24MonthLengths.empty()) {
        throw BaseValidationError("DISCOVERY 24 longitudines mensium vacuas recusat");
    }
    if (ctx.discovery24AnswerRing.directionStep != -1 &&
        ctx.discovery24AnswerRing.directionStep != 1) {
        throw BaseValidationError("DISCOVERY 24 annulum responsorum invalidum habet");
    }
    if (!ctx.discovery24MultiplicitiesPreserved) {
        throw BaseValidationError("legacyChooseEachDaySeparately multiplicities mensium servare debet");
    }
    if (!ctx.discovery24LegacyUsedAsSemanticOutput) {
        throw BaseValidationError("DISCOVERY 24 ghost legacy ad output activum pervenire debet");
    }
    if (ctx.discovery24SemanticWeaving != ctx.discovery24LegacyGhost) {
        throw BaseValidationError("DISCOVERY 24 output activus a ghost legacy separari nondum debet");
    }
    int totalLength = 0;
    for (const int length : ctx.discovery24MonthLengths) {
        if (length < LEGACY_MONTH_LENGTH_MIN || length > LEGACY_MONTH_LENGTH_MAX) {
            throw BaseValidationError("DISCOVERY 24 longitudo mensis extra fines historicos est");
        }
        totalLength += length;
    }
    if (ctx.discovery24LegacyGhost.size() != static_cast<std::size_t>(totalLength)) {
        throw BaseValidationError("DISCOVERY 24 ghost longitudinem anni localis non servat");
    }
    if (ctx.discovery24WholeWeavingOrderLegal !=
        (ctx.discovery24FirstOccurrenceOrderPreserved &&
         ctx.discovery24LastOccurrenceOrderPreserved)) {
        throw BaseValidationError("DISCOVERY 24 status ordinis texturae internus discrepat");
    }
}

void BaseValidationManager::requirePatch24MonthWeavingReady(
    const BaseMonsterContext& ctx) const {
    if (!ctx.patch24MonthWeavingReady || !ctx.patch24Applied) {
        throw BaseValidationError("PATCH 24 nondum applicatus est");
    }
    if (!ctx.discovery24MonthWeavingReady || !ctx.discovery24LegacyUsedAsSemanticOutput) {
        throw BaseValidationError("PATCH 24 cicatricem DISCOVERY 24 prius exsequi debet");
    }
    if (!ctx.patch24LegacyExecuted || !ctx.patch24CorrectComputed) {
        throw BaseValidationError("PATCH 24 ghost et correct ambos computare debet");
    }
    if (ctx.patch24LegalFamilyCount < 1) {
        throw BaseValidationError("PATCH 24 familiam legalem non vacuam requirit");
    }
    if (ctx.patch24WantedRank < 1 ||
        ctx.patch24WantedRank > ctx.patch24LegalFamilyCount) {
        throw BaseValidationError("PATCH 24 wantedRank extra familiam legalem est");
    }
    const Integer replayRank = compatibleMonthWeavingRank(
        ctx.discovery24AnswerRing,
        ctx.patch24LegalFamilyCount);
    if (replayRank != ctx.patch24WantedRank) {
        throw BaseValidationError("PATCH 24 wantedRank eodem annulo non reproduci potest");
    }
    const std::vector<int> replayCorrect = DPUnrankLegalWeaving(
        ctx.discovery24MonthLengths,
        ctx.patch24WantedRank);
    if (replayCorrect != ctx.patch24CorrectWeaving) {
        throw BaseValidationError("PATCH 24 correct textura DP discrepat");
    }
    const bool equal = ctx.discovery24LegacyGhost == ctx.patch24CorrectWeaving;
    if (ctx.patch24GhostEqualsCorrect != equal) {
        throw BaseValidationError("PATCH 24 comparatio ghost==correct discrepat");
    }
    if (equal) {
        if (!ctx.patch24LegacyReturned ||
            ctx.discovery24SemanticWeaving != ctx.discovery24LegacyGhost) {
            throw BaseValidationError("PATCH 24 ghost solum cum ghost==correct reddere debet");
        }
    } else {
        if (ctx.patch24LegacyReturned ||
            ctx.discovery24SemanticWeaving != ctx.patch24CorrectWeaving) {
            throw BaseValidationError("PATCH 24 correct cum ghost!=correct reddere debet");
        }
    }
    const bool semanticLegal = legalMonthWeavingRowInternal(
        ctx.discovery24MonthLengths,
        ctx.discovery24SemanticWeaving);
    if (!semanticLegal ||
        !ctx.patch24SemanticWholeWeavingOrderLegal) {
        throw BaseValidationError("PATCH 24 output semanticus textura integra legalis esse debet");
    }
}

void BaseValidationManager::requireDiscovery25ContiguousMonthDayReady(
    const BaseMonsterContext& ctx) const {
    requirePatch24MonthWeavingReady(ctx);
    if (!ctx.discovery25ContiguousMonthDayReady) {
        throw BaseValidationError("DISCOVERY 25 nondum paratus est");
    }
    if (!ctx.discovery25Patch24Prepared) {
        throw BaseValidationError("DISCOVERY 25 texturam semanticam PATCH 24 paratam requirit");
    }
    if (ctx.discovery25TargetPosition1 < 1 ||
        ctx.discovery25TargetPosition1 > ctx.discovery24SemanticWeaving.size()) {
        throw BaseValidationError("DISCOVERY 25 positio target extra texturam semanticam est");
    }
    const int targetMonthId =
        ctx.discovery24SemanticWeaving[ctx.discovery25TargetPosition1 - 1];
    if (ctx.discovery25TargetMonthId != targetMonthId) {
        throw BaseValidationError("DISCOVERY 25 monthId target a textura semantica discrepat");
    }
    const auto found = std::find(
        ctx.discovery24SemanticWeaving.begin(),
        ctx.discovery24SemanticWeaving.end(),
        targetMonthId);
    const std::size_t firstPosition1 =
        static_cast<std::size_t>(
            std::distance(ctx.discovery24SemanticWeaving.begin(), found)) + 1;
    if (ctx.discovery25FirstOccurrencePosition1 != firstPosition1) {
        throw BaseValidationError("DISCOVERY 25 prima positio mensis target discrepat");
    }
    const int replayGuess = oldContiguousMonthDayGuess(
        ctx.discovery24SemanticWeaving,
        ctx.discovery25TargetPosition1);
    if (!ctx.discovery25LegacyExecuted ||
        ctx.discovery25LegacyGuessedDayInMonth != replayGuess) {
        throw BaseValidationError("DISCOVERY 25 oldContiguousMonthDayGuess realiter exsequi debet");
    }
    if (!ctx.discovery25LegacyUsedAsSemanticOutput) {
        throw BaseValidationError("DISCOVERY 25 guess legacy ad statum semanticum intermedium pervenire debet");
    }
    if (!ctx.patch25Applied &&
        ctx.discovery25SemanticDayInMonth != ctx.discovery25LegacyGuessedDayInMonth) {
        throw BaseValidationError("DISCOVERY 25 sine PATCH 25 guess legacy statum semanticum gubernare debet");
    }
}

void BaseValidationManager::requirePatch25ContiguousMonthDayReady(
    const BaseMonsterContext& ctx) const {
    requireDiscovery25ContiguousMonthDayReady(ctx);
    if (!ctx.patch25ContiguousMonthDayReady || !ctx.patch25Applied) {
        throw BaseValidationError("PATCH 25 nondum applicatus est");
    }
    if (!ctx.patch25LegacyExecuted || !ctx.patch25CorrectComputed) {
        throw BaseValidationError("PATCH 25 ghost legacy et occurrence-count correctum requirit");
    }
    const int replayCorrect = countMonthOccurrencesThroughTarget(
        ctx.discovery24SemanticWeaving,
        ctx.discovery25TargetPosition1);
    if (ctx.patch25CorrectDayInMonth != replayCorrect) {
        throw BaseValidationError("PATCH 25 occurrence-count correctum a replay discrepat");
    }
    const bool equal =
        ctx.discovery25LegacyGuessedDayInMonth == ctx.patch25CorrectDayInMonth;
    if (ctx.patch25LegacyEqualsCorrect != equal ||
        ctx.patch25LegacyReturned != equal) {
        throw BaseValidationError("PATCH 25 regulam ghost==correct non servat");
    }
    const int expectedOutput = equal
        ? ctx.discovery25LegacyGuessedDayInMonth
        : ctx.patch25CorrectDayInMonth;
    if (ctx.discovery25SemanticDayInMonth != expectedOutput) {
        throw BaseValidationError("PATCH 25 diem mensis semanticum correctum non servat");
    }
}

void BaseValidationManager::requireDiscovery26YearMembershipReady(
    const BaseMonsterContext& ctx) const {
    if (!ctx.discovery26YearMembershipReady) {
        throw BaseValidationError("DISCOVERY 26 membership anni nondum parata est");
    }
    if (!ctx.discovery26LegacyExecuted) {
        throw BaseValidationError("DISCOVERY 26 iter legacy clausum vere exsequi debet");
    }
    if (!ctx.discovery26LegacyUsedAsSemanticOutput) {
        throw BaseValidationError("DISCOVERY 26 annum legacy directe ad output semanticum mittere debet");
    }
    if (ctx.discovery26MembershipAnchor.firstDay > ctx.discovery26MembershipAnchor.lastDay) {
        throw BaseValidationError("DISCOVERY 26 anchor anni fines inversos habet");
    }
    const bool closedAccepted =
        ctx.discovery26MembershipOutputYear.openGateDay <= ctx.discovery26MembershipTargetDay &&
        ctx.discovery26MembershipTargetDay <= ctx.discovery26MembershipOutputYear.closeGateDay;
    if (!closedAccepted || !ctx.discovery26LegacyClosedIntervalAccepted) {
        throw BaseValidationError("DISCOVERY 26 legacy intervalum [open,close] non servat");
    }
    const bool atOpening =
        ctx.discovery26MembershipTargetDay == ctx.discovery26MembershipOutputYear.openGateDay;
    if (ctx.discovery26TargetAtOpeningGate != atOpening) {
        throw BaseValidationError("DISCOVERY 26 notam target ad opening gate falso servat");
    }
}

void BaseValidationManager::requirePatch26YearMembershipReady(
    const BaseMonsterContext& ctx) const {
    requireDiscovery26YearMembershipReady(ctx);
    if (!ctx.patch26YearMembershipReady || !ctx.patch26Applied) {
        throw BaseValidationError("PATCH 26 membership anni nondum applicata est");
    }
    if (!ctx.patch26LegacyExecuted || !ctx.patch26CorrectComputed) {
        throw BaseValidationError("PATCH 26 cicatricem legacy et annum correctum requirit");
    }
    const bool authoritativeAccepted =
        ctx.patch26CorrectOutputYear.openGateDay < ctx.discovery26MembershipTargetDay &&
        ctx.discovery26MembershipTargetDay <= ctx.patch26CorrectOutputYear.closeGateDay;
    if (!authoritativeAccepted || !ctx.patch26AuthoritativeIntervalAccepted) {
        throw BaseValidationError("PATCH 26 intervalum (open,close] non servat");
    }

    const Patch18SequentialYearWalkWrapper replayWrapper;
    const Patch18YearWalkResult replay = replayWrapper.repair(
        ctx.calculationDay,
        ctx.discovery26MembershipAnchor,
        ctx.discovery26MembershipTargetDay);
    const bool replayEqual =
        replay.outputYear.number == ctx.patch26CorrectOutputYear.number &&
        replay.outputYear.openGateIndex == ctx.patch26CorrectOutputYear.openGateIndex &&
        replay.outputYear.closeGateIndex == ctx.patch26CorrectOutputYear.closeGateIndex &&
        replay.outputYear.openGateDay == ctx.patch26CorrectOutputYear.openGateDay &&
        replay.outputYear.closeGateDay == ctx.patch26CorrectOutputYear.closeGateDay;
    if (!replayEqual ||
        replay.forwardSteps != ctx.patch26CorrectForwardSteps ||
        replay.backwardSteps != ctx.patch26CorrectBackwardSteps) {
        throw BaseValidationError("PATCH 26 iter semanticum a replay PATCH 18 discrepat");
    }

    const bool equal =
        ctx.discovery26MembershipOutputYear.number == ctx.patch26CorrectOutputYear.number &&
        ctx.discovery26MembershipOutputYear.openGateIndex == ctx.patch26CorrectOutputYear.openGateIndex &&
        ctx.discovery26MembershipOutputYear.closeGateIndex == ctx.patch26CorrectOutputYear.closeGateIndex &&
        ctx.discovery26MembershipOutputYear.openGateDay == ctx.patch26CorrectOutputYear.openGateDay &&
        ctx.discovery26MembershipOutputYear.closeGateDay == ctx.patch26CorrectOutputYear.closeGateDay;
    if (ctx.patch26LegacyEqualsCorrect != equal ||
        ctx.patch26LegacyReturned != equal) {
        throw BaseValidationError("PATCH 26 regulam ghost==correct non servat");
    }
}

void BaseValidationManager::requirePatch17Year5000TieReady(
    const BaseMonsterContext& ctx) const {
    requireDiscovery17Year5000TieReady(ctx);
    if (!ctx.patch17Applied) {
        throw BaseValidationError("PATCH 17 nondum applicatus est");
    }
    if (ctx.patch17LegacyYear5000Sorted.size() !=
        ctx.discovery17Year5000Sorted.size()) {
        throw BaseValidationError("familia legacy PATCH 17 non servata est");
    }
    for (std::size_t i = 0; i < ctx.patch17LegacyYear5000Sorted.size(); ++i) {
        const auto& a = ctx.patch17LegacyYear5000Sorted[i];
        const auto& b = ctx.discovery17Year5000Sorted[i];
        if (a.openIndex != b.openIndex ||
            a.closeIndex != b.closeIndex ||
            a.length != b.length) {
            throw BaseValidationError("ordo legacy ante PATCH 17 mutatus est");
        }
    }

    const LegacyYearCandidateList expectata = sortEqualLengthRunsByOpeningGate(
        ctx.legacyYearGates,
        ctx.patch17LegacyYear5000Sorted);
    if (expectata.size() != ctx.patch17Year5000Sorted.size()) {
        throw BaseValidationError("familia PATCH 17 post tie-sort magnitudine discrepat");
    }
    for (std::size_t i = 0; i < expectata.size(); ++i) {
        const auto& a = expectata[i];
        const auto& b = ctx.patch17Year5000Sorted[i];
        if (a.openIndex != b.openIndex ||
            a.closeIndex != b.closeIndex ||
            a.length != b.length) {
            throw BaseValidationError("tie-sort PATCH 17 per opening gate discrepat");
        }
        if (ctx.patch17Year5000Sorted[i].length !=
            ctx.patch17LegacyYear5000Sorted[i].length) {
            throw BaseValidationError("PATCH 17 limites run aequalis longitudinis transgressus est");
        }
    }
    if (ctx.patch17EqualLengthRunCount == 0) {
        throw BaseValidationError("PATCH 17 nullum run aequalis longitudinis observat");
    }
    if (ctx.patch17Year5000SelectedOrdinal !=
        ctx.patch17LegacyYear5000SelectedOrdinal) {
        throw BaseValidationError("PATCH 17 eundem answer stream non servavit");
    }
    if (ctx.patch17Year5000SelectedOrdinal < 1 ||
        ctx.patch17Year5000SelectedOrdinal > Integer{ctx.patch17Year5000Sorted.size()}) {
        throw BaseValidationError("ordinalis PATCH 17 extra fines est");
    }
    const std::size_t index =
        (ctx.patch17Year5000SelectedOrdinal - 1).convert_to<std::size_t>();
    const auto& expectatus = ctx.patch17Year5000Sorted[index];
    if (ctx.patch17Year5000SelectedCandidate.openIndex != expectatus.openIndex ||
        ctx.patch17Year5000SelectedCandidate.closeIndex != expectatus.closeIndex ||
        ctx.patch17Year5000SelectedCandidate.length != expectatus.length) {
        throw BaseValidationError("candidatus PATCH 17 non ex familia reparata venit");
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
    const RejectionScarKey key{
        stream.first, stream.directionStep, N, acceptanceLimit};

    if (accelerationsOn()) {
        RejectionCertificate certificate{};
        bool foundCertificate = false;
        {
            std::lock_guard<std::mutex> guard(rejectionScarVaultMutex);
            const auto found = rejectionScarVault.find(key);
            if (found != rejectionScarVault.end()) {
                if (!found->second.poisoned &&
                    fingerprintAcceptable(
                        found->second.semanticFingerprint,
                        found->second.scarGeneration,
                        36)) {
                    certificate = found->second;
                    foundCertificate = true;
                } else if (!found->second.poisoned) {
                    found->second.poisoned = true;
                    scarBump(&PersistentScarMetrics::staleOrPoisonedRejected);
                }
            }
        }
        if (foundCertificate) {
            const Integer replay = ringAnswer(stream, certificate.acceptedOffset);
            bool valid = replay == certificate.acceptedAnswer &&
                         replay <= acceptanceLimit;
            if (valid && fullHistoricalValidationOn()) {
                Integer probe = 0;
                while (probe < certificate.acceptedOffset) {
                    if (ringAnswer(stream, probe) <= acceptanceLimit) {
                        valid = false;
                        break;
                    }
                    ++probe;
                }
            }
            if (valid) {
                scarBump(&PersistentScarMetrics::patch36RejectionScarHit);
                if (certificate.acceptedOffset > 0 &&
                    certificate.acceptedOffset <= Integer{std::numeric_limits<std::uint64_t>::max()}) {
                    scarBump(
                        &PersistentScarMetrics::patch36RejectionIterationsAvoided,
                        certificate.acceptedOffset.convert_to<std::uint64_t>());
                }
                return Patch13RejectionSelection{
                    acceptanceLimit,
                    certificate.acceptedAnswer,
                    certificate.acceptedOffset,
                    adapter.selectAcceptedAnswer(certificate.acceptedAnswer, N)
                };
            }
            {
                std::lock_guard<std::mutex> guard(rejectionScarVaultMutex);
                const auto found = rejectionScarVault.find(key);
                if (found != rejectionScarVault.end()) found->second.poisoned = true;
            }
            scarBump(&PersistentScarMetrics::staleOrPoisonedRejected);
        } else {
            scarBump(&PersistentScarMetrics::patch36RejectionScarMiss);
        }
    }

    Integer offset = 0;
    for (;;) {
        const Integer x = ringAnswer(stream, offset);
        if (x <= acceptanceLimit) {
            if (accelerationsOn()) {
                const RejectionCertificate certificate{
                    Integer{0},
                    offset,
                    x,
                    false,
                    36,
                    persistentSemanticFingerprint()
                };
                std::lock_guard<std::mutex> guard(rejectionScarVaultMutex);
                const auto existing = rejectionScarVault.find(key);
                if (existing == rejectionScarVault.end() || existing->second.poisoned) {
                    boundedEraseFirst(rejectionScarVault, REJECTION_SCAR_LIMIT);
                    rejectionScarVault[key] = certificate;
                }
            }
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

LegacyYearCandidatePreparation LegacyYearCandidateAdapter::prepareForSelection(
    const std::vector<Integer>& gates,
    const std::vector<LegacyYearCandidatePair>& pairs) const {
    const LegacyYearCandidateList preSort = legacyYearCandidatesBeforeSort(gates, pairs);
    return LegacyYearCandidatePreparation{
        preSort,
        legacyStableLengthOnlyYearCandidates(preSort)
    };
}

Integer LegacyYearCandidateAdapter::select(
    const LegacyAnswerRing& stream,
    const LegacyYearCandidateList& sorted,
    const LegacyBiasedSelectionAdapter& selectionAdapter,
    const Patch13RejectionWrapper& rejectionWrapper,
    const Patch14WideDetourWrapper& wideWrapper) const {
    if (sorted.empty()) {
        throw BaseValidationError("familia candidatorum annorum ad selectionem vacua est");
    }
    const Integer N = Integer{sorted.size()};
    if (N <= M_OLD) {
        return rejectionWrapper.repair(stream, N, selectionAdapter).outputRank;
    }
    return wideWrapper.repair(stream, N, selectionAdapter).outputRank;
}

Patch16YearCandidatePreparation YearCandidateCeilingPatchWrapper::prepare(
    const std::vector<Integer>& gates,
    const std::vector<LegacyYearCandidatePair>& pairs) const {
    Patch16YearCandidatePreparation out;
    for (const LegacyYearCandidatePair& pair : pairs) {
        const Patch16YearCandidateDecision decision = yearCandidateAfterFootnotePatch(
            gates,
            pair.openIndex,
            pair.closeIndex);
        if (!decision.legacyAccepted) {
            continue;
        }
        out.legacyPreSort.push_back(decision.candidate);
        if (!decision.semanticAccepted) {
            out.rejectedBeforeSort.push_back(decision.candidate);
            continue;
        }
        out.semanticPreSort.push_back(decision.candidate);
    }
    out.semanticSorted = legacyStableLengthOnlyYearCandidates(out.semanticPreSort);
    return out;
}

LegacyYear5000TiePreparation LegacyYear5000TieAdapter::prepare(
    const std::vector<Integer>& gates,
    const std::vector<LegacyYearCandidatePair>& pairs,
    const Integer& calculationDay) const {
    return legacyYear5000TiePreparation(gates, pairs, calculationDay);
}

Integer LegacyYear5000TieAdapter::select(
    const LegacyAnswerRing& stream,
    const LegacyYearCandidateList& sorted,
    const LegacyBiasedSelectionAdapter& selectionAdapter,
    const Patch13RejectionWrapper& rejectionWrapper,
    const Patch14WideDetourWrapper& wideWrapper) const {
    const LegacyYearCandidateAdapter legacyAdapter;
    return legacyAdapter.select(
        stream,
        sorted,
        selectionAdapter,
        rejectionWrapper,
        wideWrapper);
}

Integer LegacyYearJumpAdapter::guess(const LegacyYearAnchor& anchor,
                                     const Integer& targetDay) const {
    return oldJumpGuess(anchor, targetDay);
}
LegacyYearCacheEntry LegacyYearNumberOnlyCacheAdapter::getOrPut(std::map<Integer, LegacyYearCacheEntry>& cache, const Integer& yearNumber, const LegacyYearCacheEntry& current, bool& hit) const {
    const auto found=cache.find(yearNumber); if(found!=cache.end()){hit=true; return found->second;} hit=false; cache[yearNumber]=current; return current;
}
Patch19GuardedYearCacheResolution Patch19YearCacheGuardWrapper::repair(std::map<Integer, LegacyYearCacheEntry>& cache, const Integer& yearNumber, const LegacyYearCacheEntry& current, const LegacyYearCacheEntry& legacyEntry, bool legacyHit) const {
    Patch19GuardedYearCacheResolution out;
    if (!legacyHit) { out.semanticEntry=current; out.outputValue=current.value; return out; }
    out.fingerprintMatched = legacyEntry.calculationDayFingerprint == current.calculationDayFingerprint;
    out.openGateMatched = legacyEntry.openGate == current.openGate;
    out.closeGateMatched = legacyEntry.closeGate == current.closeGate;
    if (out.fingerprintMatched && out.openGateMatched && out.closeGateMatched) { out.semanticHit=true; out.semanticEntry=legacyEntry; out.outputValue=legacyEntry.value; return out; }
    cache[yearNumber]=current; out.semanticEntry=current; out.outputValue=current.value; out.entryOverwritten=true; return out;
}
Patch11LatchedOrderSauceResult LegacyStructureSauceAdapter::call(
    const Integer& calculationDay,
    const Integer& originalTargetDay) const {
    return oldStructureSauce(calculationDay, originalTargetDay);
}
LegacyStructureSelectorToken LegacyStructureSelectorAdapter::consume(
    const Patch11LatchedOrderSauceResult& sauce) const {
    return LegacyStructureSelectorToken{sauce.finalBowls.at(1), sauce.orderAt46Latch};
}
Patch20StructureSauceResult StructureSaucePatchWrapper::repair(
    const Integer& calculationDay,
    const Integer& originalTargetDay,
    const Patch18YearRecord& year) const {
    return structureSaucePatch(calculationDay, originalTargetDay, year);
}
LegacyPositiveCompositionFamily LegacyPositiveCompositionAdapter::family(
    int gapCount,
    int cutletCount) const {
    return legacyPositiveCompositions(gapCount, cutletCount);
}
std::vector<int> LegacyPositiveCompositionAdapter::unrank(
    const LegacyPositiveCompositionFamily& familyValue,
    const Integer& rank1) const {
    return legacyPositiveCompositionUnrank(familyValue, rank1);
}
Patch21CutletPartitionResult CutletPartitionPatchWrapper::repair(
    const BaseMonsterContext& ctx,
    const LegacyAnswerRing& stream,
    const LegacyBiasedSelectionAdapter& selectionAdapter,
    const Patch13RejectionWrapper& rejectionWrapper,
    const Patch14WideDetourWrapper& wideWrapper) const {
    Patch21CutletPartitionResult out;
    out.filterApplied = ctx.discovery21CalculationDayIsInternalGate;
    out.legacyPartitionReused = !out.filterApplied;
    out.semanticFamily = filteredLegacyPositiveCompositions(
        ctx.discovery21GapCount,
        ctx.discovery21CutletCount,
        ctx.discovery21InternalGateOffset,
        out.filterApplied);

    if (!out.filterApplied) {
        out.semanticSelectionRank = ctx.discovery21SelectionRank;
        out.semanticPartition = ctx.discovery21LegacyPartition;
    } else {
        if (out.semanticFamily.count <= M_OLD) {
            out.semanticSelectionRank = rejectionWrapper.repair(
                stream,
                out.semanticFamily.count,
                selectionAdapter).outputRank;
        } else {
            out.semanticSelectionRank = wideWrapper.repair(
                stream,
                out.semanticFamily.count,
                selectionAdapter).outputRank;
        }
        out.semanticPartition = filteredLegacyPositiveCompositionUnrank(
            out.semanticFamily,
            out.semanticSelectionRank);
    }

    out.semanticPrefixSums.clear();
    out.semanticPrefixSums.reserve(out.semanticPartition.size());
    int cumulative = 0;
    for (const int part : out.semanticPartition) {
        cumulative += part;
        out.semanticPrefixSums.push_back(cumulative);
        if (out.filterApplied && cumulative == ctx.discovery21InternalGateOffset) {
            out.semanticHitInternalGateBoundary = true;
        }
    }
    return out;
}

std::vector<int> LegacyRepeatedNameGenerator::call(
    const std::vector<int>& masterList,
    const Integer& rank1,
    int itemCount) const {
    return legacyNameRowWithRepeats(masterList, rank1, itemCount);
}

RepeatedNamePatchDecision RepeatedNamePatchWrapper::repair(
    const std::vector<int>& masterList,
    const Integer& rank1,
    int itemCount,
    const std::vector<int>& badNameIndices) const {
    if (badNameIndices.size() != static_cast<std::size_t>(itemCount)) {
        throw BaseValidationError("candidatus bad PATCH 22 magnitudine falsa est");
    }
    const std::vector<int> correct = partialPermutationNameRowUnrank(
        masterList,
        rank1,
        itemCount);
    const bool equal = badNameIndices == correct;
    return RepeatedNamePatchDecision{
        badNameIndices,
        correct,
        equal ? badNameIndices : correct,
        equal,
        equal,
        true,
        true
    };
}

LegacyMonthLengthMaterializationInspection
LegacyMonthLengthMaterializationAdapter::inspect(int yearLength,
                                                  int monthCount) const {
    LegacyMonthLengthMaterializationInspection out;
    out.yearLength = yearLength;
    out.monthCount = monthCount;
    out.exactFamilyCount = legacyMonthLengthConcreteFamilyCountProof(
        yearLength,
        monthCount);
    out.concreteListIndexCapacity = Integer{
        std::numeric_limits<std::size_t>::max()};
    out.concreteListContractReached = true;
    if (out.exactFamilyCount > out.concreteListIndexCapacity) {
        out.blockedBeforeAllocation = true;
        return out;
    }
    out.concreteEnumerationEntered = true;
    const LegacyMonthLengthWays ways = legacyMaterializeAllMonthLengthWays(
        yearLength,
        monthCount);
    out.materializedItemCount = ways.size();
    out.concreteMaterializationCompleted = true;
    return out;
}

MonthLengthMaterializationPatchDecision
MonthLengthMaterializationPatchWrapper::repair(
    int yearLength,
    int monthCount,
    const LegacyMonthLengthMaterializationInspection& legacyInspection) const {
    if (!legacyInspection.concreteListContractReached) {
        throw BaseValidationError("PATCH 23 API legacy listae concretae prius attingere debet");
    }
    if (legacyInspection.yearLength != yearLength ||
        legacyInspection.monthCount != monthCount) {
        throw BaseValidationError("PATCH 23 fines inspectionis legacy mutare non debet");
    }

    VirtualLegacyList virtualList(yearLength, monthCount);
    const Integer virtualCount = virtualList.count();
    if (virtualCount < 1) {
        throw BaseValidationError("PATCH 23 VirtualLegacyList familiam non vacuam requirit");
    }
    const Integer probeRank = (virtualCount + 1) / 2;
    const std::vector<int> probeItem = virtualList.itemAt1(probeRank);
    return MonthLengthMaterializationPatchDecision{
        virtualCount,
        probeRank,
        probeItem,
        true,
        true,
        virtualCount == legacyInspection.exactFamilyCount,
        true
    };
}

LegacyMonthWeavingInspection LegacyMonthWeavingAdapter::call(
    const std::vector<int>& lengths,
    const Patch11LatchedOrderSauceResult& semanticStructureSauce) const {
    if (lengths.empty()) {
        throw BaseValidationError("adapter texturae mensium longitudines vacuas recusat");
    }
    const int nextBowl = nextBowlThroughOrderAt46Latch(
        semanticStructureSauce.orderAt46Latch,
        4);
    const LegacyAnswerRing stream = answerRingThroughPatchedNextBowl(
        semanticStructureSauce.finalBowls,
        4,
        nextBowl,
        32);
    const std::vector<int> ghost = legacyChooseEachDaySeparately(lengths, stream);

    const std::size_t monthCount = lengths.size();
    std::vector<int> observedCounts(monthCount, 0);
    std::vector<int> remaining = lengths;
    std::vector<bool> opened(monthCount, false);
    std::vector<int> firstOrder;
    std::vector<int> lastOrder;
    firstOrder.reserve(monthCount);
    lastOrder.reserve(monthCount);
    bool idsValid = true;
    for (const int monthId : ghost) {
        if (monthId < 1 || monthId > static_cast<int>(monthCount)) {
            idsValid = false;
            continue;
        }
        const std::size_t index = static_cast<std::size_t>(monthId - 1);
        ++observedCounts[index];
        if (!opened[index]) {
            opened[index] = true;
            firstOrder.push_back(monthId);
        }
        --remaining[index];
        if (remaining[index] == 0) {
            lastOrder.push_back(monthId);
        }
    }

    bool multiplicitiesPreserved = idsValid && ghost.size() == static_cast<std::size_t>(
        std::accumulate(lengths.begin(), lengths.end(), 0));
    for (std::size_t i = 0; i < monthCount; ++i) {
        if (observedCounts[i] != lengths[i] || remaining[i] != 0) {
            multiplicitiesPreserved = false;
        }
    }

    bool firstOrderPreserved = firstOrder.size() == monthCount;
    bool lastOrderPreserved = lastOrder.size() == monthCount;
    for (std::size_t i = 0; i < monthCount; ++i) {
        const int expected = static_cast<int>(i + 1);
        if (!firstOrderPreserved || firstOrder[i] != expected) {
            firstOrderPreserved = false;
        }
        if (!lastOrderPreserved || lastOrder[i] != expected) {
            lastOrderPreserved = false;
        }
    }

    return LegacyMonthWeavingInspection{
        stream,
        ghost,
        multiplicitiesPreserved,
        firstOrderPreserved,
        lastOrderPreserved,
        firstOrderPreserved && lastOrderPreserved
    };
}

MonthWeavingPatchDecision MonthWeavingPatchWrapper::repair(
    const std::vector<int>& lengths,
    const LegacyAnswerRing& answerRing,
    const std::vector<int>& ghost) const {
    const Integer legalFamilyCount = exactLegalMonthWeavingCount(lengths);
    const Integer wantedRank = compatibleMonthWeavingRank(
        answerRing,
        legalFamilyCount);
    const std::vector<int> correct = DPUnrankLegalWeaving(lengths, wantedRank);
    const bool equal = ghost == correct;
    return MonthWeavingPatchDecision{
        legalFamilyCount,
        wantedRank,
        correct,
        equal ? ghost : correct,
        true,
        true,
        equal,
        equal,
        legalMonthWeavingRowInternal(lengths, equal ? ghost : correct),
        true
    };
}

LegacyContiguousMonthDayInspection LegacyContiguousMonthDayAdapter::call(
    const std::vector<int>& semanticWeaving,
    std::size_t targetPosition1) const {
    if (semanticWeaving.empty()) {
        throw BaseValidationError("adapter diei mensis texturam semanticam vacuam recusat");
    }
    if (targetPosition1 < 1 || targetPosition1 > semanticWeaving.size()) {
        throw BaseValidationError("adapter diei mensis positionem target extra fines recusat");
    }
    const int targetMonthId = semanticWeaving[targetPosition1 - 1];
    const auto found = std::find(semanticWeaving.begin(), semanticWeaving.end(), targetMonthId);
    if (found == semanticWeaving.end()) {
        throw BaseValidationError("adapter diei mensis mensem target invenire non potuit");
    }
    const std::size_t firstPosition1 =
        static_cast<std::size_t>(std::distance(semanticWeaving.begin(), found)) + 1;
    const int guess = oldContiguousMonthDayGuess(semanticWeaving, targetPosition1);
    return LegacyContiguousMonthDayInspection{
        targetPosition1,
        targetMonthId,
        firstPosition1,
        guess,
        true
    };
}

MonthDayOccurrencePatchDecision MonthDayOccurrencePatchWrapper::repair(
    const std::vector<int>& semanticWeaving,
    std::size_t targetPosition1,
    int legacyGuessedDayInMonth) const {
    const int correct = countMonthOccurrencesThroughTarget(
        semanticWeaving,
        targetPosition1);
    const bool equal = legacyGuessedDayInMonth == correct;
    return MonthDayOccurrencePatchDecision{
        legacyGuessedDayInMonth,
        correct,
        equal ? legacyGuessedDayInMonth : correct,
        true,
        true,
        equal,
        equal,
        true
    };
}

Patch18YearWalkWorkspace::Patch18YearWalkWorkspace(
    const Integer& calculationDay,
    bool stage56CorrectedSauce)
    : calculationDay_(calculationDay),
      stage56CorrectedSauce_(stage56CorrectedSauce) {
    // PATCH 31: workspace novum manet; testamentum prioris tantum narratur.
    if (accelerationsOn()) {
        const WorkspaceWillKey key{stage56CorrectedSauce_, calculationDay_};
        std::lock_guard<std::mutex> guard(workspaceWillVaultMutex);
        const auto found = workspaceWillVault.find(key);
        if (found != workspaceWillVault.end()) {
            if (!found->second.poisoned &&
                fingerprintAcceptable(
                    found->second.semanticFingerprint,
                    found->second.scarGeneration,
                    31)) {
                scarBump(&PersistentScarMetrics::patch31WorkspaceInherited);
            } else if (!found->second.poisoned) {
                found->second.poisoned = true;
                scarBump(&PersistentScarMetrics::staleOrPoisonedRejected);
            }
        }
    }
}

Patch18YearWalkWorkspace::~Patch18YearWalkWorkspace() {
    if (!accelerationsOn()) {
        return;
    }
    try {
        const WorkspaceWillKey key{stage56CorrectedSauce_, calculationDay_};
        const DeadWorkspaceWill will{
            minGateIndex_,
            maxGateIndex_,
            31,
            persistentSemanticFingerprint(),
            false
        };
        std::lock_guard<std::mutex> guard(workspaceWillVaultMutex);
        if (workspaceWillVault.find(key) == workspaceWillVault.end()) {
            boundedEraseFirst(workspaceWillVault, WORKSPACE_WILL_LIMIT);
        }
        workspaceWillVault[key] = will;
        scarBump(&PersistentScarMetrics::patch31WorkspaceWillWritten);
    } catch (...) {
        // Testamentum non potest mortem workspace in exceptionem alteram convertere.
    }
}

void Patch18YearWalkWorkspace::rememberReverseGate(
    const Integer& index,
    const Integer& day) {
    const auto found = gateDayToIndex_.find(day);
    if (found != gateDayToIndex_.end() && found->second != index) {
        poisonedReverseGateDays_[day] = true;
        scarBump(&PersistentScarMetrics::patch29ReverseGatePoisoned);
        return;
    }
    gateDayToIndex_[day] = index;
}

Integer Patch18YearWalkWorkspace::gateDay(const Integer& index) {
    return ensureGateIndex(index);
}

bool Patch18YearWalkWorkspace::exactGateIndexIfPresent(
    const Integer& day,
    Integer& indexOut) {
    if (day >= FOUNDATION_DAY_OLD) {
        while (gates_.at(maxGateIndex_) < day) {
            ensureGateIndex(maxGateIndex_ + 1);
        }
    } else {
        while (gates_.at(minGateIndex_) > day) {
            ensureGateIndex(minGateIndex_ - 1);
        }
    }

    // PATCH 29: ossuarium inversum interrogatur, sed scan historicus infra manet.
    const auto reverse = gateDayToIndex_.find(day);
    const bool reversePoisoned =
        poisonedReverseGateDays_.find(day) != poisonedReverseGateDays_.end();
    if (reverse != gateDayToIndex_.end() && !reversePoisoned) {
        const auto forward = gates_.find(reverse->second);
        if (forward != gates_.end() && forward->second == day) {
            indexOut = reverse->second;
            scarBump(&PersistentScarMetrics::patch29ReverseGateHit);
            return true;
        }
        poisonedReverseGateDays_[day] = true;
        scarBump(&PersistentScarMetrics::patch29ReverseGatePoisoned);
    }

    scarBump(&PersistentScarMetrics::patch29HistoricalScanFallback);
    if (day >= FOUNDATION_DAY_OLD) {
        for (Integer i = Integer{0}; i <= maxGateIndex_; ++i) {
            if (gates_.at(i) == day) {
                indexOut = i;
                rememberReverseGate(i, day);
                return true;
            }
        }
        return false;
    }
    for (Integer i = Integer{-1}; i >= minGateIndex_; --i) {
        if (gates_.at(i) == day) {
            indexOut = i;
            rememberReverseGate(i, day);
            return true;
        }
    }
    return false;
}

Patch18YearRecord Patch18YearWalkWorkspace::finalYear5000() {
    const Integer low = calculationDay_ - LEGACY_YEAR_MAX;
    const Integer high = calculationDay_ + LEGACY_YEAR_MAX;
    while (gates_.at(minGateIndex_) > low) {
        ensureGateIndex(minGateIndex_ - 1);
    }
    while (gates_.at(maxGateIndex_) < high) {
        ensureGateIndex(maxGateIndex_ + 1);
    }

    struct Candidate {
        Integer openIndex{};
        Integer closeIndex{};
        Integer length{};
        Integer openDay{};
    };
    std::vector<Candidate> legacyCandidates;
    for (Integer open = minGateIndex_; open <= maxGateIndex_; ++open) {
        const Integer openDay = gates_.at(open);
        if (!(openDay < calculationDay_)) {
            continue;
        }
        for (Integer close = open + 6; close <= maxGateIndex_; ++close) {
            const Integer closeDay = gates_.at(close);
            const Integer length = closeDay - openDay;
            if (length > LEGACY_YEAR_MAX) {
                break;
            }
            if (length < 252 || calculationDay_ > closeDay) {
                continue;
            }
            legacyCandidates.push_back(Candidate{open, close, length, openDay});
        }
    }
    if (legacyCandidates.empty()) {
        throw BaseValidationError("familia legacy anni 5000 vacua est");
    }

    std::vector<Candidate> semanticCandidates;
    semanticCandidates.reserve(legacyCandidates.size());
    for (const Candidate& candidate : legacyCandidates) {
        if (candidate.length <= REAL_YEAR_MAX_PATCH) {
            semanticCandidates.push_back(candidate);
        }
    }
    if (semanticCandidates.empty()) {
        throw BaseValidationError("filtrum 5778 omnes candidatos anni 5000 removit");
    }

    std::stable_sort(
        semanticCandidates.begin(),
        semanticCandidates.end(),
        [](const Candidate& a, const Candidate& b) {
            return a.length < b.length;
        });
    std::size_t runBegin = 0;
    while (runBegin < semanticCandidates.size()) {
        std::size_t runEnd = runBegin + 1;
        while (runEnd < semanticCandidates.size() &&
               semanticCandidates[runEnd].length == semanticCandidates[runBegin].length) {
            ++runEnd;
        }
        if (runEnd - runBegin > 1) {
            std::stable_sort(
                semanticCandidates.begin() + static_cast<std::ptrdiff_t>(runBegin),
                semanticCandidates.begin() + static_cast<std::ptrdiff_t>(runEnd),
                [](const Candidate& a, const Candidate& b) {
                    return a.openDay < b.openDay;
                });
        }
        runBegin = runEnd;
    }

    const Patch11LatchedOrderSauceResult sauce = stage56CorrectedSauce_
        ? sauceWithStage56RawBowlSumDetour(
              calculationDay_, calculationDay_).semanticSauce
        : sauceWithScars(calculationDay_, calculationDay_);
    const int nextBowl = nextBowlThroughOrderAt46Latch(sauce.orderAt46Latch, 1);
    const LegacyAnswerRing stream = answerRingThroughPatchedNextBowl(
        sauce.finalBowls, 1, nextBowl, 10);
    const Integer rank = chooseRank(stream, Integer{semanticCandidates.size()});
    const std::size_t chosen = (rank - 1).convert_to<std::size_t>();
    const Candidate& candidate = semanticCandidates.at(chosen);
    const Patch18YearRecord selected{
        Integer{5000},
        candidate.openIndex,
        candidate.closeIndex,
        gates_.at(candidate.openIndex),
        gates_.at(candidate.closeIndex)
    };
    buryYearCheckpoint(selected);
    return selected;
}

Integer Patch18YearWalkWorkspace::chooseRank(
    const LegacyAnswerRing& stream,
    const Integer& familySize) const {
    if (familySize < 1) {
        throw BaseValidationError("familia anni vacua est");
    }
    const LegacyBiasedSelectionAdapter selectionAdapter;
    const Patch13RejectionWrapper rejectionWrapper;
    if (familySize <= M_OLD) {
        return rejectionWrapper.repair(stream, familySize, selectionAdapter).outputRank;
    }
    const Patch14WideDetourWrapper wideWrapper;
    return wideWrapper.repair(stream, familySize, selectionAdapter).outputRank;
}

Integer Patch18YearWalkWorkspace::positiveGateGap(const Integer& n) const {
    if (n < 1) {
        throw BaseValidationError("index portae positivus requiritur");
    }
    const Patch11LatchedOrderSauceResult sauce = stage56CorrectedSauce_
        ? sauceWithStage56RawBowlSumDetour(
              FOUNDATION_DAY_OLD,
              FOUNDATION_DAY_OLD + n).semanticSauce
        : sauceWithOrderAt46Latch(
              FOUNDATION_DAY_OLD,
              FOUNDATION_DAY_OLD + n);
    const int nextBowl = nextBowlThroughOrderAt46Latch(sauce.orderAt46Latch, 1);
    const LegacyAnswerRing stream = answerRingThroughPatchedNextBowl(
        sauce.finalBowls,
        1,
        nextBowl,
        1);
    return 41 + chooseRank(stream, Integer{922});
}

Integer Patch18YearWalkWorkspace::negativeGateGap(const Integer& n) const {
    if (n < 1) {
        throw BaseValidationError("magnitudo portae negativae positiva requiritur");
    }
    const Patch11LatchedOrderSauceResult sauce = stage56CorrectedSauce_
        ? sauceWithStage56RawBowlSumDetour(
              FOUNDATION_DAY_OLD,
              FOUNDATION_DAY_OLD - n).semanticSauce
        : sauceWithOrderAt46Latch(
              FOUNDATION_DAY_OLD,
              FOUNDATION_DAY_OLD - n);
    const int nextBowl = nextBowlThroughOrderAt46Latch(sauce.orderAt46Latch, 1);
    const LegacyAnswerRing stream = answerRingThroughPatchedNextBowl(
        sauce.finalBowls,
        1,
        nextBowl,
        1);
    return 41 + chooseRank(stream, Integer{922});
}

Integer Patch18YearWalkWorkspace::ensureGateIndex(const Integer& index) {
    if (index > maxGateIndex_) {
        Integer n = maxGateIndex_ + 1;
        while (n <= index) {
            const Integer previousDay = gates_.at(n - 1);
            Integer resolvedDay{};
            bool resurrected = false;
            const GateGraveyardKey key{stage56CorrectedSauce_, n};

            if (accelerationsOn()) {
                BuriedGate corpse{};
                bool foundCorpse = false;
                {
                    std::lock_guard<std::mutex> guard(gateGraveyardMutex);
                    const auto found = gateGraveyard.find(key);
                    if (found != gateGraveyard.end()) {
                        scarBump(&PersistentScarMetrics::patch28GateGraveyardHit);
                        if (!found->second.poisoned &&
                            found->second.index == n &&
                            found->second.verifiedThroughLegacyGapPath &&
                            fingerprintAcceptable(
                                found->second.semanticFingerprint,
                                found->second.scarGeneration,
                                28)) {
                            corpse = found->second;
                            foundCorpse = true;
                        } else {
                            found->second.poisoned = true;
                            scarBump(&PersistentScarMetrics::patch28PoisonedGate);
                            scarBump(&PersistentScarMetrics::staleOrPoisonedRejected);
                        }
                    } else {
                        scarBump(&PersistentScarMetrics::patch28GateGraveyardMiss);
                    }
                }
                if (foundCorpse) {
                    const Integer rememberedGap = corpse.day - previousDay;
                    bool corpseValid = rememberedGap >= 42 && rememberedGap <= 963;
                    if (corpseValid && fullHistoricalValidationOn()) {
                        const Integer historicalGap = positiveGateGap(n);
                        scarBump(&PersistentScarMetrics::patch28GateCalculated);
                        corpseValid = historicalGap == rememberedGap;
                    }
                    if (corpseValid) {
                        resolvedDay = corpse.day;
                        resurrected = true;
                        scarBump(&PersistentScarMetrics::patch28GateResurrection);
                    } else {
                        std::lock_guard<std::mutex> guard(gateGraveyardMutex);
                        const auto found = gateGraveyard.find(key);
                        if (found != gateGraveyard.end()) found->second.poisoned = true;
                        scarBump(&PersistentScarMetrics::patch28PoisonedGate);
                        scarBump(&PersistentScarMetrics::staleOrPoisonedRejected);
                    }
                }
            }

            if (!resurrected) {
                const Integer gap = positiveGateGap(n);
                scarBump(&PersistentScarMetrics::patch28GateCalculated);
                resolvedDay = previousDay + gap;
                if (accelerationsOn()) {
                    const BuriedGate burial{
                        n,
                        resolvedDay,
                        28,
                        true,
                        false,
                        persistentSemanticFingerprint()
                    };
                    std::lock_guard<std::mutex> guard(gateGraveyardMutex);
                    const auto existing = gateGraveyard.find(key);
                    if (existing == gateGraveyard.end() || existing->second.poisoned) {
                        boundedEraseFirst(gateGraveyard, GATE_GRAVEYARD_LIMIT);
                        gateGraveyard[key] = burial;
                    }
                }
            }

            gates_[n] = resolvedDay;
            rememberReverseGate(n, resolvedDay);
            maxGateIndex_ = n;
            ++n;
        }
    }
    if (index < minGateIndex_) {
        Integer n = minGateIndex_ - 1;
        while (n >= index) {
            const Integer nextDay = gates_.at(n + 1);
            Integer resolvedDay{};
            bool resurrected = false;
            const GateGraveyardKey key{stage56CorrectedSauce_, n};

            if (accelerationsOn()) {
                BuriedGate corpse{};
                bool foundCorpse = false;
                {
                    std::lock_guard<std::mutex> guard(gateGraveyardMutex);
                    const auto found = gateGraveyard.find(key);
                    if (found != gateGraveyard.end()) {
                        scarBump(&PersistentScarMetrics::patch28GateGraveyardHit);
                        if (!found->second.poisoned &&
                            found->second.index == n &&
                            found->second.verifiedThroughLegacyGapPath &&
                            fingerprintAcceptable(
                                found->second.semanticFingerprint,
                                found->second.scarGeneration,
                                28)) {
                            corpse = found->second;
                            foundCorpse = true;
                        } else {
                            found->second.poisoned = true;
                            scarBump(&PersistentScarMetrics::patch28PoisonedGate);
                            scarBump(&PersistentScarMetrics::staleOrPoisonedRejected);
                        }
                    } else {
                        scarBump(&PersistentScarMetrics::patch28GateGraveyardMiss);
                    }
                }
                if (foundCorpse) {
                    const Integer rememberedGap = nextDay - corpse.day;
                    bool corpseValid = rememberedGap >= 42 && rememberedGap <= 963;
                    if (corpseValid && fullHistoricalValidationOn()) {
                        const Integer historicalGap = negativeGateGap(-n);
                        scarBump(&PersistentScarMetrics::patch28GateCalculated);
                        corpseValid = historicalGap == rememberedGap;
                    }
                    if (corpseValid) {
                        resolvedDay = corpse.day;
                        resurrected = true;
                        scarBump(&PersistentScarMetrics::patch28GateResurrection);
                    } else {
                        std::lock_guard<std::mutex> guard(gateGraveyardMutex);
                        const auto found = gateGraveyard.find(key);
                        if (found != gateGraveyard.end()) found->second.poisoned = true;
                        scarBump(&PersistentScarMetrics::patch28PoisonedGate);
                        scarBump(&PersistentScarMetrics::staleOrPoisonedRejected);
                    }
                }
            }

            if (!resurrected) {
                const Integer gap = negativeGateGap(-n);
                scarBump(&PersistentScarMetrics::patch28GateCalculated);
                resolvedDay = nextDay - gap;
                if (accelerationsOn()) {
                    const BuriedGate burial{
                        n,
                        resolvedDay,
                        28,
                        true,
                        false,
                        persistentSemanticFingerprint()
                    };
                    std::lock_guard<std::mutex> guard(gateGraveyardMutex);
                    const auto existing = gateGraveyard.find(key);
                    if (existing == gateGraveyard.end() || existing->second.poisoned) {
                        boundedEraseFirst(gateGraveyard, GATE_GRAVEYARD_LIMIT);
                        gateGraveyard[key] = burial;
                    }
                }
            }

            gates_[n] = resolvedDay;
            rememberReverseGate(n, resolvedDay);
            minGateIndex_ = n;
            --n;
        }
    }
    return gates_.at(index);
}

Integer Patch18YearWalkWorkspace::exactGateIndex(const Integer& day) {
    if (day >= FOUNDATION_DAY_OLD) {
        while (gates_.at(maxGateIndex_) < day) {
            ensureGateIndex(maxGateIndex_ + 1);
        }
    } else {
        while (gates_.at(minGateIndex_) > day) {
            ensureGateIndex(minGateIndex_ - 1);
        }
    }

    const auto reverse = gateDayToIndex_.find(day);
    const bool reversePoisoned =
        poisonedReverseGateDays_.find(day) != poisonedReverseGateDays_.end();
    if (reverse != gateDayToIndex_.end() && !reversePoisoned) {
        const auto forward = gates_.find(reverse->second);
        if (forward != gates_.end() && forward->second == day) {
            scarBump(&PersistentScarMetrics::patch29ReverseGateHit);
            return reverse->second;
        }
        poisonedReverseGateDays_[day] = true;
        scarBump(&PersistentScarMetrics::patch29ReverseGatePoisoned);
    }

    // Scan historicus consulto non deletur: ossuarium fallibile est.
    scarBump(&PersistentScarMetrics::patch29HistoricalScanFallback);
    if (day >= FOUNDATION_DAY_OLD) {
        for (Integer i = Integer{0}; i <= maxGateIndex_; ++i) {
            if (gates_.at(i) == day) {
                rememberReverseGate(i, day);
                return i;
            }
        }
    } else {
        for (Integer i = Integer{-1}; i >= minGateIndex_; --i) {
            if (gates_.at(i) == day) {
                rememberReverseGate(i, day);
                return i;
            }
        }
    }
    throw BaseValidationError("dies portae exactus in workspace PATCH 18 non inventus est");
}

void Patch18YearWalkWorkspace::buryYearCheckpoint(
    const Patch18YearRecord& year) {
    if (!accelerationsOn()) {
        return;
    }
    const YearCheckpointKey key{
        stage56CorrectedSauce_, calculationDay_, year.number};
    const BuriedYearCheckpoint burial{
        calculationDay_,
        year,
        30,
        stage56CorrectedSauce_,
        false,
        persistentSemanticFingerprint()
    };
    std::lock_guard<std::mutex> guard(yearCheckpointVaultMutex);
    const auto existing = yearCheckpointVault.find(key);
    if (existing == yearCheckpointVault.end() || existing->second.poisoned) {
        boundedEraseFirst(yearCheckpointVault, YEAR_CHECKPOINT_LIMIT);
        yearCheckpointVault[key] = burial;
        scarBump(&PersistentScarMetrics::patch30CheckpointBuried);
    }
}

Patch18YearRecord Patch18YearWalkWorkspace::resurrectNearestYearCheckpoint(
    const Patch18YearRecord& anchorYear,
    const Integer& targetDay) {
    if (!accelerationsOn()) {
        return anchorYear;
    }

    std::vector<std::pair<YearCheckpointKey, BuriedYearCheckpoint>> candidates;
    {
        std::lock_guard<std::mutex> guard(yearCheckpointVaultMutex);
        for (auto& pair : yearCheckpointVault) {
            const YearCheckpointKey& key = pair.first;
            BuriedYearCheckpoint& value = pair.second;
            if (key.stage56 != stage56CorrectedSauce_ ||
                key.calculationDay != calculationDay_) {
                continue;
            }
            if (value.poisoned) {
                continue;
            }
            if (value.calculationDayFingerprint != calculationDay_ ||
                value.stage56 != stage56CorrectedSauce_ ||
                !fingerprintAcceptable(
                    value.semanticFingerprint,
                    value.scarGeneration,
                    30)) {
                value.poisoned = true;
                scarBump(&PersistentScarMetrics::staleOrPoisonedRejected);
                continue;
            }
            candidates.push_back(pair);
        }
    }
    if (candidates.empty()) {
        scarBump(&PersistentScarMetrics::patch30CheckpointMiss);
        return anchorYear;
    }

    auto distanceToTarget = [&targetDay](const Patch18YearRecord& year) -> Integer {
        if (targetDay <= year.openGateDay) return Integer{year.openGateDay - targetDay};
        if (targetDay > year.closeGateDay) return Integer{targetDay - year.closeGateDay};
        return Integer{0};
    };
    std::stable_sort(
        candidates.begin(),
        candidates.end(),
        [&](const auto& a, const auto& b) {
            const Integer da = distanceToTarget(a.second.year);
            const Integer db = distanceToTarget(b.second.year);
            if (da != db) return da < db;
            Integer ay = a.second.year.number - anchorYear.number;
            Integer by = b.second.year.number - anchorYear.number;
            if (ay < 0) ay = -ay;
            if (by < 0) by = -by;
            return ay < by;
        });

    for (const auto& candidate : candidates) {
        const Patch18YearRecord& year = candidate.second.year;
        const Integer verifiedOpen = ensureGateIndex(year.openGateIndex);
        const Integer verifiedClose = ensureGateIndex(year.closeGateIndex);
        if (verifiedOpen == year.openGateDay &&
            verifiedClose == year.closeGateDay &&
            year.closeGateIndex - year.openGateIndex >= 6) {
            scarBump(&PersistentScarMetrics::patch30CheckpointHit);
            Integer avoided = year.number - anchorYear.number;
            if (avoided < 0) avoided = -avoided;
            if (avoided > 0 &&
                avoided <= Integer{std::numeric_limits<std::uint64_t>::max()}) {
                scarBump(
                    &PersistentScarMetrics::patch30YearStepsAvoided,
                    avoided.convert_to<std::uint64_t>());
            }
            return year;
        }
        {
            std::lock_guard<std::mutex> guard(yearCheckpointVaultMutex);
            const auto found = yearCheckpointVault.find(candidate.first);
            if (found != yearCheckpointVault.end()) found->second.poisoned = true;
        }
        scarBump(&PersistentScarMetrics::staleOrPoisonedRejected);
    }

    scarBump(&PersistentScarMetrics::patch30CheckpointMiss);
    return anchorYear;
}

Patch18YearRecord Patch18YearWalkWorkspace::resolveAnchor(
    const LegacyYearAnchor& anchor) {
    if (anchor.firstDay > anchor.lastDay) {
        throw BaseValidationError("fines anchoris inversi sunt");
    }
    const Integer openGateDay = anchor.firstDay - 1;
    const Integer openGateIndex = exactGateIndex(openGateDay);
    const Integer closeGateIndex = exactGateIndex(anchor.lastDay);
    if (closeGateIndex - openGateIndex < 6) {
        throw BaseValidationError("anchor anni minus sex intervalla portarum habet");
    }
    return Patch18YearRecord{
        anchor.number,
        openGateIndex,
        closeGateIndex,
        openGateDay,
        anchor.lastDay
    };
}

Patch18YearRecord Patch18YearWalkWorkspace::patchedNextYear(
    const Patch18YearRecord& knownYear) {
    const Integer openIndex = knownYear.closeGateIndex;
    struct Candidate { Integer closeIndex{}; Integer length{}; };
    std::vector<Candidate> candidates;
    Integer closeIndex = openIndex + 1;
    for (;;) {
        const Integer closeDay = ensureGateIndex(closeIndex);
        const Integer openDay = ensureGateIndex(openIndex);
        const Integer length = closeDay - openDay;
        if (length > REAL_YEAR_MAX_PATCH) {
            break;
        }
        if (closeIndex - openIndex >= 6 && length >= 252) {
            candidates.push_back(Candidate{closeIndex, length});
        }
        ++closeIndex;
    }
    std::stable_sort(candidates.begin(), candidates.end(), [](const Candidate& a, const Candidate& b) {
        return a.length < b.length;
    });
    if (candidates.empty()) {
        throw BaseValidationError("annus sequens PATCH 18 inveniri non potuit");
    }
    const Integer openDay = ensureGateIndex(openIndex);
    const Patch11LatchedOrderSauceResult sauce = stage56CorrectedSauce_
        ? sauceWithStage56RawBowlSumDetour(calculationDay_, openDay).semanticSauce
        : sauceWithOrderAt46Latch(calculationDay_, openDay);
    const int nextBowl = nextBowlThroughOrderAt46Latch(sauce.orderAt46Latch, 1);
    const LegacyAnswerRing stream = answerRingThroughPatchedNextBowl(
        sauce.finalBowls, 1, nextBowl, 11);
    const Integer rank = chooseRank(stream, Integer{candidates.size()});
    const std::size_t chosen = (rank - 1).convert_to<std::size_t>();
    const Integer chosenClose = candidates.at(chosen).closeIndex;
    const Patch18YearRecord result{
        knownYear.number + 1,
        openIndex,
        chosenClose,
        openDay,
        ensureGateIndex(chosenClose)
    };
    if (regularMod(result.number - Integer{5000}, Integer{128}) == 0) {
        buryYearCheckpoint(result);
    }
    return result;
}

Patch18YearRecord Patch18YearWalkWorkspace::patchedPreviousYear(
    const Patch18YearRecord& knownYear) {
    const Integer closeIndex = knownYear.openGateIndex;
    struct Candidate { Integer openIndex{}; Integer length{}; };
    std::vector<Candidate> candidates;
    Integer openIndex = closeIndex - 1;
    for (;;) {
        const Integer openDay = ensureGateIndex(openIndex);
        const Integer closeDay = ensureGateIndex(closeIndex);
        const Integer length = closeDay - openDay;
        if (length > REAL_YEAR_MAX_PATCH) {
            break;
        }
        if (closeIndex - openIndex >= 6 && length >= 252) {
            candidates.push_back(Candidate{openIndex, length});
        }
        --openIndex;
    }
    std::stable_sort(candidates.begin(), candidates.end(), [](const Candidate& a, const Candidate& b) {
        return a.length < b.length;
    });
    if (candidates.empty()) {
        throw BaseValidationError("annus prior PATCH 18 inveniri non potuit");
    }
    const Integer closeDay = ensureGateIndex(closeIndex);
    const Patch11LatchedOrderSauceResult sauce = stage56CorrectedSauce_
        ? sauceWithStage56RawBowlSumDetour(calculationDay_, closeDay).semanticSauce
        : sauceWithOrderAt46Latch(calculationDay_, closeDay);
    const int nextBowl = nextBowlThroughOrderAt46Latch(sauce.orderAt46Latch, 1);
    const LegacyAnswerRing stream = answerRingThroughPatchedNextBowl(
        sauce.finalBowls, 1, nextBowl, 12);
    const Integer rank = chooseRank(stream, Integer{candidates.size()});
    const std::size_t chosen = (rank - 1).convert_to<std::size_t>();
    const Integer chosenOpen = candidates.at(chosen).openIndex;
    const Patch18YearRecord result{
        knownYear.number - 1,
        chosenOpen,
        closeIndex,
        ensureGateIndex(chosenOpen),
        closeDay
    };
    if (regularMod(result.number - Integer{5000}, Integer{128}) == 0) {
        buryYearCheckpoint(result);
    }
    return result;
}

Patch18YearWalkResult Patch18SequentialYearWalkWrapper::repair(
    const Integer& calculationDay,
    const LegacyYearAnchor& anchor,
    const Integer& targetDay) const {
    Patch18YearWalkWorkspace workspace(calculationDay);
    const Patch18YearRecord anchorYear = workspace.resolveAnchor(anchor);
    Patch18YearRecord current =
        workspace.resurrectNearestYearCheckpoint(anchorYear, targetDay);
    std::size_t forwardSteps = 0;
    std::size_t backwardSteps = 0;
    while (targetDay > current.closeGateDay) {
        current = workspace.patchedNextYear(current);
        ++forwardSteps;
    }
    while (targetDay <= current.openGateDay) {
        current = workspace.patchedPreviousYear(current);
        ++backwardSteps;
    }
    if (!(current.openGateDay < targetDay && targetDay <= current.closeGateDay)) {
        throw BaseValidationError("target dies extra annum inventum PATCH 18 est");
    }
    workspace.buryYearCheckpoint(current);
    return Patch18YearWalkResult{anchorYear, current, forwardSteps, backwardSteps};
}

LegacyYearMembershipInspection LegacyYearMembershipAdapter::resolve(
    const Integer& calculationDay,
    const LegacyYearAnchor& anchor,
    const Integer& targetDay) const {
    Patch18YearWalkWorkspace workspace(calculationDay);
    const Patch18YearRecord anchorYear = workspace.resolveAnchor(anchor);
    Patch18YearRecord current = anchorYear;
    std::size_t forwardSteps = 0;
    std::size_t backwardSteps = 0;

    while (targetDay > current.closeGateDay) {
        current = workspace.patchedNextYear(current);
        ++forwardSteps;
    }
    while (targetDay < current.openGateDay) {
        current = workspace.patchedPreviousYear(current);
        ++backwardSteps;
    }

    const bool closedAccepted =
        current.openGateDay <= targetDay && targetDay <= current.closeGateDay;
    if (!closedAccepted) {
        throw BaseValidationError("legacy membership anni target extra [open,close] reliquit");
    }
    return LegacyYearMembershipInspection{
        anchorYear,
        current,
        forwardSteps,
        backwardSteps,
        targetDay == current.openGateDay,
        closedAccepted,
        true
    };
}

Patch26YearMembershipDecision OpeningGateMembershipPatchWrapper::repair(
    const Integer& calculationDay,
    const LegacyYearAnchor& anchor,
    const Integer& targetDay,
    const LegacyYearMembershipInspection& legacyInspection,
    bool stage56CorrectedSauce) const {
    if (!legacyInspection.legacyExecuted) {
        throw BaseValidationError("PATCH 26 cicatricem membership legacy ante correctionem requirit");
    }

    Patch18YearWalkWorkspace workspace(calculationDay, stage56CorrectedSauce);
    const Patch18YearRecord anchorYear = workspace.resolveAnchor(anchor);
    Patch18YearRecord current =
        workspace.resurrectNearestYearCheckpoint(anchorYear, targetDay);
    std::size_t forwardSteps = 0;
    std::size_t backwardSteps = 0;

    while (targetDay > current.closeGateDay) {
        current = workspace.patchedNextYear(current);
        ++forwardSteps;
    }
    while (targetDay <= current.openGateDay) {
        current = workspace.patchedPreviousYear(current);
        ++backwardSteps;
    }

    const bool authoritativeAccepted =
        current.openGateDay < targetDay && targetDay <= current.closeGateDay;
    if (!authoritativeAccepted) {
        throw BaseValidationError("PATCH 26 intervalum auctoritatem (open,close] non obtinuit");
    }
    workspace.buryYearCheckpoint(current);
    const bool equal =
        legacyInspection.outputYear.number == current.number &&
        legacyInspection.outputYear.openGateIndex == current.openGateIndex &&
        legacyInspection.outputYear.closeGateIndex == current.closeGateIndex &&
        legacyInspection.outputYear.openGateDay == current.openGateDay &&
        legacyInspection.outputYear.closeGateDay == current.closeGateDay;

    return Patch26YearMembershipDecision{
        legacyInspection.outputYear,
        current,
        equal ? legacyInspection.outputYear : current,
        forwardSteps,
        backwardSteps,
        true,
        true,
        equal,
        equal,
        authoritativeAccepted,
        true
    };
}

Patch17Year5000TiePreparation Year5000TiePatchWrapper::repair(
    const std::vector<Integer>& gates,
    const LegacyYearCandidateList& legacySorted) const {
    std::size_t runCount = 0;
    std::size_t begin = 0;
    while (begin < legacySorted.size()) {
        std::size_t end = begin + 1;
        while (end < legacySorted.size() &&
               legacySorted[end].length == legacySorted[begin].length) {
            ++end;
        }
        if (end - begin > 1) {
            ++runCount;
        }
        begin = end;
    }
    return Patch17Year5000TiePreparation{
        legacySorted,
        sortEqualLengthRunsByOpeningGate(gates, legacySorted),
        runCount
    };
}

Integer LegacyGateQuestionAdapter::ask(const Integer& magnitude) const {
    return oldGateQuestionDay(magnitude);
}

Integer Patch15NegativeGateQuestionWrapper::repair(
    const Integer& signedStep,
    const Integer& magnitude,
    const Integer& legacyOutput) const {
    if (signedStep < 0) {
        return FOUNDATION_DAY_OLD - magnitude;
    }
    return legacyOutput;
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
    const WideRejectionScarKey scarKey{
        stream.first,
        stream.directionStep,
        N,
        space,
        acceptanceLimit,
        initialWide
    };
    Integer rejectionSteps = 0;
    bool rememberedWideAccepted = false;
    if (accelerationsOn()) {
        WideRejectionCertificate certificate{};
        bool foundCertificate = false;
        {
            std::lock_guard<std::mutex> guard(wideRejectionScarVaultMutex);
            const auto found = wideRejectionScarVault.find(scarKey);
            if (found != wideRejectionScarVault.end()) {
                if (!found->second.poisoned &&
                    fingerprintAcceptable(
                        found->second.semanticFingerprint,
                        found->second.scarGeneration,
                        36)) {
                    certificate = found->second;
                    foundCertificate = true;
                } else if (!found->second.poisoned) {
                    found->second.poisoned = true;
                    scarBump(&PersistentScarMetrics::staleOrPoisonedRejected);
                }
            }
        }
        if (foundCertificate) {
            const Integer replay = 1 + regularMod(
                initialWide - 1 +
                    Integer{stream.directionStep} * certificate.rejectionSteps,
                space);
            bool valid = replay == certificate.acceptedWide &&
                         replay <= acceptanceLimit;
            if (valid && fullHistoricalValidationOn()) {
                Integer historical = initialWide;
                Integer historicalSteps = 0;
                while (historical > acceptanceLimit) {
                    historical = 1 + regularMod(
                        historical - 1 + Integer{stream.directionStep},
                        space);
                    ++historicalSteps;
                }
                valid = historical == certificate.acceptedWide &&
                        historicalSteps == certificate.rejectionSteps;
            }
            if (valid) {
                wide = certificate.acceptedWide;
                rejectionSteps = certificate.rejectionSteps;
                rememberedWideAccepted = true;
                scarBump(&PersistentScarMetrics::patch36WideScarHit);
            } else {
                std::lock_guard<std::mutex> guard(wideRejectionScarVaultMutex);
                const auto found = wideRejectionScarVault.find(scarKey);
                if (found != wideRejectionScarVault.end()) found->second.poisoned = true;
                scarBump(&PersistentScarMetrics::staleOrPoisonedRejected);
            }
        } else {
            scarBump(&PersistentScarMetrics::patch36WideScarMiss);
        }
    }

    if (!rememberedWideAccepted) {
        while (wide > acceptanceLimit) {
            wide = 1 + regularMod(
                wide - 1 + Integer{stream.directionStep},
                space);
            ++rejectionSteps;
        }
        if (accelerationsOn()) {
            const WideRejectionCertificate certificate{
                wide,
                rejectionSteps,
                false,
                36,
                persistentSemanticFingerprint()
            };
            std::lock_guard<std::mutex> guard(wideRejectionScarVaultMutex);
            const auto existing = wideRejectionScarVault.find(scarKey);
            if (existing == wideRejectionScarVault.end() || existing->second.poisoned) {
                boundedEraseFirst(wideRejectionScarVault, REJECTION_SCAR_LIMIT);
                wideRejectionScarVault[scarKey] = certificate;
            }
        }
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

void Patch15GateQuestionHandler::handle(
    BaseMonsterContext& ctx,
    const Discovery15GateQuestionHandler& legacyHandler,
    const LegacyGateQuestionAdapter& adapter,
    const Patch15NegativeGateQuestionWrapper& wrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.phase = "PATCH_15_LEGACY_GATE_QUESTION";
    ctx.branchTrace.push_back("PATCH_15_LEGACY_GATE_QUESTION");
    legacyHandler.handle(ctx, adapter, validator, metrics);
    ctx.patch15LegacyOutputBeforePatch = ctx.legacyGateQuestionOutput;

    ctx.currentHandler = "Patch15GateQuestionHandler";
    ctx.phase = "PATCH_15_SIGNED_GATE_DETOUR";
    ctx.branchTrace.push_back("PATCH_15_SIGNED_GATE_DETOUR");
    ctx.patch15GateQuestionOutput = wrapper.repair(
        ctx.legacyGateQuestionSignedStep,
        ctx.legacyGateQuestionMagnitude,
        ctx.patch15LegacyOutputBeforePatch);
    ctx.patch15Applied = true;
    metrics.bump(ctx, "patch15.gateQuestion.wrapper.calls");

    ctx.phase = "PATCH_15_VALIDATE";
    ctx.branchTrace.push_back("PATCH_15_VALIDATE");
    validator.requirePatch15GateQuestionReady(ctx);

    ctx.phase = "PATCH_15_GATE_QUESTION_READY";
    ctx.status = ctx.legacyGateQuestionSignedStep < 0
        ? "GRADUS_NEGATIVUS_AD_LATUS_ANTERIUS_DIRECTUS"
        : "VIA_LEGACY_NON_NEGATIVA_SERVATA";
    ctx.branchTrace.push_back("PATCH_15_GATE_QUESTION_READY");
    metrics.bump(ctx, "patch15.gateQuestion.ready");
}

void Discovery16LegacyYearCandidateHandler::handle(
    BaseMonsterContext& ctx,
    const LegacyYearCandidateAdapter& adapter,
    const LegacyBiasedSelectionAdapter& selectionAdapter,
    const Patch13RejectionWrapper& rejectionWrapper,
    const Patch14WideDetourWrapper& wideWrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.phase = "DISCOVERY_16_LEGACY_YEAR_CANDIDATES";
    ctx.currentHandler = "Discovery16LegacyYearCandidateHandler";
    ctx.branchTrace.push_back("handler:discovery16:legacy-year-max-5781");

    const LegacyYearCandidatePreparation prepared = adapter.prepareForSelection(
        ctx.legacyYearGates,
        ctx.legacyYearCandidatePairs);
    ctx.legacyYearCandidatesPreSort = prepared.preSort;
    ctx.legacyYearCandidatesSorted = prepared.sorted;
    ctx.legacyYearSelectionFamilySize = Integer{prepared.sorted.size()};
    ctx.legacyYearSelectionRing = answerRingThroughPatchedNextBowl(
        ctx.patch11LatchedOrderSauce.finalBowls,
        ctx.legacyYearQueriedBowlId,
        ctx.patchedNextBowlOutput,
        ctx.legacyYearSeal);
    ctx.legacyYearSelectionCalled = true;
    ctx.legacyYearSelectedOrdinal = adapter.select(
        ctx.legacyYearSelectionRing,
        ctx.legacyYearCandidatesSorted,
        selectionAdapter,
        rejectionWrapper,
        wideWrapper);
    const std::size_t index = (ctx.legacyYearSelectedOrdinal - 1).convert_to<std::size_t>();
    ctx.legacyYearSelectedCandidate = ctx.legacyYearCandidatesSorted[index];
    ctx.legacyYearCandidateReady = true;
    ctx.status = "LEGACY_YEAR_MAX_5781_REACHES_SELECTION";
    metrics.bump(ctx, "discovery16.legacy-year-candidates");
    validator.requireDiscovery16LegacyYearCandidatesReady(ctx);
}

void Patch16YearCandidateCeilingHandler::handle(
    BaseMonsterContext& ctx,
    const YearCandidateCeilingPatchWrapper& wrapper,
    const LegacyYearCandidateAdapter& adapter,
    const LegacyBiasedSelectionAdapter& selectionAdapter,
    const Patch13RejectionWrapper& rejectionWrapper,
    const Patch14WideDetourWrapper& wideWrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.phase = "PATCH_16_YEAR_CEILING";
    ctx.currentHandler = "Patch16YearCandidateCeilingHandler";
    ctx.branchTrace.push_back("handler:patch16:real-year-max-5778");

    const Patch16YearCandidatePreparation prepared = wrapper.prepare(
        ctx.legacyYearGates,
        ctx.legacyYearCandidatePairs);
    ctx.patch16LegacyYearCandidatesPreSort = prepared.legacyPreSort;
    ctx.patch16RejectedBeforeSort = prepared.rejectedBeforeSort;
    ctx.patch16YearCandidatesPreSort = prepared.semanticPreSort;
    ctx.patch16YearCandidatesSorted = prepared.semanticSorted;
    ctx.patch16YearSelectionFamilySize = Integer{prepared.semanticSorted.size()};
    ctx.patch16YearSelectionRing = answerRingThroughPatchedNextBowl(
        ctx.patch11LatchedOrderSauce.finalBowls,
        ctx.legacyYearQueriedBowlId,
        ctx.patchedNextBowlOutput,
        ctx.legacyYearSeal);
    ctx.patch16YearSelectionCalled = true;
    ctx.patch16YearSelectedOrdinal = adapter.select(
        ctx.patch16YearSelectionRing,
        ctx.patch16YearCandidatesSorted,
        selectionAdapter,
        rejectionWrapper,
        wideWrapper);
    const std::size_t index = (ctx.patch16YearSelectedOrdinal - 1).convert_to<std::size_t>();
    ctx.patch16YearSelectedCandidate = ctx.patch16YearCandidatesSorted[index];
    ctx.patch16Applied = true;
    ctx.status = "REAL_YEAR_MAX_5778_FILTERED_BEFORE_SORT_SELECTION";
    metrics.bump(ctx, "patch16.year-ceiling.filtered");
    validator.requirePatch16YearCandidateCeilingReady(ctx);
}

void Discovery17Year5000TieHandler::handle(
    BaseMonsterContext& ctx,
    const LegacyYear5000TieAdapter& adapter,
    const LegacyBiasedSelectionAdapter& selectionAdapter,
    const Patch13RejectionWrapper& rejectionWrapper,
    const Patch14WideDetourWrapper& wideWrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.phase = "DISCOVERY_17_YEAR_5000_TIE";
    ctx.currentHandler = "Discovery17Year5000TieHandler";
    ctx.branchTrace.push_back("handler:discovery17:year5000:length-only-tie");

    const LegacyYear5000TiePreparation prepared = adapter.prepare(
        ctx.legacyYearGates,
        ctx.legacyYearCandidatePairs,
        ctx.calculationDay);
    ctx.discovery17Year5000PreSort = prepared.preSort;
    ctx.discovery17Year5000Sorted = prepared.sorted;
    if (ctx.discovery17Year5000Sorted.empty()) {
        throw BaseValidationError("familia year 5000 legacy vacua est");
    }
    ctx.discovery17Year5000SelectionRing = answerRingThroughPatchedNextBowl(
        ctx.patch11LatchedOrderSauce.finalBowls,
        ctx.legacyYearQueriedBowlId,
        ctx.patchedNextBowlOutput,
        ctx.legacyYearSeal);
    ctx.discovery17Year5000SelectionFamilySize =
        Integer{ctx.discovery17Year5000Sorted.size()};
    ctx.discovery17Year5000SelectionCalled = true;
    ctx.discovery17Year5000SelectedOrdinal = adapter.select(
        ctx.discovery17Year5000SelectionRing,
        ctx.discovery17Year5000Sorted,
        selectionAdapter,
        rejectionWrapper,
        wideWrapper);
    const std::size_t index =
        (ctx.discovery17Year5000SelectedOrdinal - 1).convert_to<std::size_t>();
    ctx.discovery17Year5000SelectedCandidate =
        ctx.discovery17Year5000Sorted[index];
    ctx.discovery17Year5000Ready = true;
    ctx.status = "YEAR_5000_TIE_LENGTH_ONLY_STABLE_ORDER_ACTIVE";
    metrics.bump(ctx, "discovery17.year5000.tie.length-only");
    validator.requireDiscovery17Year5000TieReady(ctx);
}

void Discovery18LegacyYearJumpHandler::handle(
    BaseMonsterContext& ctx,
    const LegacyYearJumpAdapter& adapter,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.currentHandler = "Discovery18LegacyYearJumpHandler";
    ctx.phase = "DISCOVERY_18_LEGACY_JUMP";
    ctx.status = "OLD_JUMP_GUESS_ACTIVE_OUTPUT";
    ctx.branchTrace.push_back("DISCOVERY18:OLD_JUMP_GUESS");
    metrics.bump(ctx, "discovery18.oldJumpGuess.calls");

    ctx.discovery18OldJumpGuess = adapter.guess(
        ctx.discovery18JumpAnchor,
        ctx.discovery18JumpTargetDay);
    ctx.discovery18JumpOutputYearNumber = ctx.discovery18OldJumpGuess;
    ctx.discovery18GuessUsedAsOutput = true;
    ctx.discovery18JumpReady = true;
    validator.requireDiscovery18LegacyYearJumpReady(ctx);
}

void Patch18SequentialYearWalkHandler::handle(
    BaseMonsterContext& ctx,
    const Discovery18LegacyYearJumpHandler& legacyHandler,
    const LegacyYearJumpAdapter& adapter,
    const Patch18SequentialYearWalkWrapper& wrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    legacyHandler.handle(ctx, adapter, validator, metrics);
    const Integer telemetryGuess = ctx.discovery18OldJumpGuess;
    ctx.branchTrace.push_back("PATCH18:OLD_JUMP_GUESS_TELEMETRY_ONLY");
    metrics.bump(ctx, "patch18.oldJumpGuess.telemetry");

    const Patch18YearWalkResult walked = wrapper.repair(
        ctx.patch18CalculationDay,
        ctx.discovery18JumpAnchor,
        ctx.discovery18JumpTargetDay);
    ctx.patch18AnchorYear = walked.anchorYear;
    ctx.patch18OutputYear = walked.outputYear;
    ctx.patch18ForwardSteps = walked.forwardSteps;
    ctx.patch18BackwardSteps = walked.backwardSteps;
    ctx.discovery18OldJumpGuess = telemetryGuess;
    ctx.discovery18JumpOutputYearNumber = walked.outputYear.number;
    ctx.discovery18GuessUsedAsOutput = false;
    ctx.patch18GuessTelemetryOnly = true;
    ctx.patch18Applied = true;
    ctx.currentHandler = "Patch18SequentialYearWalkHandler";
    ctx.phase = "PATCH_18_SEQUENTIAL_YEAR_WALK";
    ctx.status = "OLD_JUMP_GUESS_TELEMETRY_WALK_SEMANTIC_ACTIVE";
    ctx.branchTrace.push_back("PATCH18:SEQUENTIAL_YEAR_WALK_APPLIED");
    metrics.bump(ctx, "patch18.sequential.year.walk");
    validator.requirePatch18YearWalkReady(ctx);
}
void Discovery19YearNumberCacheHandler::handle(BaseMonsterContext& ctx, std::map<Integer, LegacyYearCacheEntry>& cache, const LegacyYearNumberOnlyCacheAdapter& adapter, const BaseValidationManager& validator, const BaseMetricsShell& metrics) const {
    ctx.currentHandler="Discovery19YearNumberCacheHandler"; ctx.phase="DISCOVERY_19_YEAR_NUMBER_CACHE"; ctx.status="YEAR_NUMBER_ONLY_CACHE_KEY_ACTIVE"; ctx.branchTrace.push_back("DISCOVERY19:CACHE_KEY_YEAR_NUMBER_ONLY"); metrics.bump(ctx,"discovery19.year.cache.calls");
    bool hit=false; ctx.discovery19CachedEntry=adapter.getOrPut(cache,ctx.discovery19CacheKeyYearNumber,ctx.discovery19CacheRequest,hit); ctx.discovery19CacheHit=hit; ctx.discovery19CacheOutput=ctx.discovery19CachedEntry.value; ctx.discovery19CacheReady=true; metrics.bump(ctx, hit?"discovery19.year.cache.hit":"discovery19.year.cache.miss"); validator.requireDiscovery19YearCacheReady(ctx);
}
void Patch19YearCacheGuardHandler::handle(BaseMonsterContext& ctx, std::map<Integer, LegacyYearCacheEntry>& cache, const Discovery19YearNumberCacheHandler& legacyHandler, const LegacyYearNumberOnlyCacheAdapter& adapter, const Patch19YearCacheGuardWrapper& wrapper, const BaseValidationManager& validator, const BaseMetricsShell& metrics) const {
    legacyHandler.handle(ctx,cache,adapter,validator,metrics);
    ctx.patch19LegacyCachedEntryBeforePatch=ctx.discovery19CachedEntry; ctx.patch19LegacyOutputBeforePatch=ctx.discovery19CacheOutput; ctx.patch19LegacyCacheHitBeforePatch=ctx.discovery19CacheHit;
    const auto resolved=wrapper.repair(cache,ctx.discovery19CacheKeyYearNumber,ctx.discovery19CacheRequest,ctx.patch19LegacyCachedEntryBeforePatch,ctx.patch19LegacyCacheHitBeforePatch);
    ctx.discovery19CachedEntry=resolved.semanticEntry; ctx.discovery19CacheOutput=resolved.outputValue; ctx.discovery19CacheHit=resolved.semanticHit; ctx.patch19FingerprintMatched=resolved.fingerprintMatched; ctx.patch19OpenGateMatched=resolved.openGateMatched; ctx.patch19CloseGateMatched=resolved.closeGateMatched; ctx.patch19EntryOverwritten=resolved.entryOverwritten; ctx.patch19Applied=true; ctx.currentHandler="Patch19YearCacheGuardHandler"; ctx.phase="PATCH_19_YEAR_CACHE_GUARDS"; ctx.status=ctx.discovery19CacheHit?"YEAR_NUMBER_KEY_GUARDED_HIT":"YEAR_NUMBER_KEY_GUARDED_MISS"; ctx.branchTrace.push_back(ctx.discovery19CacheHit?"PATCH19:GUARDED_HIT":"PATCH19:GUARDED_MISS_OVERWRITE"); metrics.bump(ctx,ctx.discovery19CacheHit?"patch19.year.cache.hit":"patch19.year.cache.miss"); validator.requirePatch19YearCacheReady(ctx);
}
void Discovery20StructureSauceHandler::handle(BaseMonsterContext& ctx, const LegacyStructureSauceAdapter& sauceAdapter, const LegacyStructureSelectorAdapter& selectorAdapter, const BaseValidationManager& validator, const BaseMetricsShell& metrics) const {
    ctx.discovery20LegacyStructureSauce = sauceAdapter.call(ctx.calculationDay, ctx.discovery20OriginalTargetDay);
    ctx.discovery20SelectorToken = selectorAdapter.consume(ctx.discovery20LegacyStructureSauce);
    ctx.discovery20SelectorConsumedLegacySauce = true;
    ctx.discovery20StructureSauceReady = true;
    ctx.currentHandler = "Discovery20StructureSauceHandler";
    ctx.phase = "DISCOVERY_20_STRUCTURE_SAUCE_ORIGINAL_TARGET";
    ctx.status = "OLD_STRUCTURE_SAUCE_ORIGINAL_TARGET_FEEDS_SELECTOR";
    ctx.branchTrace.push_back("DISCOVERY20:OLD_STRUCTURE_SAUCE_TO_SELECTOR");
    metrics.bump(ctx, "discovery20.structure.sauce.calls");
    validator.requireDiscovery20StructureSauceReady(ctx);
}
void Patch20StructureSauceHandler::handle(BaseMonsterContext& ctx, const StructureSaucePatchWrapper& wrapper, const LegacyStructureSelectorAdapter& selectorAdapter, const BaseValidationManager& validator, const BaseMetricsShell& metrics) const {
    const Patch20StructureSauceResult repaired = wrapper.repair(
        ctx.calculationDay,
        ctx.discovery20OriginalTargetDay,
        ctx.discovery20ResolvedYear);
    ctx.discovery20LegacyStructureSauce = repaired.ghost;
    ctx.patch20SemanticStructureSauce = repaired.semanticSauce;
    ctx.patch20GhostExecuted = repaired.ghostExecuted;
    ctx.patch20SemanticRecomputed = repaired.semanticRecomputed;
    ctx.discovery20SelectorToken = selectorAdapter.consume(ctx.patch20SemanticStructureSauce);
    ctx.discovery20SelectorConsumedLegacySauce = false;
    ctx.patch20GhostReachedSelector = false;
    ctx.patch20Applied = true;
    ctx.discovery20StructureSauceReady = true;
    ctx.currentHandler = "Patch20StructureSauceHandler";
    ctx.phase = "PATCH_20_STRUCTURE_SAUCE_YEAR_FIRST_DAY";
    ctx.status = repaired.semanticRecomputed
        ? "OLD_STRUCTURE_SAUCE_GHOST_SEMANTIC_RECOMPUTED"
        : "OLD_STRUCTURE_SAUCE_GHOST_EQUALS_SEMANTIC_INPUT";
    ctx.branchTrace.push_back(repaired.semanticRecomputed
        ? "PATCH20:GHOST_OLD_RECOMPUTE_YEAR_FIRST_DAY"
        : "PATCH20:GHOST_OLD_REUSE_EQUAL_FIRST_DAY");
    metrics.bump(ctx, "patch20.structure.sauce.calls");
    validator.requirePatch20StructureSauceReady(ctx);
}
void Discovery21CutletPartitionHandler::handle(
    BaseMonsterContext& ctx,
    const LegacyPositiveCompositionAdapter& adapter,
    const LegacyBiasedSelectionAdapter& selectionAdapter,
    const Patch13RejectionWrapper& rejectionWrapper,
    const Patch14WideDetourWrapper& wideWrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    const Integer gapBig = ctx.discovery20ResolvedYear.closeGateIndex
                         - ctx.discovery20ResolvedYear.openGateIndex;
    if (gapBig < 1 || gapBig > 1000000) {
        throw BaseValidationError("gapCount partitionis legacy extra fines practicos est");
    }
    ctx.discovery21GapCount = gapBig.convert_to<int>();

    const Integer offsetBig = ctx.discovery21CalculationGateIndex
                            - ctx.discovery20ResolvedYear.openGateIndex;
    ctx.discovery21CalculationDayIsInternalGate =
        ctx.discovery20ResolvedYear.openGateIndex < ctx.discovery21CalculationGateIndex &&
        ctx.discovery21CalculationGateIndex < ctx.discovery20ResolvedYear.closeGateIndex;
    if (ctx.discovery21CalculationDayIsInternalGate) {
        if (offsetBig < 1 || offsetBig > 1000000) {
            throw BaseValidationError("offset portae internae extra fines practicos est");
        }
        ctx.discovery21InternalGateOffset = offsetBig.convert_to<int>();
    } else {
        ctx.discovery21InternalGateOffset = 0;
    }

    ctx.discovery21LegacyFamily = adapter.family(
        ctx.discovery21GapCount,
        ctx.discovery21CutletCount);

    const int queriedBowlId = 2;
    const int nextBowlId = nextBowlThroughOrderAt46Latch(
        ctx.patch20SemanticStructureSauce.orderAt46Latch,
        queriedBowlId);
    const LegacyAnswerRing stream = answerRingThroughPatchedNextBowl(
        ctx.patch20SemanticStructureSauce.finalBowls,
        queriedBowlId,
        nextBowlId,
        21);
    if (ctx.discovery21LegacyFamily.count <= M_OLD) {
        ctx.discovery21SelectionRank = rejectionWrapper.repair(
            stream,
            ctx.discovery21LegacyFamily.count,
            selectionAdapter).outputRank;
    } else {
        ctx.discovery21SelectionRank = wideWrapper.repair(
            stream,
            ctx.discovery21LegacyFamily.count,
            selectionAdapter).outputRank;
    }

    ctx.discovery21LegacyPartition = adapter.unrank(
        ctx.discovery21LegacyFamily,
        ctx.discovery21SelectionRank);
    ctx.discovery21LegacyPrefixSums.clear();
    ctx.discovery21LegacyPrefixSums.reserve(ctx.discovery21LegacyPartition.size());
    int cumulative = 0;
    ctx.discovery21LegacyHitInternalGateBoundary = false;
    for (const int part : ctx.discovery21LegacyPartition) {
        cumulative += part;
        ctx.discovery21LegacyPrefixSums.push_back(cumulative);
        if (ctx.discovery21CalculationDayIsInternalGate &&
            cumulative == ctx.discovery21InternalGateOffset) {
            ctx.discovery21LegacyHitInternalGateBoundary = true;
        }
    }
    ctx.discovery21LegacyIgnoredInternalGate =
        ctx.discovery21CalculationDayIsInternalGate;
    ctx.discovery21CutletPartitionReady = true;
    ctx.currentHandler = "Discovery21CutletPartitionHandler";
    ctx.phase = "DISCOVERY_21_CUTLET_PARTITION_ALL_POSITIVE";
    ctx.status = ctx.discovery21CalculationDayIsInternalGate
        ? "LEGACY_POSITIVE_COMPOSITIONS_IGNORE_INTERNAL_GATE"
        : "LEGACY_POSITIVE_COMPOSITIONS_NO_INTERNAL_GATE";
    ctx.branchTrace.push_back(ctx.discovery21CalculationDayIsInternalGate
        ? "DISCOVERY21:INTERNAL_GATE_OBSERVED_BUT_IGNORED"
        : "DISCOVERY21:NO_INTERNAL_GATE_ALL_POSITIVE");
    metrics.bump(ctx, "discovery21.cutlet.partition.calls");
    validator.requireDiscovery21CutletPartitionReady(ctx);
}

void Patch21CutletPartitionHandler::handle(
    BaseMonsterContext& ctx,
    const Discovery21CutletPartitionHandler& legacyHandler,
    const LegacyPositiveCompositionAdapter& adapter,
    const CutletPartitionPatchWrapper& wrapper,
    const LegacyBiasedSelectionAdapter& selectionAdapter,
    const Patch13RejectionWrapper& rejectionWrapper,
    const Patch14WideDetourWrapper& wideWrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    legacyHandler.handle(
        ctx,
        adapter,
        selectionAdapter,
        rejectionWrapper,
        wideWrapper,
        validator,
        metrics);
    ctx.patch21LegacyExecuted = true;

    const int queriedBowlId = 2;
    const int nextBowlId = nextBowlThroughOrderAt46Latch(
        ctx.patch20SemanticStructureSauce.orderAt46Latch,
        queriedBowlId);
    const LegacyAnswerRing stream = answerRingThroughPatchedNextBowl(
        ctx.patch20SemanticStructureSauce.finalBowls,
        queriedBowlId,
        nextBowlId,
        21);
    const Patch21CutletPartitionResult repaired = wrapper.repair(
        ctx,
        stream,
        selectionAdapter,
        rejectionWrapper,
        wideWrapper);

    ctx.patch21SemanticFamily = repaired.semanticFamily;
    ctx.patch21SemanticSelectionRank = repaired.semanticSelectionRank;
    ctx.patch21SemanticPartition = repaired.semanticPartition;
    ctx.patch21SemanticPrefixSums = repaired.semanticPrefixSums;
    ctx.patch21SemanticHitInternalGateBoundary = repaired.semanticHitInternalGateBoundary;
    ctx.patch21FilterApplied = repaired.filterApplied;
    ctx.patch21LegacyPartitionReused = repaired.legacyPartitionReused;
    ctx.patch21Applied = true;
    ctx.currentHandler = "Patch21CutletPartitionHandler";
    ctx.phase = "PATCH_21_CUTLET_PARTITION_INTERNAL_GATE_FILTER";
    ctx.status = ctx.patch21FilterApplied
        ? "FILTERED_LEGACY_FAMILY_HITS_INTERNAL_GATE"
        : "NO_INTERNAL_GATE_LEGACY_PARTITION_REUSED";
    ctx.branchTrace.push_back(ctx.patch21FilterApplied
        ? "PATCH21:FILTERED_LEGACY_SUBSEQUENCE"
        : "PATCH21:NO_INTERNAL_GATE_PASS_THROUGH");
    metrics.bump(ctx, "patch21.cutlet.partition.calls");
    validator.requirePatch21CutletPartitionReady(ctx);
}

void Discovery22RepeatedCutletNameHandler::handle(
    BaseMonsterContext& ctx,
    const LegacyRepeatedNameGenerator& generator,
    const LegacyBiasedSelectionAdapter& selectionAdapter,
    const Patch13RejectionWrapper& rejectionWrapper,
    const Patch14WideDetourWrapper& wideWrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    if (!ctx.discovery22Patch20Prepared || !ctx.discovery22Patch21Prepared) {
        throw BaseValidationError("DISCOVERY 22 sine PATCH 20 et PATCH 21 currere non potest");
    }
    ctx.discovery22MasterNameCount = 17;
    ctx.discovery22SelectionSpaceCount = legacyCutletNameSelectionSpaceCount(
        ctx.discovery22MasterNameCount,
        ctx.discovery22CutletCount);

    const int queriedBowlId = 5;
    const int nextBowlId = nextBowlThroughOrderAt46Latch(
        ctx.patch20SemanticStructureSauce.orderAt46Latch,
        queriedBowlId);
    ctx.discovery22SelectionRing = answerRingThroughPatchedNextBowl(
        ctx.patch20SemanticStructureSauce.finalBowls,
        queriedBowlId,
        nextBowlId,
        22);

    if (ctx.discovery22SelectionSpaceCount <= M_OLD) {
        ctx.discovery22SelectionRank = rejectionWrapper.repair(
            ctx.discovery22SelectionRing,
            ctx.discovery22SelectionSpaceCount,
            selectionAdapter).outputRank;
    } else {
        ctx.discovery22SelectionRank = wideWrapper.repair(
            ctx.discovery22SelectionRing,
            ctx.discovery22SelectionSpaceCount,
            selectionAdapter).outputRank;
    }

    std::vector<int> masterList;
    masterList.reserve(static_cast<std::size_t>(ctx.discovery22MasterNameCount));
    for (int canonicalIndex = 1;
         canonicalIndex <= ctx.discovery22MasterNameCount;
         ++canonicalIndex) {
        masterList.push_back(canonicalIndex);
    }
    ctx.discovery22LegacyNameIndices = generator.call(
        masterList,
        ctx.discovery22SelectionRank,
        ctx.discovery22CutletCount);
    ctx.discovery22LegacyContainsRepeat = legacyNameRowContainsRepeat(
        ctx.discovery22LegacyNameIndices);
    ctx.discovery22RepeatedNamesReady = true;
    ctx.currentHandler = "Discovery22RepeatedCutletNameHandler";
    ctx.phase = "DISCOVERY_22_REPEATED_CUTLET_NAMES";
    ctx.status = ctx.discovery22LegacyContainsRepeat
        ? "LEGACY_NAME_ROW_CONTAINS_REPEAT"
        : "LEGACY_NAME_ROW_HAS_NO_REPEAT_FOR_THIS_INPUT";
    ctx.branchTrace.push_back(ctx.discovery22LegacyContainsRepeat
        ? "DISCOVERY22:REPEATED_CANONICAL_INDEX"
        : "DISCOVERY22:NO_REPEAT_THIS_INPUT");
    metrics.bump(ctx, "discovery22.cutlet.names.calls");
    validator.requireDiscovery22RepeatedNamesReady(ctx);
}

void Patch22RepeatedCutletNameHandler::handle(
    BaseMonsterContext& ctx,
    const Discovery22RepeatedCutletNameHandler& legacyHandler,
    const LegacyRepeatedNameGenerator& generator,
    const RepeatedNamePatchWrapper& wrapper,
    const LegacyBiasedSelectionAdapter& selectionAdapter,
    const Patch13RejectionWrapper& rejectionWrapper,
    const Patch14WideDetourWrapper& wideWrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    legacyHandler.handle(
        ctx,
        generator,
        selectionAdapter,
        rejectionWrapper,
        wideWrapper,
        validator,
        metrics);
    ctx.patch22LegacyExecuted = ctx.discovery22RepeatedNamesReady;

    std::vector<int> masterList;
    masterList.reserve(static_cast<std::size_t>(ctx.discovery22MasterNameCount));
    for (int canonicalIndex = 1;
         canonicalIndex <= ctx.discovery22MasterNameCount;
         ++canonicalIndex) {
        masterList.push_back(canonicalIndex);
    }
    const RepeatedNamePatchDecision decision = wrapper.repair(
        masterList,
        ctx.discovery22SelectionRank,
        ctx.discovery22CutletCount,
        ctx.discovery22LegacyNameIndices);
    ctx.patch22CorrectNameIndices = decision.correctNameIndices;
    ctx.patch22SemanticNameIndices = decision.outputNameIndices;
    ctx.patch22CorrectComputed = decision.correctComputed;
    ctx.patch22BadEqualsCorrect = decision.badEqualsCorrect;
    ctx.patch22LegacyReturned = decision.legacyReturned;
    ctx.patch22Applied = decision.patchApplied;
    ctx.patch22RepeatedNamesReady = true;
    ctx.currentHandler = "Patch22RepeatedCutletNameHandler";
    ctx.phase = "PATCH_22_DISTINCT_CUTLET_NAMES";
    ctx.status = ctx.patch22BadEqualsCorrect
        ? "BAD_EQUALS_CORRECT_LEGACY_RETURNED"
        : "BAD_DIFFERS_CORRECT_PARTIAL_PERMUTATION_RETURNED";
    ctx.branchTrace.push_back(ctx.patch22BadEqualsCorrect
        ? "PATCH22:BAD_EQUALS_CORRECT"
        : "PATCH22:CORRECT_REPLACES_BAD");
    metrics.bump(ctx, "patch22.cutlet.names.calls");
    validator.requirePatch22RepeatedNamesReady(ctx);
}

void Discovery23MonthLengthMaterializationHandler::handle(
    BaseMonsterContext& ctx,
    const LegacyMonthLengthMaterializationAdapter& adapter,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    const LegacyMonthLengthMaterializationInspection inspection = adapter.inspect(
        ctx.discovery23YearLength,
        ctx.discovery23MonthCount);
    ctx.discovery23ExactFamilyCount = inspection.exactFamilyCount;
    ctx.discovery23ConcreteListIndexCapacity = inspection.concreteListIndexCapacity;
    ctx.discovery23LegacyConcreteListContractReached =
        inspection.concreteListContractReached;
    ctx.discovery23LegacyConcreteEnumerationEntered =
        inspection.concreteEnumerationEntered;
    ctx.discovery23LegacyConcreteMaterializationCompleted =
        inspection.concreteMaterializationCompleted;
    ctx.discovery23BlockedBeforeAllocation = inspection.blockedBeforeAllocation;
    ctx.discovery23MaterializedItemCount = inspection.materializedItemCount;
    ctx.discovery23MonthLengthMaterializationReady = true;
    ctx.currentHandler = "Discovery23MonthLengthMaterializationHandler";
    ctx.phase = "DISCOVERY_23_MONTH_LENGTH_MATERIALIZATION";
    ctx.status = ctx.discovery23BlockedBeforeAllocation
        ? "LEGACY_CONCRETE_LIST_CANNOT_BE_MATERIALIZED"
        : "LEGACY_CONCRETE_LIST_MATERIALIZED";
    ctx.branchTrace.push_back(ctx.discovery23BlockedBeforeAllocation
        ? "DISCOVERY23:CONCRETE_LIST_CARDINALITY_EXCEEDS_PLATFORM"
        : "DISCOVERY23:CONCRETE_LIST_ENUMERATED");
    metrics.bump(ctx, "discovery23.month.length.materialization.calls");
    validator.requireDiscovery23MonthLengthMaterializationReady(ctx);
}

void Patch23MonthLengthMaterializationHandler::handle(
    BaseMonsterContext& ctx,
    const Discovery23MonthLengthMaterializationHandler& legacyHandler,
    const LegacyMonthLengthMaterializationAdapter& adapter,
    const MonthLengthMaterializationPatchWrapper& wrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    legacyHandler.handle(ctx, adapter, validator, metrics);

    LegacyMonthLengthMaterializationInspection legacyInspection;
    legacyInspection.yearLength = ctx.discovery23YearLength;
    legacyInspection.monthCount = ctx.discovery23MonthCount;
    legacyInspection.exactFamilyCount = ctx.discovery23ExactFamilyCount;
    legacyInspection.concreteListIndexCapacity =
        ctx.discovery23ConcreteListIndexCapacity;
    legacyInspection.concreteListContractReached =
        ctx.discovery23LegacyConcreteListContractReached;
    legacyInspection.concreteEnumerationEntered =
        ctx.discovery23LegacyConcreteEnumerationEntered;
    legacyInspection.concreteMaterializationCompleted =
        ctx.discovery23LegacyConcreteMaterializationCompleted;
    legacyInspection.blockedBeforeAllocation =
        ctx.discovery23BlockedBeforeAllocation;
    legacyInspection.materializedItemCount =
        ctx.discovery23MaterializedItemCount;

    const MonthLengthMaterializationPatchDecision decision = wrapper.repair(
        ctx.discovery23YearLength,
        ctx.discovery23MonthCount,
        legacyInspection);
    ctx.patch23VirtualCount = decision.virtualCount;
    ctx.patch23VirtualProbeRank = decision.probeRank;
    ctx.patch23VirtualProbeItem = decision.probeItem;
    ctx.patch23LegacyExecuted = decision.legacyExecuted;
    ctx.patch23VirtualBackendUsed = decision.virtualBackendUsed;
    ctx.patch23CountMatchesLegacyProof = decision.countMatchesLegacyProof;
    ctx.patch23Applied = decision.patchApplied;
    ctx.patch23MonthLengthMaterializationReady = true;
    ctx.currentHandler = "Patch23MonthLengthMaterializationHandler";
    ctx.phase = "PATCH_23_VIRTUAL_MONTH_LENGTH_LIST";
    ctx.status = "VIRTUAL_LEGACY_LIST_ACTIVE";
    ctx.branchTrace.push_back("PATCH23:VIRTUAL_LEGACY_LIST_COUNT_ITEMAT1");
    metrics.bump(ctx, "patch23.month.length.virtual.list.calls");
    validator.requirePatch23MonthLengthMaterializationReady(ctx);
}

void Discovery24MonthWeavingHandler::handle(
    BaseMonsterContext& ctx,
    const LegacyMonthWeavingAdapter& adapter,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    const LegacyMonthWeavingInspection inspection = adapter.call(
        ctx.discovery24MonthLengths,
        ctx.discovery24SemanticStructureSauce);
    ctx.discovery24AnswerRing = inspection.answerRing;
    ctx.discovery24LegacyGhost = inspection.ghost;
    ctx.discovery24SemanticWeaving = inspection.ghost;
    ctx.discovery24MultiplicitiesPreserved = inspection.multiplicitiesPreserved;
    ctx.discovery24FirstOccurrenceOrderPreserved =
        inspection.firstOccurrenceOrderPreserved;
    ctx.discovery24LastOccurrenceOrderPreserved =
        inspection.lastOccurrenceOrderPreserved;
    ctx.discovery24WholeWeavingOrderLegal = inspection.wholeWeavingOrderLegal;
    ctx.discovery24LegacyUsedAsSemanticOutput = true;
    ctx.discovery24MonthWeavingReady = true;
    ctx.currentHandler = "Discovery24MonthWeavingHandler";
    ctx.phase = "DISCOVERY_24_MONTH_WEAVING_DAY_BY_DAY";
    ctx.status = ctx.discovery24WholeWeavingOrderLegal
        ? "LEGACY_DAY_BY_DAY_WEAVING_ACCIDENTALLY_ORDERED"
        : "LEGACY_DAY_BY_DAY_WEAVING_IGNORES_WHOLE_ORDER";
    ctx.branchTrace.push_back("DISCOVERY24:LEGACY_CHOOSE_EACH_DAY_SEPARATELY_ACTIVE");
    metrics.bump(ctx, "discovery24.month.weaving.legacy.calls");
    validator.requireDiscovery24MonthWeavingReady(ctx);
}

void Patch24MonthWeavingHandler::handle(
    BaseMonsterContext& ctx,
    const Discovery24MonthWeavingHandler& legacyHandler,
    const LegacyMonthWeavingAdapter& adapter,
    const MonthWeavingPatchWrapper& wrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    legacyHandler.handle(ctx, adapter, validator, metrics);

    const MonthWeavingPatchDecision decision = wrapper.repair(
        ctx.discovery24MonthLengths,
        ctx.discovery24AnswerRing,
        ctx.discovery24LegacyGhost);
    ctx.patch24LegalFamilyCount = decision.legalFamilyCount;
    ctx.patch24WantedRank = decision.wantedRank;
    ctx.patch24CorrectWeaving = decision.correctWeaving;
    ctx.discovery24SemanticWeaving = decision.outputWeaving;
    ctx.patch24LegacyExecuted = decision.legacyExecuted;
    ctx.patch24CorrectComputed = decision.correctComputed;
    ctx.patch24GhostEqualsCorrect = decision.ghostEqualsCorrect;
    ctx.patch24LegacyReturned = decision.legacyReturned;
    ctx.patch24SemanticWholeWeavingOrderLegal =
        decision.semanticWholeWeavingOrderLegal;
    ctx.patch24Applied = decision.patchApplied;
    ctx.patch24MonthWeavingReady = true;
    ctx.currentHandler = "Patch24MonthWeavingHandler";
    ctx.phase = "PATCH_24_WHOLE_MONTH_WEAVING_DP";
    ctx.status = ctx.patch24GhostEqualsCorrect
        ? "GHOST_EQUALS_CORRECT_LEGACY_RETURNED"
        : "GHOST_DIFFERS_CORRECT_DP_WEAVING_RETURNED";
    ctx.branchTrace.push_back(ctx.patch24GhostEqualsCorrect
        ? "PATCH24:GHOST_EQUALS_CORRECT"
        : "PATCH24:CORRECT_REPLACES_GHOST");
    metrics.bump(ctx, "patch24.month.weaving.calls");
    validator.requirePatch24MonthWeavingReady(ctx);
}

void Discovery25ContiguousMonthDayHandler::handle(
    BaseMonsterContext& ctx,
    const LegacyContiguousMonthDayAdapter& adapter,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    validator.requirePatch24MonthWeavingReady(ctx);
    const LegacyContiguousMonthDayInspection inspection = adapter.call(
        ctx.discovery24SemanticWeaving,
        ctx.discovery25TargetPosition1);
    ctx.discovery25TargetMonthId = inspection.targetMonthId;
    ctx.discovery25FirstOccurrencePosition1 = inspection.firstOccurrencePosition1;
    ctx.discovery25LegacyGuessedDayInMonth = inspection.guessedDayInMonth;
    ctx.discovery25SemanticDayInMonth = inspection.guessedDayInMonth;
    ctx.discovery25Patch24Prepared = ctx.patch24Applied;
    ctx.discovery25LegacyExecuted = inspection.legacyExecuted;
    ctx.discovery25LegacyUsedAsSemanticOutput = true;
    ctx.discovery25ContiguousMonthDayReady = true;
    ctx.currentHandler = "Discovery25ContiguousMonthDayHandler";
    ctx.phase = "DISCOVERY_25_LEGACY_CONTIGUOUS_MONTH_DAY";
    ctx.status = "EXPECTED_RED";
    ctx.branchTrace.push_back("HANDLER:DISCOVERY25_CONTIGUOUS_MONTH_DAY");
    metrics.bump(ctx, "discovery25.contiguous.month.day.ready");
    validator.requireDiscovery25ContiguousMonthDayReady(ctx);
}

void Patch25ContiguousMonthDayHandler::handle(
    BaseMonsterContext& ctx,
    const Discovery25ContiguousMonthDayHandler& legacyHandler,
    const LegacyContiguousMonthDayAdapter& adapter,
    const MonthDayOccurrencePatchWrapper& wrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    legacyHandler.handle(ctx, adapter, validator, metrics);
    const MonthDayOccurrencePatchDecision decision = wrapper.repair(
        ctx.discovery24SemanticWeaving,
        ctx.discovery25TargetPosition1,
        ctx.discovery25LegacyGuessedDayInMonth);
    ctx.patch25CorrectDayInMonth = decision.correctDayInMonth;
    ctx.patch25LegacyExecuted = decision.legacyExecuted && ctx.discovery25LegacyExecuted;
    ctx.patch25CorrectComputed = decision.correctComputed;
    ctx.patch25LegacyEqualsCorrect = decision.legacyEqualsCorrect;
    ctx.patch25LegacyReturned = decision.legacyReturned;
    ctx.patch25Applied = decision.patchApplied;
    ctx.discovery25SemanticDayInMonth = decision.outputDayInMonth;
    ctx.patch25ContiguousMonthDayReady = true;
    ctx.currentHandler = "Patch25ContiguousMonthDayHandler";
    ctx.phase = "PATCH_25_MONTH_DAY_OCCURRENCE_COUNT";
    ctx.status = ctx.patch25LegacyEqualsCorrect
        ? "GHOST_EQUALS_CORRECT_LEGACY_RETURNED"
        : "GHOST_DIFFERS_CORRECT_OCCURRENCE_COUNT_RETURNED";
    ctx.branchTrace.push_back(ctx.patch25LegacyEqualsCorrect
        ? "PATCH25:GHOST_EQUALS_CORRECT"
        : "PATCH25:CORRECT_REPLACES_GHOST");
    metrics.bump(ctx, "patch25.month.day.calls");
    validator.requirePatch25ContiguousMonthDayReady(ctx);
}

void Discovery26OpeningGateYearMembershipHandler::handle(
    BaseMonsterContext& ctx,
    const LegacyYearMembershipAdapter& adapter,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    const LegacyYearMembershipInspection inspection = adapter.resolve(
        ctx.calculationDay,
        ctx.discovery26MembershipAnchor,
        ctx.discovery26MembershipTargetDay);
    ctx.discovery26MembershipAnchorYear = inspection.anchorYear;
    ctx.discovery26MembershipOutputYear = inspection.outputYear;
    ctx.discovery26MembershipForwardSteps = inspection.forwardSteps;
    ctx.discovery26MembershipBackwardSteps = inspection.backwardSteps;
    ctx.discovery26TargetAtOpeningGate = inspection.targetAtOpeningGate;
    ctx.discovery26LegacyClosedIntervalAccepted = inspection.legacyClosedIntervalAccepted;
    ctx.discovery26LegacyExecuted = inspection.legacyExecuted;
    ctx.discovery26LegacyUsedAsSemanticOutput = true;
    ctx.discovery26YearMembershipReady = true;
    ctx.currentHandler = "Discovery26OpeningGateYearMembershipHandler";
    ctx.phase = "DISCOVERY_26_LEGACY_CLOSED_OPENING_YEAR_MEMBERSHIP";
    ctx.status = "EXPECTED_RED";
    ctx.branchTrace.push_back("DISCOVERY26:LEGACY_INTERVAL_OPEN_CLOSE_BOTH_CLOSED");
    metrics.bump(ctx, "discovery26.year.membership.legacy.calls");
    validator.requireDiscovery26YearMembershipReady(ctx);
}

void Patch26OpeningGateYearMembershipHandler::handle(
    BaseMonsterContext& ctx,
    const Discovery26OpeningGateYearMembershipHandler& legacyHandler,
    const LegacyYearMembershipAdapter& adapter,
    const OpeningGateMembershipPatchWrapper& wrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    legacyHandler.handle(ctx, adapter, validator, metrics);

    LegacyYearMembershipInspection legacyInspection;
    legacyInspection.anchorYear = ctx.discovery26MembershipAnchorYear;
    legacyInspection.outputYear = ctx.discovery26MembershipOutputYear;
    legacyInspection.forwardSteps = ctx.discovery26MembershipForwardSteps;
    legacyInspection.backwardSteps = ctx.discovery26MembershipBackwardSteps;
    legacyInspection.targetAtOpeningGate = ctx.discovery26TargetAtOpeningGate;
    legacyInspection.legacyClosedIntervalAccepted =
        ctx.discovery26LegacyClosedIntervalAccepted;
    legacyInspection.legacyExecuted = ctx.discovery26LegacyExecuted;

    const Patch26YearMembershipDecision decision = wrapper.repair(
        ctx.calculationDay,
        ctx.discovery26MembershipAnchor,
        ctx.discovery26MembershipTargetDay,
        legacyInspection);
    ctx.patch26CorrectOutputYear = decision.correctOutputYear;
    ctx.patch26CorrectForwardSteps = decision.correctForwardSteps;
    ctx.patch26CorrectBackwardSteps = decision.correctBackwardSteps;
    ctx.patch26LegacyExecuted = decision.legacyExecuted && ctx.discovery26LegacyExecuted;
    ctx.patch26CorrectComputed = decision.correctComputed;
    ctx.patch26LegacyEqualsCorrect = decision.legacyEqualsCorrect;
    ctx.patch26LegacyReturned = decision.legacyReturned;
    ctx.patch26AuthoritativeIntervalAccepted = decision.authoritativeIntervalAccepted;
    ctx.patch26Applied = decision.patchApplied;
    ctx.patch26YearMembershipReady = true;
    ctx.currentHandler = "Patch26OpeningGateYearMembershipHandler";
    ctx.phase = "PATCH_26_AUTHORITATIVE_OPENING_GATE_YEAR_MEMBERSHIP";
    ctx.status = ctx.patch26LegacyEqualsCorrect
        ? "GHOST_EQUALS_CORRECT_LEGACY_RETURNED"
        : "GHOST_DIFFERS_CORRECT_YEAR_RETURNED";
    ctx.branchTrace.push_back(ctx.patch26LegacyEqualsCorrect
        ? "PATCH26:GHOST_EQUALS_CORRECT"
        : "PATCH26:CORRECT_REPLACES_GHOST");
    metrics.bump(ctx, "patch26.year.membership.calls");
    validator.requirePatch26YearMembershipReady(ctx);
}

void Patch17Year5000TieHandler::handle(
    BaseMonsterContext& ctx,
    const Discovery17Year5000TieHandler& legacyHandler,
    const LegacyYear5000TieAdapter& adapter,
    const Year5000TiePatchWrapper& wrapper,
    const LegacyBiasedSelectionAdapter& selectionAdapter,
    const Patch13RejectionWrapper& rejectionWrapper,
    const Patch14WideDetourWrapper& wideWrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    legacyHandler.handle(
        ctx,
        adapter,
        selectionAdapter,
        rejectionWrapper,
        wideWrapper,
        validator,
        metrics);

    ctx.patch17LegacyYear5000Sorted = ctx.discovery17Year5000Sorted;
    ctx.patch17LegacyYear5000SelectedOrdinal = ctx.discovery17Year5000SelectedOrdinal;
    ctx.patch17LegacyYear5000SelectedCandidate = ctx.discovery17Year5000SelectedCandidate;

    const Patch17Year5000TiePreparation prepared = wrapper.repair(
        ctx.legacyYearGates,
        ctx.patch17LegacyYear5000Sorted);
    ctx.patch17Year5000Sorted = prepared.patchedSorted;
    ctx.patch17EqualLengthRunCount = prepared.equalLengthRunCount;
    ctx.patch17Year5000SelectedOrdinal = adapter.select(
        ctx.discovery17Year5000SelectionRing,
        ctx.patch17Year5000Sorted,
        selectionAdapter,
        rejectionWrapper,
        wideWrapper);
    const std::size_t index =
        (ctx.patch17Year5000SelectedOrdinal - 1).convert_to<std::size_t>();
    ctx.patch17Year5000SelectedCandidate = ctx.patch17Year5000Sorted[index];
    ctx.patch17Applied = true;
    ctx.phase = "PATCH_17_YEAR_5000_TIE";
    ctx.status = "YEAR_5000_EQUAL_LENGTH_RUNS_SORTED_BY_OPENING_GATE";
    ctx.currentHandler = "Patch17Year5000TieHandler";
    ctx.branchTrace.push_back("handler:patch17:year5000:equal-length-runs-opening-gate");
    metrics.bump(ctx, "patch17.year5000.tie.opening-gate");
    validator.requirePatch17Year5000TieReady(ctx);
}

void BaseDispatcher::dispatchPatchedGateQuestion(
    BaseMonsterContext& ctx,
    const Patch15GateQuestionHandler& handler,
    const Discovery15GateQuestionHandler& legacyHandler,
    const LegacyGateQuestionAdapter& adapter,
    const Patch15NegativeGateQuestionWrapper& wrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.phase = "PATCH_15_DISPATCH";
    ctx.status = "ENTERED";
    ctx.currentHandler = "BaseDispatcher";
    ctx.branchTrace.push_back("PATCH_15_DISPATCH");
    metrics.bump(ctx, "patch15.dispatch.calls");
    handler.handle(ctx, legacyHandler, adapter, wrapper, validator, metrics);
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

void BaseDispatcher::dispatchLegacyYearCandidates(
    BaseMonsterContext& ctx,
    const Discovery16LegacyYearCandidateHandler& handler,
    const LegacyYearCandidateAdapter& adapter,
    const LegacyBiasedSelectionAdapter& selectionAdapter,
    const Patch13RejectionWrapper& rejectionWrapper,
    const Patch14WideDetourWrapper& wideWrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.branchTrace.push_back("dispatcher:discovery16:legacy-year-candidates");
    handler.handle(ctx, adapter, selectionAdapter, rejectionWrapper, wideWrapper, validator, metrics);
}

void BaseDispatcher::dispatchPatchedYearCandidates(
    BaseMonsterContext& ctx,
    const Patch16YearCandidateCeilingHandler& handler,
    const YearCandidateCeilingPatchWrapper& wrapper,
    const LegacyYearCandidateAdapter& adapter,
    const LegacyBiasedSelectionAdapter& selectionAdapter,
    const Patch13RejectionWrapper& rejectionWrapper,
    const Patch14WideDetourWrapper& wideWrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.branchTrace.push_back("dispatcher:patch16:real-year-max-5778");
    handler.handle(ctx, wrapper, adapter, selectionAdapter, rejectionWrapper, wideWrapper, validator, metrics);
}

void BaseDispatcher::dispatchLegacyYear5000Tie(
    BaseMonsterContext& ctx,
    const Discovery17Year5000TieHandler& handler,
    const LegacyYear5000TieAdapter& adapter,
    const LegacyBiasedSelectionAdapter& selectionAdapter,
    const Patch13RejectionWrapper& rejectionWrapper,
    const Patch14WideDetourWrapper& wideWrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.branchTrace.push_back("dispatcher:discovery17:year5000:length-only-tie");
    handler.handle(
        ctx,
        adapter,
        selectionAdapter,
        rejectionWrapper,
        wideWrapper,
        validator,
        metrics);
}

void BaseDispatcher::dispatchLegacyYearJump(
    BaseMonsterContext& ctx,
    const Discovery18LegacyYearJumpHandler& handler,
    const LegacyYearJumpAdapter& adapter,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.branchTrace.push_back("DISPATCH:DISCOVERY18_LEGACY_YEAR_JUMP");
    handler.handle(ctx, adapter, validator, metrics);
}

void BaseDispatcher::dispatchPatchedYearWalk(
    BaseMonsterContext& ctx,
    const Patch18SequentialYearWalkHandler& handler,
    const Discovery18LegacyYearJumpHandler& legacyHandler,
    const LegacyYearJumpAdapter& adapter,
    const Patch18SequentialYearWalkWrapper& wrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.branchTrace.push_back("DISPATCH:PATCH18_SEQUENTIAL_YEAR_WALK");
    handler.handle(ctx, legacyHandler, adapter, wrapper, validator, metrics);
}
void BaseDispatcher::dispatchLegacyYearNumberCache(BaseMonsterContext& ctx, std::map<Integer, LegacyYearCacheEntry>& cache, const Discovery19YearNumberCacheHandler& handler, const LegacyYearNumberOnlyCacheAdapter& adapter, const BaseValidationManager& validator, const BaseMetricsShell& metrics) const { handler.handle(ctx,cache,adapter,validator,metrics); }
void BaseDispatcher::dispatchPatchedYearNumberCache(BaseMonsterContext& ctx, std::map<Integer, LegacyYearCacheEntry>& cache, const Patch19YearCacheGuardHandler& handler, const Discovery19YearNumberCacheHandler& legacyHandler, const LegacyYearNumberOnlyCacheAdapter& adapter, const Patch19YearCacheGuardWrapper& wrapper, const BaseValidationManager& validator, const BaseMetricsShell& metrics) const { handler.handle(ctx,cache,legacyHandler,adapter,wrapper,validator,metrics); }
void BaseDispatcher::dispatchDiscovery20StructureSauce(BaseMonsterContext& ctx, const Discovery20StructureSauceHandler& handler, const LegacyStructureSauceAdapter& sauceAdapter, const LegacyStructureSelectorAdapter& selectorAdapter, const BaseValidationManager& validator, const BaseMetricsShell& metrics) const {
    ctx.branchTrace.push_back("DISPATCH:DISCOVERY20_STRUCTURE_SAUCE");
    handler.handle(ctx, sauceAdapter, selectorAdapter, validator, metrics);
}
void BaseDispatcher::dispatchPatchedStructureSauce(BaseMonsterContext& ctx, const Patch20StructureSauceHandler& handler, const StructureSaucePatchWrapper& wrapper, const LegacyStructureSelectorAdapter& selectorAdapter, const BaseValidationManager& validator, const BaseMetricsShell& metrics) const {
    ctx.branchTrace.push_back("DISPATCH:PATCH20_STRUCTURE_SAUCE");
    handler.handle(ctx, wrapper, selectorAdapter, validator, metrics);
}
void BaseDispatcher::dispatchDiscovery21CutletPartition(
    BaseMonsterContext& ctx,
    const Discovery21CutletPartitionHandler& handler,
    const LegacyPositiveCompositionAdapter& adapter,
    const LegacyBiasedSelectionAdapter& selectionAdapter,
    const Patch13RejectionWrapper& rejectionWrapper,
    const Patch14WideDetourWrapper& wideWrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.branchTrace.push_back("DISPATCH:DISCOVERY21_CUTLET_PARTITION");
    handler.handle(
        ctx,
        adapter,
        selectionAdapter,
        rejectionWrapper,
        wideWrapper,
        validator,
        metrics);
}

void BaseDispatcher::dispatchPatchedCutletPartition(
    BaseMonsterContext& ctx,
    const Patch21CutletPartitionHandler& handler,
    const Discovery21CutletPartitionHandler& legacyHandler,
    const LegacyPositiveCompositionAdapter& adapter,
    const CutletPartitionPatchWrapper& wrapper,
    const LegacyBiasedSelectionAdapter& selectionAdapter,
    const Patch13RejectionWrapper& rejectionWrapper,
    const Patch14WideDetourWrapper& wideWrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.branchTrace.push_back("DISPATCH:PATCH21_CUTLET_PARTITION");
    handler.handle(
        ctx,
        legacyHandler,
        adapter,
        wrapper,
        selectionAdapter,
        rejectionWrapper,
        wideWrapper,
        validator,
        metrics);
}

void BaseDispatcher::dispatchDiscovery22RepeatedCutletNames(
    BaseMonsterContext& ctx,
    const Discovery22RepeatedCutletNameHandler& handler,
    const LegacyRepeatedNameGenerator& generator,
    const LegacyBiasedSelectionAdapter& selectionAdapter,
    const Patch13RejectionWrapper& rejectionWrapper,
    const Patch14WideDetourWrapper& wideWrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.branchTrace.push_back("DISPATCH:DISCOVERY22_REPEATED_CUTLET_NAMES");
    handler.handle(
        ctx,
        generator,
        selectionAdapter,
        rejectionWrapper,
        wideWrapper,
        validator,
        metrics);
}

void BaseDispatcher::dispatchPatchedRepeatedCutletNames(
    BaseMonsterContext& ctx,
    const Patch22RepeatedCutletNameHandler& handler,
    const Discovery22RepeatedCutletNameHandler& legacyHandler,
    const LegacyRepeatedNameGenerator& generator,
    const RepeatedNamePatchWrapper& wrapper,
    const LegacyBiasedSelectionAdapter& selectionAdapter,
    const Patch13RejectionWrapper& rejectionWrapper,
    const Patch14WideDetourWrapper& wideWrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.branchTrace.push_back("DISPATCH:PATCH22_REPEATED_CUTLET_NAMES");
    handler.handle(
        ctx,
        legacyHandler,
        generator,
        wrapper,
        selectionAdapter,
        rejectionWrapper,
        wideWrapper,
        validator,
        metrics);
}

void BaseDispatcher::dispatchDiscovery23MonthLengthMaterialization(
    BaseMonsterContext& ctx,
    const Discovery23MonthLengthMaterializationHandler& handler,
    const LegacyMonthLengthMaterializationAdapter& adapter,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.branchTrace.push_back("DISPATCH:DISCOVERY23_MONTH_LENGTH_MATERIALIZATION");
    handler.handle(ctx, adapter, validator, metrics);
}

void BaseDispatcher::dispatchPatchedMonthLengthMaterialization(
    BaseMonsterContext& ctx,
    const Patch23MonthLengthMaterializationHandler& handler,
    const Discovery23MonthLengthMaterializationHandler& legacyHandler,
    const LegacyMonthLengthMaterializationAdapter& adapter,
    const MonthLengthMaterializationPatchWrapper& wrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.branchTrace.push_back("DISPATCH:PATCH23_MONTH_LENGTH_MATERIALIZATION");
    handler.handle(
        ctx,
        legacyHandler,
        adapter,
        wrapper,
        validator,
        metrics);
}

void BaseDispatcher::dispatchDiscovery24MonthWeaving(
    BaseMonsterContext& ctx,
    const Discovery24MonthWeavingHandler& handler,
    const LegacyMonthWeavingAdapter& adapter,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.branchTrace.push_back("DISPATCH:DISCOVERY24_MONTH_WEAVING");
    handler.handle(ctx, adapter, validator, metrics);
}

void BaseDispatcher::dispatchPatchedMonthWeaving(
    BaseMonsterContext& ctx,
    const Patch24MonthWeavingHandler& handler,
    const Discovery24MonthWeavingHandler& legacyHandler,
    const LegacyMonthWeavingAdapter& adapter,
    const MonthWeavingPatchWrapper& wrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.branchTrace.push_back("DISPATCH:PATCH24_MONTH_WEAVING");
    handler.handle(
        ctx,
        legacyHandler,
        adapter,
        wrapper,
        validator,
        metrics);
}

void BaseDispatcher::dispatchDiscovery25ContiguousMonthDay(
    BaseMonsterContext& ctx,
    const Discovery25ContiguousMonthDayHandler& handler,
    const LegacyContiguousMonthDayAdapter& adapter,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.branchTrace.push_back("DISPATCH:DISCOVERY25_CONTIGUOUS_MONTH_DAY");
    handler.handle(ctx, adapter, validator, metrics);
}

void BaseDispatcher::dispatchPatchedContiguousMonthDay(
    BaseMonsterContext& ctx,
    const Patch25ContiguousMonthDayHandler& handler,
    const Discovery25ContiguousMonthDayHandler& legacyHandler,
    const LegacyContiguousMonthDayAdapter& adapter,
    const MonthDayOccurrencePatchWrapper& wrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.branchTrace.push_back("DISPATCH:PATCH25_MONTH_DAY_OCCURRENCE_COUNT");
    handler.handle(ctx, legacyHandler, adapter, wrapper, validator, metrics);
}

void BaseDispatcher::dispatchDiscovery26OpeningGateYearMembership(
    BaseMonsterContext& ctx,
    const Discovery26OpeningGateYearMembershipHandler& handler,
    const LegacyYearMembershipAdapter& adapter,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.branchTrace.push_back("DISPATCH:DISCOVERY26_OPENING_GATE_YEAR_MEMBERSHIP");
    handler.handle(ctx, adapter, validator, metrics);
}

void BaseDispatcher::dispatchPatchedOpeningGateYearMembership(
    BaseMonsterContext& ctx,
    const Patch26OpeningGateYearMembershipHandler& handler,
    const Discovery26OpeningGateYearMembershipHandler& legacyHandler,
    const LegacyYearMembershipAdapter& adapter,
    const OpeningGateMembershipPatchWrapper& wrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.branchTrace.push_back("DISPATCH:PATCH26_OPENING_GATE_YEAR_MEMBERSHIP");
    handler.handle(ctx, legacyHandler, adapter, wrapper, validator, metrics);
}

void BaseDispatcher::dispatchPatchedYear5000Tie(
    BaseMonsterContext& ctx,
    const Patch17Year5000TieHandler& handler,
    const Discovery17Year5000TieHandler& legacyHandler,
    const LegacyYear5000TieAdapter& adapter,
    const Year5000TiePatchWrapper& wrapper,
    const LegacyBiasedSelectionAdapter& selectionAdapter,
    const Patch13RejectionWrapper& rejectionWrapper,
    const Patch14WideDetourWrapper& wideWrapper,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics) const {
    ctx.branchTrace.push_back("dispatcher:patch17:year5000:equal-length-runs-opening-gate");
    handler.handle(
        ctx,
        legacyHandler,
        adapter,
        wrapper,
        selectionAdapter,
        rejectionWrapper,
        wideWrapper,
        validator,
        metrics);
}

LegacyGateQuestionReport BaseMonsterManager::executeLegacyGateQuestionDay(
    const Integer& signedStep) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = FOUNDATION_DAY_OLD;
    ctx.targetDay = FOUNDATION_DAY_OLD;
    ctx.phase = "PATCH_15_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";
    ctx.legacyGateQuestionSignedStep = signedStep;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyGateQuestionAdapter adapter;
    const Discovery15GateQuestionHandler legacyHandler;
    const Patch15NegativeGateQuestionWrapper wrapper;
    const Patch15GateQuestionHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchPatchedGateQuestion(
        ctx, handler, legacyHandler, adapter, wrapper, validator, metrics);

    return LegacyGateQuestionReport{
        signedStep,
        ctx.legacyGateQuestionMagnitude,
        ctx.patch15GateQuestionOutput,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size(),
        ctx.patch15LegacyOutputBeforePatch,
        ctx.patch15Applied
    };
}

LegacyGateQuestionReport BaseMonsterManager::executeUnpatchedGateQuestionDayDiagnostic(
    const Integer& signedStep) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = FOUNDATION_DAY_OLD;
    ctx.targetDay = FOUNDATION_DAY_OLD;
    ctx.phase = "DISCOVERY_15_DIAGNOSTIC_NEW";
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
        ctx.branchTrace.size(),
        Integer{0},
        false
    };
}

LegacyYearCandidateReport BaseMonsterManager::executeLegacyYearCandidateDiscovery(
    const Integer& calculationDay,
    const Integer& targetDay,
    const std::vector<Integer>& gates,
    const std::vector<LegacyYearCandidatePair>& pairs,
    int queriedBowlId,
    int seal) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = calculationDay;
    ctx.targetDay = targetDay;
    ctx.phase = "PATCH_16_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";
    ctx.legacyGateQuestionSignedStep = 0;
    ctx.legacyNextBowlQueriedId = queriedBowlId;
    ctx.legacyYearQueriedBowlId = queriedBowlId;
    ctx.legacyYearSeal = seal;
    ctx.legacyYearGates = gates;
    ctx.legacyYearCandidatePairs = pairs;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyGateQuestionAdapter gateAdapter;
    const Discovery15GateQuestionHandler gateLegacyHandler;
    const Patch15NegativeGateQuestionWrapper gateWrapper;
    const Patch15GateQuestionHandler gateHandler;
    const LegacyOrderMemorySauceAdapter orderMemoryAdapter;
    const Patch11OrderAt46LatchWrapper latchWrapper;
    const Patch11OrderAt46LatchHandler latchHandler;
    const LegacyNextBowlAdapter nextBowlAdapter;
    const Patch12NextBowlWrapper nextBowlWrapper;
    const Patch12NextBowlHandler nextBowlHandler;
    const LegacyYearCandidateAdapter yearAdapter;
    const YearCandidateCeilingPatchWrapper yearWrapper;
    const LegacyBiasedSelectionAdapter selectionAdapter;
    const Patch13RejectionWrapper rejectionWrapper;
    const Patch14WideDetourWrapper wideWrapper;
    const Patch16YearCandidateCeilingHandler yearHandler;
    const BaseDispatcher dispatcher;

    dispatcher.dispatchPatchedGateQuestion(
        ctx, gateHandler, gateLegacyHandler, gateAdapter, gateWrapper, validator, metrics);
    dispatcher.dispatchPatchedOrderAt46Latch(
        ctx, latchHandler, orderMemoryAdapter, latchWrapper, validator, metrics);
    dispatcher.dispatchPatchedNextBowl(
        ctx, nextBowlHandler, nextBowlAdapter, nextBowlWrapper, validator, metrics);
    dispatcher.dispatchPatchedYearCandidates(
        ctx,
        yearHandler,
        yearWrapper,
        yearAdapter,
        selectionAdapter,
        rejectionWrapper,
        wideWrapper,
        validator,
        metrics);

    return LegacyYearCandidateReport{
        ctx.legacyYearGates,
        ctx.legacyYearCandidatePairs,
        ctx.patch16YearCandidatesPreSort,
        ctx.patch16YearCandidatesSorted,
        ctx.patch16YearSelectionRing,
        ctx.patch16YearSelectionFamilySize,
        ctx.patch16YearSelectionCalled,
        ctx.patch16YearSelectedOrdinal,
        ctx.patch16YearSelectedCandidate,
        ctx.patch15Applied,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size(),
        ctx.patch16LegacyYearCandidatesPreSort,
        ctx.patch16RejectedBeforeSort,
        ctx.patch16Applied
    };
}

LegacyYearCandidateReport BaseMonsterManager::executeUnpatchedYearCandidateDiscoveryDiagnostic(
    const Integer& calculationDay,
    const Integer& targetDay,
    const std::vector<Integer>& gates,
    const std::vector<LegacyYearCandidatePair>& pairs,
    int queriedBowlId,
    int seal) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = calculationDay;
    ctx.targetDay = targetDay;
    ctx.phase = "DISCOVERY_16_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";
    ctx.legacyGateQuestionSignedStep = 0;
    ctx.legacyNextBowlQueriedId = queriedBowlId;
    ctx.legacyYearQueriedBowlId = queriedBowlId;
    ctx.legacyYearSeal = seal;
    ctx.legacyYearGates = gates;
    ctx.legacyYearCandidatePairs = pairs;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyGateQuestionAdapter gateAdapter;
    const Discovery15GateQuestionHandler gateLegacyHandler;
    const Patch15NegativeGateQuestionWrapper gateWrapper;
    const Patch15GateQuestionHandler gateHandler;
    const LegacyOrderMemorySauceAdapter orderMemoryAdapter;
    const Patch11OrderAt46LatchWrapper latchWrapper;
    const Patch11OrderAt46LatchHandler latchHandler;
    const LegacyNextBowlAdapter nextBowlAdapter;
    const Patch12NextBowlWrapper nextBowlWrapper;
    const Patch12NextBowlHandler nextBowlHandler;
    const LegacyYearCandidateAdapter yearAdapter;
    const LegacyBiasedSelectionAdapter selectionAdapter;
    const Patch13RejectionWrapper rejectionWrapper;
    const Patch14WideDetourWrapper wideWrapper;
    const Discovery16LegacyYearCandidateHandler yearHandler;
    const BaseDispatcher dispatcher;

    dispatcher.dispatchPatchedGateQuestion(
        ctx, gateHandler, gateLegacyHandler, gateAdapter, gateWrapper, validator, metrics);
    dispatcher.dispatchPatchedOrderAt46Latch(
        ctx, latchHandler, orderMemoryAdapter, latchWrapper, validator, metrics);
    dispatcher.dispatchPatchedNextBowl(
        ctx, nextBowlHandler, nextBowlAdapter, nextBowlWrapper, validator, metrics);
    dispatcher.dispatchLegacyYearCandidates(
        ctx, yearHandler, yearAdapter, selectionAdapter, rejectionWrapper, wideWrapper, validator, metrics);

    return LegacyYearCandidateReport{
        ctx.legacyYearGates,
        ctx.legacyYearCandidatePairs,
        ctx.legacyYearCandidatesPreSort,
        ctx.legacyYearCandidatesSorted,
        ctx.legacyYearSelectionRing,
        ctx.legacyYearSelectionFamilySize,
        ctx.legacyYearSelectionCalled,
        ctx.legacyYearSelectedOrdinal,
        ctx.legacyYearSelectedCandidate,
        ctx.patch15Applied,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size()
    };
}

LegacyYear5000TieReport BaseMonsterManager::executeLegacyYear5000TieDiscovery(
    const Integer& calculationDay,
    const Integer& targetDay,
    const std::vector<Integer>& gates,
    const std::vector<LegacyYearCandidatePair>& pairs,
    int queriedBowlId,
    int seal) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = calculationDay;
    ctx.targetDay = targetDay;
    ctx.phase = "PATCH_17_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";
    ctx.legacyGateQuestionSignedStep = 0;
    ctx.legacyNextBowlQueriedId = queriedBowlId;
    ctx.legacyYearQueriedBowlId = queriedBowlId;
    ctx.legacyYearSeal = seal;
    ctx.legacyYearGates = gates;
    ctx.legacyYearCandidatePairs = pairs;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyGateQuestionAdapter gateAdapter;
    const Discovery15GateQuestionHandler gateLegacyHandler;
    const Patch15NegativeGateQuestionWrapper gateWrapper;
    const Patch15GateQuestionHandler gateHandler;
    const LegacyOrderMemorySauceAdapter orderMemoryAdapter;
    const Patch11OrderAt46LatchWrapper latchWrapper;
    const Patch11OrderAt46LatchHandler latchHandler;
    const LegacyNextBowlAdapter nextBowlAdapter;
    const Patch12NextBowlWrapper nextBowlWrapper;
    const Patch12NextBowlHandler nextBowlHandler;
    const LegacyYear5000TieAdapter yearTieAdapter;
    const LegacyBiasedSelectionAdapter selectionAdapter;
    const Patch13RejectionWrapper rejectionWrapper;
    const Patch14WideDetourWrapper wideWrapper;
    const Discovery17Year5000TieHandler legacyTieHandler;
    const Year5000TiePatchWrapper tieWrapper;
    const Patch17Year5000TieHandler tieHandler;
    const BaseDispatcher dispatcher;

    dispatcher.dispatchPatchedGateQuestion(
        ctx, gateHandler, gateLegacyHandler, gateAdapter, gateWrapper, validator, metrics);
    dispatcher.dispatchPatchedOrderAt46Latch(
        ctx, latchHandler, orderMemoryAdapter, latchWrapper, validator, metrics);
    dispatcher.dispatchPatchedNextBowl(
        ctx, nextBowlHandler, nextBowlAdapter, nextBowlWrapper, validator, metrics);
    dispatcher.dispatchPatchedYear5000Tie(
        ctx,
        tieHandler,
        legacyTieHandler,
        yearTieAdapter,
        tieWrapper,
        selectionAdapter,
        rejectionWrapper,
        wideWrapper,
        validator,
        metrics);

    return LegacyYear5000TieReport{
        calculationDay,
        gates,
        pairs,
        ctx.discovery17Year5000PreSort,
        ctx.patch17Year5000Sorted,
        ctx.discovery17Year5000SelectionRing,
        ctx.discovery17Year5000SelectionFamilySize,
        ctx.discovery17Year5000SelectionCalled,
        ctx.patch17Year5000SelectedOrdinal,
        ctx.patch17Year5000SelectedCandidate,
        ctx.discovery17Year5000Ready,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size(),
        ctx.patch17LegacyYear5000Sorted,
        ctx.patch17LegacyYear5000SelectedOrdinal,
        ctx.patch17LegacyYear5000SelectedCandidate,
        ctx.patch17EqualLengthRunCount,
        ctx.patch17Applied
    };
}

LegacyYear5000TieReport BaseMonsterManager::executeUnpatchedYear5000TieDiagnostic(
    const Integer& calculationDay,
    const Integer& targetDay,
    const std::vector<Integer>& gates,
    const std::vector<LegacyYearCandidatePair>& pairs,
    int queriedBowlId,
    int seal) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = calculationDay;
    ctx.targetDay = targetDay;
    ctx.phase = "DISCOVERY_17_DIAGNOSTIC_NEW";
    ctx.status = "NEW";
    ctx.currentHandler = "BaseMonsterManager";
    ctx.legacyGateQuestionSignedStep = 0;
    ctx.legacyNextBowlQueriedId = queriedBowlId;
    ctx.legacyYearQueriedBowlId = queriedBowlId;
    ctx.legacyYearSeal = seal;
    ctx.legacyYearGates = gates;
    ctx.legacyYearCandidatePairs = pairs;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyGateQuestionAdapter gateAdapter;
    const Discovery15GateQuestionHandler gateLegacyHandler;
    const Patch15NegativeGateQuestionWrapper gateWrapper;
    const Patch15GateQuestionHandler gateHandler;
    const LegacyOrderMemorySauceAdapter orderMemoryAdapter;
    const Patch11OrderAt46LatchWrapper latchWrapper;
    const Patch11OrderAt46LatchHandler latchHandler;
    const LegacyNextBowlAdapter nextBowlAdapter;
    const Patch12NextBowlWrapper nextBowlWrapper;
    const Patch12NextBowlHandler nextBowlHandler;
    const LegacyYear5000TieAdapter yearTieAdapter;
    const LegacyBiasedSelectionAdapter selectionAdapter;
    const Patch13RejectionWrapper rejectionWrapper;
    const Patch14WideDetourWrapper wideWrapper;
    const Discovery17Year5000TieHandler tieHandler;
    const BaseDispatcher dispatcher;

    dispatcher.dispatchPatchedGateQuestion(
        ctx, gateHandler, gateLegacyHandler, gateAdapter, gateWrapper, validator, metrics);
    dispatcher.dispatchPatchedOrderAt46Latch(
        ctx, latchHandler, orderMemoryAdapter, latchWrapper, validator, metrics);
    dispatcher.dispatchPatchedNextBowl(
        ctx, nextBowlHandler, nextBowlAdapter, nextBowlWrapper, validator, metrics);
    dispatcher.dispatchLegacyYear5000Tie(
        ctx,
        tieHandler,
        yearTieAdapter,
        selectionAdapter,
        rejectionWrapper,
        wideWrapper,
        validator,
        metrics);

    return LegacyYear5000TieReport{
        calculationDay,
        gates,
        pairs,
        ctx.discovery17Year5000PreSort,
        ctx.discovery17Year5000Sorted,
        ctx.discovery17Year5000SelectionRing,
        ctx.discovery17Year5000SelectionFamilySize,
        ctx.discovery17Year5000SelectionCalled,
        ctx.discovery17Year5000SelectedOrdinal,
        ctx.discovery17Year5000SelectedCandidate,
        ctx.discovery17Year5000Ready,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size(),
        ctx.discovery17Year5000Sorted,
        ctx.discovery17Year5000SelectedOrdinal,
        ctx.discovery17Year5000SelectedCandidate,
        0,
        false
    };
}

LegacyYearJumpReport BaseMonsterManager::executeLegacyYearJump(
    const LegacyYearAnchor& anchor,
    const Integer& targetDay,
    const Integer& calculationDay) const {
    BaseMonsterContext ctx;
    ctx.phase = "ENTRY";
    ctx.status = "NEW";
    ctx.discovery18JumpAnchor = anchor;
    ctx.discovery18JumpTargetDay = targetDay;
    ctx.patch18CalculationDay = calculationDay;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyYearJumpAdapter adapter;
    const Discovery18LegacyYearJumpHandler legacyHandler;
    const Patch18SequentialYearWalkWrapper wrapper;
    const Patch18SequentialYearWalkHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchPatchedYearWalk(
        ctx,
        handler,
        legacyHandler,
        adapter,
        wrapper,
        validator,
        metrics);

    return LegacyYearJumpReport{
        ctx.discovery18JumpAnchor,
        ctx.discovery18JumpTargetDay,
        ctx.discovery18OldJumpGuess,
        ctx.discovery18JumpOutputYearNumber,
        ctx.discovery18GuessUsedAsOutput,
        ctx.discovery18JumpReady,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size(),
        ctx.patch18CalculationDay,
        ctx.patch18AnchorYear,
        ctx.patch18OutputYear,
        ctx.patch18ForwardSteps,
        ctx.patch18BackwardSteps,
        ctx.patch18GuessTelemetryOnly,
        ctx.patch18Applied
    };
}

LegacyYearJumpReport BaseMonsterManager::executeUnpatchedYearJumpDiagnostic(
    const LegacyYearAnchor& anchor,
    const Integer& targetDay) const {
    BaseMonsterContext ctx;
    ctx.phase = "ENTRY";
    ctx.status = "NEW";
    ctx.discovery18JumpAnchor = anchor;
    ctx.discovery18JumpTargetDay = targetDay;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyYearJumpAdapter adapter;
    const Discovery18LegacyYearJumpHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchLegacyYearJump(ctx, handler, adapter, validator, metrics);

    return LegacyYearJumpReport{
        ctx.discovery18JumpAnchor,
        ctx.discovery18JumpTargetDay,
        ctx.discovery18OldJumpGuess,
        ctx.discovery18JumpOutputYearNumber,
        ctx.discovery18GuessUsedAsOutput,
        ctx.discovery18JumpReady,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size()
    };
}
LegacyYearCacheReport BaseMonsterManager::executeLegacyYearNumberCache(const LegacyYearAnchor& anchor, const Integer& targetDay, const Integer& calculationDay) const {
    const LegacyYearJumpReport fresh=executeLegacyYearJump(anchor,targetDay,calculationDay); BaseMonsterContext ctx; ctx.phase="ENTRY"; ctx.status="NEW"; ctx.calculationDay=calculationDay; ctx.targetDay=targetDay; ctx.discovery19CacheKeyYearNumber=fresh.outputYear.number; ctx.discovery19CacheRequest=LegacyYearCacheEntry{calculationDay,fresh.outputYear.openGateDay,fresh.outputYear.closeGateDay,fresh.outputYear};
    const BaseValidationManager validator; const BaseMetricsShell metrics; const LegacyYearNumberOnlyCacheAdapter adapter; const Discovery19YearNumberCacheHandler legacyHandler; const Patch19YearCacheGuardWrapper wrapper; const Patch19YearCacheGuardHandler handler; const BaseDispatcher dispatcher; dispatcher.dispatchPatchedYearNumberCache(ctx,legacyYearNumberCache_,handler,legacyHandler,adapter,wrapper,validator,metrics);
    return LegacyYearCacheReport{ctx.discovery19CacheKeyYearNumber,ctx.discovery19CacheRequest,ctx.discovery19CachedEntry,ctx.discovery19CacheOutput,ctx.discovery19CacheHit,ctx.discovery19CacheReady,ctx.phase,ctx.status,ctx.currentHandler,ctx.branchTrace.size(),ctx.patch19LegacyCachedEntryBeforePatch,ctx.patch19LegacyOutputBeforePatch,ctx.patch19LegacyCacheHitBeforePatch,ctx.patch19FingerprintMatched,ctx.patch19OpenGateMatched,ctx.patch19CloseGateMatched,ctx.patch19EntryOverwritten,ctx.patch19Applied};
}
LegacyYearCacheReport BaseMonsterManager::executeUnpatchedYearNumberCacheDiagnostic(const LegacyYearAnchor& anchor, const Integer& targetDay, const Integer& calculationDay) const {
    const LegacyYearJumpReport fresh=executeLegacyYearJump(anchor,targetDay,calculationDay); BaseMonsterContext ctx; ctx.phase="ENTRY"; ctx.status="NEW"; ctx.calculationDay=calculationDay; ctx.targetDay=targetDay; ctx.discovery19CacheKeyYearNumber=fresh.outputYear.number; ctx.discovery19CacheRequest=LegacyYearCacheEntry{calculationDay,fresh.outputYear.openGateDay,fresh.outputYear.closeGateDay,fresh.outputYear};
    const BaseValidationManager validator; const BaseMetricsShell metrics; const LegacyYearNumberOnlyCacheAdapter adapter; const Discovery19YearNumberCacheHandler handler; const BaseDispatcher dispatcher; dispatcher.dispatchLegacyYearNumberCache(ctx,legacyYearNumberCache_,handler,adapter,validator,metrics);
    return LegacyYearCacheReport{ctx.discovery19CacheKeyYearNumber,ctx.discovery19CacheRequest,ctx.discovery19CachedEntry,ctx.discovery19CacheOutput,ctx.discovery19CacheHit,ctx.discovery19CacheReady,ctx.phase,ctx.status,ctx.currentHandler,ctx.branchTrace.size()};
}
LegacyStructureSauceReport BaseMonsterManager::executeDiscovery20StructureSauce(const LegacyYearAnchor& anchor, const Integer& originalTargetDay, const Integer& calculationDay) const {
    const LegacyYearCacheReport cacheReport = executeLegacyYearNumberCache(anchor, originalTargetDay, calculationDay);
    BaseMonsterContext ctx;
    ctx.phase = "ENTRY";
    ctx.status = "NEW";
    ctx.calculationDay = calculationDay;
    ctx.targetDay = originalTargetDay;
    ctx.discovery20OriginalTargetDay = originalTargetDay;
    ctx.discovery20ResolvedYear = cacheReport.outputValue;
    ctx.discovery20YearFirstDay = cacheReport.outputValue.openGateDay + 1;
    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyStructureSelectorAdapter selectorAdapter;
    const StructureSaucePatchWrapper wrapper;
    const Patch20StructureSauceHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchPatchedStructureSauce(ctx, handler, wrapper, selectorAdapter, validator, metrics);
    return LegacyStructureSauceReport{
        calculationDay,
        originalTargetDay,
        ctx.discovery20YearFirstDay,
        ctx.discovery20ResolvedYear,
        ctx.discovery20LegacyStructureSauce,
        ctx.patch20SemanticStructureSauce,
        ctx.discovery20SelectorToken,
        ctx.discovery20SelectorConsumedLegacySauce,
        ctx.patch20GhostExecuted,
        ctx.patch20SemanticRecomputed,
        ctx.patch20GhostReachedSelector,
        ctx.patch20Applied,
        ctx.discovery20StructureSauceReady,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size()
    };
}
LegacyStructureSauceReport BaseMonsterManager::executeUnpatchedDiscovery20StructureSauceDiagnostic(const LegacyYearAnchor& anchor, const Integer& originalTargetDay, const Integer& calculationDay) const {
    const LegacyYearCacheReport cacheReport = executeLegacyYearNumberCache(anchor, originalTargetDay, calculationDay);
    BaseMonsterContext ctx;
    ctx.phase = "ENTRY";
    ctx.status = "NEW";
    ctx.calculationDay = calculationDay;
    ctx.targetDay = originalTargetDay;
    ctx.discovery20OriginalTargetDay = originalTargetDay;
    ctx.discovery20ResolvedYear = cacheReport.outputValue;
    ctx.discovery20YearFirstDay = cacheReport.outputValue.openGateDay + 1;
    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyStructureSauceAdapter sauceAdapter;
    const LegacyStructureSelectorAdapter selectorAdapter;
    const Discovery20StructureSauceHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchDiscovery20StructureSauce(ctx, handler, sauceAdapter, selectorAdapter, validator, metrics);
    return LegacyStructureSauceReport{
        calculationDay,
        originalTargetDay,
        ctx.discovery20YearFirstDay,
        ctx.discovery20ResolvedYear,
        ctx.discovery20LegacyStructureSauce,
        ctx.patch20SemanticStructureSauce,
        ctx.discovery20SelectorToken,
        ctx.discovery20SelectorConsumedLegacySauce,
        ctx.patch20GhostExecuted,
        ctx.patch20SemanticRecomputed,
        ctx.patch20GhostReachedSelector,
        ctx.patch20Applied,
        ctx.discovery20StructureSauceReady,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size()
    };
}
LegacyCutletPartitionReport BaseMonsterManager::executeDiscovery21CutletPartition(
    const LegacyYearAnchor& anchor,
    const Integer& originalTargetDay,
    const Integer& calculationDay,
    const Integer& calculationGateIndex,
    int cutletCount) const {
    const LegacyStructureSauceReport structure = executeDiscovery20StructureSauce(
        anchor,
        originalTargetDay,
        calculationDay);
    BaseMonsterContext ctx;
    ctx.phase = "ENTRY";
    ctx.status = "NEW";
    ctx.calculationDay = calculationDay;
    ctx.targetDay = originalTargetDay;
    ctx.discovery20OriginalTargetDay = originalTargetDay;
    ctx.discovery20YearFirstDay = structure.yearFirstDay;
    ctx.discovery20ResolvedYear = structure.resolvedYear;
    ctx.patch20SemanticStructureSauce = structure.semanticStructureSauce;
    ctx.patch20Applied = structure.patch20Applied;
    ctx.discovery21CalculationGateIndex = calculationGateIndex;
    ctx.discovery21CutletCount = cutletCount;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyPositiveCompositionAdapter adapter;
    const LegacyBiasedSelectionAdapter selectionAdapter;
    const Patch13RejectionWrapper rejectionWrapper;
    const Patch14WideDetourWrapper wideWrapper;
    const Discovery21CutletPartitionHandler legacyHandler;
    const CutletPartitionPatchWrapper wrapper;
    const Patch21CutletPartitionHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchPatchedCutletPartition(
        ctx,
        handler,
        legacyHandler,
        adapter,
        wrapper,
        selectionAdapter,
        rejectionWrapper,
        wideWrapper,
        validator,
        metrics);

    return LegacyCutletPartitionReport{
        calculationDay,
        originalTargetDay,
        calculationGateIndex,
        ctx.discovery20ResolvedYear,
        ctx.discovery21GapCount,
        ctx.discovery21CutletCount,
        ctx.discovery21InternalGateOffset,
        ctx.discovery21CalculationDayIsInternalGate,
        ctx.discovery21LegacyFamily,
        ctx.discovery21SelectionRank,
        ctx.discovery21LegacyPartition,
        ctx.discovery21LegacyPrefixSums,
        ctx.discovery21LegacyHitInternalGateBoundary,
        ctx.discovery21LegacyIgnoredInternalGate,
        ctx.patch21SemanticFamily,
        ctx.patch21SemanticSelectionRank,
        ctx.patch21SemanticPartition,
        ctx.patch21SemanticPrefixSums,
        ctx.patch21SemanticHitInternalGateBoundary,
        ctx.patch21FilterApplied,
        ctx.patch21LegacyExecuted,
        ctx.patch21LegacyPartitionReused,
        ctx.patch21Applied,
        ctx.discovery21CutletPartitionReady,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size()
    };
}
LegacyCutletPartitionReport BaseMonsterManager::executeUnpatchedDiscovery21CutletPartitionDiagnostic(
    const LegacyYearAnchor& anchor,
    const Integer& originalTargetDay,
    const Integer& calculationDay,
    const Integer& calculationGateIndex,
    int cutletCount) const {
    const LegacyStructureSauceReport structure = executeDiscovery20StructureSauce(
        anchor,
        originalTargetDay,
        calculationDay);
    BaseMonsterContext ctx;
    ctx.phase = "ENTRY";
    ctx.status = "NEW";
    ctx.calculationDay = calculationDay;
    ctx.targetDay = originalTargetDay;
    ctx.discovery20OriginalTargetDay = originalTargetDay;
    ctx.discovery20YearFirstDay = structure.yearFirstDay;
    ctx.discovery20ResolvedYear = structure.resolvedYear;
    ctx.patch20SemanticStructureSauce = structure.semanticStructureSauce;
    ctx.patch20Applied = structure.patch20Applied;
    ctx.discovery21CalculationGateIndex = calculationGateIndex;
    ctx.discovery21CutletCount = cutletCount;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyPositiveCompositionAdapter adapter;
    const LegacyBiasedSelectionAdapter selectionAdapter;
    const Patch13RejectionWrapper rejectionWrapper;
    const Patch14WideDetourWrapper wideWrapper;
    const Discovery21CutletPartitionHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchDiscovery21CutletPartition(
        ctx,
        handler,
        adapter,
        selectionAdapter,
        rejectionWrapper,
        wideWrapper,
        validator,
        metrics);

    return LegacyCutletPartitionReport{
        calculationDay,
        originalTargetDay,
        calculationGateIndex,
        ctx.discovery20ResolvedYear,
        ctx.discovery21GapCount,
        ctx.discovery21CutletCount,
        ctx.discovery21InternalGateOffset,
        ctx.discovery21CalculationDayIsInternalGate,
        ctx.discovery21LegacyFamily,
        ctx.discovery21SelectionRank,
        ctx.discovery21LegacyPartition,
        ctx.discovery21LegacyPrefixSums,
        ctx.discovery21LegacyHitInternalGateBoundary,
        ctx.discovery21LegacyIgnoredInternalGate,
        FilteredPositiveCompositionFamily{},
        Integer{},
        {},
        {},
        false,
        false,
        false,
        false,
        false,
        ctx.discovery21CutletPartitionReady,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size()
    };
}

LegacyRepeatedNameReport BaseMonsterManager::executeDiscovery22RepeatedCutletNames(
    const LegacyYearAnchor& anchor,
    const Integer& originalTargetDay,
    const Integer& calculationDay,
    const Integer& calculationGateIndex,
    int cutletCount) const {
    const LegacyCutletPartitionReport partition = executeDiscovery21CutletPartition(
        anchor,
        originalTargetDay,
        calculationDay,
        calculationGateIndex,
        cutletCount);
    if (!partition.ready || !partition.patch21Applied) {
        throw BaseValidationError("PATCH 22 partitionem PATCH 21 paratam requirit");
    }

    const Patch20StructureSauceResult structure = structureSaucePatch(
        calculationDay,
        originalTargetDay,
        partition.resolvedYear);

    BaseMonsterContext ctx;
    ctx.phase = "ENTRY";
    ctx.status = "NEW";
    ctx.calculationDay = calculationDay;
    ctx.targetDay = originalTargetDay;
    ctx.discovery20OriginalTargetDay = originalTargetDay;
    ctx.discovery20YearFirstDay = partition.resolvedYear.openGateDay + 1;
    ctx.discovery20ResolvedYear = partition.resolvedYear;
    ctx.patch20SemanticStructureSauce = structure.semanticSauce;
    ctx.patch20Applied = true;
    ctx.discovery22CutletCount = cutletCount;
    ctx.discovery22Patch20Prepared = structure.ghostExecuted;
    ctx.discovery22Patch21Prepared = partition.patch21Applied;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyRepeatedNameGenerator generator;
    const RepeatedNamePatchWrapper wrapper;
    const LegacyBiasedSelectionAdapter selectionAdapter;
    const Patch13RejectionWrapper rejectionWrapper;
    const Patch14WideDetourWrapper wideWrapper;
    const Discovery22RepeatedCutletNameHandler legacyHandler;
    const Patch22RepeatedCutletNameHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchPatchedRepeatedCutletNames(
        ctx,
        handler,
        legacyHandler,
        generator,
        wrapper,
        selectionAdapter,
        rejectionWrapper,
        wideWrapper,
        validator,
        metrics);

    return LegacyRepeatedNameReport{
        calculationDay,
        originalTargetDay,
        calculationGateIndex,
        partition.resolvedYear,
        ctx.discovery22CutletCount,
        ctx.discovery22MasterNameCount,
        ctx.discovery22SelectionSpaceCount,
        ctx.discovery22SelectionRing,
        ctx.discovery22SelectionRank,
        ctx.discovery22LegacyNameIndices,
        ctx.discovery22LegacyContainsRepeat,
        ctx.discovery22Patch20Prepared,
        ctx.discovery22Patch21Prepared,
        ctx.patch22CorrectNameIndices,
        ctx.patch22SemanticNameIndices,
        ctx.patch22LegacyExecuted,
        ctx.patch22CorrectComputed,
        ctx.patch22BadEqualsCorrect,
        ctx.patch22LegacyReturned,
        ctx.patch22Applied,
        ctx.patch22RepeatedNamesReady,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size()
    };
}

LegacyRepeatedNameReport BaseMonsterManager::executeUnpatchedDiscovery22RepeatedCutletNamesDiagnostic(
    const LegacyYearAnchor& anchor,
    const Integer& originalTargetDay,
    const Integer& calculationDay,
    const Integer& calculationGateIndex,
    int cutletCount) const {
    const LegacyCutletPartitionReport partition = executeDiscovery21CutletPartition(
        anchor,
        originalTargetDay,
        calculationDay,
        calculationGateIndex,
        cutletCount);
    if (!partition.ready || !partition.patch21Applied) {
        throw BaseValidationError("diagnosticum DISCOVERY 22 partitionem PATCH 21 paratam requirit");
    }

    const Patch20StructureSauceResult structure = structureSaucePatch(
        calculationDay,
        originalTargetDay,
        partition.resolvedYear);

    BaseMonsterContext ctx;
    ctx.phase = "ENTRY";
    ctx.status = "NEW";
    ctx.calculationDay = calculationDay;
    ctx.targetDay = originalTargetDay;
    ctx.discovery20OriginalTargetDay = originalTargetDay;
    ctx.discovery20YearFirstDay = partition.resolvedYear.openGateDay + 1;
    ctx.discovery20ResolvedYear = partition.resolvedYear;
    ctx.patch20SemanticStructureSauce = structure.semanticSauce;
    ctx.patch20Applied = true;
    ctx.discovery22CutletCount = cutletCount;
    ctx.discovery22Patch20Prepared = structure.ghostExecuted;
    ctx.discovery22Patch21Prepared = partition.patch21Applied;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyRepeatedNameGenerator generator;
    const LegacyBiasedSelectionAdapter selectionAdapter;
    const Patch13RejectionWrapper rejectionWrapper;
    const Patch14WideDetourWrapper wideWrapper;
    const Discovery22RepeatedCutletNameHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchDiscovery22RepeatedCutletNames(
        ctx,
        handler,
        generator,
        selectionAdapter,
        rejectionWrapper,
        wideWrapper,
        validator,
        metrics);

    return LegacyRepeatedNameReport{
        calculationDay,
        originalTargetDay,
        calculationGateIndex,
        partition.resolvedYear,
        ctx.discovery22CutletCount,
        ctx.discovery22MasterNameCount,
        ctx.discovery22SelectionSpaceCount,
        ctx.discovery22SelectionRing,
        ctx.discovery22SelectionRank,
        ctx.discovery22LegacyNameIndices,
        ctx.discovery22LegacyContainsRepeat,
        ctx.discovery22Patch20Prepared,
        ctx.discovery22Patch21Prepared,
        {},
        {},
        false,
        false,
        false,
        false,
        false,
        ctx.discovery22RepeatedNamesReady,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size()
    };
}

LegacyMonthLengthMaterializationReport
BaseMonsterManager::executeDiscovery23MonthLengthMaterialization(
    const LegacyYearAnchor& anchor,
    const Integer& originalTargetDay,
    const Integer& calculationDay,
    const Integer& calculationGateIndex,
    int cutletCount,
    int monthCount) const {
    const LegacyRepeatedNameReport names = executeDiscovery22RepeatedCutletNames(
        anchor,
        originalTargetDay,
        calculationDay,
        calculationGateIndex,
        cutletCount);
    if (!names.ready || !names.patch22Applied) {
        throw BaseValidationError("DISCOVERY 23 PATCH 22 paratum requirit");
    }

    const Integer yearLengthInteger =
        names.resolvedYear.closeGateDay - names.resolvedYear.openGateDay;
    if (yearLengthInteger < 1 || yearLengthInteger > REAL_YEAR_MAX_PATCH) {
        throw BaseValidationError("longitudo anni DISCOVERY 23 invalida est");
    }

    BaseMonsterContext ctx;
    ctx.phase = "ENTRY";
    ctx.status = "NEW";
    ctx.calculationDay = calculationDay;
    ctx.targetDay = originalTargetDay;
    ctx.discovery23YearLength = yearLengthInteger.convert_to<int>();
    ctx.discovery23MonthCount = monthCount;
    ctx.discovery23Patch22Prepared = names.patch22Applied;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyMonthLengthMaterializationAdapter adapter;
    const MonthLengthMaterializationPatchWrapper wrapper;
    const Discovery23MonthLengthMaterializationHandler legacyHandler;
    const Patch23MonthLengthMaterializationHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchPatchedMonthLengthMaterialization(
        ctx,
        handler,
        legacyHandler,
        adapter,
        wrapper,
        validator,
        metrics);

    return LegacyMonthLengthMaterializationReport{
        calculationDay,
        originalTargetDay,
        calculationGateIndex,
        names.resolvedYear,
        cutletCount,
        ctx.discovery23YearLength,
        ctx.discovery23MonthCount,
        ctx.discovery23ExactFamilyCount,
        ctx.discovery23ConcreteListIndexCapacity,
        ctx.discovery23Patch22Prepared,
        ctx.discovery23LegacyConcreteListContractReached,
        ctx.discovery23LegacyConcreteEnumerationEntered,
        ctx.discovery23LegacyConcreteMaterializationCompleted,
        ctx.discovery23BlockedBeforeAllocation,
        ctx.discovery23MaterializedItemCount,
        ctx.patch23VirtualCount,
        ctx.patch23VirtualProbeRank,
        ctx.patch23VirtualProbeItem,
        ctx.patch23LegacyExecuted,
        ctx.patch23VirtualBackendUsed,
        ctx.patch23CountMatchesLegacyProof,
        ctx.patch23Applied,
        ctx.patch23MonthLengthMaterializationReady,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size()
    };
}

LegacyMonthLengthMaterializationReport
BaseMonsterManager::executeUnpatchedDiscovery23MonthLengthMaterializationDiagnostic(
    const LegacyYearAnchor& anchor,
    const Integer& originalTargetDay,
    const Integer& calculationDay,
    const Integer& calculationGateIndex,
    int cutletCount,
    int monthCount) const {
    const LegacyRepeatedNameReport names = executeDiscovery22RepeatedCutletNames(
        anchor,
        originalTargetDay,
        calculationDay,
        calculationGateIndex,
        cutletCount);
    if (!names.ready || !names.patch22Applied) {
        throw BaseValidationError("diagnosticum DISCOVERY 23 PATCH 22 paratum requirit");
    }

    const Integer yearLengthInteger =
        names.resolvedYear.closeGateDay - names.resolvedYear.openGateDay;
    if (yearLengthInteger < 1 || yearLengthInteger > REAL_YEAR_MAX_PATCH) {
        throw BaseValidationError("longitudo anni diagnostici DISCOVERY 23 invalida est");
    }

    BaseMonsterContext ctx;
    ctx.phase = "ENTRY";
    ctx.status = "NEW";
    ctx.calculationDay = calculationDay;
    ctx.targetDay = originalTargetDay;
    ctx.discovery23YearLength = yearLengthInteger.convert_to<int>();
    ctx.discovery23MonthCount = monthCount;
    ctx.discovery23Patch22Prepared = names.patch22Applied;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyMonthLengthMaterializationAdapter adapter;
    const Discovery23MonthLengthMaterializationHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchDiscovery23MonthLengthMaterialization(
        ctx,
        handler,
        adapter,
        validator,
        metrics);

    return LegacyMonthLengthMaterializationReport{
        calculationDay,
        originalTargetDay,
        calculationGateIndex,
        names.resolvedYear,
        cutletCount,
        ctx.discovery23YearLength,
        ctx.discovery23MonthCount,
        ctx.discovery23ExactFamilyCount,
        ctx.discovery23ConcreteListIndexCapacity,
        ctx.discovery23Patch22Prepared,
        ctx.discovery23LegacyConcreteListContractReached,
        ctx.discovery23LegacyConcreteEnumerationEntered,
        ctx.discovery23LegacyConcreteMaterializationCompleted,
        ctx.discovery23BlockedBeforeAllocation,
        ctx.discovery23MaterializedItemCount,
        {},
        {},
        {},
        false,
        false,
        false,
        false,
        ctx.discovery23MonthLengthMaterializationReady,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size()
    };
}

LegacyMonthWeavingReport BaseMonsterManager::executeDiscovery24MonthWeaving(
    const LegacyYearAnchor& anchor,
    const Integer& originalTargetDay,
    const Integer& calculationDay,
    const std::vector<int>& monthLengths) const {
    if (monthLengths.size() < 3 || monthLengths.size() > 47) {
        throw BaseValidationError("DISCOVERY 24 inter tres et quadraginta septem menses requirit");
    }
    int localYearLength = 0;
    for (const int length : monthLengths) {
        if (length < LEGACY_MONTH_LENGTH_MIN || length > LEGACY_MONTH_LENGTH_MAX) {
            throw BaseValidationError("DISCOVERY 24 longitudines mensium inter quattuor et centum viginti tres requirit");
        }
        if (localYearLength > REAL_YEAR_MAX_PATCH - length) {
            throw BaseValidationError("DISCOVERY 24 summa longitudinum mensium limitem anni excedit");
        }
        localYearLength += length;
    }

    const LegacyStructureSauceReport structure = executeDiscovery20StructureSauce(
        anchor,
        originalTargetDay,
        calculationDay);
    if (!structure.ready || !structure.patch20Applied ||
        structure.patch20GhostReachedSelector) {
        throw BaseValidationError("DISCOVERY 24 PATCH 20 sauce semanticam paratam requirit");
    }

    const LegacyMonthLengthMaterializationAdapter materializationAdapter;
    const MonthLengthMaterializationPatchWrapper materializationWrapper;
    const LegacyMonthLengthMaterializationInspection legacyInspection =
        materializationAdapter.inspect(
            localYearLength,
            static_cast<int>(monthLengths.size()));
    const MonthLengthMaterializationPatchDecision materializationDecision =
        materializationWrapper.repair(
            localYearLength,
            static_cast<int>(monthLengths.size()),
            legacyInspection);
    if (!materializationDecision.patchApplied ||
        !materializationDecision.legacyExecuted ||
        !materializationDecision.virtualBackendUsed ||
        !materializationDecision.countMatchesLegacyProof) {
        throw BaseValidationError("DISCOVERY 24 PATCH 23 backend virtualem paratum requirit");
    }

    BaseMonsterContext ctx;
    ctx.phase = "ENTRY";
    ctx.status = "NEW";
    ctx.calculationDay = calculationDay;
    ctx.targetDay = originalTargetDay;
    ctx.discovery24MonthLengths = monthLengths;
    ctx.discovery24SemanticStructureSauce = structure.semanticStructureSauce;
    ctx.discovery24Patch20Prepared = structure.patch20Applied;
    ctx.discovery24Patch23Prepared = materializationDecision.patchApplied;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyMonthWeavingAdapter adapter;
    const Discovery24MonthWeavingHandler legacyHandler;
    const MonthWeavingPatchWrapper wrapper;
    const Patch24MonthWeavingHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchPatchedMonthWeaving(
        ctx,
        handler,
        legacyHandler,
        adapter,
        wrapper,
        validator,
        metrics);

    return LegacyMonthWeavingReport{
        calculationDay,
        originalTargetDay,
        structure.resolvedYear,
        ctx.discovery24MonthLengths,
        ctx.discovery24AnswerRing,
        ctx.discovery24LegacyGhost,
        ctx.discovery24SemanticWeaving,
        ctx.discovery24Patch20Prepared,
        ctx.discovery24Patch23Prepared,
        ctx.discovery24MultiplicitiesPreserved,
        ctx.discovery24FirstOccurrenceOrderPreserved,
        ctx.discovery24LastOccurrenceOrderPreserved,
        ctx.discovery24WholeWeavingOrderLegal,
        ctx.discovery24LegacyUsedAsSemanticOutput,
        ctx.patch24LegalFamilyCount,
        ctx.patch24WantedRank,
        ctx.patch24CorrectWeaving,
        ctx.patch24LegacyExecuted,
        ctx.patch24CorrectComputed,
        ctx.patch24GhostEqualsCorrect,
        ctx.patch24LegacyReturned,
        ctx.patch24SemanticWholeWeavingOrderLegal,
        ctx.patch24Applied,
        ctx.patch24MonthWeavingReady,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size()
    };
}

LegacyMonthWeavingReport BaseMonsterManager::executeUnpatchedDiscovery24MonthWeavingDiagnostic(
    const LegacyYearAnchor& anchor,
    const Integer& originalTargetDay,
    const Integer& calculationDay,
    const std::vector<int>& monthLengths) const {
    if (monthLengths.size() < 3 || monthLengths.size() > 47) {
        throw BaseValidationError("diagnosticum DISCOVERY 24 inter tres et quadraginta septem menses requirit");
    }
    int localYearLength = 0;
    for (const int length : monthLengths) {
        if (length < LEGACY_MONTH_LENGTH_MIN || length > LEGACY_MONTH_LENGTH_MAX) {
            throw BaseValidationError("diagnosticum DISCOVERY 24 longitudines mensium extra fines historicos habet");
        }
        if (localYearLength > REAL_YEAR_MAX_PATCH - length) {
            throw BaseValidationError("diagnosticum DISCOVERY 24 summam anni nimis magnam habet");
        }
        localYearLength += length;
    }

    const LegacyStructureSauceReport structure = executeDiscovery20StructureSauce(
        anchor,
        originalTargetDay,
        calculationDay);
    if (!structure.ready || !structure.patch20Applied ||
        structure.patch20GhostReachedSelector) {
        throw BaseValidationError("diagnosticum DISCOVERY 24 PATCH 20 sauce semanticam requirit");
    }

    const LegacyMonthLengthMaterializationAdapter materializationAdapter;
    const MonthLengthMaterializationPatchWrapper materializationWrapper;
    const LegacyMonthLengthMaterializationInspection legacyInspection =
        materializationAdapter.inspect(
            localYearLength,
            static_cast<int>(monthLengths.size()));
    const MonthLengthMaterializationPatchDecision materializationDecision =
        materializationWrapper.repair(
            localYearLength,
            static_cast<int>(monthLengths.size()),
            legacyInspection);
    if (!materializationDecision.patchApplied ||
        !materializationDecision.legacyExecuted ||
        !materializationDecision.virtualBackendUsed ||
        !materializationDecision.countMatchesLegacyProof) {
        throw BaseValidationError("diagnosticum DISCOVERY 24 PATCH 23 backend virtualem requirit");
    }

    BaseMonsterContext ctx;
    ctx.phase = "ENTRY";
    ctx.status = "NEW";
    ctx.calculationDay = calculationDay;
    ctx.targetDay = originalTargetDay;
    ctx.discovery24MonthLengths = monthLengths;
    ctx.discovery24SemanticStructureSauce = structure.semanticStructureSauce;
    ctx.discovery24Patch20Prepared = structure.patch20Applied;
    ctx.discovery24Patch23Prepared = materializationDecision.patchApplied;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyMonthWeavingAdapter adapter;
    const Discovery24MonthWeavingHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchDiscovery24MonthWeaving(
        ctx,
        handler,
        adapter,
        validator,
        metrics);

    return LegacyMonthWeavingReport{
        calculationDay,
        originalTargetDay,
        structure.resolvedYear,
        ctx.discovery24MonthLengths,
        ctx.discovery24AnswerRing,
        ctx.discovery24LegacyGhost,
        ctx.discovery24SemanticWeaving,
        ctx.discovery24Patch20Prepared,
        ctx.discovery24Patch23Prepared,
        ctx.discovery24MultiplicitiesPreserved,
        ctx.discovery24FirstOccurrenceOrderPreserved,
        ctx.discovery24LastOccurrenceOrderPreserved,
        ctx.discovery24WholeWeavingOrderLegal,
        ctx.discovery24LegacyUsedAsSemanticOutput,
        {},
        {},
        {},
        false,
        false,
        false,
        false,
        false,
        false,
        ctx.discovery24MonthWeavingReady,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size()
    };
}
LegacyContiguousMonthDayReport BaseMonsterManager::executeDiscovery25ContiguousMonthDay(
    const LegacyYearAnchor& anchor,
    const Integer& originalTargetDay,
    const Integer& calculationDay,
    const std::vector<int>& monthLengths,
    std::size_t targetPosition1) const {
    if (monthLengths.size() < 3 || monthLengths.size() > 47) {
        throw BaseValidationError("DISCOVERY 25 inter tres et quadraginta septem menses requirit");
    }
    int localYearLength = 0;
    for (const int length : monthLengths) {
        if (length < LEGACY_MONTH_LENGTH_MIN || length > LEGACY_MONTH_LENGTH_MAX) {
            throw BaseValidationError("DISCOVERY 25 longitudines mensium extra fines historicos habet");
        }
        if (localYearLength > REAL_YEAR_MAX_PATCH - length) {
            throw BaseValidationError("DISCOVERY 25 summam longitudinum mensium limitem anni excedere non sinit");
        }
        localYearLength += length;
    }
    if (targetPosition1 < 1 ||
        targetPosition1 > static_cast<std::size_t>(localYearLength)) {
        throw BaseValidationError("DISCOVERY 25 positionem target intra texturam anni localis requirit");
    }

    const LegacyStructureSauceReport structure = executeDiscovery20StructureSauce(
        anchor,
        originalTargetDay,
        calculationDay);
    if (!structure.ready || !structure.patch20Applied ||
        structure.patch20GhostReachedSelector) {
        throw BaseValidationError("DISCOVERY 25 PATCH 20 sauce semanticam paratam requirit");
    }

    const LegacyMonthLengthMaterializationAdapter materializationAdapter;
    const MonthLengthMaterializationPatchWrapper materializationWrapper;
    const LegacyMonthLengthMaterializationInspection legacyInspection =
        materializationAdapter.inspect(
            localYearLength,
            static_cast<int>(monthLengths.size()));
    const MonthLengthMaterializationPatchDecision materializationDecision =
        materializationWrapper.repair(
            localYearLength,
            static_cast<int>(monthLengths.size()),
            legacyInspection);
    if (!materializationDecision.patchApplied ||
        !materializationDecision.legacyExecuted ||
        !materializationDecision.virtualBackendUsed ||
        !materializationDecision.countMatchesLegacyProof) {
        throw BaseValidationError("DISCOVERY 25 PATCH 23 backend virtualem paratum requirit");
    }

    BaseMonsterContext ctx;
    ctx.phase = "ENTRY";
    ctx.status = "NEW";
    ctx.calculationDay = calculationDay;
    ctx.targetDay = originalTargetDay;
    ctx.discovery24MonthLengths = monthLengths;
    ctx.discovery24SemanticStructureSauce = structure.semanticStructureSauce;
    ctx.discovery24Patch20Prepared = structure.patch20Applied;
    ctx.discovery24Patch23Prepared = materializationDecision.patchApplied;
    ctx.discovery25TargetPosition1 = targetPosition1;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyMonthWeavingAdapter weavingAdapter;
    const Discovery24MonthWeavingHandler legacyWeavingHandler;
    const MonthWeavingPatchWrapper weavingWrapper;
    const Patch24MonthWeavingHandler weavingHandler;
    const Discovery25ContiguousMonthDayHandler legacyMonthDayHandler;
    const MonthDayOccurrencePatchWrapper monthDayWrapper;
    const Patch25ContiguousMonthDayHandler monthDayHandler;
    const LegacyContiguousMonthDayAdapter monthDayAdapter;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchPatchedMonthWeaving(
        ctx,
        weavingHandler,
        legacyWeavingHandler,
        weavingAdapter,
        weavingWrapper,
        validator,
        metrics);
    dispatcher.dispatchPatchedContiguousMonthDay(
        ctx,
        monthDayHandler,
        legacyMonthDayHandler,
        monthDayAdapter,
        monthDayWrapper,
        validator,
        metrics);

    return LegacyContiguousMonthDayReport{
        calculationDay,
        originalTargetDay,
        structure.resolvedYear,
        ctx.discovery24MonthLengths,
        ctx.discovery24SemanticWeaving,
        ctx.discovery25TargetPosition1,
        ctx.discovery25TargetMonthId,
        ctx.discovery25FirstOccurrencePosition1,
        ctx.discovery25LegacyGuessedDayInMonth,
        ctx.discovery25SemanticDayInMonth,
        ctx.discovery25Patch24Prepared,
        ctx.discovery25LegacyExecuted,
        ctx.discovery25LegacyUsedAsSemanticOutput,
        ctx.patch25CorrectDayInMonth,
        ctx.patch25LegacyExecuted,
        ctx.patch25CorrectComputed,
        ctx.patch25LegacyEqualsCorrect,
        ctx.patch25LegacyReturned,
        ctx.patch25Applied,
        ctx.patch25ContiguousMonthDayReady,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size()
    };
}

LegacyContiguousMonthDayReport
BaseMonsterManager::executeUnpatchedDiscovery25ContiguousMonthDayDiagnostic(
    const LegacyYearAnchor& anchor,
    const Integer& originalTargetDay,
    const Integer& calculationDay,
    const std::vector<int>& monthLengths,
    std::size_t targetPosition1) const {
    if (monthLengths.size() < 3 || monthLengths.size() > 47) {
        throw BaseValidationError("diagnosticum DISCOVERY 25 inter tres et quadraginta septem menses requirit");
    }
    int localYearLength = 0;
    for (const int length : monthLengths) {
        if (length < LEGACY_MONTH_LENGTH_MIN || length > LEGACY_MONTH_LENGTH_MAX) {
            throw BaseValidationError("diagnosticum DISCOVERY 25 longitudines mensium extra fines historicos habet");
        }
        if (localYearLength > REAL_YEAR_MAX_PATCH - length) {
            throw BaseValidationError("diagnosticum DISCOVERY 25 summam longitudinum mensium limitem anni excedere non sinit");
        }
        localYearLength += length;
    }
    if (targetPosition1 < 1 ||
        targetPosition1 > static_cast<std::size_t>(localYearLength)) {
        throw BaseValidationError("diagnosticum DISCOVERY 25 positionem target intra texturam anni localis requirit");
    }

    const LegacyStructureSauceReport structure = executeDiscovery20StructureSauce(
        anchor,
        originalTargetDay,
        calculationDay);
    if (!structure.ready || !structure.patch20Applied ||
        structure.patch20GhostReachedSelector) {
        throw BaseValidationError("diagnosticum DISCOVERY 25 PATCH 20 sauce semanticam paratam requirit");
    }

    const LegacyMonthLengthMaterializationAdapter materializationAdapter;
    const MonthLengthMaterializationPatchWrapper materializationWrapper;
    const LegacyMonthLengthMaterializationInspection legacyInspection =
        materializationAdapter.inspect(
            localYearLength,
            static_cast<int>(monthLengths.size()));
    const MonthLengthMaterializationPatchDecision materializationDecision =
        materializationWrapper.repair(
            localYearLength,
            static_cast<int>(monthLengths.size()),
            legacyInspection);
    if (!materializationDecision.patchApplied ||
        !materializationDecision.legacyExecuted ||
        !materializationDecision.virtualBackendUsed ||
        !materializationDecision.countMatchesLegacyProof) {
        throw BaseValidationError("diagnosticum DISCOVERY 25 PATCH 23 backend virtualem paratum requirit");
    }

    BaseMonsterContext ctx;
    ctx.phase = "ENTRY";
    ctx.status = "NEW";
    ctx.calculationDay = calculationDay;
    ctx.targetDay = originalTargetDay;
    ctx.discovery24MonthLengths = monthLengths;
    ctx.discovery24SemanticStructureSauce = structure.semanticStructureSauce;
    ctx.discovery24Patch20Prepared = structure.patch20Applied;
    ctx.discovery24Patch23Prepared = materializationDecision.patchApplied;
    ctx.discovery25TargetPosition1 = targetPosition1;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyMonthWeavingAdapter weavingAdapter;
    const Discovery24MonthWeavingHandler legacyWeavingHandler;
    const MonthWeavingPatchWrapper weavingWrapper;
    const Patch24MonthWeavingHandler weavingHandler;
    const Discovery25ContiguousMonthDayHandler monthDayHandler;
    const LegacyContiguousMonthDayAdapter monthDayAdapter;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchPatchedMonthWeaving(
        ctx,
        weavingHandler,
        legacyWeavingHandler,
        weavingAdapter,
        weavingWrapper,
        validator,
        metrics);
    dispatcher.dispatchDiscovery25ContiguousMonthDay(
        ctx,
        monthDayHandler,
        monthDayAdapter,
        validator,
        metrics);

    return LegacyContiguousMonthDayReport{
        calculationDay,
        originalTargetDay,
        structure.resolvedYear,
        ctx.discovery24MonthLengths,
        ctx.discovery24SemanticWeaving,
        ctx.discovery25TargetPosition1,
        ctx.discovery25TargetMonthId,
        ctx.discovery25FirstOccurrencePosition1,
        ctx.discovery25LegacyGuessedDayInMonth,
        ctx.discovery25SemanticDayInMonth,
        ctx.discovery25Patch24Prepared,
        ctx.discovery25LegacyExecuted,
        ctx.discovery25LegacyUsedAsSemanticOutput,
        0,
        false,
        false,
        false,
        false,
        false,
        ctx.discovery25ContiguousMonthDayReady,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size()
    };
}

LegacyYearMembershipReport BaseMonsterManager::executeDiscovery26OpeningGateYearMembership(
    const LegacyYearAnchor& anchor,
    const Integer& targetDay,
    const Integer& calculationDay) const {
    if (anchor.firstDay > anchor.lastDay) {
        throw BaseValidationError("PATCH 26 anchor anni fines inversos habet");
    }

    BaseMonsterContext ctx;
    ctx.phase = "ENTRY";
    ctx.status = "NEW";
    ctx.calculationDay = calculationDay;
    ctx.targetDay = targetDay;
    ctx.discovery26MembershipAnchor = anchor;
    ctx.discovery26MembershipTargetDay = targetDay;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyYearMembershipAdapter adapter;
    const Discovery26OpeningGateYearMembershipHandler legacyHandler;
    const OpeningGateMembershipPatchWrapper wrapper;
    const Patch26OpeningGateYearMembershipHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchPatchedOpeningGateYearMembership(
        ctx,
        handler,
        legacyHandler,
        adapter,
        wrapper,
        validator,
        metrics);

    const Patch18YearRecord semanticOutput = ctx.patch26LegacyReturned
        ? ctx.discovery26MembershipOutputYear
        : ctx.patch26CorrectOutputYear;
    LegacyYearMembershipReport report{
        calculationDay,
        anchor,
        targetDay,
        ctx.discovery26MembershipAnchorYear,
        semanticOutput,
        ctx.patch26CorrectForwardSteps,
        ctx.patch26CorrectBackwardSteps,
        targetDay == semanticOutput.openGateDay,
        ctx.discovery26LegacyClosedIntervalAccepted,
        ctx.discovery26LegacyUsedAsSemanticOutput,
        ctx.patch26YearMembershipReady,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size()
    };
    report.legacyOutputYearBeforePatch = ctx.discovery26MembershipOutputYear;
    report.correctOutputYear = ctx.patch26CorrectOutputYear;
    report.legacyForwardStepsBeforePatch = ctx.discovery26MembershipForwardSteps;
    report.legacyBackwardStepsBeforePatch = ctx.discovery26MembershipBackwardSteps;
    report.correctForwardSteps = ctx.patch26CorrectForwardSteps;
    report.correctBackwardSteps = ctx.patch26CorrectBackwardSteps;
    report.patch26LegacyExecuted = ctx.patch26LegacyExecuted;
    report.patch26CorrectComputed = ctx.patch26CorrectComputed;
    report.patch26LegacyEqualsCorrect = ctx.patch26LegacyEqualsCorrect;
    report.patch26LegacyReturned = ctx.patch26LegacyReturned;
    report.patch26AuthoritativeIntervalAccepted =
        ctx.patch26AuthoritativeIntervalAccepted;
    report.patch26Applied = ctx.patch26Applied;
    return report;
}

LegacyYearMembershipReport BaseMonsterManager::executeUnpatchedDiscovery26OpeningGateYearMembershipDiagnostic(
    const LegacyYearAnchor& anchor,
    const Integer& targetDay,
    const Integer& calculationDay) const {
    if (anchor.firstDay > anchor.lastDay) {
        throw BaseValidationError("DISCOVERY 26 anchor anni fines inversos habet");
    }

    BaseMonsterContext ctx;
    ctx.phase = "ENTRY";
    ctx.status = "NEW";
    ctx.calculationDay = calculationDay;
    ctx.targetDay = targetDay;
    ctx.discovery26MembershipAnchor = anchor;
    ctx.discovery26MembershipTargetDay = targetDay;

    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const LegacyYearMembershipAdapter adapter;
    const Discovery26OpeningGateYearMembershipHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchDiscovery26OpeningGateYearMembership(
        ctx,
        handler,
        adapter,
        validator,
        metrics);

    return LegacyYearMembershipReport{
        calculationDay,
        anchor,
        targetDay,
        ctx.discovery26MembershipAnchorYear,
        ctx.discovery26MembershipOutputYear,
        ctx.discovery26MembershipForwardSteps,
        ctx.discovery26MembershipBackwardSteps,
        ctx.discovery26TargetAtOpeningGate,
        ctx.discovery26LegacyClosedIntervalAccepted,
        ctx.discovery26LegacyUsedAsSemanticOutput,
        ctx.discovery26YearMembershipReady,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size()
    };
}

namespace {

LegacyAnswerRing finalIntegrationAnswerRing(
    const Patch11LatchedOrderSauceResult& sauce,
    int queriedBowlId,
    int seal) {
    const int nextBowlId = nextBowlThroughOrderAt46Latch(
        sauce.orderAt46Latch,
        queriedBowlId);
    return answerRingThroughPatchedNextBowl(
        sauce.finalBowls,
        queriedBowlId,
        nextBowlId,
        seal);
}

Integer finalIntegrationChooseRank(
    const LegacyAnswerRing& ring,
    const Integer& familySize) {
    if (familySize < 1) {
        throw BaseValidationError("integratio finalis familiam non vacuam requirit");
    }
    const LegacyBiasedSelectionAdapter adapter;
    const Patch13RejectionWrapper shortWrapper;
    if (familySize <= M_OLD) {
        return shortWrapper.repair(ring, familySize, adapter).outputRank;
    }
    const Patch14WideDetourWrapper wideWrapper;
    return wideWrapper.repair(ring, familySize, adapter).outputRank;
}

std::vector<int> finalIntegrationMasterList(int n) {
    std::vector<int> out;
    out.reserve(static_cast<std::size_t>(n));
    for (int i = 1; i <= n; ++i) {
        out.push_back(i);
    }
    return out;
}

SpaghettiYearStructure buildFinalYearStructure(
    BaseMonsterContext& ctx,
    Patch18YearWalkWorkspace& workspace,
    const Patch18YearRecord& year) {
    SpaghettiYearStructure out;
    const Integer firstDay = year.openGateDay + 1;

    // PATCH 20: ghost ex target originali currit; selector solam sauce firstDay accipit.
    const Patch20StructureSauceResult structurePatch = structureSaucePatch(
        ctx.calculationDay,
        ctx.targetDay,
        year);
    if (!structurePatch.ghostExecuted) {
        throw BaseValidationError("integratio finalis ghost structure sauce requirit");
    }
    ctx.finalLegacyStructureSauceGhostExecuted = true;
    Patch11LatchedOrderSauceResult semanticSauce{};
    if (accelerationsOn()) {
        // PATCH 34: PATCH 20 corpus semanticum sepelitur etiam si Gradus 56
        // generationem eius postea recusabit. Recusatio ipsa cicatrix est.
        scarBump(&PersistentScarMetrics::patch34StructureSauceCorpseBuried);
    }
    if (ctx.stage56CorrectiveRequested) {
        Stage56RawBowlSumSauceResult stage56Sauce{};
        if (accelerationsOn()) {
            scarBump(&PersistentScarMetrics::patch34StructureSauceGenerationRejected);
            // Prima petitio generationis 56 corpus rectum sepelit; secunda petitio
            // infra ritum historicum "recompute" servat, sed ex tumulo resurgit.
            (void)sauceWithStage56RawBowlSumDetour(ctx.calculationDay, firstDay);
            stage56Sauce =
                sauceWithStage56RawBowlSumDetour(ctx.calculationDay, firstDay);
            scarBump(&PersistentScarMetrics::patch34StructureSauceResurrected);
            ctx.patch34StructureSauceResurrectionObserved = true;
        } else {
            stage56Sauce =
                sauceWithStage56RawBowlSumDetour(ctx.calculationDay, firstDay);
        }
        semanticSauce = stage56Sauce.semanticSauce;
        const Stage56PostStirDetourWitness& last = stage56Sauce.stirWitnesses.back();
        ctx.stage56PostStirOldResult = last.oldResult;
        ctx.stage56PostStirCorrectedResult = last.correctedResult;
        ctx.stage56RawBowlSum = last.rawBowlSum;
        ctx.stage56SavedOrderNumber = last.savedOrderNumber;
        ctx.stage56StirIndex = last.stirIndex;
        ctx.stage56LegacyScarCallCount = stage56Sauce.legacyScarCallCount;
        ctx.stage56AppliedCount = stage56Sauce.appliedCount;
        ctx.stage56AppliedFlag = stage56Sauce.applied;
    } else {
        semanticSauce = sauceWithScars(ctx.calculationDay, firstDay);
        if (accelerationsOn()) {
            scarBump(&PersistentScarMetrics::patch34StructureSauceResurrected);
            ctx.patch34StructureSauceResurrectionObserved = true;
        }
    }

    const int gapCount = (year.closeGateIndex - year.openGateIndex).convert_to<int>();
    std::vector<int> cutletCounts;
    for (int k = 6; k <= 17; ++k) {
        if (k <= gapCount) {
            cutletCounts.push_back(k);
        }
    }
    if (cutletCounts.empty()) {
        throw BaseValidationError("integratio finalis nullum numerum segmentorum invenit");
    }
    const LegacyAnswerRing cutletCountRing = finalIntegrationAnswerRing(
        semanticSauce, 2, 20);
    const Integer cutletCountRank = finalIntegrationChooseRank(
        cutletCountRing,
        Integer{cutletCounts.size()});
    out.cutletCount = cutletCounts.at(
        (cutletCountRank - 1).convert_to<std::size_t>());

    const LegacyAnswerRing partitionRing = finalIntegrationAnswerRing(
        semanticSauce, 2, 21);
    const LegacyPositiveCompositionAdapter legacyPartitionAdapter;
    const LegacyPositiveCompositionFamily legacyFamily = legacyPartitionAdapter.family(
        gapCount,
        out.cutletCount);
    const Integer legacyPartitionRank = finalIntegrationChooseRank(
        partitionRing,
        legacyFamily.count);
    const std::vector<int> legacyPartition = legacyPartitionAdapter.unrank(
        legacyFamily,
        legacyPartitionRank);
    ctx.finalLegacyCutletPartitionExecuted = true;

    Integer calculationGateIndex = 0;
    const bool calculationIsGate = workspace.exactGateIndexIfPresent(
        ctx.calculationDay,
        calculationGateIndex);
    const bool internalGate = calculationIsGate &&
        calculationGateIndex > year.openGateIndex &&
        calculationGateIndex < year.closeGateIndex;
    const int internalOffset = internalGate
        ? (calculationGateIndex - year.openGateIndex).convert_to<int>()
        : 0;

    BaseMonsterContext partitionContext;
    partitionContext.discovery21GapCount = gapCount;
    partitionContext.discovery21CutletCount = out.cutletCount;
    partitionContext.discovery21InternalGateOffset = internalOffset;
    partitionContext.discovery21CalculationDayIsInternalGate = internalGate;
    partitionContext.discovery21SelectionRank = legacyPartitionRank;
    partitionContext.discovery21LegacyPartition = legacyPartition;
    const CutletPartitionPatchWrapper partitionWrapper;
    const LegacyBiasedSelectionAdapter selectionAdapter;
    const Patch13RejectionWrapper rejectionWrapper;
    const Patch14WideDetourWrapper wideWrapper;
    const Patch21CutletPartitionResult partitionDecision = partitionWrapper.repair(
        partitionContext,
        partitionRing,
        selectionAdapter,
        rejectionWrapper,
        wideWrapper);
    out.cutletPartition = partitionDecision.semanticPartition;

    const std::vector<int> cutletMaster = finalIntegrationMasterList(17);
    const Integer cutletNameSpace = legacyCutletNameSelectionSpaceCount(
        17,
        out.cutletCount);
    const LegacyAnswerRing cutletNameRing = finalIntegrationAnswerRing(
        semanticSauce, 5, 22);
    const Integer cutletNameRank = finalIntegrationChooseRank(
        cutletNameRing,
        cutletNameSpace);
    const LegacyRepeatedNameGenerator legacyNameGenerator;
    const std::vector<int> badCutletNames = legacyNameGenerator.call(
        cutletMaster,
        cutletNameRank,
        out.cutletCount);
    ctx.finalLegacyCutletNamesExecuted = true;
    const RepeatedNamePatchWrapper repeatedNameWrapper;
    const RepeatedNamePatchDecision cutletNameDecision = repeatedNameWrapper.repair(
        cutletMaster,
        cutletNameRank,
        out.cutletCount,
        badCutletNames);
    out.cutletNameIndices = cutletNameDecision.outputNameIndices;

    Integer cursorGate = year.openGateIndex;
    out.cutlets.reserve(static_cast<std::size_t>(out.cutletCount));
    for (int i = 0; i < out.cutletCount; ++i) {
        const Integer openGateIndex = cursorGate;
        const Integer closeGateIndex = cursorGate + out.cutletPartition.at(
            static_cast<std::size_t>(i));
        out.cutlets.push_back(SpaghettiCutletRecord{
            out.cutletNameIndices.at(static_cast<std::size_t>(i)),
            openGateIndex,
            closeGateIndex,
            workspace.gateDay(openGateIndex) + 1,
            workspace.gateDay(closeGateIndex)
        });
        cursorGate = closeGateIndex;
    }
    if (cursorGate != year.closeGateIndex) {
        throw BaseValidationError("integratio finalis segmenta annum non claudunt");
    }

    const int yearLength = (year.closeGateDay - year.openGateDay).convert_to<int>();
    const int minMonths = (yearLength + LEGACY_MONTH_LENGTH_MAX - 1) /
        LEGACY_MONTH_LENGTH_MAX;
    const int maxMonths = std::min(47, yearLength / LEGACY_MONTH_LENGTH_MIN);
    if (minMonths < 3 || minMonths > maxMonths) {
        throw BaseValidationError("integratio finalis fines numeri mensium invalidos habet");
    }
    const LegacyAnswerRing monthCountRing = finalIntegrationAnswerRing(
        semanticSauce, 3, 30);
    const Integer monthCountRank = finalIntegrationChooseRank(
        monthCountRing,
        Integer{maxMonths - minMonths + 1});
    out.monthCount = minMonths + monthCountRank.convert_to<int>() - 1;

    const LegacyMonthLengthMaterializationAdapter materializationAdapter;
    const Integer rawMonthLengthCount = legacyMonthLengthConcreteFamilyCountProof(
        yearLength,
        out.monthCount);
    LegacyMonthLengthMaterializationInspection legacyMonthLengths;
    if (rawMonthLengthCount <= Integer{10000}) {
        legacyMonthLengths = materializationAdapter.inspect(yearLength, out.monthCount);
    } else {
        legacyMonthLengths.yearLength = yearLength;
        legacyMonthLengths.monthCount = out.monthCount;
        legacyMonthLengths.exactFamilyCount = rawMonthLengthCount;
        legacyMonthLengths.concreteListIndexCapacity = Integer{
            std::numeric_limits<std::size_t>::max()};
        legacyMonthLengths.concreteListContractReached = true;
        legacyMonthLengths.blockedBeforeAllocation = true;
    }
    ctx.finalLegacyMonthLengthListContractExecuted =
        legacyMonthLengths.concreteListContractReached;
    const MonthLengthMaterializationPatchWrapper materializationWrapper;
    const MonthLengthMaterializationPatchDecision materializationDecision =
        materializationWrapper.repair(yearLength, out.monthCount, legacyMonthLengths);
    if (!materializationDecision.patchApplied ||
        !materializationDecision.virtualBackendUsed) {
        throw BaseValidationError("integratio finalis VirtualLegacyList non activavit");
    }
    VirtualLegacyList monthLengthList(yearLength, out.monthCount);
    const LegacyAnswerRing monthLengthRing = finalIntegrationAnswerRing(
        semanticSauce, 3, 31);
    const Integer monthLengthRank = finalIntegrationChooseRank(
        monthLengthRing,
        monthLengthList.count());
    out.monthLengths = monthLengthList.itemAt1(monthLengthRank);

    const LegacyMonthWeavingAdapter weavingAdapter;
    const LegacyMonthWeavingInspection weavingGhost = weavingAdapter.call(
        out.monthLengths,
        semanticSauce);
    ctx.finalLegacyMonthWeavingExecuted = true;
    const MonthWeavingPatchWrapper weavingWrapper;
    const MonthWeavingPatchDecision weavingDecision = weavingWrapper.repair(
        out.monthLengths,
        weavingGhost.answerRing,
        weavingGhost.ghost);
    if (!weavingDecision.patchApplied ||
        !weavingDecision.semanticWholeWeavingOrderLegal) {
        throw BaseValidationError("integratio finalis texturam mensium legalem requirit");
    }
    out.monthWeaving = weavingDecision.outputWeaving;

    const std::vector<int> monthMaster = finalIntegrationMasterList(47);
    const Integer monthNameSpace = legacyCutletNameSelectionSpaceCount(
        47,
        out.monthCount);
    const LegacyAnswerRing monthNameRing = finalIntegrationAnswerRing(
        semanticSauce, 5, 33);
    const Integer monthNameRank = finalIntegrationChooseRank(
        monthNameRing,
        monthNameSpace);
    const std::vector<int> badMonthNames = legacyNameGenerator.call(
        monthMaster,
        monthNameRank,
        out.monthCount);
    ctx.finalLegacyMonthNamesExecuted = true;
    const RepeatedNamePatchDecision monthNameDecision = repeatedNameWrapper.repair(
        monthMaster,
        monthNameRank,
        out.monthCount,
        badMonthNames);
    out.monthNameIndices = monthNameDecision.outputNameIndices;

    return out;
}

} // namespace

void BaseValidationManager::requireFinalIntegrationReady(
    const BaseMonsterContext& ctx) const {
    if (!ctx.finalIntegrationReady ||
        !ctx.finalExactFiveFieldReturn ||
        !ctx.finalLegacyContiguousMonthDayExecuted) {
        throw BaseValidationError("integratio finalis omnes cicatrices et exitum quinque camporum requirit");
    }
    if (!ctx.finalGuardedCacheHit && !ctx.patch27AncestralHit &&
        (!ctx.finalLegacyStructureSauceGhostExecuted ||
         !ctx.finalLegacyCutletPartitionExecuted ||
         !ctx.finalLegacyCutletNamesExecuted ||
         !ctx.finalLegacyMonthLengthListContractExecuted ||
         !ctx.finalLegacyMonthWeavingExecuted ||
         !ctx.finalLegacyMonthNamesExecuted)) {
        throw BaseValidationError("integratio finalis structuram non-cached per omnes cicatrices aedificare debet");
    }
    if (!(ctx.finalCurrentYear.openGateDay < ctx.targetDay &&
          ctx.targetDay <= ctx.finalCurrentYear.closeGateDay)) {
        throw BaseValidationError("integratio finalis target extra annum (open,close] habet");
    }
    if (ctx.resultFive.cutletName.empty() || ctx.resultFive.monthName.empty() ||
        ctx.resultFive.dayInCutlet < 1 || ctx.resultFive.dayInMonth < 1) {
        throw BaseValidationError("integratio finalis quinque campos invalidos habet");
    }
    // PATCH 27 REMEMBERED-SCAR VALIDATION: structura iam sepulta/cache-validata
    // non debet duodecim cicatrices CPU iterum fingere. Via non-cached adhuc
    // plenam ceremoniam Gradus 56 probat; cache/resurrectio corpus iam probatum
    // tantum recognoscit.
    if (ctx.stage56CorrectiveRequested &&
        !ctx.finalGuardedCacheHit && !ctx.patch27AncestralHit &&
        (!ctx.stage56AppliedFlag ||
         ctx.stage56LegacyScarCallCount != 12 ||
         ctx.stage56AppliedCount != 12 ||
         ctx.stage56StirIndex != 12)) {
        throw BaseValidationError(
            "integratio finalis Gradus 56 duodecim cicatrices raw bowl sum requirit");
    }
}

void FinalIntegrationHandler::handle(
    BaseMonsterContext& ctx,
    std::map<Integer, FinalStructureCacheEntry>& structureCache,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics,
    const FinalIntegrationFaultPlan& faultPlan) const {
    if (faultPlan.recoverableFailuresToInject < 0) {
        throw BaseValidationError("numerus defectuum recoverabilium negativus esse non potest");
    }
    if (faultPlan.retryBudget < 0) {
        throw BaseValidationError("retryBudget negativus esse non potest");
    }
    if (faultPlan.injectionStage != 40 && faultPlan.injectionStage != 50) {
        throw BaseValidationError("gradus injectionis recovery debet esse 40 aut 50");
    }

    ctx.mode = "AUTHORITATIVE_SPAGHETTI";
    ctx.status = "NEW";
    ctx.retryBudget = faultPlan.retryBudget;
    ctx.recoveryDepth = 0;
    ctx.finalRecoverableFailuresObserved = 0;
    ctx.finalRecoverySnapshotRestoredExactly = false;
    int stage = 0;
    Patch18YearWalkWorkspace workspace(
        ctx.calculationDay,
        ctx.stage56CorrectiveRequested);
    Patch18YearRecord year5000{};
    Patch18YearRecord targetYear{};
    SpaghettiYearStructure structure{};
    bool cacheReady = false;
    bool pendingCacheWrite = false;
    FinalStructureCacheEntry pendingCacheEntry{};
    int injectedFailuresRemaining = faultPlan.recoverableFailuresToInject;
    int failuresObserved = 0;
    int recoveryDepth = 0;
    bool snapshotRestoredExactly = false;

    goto FINAL_MAIN_DISPATCH;

FINAL_MAIN_DISPATCH:
    ctx.subPhase = stage;
    ctx.branchTrace.push_back("FINAL_MAIN_" + std::to_string(stage));
    if (stage == 0) goto FINAL_MAIN_VALIDATE_INPUT;
    if (stage == 10) goto FINAL_MAIN_YEAR_5000;
    if (stage == 20) goto FINAL_MAIN_YEAR_WALK;
    if (stage == 30) goto FINAL_MAIN_CACHE;
    if (stage == 40) goto FINAL_MAIN_STRUCTURE;
    if (stage == 50) goto FINAL_MAIN_FINALIZE;
    if (stage == 60) goto FINAL_MAIN_VALIDATE_OUTPUT;
    throw BaseValidationError("status integrationis finalis ignotus est");

FINAL_MAIN_VALIDATE_INPUT:
    ctx.phase = "FINAL_ENTRY";
    ctx.previousHandler = ctx.currentHandler;
    ctx.currentHandler = "FinalIntegrationHandler";
    metrics.bump(ctx, "final.calls");
    stage = 10;
    goto FINAL_MAIN_DISPATCH;

FINAL_MAIN_YEAR_5000:
    ctx.phase = "FINAL_YEAR_5000";
    year5000 = workspace.finalYear5000();
    ctx.finalYear5000 = year5000;
    stage = 20;
    goto FINAL_MAIN_DISPATCH;

FINAL_MAIN_YEAR_WALK: {
    ctx.phase = "FINAL_YEAR_WALK";
    const LegacyYearAnchor anchor{
        year5000.number,
        year5000.openGateDay + 1,
        year5000.closeGateDay
    };
    (void)oldJumpGuess(anchor, ctx.targetDay);
    const LegacyYearMembershipAdapter legacyMembership;
    LegacyYearMembershipInspection legacyInspection{};
    if (ctx.stage56CorrectiveRequested) {
        // Cicatrix historica membership manet in geometria Gradus 55; non cogitur
        // anchor correctionis Gradus 56 quasi portam veterem agnoscere.
        Patch18YearWalkWorkspace historicalWorkspace(ctx.calculationDay, false);
        const Patch18YearRecord historicalYear5000 = historicalWorkspace.finalYear5000();
        const LegacyYearAnchor historicalAnchor{
            historicalYear5000.number,
            historicalYear5000.openGateDay + 1,
            historicalYear5000.closeGateDay
        };
        legacyInspection = legacyMembership.resolve(
            ctx.calculationDay,
            historicalAnchor,
            ctx.targetDay);
    } else {
        legacyInspection = legacyMembership.resolve(
            ctx.calculationDay,
            anchor,
            ctx.targetDay);
    }
    const OpeningGateMembershipPatchWrapper membershipWrapper;
    const Patch26YearMembershipDecision membershipDecision = membershipWrapper.repair(
        ctx.calculationDay,
        anchor,
        ctx.targetDay,
        legacyInspection,
        ctx.stage56CorrectiveRequested);
    if (!membershipDecision.patchApplied ||
        !membershipDecision.authoritativeIntervalAccepted) {
        throw BaseValidationError("integratio finalis PATCH 26 annum non confirmavit");
    }
    targetYear = membershipDecision.outputYear;
    ctx.finalCurrentYear = targetYear;
    stage = 30;
    goto FINAL_MAIN_DISPATCH;
}

FINAL_MAIN_CACHE: {
    ctx.phase = "FINAL_GUARDED_CACHE";
    const auto found = structureCache.find(targetYear.number);
    if (found != structureCache.end()) {
        const FinalStructureCacheEntry& entry = found->second;
        const bool fingerprint = entry.calculationDayFingerprint == ctx.calculationDay;
        const bool open = entry.openGate == targetYear.openGateDay;
        const bool close = entry.closeGate == targetYear.closeGateDay;
        if (fingerprint && open && close) {
            structure = entry.value;
            ctx.finalGuardedCacheHit = true;
            cacheReady = true;
        } else {
            // Cicatrix key year-number-only manet; entry vetus ante validationem non mutatur.
            ctx.finalGuardedCacheRejected = true;
        }
    }

    if (!cacheReady && accelerationsOn()) {
        // PATCH 27: cache localis mortuus non fingitur HIT. Ex sepulcro externo
        // tantum post miss localem resurrectio temptatur.
        const StructureVaultKey vaultKey{
            ctx.stage56CorrectiveRequested,
            ctx.calculationDay,
            targetYear.number,
            targetYear.openGateDay,
            targetYear.closeGateDay
        };
        BuriedFinalStructure corpse{};
        bool corpseFound = false;
        {
            std::lock_guard<std::mutex> guard(ancestralMemoryVaultMutex);
            const auto ancestor = ancestralMemoryVault.find(vaultKey);
            if (ancestor != ancestralMemoryVault.end()) {
                if (!ancestor->second.poisoned &&
                    ancestor->second.calculationDayFingerprint == ctx.calculationDay &&
                    ancestor->second.yearNumber == targetYear.number &&
                    ancestor->second.openGate == targetYear.openGateDay &&
                    ancestor->second.closeGate == targetYear.closeGateDay &&
                    ancestor->second.stage56 == ctx.stage56CorrectiveRequested &&
                    fingerprintAcceptable(
                        ancestor->second.semanticFingerprint,
                        static_cast<std::uint64_t>(ancestor->second.burialGeneration),
                        27)) {
                    corpse = ancestor->second;
                    ++ancestor->second.resurrectionCount;
                    corpseFound = true;
                } else {
                    ancestor->second.poisoned = true;
                    ctx.patch27RejectedCorpse = true;
                    scarBump(&PersistentScarMetrics::patch27RejectedCorpse);
                    scarBump(&PersistentScarMetrics::staleOrPoisonedRejected);
                }
            }
        }
        if (corpseFound) {
            structure = corpse.value;
            cacheReady = true;
            ctx.patch27AncestralHit = true;
            ctx.branchTrace.push_back("PATCH27_ANCESTRAL_CORPSE_RESURRECTED");
            scarBump(&PersistentScarMetrics::patch27AncestralHit);
            scarBump(&PersistentScarMetrics::patch27ResurrectionCount);
            pendingCacheEntry = FinalStructureCacheEntry{
                ctx.calculationDay,
                targetYear.openGateDay,
                targetYear.closeGateDay,
                structure
            };
            pendingCacheWrite = true;
        } else {
            ctx.patch27AncestralMiss = true;
            ctx.branchTrace.push_back("PATCH27_ANCESTRAL_TOMB_EMPTY");
            scarBump(&PersistentScarMetrics::patch27AncestralMiss);
        }
    }
    stage = cacheReady ? 50 : 40;
    goto FINAL_MAIN_DISPATCH;
}

FINAL_MAIN_STRUCTURE:
    if (faultPlan.injectionStage == 40 && injectedFailuresRemaining > 0) {
        const BaseMonsterContext ctxSnapshot = ctx;
        const Patch18YearRecord year5000Snapshot = year5000;
        const Patch18YearRecord targetYearSnapshot = targetYear;
        const SpaghettiYearStructure structureSnapshot = structure;
        const bool cacheReadySnapshot = cacheReady;
        const bool pendingCacheWriteSnapshot = pendingCacheWrite;
        const FinalStructureCacheEntry pendingCacheEntrySnapshot = pendingCacheEntry;
        try {
            --injectedFailuresRemaining;
            throw BaseRecoverableError("defectus recoverabilis artificialis in structura finali");
        } catch (const BaseRecoverableError&) {
            ctx = ctxSnapshot;
            year5000 = year5000Snapshot;
            targetYear = targetYearSnapshot;
            structure = structureSnapshot;
            cacheReady = cacheReadySnapshot;
            pendingCacheWrite = pendingCacheWriteSnapshot;
            pendingCacheEntry = pendingCacheEntrySnapshot;
            ++failuresObserved;
            ++recoveryDepth;
            snapshotRestoredExactly = true;
            ctx.finalRecoverableFailuresObserved = failuresObserved;
            ctx.recoveryDepth = recoveryDepth;
            ctx.finalRecoverySnapshotRestoredExactly = true;
            metrics.bump(ctx, "final.recoverableError");
            if (ctx.retryBudget <= 0) {
                ctx.status = "FAILED_RETRY_EXHAUSTED";
                throw BaseRecoverableError("retry finalis exhaustum est post defectum recoverabilem");
            }
            --ctx.retryBudget;
            stage = 40;
            goto FINAL_MAIN_DISPATCH;
        }
    }
    ctx.phase = "FINAL_STRUCTURE_BUILD";
    structure = buildFinalYearStructure(ctx, workspace, targetYear);
    pendingCacheEntry = FinalStructureCacheEntry{
        ctx.calculationDay,
        targetYear.openGateDay,
        targetYear.closeGateDay,
        structure
    };
    pendingCacheWrite = true;
    stage = 50;
    goto FINAL_MAIN_DISPATCH;

FINAL_MAIN_FINALIZE: {
    if (faultPlan.injectionStage == 50 && injectedFailuresRemaining > 0) {
        const BaseMonsterContext ctxSnapshot = ctx;
        const Patch18YearRecord year5000Snapshot = year5000;
        const Patch18YearRecord targetYearSnapshot = targetYear;
        const SpaghettiYearStructure structureSnapshot = structure;
        const bool cacheReadySnapshot = cacheReady;
        const bool pendingCacheWriteSnapshot = pendingCacheWrite;
        const FinalStructureCacheEntry pendingCacheEntrySnapshot = pendingCacheEntry;
        try {
            --injectedFailuresRemaining;
            throw BaseRecoverableError("defectus recoverabilis artificialis ante validationem finalem");
        } catch (const BaseRecoverableError&) {
            ctx = ctxSnapshot;
            year5000 = year5000Snapshot;
            targetYear = targetYearSnapshot;
            structure = structureSnapshot;
            cacheReady = cacheReadySnapshot;
            pendingCacheWrite = pendingCacheWriteSnapshot;
            pendingCacheEntry = pendingCacheEntrySnapshot;
            ++failuresObserved;
            ++recoveryDepth;
            snapshotRestoredExactly = true;
            ctx.finalRecoverableFailuresObserved = failuresObserved;
            ctx.recoveryDepth = recoveryDepth;
            ctx.finalRecoverySnapshotRestoredExactly = true;
            metrics.bump(ctx, "final.recoverableError");
            if (ctx.retryBudget <= 0) {
                ctx.status = "FAILED_RETRY_EXHAUSTED";
                throw BaseRecoverableError("retry finalis exhaustum est post defectum recoverabilem");
            }
            --ctx.retryBudget;
            stage = 50;
            goto FINAL_MAIN_DISPATCH;
        }
    }
    ctx.phase = "FINAL_FIVE_FIELDS";
    ctx.finalStructure = structure;
    const SpaghettiCutletRecord* chosenCutlet = nullptr;
    for (const SpaghettiCutletRecord& cutlet : structure.cutlets) {
        if (cutlet.firstDay <= ctx.targetDay && ctx.targetDay <= cutlet.lastDay) {
            chosenCutlet = &cutlet;
            break;
        }
    }
    if (chosenCutlet == nullptr) {
        throw BaseValidationError("integratio finalis segmentum target invenire non potuit");
    }
    const Integer dayInCutlet = ctx.targetDay - chosenCutlet->firstDay + 1;
    const Integer positionInteger = ctx.targetDay - targetYear.openGateDay;
    if (positionInteger < 1 ||
        positionInteger > Integer{structure.monthWeaving.size()}) {
        throw BaseValidationError("integratio finalis positio target in textura extra fines est");
    }
    const std::size_t position1 = positionInteger.convert_to<std::size_t>();
    const int monthId = structure.monthWeaving.at(position1 - 1);
    if (monthId < 1 || monthId > structure.monthCount) {
        throw BaseValidationError("integratio finalis monthId extra fines est");
    }
    const LegacyContiguousMonthDayAdapter contiguousAdapter;
    const LegacyContiguousMonthDayInspection contiguousGhost = contiguousAdapter.call(
        structure.monthWeaving,
        position1);
    ctx.finalLegacyContiguousMonthDayExecuted = contiguousGhost.legacyExecuted;
    const MonthDayOccurrencePatchWrapper occurrenceWrapper;
    const MonthDayOccurrencePatchDecision occurrenceDecision = occurrenceWrapper.repair(
        structure.monthWeaving,
        position1,
        contiguousGhost.guessedDayInMonth);
    if (!occurrenceDecision.patchApplied) {
        throw BaseValidationError("integratio finalis PATCH 25 diem mensis non reparavit");
    }
    const int cutletIndex = chosenCutlet->canonicalIndex;
    const int monthNameIndex = structure.monthNameIndices.at(
        static_cast<std::size_t>(monthId - 1));
    ctx.resultFive = SpaghettiDateFive{
        targetYear.number,
        std::string(cutletSourceName(static_cast<std::size_t>(cutletIndex))),
        dayInCutlet,
        std::string(monthSourceName(static_cast<std::size_t>(monthNameIndex))),
        Integer{occurrenceDecision.outputDayInMonth}
    };
    ctx.finalExactFiveFieldReturn = true;
    ctx.finalIntegrationReady = true;
    stage = 60;
    goto FINAL_MAIN_DISPATCH;
}

FINAL_MAIN_VALIDATE_OUTPUT:
    ctx.phase = "FINAL_VALIDATE";
    validator.requireFinalIntegrationReady(ctx);
    if (pendingCacheWrite) {
        structureCache[targetYear.number] = pendingCacheEntry;
        pendingCacheWrite = false;
    }
    if (accelerationsOn()) {
        const StructureVaultKey vaultKey{
            ctx.stage56CorrectiveRequested,
            ctx.calculationDay,
            targetYear.number,
            targetYear.openGateDay,
            targetYear.closeGateDay
        };
        const BuriedFinalStructure burial{
            ctx.calculationDay,
            targetYear.number,
            targetYear.openGateDay,
            targetYear.closeGateDay,
            structure,
            0,
            27,
            ctx.stage56CorrectiveRequested,
            false,
            persistentSemanticFingerprint()
        };
        std::lock_guard<std::mutex> guard(ancestralMemoryVaultMutex);
        const auto existing = ancestralMemoryVault.find(vaultKey);
        if (existing == ancestralMemoryVault.end() || existing->second.poisoned) {
            boundedEraseFirst(ancestralMemoryVault, ANCESTRAL_STRUCTURE_LIMIT);
            ancestralMemoryVault[vaultKey] = burial;
            ctx.patch27BuriedStructure = true;
            scarBump(&PersistentScarMetrics::patch27BuriedStructure);
        }
    }
    ctx.finalRecoverableFailuresObserved = failuresObserved;
    ctx.recoveryDepth = recoveryDepth;
    ctx.finalRecoverySnapshotRestoredExactly = snapshotRestoredExactly;
    ctx.status = "GREEN";
    metrics.bump(ctx, "final.success");
    return;
}

void BaseDispatcher::dispatchFinalIntegration(
    BaseMonsterContext& ctx,
    std::map<Integer, FinalStructureCacheEntry>& structureCache,
    const FinalIntegrationHandler& handler,
    const BaseValidationManager& validator,
    const BaseMetricsShell& metrics,
    const FinalIntegrationFaultPlan& faultPlan) const {
    ctx.previousHandler = ctx.currentHandler;
    ctx.currentHandler = "BaseDispatcher::dispatchFinalIntegration";
    ctx.branchTrace.push_back("DISPATCH_FINAL_INTEGRATION");
    handler.handle(ctx, structureCache, validator, metrics, faultPlan);
}

Stage54IntegrationReport BaseMonsterManager::executeFinalIntegration(
    const Integer& calculationDay,
    const Integer& targetDay) const {
    return executeFinalIntegrationRecoveryAudit(
        calculationDay,
        targetDay,
        FinalIntegrationFaultPlan{});
}

Stage54IntegrationReport BaseMonsterManager::executeFinalIntegrationRecoveryAudit(
    const Integer& calculationDay,
    const Integer& targetDay,
    const FinalIntegrationFaultPlan& faultPlan) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = calculationDay;
    ctx.targetDay = targetDay;
    ctx.phase = "ENTRY";
    ctx.status = "NEW";
    ctx.mode = "AUTHORITATIVE_SPAGHETTI";
    ctx.retryBudget = faultPlan.retryBudget;
    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const FinalIntegrationHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchFinalIntegration(
        ctx,
        finalStructureCache_,
        handler,
        validator,
        metrics,
        faultPlan);
    return Stage54IntegrationReport{
        ctx.resultFive,
        ctx.finalYear5000,
        ctx.finalCurrentYear,
        ctx.finalStructure,
        ctx.finalGuardedCacheHit,
        ctx.finalGuardedCacheRejected,
        ctx.finalLegacyStructureSauceGhostExecuted,
        ctx.finalLegacyCutletPartitionExecuted,
        ctx.finalLegacyCutletNamesExecuted,
        ctx.finalLegacyMonthLengthListContractExecuted,
        ctx.finalLegacyMonthWeavingExecuted,
        ctx.finalLegacyMonthNamesExecuted,
        ctx.finalLegacyContiguousMonthDayExecuted,
        ctx.finalExactFiveFieldReturn,
        ctx.finalIntegrationReady,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size(),
        ctx.retryBudget,
        ctx.recoveryDepth,
        ctx.finalRecoverableFailuresObserved,
        ctx.finalRecoverySnapshotRestoredExactly
    };
}

Stage54IntegrationReport BaseMonsterManager::executeFinalIntegrationStage56(
    const Integer& calculationDay,
    const Integer& targetDay) const {
    return executeFinalIntegrationStage56RecoveryAudit(
        calculationDay,
        targetDay,
        FinalIntegrationFaultPlan{});
}

Stage54IntegrationReport BaseMonsterManager::executeFinalIntegrationStage56RecoveryAudit(
    const Integer& calculationDay,
    const Integer& targetDay,
    const FinalIntegrationFaultPlan& faultPlan) const {
    BaseMonsterContext ctx;
    ctx.calculationDay = calculationDay;
    ctx.targetDay = targetDay;
    ctx.phase = "ENTRY";
    ctx.status = "NEW";
    ctx.mode = "AUTHORITATIVE_SPAGHETTI_GRADUS_56";
    ctx.retryBudget = faultPlan.retryBudget;
    ctx.stage56CorrectiveRequested = true;
    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    const FinalIntegrationHandler handler;
    const BaseDispatcher dispatcher;
    dispatcher.dispatchFinalIntegration(
        ctx,
        stage56FinalStructureCache_,
        handler,
        validator,
        metrics,
        faultPlan);
    return Stage54IntegrationReport{
        ctx.resultFive,
        ctx.finalYear5000,
        ctx.finalCurrentYear,
        ctx.finalStructure,
        ctx.finalGuardedCacheHit,
        ctx.finalGuardedCacheRejected,
        ctx.finalLegacyStructureSauceGhostExecuted,
        ctx.finalLegacyCutletPartitionExecuted,
        ctx.finalLegacyCutletNamesExecuted,
        ctx.finalLegacyMonthLengthListContractExecuted,
        ctx.finalLegacyMonthWeavingExecuted,
        ctx.finalLegacyMonthNamesExecuted,
        ctx.finalLegacyContiguousMonthDayExecuted,
        ctx.finalExactFiveFieldReturn,
        ctx.finalIntegrationReady,
        ctx.phase,
        ctx.status,
        ctx.currentHandler,
        ctx.branchTrace.size(),
        ctx.retryBudget,
        ctx.recoveryDepth,
        ctx.finalRecoverableFailuresObserved,
        ctx.finalRecoverySnapshotRestoredExactly
    };
}

std::size_t BaseMonsterManager::finalStructureCacheSizeDiagnostic() const {
    return finalStructureCache_.size();
}

std::size_t BaseMonsterManager::stage56FinalStructureCacheSizeDiagnostic() const {
    return stage56FinalStructureCache_.size();
}

SpaghettiDateFive calendarDateSpaghetti(
    const Integer& calculationDay,
    const Integer& targetDay) {
    // PATCH 39: modo accelerationum exstincto API ipsa cicatrix historica manet
    // physice et executable: manager nascitur, operatur, moritur.
    if (!accelerationsOn()) {
        BaseMonsterManager manager;
        return manager.executeFinalIntegrationStage56(calculationDay, targetDay).result;
    }

    const FinalResultKey key{
        calculationDay, targetDay, PERSISTENT_SCAR_GENERATION};
    if (accelerationsOn()) {
        BuriedFinalResult corpse{};
        bool foundCorpse = false;
        {
            std::lock_guard<std::mutex> guard(finalResultBurialVaultMutex);
            const auto found = finalResultBurialVault.find(key);
            if (found != finalResultBurialVault.end()) {
                if (!found->second.poisoned &&
                    fingerprintAcceptable(
                        found->second.semanticFingerprint,
                        found->second.scarGeneration,
                        39)) {
                    corpse = found->second;
                    foundCorpse = true;
                } else if (!found->second.poisoned) {
                    found->second.poisoned = true;
                    scarBump(&PersistentScarMetrics::staleOrPoisonedRejected);
                }
            }
        }
        if (foundCorpse && !fullHistoricalValidationOn()) {
            scarBump(&PersistentScarMetrics::patch39FinalResultHit);
            return corpse.value;
        }
        if (foundCorpse && fullHistoricalValidationOn()) {
            BaseMonsterManager validatingManager;
            const SpaghettiDateFive rebuilt = validatingManager
                .executeFinalIntegrationStage56(calculationDay, targetDay).result;
            const bool equal =
                rebuilt.yearNumber == corpse.value.yearNumber &&
                rebuilt.cutletName == corpse.value.cutletName &&
                rebuilt.dayInCutlet == corpse.value.dayInCutlet &&
                rebuilt.monthName == corpse.value.monthName &&
                rebuilt.dayInMonth == corpse.value.dayInMonth;
            if (equal) {
                scarBump(&PersistentScarMetrics::patch39FinalResultHit);
                return corpse.value;
            }
            {
                std::lock_guard<std::mutex> guard(finalResultBurialVaultMutex);
                const auto found = finalResultBurialVault.find(key);
                if (found != finalResultBurialVault.end()) found->second.poisoned = true;
            }
            scarBump(&PersistentScarMetrics::staleOrPoisonedRejected);
            return rebuilt;
        }
        scarBump(&PersistentScarMetrics::patch39FinalResultMiss);
    }

    // Manager temporarius consulto manet. PATCH 39 sepulcrum extra vitam eius est.
    BaseMonsterManager manager;
    const SpaghettiDateFive rebuilt =
        manager.executeFinalIntegrationStage56(calculationDay, targetDay).result;

    if (accelerationsOn()) {
        const BuriedFinalResult burial{
            rebuilt,
            false,
            39,
            persistentSemanticFingerprint()
        };
        std::lock_guard<std::mutex> guard(finalResultBurialVaultMutex);
        const auto existing = finalResultBurialVault.find(key);
        if (existing == finalResultBurialVault.end() || existing->second.poisoned) {
            boundedEraseFirst(finalResultBurialVault, FINAL_RESULT_BURIAL_LIMIT);
            finalResultBurialVault[key] = burial;
        }
    }
    return rebuilt;
}

#ifdef PASTAFARI_INTERNAL_SCAR_POISON_ORACLE
bool poisonPatch33AutopsyCorpseForCI() {
    // Tribunal tantum: corpus diagnosticum corrumpitur et Patch32 tumulus
    // evacuatur, ne sepultura exterior autopsiam venenatam occultet.
    bool poisoned = false;
    {
        std::lock_guard<std::mutex> guard(sauceAutopsyVaultMutex);
        for (auto& entry : sauceAutopsyVault) {
            entry.second.semanticFingerprint = "CORPUS_VETUS_PATCH33";
            poisoned = true;
        }
    }
    {
        std::lock_guard<std::mutex> guard(sauceTombMutex);
        sauceTomb.clear();
    }
    return poisoned;
}

bool poisonPatch27AncestralCorpseForCI() {
    bool poisoned = false;
    std::lock_guard<std::mutex> guard(ancestralMemoryVaultMutex);
    for (auto& entry : ancestralMemoryVault) {
        entry.second.semanticFingerprint = "CORPUS_VETUS_PATCH27";
        poisoned = true;
    }
    return poisoned;
}

bool poisonPatch39FinalCorpseForCI() {
    bool poisoned = false;
    std::lock_guard<std::mutex> guard(finalResultBurialVaultMutex);
    for (auto& entry : finalResultBurialVault) {
        entry.second.semanticFingerprint = "CORPUS_VETUS_PATCH39";
        poisoned = true;
    }
    return poisoned;
}
#endif

SpaghettiDateFive calendarDateSpaghettiThroughStage55(
    const Integer& calculationDay,
    const Integer& targetDay) {
    BaseMonsterManager manager;
    return manager.executeFinalIntegration(calculationDay, targetDay).result;
}

void BaseMonsterManager::clearLegacyYearNumberCacheDiagnostic() const { legacyYearNumberCache_.clear(); }

} // namespace pastafari
