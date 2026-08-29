#pragma once

#include <array>
#include <boost/multiprecision/cpp_int.hpp>
#include <map>
#include <stdexcept>
#include <string>
#include <vector>

namespace pastafari {

using Integer = boost::multiprecision::cpp_int;

inline const Integer M_OLD = (Integer{1} << 127) - 1;
inline const Integer FOUNDATION_DAY_OLD = Integer{-15055671};

Integer regularMod(const Integer& x, const Integer& d);
Integer oldRemainder(const Integer& x);
Integer savePatch(const Integer& x);
Integer oldDayTag(const Integer& day);
Integer dayTagWithFoundationScar(const Integer& day);
Integer oldDistance(const Integer& calculationDay, const Integer& targetDay);
Integer distanceWithChronologicalPatch(const Integer& calculationDay,
                                       const Integer& targetDay,
                                       const Integer& legacyDistance);

using Stone = std::array<Integer, 5>;
using StoneTable = std::array<Stone, 47>;
using HiddenDrops = std::array<Integer, 7>;
using VisibleDropStore = std::vector<Integer>;
using PermutationOrder = std::array<int, 6>;
using BowlState = std::array<Integer, 6>;
using PourTriplet = std::array<Integer, 3>;
using BowlAlias = std::array<int, 6>;

enum class GrindStoneKind {
    NONE = -1,
    WHEAT = 0,
    BARLEY = 1,
    SALT = 2,
    BITTER = 3,
    RED = 4
};

struct VisibleGrindRow {
    GrindStoneKind kind = GrindStoneKind::WHEAT;
    int a = 0;
    int b = 0;
    int c = 0;
    int d = 0;
};

struct LegacyGrindLookup {
    VisibleGrindRow row{};
    int physicalIndex = -1;
    bool found = false;
};

const std::array<VisibleGrindRow, 11>& legacyVisibleGrindTableZeroBased();
LegacyGrindLookup legacyGrindRow(int grind);
const std::array<VisibleGrindRow, 12>& grindTableWithSentinel();
LegacyGrindLookup grindRowWithSentinel(int grind);
PermutationOrder oldPermutationUnrank0(int rank0);

struct LegacyFixedPourComputation {
    PermutationOrder order{};
    std::array<int, 3> fixedBowlIds{{1, 2, 3}};
    PourTriplet pours{};
};

struct BowlAliasPourComputation {
    BowlAlias bowlAlias{};
    std::array<int, 3> aliasedBowlIds{{1, 2, 3}};
    PourTriplet pours{};
};

LegacyFixedPourComputation legacyPoursToFixedBowlIds(const Integer& drop,
                                                     int index,
                                                     const BowlState& oldBowls,
                                                     const Stone& stoneRow);
BowlAlias installBowlAlias(const PermutationOrder& order);
Integer bowlAtAliasedPosition(const BowlState& oldBowls,
                              const BowlAlias& bowlAlias,
                              int position);
BowlAliasPourComputation poursThroughBowlAlias(const Integer& drop,
                                               int index,
                                               const BowlState& oldBowls,
                                               const Stone& stoneRow,
                                               const PermutationOrder& order);
struct Patch10DeferredBowlComputation {
    BowlState vaultOld{};
    BowlState pending{};
    BowlState output{};
};

struct LegacySauceCounts {
    Integer action{};
    Integer target{};
    Integer distance{};
    Integer connection{};
    int direction = 0;
};

struct LegacyOrderMemorySauceResult {
    BowlState finalBowls{};
    PermutationOrder queryOrder{};
    PermutationOrder orderAtDrop46Diagnostic{};
    PermutationOrder finalPostStirOrder{};
    std::size_t orderWriteCount = 0;
    std::string finalOrderSource;
};

struct Patch11LatchedOrderSauceResult {
    BowlState finalBowls{};
    PermutationOrder queryOrder{};
    PermutationOrder orderAt46Latch{};
    PermutationOrder legacyQueryOrderBeforePatch{};
    PermutationOrder finalPostStirOrder{};
    std::size_t legacyOrderWriteCount = 0;
    std::size_t latchWriteCount = 0;
    std::string finalLegacyOrderSource;
};

Patch10DeferredBowlComputation stirBowlsThroughVaultOld(const BowlState& bowls,
                                                        int index,
                                                        const Integer& drop,
                                                        const Stone& stoneRow,
                                                        const PermutationOrder& order,
                                                        const PourTriplet& firstThreePours);

void legacyStirBowlsInPlace(BowlState& bowls,
                            int index,
                            const Integer& drop,
                            const Stone& stoneRow,
                            const PermutationOrder& order,
                            const PourTriplet& firstThreePours);

LegacySauceCounts sauceCountsThroughScars(const Integer& calculationDay,
                                          const Integer& targetDay);
VisibleDropStore buildVisibleDropsThroughPatchedHistory(const LegacySauceCounts& counts,
                                                        const StoneTable& stones,
                                                        const HiddenDrops& backwardStorage);
BowlState initialBowlsThroughCounts(const LegacySauceCounts& counts);
LegacyOrderMemorySauceResult legacySauceWithOverwritableOrderMemory(
    const Integer& calculationDay,
    const Integer& targetDay);
Patch11LatchedOrderSauceResult sauceWithOrderAt46Latch(
    const Integer& calculationDay,
    const Integer& targetDay);
int oldNextBowlFixedName(int id);
int nextBowlThroughOrderAt46Latch(const PermutationOrder& orderAt46Latch,
                                  int queriedBowlId);

Stone mutateStonesWrong(int i, Stone state);
StoneTable buildStonesThroughWrongLegacyMutation();
Stone stonePatch(int i, Stone state);
StoneTable buildStonesThroughLegacyBuilder();
Integer makeHiddenLegacyValue(int k,
                              const Integer& calculationDay,
                              const Integer& targetDay,
                              const StoneTable& stones);
HiddenDrops buildHiddenWithBackwardStorage(const Integer& calculationDay,
                                           const Integer& targetDay,
                                           const StoneTable& stones);
Integer hiddenByNearness(const HiddenDrops& backwardStorage, int k);
HiddenDrops buildHiddenNearnessView(const HiddenDrops& backwardStorage);
Integer legacyPrior(const VisibleDropStore& dropStore, int i, int back);
Integer priorPatch(const VisibleDropStore& dropStore,
                   const HiddenDrops& backwardStorage,
                   int i,
                   int back);

struct BaseMonsterContext {
    Integer calculationDay;
    Integer targetDay;
    std::string phase;
    std::string status;
    std::string currentHandler;
    std::vector<std::string> branchTrace;
    std::vector<std::string> logs;
    std::map<std::string, Integer> metrics;
    Integer legacyArithmeticInput;
    Integer legacyArithmeticOutput;
    Integer patchedArithmeticOutput;
    bool legacyArithmeticReady = false;
    bool patch01Applied = false;
    Integer legacyDayTagInput;
    Integer legacyDayTagOutput;
    Integer patchedDayTagOutput;
    bool legacyDayTagReady = false;
    bool patch02Applied = false;
    Integer legacyDistanceCalculationDay;
    Integer legacyDistanceTargetDay;
    Integer legacyDistanceOutput;
    Integer patchedDistanceOutput;
    bool legacyDistanceReady = false;
    bool patch03Applied = false;
    StoneTable legacyStoneTable{};
    bool legacyStoneTableReady = false;
    StoneTable patchedStoneTable{};
    bool patch04Applied = false;
    HiddenDrops legacyHiddenBackward{};
    bool legacyHiddenBackwardReady = false;
    HiddenDrops patchedHiddenNearness{};
    bool patch05Applied = false;
    VisibleDropStore legacyPriorDropStore{};
    int legacyPriorI = 0;
    int legacyPriorBack = 0;
    Integer legacyPriorOutput{};
    bool legacyPriorReady = false;
    HiddenDrops patch06HiddenBackward{};
    Integer patchedPriorOutput{};
    bool patch06LegacyPathUsed = false;
    bool patch06HiddenPathUsed = false;
    bool patch06Applied = false;
    int legacyGrindOrdinal = 0;
    int legacyGrindPhysicalIndex = -1;
    VisibleGrindRow legacyGrindOutput{};
    bool legacyGrindFound = false;
    bool legacyGrindReady = false;
    VisibleGrindRow patchedGrindOutput{};
    bool patchedGrindFound = false;
    bool patch07Applied = false;
    int legacyPermutationCallerRank1 = 0;
    int legacyPermutationRank0Input = -1;
    PermutationOrder legacyPermutationOutput{};
    bool legacyPermutationFound = false;
    bool legacyPermutationReady = false;
    Integer patch08PermutationDrop{};
    int patchedPermutationOneBased = 0;
    int patchedPermutationLegacyRank0 = -1;
    PermutationOrder patchedPermutationOutput{};
    bool patchedPermutationFound = false;
    bool patch08Applied = false;
    Integer legacyFixedPourDrop{};
    int legacyFixedPourIndex = 0;
    BowlState legacyFixedPourOldBowls{};
    Stone legacyFixedPourStoneRow{};
    PermutationOrder legacyFixedPourOrder{};
    std::array<int, 3> legacyFixedPourBowlIds{{1, 2, 3}};
    PourTriplet legacyFixedPourOutput{};
    bool legacyFixedPourReady = false;
    BowlAlias bowlAlias{};
    std::array<int, 3> aliasedFixedPourBowlIds{{1, 2, 3}};
    PourTriplet patchedFixedPourOutput{};
    bool patch09Applied = false;
    BowlState legacyInPlaceBowlInput{};
    Integer legacyInPlaceBowlDrop{};
    int legacyInPlaceBowlIndex = 0;
    Stone legacyInPlaceBowlStoneRow{};
    PermutationOrder legacyInPlaceBowlOrder{};
    PourTriplet legacyInPlaceBowlPours{};
    BowlState legacyInPlaceBowlOutput{};
    bool legacyInPlaceBowlReady = false;
    BowlState bowlVaultOld{};
    BowlState bowlPending{};
    BowlState patchedInPlaceBowlOutput{};
    bool patch10Applied = false;
    LegacyOrderMemorySauceResult legacyOrderMemorySauce{};
    bool legacyOrderMemorySauceReady = false;
    Patch11LatchedOrderSauceResult patch11LatchedOrderSauce{};
    bool patch11Applied = false;
    int legacyNextBowlQueriedId = 0;
    int legacyNextBowlOutput = 0;
    PermutationOrder legacyNextBowlOrderAt46Latch{};
    bool legacyNextBowlReady = false;
    int patchedNextBowlOutput = 0;
    std::size_t patch12QueriedPosition = 0;
    bool patch12Applied = false;
};

struct BaseRunReport {
    std::string phase;
    std::string status;
    std::size_t branchCount;
};

struct LegacyRemainderReport {
    Integer input;
    Integer output;
    std::string phase;
    std::string status;
    std::string handler;
    std::size_t branchCount;
    Integer legacyOutputBeforePatch;
    bool patch01Applied;
};

struct LegacyDayTagReport {
    Integer input;
    Integer output;
    std::string phase;
    std::string status;
    std::string handler;
    std::size_t branchCount;
    Integer legacyOutputBeforePatch{};
    bool patch02Applied = false;
};

struct LegacyDistanceReport {
    Integer calculationDay;
    Integer targetDay;
    Integer output;
    std::string phase;
    std::string status;
    std::string handler;
    std::size_t branchCount;
    Integer legacyOutput{};
    bool patch03Applied = false;
};

struct LegacyStoneTableReport {
    StoneTable output;
    std::string phase;
    std::string status;
    std::string handler;
    std::size_t branchCount;
    StoneTable legacyOutput{};
    bool patch04Applied = false;
};

struct LegacyHiddenReport {
    Integer calculationDay;
    Integer targetDay;
    HiddenDrops output{};
    std::string phase;
    std::string status;
    std::string handler;
    std::size_t branchCount;
    HiddenDrops legacyOutput{};
    bool patch05Applied = false;
};

struct LegacyPriorReport {
    Integer calculationDay{};
    Integer targetDay{};
    int i = 0;
    int back = 0;
    Integer output{};
    std::string phase;
    std::string status;
    std::string handler;
    std::size_t branchCount = 0;
    Integer legacyOutputBeforePatch{};
    bool legacyPathUsed = false;
    bool hiddenPathUsed = false;
    bool patch06Applied = false;
};

struct PermutationRankReport {
    int oneBasedRank = 0;
    PermutationOrder output{};
    bool found = false;
    int legacyRank0Input = -1;
    std::string phase;
    std::string status;
    std::string handler;
    std::size_t branchCount = 0;
    Integer dropInput{};
    int patchedOneBasedRank = 0;
    int patchedLegacyRank0 = -1;
    PermutationOrder legacyOutputBeforePatch{};
    bool legacyFoundBeforePatch = false;
    bool patch08Applied = false;
};

struct GrindLookupReport {
    int grind = 0;
    VisibleGrindRow output{};
    bool found = false;
    int physicalIndex = -1;
    std::string phase;
    std::string status;
    std::string handler;
    std::size_t branchCount = 0;
    VisibleGrindRow legacyOutputBeforePatch{};
    bool legacyFoundBeforePatch = false;
    bool patch07Applied = false;
};

struct LegacyFixedPourReport {
    Integer drop{};
    int index = 0;
    BowlState oldBowls{};
    Stone stoneRow{};
    PermutationOrder order{};
    std::array<int, 3> fixedBowlIds{{1, 2, 3}};
    PourTriplet output{};
    std::string phase;
    std::string status;
    std::string handler;
    std::size_t branchCount = 0;
    PourTriplet legacyOutputBeforePatch{};
    std::array<int, 3> legacyFixedBowlIdsBeforePatch{{1, 2, 3}};
    BowlAlias bowlAlias{};
    std::array<int, 3> aliasedBowlIds{{1, 2, 3}};
    bool patch09Applied = false;
};

struct LegacyInPlaceBowlReport {
    BowlState input{};
    Integer drop{};
    int index = 0;
    Stone stoneRow{};
    PermutationOrder order{};
    PourTriplet firstThreePours{};
    BowlState output{};
    std::string phase;
    std::string status;
    std::string handler;
    std::size_t branchCount = 0;
    BowlState legacyOutputBeforePatch{};
    BowlState vaultOld{};
    BowlState pending{};
    bool patch10Applied = false;
};

struct LegacyOrderMemoryReport {
    Integer calculationDay{};
    Integer targetDay{};
    BowlState finalBowls{};
    PermutationOrder queryOrder{};
    PermutationOrder orderAtDrop46Diagnostic{};
    PermutationOrder finalPostStirOrder{};
    std::size_t orderWriteCount = 0;
    std::string finalOrderSource;
    PermutationOrder legacyQueryOrderBeforePatch{};
    PermutationOrder orderAt46Latch{};
    std::size_t latchWriteCount = 0;
    bool patch11Applied = false;
    std::string phase;
    std::string status;
    std::string handler;
    std::size_t branchCount = 0;
};

struct LegacyNextBowlReport {
    Integer calculationDay{};
    Integer targetDay{};
    int queriedBowlId = 0;
    int outputBowlId = 0;
    PermutationOrder orderAt46Latch{};
    std::size_t latchWriteCount = 0;
    bool patch11Prepared = false;
    std::string phase;
    std::string status;
    std::string handler;
    std::size_t branchCount = 0;
    int legacyOutputBeforePatch = 0;
    std::size_t queriedPosition = 0;
    bool patch12Applied = false;
};

class BaseValidationError final : public std::runtime_error {
public:
    using std::runtime_error::runtime_error;
};

class BaseValidationManager {
public:
    void requireNeutralBootstrapState(const BaseMonsterContext& ctx) const;
    void requireLegacyArithmeticReady(const BaseMonsterContext& ctx) const;
    void requirePatch01Ready(const BaseMonsterContext& ctx) const;
    void requireLegacyDayTagReady(const BaseMonsterContext& ctx) const;
    void requirePatch02Ready(const BaseMonsterContext& ctx) const;
    void requireLegacyDistanceReady(const BaseMonsterContext& ctx) const;
    void requirePatch03Ready(const BaseMonsterContext& ctx) const;
    void requireLegacyStoneTableReady(const BaseMonsterContext& ctx) const;
    void requirePatch04Ready(const BaseMonsterContext& ctx) const;
    void requireLegacyHiddenBackwardReady(const BaseMonsterContext& ctx) const;
    void requirePatch05Ready(const BaseMonsterContext& ctx) const;
    void requireLegacyPriorReady(const BaseMonsterContext& ctx) const;
    void requirePatch06Ready(const BaseMonsterContext& ctx) const;
    void requireLegacyGrindReady(const BaseMonsterContext& ctx) const;
    void requirePatch07Ready(const BaseMonsterContext& ctx) const;
    void requireLegacyPermutationReady(const BaseMonsterContext& ctx) const;
    void requirePatch08Ready(const BaseMonsterContext& ctx) const;
    void requireLegacyFixedPourReady(const BaseMonsterContext& ctx) const;
    void requirePatch09Ready(const BaseMonsterContext& ctx) const;
    void requireLegacyInPlaceBowlReady(const BaseMonsterContext& ctx) const;
    void requirePatch10Ready(const BaseMonsterContext& ctx) const;
    void requireLegacyOrderMemorySauceReady(const BaseMonsterContext& ctx) const;
    void requirePatch11Ready(const BaseMonsterContext& ctx) const;
    void requireLegacyNextBowlReady(const BaseMonsterContext& ctx) const;
    void requirePatch12Ready(const BaseMonsterContext& ctx) const;
};

class BaseMetricsShell {
public:
    void bump(BaseMonsterContext& ctx, const std::string& key) const;
};

class LegacyArithmeticAdapter {
public:
    Integer callOldRemainder(const Integer& x) const;
};

class LegacyDayTagAdapter {
public:
    Integer callOldDayTag(const Integer& day) const;
};

class LegacyDistanceAdapter {
public:
    Integer callOldDistance(const Integer& calculationDay, const Integer& targetDay) const;
};

class LegacyStoneMutationAdapter {
public:
    StoneTable buildWrongStoneTable() const;
};

class LegacyHiddenStorageAdapter {
public:
    HiddenDrops buildBackward(const Integer& calculationDay,
                              const Integer& targetDay,
                              const StoneTable& stones) const;
};

class LegacyPriorAdapter {
public:
    Integer read(const VisibleDropStore& dropStore, int i, int back) const;
};

class LegacyPermutationAdapter {
public:
    PermutationOrder unrank0(int rank0) const;
};

class LegacyGrindTableAdapter {
public:
    LegacyGrindLookup read(int grind) const;
};

class LegacyFixedPourAdapter {
public:
    LegacyFixedPourComputation compute(const Integer& drop,
                                       int index,
                                       const BowlState& oldBowls,
                                       const Stone& stoneRow) const;
};

class LegacyInPlaceBowlAdapter {
public:
    BowlState stir(const BowlState& bowls,
                   int index,
                   const Integer& drop,
                   const Stone& stoneRow,
                   const PermutationOrder& order,
                   const PourTriplet& firstThreePours) const;
};

class LegacyOrderMemorySauceAdapter {
public:
    LegacyOrderMemorySauceResult run(const Integer& calculationDay,
                                     const Integer& targetDay) const;
};

class Patch11OrderAt46LatchWrapper {
public:
    Patch11LatchedOrderSauceResult repair(const Integer& calculationDay,
                                          const Integer& targetDay) const;
};

class LegacyNextBowlAdapter {
public:
    int nextFixedName(int queriedBowlId) const;
};

class Patch12NextBowlWrapper {
public:
    int repair(const PermutationOrder& orderAt46Latch,
               int queriedBowlId) const;
};

class Patch10DeferredBowlWrapper {
public:
    Patch10DeferredBowlComputation repair(const BowlState& bowls,
                                          int index,
                                          const Integer& drop,
                                          const Stone& stoneRow,
                                          const PermutationOrder& order,
                                          const PourTriplet& firstThreePours) const;
};

class Patch09BowlAliasWrapper {
public:
    BowlAliasPourComputation repair(const Integer& drop,
                                    int index,
                                    const BowlState& oldBowls,
                                    const Stone& stoneRow,
                                    const PermutationOrder& order) const;
};

class Discovery01RemainderHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyArithmeticAdapter& adapter,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

class Patch01SaveWrapper {
public:
    Integer repair(const Integer& x) const;
};

class Patch01RemainderHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyArithmeticAdapter& adapter,
                const Patch01SaveWrapper& wrapper,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

class Discovery02DayTagHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyDayTagAdapter& adapter,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

class Patch02DayTagWrapper {
public:
    Integer repair(const Integer& day) const;
};

class Patch02DayTagHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyDayTagAdapter& adapter,
                const Patch02DayTagWrapper& wrapper,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

class Discovery03DistanceHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyDistanceAdapter& adapter,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

class Patch03DistanceWrapper {
public:
    Integer repair(const Integer& calculationDay,
                   const Integer& targetDay,
                   const Integer& legacyDistance) const;
};

class Patch03DistanceHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyDistanceAdapter& adapter,
                const Patch03DistanceWrapper& wrapper,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

class Discovery04StoneMutationHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyStoneMutationAdapter& adapter,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

class Patch04StoneSnapshotWrapper {
public:
    StoneTable repair() const;
};

class Patch04StoneMutationHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyStoneMutationAdapter& adapter,
                const Patch04StoneSnapshotWrapper& wrapper,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

class Discovery05HiddenStorageHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyHiddenStorageAdapter& adapter,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

class Patch05HiddenNearnessWrapper {
public:
    Integer read(const HiddenDrops& backwardStorage, int k) const;
};

class Patch05HiddenStorageHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyHiddenStorageAdapter& adapter,
                const Patch05HiddenNearnessWrapper& wrapper,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

class Discovery06PriorHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyPriorAdapter& adapter,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

class Patch06PriorWrapper {
public:
    Integer read(const VisibleDropStore& dropStore,
                 const HiddenDrops& backwardStorage,
                 int i,
                 int back) const;
};

class Patch06PriorHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyPriorAdapter& adapter,
                const Patch06PriorWrapper& wrapper,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

class Discovery07GrindIndexHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyGrindTableAdapter& adapter,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

class Patch07SentinelGrindWrapper {
public:
    LegacyGrindLookup read(int grind) const;
};

class Patch07GrindIndexHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyGrindTableAdapter& adapter,
                const Patch07SentinelGrindWrapper& wrapper,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

class Discovery08PermutationRankHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyPermutationAdapter& adapter,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

struct Patch08PermutationResolution {
    int oneBased = 0;
    int legacyRank0 = -1;
    PermutationOrder order{};
};

class Patch08PermutationRankWrapper {
public:
    Patch08PermutationResolution resolve(const Integer& drop,
                                         const LegacyPermutationAdapter& adapter) const;
};

class Patch08PermutationRankHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyPermutationAdapter& adapter,
                const Patch08PermutationRankWrapper& wrapper,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

class Discovery09FixedPourHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyFixedPourAdapter& adapter,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

class Patch09BowlAliasHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyFixedPourAdapter& adapter,
                const Patch09BowlAliasWrapper& wrapper,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

class Discovery10InPlaceBowlHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyInPlaceBowlAdapter& adapter,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

class Patch10InPlaceBowlHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyInPlaceBowlAdapter& adapter,
                const Patch10DeferredBowlWrapper& wrapper,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

class Discovery11OverwrittenOrderHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyOrderMemorySauceAdapter& adapter,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

class Patch11OrderAt46LatchHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyOrderMemorySauceAdapter& adapter,
                const Patch11OrderAt46LatchWrapper& wrapper,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

class Discovery12NextBowlHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyNextBowlAdapter& adapter,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

class Patch12NextBowlHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyNextBowlAdapter& adapter,
                const Patch12NextBowlWrapper& wrapper,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

class BaseDispatcher {
public:
    void dispatch(BaseMonsterContext& ctx,
                  const BaseValidationManager& validator,
                  const BaseMetricsShell& metrics) const;

