#include "pastafari/monster.hpp"
#include "pastafari/source_language_catalog.hpp"
#include "reference/normative_reference.hpp"
#include "stage_55_fast_reference.hpp"

#include <iostream>
#include <stdexcept>
#include <string>
#include <tuple>

namespace {
using pastafari::Integer;
using pastafari::SpaghettiDateFive;
using pastafari::reference::Big;
using pastafari::reference::CalendarDate;
using pastafari::reference::NormativeOracle;

void require(bool condition, const char* message) {
    if (!condition) throw std::runtime_error(message);
}

int cutletIndex(const std::string& name) {
    for (int i = 1; i <= 17; ++i) {
        if (pastafari::cutletSourceName(static_cast<std::size_t>(i)) == name) return i;
    }
    return -1;
}

int monthIndex(const std::string& name) {
    for (int i = 1; i <= 47; ++i) {
        if (pastafari::monthSourceName(static_cast<std::size_t>(i)) == name) return i;
    }
    return -1;
}

using Five = std::tuple<Integer,int,Integer,int,Integer>;

Five canonical(const SpaghettiDateFive& d) {
    return {d.yearNumber, cutletIndex(d.cutletName), d.dayInCutlet,
            monthIndex(d.monthName), d.dayInMonth};
}

Five canonical(const CalendarDate& d) {
    return {d.yearNumber, cutletIndex(d.cutletName), d.dayInCutlet,
            monthIndex(d.monthName), d.dayInMonth};
}
} // namespace

int main(int argc, char** argv) {
    try {
        require(argc == 3, "usus: stage_56_e2e_worker c t");

        const Integer c{argv[1]};
        const Integer t{argv[2]};
        const Big rc{argv[1]};
        const Big rt{argv[2]};

        const SpaghettiDateFive actual = pastafari::calendarDateSpaghetti(c, t);

        NormativeOracle oracle(false);
        const CalendarDate expected =
            pastafari::stage55audit::calendariumCeler(oracle, rc, rt);

        require(canonical(actual) == canonical(expected),
                "E2E Gradus 56 contra reference saved-sum celerem discrepat");

        std::cout
            << "GRADUS_56_E2E_SAVED_SUM_TRANSIIT"
            << " C=" << c
            << " T=" << t
            << " RESULT=["
            << actual.yearNumber << ","
            << cutletIndex(actual.cutletName) << ","
            << actual.dayInCutlet << ","
            << monthIndex(actual.monthName) << ","
            << actual.dayInMonth << "]\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "GRADUS_56_E2E_PROCESSUS_DEFECIT: "
                  << error.what() << "\n";
        return 1;
    }
}