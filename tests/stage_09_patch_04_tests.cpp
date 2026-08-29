#include "pastafari/monster.hpp"
#include "tests/reference/normative_reference.hpp"

#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

namespace {

std::string legeTotum(const std::string& via) {
    std::ifstream in(via);
    if (!in) {
        return {};
    }
    std::ostringstream out;
    out << in.rdbuf();
    return out.str();
}

} // spatium nominum

int main() {
    using pastafari::BaseMonsterManager;
    using pastafari::Integer;
    using pastafari::Stone;
    using pastafari::StoneTable;
    using pastafari::buildStonesThroughLegacyBuilder;
    using pastafari::buildStonesThroughWrongLegacyMutation;
    using pastafari::mutateStonesWrong;
    using pastafari::stonePatch;
    using pastafari::reference::buildStones;

    int defectus = 0;

    const Stone initium{Integer{17}, Integer{29}, Integer{43}, Integer{71}, Integer{101}};
    const Stone legacySecundus = mutateStonesWrong(2, initium);
    const Stone reparatusSecundus = stonePatch(2, initium);
    const auto normativa = buildStones();

    if (legacySecundus == normativa[2]) {
        std::cerr << "CICATRIX_MUTATIONIS_SEQUENTIALIS_DELETA_EST\n";
        ++defectus;
    }
    if (reparatusSecundus != normativa[2]) {
        std::cerr << "STONE_PATCH_LAPIDEM_SECUNDUM_NON_REPARAVIT\n";
        ++defectus;
    }

    const StoneTable legacyDirecta = buildStonesThroughWrongLegacyMutation();
    const StoneTable reparataDirecta = buildStonesThroughLegacyBuilder();
    if (legacyDirecta == reparataDirecta) {
        std::cerr << "BUILDER_LEGACY_ET_BUILDER_REPARATUS_INOPINATE_CONCORDANT\n";
        ++defectus;
    }

    for (int i = 1; i <= 46; ++i) {
        if (reparataDirecta[i] != normativa[i]) {
            std::cerr << "BUILDER_REPARATUS_A_NORMA_DISCREPAT_IN_LAPIDE " << i << "\n";
            ++defectus;
            break;
        }
    }

    BaseMonsterManager manager;
    const auto report = manager.executeStoneTable();
    if (!report.patch04Applied ||
        report.status != "PATCHED_STONE_TABLE_EXPOSED" ||
        report.handler != "Patch04StoneMutationHandler") {
        std::cerr << "VIA_PATCH_04_STATUS_INVALIDUS\n";
        ++defectus;
    }
    if (report.output != reparataDirecta) {
        std::cerr << "VIA_PATCH_04_BUILDER_REPARATUM_NON_EXPOSUIT\n";
        ++defectus;
    }
    if (report.legacyOutput != legacyDirecta) {
        std::cerr << "VIA_PATCH_04_CICATRICEM_LEGACY_NON_SERVAVIT\n";
        ++defectus;
    }

    const auto diagnosticum = manager.executeUnpatchedStoneTableDiagnostic();
    if (diagnosticum.patch04Applied ||
        diagnosticum.output != legacyDirecta ||
        diagnosticum.status != "LEGACY_STONE_TABLE_EXPOSED" ||
        diagnosticum.handler != "Discovery04StoneMutationHandler") {
        std::cerr << "VIA_DIAGNOSTICA_LEGACY_INVALIDA\n";
        ++defectus;
    }

    const std::string fons = legeTotum("src/monster.cpp");
    if (fons.empty()) {
        std::cerr << "FONS_MONSTRI_NON_LEGI_POTUIT\n";
        ++defectus;
    } else {
        if (fons.find("const Stone old = state;") == std::string::npos ||
            fons.find("Stone garbage = mutateStonesWrong(i, state);") == std::string::npos) {
            std::cerr << "VOCATIO_LEGACY_SUPER_STATUM_CLONATUM_NON_APPARET\n";
            ++defectus;
        }
        if (fons.find("garbage[0] = savePatch(old[0] * old[0]") == std::string::npos ||
            fons.find("garbage[4] = savePatch(old[4] * old[4]") == std::string::npos) {
            std::cerr << "OVERWRITE_QUINQUE_PARTIUM_EX_SNAPSHOT_NON_APPARET\n";
            ++defectus;
        }
    }

    if (defectus != 0) {
        std::cerr << "REGRESSIO_PATCH_04_DEFECIT: " << defectus << " defectus inventi sunt\n";
        return 1;
    }

    std::cout << "REGRESSIO_PATCH_04_TRANSIIT\n";
    return 0;
}
