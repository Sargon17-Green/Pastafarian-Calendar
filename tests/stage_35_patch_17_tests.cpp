#include "pastafari/monster.hpp"

#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

using pastafari::BaseMonsterManager;
using pastafari::Integer;
using pastafari::LegacyYearCandidate;
using pastafari::LegacyYearCandidateList;
using pastafari::LegacyYearCandidatePair;
using pastafari::legacyStableLengthOnlyYearCandidates;
using pastafari::legacyYear5000TiePreparation;
using pastafari::sortEqualLengthRunsByOpeningGate;

static void require(bool condicio, const std::string& nuntius) {
    if (!condicio) {
        throw std::runtime_error(nuntius);
    }
}

static std::string indices(const LegacyYearCandidateList& candidates) {
    std::string out;
    for (std::size_t i = 0; i < candidates.size(); ++i) {
        if (i != 0) out += ",";
        out += std::to_string(candidates[i].openIndex);
    }
    return out;
}

static bool idem(const LegacyYearCandidate& a, const LegacyYearCandidate& b) {
    return a.openIndex == b.openIndex &&
           a.closeIndex == b.closeIndex &&
           a.length == b.length;
}

int main() {
    try {
        const Integer basis = pastafari::FOUNDATION_DAY_OLD;
        std::vector<Integer> gates;
        for (int i = 0; i <= 10; ++i) {
            gates.push_back(basis + Integer{50 * i});
        }
        const Integer calculationDay = basis + 225;
        const std::vector<LegacyYearCandidatePair> pairs{
            {4, 10},
            {0, 6},
            {2, 8}
        };

        const auto legacyDirect = legacyYear5000TiePreparation(
            gates,
            pairs,
            calculationDay);
        require(indices(legacyDirect.preSort) == "4,0,2",
                "familia legacy ante sortem non servata est");
        require(indices(legacyDirect.sorted) == "4,0,2",
                "stable sort legacy per longitudinem solam mutatus est");

        const LegacyYearCandidateList patchedDirect = sortEqualLengthRunsByOpeningGate(
            gates,
            legacyDirect.sorted);
        require(indices(patchedDirect) == "0,2,4",
                "PATCH 17 run aequalis longitudinis per opening gate non ordinavit");
        for (std::size_t i = 0; i < patchedDirect.size(); ++i) {
            require(patchedDirect[i].length == legacyDirect.sorted[i].length,
                    "PATCH 17 limites run longitudinis transgressus est");
        }

        LegacyYearCandidateList nonLengthSorted{
            LegacyYearCandidate{4, 10, Integer{300}},
            LegacyYearCandidate{0, 4, Integer{200}},
            LegacyYearCandidate{2, 8, Integer{300}}
        };
        const auto localOnly = sortEqualLengthRunsByOpeningGate(gates, nonLengthSorted);
        require(indices(localOnly) == "4,0,2",
                "helper PATCH 17 candidatos 300 non contiguos ut global two-key sort regruppavit");
        require(localOnly[0].length == 300 &&
                localOnly[1].length == 200 &&
                localOnly[2].length == 300,
                "helper PATCH 17 structuram run non contiguam mutavit");

        const BaseMonsterManager manager;
        const auto diagnostic = manager.executeUnpatchedYear5000TieDiagnostic(
            calculationDay,
            calculationDay,
            gates,
            pairs,
            1,
            10);
        require(indices(diagnostic.sorted) == "4,0,2",
                "via diagnostica DISCOVERY 17 cicatricem length-only non servat");
        require(!diagnostic.patch17Applied,
                "via diagnostica PATCH 17 falso applicatum refert");

        const auto report = manager.executeLegacyYear5000TieDiscovery(
            calculationDay,
            calculationDay,
            gates,
            pairs,
            1,
            10);
        require(report.discovery17Ready,
                "cicatrix DISCOVERY 17 ante PATCH 17 non cucurrit");
        require(report.patch17Applied,
                "PATCH 17 nondum applicatus est");
        require(report.status == "YEAR_5000_EQUAL_LENGTH_RUNS_SORTED_BY_OPENING_GATE",
                "status PATCH 17 inexpectatus est");
        require(report.handler == "Patch17Year5000TieHandler",
                "handler PATCH 17 inexpectatus est");
        require(indices(report.legacySortedBeforePatch) == "4,0,2",
                "ordo legacy ante PATCH 17 non servatus est");
        require(indices(report.sorted) == "0,2,4",
                "ordo semanticus PATCH 17 non est opening gate ascendens");
        require(report.equalLengthRunCount == 1,
                "numerus run aequalis longitudinis PATCH 17 non est unus");
        require(report.selectionCalled && report.selectionFamilySize == 3,
                "selectio PATCH 17 familiam trium non accepit");
        require(report.selectedOrdinal == report.legacySelectedOrdinalBeforePatch,
                "PATCH 17 answer stream vel family size selectionis mutavit");
        require(idem(report.legacySelectedCandidateBeforePatch,
                     diagnostic.selectedCandidate),
                "candidatus legacy ante PATCH 17 diagnosticum non concordat");
        const std::size_t selectedIndex =
            (report.selectedOrdinal - 1).convert_to<std::size_t>();
        require(idem(report.selectedCandidate, report.sorted[selectedIndex]),
                "candidatus PATCH 17 non ex familia reparata electus est");

        std::cout << "ORDO_LEGACY=" << indices(report.legacySortedBeforePatch) << "\n";
        std::cout << "ORDO_PATCH17=" << indices(report.sorted) << "\n";
        std::cout << "RUNS_AEQUALIS_LONGITUDINIS=" << report.equalLengthRunCount << "\n";
        std::cout << "ORDINALIS_LEGACY=" << report.legacySelectedOrdinalBeforePatch << "\n";
        std::cout << "ORDINALIS_PATCH17=" << report.selectedOrdinal << "\n";
        std::cout << "OPENING_LEGACY_ELECTUS="
                  << report.legacySelectedCandidateBeforePatch.openIndex << "\n";
        std::cout << "OPENING_PATCH17_ELECTUS="
                  << report.selectedCandidate.openIndex << "\n";
        std::cout << "PROBE_NON_CONTIGUUS=" << indices(localOnly) << "\n";
        std::cout << "REGRESSIO_PATCH_17_TRANSIIT\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "REGRESSIO_PATCH_17_ERROR: " << error.what() << "\n";
        return 1;
    }
}
