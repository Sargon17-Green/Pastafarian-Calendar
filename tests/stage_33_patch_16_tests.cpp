#include "pastafari/monster.hpp"

#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

using pastafari::BaseMonsterManager;
using pastafari::Integer;
using pastafari::LEGACY_YEAR_MAX;
using pastafari::REAL_YEAR_MAX_PATCH;
using pastafari::LegacyYearCandidate;
using pastafari::LegacyYearCandidatePair;
using pastafari::legacyStableLengthOnlyYearCandidates;
using pastafari::legacyYearCandidatesBeforeSort;
using pastafari::yearCandidateAfterFootnotePatch;

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
    if (a.size() != b.size()) return false;
    for (std::size_t i = 0; i < a.size(); ++i) {
        if (a[i] != b[i]) return false;
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
        require(LEGACY_YEAR_MAX == 5781, "cicatrix LEGACY_YEAR_MAX mutata est");
        require(REAL_YEAR_MAX_PATCH == 5778, "REAL_YEAR_MAX_PATCH non est 5778");

        const std::vector<Integer> gates{
            Integer{0}, Integer{100}, Integer{200}, Integer{300}, Integer{400}, Integer{500},
            Integer{5778}, Integer{5779}, Integer{5780}, Integer{5781}, Integer{5782}
        };
        const std::vector<LegacyYearCandidatePair> pairs{
            {0, 9}, {0, 7}, {0, 6}, {0, 8}, {0, 10}
        };

        const auto d5778 = yearCandidateAfterFootnotePatch(gates, 0, 6);
        const auto d5779 = yearCandidateAfterFootnotePatch(gates, 0, 7);
        const auto d5780 = yearCandidateAfterFootnotePatch(gates, 0, 8);
        const auto d5781 = yearCandidateAfterFootnotePatch(gates, 0, 9);
        const auto d5782 = yearCandidateAfterFootnotePatch(gates, 0, 10);
        require(d5778.legacyAccepted && d5778.semanticAccepted,
                "5778 post call legacy a PATCH 16 repudiatur");
        require(d5779.legacyAccepted && !d5779.semanticAccepted,
                "5779 non post acceptance legacy ante sortem rejectus est");
        require(d5780.legacyAccepted && !d5780.semanticAccepted,
                "5780 non post acceptance legacy ante sortem rejectus est");
        require(d5781.legacyAccepted && !d5781.semanticAccepted,
                "5781 non post acceptance legacy ante sortem rejectus est");
        require(!d5782.legacyAccepted && !d5782.semanticAccepted,
                "5782 a cicatrice legacy contra regulam admittitur");

        const auto legacyPre = legacyYearCandidatesBeforeSort(gates, pairs);
        const auto legacySorted = legacyStableLengthOnlyYearCandidates(legacyPre);
        require(eadem(longitudines(legacyPre),
                      {Integer{5781}, Integer{5779}, Integer{5778}, Integer{5780}}),
                "familia raw legacy ante PATCH 16 mutata est");
        require(eadem(longitudines(legacySorted),
                      {Integer{5778}, Integer{5779}, Integer{5780}, Integer{5781}}),
                "stable sort legacy cicatricis mutatus est");

        const BaseMonsterManager manager;
        const auto diagnostic = manager.executeUnpatchedYearCandidateDiscoveryDiagnostic(
            pastafari::FOUNDATION_DAY_OLD,
            pastafari::FOUNDATION_DAY_OLD,
            gates,
            pairs,
            1,
            10);
        require(diagnostic.selectionCalled && diagnostic.selectionFamilySize == 4,
                "via diagnostica Discovery 16 familiam legacy non servat");
        require(eadem(longitudines(diagnostic.sorted),
                      {Integer{5778}, Integer{5779}, Integer{5780}, Integer{5781}}),
                "via diagnostica Discovery 16 cicatricem sortatam amisit");

        const auto report = manager.executeLegacyYearCandidateDiscovery(
            pastafari::FOUNDATION_DAY_OLD,
            pastafari::FOUNDATION_DAY_OLD,
            gates,
            pairs,
            1,
            10);
        require(report.patch16Applied, "PATCH 16 non applicatus est");
        require(report.status == "REAL_YEAR_MAX_5778_FILTERED_BEFORE_SORT_SELECTION",
                "status PATCH 16 inexpectatus est");
        require(eadem(longitudines(report.legacyPreSortBeforePatch),
                      {Integer{5781}, Integer{5779}, Integer{5778}, Integer{5780}}),
                "familia legacy raw in report PATCH 16 non servata est");
        require(eadem(longitudines(report.rejectedBeforeSort),
                      {Integer{5781}, Integer{5779}, Integer{5780}}),
                "ordo rejectionum ante sortem PATCH 16 falsus est");
        require(eadem(longitudines(report.preSort), {Integer{5778}}),
                "familia semantica ante sortem non est solum 5778");
        require(eadem(longitudines(report.sorted), {Integer{5778}}),
                "familia semantica post sortem non est solum 5778");
        require(report.selectionCalled && report.selectionFamilySize == 1,
                "selectio semantica non solum 5778 accepit");
        require(report.selectedCandidate.length == 5778,
                "selectio semantica candidatum 5778 non elegit");

        const std::vector<Integer> tieGates{
            Integer{0}, Integer{10}, Integer{20}, Integer{30}, Integer{40},
            Integer{50}, Integer{490}, Integer{500}, Integer{510}
        };
        const std::vector<LegacyYearCandidatePair> tiePairs{{2, 8}, {0, 6}};
        const auto tieReport = manager.executeLegacyYearCandidateDiscovery(
            pastafari::FOUNDATION_DAY_OLD,
            pastafari::FOUNDATION_DAY_OLD,
            tieGates,
            tiePairs,
            1,
            10);
        require(tieReport.preSort.size() == 2 && tieReport.sorted.size() == 2,
                "probe aequalis longitudinis familiam duorum non servat");
        require(tieReport.preSort[0].openIndex == 2 && tieReport.preSort[1].openIndex == 0,
                "ordo inputuum probe tie mutatus est ante sortem");
        require(tieReport.sorted[0].openIndex == 2 && tieReport.sorted[1].openIndex == 0,
                "PATCH 17 praemature tie per opening gate ordinavit");
        require(tieReport.sorted[0].length == 490 && tieReport.sorted[1].length == 490,
                "probe tie longitudines aequales non habet");

        std::cout << "LEGACY_YEAR_MAX=" << LEGACY_YEAR_MAX << "\n";
        std::cout << "REAL_YEAR_MAX_PATCH=" << REAL_YEAR_MAX_PATCH << "\n";
        std::cout << "LEGACY_PRE_SORT=" << series(longitudines(report.legacyPreSortBeforePatch)) << "\n";
        std::cout << "REJECTA_ANTE_SORTEM=" << series(longitudines(report.rejectedBeforeSort)) << "\n";
        std::cout << "SEMANTICA_ANTE_SORTEM=" << series(longitudines(report.preSort)) << "\n";
        std::cout << "SEMANTICA_SORTATA=" << series(longitudines(report.sorted)) << "\n";
        std::cout << "FAMILIA_SELECTIONIS=" << report.selectionFamilySize << "\n";
        std::cout << "TIE_OPENING_ORDO="
                  << tieReport.sorted[0].openIndex << "," << tieReport.sorted[1].openIndex << "\n";
        std::cout << "REGRESSIO_PATCH_16_TRANSIIT\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "REGRESSIO_PATCH_16_DEFECIT: " << error.what() << "\n";
        return 1;
    }
}
