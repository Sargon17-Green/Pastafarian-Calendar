#include "pastafari/http_api/date_conversion.hpp"
#include "pastafari/http_api/venus_boundary.hpp"
#include <cassert>
#include <iostream>
using namespace pastafari::http_api;
int main(){
    assert(jdnToEngineDay(Integer{1721426})==1);
    assert(jdnToEngineDay(Integer{1442903})==Integer{-278522});
    assert(jdnToEngineDay(FOUNDATION_JDN)==FOUNDATION_ENGINE_DAY);
    assert(gregorianToJdn({Integer{-762},6,7})==Integer{1442903});
    assert(gregorianToJdn({Integer{1},1,1})==Integer{1721426});
    auto a=resolveDate("31/08/2026"); assert(a.detectedFormat=="dmy");
    auto b=resolveDate("08/31/2026"); assert(b.detectedFormat=="mdy");
    bool amb=false;try{(void)resolveDate("03/04/2026");}catch(const DateError&e){amb=e.code=="AMBIGUOUS_DATE";}assert(amb);
    auto c=resolveDate("03/04/2026","gregorian","dmy");assert(c.normalized=="2026-04-03");
    auto iso=resolveDate("2026-W36-3"); assert(iso.engineDay==resolveDate("2026-09-02").engineDay);
    auto ord=resolveDate("2026-245"); assert(ord.engineDay==resolveDate("2026-09-02").engineDay);
    auto named=resolveDate("2 September 2026"); assert(named.engineDay==resolveDate("2026-09-02").engineDay);
    auto named2=resolveDate("September 2, 2026"); assert(named2.engineDay==resolveDate("2026-09-02").engineDay);
    bool badint=false;try{(void)resolveDate("0017","engine-day");}catch(const DateError&e){badint=e.code=="INVALID_INTEGER";}assert(badint);
    bool variant=false;try{(void)resolveDate("1447-01-01","islamic");}catch(const DateError&e){variant=e.code=="CALENDAR_VARIANT_REQUIRED";}assert(variant);
    auto now=currentDayAtUnixMilliseconds(0); // 1970-01-01T00:00:00Z; model range.
    assert(now.previousBoundary.jd <= 2440587.5 && 2440587.5 < now.nextBoundary.jd);
    assert(now.engineDay==jdnToEngineDay(now.jdn));
    std::cout<<"HTTP_API_CORE_TESTS=PASS\n";
    std::cout<<"UNIX_EPOCH_KISURRA_JDN="<<now.jdn<<" ENGINE_DAY="<<now.engineDay<<"\n";
}
