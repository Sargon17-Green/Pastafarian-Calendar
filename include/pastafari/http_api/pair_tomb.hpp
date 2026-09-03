#pragma once
#include "engine_port.hpp"
#include <array>
#include <cstdint>
#include <vector>
namespace pastafari::http_api {

// Prima cicatrix accelerationis supra engine historicum. Direct-mapped et sine
// allocatione in lookup communi; missus semper ad EnginePort veterem cadit.
class PairTombEnginePort final : public EnginePort {
public:
    static constexpr std::size_t SLOT_COUNT=4096;
    static constexpr std::size_t HOT_SEED_COUNT=4;
    static constexpr std::size_t HOT_ALMANAC_COUNT=2;

    struct AlmanacCutlet {
        std::size_t canonicalIndex{};
        std::int64_t firstDay{};
        std::int64_t lastDay{};
    };

    struct Metrics {
        std::uint64_t hits{},misses{},bypasses{},evictions{};
        std::uint64_t hotSeedHits{},almanacHits{},directMappedHits{};
    };
private:
    struct Slot {
        bool occupied=false;
        std::int64_t calculationDay{};
        std::int64_t targetDay{};
        CanonicalPastafariDate value{};
    };
    struct HotAlmanac {
        bool occupied=false;
        std::int64_t calculationDay{};
        Integer year{};
        std::int64_t openDay{};
        std::int64_t closeDay{};
        std::vector<AlmanacCutlet> cutlets{};
        std::vector<int> monthWeaving{};
        std::vector<std::size_t> monthNameIndices{};
    };

    EnginePort& buriedMonster_;
    std::array<Slot,HOT_SEED_COUNT> hotSeed_{};
    std::array<HotAlmanac,HOT_ALMANAC_COUNT> hotAlmanac_{};
    std::array<Slot,SLOT_COUNT> tombs_{};
    Metrics metrics_{};
    bool enabled_=true;
    static bool narrow(const Integer&,std::int64_t&);
    static std::size_t slotFor(std::int64_t,std::int64_t);
    void installGeneratedHotSeed();
    void installGeneratedHotAlmanac();
    bool lookupHotAlmanac(std::int64_t,std::int64_t,CanonicalPastafariDate&) const;
public:
    explicit PairTombEnginePort(EnginePort& monster);
    CanonicalPastafariDate calculate(const Integer&,const Integer&) override;
    void setEnabled(bool enabled){enabled_=enabled;}
    bool enabled()const{return enabled_;}
    void clear();
    Metrics metrics()const{return metrics_;}

    // Cicatrices diagnosticae: workflow fasciculos generatos probat sine
    // mutatione semanticae monstri.
    bool buryHotSeedDiagnostic(const Integer&,const Integer&,const CanonicalPastafariDate&);
    std::size_t generatedSeededCount()const;
    bool buryHotAlmanacDiagnostic(const Integer& calculationDay,
                                  const Integer& year,
                                  const Integer& openDay,
                                  const Integer& closeDay,
                                  const std::vector<AlmanacCutlet>& cutlets,
                                  const std::vector<int>& monthWeaving,
                                  const std::vector<std::size_t>& monthNameIndices);
    std::size_t generatedAlmanacCount()const;
};
} // namespace pastafari::http_api
