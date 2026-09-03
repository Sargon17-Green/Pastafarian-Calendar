#include "pastafari/http_api/pair_tomb.hpp"
#include <limits>
#include <string>
namespace pastafari::http_api {
namespace {
std::uint64_t mix(std::uint64_t x){x+=0x9e3779b97f4a7c15ULL;x=(x^(x>>30))*0xbf58476d1ce4e5b9ULL;x=(x^(x>>27))*0x94d049bb133111ebULL;return x^(x>>31);}
struct GeneratedHotSeedLiteral {
    bool occupied;
    std::int64_t calculationDay;
    std::int64_t targetDay;
    const char* year;
    std::size_t cutletIndex;
    const char* cutletName;
    const char* dayInCutlet;
    std::size_t monthIndex;
    const char* monthName;
    const char* dayInMonth;
};
constexpr std::array<GeneratedHotSeedLiteral,PairTombEnginePort::HOT_SEED_COUNT> GENERATED_HOT_SEED{{
#include "pastafari/http_api/generated_hot_two_day_seed.inc"
}};
Integer decimalInteger(const char* text){return Integer{std::string{text}};}
}
PairTombEnginePort::PairTombEnginePort(EnginePort& monster):buriedMonster_(monster){installGeneratedHotSeed();}
bool PairTombEnginePort::narrow(const Integer&v,std::int64_t&out){
    static const Integer lo=std::numeric_limits<std::int64_t>::min(),hi=std::numeric_limits<std::int64_t>::max();
    if(v<lo||v>hi) return false;
    out=v.convert_to<std::int64_t>();
    return true;
}
std::size_t PairTombEnginePort::slotFor(std::int64_t c,std::int64_t t){
    auto a=mix(static_cast<std::uint64_t>(c)),b=mix(static_cast<std::uint64_t>(t)^0xd6e8feb86659fd93ULL);
    return static_cast<std::size_t>((a^(b+(a<<6)+(a>>2)))&(SLOT_COUNT-1));
}
void PairTombEnginePort::installGeneratedHotSeed(){
    for(const auto&literal:GENERATED_HOT_SEED){
        if(!literal.occupied)continue;
        const CanonicalPastafariDate value{
            decimalInteger(literal.year),literal.cutletIndex,literal.cutletName,
            decimalInteger(literal.dayInCutlet),literal.monthIndex,literal.monthName,
            decimalInteger(literal.dayInMonth)};
        (void)buryHotSeedDiagnostic(Integer{literal.calculationDay},Integer{literal.targetDay},value);
    }
}
bool PairTombEnginePort::buryHotSeedDiagnostic(const Integer&c,const Integer&t,const CanonicalPastafariDate&value){
    std::int64_t cn,tn;if(!narrow(c,cn)||!narrow(t,tn))return false;
    for(auto&slot:hotSeed_){
        if(slot.occupied&&slot.calculationDay==cn&&slot.targetDay==tn){slot.value=value;return true;}
    }
    for(auto&slot:hotSeed_){
        if(!slot.occupied){slot={true,cn,tn,value};return true;}
    }
    return false;
}
std::size_t PairTombEnginePort::generatedSeededCount()const{
    std::size_t count=0;for(const auto&slot:hotSeed_)if(slot.occupied)++count;return count;
}
CanonicalPastafariDate PairTombEnginePort::calculate(const Integer&c,const Integer&t){
    if(!enabled_){++metrics_.bypasses;return buriedMonster_.calculate(c,t);}
    std::int64_t cn,tn;if(!narrow(c,cn)||!narrow(t,tn)){++metrics_.bypasses;return buriedMonster_.calculate(c,t);}
    for(const auto&slot:hotSeed_){
        if(slot.occupied&&slot.calculationDay==cn&&slot.targetDay==tn){++metrics_.hits;return slot.value;}
    }
    auto&slot=tombs_[slotFor(cn,tn)];
    if(slot.occupied&&slot.calculationDay==cn&&slot.targetDay==tn){++metrics_.hits;return slot.value;}
    ++metrics_.misses;auto result=buriedMonster_.calculate(c,t);if(slot.occupied)++metrics_.evictions;slot={true,cn,tn,result};return result;
}
void PairTombEnginePort::clear(){for(auto&s:hotSeed_)s=Slot{};for(auto&s:tombs_)s=Slot{};metrics_={};}
} // namespace pastafari::http_api
