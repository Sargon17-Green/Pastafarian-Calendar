#include "pastafari/monster.hpp"
#include "tests/reference/normative_reference.hpp"

#include <iostream>
#include <sstream>
#include <vector>

namespace {

std::string orderText(const pastafari::PermutationOrder& order) {
    std::ostringstream out;
    out << '[';
    for (std::size_t i = 0; i < order.size(); ++i) {
        if (i != 0) {
            out << ',';
        }
        out << order[i];
    }
    out << ']';
    return out.str();
}

int mismatchCount(const pastafari::PermutationOrder& a,
                  const pastafari::PermutationOrder& b) {
    int n = 0;
    for (std::size_t i = 0; i < a.size(); ++i) {
        if (a[i] != b[i]) {
            ++n;
        }
    }
    return n;
}

struct Casus {
    const char* nomen;
    pastafari::Integer calculationDay;
    pastafari::Integer targetDay;
};

} // namespace

int main() {
    using pastafari::BaseMonsterManager;
    using pastafari::FOUNDATION_DAY_OLD;
    namespace ref = pastafari::reference;

    const std::vector<Casus> casus{
        {"FUNDATIO", FOUNDATION_DAY_OLD, FOUNDATION_DAY_OLD},
        {"POST_UNUM", FOUNDATION_DAY_OLD + 1, FOUNDATION_DAY_OLD + 1},
        {"TRANSITUS", FOUNDATION_DAY_OLD - 2, FOUNDATION_DAY_OLD + 3},
    };

    BaseMonsterManager manager;
    int defectus = 0;
    int cicatricesDivergentes = 0;

    for (const Casus& c : casus) {
        const auto expected = ref::sauce(c.calculationDay, c.targetDay);
        const auto report = manager.executeOverwritableOrderMemorySauce(
            c.calculationDay, c.targetDay);
        const auto legacy = manager.executeUnpatchedOverwritableOrderMemoryDiagnostic(
            c.calculationDay, c.targetDay);

        if (!report.patch11Applied || report.latchWriteCount != 1) {
            std::cerr << "DEFECTUS_LATCH " << c.nomen
                      << ": applicata=" << report.patch11Applied
                      << " scripturae=" << report.latchWriteCount << '\n';
            ++defectus;
        }
        if (report.orderWriteCount != 58 || report.finalOrderSource != "post-commotio 12") {
            std::cerr << "DEFECTUS_MEMORIAE_LEGACY " << c.nomen
                      << ": scripturae=" << report.orderWriteCount
                      << " fons=" << report.finalOrderSource << '\n';
            ++defectus;
        }
        if (report.queryOrder != expected.orderAtDrop46 ||
            report.orderAt46Latch != expected.orderAtDrop46 ||
            report.orderAtDrop46Diagnostic != expected.orderAtDrop46) {
            std::cerr << "DEFECTUS_ORDINIS_LATCH " << c.nomen
                      << ": expectatus=" << orderText(expected.orderAtDrop46)
                      << " query=" << orderText(report.queryOrder)
                      << " latch=" << orderText(report.orderAt46Latch) << '\n';
            ++defectus;
        }
        if (report.legacyQueryOrderBeforePatch != report.finalPostStirOrder) {
            std::cerr << "DEFECTUS_CICATRICIS_IN_REPORT " << c.nomen << '\n';
            ++defectus;
        }
        if (legacy.queryOrder != legacy.finalPostStirOrder ||
            legacy.orderWriteCount != 58 ||
            legacy.finalOrderSource != "post-commotio 12" ||
            legacy.patch11Applied || legacy.latchWriteCount != 0) {
            std::cerr << "DEFECTUS_VIAE_DIAGNOSTICAE " << c.nomen << '\n';
            ++defectus;
        }
        if (report.finalBowls != legacy.finalBowls) {
            std::cerr << "DEFECTUS_CRATERUM_FINALIUM_MUTATORUM " << c.nomen << '\n';
            ++defectus;
        }
        if (mismatchCount(legacy.queryOrder, expected.orderAtDrop46) != 0) {
            ++cicatricesDivergentes;
        }
    }

    if (cicatricesDivergentes == 0) {
        std::cerr << "DEFECTUS_CICATRICIS: nullus casus memoriam superscriptam demonstravit\n";
        ++defectus;
    }

    if (defectus != 0) {
        std::cerr << "REGRESSIO_PATCH_11_DEFECIT: " << defectus
                  << " defectus inventi sunt\n";
        return 1;
    }

    std::cout << "REGRESSIO_PATCH_11_TRANSIIT\n";
    std::cout << "CASUS_PROBATI=" << casus.size() << '\n';
    std::cout << "CICATRICES_LEGACY_DIVERGENTES=" << cicatricesDivergentes << '\n';
    return 0;
}
