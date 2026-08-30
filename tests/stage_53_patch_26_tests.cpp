#include "pastafari/monster.hpp"
#include "reference/normative_reference.hpp"

#include <array>
#include <iostream>
#include <stdexcept>
#include <string>

using pastafari::BaseMonsterManager;
using pastafari::Integer;
using pastafari::LegacyYearAnchor;
using pastafari::LegacyYearMembershipAdapter;
using pastafari::OpeningGateMembershipPatchWrapper;
using pastafari::Patch18YearRecord;
using pastafari::reference::NormativeOracle;
using pastafari::reference::Year;

static void require(bool condition, const std::string& message) {
    if (!condition) throw std::runtime_error(message);
}

static bool sameYear(const Patch18YearRecord& a, const Patch18YearRecord& b) {
    return a.number == b.number &&
           a.openGateIndex == b.openGateIndex &&
           a.closeGateIndex == b.closeGateIndex &&
           a.openGateDay == b.openGateDay &&
           a.closeGateDay == b.closeGateDay;
}

static bool sameYear(const Patch18YearRecord& actual, const Year& expected) {
    return actual.number == expected.number &&
           actual.openGateIndex == expected.openGateIndex &&
           actual.closeGateIndex == expected.closeGateIndex &&
           actual.openGateDay == expected.openGateDay &&
           actual.closeGateDay == expected.closeGateDay;
}

int main() {
    try {
        NormativeOracle oracle;
        BaseMonsterManager manager;
        const LegacyYearMembershipAdapter legacyAdapter;
        const OpeningGateMembershipPatchWrapper wrapper;

        const std::array<Integer,3> calculationGateIndices{
            Integer{0}, Integer{7}, Integer{-11}
        };

        int repaired = 0;
        for (const Integer& calculationGateIndex : calculationGateIndices) {
            const Integer calculationDay = oracle.gateValueForTest(calculationGateIndex);
            const Year year5000 = oracle.year5000(calculationDay);
            const LegacyYearAnchor anchor{
                year5000.number,
                year5000.openGateDay + 1,
                year5000.closeGateDay
            };

            const Integer openingTarget = year5000.openGateDay;
            const Year openingNormative = oracle.findTargetYear(
                calculationDay,
                openingTarget);
            const auto legacyOpening = legacyAdapter.resolve(
                calculationDay,
                anchor,
                openingTarget);
            const auto decisionOpening = wrapper.repair(
                calculationDay,
                anchor,
                openingTarget,
                legacyOpening);

            require(legacyOpening.legacyExecuted,
                    "PATCH 26 helper legacy ante correctionem vere currere debet");
            require(legacyOpening.outputYear.number == year5000.number,
                    "PATCH 26 cicatrix [open,close] annum novum servare debet");
            require(decisionOpening.patchApplied && decisionOpening.correctComputed,
                    "PATCH 26 wrapper correctionem computare debet");
            require(!decisionOpening.legacyEqualsCorrect &&
                        !decisionOpening.legacyReturned,
                    "opening gate ramum ghost!=correct exercere debet");
            require(sameYear(decisionOpening.correctOutputYear, openingNormative),
                    "PATCH 26 wrapper opening gate anno priori attribuere debet");
            require(sameYear(decisionOpening.outputYear, openingNormative),
                    "PATCH 26 wrapper correctum loco ghost reddere debet");
            require(decisionOpening.authoritativeIntervalAccepted,
                    "PATCH 26 wrapper intervalum (open,close] servare debet");

            const auto diagnostic =
                manager.executeUnpatchedDiscovery26OpeningGateYearMembershipDiagnostic(
                    anchor,
                    openingTarget,
                    calculationDay);
            const auto patched = manager.executeDiscovery26OpeningGateYearMembership(
                anchor,
                openingTarget,
                calculationDay);
            require(diagnostic.handler == "Discovery26OpeningGateYearMembershipHandler" &&
                        diagnostic.status == "EXPECTED_RED",
                    "PATCH 26 via diagnostica DISCOVERY 26 cicatricem servare debet");
            require(patched.handler == "Patch26OpeningGateYearMembershipHandler" &&
                        patched.patch26Applied,
                    "PATCH 26 via activa handler correctum adhibere debet");
            require(sameYear(patched.legacyOutputYearBeforePatch, diagnostic.outputYear),
                    "PATCH 26 ghost report cum diagnostico legacy congruere debet");
            require(sameYear(patched.outputYear, openingNormative),
                    "PATCH 26 via activa opening gate normativum reddere debet");
            require(patched.correctBackwardSteps ==
                        patched.legacyBackwardStepsBeforePatch + 1,
                    "opening gate correctionem unum gradum retro addere debet");
            ++repaired;

            const Integer interiorTarget = year5000.openGateDay + 1;
            const auto legacyInterior = legacyAdapter.resolve(
                calculationDay,
                anchor,
                interiorTarget);
            const auto decisionInterior = wrapper.repair(
                calculationDay,
                anchor,
                interiorTarget,
                legacyInterior);
            require(decisionInterior.legacyEqualsCorrect &&
                        decisionInterior.legacyReturned,
                    "PATCH 26 ramum ghost==correct pro die interiori exercere debet");
            require(sameYear(decisionInterior.outputYear, legacyInterior.outputYear),
                    "PATCH 26 ghost rectum pro die interiori retinere debet");

            const Integer closeTarget = year5000.closeGateDay;
            const auto legacyClose = legacyAdapter.resolve(
                calculationDay,
                anchor,
                closeTarget);
            const auto decisionClose = wrapper.repair(
                calculationDay,
                anchor,
                closeTarget,
                legacyClose);
            require(decisionClose.legacyEqualsCorrect && decisionClose.legacyReturned,
                    "PATCH 26 closing gate in eodem anno retinere debet");
            require(decisionClose.authoritativeIntervalAccepted,
                    "PATCH 26 closing gate in (open,close] includere debet");
        }

        require(repaired == 3,
                "PATCH 26 tres witness opening-gate reparare debet");
        std::cout
            << "REGRESSIO_PATCH_26_TRANSIIT: legacy [open,close] cicatrix, backward <=, "
               "ghost==correct, ghost!=correct et tres opening-gate witness probati sunt\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "REGRESSIO_PATCH_26_ERROR: " << error.what() << "\n";
        return 1;
    }
}
