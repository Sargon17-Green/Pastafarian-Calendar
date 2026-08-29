#include "pastafari/monster.hpp"
#include "tests/reference/normative_reference.hpp"

#include <array>
#include <iostream>

namespace {

struct Casus {
    int queriedBowlId;
    int seal;
};

} // namespace

int main() {
    using pastafari::BaseMonsterManager;
    using pastafari::FOUNDATION_DAY_OLD;
    using pastafari::Integer;
    using pastafari::M_OLD;
    using pastafari::biasedLegacyPick;
    namespace ref = pastafari::reference;

    const auto sauceNormativa = ref::sauce(ref::FOUNDATION_DAY, ref::FOUNDATION_DAY);
    const std::array<Casus, 3> casus{{
        Casus{1, 1},
        Casus{2, 21},
        Casus{3, 31}
    }};

    BaseMonsterManager manager;
    int discrepantiae = 0;
    int defectusInopinati = 0;

    for (const auto& casusUnus : casus) {
        const auto streamNormativus = ref::askBowl(
            sauceNormativa,
            casusUnus.queriedBowlId,
            casusUnus.seal);
        const Integer N = streamNormativus.first - 1;

        if (streamNormativus.first <= 1 || N <= M_OLD / 2 ||
            streamNormativus.directionStep != -1) {
            std::cerr << "DEFECTUS_WITNESS_DISCOVERY_13 queried="
                      << casusUnus.queriedBowlId
                      << " seal=" << casusUnus.seal
                      << " first=" << streamNormativus.first
                      << " N=" << N
                      << " directio=" << streamNormativus.directionStep << '\n';
            ++defectusInopinati;
            continue;
        }

        const Integer normativus = ref::chooseRankShort(streamNormativus, N);
        const Integer cicatrixDirecta = biasedLegacyPick(streamNormativus.first, N);
        const auto actualis = manager.executeLegacyBiasedSelection(
            FOUNDATION_DAY_OLD,
            FOUNDATION_DAY_OLD,
            casusUnus.queriedBowlId,
            casusUnus.seal,
            N);

        const int nextNormativus = ref::nextBowlInDrop46Order(
            sauceNormativa,
            casusUnus.queriedBowlId);

        if (!actualis.patch11Prepared || !actualis.patch12Prepared ||
            actualis.orderAt46Latch != sauceNormativa.orderAtDrop46 ||
            actualis.finalBowls != sauceNormativa.bowls ||
            actualis.nextBowlId != nextNormativus ||
            actualis.answerRing.first != streamNormativus.first ||
            actualis.answerRing.directionStep != streamNormativus.directionStep ||
            actualis.firstAnswer != streamNormativus.first ||
            actualis.familySize != N) {
            std::cerr << "DEFECTUS_VIAE_DISCOVERY_13 queried="
                      << casusUnus.queriedBowlId
                      << " seal=" << casusUnus.seal
                      << " first_actualis=" << actualis.answerRing.first
                      << " first_normativus=" << streamNormativus.first
                      << " directio_actualis=" << actualis.answerRing.directionStep
                      << " directio_normativa=" << streamNormativus.directionStep
                      << " next_actualis=" << actualis.nextBowlId
                      << " next_normativus=" << nextNormativus << '\n';
            ++defectusInopinati;
            continue;
        }

        if (cicatrixDirecta != 1 || normativus != N) {
            std::cerr << "DEFECTUS_FORMae_WITNESS_DISCOVERY_13 queried="
                      << casusUnus.queriedBowlId
                      << " seal=" << casusUnus.seal
                      << " cicatrix=" << cicatrixDirecta
                      << " normativus=" << normativus
                      << " N=" << N << '\n';
            ++defectusInopinati;
            continue;
        }

        if (actualis.outputRank != normativus) {
            ++discrepantiae;
            std::cout << "DISCREPANTIA_SELECTIONIS queried="
                      << casusUnus.queriedBowlId
                      << " seal=" << casusUnus.seal
                      << " first=" << streamNormativus.first
                      << " directio=" << streamNormativus.directionStep
                      << " N=" << N
                      << " legacy=" << actualis.outputRank
                      << " normativus=" << normativus << '\n';
        }
    }

    if (defectusInopinati != 0) {
        std::cerr << "REGRESSIO_DISCOVERY_13_INOPINATE_DEFECIT: "
                  << defectusInopinati << " defectus inventi sunt\n";
        return 2;
    }

    if (discrepantiae == 0) {
        std::cout << "REGRESSIO_DISCOVERY_13_TRANSIIT\n";
        return 0;
    }

    if (discrepantiae == 3) {
        std::cerr << "REGRESSIO_DISCOVERY_13_DEFECIT: 3 discrepantiae normativae "
                     "ex modulo directo ante rejectionem inventae sunt\n";
        return 1;
    }

    std::cerr << "REGRESSIO_DISCOVERY_13_INOPINATE_DEFECIT: discrepantiae="
              << discrepantiae << " expectatae=3\n";
    return 2;
}
