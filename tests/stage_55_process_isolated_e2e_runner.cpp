#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

namespace {
void require(bool c,const std::string&m){if(!c)throw std::runtime_error(m);}
int curre(const std::string& programma,const std::string& argumentum){
 pid_t pid=fork();
 if(pid<0)throw std::runtime_error("fork defecit");
 if(pid==0){
  execl(programma.c_str(),programma.c_str(),argumentum.c_str(),static_cast<char*>(nullptr));
  _exit(127);
 }
 int status=0; require(waitpid(pid,&status,0)==pid,"waitpid defecit");
 if(WIFEXITED(status))return WEXITSTATUS(status);
 if(WIFSIGNALED(status))return 128+WTERMSIG(status);
 return 125;
}
int curreCumFixtura(const std::string& programma,const std::string& fixtura,const std::string& annus){
 pid_t pid=fork();
 if(pid<0)throw std::runtime_error("fork fixturae defecit");
 if(pid==0){
  execl(programma.c_str(),programma.c_str(),"--fixture",fixtura.c_str(),annus.c_str(),static_cast<char*>(nullptr));
  _exit(127);
 }
 int status=0; require(waitpid(pid,&status,0)==pid,"waitpid fixturae defecit");
 if(WIFEXITED(status))return WEXITSTATUS(status);
 if(WIFSIGNALED(status))return 128+WTERMSIG(status);
 return 125;
}
}

int main(){
 try{
  const std::string e2e="build_stage55_clang/stage_55_final_e2e_worker";
  const std::vector<std::string> modi{
   "foundation","before","after","cross",
   "opening","first","internal_target","closing","internal_calc",
   "year5000","year5001","year4999","cache_warm","cache_fingerprint"
  };
  for(const auto&m:modi){
   const int ec=curre(e2e,m);
   require(ec==0,"worker e2e defecit: "+m+" exit="+std::to_string(ec));
   std::cout<<"AUDIT_PROCESSUS_E2E_PASS MODUS="<<m<<'\n'<<std::flush;
  }
  const std::string far="build_stage55_clang/stage_55_far_year_worker";
  const std::string fixtura="tests/fixtures/stage_55_far_year_fixtures.txt";
  for(const auto&y:std::vector<std::string>{"1","0","-1"}){
   const int ec=curreCumFixtura(far,fixtura,y);
   require(ec==0,"worker anni remoti defecit: "+y+" exit="+std::to_string(ec));
   std::cout<<"AUDIT_PROCESSUS_ANNUS_PASS YEAR="<<y<<'\n'<<std::flush;
  }
  std::cout<<"AUDIT_E2E_PROCESSIBUS_ISOLATIS_GRADUS_55_TRANSIIT: categoriae 1-3,26-30,42-50\n";
  return 0;
 }catch(const std::exception&e){std::cerr<<"AUDIT_E2E_PROCESSIBUS_ISOLATIS_DEFECIT: "<<e.what()<<'\n';return 1;}
}
