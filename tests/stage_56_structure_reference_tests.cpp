#include "pastafari/monster.hpp"
#include "pastafari/source_language_catalog.hpp"
#include "reference/normative_reference.hpp"
#include "stage_55_fast_reference.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <iostream>
#include <iterator>
#include <map>
#include <numeric>
#include <set>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

namespace {
using pastafari::BaseMonsterManager;
using pastafari::Integer;
using pastafari::SpaghettiDateFive;
using pastafari::Stage54IntegrationReport;
using pastafari::reference::Big;
using pastafari::reference::NormativeOracle;
using pastafari::reference::Year;
using pastafari::reference::YearStructure;

void exige(bool condicio, const std::string& nuntius) {
    if (!condicio) throw std::runtime_error(nuntius);
}

struct Exspectatio {
    Year annus{};
    YearStructure structura{};
};

Exspectatio construeIndependenter(
    NormativeOracle& oracle, const Big& c, const Year& annus) {
    // Hoc test-only reference non legit nec revocat productionis
    // buildFinalYearStructure, DPUnrankLegalWeaving aut cache.
    const auto sauce = pastafari::reference::sauce(c, annus.openGateDay + 1);
    YearStructure s{};
    s.cutletCount = oracle.chooseCutletCount(sauce, annus);
    s.cutletPartition = oracle.chooseCutletPartition(
        c, sauce, annus, s.cutletCount);
    s.cutletNameIndices =
        oracle.chooseCutletNameIndices(sauce, s.cutletCount);
    s.cutlets = oracle.materializeCutlets(
        annus, s.cutletPartition, s.cutletNameIndices);
    s.monthCount = oracle.chooseMonthCount(sauce, annus);
    s.monthLengths = oracle.chooseMonthLengths(
        sauce, annus, s.monthCount);
    s.monthNameIndices =
        oracle.chooseMonthNameIndices(sauce, s.monthCount);

    // Reference celer pro longis texturis, adversus naivam reference
    // iam in stage_55_fast_reference.hpp separatim comprobata.
    pastafari::stage55audit::TexturaCelerReference familia(s.monthLengths);
    const Big gradus = pastafari::reference::chooseRank(
        pastafari::reference::askBowl(
            sauce, 4, pastafari::reference::SEAL_MONTH_WEAVING),
        familia.numerusOmnium());
    s.monthWeaving = familia.aperiGradum(gradus);
    return Exspectatio{annus, std::move(s)};
}


void exigeLegesStructurae(const Exspectatio& e) {
    // Haec sunt invariantes canonicae test-only, separatim ab
    // comparatione productionis et reference: errores communes detegunt.
    const auto& y = e.annus;
    const auto& s = e.structura;
    const Big annusDies = y.closeGateDay - y.openGateDay;
    const Big portaIntervalla = y.closeGateIndex - y.openGateIndex;
    exige(annusDies >= 252 && annusDies <= 5778,
          "longitudo anni extra fines canonicos");
    exige(portaIntervalla >= 6 && portaIntervalla <= 137,
          "numerus intervallorum annui absurdus");
    exige(s.cutletCount >= 6 && s.cutletCount <= 17 &&
          static_cast<int>(s.cutlets.size()) == s.cutletCount &&
          static_cast<int>(s.cutletPartition.size()) == s.cutletCount &&
          static_cast<int>(s.cutletNameIndices.size()) == s.cutletCount,
          "numeri segmentorum et vectorum discrepant");
    exige(s.monthCount >= 3 && s.monthCount <= 47 &&
          static_cast<int>(s.monthLengths.size()) == s.monthCount &&
          static_cast<int>(s.monthNameIndices.size()) == s.monthCount,
          "numeri mensium et vectorum discrepant");

    std::set<int> nominaSegmentorum;
    Big porta = y.openGateIndex;
    Big primusDies = y.openGateDay + 1;
    for (int j = 0; j < s.cutletCount; ++j) {
        const std::size_t i = static_cast<std::size_t>(j);
        const int gaps = s.cutletPartition[i];
        const auto& cutlet = s.cutlets[i];
        exige(gaps >= 1, "partitio segmenti habet intervallum non positivum");
        exige(cutlet.openGateIndex == porta &&
              cutlet.closeGateIndex == porta + gaps &&
              cutlet.firstDay == primusDies &&
              cutlet.lastDay >= cutlet.firstDay,
              "segmenta non sunt contigua per portas et dies");
        const int nomen = s.cutletNameIndices[i];
        exige(cutlet.nameIndex == nomen &&
              nomen >= 1 && nomen <= 17 &&
              nominaSegmentorum.insert(nomen).second,
              "index nominis segmenti repetitus vel invalidus");
        porta = cutlet.closeGateIndex;
        primusDies = cutlet.lastDay + 1;
    }
    exige(porta == y.closeGateIndex &&
          primusDies == y.closeGateDay + 1,
          "partitio segmentorum non totum annum claudit");
    exige(Big{std::accumulate(s.cutletPartition.begin(),
                             s.cutletPartition.end(), 0)} == portaIntervalla,
          "summa intervallorum segmentorum non congruit");

    std::set<int> nominaMensium;
    int diesMensium = 0;
    for (int j = 0; j < s.monthCount; ++j) {
        const std::size_t i = static_cast<std::size_t>(j);
        const int longitudo = s.monthLengths[i];
        const int nomen = s.monthNameIndices[i];
        exige(longitudo >= 4 && longitudo <= 123,
              "longitudo mensis extra fines canonicos");
        exige(nomen >= 1 && nomen <= 47 &&
              nominaMensium.insert(nomen).second,
              "nomen mensis repetitum vel invalidum");
        diesMensium += longitudo;
    }
    exige(Big{diesMensium} == annusDies &&
          s.monthWeaving.size() == static_cast<std::size_t>(diesMensium),
          "summa dierum mensium non est longitudo anni");

    std::vector<int> reliqui = s.monthLengths;
    int aperti = 0;
    int clausi = 0;
    for (const int mensis : s.monthWeaving) {
        exige(mensis >= 1 && mensis <= s.monthCount,
              "index mensis extra fines in textura");
        const std::size_t i = static_cast<std::size_t>(mensis - 1);
        exige(reliqui[i] > 0, "mensis frequentior quam longitudo sua");
        if (reliqui[i] == s.monthLengths[i]) {
            exige(mensis == aperti + 1, "ordo primae apparitionis non legalis");
            aperti = mensis;
        }
        --reliqui[i];
        if (reliqui[i] == 0) {
            exige(mensis == clausi + 1, "ordo clausurae non legalis");
            clausi = mensis;
        }
    }
    exige(aperti == s.monthCount && clausi == s.monthCount &&
          std::all_of(reliqui.begin(), reliqui.end(),
                      [](int v) { return v == 0; }),
          "textura mensium non omnes menses exacte complevit");
}

void comparaStructuram(
    const Stage54IntegrationReport& actual,
    const Exspectatio& reference, const std::string& titulus) {
    const auto& y = actual.targetYear;
    const auto& e = reference.annus;
    exige(y.number == e.number &&
          y.openGateIndex == e.openGateIndex &&
          y.closeGateIndex == e.closeGateIndex &&
          y.openGateDay == e.openGateDay &&
          y.closeGateDay == e.closeGateDay,
          titulus + ": annus aut portae ab oraculo discrepant");

    const auto& a = actual.structure;
    const auto& s = reference.structura;
    exige(a.cutletCount == s.cutletCount &&
          a.cutletPartition == s.cutletPartition &&
          a.cutletNameIndices == s.cutletNameIndices,
          titulus + ": partitiones/nomen segmentorum discrepant");
    exige(a.cutlets.size() == s.cutlets.size(),
          titulus + ": numerus segmentorum materialium discrepat");
    for (std::size_t i = 0; i < a.cutlets.size(); ++i) {
        const auto& ac = a.cutlets[i];
        const auto& ec = s.cutlets[i];
        exige(ac.canonicalIndex == ec.nameIndex &&
              ac.openGateIndex == ec.openGateIndex &&
              ac.closeGateIndex == ec.closeGateIndex &&
              ac.firstDay == ec.firstDay &&
              ac.lastDay == ec.lastDay,
              titulus + ": segmentum materializatum discrepat apud " +
                  std::to_string(i));
    }
    exige(a.monthCount == s.monthCount &&
          a.monthLengths == s.monthLengths &&
          a.monthNameIndices == s.monthNameIndices,
          titulus + ": numerus/longitudines/nomina mensium discrepant");
    exige(a.monthWeaving == s.monthWeaving,
          titulus + ": tota textura mensium contra reference discrepat");
}

SpaghettiDateFive diesExReference(
    const Exspectatio& e, const Big& t) {
    const auto& s = e.structura;
    const pastafari::reference::Cutlet* segmentum = nullptr;
    for (const auto& cutlet : s.cutlets) {
        if (cutlet.firstDay <= t && t <= cutlet.lastDay) {
            segmentum = &cutlet;
            break;
        }
    }
    exige(segmentum != nullptr, "oraculum segmentum target non invenit");
    const Big locus = t - e.annus.openGateDay - 1;
    exige(locus >= 0 && locus < Big{s.monthWeaving.size()},
          "oraculum target extra texturam habet");
    const std::size_t pos = locus.convert_to<std::size_t>();
    const int monthId = s.monthWeaving.at(pos);
    const int diesMensis = static_cast<int>(std::count(
        s.monthWeaving.begin(),
        s.monthWeaving.begin() + static_cast<std::ptrdiff_t>(pos + 1),
        monthId));
    return SpaghettiDateFive{
        e.annus.number,
        std::string(pastafari::cutletSourceName(
            static_cast<std::size_t>(segmentum->nameIndex))),
        t - segmentum->firstDay + 1,
        std::string(pastafari::monthSourceName(
            static_cast<std::size_t>(
                s.monthNameIndices.at(static_cast<std::size_t>(monthId - 1))))),
        Integer{diesMensis}
    };
}

void comparaDiem(const SpaghettiDateFive& a,
                 const SpaghettiDateFive& b,
                 const std::string& titulus) {
    exige(a.yearNumber == b.yearNumber &&
          a.cutletName == b.cutletName &&
          a.dayInCutlet == b.dayInCutlet &&
          a.monthName == b.monthName &&
          a.dayInMonth == b.dayInMonth,
          titulus + ": quinque campi contra reference discrepant");
}


std::set<Big> eligeTerminos(const Exspectatio& e) {
    const auto& s = e.structura;
    const auto& y = e.annus;
    const Big first = y.openGateDay + 1;
    const Big last = y.closeGateDay;
    exige(first < last, "annus probationis nimis brevis");
    exige(!s.cutlets.empty() && !s.monthWeaving.empty(),
          "structura vacua ad probationem terminorum");

    std::set<Big> targets{first, first + 1, (first + last) / 2,
                          last - 1, last};
    // Quorumlibet segmentorum dies primus et ultimus, non tantum tria.
    for (const auto& cutlet : s.cutlets) {
        targets.insert(cutlet.firstDay);
        targets.insert(cutlet.lastDay);
    }

    const std::size_t absent = s.monthWeaving.size();
    const std::size_t count = static_cast<std::size_t>(s.monthCount);
    std::vector<std::size_t> firstMonth(count, absent);
    std::vector<std::size_t> middleMonth(count, absent);
    std::vector<std::size_t> lastMonth(count, absent);
    std::vector<int> appearances(count, 0);
    for (std::size_t pos = 0; pos < s.monthWeaving.size(); ++pos) {
        const int id = s.monthWeaving[pos];
        exige(id > 0 && static_cast<std::size_t>(id) <= count,
              "index mensis reference extra fines");
        const std::size_t i = static_cast<std::size_t>(id - 1);
        if (firstMonth[i] == absent) firstMonth[i] = pos;
        ++appearances[i];
        if (appearances[i] == (s.monthLengths[i] + 1) / 2)
            middleMonth[i] = pos;
        lastMonth[i] = pos;
    }
    // Omnium mensium prima et ultima apparentia in textura.
    // Etiam menses non contigui ad dies reales recte proiciendi sunt.
    for (std::size_t k = 0; k < count; ++k) {
        exige(firstMonth[k] != absent &&
              middleMonth[k] != absent &&
              lastMonth[k] != absent &&
              appearances[k] == s.monthLengths[k],
              "mensis reference omnes positiones non habet");
        targets.insert(first + Big{firstMonth[k]});
        targets.insert(first + Big{middleMonth[k]});
        targets.insert(first + Big{lastMonth[k]});
    }
    for (const Big& t : targets) {
        exige(first <= t && t <= last, "sample intra annum non est");
    }
    exige(targets.size() >= 3 * count,
          "prima/media/ultima cuiusque mensis non selecta est");
    return targets;
}

void exigeProiectionesFinium(
    BaseMonsterManager& manager,
    const std::map<std::pair<Big, Big>, Exspectatio>& references) {
    int casus = 0;
    int anni = 0;
    int minimumCasuum = 0;
    int frigidiIndependentes = 0;
    for (const auto& [key, expected] : references) {
        minimumCasuum += 3 * expected.structura.monthCount;
        const Big& c = key.first;
        const std::set<Big> targets = eligeTerminos(expected);
        const auto mid = std::next(targets.begin(),
            static_cast<std::ptrdiff_t>(targets.size() / 2));
        const Big diesPrimus = *targets.begin();
        const Big medius = *mid;
        const Big ultimus = *targets.rbegin();
        bool cacheCalidus = false;
        bool primus = true;
        for (const Big& t : targets) {
            const auto actual = manager.executeFinalIntegrationStage56(c, t);
            const std::string label = "terminus " + std::to_string(anni + 1)
                + "/" + std::to_string(casus + 1);
            exige(actual.ready && actual.status == "GREEN",
                  label + ": integratio non viridis");
            comparaStructuram(actual, expected, label);
            comparaDiem(actual.result, diesExReference(expected, t), label);
            // Triades frigidae ex calculo novo, praeter structuram cache.
            if (t == diesPrimus || t == medius || t == ultimus) {
                const auto recens =
                    BaseMonsterManager{}.executeFinalIntegrationStage56(c, t);
                exige(recens.ready && recens.status == "GREEN" &&
                      !recens.guardedCacheHit && !recens.guardedCacheRejected,
                      label + ": manager recens non frigidus");
                comparaStructuram(recens, expected, label + ": recens");
                comparaDiem(recens.result, actual.result,
                            label + ": frigidus adversus calidum");
                ++frigidiIndependentes;
            }
            // Prima vocatio huius anni potest alium fingerprint de cache
            // ab invocationibus prioribus recipere. Ceterae omnes in
            // eodem c/anno debent cache uti, sine recalculatione.
            if (!primus) {
                exige(actual.guardedCacheHit && !actual.guardedCacheRejected,
                      label + ": cache intra idem c/annum non calidus");
            }
            if (actual.guardedCacheHit && !actual.guardedCacheRejected)
                cacheCalidus = true;
            primus = false;
            ++casus;
        }
        exige(cacheCalidus, "cache annum testatum nunquam calefecit");
        ++anni;
        std::cout << "GRADUS56_TERMINI_ANNUS_PASS=" << anni
                  << " CASES=" << targets.size()
                  << " YEAR=" << expected.annus.number
                  << '\n' << std::flush;
    }
    exige(anni == 5 && casus >= minimumCasuum,
          "non omnes termini mensium in quinque annis examinati sunt");
    exige(frigidiIndependentes == 15,
          "probationes XV frigidae independentes defecerunt");
    std::cout << "GRADUS56_FRIGIDI=15/15_PASS\n";
    std::cout << "GRADUS56_TERMINI_REFERENCE=PASS"
              << " ANNI=" << anni << " CASUS=" << casus << '\n';
}


void exigeOrdinemInvocationumNeutrum(
    const std::vector<std::pair<Big, Big>>& casus,
    const std::map<std::pair<Big, Big>, Exspectatio>& references) {
    // Eaedem interrogationes in ordine recto et inverso a duobus
    // manageribus independentibus: cache annuum quaestionum priorum
    // ordinem in valores canonicos inflectere numquam licet.
    exige(casus.size() == 7, "ordo metamorphicus VII casus requirit");
    BaseMonsterManager rectus;
    BaseMonsterManager inversus;
    std::vector<SpaghettiDateFive> testimonia(casus.size());

    const auto verifica = [&](BaseMonsterManager& m,
                             const std::pair<Big, Big>& par,
                             std::size_t index,
                             const std::string& titulus) {
        const Exspectatio* expected = nullptr;
        for (const auto& [key, v] : references) {
            if (key.first == par.first &&
                v.annus.openGateDay < par.second &&
                par.second <= v.annus.closeGateDay) {
                exige(expected == nullptr,
                      titulus + ": multiplex annus pro eodem die");
                expected = &v;
            }
        }
        exige(expected != nullptr, titulus + ": reference non inventa");
        const auto actual = m.executeFinalIntegrationStage56(
            par.first, par.second);
        exige(actual.ready && actual.status == "GREEN",
              titulus + ": manager non viridis");
        comparaStructuram(actual, *expected, titulus);
        comparaDiem(actual.result,
                    diesExReference(*expected, par.second), titulus);
        comparaDiem(actual.result, testimonia.at(index), titulus);
    };

    // Primum recte: testimonia definimus a reference prius independenti.
    for (std::size_t i = 0; i < casus.size(); ++i) {
        const auto& par = casus[i];
        const Exspectatio* expected = nullptr;
        for (const auto& [key, v] : references) {
            if (key.first == par.first &&
                v.annus.openGateDay < par.second &&
                par.second <= v.annus.closeGateDay) {
                exige(expected == nullptr,
                      "recto ordine plures annos eadem die invenit");
                expected = &v;
            }
        }
        exige(expected != nullptr, "recto ordine reference deest");
        testimonia[i] = diesExReference(*expected, par.second);
        verifica(rectus, par, i, "ordo rectus frigidus");
    }
    for (std::size_t i = casus.size(); i-- > 0;) {
        verifica(inversus, casus[i], i, "ordo inversus frigidus");
    }

    // Nunc idem manager, sed ordine contrario calidus/reiectus.
    for (std::size_t i = casus.size(); i-- > 0;) {
        verifica(rectus, casus[i], i, "ordo rectus conversus");
    }
    for (std::size_t i = 0; i < casus.size(); ++i) {
        verifica(inversus, casus[i], i, "ordo inversus conversus");
    }
    exige(rectus.stage56FinalStructureCacheSizeDiagnostic() == 3 &&
          inversus.stage56FinalStructureCacheSizeDiagnostic() == 3,
          "cache non tria numeri annorum continet post permutationem");
    std::cout << "GRADUS56_ORDO_INVOCATIONUM=28/28_PASS"
              << " CONTEXTUS=2 CACHE_ANNI=3\n";
}


void exigeTerminosInversosEtFaciemPublicam(
    const std::map<std::pair<Big, Big>, Exspectatio>& references) {
    // Non tantum ordo invocationum paucorum dierum: omnes termini
    // ex quinque annis sunt in ordine inverso, etiam inter annos/c.
    // Comparatio fit cum reference test-only et API publico.
    BaseMonsterManager inversus;
    int numerus = 0;
    int anni = 0;
    int publica = 0;
    int minimum = 0;
    for (auto it = references.rbegin(); it != references.rend(); ++it) {
        const Big& c = it->first.first;
        const Exspectatio& expected = it->second;
        const std::set<Big> dates = eligeTerminos(expected);
        minimum += 3 * expected.structura.monthCount;
        const Big first = *dates.begin();
        const Big middle = *std::next(dates.begin(),
            static_cast<std::ptrdiff_t>(dates.size() / 2));
        const Big last = *dates.rbegin();
        bool prima = true;
        for (auto t = dates.rbegin(); t != dates.rend(); ++t) {
            const auto r = inversus.executeFinalIntegrationStage56(c, *t);
            const std::string label = "inversus " + std::to_string(anni + 1)
                + "/" + std::to_string(numerus + 1);
            exige(r.ready && r.status == "GREEN",
                  label + ": non viridis");
            comparaStructuram(r, expected, label);
            const auto diei = diesExReference(expected, *t);
            comparaDiem(r.result, diei, label);
            if (!prima) {
                exige(r.guardedCacheHit && !r.guardedCacheRejected,
                      label + ": cache inversus non calidus");
            }
            if (*t == first || *t == middle || *t == last) {
                const auto publicus = pastafari::calendarDateSpaghetti(c, *t);
                comparaDiem(publicus, diei, label + ": facies publica");
                ++publica;
            }
            prima = false;
            ++numerus;
        }
        ++anni;
        std::cout << "GRADUS56_TERMINI_INVERSI_ANNUS_PASS=" << anni
                  << " CASES=" << dates.size()
                  << '\n' << std::flush;
    }
    exige(anni == 5 && numerus >= minimum && publica == 15,
          "termini inversi aut API publica insufficientia");
    std::cout << "GRADUS56_TERMINI_INVERSI=PASS ANNI=" << anni
              << " CASUS=" << numerus << " FACADE=" << publica
              << "/15_PASS\n";
}


void exigeAnnumIntegrumPerSingulosDies() {
    // Testis independentis dies singulos anni 5000 requirit: nullum
    // specimen rarum pro die intra mensem hic satis est.
    const Big c = pastafari::FOUNDATION_DAY_OLD;
    NormativeOracle oraculum(false);
    const Year y = oraculum.year5000(c);
    const Exspectatio expected = construeIndependenter(oraculum, c, y);
    exigeLegesStructurae(expected);
    const Big first = y.openGateDay + 1;
    const Big length = y.closeGateDay - y.openGateDay;
    exige(y.number == 5000 && length == 4244,
          "testimonium anni 5000 mutatum est");
    BaseMonsterManager manager;
    std::size_t numerus = 0;
    const std::size_t n = length.convert_to<std::size_t>();
    for (std::size_t i = 0; i < n; ++i) {
        const Big t = first + Big{i};
        const auto actual = manager.executeFinalIntegrationStage56(c, t);
        const std::string label = "annus 5000 dies "
            + std::to_string(i + 1);
        exige(actual.ready && actual.status == "GREEN",
              label + ": integratio non viridis");
        comparaStructuram(actual, expected, label);
        comparaDiem(actual.result, diesExReference(expected, t), label);
        if (i == 0) {
            exige(!actual.guardedCacheHit && !actual.guardedCacheRejected,
                  "annus integer: initium non frigidum est");
        } else {
            exige(actual.guardedCacheHit && !actual.guardedCacheRejected,
                  label + ": cache non calidus intra eundem annum");
        }
        ++numerus;
        if (numerus % 512 == 0 || numerus == n) {
            std::cout << "GRADUS56_ANNUS_INTEGER_PROGRESS="
                      << numerus << "/" << n << '\n' << std::flush;
        }
    }
    exige(numerus == n, "annus integer non omnes dies consumpsit");
    std::cout << "GRADUS56_ANNUS_INTEGER=" << numerus
              << "/" << n << "_PASS YEAR=" << y.number << '\n';
}

} // namespace

