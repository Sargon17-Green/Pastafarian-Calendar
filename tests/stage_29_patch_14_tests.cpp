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
    const std::array<Integer, 3> familiaeLatae{{
        M_OLD + 1,
        M_OLD * M_OLD,
        M_OLD * M_OLD * M_OLD
    }};

    BaseMonsterManager manager;
    int defectus = 0;
    int cicatricesLatae = 0;

    for (const auto& N : familiaeLatae) {
        const Integer normativus = ref::chooseRankWide(streamNormativus, N);
        const auto actualis = manager.executeLegacyWideSelectionAssumption(
            FOUNDATION_DAY_OLD,
            FOUNDATION_DAY_OLD,
            1,
            1,
            N);
        const auto diagnosticum = manager.executeUnpatchedWideSelectionDiagnostic(
            FOUNDATION_DAY_OLD,
            FOUNDATION_DAY_OLD,
            1,
            1,
            N);

        if (!actualis.patch11Prepared || !actualis.patch12Prepared || !actualis.patch14Applied ||
            actualis.usedShortPath || !actualis.usedWideDetour ||
            !actualis.outputAvailable || actualis.outputRank != normativus) {
            std::cerr << "DEFECTUS_OUTPUT_PATCH_14 N=" << N << '\n';
            ++defectus;
        }
        if (!actualis.legacyShortFailureBeforePatch ||
            actualis.legacyFailureBeforePatch.empty() ||
            actualis.legacyOutputAvailableBeforePatch ||
            !diagnosticum.legacyShortFailure || diagnosticum.outputAvailable) {
            std::cerr << "DEFECTUS_CICATRICIS_PATCH_14 N=" << N << '\n';
            ++defectus;
        } else {
            ++cicatricesLatae;
        }

        Integer spatium = M_OLD;
        int places = 1;
        while (spatium < N) {
            spatium *= M_OLD;
            ++places;
        }
        if (actualis.widePlaces != places || actualis.wideSpace != spatium ||
            actualis.wideDigitReadCount != places ||
            static_cast<int>(actualis.wideDigits.size()) != places) {
            std::cerr << "DEFECTUS_SPATII_PATCH_14 N=" << N << '\n';
            ++defectus;
        }

        Integer wide = 1;
        Integer pondus = 1;
        for (int j = 0; j < places; ++j) {
            const Integer digit = ref::answerAt(streamNormativus, Integer{j});
            if (actualis.wideDigits[static_cast<std::size_t>(j)] != digit) {
                std::cerr << "DEFECTUS_DIGITI_PATCH_14 N=" << N << " locus=" << j << '\n';
                ++defectus;
            }
            wide += (digit - 1) * pondus;
            pondus *= M_OLD;
        }
        if (actualis.wideInitialValue != wide) {
            std::cerr << "DEFECTUS_COMPOSITIONIS_PATCH_14 N=" << N << '\n';
            ++defectus;
        }

        const Integer limes = (spatium / N) * N;
        Integer acceptus = wide;
        Integer gradus = 0;
        while (acceptus > limes) {
            acceptus = 1 + pastafari::regularMod(
                acceptus - 1 + Integer{streamNormativus.directionStep},
                spatium);
            ++gradus;
        }
        if (actualis.wideAcceptanceLimit != limes || actualis.wideAcceptedValue != acceptus ||
            actualis.wideRejectionSteps != gradus) {
            std::cerr << "DEFECTUS_REJECTIONIS_PATCH_14 N=" << N << '\n';
            ++defectus;
        }
    }

    const Integer NBreve = M_OLD;
    const Integer breveNormativum = ref::chooseRankShort(streamNormativus, NBreve);
    const auto breve = manager.executeLegacyWideSelectionAssumption(
        FOUNDATION_DAY_OLD,
        FOUNDATION_DAY_OLD,
        1,
        1,
        NBreve);
    if (!breve.patch14Applied || !breve.usedShortPath || breve.usedWideDetour ||
        !breve.outputAvailable || breve.outputRank != breveNormativum ||
        !breve.legacyOutputAvailableBeforePatch || breve.legacyShortFailureBeforePatch ||
        breve.widePlaces != 0 || breve.wideDigitReadCount != 0 || !breve.wideDigits.empty()) {
        std::cerr << "DEFECTUS_VIAE_BREVIS_PATCH_14\n";
        ++defectus;
    }

    const Integer digit0 = ref::answerAt(streamNormativus, Integer{0});
    const Integer digit1 = ref::answerAt(streamNormativus, Integer{1});
    const Integer wideDuo = 1 + (digit0 - 1) + (digit1 - 1) * M_OLD;
    const Integer NRejectionis = wideDuo - 1;
    if (NRejectionis <= M_OLD || NRejectionis > M_OLD * M_OLD) {
        std::cerr << "DEFECTUS_WITNESS_REJECTIONIS_PATCH_14\n";
        ++defectus;
    } else {
        const auto rejectio = manager.executeLegacyWideSelectionAssumption(
            FOUNDATION_DAY_OLD,
            FOUNDATION_DAY_OLD,
            1,
            1,
            NRejectionis);
        const Integer normativus = ref::chooseRankWide(streamNormativus, NRejectionis);
        if (!rejectio.usedWideDetour || rejectio.widePlaces != 2 ||
            rejectio.wideDigitReadCount != 2 || rejectio.wideDigits.size() != 2 ||
            rejectio.wideInitialValue != NRejectionis + 1 ||
            rejectio.wideAcceptanceLimit != NRejectionis ||
            rejectio.wideAcceptedValue != NRejectionis ||
            rejectio.wideRejectionSteps != 1 ||
            !rejectio.outputAvailable || rejectio.outputRank != NRejectionis ||
            rejectio.outputRank != normativus) {
            std::cerr << "DEFECTUS_WITNESS_REJECTIONIS_UNIUS_GRADUS_PATCH_14\n";
            ++defectus;
        }
    }

    if (defectus != 0) {
        std::cerr << "REGRESSIO_PATCH_14_DEFECIT: " << defectus << " defectus inventi sunt\n";
        return 1;
    }

    std::cout << "REGRESSIO_PATCH_14_TRANSIIT\n";
    std::cout << "FAMILIAE_LATAE_PROBATAE=3\n";
    std::cout << "CICATRICES_SHORT_ONLY_DIVERGENTES=" << cicatricesLatae << '\n';
    std::cout << "VIA_BREVIS_N_M=PASS\n";
    std::cout << "REJECTIO_WIDE_UNIUS_GRADUS=PASS\n";
    std::cout << "DIGITI_WIDE_RELECTI_DURANTE_REJECTIONE=0\n";
    return 0;
}
