#!/usr/bin/env sh
set -eu

if [ -n "${CXX:-}" ]; then
  :
elif command -v clang++ >/dev/null 2>&1; then
  CXX=clang++
else
  CXX=g++
fi

TMPROOT=${TMPDIR:-/tmp}
BUILD_DIR="$TMPROOT/pastafari-http-tests.$$"
mkdir -p "$BUILD_DIR"
trap 'rm -rf "$BUILD_DIR"' EXIT HUP INT TERM

TEST_OPT=${PASTAFARI_HTTP_TEST_OPT:--O0}
FLAGS="-std=c++20 $TEST_OPT -Wall -Wextra -Werror -pthread -Iinclude"
for source in \
  src/date_conversion.cpp \
  src/venus_boundary.cpp \
  src/service.cpp \
  src/name_language.cpp \
  src/strict_json.cpp \
  src/http_protocol.cpp \
  src/pair_tomb.cpp; do
  "$CXX" $FLAGS -c "$source" -o "$BUILD_DIR/$(basename "$source" .cpp).o"
done

compile_test() {
  name=$1
  source=$2
  shift 2
  "$CXX" $FLAGS -c "$source" -o "$BUILD_DIR/$name.test.o"
  "$CXX" -pthread "$BUILD_DIR/$name.test.o" "$@" -o "$BUILD_DIR/$name"
  "$BUILD_DIR/$name"
}

compile_test core tests/http_api_core_tests.cpp \
  "$BUILD_DIR/date_conversion.o" "$BUILD_DIR/venus_boundary.o"
compile_test strict_json tests/strict_json_tests.cpp \
  "$BUILD_DIR/strict_json.o"
compile_test service tests/service_tests.cpp \
  "$BUILD_DIR/date_conversion.o" "$BUILD_DIR/venus_boundary.o" \
  "$BUILD_DIR/service.o" "$BUILD_DIR/name_language.o" "$BUILD_DIR/strict_json.o"
compile_test protocol tests/http_protocol_tests.cpp \
  "$BUILD_DIR/date_conversion.o" "$BUILD_DIR/venus_boundary.o" \
  "$BUILD_DIR/service.o" "$BUILD_DIR/name_language.o" "$BUILD_DIR/strict_json.o" "$BUILD_DIR/http_protocol.o"
compile_test pair_tomb tests/pair_tomb_tests.cpp \
  "$BUILD_DIR/pair_tomb.o"

echo "PROBATIONES_HTTP_OMNES_TRANSIERUNT CXX=$CXX TEST_OPT=$TEST_OPT"
