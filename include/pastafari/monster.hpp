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
inline constexpr int LEGACY_YEAR_MAX = 5781;
inline constexpr int REAL_YEAR_MAX_PATCH = 5778;
inline constexpr int LEGACY_MONTH_LENGTH_MIN = 4;
inline constexpr int LEGACY_MONTH_LENGTH_MAX = 123;

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

struct LegacyYearAnchor {
    Integer number{};
    Integer firstDay{};
    Integer lastDay{};
};

Integer oldJumpGuess(const LegacyYearAnchor& anchor, const Integer& targetDay);

struct Patch18YearRecord {
    Integer number{};
    Integer openGateIndex{};
    Integer closeGateIndex{};
    Integer openGateDay{};
    Integer closeGateDay{};
};

struct Patch18YearWalkResult {
    Patch18YearRecord anchorYear{};
    Patch18YearRecord outputYear{};
    std::size_t forwardSteps = 0;
    std::size_t backwardSteps = 0;
};

struct LegacyYearCacheEntry { Integer calculationDayFingerprint{}; Integer openGate{}; Integer closeGate{}; Patch18YearRecord value{}; };
struct LegacyYearCacheReport { Integer cacheKeyYearNumber{}; LegacyYearCacheEntry requestEntry{}; LegacyYearCacheEntry cachedEntry{}; Patch18YearRecord outputValue{}; bool cacheHit=false; bool ready=false; std::string phase; std::string status; std::string handler; std::size_t branchCount=0; LegacyYearCacheEntry legacyCachedEntryBeforePatch{}; Patch18YearRecord legacyOutputBeforePatch{}; bool legacyCacheHitBeforePatch=false; bool fingerprintMatched=false; bool openGateMatched=false; bool closeGateMatched=false; bool entryOverwritten=false; bool patch19Applied=false; };
struct Patch19GuardedYearCacheResolution { LegacyYearCacheEntry semanticEntry{}; Patch18YearRecord outputValue{}; bool semanticHit=false; bool fingerprintMatched=false; bool openGateMatched=false; bool closeGateMatched=false; bool entryOverwritten=false; };

Patch11LatchedOrderSauceResult oldStructureSauce(
    const Integer& calculationDay,
    const Integer& originalTargetDay);

struct Patch20StructureSauceResult {
    Patch11LatchedOrderSauceResult ghost{};
    Patch11LatchedOrderSauceResult semanticSauce{};
    Integer mustUse{};
    bool ghostExecuted = false;
    bool semanticRecomputed = false;
};

Patch20StructureSauceResult structureSaucePatch(
    const Integer& calculationDay,
    const Integer& originalTargetDay,
    const Patch18YearRecord& year);

struct LegacyPositiveCompositionFamily {
    int gapCount = 0;
    int cutletCount = 0;
    Integer count{};
};

LegacyPositiveCompositionFamily legacyPositiveCompositions(int gapCount,
                                                            int cutletCount);
std::vector<int> legacyPositiveCompositionUnrank(
    const LegacyPositiveCompositionFamily& family,
    const Integer& rank1);

struct FilteredPositiveCompositionFamily {
    int gapCount = 0;
    int cutletCount = 0;
    int internalGateOffset = 0;
    bool internalGateRequired = false;
    Integer count{};
};

FilteredPositiveCompositionFamily filteredLegacyPositiveCompositions(
    int gapCount,
    int cutletCount,
    int internalGateOffset,
    bool internalGateRequired);
std::vector<int> filteredLegacyPositiveCompositionUnrank(
    const FilteredPositiveCompositionFamily& family,
    const Integer& rank1);

struct Patch21CutletPartitionResult {
    FilteredPositiveCompositionFamily semanticFamily{};
    Integer semanticSelectionRank{};
    std::vector<int> semanticPartition{};
    std::vector<int> semanticPrefixSums{};
    bool semanticHitInternalGateBoundary = false;
    bool filterApplied = false;
    bool legacyPartitionReused = false;
};

struct LegacyCutletPartitionReport {
    Integer calculationDay{};
    Integer originalTargetDay{};
    Integer calculationGateIndex{};
    Patch18YearRecord resolvedYear{};
    int gapCount = 0;
    int cutletCount = 0;
    int internalGateOffset = 0;
    bool calculationDayIsInternalGate = false;
    LegacyPositiveCompositionFamily legacyFamily{};
    Integer selectionRank{};
    std::vector<int> legacyPartition{};
    std::vector<int> legacyPrefixSums{};
    bool legacyHitInternalGateBoundary = false;
    bool legacyIgnoredInternalGate = false;
    FilteredPositiveCompositionFamily semanticFamily{};
    Integer semanticSelectionRank{};
    std::vector<int> semanticPartition{};
    std::vector<int> semanticPrefixSums{};
    bool semanticHitInternalGateBoundary = false;
    bool patch21FilterApplied = false;
    bool patch21LegacyExecuted = false;
    bool patch21LegacyPartitionReused = false;
    bool patch21Applied = false;
    bool ready = false;
    std::string phase;
    std::string status;
    std::string handler;
    std::size_t branchCount = 0;
};

struct LegacyStructureSelectorToken {
    Integer bowl2{};
    PermutationOrder orderAt46Latch{};
};

struct LegacyStructureSauceReport {
    Integer calculationDay{};
    Integer originalTargetDay{};
    Integer yearFirstDay{};
    Patch18YearRecord resolvedYear{};
    Patch11LatchedOrderSauceResult legacyStructureSauce{};
    Patch11LatchedOrderSauceResult semanticStructureSauce{};
    LegacyStructureSelectorToken selectorToken{};
    bool selectorConsumedLegacySauce = false;
    bool patch20GhostExecuted = false;
    bool patch20SemanticRecomputed = false;
    bool patch20GhostReachedSelector = false;
    bool patch20Applied = false;
    bool ready = false;
    std::string phase;
    std::string status;
    std::string handler;
    std::size_t branchCount = 0;
};

struct LegacyAnswerRing {
    Integer first{};
    int directionStep = 0;
};

LegacyAnswerRing answerRingThroughPatchedNextBowl(const BowlState& finalBowls,
                                                   int queriedBowlId,
                                                   int nextBowlId,
                                                   int seal);
Integer ringAnswer(const LegacyAnswerRing& stream, const Integer& offset);
Integer biasedLegacyPick(const Integer& x, const Integer& N);
Integer oldGateQuestionDay(const Integer& n);

Integer legacyCutletNameSelectionSpaceCount(int masterCount, int itemCount);
std::vector<int> legacyNameRowWithRepeats(const std::vector<int>& masterList,
                                          const Integer& rank1,
                                          int itemCount);
bool legacyNameRowContainsRepeat(const std::vector<int>& row);
std::vector<int> partialPermutationNameRowUnrank(const std::vector<int>& masterList,
                                                  const Integer& rank1,
                                                  int itemCount);

