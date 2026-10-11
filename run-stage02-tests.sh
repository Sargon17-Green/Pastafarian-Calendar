#!/usr/bin/env sh
set -eu

# Rhaid defnyddio ffeiliau union Cam 1 y gangen hon, nid amnewidion prawf.
if ! command -v git >/dev/null 2>&1; then
    echo 'E_STAGE02_GIT_REQUIRED_FOR_BASELINE_PROVENANCE' >&2
    exit 1
fi
if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null || true)" != true ]; then
    echo 'E_STAGE02_NOT_IN_GIT_WORKTREE' >&2
    exit 1
fi
branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)
if [ "$branch" != 'Kotlin+Cymraeg' ]; then
    echo 'E_STAGE02_WRONG_BRANCH' >&2
    exit 1
fi

# Mae --path yn parchu priodoleddau Git (gan gynnwys normaleiddio CRLF).
# Mae'r SHA yn perthyn i'r union gangen gychwynnol, nid i weithrediad arall.
while IFS=' ' read -r expected source; do
    if [ ! -f "$source" ]; then
        printf 'E_STAGE02_BASELINE_MISSING:%s\n' "$source" >&2
        exit 1
    fi
    actual=$(git hash-object --path="$source" "$source") || {
        printf 'E_STAGE02_BASELINE_HASH_FAILURE:%s\n' "$source" >&2
        exit 1
    }
    if [ "$actual" != "$expected" ]; then
        printf 'E_STAGE02_BASELINE_CHANGED:%s\n' "$source" >&2
        exit 1
    fi
done <<'BASELINE'
3c567e1bb7ad0a5d96b48edbee0d0a4163c05ce8 src/main/kotlin/pastafari/ExactInt.kt
7082e7e87018ea1d320d10a40b0c77d3daa286bd src/main/kotlin/pastafari/SourceLanguageCatalog.kt
c6a1ef4f61dd813f4223290c346694562e05818f src/test/kotlin/pastafari/NormativeCore.kt
033869e43285f793aacf7cf300ce6cf6d0c6a81f src/test/kotlin/pastafari/NormativeCalendar.kt
e9b92357a5f5cc804278507860dd2a261d30a0f3 src/test/kotlin/pastafari/Stage01Tests.kt
BASELINE
printf '%s\n' 'STAGE02_BASELINE_PROVENANCE_PASS_5'

build_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
regression_log="$build_dir/stage01.log"
discovery_log="$build_dir/stage02.log"
strict_log="$build_dir/strict.log"
if ! STAGE01_OUTPUT_JAR="$build_dir/stage01.jar" sh run-stage01-tests.sh > "$regression_log" 2>&1; then
    cat "$regression_log" >&2
    echo 'E_STAGE01_REGRESSION_FAILURE' >&2
    exit 1
fi
cat "$regression_log"
if ! grep -Fxq 'STAGE01_PASS_66' "$regression_log"; then
    echo 'E_STAGE01_REGRESSION_MARKER' >&2
    exit 1
fi

if ! kotlinc \
    src/main/kotlin/pastafari/ExactInt.kt \
    src/main/kotlin/pastafari/SourceLanguageCatalog.kt \
    src/main/kotlin/pastafari/LegacyRemainderAdapter.kt \
    src/main/kotlin/pastafari/SavePatchWrapper.kt \
    src/main/kotlin/pastafari/LegacyDayTagAdapter.kt \
    src/main/kotlin/pastafari/MonsterBootstrap.kt \
    src/test/kotlin/pastafari/NormativeCore.kt \
    src/test/kotlin/pastafari/NormativeCalendar.kt \
    src/test/kotlin/pastafari/Stage02Tests.kt \
    -include-runtime -d "$build_dir/stage02.jar"; then
    echo 'E_STAGE02_COMPILE' >&2
    exit 1
fi
if ! kotlin -classpath "$build_dir/stage02.jar" pastafari.Stage02Tests > "$discovery_log" 2>&1; then
    cat "$discovery_log" >&2
    echo 'E_STAGE02_DISCOVERY_EXECUTION' >&2
    exit 1
fi
cat "$discovery_log"
for marker in \
    STAGE02_PERIODICITY_PASS_195 \
    STAGE02_FAR_ARITHMETIC_AND_REJECTION_PASS \
    STAGE02_BOUNDARY_AND_OWNERSHIP_PASS_7 \
    STAGE02_EXPECTED_RED_3
do
    if ! grep -Fxq "$marker" "$discovery_log"; then
        printf 'E_STAGE02_MISSING_DISCOVERY_MARKER:%s\n' "$marker" >&2
        exit 1
    fi
done
if kotlin -classpath "$build_dir/stage02.jar" pastafari.Stage02Tests --strict > "$strict_log" 2>&1; then
    echo 'E_DISCOVERY01_STRICT_UNEXPECTED_GREEN' >&2
    exit 1
fi
if ! grep -Fq 'E_DISCOVERY01_NORMATIVE_DIFFERENCE:M,2M,3M' "$strict_log"; then
    cat "$strict_log" >&2
    echo 'E_DISCOVERY01_STRICT_WRONG_FAILURE' >&2
    exit 1
fi
printf '%s\n' 'STAGE02_STRICT_RED_CONFIRMED'
