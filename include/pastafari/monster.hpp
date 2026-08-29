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
};

} // namespace pastafari
