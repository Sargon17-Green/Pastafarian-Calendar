#!/usr/bin/env sh
set -eu

if [ -n "${CXX:-}" ]; then
  :
elif command -v clang++ >/dev/null 2>&1; then
  CXX=clang++
else
  CXX=g++
fi

OUTPUT=${OUTPUT:-pastafari-http}
LINKER_FLAGS=${PASTAFARI_HTTP_LINKER_FLAGS:-}
if [ -z "$LINKER_FLAGS" ] && [ "$(basename "$CXX")" = "clang++" ] && command -v ld.lld >/dev/null 2>&1; then
  LINKER_FLAGS="-fuse-ld=lld"
fi
MONSTER_OPT=${PASTAFARI_HTTP_MONSTER_OPT:--O2}
MONSTER_OBJECT=${PASTAFARI_HTTP_MONSTER_OBJECT:-}
API_OPT=${PASTAFARI_HTTP_API_OPT:--O2}
SERVER_OPT=${PASTAFARI_HTTP_SERVER_OPT:--O0}
TMPROOT=${TMPDIR:-/tmp}
BUILD_DIR="$TMPROOT/pastafari-http-build.$$"
mkdir -p "$BUILD_DIR"
cleanup(){ rm -rf "$BUILD_DIR"; }
trap cleanup EXIT
trap 'exit 130' HUP INT TERM

API_FLAGS="-std=c++20 $API_OPT -Wall -Wextra -Werror -pthread -Iinclude"
SERVER_FLAGS="-std=c++20 $SERVER_OPT -Wall -Wextra -Werror -pthread -Iinclude"
MONSTER_FLAGS="-std=c++20 $MONSTER_OPT -Wall -Wextra -Wpedantic -Iinclude -Itests -I."

# Monstrum maximum primum compilatur, ante translation units Boost, ut vertex
# memoriae instrumentarii compilationis non inutiliter augeatur. Objectum iam
# probatum ad iterationem localem reutilizari potest; CI illud non praebet.
if [ -n "$MONSTER_OBJECT" ]; then
  test -r "$MONSTER_OBJECT"
  cp "$MONSTER_OBJECT" "$BUILD_DIR/monster.o"
else
  "$CXX" $MONSTER_FLAGS -c src/monster.cpp -o "$BUILD_DIR/monster.o"
fi

for source in \
  src/date_conversion.cpp \
  src/cors.cpp \
  src/venus_boundary.cpp \
  src/service.cpp \
  src/name_language.cpp \
  src/strict_json.cpp \
  src/http_protocol.cpp \
  src/pair_tomb.cpp \
  src/celeritas_engine_port.cpp; do
  object="$BUILD_DIR/$(basename "$source" .cpp).o"
  "$CXX" $API_FLAGS -c "$source" -o "$object"
done

# Boost.Beast multa template instantiat; hoc translation unit semanticae calendarii
# non interest, ideo optimizatione humili separatim aedificatur.
"$CXX" $SERVER_FLAGS -c src/http_server_main.cpp -o "$BUILD_DIR/http_server_main.o"

# Monstrum historicum admonitiones suas retinet; cicatrix HTTP eas in errores non mutat.
"$CXX" $LINKER_FLAGS -pthread "$BUILD_DIR"/*.o -o "$OUTPUT"

echo "AEDIFICATIO_HTTP_TRANSIIT CXX=$CXX OUTPUT=$OUTPUT MONSTER_OPT=$MONSTER_OPT API_OPT=$API_OPT SERVER_OPT=$SERVER_OPT LINKER_FLAGS=$LINKER_FLAGS MONSTER_OBJECT=${MONSTER_OBJECT:-none}"
