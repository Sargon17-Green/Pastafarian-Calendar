#include "pastafari/monster.hpp"

#include <array>
#include <iostream>
#include <string>

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
    const std::array<Integer, 6> gradus{
        Integer{0}, Integer{1}, Integer{17},
        Integer{-1}, Integer{-17}, Integer{-123456}
    };

    int discrepantiae = 0;
    int concordantiaeNonNegativae = 0;
    for (const Integer& signedStep : gradus) {
        const auto relatio = manager.executeLegacyGateQuestionDay(signedStep);
        const Integer expectatus = FOUNDATION_DAY_OLD + signedStep;
        Integer magnitudo = signedStep;
        if (magnitudo < 0) {
            magnitudo = -magnitudo;
        }
        const Integer expectatusLegacy = FOUNDATION_DAY_OLD + magnitudo;

        if (relatio.magnitudePassedToLegacy != magnitudo) {
            std::cerr << "CICATRIX_MAGNITUDINIS_LEGACY_NON_EXACTA signedStep="
                      << signedStep << "\n";
            return 2;
        }

        if (relatio.outputQuestionDay != expectatus) {
            ++discrepantiae;
            std::cout << "DISCREPANTIA_PORTAE signedStep=" << signedStep
                      << " expectatus=" << expectatus
                      << " actualis=" << relatio.outputQuestionDay
                      << " magnitudo_legacy=" << relatio.magnitudePassedToLegacy
                      << "\n";
        } else if (signedStep >= 0) {
            ++concordantiaeNonNegativae;
            std::cout << "CONCORDANTIA_PORTAE signedStep=" << signedStep
                      << " valor=" << relatio.outputQuestionDay << "\n";
        }
    }

    if (concordantiaeNonNegativae != 3) {
        std::cerr << "CASUS_NON_NEGATIVI_NON_TRES_SUNT\n";
        return 2;
    }
    if (discrepantiae == 0) {
        std::cout << "REGRESSIO_DISCOVERY_15_TRANSIIT\n";
        return 0;
    }
    if (discrepantiae == 3) {
        std::cout << "REGRESSIO_DISCOVERY_15_DEFECIT: 3 gradus negativi ad latus positivum Fundationis quaesiti sunt\n";
        return 1;
    }
    std::cerr << "REGRESSIO_DISCOVERY_15_INEXPECTATA: discrepantiae=" << discrepantiae << "\n";
    return 2;
}
