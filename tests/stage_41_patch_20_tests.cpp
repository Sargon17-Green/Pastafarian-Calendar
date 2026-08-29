#include "pastafari/monster.hpp"
#include "reference/normative_reference.hpp"

#include <array>
#include <iostream>
#include <stdexcept>
#include <string>

using pastafari::BaseMonsterManager;
using pastafari::Integer;
using pastafari::LegacyStructureSelectorToken;
using pastafari::LegacyYearAnchor;
using pastafari::Patch18YearRecord;
using pastafari::Patch11LatchedOrderSauceResult;
using pastafari::reference::NormativeOracle;
using pastafari::reference::SauceResult;
using pastafari::reference::Year;

static void require(bool condition, const std::string& message) {
    if (!condition) throw std::runtime_error(message);
}

static bool idemOrdo(const pastafari::PermutationOrder& actual,
                     const std::array<int, 6>& expected) {
    for (std::size_t i = 0; i < actual.size(); ++i) {
        if (actual[i] != expected[i]) return false;
    }
    return true;
}

static bool idemSauce(const Patch11LatchedOrderSauceResult& actual,
                      const SauceResult& expected) {
    for (std::size_t i = 0; i < actual.finalBowls.size(); ++i) {
        if (actual.finalBowls[i] != expected.bowls[i]) return false;
    }
    return idemOrdo(actual.orderAt46Latch, expected.orderAtDrop46);
}

static bool idemToken(const LegacyStructureSelectorToken& token,
                      const SauceResult& expected) {
    return token.bowl2 == expected.bowls[1] &&
           idemOrdo(token.orderAt46Latch, expected.orderAtDrop46);
}

