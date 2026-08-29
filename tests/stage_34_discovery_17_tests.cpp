#include "pastafari/monster.hpp"

#include <algorithm>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

using pastafari::BaseMonsterManager;
using pastafari::Integer;
using pastafari::LegacyYearCandidate;
using pastafari::LegacyYearCandidateList;
using pastafari::LegacyYearCandidatePair;
using pastafari::legacyYear5000TiePreparation;

static void require(bool condicio, const std::string& nuntius) {
    if (!condicio) {
        throw std::runtime_error(nuntius);
    }
}

static std::string indices(const LegacyYearCandidateList& candidates) {
    std::string out;
    for (std::size_t i = 0; i < candidates.size(); ++i) {
        if (i != 0) out += ",";
        out += std::to_string(candidates[i].openIndex);
    }
    return out;
}

static LegacyYearCandidateList normativumTieSort(
    const std::vector<Integer>& gates,
    const LegacyYearCandidateList& input) {
    LegacyYearCandidateList out = input;
    std::size_t begin = 0;
    while (begin < out.size()) {
        std::size_t end = begin + 1;
        while (end < out.size() && out[end].length == out[begin].length) {
            ++end;
        }
        std::stable_sort(
            out.begin() + static_cast<std::ptrdiff_t>(begin),
            out.begin() + static_cast<std::ptrdiff_t>(end),
            [&](const LegacyYearCandidate& a, const LegacyYearCandidate& b) {
                return gates[a.openIndex] < gates[b.openIndex];
            });
        begin = end;
    }
    return out;
}

int main() {
    try {
        const Integer basis = pastafari::FOUNDATION_DAY_OLD;
        std::vector<Integer> gates;
        for (int i = 0; i <= 10; ++i) {
            gates.push_back(basis + Integer{50 * i});
        }
        const Integer calculationDay = basis + 225;
        const std::vector<LegacyYearCandidatePair> pairs{
            {4, 10},
            {0, 6},
            {2, 8}
        };

        const auto direct = legacyYear5000TiePreparation(gates, pairs, calculationDay);
        require(direct.preSort.size() == 3 && direct.sorted.size() == 3,
                "familia tie year 5000 trium candidatorum non est");
        require(indices(direct.preSort) == "4,0,2",
                "ordo inputuum tie ante sortem legacy mutatus est");
        require(indices(direct.sorted) == "4,0,2",
                "stable sort legacy per longitudinem solam cicatricem non servat");
        for (const auto& candidate : direct.sorted) {
            require(candidate.length == 300,
                    "run tie year 5000 longitudinem communem 300 non habet");
            require(gates[candidate.openIndex] < calculationDay &&
                    calculationDay <= gates[candidate.closeIndex],
                    "candidatus tie diem calculationis non continet");
        }

        const LegacyYearCandidateList normative = normativumTieSort(gates, direct.sorted);
        require(indices(normative) == "0,2,4",
                "ordo normativus opening gate pro probe tie inexpectatus est");

        const BaseMonsterManager manager;
        const auto report = manager.executeLegacyYear5000TieDiscovery(
            calculationDay,
            calculationDay,
            gates,
            pairs,
            1,
            10);
        require(report.discovery17Ready, "DISCOVERY 17 non paratus est");
        require(report.selectionCalled && report.selectionFamilySize == 3,
                "selectio year 5000 familiam trium non accepit");
        require(indices(report.preSort) == "4,0,2",
                "familia activa ante sortem tie mutata est");

        int discrepantiae = 0;
        for (std::size_t i = 0; i < normative.size(); ++i) {
            if (report.sorted[i].openIndex != normative[i].openIndex ||
                report.sorted[i].closeIndex != normative[i].closeIndex ||
                report.sorted[i].length != normative[i].length) {
                ++discrepantiae;
                std::cout << "DISCREPANTIA_TIE_YEAR_5000 positio=" << (i + 1)
                          << " opening_expectatus=" << normative[i].openIndex
                          << " opening_actualis=" << report.sorted[i].openIndex
                          << " longitudo=" << report.sorted[i].length << "\n";
            }
        }

        std::cout << "CALCULATION_DAY=" << calculationDay << "\n";
        std::cout << "ORDO_INPUT=" << indices(report.preSort) << "\n";
        std::cout << "ORDO_ACTIVUS=" << indices(report.sorted) << "\n";
        std::cout << "ORDO_NORMATIVUS_OPENING_GATE=" << indices(normative) << "\n";
        std::cout << "FAMILIA_SELECTIONIS=" << report.selectionFamilySize << "\n";

        if (discrepantiae == 0) {
            std::cout << "REGRESSIO_DISCOVERY_17_TRANSIIT\n";
            return 0;
        }
        if (discrepantiae == 3) {
            std::cout << "REGRESSIO_DISCOVERY_17_DEFECIT: "
                         "3 positiones run aequalis longitudinis ordinem inputuum legacy servant "
                         "loco opening gate maturioris\n";
            return 1;
        }
        std::cerr << "REGRESSIO_DISCOVERY_17_INEXPECTATA: discrepantiae="
                  << discrepantiae << "\n";
        return 2;
    } catch (const std::exception& error) {
        std::cerr << "REGRESSIO_DISCOVERY_17_ERROR: " << error.what() << "\n";
        return 3;
    }
}
