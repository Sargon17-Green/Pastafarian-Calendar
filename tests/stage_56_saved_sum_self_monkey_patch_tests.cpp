#include "pastafari/monster.hpp"

#include <array>
#include <fstream>
#include <iostream>
#include <sstream>
#include <stdexcept>
#include <string>

using pastafari::BowlState;
using pastafari::Integer;
using pastafari::PermutationOrder;
using pastafari::Stage56PostStirDetourWitness;

namespace {
void require(bool ok, const std::string& message) {
    if (!ok) throw std::runtime_error(message);
}

BowlState formula(const BowlState& old, int stir, bool useRawInsideU,
                  Integer& rawOut, Integer& savedOut, PermutationOrder& orderOut) {
    Integer raw = 0;
    for (const Integer& bowl : old) raw += bowl;
    const Integer saved = pastafari::savePatch(raw + 149 * stir);
    const int oneBased =
        (pastafari::regularMod(saved - 1, Integer{720}) + 1).convert_to<int>();
    const PermutationOrder order = pastafari::oldPermutationUnrank0(oneBased - 1);
    BowlState next = old;
    for (int position = 1; position <= 6; ++position) {
        const std::size_t pos = static_cast<std::size_t>(position - 1);
        const std::size_t prevPos = static_cast<std::size_t>((position + 4) % 6);
        const std::size_t nextPos = static_cast<std::size_t>(position % 6);
        const int id = order[pos];
        const int prev = order[prevPos];
        const int following = order[nextPos];
        const Integer operand = useRawInsideU ? raw : saved;
        const Integer u = old[static_cast<std::size_t>(id - 1)]
                        + 3 * old[static_cast<std::size_t>(prev - 1)]
                        + 5 * old[static_cast<std::size_t>(following - 1)]
                        + operand + stir + position * position;
        next[static_cast<std::size_t>(id - 1)] = pastafari::savePatch(
            u * u + 7 * old[static_cast<std::size_t>(prev - 1)]
                * old[static_cast<std::size_t>(following - 1)]);
    }
    rawOut = raw; savedOut = saved; orderOut = order;
    return next;
}

void requirePhysicalMonkeyScar() {
    std::ifstream in("src/monster.cpp");
    require(static_cast<bool>(in), "src/monster.cpp aperiri non potest");
    std::ostringstream ss; ss << in.rdbuf();
    const std::string source = ss.str();
    require(source.find("stage56SelfEatingDispatchSlot") != std::string::npos,
            "slot self-eating physice non inventus est");
    require(source.find("whatWasHereBeforeTheMonkeyAteIt") != std::string::npos,
            "cicatrix simiae physice non inventa est");
    require(source.find(".exchange(") != std::string::npos,
            "monkey patch atomicum physice non inventum est");
    require(source.find("stage56RawSumSacrificeNobodyMayReturn") != std::string::npos,
            "mutans sacrificialis physice non servatus est");
    require(source.find("return stage56RawBowlSumPostStirDetour(oldBowls, stirIndex);") != std::string::npos,
            "bootstrap se ipsam post rescriptionem non revocat");
}
} // namespace

int main() {
    try {
        const BowlState discriminator{{Integer{1},Integer{2},Integer{3},Integer{4},Integer{5},Integer{6}}};
        Integer raw{}, saved{}; PermutationOrder order{};
        const BowlState canonical = formula(discriminator,1,false,raw,saved,order);
        Integer raw2{}, saved2{}; PermutationOrder order2{};
        const BowlState rawSumMutant = formula(discriminator,1,true,raw2,saved2,order2);
        require(raw == Integer{21}, "S discriminatoris non est 21");
        require(saved == Integer{170}, "R discriminatoris non est 170");
        require(canonical != rawSumMutant, "discriminator mutantem raw-sum non interficit");

        const Stage56PostStirDetourWitness first =
            pastafari::stage56RawBowlSumPostStirDetour(discriminator,1);
        require(first.correctedResult == canonical, "prima vocatio saved-sum non reddidit");
        require(first.correctedResult != rawSumMutant, "prima vocatio mutantem raw-sum effugere sivit");
        require(first.oldResult == first.correctedResult,
                "post monkey patch duo campi semantici congruere debent");

        const Stage56PostStirDetourWitness second =
            pastafari::stage56RawBowlSumPostStirDetour(discriminator,1);
        require(second.correctedResult == canonical, "secunda vocatio post patch saved-sum amisit");
        require(second.correctedResult != rawSumMutant, "secunda vocatio ad raw-sum regressa est");
        requirePhysicalMonkeyScar();

        std::cout << "PASS self-eating saved-sum monkey patch\n"
                  << "S=21 R=170\n"
                  << "canonical=[43348,43821,49771,36114,57684,55801]\n"
                  << "rawSumMutant=[3565,3740,5518,1695,8365,7674]\n";
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "FAIL: " << e.what() << "\n";
        return 1;
    }
}
