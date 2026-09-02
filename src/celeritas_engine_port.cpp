#include "pastafari/http_api/engine_port.hpp"
#include "pastafari/monster.hpp"
#include "pastafari/source_language_catalog.hpp"
#include <stdexcept>
namespace pastafari::http_api {
namespace {
template<class Catalog> std::size_t indexFor(const Catalog& cat,const std::string& name,const char* kind){
    for(const auto&e:cat)if(e.text==name)return e.canonicalIndex;
    throw std::runtime_error(std::string("machina nomen ignotum reddidit pro ")+kind+"; nomen: "+name);
}}
CanonicalPastafariDate CeleritasEnginePort::calculate(const Integer& c,const Integer&t){
    auto r=pastafari::calendarDateSpaghetti(c,t);
    return {r.yearNumber,indexFor(pastafari::CUTLET_SOURCE_CATALOG,r.cutletName,"cutlet"),r.cutletName,r.dayInCutlet,
            indexFor(pastafari::MONTH_SOURCE_CATALOG,r.monthName,"month"),r.monthName,r.dayInMonth};
}
} // namespace pastafari::http_api
