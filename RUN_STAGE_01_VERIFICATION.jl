using Dates

const ROOT = @__DIR__
const WORKSPACE = joinpath(ROOT, "repo_delta")
const USER_ONLY = joinpath(ROOT, "user_only")
const LOG_PATH = joinpath(WORKSPACE, "STAGE_01_EXECUTION_LOG.txt")

function replace_key!(path::String, key::String, value::String)
    text = read(path, String)
    rx = Regex("(?m)^" * key * "=.*$")
    occursin(rx, text) || error("MISSING_KEY:" * key * ":" * path)
    text = replace(text, rx => key * "=" * value)
    write(path, text)
end

function replace_exact!(path::String, old::String, new::String)
    text = read(path, String)
    occursin(old, text) || error("MISSING_TEXT:" * path * ":" * old)
    write(path, replace(text, old => new))
end

function finalize_stage!(version_string::String)
    development = joinpath(WORKSPACE, "DEVELOPMENT_STAGE.md")
    readme = joinpath(WORKSPACE, "README.md")
    history = joinpath(WORKSPACE, "SPAGHETTI_DEVELOPMENT_HISTORY.md")
    audit = joinpath(WORKSPACE, "STAGE_01_STATIC_AUDIT.tsv")
    handoff = joinpath(USER_ONLY, "HANDOFF_STAGE_01_DRAFT.md")

    replace_key!(development, "LAST_COMPLETED_STAGE", "1")
    replace_key!(development, "SOURCE_LANGUAGE_CATALOG_FROZEN", "YES")
    replace_key!(development, "STATIC_ORACLE_AUDIT", "PASS_RUNTIME_VERIFIED")
    replace_key!(development, "JULIA_RUNTIME_CHECK", "PASS")

    replace_key!(readme, "SOURCE_LANGUAGE_CATALOG_STATE", "COMPLETE_FROZEN")
    replace_key!(readme, "SOURCE_LANGUAGE_CATALOG_FROZEN", "YES")
    replace_key!(readme, "JULIA_RUNTIME_STATE", "AVAILABLE")
    replace_key!(readme, "LOCAL_TEST_STATE", "PASS")
    replace_key!(readme, "JULIA_PORTABLE_RUNTIME_ATTEMPT", "NOT_REQUIRED_FOR_FINAL_PASS")
    replace_key!(readme, "STATIC_ORACLE_AUDIT", "PASS_RUNTIME_VERIFIED")

    replace_key!(history, "SOURCE_LANGUAGE_CATALOG_STATE", "COMPLETE_FROZEN")
    replace_key!(history, "STATIC_ORACLE_AUDIT", "PASS_RUNTIME_VERIFIED")

    replace_exact!(readme, "aňţtala.", "aňţtala. ämţtala. ümprala.")
    replace_exact!(history, "aňţtala.", "aňţtala. ämţtala. ümprala.")
    replace_exact!(handoff, "aňţtala.", "aňţtala. ämţtala. ümprala.")

    replace_exact!(audit,
        "catalog\tcatalog_frozen\tPENDING_RUNTIME_PASS\t64_of_64_static_complete_but_freeze_forbidden_until_real_Julia_PASS",
        "catalog\tcatalog_frozen\tPASS\t64_of_64_complete_and_frozen_after_real_Julia_PASS")
    replace_exact!(audit,
        "runtime\tjulia_tests_executed\tPENDING\tjulia_runtime_unavailable_in_current_environment",
        "runtime\tjulia_tests_executed\tPASS\tPkg_test_completed_successfully_in_Julia_" * replace(version_string, ' ' => '_'))

    replace_key!(handoff, "HANDOFF_STATE", "STAGE_01_COMPLETE_GREEN")
    replace_key!(handoff, "SOURCE_LANGUAGE_CATALOG_STATE", "COMPLETE_FROZEN")
    replace_key!(handoff, "LOCAL_TEST_STATE", "PASS")
    replace_key!(handoff, "JULIA_RUNTIME_STATE", "AVAILABLE")
    replace_key!(handoff, "STATIC_ORACLE_AUDIT", "PASS_RUNTIME_VERIFIED")

    write(joinpath(WORKSPACE, "TEST_RESULT_STAGE_01.txt"),
        "STAGE=01\n" *
        "STATE=PASS\n" *
        "JULIA_RUNTIME=AVAILABLE\n" *
        "JULIA_VERSION=" * version_string * "\n" *
        "SOURCE_LANGUAGE_CATALOG_VERIFIED=64/64\n" *
        "SOURCE_LANGUAGE_CATALOG_FROZEN=YES\n" *
        "HUMAN_PROSE_STATE=VALIDATED_MINIMAL_NEW_ITHKUIL\n" *
        "EXPECTED=GREEN\n" *
        "ACTUAL=GREEN\n" *
        "TEST_COMMAND=julia --project=. -e 'using Pkg; Pkg.test()'\n" *
        "STATIC_ORACLE_AUDIT=PASS_RUNTIME_VERIFIED\n")
end

isdir(WORKSPACE) || error("MISSING_WORKSPACE:" * WORKSPACE)
isfile(joinpath(WORKSPACE, "Project.toml")) || error("MISSING_PROJECT_TOML")

version_string = string(VERSION)
test_expr = "using Pkg; Pkg.test()"
cmd = `$(Base.julia_cmd()) --project=$(WORKSPACE) -e $(test_expr)`
passed = false

open(LOG_PATH, "w") do io
    println(io, "STAGE=01")
    println(io, "JULIA_VERSION=" * version_string)
    println(io, "START_TIME=" * string(now()))
    println(io, "COMMAND=julia --project=. -e 'using Pkg; Pkg.test()'")
    println(io, "OUTPUT_BEGIN")
    try
        run(pipeline(cmd, stdout=io, stderr=io))
        passed = true
    catch err
        println(io, "OUTPUT_END")
        println(io, "STATE=FAIL")
        println(io, "ERROR_TYPE=" * string(typeof(err)))
        println(io, "END_TIME=" * string(now()))
    end
    if passed
        println(io, "OUTPUT_END")
        println(io, "STATE=PASS")
        println(io, "END_TIME=" * string(now()))
    end
end

if !passed
    println("STAGE_01=FAIL")
    println("LOG=" * LOG_PATH)
    exit(1)
end

finalize_stage!(version_string)
println("STAGE_01=PASS")
println("LAST_COMPLETED_STAGE=1")
println("SOURCE_LANGUAGE_CATALOG_FROZEN=YES")
println("UPLOAD_ROOT=" * WORKSPACE)
println("LOG=" * LOG_PATH)
