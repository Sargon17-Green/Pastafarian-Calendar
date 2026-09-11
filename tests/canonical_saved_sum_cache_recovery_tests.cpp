// Canonical saved-sum correction: Stage 56 cache/history/recovery audit.
// This file intentionally tests the production manager, not the raw-sum mutant.
#include "pastafari/monster.hpp"

#include <iostream>
#include <stdexcept>
#include <string>

using pastafari::BaseMonsterManager;
using pastafari::BaseRecoverableError;
using pastafari::FinalIntegrationFaultPlan;
using pastafari::SpaghettiDateFive;

namespace {
void require(bool condition, const std::string& message) {
    if (!condition) throw std::runtime_error(message);
}

bool sameResult(const SpaghettiDateFive& a, const SpaghettiDateFive& b) {
    return a.yearNumber == b.yearNumber &&
           a.cutletName == b.cutletName &&
           a.dayInCutlet == b.dayInCutlet &&
           a.monthName == b.monthName &&
           a.dayInMonth == b.dayInMonth;
}
}

int main() {
    try {
        const auto c = pastafari::FOUNDATION_DAY_OLD;
        const auto a = pastafari::FOUNDATION_DAY_OLD;
        const auto b = pastafari::FOUNDATION_DAY_OLD + 1;

        BaseMonsterManager manager;
        const auto coldA = manager.executeFinalIntegrationStage56(c, a);
        require(coldA.ready && coldA.status == "GREEN" && !coldA.guardedCacheHit,
                "Stage56 cold A debet computare sine cache hit");
        const auto warmA = manager.executeFinalIntegrationStage56(c, a);
        require(warmA.ready && warmA.status == "GREEN" && warmA.guardedCacheHit,
                "Stage56 warm A debet cache semanticum attingere");
        require(sameResult(coldA.result, warmA.result),
                "Stage56 cold/warm A output discrepat");

        const auto firstB = manager.executeFinalIntegrationStage56(c, b);
        const auto backA = manager.executeFinalIntegrationStage56(c, a);
        BaseMonsterManager freshManager;
        const auto freshB = freshManager.executeFinalIntegrationStage56(c, b);
        require(sameResult(firstB.result, freshB.result),
                "Stage56 B pendet ex historia instantiae");
        require(sameResult(coldA.result, backA.result),
                "Stage56 A->B->A output discrepat");

        BaseMonsterManager retryManager;
        const auto retry = retryManager.executeFinalIntegrationStage56RecoveryAudit(
            c, a, FinalIntegrationFaultPlan{1, 2, 50});
        require(retry.ready && retry.status == "GREEN" &&
                retry.recoverableFailuresObserved == 1 &&
                retry.recoveryDepth == 1 && retry.retryBudgetRemaining == 1 &&
                retry.recoverySnapshotRestoredExactly,
                "Stage56 recovery audit metadata discrepat");
        require(sameResult(retry.result, coldA.result),
                "Stage56 retry mutavit output canonicalem");

        BaseMonsterManager exhaustedManager;
        bool exhausted = false;
        try {
            (void)exhaustedManager.executeFinalIntegrationStage56RecoveryAudit(
                c, a, FinalIntegrationFaultPlan{3, 2, 50});
        } catch (const BaseRecoverableError&) {
            exhausted = true;
        }
        require(exhausted, "Stage56 retry exhaustion errorem recoverabilem exigere debet");
        require(exhaustedManager.stage56FinalStructureCacheSizeDiagnostic() == 0,
                "Stage56 cache non debet post exhaustionem contaminari");
        const auto postExhaustion = exhaustedManager.executeFinalIntegrationStage56(c, a);
        require(sameResult(postExhaustion.result, coldA.result),
                "Stage56 clean retry post exhaustionem output mutavit");
        require(exhaustedManager.stage56FinalStructureCacheSizeDiagnostic() == 1,
                "Stage56 clean retry cache validum implere debet");

        std::cout
            << "CANONICAL_SAVED_SUM_CACHE_RECOVERY=PASS: cold/warm, A->B->A, "
               "fresh-instance, retry, exhaustion, clean-retry\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "CANONICAL_SAVED_SUM_CACHE_RECOVERY=FAIL: " << error.what() << '\n';
        return 1;
    }
}