    void dispatchLegacyRemainder(BaseMonsterContext& ctx,
                                 const Discovery01RemainderHandler& handler,
                                 const LegacyArithmeticAdapter& adapter,
                                 const BaseValidationManager& validator,
                                 const BaseMetricsShell& metrics) const;

    void dispatchPatchedRemainder(BaseMonsterContext& ctx,
                                  const Patch01RemainderHandler& handler,
                                  const LegacyArithmeticAdapter& adapter,
                                  const Patch01SaveWrapper& wrapper,
                                  const BaseValidationManager& validator,
                                  const BaseMetricsShell& metrics) const;

    void dispatchLegacyDayTag(BaseMonsterContext& ctx,
                              const Discovery02DayTagHandler& handler,
                              const LegacyDayTagAdapter& adapter,
                              const BaseValidationManager& validator,
                              const BaseMetricsShell& metrics) const;

    void dispatchPatchedDayTag(BaseMonsterContext& ctx,
                               const Patch02DayTagHandler& handler,
                               const LegacyDayTagAdapter& adapter,
                               const Patch02DayTagWrapper& wrapper,
                               const BaseValidationManager& validator,
                               const BaseMetricsShell& metrics) const;

    void dispatchLegacyDistance(BaseMonsterContext& ctx,
                                const Discovery03DistanceHandler& handler,
                                const LegacyDistanceAdapter& adapter,
                                const BaseValidationManager& validator,
                                const BaseMetricsShell& metrics) const;

