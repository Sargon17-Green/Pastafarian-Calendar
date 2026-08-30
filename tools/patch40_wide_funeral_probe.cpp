#include "pastafari/monster.hpp"
#include <iostream>
#include <stdexcept>
#include <string>

using pastafari::Integer;

static void require(bool ok, const char* what) {
    if (!ok) throw std::runtime_error(what);
}

int main() {
    using namespace pastafari;
    setAccelerationScarsEnabled(true);
    setFullHistoricalAccelerationValidation(false);
    resetPersistentScarVaultsDiagnostic();

    LegacyBiasedSelectionAdapter selector;
    Patch14WideDetourWrapper wide;

    // +1: M^2 mod (M+2) = 4. first=M-1 makes initialWide=M^2-1,
    // hence two historical increments: M^2 then wrap to 1.
    {
        const Integer N = M_OLD + 2;
        const LegacyAnswerRing ring{M_OLD - 1, +1};
        const auto got = wide.repair(ring, N, selector);
        require(got.rejectionSteps == 2, "PATCH40 +1 gradus discrepat");
        require(got.acceptedWide == 1, "PATCH40 +1 corpus discrepat");
        require(got.outputRank == biasedLegacyPick(Integer{1}, N),
                "PATCH40 +1 rank discrepat");
    }

    // -1: choose N=space-(M+5), so acceptanceLimit=N. first=1 with
    // descending ring gives initialWide=space-M+1, exactly six decrements
    // above the limit.
    {
        const Integer space = M_OLD * M_OLD;
        const Integer N = space - (M_OLD + 5);
        const LegacyAnswerRing ring{Integer{1}, -1};
        const auto got = wide.repair(ring, N, selector);
        require(got.rejectionSteps == 6, "PATCH40 -1 gradus discrepat");
        require(got.acceptedWide == N, "PATCH40 -1 corpus discrepat");
        require(got.outputRank == biasedLegacyPick(N, N),
                "PATCH40 -1 rank discrepat");
    }

    // Shard 83 witness that exposed the astronomical +1 rejection walk.
    {
        const auto d = calendarDateSpaghetti(Integer{-15043652}, Integer{-15043556});
        require(d.yearNumber == 5000, "PATCH40 witness annus discrepat");
        require(d.cutletName == "cornu", "PATCH40 witness segmentum discrepat");
        require(d.dayInCutlet == 411, "PATCH40 witness dies segmenti discrepat");
        require(d.monthName == "arena", "PATCH40 witness mensis discrepat");
        require(d.dayInMonth == 50, "PATCH40 witness dies mensis discrepat");
    }

    const auto m = persistentScarMetricsDiagnostic();
    require(m.patch40WideFuneralShortcut >= 3,
            "PATCH40 exsequiae latae non observatae sunt");
    std::cout << "PATCH40_EXSEQUIAE_REIECTIONIS_LATAE=PASS hits="
              << m.patch40WideFuneralShortcut << "\n";
}
