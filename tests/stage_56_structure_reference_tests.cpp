#include "pastafari/monster.hpp"
#include "pastafari/source_language_catalog.hpp"
#include "reference/normative_reference.hpp"
#include "stage_55_fast_reference.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <iostream>
#include <map>
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
    const std::array<std::size_t, 3> cutletIds{
        0, s.cutlets.size() / 2, s.cutlets.size() - 1
    };
    for (const std::size_t k : cutletIds) {
        const auto& cutlet = s.cutlets[k];
        targets.insert(cutlet.firstDay);
        targets.insert(cutlet.lastDay);
    }

    const std::size_t absent = s.monthWeaving.size();
    const std::size_t count = static_cast<std::size_t>(s.monthCount);
    std::vector<std::size_t> firstMonth(count, absent);
    std::vector<std::size_t> lastMonth(count, absent);
    for (std::size_t pos = 0; pos < s.monthWeaving.size(); ++pos) {
        const int id = s.monthWeaving[pos];
        exige(id > 0 && static_cast<std::size_t>(id) <= count,
              "index mensis reference extra fines");
        const std::size_t i = static_cast<std::size_t>(id - 1);
        if (firstMonth[i] == absent) firstMonth[i] = pos;
        lastMonth[i] = pos;
    }
    const std::array<std::size_t, 3> monthIds{0, count / 2, count - 1};
    for (const std::size_t k : monthIds) {
        exige(firstMonth[k] != absent && lastMonth[k] != absent,
              "mensis reference non apparuit");
        targets.insert(first + Big{firstMonth[k]});
        targets.insert(first + Big{lastMonth[k]});
    }
    for (const Big& t : targets) {
        exige(first <= t && t <= last, "sample intra annum non est");
    }
    exige(targets.size() >= 9, "termini distincti insufficientes sunt");
    return targets;
}

void exigeProiectionesFinium(
    BaseMonsterManager& manager,
    const std::map<std::pair<Big, Big>, Exspectatio>& references) {
    int casus = 0;
    int anni = 0;
    for (const auto& [key, expected] : references) {
        const Big& c = key.first;
        const std::set<Big> targets = eligeTerminos(expected);
        bool cacheCalidus = false;
        for (const Big& t : targets) {
            const auto actual = manager.executeFinalIntegrationStage56(c, t);
            const std::string label = "terminus " + std::to_string(anni + 1)
                + "/" + std::to_string(casus + 1);
            exige(actual.ready && actual.status == "GREEN",
                  label + ": integratio non viridis");
            comparaStructuram(actual, expected, label);
            comparaDiem(actual.result, diesExReference(expected, t), label);
            if (actual.guardedCacheHit && !actual.guardedCacheRejected)
                cacheCalidus = true;
            ++casus;
        }
        exige(cacheCalidus, "cache annum testatum nunquam calefecit");
        ++anni;
        std::cout << "GRADUS56_TERMINI_ANNUS_PASS=" << anni
                  << " CASES=" << targets.size()
                  << " YEAR=" << expected.annus.number
                  << '\n' << std::flush;
    }
    exige(anni == 5 && casus >= 45,
          "coverage quinque annorum et saltem XLV terminorum defecit");
    std::cout << "GRADUS56_TERMINI_REFERENCE=PASS"
              << " ANNI=" << anni << " CASUS=" << casus << '\n';
}

} // namespace

int main() {
    try {
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
        std::cout << "GRADUS56_STRUCTURA_REFERENCE=7/7_PASS"
                  << " STRUCTURAE=5/5_PASS\n";
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "GRADUS56_STRUCTURA_REFERENCE_DEFECIT: "
                  << e.what() << '\n';
        return 1;
    }
}