    void dispatchPatchedDistance(BaseMonsterContext& ctx,
                                 const Patch03DistanceHandler& handler,
                                 const LegacyDistanceAdapter& adapter,
                                 const Patch03DistanceWrapper& wrapper,
                                 const BaseValidationManager& validator,
                                 const BaseMetricsShell& metrics) const;

    void dispatchLegacyStoneMutation(BaseMonsterContext& ctx,
                                     const Discovery04StoneMutationHandler& handler,
                                     const LegacyStoneMutationAdapter& adapter,
                                     const BaseValidationManager& validator,
                                     const BaseMetricsShell& metrics) const;

    void dispatchPatchedStoneMutation(BaseMonsterContext& ctx,
                                      const Patch04StoneMutationHandler& handler,
                                      const LegacyStoneMutationAdapter& adapter,
                                      const Patch04StoneSnapshotWrapper& wrapper,
                                      const BaseValidationManager& validator,
                                      const BaseMetricsShell& metrics) const;

    void dispatchLegacyHiddenStorage(BaseMonsterContext& ctx,
                                     const Discovery05HiddenStorageHandler& handler,
                                     const LegacyHiddenStorageAdapter& adapter,
                                     const BaseValidationManager& validator,
                                     const BaseMetricsShell& metrics) const;