struct RepeatedNamePatchDecision {
    std::vector<int> badNameIndices{};
    std::vector<int> correctNameIndices{};
    std::vector<int> outputNameIndices{};
    bool badEqualsCorrect = false;
    bool legacyReturned = false;
    bool correctComputed = false;
    bool patchApplied = false;
};

struct LegacyRepeatedNameReport {
    Integer calculationDay{};
    Integer originalTargetDay{};
    Integer calculationGateIndex{};
    Patch18YearRecord resolvedYear{};
    int cutletCount = 0;
    int masterNameCount = 0;
    Integer selectionSpaceCount{};
    LegacyAnswerRing answerRing{};
    Integer selectionRank{};
    std::vector<int> legacyNameIndices{};
    bool legacyContainsRepeat = false;
    bool patch20Prepared = false;
    bool patch21Prepared = false;
    std::vector<int> patch22CorrectNameIndices{};
    std::vector<int> semanticNameIndices{};
    bool patch22LegacyExecuted = false;
    bool patch22CorrectComputed = false;
    bool patch22BadEqualsCorrect = false;
    bool patch22LegacyReturned = false;
    bool patch22Applied = false;
    bool ready = false;
    std::string phase;
    std::string status;
    std::string handler;
    std::size_t branchCount = 0;
};

using LegacyMonthLengthWays = std::vector<std::vector<int>>;

Integer legacyMonthLengthConcreteFamilyCountProof(int yearLength,
                                                  int monthCount);
LegacyMonthLengthWays legacyMaterializeAllMonthLengthWays(int yearLength,
                                                          int monthCount);

struct LegacyMonthLengthMaterializationInspection {
    int yearLength = 0;
    int monthCount = 0;
    Integer exactFamilyCount{};
    Integer concreteListIndexCapacity{};
    bool concreteListContractReached = false;
    bool concreteEnumerationEntered = false;
    bool concreteMaterializationCompleted = false;
    bool blockedBeforeAllocation = false;
    std::size_t materializedItemCount = 0;
};

struct LegacyMonthLengthMaterializationReport {
    Integer calculationDay{};
    Integer originalTargetDay{};
    Integer calculationGateIndex{};
    Patch18YearRecord resolvedYear{};
    int cutletCount = 0;
    int yearLength = 0;
    int monthCount = 0;
    Integer exactFamilyCount{};
    Integer concreteListIndexCapacity{};
    bool patch22Prepared = false;
    bool legacyConcreteListContractReached = false;
    bool legacyConcreteEnumerationEntered = false;
    bool legacyConcreteMaterializationCompleted = false;
    bool blockedBeforeAllocation = false;
    std::size_t materializedItemCount = 0;
    bool patch23Applied = false;
    bool ready = false;
    std::string phase;
    std::string status;
    std::string handler;
    std::size_t branchCount = 0;
};

struct LegacyYearCandidatePair {
    std::size_t openIndex = 0;
    std::size_t closeIndex = 0;
};

struct LegacyYearCandidate {
    std::size_t openIndex = 0;
    std::size_t closeIndex = 0;
    Integer length{};
};

using LegacyYearCandidateList = std::vector<LegacyYearCandidate>;

bool legacyYearCandidateAllowed(const std::vector<Integer>& gates,
                                std::size_t openIndex,
                                std::size_t closeIndex);
LegacyYearCandidateList legacyYearCandidatesBeforeSort(
    const std::vector<Integer>& gates,
    const std::vector<LegacyYearCandidatePair>& pairs);
LegacyYearCandidateList legacyStableLengthOnlyYearCandidates(
    const LegacyYearCandidateList& candidates);

struct LegacyYearCandidatePreparation {
    LegacyYearCandidateList preSort{};
    LegacyYearCandidateList sorted{};
};

struct Patch16YearCandidateDecision {
    bool legacyAccepted = false;
    bool semanticAccepted = false;
    LegacyYearCandidate candidate{};
};

struct Patch16YearCandidatePreparation {
    LegacyYearCandidateList legacyPreSort{};
    LegacyYearCandidateList rejectedBeforeSort{};
    LegacyYearCandidateList semanticPreSort{};
    LegacyYearCandidateList semanticSorted{};
};

struct LegacyYear5000TiePreparation {
    LegacyYearCandidateList preSort{};
    LegacyYearCandidateList sorted{};
};

struct Patch17Year5000TiePreparation {
    LegacyYearCandidateList legacySorted{};
    LegacyYearCandidateList patchedSorted{};
    std::size_t equalLengthRunCount = 0;
};

Patch16YearCandidateDecision yearCandidateAfterFootnotePatch(
    const std::vector<Integer>& gates,
    std::size_t openIndex,
    std::size_t closeIndex);
LegacyYear5000TiePreparation legacyYear5000TiePreparation(
    const std::vector<Integer>& gates,
    const std::vector<LegacyYearCandidatePair>& pairs,
    const Integer& calculationDay);
LegacyYearCandidateList sortEqualLengthRunsByOpeningGate(
    const std::vector<Integer>& gates,
    const LegacyYearCandidateList& lengthSorted);

struct Patch13RejectionSelection {
    Integer acceptanceLimit{};
    Integer acceptedAnswer{};
    Integer acceptedOffset{};
    Integer outputRank{};
};

struct LegacyWideSelectionAttempt {
    bool outputAvailable = false;
    Integer outputRank{};
    bool legacyShortFailure = false;
    std::string legacyFailure;
};