int main(int argc, char** argv) {
    try {
        if (argc == 2 && std::string(argv[1]) == "--annus-integer") {
            exigeAnnumIntegrumPerSingulosDies();
            return 0;
        }
        exige(argc == 1, "argumenta testis ignota");
        const Big fundamentum = pastafari::FOUNDATION_DAY_OLD;
        NormativeOracle oracle(false); // saved-sum, numquam raw-sum
        const Year y5000 = oracle.year5000(fundamentum);
        const Year prior = oracle.previousYear(fundamentum, y5000);
        const Year posterior = oracle.nextYear(fundamentum, y5000);
        exige(y5000.number == 5000 &&
              prior.number == 4999 && posterior.number == 5001,
              "tres anni circa fundamentum extra ordinem sunt");
        const std::vector<std::pair<Big, Big>> casus{
            {fundamentum, fundamentum},
            {fundamentum, y5000.openGateDay + 1},
            {fundamentum, y5000.closeGateDay},
            {fundamentum, prior.closeGateDay},
            {fundamentum, posterior.openGateDay + 1},
            {fundamentum + 1, fundamentum},
            {Big{-15048173}, Big{-15048173}}
        };
        BaseMonsterManager manager;
        std::map<std::pair<Big, Big>, Exspectatio> referencePerAnnum;
        int numerus = 0;
        for (const auto& [c, t] : casus) {
            const std::string titulus = "casus " + std::to_string(numerus + 1);
            const Year y = oracle.findTargetYear(c, t);
            const auto clavis = std::make_pair(c, y.number);
            auto it = referencePerAnnum.find(clavis);
            if (it == referencePerAnnum.end()) {
                auto expected = construeIndependenter(oracle, c, y);
                exigeLegesStructurae(expected);
                it = referencePerAnnum.emplace(clavis, std::move(expected)).first;
            }
            const Stage54IntegrationReport actual =
                manager.executeFinalIntegrationStage56(c, t);
            exige(actual.ready && actual.status == "GREEN",
                  titulus + ": manager non viridis");
            comparaStructuram(actual, it->second, titulus);
            comparaDiem(actual.result, diesExReference(it->second, t), titulus);
            ++numerus;
            std::cout << "GRADUS56_STRUCTURA_DIFF_CASUS_PASS=" << numerus
                      << " YEAR=" << actual.targetYear.number
                      << " CUTLETS=" << actual.structure.cutletCount
                      << " MONTHS=" << actual.structure.monthCount
                      << " DAYS=" << actual.structure.monthWeaving.size()
                      << '\n' << std::flush;
        }
        exige(numerus == 7 && referencePerAnnum.size() == 5,
              "coverage septem casuum et quinque structuram defecit");
        exigeProiectionesFinium(manager, referencePerAnnum);
        exigeOrdinemInvocationumNeutrum(casus, referencePerAnnum);
        exigeTerminosInversosEtFaciemPublicam(referencePerAnnum);
        std::cout << "GRADUS56_STRUCTURA_REFERENCE=7/7_PASS"
                  << " STRUCTURAE=5/5_PASS\n";
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "GRADUS56_STRUCTURA_REFERENCE_DEFECIT: "
                  << e.what() << '\n';
        return 1;
    }
}
