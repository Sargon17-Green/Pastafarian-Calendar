#include "pastafari/monster.hpp"

#include <array>
#include <iostream>

namespace {

using pastafari::GrindStoneKind;
using pastafari::VisibleGrindRow;

bool idem(const VisibleGrindRow& a, const VisibleGrindRow& b) {
    return a.kind == b.kind && a.a == b.a && a.b == b.b && a.c == b.c && a.d == b.d;
}

} // namespace

int main() {
    using pastafari::BaseMonsterManager;
    using pastafari::grindTableWithSentinel;
    using pastafari::legacyGrindRow;
    using pastafari::legacyVisibleGrindTableZeroBased;

    const std::array<VisibleGrindRow, 11> normativae{{
        {GrindStoneKind::WHEAT, 3, 5, 7, 11},
        {GrindStoneKind::BARLEY, 5, 7, 11, 13},
        {GrindStoneKind::SALT, 7, 11, 13, 17},
        {GrindStoneKind::BITTER, 11, 13, 17, 19},
        {GrindStoneKind::RED, 13, 17, 19, 23},
        {GrindStoneKind::WHEAT, 17, 19, 23, 29},
        {GrindStoneKind::BARLEY, 19, 23, 29, 31},
        {GrindStoneKind::SALT, 23, 29, 31, 37},
        {GrindStoneKind::BITTER, 29, 31, 37, 41},
        {GrindStoneKind::RED, 31, 37, 41, 43},
        {GrindStoneKind::WHEAT, 37, 41, 43, 47},
    }};

    int defectus = 0;
    const auto& tabula = grindTableWithSentinel();
    if (tabula.size() != 12 || tabula[0].kind != GrindStoneKind::NONE ||
        tabula[0].a != 0 || tabula[0].b != 0 || tabula[0].c != 0 || tabula[0].d != 0) {
        std::cerr << "SENTINELLA_MOLITIONIS_INVALIDA\n";
        ++defectus;
    }

    for (int grind = 1; grind <= 11; ++grind) {
        if (!idem(tabula[static_cast<std::size_t>(grind)], normativae[static_cast<std::size_t>(grind - 1)])) {
            std::cerr << "ORDO_POST_SENTINELLAM_INVALIDUS grind=" << grind << '\n';
            ++defectus;
        }
    }

    if (legacyVisibleGrindTableZeroBased().size() != 11) {
        std::cerr << "CICATRIX_TABULAE_LEGACY_DELETA\n";
        ++defectus;
    }
    const auto legacy1 = legacyGrindRow(1);
    const auto legacy11 = legacyGrindRow(11);
    if (!legacy1.found || idem(legacy1.row, normativae[0]) || legacy11.found) {
        std::cerr << "CICATRIX_INDICIS_LEGACY_DELETA\n";
        ++defectus;
    }

    BaseMonsterManager manager;
    for (int grind = 1; grind <= 11; ++grind) {
        const auto report = manager.executeGrindRow(grind);
        if (!report.found || !report.patch07Applied || report.physicalIndex != grind ||
            !idem(report.output, normativae[static_cast<std::size_t>(grind - 1)])) {
            std::cerr << "DISCREPANTIA_PATCH_07 grind=" << grind << '\n';
            ++defectus;
        }
        const auto diagnostic = manager.executeUnpatchedGrindDiagnostic(grind);
        const auto legacy = legacyGrindRow(grind);
        if (diagnostic.patch07Applied || diagnostic.found != legacy.found ||
            diagnostic.physicalIndex != legacy.physicalIndex ||
            (legacy.found && !idem(diagnostic.output, legacy.row))) {
            std::cerr << "DIAGNOSTICUM_LEGACY_INVALIDUM grind=" << grind << '\n';
            ++defectus;
        }
    }

    if (defectus != 0) {
        std::cerr << "REGRESSIO_PATCH_07_DEFECIT: " << defectus << " defectus inventi sunt\n";
        return 1;
    }

    std::cout << "REGRESSIO_PATCH_07_TRANSIIT\n";
    return 0;
}
