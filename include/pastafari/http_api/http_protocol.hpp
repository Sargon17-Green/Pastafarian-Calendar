#pragma once
#include "service.hpp"
#include <map>
#include <string>
#include <string_view>
namespace pastafari::http_api {
struct HttpResponse { int status{}; std::map<std::string,std::string> headers; std::string body; };
class HttpProtocol {
    CalendarService& service_;
public:
    explicit HttpProtocol(CalendarService&s):service_(s){}
    HttpResponse handle(std::string_view method,std::string_view target,std::string_view contentType,std::string_view body,std::int64_t sampledRequestMillis);
};
} // namespace pastafari::http_api
