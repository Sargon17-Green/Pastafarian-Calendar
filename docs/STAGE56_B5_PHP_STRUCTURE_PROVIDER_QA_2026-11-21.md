# Stage56 B5: PHP-owned conditional YearStructureProvider
PROJECT_ID: PC-BRANCH-PHP-MALAY
Parent SHA: e551b7e7987eba6553da903061394705965e39db

Added opt-in YearStructureProvider56 PHP production code, using the existing
BootstrapKernel canonical bowl response and production exact BigInt algorithms
in YearStructureSlices56, MonthWeavingRanker56 and UnboundedUniformChoice56.
Seven normative bowl/seal pairs: (2,20), (2,21), (5,22),
(3,30), (3,31), (4,32), (5,33); sauce target is first day of the
target year; calculationJdn is fixed for the call.

The provider requires a trusted contextual Year5000 witness, a target-year
witness with the same context and source commit, and gateDay(index) callback.
It independently validates adjacent 4999/5000/5001 seams, 6..137 gate
gaps, 42..963 days per gap, 252..5778-year length, and generates PHP-owned
cutlet partitions, unique names, month length vectors, month weave and
name indices. Internal calculation-day gates force cutlet boundaries.
No copied test oracle or external JS algorithm, no PATCH22/PATCH23 wiring.

tests/stage56_year_structure_provider.php validates a SYNTHETIC 252-day,
six-gate year with invariant and rejection assertions; never call this
proof of authentic 4999/5000/5001. A user-supplied witness callback
CANNOT authenticate its own source. Canonical source bytes/scroll-derived
independent oracle/Year5000 anchors and real year export are still missing.

NEXT: verify PHP8.3/64 native SHA-bound job and artifact; independently
authenticate callback source; generate actual 4999/5000/5001 PHP outputs,
three separate 900s/512M count/rank/unrank profiles and independent
differential. Stage56 NOT ACCEPTED. No merge, main, publication.
