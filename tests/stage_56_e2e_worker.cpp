#include "pastafari/monster.hpp"
#include "pastafari/source_language_catalog.hpp"

#include <iostream>
#include <stdexcept>
#include <string>

namespace {
using pastafari::Integer;

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

void require(bool condition, const char* message) {
    if (!condition) throw std::runtime_error(message);
}
} // namespace

int main(int argc, char** argv) {
    try {
        require(argc == 8,
                "usus: stage_56_e2e_worker c t annus index-segmenti dies-segmenti index-mensis dies-mensis");
        const Integer c{argv[1]};
        const Integer t{argv[2]};
        const Integer expectedYear{argv[3]};
        const int expectedCutlet = std::stoi(argv[4]);
        const Integer expectedDayInCutlet{argv[5]};
        const int expectedMonth = std::stoi(argv[6]);
        const Integer expectedDayInMonth{argv[7]};

        const pastafari::SpaghettiDateFive actual = pastafari::calendarDateSpaghetti(c, t);
        require(actual.yearNumber == expectedYear, "annus E2E Gradus 56 discrepat");
        require(cutletIndex(actual.cutletName) == expectedCutlet,
                "index segmenti E2E Gradus 56 discrepat");
        require(actual.dayInCutlet == expectedDayInCutlet,
                "dies in segmento E2E Gradus 56 discrepat");
        require(monthIndex(actual.monthName) == expectedMonth,
                "index mensis E2E Gradus 56 discrepat");
        require(actual.dayInMonth == expectedDayInMonth,
                "dies in mense E2E Gradus 56 discrepat");

        std::cout << "GRADUS_56_E2E_PROCESSUS_TRANSIIT C=" << c
                  << " T=" << t
                  << " RESULT=[" << actual.yearNumber
                  << "," << expectedCutlet
                  << "," << actual.dayInCutlet
                  << "," << expectedMonth
                  << "," << actual.dayInMonth << "]\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "GRADUS_56_E2E_PROCESSUS_DEFECIT: " << error.what() << "\n";
        return 1;
    }
}
