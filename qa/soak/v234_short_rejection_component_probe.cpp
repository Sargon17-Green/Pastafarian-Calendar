// Focused component regression for the isolated Celeritas short-rejection
// candidate. Not a calendar converter, not original-F evidence, not a soak.
// Build only against the candidate from v233, never launch the two huge
// witnesses against the unaccelerated original loop.
#include "pastafari/monster.hpp"
#include <iostream>
#include <stdexcept>
#include <vector>

using namespace pastafari;

struct Case {
    const char* label;
    Integer n;
    Integer first;
    int direction;
    Integer limit;
    Integer answer;
    Integer offset;
};

void require(bool ok, const char* msg) {
    if (!ok) throw std::runtime_error(msg);
}

void verify(const Case& c, const Patch13RejectionSelection& r) {
    require(r.acceptanceLimit == c.limit, "acceptance limit mismatch");
    require(r.acceptedAnswer == c.answer, "accepted answer mismatch");
    require(r.acceptedOffset == c.offset, "first accepted offset mismatch");
    require(r.outputRank == (c.answer - 1) % c.n + 1, "rank mismatch");
    require(ringAnswer({c.first,c.direction},r.acceptedOffset)==r.acceptedAnswer,
            "ring endpoint mismatch");
    if (r.acceptedOffset > 0)
        require(ringAnswer({c.first,c.direction},r.acceptedOffset-1)>r.acceptanceLimit,
                "previous ring point was accepted");
}

int main() {
    LegacyBiasedSelectionAdapter adapter;
    Patch13RejectionWrapper wrapper;
    const Integer M=M_OLD;
    const Integer N=(M+1)/2;
    const std::vector<Case> small{
        {"already_accepted", M, 17, +1, M, 17, 0},
        {"single_family", 1, M, -1, M, M, 0},
        {"at_limit", N, N, -1, N, N, 0},
        {"minus_one", N, N+1, -1, N, N, 1},
        {"minus_seven", N, N+7, -1, N, N, 7},
        {"plus_one", N, M, +1, N, 1, 1},
        {"plus_seven", N, M-6, +1, N, 1, 7},
        {"normalize_zero", N, 0, +1, N, 1, 1},
        {"normalize_negative", N, -1, +1, N, 1, 2}
    };
    const std::vector<Case> huge{
        {"maximum_minus", N, M, -1, N, N, M-N},
        {"maximum_plus", N, N+1, +1, N, 1, M-N},
        {"V5_000371",
         Integer{"58764911443094882586555884543957256800"},
         Integer{"132347082236251974591906934230555451540"},
         -1,
         Integer{"117529822886189765173111769087914513600"},
         Integer{"117529822886189765173111769087914513600"},
         Integer{"14817259350062209418795165142640937940"}},
        {"V5_000385",
         Integer{"107801604682176811844064421003985237000"},
         Integer{"165107666744634915217806908987305889409"},
         -1,
         Integer{"107801604682176811844064421003985237000"},
         Integer{"107801604682176811844064421003985237000"},
         Integer{"57306062062458103373742487983320652409"}}
    };
    auto run=[&](const Case& c) {
        auto r=wrapper.repair({c.first,c.direction},c.n,adapter);
        verify(c,r);
        return r;
    };
    unsigned checks=0;
    for(const auto& c:small) {
        resetPersistentScarVaultsDiagnostic();
        setAccelerationScarsEnabled(false);
        setFullHistoricalAccelerationValidation(false);
        run(c); ++checks;
        setAccelerationScarsEnabled(true);
        setFullHistoricalAccelerationValidation(false);
        run(c); ++checks; // cold
        run(c); ++checks; // cached
        setFullHistoricalAccelerationValidation(true);
        run(c); ++checks; // historical replay of bounded cached witness
        resetPersistentScarVaultsDiagnostic();
        run(c); ++checks; // cold historical route
    }
    setAccelerationScarsEnabled(true);
    setFullHistoricalAccelerationValidation(false);
    for(const auto& c:huge) {
        resetPersistentScarVaultsDiagnostic();
        run(c); ++checks;
        run(c); ++checks;
        std::cout<<"HUGE "<<c.label<<" OFFSET "<<c.offset<<'\n';
    }
    unsigned rejected=0;
    for(const auto& c:std::vector<Case>{
        {"zero_N",0,1,+1,0,0,0},
        {"above_M",M+1,1,+1,0,0,0},
        {"invalid_dir",N,1,0,0,0,0}}) {
        try { (void)wrapper.repair({c.first,c.direction},c.n,adapter); }
        catch(const BaseValidationError&) { ++rejected; continue; }
        throw std::runtime_error("invalid input accepted");
    }
    require(checks==53 && rejected==3,"coverage count");
    std::cout<<"PATCH13_COMPONENT_PASS checks="<<checks
             <<" rejected="<<rejected<<" original_F_calls=0\n";
}
