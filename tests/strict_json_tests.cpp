#include "pastafari/http_api/strict_json.hpp"
#include <cassert>
#include <iostream>
using namespace pastafari::http_api::json;
int main(){auto v=parse(R"({"day":"0017","n":17,"a":[true,null]})");assert(v.isObject());assert(member(v.object(),"day")->isString());assert(member(v.object(),"n")->isNumber());bool dup=false;try{(void)parse(R"({"a":1,"a":2})");}catch(const Error&){dup=true;}assert(dup);std::cout<<"STRICT_JSON_TESTS=PASS\n";}
