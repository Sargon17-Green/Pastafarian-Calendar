#include "pastafari/monster.hpp"
#include "reference/normative_reference.hpp"
#include "stage_55_fast_reference.hpp"

#include <array>
#include <iostream>
#include <stdexcept>
#include <string>

namespace {
using pastafari::Integer;
using pastafari::SpaghettiDateFive;
using pastafari::reference::Big;
using pastafari::reference::CalendarDate;
using pastafari::reference::NormativeOracle;
using pastafari::reference::Year;

void exige(bool ok, const char* nuntius) {
    if (!ok) throw std::runtime_error(nuntius);
}

bool eademDies(const SpaghettiDateFive& a, const CalendarDate& b) {
    return a.yearNumber == b.yearNumber &&
           a.cutletName == b.cutletName &&
           a.dayInCutlet == b.dayInCutlet &&
           a.monthName == b.monthName &&
           a.dayInMonth == b.dayInMonth;
}

Year quaereAnnum(NormativeOracle& oracle, const Big& c, const Big& desideratus) {
    Year annus = oracle.year5000(c);
    exige(annus.number == 5000, "annus fundamentalis 5000 deest");
    while (annus.number > desideratus) {
        const Year anterior = oracle.previousYear(c, annus);
        exige(anterior.number == annus.number - 1,
              "numerus anni sine successione computatus est");
        exige(anterior.closeGateDay == annus.openGateDay,
              "porta communis annorum vicinorum discrepat");
        annus = anterior;
        if (annus.number % 500 == 0) {
            std::cerr << "GRADUS56_PROGRESSUS_YEAR=" << annus.number
                      << '\n' << std::flush;
        }
    }
    exige(annus.number == desideratus, "annus desideratus non inventus est");
    exige(annus.closeGateDay > annus.openGateDay,
          "annus remoti temporis non positivus est");
    return annus;
}

void probaDiem(NormativeOracle& oracle, const Big& c, const Year& annus,
               const Big& target) {
    const CalendarDate expected =
        pastafari::stage55audit::calendariumCelerInAnno(
            oracle, c, target, annus);
    const SpaghettiDateFive actual =
        pastafari::calendarDateSpaghetti(Integer{c}, Integer{target});
    exige(expected.yearNumber == annus.number &&
          actual.yearNumber == annus.number, "numerus anni finitimus discrepavit");
    exige(eademDies(actual, expected),
          "quinque campi contra reference saved-sum discrepant");
    std::cout << "GRADUS56_ANNUS_REMOTUS_DIES_PASS YEAR=" << annus.number
              << " TARGET=" << target
              << " RESULT=[" << actual.yearNumber << ","
              << actual.cutletName << "," << actual.dayInCutlet << ","
              << actual.monthName << "," << actual.dayInMonth << "]\n"
              << std::flush;
}
} // namespace

int main(int argc, char** argv) {
    try {
        exige(argc == 2, "usus: stage_56_far_year_saved_sum_worker 1|0|-1");
        const std::string argumentum{argv[1]};
        exige(argumentum == "1" || argumentum == "0" || argumentum == "-1",
              "solum anni 1, 0, -1 licent");
        const Big numerus{argumentum};
        const Big c = pastafari::FOUNDATION_DAY_OLD;
        NormativeOracle oracle(false); // saved-sum; non mutans raw-sum
        const Year annus = quaereAnnum(oracle, c, numerus);
        const std::array<Big, 2> limites{
            annus.openGateDay + 1, annus.closeGateDay
        };
        for (const Big& target : limites) probaDiem(oracle, c, annus, target);
        std::cout << "GRADUS56_ANNUS_REMOTUS_SAVED_SUM=2/2_PASS YEAR="
                  << numerus << '\n';
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "GRADUS56_ANNUS_REMOTUS_DEFECIT: " << e.what() << '\n';
        return 1;
    }
}
