#include "pastafari/monster.hpp"
#include "pastafari/source_language_catalog.hpp"
#include "tests/reference/normative_reference.hpp"

#include <algorithm>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <map>
#include <set>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

namespace fs = std::filesystem;
using pastafari::reference::Big;

namespace {

void require(bool condition, const std::string& message) {
    if (!condition) {
        throw std::runtime_error(message);
    }
}

std::map<std::string, std::string> readFixture(const fs::path& path) {
    std::ifstream in(path, std::ios::binary);
    if (!in) {
        throw std::runtime_error("fasciculus probationum aperiri non potest");
    }
    std::map<std::string, std::string> data;
    std::string line;
    while (std::getline(in, line)) {
        const auto tab = line.find('\t');
        require(tab != std::string::npos, "linea probationis tabulatorem non habet");
        data.emplace(line.substr(0, tab), line.substr(tab + 1));
    }
    return data;
}

std::string asText(const Big& x) {
    return pastafari::reference::toDecimal(x);
}

void requireFixture(const std::map<std::string, std::string>& f,
                    const std::string& key,
                    const Big& actual) {
    auto it = f.find(key);
    require(it != f.end(), "clavis probationis deest: " + key);
    require(it->second == asText(actual), "valor probationis discrepat: " + key);
}

void requireFixture(const std::map<std::string, std::string>& f,
                    const std::string& key,
                    int actual) {
    auto it = f.find(key);
    require(it != f.end(), "clavis probationis deest: " + key);
    require(it->second == std::to_string(actual), "valor probationis discrepat: " + key);
}

bool containsHebrewUtf8(const std::string& bytes) {
    for (std::size_t i = 0; i + 1 < bytes.size(); ++i) {
        const unsigned char a = static_cast<unsigned char>(bytes[i]);
        const unsigned char b = static_cast<unsigned char>(bytes[i + 1]);
        if (a == 0xD6 && b >= 0x80 && b <= 0xBF) {
            return true;
        }
        if (a == 0xD7 && b >= 0x80 && b <= 0xBF) {
            return true;
        }
    }
    return false;
}

void auditNoHebrew(const fs::path& root) {
    const std::set<std::string> extensions{
        ".hpp", ".cpp", ".md", ".txt", ".tsv"
    };
    for (const auto& entry : fs::recursive_directory_iterator(root)) {
        if (!entry.is_regular_file()) {
            continue;
        }
        if (!extensions.contains(entry.path().extension().string())) {
            continue;
        }
        std::ifstream in(entry.path(), std::ios::binary);
        std::ostringstream buffer;
        buffer << in.rdbuf();
        require(!containsHebrewUtf8(buffer.str()),
                "scriptura Hebraica in fasciculo inventa est: " + entry.path().string());
    }
}

} // namespace

