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

struct AnniFinitimi {
    Year prior;
    Year annus;
    Year posterior;
};

AnniFinitimi quaereAnnum(NormativeOracle& oracle, const Big& c,
                         const Big& desideratus) {
    Year annus = oracle.year5000(c);
    Year posterior = annus;
    exige(annus.number == 5000, "annus fundamentalis 5000 deest");
    while (annus.number > desideratus) {
        const Year anterior = oracle.previousYear(c, annus);
        posterior = annus; // successor from canonical year-5000 backward chain
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
    // For -1, 0, 1 a successor was encountered during the walk back
    // from 5000. Never infer it by reversing NEXT/PREVIOUS selectors.
    exige(posterior.number == annus.number + 1 &&
          posterior.openGateDay == annus.closeGateDay &&
          posterior.openGateIndex == annus.closeGateIndex,
          "annus posterior in catena canonica deest");
    const Year prior = oracle.previousYear(c, annus);
    exige(prior.number == annus.number - 1 &&
          prior.closeGateDay == annus.openGateDay &&
          prior.closeGateIndex == annus.openGateIndex,
          "annus prior in catena canonica non continuus est");
    return AnniFinitimi{prior, annus, posterior};
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
        const AnniFinitimi tria = quaereAnnum(oracle, c, numerus);
        const Year& annus = tria.annus;
        // Quondam sola duo extrema cuiusque anni remoti probabantur.
        // Interior anni est nunc quoque observatus: secunda dies, mediana,
        // et paenultima, ne defectus texturæ inter portas lateat.
        const Big first = annus.openGateDay + Big{1};
        const Big second = annus.openGateDay + Big{2};
        const Big middle = annus.openGateDay
            + (annus.closeGateDay - annus.openGateDay) / Big{2};
        const Big penultimate = annus.closeGateDay - Big{1};
        const Big last = annus.closeGateDay;
        exige(first < second && second < middle &&
              middle < penultimate && penultimate < last,
              "quinque indices diversi in anno remoto exiguntur");
        const std::array<Big, 5> quinque{
            first, second, middle, penultimate, last};
        for (const Big& target : quinque) {
            probaDiem(oracle, c, annus, target);
        }
        std::cout << "GRADUS56_ANNUS_REMOTUS_INTERIOR=3/3_PASS YEAR="
                  << numerus << '\n';
        std::cout << "GRADUS56_ANNUS_REMOTUS_SAVED_SUM=5/5_PASS YEAR="
                  << numerus << '\n';

        // Immediate neighbors of both gates, using the exact year chain
        // discovered from year 5000, not a conjectured inverse path.
        // Same process, same calculation day and public dispatcher.
        probaDiem(oracle, c, tria.prior, annus.openGateDay);
        probaDiem(oracle, c, tria.posterior, annus.closeGateDay + Big{1});
        std::cout << "GRADUS56_ANNUS_REMOTUS_LIMINA_VICINA=2/2_PASS YEAR="
                  << numerus << '\n';
        std::cout << "GRADUS56_ANNUS_REMOTUS_SEPTEM=7/7_PASS YEAR="
                  << numerus << '\n';
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "GRADUS56_ANNUS_REMOTUS_DEFECIT: " << e.what() << '\n';
        return 1;
    }
}
