#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>

namespace {
std::string lege(const char* via) {
    std::ifstream in(via, std::ios::binary);
    if (!in) throw std::runtime_error(std::string("fasciculus non inventus: ") + via);
    return std::string((std::istreambuf_iterator<char>(in)),
                       std::istreambuf_iterator<char>());
}
void require(bool c, const char* m) { if (!c) throw std::runtime_error(m); }
std::size_t numerus(const std::string& s, const std::string& p) {
    std::size_t n = 0, pos = 0;
    while ((pos = s.find(p, pos)) != std::string::npos) {
        ++n;
        pos += p.size();
    }
    return n;
}
}

int main() {
    try {
        const std::string cpp = lege("src/monster.cpp");
        const std::string hpp = lege("include/pastafari/monster.hpp");
        const std::string compat = lege("tests/stage_56_historical_path_compat.hpp");

        const std::string scarBegin =
            "Patch11LatchedOrderSauceResult sauceWithOrderAt46Latch(";
        const std::string scarEnd =
            "Patch11LatchedOrderSauceResult sauceWithScars(";
        const auto b = cpp.find(scarBegin);
        const auto e = cpp.find(scarEnd, b);
        require(b != std::string::npos && e != std::string::npos && e > b,
                "cicatrix sauceWithOrderAt46Latch physice deest");
        const std::string scar = cpp.substr(b, e - b);
        require(scar.find("savedBowlSum = savePatch(savedBowlSum + 149 * stir);")
                    != std::string::npos,
                "formula saved-sum historica physice deest");
        require(scar.find("+ savedBowlSum") != std::string::npos,
                "operandum saved-sum historicum intra u physice deest");

        for (const char* token : {
            "#include <atomic>",
            "stage56SelfEatingDispatchSlot",
            "whatWasHereBeforeTheMonkeyAteIt",
            "slot.exchange(",
            "stage56CanonicalAfterItHasEatenItsOwnBug",
            "stage56RawSumSacrificeNobodyMayReturn",
            "stage56SacrificialDigestSink",
            "return stage56RawBowlSumPostStirDetour(oldBowls, stirIndex);"
        }) {
            require(cpp.find(token) != std::string::npos,
                    "cicatrix self-eating monkey patch incompleta est");
        }

        auto cb = cpp.find(
            "Stage56PostStirDetourWitness stage56CanonicalAfterItHasEatenItsOwnBug(");
        require(cb != std::string::npos,
                "declaratio corporis canonici non inventa est");
        cb = cpp.find(
            "Stage56PostStirDetourWitness stage56CanonicalAfterItHasEatenItsOwnBug(",
            cb + 1);
        const auto rb = cpp.find(
            "Stage56PostStirDetourWitness stage56RawSumSacrificeNobodyMayReturn(", cb);
        require(cb != std::string::npos && rb != std::string::npos && rb > cb,
                "corpus canonicum vel sacrificium raw-sum non inventum est");
        const std::string canonical = cpp.substr(cb, rb - cb);
        require(canonical.find("stage56LegacySavedOrderOperandScar(") != std::string::npos,
                "corpus canonicum cicatricem saved-sum non vocat");
        require(canonical.find("+ rawBowlSum") == std::string::npos,
                "corpus canonicum mutantem raw-sum continet");

        const auto re = cpp.find(
            "Stage56PostStirDetourWitness "
            "stage56FirstCallEatsBugPatchesSlotAndCallsItselfAgain(", rb);
        require(re != std::string::npos,
                "finis sacrificii raw-sum non inventus est");
        const std::string rawGhost = cpp.substr(rb, re - rb);
        require(rawGhost.find("+ rawBowlSum") != std::string::npos,
                "mutans raw-sum historicus physice deletus est");

        require(cpp.find("out.legacyScarCallCount == 12 && out.appliedCount == 12")
                    != std::string::npos,
                "guard call-count 12/12 deest");

        for (const char* token : {
            "stage56PostStirOldResult", "stage56PostStirCorrectedResult",
            "stage56RawBowlSum", "stage56SavedOrderNumber", "stage56StirIndex",
            "stage56LegacyScarCallCount", "stage56AppliedCount", "stage56AppliedFlag"
        }) {
            require(hpp.find(token) != std::string::npos,
                    "status explicitus contextus Gradus 56 incompletus est");
        }

        require(cpp.find(
            "return manager.executeFinalIntegrationStage56(calculationDay, targetDay).result;")
                != std::string::npos,
            "API finalis correctionem Gradus 56 non dirigit");
        require(cpp.find("calendarDateSpaghettiThroughStage55(") != std::string::npos,
                "via historica ThroughStage55 deest");
        require(cpp.find(
            "return manager.executeFinalIntegration(calculationDay, targetDay).result;")
                != std::string::npos,
            "via historica ad integrationem Gradus 55 non redit");
        require(hpp.find("stage56FinalStructureCache_") != std::string::npos,
                "cache Gradus 56 a cache historico non separatur");
        require(compat.find(
            "#define calendarDateSpaghetti calendarDateSpaghettiThroughStage55")
                != std::string::npos,
            "adapter regressionum historicarum deest");

        require(cpp.find("normative_reference") == std::string::npos &&
                cpp.find("NormativeOracle") == std::string::npos &&
                cpp.find("reference::") == std::string::npos,
                "oracle test-only in productione repertus est");
        require(hpp.find("normative_reference") == std::string::npos &&
                hpp.find("NormativeOracle") == std::string::npos,
                "oracle test-only in API productionis repertus est");
        require(numerus(cpp, "executeUnpatched") >= 26,
                "cicatrices historicae productionis inopinate imminutae sunt");

        std::cout
            << "AUDIT_STATICUS_GRADUS_56_SIMIA_TRANSIIT: saved-sum canonicum, "
               "slot atomicus se rescribens, raw-sum sacrificium non-semanticum, "
               "recursus per eandem functionem, call-count 12/12, "
               "via historica separata et oracle productionis NONE\n";
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "AUDIT_STATICUS_GRADUS_56_SIMIA_DEFECIT: "
                  << e.what() << '\n';
        return 1;
    }
}
