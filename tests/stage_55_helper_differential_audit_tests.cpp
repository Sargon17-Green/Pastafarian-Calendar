#include "pastafari/monster.hpp"
#include "reference/normative_reference.hpp"

#include <algorithm>
#include <array>
#include <iostream>
#include <map>
#include <numeric>
#include <set>
#include <stdexcept>
#include <string>
#include <vector>

using pastafari::Integer;
using pastafari::LegacyAnswerRing;
using pastafari::LegacyBiasedSelectionAdapter;
using pastafari::Patch13RejectionWrapper;
using pastafari::Patch14WideDetourWrapper;
using pastafari::Patch18YearWalkWorkspace;
using pastafari::PermutationOrder;
using pastafari::VirtualLegacyList;
using pastafari::reference::Big;

namespace {
void require(bool condicio, const std::string& nuntius) {
    if (!condicio) throw std::runtime_error(nuntius);
}

struct NaiveWeaveKey {
    std::vector<int> remaining{};
    int opened = 0;
    int closed = 0;
    bool operator<(const NaiveWeaveKey& other) const {
        if (opened != other.opened) return opened < other.opened;
        if (closed != other.closed) return closed < other.closed;
        return remaining < other.remaining;
    }
};

class NaiveWeaveOracle {
public:
    explicit NaiveWeaveOracle(std::vector<int> lengths) : lengths_(std::move(lengths)) {}
    Integer countAll() { return count(NaiveWeaveKey{lengths_,0,0}); }
    std::vector<int> unrank1(Integer rank) {
        NaiveWeaveKey state{lengths_,0,0};
        const Integer total = count(state);
        require(rank >= 1 && rank <= total, "rank naive extra fines est");
        std::vector<int> out;
        const int n = std::accumulate(lengths_.begin(), lengths_.end(), 0);
        while (static_cast<int>(out.size()) < n) {
            bool electus = false;
            for (int id = 1; id <= static_cast<int>(lengths_.size()); ++id) {
                if (!legal(state,id)) continue;
                const auto next = apply(state,id);
                const Integer block = count(next);
                if (rank > block) { rank -= block; continue; }
                out.push_back(id); state = next; electus = true; break;
            }
            require(electus, "unrank naive electionem non invenit");
        }
        return out;
    }
private:
    std::vector<int> lengths_;
    std::map<NaiveWeaveKey,Integer> memo_;
    bool legal(const NaiveWeaveKey& state, int id) const {
        const std::size_t i = static_cast<std::size_t>(id-1);
        if (state.remaining[i] == 0) return false;
        const bool apertus = state.remaining[i] < lengths_[i];
        if (!apertus && id != state.opened + 1) return false;
        const bool claudit = state.remaining[i] == 1;
        return !claudit || id == state.closed + 1;
    }
    NaiveWeaveKey apply(const NaiveWeaveKey& state, int id) const {
        auto next = state;
        const std::size_t i = static_cast<std::size_t>(id-1);
        if (next.remaining[i] == lengths_[i]) next.opened = id;
        --next.remaining[i];
        if (next.remaining[i] == 0) next.closed = id;
        return next;
    }
    Integer count(const NaiveWeaveKey& state) {
        if (std::all_of(state.remaining.begin(), state.remaining.end(), [](int x){return x==0;})) return 1;
        const auto it = memo_.find(state); if (it != memo_.end()) return it->second;
        Integer total = 0;
        for (int id=1; id<=static_cast<int>(lengths_.size()); ++id) if (legal(state,id)) total += count(apply(state,id));
        memo_.emplace(state,total); return total;
    }
};

void requireWeave(const std::vector<int>& lengths) {
    NaiveWeaveOracle naive(lengths);
    const Integer n = naive.countAll();
    require(pastafari::exactLegalMonthWeavingCount(lengths) == n,
            "count weaving contra naive discrepavit");
    const std::array<Integer,3> ranks{Integer{1}, (n+1)/2, n};
    for (const auto& r : ranks) {
        require(pastafari::DPUnrankLegalWeaving(lengths,r) == naive.unrank1(r),
                "unrank weaving contra naive discrepavit");
    }
}

void requireDistinct(const std::vector<int>& row, int n) {
    require(static_cast<int>(row.size()) == n, "longitudo row distincti discrepat");
    std::set<int> s(row.begin(), row.end());
    require(static_cast<int>(s.size()) == n, "nomina repetita inventa sunt");
}

std::vector<Integer> gatesForLength(int L) {
    return {Integer{0},Integer{10},Integer{20},Integer{30},Integer{40},Integer{50},Integer{L}};
}
}

