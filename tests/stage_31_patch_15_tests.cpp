#include "pastafari/monster.hpp"

#include <array>
#include <iostream>

int main() {
    using pastafari::BaseMonsterManager;
    using pastafari::FOUNDATION_DAY_OLD;
    using pastafari::Integer;
    using pastafari::oldGateQuestionDay;

    if (oldGateQuestionDay(Integer{0}) != FOUNDATION_DAY_OLD ||
        oldGateQuestionDay(Integer{7}) != FOUNDATION_DAY_OLD + 7 ||
        oldGateQuestionDay(Integer{-7}) != FOUNDATION_DAY_OLD - 7) {
        std::cerr << "FORMA_OLD_GATE_QUESTION_DAY_MUTATA_EST\n";
        return 2;
    }

    const BaseMonsterManager manager;
    const std::array<Integer, 7> gradus{
        Integer{0}, Integer{1}, Integer{17},
        Integer{-1}, Integer{-17}, Integer{-101}, Integer{-123456}
    };

    int casusNegativi = 0;
    int cicatricesDivergentes = 0;
    for (const Integer& signedStep : gradus) {
        Integer magnitudo = signedStep;
        if (magnitudo < 0) {
            magnitudo = -magnitudo;
        }
        const Integer legacyExpectatus = FOUNDATION_DAY_OLD + magnitudo;
        const Integer semanticusExpectatus = signedStep < 0
            ? FOUNDATION_DAY_OLD - magnitudo
            : legacyExpectatus;

        const auto activus = manager.executeLegacyGateQuestionDay(signedStep);
        const auto diagnosticus = manager.executeUnpatchedGateQuestionDayDiagnostic(signedStep);

        if (diagnosticus.magnitudePassedToLegacy != magnitudo ||
            diagnosticus.outputQuestionDay != legacyExpectatus ||
            diagnosticus.handler != "Discovery15GateQuestionHandler" ||
            diagnosticus.patch15Applied) {
            std::cerr << "VIA_DIAGNOSTICA_DISCOVERY_15_MUTATA_EST signedStep="
                      << signedStep << "\n";
            return 2;
        }

        if (activus.magnitudePassedToLegacy != magnitudo ||
            activus.legacyOutputBeforePatch != legacyExpectatus ||
            activus.outputQuestionDay != semanticusExpectatus ||
            activus.handler != "Patch15GateQuestionHandler" ||
            !activus.patch15Applied) {
            std::cerr << "PATCH_15_NON_EXACTUS signedStep=" << signedStep << "\n";
            return 2;
        }

        if (signedStep < 0) {
            ++casusNegativi;
            if (activus.legacyOutputBeforePatch == activus.outputQuestionDay) {
                std::cerr << "DETOUR_NEGATIVUS_NON_OBSERVABILIS signedStep=" << signedStep << "\n";
                return 2;
            }
            ++cicatricesDivergentes;
        } else if (activus.legacyOutputBeforePatch != activus.outputQuestionDay) {
            std::cerr << "VIA_NON_NEGATIVA_LEGACY_MUTATA_EST signedStep=" << signedStep << "\n";
            return 2;
        }
    }

    const auto primus = manager.executeLegacyGateQuestionDay(Integer{-101});
    const auto secundus = manager.executeLegacyGateQuestionDay(Integer{17});
    if (primus.outputQuestionDay != FOUNDATION_DAY_OLD - 101 ||
        secundus.outputQuestionDay != FOUNDATION_DAY_OLD + 17 ||
        secundus.legacyOutputBeforePatch != FOUNDATION_DAY_OLD + 17) {
        std::cerr << "STATUS_PATCH_15_INTER_INVOCATIONES_CONTAMINATUS_EST\n";
        return 2;
    }

    if (casusNegativi != 4 || cicatricesDivergentes != 4) {
        std::cerr << "NUMERUS_CASUUM_NEGATIVORUM_INEXPECTATUS\n";
        return 2;
    }

    std::cout << "REGRESSIO_PATCH_15_TRANSIIT\n";
    std::cout << "CASUS_NEGATIVI_PROBATI=" << casusNegativi << "\n";
    std::cout << "CICATRICES_POSITIVAE_DIVERGENTES=" << cicatricesDivergentes << "\n";
    std::cout << "VIA_NON_NEGATIVA_LEGACY_SERVATA=YES\n";
    return 0;
}
