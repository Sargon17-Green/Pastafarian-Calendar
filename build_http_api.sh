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
LOW_MEMORY_SCAR=${PASTAFARI_HTTP_LOW_MEMORY_SCAR:-0}
ANCESTRAL_YEAR_INDEX_SCAR=${PASTAFARI_HTTP_ANCESTRAL_YEAR_INDEX_SCAR:-1}
TMPROOT=${TMPDIR:-/tmp}
BUILD_DIR="$TMPROOT/pastafari-http-build.$$"
mkdir -p "$BUILD_DIR"
cleanup(){ rm -rf "$BUILD_DIR"; }
trap cleanup EXIT
trap 'exit 130' HUP INT TERM

API_FLAGS="-std=c++20 $API_OPT -Wall -Wextra -Werror -pthread -Iinclude"
SERVER_FLAGS="-std=c++20 $SERVER_OPT -Wall -Wextra -Werror -pthread -Iinclude"
MONSTER_FLAGS="-std=c++20 $MONSTER_OPT -Wall -Wextra -Wpedantic -Iinclude -Itests -I."
MONSTER_SOURCE=src/monster.cpp

# CICATRIX MEMORIAE HTTP: monstrum in repository intactum manet. Solum copia
# temporaria aedificationis burialem gravissimam Patch 38 non persistentem facit.
if [ "$LOW_MEMORY_SCAR" = "1" ]; then
  if [ -n "$MONSTER_OBJECT" ]; then
    echo "PASTAFARI_HTTP_LOW_MEMORY_SCAR non accipit MONSTER_OBJECT praecompilatum" >&2
    exit 2
  fi
  test -r tools/http_low_memory_monster.awk
  LOW_MEMORY_SOURCE="$BUILD_DIR/monster.http-low-memory.cpp"
  awk -f tools/http_low_memory_monster.awk "$MONSTER_SOURCE" > "$LOW_MEMORY_SOURCE"
  MONSTER_SOURCE="$LOW_MEMORY_SOURCE"
fi

# CICATRIX INDICIS ANNI: structurae PATCH 27 iam sepultae ante year-walk
# consuluntur. src/monster.cpp manet intactum; tantum copia HTTP hunc detour habet.
if [ "$ANCESTRAL_YEAR_INDEX_SCAR" = "1" ] && [ -z "$MONSTER_OBJECT" ]; then
  test -r tools/http_ancestral_year_index.awk
  INDEXED_SOURCE="$BUILD_DIR/monster.http-ancestral-index.cpp"
  awk -f tools/http_ancestral_year_index.awk "$MONSTER_SOURCE" > "$INDEXED_SOURCE"
  MONSTER_SOURCE="$INDEXED_SOURCE"
fi

# Monstrum maximum primum compilatur, ante translation units Boost.
if [ -n "$MONSTER_OBJECT" ]; then
  test -r "$MONSTER_OBJECT"
  cp "$MONSTER_OBJECT" "$BUILD_DIR/monster.o"
else
  "$CXX" $MONSTER_FLAGS -c "$MONSTER_SOURCE" -o "$BUILD_DIR/monster.o"
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

"$CXX" $SERVER_FLAGS -c src/http_server_main.cpp -o "$BUILD_DIR/http_server_main.o"
"$CXX" $LINKER_FLAGS -pthread "$BUILD_DIR"/*.o -o "$OUTPUT"

echo "AEDIFICATIO_HTTP_TRANSIIT CXX=$CXX OUTPUT=$OUTPUT MONSTER_OPT=$MONSTER_OPT API_OPT=$API_OPT SERVER_OPT=$SERVER_OPT LINKER_FLAGS=$LINKER_FLAGS MONSTER_OBJECT=${MONSTER_OBJECT:-none} LOW_MEMORY_SCAR=$LOW_MEMORY_SCAR ANCESTRAL_YEAR_INDEX_SCAR=$ANCESTRAL_YEAR_INDEX_SCAR"