int main(int argc, char** argv) {
    try {
        using namespace pastafari::reference;
        require(argc == 3, "via radicis et fasciculi probationum requiruntur");
        const fs::path root = argv[1];
        const fs::path fixturePath = argv[2];
        const auto fixture = readFixture(fixturePath);

        require(TABLETS_DAY - FOUNDATION_DAY == Big{14777149}, "intervallum tabularum et fundamenti falsum est");
        require(SAVE(1) == 1, "SAVE unius falsum est");
        require(SAVE(M) == M, "SAVE multipli M falsum est");
        require(SAVE(2 * M) == M, "SAVE duplicis M falsum est");
        require(SAVE(M + 1) == 1, "SAVE post M falsum est");
        require(dayCount(FOUNDATION_DAY - 1) == 2, "numerus diei ante fundamentum falsus est");
        require(dayCount(FOUNDATION_DAY) == 1, "numerus diei fundamenti falsus est");
        require(dayCount(FOUNDATION_DAY + 1) == 3, "numerus diei post fundamentum falsus est");

        const auto equalCounts = workCounts(FOUNDATION_DAY, FOUNDATION_DAY);
        require(equalCounts.distance == 1 && equalCounts.direction == 2,
                "casus diei eiusdem falsus est");
        const auto crossCounts = workCounts(FOUNDATION_DAY - 2, FOUNDATION_DAY + 3);
        require(crossCounts.distance == 6 && crossCounts.direction == 3,
                "casus trans fundamentum falsus est");

        const auto p1 = bowlOrderFromNumber(1);
        const auto p720 = bowlOrderFromNumber(720);
        require(p1 == std::array<int, 6>{1, 2, 3, 4, 5, 6}, "permutatio prima falsa est");
        require(p720 == std::array<int, 6>{6, 5, 4, 3, 2, 1}, "permutatio ultima falsa est");

        const AnswerStream shortStream{Big{1}, 1};
        require(chooseRank(shortStream, Big{10}) == 1, "electio brevis simplex falsa est");
        require(chooseRank(AnswerStream{M, -1}, M) == M, "electio brevis in limite falsa est");
        require(chooseRank(AnswerStream{Big{1}, 1}, M + 1) == M + 1, "electio lata simplex falsa est");

        BoundedCompositionFamily toy(9, 2, 4, 5);
        require(toy.count() == 2, "numerus compositionum probationis falsus est");
        require(toy.unrank1(1) == std::vector<int>({4, 5}), "prima compositio falsa est");
        require(toy.unrank1(2) == std::vector<int>({5, 4}), "secunda compositio falsa est");

        require(pastafari::CUTLET_SOURCE_CATALOG.size() == 17, "catalogus segmentorum non septemdecim nomina habet");
        require(pastafari::MONTH_SOURCE_CATALOG.size() == 47, "catalogus mensium non quadraginta septem nomina habet");
        for (std::size_t i = 0; i < pastafari::CUTLET_SOURCE_CATALOG.size(); ++i) {
            require(pastafari::CUTLET_SOURCE_CATALOG[i].canonicalIndex == i + 1,
                    "index canonicus segmenti falsus est");
            require(!pastafari::CUTLET_SOURCE_CATALOG[i].text.empty(), "nomen segmenti vacuum est");
        }
        for (std::size_t i = 0; i < pastafari::MONTH_SOURCE_CATALOG.size(); ++i) {
            require(pastafari::MONTH_SOURCE_CATALOG[i].canonicalIndex == i + 1,
                    "index canonicus mensis falsus est");
            require(!pastafari::MONTH_SOURCE_CATALOG[i].text.empty(), "nomen mensis vacuum est");
        }

        const auto stones = buildStones();
        const auto sauceFoundation = sauce(FOUNDATION_DAY, FOUNDATION_DAY);
        requireFixture(fixture, "save_1", SAVE(1));
        requireFixture(fixture, "save_M_minus_1", SAVE(M - 1));
        requireFixture(fixture, "save_M", SAVE(M));
        requireFixture(fixture, "save_M_plus_1", SAVE(M + 1));
        requireFixture(fixture, "save_2M", SAVE(2 * M));
        requireFixture(fixture, "day_foundation_minus_1", dayCount(FOUNDATION_DAY - 1));
        requireFixture(fixture, "day_foundation", dayCount(FOUNDATION_DAY));
        requireFixture(fixture, "day_foundation_plus_1", dayCount(FOUNDATION_DAY + 1));
        requireFixture(fixture, "counts_action", crossCounts.action);
        requireFixture(fixture, "counts_target", crossCounts.target);
        requireFixture(fixture, "counts_distance", crossCounts.distance);
        requireFixture(fixture, "counts_connection", crossCounts.connection);
        requireFixture(fixture, "counts_direction", crossCounts.direction);
        for (int kind = 0; kind < 5; ++kind) {
            requireFixture(fixture, "stone_2_" + std::to_string(kind + 1), stones[2][kind]);
            requireFixture(fixture, "stone_46_" + std::to_string(kind + 1), stones[46][kind]);
        }
        for (int i = 0; i < 6; ++i) {
            requireFixture(fixture, "sauce_foundation_bowl_" + std::to_string(i + 1), sauceFoundation.bowls[i]);
            requireFixture(fixture, "sauce_foundation_order_" + std::to_string(i + 1), sauceFoundation.orderAtDrop46[i]);
        }
        const auto stream = askBowl(sauceFoundation, 1, SEAL_GATE_GAP);
        requireFixture(fixture, "sauce_foundation_ask_first", stream.first);
        requireFixture(fixture, "sauce_foundation_ask_step", stream.directionStep);

        pastafari::BaseMonsterManager manager;
        const auto reportA = manager.execute(FOUNDATION_DAY, FOUNDATION_DAY);
        const auto reportB = manager.execute(FOUNDATION_DAY + 1, FOUNDATION_DAY + 2);
        require(reportA.phase == "BOOTSTRAP_DONE" && reportA.status == "OK", "structura productionis initialis non viridis est");
        require(reportB.phase == "BOOTSTRAP_DONE" && reportB.status == "OK", "secunda invocatio structurae non viridis est");
        require(reportA.branchCount == 3 && reportB.branchCount == 3, "dispatcher initialis transitum inopinum habet");

        NormativeOracle oracleSmoke;
        const Big gatePlusOne = oracleSmoke.ensureGateIndex(1);
        const Big gateMinusOne = oracleSmoke.ensureGateIndex(-1);
        require(gatePlusOne - FOUNDATION_DAY >= 42 && gatePlusOne - FOUNDATION_DAY <= 963,
                "intervallum portae positivae extra fines est");
        require(FOUNDATION_DAY - gateMinusOne >= 42 && FOUNDATION_DAY - gateMinusOne <= 963,
                "intervallum portae negativae extra fines est");
        const Year anchorSmoke = oracleSmoke.year5000(FOUNDATION_DAY);
        require(anchorSmoke.openGateDay < FOUNDATION_DAY && FOUNDATION_DAY <= anchorSmoke.closeGateDay,
                "annus quinque milium fundamentum non continet");
        require(anchorSmoke.closeGateDay - anchorSmoke.openGateDay >= YEAR_MIN_DAYS
                && anchorSmoke.closeGateDay - anchorSmoke.openGateDay <= YEAR_MAX_DAYS,
                "longitudo anni quinque milium extra fines est");

        auditNoHebrew(root);

        std::cout << "OMNES_PROBATIONES_BOOTSTRAP_TRANSEUNT\n";
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "PROBATIO_DEFECIT: " << e.what() << '\n';
        return 1;
    }
}
