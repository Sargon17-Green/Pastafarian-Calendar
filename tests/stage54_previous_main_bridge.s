.intel_syntax noprefix
.section .text
.global __wrap_calendarDateSpaghetti
.extern calendarDateSpaghettiLegacyDiagnostic
.type __wrap_calendarDateSpaghetti,@function
__wrap_calendarDateSpaghetti:
    jmp calendarDateSpaghettiLegacyDiagnostic
.size __wrap_calendarDateSpaghetti,.-__wrap_calendarDateSpaghetti
