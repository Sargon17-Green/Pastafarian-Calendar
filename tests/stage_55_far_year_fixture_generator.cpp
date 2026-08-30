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
void emitte(const Year& annus, const CalendarDate& dies, const Big& target) {
    std::cout << "YEAR=" << annus.number
              << " TARGET=" << target
              << " OPEN=" << annus.openGateDay
              << " CLOSE=" << annus.closeGateDay
              << " RESULT=[" << dies.yearNumber << ',' << dies.cutletName << ','
              << dies.dayInCutlet << ',' << dies.monthName << ',' << dies.dayInMonth << "]\n";
}
}

int main() {
    try {
        pastafari::stage55audit::probaReferenceCelerem();
        const Big c = pastafari::reference::FOUNDATION_DAY;
        NormativeOracle oracle;
        Year annus = oracle.year5000(c);
        while (annus.number >= -1) {
            if (annus.number == 1 || annus.number == 0 || annus.number == -1) {
                const Big target = annus.openGateDay + 1;
                const CalendarDate dies = pastafari::stage55audit::calendariumCelerInAnno(
                    oracle, c, target, annus);
                emitte(annus, dies, target);
            }
            if (annus.number == -1) break;
            if ((annus.number % 250) == 0)
                std::cerr << "PROGRESSUS_FIXTURAE_ANNUS=" << annus.number << '\n' << std::flush;
            annus = oracle.previousYear(c, annus);
        }
        std::cerr << "FIXTURAE_ANNORUM_REMOTORUM_TRANSIERUNT\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "FIXTURAE_ANNORUM_REMOTORUM_DEFECERUNT: " << error.what() << '\n';
        return 1;
    }
}
