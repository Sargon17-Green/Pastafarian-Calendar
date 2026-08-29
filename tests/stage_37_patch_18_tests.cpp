#include "pastafari/monster.hpp"
#include "reference/normative_reference.hpp"

#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

using pastafari::BaseMonsterManager;
using pastafari::Integer;
using pastafari::LegacyYearAnchor;
using pastafari::oldJumpGuess;
using pastafari::reference::NormativeOracle;
using pastafari::reference::Year;

static void require(bool condicio, const std::string& nuntius) {
    if (!condicio) {
        throw std::runtime_error(nuntius);
    }
}

struct Casus {
    Integer targetDay{};
    Integer expectedYear{};
    std::size_t forwardSteps = 0;
    std::size_t backwardSteps = 0;
};

int main() {
    try {
        NormativeOracle oracle;
        const Integer calculationDay = pastafari::reference::FOUNDATION_DAY;
        const Year y5000 = oracle.year5000(calculationDay);
        const Year y5001 = oracle.nextYear(calculationDay, y5000);
        const Year y5002 = oracle.nextYear(calculationDay, y5001);
        const Year y4999 = oracle.previousYear(calculationDay, y5000);
        const Year y4998 = oracle.previousYear(calculationDay, y4999);

        const LegacyYearAnchor anchor{
            y5000.number,
            y5000.openGateDay + 1,
            y5000.closeGateDay
        };

        const std::vector<Casus> casus{
            Casus{anchor.firstDay + 365, Integer{5000}, 0, 0},
            Casus{y5001.openGateDay + 1, Integer{5001}, 1, 0},
            Casus{y5002.openGateDay + 1, Integer{5002}, 2, 0},
            Casus{y4999.openGateDay + 1, Integer{4999}, 0, 1},
            Casus{y4998.openGateDay + 1, Integer{4998}, 0, 2}
        };

        const BaseMonsterManager manager;
        int telemetryDivergences = 0;
        std::size_t totalForward = 0;
        std::size_t totalBackward = 0;

        for (const Casus& casusUnus : casus) {
            const Integer legacyGuess = oldJumpGuess(anchor, casusUnus.targetDay);
            const auto diagnostic = manager.executeUnpatchedYearJumpDiagnostic(
                anchor,
                casusUnus.targetDay);
            const auto report = manager.executeLegacyYearJump(
                anchor,
                casusUnus.targetDay,
                calculationDay);

            require(diagnostic.ready && diagnostic.guessUsedAsOutput,
                    "diagnosticum DISCOVERY 18 non servatum est");
            require(diagnostic.outputYearNumber == legacyGuess &&
                    diagnostic.oldGuess == legacyGuess,
                    "diagnosticum oldJumpGuess non idem output reddit");

            require(report.ready, "PATCH 18 report non paratus est");
            require(report.patch18Applied,
                    "PATCH 18 flag non positus est");
            require(report.guessTelemetryOnly && !report.guessUsedAsOutput,
                    "oldJumpGuess non est telemetry tantum");
            require(report.oldGuess == legacyGuess,
                    "telemetria oldJumpGuess mutata est");
            require(report.outputYearNumber == casusUnus.expectedYear,
                    "annus semanticus PATCH 18 a norma differt");
            require(report.outputYear.number == casusUnus.expectedYear,
                    "recordum anni PATCH 18 a numero output differt");
            require(report.outputYear.openGateDay < casusUnus.targetDay &&
                    casusUnus.targetDay <= report.outputYear.closeGateDay,
                    "target dies intra recordum anni non continetur");
            require(report.forwardSteps == casusUnus.forwardSteps &&
                    report.backwardSteps == casusUnus.backwardSteps,
                    "numerus graduum sequentialium falsus est");
            require(report.anchorYear.number == 5000 &&
                    report.anchorYear.openGateDay + 1 == anchor.firstDay &&
                    report.anchorYear.closeGateDay == anchor.lastDay,
                    "anchor 5000 PATCH 18 mutatus est");

            totalForward += report.forwardSteps;
            totalBackward += report.backwardSteps;
            if (legacyGuess != casusUnus.expectedYear) {
                ++telemetryDivergences;
            }

            std::cout << "CASUS_PATCH18 target=" << casusUnus.targetDay
                      << " oldGuess=" << legacyGuess
                      << " annus=" << report.outputYearNumber
                      << " ante=" << report.outputYear.openGateDay
                      << " post=" << report.outputYear.closeGateDay
                      << " gradus_plus=" << report.forwardSteps
                      << " gradus_minus=" << report.backwardSteps
                      << "\n";
        }

        require(telemetryDivergences >= 3,
                "cicatrix oldJumpGuess non satis observabilis est");
        require(totalForward == 3,
                "summa graduum forward inexpectata est");
        require(totalBackward == 3,
                "summa graduum backward inexpectata est");

        std::cout << "REGRESSIO_PATCH_18_TRANSIIT\n";
        std::cout << "CASUS_PROBATI=" << casus.size() << "\n";
        std::cout << "CICATRICES_OLD_JUMP_DIVERGENTES=" << telemetryDivergences << "\n";
        std::cout << "GRADUS_FORWARD_TOTAL=" << totalForward << "\n";
        std::cout << "GRADUS_BACKWARD_TOTAL=" << totalBackward << "\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "REGRESSIO_PATCH_18_ERROR: " << error.what() << "\n";
        return 1;
    }
}
