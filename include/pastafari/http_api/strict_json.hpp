#pragma once
#include <map>
#include <stdexcept>
#include <string>
#include <string_view>
#include <variant>
#include <vector>

namespace pastafari::http_api::json {
struct Number { std::string lexeme; };
struct Value;
using Array = std::vector<Value>;
using Object = std::map<std::string,Value,std::less<>>;
struct Value {
    using Storage=std::variant<std::nullptr_t,bool,Number,std::string,Array,Object>;
    Storage data;
    bool isString()const{return std::holds_alternative<std::string>(data);} bool isObject()const{return std::holds_alternative<Object>(data);} bool isArray()const{return std::holds_alternative<Array>(data);} bool isNumber()const{return std::holds_alternative<Number>(data);}
    const std::string& string()const{return std::get<std::string>(data);} const Object& object()const{return std::get<Object>(data);} const Array& array()const{return std::get<Array>(data);}
};
class Error:public std::runtime_error{public:std::size_t offset;Error(std::string m,std::size_t o):std::runtime_error(std::move(m)),offset(o){}};
Value parse(std::string_view text);
std::string stringify(const Value& value);
std::string escape(std::string_view value);
const Value* member(const Object& object,std::string_view key);
} // namespace pastafari::http_api::json
