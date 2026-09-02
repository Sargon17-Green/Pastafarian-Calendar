#!/usr/bin/env sh
set -eu

if [ -n "${D_COMPILER:-}" ]; then
    compiler="$D_COMPILER"
elif command -v dmd >/dev/null 2>&1; then
    compiler="dmd"
elif command -v ldc2 >/dev/null 2>&1; then
    compiler="ldc2"
elif command -v ldc >/dev/null 2>&1; then
    compiler="ldc"
elif command -v gdc >/dev/null 2>&1; then
    compiler="gdc"
else
    printf '%s\n' 'D կոմպիլյատոր չի գտնվել։ Սահմանեք D_COMPILER կամ տեղադրեք DMD/LDC/GDC։' >&2
    exit 127
fi

case "$(basename "$compiler")" in
    *gdc*)
        "$compiler" -Isource -Itests -funittest -o stage01_tests \
            tests/stage01_tests.d tests/normative_oracle.d \
            source/pastafari/catalog.d source/pastafari/monster_base.d
        ;;
    *)
        "$compiler" -Isource -Itests -unittest -of=stage01_tests \
            tests/stage01_tests.d tests/normative_oracle.d \
            source/pastafari/catalog.d source/pastafari/monster_base.d
        ;;
esac

./stage01_tests
rm -f stage01_tests stage01_tests.o
