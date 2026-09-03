#include "pastafari/http_api/pair_tomb.hpp"
#include "pastafari/monster.hpp"
#include <algorithm>
#include <cstdint>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <string>
#include <vector>

using namespace pastafari::http_api;

namespace {
std::int64_t parseDay(const char* text){
    Integer value{std::string{text}};
    static const Integer lo=std::numeric_limits<std::int64_t>::min();
    static const Integer hi=std::numeric_limits<std::int64_t>::max();
    if(value<lo||value>hi)throw std::runtime_error("dies extra int64 est");
    return value.convert_to<std::int64_t>();
}
std::int64_t narrow(const pastafari::Integer&v,const char*what){
    static const pastafari::Integer lo=std::numeric_limits<std::int64_t>::min();
    static const pastafari::Integer hi=std::numeric_limits<std::int64_t>::max();
    if(v<lo||v>hi)throw std::runtime_error(std::string(what)+" extra int64 est");
    return v.convert_to<std::int64_t>();
}
void emitIntVector(const std::vector<int>&v){
    std::cout<<"std::vector<int>{";
    for(std::size_t i=0;i<v.size();++i){if(i)std::cout<<',';std::cout<<v[i];}
    std::cout<<'}';
}
void emitSizeVector(const std::vector<int>&v){
    std::cout<<"std::vector<std::size_t>{";
    for(std::size_t i=0;i<v.size();++i){if(i)std::cout<<',';std::cout<<v[i];}
    std::cout<<'}';
}
void emitAlmanac(std::int64_t c,const pastafari::Stage54IntegrationReport&r){
    if(!r.ready||!r.exactFiveFieldReturn)throw std::runtime_error("report almanaci non paratus est");
    const auto open=narrow(r.targetYear.openGateDay,"porta aperiens");
    const auto close=narrow(r.targetYear.closeGateDay,"porta claudens");
    const auto length=static_cast<std::size_t>(close-open);
    if(r.structure.monthWeaving.size()!=length)throw std::runtime_error("textura mensium longitudinem anni non aequat");
    std::cout<<"// ATLAS_CALCULATION_DAY="<<c<<" YEAR="<<r.targetYear.number<<" OPEN="<<open<<" CLOSE="<<close<<"\n";
    std::cout<<"(void)buryHotAlmanacDiagnostic(Integer{\""<<c<<"\"},Integer{\""<<r.targetYear.number<<"\"},Integer{\""<<open<<"\"},Integer{\""<<close<<"\"},\n";
    std::cout<<"    std::vector<AlmanacCutlet>{";
    for(std::size_t i=0;i<r.structure.cutlets.size();++i){
        const auto&cut=r.structure.cutlets[i];
        if(i)std::cout<<',';
        std::cout<<'{'<<cut.canonicalIndex<<','<<narrow(cut.firstDay,"primus dies cutlet")<<"LL,"<<narrow(cut.lastDay,"ultimus dies cutlet")<<"LL}";
    }
    std::cout<<"},\n    ";emitIntVector(r.structure.monthWeaving);
    std::cout<<",\n    ";emitSizeVector(r.structure.monthNameIndices);
    std::cout<<");\n";
}
void build(std::int64_t c,std::int64_t low,std::int64_t high,std::int64_t globalLow){
    if(high<=low)throw std::runtime_error("shard inversus est");
    pastafari::BaseMonsterManager manager;
    auto report=manager.executeFinalIntegrationStage56(pastafari::Integer{c},pastafari::Integer{low});
    std::size_t guard=0;
    for(;;){
        if(!report.ready||!report.exactFiveFieldReturn)throw std::runtime_error("annus atlas non paratus est");
        const auto open=narrow(report.targetYear.openGateDay,"porta aperiens");
        const auto close=narrow(report.targetYear.closeGateDay,"porta claudens");
        if(close<=open)throw std::runtime_error("fines anni inversi sunt");
        const bool leading=(low==globalLow&&open<globalLow&&close>=globalLow);
        const bool assigned=(open>=low&&open<high);
        if(leading||assigned)emitAlmanac(c,report);
        if(close>=high)break;
        auto next=manager.executeFinalIntegrationStage56(pastafari::Integer{c},pastafari::Integer{close}+1);
        if(next.targetYear.openGateDay!=report.targetYear.closeGateDay)throw std::runtime_error("continuitas atlas fracta est");
        report=std::move(next);
        if(++guard>PairTombEnginePort::HOT_ALMANAC_LIMIT)throw std::runtime_error("custos atlas excessus est");
    }
}
}

int main(int argc,char**argv){
    try{
        if(argc!=5){
            std::cerr<<"usus: generate_hot_almanac_shard CALCULATION_DAY LOW HIGH GLOBAL_LOW\n";
            return 2;
        }
        const auto base=parseDay(argv[1]);
        const auto low=parseDay(argv[2]);
        const auto high=parseDay(argv[3]);
        const auto globalLow=parseDay(argv[4]);
        if(base==std::numeric_limits<std::int64_t>::max())throw std::runtime_error("base nimis magnus est");
        build(base,low,high,globalLow);
        build(base+1,low,high,globalLow);
        return 0;
    }catch(const std::exception&e){
        std::cerr<<"fatal: "<<e.what()<<'\n';
        return 1;
    }
}
