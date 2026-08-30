#include "pastafari/monster.hpp"
#include "pastafari/source_language_catalog.hpp"
#include "reference/normative_reference.hpp"
#include "stage_55_fast_reference.hpp"

#include <array>
#include <fstream>
#include <iostream>
#include <map>
#include <sstream>
#include <stdexcept>
#include <string>
#include <tuple>
#include <vector>

using pastafari::BaseMetricsShell;
using pastafari::BaseMonsterContext;
using pastafari::BaseValidationManager;
using pastafari::BowlState;
using pastafari::FinalIntegrationHandler;
using pastafari::FinalStructureCacheEntry;
using pastafari::Integer;
using pastafari::PermutationOrder;
using pastafari::SpaghettiDateFive;
using pastafari::Stage56PostStirDetourWitness;
using pastafari::Stage56RawBowlSumSauceResult;
using pastafari::reference::Big;
using pastafari::reference::CalendarDate;
using pastafari::reference::NormativeOracle;
using pastafari::reference::SauceResult;
using pastafari::reference::Year;

namespace {

void require(bool condition, const std::string& message) {
    if (!condition) throw std::runtime_error(message);
}

int cutletIndex(const std::string& text) {
    for (const auto& entry : pastafari::CUTLET_SOURCE_CATALOG) {
        if (entry.text == text) return static_cast<int>(entry.canonicalIndex);
    }
    return -1;
}

int monthIndex(const std::string& text) {
    for (const auto& entry : pastafari::MONTH_SOURCE_CATALOG) {
        if (entry.text == text) return static_cast<int>(entry.canonicalIndex);
    }
    return -1;
}

using CanonicalFive = std::tuple<Integer,int,Integer,int,Integer>;

CanonicalFive canonical(const SpaghettiDateFive& d) {
    return {d.yearNumber, cutletIndex(d.cutletName), d.dayInCutlet,
            monthIndex(d.monthName), d.dayInMonth};
}

CanonicalFive canonical(const CalendarDate& d) {
    return {d.yearNumber, cutletIndex(d.cutletName), d.dayInCutlet,
            monthIndex(d.monthName), d.dayInMonth};
}

CalendarDate correctedFastCalendar(
    NormativeOracle& oracle,
    const Big& calculationDay,
    const Big& targetDay) {
    const Year year = oracle.findTargetYear(calculationDay, targetDay);
    const SauceResult sauce = pastafari::reference::sauceRawBowlSum(
        calculationDay,
        year.openGateDay + 1);
    const int cutletCount = oracle.chooseCutletCount(sauce, year);
    const auto partition = oracle.chooseCutletPartition(
        calculationDay, sauce, year, cutletCount);
    const auto cutletNames = oracle.chooseCutletNameIndices(sauce, cutletCount);
    const auto cutlets = oracle.materializeCutlets(year, partition, cutletNames);
    const int monthCount = oracle.chooseMonthCount(sauce, year);
    const auto monthLengths = oracle.chooseMonthLengths(sauce, year, monthCount);
    const auto monthNames = oracle.chooseMonthNameIndices(sauce, monthCount);

    pastafari::stage55audit::TexturaCelerReference weavingFamily(monthLengths);
    const Big weavingRank = pastafari::reference::chooseRank(
        pastafari::reference::askBowl(
            sauce, 4, pastafari::reference::SEAL_MONTH_WEAVING),
        weavingFamily.numerusOmnium());
    const auto weaving = weavingFamily.aperiGradum(weavingRank);

    int cutletPosition = -1;
    for (std::size_t i = 0; i < cutlets.size(); ++i) {
        if (cutlets[i].firstDay <= targetDay && targetDay <= cutlets[i].lastDay) {
            cutletPosition = static_cast<int>(i);
            break;
        }
    }
    require(cutletPosition >= 0, "reference Gradus 56 segmentum target non invenit");
    const Big dayInCutlet = targetDay - cutlets[static_cast<std::size_t>(cutletPosition)].firstDay + 1;
    const Big offsetBig = targetDay - (year.openGateDay + 1);
    require(offsetBig >= 0 && offsetBig < Big{weaving.size()},
            "reference Gradus 56 positionem target extra texturam invenit");
    const std::size_t offset = offsetBig.convert_to<std::size_t>();
    const int monthId = weaving.at(offset);
    Big dayInMonth = 0;
    for (std::size_t p = 0; p <= offset; ++p) {
        if (weaving[p] == monthId) ++dayInMonth;
    }

    return CalendarDate{
        year.number,
        std::string(pastafari::cutletSourceName(
            static_cast<std::size_t>(cutletNames.at(static_cast<std::size_t>(cutletPosition))))),
        dayInCutlet,
        std::string(pastafari::monthSourceName(
            static_cast<std::size_t>(monthNames.at(static_cast<std::size_t>(monthId - 1))))),
        dayInMonth
    };
}

BowlState independentCorrectedPostStir(
    const BowlState& old,
    int stir,
    Integer& rawOut,
    Integer& savedOut,
    PermutationOrder& orderOut) {
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
        const Integer u = old[static_cast<std::size_t>(id - 1)]
                        + 3 * old[static_cast<std::size_t>(prev - 1)]
                        + 5 * old[static_cast<std::size_t>(following - 1)]
                        + raw
                        + stir
                        + position * position;
        next[static_cast<std::size_t>(id - 1)] = pastafari::savePatch(
            u * u
            + 7 * old[static_cast<std::size_t>(prev - 1)]
                * old[static_cast<std::size_t>(following - 1)]);
    }
    rawOut = raw;
    savedOut = saved;
    orderOut = order;
    return next;
}

