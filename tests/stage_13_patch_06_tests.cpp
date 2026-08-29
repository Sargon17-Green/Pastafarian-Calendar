#include "pastafari/monster.hpp"
#include "tests/reference/normative_reference.hpp"

#include <iostream>

int main() {
    using pastafari::BaseMonsterManager;
    using pastafari::BaseValidationError;
    using pastafari::FOUNDATION_DAY_OLD;
    using pastafari::Integer;
    using pastafari::VisibleDropStore;
    using pastafari::buildHiddenWithBackwardStorage;
    using pastafari::buildStonesThroughLegacyBuilder;
    using pastafari::hiddenByNearness;
    using pastafari::legacyPrior;
    using pastafari::priorPatch;
    using pastafari::reference::buildHiddenDrops;
    using pastafari::reference::buildStones;
    using pastafari::reference::workCounts;

    const Integer calculationDay = FOUNDATION_DAY_OLD + 17;
    const Integer targetDay = FOUNDATION_DAY_OLD + 43;
    const VisibleDropStore visibiles{Integer{101}, Integer{202}, Integer{303}};

    const auto counts = workCounts(calculationDay, targetDay);
    const auto stonesNormativi = buildStones();
    const auto occultaeNormativae = buildHiddenDrops(counts, stonesNormativi);

    const auto stonesProductionis = buildStonesThroughLegacyBuilder();
    const auto occultaeRetrogradae = buildHiddenWithBackwardStorage(
        calculationDay, targetDay, stonesProductionis);

    int defectus = 0;

    for (int back = 1; back <= 7; ++back) {
        bool legacyReiecit = false;
        try {
            static_cast<void>(legacyPrior(visibiles, 1, back));
        } catch (const BaseValidationError&) {
            legacyReiecit = true;
        }
        if (!legacyReiecit) {
            std::cerr
                << "CICATRIX_PRIOR_DELETA back=" << back
                << ": legacyPrior historiam occultam iam intellegit\n";
            ++defectus;
        }

        const Integer directus = priorPatch(
            visibiles, occultaeRetrogradae, 1, back);
        const Integer expectatus = occultaeNormativae[static_cast<std::size_t>(back - 1)];
        if (directus != expectatus) {
            std::cerr
                << "DISCREPANTIA_PRIOR_PATCH_DIRECTA back=" << back
                << ": mapping historiae occultae erravit\n";
            ++defectus;
        }

        if (hiddenByNearness(occultaeRetrogradae, back) != expectatus) {
            std::cerr
                << "DISCREPANTIA_OCCULTAE_EXISTENTIS back=" << back
                << ": cicatrix repositionis retrogradae non congruit accessui 8-k\n";
            ++defectus;
        }
    }

    if (priorPatch(visibiles, occultaeRetrogradae, 4, 1) != 303 ||
        priorPatch(visibiles, occultaeRetrogradae, 4, 2) != 202 ||
        priorPatch(visibiles, occultaeRetrogradae, 4, 3) != 101) {
        std::cerr << "DISCREPANTIA_PRIOR_PATCH_VISIBILIS: via legacy pro slot positivo non servata est\n";
        ++defectus;
    }

    BaseMonsterManager manager;

    const auto visibilis = manager.executePrior(
        calculationDay, targetDay, visibiles, 4, 2);
    if (visibilis.output != 202 ||
        visibilis.legacyOutputBeforePatch != 202 ||
        !visibilis.legacyPathUsed ||
        visibilis.hiddenPathUsed ||
        !visibilis.patch06Applied ||
        visibilis.status != "PATCHED_PRIOR_RESULT_EXPOSED" ||
        visibilis.handler != "Patch06PriorHandler") {
        std::cerr << "DEFECTUS_VIAE_PATCH_06_VISIBILIS: slot positivus per legacy non transiit\n";
        ++defectus;
    }

    for (int back = 1; back <= 7; ++back) {
        const auto report = manager.executePrior(
            calculationDay, targetDay, visibiles, 1, back);
        const Integer expectatus = occultaeNormativae[static_cast<std::size_t>(back - 1)];
        if (report.output != expectatus ||
            report.legacyPathUsed ||
            !report.hiddenPathUsed ||
            !report.patch06Applied ||
            report.status != "PATCHED_PRIOR_RESULT_EXPOSED" ||
            report.handler != "Patch06PriorHandler") {
            std::cerr
                << "DEFECTUS_VIAE_PATCH_06_OCCULTAE back=" << back
                << ": fallback occultus valorem normativum non exposuit\n";
            ++defectus;
        }
    }

    const auto diagnosticum = manager.executeUnpatchedPriorDiagnostic(
        calculationDay, targetDay, visibiles, 4, 2);
    if (diagnosticum.output != 202 ||
        diagnosticum.patch06Applied ||
        diagnosticum.hiddenPathUsed ||
        diagnosticum.status != "LEGACY_PRIOR_VISIBLE_RESULT_EXPOSED" ||
        diagnosticum.handler != "Discovery06PriorHandler") {
        std::cerr << "DEFECTUS_DIAGNOSTICI_PRIOR: via legacy visibilis non integra mansit\n";
        ++defectus;
    }

    bool diagnosticumOccultumReiecit = false;
    try {
        static_cast<void>(manager.executeUnpatchedPriorDiagnostic(
            calculationDay, targetDay, visibiles, 1, 1));
    } catch (const BaseValidationError&) {
        diagnosticumOccultumReiecit = true;
    }
    if (!diagnosticumOccultumReiecit) {
        std::cerr << "CICATRIX_DIAGNOSTICA_DELETA: via legacy occulta non iam deficit\n";
        ++defectus;
    }

    bool ultraSeptemReiectum = false;
    try {
        static_cast<void>(priorPatch(visibiles, occultaeRetrogradae, 1, 8));
    } catch (const BaseValidationError&) {
        ultraSeptemReiectum = true;
    }
    if (!ultraSeptemReiectum) {
        std::cerr << "DEFECTUS_LIMINIS_PATCH_06: hiddenK octavus non reiectus est\n";
        ++defectus;
    }

    if (defectus != 0) {
        std::cerr
            << "REGRESSIO_PATCH_06_DEFECIT: "
            << defectus
            << " defectus inventi sunt\n";
        return 1;
    }

    std::cout << "REGRESSIO_PATCH_06_TRANSIIT\n";
    return 0;
}
