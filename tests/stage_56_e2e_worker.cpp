#include "pastafari/monster.hpp"
#include "pastafari/source_language_catalog.hpp"
#include "reference/normative_reference.hpp"
#include "stage_55_fast_reference.hpp"

#include <array>
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

void requireCanonicalAc1FixedVectors() {
    // Testimonia fixa ex README.md / AC.1 in ramo main.
    // Non e NormativeOracle neque e codice productionis derivantur.
    // Mutant veteris rawBowlSum has decem probationes transire non potest.
    struct CanonicalAc1 {
        long long c;
        long long t;
        long long annus;
        int segmentum;
        long long diesSegmenti;
        int mensis;
        long long diesMensis;
    };
    constexpr std::array<CanonicalAc1, 10> vectores{{
        {-15055671, -15055671, 5000, 10, 503, 20, 56},
        {-15055671, -15055672, 5000, 10, 502, 32, 21},
        {-15055671, -15055670, 5000, 14, 1, 29, 38},
        {-15055671, -15056171, 5000, 10, 3, 1, 29},
        {-15055671, -15055171, 5000, 14, 500, 18, 76},
        {-15055671, -15061671, 4999, 5, 158, 43, 3},
        {-15055671, -15049671, 5001, 12, 95, 5, 81},
        {-15056905, -15056448, 5000, 9, 167, 10, 65},
        {-15054437, -15053449, 5000, 14, 10, 1, 45},
        {-15058171, -15053171, 5002, 5, 288, 29, 13}
    }};
    int numerus = 0;
    for (const CanonicalAc1& v : vectores) {
        const SpaghettiDateFive actual =
            pastafari::calendarDateSpaghetti(Integer{v.c}, Integer{v.t});
        const Five expected{
            Integer{v.annus}, v.segmentum, Integer{v.diesSegmenti},
            v.mensis, Integer{v.diesMensis}};
        if (canonical(actual) != expected) {
            throw std::runtime_error(
                "AC.1 testis canonicus " + std::to_string(numerus + 1)
                + " discrepavit a quinque valoribus fixis main");
        }
        ++numerus;
        std::cout << "GRADUS56_AC1_VECTOR_PASS=" << numerus
                  << " C=" << v.c << " T=" << v.t << '\n' << std::flush;
    }
    require(numerus == 10, "decem testes AC.1 exiguntur");
    std::cout << "GRADUS56_AC1_CANONICA=10/10_PASS\n" << std::flush;

    // Eaedem decem exspectationes FIXAE denuo in ordine adverso,
    // intra eundem processum post omnes primas invocationes: hoc
    // detectat state leakage et latentem dependentiam ab ordine API.
    int inversi = 0;
    for (auto it = vectores.rbegin(); it != vectores.rend(); ++it) {
        const CanonicalAc1& v = *it;
        const Five expected{
            Integer{v.annus}, v.segmentum, Integer{v.diesSegmenti},
            v.mensis, Integer{v.diesMensis}};
        const Five actual = canonical(pastafari::calendarDateSpaghetti(
            Integer{v.c}, Integer{v.t}));
        require(actual == expected,
                "AC.1 ordo inversus discrepavit a valoribus fixis main");
        ++inversi;
        std::cout << "GRADUS56_AC1_INVERSE_VECTOR_PASS=" << inversi
                  << " ORIGINAL_INDEX=" << (vectores.size() - inversi + 1)
                  << '\n' << std::flush;
    }
    require(inversi == 10, "decem testes inversi AC.1 exiguntur");
    std::cout << "GRADUS56_AC1_ORDO_INVERSUS=10/10_PASS\n";
}

} // namespace

int main(int argc, char** argv) {
    try {
        if (argc == 2 && std::string(argv[1]) == "--ac1-canonical") {
            requireCanonicalAc1FixedVectors();
            return 0;
        }
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