void requireReferenceCommitWitnessConstants(
    const Integer& c,
    const Integer& t,
    const Stage56RawBowlSumSauceResult& prod) {
    BowlState expectedBowls{};
    PermutationOrder expectedOrder{};
    bool applicable = false;

    if (c == Integer{-15055671} && t == Integer{-15055671}) {
        expectedBowls = BowlState{{
            Integer{"67068226522203060890658143482200172502"},
            Integer{"156830781782038036265833091137164500083"},
            Integer{"27860245395513113590943202859639481773"},
            Integer{"154958270957687565769906933601352753179"},
            Integer{"83762519477527209919484977230999195024"},
            Integer{"154633989471499313687998830839607736513"}
        }};
        expectedOrder = PermutationOrder{{4,5,2,3,6,1}};
        applicable = true;
    } else if (c == Integer{-15048173} && t == Integer{-15048173}) {
        expectedBowls = BowlState{{
            Integer{"117774601791306122049402151598700069949"},
            Integer{"25984316916056421874135403969605614983"},
            Integer{"143826773047381553934876475558335320216"},
            Integer{"59571312657074816751803206901536426066"},
            Integer{"65620015217119503197726025514221700116"},
            Integer{"28674863197150075414624507047786307945"}
        }};
        expectedOrder = PermutationOrder{{3,4,6,5,2,1}};
        applicable = true;
    }

    if (!applicable) return;
    require(prod.semanticSauce.finalBowls == expectedBowls,
            "sex crateres contra reconstructionem numerorum commit testimonialis discrepant");
    require(prod.semanticSauce.orderAt46Latch == expectedOrder,
            "ordo guttae 46 contra reconstructionem commit testimonialis discrepat");
}

void requireSauceAgainstIndependentOracle(const Integer& c, const Integer& t) {
    const Stage56RawBowlSumSauceResult prod =
        pastafari::sauceWithStage56RawBowlSumDetour(c, t);
    requireReferenceCommitWitnessConstants(c, t, prod);
    const SauceResult ref = pastafari::reference::sauceRawBowlSum(c, t);
    for (std::size_t i = 0; i < 6; ++i) {
        require(prod.semanticSauce.finalBowls[i] == ref.bowls[i],
                "Gradus 56 final bowls contra oracle localem discrepant");
        require(prod.semanticSauce.orderAt46Latch[i] == ref.orderAtDrop46[i],
                "Gradus 56 drop-46 order contra oracle localem discrepat");
    }
    require(prod.legacyScarCallCount == 12,
            "cicatrix legacy post-commotionis non exacte duodecies cucurrit");
    require(prod.appliedCount == 12 && prod.applied,
            "detour raw bowl sum non exacte duodecies applicatus est");

    const auto counts = pastafari::reference::workCounts(c, t);
    const auto stones = pastafari::reference::buildStones();
    const auto hidden = pastafari::reference::buildHiddenDrops(counts, stones);
    const auto visible = pastafari::reference::buildVisibleDrops(counts, stones, hidden);
    auto afterDrops = pastafari::reference::applyVisibleDropsToBowls(
        pastafari::reference::initialBowls(counts), visible, stones);
    BowlState expected{};
    for (std::size_t i = 0; i < 6; ++i) expected[i] = afterDrops.first[i];

    for (int stir = 1; stir <= 12; ++stir) {
        Integer raw{};
        Integer saved{};
        PermutationOrder order{};
        expected = independentCorrectedPostStir(expected, stir, raw, saved, order);
        const Stage56PostStirDetourWitness& witness =
            prod.stirWitnesses.at(static_cast<std::size_t>(stir - 1));
        require(witness.stirIndex == stir && witness.applied,
                "index vel applied flag testis post-commotionis invalidus est");
        require(witness.rawBowlSum == raw && witness.savedOrderNumber == saved,
                "raw bowl sum vel saved order number contra computationem independentem discrepat");
        require(witness.correctedOrder == order && witness.legacyOrder == order,
                "guard permutationis Gradus 56 discrepat");
        require(witness.correctedResult == expected,
                "una ex duodecim post-commotionibus contra formulam independentem discrepat");
        require(witness.oldResult != witness.correctedResult,
                "discriminator post-commotionis cicatricem a correctione non distinxit");
    }
}

