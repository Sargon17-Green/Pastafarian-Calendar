#include "pastafari/monster.hpp"
#include "reference/normative_reference.hpp"

#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

using pastafari::BaseMonsterManager;
using pastafari::Integer;
using pastafari::LegacyYearAnchor;
using pastafari::reference::NormativeOracle;
using pastafari::reference::SauceResult;
using pastafari::reference::Year;

static void require(bool condition, const std::string& message) {
    if (!condition) throw std::runtime_error(message);
}

static bool hitsBoundary(const std::vector<int>& partition, int offset) {
    int cumulative = 0;
    for (int part : partition) {
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

int main() {
    try {
        NormativeOracle oracle;
        const Integer calculationGateIndex = 1;
        const Integer calculationDay = oracle.gateValueForTest(calculationGateIndex);
        const Year year5000 = oracle.year5000(calculationDay);
        Integer exactIndex{};
        require(oracle.exactGateIndex(calculationDay, exactIndex),
                "dies calculi witness porta exacta esse debet");
        require(exactIndex == calculationGateIndex,
                "index portae witness mutatus est");
        require(year5000.openGateIndex < calculationGateIndex &&
                calculationGateIndex < year5000.closeGateIndex,
                "dies calculi witness porta interna anni 5000 esse debet");

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
        require(hitsBoundary(normativePartition, internalOffset),
                "partitio normativa portam internam attingere debet");

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

        require(report.ready,
                "PATCH 21 partitionem paratam reddere debet");
        require(report.handler == "Patch21CutletPartitionHandler",
                "handler PATCH 21 expectatus est");
        require(report.patch21Applied,
                "PATCH 21 via activa applicari debet");
        require(report.patch21LegacyExecuted,
                "familia legacy ante PATCH 21 vere exsequi debet");
        require(report.calculationDayIsInternalGate,
                "porta interna in contextu PATCH 21 observari debet");
        require(report.legacyIgnoredInternalGate,
                "cicatrix legacy portam internam adhuc ignorare debet");
        require(report.patch21FilterApplied,
                "familia semantica PATCH 21 portam internam filtrare debet");
        require(report.semanticHitInternalGateBoundary,
                "partitio semantica PATCH 21 portam internam attingere debet");
        require(report.gapCount == gapCount,
                "gapCount legacy ab anno resoluto differt");
        require(report.cutletCount == cutletCount,
                "cutletCount legacy ab input differt");
        require(report.internalGateOffset == internalOffset,
                "offset portae internae male derivatus est");

        const auto directFamily = pastafari::legacyPositiveCompositions(
            gapCount,
            cutletCount);
        require(report.legacyFamily.count == directFamily.count,
                "familia legacy non est omnis positive compositions");
        const auto directPartition = pastafari::legacyPositiveCompositionUnrank(
            directFamily,
            report.selectionRank);
        require(directPartition == report.legacyPartition,
                "via activa non ex unrank familiae legacy venit");

        const bool legacyHits = hitsBoundary(report.legacyPartition, internalOffset);
        require(legacyHits == report.legacyHitInternalGateBoundary,
                "diagnosticum prefixum portae internae discrepat");
        require(!legacyHits,
                "witness legacy post PATCH 21 cicatricem servare debet");
        require(report.semanticPartition == normativePartition,
                "partitio semantica PATCH 21 ab oracle normativo differt");

        const auto diagnostic = manager.executeUnpatchedDiscovery21CutletPartitionDiagnostic(
            anchor,
            yearFirstDay,
            calculationDay,
            calculationGateIndex,
            cutletCount);
        require(diagnostic.ready,
                "diagnosticum DISCOVERY 21 paratum esse debet");
        require(diagnostic.handler == "Discovery21CutletPartitionHandler",
                "diagnosticum handler DISCOVERY 21 servare debet");
        require(!diagnostic.patch21Applied,
                "diagnosticum PATCH 21 applicare non debet");
        require(diagnostic.legacyPartition == report.legacyPartition,
                "diagnosticum eandem partitionem legacy servare debet");
        require(!diagnostic.legacyHitInternalGateBoundary,
                "diagnosticum defectum prefixi portae internae servare debet");

        std::cout << "DISCOVERY_21_WITNESS"
                  << " gapCount=" << gapCount
                  << " cutletCount=" << cutletCount
                  << " internalGateOffset=" << internalOffset
                  << " familyCount=" << report.legacyFamily.count
                  << " rank=" << report.selectionRank
                  << " legacy=" << integerList(report.legacyPartition)
                  << " prefixes=" << integerList(report.legacyPrefixSums)
                  << " normative=" << integerList(normativePartition)
                  << "\n";

        std::cout << "REGRESSIO_DISCOVERY_21_POST_PATCH_TRANSIIT\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "REGRESSIO_DISCOVERY_21_ERROR: " << error.what() << "\n";
        return 4;
    }
}