struct Patch14WideDetourSelection {
    int places = 0;
    Integer space{};
    std::vector<Integer> digits{};
    int digitReadCount = 0;
    Integer initialWide{};
    Integer acceptanceLimit{};
    Integer acceptedWide{};
    Integer rejectionSteps{};
    Integer outputRank{};
};

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
    int legacyBiasedSelectionQueriedBowlId = 0;
    int legacyBiasedSelectionSeal = 0;
    Integer legacyBiasedSelectionFamilySize{};
    LegacyAnswerRing legacyBiasedSelectionRing{};
    Integer legacyBiasedSelectionFirstAnswer{};
    Integer legacyBiasedSelectionOutput{};
    bool legacyBiasedSelectionReady = false;
    Integer patch13AcceptanceLimit{};
    Integer patch13AcceptedAnswer{};
    Integer patch13AcceptedOffset{};
    Integer patchedBiasedSelectionOutput{};
    bool patch13Applied = false;
    Integer legacyWideSelectionFamilySize{};
    LegacyAnswerRing legacyWideSelectionRing{};
    bool legacyWideSelectionOutputAvailable = false;
    Integer legacyWideSelectionOutput{};
    bool legacyWideSelectionShortFailure = false;
    std::string legacyWideSelectionFailure;
    bool legacyWideSelectionReady = false;
    bool patch14LegacyOutputAvailableBeforePatch = false;
    Integer patch14LegacyOutputBeforePatch{};
    bool patch14LegacyShortFailureBeforePatch = false;
    std::string patch14LegacyFailureBeforePatch;
    bool patch14UsedShortPath = false;
    bool patch14UsedWideDetour = false;
    int patch14WidePlaces = 0;
    Integer patch14WideSpace{};
    std::vector<Integer> patch14WideDigits{};
    int patch14WideDigitReadCount = 0;
    Integer patch14WideInitialValue{};
    Integer patch14WideAcceptanceLimit{};
    Integer patch14WideAcceptedValue{};
    Integer patch14WideRejectionSteps{};
    bool patch14Applied = false;
    Integer legacyGateQuestionSignedStep{};
    Integer legacyGateQuestionMagnitude{};
    Integer legacyGateQuestionOutput{};
    bool legacyGateQuestionReady = false;
    Integer patch15LegacyOutputBeforePatch{};
    Integer patch15GateQuestionOutput{};
    bool patch15Applied = false;
    std::vector<Integer> legacyYearGates{};
    std::vector<LegacyYearCandidatePair> legacyYearCandidatePairs{};
    LegacyYearCandidateList legacyYearCandidatesPreSort{};
    LegacyYearCandidateList legacyYearCandidatesSorted{};
    LegacyAnswerRing legacyYearSelectionRing{};
    Integer legacyYearSelectionFamilySize{};
    bool legacyYearSelectionCalled = false;
    Integer legacyYearSelectedOrdinal{};
    LegacyYearCandidate legacyYearSelectedCandidate{};
    int legacyYearQueriedBowlId = 0;
    int legacyYearSeal = 0;
    bool legacyYearCandidateReady = false;
    LegacyYearCandidateList patch16LegacyYearCandidatesPreSort{};
    LegacyYearCandidateList patch16RejectedBeforeSort{};
    LegacyYearCandidateList patch16YearCandidatesPreSort{};
    LegacyYearCandidateList patch16YearCandidatesSorted{};
    LegacyAnswerRing patch16YearSelectionRing{};
    Integer patch16YearSelectionFamilySize{};
    bool patch16YearSelectionCalled = false;
    Integer patch16YearSelectedOrdinal{};
    LegacyYearCandidate patch16YearSelectedCandidate{};
    bool patch16Applied = false;
    LegacyYearCandidateList discovery17Year5000PreSort{};
    LegacyYearCandidateList discovery17Year5000Sorted{};
    LegacyAnswerRing discovery17Year5000SelectionRing{};
    Integer discovery17Year5000SelectionFamilySize{};
    bool discovery17Year5000SelectionCalled = false;
    Integer discovery17Year5000SelectedOrdinal{};
    LegacyYearCandidate discovery17Year5000SelectedCandidate{};
    bool discovery17Year5000Ready = false;
    LegacyYearCandidateList patch17LegacyYear5000Sorted{};
    Integer patch17LegacyYear5000SelectedOrdinal{};
    LegacyYearCandidate patch17LegacyYear5000SelectedCandidate{};
    LegacyYearCandidateList patch17Year5000Sorted{};
    std::size_t patch17EqualLengthRunCount = 0;
    Integer patch17Year5000SelectedOrdinal{};
    LegacyYearCandidate patch17Year5000SelectedCandidate{};
    bool patch17Applied = false;
    LegacyYearAnchor discovery18JumpAnchor{};
    Integer discovery18JumpTargetDay{};
    Integer discovery18OldJumpGuess{};
    Integer discovery18JumpOutputYearNumber{};
    bool discovery18GuessUsedAsOutput = false;
    bool discovery18JumpReady = false;
    Integer patch18CalculationDay{};
    Patch18YearRecord patch18AnchorYear{};
    Patch18YearRecord patch18OutputYear{};
    std::size_t patch18ForwardSteps = 0;
    std::size_t patch18BackwardSteps = 0;
    bool patch18GuessTelemetryOnly = false;
    bool patch18Applied = false;
    Integer discovery19CacheKeyYearNumber{}; LegacyYearCacheEntry discovery19CacheRequest{}; LegacyYearCacheEntry discovery19CachedEntry{}; Patch18YearRecord discovery19CacheOutput{}; bool discovery19CacheHit=false; bool discovery19CacheReady=false;
    LegacyYearCacheEntry patch19LegacyCachedEntryBeforePatch{}; Patch18YearRecord patch19LegacyOutputBeforePatch{}; bool patch19LegacyCacheHitBeforePatch=false; bool patch19FingerprintMatched=false; bool patch19OpenGateMatched=false; bool patch19CloseGateMatched=false; bool patch19EntryOverwritten=false; bool patch19Applied=false;
    Integer discovery20OriginalTargetDay{};
    Integer discovery20YearFirstDay{};
    Patch18YearRecord discovery20ResolvedYear{};
    Patch11LatchedOrderSauceResult discovery20LegacyStructureSauce{};
    Patch11LatchedOrderSauceResult patch20SemanticStructureSauce{};
    LegacyStructureSelectorToken discovery20SelectorToken{};
    bool discovery20SelectorConsumedLegacySauce=false;
    bool patch20GhostExecuted=false;
    bool patch20SemanticRecomputed=false;
    bool patch20GhostReachedSelector=false;
    bool patch20Applied=false;
    bool discovery20StructureSauceReady=false;
    Integer discovery21CalculationGateIndex{};
    int discovery21GapCount=0;
    int discovery21CutletCount=0;
    int discovery21InternalGateOffset=0;
    bool discovery21CalculationDayIsInternalGate=false;
    LegacyPositiveCompositionFamily discovery21LegacyFamily{};
    Integer discovery21SelectionRank{};
    std::vector<int> discovery21LegacyPartition{};
    std::vector<int> discovery21LegacyPrefixSums{};
    bool discovery21LegacyHitInternalGateBoundary=false;
    bool discovery21LegacyIgnoredInternalGate=false;
    FilteredPositiveCompositionFamily patch21SemanticFamily{};
    Integer patch21SemanticSelectionRank{};
    std::vector<int> patch21SemanticPartition{};
    std::vector<int> patch21SemanticPrefixSums{};
    bool patch21SemanticHitInternalGateBoundary=false;
    bool patch21FilterApplied=false;
    bool patch21LegacyExecuted=false;
    bool patch21LegacyPartitionReused=false;
    bool patch21Applied=false;
    bool discovery21CutletPartitionReady=false;
    int discovery22CutletCount=0;
    int discovery22MasterNameCount=0;
    Integer discovery22SelectionSpaceCount{};
    LegacyAnswerRing discovery22SelectionRing{};
    Integer discovery22SelectionRank{};
    std::vector<int> discovery22LegacyNameIndices{};
    bool discovery22LegacyContainsRepeat=false;
    bool discovery22Patch20Prepared=false;
    bool discovery22Patch21Prepared=false;
    bool discovery22RepeatedNamesReady=false;
    std::vector<int> patch22CorrectNameIndices{};
    std::vector<int> patch22SemanticNameIndices{};
    bool patch22LegacyExecuted=false;
    bool patch22CorrectComputed=false;
    bool patch22BadEqualsCorrect=false;
    bool patch22LegacyReturned=false;
    bool patch22Applied=false;
    bool patch22RepeatedNamesReady=false;
    int discovery23YearLength=0;
    int discovery23MonthCount=0;
    Integer discovery23ExactFamilyCount{};
    Integer discovery23ConcreteListIndexCapacity{};
    bool discovery23Patch22Prepared=false;
    bool discovery23LegacyConcreteListContractReached=false;
    bool discovery23LegacyConcreteEnumerationEntered=false;
    bool discovery23LegacyConcreteMaterializationCompleted=false;
    bool discovery23BlockedBeforeAllocation=false;
    std::size_t discovery23MaterializedItemCount=0;
    bool discovery23MonthLengthMaterializationReady=false;
};

