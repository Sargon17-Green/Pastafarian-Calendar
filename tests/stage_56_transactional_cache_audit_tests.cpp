#include "pastafari/monster.hpp"
#include "pastafari/source_language_catalog.hpp"

#include <algorithm>
#include <array>
#include <cstddef>

#include <iostream>
#include <map>
#include <numeric>
#include <set>
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



void exigeTexturamEtTerminosExStructuraIndependenter() {
    // Oraculum internum post fabricationem anni: hic neque adapter
    // PATCH25 neque cache output productionis in exspectatione adhibetur.
    const Integer c = pastafari::FOUNDATION_DAY_OLD;
    BaseMonsterManager reusus;
    const auto prima = reusus.executeFinalIntegrationStage56(c, c);
    exigeViridem(prima);
    const auto& s = prima.structure;
    const auto& year = prima.targetYear;
    const Integer n = year.closeGateDay - year.openGateDay;

    exige(s.cutletCount >= 6 && s.cutletCount <= 17,
          "numerus segmentorum non legalis");
    exige(static_cast<int>(s.cutlets.size()) == s.cutletCount &&
          static_cast<int>(s.cutletPartition.size()) == s.cutletCount &&
          static_cast<int>(s.cutletNameIndices.size()) == s.cutletCount,
          "magnitudines segmentorum non concordant");
    exige(s.monthCount >= 3 && s.monthCount <= 47 &&
          static_cast<int>(s.monthLengths.size()) == s.monthCount &&
          static_cast<int>(s.monthNameIndices.size()) == s.monthCount,
          "magnitudines mensium non concordant");
    exige(Integer{s.monthWeaving.size()} == n,
          "texturae longitudo ab anno discrepat");

    std::set<Integer> targets;
    targets.insert(year.openGateDay + 1);
    targets.insert(year.closeGateDay);
    targets.insert(year.openGateDay + (n + 1) / 2);
    Integer nextCutletFirst = year.openGateDay + 1;
    for (int k = 0; k < s.cutletCount; ++k) {
        const auto& x = s.cutlets[static_cast<std::size_t>(k)];
        exige(x.firstDay == nextCutletFirst && x.lastDay >= x.firstDay,
              "segmenta non contigua sunt");
        exige(x.canonicalIndex == s.cutletNameIndices[static_cast<std::size_t>(k)] &&
              x.canonicalIndex >= 1 && x.canonicalIndex <= 17,
              "index nominis segmenti invalidus");
        nextCutletFirst = x.lastDay + 1;
    }
    exige(nextCutletFirst == year.closeGateDay + 1,
          "segmenta usque ad ultimum diem non perveniunt");

    // Ambae partes primi et ultimi termini segmenti, etiam si mutationes
    // menses cum iis non congruunt.
    for (const auto* x : {&s.cutlets.front(), &s.cutlets.back()}) {
        targets.insert(x->firstDay);
        targets.insert(x->lastDay);
    }
    if (s.cutlets.size() > 1) {
        targets.insert(s.cutlets[0].lastDay);
        targets.insert(s.cutlets[1].firstDay);
    }

    std::vector<int> remaining = s.monthLengths;
    std::vector<std::size_t> primaOcc(
        static_cast<std::size_t>(s.monthCount), s.monthWeaving.size());
    std::vector<std::size_t> ultimaOcc(
        static_cast<std::size_t>(s.monthCount), s.monthWeaving.size());
    int aperti = 0;
    int clausi = 0;
    for (std::size_t pos = 0; pos < s.monthWeaving.size(); ++pos) {
        const int monthId = s.monthWeaving[pos];
        exige(monthId >= 1 && monthId <= s.monthCount,
              "textura mensis indicem extra fines habet");
        const std::size_t k = static_cast<std::size_t>(monthId - 1);
        exige(remaining[k] > 0, "mensis plures dies quam definiti recepit");
        if (remaining[k] == s.monthLengths[k]) {
            exige(monthId == aperti + 1,
                  "ordo primae apparitionis mensium non legalis");
            aperti = monthId;
            primaOcc[k] = pos;
        }
        --remaining[k];
        if (remaining[k] == 0) {
            exige(monthId == clausi + 1,
                  "ordo ultimae apparitionis mensium non legalis");
            clausi = monthId;
            ultimaOcc[k] = pos;
        }
    }
    exige(aperti == s.monthCount && clausi == s.monthCount &&
          std::all_of(remaining.begin(), remaining.end(),
                      [](int count) { return count == 0; }),
          "textura omnes menses non aperuit et clausit");
    for (int name : s.monthNameIndices) {
        exige(name >= 1 && name <= 47, "index nominis mensis invalidus");
    }
    // Testantur initium/finem mensis primi, secundi et ultimi;
    // maximo duodecim puncta ad tempus CI moderatum.
    for (int k : {0, 1, s.monthCount - 1}) {
        targets.insert(year.openGateDay + 1 +
                       Integer{primaOcc[static_cast<std::size_t>(k)]});
        targets.insert(year.openGateDay + 1 +
                       Integer{ultimaOcc[static_cast<std::size_t>(k)]});
    }

    for (const Integer& t : targets) {
        const auto actual = reusus.executeFinalIntegrationStage56(c, t);
        exigeViridem(actual);
        exige(actual.guardedCacheHit && !actual.guardedCacheRejected,
              "sample intra annum debet cache calidum uti");
        const auto* segmentum = static_cast<const pastafari::SpaghettiCutletRecord*>(nullptr);
        for (const auto& x : s.cutlets) {
            if (x.firstDay <= t && t <= x.lastDay) {
                segmentum = &x;
                break;
            }
        }
        exige(segmentum != nullptr, "sample sine segmento");
        const std::size_t p = (t - year.openGateDay - 1).convert_to<std::size_t>();
        const int monthId = s.monthWeaving.at(p);
        const int occ = static_cast<int>(std::count(
            s.monthWeaving.begin(), s.monthWeaving.begin() +
                static_cast<std::ptrdiff_t>(p + 1), monthId));
        const SpaghettiDateFive expected{
            year.number,
            std::string(pastafari::cutletSourceName(
                static_cast<std::size_t>(segmentum->canonicalIndex))),
            t - segmentum->firstDay + 1,
            std::string(pastafari::monthSourceName(
                static_cast<std::size_t>(
                    s.monthNameIndices.at(static_cast<std::size_t>(monthId - 1))))),
            Integer{occ}
        };
        exige(eademDies(actual.result, expected),
              "sample terminalis structuram versus API mutavit");
    }
    exige(targets.size() >= 8,
          "sample structurale fines diversos non exercuit");
}

