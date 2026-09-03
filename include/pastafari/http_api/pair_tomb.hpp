#pragma once
#include "engine_port.hpp"
#include <array>
#include <cstdint>
namespace pastafari::http_api {

// Prima cicatrix accelerationis supra engine historicum. Direct-mapped et sine
// allocatione in lookup communi; missus semper ad EnginePort veterem cadit.
class PairTombEnginePort final : public EnginePort {
public:
    static constexpr std::size_t SLOT_COUNT=4096;
    static constexpr std::size_t HOT_SEED_COUNT=4;
    struct Metrics { std::uint64_t hits{},misses{},bypasses{},evictions{}; };
private:
    struct Slot {
        bool occupied=false;
        std::int64_t calculationDay{};
        std::int64_t targetDay{};
        CanonicalPastafariDate value{};
    };
    EnginePort& buriedMonster_;
    std::array<Slot,HOT_SEED_COUNT> hotSeed_{};
    std::array<Slot,SLOT_COUNT> tombs_{};
    Metrics metrics_{};
    bool enabled_=true;
    static bool narrow(const Integer&,std::int64_t&);
    static std::size_t slotFor(std::int64_t,std::int64_t);
    void installGeneratedHotSeed();
public:
    explicit PairTombEnginePort(EnginePort& monster);
    CanonicalPastafariDate calculate(const Integer&,const Integer&) override;
    void setEnabled(bool enabled){enabled_=enabled;}
    bool enabled()const{return enabled_;}
    void clear();
    Metrics metrics()const{return metrics_;}

    // Cicatrix diagnostica: workflow utitur fasciculo generato; probatio potest
    // corpus fixum sepelire sine invocatione monstri.
    bool buryHotSeedDiagnostic(const Integer&,const Integer&,const CanonicalPastafariDate&);
    std::size_t generatedSeededCount()const;
};
} // namespace pastafari::http_api