int main() {
    try {
        // 4 — SAVE termini.
        const std::array<Integer,5> saveCases{Integer{1}, pastafari::M_OLD-1, pastafari::M_OLD, pastafari::M_OLD+1, 2*pastafari::M_OLD};
        for (const auto& x : saveCases) require(pastafari::savePatch(x) == pastafari::reference::SAVE(x), "SAVE discrepavit");

        // 5 — subtractio/wrap per distantiam inclusivam.
        const std::array<std::pair<Integer,Integer>,4> distCases{{
            {pastafari::FOUNDATION_DAY_OLD-3,pastafari::FOUNDATION_DAY_OLD+5},
            {pastafari::FOUNDATION_DAY_OLD+5,pastafari::FOUNDATION_DAY_OLD-3},
            {pastafari::FOUNDATION_DAY_OLD,pastafari::FOUNDATION_DAY_OLD},
            {pastafari::FOUNDATION_DAY_OLD+1,pastafari::FOUNDATION_DAY_OLD+2}}};
        for (const auto& q : distCases) {
            const auto e = pastafari::reference::workCounts(q.first,q.second).distance;
            const auto a = pastafari::distanceWithChronologicalPatch(q.first,q.second,pastafari::oldDistance(q.first,q.second));
            require(a==e,"distantia subtractionis/wrap discrepavit");
        }

        // 6–7 — permutation ranks 1 et 720.
        for (int r : {1,720}) {
            const auto e = pastafari::reference::permutationUnrank1(r,{1,2,3,4,5,6});
            PermutationOrder ea{}; for (std::size_t i=0;i<6;++i) ea[i]=e[i];
            require(pastafari::oldPermutationUnrank0(r-1)==ea,"permutation rank terminus discrepavit");
        }

        // 8 — ultimus queried bowl in ordine drop 46.
        const auto sProd = pastafari::sauceWithScars(pastafari::FOUNDATION_DAY_OLD,pastafari::FOUNDATION_DAY_OLD);
        const auto sRef = pastafari::reference::sauce(pastafari::reference::FOUNDATION_DAY,pastafari::reference::FOUNDATION_DAY);
        require(sProd.orderAt46Latch == sRef.orderAtDrop46,"orderAt46 discrepavit");
        const int ultimus = sProd.orderAt46Latch.back();
        require(pastafari::nextBowlThroughOrderAt46Latch(sProd.orderAt46Latch,ultimus) ==
                pastafari::reference::nextBowlInDrop46Order(sRef,ultimus),"next bowl ultimus discrepavit");

        // 9–10 — direction odd/even.
        const auto odd = pastafari::sauceCountsThroughScars(pastafari::FOUNDATION_DAY_OLD,pastafari::FOUNDATION_DAY_OLD+1);
        const auto even = pastafari::sauceCountsThroughScars(pastafari::FOUNDATION_DAY_OLD,pastafari::FOUNDATION_DAY_OLD);
        require(odd.direction==3 && (odd.direction%2)==1,"direction odd non est 3");
        require(even.direction==2 && (even.direction%2)==0,"direction even non est 2");

        LegacyBiasedSelectionAdapter legacySelect;
        Patch13RejectionWrapper shortPatch;
        Patch14WideDetourWrapper widePatch;
        auto requireShort = [&](const LegacyAnswerRing& ring, const Integer& N) {
            pastafari::reference::AnswerStream rs{ring.first,ring.directionStep};
            require(shortPatch.repair(ring,N,legacySelect).outputRank == pastafari::reference::chooseRankShort(rs,N),"short selection discrepavit");
        };
        // 11 N=1, 12 N=M, 13 N non divisor M, 14 rejectio iuxta limen.
        requireShort(LegacyAnswerRing{Integer{17},1},Integer{1});
        requireShort(LegacyAnswerRing{pastafari::M_OLD,-1},pastafari::M_OLD);
        requireShort(LegacyAnswerRing{Integer{1234567},1},Integer{7});
        const Integer N7{7}; const Integer lim7=(pastafari::M_OLD/N7)*N7;
        const LegacyAnswerRing rejectRing{lim7+1,-1};
        const auto rejectDecision=shortPatch.repair(rejectRing,N7,legacySelect);
        require(rejectDecision.acceptedOffset==1 && rejectDecision.acceptedAnswer==lim7,"short rejectio unius gradus non exercita est");
        requireShort(rejectRing,N7);

        auto requireWide = [&](const Integer& N) {
            const LegacyAnswerRing ring{Integer{123456789},1};
            pastafari::reference::AnswerStream rs{ring.first,ring.directionStep};
            require(widePatch.repair(ring,N,legacySelect).outputRank == pastafari::reference::chooseRankWide(rs,N),"wide selection discrepavit");
        };
        // 15–17.
        requireWide(pastafari::M_OLD+1);
        requireWide(pastafari::M_OLD*pastafari::M_OLD);
        requireWide(pastafari::M_OLD*pastafari::M_OLD+1);

        // 18–20 — gates ±1/±2 et nulla symmetria coacta.
        Patch18YearWalkWorkspace ws(pastafari::FOUNDATION_DAY_OLD);
        pastafari::reference::NormativeOracle gateOracle;
        for (int k : {-2,-1,1,2}) require(ws.gateDay(Integer{k})==gateOracle.gateValueForTest(Big{k}),"gate ±1/±2 discrepavit");
        bool asymmetricus=false;
        for (int k=1;k<=8;++k) {
            const Integer p=ws.gateDay(k)-ws.gateDay(k-1);
            const Integer n=ws.gateDay(-(k-1))-ws.gateDay(-k);
            if (p!=n) asymmetricus=true;
        }
        require(asymmetricus,"symmetria portarum coacta esse videtur");

        // 21–25 — termini longitudinis anni et reiectio 5779..5781.
        for (int L : {252,5778,5779,5780,5781}) {
            const auto d=pastafari::yearCandidateAfterFootnotePatch(gatesForLength(L),0,6);
            require(d.legacyAccepted,"legacy candidatum intra 252..5781 accipere debet");
            require(d.semanticAccepted==(L<=5778),"ceiling 5778 discrepavit");
        }

        // 31–32 — cutlet count 6 et 17 per familias compositionum positivas.
        for (int K : {6,17}) {
            const auto fam=pastafari::legacyPositiveCompositions(17,K);
            pastafari::reference::BoundedCompositionFamily refFam(17,K,1,17);
            require(fam.count==refFam.count(),"count partitionis cutlet discrepavit");
            const Integer r=(fam.count+1)/2;
            require(pastafari::legacyPositiveCompositionUnrank(fam,r)==refFam.unrank1(r),"unrank partitionis cutlet discrepavit");
        }

        // 33–34 — month count minimum/maximun pro anno 252 dierum: 3 et 47.
        for (int K : {3,47}) {
            VirtualLegacyList fam(252,K);
            pastafari::reference::BoundedCompositionFamily refFam(252,K,4,123);
            require(fam.count()==refFam.count(),"count longitudinum mensium discrepavit");
            const Integer r=(fam.count()+1)/2;
            require(fam.itemAt1(r)==refFam.unrank1(r),"unrank longitudinum mensium discrepavit");
        }

        // 35–36 — longitudo mensis 4 et 123 ut termini familiae [4,123].
        VirtualLegacyList termini(127,2);
        require(termini.itemAt1(1)==std::vector<int>({4,123}),"mensis 4 terminus abest");
        require(termini.itemAt1(termini.count())==std::vector<int>({123,4}),"mensis 123 terminus abest");

        // 37 interleaved et 38 heavy weaving contra counter naive independentem.
        requireWeave({4,4,4});
        requireWeave({15,14,13});

        // 39–40 — nomina segmentorum/mensium distincta per partial permutationem.
        std::vector<int> master17(17); std::iota(master17.begin(),master17.end(),1);
        const Integer count17=pastafari::reference::fallingFactorial(17,17);
        const auto row17=pastafari::partialPermutationNameRowUnrank(master17,(count17+1)/2,17);
        requireDistinct(row17,17);
        require(row17==pastafari::reference::unrankDistinctNameIndices(17,17,(count17+1)/2),"nomina cutlet discrepaverunt");
        std::vector<int> master47(47); std::iota(master47.begin(),master47.end(),1);
        const Integer count47=pastafari::reference::fallingFactorial(47,47);
        const auto row47=pastafari::partialPermutationNameRowUnrank(master47,(count47+1)/2,47);
        requireDistinct(row47,47);
        require(row47==pastafari::reference::unrankDistinctNameIndices(47,47,(count47+1)/2),"nomina mensium discrepaverunt");

        // 41 — dayInMonth cum apparitionibus separatis, target inclusus.
        const std::vector<int> weaving{1,2,1,3,1,2};
        require(pastafari::oldContiguousMonthDayGuess(weaving,5)==5,"cicatrix contigua non servatur");
        require(pastafari::countMonthOccurrencesThroughTarget(weaving,5)==3,"occurrence-count target inclusum discrepavit");

        std::cout << "AUDIT_HELPERS_DIFFERENTIALIS_GRADUS_55_TRANSIIT: categoriae 4-25 et 31-41 cum oracle/helper C++ independente congruunt\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "AUDIT_HELPERS_DIFFERENTIALIS_GRADUS_55_DEFECIT: " << error.what() << '\n';
        return 1;
    }
}
