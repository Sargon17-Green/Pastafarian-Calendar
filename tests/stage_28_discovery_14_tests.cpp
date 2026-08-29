#include "pastafari/monster.hpp"
#include "tests/reference/normative_reference.hpp"

#include <array>
#include <iostream>

int main() {
    using pastafari::BaseMonsterManager;
    using pastafari::FOUNDATION_DAY_OLD;
    using pastafari::Integer;
    using pastafari::M_OLD;
    namespace ref = pastafari::reference;

    const auto sauceNormativa = ref::sauce(ref::FOUNDATION_DAY, ref::FOUNDATION_DAY);
    const auto streamNormativus = ref::askBowl(sauceNormativa, 1, 1);
    const std::array<Integer, 3> familiae{{
        M_OLD + 1,
        M_OLD * M_OLD,
        M_OLD * M_OLD * M_OLD
    }};

    BaseMonsterManager manager;
    int discrepantiae = 0;
    int defectusInopinati = 0;

    for (const auto& N : familiae) {
        const Integer normativus = ref::chooseRankWide(streamNormativus, N);
        const auto actualis = manager.executeLegacyWideSelectionAssumption(
            FOUNDATION_DAY_OLD,
            FOUNDATION_DAY_OLD,
            1,
            1,
            N);

        if (!actualis.patch11Prepared || !actualis.patch12Prepared ||
            actualis.answerRing.first != streamNormativus.first ||
            actualis.answerRing.directionStep != streamNormativus.directionStep) {
            std::cerr << "DEFECTUS_ANNULI_DISCOVERY_14 N=" << N << '\n';
            ++defectusInopinati;
        }
        if (!actualis.legacyShortFailure || actualis.legacyFailure.empty() ||
            actualis.outputAvailable) {
            std::cerr << "DEFECTUS_ASSUMPTIONIS_LEGACY_DISCOVERY_14 N=" << N << '\n';
            ++defectusInopinati;
        }

        if (!actualis.outputAvailable || actualis.outputRank != normativus) {
            ++discrepantiae;
            std::cout << "DISCREPANTIA_SELECTIONIS_LATAE N=" << N
                      << " normativus=" << normativus
                      << " actualis=";
            if (actualis.outputAvailable) {
                std::cout << actualis.outputRank;
            } else {
                std::cout << "ABSENS";
            }
            std::cout << " causa_legacy=" << actualis.legacyFailure << '\n';
        }
    }

    if (defectusInopinati != 0) {
        std::cerr << "REGRESSIO_DISCOVERY_14_INOPINATE_DEFECIT: "
                  << defectusInopinati << " defectus infrastructurae inventi sunt\n";
        return 2;
    }
    if (discrepantiae == 0) {
        std::cout << "REGRESSIO_DISCOVERY_14_TRANSIIT\n";
        return 0;
    }
    if (discrepantiae != 3) {
        std::cerr << "REGRESSIO_DISCOVERY_14_INOPINATE_DEFECIT: "
                  << discrepantiae << " discrepantiae latae inventae sunt\n";
        return 2;
    }

    std::cerr << "REGRESSIO_DISCOVERY_14_DEFECIT: 3 familiae supra M a via short-only legacy repudiatae sunt\n";
    return 1;
}
