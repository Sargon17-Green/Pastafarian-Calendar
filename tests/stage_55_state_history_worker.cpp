#include "pastafari/monster.hpp"

#include <iostream>
#include <stdexcept>
#include <string>

namespace {
void require(bool condicio,const std::string& nuntius){if(!condicio)throw std::runtime_error(nuntius);}
bool idem(const pastafari::SpaghettiDateFive&a,const pastafari::SpaghettiDateFive&b){return a.yearNumber==b.yearNumber&&a.cutletName==b.cutletName&&a.dayInCutlet==b.dayInCutlet&&a.monthName==b.monthName&&a.dayInMonth==b.dayInMonth;}
}
int main(){
 try{
  const auto c=pastafari::FOUNDATION_DAY_OLD;
  const auto t=pastafari::FOUNDATION_DAY_OLD;
  pastafari::BaseMonsterManager a,b;
  const auto a1=a.executeFinalIntegration(c,t);
  const auto b1=b.executeFinalIntegration(c,t);
  const auto a2=a.executeFinalIntegration(c,t);
  const auto b2=b.executeFinalIntegration(c,t);
  require(idem(a1.result,b1.result),"G: instantiae separatae discrepant");
  require(idem(a1.result,a2.result)&&idem(b1.result,b2.result),"H: invocationes repetitae historiam sentiunt");
  require(a2.guardedCacheHit&&b2.guardedCacheHit,"C/H: secundae invocationes cache warm exercere debent");
  std::cout<<"AUDIT_STATUS_HISTORIAE_TRANSIIT: C,G,H duae instantiae interleaved et repeated calls probata sunt\n";
  return 0;
 }catch(const std::exception&e){std::cerr<<"AUDIT_STATUS_HISTORIAE_DEFECIT: "<<e.what()<<'\n';return 1;}
}
