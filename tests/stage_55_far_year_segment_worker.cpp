#include "reference/normative_reference.hpp"
#include "stage_55_fast_reference.hpp"

#include <iostream>
#include <stdexcept>
#include <string>

using pastafari::reference::Big;
using pastafari::reference::CalendarDate;
using pastafari::reference::NormativeOracle;
using pastafari::reference::Year;

namespace {
Big legito(const char* textus) { return Big{std::string(textus)}; }

void checkpoint(const Year& annus) {
    std::cout << "CHECKPOINT YEAR=" << annus.number
              << " OPEN_INDEX=" << annus.openGateIndex
              << " CLOSE_INDEX=" << annus.closeGateIndex
              << " OPEN_DAY=" << annus.openGateDay
              << " CLOSE_DAY=" << annus.closeGateDay << '\n';
}

void fixture(const Year& annus, const Big& c) {
    const Big target = annus.openGateDay + 1;
    NormativeOracle oracleStructurae;
    const CalendarDate dies = pastafari::stage55audit::calendariumCelerInAnno(
        oracleStructurae, c, target, annus);
    std::cout << "FIXTURE YEAR=" << annus.number
              << " TARGET=" << target
              << " OPEN=" << annus.openGateDay
              << " CLOSE=" << annus.closeGateDay
              << " RESULT=[" << dies.yearNumber << ',' << dies.cutletName << ','
              << dies.dayInCutlet << ',' << dies.monthName << ',' << dies.dayInMonth << "]\n";
}
}

int main(int argc, char** argv) {
    try {
        pastafari::stage55audit::probaReferenceCelerem();
        const Big c = pastafari::reference::FOUNDATION_DAY;
        NormativeOracle oracle;
        Year annus;
        Big finis;

        if (argc == 3 && std::string(argv[1]) == "--init") {
            finis = legito(argv[2]);
            annus = oracle.year5000(c);
        } else if (argc == 8 && std::string(argv[1]) == "--resume") {
            annus = Year{legito(argv[2]), legito(argv[3]), legito(argv[4]),
                         legito(argv[5]), legito(argv[6])};
            finis = legito(argv[7]);
            oracle.seedGateAnchorForStage55Audit(annus.openGateIndex, annus.openGateDay);
        } else {
            throw std::runtime_error("argumenta checkpoint segmenti invalida sunt");
        }

        if (finis > annus.number)
            throw std::runtime_error("finis segmenti post initium positus est");
        while (annus.number > finis) annus = oracle.previousYear(c, annus);
        if (annus.number != finis)
            throw std::runtime_error("finis segmenti non exacte attactus est");

        checkpoint(annus);
        if (annus.number == 1 || annus.number == 0 || annus.number == -1)
            fixture(annus, c);
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "SEGMENTUM_ANNI_REMOTI_DEFECIT: " << error.what() << '\n';
        return 1;
    }
}