    void dispatchPatchedHiddenStorage(BaseMonsterContext& ctx,
                                      const Patch05HiddenStorageHandler& handler,
                                      const LegacyHiddenStorageAdapter& adapter,
                                      const Patch05HiddenNearnessWrapper& wrapper,
                                      const BaseValidationManager& validator,
                                      const BaseMetricsShell& metrics) const;

    void dispatchLegacyPrior(BaseMonsterContext& ctx,
                             const Discovery06PriorHandler& handler,
                             const LegacyPriorAdapter& adapter,
                             const BaseValidationManager& validator,
                             const BaseMetricsShell& metrics) const;

    void dispatchPatchedPrior(BaseMonsterContext& ctx,
                              const Patch06PriorHandler& handler,
                              const LegacyPriorAdapter& adapter,
                              const Patch06PriorWrapper& wrapper,
                              const BaseValidationManager& validator,
                              const BaseMetricsShell& metrics) const;

    void dispatchLegacyGrindIndex(BaseMonsterContext& ctx,
                                  const Discovery07GrindIndexHandler& handler,
                                  const LegacyGrindTableAdapter& adapter,
                                  const BaseValidationManager& validator,
                                  const BaseMetricsShell& metrics) const;

    void dispatchLegacyPermutationRank(BaseMonsterContext& ctx,
                                       const Discovery08PermutationRankHandler& handler,
                                       const LegacyPermutationAdapter& adapter,
                                       const BaseValidationManager& validator,
                                       const BaseMetricsShell& metrics) const;

