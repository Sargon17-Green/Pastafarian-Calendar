#include "pastafari/monster.hpp"

#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

using pastafari::BaseMonsterManager;
using pastafari::Integer;
using pastafari::LEGACY_YEAR_MAX;
using pastafari::LegacyYearCandidate;
using pastafari::LegacyYearCandidatePair;
using pastafari::legacyYearCandidateAllowed;

static void require(bool condicio, const std::string& nuntius) {
    if (!condicio) {
        throw std::runtime_error(nuntius);
    }
}

static std::vector<Integer> longitudines(const std::vector<LegacyYearCandidate>& candidates) {
    std::vector<Integer> out;
    for (const auto& candidate : candidates) {
        out.push_back(candidate.length);
    }
    return out;
}

static bool eadem(const std::vector<Integer>& a, const std::vector<Integer>& b) {
    if (a.size() != b.size()) {
        return false;
    }
    for (std::size_t i = 0; i < a.size(); ++i) {
        if (a[i] != b[i]) {
            return false;
        }
    }
    return true;
}

static std::string series(const std::vector<Integer>& valores) {
    std::string out;
    for (std::size_t i = 0; i < valores.size(); ++i) {
        if (i != 0) out += ",";
        out += valores[i].convert_to<std::string>();
    }
    return out;
}

int main() {
    try {
        require(LEGACY_YEAR_MAX == 5781, "LEGACY_YEAR_MAX non est 5781");

        const std::vector<Integer> gates{
            Integer{0}, Integer{100}, Integer{200}, Integer{300}, Integer{400}, Integer{500},
            Integer{5778}, Integer{5779}, Integer{5780}, Integer{5781}, Integer{5782}
        };
        const std::vector<LegacyYearCandidatePair> pairs{
            {0, 9}, {0, 7}, {0, 6}, {0, 8}, {0, 10}
        };

        require(legacyYearCandidateAllowed(gates, 0, 6), "5778 a legacy repudiatur");
        require(legacyYearCandidateAllowed(gates, 0, 7), "5779 a legacy repudiatur");
        require(legacyYearCandidateAllowed(gates, 0, 8), "5780 a legacy repudiatur");
        require(legacyYearCandidateAllowed(gates, 0, 9), "5781 a legacy repudiatur");
        require(!legacyYearCandidateAllowed(gates, 0, 10), "5782 a legacy admittitur");
        require(!legacyYearCandidateAllowed(gates, 1, 6), "gapCount infra sex non repudiatur");

        const BaseMonsterManager manager;
        const auto report = manager.executeLegacyYearCandidateDiscovery(
            pastafari::FOUNDATION_DAY_OLD,
            pastafari::FOUNDATION_DAY_OLD,
            gates,
            pairs,
            1,
            10);

        require(report.patch15Prepared, "PATCH 15 ante Discovery 16 non praeparatus est");
        require(report.selectionCalled, "familia legacy selectionem non attigit");
        require(report.selectionFamilySize == 4, "magnitudo selectionis legacy non est quattuor");
        require(report.selectedOrdinal >= 1 && report.selectedOrdinal <= 4,
                "ordinalis selectionis extra familiam est");
        require(report.status == "LEGACY_YEAR_MAX_5781_REACHES_SELECTION",
                "status Discovery 16 inexpectatus est");

        const std::vector<Integer> pre = longitudines(report.preSort);
        const std::vector<Integer> sorted = longitudines(report.sorted);
        require(eadem(pre, {Integer{5781}, Integer{5779}, Integer{5778}, Integer{5780}}),
                "ordo raw ante sortem legacy mutatus est");
        require(eadem(sorted, {Integer{5778}, Integer{5779}, Integer{5780}, Integer{5781}}),
                "stable sort legacy per longitudinem non produxit familiam exspectatam");

        std::vector<Integer> supraNormam;
        for (const Integer& L : sorted) {
            if (L > 5778) {
                supraNormam.push_back(L);
            }
        }

        std::cout << "LEGACY_YEAR_MAX=" << LEGACY_YEAR_MAX << "\n";
        std::cout << "FAMILIA_ANTE_SORTEM=" << series(pre) << "\n";
        std::cout << "FAMILIA_SORTATA=" << series(sorted) << "\n";
        std::cout << "FAMILIA_SELECTIONIS=" << report.selectionFamilySize << "\n";
        std::cout << "ORDINALIS_ELECTUS=" << report.selectedOrdinal << "\n";
        std::cout << "LONGITUDO_ELECTA=" << report.selectedCandidate.length << "\n";
        std::cout << "SUPRA_CULMEN_NORMATIVUM=" << series(supraNormam) << "\n";

        if (supraNormam.empty()) {
            std::cout << "REGRESSIO_DISCOVERY_16_TRANSIIT\n";
            return 0;
        }
        if (eadem(supraNormam, {Integer{5779}, Integer{5780}, Integer{5781}})) {
            std::cerr
                << "REGRESSIO_DISCOVERY_16_DEFECIT: 3 longitudines 5779..5781 "
                << "per LEGACY_YEAR_MAX=5781 ad sortem et selectionem pervenerunt\n";
            return 1;
        }
        std::cerr << "REGRESSIO_DISCOVERY_16_INEXPECTATA: " << series(supraNormam) << "\n";
        return 2;
    } catch (const std::exception& error) {
        std::cerr << "REGRESSIO_DISCOVERY_16_ERROR: " << error.what() << "\n";
        return 3;
    }
}
