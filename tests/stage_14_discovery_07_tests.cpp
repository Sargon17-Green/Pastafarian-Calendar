#include "pastafari/monster.hpp"

#include <array>
#include <iostream>
#include <string>

namespace {

using pastafari::GrindStoneKind;
using pastafari::VisibleGrindRow;

bool idem(const VisibleGrindRow& a, const VisibleGrindRow& b) {
    return a.kind == b.kind && a.a == b.a && a.b == b.b && a.c == b.c && a.d == b.d;
}

std::string nomen(GrindStoneKind kind) {
    switch (kind) {
        case GrindStoneKind::WHEAT: return "WHEAT";
        case GrindStoneKind::BARLEY: return "BARLEY";
        case GrindStoneKind::SALT: return "SALT";
        case GrindStoneKind::BITTER: return "BITTER";
        case GrindStoneKind::RED: return "RED";
    }
    return "IGNOTUM";
}

void imprime(const VisibleGrindRow& row) {
    std::cerr << nomen(row.kind)
              << ',' << row.a
              << ',' << row.b
              << ',' << row.c
              << ',' << row.d;
}

} // namespace

int main() {
    using pastafari::BaseMonsterManager;
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

    if (legacyVisibleGrindTableZeroBased().size() != 11) {
        std::cerr << "FORMA_LEGACY_INOPINATA: tabula undecim ordines reales continere debet\n";
        return 2;
    }

    const auto prima = legacyGrindRow(1);
    const auto decima = legacyGrindRow(10);
    const auto undecima = legacyGrindRow(11);
    if (!prima.found || prima.physicalIndex != 1 || !idem(prima.row, normativae[1]) ||
        !decima.found || decima.physicalIndex != 10 || !idem(decima.row, normativae[10]) ||
        undecima.found || undecima.physicalIndex != 11) {
        std::cerr << "FORMA_LEGACY_INOPINATA: caller one-based displacementem historicam non servat\n";
        return 2;
    }

    BaseMonsterManager manager;
    int discrepantiae = 0;

    for (int grind = 1; grind <= 11; ++grind) {
        const auto report = manager.executeGrindRow(grind);
        const auto& expectatus = normativae[static_cast<std::size_t>(grind - 1)];

        if (report.grind != grind || report.physicalIndex != grind || report.branchCount < 4) {
            std::cerr << "DEFECTUS_VIAE_MOLITIONIS grind=" << grind << "\n";
            return 2;
        }

        if (!report.found || !idem(report.output, expectatus)) {
            std::cerr << "DISCREPANTIA MOLITIONIS grind=" << grind << " expectatus=";
            imprime(expectatus);
            std::cerr << " actualis=";
            if (report.found) {
                imprime(report.output);
            } else {
                std::cerr << "ABSENS";
            }
            std::cerr << " index_physicus=" << report.physicalIndex << '\n';
            ++discrepantiae;
        } else {
            std::cout << "CONCORDANTIA MOLITIONIS grind=" << grind << '\n';
        }
    }

    if (discrepantiae == 0) {
        std::cout << "REGRESSIO_DISCOVERY_07_TRANSIIT\n";
        return 0;
    }

    if (discrepantiae == 11) {
        std::cerr
            << "REGRESSIO_DISCOVERY_07_DEFECIT: 11 discrepantiae normativae ex indice one-based directo inventae sunt\n";
        return 1;
    }

    std::cerr
        << "REGRESSIO_DISCOVERY_07_INOPINATE_DEFECIT: "
        << discrepantiae
        << " discrepantiae inventae sunt; undecim exspectabantur\n";
    return 2;
}