struct LegacyYearJumpReport {
    LegacyYearAnchor anchor{};
    Integer targetDay{};
    Integer oldGuess{};
    Integer outputYearNumber{};
    bool guessUsedAsOutput = false;
    bool ready = false;
    std::string phase;
    std::string status;
    std::string handler;
    std::size_t branchCount = 0;
    Integer calculationDay{};
    Patch18YearRecord anchorYear{};
    Patch18YearRecord outputYear{};
    std::size_t forwardSteps = 0;
    std::size_t backwardSteps = 0;
    bool guessTelemetryOnly = false;
    bool patch18Applied = false;
};

struct LegacyYearCandidateReport {
    std::vector<Integer> gates{};
    std::vector<LegacyYearCandidatePair> pairs{};
    LegacyYearCandidateList preSort{};
    LegacyYearCandidateList sorted{};
    LegacyAnswerRing answerRing{};
    Integer selectionFamilySize{};
    bool selectionCalled = false;
    Integer selectedOrdinal{};
    LegacyYearCandidate selectedCandidate{};
    bool patch15Prepared = false;
    std::string phase;
    std::string status;
    std::string handler;
    std::size_t branchCount = 0;
    LegacyYearCandidateList legacyPreSortBeforePatch{};
    LegacyYearCandidateList rejectedBeforeSort{};
    bool patch16Applied = false;
};

struct LegacyYear5000TieReport {
    Integer calculationDay{};
    std::vector<Integer> gates{};
    std::vector<LegacyYearCandidatePair> pairs{};
    LegacyYearCandidateList preSort{};
    LegacyYearCandidateList sorted{};
    LegacyAnswerRing answerRing{};
    Integer selectionFamilySize{};
    bool selectionCalled = false;
    Integer selectedOrdinal{};
    LegacyYearCandidate selectedCandidate{};
    bool discovery17Ready = false;
    std::string phase;
    std::string status;
    std::string handler;
    std::size_t branchCount = 0;
    LegacyYearCandidateList legacySortedBeforePatch{};
    Integer legacySelectedOrdinalBeforePatch{};
    LegacyYearCandidate legacySelectedCandidateBeforePatch{};
    std::size_t equalLengthRunCount = 0;
    bool patch17Applied = false;
};

struct LegacyWideSelectionReport {
    Integer calculationDay{};
    Integer targetDay{};
    int queriedBowlId = 0;
    int seal = 0;
    Integer familySize{};
    LegacyAnswerRing answerRing{};
    bool outputAvailable = false;
    Integer outputRank{};
    bool legacyShortFailure = false;
    std::string legacyFailure;
    BowlState finalBowls{};
    PermutationOrder orderAt46Latch{};
    int nextBowlId = 0;
    bool patch11Prepared = false;
    bool patch12Prepared = false;
    std::string phase;
    std::string status;
    std::string handler;
    std::size_t branchCount = 0;
    bool legacyOutputAvailableBeforePatch = false;
    Integer legacyOutputBeforePatch{};
    bool legacyShortFailureBeforePatch = false;
    std::string legacyFailureBeforePatch;
    bool patch14Applied = false;
    bool usedShortPath = false;
    bool usedWideDetour = false;
    int widePlaces = 0;
    Integer wideSpace{};
    std::vector<Integer> wideDigits{};
    int wideDigitReadCount = 0;
    Integer wideInitialValue{};
    Integer wideAcceptanceLimit{};
    Integer wideAcceptedValue{};
    Integer wideRejectionSteps{};
};

