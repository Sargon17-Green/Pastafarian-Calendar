# Stage44 / DISCOVERY22 Native closure
PROJECT_ID: PC-BRANCH-PHP-MALAY
SOURCE_SHA=da77d83a2d9d8945d1d608d485cada8fde448a3e
ACTIONS_RUN=https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41199851276
RUN_STATUS=completed
RUN_CONCLUSION=success
ALL_JOBS=15_OF_15_SUCCESS
NATIVE_JOB=https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41199851276/job/124533328466
NATIVE_PHP=8.3.36_64BIT
NATIVE_LINT=PASS_2_FILES
NATIVE_CONTROLS=18
NATIVE_CANDIDATES=2
NATIVE_REPRODUCED=2
NATIVE_REJECTED=0
NATIVE_OTHER=0
NATIVE_STDERR=EMPTY
NATIVE_EXIT=0
NATIVE_ARTIFACT=https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41199851276/artifacts/13042193909
NATIVE_ARTIFACT_SHA256=2098a088709527d66c924bb49f8d3d3f58be1462b578ffd228d3fb0ba036b8c3

Actual stdout:
CANDIDATE_REPRODUCED direction=forward canonical_gate=14 returned_gate=13 target=-15053458
CANDIDATE_REPRODUCED direction=backward canonical_gate=-12 returned_gate=-11 target=-15057703
STAGE44_DISCOVERY22_PROBE controls=18 candidates=2 reproduced=2 rejected=0 other=0

Classification: EXPECTED_RED confirmed *only* for intentionally noncanonical
caller-supplied adjacent-year callback. Trusted-provider assumption is broken
by the experiment. This authorizes independent-validation PATCH22 research,
not a claim of real-world failure on trustworthy providers.
