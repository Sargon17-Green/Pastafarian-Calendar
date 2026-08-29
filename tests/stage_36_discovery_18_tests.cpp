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

static Year sequentialYear(NormativeOracle& oracle,
                           const Integer& calculationDay,
                           const Integer& targetDay,
                           const Year& anchor,
                           int& transitūs) {
    Year y = anchor;
    transitūs = 0;
    while (targetDay > y.closeGateDay) {
        y = oracle.nextYear(calculationDay, y);
        ++transitūs;
    }
    while (targetDay <= y.openGateDay) {
        y = oracle.previousYear(calculationDay, y);
        --transitūs;
    }
    return y;
}

int main() {
    try {
        NormativeOracle oracle;
        const Integer calculationDay = pastafari::reference::FOUNDATION_DAY;
        const Year anchorYear = oracle.year5000(calculationDay);
        const LegacyYearAnchor anchor{
            anchorYear.number,
            anchorYear.openGateDay + 1,
            anchorYear.closeGateDay
        };

        require(anchor.number == 5000, "anchor year 5000 non est");
        require(anchor.lastDay - anchor.firstDay + 1 == 4244,
                "longitudo witness anchoris inexpectata est");

        const Year next = oracle.nextYear(calculationDay, anchorYear);
        const std::vector<Integer> targets{
            anchor.firstDay,
            anchor.firstDay + 365,
            anchor.lastDay,
            next.openGateDay + 1
        };

        const BaseMonsterManager manager;
        int discrepantiae = 0;
        int controles = 0;

        for (const Integer& targetDay : targets) {
            int transitūs = 0;
            const Year expected = sequentialYear(
                oracle,
                calculationDay,
                targetDay,
                anchorYear,
                transitūs);
            const Integer directGuess = oldJumpGuess(anchor, targetDay);
            const auto report = manager.executeLegacyYearJump(anchor, targetDay);

            require(report.ready, "DISCOVERY 18 non paratus est");
            require(report.oldGuess == directGuess,
                    "report oldJumpGuess a helper directo differt");
            require(report.anchor.number == anchor.number &&
                    report.anchor.firstDay == anchor.firstDay &&
                    report.anchor.lastDay == anchor.lastDay,
                    "anchor reportatus mutatus est");
            require(report.targetDay == targetDay,
                    "targetDay reportatus mutatus est");

            if (report.outputYearNumber != expected.number) {
                ++discrepantiae;
                std::cout << "DISCREPANTIA_SALTUS target=" << targetDay
                          << " guess=" << report.oldGuess
                          << " actualis=" << report.outputYearNumber
                          << " normativus=" << expected.number
                          << " transitus_sequentiales=" << transitūs << "\n";
            } else {
                ++controles;
                std::cout << "CONCORDANTIA_SALTUS target=" << targetDay
                          << " annus=" << expected.number
                          << " transitus_sequentiales=" << transitūs << "\n";
            }
        }

        std::cout << "ANCHOR_NUMBER=" << anchor.number << "\n";
        std::cout << "ANCHOR_FIRST_DAY=" << anchor.firstDay << "\n";
        std::cout << "ANCHOR_LAST_DAY=" << anchor.lastDay << "\n";
        std::cout << "ANCHOR_LENGTH=" << (anchor.lastDay - anchor.firstDay + 1) << "\n";
        std::cout << "CONTROLES_CONCORDANTES=" << controles << "\n";

        if (discrepantiae == 0) {
            std::cout << "REGRESSIO_DISCOVERY_18_TRANSIIT\n";
            return 0;
        }
        if (discrepantiae == 3 && controles == 1) {
            std::cout << "REGRESSIO_DISCOVERY_18_DEFECIT: "
                         "3 target dies per oldJumpGuess /365 ad annum falsum saltant "
                         "loco ambulationis sequentialis\n";
            return 1;
        }
        std::cerr << "REGRESSIO_DISCOVERY_18_INEXPECTATA: discrepantiae="
                  << discrepantiae << " controles=" << controles << "\n";
        return 2;
    } catch (const std::exception& error) {
        std::cerr << "REGRESSIO_DISCOVERY_18_ERROR: " << error.what() << "\n";
        return 3;
    }
}
