#!/usr/bin/env sh
set -eu
kotlinc src/main/kotlin/pastafari/ExactInt.kt src/main/kotlin/pastafari/SourceLanguageCatalog.kt src/main/kotlin/pastafari/MonsterBootstrap.kt src/test/kotlin/pastafari/NormativeCore.kt src/test/kotlin/pastafari/NormativeCalendar.kt src/test/kotlin/pastafari/Stage01FixtureGenerator.kt -include-runtime -d stage01-fixture-generator.jar
kotlin -classpath stage01-fixture-generator.jar pastafari.Stage01FixtureGenerator > stage01-fixtures.tsv
