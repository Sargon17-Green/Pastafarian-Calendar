# Befunge QA Spaghetti 04 — genuine input-dependent two-arm join

Fourth of twelve spaghetti-only work cycles. QA branch only. Preserves all
three self-modifying gate candidates and leaves production source intact.

PARENT_BLOB: 2baa1795a9a5802f58ecbd87ac8f138a1e811066
CANDIDATE_BLOB: e2eb7eec5503c22c6e73fb66aa7f8b9b072c4667
23 physical Funge-space source cells changed.

Entry: immediately after the existing native scanner g at (107,5), which
reads the saved input byte. Original literal zeros at (108,5),(109,5) are
replaced by v,>. A south detour reads the same stack byte without consuming
it (':' 2 % at (112..114,6)), then a native vertical conditional | at
(350,6) chooses:
- even input character (including the digit '0') -> lower arm;
  0 at (350,7), 0 at (350,8), west at (350,9), up at (320,9).
- odd input character (including digit '1') -> upper arm;
  reverse west on row 5, arithmetic 0 0 + 1 - ! 0, then south at (333,5).
Both arms have exactly the same net stack effect: retain original scanner
byte plus two 0 values, before rejoining at (320,7) and returning north to
(109,5), which redirects east to the original lexical scanner instructions.

The Native runner MUST capture full real PyFunge STEP records from the
repository's existing sitecustomize instrumentation and verify the
observed fork vectors, distinct upper/lower physical locations, joining
point, and scanner reentry. Compare original production, accepted prior
candidate, and new candidate against real independent Befunge references
on both zero-leading and one-leading sample inputs; invalid tokens also
must retain rejection semantics. Perturb each arithmetic arm separately
and demand observable output or termination effects.

Limitations: each input may traverse the lexer/fork multiple times. Only
the first input-character fork and selected sample families are audited;
no universal State Ownership guarantee, no new Stage 1 closure.
Previous run 39026040783 of the full legacy regression showed an overall
FAIL despite the API returning SUCCESS for 30 listed jobs. Investigate
the remaining/aggregate failure before any promotion. Do not promote QA
candidate to src or merge PR #17, and do not start Stage 2.