void exigeTresCustodesCacheSeparatim() {
    // Iniectio test-only in cache structurae. Singulus custodum triplicis
    // identitatis corrumpitur, sine immutatione diei interrogati.
    // Corruptio structurae adiuncta semper reparari debet post rejectum.
    const Integer c = pastafari::FOUNDATION_DAY_OLD;
    const Integer t = c;
    pastafari::BaseMonsterContext ctx;
    std::map<Integer, pastafari::FinalStructureCacheEntry> cache;
    const pastafari::FinalIntegrationHandler handler;
    const pastafari::BaseValidationManager validator;
    const pastafari::BaseMetricsShell metrics;
    ctx.calculationDay = c;
    ctx.targetDay = t;
    ctx.stage56CorrectiveRequested = true;

    const auto invoca = [&] {
        handler.handle(ctx, cache, validator, metrics);
        exige(ctx.status == "GREEN" && ctx.finalIntegrationReady,
              "audit triplicis cache non viridis");
    };

    invoca();
    const SpaghettiDateFive expected = ctx.resultFive;
    exige(!ctx.finalGuardedCacheHit && !ctx.finalGuardedCacheRejected,
          "prima invocatio cache non frigida est");
    exige(cache.size() == 1, "prima invocatio cache unicum non produxit");
    const Integer annus = ctx.finalCurrentYear.number;
    exige(cache.contains(annus),
          "clavis anni initialis in cache absens est");
    const pastafari::FinalStructureCacheEntry vera = cache.at(annus);
    exige(vera.calculationDayFingerprint == c &&
          vera.openGate == ctx.finalCurrentYear.openGateDay &&
          vera.closeGate == ctx.finalCurrentYear.closeGateDay,
          "initio tres custodes cache incorrecti sunt");

    for (int quae = 0; quae < 3; ++quae) {
        // Custodem unum tantum adulteramus et body invalidum reponimus.
        auto& entry = cache.at(annus);
        entry = vera;
        if (quae == 0) {
            ++entry.calculationDayFingerprint;
        } else if (quae == 1) {
            --entry.openGate;
        } else {
            ++entry.closeGate;
        }
        entry.value.cutlets.clear();
        entry.value.monthWeaving.clear();

        invoca();
        exige(ctx.finalGuardedCacheRejected && !ctx.finalGuardedCacheHit,
              "cache adulteratus non repudiatus est");
        exige(ctx.stage56AppliedFlag &&
              ctx.stage56LegacyScarCallCount == 12 &&
              ctx.stage56AppliedCount == 12,
              "cache corruptus novam computationem XII commotionum omisit");
        exige(eademDies(ctx.resultFive, expected),
              "reconstructio post cache corruptum quinque campos mutavit");
        exige(cache.size() == 1, "reconstructio cache duplicem annum inseruit");
        const auto& novus = cache.at(annus);
        exige(novus.calculationDayFingerprint == vera.calculationDayFingerprint &&
              novus.openGate == vera.openGate &&
              novus.closeGate == vera.closeGate &&
              !novus.value.cutlets.empty() &&
              !novus.value.monthWeaving.empty(),
              "custodes et structura post rejectum non reparati sunt");

        invoca();
        exige(ctx.finalGuardedCacheHit && !ctx.finalGuardedCacheRejected,
              "cache reparatus secunda invocatione non calidus est");
        exige(ctx.stage56AppliedCount == 0,
              "cache reparatus computationem redundantem simulavit");
        exige(eademDies(ctx.resultFive, expected),
              "cache reparatus output quinque camporum mutavit");
    }
}

