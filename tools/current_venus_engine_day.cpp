#include "pastafari/http_api/venus_boundary.hpp"
#include <chrono>
#include <iostream>

using namespace pastafari::http_api;

int main(){
    try{
        const auto resolved=currentDayAt(std::chrono::system_clock::now());
        std::cout<<resolved.engineDay<<'\n';
        return 0;
    }catch(const std::exception&e){
        std::cerr<<"fatal: "<<e.what()<<'\n';
        return 1;
    }
}
