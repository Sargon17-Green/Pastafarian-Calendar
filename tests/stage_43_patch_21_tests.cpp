#include "pastafari/monster.hpp"
#include "reference/normative_reference.hpp"

#include <algorithm>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

using pastafari::BaseMonsterContext;
using pastafari::BaseMonsterManager;
using pastafari::CutletPartitionPatchWrapper;
using pastafari::Integer;
using pastafari::LegacyAnswerRing;
using pastafari::LegacyBiasedSelectionAdapter;
using pastafari::LegacyYearAnchor;
using pastafari::Patch13RejectionWrapper;
using pastafari::Patch14WideDetourWrapper;
using pastafari::reference::NormativeOracle;
using pastafari::reference::SauceResult;
using pastafari::reference::Year;

static void require(bool condition, const std::string& message) {
    if (!condition) throw std::runtime_error(message);
}

static bool hitsBoundary(const std::vector<int>& partition, int offset) {
    int cumulative = 0;
    for (const int part : partition) {
        cumulative += part;
        if (cumulative == offset) return true;
    }
    return false;
}

static std::string integerList(const std::vector<int>& values) {
    std::string out = "[";
    for (std::size_t i = 0; i < values.size(); ++i) {
        if (i != 0) out += ",";
        out += std::to_string(values[i]);
    }
    return out + "]";
}

static std::vector<std::vector<int>> filteredLegacyMaterialization(
    int gapCount,
    int cutletCount,
    int internalGateOffset) {
    const auto legacy = pastafari::legacyPositiveCompositions(gapCount, cutletCount);
    const unsigned long long count = legacy.count.convert_to<unsigned long long>();
    std::vector<std::vector<int>> out;
    for (unsigned long long ordinal = 1; ordinal <= count; ++ordinal) {
        const auto candidate = pastafari::legacyPositiveCompositionUnrank(
            legacy,
            Integer{ordinal});
        if (hitsBoundary(candidate, internalGateOffset)) {
            out.push_back(candidate);
        }
    }
    return out;
}

static void requireFilteredFamilyIsExactLegacySubsequence() {
    for (int gapCount = 4; gapCount <= 11; ++gapCount) {
        const int maxCutlets = std::min(gapCount, 6);
        for (int cutletCount = 2; cutletCount <= maxCutlets; ++cutletCount) {
            for (int offset = 1; offset < gapCount; ++offset) {
                const auto expected = filteredLegacyMaterialization(
                    gapCount,
                    cutletCount,
                    offset);
                require(!expected.empty(),
                        "familia testis filtrata vacua esse non debet");
                const auto family = pastafari::filteredLegacyPositiveCompositions(
                    gapCount,
                    cutletCount,
                    offset,
                    true);
                require(family.count == Integer{expected.size()},
                        "numerus familiae filtratae a subsequencia legacy differt");
                for (std::size_t i = 0; i < expected.size(); ++i) {
                    const auto actual = pastafari::filteredLegacyPositiveCompositionUnrank(
                        family,
                        Integer{i + 1});
                    require(actual == expected[i],
                            "ordo lexicographicus familiae filtratae mutatus est");
                }
            }
        }
    }
}

static void requireNoInternalGatePassesLegacyThrough() {
    BaseMonsterContext ctx;
    ctx.discovery21GapCount = 9;
    ctx.discovery21CutletCount = 6;
    ctx.discovery21InternalGateOffset = 0;
    ctx.discovery21CalculationDayIsInternalGate = false;
    ctx.discovery21LegacyFamily = pastafari::legacyPositiveCompositions(9, 6);
    ctx.discovery21SelectionRank = 7;
    ctx.discovery21LegacyPartition = pastafari::legacyPositiveCompositionUnrank(
        ctx.discovery21LegacyFamily,
        ctx.discovery21SelectionRank);

    const CutletPartitionPatchWrapper wrapper;
    const LegacyAnswerRing unusedStream{};
    const LegacyBiasedSelectionAdapter selectionAdapter;
    const Patch13RejectionWrapper rejectionWrapper;
    const Patch14WideDetourWrapper wideWrapper;
    const auto repaired = wrapper.repair(
        ctx,
        unusedStream,
        selectionAdapter,
        rejectionWrapper,
        wideWrapper);

    require(!repaired.filterApplied,
            "casus sine porta interna filter adhibere non debet");
    require(repaired.legacyPartitionReused,
            "casus sine porta interna partitionem legacy reutilizare debet");
    require(repaired.semanticFamily.count == ctx.discovery21LegacyFamily.count,
            "familia sine porta interna magnitudinem legacy servare debet");
    require(repaired.semanticSelectionRank == ctx.discovery21SelectionRank,
            "rank sine porta interna mutari non debet");
    require(repaired.semanticPartition == ctx.discovery21LegacyPartition,
            "partitio sine porta interna mutari non debet");
}