void exigeMetamorphosinDieiCalculationis() {
    // Tantum dies calculationis mutatur: dies quaesitus invariabilis.
    // Cache utitur yearNumber pro clave, sed fingerprint diei calculationis
    // partem identitatis semanticae servare debet.
    const Integer c0 = pastafari::FOUNDATION_DAY_OLD;
    const Integer c1 = c0 + 1;
    const Integer t = c0;
    BaseMonsterManager reusus;

    const Stage54IntegrationReport ante =
        reusus.executeFinalIntegrationStage56(c0, t);
    exigeViridem(ante);
    exige(!ante.guardedCacheHit && !ante.guardedCacheRejected,
          "cache primum dies calculationis non frigidus est");

    const Stage54IntegrationReport alternus =
        reusus.executeFinalIntegrationStage56(c1, t);
    const Stage54IntegrationReport recens =
        BaseMonsterManager{}.executeFinalIntegrationStage56(c1, t);
    exigeViridem(alternus);
    exigeViridem(recens);
    exige(alternus.targetYear.number == ante.targetYear.number,
          "prova fingerprint eundem annum non tenuit");
    exige(alternus.guardedCacheRejected && !alternus.guardedCacheHit,
          "mutatio calculationDay solo fingerprint vetus non reiecit");
    exige(!recens.guardedCacheHit,
          "novus manager cache frigidum non habuit");
    exige(eademDies(alternus.result, recens.result),
          "mutatio calculationDay solo exitum contra fresh corrupit");
    exige(reusus.stage56FinalStructureCacheSizeDiagnostic() == 1,
          "mutatio calculationDay falso plures annos cumulavit");

    const Stage54IntegrationReport calidus =
        reusus.executeFinalIntegrationStage56(c1, t);
    exigeViridem(calidus);
    exige(calidus.guardedCacheHit && !calidus.guardedCacheRejected,
          "eadem calculationDay post reiectionem cache non calefecit");
    exige(eademDies(calidus.result, recens.result),
          "cache calidus post reiectionem output corrupit");

    const Stage54IntegrationReport reversus =
        reusus.executeFinalIntegrationStage56(c0, t);
    exigeViridem(reversus);
    exige(reversus.guardedCacheRejected && !reversus.guardedCacheHit,
          "reditus ad diem calculationis primum fingerprint non reiecit");
    exige(eademDies(reversus.result, ante.result),
          "reditus calculationis output primum non restituit");
    exige(reusus.stage56FinalStructureCacheSizeDiagnostic() == 1,
          "repetita fingerprint reiectio incrementum cache spurium creavit");
}

