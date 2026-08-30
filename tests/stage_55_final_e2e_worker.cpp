#include "pastafari/monster.hpp"
#include "reference/normative_reference.hpp"
#include "stage_55_fast_reference.hpp"

#include <iostream>
#include <stdexcept>
#include <string>

using pastafari::BaseMonsterManager;
using pastafari::Integer;
using pastafari::SpaghettiDateFive;
using pastafari::reference::CalendarDate;
using pastafari::reference::NormativeOracle;
using pastafari::reference::Year;

namespace {
void require(bool c,const std::string& m){if(!c)throw std::runtime_error(m);}
bool idem(const SpaghettiDateFive&a,const CalendarDate&b){return a.yearNumber==b.yearNumber&&a.cutletName==b.cutletName&&a.dayInCutlet==b.dayInCutlet&&a.monthName==b.monthName&&a.dayInMonth==b.dayInMonth;}
struct Casus{Integer c{},t{};CalendarDate e{};std::string nomen;int categoria=0;};

Casus para(const std::string& modus){
 const Integer f=pastafari::FOUNDATION_DAY_OLD;
 NormativeOracle o;
 if(modus=="foundation") return {f,f,pastafari::stage55audit::calendariumCeler(o,f,f),"foundation",1};
 if(modus=="before") return {f-1,f-1,pastafari::stage55audit::calendariumCeler(o,f-1,f-1),"ante foundation",2};
 if(modus=="after") return {f+1,f+1,pastafari::stage55audit::calendariumCeler(o,f+1,f+1),"post foundation",2};
 if(modus=="cross") return {f-1,f+1,pastafari::stage55audit::calendariumCeler(o,f-1,f+1),"trans foundation",3};
 if(modus=="opening"||modus=="first"||modus=="internal_target"||modus=="closing"){
  const Year y=o.year5000(f); Integer t{}; int cat=0;
  if(modus=="opening"){t=y.openGateDay;cat=26;}
  if(modus=="first"){t=y.openGateDay+1;cat=27;}
  if(modus=="internal_target"){t=o.gateValueForTest(y.openGateIndex+1);cat=28;require(y.openGateDay<t&&t<y.closeGateDay,"porta interna target abest");}
  if(modus=="closing"){t=y.closeGateDay;cat=29;}
  return {f,t,pastafari::stage55audit::calendariumCeler(o,f,t),modus,cat};
 }
 if(modus=="internal_calc"){
  const Integer c=o.gateValueForTest(Integer{7}); const Year y=o.year5000(c); Integer idx{};
  require(o.exactGateIndex(c,idx)&&y.openGateIndex<idx&&idx<y.closeGateIndex,"calculationDay porta interna non est");
  const Integer t=y.openGateDay+1; return {c,t,pastafari::stage55audit::calendariumCeler(o,c,t),modus,30};
 }
 if(modus=="year5000"||modus=="year5001"||modus=="year4999"){
  const Year y5000=o.year5000(f); Year y=y5000; int cat=42;
  if(modus=="year5001"){y=o.nextYear(f,y5000);cat=43;}
  if(modus=="year4999"){y=o.previousYear(f,y5000);cat=44;}
  const Integer t=y.openGateDay+1; return {f,t,pastafari::stage55audit::calendariumCeler(o,f,t),modus,cat};
 }
 throw std::runtime_error("modus e2e ignotus est");
}

int cacheWarm(){
 const Integer f=pastafari::FOUNDATION_DAY_OLD;
 CalendarDate e; {NormativeOracle o;e=pastafari::stage55audit::calendariumCeler(o,f,f);} 
 BaseMonsterManager m; const auto cold=m.executeFinalIntegration(f,f); const auto warm=m.executeFinalIntegration(f,f);
 require(!cold.guardedCacheHit&&warm.guardedCacheHit,"cache cold/warm rami discrepant");
 require(idem(cold.result,e)&&idem(warm.result,e),"cache warm output mutavit");
 std::cout<<"AUDIT_E2E_TRANSIIT CATEGORIAE=48,49 MODUS=cache_warm\n";return 0;
}
int cacheFingerprint(){
 const Integer f=pastafari::FOUNDATION_DAY_OLD,c2=f+1;
 CalendarDate e1,e2; {NormativeOracle o;e1=pastafari::stage55audit::calendariumCeler(o,f,f);e2=pastafari::stage55audit::calendariumCeler(o,c2,f);require(e1.yearNumber==e2.yearNumber,"idem year number requiritur");}
 BaseMonsterManager m; const auto a=m.executeFinalIntegration(f,f); const auto b=m.executeFinalIntegration(c2,f);
 require(idem(a.result,e1)&&idem(b.result,e2),"cache fingerprint output mutavit");
 require(b.guardedCacheRejected,"fingerprint mutatus cache reicere debet");
 std::cout<<"AUDIT_E2E_TRANSIIT CATEGORIA=50 MODUS=cache_fingerprint\n";return 0;
}
}

int main(int argc,char**argv){
 try{
  pastafari::stage55audit::probaReferenceCelerem();
  require(argc==2,"modus e2e requiritur"); const std::string modus=argv[1];
  if(modus=="cache_warm")return cacheWarm(); if(modus=="cache_fingerprint")return cacheFingerprint();
  const Casus q=para(modus); const auto a=pastafari::calendarDateSpaghetti(q.c,q.t); require(idem(a,q.e),"quinque campi discrepant in "+q.nomen);
  std::cout<<"AUDIT_E2E_TRANSIIT CATEGORIA="<<q.categoria<<" MODUS="<<modus<<" RESULT=["<<a.yearNumber<<','<<a.cutletName<<','<<a.dayInCutlet<<','<<a.monthName<<','<<a.dayInMonth<<"]\n";
  return 0;
 }catch(const std::exception&e){std::cerr<<"AUDIT_E2E_GRADUS_55_DEFECIT: "<<e.what()<<'\n';return 1;}
}