int main() {
    try {
        requireFilteredFamilyIsExactLegacySubsequence();
        requireNoInternalGatePassesLegacyThrough();

        NormativeOracle oracle;
        const Integer calculationGateIndex = 1;
        const Integer calculationDay = oracle.gateValueForTest(calculationGateIndex);
        const Year year5000 = oracle.year5000(calculationDay);
        require(year5000.openGateIndex < calculationGateIndex &&
                calculationGateIndex < year5000.closeGateIndex,
                "witness PATCH 21 portam calculation-day internam requirit");

        const Integer yearFirstDay = year5000.openGateDay + 1;
        const SauceResult structureSauce = pastafari::reference::sauce(
            calculationDay,
            yearFirstDay);
        const int cutletCount = oracle.chooseCutletCount(structureSauce, year5000);
        const std::vector<int> normativePartition = oracle.chooseCutletPartition(
            calculationDay,
            structureSauce,
            year5000,
            cutletCount);
        const int gapCount = (year5000.closeGateIndex - year5000.openGateIndex).convert_to<int>();
        const int internalOffset = (calculationGateIndex - year5000.openGateIndex).convert_to<int>();
        const auto expectedFiltered = filteredLegacyMaterialization(
            gapCount,
            cutletCount,
            internalOffset);
        const auto expectedIt = std::find(
            expectedFiltered.begin(),
            expectedFiltered.end(),
            normativePartition);
        require(expectedIt != expectedFiltered.end(),
                "partitio normativa in subsequencia filtrata legacy inveniri debet");
        const Integer expectedRank = Integer{
            static_cast<unsigned long long>(std::distance(expectedFiltered.begin(), expectedIt) + 1)};

        const LegacyYearAnchor anchor{
            year5000.number,
            yearFirstDay,
            year5000.closeGateDay
        };
        BaseMonsterManager manager;
        manager.clearLegacyYearNumberCacheDiagnostic();
        const auto report = manager.executeDiscovery21CutletPartition(
            anchor,
            yearFirstDay,
            calculationDay,
            calculationGateIndex,
            cutletCount);

        require(report.ready && report.patch21Applied,
                "via activa PATCH 21 parata esse debet");
        require(report.handler == "Patch21CutletPartitionHandler",
                "handler PATCH 21 viae activae expectatus est");
        require(report.patch21LegacyExecuted,
                "raw legacy partition ante filter vere exsequi debet");
        require(report.calculationDayIsInternalGate,
                "porta calculation-day interna servari debet");
        require(report.legacyIgnoredInternalGate,
                "cicatrix DISCOVERY 21 portam internam adhuc ignorare debet");
        require(!report.legacyHitInternalGateBoundary,
                "raw legacy witness portam internam non attingere debet");
        require(report.patch21FilterApplied,
                "PATCH 21 filter portae internae adhibere debet");
        require(!report.patch21LegacyPartitionReused,
                "partitio legacy defectiva in casu interno reutilizari non debet");
        require(report.semanticFamily.count == Integer{expectedFiltered.size()},
                "familia semantica non est subsequencia filtrata exacta");
        require(report.semanticSelectionRank == expectedRank,
                "rank semanticus a rank oracle in familia filtrata differt");
        require(report.semanticPartition == normativePartition,
                "partitio PATCH 21 ab oracle normativo differt");
        require(report.semanticHitInternalGateBoundary,
                "partitio PATCH 21 portam internam attingere debet");
        require(hitsBoundary(report.semanticPartition, internalOffset),
                "prefixum semanticum portae internae deest");

        const auto diagnostic = manager.executeUnpatchedDiscovery21CutletPartitionDiagnostic(
            anchor,
            yearFirstDay,
            calculationDay,
            calculationGateIndex,
            cutletCount);
        require(diagnostic.ready,
                "diagnosticum DISCOVERY 21 paratum esse debet");
        require(diagnostic.handler == "Discovery21CutletPartitionHandler",
                "diagnosticum handler historicum servare debet");
        require(!diagnostic.patch21Applied,
                "diagnosticum PATCH 21 applicare non debet");
        require(diagnostic.legacyPartition == report.legacyPartition,
                "raw legacy partition inter viam activam et diagnosticum mutata est");
        require(!diagnostic.legacyHitInternalGateBoundary,
                "diagnosticum defectum portae internae servare debet");

        const auto reportIterum = manager.executeDiscovery21CutletPartition(
            anchor,
            yearFirstDay,
            calculationDay,
            calculationGateIndex,
            cutletCount);
        require(reportIterum.semanticPartition == report.semanticPartition &&
                reportIterum.semanticSelectionRank == report.semanticSelectionRank &&
                reportIterum.legacyPartition == report.legacyPartition,
                "diagnosticum interpositum statum invocationis sequentis mutavit");

        std::cout << "REGRESSIO_PATCH_21_TRANSIIT\n";
        std::cout << "GAP_COUNT=" << gapCount << "\n";
        std::cout << "CUTLET_COUNT=" << cutletCount << "\n";
        std::cout << "INTERNAL_GATE_OFFSET=" << internalOffset << "\n";
        std::cout << "LEGACY_FAMILY_COUNT=" << report.legacyFamily.count << "\n";
        std::cout << "FILTERED_FAMILY_COUNT=" << report.semanticFamily.count << "\n";
        std::cout << "LEGACY_RANK=" << report.selectionRank << "\n";
        std::cout << "SEMANTIC_RANK=" << report.semanticSelectionRank << "\n";
        std::cout << "LEGACY_PARTITION=" << integerList(report.legacyPartition) << "\n";
        std::cout << "SEMANTIC_PARTITION=" << integerList(report.semanticPartition) << "\n";
        std::cout << "NORMATIVE_PARTITION=" << integerList(normativePartition) << "\n";
        std::cout << "LEGACY_EXECUTED=YES\n";
        std::cout << "FILTERED_LEGACY_SUBSEQUENCE=YES\n";
        std::cout << "NO_INTERNAL_GATE_PASS_THROUGH=YES\n";
        std::cout << "DIAGNOSTIC_DISCOVERY_21_PRESERVED=YES\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "REGRESSIO_PATCH_21_ERROR: " << error.what() << "\n";
        return 1;
    }
}
