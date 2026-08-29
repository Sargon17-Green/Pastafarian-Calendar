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
    using pastafari::BaseValidationError;
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
    int defectus = 0;
    int cicatricesDivergentes = 0;

    for (const auto& casusUnus : casus) {
        const auto stream = ref::askBowl(
            sauceNormativa,
            casusUnus.queriedBowlId,
            casusUnus.seal);
        const Integer N = stream.first - 1;
        const Integer limit = (M_OLD / N) * N;
        const Integer normativus = ref::chooseRankShort(stream, N);

        const auto actualis = manager.executeLegacyBiasedSelection(
            FOUNDATION_DAY_OLD,
            FOUNDATION_DAY_OLD,
            casusUnus.queriedBowlId,
            casusUnus.seal,
            N);
        const auto diagnosticus = manager.executeUnpatchedBiasedSelectionDiagnostic(
            FOUNDATION_DAY_OLD,
            FOUNDATION_DAY_OLD,
            casusUnus.queriedBowlId,
            casusUnus.seal,
            N);

        if (actualis.legacyOutputBeforePatch != diagnosticus.outputRank) {
            std::cerr << "DEFECTUS_CICATRICIS_PATCH_13 queried="
                      << casusUnus.queriedBowlId << '\n';
            ++defectus;
        }
        if (actualis.legacyOutputBeforePatch !=
            biasedLegacyPick(stream.first, N)) {
            std::cerr << "DEFECTUS_MODULI_DIRECTI_PATCH_13 queried="
                      << casusUnus.queriedBowlId << '\n';
            ++defectus;
        }
        if (actualis.legacyOutputBeforePatch != normativus) {
            ++cicatricesDivergentes;
        }
        if (!actualis.patch13Applied ||
            actualis.acceptanceLimit != limit ||
            actualis.acceptedOffset != 1 ||
            actualis.acceptedAnswer != N ||
            actualis.outputRank != normativus ||
            actualis.outputRank != N) {
            std::cerr << "DEFECTUS_REJECTIONIS_PATCH_13 queried="
                      << casusUnus.queriedBowlId
                      << " limit=" << actualis.acceptanceLimit
                      << " offset=" << actualis.acceptedOffset
                      << " x=" << actualis.acceptedAnswer
                      << " legacy=" << actualis.legacyOutputBeforePatch
                      << " output=" << actualis.outputRank
                      << " normativus=" << normativus << '\n';
            ++defectus;
        }
        if (diagnosticus.patch13Applied ||
            diagnosticus.outputRank != biasedLegacyPick(stream.first, N)) {
            std::cerr << "DEFECTUS_DIAGNOSTICI_PATCH_13 queried="
                      << casusUnus.queriedBowlId << '\n';
            ++defectus;
        }
    }

    {
        const auto stream = ref::askBowl(sauceNormativa, 1, 1);
        const Integer N = M_OLD;
        const auto actualis = manager.executeLegacyBiasedSelection(
            FOUNDATION_DAY_OLD,
            FOUNDATION_DAY_OLD,
            1,
            1,
            N);
        if (!actualis.patch13Applied ||
            actualis.acceptanceLimit != M_OLD ||
            actualis.acceptedOffset != 0 ||
            actualis.acceptedAnswer != stream.first ||
            actualis.outputRank != biasedLegacyPick(stream.first, N)) {
            std::cerr << "DEFECTUS_LIMITE_M_PATCH_13\n";
            ++defectus;
        }
    }

    bool zeroReiectum = false;
    try {
        (void)manager.executeLegacyBiasedSelection(
            FOUNDATION_DAY_OLD,
            FOUNDATION_DAY_OLD,
            1,
            1,
            Integer{0});
    } catch (const BaseValidationError&) {
        zeroReiectum = true;
    }
    if (!zeroReiectum) {
        std::cerr << "DEFECTUS_N_ZERO_PATCH_13\n";
        ++defectus;
    }

    bool supraMReiectum = false;
    try {
        (void)manager.executeLegacyBiasedSelection(
            FOUNDATION_DAY_OLD,
            FOUNDATION_DAY_OLD,
            1,
            1,
            M_OLD + 1);
    } catch (const BaseValidationError&) {
        supraMReiectum = true;
    }
    if (!supraMReiectum) {
        std::cerr << "DEFECTUS_N_SUPRA_M_PATCH_13\n";
        ++defectus;
    }

    if (cicatricesDivergentes != 3) {
        std::cerr << "DEFECTUS_NUMERI_CICATRICUM_PATCH_13 actualis="
                  << cicatricesDivergentes << " expectatus=3\n";
        ++defectus;
    }

    if (defectus != 0) {
        std::cerr << "REGRESSIO_PATCH_13_DEFECIT: " << defectus
                  << " defectus inventi sunt\n";
        return 1;
    }

    std::cout << "REGRESSIO_PATCH_13_TRANSIIT\n";
    std::cout << "CASUS_REJECTIONIS_PROBATI=3\n";
    std::cout << "CICATRICES_LEGACY_DIVERGENTES=" << cicatricesDivergentes << '\n';
    std::cout << "OFFSET_ACCEPTUS_WITNESS=1\n";
    return 0;
}
