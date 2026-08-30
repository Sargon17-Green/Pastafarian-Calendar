#include "pastafari/monster.hpp"
#include "reference/normative_reference.hpp"
#include "stage_55_fast_reference.hpp"

#include <iostream>
#include <fstream>
#include <regex>
#include <stdexcept>
#include <string>

using pastafari::Integer;
using pastafari::SpaghettiDateFive;
using pastafari::reference::Big;
using pastafari::reference::CalendarDate;
using pastafari::reference::NormativeOracle;
using pastafari::reference::Year;

namespace {
void require(bool condicio, const std::string& nuntius) {
    if (!condicio) throw std::runtime_error(nuntius);
}

bool idem(const SpaghettiDateFive& actualis, const CalendarDate& expectata) {
    return actualis.yearNumber == expectata.yearNumber &&
           actualis.cutletName == expectata.cutletName &&
           actualis.dayInCutlet == expectata.dayInCutlet &&
           actualis.monthName == expectata.monthName &&
           actualis.dayInMonth == expectata.dayInMonth;
}

Year adAnnum(NormativeOracle& oracle, const Big& c, const Big& numerus) {
    Year annus = oracle.year5000(c);
    while (annus.number > numerus) annus = oracle.previousYear(c, annus);
    while (annus.number < numerus) annus = oracle.nextYear(c, annus);
    return annus;
}

struct FixtureRemota {
    Big numerus;
    Big target;
    CalendarDate expectata;
};

FixtureRemota legeFixturam(const std::string& via, const Big& numerus) {
    std::ifstream input(via);
    if (!input) throw std::runtime_error("fixtura anni remoti aperiri non potuit");
    const std::regex forma(
        R"(^FIXTURE YEAR=(-?[0-9]+) TARGET=(-?[0-9]+) OPEN=(-?[0-9]+) CLOSE=(-?[0-9]+) RESULT=\[(-?[0-9]+),([^,]+),(-?[0-9]+),([^,]+),(-?[0-9]+)\]$)");
    std::string linea;
    std::smatch partes;
    while (std::getline(input, linea)) {
        if (!std::regex_match(linea, partes, forma)) continue;
        const Big annus{partes[1].str()};
        if (annus != numerus) continue;
        return FixtureRemota{
            annus,
            Big{partes[2].str()},
            CalendarDate{Big{partes[5].str()}, partes[6].str(), Big{partes[7].str()},
                         partes[8].str(), Big{partes[9].str()}}
        };
    }
    throw std::runtime_error("fixtura anni remoti petita non inventa est");
}
}

int main(int argc, char** argv) {
    try {
        require(argc == 2 || (argc == 4 && std::string(argv[1]) == "--fixture"),
                "argumenta anni remoti invalida sunt");
        const bool exFixtura = argc == 4;
        const Big numerus{std::string(argv[exFixtura ? 3 : 1])};
        require(numerus == 1 || numerus == 0 || numerus == -1,
                "hic worker tantum annos 1, 0 et -1 audit");

        const Big c = pastafari::FOUNDATION_DAY_OLD;
        Big target;
        CalendarDate expectata;
        if (exFixtura) {
            const FixtureRemota fixtura = legeFixturam(argv[2], numerus);
            target = fixtura.target;
            expectata = fixtura.expectata;
        } else {
            pastafari::stage55audit::probaReferenceCelerem();
            NormativeOracle oracle;
            const Year annus = adAnnum(oracle, c, numerus);
            target = annus.openGateDay + 1;
            expectata = pastafari::stage55audit::calendariumCeler(oracle, c, target);
        }
        const SpaghettiDateFive actualis = pastafari::calendarDateSpaghetti(c, target);

        require(expectata.yearNumber == numerus,
                "oracle annum auditum non reddidit");
        require(idem(actualis, expectata),
                "quinque campi spaghetti ab oracle locali discrepant");

        std::cout << "AUDIT_ANNUS_REMOTUS_TRANSIIT YEAR=" << numerus
                  << " TARGET=" << target
                  << " RESULT=[" << actualis.yearNumber << ','
                  << actualis.cutletName << ',' << actualis.dayInCutlet << ','
                  << actualis.monthName << ',' << actualis.dayInMonth << "]\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "AUDIT_ANNUS_REMOTUS_DEFECIT: " << error.what() << '\n';
        return 1;
    }
}
