#include "pastafari/monster.hpp"

#include <iostream>
#include <map>
#include <stdexcept>
#include <string>

namespace {
using pastafari::BaseMonsterManager;
using pastafari::BaseRecoverableError;
using pastafari::FinalIntegrationFaultPlan;
using pastafari::Integer;
using pastafari::SpaghettiDateFive;
using pastafari::Stage54IntegrationReport;

void exige(bool condicio, const char* causa) {
    if (!condicio) throw std::runtime_error(causa);
}

bool eademDies(const SpaghettiDateFive& a, const SpaghettiDateFive& b) {
    return a.yearNumber == b.yearNumber &&
           a.cutletName == b.cutletName &&
           a.dayInCutlet == b.dayInCutlet &&
           a.monthName == b.monthName &&
           a.dayInMonth == b.dayInMonth;
}

void exigeViridem(const Stage54IntegrationReport& r) {
    exige(r.ready && r.status == "GREEN", "exitus integrationis non viridis");
    exige(r.exactFiveFieldReturn, "quinque campi exacti non confirmati");
}

void exigeRecuperationem(const Stage54IntegrationReport& r,
                         int defectus, int reliquum) {
    exigeViridem(r);
    exige(r.recoverableFailuresObserved == defectus,
          "numerus defectuum recuperabilium discrepavit");
    exige(r.recoveryDepth == defectus,
          "altitudo recuperationis discrepavit");
    exige(r.retryBudgetRemaining == reliquum,
          "numerus conatuum reliquorum discrepavit");
    exige(r.recoverySnapshotRestoredExactly == (defectus != 0),
          "snapshot recuperationis non exacte restitutum est");
}
void exigeRepetitionemContextus() {
    pastafari::BaseMonsterContext contextus;
    std::map<Integer, pastafari::FinalStructureCacheEntry> cache;
    const pastafari::FinalIntegrationHandler handler;
    const pastafari::BaseValidationManager validator;
    const pastafari::BaseMetricsShell metrics;
    const Integer c0 = pastafari::FOUNDATION_DAY_OLD;
    const Integer c1 = c0 + 1;

    const auto invoca = [&](const Integer& c) {
        contextus.calculationDay = c;
        contextus.targetDay = c;
        contextus.stage56CorrectiveRequested = true;
        handler.handle(contextus, cache, validator, metrics);
        exige(contextus.status == "GREEN", "contextus iteratus non viridis");
    };

    invoca(c0);
    exige(!contextus.finalGuardedCacheHit &&
          contextus.stage56AppliedCount == 12,
          "contextus primus non computavit XII commotiones");
    const SpaghettiDateFive primus = contextus.resultFive;

    invoca(c0);
    exige(contextus.finalGuardedCacheHit,
          "contextus reusus cache calidum non cognovit");
    exige(contextus.stage56AppliedCount == 0,
          "cache calidus cicatrices veteris invocationis retinuit");
    exige(eademDies(primus, contextus.resultFive),
          "contextus reusus cache calido exitum corrupit");

    invoca(c1);
    exige(!contextus.finalGuardedCacheHit && contextus.finalGuardedCacheRejected,
          "contextus reusus flag cache-hit veterem ad novum c transtulit");
    exige(contextus.stage56AppliedFlag &&
          contextus.stage56LegacyScarCallCount == 12 &&
          contextus.stage56AppliedCount == 12,
          "contextus reusus XII cicatrices post cache rejectum non reexercuit");
    const SpaghettiDateFive recens =
        pastafari::calendarDateSpaghetti(c1, c1);
    exige(eademDies(recens, contextus.resultFive),
          "contextus reusus exitum contra novam invocationem discrepavit");

    invoca(c1);
    exige(contextus.finalGuardedCacheHit && !contextus.finalGuardedCacheRejected,
          "contextus reusus flag cache-rejection vetus retinuit");
    exige(contextus.stage56AppliedCount == 0,
          "cache secundum calidum cicatrices novas simulavit");
}

} // namespace

