#!/usr/bin/env sh
set -eu

# Cadw'r contract cynhyrchu ffeiliau fixture, ond cynnwys pob dibyniaeth
# gynhyrchu sy'n angenrheidiol erbyn Cam 5. Nid oes cod prawf newydd yma.
build_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
kotlinc \
    src/main/kotlin/pastafari/ExactInt.kt \
    src/main/kotlin/pastafari/SourceLanguageCatalog.kt \
    src/main/kotlin/pastafari/LegacyRemainderAdapter.kt \
    src/main/kotlin/pastafari/SavePatchWrapper.kt \
    src/main/kotlin/pastafari/LegacyDayTagAdapter.kt \
    src/main/kotlin/pastafari/DayTagPatchWrapper.kt \
    src/main/kotlin/pastafari/MonsterBootstrap.kt \
    src/test/kotlin/pastafari/NormativeCore.kt \
    src/test/kotlin/pastafari/NormativeCalendar.kt \
    src/test/kotlin/pastafari/Stage01FixtureGenerator.kt \
    -include-runtime -d "$build_dir/stage01-fixture-generator.jar"
kotlin -classpath "$build_dir/stage01-fixture-generator.jar" pastafari.Stage01FixtureGenerator > stage01-fixtures.tsv