struct LegacyGateQuestionReport {
    Integer signedStep{};
    Integer magnitudePassedToLegacy{};
    Integer outputQuestionDay{};
    std::string phase;
    std::string status;
    std::string handler;
    std::size_t branchCount = 0;
    Integer legacyOutputBeforePatch{};
    bool patch15Applied = false;
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

struct LegacyBiasedSelectionReport {
    Integer calculationDay{};
    Integer targetDay{};
    int queriedBowlId = 0;
    int seal = 0;
    Integer familySize{};
    LegacyAnswerRing answerRing{};
    Integer firstAnswer{};
    Integer outputRank{};
    BowlState finalBowls{};
    PermutationOrder orderAt46Latch{};
    int nextBowlId = 0;
    bool patch11Prepared = false;
    bool patch12Prepared = false;
    std::string phase;
    std::string status;
    std::string handler;
    std::size_t branchCount = 0;
    Integer legacyOutputBeforePatch{};
    Integer acceptanceLimit{};
    Integer acceptedAnswer{};
    Integer acceptedOffset{};
    bool patch13Applied = false;
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
    void requireLegacyBiasedSelectionReady(const BaseMonsterContext& ctx) const;
    void requirePatch13BiasedSelectionReady(const BaseMonsterContext& ctx) const;
    void requireDiscovery14WideAssumptionReady(const BaseMonsterContext& ctx) const;
    void requirePatch14WideSelectionReady(const BaseMonsterContext& ctx) const;
    void requireDiscovery15GateQuestionReady(const BaseMonsterContext& ctx) const;
    void requirePatch15GateQuestionReady(const BaseMonsterContext& ctx) const;
    void requireDiscovery16LegacyYearCandidatesReady(const BaseMonsterContext& ctx) const;
    void requirePatch16YearCandidateCeilingReady(const BaseMonsterContext& ctx) const;
    void requireDiscovery17Year5000TieReady(const BaseMonsterContext& ctx) const;
    void requirePatch17Year5000TieReady(const BaseMonsterContext& ctx) const;
    void requireDiscovery18LegacyYearJumpReady(const BaseMonsterContext& ctx) const;
    void requirePatch18YearWalkReady(const BaseMonsterContext& ctx) const;
    void requireDiscovery19YearCacheReady(const BaseMonsterContext& ctx) const;
    void requirePatch19YearCacheReady(const BaseMonsterContext& ctx) const;
    void requireDiscovery20StructureSauceReady(const BaseMonsterContext& ctx) const;
    void requirePatch20StructureSauceReady(const BaseMonsterContext& ctx) const;
    void requireDiscovery21CutletPartitionReady(const BaseMonsterContext& ctx) const;
    void requirePatch21CutletPartitionReady(const BaseMonsterContext& ctx) const;
    void requireDiscovery22RepeatedNamesReady(const BaseMonsterContext& ctx) const;
    void requirePatch22RepeatedNamesReady(const BaseMonsterContext& ctx) const;
    void requireDiscovery23MonthLengthMaterializationReady(
        const BaseMonsterContext& ctx) const;
};

class BaseMetricsShell {
public:
    void bump(BaseMonsterContext& ctx, const std::string& key) const;
};

class LegacyGateQuestionAdapter {
public:
    Integer ask(const Integer& magnitude) const;
};

class Patch15NegativeGateQuestionWrapper {
public:
    Integer repair(const Integer& signedStep,
                   const Integer& magnitude,
                   const Integer& legacyOutput) const;
};

class LegacyBiasedSelectionAdapter;
class Patch13RejectionWrapper;
class Patch14WideDetourWrapper;

class LegacyYearCandidateAdapter {
public:
    LegacyYearCandidatePreparation prepareForSelection(
        const std::vector<Integer>& gates,
        const std::vector<LegacyYearCandidatePair>& pairs) const;
    Integer select(const LegacyAnswerRing& stream,
                   const LegacyYearCandidateList& sorted,
                   const LegacyBiasedSelectionAdapter& selectionAdapter,
                   const Patch13RejectionWrapper& rejectionWrapper,
                   const Patch14WideDetourWrapper& wideWrapper) const;
};

class YearCandidateCeilingPatchWrapper {
public:
    Patch16YearCandidatePreparation prepare(
        const std::vector<Integer>& gates,
        const std::vector<LegacyYearCandidatePair>& pairs) const;
};

class LegacyYear5000TieAdapter {
public:
    LegacyYear5000TiePreparation prepare(
        const std::vector<Integer>& gates,
        const std::vector<LegacyYearCandidatePair>& pairs,
        const Integer& calculationDay) const;
    Integer select(const LegacyAnswerRing& stream,
                   const LegacyYearCandidateList& sorted,
                   const LegacyBiasedSelectionAdapter& selectionAdapter,
                   const Patch13RejectionWrapper& rejectionWrapper,
                   const Patch14WideDetourWrapper& wideWrapper) const;
};

class Year5000TiePatchWrapper {
public:
    Patch17Year5000TiePreparation repair(
        const std::vector<Integer>& gates,
        const LegacyYearCandidateList& legacySorted) const;
};

class LegacyYearJumpAdapter {
public:
    Integer guess(const LegacyYearAnchor& anchor, const Integer& targetDay) const;
};

class Patch18YearWalkWorkspace {
public:
    explicit Patch18YearWalkWorkspace(const Integer& calculationDay);
    Patch18YearRecord resolveAnchor(const LegacyYearAnchor& anchor);
    Patch18YearRecord patchedNextYear(const Patch18YearRecord& knownYear);
    Patch18YearRecord patchedPreviousYear(const Patch18YearRecord& knownYear);
private:
    Integer calculationDay_{};
    std::map<Integer, Integer> gates_{{Integer{0}, FOUNDATION_DAY_OLD}};
    Integer minGateIndex_{0};
    Integer maxGateIndex_{0};
    Integer chooseRank(const LegacyAnswerRing& stream, const Integer& familySize) const;
    Integer positiveGateGap(const Integer& n) const;
    Integer negativeGateGap(const Integer& n) const;
    Integer ensureGateIndex(const Integer& index);
    Integer exactGateIndex(const Integer& day);
};

class Patch18SequentialYearWalkWrapper {
public:
    Patch18YearWalkResult repair(const Integer& calculationDay,
                                 const LegacyYearAnchor& anchor,
                                 const Integer& targetDay) const;
};
class LegacyYearNumberOnlyCacheAdapter { public: LegacyYearCacheEntry getOrPut(std::map<Integer, LegacyYearCacheEntry>& cache, const Integer& yearNumber, const LegacyYearCacheEntry& current, bool& hit) const; };
class Patch19YearCacheGuardWrapper { public: Patch19GuardedYearCacheResolution repair(std::map<Integer, LegacyYearCacheEntry>& cache, const Integer& yearNumber, const LegacyYearCacheEntry& current, const LegacyYearCacheEntry& legacyEntry, bool legacyHit) const; };
class LegacyStructureSauceAdapter { public: Patch11LatchedOrderSauceResult call(const Integer& calculationDay, const Integer& originalTargetDay) const; };
class LegacyStructureSelectorAdapter { public: LegacyStructureSelectorToken consume(const Patch11LatchedOrderSauceResult& sauce) const; };
class StructureSaucePatchWrapper { public: Patch20StructureSauceResult repair(const Integer& calculationDay, const Integer& originalTargetDay, const Patch18YearRecord& year) const; };
class LegacyPositiveCompositionAdapter {
public:
    LegacyPositiveCompositionFamily family(int gapCount, int cutletCount) const;
    std::vector<int> unrank(const LegacyPositiveCompositionFamily& family,
                            const Integer& rank1) const;
};

class LegacyBiasedSelectionAdapter;
class Patch13RejectionWrapper;
class Patch14WideDetourWrapper;

class CutletPartitionPatchWrapper {
public:
    Patch21CutletPartitionResult repair(
        const BaseMonsterContext& ctx,
        const LegacyAnswerRing& stream,
        const LegacyBiasedSelectionAdapter& selectionAdapter,
        const Patch13RejectionWrapper& rejectionWrapper,
        const Patch14WideDetourWrapper& wideWrapper) const;
};

class LegacyRepeatedNameGenerator {
public:
    std::vector<int> call(const std::vector<int>& masterList,
                          const Integer& rank1,
                          int itemCount) const;
};

class RepeatedNamePatchWrapper {
public:
    RepeatedNamePatchDecision repair(const std::vector<int>& masterList,
                                     const Integer& rank1,
                                     int itemCount,
                                     const std::vector<int>& badNameIndices) const;
};

class LegacyMonthLengthMaterializationAdapter {
public:
    LegacyMonthLengthMaterializationInspection inspect(int yearLength,
                                                       int monthCount) const;
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

class LegacyBiasedSelectionAdapter {
public:
    Integer selectBeforeRejection(const LegacyAnswerRing& stream,
                                  const Integer& N) const;
    Integer selectAcceptedAnswer(const Integer& x,
                                 const Integer& N) const;
};

class Patch13RejectionWrapper {
public:
    Patch13RejectionSelection repair(const LegacyAnswerRing& stream,
                                     const Integer& N,
                                     const LegacyBiasedSelectionAdapter& adapter) const;
};

class LegacyShortOnlyWideSelectionAdapter {
public:
    LegacyWideSelectionAttempt attempt(const LegacyAnswerRing& stream,
                                       const Integer& N,
                                       const LegacyBiasedSelectionAdapter& selectionAdapter,
                                       const Patch13RejectionWrapper& rejectionWrapper) const;
};

class Patch14WideDetourWrapper {
public:
    Patch14WideDetourSelection repair(const LegacyAnswerRing& stream,
                                      const Integer& N,
                                      const LegacyBiasedSelectionAdapter& selectionAdapter) const;
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

class Discovery13BiasedSelectionHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyBiasedSelectionAdapter& adapter,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

class Patch13BiasedSelectionHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyBiasedSelectionAdapter& adapter,
                const Patch13RejectionWrapper& wrapper,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

class Discovery14WideAssumptionHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyShortOnlyWideSelectionAdapter& adapter,
                const LegacyBiasedSelectionAdapter& selectionAdapter,
                const Patch13RejectionWrapper& rejectionWrapper,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

class Patch14WideSelectionHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyShortOnlyWideSelectionAdapter& legacyAdapter,
                const LegacyBiasedSelectionAdapter& selectionAdapter,
                const Patch13RejectionWrapper& rejectionWrapper,
                const Patch14WideDetourWrapper& wideWrapper,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

class Discovery15GateQuestionHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyGateQuestionAdapter& adapter,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

class Patch15GateQuestionHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const Discovery15GateQuestionHandler& legacyHandler,
                const LegacyGateQuestionAdapter& adapter,
                const Patch15NegativeGateQuestionWrapper& wrapper,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

class Discovery16LegacyYearCandidateHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyYearCandidateAdapter& adapter,
                const LegacyBiasedSelectionAdapter& selectionAdapter,
                const Patch13RejectionWrapper& rejectionWrapper,
                const Patch14WideDetourWrapper& wideWrapper,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

class Patch16YearCandidateCeilingHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const YearCandidateCeilingPatchWrapper& wrapper,
                const LegacyYearCandidateAdapter& adapter,
                const LegacyBiasedSelectionAdapter& selectionAdapter,
                const Patch13RejectionWrapper& rejectionWrapper,
                const Patch14WideDetourWrapper& wideWrapper,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

class Discovery17Year5000TieHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyYear5000TieAdapter& adapter,
                const LegacyBiasedSelectionAdapter& selectionAdapter,
                const Patch13RejectionWrapper& rejectionWrapper,
                const Patch14WideDetourWrapper& wideWrapper,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

class Patch17Year5000TieHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const Discovery17Year5000TieHandler& legacyHandler,
                const LegacyYear5000TieAdapter& adapter,
                const Year5000TiePatchWrapper& wrapper,
                const LegacyBiasedSelectionAdapter& selectionAdapter,
                const Patch13RejectionWrapper& rejectionWrapper,
                const Patch14WideDetourWrapper& wideWrapper,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

class Discovery18LegacyYearJumpHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyYearJumpAdapter& adapter,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};

class Patch18SequentialYearWalkHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const Discovery18LegacyYearJumpHandler& legacyHandler,
                const LegacyYearJumpAdapter& adapter,
                const Patch18SequentialYearWalkWrapper& wrapper,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};
class Discovery19YearNumberCacheHandler { public: void handle(BaseMonsterContext& ctx, std::map<Integer, LegacyYearCacheEntry>& cache, const LegacyYearNumberOnlyCacheAdapter& adapter, const BaseValidationManager& validator, const BaseMetricsShell& metrics) const; };
class Patch19YearCacheGuardHandler { public: void handle(BaseMonsterContext& ctx, std::map<Integer, LegacyYearCacheEntry>& cache, const Discovery19YearNumberCacheHandler& legacyHandler, const LegacyYearNumberOnlyCacheAdapter& adapter, const Patch19YearCacheGuardWrapper& wrapper, const BaseValidationManager& validator, const BaseMetricsShell& metrics) const; };
class Discovery20StructureSauceHandler { public: void handle(BaseMonsterContext& ctx, const LegacyStructureSauceAdapter& sauceAdapter, const LegacyStructureSelectorAdapter& selectorAdapter, const BaseValidationManager& validator, const BaseMetricsShell& metrics) const; };
class Patch20StructureSauceHandler { public: void handle(BaseMonsterContext& ctx, const StructureSaucePatchWrapper& wrapper, const LegacyStructureSelectorAdapter& selectorAdapter, const BaseValidationManager& validator, const BaseMetricsShell& metrics) const; };
class Discovery21CutletPartitionHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyPositiveCompositionAdapter& adapter,
                const LegacyBiasedSelectionAdapter& selectionAdapter,
                const Patch13RejectionWrapper& rejectionWrapper,
                const Patch14WideDetourWrapper& wideWrapper,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};