void exigeMetamorphosinDieiQuaesiti() {
    // Unum diem calculationis retinemus; dies interrogatus intra annum,
    // deinde trans utrumque terminum, mutatur. Structura per annum
    // servata numquam resultatum diei interrogati veteris restituere debet.
    const Integer c = pastafari::FOUNDATION_DAY_OLD;
    BaseMonsterManager reusus;
    const Stage54IntegrationReport initium =
        reusus.executeFinalIntegrationStage56(c, c);
    exigeViridem(initium);
    const auto& annus = initium.targetYear;
    exige(annus.openGateDay < c && c <= annus.closeGateDay,
          "dies calculationis extra annum initialem est");
    exige(annus.closeGateDay - annus.openGateDay >= 252,
          "annus initialis brevior minimo legali est");
    exige(reusus.stage56FinalStructureCacheSizeDiagnostic() == 1,
          "cache initii non unum annum continet");

    const Integer primus = annus.openGateDay + 1;
    const Integer medius = primus +
        (annus.closeGateDay - primus) / 2;
    const Integer ultimus = annus.closeGateDay;
    const std::array<Integer, 3> intra{{primus, medius, ultimus}};
    for (const Integer& t : intra) {
        const Stage54IntegrationReport calidus =
            reusus.executeFinalIntegrationStage56(c, t);
        const Stage54IntegrationReport frigidus =
            BaseMonsterManager{}.executeFinalIntegrationStage56(c, t);
        exigeViridem(calidus);
        exigeViridem(frigidus);
        exige(calidus.guardedCacheHit && !calidus.guardedCacheRejected,
              "mutatio targetDay intra annum cache validum non adhibuit");
        exige(!frigidus.guardedCacheHit,
              "instantia nova cache frigidum non habet");
        exige(calidus.targetYear.number == annus.number &&
              frigidus.targetYear.number == annus.number,
              "mutatio intra annum numerum anni corrupit");
        exige(eademDies(calidus.result, frigidus.result),
              "cache calidus in diverso targetDay quinque campos corrupit");
        exige(reusus.stage56FinalStructureCacheSizeDiagnostic() == 1,
              "mutatio targetDay intra annum numerum entry cache auxit");
    }

    // Intervalla sunt (openGate,closeGate]: openGate est ultimus dies
    // anni praecedentis, closeGate+1 primus dies anni sequentis.
    const std::array<Integer, 2> extra{{
        annus.openGateDay, annus.closeGateDay + 1
    }};
    const std::array<Integer, 2> anni{{
        annus.number - 1, annus.number + 1
    }};
    for (std::size_t i = 0; i < extra.size(); ++i) {
        const Stage54IntegrationReport motus =
            reusus.executeFinalIntegrationStage56(c, extra[i]);
        const Stage54IntegrationReport novus =
            BaseMonsterManager{}.executeFinalIntegrationStage56(c, extra[i]);
        exigeViridem(motus);
        exigeViridem(novus);
        exige(!motus.guardedCacheHit && !motus.guardedCacheRejected,
              "annus vicinus falso cache hit vel fingerprint rejectum tulit");
        exige(motus.targetYear.number == anni[i] &&
              novus.targetYear.number == anni[i],
              "finis anni contigui falsum numerum anni dedit");
        exige(eademDies(motus.result, novus.result),
              "annus vicinus cache reuso contra instantiam novam discrepavit");
        exige(reusus.stage56FinalStructureCacheSizeDiagnostic() == i + 2,
              "cache annorum vicinorum non singulos entries constituit");
    }

    const Stage54IntegrationReport regressus =
        reusus.executeFinalIntegrationStage56(c, c);
    exigeViridem(regressus);
    exige(regressus.guardedCacheHit && !regressus.guardedCacheRejected,
          "reditus ad annum initialem cache calidum non invenit");
    exige(eademDies(regressus.result, initium.result),
          "transitus annorum exitum diei initialis corrupit");
    exige(reusus.stage56FinalStructureCacheSizeDiagnostic() == 3,
          "reditus ad annum initialem cache vicinorum delevit");
}

} // namespace

int main() {
    try {
        pastafari::setAccelerationScarsEnabled(false);
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
        exigeMetamorphosinDieiQuaesiti();
        exigeMetamorphosinDieiCalculationis();
        exigeTresCustodesCacheSeparatim();
        exigeTexturamEtTerminosExStructuraIndependenter();

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