void requireStaticScar() {
    std::ifstream in("src/monster.cpp");
    require(static_cast<bool>(in), "src/monster.cpp ad audit staticum aperiri non potest");
    std::ostringstream buffer;
    buffer << in.rdbuf();
    const std::string source = buffer.str();
    const std::string beginToken =
        "Patch11LatchedOrderSauceResult sauceWithOrderAt46Latch(";
    const std::string endToken =
        "Patch11LatchedOrderSauceResult sauceWithScars(";
    const std::size_t begin = source.find(beginToken);
    const std::size_t end = source.find(endToken, begin);
    require(begin != std::string::npos && end != std::string::npos && end > begin,
            "cicatrix sauceWithOrderAt46Latch physice non inventa est");
    const std::string scar = source.substr(begin, end - begin);
    require(scar.find("savedBowlSum = savePatch(savedBowlSum + 149 * stir);") != std::string::npos,
            "formula orderNumber legacy physice deleta est");
    require(scar.find("+ savedBowlSum") != std::string::npos,
            "operandum savedOrderNumber legacy intra u physice deleta est");
}

void runCorrectedContext(BaseMonsterContext& ctx,
                         const Integer& c,
                         const Integer& t,
                         std::map<Integer, FinalStructureCacheEntry>& cache) {
    ctx.calculationDay = c;
    ctx.targetDay = t;
    ctx.phase = "ENTRY";
    ctx.status = "NEW";
    ctx.mode = "AUTHORITATIVE_SPAGHETTI_GRADUS_56_PROBA";
    ctx.retryBudget = 3;
    ctx.stage56CorrectiveRequested = true;
    const FinalIntegrationHandler handler;
    const BaseValidationManager validator;
    const BaseMetricsShell metrics;
    handler.handle(ctx, cache, validator, metrics);
}

void requireContextOwnership() {
    BaseMonsterContext a;
    BaseMonsterContext b;
    std::map<Integer, FinalStructureCacheEntry> cacheA;
    std::map<Integer, FinalStructureCacheEntry> cacheB;
    const Integer f = pastafari::FOUNDATION_DAY_OLD;
    runCorrectedContext(a, f, f, cacheA);
    const auto aOld = a.stage56PostStirOldResult;
    const auto aCorrected = a.stage56PostStirCorrectedResult;
    const Integer aRaw = a.stage56RawBowlSum;
    const Integer aSaved = a.stage56SavedOrderNumber;
    const int aStir = a.stage56StirIndex;
    const std::size_t aCount = a.stage56AppliedCount;

    runCorrectedContext(b, Integer{-15048173}, Integer{-15048173}, cacheB);
    require(a.stage56PostStirOldResult == aOld &&
            a.stage56PostStirCorrectedResult == aCorrected &&
            a.stage56RawBowlSum == aRaw &&
            a.stage56SavedOrderNumber == aSaved &&
            a.stage56StirIndex == aStir &&
            a.stage56AppliedCount == aCount,
            "contextus secundus statum Gradus 56 contextus primi contaminavit");
    require(a.stage56AppliedFlag && b.stage56AppliedFlag &&
            a.stage56LegacyScarCallCount == 12 && b.stage56LegacyScarCallCount == 12 &&
            a.stage56AppliedCount == 12 && b.stage56AppliedCount == 12,
            "status Gradus 56 inter contextus non proprie possessus est");
    require(a.stage56PostStirCorrectedResult != b.stage56PostStirCorrectedResult,
            "duo contextus discriminantes statum eundem casu retinuerunt");
}