    void dispatchPatchedPermutationRank(BaseMonsterContext& ctx,
                                        const Patch08PermutationRankHandler& handler,
                                        const LegacyPermutationAdapter& adapter,
                                        const Patch08PermutationRankWrapper& wrapper,
                                        const BaseValidationManager& validator,
                                        const BaseMetricsShell& metrics) const;

    void dispatchPatchedGrindIndex(BaseMonsterContext& ctx,
                                   const Patch07GrindIndexHandler& handler,
                                   const LegacyGrindTableAdapter& adapter,
                                   const Patch07SentinelGrindWrapper& wrapper,
                                   const BaseValidationManager& validator,
                                   const BaseMetricsShell& metrics) const;

    void dispatchLegacyFixedPours(BaseMonsterContext& ctx,
                                  const Discovery09FixedPourHandler& handler,
                                  const LegacyFixedPourAdapter& adapter,
                                  const BaseValidationManager& validator,
                                  const BaseMetricsShell& metrics) const;

    void dispatchPatchedFixedPours(BaseMonsterContext& ctx,
                                   const Patch09BowlAliasHandler& handler,
                                   const LegacyFixedPourAdapter& adapter,
                                   const Patch09BowlAliasWrapper& wrapper,
                                   const BaseValidationManager& validator,
                                   const BaseMetricsShell& metrics) const;

