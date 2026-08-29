#include "pastafari/monster.hpp"
#include "reference/normative_reference.hpp"
#include <iostream>
#include <stdexcept>
#include <string>

using pastafari::BaseMonsterManager;
using pastafari::Integer;
using pastafari::LegacyYearAnchor;
using pastafari::reference::NormativeOracle;
using pastafari::reference::Year;

static void require(bool condition, const std::string& message) {
    if (!condition) throw std::runtime_error(message);
}

static bool sameYear(const pastafari::Patch18YearRecord& a,
                     const pastafari::Patch18YearRecord& b) {
    return a.number == b.number &&
           a.openGateIndex == b.openGateIndex &&
           a.closeGateIndex == b.closeGateIndex &&
           a.openGateDay == b.openGateDay &&
           a.closeGateDay == b.closeGateDay;
}

int main() {
    try {
        NormativeOracle oracle;
        const Integer c0 = pastafari::reference::FOUNDATION_DAY;
        const Year y5000 = oracle.year5000(c0);
        const Year y5001 = oracle.nextYear(c0, y5000);
        const LegacyYearAnchor anchor{y5000.number, y5000.openGateDay + 1, y5000.closeGateDay};
        const Integer targetDay = y5001.openGateDay + 1;
        BaseMonsterManager manager;

        manager.clearLegacyYearNumberCacheDiagnostic();
        const auto first = manager.executeLegacyYearNumberCache(anchor, targetDay, c0);
        require(first.ready && first.patch19Applied, "prima invocatio PATCH 19 parata esse debet");
        require(!first.legacyCacheHitBeforePatch && !first.cacheHit, "prima invocatio MISS legacy et semanticum esse debet");
        require(!first.entryOverwritten, "prima MISS overwrite superfluum facere non debet");
        require(sameYear(first.outputValue, first.requestEntry.value), "prima MISS value currentem reddere debet");

        const auto exactHit = manager.executeLegacyYearNumberCache(anchor, targetDay, c0);
        require(exactHit.legacyCacheHitBeforePatch, "secunda invocatio eadem HIT legacy esse debet");
        require(exactHit.cacheHit, "tres guardi congruentes HIT semanticum concedere debent");
        require(exactHit.fingerprintMatched && exactHit.openGateMatched && exactHit.closeGateMatched, "tres guardi in HIT exacto congruere debent");
        require(!exactHit.entryOverwritten, "HIT congruens overwrite facere non debet");

        const Integer c1 = c0 + 1;
        const auto guardedMiss = manager.executeLegacyYearNumberCache(anchor, targetDay, c1);
        require(guardedMiss.legacyCacheHitBeforePatch, "clavis year.number eadem HIT legacy ante guardos dare debet");
        require(!guardedMiss.cacheHit, "guard mismatch HIT semanticum negare debet");
        require(!guardedMiss.fingerprintMatched, "fingerprint mutatus mismatch esse debet");
        require(guardedMiss.entryOverwritten, "guard mismatch entry sub eadem clave overwrite facere debet");
        require(guardedMiss.legacyCachedEntryBeforePatch.calculationDayFingerprint == c0, "legacy entry ante patch primum fingerprint servare debet");
        require(guardedMiss.cachedEntry.calculationDayFingerprint == c1, "entry semanticus post overwrite fingerprint currentem servare debet");
        require(sameYear(guardedMiss.outputValue, guardedMiss.requestEntry.value), "MISS guardatus value currentem reddere debet");

        const auto afterOverwriteHit = manager.executeLegacyYearNumberCache(anchor, targetDay, c1);
        require(afterOverwriteHit.legacyCacheHitBeforePatch && afterOverwriteHit.cacheHit, "eadem request post overwrite HIT semanticum fieri debet");
        require(afterOverwriteHit.fingerprintMatched && afterOverwriteHit.openGateMatched && afterOverwriteHit.closeGateMatched, "entry overwrite tres guardos currentes servare debet");
        require(!afterOverwriteHit.entryOverwritten, "HIT post overwrite novum overwrite facere non debet");

        const Integer c2 = c0 + 2;
        const auto secondGuardedMiss = manager.executeLegacyYearNumberCache(anchor, targetDay, c2);
        require(secondGuardedMiss.legacyCacheHitBeforePatch && !secondGuardedMiss.cacheHit, "fingerprint secundus mutatus MISS guardatum dare debet");
        require(secondGuardedMiss.entryOverwritten, "MISS secundus eandem clavem iterum overwrite facere debet");
        require(secondGuardedMiss.legacyCachedEntryBeforePatch.calculationDayFingerprint == c1, "legacy HIT ante secundum overwrite entry proxime servatam videre debet");
        require(secondGuardedMiss.cachedEntry.calculationDayFingerprint == c2, "overwrite secundus fingerprint currentem servare debet");

        manager.clearLegacyYearNumberCacheDiagnostic();
        const auto diagnosticFirst = manager.executeUnpatchedYearNumberCacheDiagnostic(anchor, targetDay, c0);
        require(diagnosticFirst.ready && !diagnosticFirst.cacheHit, "diagnosticum primum MISS esse debet");
        const auto diagnosticStale = manager.executeUnpatchedYearNumberCacheDiagnostic(anchor, targetDay, c1);
        require(diagnosticStale.ready && diagnosticStale.cacheHit, "diagnosticum Stage 38 HIT year.number solum servare debet");
        require(diagnosticStale.cachedEntry.calculationDayFingerprint == c0, "diagnosticum stale entry primam reddere debet");
        require(diagnosticStale.outputValue.closeGateDay != diagnosticStale.requestEntry.value.closeGateDay ||
                diagnosticStale.cachedEntry.calculationDayFingerprint != diagnosticStale.requestEntry.calculationDayFingerprint,
                "diagnosticum Stage 38 stale esse debet");
        require(diagnosticStale.handler == "Discovery19YearNumberCacheHandler", "diagnosticum handler legacy servare debet");

        std::cout << "REGRESSIO_PATCH_19_TRANSIIT\n";
        std::cout << "CLAVIS_LEGACY_YEAR_NUMBER_SERVATA=YES\n";
        std::cout << "GUARDI_PROBATI=3\n";
        std::cout << "OVERWRITE_SUB_EADEM_CLAVE=2\n";
        std::cout << "DIAGNOSTICUM_STALE_HIT=YES\n";
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "REGRESSIO_PATCH_19_ERROR: " << e.what() << "\n";
        return 1;
    }
}
