# QA19 one-cell Native BF98 counterfactuals

The three source x cells are (150,20), (175,38), (396,17).
A program starts from a source-pinned, earlier genuine Native QA13 trace prefix.
The experiment compares a normal unmodified run against two otherwise identical one-cell pointer displacements: execution of the source x, and execution of a neutral z substituted only in temporary program memory.
An independent Befunge oracle verifies the normal baseline.

No counterfactual result establishes reachability under an ordinary unmodified input, absence of dead code, or Stage 1 acceptance. Earlier QA evidence, production source and main remain unchanged.

## Discovery RED and focused remediation (2026-10-21)

First GitHub Actions run 39632473432 was RED at the Native precondition, not at an x opcode. Immutable QA13 witness record 12359187730 selected, for each candidate, an already executed rightward-moving neighboring source 0 with TOSS depth exactly 0 (three targets: 4, 1, 4 candidates). A test-only requirement of two pre-existing operands was therefore overrestrictive. Befunge-98 defines missing pops as zero. Retry now permits the original zero-depth prefix and records implicit-zero underflow explicitly; it does not fabricate stack operands, edit production source, or claim any ordinary route to x. Keep the original RED in the audit trail.