    void dispatchLegacyInPlaceBowlStir(BaseMonsterContext& ctx,
                                        const Discovery10InPlaceBowlHandler& handler,
                                        const LegacyInPlaceBowlAdapter& adapter,
                                        const BaseValidationManager& validator,
                                        const BaseMetricsShell& metrics) const;

    void dispatchPatchedInPlaceBowlStir(BaseMonsterContext& ctx,
                                         const Patch10InPlaceBowlHandler& handler,
                                         const LegacyInPlaceBowlAdapter& adapter,
                                         const Patch10DeferredBowlWrapper& wrapper,
                                         const BaseValidationManager& validator,
                                         const BaseMetricsShell& metrics) const;

    void dispatchLegacyOverwrittenOrder(BaseMonsterContext& ctx,
                                        const Discovery11OverwrittenOrderHandler& handler,
                                        const LegacyOrderMemorySauceAdapter& adapter,
                                        const BaseValidationManager& validator,
                                        const BaseMetricsShell& metrics) const;

    void dispatchPatchedOrderAt46Latch(BaseMonsterContext& ctx,
                                       const Patch11OrderAt46LatchHandler& handler,
                                       const LegacyOrderMemorySauceAdapter& adapter,
                                       const Patch11OrderAt46LatchWrapper& wrapper,
                                       const BaseValidationManager& validator,
                                       const BaseMetricsShell& metrics) const;

