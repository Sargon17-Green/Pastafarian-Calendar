#include "pastafari/monster.hpp"

#include <iostream>
#include <stdexcept>
#include <string>

using pastafari::BaseMonsterManager;
using pastafari::BaseRecoverableError;
using pastafari::FinalIntegrationFaultPlan;
using pastafari::SpaghettiDateFive;
using pastafari::Stage54IntegrationReport;

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

void requireRetryReport(const Stage54IntegrationReport& report,
                        int failures,
                        int budgetRemaining) {
    require(report.ready, "integratio post retry parata esse debet");
    require(report.status == "GREEN", "integratio post retry viridis esse debet");
    require(report.recoverableFailuresObserved == failures,
            "numerus defectuum recoverabilium observatorum discrepat");
    require(report.recoveryDepth == failures,
            "recoveryDepth numerum retry prosperorum sequi debet");
    require(report.retryBudgetRemaining == budgetRemaining,
            "retryBudget residuum discrepat");
    require(report.recoverySnapshotRestoredExactly == (failures != 0),
            "signum restitutionis snapshot discrepat");
}
}

int main() {
    try {
        const auto c = pastafari::FOUNDATION_DAY_OLD;
        const auto t = pastafari::FOUNDATION_DAY_OLD;

        BaseMonsterManager manager;
        const auto retry0 = manager.executeFinalIntegrationRecoveryAudit(
            c, t, FinalIntegrationFaultPlan{0, 2, 50});
        const auto retry1 = manager.executeFinalIntegrationRecoveryAudit(
            c, t, FinalIntegrationFaultPlan{1, 2, 50});
        const auto retry2 = manager.executeFinalIntegrationRecoveryAudit(
            c, t, FinalIntegrationFaultPlan{2, 2, 50});
        requireRetryReport(retry0, 0, 2);
        requireRetryReport(retry1, 1, 1);
        requireRetryReport(retry2, 2, 0);
        require(sameResult(retry0.result, retry1.result) &&
                sameResult(retry0.result, retry2.result),
                "retry 0/1/2 idem output normativum reddere debent");

        BaseMonsterManager structureManager;
        const auto structureRetry = structureManager.executeFinalIntegrationRecoveryAudit(
            c, t, FinalIntegrationFaultPlan{1, 1, 40});
        requireRetryReport(structureRetry, 1, 0);
        require(sameResult(retry0.result, structureRetry.result),
                "retry in structura idem output normativum reddere debet");

        BaseMonsterManager exhaustedManager;
        bool exhausted = false;
        try {
            (void)exhaustedManager.executeFinalIntegrationRecoveryAudit(
                c, t, FinalIntegrationFaultPlan{3, 2, 50});
        } catch (const BaseRecoverableError& error) {
            exhausted = std::string(error.what()).find("exhaustum") != std::string::npos;
        }
        require(exhausted, "exhaustio retry errorem recoverabilem explicitum exigere debet");
        require(exhaustedManager.finalStructureCacheSizeDiagnostic() == 0,
                "cache ante validationem et commit scribi non debet");
        const auto postExhaustion = exhaustedManager.executeFinalIntegration(c, t);
        require(sameResult(postExhaustion.result, retry0.result),
                "post exhaustionem nullus status semanticus pendens effluere debet");
        require(exhaustedManager.finalStructureCacheSizeDiagnostic() == 1,
                "post errorem invocatio nova cache solum post validationem implere debet");

        std::cout
            << "AUDIT_RECOVERY_GRADUS_55_TRANSIIT: retry 0/1/2, exhaustion explicitum, "
               "snapshot exactum et cache post validationem probata sunt\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "AUDIT_RECOVERY_GRADUS_55_DEFECIT: " << error.what() << '\n';
        return 1;
    }
}
