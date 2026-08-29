#include "pastafari/monster.hpp"
#include "tests/reference/normative_reference.hpp"

#include <iostream>
#include <string>

namespace {

std::string decimal(const pastafari::Integer& x) {
    return x.convert_to<std::string>();
}

} // namespace

int main() {
    using pastafari::BaseMonsterManager;
    using pastafari::FOUNDATION_DAY_OLD;
    using pastafari::Integer;
    using pastafari::reference::buildHiddenDrops;
    using pastafari::reference::buildStones;
    using pastafari::reference::workCounts;

    const Integer calculationDay = FOUNDATION_DAY_OLD + 17;
    const Integer targetDay = FOUNDATION_DAY_OLD + 43;

    const auto counts = workCounts(calculationDay, targetDay);
    const auto stones = buildStones();
    const auto expectatae = buildHiddenDrops(counts, stones);

    BaseMonsterManager manager;
    const auto report = manager.executeHiddenDrops(calculationDay, targetDay);

    int defectusViae = 0;
    if (report.calculationDay != calculationDay ||
        report.targetDay != targetDay ||
        report.branchCount < 4 ||
        report.status.empty() ||
        report.handler.empty()) {
        std::cerr << "DEFECTUS_VIAE_DISCOVERY_05: metadata viae incompleta sunt\n";
        ++defectusViae;
    }

    for (std::size_t k = 0; k < 7; ++k) {
        const std::size_t retro = 6 - k;
        if (report.legacyOutput[retro] != expectatae[k]) {
            std::cerr
                << "DEFECTUS_ORDINIS_RETROGRADI k=" << (k + 1)
                << ": expectatus_in_slot=" << (retro + 1)
                << " valor=" << decimal(expectatae[k])
                << " actualis=" << decimal(report.legacyOutput[retro])
                << "\n";
            ++defectusViae;
        }
    }

    if (defectusViae != 0) {
        std::cerr
            << "REGRESSIO_DISCOVERY_05_INOPINATE_DEFECIT: "
            << defectusViae
            << " defectus structurae inventi sunt\n";
        return 2;
    }

    int discrepantiae = 0;
    for (std::size_t k = 0; k < 7; ++k) {
        if (report.output[k] != expectatae[k]) {
            std::cerr
                << "DISCREPANTIA GUTTA_OCCULTA k=" << (k + 1)
                << ": expectatus=" << decimal(expectatae[k])
                << " actualis=" << decimal(report.output[k])
                << "\n";
            ++discrepantiae;
        } else {
            std::cout
                << "CONCORDANTIA GUTTA_OCCULTA k=" << (k + 1)
                << ": valor=" << decimal(report.output[k])
                << "\n";
        }
    }

    if (discrepantiae == 0) {
        std::cout << "REGRESSIO_DISCOVERY_05_TRANSIIT\n";
        return 0;
    }

    if (discrepantiae != 6) {
        std::cerr
            << "REGRESSIO_DISCOVERY_05_INOPINATE_DEFECIT: "
            << discrepantiae
            << " discrepantiae inventae sunt, sed aut sex ante patch aut nullae post patch exspectabantur\n";
        return 2;
    }

    std::cerr
        << "REGRESSIO_DISCOVERY_05_DEFECIT: "
        << discrepantiae
        << " discrepantiae normativae ex ordine retrogrado inventae sunt\n";
    return 1;
}