    void dispatchLegacyNextBowl(BaseMonsterContext& ctx,
                                const Discovery12NextBowlHandler& handler,
                                const LegacyNextBowlAdapter& adapter,
                                const BaseValidationManager& validator,
                                const BaseMetricsShell& metrics) const;

    void dispatchPatchedNextBowl(BaseMonsterContext& ctx,
                                 const Patch12NextBowlHandler& handler,
                                 const LegacyNextBowlAdapter& adapter,
                                 const Patch12NextBowlWrapper& wrapper,
                                 const BaseValidationManager& validator,
                                 const BaseMetricsShell& metrics) const;
};

class BaseMonsterManager {
public:
    BaseRunReport execute(const Integer& calculationDay, const Integer& targetDay) const;
    LegacyRemainderReport executeLegacyRemainder(const Integer& x) const;
    LegacyRemainderReport executeUnpatchedRemainderDiagnostic(const Integer& x) const;
    LegacyDayTagReport executeLegacyDayTag(const Integer& day) const;
    LegacyDayTagReport executeUnpatchedDayTagDiagnostic(const Integer& day) const;
    LegacyDistanceReport executeDistance(const Integer& calculationDay, const Integer& targetDay) const;
    LegacyDistanceReport executeUnpatchedDistanceDiagnostic(const Integer& calculationDay,
                                                            const Integer& targetDay) const;
    LegacyStoneTableReport executeStoneTable() const;
    LegacyStoneTableReport executeUnpatchedStoneTableDiagnostic() const;
    LegacyHiddenReport executeHiddenDrops(const Integer& calculationDay,
                                          const Integer& targetDay) const;
    LegacyHiddenReport executeUnpatchedHiddenStorageDiagnostic(const Integer& calculationDay,
                                                               const Integer& targetDay) const;
    LegacyPriorReport executePrior(const Integer& calculationDay,
                                   const Integer& targetDay,
                                   const VisibleDropStore& dropStore,
                                   int i,
                                   int back) const;
    LegacyPriorReport executeUnpatchedPriorDiagnostic(const Integer& calculationDay,
                                                      const Integer& targetDay,
                                                      const VisibleDropStore& dropStore,
                                                      int i,
                                                      int back) const;
    GrindLookupReport executeGrindRow(int grind) const;
    GrindLookupReport executeUnpatchedGrindDiagnostic(int grind) const;
    PermutationRankReport executePermutationOrder(int oneBasedRank) const;
    PermutationRankReport executePermutationFromDrop(const Integer& drop) const;
    PermutationRankReport executeUnpatchedPermutationDiagnostic(int oneBasedRank) const;
    LegacyFixedPourReport executeFixedPours(const Integer& drop,
                                            int index,
                                            const BowlState& oldBowls,
                                            const Stone& stoneRow) const;
    LegacyFixedPourReport executeUnpatchedFixedPoursDiagnostic(const Integer& drop,
                                                               int index,
                                                               const BowlState& oldBowls,
                                                               const Stone& stoneRow) const;
    LegacyInPlaceBowlReport executeInPlaceBowlStir(const BowlState& bowls,
                                                     int index,
                                                     const Integer& drop,
                                                     const Stone& stoneRow,
                                                     const PermutationOrder& order,
                                                     const PourTriplet& firstThreePours) const;
    LegacyInPlaceBowlReport executeUnpatchedInPlaceBowlStirDiagnostic(const BowlState& bowls,
                                                                        int index,
                                                                        const Integer& drop,
                                                                        const Stone& stoneRow,
                                                                        const PermutationOrder& order,
                                                                        const PourTriplet& firstThreePours) const;
    LegacyOrderMemoryReport executeOverwritableOrderMemorySauce(const Integer& calculationDay,
                                                                const Integer& targetDay) const;
    LegacyOrderMemoryReport executeUnpatchedOverwritableOrderMemoryDiagnostic(
        const Integer& calculationDay,
        const Integer& targetDay) const;
    LegacyNextBowlReport executeLegacyNextBowl(const Integer& calculationDay,
                                               const Integer& targetDay,
                                               int queriedBowlId) const;
    LegacyNextBowlReport executeUnpatchedNextBowlDiagnostic(
        const Integer& calculationDay,
        const Integer& targetDay,
        int queriedBowlId) const;
};

} // namespace pastafari
