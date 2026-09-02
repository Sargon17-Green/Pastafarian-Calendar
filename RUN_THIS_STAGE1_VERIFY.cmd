@echo off
setlocal EnableExtensions
cd /d "%~dp0"

if not exist build mkdir build
set "LOG=build\STAGE_01_VERIFY_LOG.txt"

>"%LOG%" echo STAGE=1
>>"%LOG%" echo MODE=STAGE1_VERIFY
>>"%LOG%" echo COBOL=GNUCOBOL
>>"%LOG%" echo STRICT_WARNINGS=YES

where cobc >nul 2>nul
if errorlevel 1 goto blocked

>>"%LOG%" echo CMD=cobc --version
cobc --version >>"%LOG%" 2>&1
if errorlevel 1 goto fail

set "WARNINGS=-Wall -Wextra -Wno-terminator -Wstrict-typing -Wcall-params -Wlinkage -Wtruncate -Werror"
set "COMMON=src\big_integer.cob src\source_language_catalog.cob src\monster_bootstrap.cob test\oracle\oracle_constants.cob test\oracle\oracle_bigint.cob test\oracle\normative_basic.cob test\oracle\normative_bigint_primitives.cob test\oracle\normative_sauce.cob test\oracle\normative_selection.cob test\oracle\normative_families.cob test\oracle\normative_weaving.cob test\oracle\normative_gates.cob test\oracle\normative_year.cob test\oracle\normative_oracle.cob"

>>"%LOG%" echo PHASE=COMPILE_STAGE1_STRICT
cobc -std=default -free %WARNINGS% -x -o build\bootstrap-tests.exe test\bootstrap_tests.cob test\big_integer_tests.cob test\normative_primitive_tests.cob test\source_catalog_tests.cob test\family_bruteforce_tests.cob test\selection_tests.cob test\ownership_error_tests.cob %COMMON% >>"%LOG%" 2>&1
if errorlevel 1 goto fail

>>"%LOG%" echo PHASE=RUN_STAGE1_BOOTSTRAP_TESTS
build\bootstrap-tests.exe >>"%LOG%" 2>&1
if errorlevel 1 goto fail

findstr /I /C:"signal SIGSEGV" /C:"attempt to reference invalid memory address" /C:"stack overflow" /C:"abnormal termination" "%LOG%" >nul
if not errorlevel 1 goto fatal

findstr /C:"BOOTSTRAP_RESULT=PASS" "%LOG%" >nul
if errorlevel 1 goto missing

>>"%LOG%" echo RESULT=PASS_STAGE1_VERIFY
>>"%LOG%" echo EXIT_CODE=0
type "%LOG%"
exit /b 0

:blocked
>>"%LOG%" echo RESULT=BLOCKED
>>"%LOG%" echo REASON=COBC_NOT_FOUND
>>"%LOG%" echo EXIT_CODE=127
type "%LOG%"
exit /b 127

:fatal
>>"%LOG%" echo RESULT=FAIL
>>"%LOG%" echo REASON=FATAL_RUNTIME_MARKER
>>"%LOG%" echo EXIT_CODE=3
type "%LOG%"
exit /b 3

:missing
>>"%LOG%" echo RESULT=FAIL
>>"%LOG%" echo REASON=BOOTSTRAP_PASS_MARKER_MISSING
>>"%LOG%" echo EXIT_CODE=4
type "%LOG%"
exit /b 4

:fail
set "RC=%ERRORLEVEL%"
>>"%LOG%" echo RESULT=FAIL
>>"%LOG%" echo EXIT_CODE=%RC%
type "%LOG%"
exit /b %RC%