void requireExternalWitnessesAndNearFoundation() {
    struct Witness {
        Integer c;
        Integer t;
        CanonicalFive expected;
        const char* name;
    };
    const std::array<Witness,4> witnesses{{
        {Integer{-15055671}, Integer{-15055671},
         CanonicalFive{Integer{5000},4,Integer{762},12,Integer{105}}, "foundation"},
        {Integer{-15048173}, Integer{-15048173},
         CanonicalFive{Integer{5000},12,Integer{21},47,Integer{57}}, "idem"},
        {Integer{-15048173}, Integer{-15048172},
         CanonicalFive{Integer{5000},12,Integer{22},18,Integer{58}}, "post"},
        {Integer{-15048173}, Integer{-15048174},
         CanonicalFive{Integer{5000},12,Integer{20},7,Integer{58}}, "ante"}
    }};

    for (const Witness& w : witnesses) {
        const SpaghettiDateFive prod = pastafari::calendarDateSpaghetti(w.c, w.t);
        require(canonical(prod) == w.expected,
                std::string("witness externus Gradus 56 discrepat: ") + w.name);
    }

    // Casus prope Foundation end-to-end manet separatus a quattuor testimoniis externis.
    // Oracle C++ independens supra ad sex crateres et omnes XII commotiones adhibetur;
    // hic iter DP longum consulto non duplicatur, quia testimonia canonica externa iam
    // exitum calendarii finalem discriminatorie definiunt.
    const Integer f = pastafari::FOUNDATION_DAY_OLD;
    const SpaghettiDateFive prodCross = pastafari::calendarDateSpaghetti(f - 1, f + 1);
    const CanonicalFive nearFoundationExpected{
        Integer{5000}, 3, Integer{1}, 3, Integer{96}
    };
    require(canonical(prodCross) == nearFoundationExpected,
            "casus end-to-end prope Foundation Gradus 56 discrepat");
}

} // namespace

int main() {
    try {
        std::cerr << "GRADUS56_FASE=DISCRIMINATOR\n";
        const BowlState discriminator{{Integer{1},Integer{2},Integer{3},Integer{4},Integer{5},Integer{6}}};
        const Stage56PostStirDetourWitness d =
            pastafari::stage56RawBowlSumPostStirDetour(discriminator, 1);
        require(d.rawBowlSum != d.savedOrderNumber,
                "discriminator rawBowlSum != SAVE(rawBowlSum+149*stir) non distinxit");
        require(d.oldResult != d.correctedResult,
                "discriminator exitum legacy a correctione non distinxit");
        Integer raw{};
        Integer saved{};
        PermutationOrder order{};
        const BowlState independent = independentCorrectedPostStir(
            discriminator, 1, raw, saved, order);
        require(d.correctedResult == independent &&
                d.rawBowlSum == raw && d.savedOrderNumber == saved &&
                d.correctedOrder == order && d.legacyOrder == order,
                "detour discriminatoris contra formulam independentem discrepat");

        std::cerr << "GRADUS56_FASE=SAUCE_FOUNDATION\n";
        requireSauceAgainstIndependentOracle(
            pastafari::FOUNDATION_DAY_OLD,
            pastafari::FOUNDATION_DAY_OLD);
        std::cerr << "GRADUS56_FASE=SAUCE_WITNESS\n";
        requireSauceAgainstIndependentOracle(
            Integer{-15048173},
            Integer{-15048173});
        std::cerr << "GRADUS56_FASE=STATIC\n";
        requireStaticScar();
        std::cerr << "GRADUS56_FASE=CONTEXTS\n";
        requireContextOwnership();
        std::cerr << "GRADUS56_FASE=FINIS\n";

        std::cout
            << "GRADUS_56_CORRECTIO_RAW_BOWL_SUM_TRANSIIT: discriminator, cicatrix 12/12, "
               "detour 12/12, guard ordinis, oracle C++ localis et duo contextus probati sunt; "
               "E2E processibus separatis exercetur\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "GRADUS_56_CORRECTIO_RAW_BOWL_SUM_DEFECIT: " << error.what() << "\n";
        return 1;
    }
}
