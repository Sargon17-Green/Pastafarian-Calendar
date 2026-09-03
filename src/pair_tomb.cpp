#include "pastafari/http_api/pair_tomb.hpp"
#include "pastafari/source_language_catalog.hpp"
#include <limits>
#include <stdexcept>
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
std::string cutletNameAt(std::size_t canonicalIndex){
    if(canonicalIndex<1||canonicalIndex>pastafari::CUTLET_SOURCE_CATALOG.size())throw std::runtime_error("index cutlet almanaci invalidus est");
    return std::string(pastafari::cutletSourceName(canonicalIndex));
}
std::string monthNameAt(std::size_t canonicalIndex){
    if(canonicalIndex<1||canonicalIndex>pastafari::MONTH_SOURCE_CATALOG.size())throw std::runtime_error("index mensis almanaci invalidus est");
    return std::string(pastafari::monthSourceName(canonicalIndex));
}
}
PairTombEnginePort::PairTombEnginePort(EnginePort& monster):buriedMonster_(monster){installGeneratedHotSeed();installGeneratedHotAlmanac();}
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
void PairTombEnginePort::installGeneratedHotAlmanac(){
#include "pastafari/http_api/generated_hot_year_almanac_seed.inc"
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
bool PairTombEnginePort::buryHotAlmanacDiagnostic(
    const Integer&c,const Integer&year,const Integer&open,const Integer&close,
    const std::vector<AlmanacCutlet>&cutlets,const std::vector<int>&weaving,
    const std::vector<std::size_t>&monthNames){
    std::int64_t cn,on,cl;if(!narrow(c,cn)||!narrow(open,on)||!narrow(close,cl))return false;
    if(cl<=on||cutlets.empty()||monthNames.empty())return false;
    const Integer expected=close-open;
    if(expected<1||expected>Integer{std::numeric_limits<std::size_t>::max()})return false;
    if(weaving.size()!=expected.convert_to<std::size_t>())return false;
    std::int64_t cursor=on+1;
    for(const auto&cutlet:cutlets){
        if(cutlet.canonicalIndex<1||cutlet.canonicalIndex>pastafari::CUTLET_SOURCE_CATALOG.size())return false;
        if(cutlet.firstDay!=cursor||cutlet.lastDay<cutlet.firstDay||cutlet.lastDay>cl)return false;
        if(cutlet.lastDay==std::numeric_limits<std::int64_t>::max())return false;
        cursor=cutlet.lastDay+1;
    }
    if(cursor!=cl+1)return false;
    for(int monthId:weaving){if(monthId<1||static_cast<std::size_t>(monthId)>monthNames.size())return false;}
    for(std::size_t nameIndex:monthNames){if(nameIndex<1||nameIndex>pastafari::MONTH_SOURCE_CATALOG.size())return false;}
    HotAlmanac value{true,cn,year,on,cl,cutlets,weaving,monthNames};
    for(auto&slot:hotAlmanac_){
        if(slot.occupied&&slot.calculationDay==cn){slot=std::move(value);return true;}
    }
    for(auto&slot:hotAlmanac_){
        if(!slot.occupied){slot=std::move(value);return true;}
    }
    return false;
}
std::size_t PairTombEnginePort::generatedAlmanacCount()const{
    std::size_t count=0;for(const auto&slot:hotAlmanac_)if(slot.occupied)++count;return count;
}
bool PairTombEnginePort::lookupHotAlmanac(std::int64_t c,std::int64_t t,CanonicalPastafariDate&out)const{
    for(const auto&almanac:hotAlmanac_){
        if(!almanac.occupied||almanac.calculationDay!=c||!(almanac.openDay<t&&t<=almanac.closeDay))continue;
        const AlmanacCutlet*chosen=nullptr;
        for(const auto&cutlet:almanac.cutlets){
            if(cutlet.firstDay<=t&&t<=cutlet.lastDay){chosen=&cutlet;break;}
        }
        if(chosen==nullptr)throw std::runtime_error("almanacum cutlet target non invenit");
        const Integer positionInteger=Integer{t}-Integer{almanac.openDay};
        if(positionInteger<1||positionInteger>Integer{almanac.monthWeaving.size()})throw std::runtime_error("almanacum positionem target amisit");
        const std::size_t position1=positionInteger.convert_to<std::size_t>();
        const int monthId=almanac.monthWeaving.at(position1-1);
        if(monthId<1||static_cast<std::size_t>(monthId)>almanac.monthNameIndices.size())throw std::runtime_error("almanacum monthId invalidum habet");
        std::size_t dayInMonth=0;
        for(std::size_t i=0;i<position1;++i)if(almanac.monthWeaving[i]==monthId)++dayInMonth;
        const std::size_t monthNameIndex=almanac.monthNameIndices.at(static_cast<std::size_t>(monthId-1));
        out=CanonicalPastafariDate{
            almanac.year,
            chosen->canonicalIndex,
            cutletNameAt(chosen->canonicalIndex),
            Integer{t}-Integer{chosen->firstDay}+1,
            monthNameIndex,
            monthNameAt(monthNameIndex),
            Integer{dayInMonth}
        };
        return true;
    }
    return false;
}
CanonicalPastafariDate PairTombEnginePort::calculate(const Integer&c,const Integer&t){
    if(!enabled_){++metrics_.bypasses;return buriedMonster_.calculate(c,t);}
    std::int64_t cn,tn;if(!narrow(c,cn)||!narrow(t,tn)){++metrics_.bypasses;return buriedMonster_.calculate(c,t);}
    for(const auto&slot:hotSeed_){
        if(slot.occupied&&slot.calculationDay==cn&&slot.targetDay==tn){++metrics_.hits;++metrics_.hotSeedHits;return slot.value;}
    }
    auto&slot=tombs_[slotFor(cn,tn)];
    if(slot.occupied&&slot.calculationDay==cn&&slot.targetDay==tn){++metrics_.hits;++metrics_.directMappedHits;return slot.value;}
    CanonicalPastafariDate almanacValue{};
    if(lookupHotAlmanac(cn,tn,almanacValue)){
        ++metrics_.hits;++metrics_.almanacHits;
        if(slot.occupied)++metrics_.evictions;
        slot={true,cn,tn,almanacValue};
        return almanacValue;
    }
    ++metrics_.misses;auto result=buriedMonster_.calculate(c,t);if(slot.occupied)++metrics_.evictions;slot={true,cn,tn,result};return result;
}
void PairTombEnginePort::clear(){for(auto&s:hotSeed_)s=Slot{};for(auto&a:hotAlmanac_)a=HotAlmanac{};for(auto&s:tombs_)s=Slot{};metrics_={};}
} // namespace pastafari::http_api