int main() {
    try {
        const Integer c0 = pastafari::FOUNDATION_DAY_OLD;
        const Integer c1 = c0 + 1;

        BaseMonsterManager primus;
        BaseMonsterManager alter;
        const Stage54IntegrationReport p0 =
            primus.executeFinalIntegrationStage56(c0, c0);
        const Stage54IntegrationReport a0 =
            alter.executeFinalIntegrationStage56(c0, c0);
        exigeViridem(p0);
        exigeViridem(a0);
        exige(eademDies(p0.result, a0.result),
              "primae invocationes instantiae diversae discrepaverunt");
        exige(!p0.guardedCacheHit && !a0.guardedCacheHit,
              "cache initio frigidum esse debet");
        exige(primus.stage56FinalStructureCacheSizeDiagnostic() == 1 &&
              alter.stage56FinalStructureCacheSizeDiagnostic() == 1,
              "cache Stage 56 initio non creatus est");
        exige(primus.finalStructureCacheSizeDiagnostic() == 0 &&
              alter.finalStructureCacheSizeDiagnostic() == 0,
              "cache historicum Stage 55 per Stage 56 pollutus est");

        const Stage54IntegrationReport p1 =
            primus.executeFinalIntegrationStage56(c0, c0);
        const Stage54IntegrationReport a1 =
            alter.executeFinalIntegrationStage56(c0, c0);
        exigeViridem(p1);
        exigeViridem(a1);
        exige(p1.guardedCacheHit && a1.guardedCacheHit,
              "cache Stage 56 in invocatione repetita non adhibitus est");
        exige(eademDies(p0.result, p1.result) &&
              eademDies(a0.result, a1.result),
              "status cache calidus semanticae vim dedit");

        const Stage54IntegrationReport mutatus =
            primus.executeFinalIntegrationStage56(c1, c1);
        const Stage54IntegrationReport novus =
            BaseMonsterManager{}.executeFinalIntegrationStage56(c1, c1);
        exigeViridem(mutatus);
        exigeViridem(novus);
        exige(mutatus.guardedCacheRejected,
              "mutatio calculationDay cache eiusdem anni non reiecit");
        exige(eademDies(mutatus.result, novus.result),
              "cache vetus exitum mutatum corrupit");
        const Stage54IntegrationReport mutatusIterum =
            primus.executeFinalIntegrationStage56(c1, c1);
        exige(mutatusIterum.guardedCacheHit &&
              eademDies(mutatus.result, mutatusIterum.result),
              "cache post reiectionem non refectus est");
        exige(eademDies(a0.result,
                        alter.executeFinalIntegrationStage56(c0, c0).result),
              "altera instantia a prima contaminata est");

        BaseMonsterManager reciperans;
        const Stage54IntegrationReport r0 =
            reciperans.executeFinalIntegrationStage56RecoveryAudit(
                c0, c0, FinalIntegrationFaultPlan{0, 2, 50});
        const Stage54IntegrationReport r1 =
            reciperans.executeFinalIntegrationStage56RecoveryAudit(
                c0, c0, FinalIntegrationFaultPlan{1, 2, 50});
        const Stage54IntegrationReport r2 =
            reciperans.executeFinalIntegrationStage56RecoveryAudit(
                c0, c0, FinalIntegrationFaultPlan{2, 2, 50});
        exigeRecuperationem(r0, 0, 2);
        exigeRecuperationem(r1, 1, 1);
        exigeRecuperationem(r2, 2, 0);
        exige(eademDies(p0.result, r0.result) &&
              eademDies(p0.result, r1.result) &&
              eademDies(p0.result, r2.result),
              "retry ante validationem exitum canonicum mutavit");

        BaseMonsterManager structura;
        const Stage54IntegrationReport anteStructuram =
            structura.executeFinalIntegrationStage56RecoveryAudit(
                c0, c0, FinalIntegrationFaultPlan{1, 1, 40});
        exigeRecuperationem(anteStructuram, 1, 0);
        exige(eademDies(p0.result, anteStructuram.result),
              "retry in structura exitum canonicum mutavit");

        BaseMonsterManager exhaustus;
        bool erroremCepit = false;
        try {
            (void)exhaustus.executeFinalIntegrationStage56RecoveryAudit(
                c0, c0, FinalIntegrationFaultPlan{3, 2, 50});
        } catch (const BaseRecoverableError&) {
            erroremCepit = true;
        }
        exige(erroremCepit, "exhaustio retry non nuntiata est");
        exige(exhaustus.stage56FinalStructureCacheSizeDiagnostic() == 0,
              "cache Stage 56 ante validationem in errore scriptus est");
        const Stage54IntegrationReport sanus =
            exhaustus.executeFinalIntegrationStage56(c0, c0);
        exigeViridem(sanus);
        exige(eademDies(p0.result, sanus.result),
              "errorem priorem status semanticus secutus est");
        exige(exhaustus.stage56FinalStructureCacheSizeDiagnostic() == 1,
              "cache post errorem non rite creatus est");
        exige(exhaustus.finalStructureCacheSizeDiagnostic() == 0,
              "cache Stage 55 a recuperatione Stage 56 contaminatus est");

        const SpaghettiDateFive publicus =
            pastafari::calendarDateSpaghetti(c0, c0);
        exige(eademDies(publicus, p0.result),
              "API publica et manager Stage 56 discrepant");

        exigeRepetitionemContextus();

        std::cout << "GRADUS56_CACHE_RECOVERY_TRANSIIT: "
                     "cache frigidus/calidus, reiectio fingerprint, "
                     "duae instantiae, retry 0/1/2, injectio 40/50, "
                     "exhaustio sine commit, cache historicus separatus, "
                     "API publica et contextus reusus congruentes\n";
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "GRADUS56_CACHE_RECOVERY_DEFECIT: "
                  << e.what() << '\n';
        return 1;
    }
}
