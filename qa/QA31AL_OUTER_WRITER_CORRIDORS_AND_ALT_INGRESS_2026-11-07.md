# QA31AL — exact-source outer p/conditional-ingress audit (2026-11-07)

PROJECT_ID: PC-BRANCH-BEFUNGE98-KYRGYZ
Source Git blob: 560d6aa5807a7f766213a33835cce85eab0fa40c
Previous accepted QA31AK HEAD: 9094e8fe7ffa512ee242392ab480eba89553ee87
Original production source file: src/interleaved_work_counts.b98

## Narrow objective and safety contract

Inventory 44 original literal p glyphs outside rows 0..44 and determine
whether ORIGINAL SOURCE itself yields any bounded static proof that a
specific straight-line entry cannot put to q=(1,49) or m=(3,49).
Do not conflate a literal p glyph with a physically executed opcode.

Scan exactly up to 60 source cells upstream of each p in the four
cardinal directions for the first matching direction arrow. Accept a
conditional local corridor ONLY when all intervening original bytes
are pure deterministic stack arithmetic (digits 0..f, math, stack
shuffles, whitespace) without another control, memory read/write,
input, quote, or vector turn.

Symbolically interpret each accepted corridor on an ARBITRARY incoming
stack. Missing elements are UNKNOWN, not zero. Evaluate p with top
operands (y,x,v) and claim that the conditional corridor excludes a
counter address only when static y is a constant unequal to 49.
This does not prove the corridor is executed, or exclude p reached from
any other direction/source entry/modified code.

Expected source-only breakdown of the 44 external literal p glyphs:
- 43 bounded accepted pure straight corridors (one per original
  source p site apart from [369,575]).
- 11 corridors with constant y not equal 49, conditional exclusion
  of both q=(1,49) and m=(3,49).
- 32 corridors have unknown y for an arbitrary incoming stack.
- [369,575] has no qualifying local anchor within 60 cells.
- All 44 global dynamic targets remain UNKNOWN without execution
  and stack/IP evidence.
- Counter rows 20,23,29,32 each have original source '>' at
  x=10; adjacent north/south/west cells are blank. This is source
  geometry allowing a hypothetical inbound vector under some IP
  history, NOT a physical witness of an alternative ingress.

Forward checker independently inventories all original p source
coordinates and the precise corridor sequences. The second checker
imports NO forward code; it re-reads SHA-pinned source, reconstructs
each ray byte by byte, checks precise coordinate order, verifies exact
11 source-pinned fixed-y values, and independently runs at least five
different concrete pre-entry stack seeds per anchored corridor as
a supplementary falsification test. Samples are not a mathematical
proof in place of the forward arbitrary-stack abstract interpretation.
It rejects 14 synthetic tampered reports; the forward verifier checks
10 changed source p-glyph controls. All cases remain source-only.

## Acceptance

Only completed exact-code-SHA CI logs, independent oracle and
artifact acceptance may close this QA31AL *finite conditional* gate.
Never claim whole-program Funge-98 or natural-input reachability,
functional/geometric Stage1 acceptance, or a successful new Native
run. Do not change any production code. No merge/main/Stage2.

## NEXT after bounded QA31AL

QA31AM: investigate the 32 conditional unknown-y external corridors,
the unanchored original site (369,575), and physical alternative
IP/stack history. Seek original-source bounded predecessor paths and
address expressions. If those depend on unconstrained stack or mutable
code, explicitly preserve UNKNOWN and use already accepted original
signed Native evidence first. A new Native candidate must be
independently grounded in a concrete natural input and obey
<=25000 STEP per case, never fabricate expected RED.
Stage1 global/functional/geometric remains OPEN.
