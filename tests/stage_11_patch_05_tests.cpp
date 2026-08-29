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
    using pastafari::BaseValidationError;
    using pastafari::FOUNDATION_DAY_OLD;
    using pastafari::Integer;
    using pastafari::buildHiddenWithBackwardStorage;
    using pastafari::buildStonesThroughLegacyBuilder;
    using pastafari::hiddenByNearness;
    using pastafari::reference::buildHiddenDrops;
    using pastafari::reference::buildStones;
    using pastafari::reference::workCounts;

    const Integer calculationDay = FOUNDATION_DAY_OLD + 17;
    const Integer targetDay = FOUNDATION_DAY_OLD + 43;

    const auto counts = workCounts(calculationDay, targetDay);
    const auto stonesNormativi = buildStones();
    const auto expectatae = buildHiddenDrops(counts, stonesNormativi);
    const auto stonesProductionis = buildStonesThroughLegacyBuilder();
    const auto backward = buildHiddenWithBackwardStorage(
        calculationDay, targetDay, stonesProductionis);

    int defectus = 0;

    for (int k = 1; k <= 7; ++k) {
        const std::size_t normalis = static_cast<std::size_t>(k - 1);
        const std::size_t retro = static_cast<std::size_t>(7 - k);

        if (backward[retro] != expectatae[normalis]) {
            std::cerr
                << "CICATRIX_RETROGRADA_CORRUPTA k=" << k
                << ": expectatus=" << decimal(expectatae[normalis])
                << " actualis=" << decimal(backward[retro])
                << "\n";
            ++defectus;
        }

        const Integer perAccessum = hiddenByNearness(backward, k);
        if (perAccessum != expectatae[normalis]) {
            std::cerr
                << "DISCREPANTIA ACCESSUS_OCTO_MINUS_K k=" << k
                << ": expectatus=" << decimal(expectatae[normalis])
                << " actualis=" << decimal(perAccessum)
                << "\n";
            ++defectus;
        }
    }

    bool indexInferiorReiectus = false;
    bool indexSuperiorReiectus = false;
    try {
        static_cast<void>(hiddenByNearness(backward, 0));
    } catch (const BaseValidationError&) {
        indexInferiorReiectus = true;
    }
    try {
        static_cast<void>(hiddenByNearness(backward, 8));
    } catch (const BaseValidationError&) {
        indexSuperiorReiectus = true;
    }
    if (!indexInferiorReiectus || !indexSuperiorReiectus) {
        std::cerr << "DEFECTUS_VALIDATIONIS_ACCESSUS: indices extra 1..7 non ambo reiecti sunt\n";
        ++defectus;
    }

    BaseMonsterManager manager;
    const auto report = manager.executeHiddenDrops(calculationDay, targetDay);
    const auto diagnosticum = manager.executeUnpatchedHiddenStorageDiagnostic(
        calculationDay, targetDay);

    if (!report.patch05Applied ||
        report.status != "PATCHED_HIDDEN_NEARNESS_EXPOSED" ||
        report.handler != "Patch05HiddenStorageHandler") {
        std::cerr << "DEFECTUS_VIAE_PATCH_05: status vel signum emendationis invalidum est\n";
        ++defectus;
    }

    int discrepantiaeLegacy = 0;
    for (int k = 1; k <= 7; ++k) {
        const std::size_t normalis = static_cast<std::size_t>(k - 1);
        const std::size_t retro = static_cast<std::size_t>(7 - k);

        if (report.output[normalis] != expectatae[normalis]) {
            std::cerr
                << "DISCREPANTIA VIAE_PATCH_05 k=" << k
                << ": expectatus=" << decimal(expectatae[normalis])
                << " actualis=" << decimal(report.output[normalis])
                << "\n";
            ++defectus;
        }
        if (report.legacyOutput[retro] != expectatae[normalis]) {
            std::cerr << "CICATRIX_REPORTI_RETROGRADA_CORRUPTA k=" << k << "\n";
            ++defectus;
        }
        if (diagnosticum.output[normalis] != expectatae[normalis]) {
            ++discrepantiaeLegacy;
        }
    }

    if (diagnosticum.patch05Applied || discrepantiaeLegacy != 6) {
        std::cerr
            << "DEFECTUS_DIAGNOSTICI_LEGACY: exspectatae sunt sex discrepantiae sine patch, inventae="
            << discrepantiaeLegacy
            << "\n";
        ++defectus;
    }

    if (defectus != 0) {
        std::cerr
            << "REGRESSIO_PATCH_05_DEFECIT: "
            << defectus
            << " defectus inventi sunt\n";
        return 1;
    }

    std::cout << "REGRESSIO_PATCH_05_TRANSIIT\n";
    return 0;
}