class Patch21CutletPartitionHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const Discovery21CutletPartitionHandler& legacyHandler,
                const LegacyPositiveCompositionAdapter& adapter,
                const CutletPartitionPatchWrapper& wrapper,
                const LegacyBiasedSelectionAdapter& selectionAdapter,
                const Patch13RejectionWrapper& rejectionWrapper,
                const Patch14WideDetourWrapper& wideWrapper,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};
class Discovery22RepeatedCutletNameHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyRepeatedNameGenerator& generator,
                const LegacyBiasedSelectionAdapter& selectionAdapter,
                const Patch13RejectionWrapper& rejectionWrapper,
                const Patch14WideDetourWrapper& wideWrapper,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};
class Patch22RepeatedCutletNameHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const Discovery22RepeatedCutletNameHandler& legacyHandler,
                const LegacyRepeatedNameGenerator& generator,
                const RepeatedNamePatchWrapper& wrapper,
                const LegacyBiasedSelectionAdapter& selectionAdapter,
                const Patch13RejectionWrapper& rejectionWrapper,
                const Patch14WideDetourWrapper& wideWrapper,
                const BaseValidationManager& validator,
                const BaseMetricsShell& metrics) const;
};
class Discovery23MonthLengthMaterializationHandler {
public:
    void handle(BaseMonsterContext& ctx,
                const LegacyMonthLengthMaterializationAdapter& adapter,
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

    void dispatchLegacyBiasedSelection(BaseMonsterContext& ctx,
                                       const Discovery13BiasedSelectionHandler& handler,
                                       const LegacyBiasedSelectionAdapter& adapter,
                                       const BaseValidationManager& validator,
                                       const BaseMetricsShell& metrics) const;

    void dispatchPatchedBiasedSelection(BaseMonsterContext& ctx,
                                        const Patch13BiasedSelectionHandler& handler,
                                        const LegacyBiasedSelectionAdapter& adapter,
                                        const Patch13RejectionWrapper& wrapper,
                                        const BaseValidationManager& validator,
                                        const BaseMetricsShell& metrics) const;

    void dispatchLegacyWideSelectionAssumption(BaseMonsterContext& ctx,
                                               const Discovery14WideAssumptionHandler& handler,
                                               const LegacyShortOnlyWideSelectionAdapter& adapter,
                                               const LegacyBiasedSelectionAdapter& selectionAdapter,
                                               const Patch13RejectionWrapper& rejectionWrapper,
                                               const BaseValidationManager& validator,
                                               const BaseMetricsShell& metrics) const;

    void dispatchPatchedWideSelection(BaseMonsterContext& ctx,
                                      const Patch14WideSelectionHandler& handler,
                                      const LegacyShortOnlyWideSelectionAdapter& legacyAdapter,
                                      const LegacyBiasedSelectionAdapter& selectionAdapter,
                                      const Patch13RejectionWrapper& rejectionWrapper,
                                      const Patch14WideDetourWrapper& wideWrapper,
                                      const BaseValidationManager& validator,
                                      const BaseMetricsShell& metrics) const;

    void dispatchLegacyGateQuestion(BaseMonsterContext& ctx,
                                    const Discovery15GateQuestionHandler& handler,
                                    const LegacyGateQuestionAdapter& adapter,
                                    const BaseValidationManager& validator,
                                    const BaseMetricsShell& metrics) const;

    void dispatchPatchedGateQuestion(BaseMonsterContext& ctx,
                                     const Patch15GateQuestionHandler& handler,
                                     const Discovery15GateQuestionHandler& legacyHandler,
                                     const LegacyGateQuestionAdapter& adapter,
                                     const Patch15NegativeGateQuestionWrapper& wrapper,
                                     const BaseValidationManager& validator,
                                     const BaseMetricsShell& metrics) const;

    void dispatchLegacyYearCandidates(BaseMonsterContext& ctx,
                                      const Discovery16LegacyYearCandidateHandler& handler,
                                      const LegacyYearCandidateAdapter& adapter,
                                      const LegacyBiasedSelectionAdapter& selectionAdapter,
                                      const Patch13RejectionWrapper& rejectionWrapper,
                                      const Patch14WideDetourWrapper& wideWrapper,
                                      const BaseValidationManager& validator,
                                      const BaseMetricsShell& metrics) const;

    void dispatchPatchedYearCandidates(BaseMonsterContext& ctx,
                                       const Patch16YearCandidateCeilingHandler& handler,
                                       const YearCandidateCeilingPatchWrapper& wrapper,
                                       const LegacyYearCandidateAdapter& adapter,
                                       const LegacyBiasedSelectionAdapter& selectionAdapter,
                                       const Patch13RejectionWrapper& rejectionWrapper,
                                       const Patch14WideDetourWrapper& wideWrapper,
                                       const BaseValidationManager& validator,
                                       const BaseMetricsShell& metrics) const;

    void dispatchLegacyYear5000Tie(BaseMonsterContext& ctx,
                                   const Discovery17Year5000TieHandler& handler,
                                   const LegacyYear5000TieAdapter& adapter,
                                   const LegacyBiasedSelectionAdapter& selectionAdapter,
                                   const Patch13RejectionWrapper& rejectionWrapper,
                                   const Patch14WideDetourWrapper& wideWrapper,
                                   const BaseValidationManager& validator,
                                   const BaseMetricsShell& metrics) const;

    void dispatchPatchedYear5000Tie(BaseMonsterContext& ctx,
                                    const Patch17Year5000TieHandler& handler,
                                    const Discovery17Year5000TieHandler& legacyHandler,
                                    const LegacyYear5000TieAdapter& adapter,
                                    const Year5000TiePatchWrapper& wrapper,
                                    const LegacyBiasedSelectionAdapter& selectionAdapter,
                                    const Patch13RejectionWrapper& rejectionWrapper,
                                    const Patch14WideDetourWrapper& wideWrapper,
                                    const BaseValidationManager& validator,
                                    const BaseMetricsShell& metrics) const;

    void dispatchLegacyYearJump(BaseMonsterContext& ctx,
                                const Discovery18LegacyYearJumpHandler& handler,
                                const LegacyYearJumpAdapter& adapter,
                                const BaseValidationManager& validator,
                                const BaseMetricsShell& metrics) const;

    void dispatchPatchedYearWalk(BaseMonsterContext& ctx,
                                 const Patch18SequentialYearWalkHandler& handler,
                                 const Discovery18LegacyYearJumpHandler& legacyHandler,
                                 const LegacyYearJumpAdapter& adapter,
                                 const Patch18SequentialYearWalkWrapper& wrapper,
                                 const BaseValidationManager& validator,
                                 const BaseMetricsShell& metrics) const;
    void dispatchLegacyYearNumberCache(BaseMonsterContext& ctx, std::map<Integer, LegacyYearCacheEntry>& cache, const Discovery19YearNumberCacheHandler& handler, const LegacyYearNumberOnlyCacheAdapter& adapter, const BaseValidationManager& validator, const BaseMetricsShell& metrics) const;
    void dispatchPatchedYearNumberCache(BaseMonsterContext& ctx, std::map<Integer, LegacyYearCacheEntry>& cache, const Patch19YearCacheGuardHandler& handler, const Discovery19YearNumberCacheHandler& legacyHandler, const LegacyYearNumberOnlyCacheAdapter& adapter, const Patch19YearCacheGuardWrapper& wrapper, const BaseValidationManager& validator, const BaseMetricsShell& metrics) const;
    void dispatchDiscovery20StructureSauce(BaseMonsterContext& ctx, const Discovery20StructureSauceHandler& handler, const LegacyStructureSauceAdapter& sauceAdapter, const LegacyStructureSelectorAdapter& selectorAdapter, const BaseValidationManager& validator, const BaseMetricsShell& metrics) const;
    void dispatchPatchedStructureSauce(BaseMonsterContext& ctx, const Patch20StructureSauceHandler& handler, const StructureSaucePatchWrapper& wrapper, const LegacyStructureSelectorAdapter& selectorAdapter, const BaseValidationManager& validator, const BaseMetricsShell& metrics) const;
    void dispatchDiscovery21CutletPartition(BaseMonsterContext& ctx,
                                            const Discovery21CutletPartitionHandler& handler,
                                            const LegacyPositiveCompositionAdapter& adapter,
                                            const LegacyBiasedSelectionAdapter& selectionAdapter,
                                            const Patch13RejectionWrapper& rejectionWrapper,
                                            const Patch14WideDetourWrapper& wideWrapper,
                                            const BaseValidationManager& validator,
                                            const BaseMetricsShell& metrics) const;
    void dispatchPatchedCutletPartition(BaseMonsterContext& ctx,
                                        const Patch21CutletPartitionHandler& handler,
                                        const Discovery21CutletPartitionHandler& legacyHandler,
                                        const LegacyPositiveCompositionAdapter& adapter,
                                        const CutletPartitionPatchWrapper& wrapper,
                                        const LegacyBiasedSelectionAdapter& selectionAdapter,
                                        const Patch13RejectionWrapper& rejectionWrapper,
                                        const Patch14WideDetourWrapper& wideWrapper,
                                        const BaseValidationManager& validator,
                                        const BaseMetricsShell& metrics) const;
    void dispatchDiscovery22RepeatedCutletNames(BaseMonsterContext& ctx,
                                                const Discovery22RepeatedCutletNameHandler& handler,
                                                const LegacyRepeatedNameGenerator& generator,
                                                const LegacyBiasedSelectionAdapter& selectionAdapter,
                                                const Patch13RejectionWrapper& rejectionWrapper,
                                                const Patch14WideDetourWrapper& wideWrapper,
                                                const BaseValidationManager& validator,
                                                const BaseMetricsShell& metrics) const;
    void dispatchPatchedRepeatedCutletNames(BaseMonsterContext& ctx,
                                            const Patch22RepeatedCutletNameHandler& handler,
                                            const Discovery22RepeatedCutletNameHandler& legacyHandler,
                                            const LegacyRepeatedNameGenerator& generator,
                                            const RepeatedNamePatchWrapper& wrapper,
                                            const LegacyBiasedSelectionAdapter& selectionAdapter,
                                            const Patch13RejectionWrapper& rejectionWrapper,
                                            const Patch14WideDetourWrapper& wideWrapper,
                                            const BaseValidationManager& validator,
                                            const BaseMetricsShell& metrics) const;
    void dispatchDiscovery23MonthLengthMaterialization(
        BaseMonsterContext& ctx,
        const Discovery23MonthLengthMaterializationHandler& handler,
        const LegacyMonthLengthMaterializationAdapter& adapter,
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
    LegacyBiasedSelectionReport executeLegacyBiasedSelection(
        const Integer& calculationDay,
        const Integer& targetDay,
        int queriedBowlId,
        int seal,
        const Integer& familySize) const;
    LegacyBiasedSelectionReport executeUnpatchedBiasedSelectionDiagnostic(
        const Integer& calculationDay,
        const Integer& targetDay,
        int queriedBowlId,
        int seal,
        const Integer& familySize) const;
    LegacyWideSelectionReport executeLegacyWideSelectionAssumption(
        const Integer& calculationDay,
        const Integer& targetDay,
        int queriedBowlId,
        int seal,
        const Integer& familySize) const;
    LegacyWideSelectionReport executeUnpatchedWideSelectionDiagnostic(
        const Integer& calculationDay,
        const Integer& targetDay,
        int queriedBowlId,
        int seal,
        const Integer& familySize) const;
    LegacyGateQuestionReport executeLegacyGateQuestionDay(const Integer& signedStep) const;
    LegacyGateQuestionReport executeUnpatchedGateQuestionDayDiagnostic(const Integer& signedStep) const;
    LegacyYearCandidateReport executeLegacyYearCandidateDiscovery(
        const Integer& calculationDay,
        const Integer& targetDay,
        const std::vector<Integer>& gates,
        const std::vector<LegacyYearCandidatePair>& pairs,
        int queriedBowlId,
        int seal) const;
    LegacyYearCandidateReport executeUnpatchedYearCandidateDiscoveryDiagnostic(
        const Integer& calculationDay,
        const Integer& targetDay,
        const std::vector<Integer>& gates,
        const std::vector<LegacyYearCandidatePair>& pairs,
        int queriedBowlId,
        int seal) const;
    LegacyYear5000TieReport executeLegacyYear5000TieDiscovery(
        const Integer& calculationDay,
        const Integer& targetDay,
        const std::vector<Integer>& gates,
        const std::vector<LegacyYearCandidatePair>& pairs,
        int queriedBowlId,
        int seal) const;
    LegacyYear5000TieReport executeUnpatchedYear5000TieDiagnostic(
        const Integer& calculationDay,
        const Integer& targetDay,
        const std::vector<Integer>& gates,
        const std::vector<LegacyYearCandidatePair>& pairs,
        int queriedBowlId,
        int seal) const;
    LegacyYearJumpReport executeLegacyYearJump(const LegacyYearAnchor& anchor,
                                               const Integer& targetDay,
                                               const Integer& calculationDay = FOUNDATION_DAY_OLD) const;
    LegacyYearJumpReport executeUnpatchedYearJumpDiagnostic(
        const LegacyYearAnchor& anchor,
        const Integer& targetDay) const;
    LegacyYearCacheReport executeLegacyYearNumberCache(const LegacyYearAnchor& anchor, const Integer& targetDay, const Integer& calculationDay) const;
    LegacyYearCacheReport executeUnpatchedYearNumberCacheDiagnostic(const LegacyYearAnchor& anchor, const Integer& targetDay, const Integer& calculationDay) const;
    LegacyStructureSauceReport executeDiscovery20StructureSauce(const LegacyYearAnchor& anchor, const Integer& originalTargetDay, const Integer& calculationDay) const;
    LegacyStructureSauceReport executeUnpatchedDiscovery20StructureSauceDiagnostic(const LegacyYearAnchor& anchor, const Integer& originalTargetDay, const Integer& calculationDay) const;
    LegacyCutletPartitionReport executeDiscovery21CutletPartition(
        const LegacyYearAnchor& anchor,
        const Integer& originalTargetDay,
        const Integer& calculationDay,
        const Integer& calculationGateIndex,
        int cutletCount) const;
    LegacyCutletPartitionReport executeUnpatchedDiscovery21CutletPartitionDiagnostic(
        const LegacyYearAnchor& anchor,
        const Integer& originalTargetDay,
        const Integer& calculationDay,
        const Integer& calculationGateIndex,
        int cutletCount) const;
    LegacyRepeatedNameReport executeDiscovery22RepeatedCutletNames(
        const LegacyYearAnchor& anchor,
        const Integer& originalTargetDay,
        const Integer& calculationDay,
        const Integer& calculationGateIndex,
        int cutletCount) const;
    LegacyRepeatedNameReport executeUnpatchedDiscovery22RepeatedCutletNamesDiagnostic(
        const LegacyYearAnchor& anchor,
        const Integer& originalTargetDay,
        const Integer& calculationDay,
        const Integer& calculationGateIndex,
        int cutletCount) const;
    LegacyMonthLengthMaterializationReport executeDiscovery23MonthLengthMaterialization(
        const LegacyYearAnchor& anchor,
        const Integer& originalTargetDay,
        const Integer& calculationDay,
        const Integer& calculationGateIndex,
        int cutletCount,
        int monthCount) const;
    void clearLegacyYearNumberCacheDiagnostic() const;
private:
    mutable std::map<Integer, LegacyYearCacheEntry> legacyYearNumberCache_{};
};

} // namespace pastafari