int main() {
    try {
        NormativeOracle oracle;
        const Integer calculationDay = pastafari::reference::FOUNDATION_DAY;
        const Year year5000 = oracle.year5000(calculationDay);
        const Integer yearFirstDay = year5000.openGateDay + 1;
        const LegacyYearAnchor anchor{
            year5000.number,
            yearFirstDay,
            year5000.closeGateDay
        };
        const Patch18YearRecord yearRecord{
            year5000.number,
            year5000.openGateIndex,
            year5000.closeGateIndex,
            year5000.openGateDay,
            year5000.closeGateDay
        };
        const SauceResult normativeStructure = pastafari::reference::sauce(
            calculationDay,
            yearFirstDay);

        const std::array<Integer, 3> targets{
            yearFirstDay + 1,
            yearFirstDay + 365,
            year5000.closeGateDay
        };

        int ghostDivergences = 0;
        for (const Integer& originalTargetDay : targets) {
            const SauceResult legacyExpected = pastafari::reference::sauce(
                calculationDay,
                originalTargetDay);
            const auto direct = pastafari::structureSaucePatch(
                calculationDay,
                originalTargetDay,
                yearRecord);
            require(direct.ghostExecuted,
                    "structureSaucePatch oldStructureSauce ut ghost exsequi debet");
            require(direct.mustUse == yearFirstDay,
                    "structureSaucePatch mustUse ex openGate+1 derivare debet");
            require(direct.semanticRecomputed,
                    "target diversus recomputationem semanticam requirit");
            require(idemSauce(direct.ghost, legacyExpected),
                    "ghost target originalem exacte sequi debet");
            require(idemSauce(direct.semanticSauce, normativeStructure),
                    "sauce semantica year.firstDay exacte sequi debet");
            if (!idemSauce(direct.ghost, normativeStructure)) {
                ++ghostDivergences;
            }
        }
        require(ghostDivergences == 3,
                "tres ghostes witness a sauce year.firstDay divergere debent");

        const auto equalDirect = pastafari::structureSaucePatch(
            calculationDay,
            yearFirstDay,
            yearRecord);
        require(equalDirect.ghostExecuted,
                "casus aequalis oldStructureSauce ut ghost exsequi debet");
        require(!equalDirect.semanticRecomputed,
                "casus aequalis sauce iterum computare non debet");
        require(idemSauce(equalDirect.ghost, normativeStructure),
                "ghost casus aequalis normativus esse debet");
        require(idemSauce(equalDirect.semanticSauce, normativeStructure),
                "sauce semantica casus aequalis normativus esse debet");

        BaseMonsterManager manager;
        manager.clearLegacyYearNumberCacheDiagnostic();
        int selectorNormativi = 0;
        int diagnosticaLegacy = 0;
        for (const Integer& originalTargetDay : targets) {
            const SauceResult legacyExpected = pastafari::reference::sauce(
                calculationDay,
                originalTargetDay);
            const auto report = manager.executeDiscovery20StructureSauce(
                anchor,
                originalTargetDay,
                calculationDay);
            require(report.ready && report.patch20Applied,
                    "via activa PATCH 20 parata esse debet");
            require(report.handler == "Patch20StructureSauceHandler",
                    "via activa handler PATCH 20 habere debet");
            require(report.patch20GhostExecuted,
                    "via activa ghost legacy exsequi debet");
            require(report.patch20SemanticRecomputed,
                    "via activa target diversum recomputare debet");
            require(!report.patch20GhostReachedSelector,
                    "ghost viae activae ad selector pervenire non debet");
            require(!report.selectorConsumedLegacySauce,
                    "selector viae activae sauce legacy consumere non debet");
            require(idemSauce(report.legacyStructureSauce, legacyExpected),
                    "report ghost target originalem servare debet");
            require(idemSauce(report.semanticStructureSauce, normativeStructure),
                    "report sauce semanticam year.firstDay servare debet");
            require(idemToken(report.selectorToken, normativeStructure),
                    "selector solam sauce year.firstDay videre debet");
            ++selectorNormativi;

            const auto diagnostic = manager.executeUnpatchedDiscovery20StructureSauceDiagnostic(
                anchor,
                originalTargetDay,
                calculationDay);
            require(diagnostic.ready,
                    "diagnosticum DISCOVERY 20 paratum esse debet");
            require(!diagnostic.patch20Applied,
                    "diagnosticum PATCH 20 applicare non debet");
            require(diagnostic.selectorConsumedLegacySauce,
                    "diagnosticum selector oldStructureSauce consumere debet");
            require(diagnostic.handler == "Discovery20StructureSauceHandler",
                    "diagnosticum handler historicum servare debet");
            require(idemSauce(diagnostic.legacyStructureSauce, legacyExpected),
                    "diagnosticum ghost historicum target originalem sequi debet");
            require(!idemToken(diagnostic.selectorToken, normativeStructure),
                    "diagnosticum cicatricem DISCOVERY 20 servare debet");
            ++diagnosticaLegacy;
        }

        const auto equalReport = manager.executeDiscovery20StructureSauce(
            anchor,
            yearFirstDay,
            calculationDay);
        require(equalReport.ready && equalReport.patch20Applied,
                "casus aequalis PATCH 20 paratus esse debet");
        require(equalReport.patch20GhostExecuted,
                "casus aequalis ghost exsequi debet");
        require(!equalReport.patch20SemanticRecomputed,
                "casus aequalis recomputationem superfluam non debet");
        require(!equalReport.patch20GhostReachedSelector,
                "casus aequalis ghost state directe ad selector non mittitur");
        require(idemToken(equalReport.selectorToken, normativeStructure),
                "casus aequalis selector normativus manere debet");

        std::cout << "REGRESSIO_PATCH_20_TRANSIIT\n";
        std::cout << "GHOSTES_DIVERGENTES=" << ghostDivergences << "\n";
        std::cout << "SELECTORES_NORMATIVI=" << selectorNormativi << "\n";
        std::cout << "DIAGNOSTICA_LEGACY=" << diagnosticaLegacy << "\n";
        std::cout << "TARGET_AEQUALIS_RECOMPUTATIO=NO\n";
        std::cout << "GHOST_AD_SELECTOR=NO\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "REGRESSIO_PATCH_20_ERROR: " << error.what() << "\n";
        return 1;
    }
}
